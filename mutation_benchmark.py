#!/usr/bin/env python3
"""
Banc d'essai de Mutation Testing (Mutation Testing Benchmark) étendu
pour l'évaluation de la fidélité de l'émulateur LC86K87 sans oracle matériel.

Compare la capacité de détection de fautes entre 3 approches :
1. La suite manuelle VMC (54 tests unitaires de référence issus du manuel Sanyo)
2. La suite de tests métamorphiques (MR1 à MR18 - invariants algébriques, système et temporels)
3. La suite de bisimulation formelle Sail (modèle mathématique d'état Cambridge Sail)
"""

import os
import subprocess
import shutil
import sys
import time

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
DECODE_FILE = os.path.join(PROJECT_DIR, "decode.zig")
ISA_FILE = os.path.join(PROJECT_DIR, "isa.zig")
LC86K_FILE = os.path.join(PROJECT_DIR, "lc86K.zig")

# Définition des 26 mutants représentatifs (ALU, Logique, Pile, Flot de contrôle, Banques RAM, Timing)
MUTANTS = [
    {
        "id": "MUT-01",
        "file": DECODE_FILE,
        "category": "Arithmetic / Flag CY",
        "description": "Erreur de bord sur Carry ADD (>= au lieu de >)",
        "target": "cpu.psw.cy = result > 0xFF;",
        "mutant": "cpu.psw.cy = result >= 0xFF;",
    },
    {
        "id": "MUT-02",
        "file": DECODE_FILE,
        "category": "Arithmetic / Flag AC",
        "description": "Erreur seuil sur Auxiliary Carry ADD (> 0xE au lieu de > 0xF)",
        "target": "cpu.psw.ac = (cpu.a & 0xF) + (v & 0xF) > 0xF;",
        "mutant": "cpu.psw.ac = (cpu.a & 0xF) + (v & 0xF) > 0xE;",
    },
    {
        "id": "MUT-03",
        "file": DECODE_FILE,
        "category": "Arithmetic / Parity",
        "description": "Inversion de polarité de la parité (pair au lieu de impair)",
        "target": "cpu.psw.p = @popCount(cpu.a) % 2 == 1;",
        "mutant": "cpu.psw.p = @popCount(cpu.a) % 2 == 0;",
    },
    {
        "id": "MUT-04",
        "file": DECODE_FILE,
        "category": "Arithmetic / Flag CY SUB",
        "description": "Erreur de comparaison Carry SUB (<= 0 au lieu de < 0)",
        "target": "cpu.psw.cy = result < 0;",
        "mutant": "cpu.psw.cy = result <= 0;",
    },
    {
        "id": "MUT-05",
        "file": DECODE_FILE,
        "category": "Arithmetic / Flag AC SUB",
        "description": "Inversion de l'Auxiliary Carry sur SUB",
        "target": "cpu.psw.ac = (cpu.a & 0xF) < (v & 0xF);",
        "mutant": "cpu.psw.ac = (cpu.a & 0xF) <= (v & 0xF);",
    },
    {
        "id": "MUT-06",
        "file": DECODE_FILE,
        "category": "Logic / AND",
        "description": "Confusion d'opérateur logique : AND muté en OR",
        "target": "cpu.a &= readOp8(cpu, dec);",
        "mutant": "cpu.a |= readOp8(cpu, dec);",
    },
    {
        "id": "MUT-07",
        "file": DECODE_FILE,
        "category": "Logic / XOR Mask",
        "description": "Perte du bit de poids fort dans le XOR",
        "target": "cpu.a ^= readOp8(cpu, dec);",
        "mutant": "cpu.a ^= (readOp8(cpu, dec) & 0x7F);",
    },
    {
        "id": "MUT-08",
        "file": DECODE_FILE,
        "category": "Stack / Push Direction",
        "description": "Direction de pile inversée (décrément au push au lieu d'incrément)",
        "target": "cpu.sp +%= 1;\n            cpu.ram_bank0[cpu.sp] = val;",
        "mutant": "cpu.sp -%= 1;\n            cpu.ram_bank0[cpu.sp] = val;",
    },
    {
        "id": "MUT-09",
        "file": DECODE_FILE,
        "category": "Stack / Pop Off-by-one",
        "description": "Pop lit avant ajustement du pointeur de pile",
        "target": "const val = cpu.ram_bank0[cpu.sp];\n            cpu.sp -%= 1;",
        "mutant": "cpu.sp -%= 1;\n            const val = cpu.ram_bank0[cpu.sp];",
    },
    {
        "id": "MUT-10",
        "file": DECODE_FILE,
        "category": "Shift / ROL Wrapping",
        "description": "Perte du bit de rebouclage cyclique sur ROL (décalage simple)",
        "target": "cpu.a = (cpu.a << 1) | (cpu.a >> 7);",
        "mutant": "cpu.a = (cpu.a << 1);",
    },
    {
        "id": "MUT-11",
        "file": DECODE_FILE,
        "category": "Shift / ROR Wrapping",
        "description": "Perte du bit de rebouclage cyclique sur ROR",
        "target": "cpu.a = (cpu.a >> 1) | ((cpu.a & 1) << 7);",
        "mutant": "cpu.a = (cpu.a >> 1);",
    },
    {
        "id": "MUT-12",
        "file": DECODE_FILE,
        "category": "Bit Manipulation / NOT1",
        "description": "NOT1 n'inverse pas le bit (muté en mise à zéro)",
        "target": ".not1 => old ^ (@as(u8, 1) << bit),",
        "mutant": ".not1 => old & ~(@as(u8, 1) << bit),",
    },
    {
        "id": "MUT-13",
        "file": DECODE_FILE,
        "category": "Control Flow / BR Offset",
        "description": "Erreur d'offset de saut relatif (+1)",
        "target": "cpu.pc +%= rel;",
        "mutant": "cpu.pc +%= rel +% 1;",
    },
    {
        "id": "MUT-14",
        "file": ISA_FILE,
        "category": "Temporal / NOP Cycles",
        "description": "Coût de cycle erroné sur NOP (2 cycles au lieu de 1)",
        "target": "0x0 => .{ .inst = .nop, .size = 1, .cycles = 1, .mnemonic = \"NOP\", .disp = .fmtI },",
        "mutant": "0x0 => .{ .inst = .nop, .size = 1, .cycles = 2, .mnemonic = \"NOP\", .disp = .fmtI },",
    },
    {
        "id": "MUT-15",
        "file": ISA_FILE,
        "category": "Temporal / BR Cycles",
        "description": "Coût de cycle erroné sur BR (1 cycle au lieu de 2)",
        "target": "0x1 => .{ .inst = .br, .mode = .imm, .size = 2, .cycles = 2, .mnemonic = \"BR\", .disp = .fmtA_br },",
        "mutant": "0x1 => .{ .inst = .br, .mode = .imm, .size = 2, .cycles = 1, .mnemonic = \"BR\", .disp = .fmtA_br },",
    },
    {
        "id": "MUT-16",
        "file": DECODE_FILE,
        "category": "Control Flow / BZ Condition",
        "description": "Inversion de la condition de saut BZ (!= 0 au lieu de == 0)",
        "target": "if (cpu.a == 0) cpu.pc +%= signExt8(offset);",
        "mutant": "if (cpu.a != 0) cpu.pc +%= signExt8(offset);",
    },
    {
        "id": "MUT-17",
        "file": DECODE_FILE,
        "category": "Control Flow / BNZ Condition",
        "description": "Inversion de la condition de saut BNZ (== 0 au lieu de != 0)",
        "target": "if (cpu.a != 0) cpu.pc +%= signExt8(offset);",
        "mutant": "if (cpu.a == 0) cpu.pc +%= signExt8(offset);",
    },
    {
        "id": "MUT-18",
        "file": DECODE_FILE,
        "category": "Shift / ROLC Carry Loss",
        "description": "Perte de l'injection du Carry précédent dans ROLC",
        "target": "cpu.a = (cpu.a << 1) | old_c;",
        "mutant": "cpu.a = (cpu.a << 1);",
    },
    {
        "id": "MUT-19",
        "file": DECODE_FILE,
        "category": "Shift / RORC Carry Loss",
        "description": "Perte de l'injection du Carry précédent dans RORC",
        "target": "cpu.a = (old_c << 7) | (cpu.a >> 1);",
        "mutant": "cpu.a = (cpu.a >> 1);",
    },
    {
        "id": "MUT-20",
        "file": DECODE_FILE,
        "category": "Logic / OR Confusion",
        "description": "Opération OR mutée en AND",
        "target": "cpu.a |= readOp8(cpu, dec);",
        "mutant": "cpu.a &= readOp8(cpu, dec);",
    },
    {
        "id": "MUT-21",
        "file": DECODE_FILE,
        "category": "Logic / XOR Identity Loss",
        "description": "Opération XOR mutée en simple assignation",
        "target": "cpu.a ^= readOp8(cpu, dec);",
        "mutant": "cpu.a = readOp8(cpu, dec);",
    },
    {
        "id": "MUT-22",
        "file": LC86K_FILE,
        "category": "Memory / RAMBK0 Banking",
        "description": "Ignorer le basculement de banque RAM (fixé à Bank 0)",
        "target": "return if (self.psw.rambk0) &self.ram_bank1 else &self.ram_bank0;",
        "mutant": "return &self.ram_bank0;",
    },
    {
        "id": "MUT-23",
        "file": DECODE_FILE,
        "category": "Arithmetic / INC Parity",
        "description": "Inversion du drapeau de parité sur INC",
        "target": "const val = cpu.load8(addr) +% 1;\n            cpu.store8(addr, val);\n            cpu.psw.p = @popCount(val) % 2 == 1;",
        "mutant": "const val = cpu.load8(addr) +% 1;\n            cpu.store8(addr, val);\n            cpu.psw.p = @popCount(val) % 2 == 0;",
    },
    {
        "id": "MUT-24",
        "file": DECODE_FILE,
        "category": "Bit Manipulation / SET1",
        "description": "SET1 muté en CLR1 (mise à zéro au lieu de mise à 1)",
        "target": ".set1 => old | (@as(u8, 1) << bit),",
        "mutant": ".set1 => old & ~(@as(u8, 1) << bit),",
    },
    {
        "id": "MUT-25",
        "file": DECODE_FILE,
        "category": "Bit Manipulation / CLR1",
        "description": "CLR1 muté en SET1 (mise à 1 au lieu de mise à zéro)",
        "target": ".clr1 => old & ~(@as(u8, 1) << bit),",
        "mutant": ".clr1 => old | (@as(u8, 1) << bit),",
    },
    {
        "id": "MUT-26",
        "file": DECODE_FILE,
        "category": "Arithmetic / ADD Overflow",
        "description": "Inversion logique du calcul du flag Overflow (OV)",
        "target": "cpu.psw.ov = (@as(u1, @truncate(cpu.a >> 7)) == @as(u1, @truncate(v >> 7))) and",
        "mutant": "cpu.psw.ov = (@as(u1, @truncate(cpu.a >> 7)) != @as(u1, @truncate(v >> 7))) and",
    },
]

def run_test_target(target: str) -> bool:
    """Exécute un test Zig cible. Retourne True si les tests passent (mutant survit), False s'ils échouent (mutant tué)."""
    res = subprocess.run(
        ["zig", "build", target],
        cwd=PROJECT_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return res.returncode == 0

def main():
    print("=" * 96)
    print(" BANC DE TEST DE MUTATION ÉTENDU - LC86K87 (VMC vs Métamorphique vs Sail Bisimulation)")
    print("=" * 96)

    # Sauvegardes de sécurité
    decode_bak = DECODE_FILE + ".benchmark_bak"
    isa_bak = ISA_FILE + ".benchmark_bak"
    lc86k_bak = LC86K_FILE + ".benchmark_bak"
    shutil.copyfile(DECODE_FILE, decode_bak)
    shutil.copyfile(ISA_FILE, isa_bak)
    shutil.copyfile(LC86K_FILE, lc86k_bak)

    results = []

    try:
        # Vérification initiale de la baseline
        print("Vérification nominale (baseline propre)...")
        if not run_test_target("test-vmc") or not run_test_target("test-meta") or not run_test_target("test-sail"):
            print("ERREUR : Les tests échouent déjà sur le code non muté !")
            sys.exit(1)
        print("Baseline nominale validée : 100% pass sur VMC, Métamorphique et Sail.\n")

        total = len(MUTANTS)
        print(f"Exécution de l'injection sur {total} mutants synthétiques...\n")
        print(f"{'ID':<8} | {'Catégorie':<28} | {'VMC':<8} | {'Métamorphique':<14} | {'Sail Bisim':<12}")
        print("-" * 80)

        for m in MUTANTS:
            target_file = m["file"]
            with open(target_file, "r") as f:
                content = f.read()

            if m["target"] not in content:
                print(f"AVERTISSEMENT : Cible pour {m['id']} introuvable dans {os.path.basename(target_file)}")
                continue

            # Injection du mutant
            mutated_content = content.replace(m["target"], m["mutant"], 1)
            with open(target_file, "w") as f:
                f.write(mutated_content)

            # Évaluation sous les 3 suites
            vmc_survived = run_test_target("test-vmc")
            vmc_killed = not vmc_survived

            meta_survived = run_test_target("test-meta")
            meta_killed = not meta_survived

            sail_survived = run_test_target("test-sail")
            sail_killed = not sail_survived

            # Restauration immédiate
            with open(target_file, "w") as f:
                f.write(content)

            vmc_status = "KILLED" if vmc_killed else "SURVIVED"
            meta_status = "KILLED" if meta_killed else "SURVIVED"
            sail_status = "KILLED" if sail_killed else "SURVIVED"

            print(f"{m['id']:<8} | {m['category']:<28} | {vmc_status:<8} | {meta_status:<14} | {sail_status:<12}")

            results.append({
                "id": m["id"],
                "category": m["category"],
                "description": m["description"],
                "vmc_killed": vmc_killed,
                "meta_killed": meta_killed,
                "sail_killed": sail_killed,
            })

    finally:
        # Restauration garantie des fichiers originaux
        shutil.copyfile(decode_bak, DECODE_FILE)
        shutil.copyfile(isa_bak, ISA_FILE)
        shutil.copyfile(lc86k_bak, LC86K_FILE)
        if os.path.exists(decode_bak): os.remove(decode_bak)
        if os.path.exists(isa_bak): os.remove(isa_bak)
        if os.path.exists(lc86k_bak): os.remove(lc86k_bak)

    # Synthèse des statistiques
    total_evaluated = len(results)
    vmc_total_killed = sum(1 for r in results if r["vmc_killed"])
    meta_total_killed = sum(1 for r in results if r["meta_killed"])
    sail_total_killed = sum(1 for r in results if r["sail_killed"])
    
    meta_only_killed = sum(1 for r in results if r["meta_killed"] and not r["vmc_killed"])
    combined_killed = sum(1 for r in results if r["vmc_killed"] or r["meta_killed"] or r["sail_killed"])

    vmc_score = (vmc_total_killed / total_evaluated) * 100 if total_evaluated > 0 else 0
    meta_score = (meta_total_killed / total_evaluated) * 100 if total_evaluated > 0 else 0
    sail_score = (sail_total_killed / total_evaluated) * 100 if total_evaluated > 0 else 0
    comb_score = (combined_killed / total_evaluated) * 100 if total_evaluated > 0 else 0

    print("\n" + "=" * 96)
    print(" RÉSULTATS SCIENTIFIQUES DU MUTATION TESTING (TRIPARTITE)")
    print("=" * 96)
    print(f"Total Mutants Injectés                 : {total_evaluated}")
    print(f"Mutants Tués par Suite VMC (Manuelle)  : {vmc_total_killed}/{total_evaluated} ({vmc_score:.1f}%)")
    print(f"Mutants Tués par Suite Métamorphique   : {meta_total_killed}/{total_evaluated} ({meta_score:.1f}%)")
    print(f"Mutants Tués par Bisimulation Sail     : {sail_total_killed}/{total_evaluated} ({sail_score:.1f}%)")
    print(f"Mutants Tués EXCLUSIVEMENT par Métam. : {meta_only_killed}")
    print(f"Score Combiné Total (Union Tripartite): {combined_killed}/{total_evaluated} ({comb_score:.1f}%)")
    print("=" * 96)

    # Export des résultats en Markdown (prêt pour publication)
    report_path = os.path.join(PROJECT_DIR, "mutation_results.md")
    with open(report_path, "w") as f:
        f.write("# Résultats de l'Évaluation Tripartite par Mutation Testing (LC86K87)\n\n")
        f.write("Confrontation expérimentale entre la suite manuelle constructeur (VMC), ")
        f.write("la suite métamorphique (MR1-14) et la bisimulation formelle Cambridge Sail.\n\n")
        f.write("| ID | Catégorie | Description de la faute injectée | Suite VMC (54 tests) | Suite Métamorphique (MR1-14) | Bisimulation Sail |\n")
        f.write("| :--- | :--- | :--- | :---: | :---: | :---: |\n")
        for r in results:
            vmc_badge = "✅ Tué" if r["vmc_killed"] else "❌ Survécu"
            meta_badge = "✅ Tué" if r["meta_killed"] else "❌ Survécu"
            sail_badge = "✅ Tué" if r["sail_killed"] else "❌ Survécu"
            f.write(f"| **{r['id']}** | {r['category']} | {r['description']} | {vmc_badge} | {meta_badge} | {sail_badge} |\n")
        f.write("\n## Synthèse des Scores de Mutation\n\n")
        f.write(f"- **Mutation Score Suite VMC (Manuelle d'époque)** : **{vmc_score:.1f}%** ({vmc_total_killed}/{total_evaluated})\n")
        f.write(f"- **Mutation Score Suite Métamorphique (Sans oracle)** : **{meta_score:.1f}%** ({meta_total_killed}/{total_evaluated})\n")
        f.write(f"- **Mutation Score Bisimulation Formelle Sail** : **{sail_score:.1f}%** ({sail_total_killed}/{total_evaluated})\n")
        f.write(f"- **Score Combiné Global (Union Tripartite)** : **{comb_score:.1f}%** ({combined_killed}/{total_evaluated})\n")
        f.write(f"- **Mutants échappant aux tests constructeur et éliminés sans oracle** : **{meta_only_killed}**\n")

    print(f"\nRapport détaillé sauvegardé dans : {report_path}")

if __name__ == "__main__":
    main()
