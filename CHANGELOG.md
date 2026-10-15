# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-10-15

### Fixed
- **Instructions `BE @Rj` et `BNE @Rj` (`0x34..0x37`, `0x44..0x47`)** :
  - Taille d'instruction corrigée à 3 octets (`opcode`, `imm8`, `rel8`) au lieu de 2.
  - Sémantique de comparaison corrigée : compare désormais la valeur pointée `((Rj))` avec l'immédiat `imm8` (au lieu de l'accumulateur).
  - Positionnement exact du drapeau Carry : `CY = ((Rj)) < imm8`.
  - Calcul de la cible de saut corrigé (`pc + 3 + rel8`) et ajout du formateur `.fmtMR_br` dans le désassembleur `debug.zig`.
- **Drapeau Carry (`CY`) sur `ROL` et `ROR`** :
  - `ROL` (`0xE0`) et `ROR` (`0xC0`) n'écrasent plus le flag Carry (seuls `ROLC` et `RORC` font intervenir `CY`).
- **Bit de parité matérielle (`PSW.P`)** :
  - Les instructions `INC` et `DEC` en RAM (`inc_d9`, `inc_ri`, `dec_d9`, `dec_ri`) ne modifient plus `PSW.P` (qui reflète uniquement la parité impaire de `ACC`).
  - Mise à jour systématique de `PSW.P` sur toutes les opérations chargeant ou altérant `ACC` (`LD`, `LD @Ri`, `XCH`, `MUL`, `DIV`, `LDC`, `LDF`).
- **Sous-routines `CALLF`** :
  - Synchronisation du bank d'instructions via `syncInstructionBank()` lors de l'exécution de `CALLF` (aligné avec `JMPF`).
- **Adressage indirect par registre (`@Ri`)** :
  - `readIndirectAddr` accède au bank de RAM actif (`currentRamBank()`) au lieu de forcer le bank 0.
- **Timer 0 (Mode 2 - cascade 16 bits)** :
  - Exécution conditionnée à l'activation simultanée de `T0LRUN` et `T0HRUN`.
- **Timer 1 (Mode 2 vs Mode 0)** :
  - Mode cascade 16 bits actif uniquement si `T1LONG | T1HRUN | T1LRUN` sont tous armés. Si `T1LRUN == 0`, `T1H` continue son comptage en tant que timer 8 bits indépendant.
- **Base Timer (INT1)** :
  - Déclenchement périodique de l'interruption `INT1` via modulo (`new_counter % int1_rate == 0`) au lieu d'un déclenchement one-shot.
- **Registres SFR (`PSW`, `ACC`, `VRMAD1`, `VRMAD2`, `VTRBF`, `P3INT`)** :
  - `SFR_PSW` : le bit 0 (`P`) est en lecture seule matérielle, protégé contre les écritures logicielles, et calculé dynamiquement sur `ACC`.
  - `SFR_ACC` : mise à jour de la parité impaire lors d'une écriture dans le registre.
  - `SFR_VRMAD1` & `SFR_VRMAD2` : gestion d'adresse 9 bits avec bits 7:1 de `VRMAD2` retournant 1 (`0xFE | bit0`).
  - `SFR_VTRBF` : auto-incrémentation de `VRMAD` et synchronisation des registres miroirs `sfr_raw[SFR_VRMAD1]` et `sfr_raw[SFR_VRMAD2]` lorsque `VSEL.bit4` est actif.
  - `SFR_P3INT` : valeur de reset fixée à `0xFD`.
- **Service des interruptions (`servicePendingInterrupt`)** :
  - Retrait des vérifications de masques inexistants sur `IE` pour les sources locales (seul le bit 7 `EA` est le master enable général, chaque périphérique gérant son enable local).

### Added
- 15 nouveaux tests unitaires dans `tests.zig` couvrant tous les cas corrigés (suite passée de 54 à 69 tests automatisés, 100% passants).
- Documentation mise à jour dans `doc/doc_inst.md` et `README.md`.

## [0.1.0] - 2026-10-05

- Cœur CPU Sanyo LC86K87 initial en Zig 0.16.
- 70 instructions décodées et exécutées.
- Support des timers T0, T1, Base Timer et interruptions.
