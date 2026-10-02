const cpu_mod = @import("lc86K");
const decode_mod = @import("decode");
const timer_mod = @import("timer");
const isa_mod = @import("isa");
const debug_mod = @import("debug");

/// Exécute une instruction et retourne le nombre de cycles consommés.
pub const step = decode_mod.step;
pub const DecodeResult = decode_mod.DecodeResult;

pub const Cpu = cpu_mod.Cpu;
pub const Psw = cpu_mod.Psw;

pub const tickTimer0 = timer_mod.tickTimer0;
pub const tickTimer1 = timer_mod.tickTimer1;
pub const tickBaseTimer = timer_mod.tickBaseTimer;
pub const tick = timer_mod.tick;

pub const isa = isa_mod;
pub const debug = debug_mod;
