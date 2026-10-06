const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const isa_mod = b.createModule(.{
        .root_source_file = b.path("isa.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lc86K_mod = b.createModule(.{
        .root_source_file = b.path("lc86K.zig"),
        .target = target,
        .optimize = optimize,
    });

    const timer_mod = b.createModule(.{
        .root_source_file = b.path("timer.zig"),
        .target = target,
        .optimize = optimize,
    });
    timer_mod.addImport("lc86K", lc86K_mod);
    lc86K_mod.addImport("timer", timer_mod);

    const decode_mod = b.createModule(.{
        .root_source_file = b.path("decode.zig"),
        .target = target,
        .optimize = optimize,
    });
    decode_mod.addImport("lc86K", lc86K_mod);
    decode_mod.addImport("isa", isa_mod);

    const debug_mod = b.createModule(.{
        .root_source_file = b.path("debug.zig"),
        .target = target,
        .optimize = optimize,
    });
    debug_mod.addImport("lc86K", lc86K_mod);
    debug_mod.addImport("isa", isa_mod);

    decode_mod.addImport("debug", debug_mod);

    // ── Bibliothèque ──────────────────────────────────────────────
    // Module racine exposé aux consommateurs : @import("lc86k")
    const lib_mod = b.addModule("lc86k", .{
        .root_source_file = b.path("root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("lc86K", lc86K_mod);
    lib_mod.addImport("decode", decode_mod);
    lib_mod.addImport("timer", timer_mod);
    lib_mod.addImport("isa", isa_mod);
    lib_mod.addImport("debug", debug_mod);

    const lib = b.addLibrary(.{
        .name = "lc86k",
        .root_module = lib_mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    // ── Tests ────────────────────────────────────────────────────
    const test_mod = b.createModule(.{
        .root_source_file = b.path("tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_mod.addImport("lc86K", lc86K_mod);
    test_mod.addImport("decode", decode_mod);

    const tests = b.addTest(.{ .root_module = test_mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);

    // ── Programme de validation (tests/) ─────────────────────────
    // Consomme la bibliothèque comme un utilisateur : @import("lc86k")
    const prog_test_mod = b.createModule(.{
        .root_source_file = b.path("tests/programme_validation.zig"),
        .target = target,
        .optimize = optimize,
    });
    prog_test_mod.addImport("lc86k", lib_mod);

    const prog_tests = b.addTest(.{ .root_module = prog_test_mod });
    const run_prog_tests = b.addRunArtifact(prog_tests);
    test_step.dependOn(&run_prog_tests.step);
}
