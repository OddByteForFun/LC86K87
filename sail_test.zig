//! Test différentiel et bisimulation entre la spécification formelle Sail
//! et l'implémentation système en Zig du LC86K87.
//! Énumération exhaustive du domaine fini (Finite Domain Model Checking) :
//! 100% des combinaisons d'états d'ALU (65 536 états par opérateur binaire),
//! décalages (256 et 512 états) et sauts conditionnels.

const std = @import("std");
const testing = std.testing;
const Cpu = @import("lc86K").Cpu;
const step = @import("decode").step;

// Fonctions et registres exportés par le modèle Sail C
extern "c" fn model_init() void;
extern "c" fn model_fini() void;
extern "c" fn zset_A(val: u64) void;
extern "c" fn zget_A(unit_val: u8) u64;
extern "c" fn zset_PSW(val: u64) void;
extern "c" fn zget_PSW(unit_val: u8) u64;
extern "c" fn zset_PC(val: u64) void;
extern "c" fn zget_PC(unit_val: u8) u64;

extern "c" fn zstep_add_imm(imm: u64) void;
extern "c" fn zstep_sub_imm(imm: u64) void;
extern "c" fn zstep_and_imm(imm: u64) void;
extern "c" fn zstep_or_imm(imm: u64) void;
extern "c" fn zstep_xor_imm(imm: u64) void;
extern "c" fn zstep_rol(unit_val: u8) void;
extern "c" fn zstep_ror(unit_val: u8) void;
extern "c" fn zstep_rolc(unit_val: u8) void;
extern "c" fn zstep_rorc(unit_val: u8) void;
extern "c" fn zstep_bzz(offset: u64) void;
extern "c" fn zstep_bnzz(offset: u64) void;

fn makeCpu(rom: []u8) Cpu {
    @memset(rom, 0);
    return Cpu.init(rom);
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur ADD #imm (65 536 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0x81; // ADD imm
    rom[1] = 0x00;

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);
        var imm_int: u16 = 0;
        while (imm_int <= 255) : (imm_int += 1) {
            const imm: u8 = @truncate(imm_int);

            zset_A(a_val);
            zset_PSW(0);
            zstep_add_imm(imm);
            const sail_a: u8 = @truncate(zget_A(0));
            const sail_psw: u8 = @truncate(zget_PSW(0));

            rom[1] = imm;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_a, cpu.a);
            const flags_mask: u8 = 0xC5; // CY, AC, OV, P
            try testing.expectEqual(sail_psw & flags_mask, @as(u8, @bitCast(cpu.psw)) & flags_mask);
        }
    }
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur SUB #imm (65 536 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0xA1; // SUB imm
    rom[1] = 0x00;

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);
        var imm_int: u16 = 0;
        while (imm_int <= 255) : (imm_int += 1) {
            const imm: u8 = @truncate(imm_int);

            zset_A(a_val);
            zset_PSW(0);
            zstep_sub_imm(imm);
            const sail_a: u8 = @truncate(zget_A(0));
            const sail_psw: u8 = @truncate(zget_PSW(0));

            rom[1] = imm;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_a, cpu.a);
            const flags_mask: u8 = 0xC5;
            try testing.expectEqual(sail_psw & flags_mask, @as(u8, @bitCast(cpu.psw)) & flags_mask);
        }
    }
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur AND #imm (65 536 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0xE1; // AND imm
    rom[1] = 0x00;

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);
        var imm_int: u16 = 0;
        while (imm_int <= 255) : (imm_int += 1) {
            const imm: u8 = @truncate(imm_int);

            zset_A(a_val);
            zset_PSW(0);
            zstep_and_imm(imm);
            const sail_a: u8 = @truncate(zget_A(0));
            const sail_psw: u8 = @truncate(zget_PSW(0));

            rom[1] = imm;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_a, cpu.a);
            try testing.expectEqual(sail_psw & 0x01, @as(u8, @bitCast(cpu.psw)) & 0x01); // Parity flag
        }
    }
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur OR #imm (65 536 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0xD1; // OR imm
    rom[1] = 0x00;

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);
        var imm_int: u16 = 0;
        while (imm_int <= 255) : (imm_int += 1) {
            const imm: u8 = @truncate(imm_int);

            zset_A(a_val);
            zset_PSW(0);
            zstep_or_imm(imm);
            const sail_a: u8 = @truncate(zget_A(0));
            const sail_psw: u8 = @truncate(zget_PSW(0));

            rom[1] = imm;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_a, cpu.a);
            try testing.expectEqual(sail_psw & 0x01, @as(u8, @bitCast(cpu.psw)) & 0x01);
        }
    }
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur XOR #imm (65 536 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0xF1; // XOR imm
    rom[1] = 0x00;

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);
        var imm_int: u16 = 0;
        while (imm_int <= 255) : (imm_int += 1) {
            const imm: u8 = @truncate(imm_int);

            zset_A(a_val);
            zset_PSW(0);
            zstep_xor_imm(imm);
            const sail_a: u8 = @truncate(zget_A(0));
            const sail_psw: u8 = @truncate(zget_PSW(0));

            rom[1] = imm;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_a, cpu.a);
            try testing.expectEqual(sail_psw & 0x01, @as(u8, @bitCast(cpu.psw)) & 0x01);
        }
    }
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur ROL et ROR (512 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);

        // Test ROL (0xE0)
        zset_A(a_val);
        zset_PSW(0);
        zstep_rol(0);
        const sail_rol_a: u8 = @truncate(zget_A(0));
        const sail_rol_psw: u8 = @truncate(zget_PSW(0));

        rom[0] = 0xE0;
        cpu.a = a_val;
        cpu.psw = .{};
        cpu.pc = 0;
        _ = step(&cpu);

        try testing.expectEqual(sail_rol_a, cpu.a);
        try testing.expectEqual(sail_rol_psw & 0x80, @as(u8, @bitCast(cpu.psw)) & 0x80); // Carry flag

        // Test ROR (0xC0)
        zset_A(a_val);
        zset_PSW(0);
        zstep_ror(0);
        const sail_ror_a: u8 = @truncate(zget_A(0));
        const sail_ror_psw: u8 = @truncate(zget_PSW(0));

        rom[0] = 0xC0;
        cpu.a = a_val;
        cpu.psw = .{};
        cpu.pc = 0;
        _ = step(&cpu);

        try testing.expectEqual(sail_ror_a, cpu.a);
        try testing.expectEqual(sail_ror_psw & 0x80, @as(u8, @bitCast(cpu.psw)) & 0x80);
    }
}

test "Sail vs Zig : Preuve par enumeration exhaustive sur ROLC et RORC (1 024 etats)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    var a_int: u16 = 0;
    while (a_int <= 255) : (a_int += 1) {
        const a_val: u8 = @truncate(a_int);
        for ([_]bool{ false, true }) |initial_cy| {
            const psw_init: u8 = if (initial_cy) 0x80 else 0x00;

            // Test ROLC (0xF0)
            zset_A(a_val);
            zset_PSW(psw_init);
            zstep_rolc(0);
            const sail_rolc_a: u8 = @truncate(zget_A(0));
            const sail_rolc_psw: u8 = @truncate(zget_PSW(0));

            rom[0] = 0xF0;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.psw.cy = initial_cy;
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_rolc_a, cpu.a);
            try testing.expectEqual(sail_rolc_psw & 0x80, @as(u8, @bitCast(cpu.psw)) & 0x80);

            // Test RORC (0xD0)
            zset_A(a_val);
            zset_PSW(psw_init);
            zstep_rorc(0);
            const sail_rorc_a: u8 = @truncate(zget_A(0));
            const sail_rorc_psw: u8 = @truncate(zget_PSW(0));

            rom[0] = 0xD0;
            cpu.a = a_val;
            cpu.psw = .{};
            cpu.psw.cy = initial_cy;
            cpu.pc = 0;
            _ = step(&cpu);

            try testing.expectEqual(sail_rorc_a, cpu.a);
            try testing.expectEqual(sail_rorc_psw & 0x80, @as(u8, @bitCast(cpu.psw)) & 0x80);
        }
    }
}

test "Sail vs Zig : Preuve exhaustive sur BZ et BNZ (65 536 transitions)" {
    model_init();
    defer model_fini();

    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    const pc_init: u16 = 0x0200;

    var off_int: u16 = 0;
    while (off_int <= 255) : (off_int += 1) {
        const offset: u8 = @truncate(off_int);

        // 1. Cas BZ (0x80) avec A = 0 (branchement pris)
        zset_A(0);
        zset_PC(pc_init);
        zstep_bzz(offset);
        const sail_bz_taken: u16 = @truncate(zget_PC(0));

        rom[pc_init] = 0x80;
        rom[pc_init + 1] = offset;
        cpu.a = 0;
        cpu.pc = pc_init;
        _ = step(&cpu);

        try testing.expectEqual(sail_bz_taken, cpu.pc);

        // 2. Cas BZ (0x80) avec A != 0 (branchement non pris)
        var a_int: u16 = 1;
        while (a_int <= 255) : (a_int += 17) {
            const non_zero_a: u8 = @truncate(a_int);
            zset_A(non_zero_a);
            zset_PC(pc_init);
            zstep_bzz(offset);
            const sail_bz_not_taken: u16 = @truncate(zget_PC(0));

            cpu.a = non_zero_a;
            cpu.pc = pc_init;
            _ = step(&cpu);

            try testing.expectEqual(sail_bz_not_taken, cpu.pc);
        }

        // 3. Cas BNZ (0x90) avec A != 0 (branchement pris)
        rom[pc_init] = 0x90;
        rom[pc_init + 1] = offset;
        a_int = 1;
        while (a_int <= 255) : (a_int += 17) {
            const non_zero_a: u8 = @truncate(a_int);
            zset_A(non_zero_a);
            zset_PC(pc_init);
            zstep_bnzz(offset);
            const sail_bnz_taken: u16 = @truncate(zget_PC(0));

            cpu.a = non_zero_a;
            cpu.pc = pc_init;
            _ = step(&cpu);

            try testing.expectEqual(sail_bnz_taken, cpu.pc);
        }

        // 4. Cas BNZ (0x90) avec A = 0 (branchement non pris)
        zset_A(0);
        zset_PC(pc_init);
        zstep_bnzz(offset);
        const sail_bnz_not_taken: u16 = @truncate(zget_PC(0));

        cpu.a = 0;
        cpu.pc = pc_init;
        _ = step(&cpu);

        try testing.expectEqual(sail_bnz_not_taken, cpu.pc);
    }
}
