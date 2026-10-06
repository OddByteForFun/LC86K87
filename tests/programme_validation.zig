// Programme de validation du cœur LC86K87.
//
// Un programme en assembleur LC86K, assemblé à la main, est chargé dans la
// ROM puis exécuté instruction par instruction via la façade publique du
// module (`@import("lc86k")`), comme le ferait un vrai consommateur.
// Le programme a un comportement déterministe : à la fin, les résultats
// attendus sont connus à l'avance et comparés à l'état réel du CPU.
//
// Ce qui est validé :
//   - MOV/ADD/ADDC/SUB/MUL/DIV et les drapeaux CY/AC/OV/P
//   - LD/ST en espace RAM et en espace SFR (ACC, B, C, PSW, SP, PCON)
//   - boucles avec INC + DBNZ et adressage indirect @R0
//   - branches BZ/BNZ/BE/BR
//   - pile : PUSH/POP + CALL/RET (sous-programme de vérification)
//   - HALT via SET1 PCON,0
//   - coût en cycles et nombre d'instructions exécutées
//
// Carte RAM (bank 0) utilisée par le programme :
//   00h        R0 — pointeur de table
//   08h        compteur de boucle
//   20h-27h    table de données (12h 34h 56h 78h 9Ah BCh DEh F0h)
//   30h        somme 16 bits [7:0]   = 38h
//   31h        somme 16 bits [15:8]  = 04h
//   32h        XOR en cascade        = 00h
//   34h        MUL : ACC             = 01h
//   35h        MUL : C               = C2h
//   36h        DIV : quotient [15:8] = 00h
//   37h        DIV : quotient [7:0]  = 40h
//   38h        DIV : reste           = 02h
//   39h        status                = 55h (OK)
//   3Ah        ACC après ADD 78h+9Ah = 12h
//   3Bh        PSW après ADD         = C0h (CY=1, AC=1, OV=0, P=0)
//   3Ch        ACC après 80h-01h     = 7Fh
//   3Dh        PSW après SUB         = 45h (CY=0, AC=1, OV=1, P=1)
//   80h        sauvegarde PUSH (04h), 81h/82h : adresse de retour CALL

const std = @import("std");
const testing = std.testing;
const lc86k = @import("lc86k");

/// Adresse du premier octet hors HALT (le PC final du CPU).
const adresse_apres_halt: u16 = 0x094;
/// Nombre d'instructions exécutées jusqu'au HALT.
const instructions_attendues: u32 = 146;
/// Nombre total de cycles consommés jusqu'au HALT (table isa.TABLE).
const cycles_attendus: u32 = 208;

/// Programme assemblé à la main. Chaque ligne = une instruction,
/// l'adresse est donnée en commentaire.
const programme = [_]u8{
    // ── Phase 0 : initialisation ─────────────────────────────────────
    0x23, 0x06, 0x7F, // 0000h: MOV #07FH,SP      SP = 7Fh (pile en 80h+)
    0x22, 0x08, 0x08, // 0003h: MOV #008H,008H    compteur = 8
    0x22, 0x20, 0x12, // 0006h: MOV #012H,020H    table[0] = 12h
    0x22, 0x21, 0x34, // 0009h: MOV #034H,021H    table[1] = 34h
    0x22, 0x22, 0x56, // 000Ch: MOV #056H,022H    table[2] = 56h
    0x22, 0x23, 0x78, // 000Fh: MOV #078H,023H    table[3] = 78h
    0x22, 0x24, 0x9A, // 0012h: MOV #09AH,024H    table[4] = 9Ah
    0x22, 0x25, 0xBC, // 0015h: MOV #0BCH,025H    table[5] = BCh
    0x22, 0x26, 0xDE, // 0018h: MOV #0DEH,026H    table[6] = DEh
    0x22, 0x27, 0xF0, // 001Bh: MOV #0F0H,027H    table[7] = F0h
    0x22, 0x00, 0x20, // 001Eh: MOV #020H,000H    R0 = pointeur table
    0x23, 0x00, 0x00, // 0021h: MOV #000H,ACC     ACC = 0
    0x22, 0x31, 0x00, // 0024h: MOV #000H,031H    somme.hi = 0

    // ── Phase 1 : somme 16 bits des 8 octets (boucle) ────────────────
    0x84, //             0027h: ADD @R0             loop1: ACC += (R0), CY
    0x12, 0x30, //       0028h: ST 030H             somme.lo = ACC
    0x02, 0x31, //       002Ah: LD 031H             ACC = somme.hi
    0x91, 0x00, //       002Ch: ADDC #000H          somme.hi += CY
    0x12, 0x31, //       002Eh: ST 031H             somme.hi = ACC
    0x02, 0x30, //       0030h: LD 030H             ACC = somme.lo
    0x62, 0x00, //       0032h: INC 000H            R0++
    0x52, 0x08, 0xF0, // 0034h: DBNZ 008H,0027h     compteur--, boucle (-10h)

    // ── Phase 2 : XOR en cascade des 8 octets (boucle) ───────────────
    0x22, 0x00, 0x20, // 0037h: MOV #020H,000H      R0 = pointeur table
    0x22, 0x08, 0x08, // 003Ah: MOV #008H,008H      compteur = 8
    0x23, 0x00, 0x00, // 003Dh: MOV #000H,ACC       ACC = 0
    0xF4, //             0040h: XOR @R0              loop2: ACC ^= (R0)
    0x62, 0x00, //       0041h: INC 000H             R0++
    0x52, 0x08, 0xFA, // 0043h: DBNZ 008H,0040h      compteur--, boucle (-6)
    0x12, 0x32, //       0046h: ST 032H              xor = 00h

    // ── Phase 3 : statut, pile, appel du sous-programme ──────────────
    0x22, 0x39, 0xEE, // 0048h: MOV #0EEH,039H       status = KO par défaut
    0x02, 0x31, //       004Bh: LD 031H               ACC = somme.hi
    0x90, 0x03, //       004Dh: BNZ 0052h             ≠0 → poids fort plausible
    0x22, 0x39, 0xDD, // 004Fh: MOV #0DDH,039H        sinon status = anomalie
    0x61, 0x00, //       0052h: PUSH ACC              sauvegarde en pile[80h]
    0x08, 0x95, //       0054h: CALL 0095h            → sous-programme verify
    0x71, 0x00, //       0056h: POP ACC               restaure ACC (04h)

    // ── Phase 4 : MUL puis DIV ───────────────────────────────────────
    0x23, 0x02, 0x0A, // 0058h: MOV #00AH,B           B = 10
    0x23, 0x00, 0x00, // 005Bh: MOV #000H,ACC         ACC = 0
    0x23, 0x03, 0x2D, // 005Eh: MOV #02DH,C           C = 45
    0x30, //             0061h: MUL                    (ACC:C)*B = 0001C2h
    0x12, 0x34, //       0062h: ST 034H                MUL ACC = 01h
    0x03, 0x03, //       0064h: LD 003H                ACC = C
    0x12, 0x35, //       0066h: ST 035H                MUL C = C2h
    0x23, 0x00, 0x01, // 0068h: MOV #001H,ACC           ACC = 01h
    0x23, 0x03, 0xC2, // 006Bh: MOV #0C2H,C             C = C2h → 450
    0x23, 0x02, 0x07, // 006Eh: MOV #007H,B             B = 7
    0x40, //             0071h: DIV                      450 / 7
    0x12, 0x36, //       0072h: ST 036H                  quotient [15:8] = 00h
    0x03, 0x03, //       0074h: LD 003H                  ACC = C
    0x12, 0x37, //       0076h: ST 037H                  quotient [7:0] = 40h
    0x03, 0x02, //       0078h: LD 002H                  ACC = B
    0x12, 0x38, //       007Ah: ST 038H                  reste = 02h

    // ── Phase 5 : contrôle des drapeaux ──────────────────────────────
    0x23, 0x00, 0x78, // 007Ch: MOV #078H,ACC           ACC = 78h
    0x81, 0x9A, //       007Fh: ADD #09AH                78h+9Ah = 112h
    0x12, 0x3A, //       0081h: ST 03AH                  ACC = 12h
    0x03, 0x01, //       0083h: LD 001H                  ACC = PSW
    0x12, 0x3B, //       0085h: ST 03BH                  PSW = C0h
    0x23, 0x00, 0x80, // 0087h: MOV #080H,ACC             ACC = 80h
    0xA1, 0x01, //       008Ah: SUB #001H                 80h-01h = 7Fh
    0x12, 0x3C, //       008Ch: ST 03CH                   ACC = 7Fh
    0x03, 0x01, //       008Eh: LD 001H                   ACC = PSW
    0x12, 0x3D, //       0090h: ST 03DH                   PSW = 45h

    // ── Phase 6 : HALT ───────────────────────────────────────────────
    0xF8, 0x07, //       0092h: SET1 PCON,0               HALT
    0x00, //             0094h: NOP                       jamais exécuté

    // ── Sous-programme verify (cible du CALL) ────────────────────────
    0x02, 0x32, //       0095h: LD 032H                   ACC = xor
    0x80, 0x02, //       0097h: BZ 009Bh                  xor nul → contrôle 1
    0x01, 0x12, //       0099h: BR 00ADh                  sinon → échec
    0x02, 0x30, //       009Bh: LD 030H                   ACC = somme.lo
    0x31, 0x38, 0x02, // 009Dh: BE #038H,00A2h             = 38h → contrôle 2
    0x01, 0x0B, //       00A0h: BR 00ADh                  sinon → échec
    0x02, 0x31, //       00A2h: LD 031H                   ACC = somme.hi
    0x31, 0x04, 0x02, // 00A4h: BE #004H,00A9h             = 04h → OK
    0x01, 0x04, //       00A7h: BR 00ADh                  sinon → échec
    0x22, 0x39, 0x55, // 00A9h: MOV #055H,039H             status = OK
    0xA0, //             00ACh: RET
    0xA0, //             00ADh: RET                       échec (status ≠ 55h)
};

/// Charge le programme dans une ROM de 64 KiB (le reste vaut 00h = NOP).
fn makeRom() [65536]u8 {
    var rom: [65536]u8 = @splat(0);
    @memcpy(rom[0..programme.len], &programme);
    return rom;
}

/// Exécute le programme jusqu'au HALT et rend le CPU final.
/// `rom` doit rester vivant aussi longtemps que le CPU retourné
/// (Cpu conserve un slice vers la ROM).
fn executer(rom: []u8) lc86k.Cpu {
    var cpu = lc86k.Cpu.init(rom);
    var pas: u32 = 0;
    while (!cpu.halted and pas < 10_000) : (pas += 1) {
        _ = lc86k.step(&cpu);
    }
    return cpu;
}

test "programme : HALT atteint, PC final, cycles et nombre d'instructions" {
    var rom = makeRom();
    var cpu = lc86k.Cpu.init(&rom);

    var cycles: u32 = 0;
    var pas: u32 = 0;
    while (!cpu.halted and pas < 10_000) : (pas += 1) {
        cycles += lc86k.step(&cpu);
    }

    // Le programme se termine bien par SET1 PCON,0
    try testing.expect(cpu.halted);
    try testing.expectEqual(adresse_apres_halt, cpu.pc);
    // Aucune interruption ne doit avoir détourné le flux (vecteurs intacts)
    try testing.expectEqual(@as(u8, 0), cpu.interrupt_depth);
    try testing.expectEqual(instructions_attendues, pas);
    try testing.expectEqual(cycles_attendus, cycles);
    // La pile est revenue à sa valeur initiale après CALL/RET + PUSH/POP
    try testing.expectEqual(@as(u8, 0x7F), cpu.sp);
}

test "programme : résultats calculés en RAM" {
    var rom = makeRom();
    const cpu = executer(&rom);

    // Somme 16 bits de la table : 12h+34h+56h+78h+9Ah+BCh+DEh+F0h = 0438h
    try testing.expectEqual(@as(u8, 0x38), cpu.ram_bank0[0x30]);
    try testing.expectEqual(@as(u8, 0x04), cpu.ram_bank0[0x31]);
    // XOR en cascade : 12h^34h^56h^78h^9Ah^BCh^DEh^F0h = 00h
    try testing.expectEqual(@as(u8, 0x00), cpu.ram_bank0[0x32]);
    // MUL : (002Dh) x 0Ah = 0001C2h → ACC=01h, C=C2h
    try testing.expectEqual(@as(u8, 0x01), cpu.ram_bank0[0x34]);
    try testing.expectEqual(@as(u8, 0xC2), cpu.ram_bank0[0x35]);
    // DIV : 01C2h / 07h → quotient 0040h, reste 02h
    try testing.expectEqual(@as(u8, 0x00), cpu.ram_bank0[0x36]);
    try testing.expectEqual(@as(u8, 0x40), cpu.ram_bank0[0x37]);
    try testing.expectEqual(@as(u8, 0x02), cpu.ram_bank0[0x38]);
    // Le sous-programme de vérification valide les trois contrôles
    try testing.expectEqual(@as(u8, 0x55), cpu.ram_bank0[0x39]);
    // Drapeaux après 78h+9Ah = 112h → ACC=12h, PSW=C0h (CY=1, AC=1)
    try testing.expectEqual(@as(u8, 0x12), cpu.ram_bank0[0x3A]);
    try testing.expectEqual(@as(u8, 0xC0), cpu.ram_bank0[0x3B]);
    // Drapeaux après 80h-01h = 7Fh → ACC=7Fh, PSW=45h (OV=1, AC=1, P=1)
    try testing.expectEqual(@as(u8, 0x7F), cpu.ram_bank0[0x3C]);
    try testing.expectEqual(@as(u8, 0x45), cpu.ram_bank0[0x3D]);
    // La table et le pointeur ne sont pas corrompus
    const table = [_]u8{ 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0 };
    for (table, 0..) |attendu, i| {
        try testing.expectEqual(attendu, cpu.ram_bank0[0x20 + i]);
    }
    try testing.expectEqual(@as(u8, 0x28), cpu.ram_bank0[0x00]); // R0 = fin table
    try testing.expectEqual(@as(u8, 0x00), cpu.ram_bank0[0x08]); // compteur écoulé
    // Trace de la pile : ACC poussé, adresse de retour du CALL
    try testing.expectEqual(@as(u8, 0x04), cpu.ram_bank0[0x80]);
    try expectReturnAddress(cpu);
}

test "programme : état final des registres" {
    var rom = makeRom();
    const cpu = executer(&rom);

    // ACC = PSW relu après le SUB (dernière valeur chargée)
    try testing.expectEqual(@as(u8, 0x45), cpu.a);
    // B = reste du DIV, C = quotient bas du DIV
    try testing.expectEqual(@as(u8, 0x02), cpu.b);
    try testing.expectEqual(@as(u8, 0x40), cpu.c);
    // PSW final : CY=0, AC=1, OV=1, P=1 (issu du SUB 80h-01h)
    try testing.expectEqual(@as(u8, 0x45), @as(u8, @bitCast(cpu.psw)));
    try testing.expect(cpu.psw.ac);
    try testing.expect(cpu.psw.ov);
    try testing.expect(!cpu.psw.cy);
    try testing.expect(cpu.psw.p);
    // SFR PCON bit 0 posé par SET1 PCON,0
    try testing.expect(cpu.halted);
    try testing.expectEqual(@as(u8, 0x01), cpu.sfr_raw[0x07]);
}

/// Vérifie l'adresse de retour (0056h) laissée dans la pile par le CALL.
fn expectReturnAddress(cpu: lc86k.Cpu) !void {
    try testing.expectEqual(@as(u8, 0x56), cpu.ram_bank0[0x81]);
    try testing.expectEqual(@as(u8, 0x00), cpu.ram_bank0[0x82]);
}
