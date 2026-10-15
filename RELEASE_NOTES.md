## LC86K87 v0.1.1 — Hardware Accuracy & Instruction Fixes

Cette version apporte des corrections majeures de conformité matérielle par rapport à l'architecture Sanyo LC86K87 et aux références du VMU Dreamcast (`libevmu`).

### 🐛 Corrections de bugs (Bug Fixes)

- **Encodage & calcul `BE @Rj` / `BNE @Rj` (`0x34..0x37`, `0x44..0x47`)** :
  - Taille corrigée à **3 octets** (`opcode`, `imm8`, `rel8`) au lieu de 2.
  - Sémantique conforme : comparaison de `((Rj))` avec l'immédiat `imm8` (au lieu d'ACC).
  - Calcul et mise à jour conforme du Carry flag : `CY = ((Rj)) < imm8`.
  - Calcul du saut relatif corrigé (`pc + 3 + rel8`) et désassemblage `.fmtMR_br` (`@Rj,#xxh,xxxxh`).
- **Préservation de `CY` sur `ROL` et `ROR`** :
  - `ROL` et `ROR` n'écrasent plus le flag Carry (seuls `ROLC` et `RORC` font intervenir `CY`).
- **Protection du bit de parité `PSW.P`** :
  - Les instructions `INC` et `DEC` en mémoire RAM ne corrompent plus le bit `PSW.P` (parité impaire de `ACC`).
  - Actualisation systématique de `PSW.P` pour toutes les instructions modifiant ou chargeant `ACC` (`LD`, `LD @Ri`, `XCH`, `MUL`, `DIV`, `LDC`, `LDF`).
- **Synchronisation du bank d'instructions (`CALLF`)** :
  - Exécution de `syncInstructionBank()` lors de `CALLF` pour valider les bascules de bank en attente (`pending_ext`).
- **Résolution d'adresse indirecte (`@Ri`)** :
  - Résolution des pointeurs indirects dans le bank RAM courant (`currentRamBank()`) au lieu de forcer le bank 0.
- **Timers T0, T1 et Base Timer** :
  - Timer 0 Mode 2 (cascade 16 bits) requiert l'activation conjointe de `T0LRUN` et `T0HRUN`.
  - Timer 1 Mode 2 ne cascade en 16 bits que si `T1LONG | T1HRUN | T1LRUN` sont tous actifs ; sinon `T1H` fonctionne en mode 8 bits autonome sans blocage si `T1LRUN == 0`.
  - Base Timer `INT1` déclenché de façon périodique via modulo (`new_counter % int1_rate == 0`).
- **Registres SFR (`PSW`, `ACC`, `VRMAD1`, `VRMAD2`, `VTRBF`, `P3INT`)** :
  - `SFR_PSW` : bit 0 protégé en écriture et calculé dynamiquement à la lecture.
  - `SFR_ACC` : calcul de la parité impaire à l'écriture.
  - `SFR_VRMAD1` / `SFR_VRMAD2` : espace 9 bits conforme (`VRMAD2` bits 7:1 lus à 1 : `0xFE | bit0`).
  - `SFR_VTRBF` : auto-incrémentation de l'adresse et mise à jour des registres miroirs `VRMAD1/2`.
  - `SFR_P3INT` : valeur de reset fixée à `0xFD`.
- **Interruption dispatch (`servicePendingInterrupt`)** :
  - Suppression des contrôles de masques invalides sur `IE` pour les sources locales.

### ✅ Tests & Validation
- **69 tests automatisés** exécutés et validés avec succès (100% passants) via `zig build test`.
- 15 nouveaux tests unitaires couvrant l'intégralité des corrections matérielles.
