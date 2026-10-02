const std = @import("std");
const Cpu = @import("lc86K").Cpu;
const isa = @import("isa");

/// Niveaux de verbosité du trace d'exécution.
pub const LogLevel = enum(u8) {
    none = 0,
    error_level = 1,
    warn = 2,
    info = 3,
    trace = 4,
};

pub var log_level: LogLevel = .none;

/// Sink optionnel : si défini, chaque message y est transmis au lieu de
/// print sur stderr. Permet d'héberger le core dans un hôte qui possède
/// déjà sa propre journalisation (GUI, tests, embarque).
pub var log_sink: ?*const fn (level: LogLevel, msg: []const u8) void = null;

/// Compteur d'échantillonnage utilisé pour limiter la trace HALT.
pub var halt_sample: u16 = 0;

pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (@intFromEnum(log_level) == 0) return;

    var buf: [512]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, fmt, args) catch return;

    if (log_sink) |sink| {
        sink(log_level, msg);
    } else {
        std.debug.print("{s}\n", .{msg});
    }
}

pub fn disassembleAt(cpu: *Cpu, buf: []u8, pc: u16) usize {
    const rom = cpu.inst_bank.data;
    if (pc >= rom.len) return 0;

    const start_pc = pc;
    const opcode = rom[pc];
    const e = isa.TABLE[opcode];

    // Octets opérande lus depuis la table ISA (taille unique de source de vérité)
    const operands = rom[pc + 1 .. @min(pc + e.size, rom.len)];

    return switch (e.disp) {
        .fmtI => fmtI(buf, start_pc, e.mnemonic),
        .fmtI2 => fmtI2(buf, start_pc, e.mnemonic, read16(operands, 0)),
        .fmtImm => fmtImm(buf, start_pc, e.mnemonic, operands[0]),
        .fmtBI => fmtImm(buf, start_pc, e.mnemonic, operands[0]),
        .fmtA_d9 => fmtA(buf, start_pc, e.mnemonic, isa.decodeD9(opcode, operands[0])),
        .fmtA_br => {
            const r8 = operands[0];
            const tgt: u16 = start_pc + 2 +% @as(u16, @bitCast(@as(i16, @as(i8, @bitCast(r8)))));
            return fmtA(buf, start_pc, e.mnemonic, tgt);
        },
        .fmtA_callr => {
            const offset = read16(operands, 0);
            const tgt: u16 = start_pc +% 3 +% @as(u16, @bitCast(@as(i16, @bitCast(offset))));
            return fmtA(buf, start_pc, e.mnemonic, tgt);
        },
        .fmtA_jmp => {
            const imm8 = operands[0];
            const ad12 = ((@as(u16, opcode & 0x10) << 7) |
                (@as(u16, opcode & 0x07) << 8) |
                @as(u16, imm8));
            return fmtA(buf, start_pc, e.mnemonic, (start_pc & 0xF000) | ad12);
        },
        .fmtA_abs => return fmtA(buf, start_pc, e.mnemonic, read16(operands, 0)),
        .fmtR => return fmtR(buf, start_pc, e.mnemonic, @intCast(e.ri orelse 0)),
        .fmtM => return fmtM(buf, start_pc, e.mnemonic, isa.decodeD9(opcode, operands[0]), operands[1]),
        .fmtMR => return fmtMR(buf, start_pc, e.mnemonic, @intCast(e.ri orelse 0), operands[0]),
        .fmtBitBranch => return fmtBitAddress(buf, start_pc, e.mnemonic, isa.decodeD9(opcode, operands[0]), @intCast(e.bit orelse 0)),
        .fmtBitOp => return fmtBitAddress(buf, start_pc, e.mnemonic, isa.decodeD9(opcode, operands[0]), @intCast(e.bit orelse 0)),
    };
}

fn read16(operands: []const u8, i: usize) u16 {
    if (i + 1 < operands.len) {
        return (@as(u16, operands[i + 1]) << 8) | @as(u16, operands[i]);
    }
    return 0;
}

fn fmtI(buf: []u8, pc: u16, mnem: []const u8) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s}", .{ pc, mnem }) catch return 0).len;
}

fn fmtI2(buf: []u8, pc: u16, mnem: []const u8, val: anytype) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} {X:0>4}", .{ pc, mnem, @as(u16, val) }) catch return 0).len;
}

fn fmtImm(buf: []u8, pc: u16, mnem: []const u8, imm: u8) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} #{X:0>2}h", .{ pc, mnem, imm }) catch return 0).len;
}

fn fmtA(buf: []u8, pc: u16, mnem: []const u8, addr: u16) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} {X:0>4}h", .{ pc, mnem, addr }) catch return 0).len;
}

fn fmtR(buf: []u8, pc: u16, mnem: []const u8, ri: u2) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} @R{d}", .{ pc, mnem, ri }) catch return 0).len;
}

fn fmtM(buf: []u8, pc: u16, mnem: []const u8, addr: u16, imm: u8) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} {X:0>4}h,#{X:0>2}h", .{ pc, mnem, addr, imm }) catch return 0).len;
}

fn fmtMR(buf: []u8, pc: u16, mnem: []const u8, ri: u2, imm: u8) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} @R{d},#{X:0>2}h", .{ pc, mnem, ri, imm }) catch return 0).len;
}

fn fmtBitAddress(buf: []u8, pc: u16, mnem: []const u8, addr: u16, bit: u3) usize {
    return (std.fmt.bufPrint(buf, "{X:0>4}: {s} {X:0>3}h.{d}", .{ pc, mnem, addr, bit }) catch return 0).len;
}

// ── Loop detection ────────────────────────────────────────
const LOOP_WINDOW: usize = 128;
pub var pc_history: [LOOP_WINDOW]u16 = undefined;
pub var pc_hist_pos: usize = 0;
pub var loop_detected_pc: ?u16 = null;
pub var loop_count: u32 = 0;

pub fn recordPC(pc: u16) void {
    pc_history[pc_hist_pos] = pc;
    pc_hist_pos = (pc_hist_pos + 1) % LOOP_WINDOW;

    var same_count: u32 = 0;
    for (pc_history) |h| {
        if (h == pc) same_count += 1;
    }
    if (same_count > LOOP_WINDOW * 2 / 3) {
        if (loop_detected_pc) |lp| {
            if (lp == pc) {
                loop_count += 1;
            } else {
                loop_detected_pc = pc;
                loop_count = 1;
            }
        } else {
            loop_detected_pc = pc;
            loop_count = 1;
        }
    } else if (loop_detected_pc) |lp| {
        if (lp != pc) {
            loop_detected_pc = null;
            loop_count = 0;
        }
    }
}

pub fn formatCpuState(cpu: *Cpu, buf: []u8) usize {
    const msg = std.fmt.bufPrint(buf, "A={X:0>2} B={X:0>2} C={X:0>2} SP={X:0>2} PSW={X:0>2} IE={X:0>2} halted={s} depth={d}", .{
        cpu.a,
        cpu.b,
        cpu.c,
        cpu.sp,
        @as(u8, @bitCast(cpu.psw)),
        cpu.sfr_raw[0x08],
        if (cpu.halted) "YES" else "no",
        cpu.interrupt_depth,
    }) catch return buf.len;
    return msg.len;
}

pub fn formatSfrState(cpu: *Cpu, buf: []u8) usize {
    const msg = std.fmt.bufPrint(buf, "T0CNT={X:0>2} T0L={X:0>2} T0H={X:0>2} T1CNT={X:0>2} T1L={X:0>2} T1H={X:0>2} BTCR={X:0>2} P3={X:0>2}", .{
        cpu.sfr_raw[0x4E],
        cpu.t0l_counter,
        cpu.t0h_counter,
        cpu.sfr_raw[0x18],
        cpu.t1l_counter,
        cpu.t1h_counter,
        cpu.sfr_raw[0x7F],
        cpu.p3_buttons,
    }) catch return buf.len;
    return msg.len;
}

pub fn instSize(rom: []const u8, addr: u16) u16 {
    if (addr >= rom.len) return 1;
    const opcode = rom[addr];
    return isa.TABLE[opcode].size;
}
