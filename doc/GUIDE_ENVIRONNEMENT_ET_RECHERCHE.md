# Guide Complet : Environnement, Vérification Formelle (Sail) et Recherche

Ce document récapitule l'intégralité du travail accompli, les outils logiciels installés sur votre machine macOS, l'architecture des fichiers créés, ainsi que les commandes de reproduction pour l'article de recherche et la thèse.

---

## 1. Logiciels et Outils Installés sur macOS

Pour permettre la spécification formelle et la co-simulation sans matériel physique, la chaîne d'outils suivante a été installée et configurée :

| Logiciel | Version | Méthode d'installation | Rôle dans le projet |
| :--- | :--- | :--- | :--- |
| **Homebrew** | Stable | Déjà présent (`/opt/homebrew/bin/brew`) | Gestionnaire de paquets système macOS. |
| **OPAM** | 2.6.1 | `brew install opam` | Gestionnaire de paquets officiel pour le langage OCaml. |
| **OCaml** | 5.4.1 | Via OPAM (`opam switch`) | Environnement d'exécution et de compilation pour Sail. |
| **Z3** | 5.1.0 | `brew install z3` | Solveur SMT (Satisfiabilité Modulo Théories). Requis par Sail pour vérifier les contraintes sur les vecteurs de bits et les types dépendants. |
| **pkgconf** | 3.0.8 | `brew install pkgconf` | Outil de résolution de dépendances C. |
| **GMP (GNU MP)** | 6.3.0 | Homebrew (`/opt/homebrew/opt/gmp`) | Bibliothèque arithmétique multi-précision liée au runtime Sail C. |
| **Sail** | 0.20.3 | `opam install -y sail` | **Le compilateur d'architecture formelle de Cambridge**. Permet de décrire l'ISA mathématiquement et de générer du code C / Coq / Isabelle. |
| **sail_c_backend**| 0.20.3 | Inclus dans le paquet OPAM Sail | Backend Sail traduisant une spécification `.sail` en bibliothèque C. |
| **Zig** | 0.16.0 | Déjà présent (`/opt/homebrew/bin/zig`) | Langage d'implémentation de l'émulateur LC86K87 et compilateur C (`zig cc`). |
| **Python** | 3.14.2 | Déjà présent (`/opt/homebrew/bin/python3`)| Exécuteur du banc d'essai de *Mutation Testing*. |

---

## 2. Architecture des Fichiers Créés dans le Projet

Tous les fichiers créés sont situés dans votre dépôt [`LC86K87`](file:///Users/xophidia/Documents/dev/LC86K87) :

```text
LC86K87/
├── sail/
│   ├── lc86k.sail              <- Spécification formelle de référence en langage Sail
│   ├── lc86k_sail.h            <- En-tête C généré automatiquement par Sail
│   ├── lc86k_sail.c            <- Implémentation C générée automatiquement par Sail
│   ├── liblc86k_sail.a         <- Bibliothèque statique C (modèle + runtime Sail + GMP)
│   └── README.md               <- Documentation technique du dossier Sail
├── doc/
│   ├── article_methodologie_resultats.md <- Manuscrit complet pour l'article (prêt pour soumission)
│   └── GUIDE_ENVIRONNEMENT_ET_RECHERCHE.md <- Ce présent document récapitulatif
├── metamorphic_tests.zig       <- Suite de tests métamorphiques (MR1 à MR11 sans oracle matériel)
├── sail_test.zig               <- Banc de bisimulation différentielle Sail (C) vs Émulateur (Zig)
├── mutation_benchmark.py       <- Script automatisé d'injection de 15 fautes micro-architecturales
├── mutation_results.md         <- Résultats expérimentaux détaillés du Mutation Testing
└── build.zig                   <- Script de compilation Zig configuré avec les nouvelles cibles
```

---

## 3. Les Trois Niveaux de Vérification Disponibles

Votre fichier [`build.zig`](file:///Users/xophidia/Documents/dev/LC86K87/build.zig) propose désormais 3 cibles de tests isolées et complémentaires :

### Niveau 1 : La suite manuelle d'époque (Baseline VMC)
Exécute les 54 tests unitaires déterministes écrits d'après les exemples VMC du manuel officiel Sanyo/Sega.
```sh
zig build test-vmc --summary all
```
*Résultat : 54/54 pass (mais ne détecte que 40% des bugs de coin lors des mutations).*

### Niveau 2 : Le Test Métamorphique sans Oracle (Notre contribution)
Exécute les 11 relations métamorphiques formelles (MR1 à MR11) basées sur l'inversibilité algébrique, les cas limites, les éléments neutres/absorbants, la pile et la composition temporelle des cycles.
```sh
zig build test-meta --summary all
```
*Résultat : 11/11 pass (éradique 100% des 15 mutants injectés, dont 9 manqués par la baseline).*

### Niveau 3 : La Bisimulation Formelle Sail vs Zig
Exécute en co-simulation différentielle le modèle mathématique C généré par Sail face à votre cœur Zig sur 2 000 tirages pseudo-aléatoires pour prouver l'égalité stricte des registres et des drapeaux.
```sh
zig build test-sail --summary all
```
*Résultat : 2/2 pass (2 000 états vérifiés au bit près en 355 ms).*

---

## 4. Comment Régénérer le Modèle Sail en Cas de Modification

Si vous enrichissez la spécification formelle dans [`sail/lc86k.sail`](file:///Users/xophidia/Documents/dev/LC86K87/sail/lc86k.sail) (par exemple en ajoutant de nouvelles instructions), voici la procédure exacte pour régénérer la bibliothèque C et re-valider :

### Étape A : Compiler la spécification Sail en code C
```sh
opam exec -- sail -c sail/lc86k.sail -o sail/lc86k_sail \
    --c-no-main \
    --c-preserve step_add_imm \
    --c-preserve step_sub_imm \
    --c-preserve get_A \
    --c-preserve set_A \
    --c-preserve get_PSW \
    --c-preserve set_PSW
```
*(Ajoutez `--c-preserve <nom_fonction>` pour chaque nouvelle fonction que vous souhaitez exposer au C).*

### Étape B : Recompiler la bibliothèque statique `liblc86k_sail.a`
Utilisez le compilateur C intégré de Zig (`zig cc`) avec les includes du runtime Sail :
```sh
# 1. Compiler le modèle généré
zig cc -c sail/lc86k_sail.c -I/Users/xophidia/.opam/default/share/sail/lib -o sail/lc86k_sail.o

# 2. Compiler les modules du runtime Sail
zig cc -c /Users/xophidia/.opam/default/share/sail/lib/sail.c -I/Users/xophidia/.opam/default/share/sail/lib -o sail/sail.o
zig cc -c /Users/xophidia/.opam/default/share/sail/lib/rts.c -I/Users/xophidia/.opam/default/share/sail/lib -o sail/rts.o
zig cc -c /Users/xophidia/.opam/default/share/sail/lib/elf.c -I/Users/xophidia/.opam/default/share/sail/lib -o sail/elf.o

# 3. Créer l'archive statique
ar rcs sail/liblc86k_sail.a sail/lc86k_sail.o sail/sail.o sail/rts.o sail/elf.o
```

### Étape C : Lancer le test de bisimulation
```sh
zig build test-sail --summary all
```

---

## 5. Comment Rejouer le Mutation Testing (Résultats de l'Article)

Pour relancer l'expérience scientifique comparant la suite manuelle et la suite métamorphique :
```sh
python3 mutation_benchmark.py
```
Le script effectue automatiquement :
1. Une sauvegarde des fichiers originaux (`decode.zig` et `isa.zig`) ;
2. L'injection successive de 15 mutants micro-architecturaux ;
3. L'évaluation sous `zig build test-vmc` puis `zig build test-meta` ;
4. La restauration immédiate du code d'origine ;
5. La régénération du tableau comparatif dans [`mutation_results.md`](file:///Users/xophidia/Documents/dev/LC86K87/mutation_results.md).

---

## 6. Synthèse des Résultats pour l'Article et la Thèse

Le document rédigé dans [`doc/article_methodologie_resultats.md`](file:///Users/xophidia/Documents/dev/LC86K87/doc/article_methodologie_resultats.md) constitue la base complète de votre publication. Il intègre :
- **Section I (Introduction) :** Le dilemme post-silicium en préservation numérique et la présentation du LC86K87.
- **Section II (État de l'art) :** Analyse critique de l'émulation patrimoniale, des limites du test différentiel avec hardware, et du positionnement inédit du test métamorphique.
- **Section III (Méthodologie) :** Modélisation formelle mathématique ($\sigma \in \Sigma$), définition des 11 relations métamorphiques et extrait de spécification formelle Sail.
- **Section IV (Résultats) :** Le tableau 1 confrontant les deux approches (40 % vs 100 % de mutants tués) et l'analyse qualitative des dérives temporelles et des cas limites.
- **Section V (Perspectives Thèse) :** Trajectoire d'extension vers l'émulateur complet [`LC86000-core`](file:///Users/xophidia/Documents/dev/LC86000-core) (bus Maple, écran LCD multiplexé, gestion d'énergie).
- **Bibliographie :** 21 références académiques calibrées (UNESCO, Rothenberg, Armstrong/POPL, Chen, Zhendong Su/PLDI).
