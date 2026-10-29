# Résultats de l'Évaluation Tripartite par Mutation Testing (LC86K87)

Confrontation expérimentale entre la suite manuelle constructeur (VMC), la suite métamorphique (MR1-14) et la bisimulation formelle Cambridge Sail.

| ID | Catégorie | Description de la faute injectée | Suite VMC (54 tests) | Suite Métamorphique (MR1-14) | Bisimulation Sail |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **MUT-01** | Arithmetic / Flag CY | Erreur de bord sur Carry ADD (>= au lieu de >) | ❌ Survécu | ✅ Tué | ✅ Tué |
| **MUT-02** | Arithmetic / Flag AC | Erreur seuil sur Auxiliary Carry ADD (> 0xE au lieu de > 0xF) | ❌ Survécu | ✅ Tué | ✅ Tué |
| **MUT-03** | Arithmetic / Parity | Inversion de polarité de la parité (pair au lieu de impair) | ❌ Survécu | ✅ Tué | ✅ Tué |
| **MUT-04** | Arithmetic / Flag CY SUB | Erreur de comparaison Carry SUB (<= 0 au lieu de < 0) | ❌ Survécu | ✅ Tué | ✅ Tué |
| **MUT-05** | Arithmetic / Flag AC SUB | Inversion de l'Auxiliary Carry sur SUB | ❌ Survécu | ✅ Tué | ✅ Tué |
| **MUT-06** | Logic / AND | Confusion d'opérateur logique : AND muté en OR | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-07** | Logic / XOR Mask | Perte du bit de poids fort dans le XOR | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-08** | Stack / Push Direction | Direction de pile inversée (décrément au push au lieu d'incrément) | ✅ Tué | ✅ Tué | ❌ Survécu |
| **MUT-09** | Stack / Pop Off-by-one | Pop lit avant ajustement du pointeur de pile | ✅ Tué | ✅ Tué | ❌ Survécu |
| **MUT-10** | Shift / ROL Wrapping | Perte du bit de rebouclage cyclique sur ROL (décalage simple) | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-11** | Shift / ROR Wrapping | Perte du bit de rebouclage cyclique sur ROR | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-12** | Bit Manipulation / NOT1 | NOT1 n'inverse pas le bit (muté en mise à zéro) | ❌ Survécu | ✅ Tué | ❌ Survécu |
| **MUT-13** | Control Flow / BR Offset | Erreur d'offset de saut relatif (+1) | ❌ Survécu | ✅ Tué | ❌ Survécu |
| **MUT-14** | Temporal / NOP Cycles | Coût de cycle erroné sur NOP (2 cycles au lieu de 1) | ❌ Survécu | ✅ Tué | ❌ Survécu |
| **MUT-15** | Temporal / BR Cycles | Coût de cycle erroné sur BR (1 cycle au lieu de 2) | ❌ Survécu | ✅ Tué | ❌ Survécu |
| **MUT-16** | Control Flow / BZ Condition | Inversion de la condition de saut BZ (!= 0 au lieu de == 0) | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-17** | Control Flow / BNZ Condition | Inversion de la condition de saut BNZ (== 0 au lieu de != 0) | ❌ Survécu | ✅ Tué | ✅ Tué |
| **MUT-18** | Shift / ROLC Carry Loss | Perte de l'injection du Carry précédent dans ROLC | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-19** | Shift / RORC Carry Loss | Perte de l'injection du Carry précédent dans RORC | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-20** | Logic / OR Confusion | Opération OR mutée en AND | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-21** | Logic / XOR Identity Loss | Opération XOR mutée en simple assignation | ✅ Tué | ✅ Tué | ✅ Tué |
| **MUT-22** | Memory / RAMBK0 Banking | Ignorer le basculement de banque RAM (fixé à Bank 0) | ❌ Survécu | ✅ Tué | ❌ Survécu |
| **MUT-23** | Arithmetic / INC Parity | Inversion du drapeau de parité sur INC | ❌ Survécu | ✅ Tué | ❌ Survécu |
| **MUT-24** | Bit Manipulation / SET1 | SET1 muté en CLR1 (mise à zéro au lieu de mise à 1) | ✅ Tué | ✅ Tué | ❌ Survécu |
| **MUT-25** | Bit Manipulation / CLR1 | CLR1 muté en SET1 (mise à 1 au lieu de mise à zéro) | ✅ Tué | ✅ Tué | ❌ Survécu |
| **MUT-26** | Arithmetic / ADD Overflow | Inversion logique du calcul du flag Overflow (OV) | ✅ Tué | ✅ Tué | ✅ Tué |

## Synthèse des Scores de Mutation

- **Mutation Score Suite VMC (Manuelle d'époque)** : **53.8%** (14/26)
- **Mutation Score Suite Métamorphique (Sans oracle)** : **100.0%** (26/26)
- **Mutation Score Bisimulation Formelle Sail** : **61.5%** (16/26)
- **Score Combiné Global (Union Tripartite)** : **100.0%** (26/26)
- **Mutants échappant aux tests constructeur et éliminés sans oracle** : **12**
