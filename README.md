# LC86K87 — CPU core

Émulation du **Sanyo LC86K87**, CPU 8 bits du Visual Memory Unit de la Dreamcast,
en **Zig 0.16**. Bibliothèque autonome : aucune dépendance, aucun moteur de rendu,
aucun système de fichiers.

## Spécification

| Élément | Implémentation |
|---|---|
| Architecture | 8 bits, espaces mémoire séparés : programme 64 KiB, RAM 512 B, XRAM 256+6 B, SFR 128 |
| Registres | ACC, B, C, SP, PC, PSW |
| PSW | P (parité de ACC), OV, AC, CY, rambk0, irbk0, irbk1 — pas de Z ni S : les conditions de branche testent ACC directement |
| Horloges | RC 879 236 Hz, CF 6 MHz, quartz 32 768 Hz sélectionnés par OCR5:4 ; division /12 ou /6 par OCR7 ; source du base timer par ISL |
| RAM | 512 B internes, 2 banks de 256 B, sélection par PSW.rambk0 |
| XRAM | 0x180-0x1FF : 2 banks de 128 B pour le LCD, 6 B d'icônes, sélection par XBNK |
| SFR | 0x100-0x17F, effets de bord implémentés sur T0CNT, T0PRR, T1CNT, BTCR, OCR, ISL, PCON, P3INT, EXT, FPR, VSEL, VRMAD1/2, VTRBF, MPLRST |
| Timers | Timer 0 16 bits avec prescaler, Timer 1 16 bits, Base timer 14 bits |
| Interruptions | 6 sources : T0L, base timer, T0H, T1, P3, Maple IRQ9 — niveau et front, HALT et réveil, RETI imbriqués |
| Mémoire programme | fenêtre de 64 KiB, 3 banks : ROM, flash0, flash1, par EXT (0x88/0x89) et FPR |
| Ports | P3 (boutons, active-low, front d'IRQ), P7 (lecture seule) |

## ISA

- **70 instructions** (manuel de développement LC86K, p. 561), 45 mnémoniques
- **256 opcodes sur 256 décodés**
- Modes d'adressage : implicite, immédiat (`#i8`), direct `d9` (adresse 9 bits), indirect `@Ri`
- Taille en octets et nombre de cycles de chaque opcode dans `isa.TABLE`


Répartition des 256 opcodes :

| Famille | Instructions | Opcodes |
|---|---|---|
| sans effet | NOP | `0x00` |
| arithmétique | ADD, ADDC, SUB, SUBC, INC, DEC, MUL, DIV | `0x30`, `0x40`, `0x62-0x67`, `0x72-0x77`, `0x81-0x87`, `0x91-0x97`, `0xA1-0xA7`, `0xB1-0xB7` |
| logique | AND, OR, XOR | `0xD1-0xD7`, `0xE1-0xE7`, `0xF1-0xF7` |
| rotations | ROL, ROLC, ROR, RORC | `0xC0`, `0xD0`, `0xE0`, `0xF0` |
| transfert | LD, ST, MOV, XCH, LDC | `0x02-0x07`, `0x12-0x17`, `0x22-0x27`, `0x60-0x61`, `0x70-0x71`, `0xC1-0xC7` |
| mémoire flash | LDF, STF | `0x50`, `0x51` |
| saut | BR, BRF, JMP, JMPF | `0x01`, `0x11`, `0x21`, `0x28-0x2F`, `0x38-0x3F` |
| branchement | BZ, BNZ, BP, BN, BPC, BE, BNE, DBNZ | `0x31-0x37`, `0x41-0x47`, `0x48-0x4F`, `0x52-0x57`, `0x58-0x5F`, `0x68-0x6F`, `0x78-0x7F`, `0x80`, `0x88-0x8F`, `0x90`, `0x98-0x9F` |
| appel | CALL, CALLR, CALLF, RET, RETI | `0x08-0x0F`, `0x10`, `0x18-0x1F`, `0x20`, `0xA0`, `0xB0` |
| bits | NOT1, CLR1, SET1 | `0xA8-0xAF`, `0xB8-0xBF`, `0xC8-0xCF`, `0xD8-0xDF`, `0xE8-0xEF`, `0xF8-0xFF` |

Tableau détaillé instruction par instruction : [doc/doc_inst.md](doc/doc_inst.md).

## Validation

- **54 tests automatisés**, `zig build test` → 54/54
- **67 des 70 instructions (96 %) ont au moins un test dédié**
- **Sources des tests** : les exemples VMC-151 à VMC-224 du manuel de développement,
  plus des tests unitaires écrits à partir de séquences d'opcodes
- Couvert : flags CY/AC/OV/P, arithmétique avec carry et overflow, rotations,
  branches conditionnelles prises et non prises, branche sur bit avec effacement
  (BPC), pile, CALL/CALLF/RET imbriqués, bascule de bank par EXT
- :warning: Non couvert : `CALLR`, `LDF`/`STF`, coût de cycle mesuré, effets de bord des
  périphériques

La colonne VMC de [doc/doc_inst.md](doc/doc_inst.md) donne la référence de chaque
test.

## Reste à faire

1. `CALLR` (`0x10`) : implémentée mais sans test ; le calcul de cible
   (`return_addr + offset - 1`) doit être confronté au manuel
2. `LDF`/`STF` (`0x50`/`0x51`) : implémentées mais sans test ; vérifier l'adressage
   17 bits et la séquence d'écriture protégée par FPR
3. Coût de cycle : valeurs reprises du manuel, jamais mesurées ; les cycles des
   branches (prise ou non), des sauts de page (`JMPF`, `CALLF`) et des boucles
   `DBNZ` sont des estimations
4. SFR périphériques : `MCR`, `CNR`, `TDR`, `VCCR`, `MPLSTA`, `MPLRST` ne sont que
   des stockages — pas de modèle LCD, PWM ni Maple
5. Port 1 (`0x44`-`0x46`)
6. Série : `SCON0`/`SCON1`, `SBUF0`/`SBUF1`, `SBR` absents
7. Work RAM : chemin `VRMAD`/`VTRBF` 
8. Registre IP : le masquage global (`IE` bit 7) et les bits d'enable par
   périphérique sont gérés, mais IP n'est pas lu source par source

## Construire et tester

```sh
zig build test    
zig build         # bibliothèque statique liblc86k.a
```

Un fichier test et un programme de test sont disponibles.

```sh
zig build test --summary all
Build Summary: 5/5 steps succeeded; 57/57 tests passed
test success
├─ run test 54 pass (54 total) 16ms MaxRSS:4M
│  └─ compile test Debug native cached 55ms MaxRSS:21M
└─ run test 3 pass (3 total) 31ms MaxRSS:5M
   └─ compile test Debug native cached 55ms MaxRSS:21M
```

Zig 0.16 requis. 

## Utilisation

```zig
const lc86k = @import("lc86k");

var rom: [65536]u8 = @splat(0);
rom[0] = 0x81; rom[1] = 0x13; // ADD A, #13h
var cpu = lc86k.Cpu.init(&rom);

const cycles = lc86k.step(&cpu); // cycles consommés par l'instruction
```

`Cpu.init(rom)` reçoit la bank ROM de 64 KiB. Les champs publics (`a`, `b`, `c`,
`sp`, `pc`, `psw`, `halted`, `sfr_raw`, `p3_buttons`...) sont modifiables
directement, ce qui permet d'écrire des tests instruction par instruction comme
`tests.zig`.

Trace d'exécution :

```zig
lc86k.debug.log_level = .trace;
lc86k.debug.log_sink = mySink; // sinon stderr
```

## Fichiers

| Fichier | Contenu |
|---|---|
| `root.zig` | façade du module, point d'entrée des consommateurs |
| `lc86K.zig` | état du CPU, espaces mémoire, accès SFR, horloges, dispatch des interruptions |
| `isa.zig` | table des 256 opcodes : mnémonique, mode, taille, cycles, format d'affichage |
| `decode.zig` | sémantique d'exécution d'une instruction |
| `timer.zig` | comptage Timer 0, Timer 1, Base timer |
| `debug.zig` | désassembleur, trace, détection de boucle |
| `tests.zig` | 54 tests |

## Documentation

- [doc/doc_inst.md](doc/doc_inst.md) — les 70 instructions, flags, opcodes, état des tests
- [doc/doc_timer.md](doc/doc_timer.md) — comportement des timers et base timer

## Références

- libevmu de Falco Girgis (MIT), la référence communautaire pour le comportement
  matériel du VMU : <https://github.com/gyrovorbis/libevmu>,
  <http://vmu.falcogirgis.net>
- <https://dreamcast.wiki>
- Manuel de développement du VMU (Sega, 1996) et Hardware Manual LC86K Series
  (Sanyo) : documents protégés par le droit d'auteur, non redistribués ici

## Licence

MIT — voir [LICENSE](LICENSE).
