//! Metamorphic Testing Suite for Sanyo LC86K87 (Dreamcast VMU CPU core).
//!
//! Cet ensemble de tests implémente le paradigme du Test Métamorphique (Metamorphic Testing)
//! pour valider la fidélité de l'émulateur CPU sans recours à un oracle matériel physique.
//! Chaque test évalue une Relation Métamorphique (MR) algébrique, logique ou temporelle.

const std = @import("std");
const testing = std.testing;
const lc86k = @import("lc86K");
const Cpu = lc86k.Cpu;
const step = @import("decode").step;

fn makeCpu(rom: []u8) Cpu {
    @memset(rom, 0);
    return Cpu.init(rom);
}

// ─────────────────────────────────────────────────────────────────────────────
// MR1 : Inversibilité Algébrique (ADD A, #k puis SUB A, #k)
// Propriété : Pour tout A0 et tout k, (A0 + k) - k = A0 mod 256.
//             Le registre A et le drapeau de parité PSW.P doivent être restaurés.
// ─────────────────────────────────────────────────────────────────────────────
test "MR1: Invertibility - ADD #k then SUB #k preserves A and PSW.p across domain" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    // Code : ADD A, #k ; SUB A, #k ; NOP
    rom[0] = 0x81; // ADD imm
    rom[1] = 0x00; // k (sera patché)
    rom[2] = 0xA1; // SUB imm
    rom[3] = 0x00; // k (sera patché)
    rom[4] = 0x00; // NOP

    // Échantillonnage représentatif du domaine (256 valeurs de A x 64 valeurs de k)
    var a_val: u16 = 0;
    while (a_val <= 255) : (a_val += 1) {
        var k_val: u16 = 0;
        while (k_val <= 255) : (k_val += 4) {
            rom[1] = @truncate(k_val);
            rom[3] = @truncate(k_val);

            cpu.a = @truncate(a_val);
            cpu.pc = 0;
            cpu.psw.p = @popCount(cpu.a) % 2 == 1;

            const initial_p = cpu.psw.p;

            _ = step(&cpu); // ADD
            _ = step(&cpu); // SUB

            try testing.expectEqual(@as(u8, @truncate(a_val)), cpu.a);
            try testing.expectEqual(initial_p, cpu.psw.p);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR2 : Commutativité de l'Accumulation (ADD #k1, ADD #k2 == ADD #k2, ADD #k1)
// Propriété : L'ordre d'addition de deux constantes immédiates ne doit pas modifier
//             la valeur finale de l'accumulateur A ni la parité finale.
// ─────────────────────────────────────────────────────────────────────────────
test "MR2: Commutativity - ADD #k1, ADD #k2 vs ADD #k2, ADD #k1" {
    var rom1: [65536]u8 = undefined;
    var rom2: [65536]u8 = undefined;

    var prng = std.Random.DefaultPrng.init(0x1998_11_27); // Date de sortie Dreamcast au Japon
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 500) : (iter += 1) {
        const a_init = rand.int(u8);
        const k1 = rand.int(u8);
        const k2 = rand.int(u8);

        // Branche 1 : k1 puis k2
        var cpu1 = makeCpu(&rom1);
        rom1[0] = 0x81; rom1[1] = k1;
        rom1[2] = 0x81; rom1[3] = k2;
        cpu1.a = a_init;
        cpu1.pc = 0;
        _ = step(&cpu1);
        _ = step(&cpu1);

        // Branche 2 : k2 puis k1
        var cpu2 = makeCpu(&rom2);
        rom2[0] = 0x81; rom2[1] = k2;
        rom2[2] = 0x81; rom2[3] = k1;
        cpu2.a = a_init;
        cpu2.pc = 0;
        _ = step(&cpu2);
        _ = step(&cpu2);

        try testing.expectEqual(cpu1.a, cpu2.a);
        try testing.expectEqual(cpu1.psw.p, cpu2.psw.p);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR3 : Invariance Involutive du XOR (XOR #k appliqué 2 fois)
// Propriété : Pour tout A0 et masque k, (A0 ^ k) ^ k = A0.
// ─────────────────────────────────────────────────────────────────────────────
test "MR3: Involutory Idempotence - Double XOR #k restores exact accumulator" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0xF1; // XOR imm
    rom[1] = 0x00; // patché
    rom[2] = 0xF1; // XOR imm
    rom[3] = 0x00; // patché

    var prng = std.Random.DefaultPrng.init(0xCAFE_BABE);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 1000) : (iter += 1) {
        const a_init = rand.int(u8);
        const mask = rand.int(u8);

        rom[1] = mask;
        rom[3] = mask;

        cpu.a = a_init;
        cpu.pc = 0;
        cpu.psw.p = @popCount(a_init) % 2 == 1;
        const initial_p = cpu.psw.p;

        _ = step(&cpu);
        _ = step(&cpu);

        try testing.expectEqual(a_init, cpu.a);
        try testing.expectEqual(initial_p, cpu.psw.p);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR4 : Commutativité des Opérations Logiques (AND, OR, XOR)
// ─────────────────────────────────────────────────────────────────────────────
test "MR4: Logic Commutativity - AND/OR/XOR sequence invariance" {
    var rom1: [65536]u8 = undefined;
    var rom2: [65536]u8 = undefined;

    var prng = std.Random.DefaultPrng.init(0x1234_5678);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 300) : (iter += 1) {
        const a_init = rand.int(u8);
        const m1 = rand.int(u8);
        const m2 = rand.int(u8);

        // Test AND (0xE1)
        {
            var cpu1 = makeCpu(&rom1);
            rom1[0] = 0xE1; rom1[1] = m1;
            rom1[2] = 0xE1; rom1[3] = m2;
            cpu1.a = a_init; cpu1.pc = 0;
            _ = step(&cpu1); _ = step(&cpu1);

            var cpu2 = makeCpu(&rom2);
            rom2[0] = 0xE1; rom2[1] = m2;
            rom2[2] = 0xE1; rom2[3] = m1;
            cpu2.a = a_init; cpu2.pc = 0;
            _ = step(&cpu2); _ = step(&cpu2);

            try testing.expectEqual(cpu1.a, cpu2.a);
        }

        // Test OR (0xD1)
        {
            var cpu1 = makeCpu(&rom1);
            rom1[0] = 0xD1; rom1[1] = m1;
            rom1[2] = 0xD1; rom1[3] = m2;
            cpu1.a = a_init; cpu1.pc = 0;
            _ = step(&cpu1); _ = step(&cpu1);

            var cpu2 = makeCpu(&rom2);
            rom2[0] = 0xD1; rom2[1] = m2;
            rom2[2] = 0xD1; rom2[3] = m1;
            cpu2.a = a_init; cpu2.pc = 0;
            _ = step(&cpu2); _ = step(&cpu2);

            try testing.expectEqual(cpu1.a, cpu2.a);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR5 : Invariance Involutive de Manipulation de Bits (NOT1 appliqué 2 fois)
// Propriété : NOT1 [d9], b inversé 2 fois sur la même case mémoire restaure la valeur.
// ─────────────────────────────────────────────────────────────────────────────
test "MR5: Bitwise NOT1 twice on direct RAM restores exact memory state" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0xDEAD_BEEF);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 200) : (iter += 1) {
        const bit = rand.intRangeAtMost(u3, 0, 7);
        const ram_addr: u8 = rand.intRangeAtMost(u8, 0x10, 0x50); // zone sûre hors stack
        const initial_val = rand.int(u8);

        cpu.ram_bank0[ram_addr] = initial_val;

        // NOT1 d9, bit : opcode = 0xA8 + bit, suivi de l'adresse d9
        const opcode = 0xA8 | @as(u8, bit);
        rom[0] = opcode;
        rom[1] = ram_addr;
        rom[2] = opcode;
        rom[3] = ram_addr;

        cpu.pc = 0;
        _ = step(&cpu);
        _ = step(&cpu);

        try testing.expectEqual(initial_val, cpu.ram_bank0[ram_addr]);

        // Vérification métamorphique de SET1 (0xE8 | bit) et CLR1 (0xC8 | bit)
        const opcode_set1 = 0xE8 | @as(u8, bit);
        const opcode_clr1 = 0xC8 | @as(u8, bit);
        rom[0] = opcode_set1;
        rom[1] = ram_addr;
        cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(initial_val | (@as(u8, 1) << bit), cpu.ram_bank0[ram_addr]);

        rom[0] = opcode_clr1;
        rom[1] = ram_addr;
        cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(initial_val & ~(@as(u8, 1) << bit), cpu.ram_bank0[ram_addr]);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR6 : Préservation de Pile (PUSH d9 suivi de POP d9_target)
// Propriété : La valeur dépilée est identique à la valeur empilée,
//             et le pointeur de pile SP final est strictement égal au SP initial.
// ─────────────────────────────────────────────────────────────────────────────
test "MR6: Stack Frame Invariance - PUSH then POP preserves SP and transfers data" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x5441_434B); // "TACK"
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 100) : (iter += 1) {
        const src_addr: u8 = rand.intRangeAtMost(u8, 0x10, 0x30);
        const dst_addr: u8 = rand.intRangeAtMost(u8, 0x31, 0x50);
        const test_val = rand.int(u8);
        const initial_sp: u8 = 0x7F;

        cpu.ram_bank0[src_addr] = test_val;
        cpu.ram_bank0[dst_addr] = 0x00;
        cpu.sp = initial_sp;

        // PUSH src_addr (0x60, src_addr)
        // POP dst_addr  (0x70, dst_addr)
        rom[0] = 0x60; rom[1] = src_addr;
        rom[2] = 0x70; rom[3] = dst_addr;

        cpu.pc = 0;
        _ = step(&cpu); // PUSH
        try testing.expectEqual(initial_sp +% 1, cpu.sp);

        _ = step(&cpu); // POP
        try testing.expectEqual(initial_sp, cpu.sp);
        try testing.expectEqual(test_val, cpu.ram_bank0[dst_addr]);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR7 : Périodicité Cyclique des Rotations (8x ROL == identité, 8x ROR == identité)
// Propriété : Effectuer 8 rotations de 1 bit sur un octet restaure l'accumulateur A.
// ─────────────────────────────────────────────────────────────────────────────
test "MR7: Cyclic Rotation Invariance - 8x ROL and 8x ROR restore initial accumulator" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    // 8x ROL (0xE0)
    @memset(rom[0..8], 0xE0);
    // 8x ROR (0xC0)
    @memset(rom[8..16], 0xC0);

    var a_val: u16 = 0;
    while (a_val <= 255) : (a_val += 1) {
        // Test 8x ROL
        cpu.a = @truncate(a_val);
        cpu.pc = 0;
        for (0..8) |_| _ = step(&cpu);
        try testing.expectEqual(@as(u8, @truncate(a_val)), cpu.a);

        // Test 8x ROR
        cpu.a = @truncate(a_val);
        cpu.pc = 8;
        for (0..8) |_| _ = step(&cpu);
        try testing.expectEqual(@as(u8, @truncate(a_val)), cpu.a);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR8 : Invariance de la Somme Temporelle des Cycles
// Propriété : Deux blocs d'instructions aux sémantiques différentes mais
//             ayant la même durée théorique (ex: 4x NOP de 1 cycle vs 2x BR de 2 cycles)
//             doivent consommer exactement la même somme de cycles CPU.
// ─────────────────────────────────────────────────────────────────────────────
test "MR8: Cycle Timing Compositionality - NOPs vs Relative Branches" {
    var rom1: [65536]u8 = undefined;
    var rom2: [65536]u8 = undefined;

    var cpu1 = makeCpu(&rom1);
    var cpu2 = makeCpu(&rom2);

    // Séquence 1 : 4x NOP (Opcode 0x00, 1 cycle chacun = 4 cycles)
    rom1[0] = 0x00;
    rom1[1] = 0x00;
    rom1[2] = 0x00;
    rom1[3] = 0x00;

    // Séquence 2 : 2x BR $+0 (Opcode 0x01, rel=0, 2 cycles chacun = 4 cycles)
    rom2[0] = 0x01; rom2[1] = 0x00;
    rom2[2] = 0x01; rom2[3] = 0x00;

    cpu1.pc = 0;
    var cycles1: u32 = 0;
    for (0..4) |_| {
        cycles1 += step(&cpu1);
    }

    cpu2.pc = 0;
    var cycles2: u32 = 0;
    for (0..2) |_| {
        cycles2 += step(&cpu2);
    }

    try testing.expectEqual(@as(u32, 4), cycles1);
    try testing.expectEqual(@as(u32, 4), cycles2);
    try testing.expectEqual(cycles1, cycles2);
}

// ─────────────────────────────────────────────────────────────────────────────
// MR9 : Éléments Neutres et Absorbants Logiques (Identity & Annihilator Relations)
// Propriété :
//   AND : x AND 0 = 0 (absorbant), x AND 0xFF = x (neutre)
//   OR  : x OR 0 = x (neutre), x OR 0xFF = 0xFF (absorbant)
//   XOR : x XOR 0 = x (neutre), x XOR x = 0 (auto-inverse)
// ─────────────────────────────────────────────────────────────────────────────
test "MR9: Boolean Neutral and Absorbing Element Relations" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var a_val: u16 = 0;
    while (a_val <= 255) : (a_val += 1) {
        const a: u8 = @truncate(a_val);

        // 1. AND avec 0x00 doit donner 0 (élément absorbant)
        rom[0] = 0xE1; rom[1] = 0x00; // AND #0x00
        cpu.a = a; cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(@as(u8, 0x00), cpu.a);

        // 2. AND avec 0xFF doit préserver a (élément neutre)
        rom[0] = 0xE1; rom[1] = 0xFF; // AND #0xFF
        cpu.a = a; cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(a, cpu.a);

        // 3. OR avec 0x00 doit préserver a (élément neutre)
        rom[0] = 0xD1; rom[1] = 0x00; // OR #0x00
        cpu.a = a; cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(a, cpu.a);

        // 4. OR avec 0xFF doit donner 0xFF (élément absorbant)
        rom[0] = 0xD1; rom[1] = 0xFF; // OR #0xFF
        cpu.a = a; cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(@as(u8, 0xFF), cpu.a);

        // 5. XOR avec 0x00 doit préserver a (élément neutre)
        rom[0] = 0xF1; rom[1] = 0x00; // XOR #0x00
        cpu.a = a; cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(a, cpu.a);

        // 6. XOR avec a lui-même doit donner 0 (auto-inverse)
        rom[0] = 0xF1; rom[1] = a; // XOR #a
        cpu.a = a; cpu.pc = 0;
        _ = step(&cpu);
        try testing.expectEqual(@as(u8, 0x00), cpu.a);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR10 : Partition et Invariants Frontières des Drapeaux Arithmétiques ADD (CY, AC, P)
// Propriété :
//   CY == true  <=> A + K > 255
//   AC == true  <=> (A & 0xF) + (K & 0xF) > 0xF
//   P == true   <=> popCount(result) % 2 == 1
// ─────────────────────────────────────────────────────────────────────────────
test "MR10: Arithmetic Flag Partition Invariance - ADD (CY, AC, P)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0x81; // ADD imm
    rom[1] = 0x00; // patché

    var a_val: u16 = 0;
    while (a_val <= 255) : (a_val += 7) {
        var k_val: u16 = 0;
        while (k_val <= 255) : (k_val += 7) {
            const a: u8 = @truncate(a_val);
            const k: u8 = @truncate(k_val);
            rom[1] = k;

            cpu.a = a;
            cpu.pc = 0;
            _ = step(&cpu);

            const expected_sum: u16 = @as(u16, a) + @as(u16, k);
            const expected_cy = expected_sum > 0xFF;
            const expected_ac = (a & 0xF) + (k & 0xF) > 0xF;
            const expected_ov = (@as(u1, @truncate(a >> 7)) == @as(u1, @truncate(k >> 7))) and
                (@as(u1, @truncate(a >> 7)) != @as(u1, @truncate(cpu.a >> 7)));
            const expected_p = @popCount(cpu.a) % 2 == 1;

            try testing.expectEqual(expected_cy, cpu.psw.cy);
            try testing.expectEqual(expected_ac, cpu.psw.ac);
            try testing.expectEqual(expected_ov, cpu.psw.ov);
            try testing.expectEqual(expected_p, cpu.psw.p);
        }
    }

    // Cas frontières critiques : 255 + 0 (somme = 255, pas de débordement)
    rom[1] = 0x00;
    cpu.a = 0xFF;
    cpu.pc = 0;
    _ = step(&cpu);
    try testing.expect(!cpu.psw.cy);

    // Cas frontière AC : 0x0F + 0x00 (pas de half-carry)
    rom[1] = 0x00;
    cpu.a = 0x0F;
    cpu.pc = 0;
    _ = step(&cpu);
    try testing.expect(!cpu.psw.ac);
}

// ─────────────────────────────────────────────────────────────────────────────
// MR11 : Partition et Invariants Frontières des Drapeaux Arithmétiques SUB (CY, AC, P)
// Propriété :
//   CY == true  <=> A < K
//   AC == true  <=> (A & 0xF) < (K & 0xF)
//   P == true   <=> popCount(result) % 2 == 1
// ─────────────────────────────────────────────────────────────────────────────
test "MR11: Arithmetic Flag Partition Invariance - SUB (CY, AC, P)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0xA1; // SUB imm
    rom[1] = 0x00; // patché

    var a_val: u16 = 0;
    while (a_val <= 255) : (a_val += 7) {
        var k_val: u16 = 0;
        while (k_val <= 255) : (k_val += 7) {
            const a: u8 = @truncate(a_val);
            const k: u8 = @truncate(k_val);
            rom[1] = k;

            cpu.a = a;
            cpu.pc = 0;
            _ = step(&cpu);

            const expected_cy = a < k;
            const expected_ac = (a & 0xF) < (k & 0xF);
            const expected_p = @popCount(cpu.a) % 2 == 1;

            try testing.expectEqual(expected_cy, cpu.psw.cy);
            try testing.expectEqual(expected_ac, cpu.psw.ac);
            try testing.expectEqual(expected_p, cpu.psw.p);
        }
    }

    // Cas frontières critiques : A == K (résultat = 0, pas d'emprunt)
    rom[1] = 0x42;
    cpu.a = 0x42;
    cpu.pc = 0;
    _ = step(&cpu);
    try testing.expect(!cpu.psw.cy);
    try testing.expect(!cpu.psw.ac);
}

// ─────────────────────────────────────────────────────────────────────────────
// MR12 : Dualité et Complémentarité des Sauts Conditionnels (BZ vs BNZ)
// Propriété :
//   Si A == 0 : BZ prend le saut (PC = PC0 + 2 + signExt(rel)), BNZ continue (PC = PC0 + 2).
//   Si A != 0 : BZ continue (PC = PC0 + 2), BNZ prend le saut (PC = PC0 + 2 + signExt(rel)).
//   Pour tout état, exactement un des deux sauts est pris.
// ─────────────────────────────────────────────────────────────────────────────
test "MR12: Control Flow Duality - Conditional Branching (BZ vs BNZ)" {
    var rom: [65536]u8 = undefined;
    var cpu1 = makeCpu(&rom);
    var cpu2 = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1998_12_23);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 200) : (iter += 1) {
        const offset = rand.int(u8);
        const pc_start: u16 = rand.intRangeAtMost(u16, 0x1000, 0x5000);
        const rel_i16 = @as(i16, @as(i8, @bitCast(offset)));
        const target_taken: u16 = @bitCast(@as(i16, @bitCast(pc_start + 2)) +% rel_i16);
        const target_not_taken: u16 = pc_start + 2;

        rom[pc_start] = 0x80; // BZ
        rom[pc_start + 1] = offset;

        // Cas 1 : A == 0 -> BZ pris, BNZ non pris
        cpu1.pc = pc_start;
        cpu1.a = 0;
        _ = step(&cpu1);

        rom[pc_start] = 0x90; // BNZ
        cpu2.pc = pc_start;
        cpu2.a = 0;
        _ = step(&cpu2);

        try testing.expectEqual(target_taken, cpu1.pc);
        try testing.expectEqual(target_not_taken, cpu2.pc);

        // Cas 2 : A != 0 -> BZ non pris, BNZ pris
        const non_zero_a = rand.intRangeAtMost(u8, 1, 255);
        rom[pc_start] = 0x80; // BZ
        cpu1.pc = pc_start;
        cpu1.a = non_zero_a;
        _ = step(&cpu1);

        rom[pc_start] = 0x90; // BNZ
        cpu2.pc = pc_start;
        cpu2.a = non_zero_a;
        _ = step(&cpu2);

        try testing.expectEqual(target_not_taken, cpu1.pc);
        try testing.expectEqual(target_taken, cpu2.pc);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR13 : Isomorphisme et Isolation de Banque RAM (RAMBK0 Translation Invariance)
// Propriété :
//   Une écriture en banque 0 (RAMBK0=false) n'altère pas la banque 1 (isolation).
//   L'incrémentation/décrémentation en banque 0 et banque 1 sont strictement isomorphes.
// ─────────────────────────────────────────────────────────────────────────────
test "MR13: Memory Bank Isolation and Isomorphism (RAMBK0 Invariance)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1999_07_07);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 100) : (iter += 1) {
        const addr: u8 = rand.int(u8);
        const val0: u8 = rand.int(u8);
        const val1: u8 = rand.int(u8);

        // Écrire val0 en banque 0
        cpu.psw.rambk0 = false;
        cpu.store8(addr, val0);

        // Écrire val1 en banque 1
        cpu.psw.rambk0 = true;
        cpu.store8(addr, val1);

        // Vérifier l'isolation stricte
        cpu.psw.rambk0 = false;
        try testing.expectEqual(val0, cpu.load8(addr));

        cpu.psw.rambk0 = true;
        try testing.expectEqual(val1, cpu.load8(addr));
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR14 : Périodicité d'Ordre 9 sur ROLC et RORC (Involutivité de l'anneau à 9 bits)
// Propriété :
//   (ROLC)^9 (A, CY) == (A, CY)
//   (RORC)^9 (A, CY) == (A, CY)
//   ROLC(RORC(A, CY)) == (A, CY)
// ─────────────────────────────────────────────────────────────────────────────
test "MR14: 9-bit Periodicity and Inversibility - ROLC / RORC" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1999_08_08);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 100) : (iter += 1) {
        const a_orig = rand.int(u8);
        const cy_orig = rand.boolean();

        // 1. Neuf fois ROLC (0xF0)
        rom[0] = 0xF0;
        cpu.a = a_orig;
        cpu.psw.cy = cy_orig;
        for (0..9) |_| {
            cpu.pc = 0;
            _ = step(&cpu);
        }
        try testing.expectEqual(a_orig, cpu.a);
        try testing.expectEqual(cy_orig, cpu.psw.cy);

        // 2. Neuf fois RORC (0xD0)
        rom[0] = 0xD0;
        cpu.a = a_orig;
        cpu.psw.cy = cy_orig;
        for (0..9) |_| {
            cpu.pc = 0;
            _ = step(&cpu);
        }
        try testing.expectEqual(a_orig, cpu.a);
        try testing.expectEqual(cy_orig, cpu.psw.cy);

        // 3. ROLC suivi de RORC = Identité
        rom[0] = 0xF0;
        rom[1] = 0xD0;
        cpu.a = a_orig;
        cpu.psw.cy = cy_orig;
        cpu.pc = 0;
        _ = step(&cpu);
        _ = step(&cpu);
        try testing.expectEqual(a_orig, cpu.a);
        try testing.expectEqual(cy_orig, cpu.psw.cy);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR15 : Inversibilité et Préservation de Parité Arithmétique (INC / DEC)
// Propriété :
//   1. INC(mem) suivi de DEC(mem) restaure la valeur originale en mémoire (Identité).
//   2. Invariance de parité : INC(mem) et DEC(mem) ne modifient pas le bit de parité PSW.P
//      (qui est réservé matériellement à la parité de l'accumulateur ACC).
// ─────────────────────────────────────────────────────────────────────────────
test "MR15: Incrementation/Decrementation Invariance and Parity Flag (INC / DEC)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1999_09_09);
    const rand = prng.random();

    var iter: usize = 0;
    while (iter < 100) : (iter += 1) {
        const ram_addr: u8 = rand.intRangeAtMost(u8, 0x10, 0x50);
        const initial_val = rand.int(u8);
        const psw_p_before = rand.boolean();
        cpu.psw.p = psw_p_before;

        cpu.ram_bank0[ram_addr] = initial_val;

        // 1. INC d9 (0x62)
        rom[0] = 0x62;
        rom[1] = ram_addr;
        cpu.pc = 0;
        _ = step(&cpu);

        const after_inc = initial_val +% 1;
        try testing.expectEqual(after_inc, cpu.ram_bank0[ram_addr]);
        // Le bit PSW.P doit rester invariant (non altéré par les opérations mémoire)
        try testing.expectEqual(psw_p_before, cpu.psw.p);

        // 2. DEC d9 (0x72) : Restaure la valeur originale
        rom[0] = 0x72;
        rom[1] = ram_addr;
        cpu.pc = 0;
        _ = step(&cpu);

        try testing.expectEqual(initial_val, cpu.ram_bank0[ram_addr]);
        try testing.expectEqual(psw_p_before, cpu.psw.p);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR16 : Invariance Euclidienne de la Division et Involutivité Compositionnelle (DIV / MUL)
// Propriétés :
//   1. Invariance euclidienne : pour tout dividende 16 bits N = (A0 << 8) | C0 et tout diviseur 8 bits B0 != 0,
//      DIV produit Quotient Q = (A << 8) | C et Reste R = B tels que :
//      Q * B0 + R == N  avec  R < B0, PSW.ov == false, PSW.cy == false.
//   2. Division par zéro (condition limite) : si B0 == 0,
//      DIV produit A == 0xFF, PSW.ov == true, PSW.cy == false.
//   3. Involutivité compositionnelle DIV o MUL (quand produit <= 0xFFFF) :
//      Pour tout N0 <= 0xFFFF / K (avec K in [1, 255]),
//      MUL(N0, K) suivi de DIV(P, K) restaure strictement N0 avec Reste == 0.
//   4. Débordement de multiplication : si N0 * B0 > 0xFFFF,
//      MUL produit B = result >> 16, A = (result >> 8) & 0xFF, C = result & 0xFF et PSW.ov == true.
// ─────────────────────────────────────────────────────────────────────────────
test "MR16: Euclidean Division Invariance and Multiplication Composition (DIV / MUL)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1999_10_10);
    const rand = prng.random();

    // 1. Invariance Euclidienne de DIV sur des entrées aléatoires
    rom[0] = 0x40; // DIV (1 octet, 7 cycles)
    var iter: usize = 0;
    while (iter < 200) : (iter += 1) {
        const a_orig = rand.int(u8);
        const c_orig = rand.int(u8);
        const b_orig = rand.intRangeAtMost(u8, 1, 255); // Non nul

        const dividend: u16 = (@as(u16, a_orig) << 8) | @as(u16, c_orig);

        cpu.a = a_orig;
        cpu.c = c_orig;
        cpu.b = b_orig;
        cpu.psw.ov = rand.boolean();
        cpu.psw.cy = rand.boolean();
        cpu.pc = 0;

        _ = step(&cpu);

        const quotient: u16 = (@as(u16, cpu.a) << 8) | @as(u16, cpu.c);
        const remainder: u8 = cpu.b;

        // Invariants euclidiens
        try testing.expectEqual(dividend, quotient *% @as(u16, b_orig) +% @as(u16, remainder));
        try testing.expect(remainder < b_orig);
        try testing.expect(!cpu.psw.ov);
        try testing.expect(!cpu.psw.cy);
    }

    // 2. Comportement frontière : Division par zéro
    for (0..20) |_| {
        cpu.a = rand.int(u8);
        cpu.c = rand.int(u8);
        cpu.b = 0;
        cpu.psw.ov = false;
        cpu.psw.cy = true;
        cpu.pc = 0;

        _ = step(&cpu);

        try testing.expectEqual(@as(u8, 0xFF), cpu.a);
        try testing.expect(cpu.psw.ov);
        try testing.expect(!cpu.psw.cy);
    }

    // 3. Involutivité compositionnelle DIV o MUL (quand produit <= 0xFFFF)
    // rom[0] = 0x30 (MUL), rom[1] = 0x40 (DIV)
    rom[0] = 0x30;
    rom[1] = 0x40;

    iter = 0;
    while (iter < 100) : (iter += 1) {
        const k: u8 = rand.intRangeAtMost(u8, 1, 255);
        const max_n: u16 = @intCast(@as(u32, 0xFFFF) / k);
        const n0: u16 = if (max_n > 0) rand.intRangeAtMost(u16, 0, max_n) else 0;

        // Configuration pour MUL : (A:C) * B
        cpu.a = @truncate(n0 >> 8);
        cpu.c = @truncate(n0);
        cpu.b = k;
        cpu.pc = 0;

        _ = step(&cpu); // MUL : Résultat dans (B:A:C)

        try testing.expectEqual(@as(u8, 0), cpu.b); // Pas de débordement 16-bit
        try testing.expect(!cpu.psw.ov);

        // Préparation pour DIV : diviseur dans B
        cpu.b = k;
        _ = step(&cpu); // DIV : (A:C) / B -> (A:C), reste dans B

        const recovered_n: u16 = (@as(u16, cpu.a) << 8) | @as(u16, cpu.c);
        try testing.expectEqual(n0, recovered_n);
        try testing.expectEqual(@as(u8, 0), cpu.b); // Reste nul
        try testing.expect(!cpu.psw.ov);
        try testing.expect(!cpu.psw.cy);
    }

    // 4. Débordement sur Multiplication 24 bits (P > 0xFFFF)
    rom[0] = 0x30; // MUL
    iter = 0;
    while (iter < 50) : (iter += 1) {
        const n0: u16 = rand.intRangeAtMost(u16, 0x1000, 0xFFFF);
        const b0: u8 = rand.intRangeAtMost(u8, 16, 255);
        const expected_prod: u24 = @as(u24, n0) * @as(u24, b0);

        cpu.a = @truncate(n0 >> 8);
        cpu.c = @truncate(n0);
        cpu.b = b0;
        cpu.pc = 0;

        _ = step(&cpu);

        const actual_prod: u24 = (@as(u24, cpu.b) << 16) | (@as(u24, cpu.a) << 8) | @as(u24, cpu.c);
        try testing.expectEqual(expected_prod, actual_prod);
        try testing.expectEqual(expected_prod > 0xFFFF, cpu.psw.ov);
        try testing.expect(!cpu.psw.cy);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR17 : Masquage d'Interruption et Préservation de Contexte RETI (IE / RETI)
// Propriétés :
//   1. Invariance négative de masquage : quand IE.7 == 0 (interruptions globalement masquées),
//      la présence de requêtes d'interruption (T0LOVF | T0LIE) n'altère ni SP ni PC
//      (l'exécution se poursuit séquentiellement).
//   2. Cycle complet d'interruption et involution RETI : quand IE.7 == 1,
//      le déclenchement d'une IRQ empile l'adresse de retour (SP += 2), positionne
//      interrupt_depth = 1 et déroute le PC vers le vecteur prescrit (0x0013 pour Timer 0L).
//      L'exécution ultérieure de RETI (0xB0) restaure strictement PC, SP, l'état
//      interrupt_depth = 0 et la banque mémoire d'origine.
// ─────────────────────────────────────────────────────────────────────────────
test "MR17: Interrupt Context Masking and Frame Restoration Invariance (IE / RETI)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1999_11_11);
    const rand = prng.random();

    // 1. Masquage global (IE.7 = 0) : Aucune déviation de flot de contrôle
    var iter: usize = 0;
    while (iter < 50) : (iter += 1) {
        const start_pc: u16 = rand.intRangeAtMost(u16, 0x0200, 0x0500);
        const start_sp: u8 = rand.intRangeAtMost(u8, 0x60, 0x7E);

        // Placer un NOP à start_pc
        rom[start_pc] = 0x00; // NOP

        cpu.pc = start_pc;
        cpu.sp = start_sp;
        cpu.interrupt_depth = 0;

        // Désactiver IE (bit 7 = 0) et poser le flag d'interruption Timer 0L
        cpu.sfr_raw[Cpu.SFR_IE] = 0x00;
        cpu.sfr_raw[Cpu.SFR_T0CNT] = Cpu.T0CNT_T0LOVF | Cpu.T0CNT_T0LIE;

        _ = step(&cpu);

        // L'interruption n'a pas été servie : PC a avancé de 1 (NOP), SP inchangé, depth inchangé
        try testing.expectEqual(start_pc + 1, cpu.pc);
        try testing.expectEqual(start_sp, cpu.sp);
        try testing.expectEqual(@as(u8, 0), cpu.interrupt_depth);
    }

    // 2. Dispatch et Restauration exacte via RETI (IE.7 = 1)
    // Placer un RETI (0xB0) au vecteur de Timer 0L (0x0013)
    rom[0x0013] = 0xB0; // RETI

    iter = 0;
    while (iter < 50) : (iter += 1) {
        const start_pc: u16 = rand.intRangeAtMost(u16, 0x0200, 0x0500);
        const start_sp: u8 = rand.intRangeAtMost(u8, 0x60, 0x7E);

        // Instruction témoin : NOP à start_pc
        rom[start_pc] = 0x00; // NOP (taille 1)
        const expected_return_pc = start_pc + 1;

        cpu.pc = start_pc;
        cpu.sp = start_sp;
        cpu.interrupt_depth = 0;
        cpu.process_this_instr = true;

        // Activer IE (bit 7 = 1) et armer l'interruption Timer 0L
        cpu.sfr_raw[Cpu.SFR_IE] = 0x80;
        cpu.sfr_raw[Cpu.SFR_T0CNT] = Cpu.T0CNT_T0LOVF | Cpu.T0CNT_T0LIE;

        // Étape 1 : Exécution du NOP, détection de l'interruption en fin de step, dispatch vers 0x0013
        _ = step(&cpu);

        try testing.expectEqual(@as(u16, 0x0013), cpu.pc);
        try testing.expectEqual(start_sp +% 2, cpu.sp);
        try testing.expectEqual(@as(u8, 1), cpu.interrupt_depth);

        // Vérifier que l'adresse de retour empilée est bien expected_return_pc
        const popped_hi = cpu.ram_bank0[cpu.sp];
        const popped_lo = cpu.ram_bank0[cpu.sp - 1];
        const stacked_pc = (@as(u16, popped_hi) << 8) | @as(u16, popped_lo);
        try testing.expectEqual(expected_return_pc, stacked_pc);

        // Étape 2 : Exécution de RETI au vecteur 0x0013
        _ = step(&cpu);

        // RETI doit restaurer le PC de retour, le SP initial, et remettre interrupt_depth à 0
        try testing.expectEqual(expected_return_pc, cpu.pc);
        try testing.expectEqual(start_sp, cpu.sp);
        try testing.expectEqual(@as(u8, 0), cpu.interrupt_depth);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MR18 : Isolation et Commutation des Banques de Registres Indirects (IRBK0/1 & @R0..@R3)
// Propriétés :
//   1. Isolation des 4 banques de registres indirects :
//      Pour b in [0..3], IRBK sélectionne 4 pointeurs situés en RAM bank 0 aux adresses [4*b .. 4*b + 3].
//      Une écriture ou lecture indirecte (@R0) dans la banque b n'interagit qu'avec la cible
//      pointée par ram_bank0[4*b], sans modifier ni interférer avec les cibles des banques b' != b.
//   2. Invariance d'équivalence d'adressage direct / indirect :
//      Pour toute banque b, LD A, @Rj lit exactement la même valeur mémoire que LD A, d9
//      où d9 correspond à l'adresse calculée par le pointeur de banque.
// ─────────────────────────────────────────────────────────────────────────────
test "MR18: Indirect Register Banks Isolation and Commutative Addressing (IRBK0/1 & @R0..@R3)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var prng = std.Random.DefaultPrng.init(0x1999_12_12);
    const rand = prng.random();

    // Code ROM :
    // rom[0] = 0x04 : LD A, @R0 (op_ri ri=0)
    // rom[1] = 0x14 : ST A, @R0 (op_ri ri=0)
    rom[0] = 0x04; // LD A, @R0
    rom[1] = 0x14; // ST A, @R0

    var iter: usize = 0;
    while (iter < 50) : (iter += 1) {
        // 4 cellules RAM cibles disjointes pour les 4 banques (plage 0x40..0x7F)
        const target_cells = [4]u8{ 0x40, 0x50, 0x60, 0x70 };
        var cell_values: [4]u8 = undefined;

        // Initialisation de chaque banque b (0..3) :
        // Le registre @R0 de la banque b est stocké à l'adresse RAM 4*b
        for (0..4) |b| {
            const ptr_addr = @as(u8, @intCast(b * 4));
            cpu.ram_bank0[ptr_addr] = target_cells[b]; // @R0 pointe vers target_cells[b]
            cell_values[b] = rand.int(u8);
            cpu.ram_bank0[target_cells[b]] = cell_values[b]; // Valeur initiale dans la cellule cible
        }

        // 1. Vérification de lecture isolée : pour chaque banque b, LD A, @R0 lit bien cell_values[b]
        for (0..4) |b| {
            cpu.psw.irbk0 = (b & 1) != 0;
            cpu.psw.irbk1 = (b & 2) != 0;
            cpu.pc = 0; // Exécute LD A, @R0

            _ = step(&cpu);

            try testing.expectEqual(cell_values[b], cpu.a);
        }

        // 2. Vérification d'écriture isolée : écrire dans la banque b n'altère aucune autre cellule cible
        for (0..4) |b| {
            cpu.psw.irbk0 = (b & 1) != 0;
            cpu.psw.irbk1 = (b & 2) != 0;

            const new_val = cell_values[b] ^ 0xAA;
            cpu.a = new_val;
            cpu.pc = 1; // Exécute ST A, @R0

            _ = step(&cpu);

            // Vérifier que la cellule cible de la banque b est mise à jour
            try testing.expectEqual(new_val, cpu.ram_bank0[target_cells[b]]);

            // Vérifier que toutes les autres banques b' != b sont strictement inchangées
            for (0..4) |other_b| {
                if (other_b != b) {
                    try testing.expectEqual(cell_values[other_b], cpu.ram_bank0[target_cells[other_b]]);
                }
            }

            // Restaurer pour le prochain tour
            cell_values[b] = new_val;
        }

        // 3. Équivalence stricte avec adressage direct d9
        // rom[2..3] = 0x02, target_cells[0] : LD A, d9 (opcode 0x02)
        rom[2] = 0x02; // LD A, d9
        rom[3] = target_cells[0];

        // Lecture indirecte via banque 0
        cpu.psw.irbk0 = false;
        cpu.psw.irbk1 = false;
        cpu.pc = 0;
        _ = step(&cpu);
        const indirect_val = cpu.a;

        // Lecture directe via d9
        cpu.pc = 2;
        _ = step(&cpu);
        const direct_val = cpu.a;

        try testing.expectEqual(indirect_val, direct_val);
    }
}


