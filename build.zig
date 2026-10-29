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
    // 1. Suite de tests manuels VMC (baseline)
    const vmc_test_mod = b.createModule(.{
        .root_source_file = b.path("tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    vmc_test_mod.addImport("lc86K", lc86K_mod);
    vmc_test_mod.addImport("decode", decode_mod);

    const vmc_tests = b.addTest(.{ .root_module = vmc_test_mod });
    const run_vmc_tests = b.addRunArtifact(vmc_tests);
    const vmc_step = b.step("test-vmc", "Exécuter les tests manuels VMC de référence");
    vmc_step.dependOn(&run_vmc_tests.step);

    // 2. Programme de validation assembleur (tests/programme_validation.zig)
    const prog_test_mod = b.createModule(.{
        .root_source_file = b.path("tests/programme_validation.zig"),
        .target = target,
        .optimize = optimize,
    });
    prog_test_mod.addImport("lc86k", lib_mod);

    const prog_tests = b.addTest(.{ .root_module = prog_test_mod });
    const run_prog_tests = b.addRunArtifact(prog_tests);
    const prog_step = b.step("test-prog", "Exécuter le programme de validation assembleur");
    prog_step.dependOn(&run_prog_tests.step);

    // 3. Suite de tests métamorphiques (MR1 à MR18 sans oracle)
    const meta_test_mod = b.createModule(.{
        .root_source_file = b.path("metamorphic_tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    meta_test_mod.addImport("lc86K", lc86K_mod);
    meta_test_mod.addImport("decode", decode_mod);

    const meta_tests = b.addTest(.{ .root_module = meta_test_mod });
    const run_meta_tests = b.addRunArtifact(meta_tests);
    const meta_step = b.step("test-meta", "Exécuter les tests métamorphiques sans oracle");
    meta_step.dependOn(&run_meta_tests.step);

    // 4. Suite de test différentiel Sail (bisimulation formelle)
    const sail_test_mod = b.createModule(.{
        .root_source_file = b.path("sail_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    sail_test_mod.addImport("lc86K", lc86K_mod);
    sail_test_mod.addImport("decode", decode_mod);
    sail_test_mod.link_libc = true;
    sail_test_mod.addObjectFile(b.path("sail/liblc86k_sail.a"));
    sail_test_mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/opt/gmp/lib" });
    sail_test_mod.linkSystemLibrary("gmp", .{});

    const sail_tests = b.addTest(.{ .root_module = sail_test_mod });
    const run_sail_tests = b.addRunArtifact(sail_tests);
    const sail_step = b.step("test-sail", "Exécuter les tests de bisimulation formelle Sail vs Zig");
    sail_step.dependOn(&run_sail_tests.step);

    // 5. Cible par défaut "zig build test" (exécute les suites VMC, validation assembleur et métamorphiques)
    const test_step = b.step("test", "Exécuter l'ensemble des suites de tests");
    test_step.dependOn(&run_vmc_tests.step);
    test_step.dependOn(&run_prog_tests.step);
    test_step.dependOn(&run_meta_tests.step);
}
