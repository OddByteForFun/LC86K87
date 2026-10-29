# Analyse Détaillée de l'Anomalie Frontière MUT-01 : Carry Flag ADD (`> 0xFF` vs `>= 0xFF`)

**Projet :** Émulateur Patrimonial Sanyo LC86K87 (Sega Dreamcast Visual Memory Unit)  
**ID Mutant :** `MUT-01`  
**Catégorie micro-architecturale :** *Arithmetic / Flag CY (Carry)*  
**Objectif de l'analyse :** Démontrer pourquoi les exemples officiels du manuel constructeur Sanyo de 1998 sont aveugles face à une erreur d'opérateur relationnel aux bornes, et comment l'approche formelle sans oracle (Test Métamorphique MR10 & Bisimulation Sail) neutralise l'anomalie.

---

## 1. L'Erreur Micro-Architecturale Injectée (`MUT-01`)

Dans le moteur d'exécution séquentiel de l'émulateur (`decode.zig`, lignes 88 à 97), l'instruction `ADD` non signée sur l'accumulateur 8 bits est évaluée dans un registre élargi 16 bits afin de capturer l'éventuelle retenue (*Carry Flag* $CY$) :

```zig
// =========================================================================
// CODE NOMINAL CORRECT :
// =========================================================================
const v = readOp8(cpu, dec);
const result: u16 = @as(u16, cpu.a) + @as(u16, v);

// Le Carry Flag doit être levé si et seulement si la somme dépasse 255 :
cpu.psw.cy = result > 0xFF; 

// =========================================================================
// CODE MUTÉ (MUT-01 - Erreur frontière classique de rétro-ingénierie) :
// =========================================================================
const v = readOp8(cpu, dec);
const result: u16 = @as(u16, cpu.a) + @as(u16, v);

// ERREUR : Substitution de l'opérateur relationnel strict '>' par '>='
cpu.psw.cy = result >= 0xFF; 
```

### Analyse sémantique de la faute
* En arithmétique 8 bits non signée, l'intervalle des valeurs représentables est $[0, 255]$ ($[0x00, 0xFF]$).
* Lorsque la somme vaut **exactement 255** (par exemple $255 + 0$, ou $200 + 55$, ou $128 + 127$) :
  * **Comportement matériel réel :** $255 > 255 \implies \text{FAUX}$. Le résultat tient intégralement dans l'accumulateur 8 bits ; aucun débordement n'a lieu, donc $CY = 0$.
  * **Comportement du mutant `MUT-01` :** $255 \ge 255 \implies \text{VRAI}$. L'émulateur lève erronément le drapeau $CY = 1$.
* **Conséquence en émulation :** Toute instruction arithmétique ultérieure dépendante de la retenue (comme `ADDC` ou un saut conditionnel sur carry) exécutera une branche de code totalement corrompue en jeu.

---

## 2. Le Programme d'Exemple dans le Manuel Constructeur Officiel

Dans le manuel officiel de Sanyo (*LC86000 Series Hardware Manual*, document `VMU.pdf`), la section consacrée aux instructions arithmétiques `ADD` et `ADDC` (pages 561 et 570, exemples VMC-156 et VMC-158) fournit le programme de référence suivant :

```text
Exemple VMC-158 officiel Sanyo (VMU.pdf) :
-------------------------------------------------------------------------
Instructions           | Accumulateur | CY  | AC  | OV  | Commentaire
-------------------------------------------------------------------------
MOV  #055H, ACC        | ACC = 0x55   | -   | -   | -   | Init ACC à 85
ADD  #013H             | ACC = 0x68   | 0   | 0   | 0   | Somme = 104
ADDC #00AH             | ACC = 0x72   | 0   | 1   | 0   | Somme = 114
ADDC #00FH             | ACC = 0x81   | 0   | 0   | 1   | Somme = 129
ADDC #080H             | ACC = 0x01   | 1   | 0   | 0   | Somme = 257 (Débordement)
ADDC #001H             | ACC = 0x03   | 0   | 0   | 0   | Somme = 3
-------------------------------------------------------------------------
```

---

## 3. La Retranscription Fidèle dans le Banc de Test VMC (`tests.zig`)

Le développeur de l'émulateur a fidèlement transcrit cet exemple officiel sous la forme d'un test unitaire automatisé (`tests.zig`, lignes 128 à 154) :

```zig
test "VMC-158 ADDC imm example" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0x23; rom[1] = 0x00; rom[2] = 0x55; // MOV #055H,ACC
    rom[3] = 0x81; rom[4] = 0x13;                 // ADD #013H
    rom[5] = 0x91; rom[6] = 0x0A;                 // ADDC #00AH
    rom[7] = 0x91; rom[8] = 0x0F;                 // ADDC #00FH
    rom[9] = 0x91; rom[10] = 0x80;                // ADDC #080H
    rom[11] = 0x91; rom[12] = 0x01;               // ADDC #001H

    _ = step(&cpu); // MOV
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x68), cpu.a);
    try testing.expect(!cpu.psw.cy); // Assertion Carry : 104

    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x72), cpu.a);
    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x81), cpu.a);

    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x01), cpu.a);
    try testing.expect(cpu.psw.cy);  // Assertion Carry : 257

    _ = step(&cpu); try testing.expectEqual(@as(u8, 0x03), cpu.a);
    try testing.expect(!cpu.psw.cy);
}
```

---

## 4. Démonstration Mathématique de l'Angle Mort du Manuel Constructeur

Pourquoi ce test officiel est-il **totalement incapable de détecter l'erreur `MUT-01`** ?

Examinons la valeur de vérité de la condition sur chaque calcul du test constructeur :

| Étape | Calcul évalué | Somme réelle | Évaluation nominale (`result > 0xFF`) | Évaluation du mutant (`result >= 0xFF`) | Le mutant est-il détecté ? |
| :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | $85 + 19$ | **104** | `104 > 255` $\implies$ **FAUX** | `104 >= 255` $\implies$ **FAUX** | ❌ Non (Même résultat) |
| 2 | $104 + 10$ | **114** | `114 > 255` $\implies$ **FAUX** | `114 >= 255` $\implies$ **FAUX** | ❌ Non (Même résultat) |
| 3 | $114 + 15$ | **129** | `129 > 255` $\implies$ **FAUX** | `129 >= 255` $\implies$ **FAUX** | ❌ Non (Même résultat) |
| 4 | $129 + 128$ | **257** | `257 > 255` $\implies$ **VRAI** | `257 >= 255` $\implies$ **VRAI** | ❌ Non (Même résultat) |
| 5 | $1 + 1 + 1$ | **3** | `3 > 255` $\implies$ **FAUX** | `3 >= 255` $\implies$ **FAUX** | ❌ Non (Même résultat) |

**Conclusion :**  
Dans toutes les valeurs choisies par les ingénieurs de Sanyo en 1998, la somme est soit **strictement inférieure à 255**, soit **strictement supérieure à 255**.  
Le cas frontière singulier où $\mathbf{Somme = 255}$ n'est **JAMAIS testé**.

Par conséquent, l'émulateur muté avec un bug d'opérateur relationnel passe **100 % des tests du manuel avec succès**. Le mutant `MUT-01` **SURVIT** aux tests officiels.

---

## 5. Comment l'Approche sans Oracle Élimine le Mutant

### A. Par la Relation Métamorphique MR10 (`metamorphic_tests.zig`)
Dans notre suite de vérification sans oracle, la relation MR10 intègre explicitement la vérification des points singuliers du domaine :

```zig
test "MR10: Arithmetic Flag Partition Invariance - ADD (CY, AC, P)" {
    var rom: [65536]u8 = undefined;
    var cpu = makeCpu(&rom);

    rom[0] = 0x81; // ADD imm

    // Cas frontière critique formalisé : 255 + 0 = 255 (AUCUN débordement)
    rom[1] = 0x00;
    cpu.a = 0xFF;  // ACC = 255
    cpu.pc = 0;
    _ = step(&cpu); // Exécute 255 + 0 = 255

    // Invariant formel : Le Carry doit impérativement rester à 0 !
    try testing.expect(!cpu.psw.cy);
}
```

* **Exécution sur le mutant `MUT-01` :**  
  $255 \ge 255$ est évalué à `true` $\implies$ `cpu.psw.cy = true`.  
  L'assertion `try testing.expect(!cpu.psw.cy)` échoue immédiatement :
  ```text
  Test failure: expected false, found true
  >>> MUT-01 KILLED par MR10 !
  ```

### B. Par la Bisimulation Formelle Sail Exhaustive (`sail_test.zig`)
Notre modèle déclaratif Cambridge Sail évalue de manière exhaustive les $256 \times 256 = 65\,536$ combinaisons possibles de $(A, \text{imm})$.

Lorsqu'il évalue le couple $(A = 255, \text{imm} = 0)$ :
* Le modèle mathématique Sail calcule : $\text{CY}_{\text{Sail}} = 0$.
* L'émulateur muté Zig calcule : $\text{CY}_{\text{Zig}} = 1$.
* La comparaison bit-à-bit détecte immédiatement la divergence sur le bit 7 du mot d'état $PSW$ :
  ```text
  Sail PSW (0x00) != Zig PSW (0x80)
  >>> MUT-01 KILLED par Bisimulation Sail !
  ```

---

## 6. Portée Épistémologique pour l'Article et la Thèse

Ce cas précis illustre de manière irréfutable :
1. **L'illusion de conformité des documentations constructeur :** Un émulateur peut valider 100 % des tests officiels d'un fabricant tout en abritant des régressions micro-architecturales latentes.
2. **La puissance du Test Métamorphique aux bornes :** L'exploration systématique des frontières singulières débusque les anomalies invisibles aux scénarios fonctionnels conventionnels.
3. **La complémentarité de la Bisimulation Déclarative :** Le modèle Sail apporte l'oracle exhaustif absolu sur le domaine fini, confirmant l'élimination définitive du bug sans recours au composant physique d'origine.
