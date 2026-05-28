# Gramática de Ponto Flutuante Decimal — C99

Especificação conforme **ISO/IEC 9899:1999 (C99)**, §6.4.4.2 — restrita à forma **decimal**.

---

## 1. Gramática BNF

```
decimal-floating-constant
    ::= fractional-constant [ exponent-part ] [ floating-suffix ]
      | digit-sequence exponent-part [ floating-suffix ]

fractional-constant
    ::= [ digit-sequence ] "." digit-sequence     (* formas A e C *)
      | digit-sequence "."                         (* forma B      *)

exponent-part
    ::= ("e" | "E") [ sign ] digit-sequence

sign
    ::= "+" | "-"

digit-sequence
    ::= digit { digit }

digit
    ::= "0" | "1" | "2" | "3" | "4"
      | "5" | "6" | "7" | "8" | "9"

floating-suffix
    ::= "f" | "F"    (* → float       *)
      | "l" | "L"    (* → long double *)
```

> Se nenhum sufixo for informado, o tipo é **`double`** (padrão C99).

---

## 2. Tabela DNF — Formas Disjuntivas Normais

Cada linha é uma **conjunção** de partes; as linhas formam a **disjunção** completa de literais válidos.

| Forma | Parte inteira | Ponto | Parte fracionária | Expoente `e/E[±]d+` | Sufixo | Exemplo |
|:-----:|:-------------:|:-----:|:-----------------:|:-------------------:|:------:|---------|
| **A** | `d+` | `.` | `d+` | opcional | opcional | `3.14`, `3.14e2f` |
| **B** | `d+` | `.` | *(vazio)* | opcional | opcional | `3.`, `3.e2` |
| **C** | *(vazio)* | `.` | `d+` | opcional | opcional | `.5`, `.5e-1L` |
| **D** | `d+` | *(sem ponto)* | *(sem fração)* | **obrigatório** | opcional | `1e10`, `42E-3f` |

Legenda: `d+` = um ou mais dígitos decimais; campos *opcionais* podem ser omitidos.

### Tabela de sufixos

| Sufixo | Tipo C | Tamanho típico |
|--------|--------|---------------|
| *(ausente)* | `double` | 64 bits |
| `f` ou `F` | `float` | 32 bits |
| `l` ou `L` | `long double` | 80 ou 128 bits |

---

## 3. Diagrama de Transição de Estados

```
           ┌─────────────────────────────────────────────────────┐
           │           decimal-floating-constant                 │
           └─────────────────────────────────────────────────────┘

  ┌───────┐   digit   ┌──────────┐    '.'    ┌──────────┐
  │ START ├──────────►│ INT_PART ├──────────►│ AFTER_DOT│
  │       │           └────┬─────┘           └────┬─────┘
  │       │  '.'           │                      │ digit
  │       ├──────────────► │ (salta INT_PART)     ▼
  └───────┘                │             ┌──────────────┐
                           │             │  FRAC_PART   │
                           │             └──────┬───────┘
                           │                    │
                           └────────────────────┘
                                    │
                              e / E ?
                                    │
                           ┌────────▼────────┐
                           │  EXP_MARKER     │  consome 'e'/'E'
                           └────────┬────────┘
                                    │
                              + / - ?  (opcional)
                                    │
                           ┌────────▼────────┐
                           │  EXP_SIGN       │  consome sinal
                           └────────┬────────┘
                                    │ digit+
                           ┌────────▼────────┐
                           │  EXP_DIGITS     │  ← obrigatório
                           └────────┬────────┘
                                    │
                              f/F/l/L ?  (opcional)
                                    │
                           ┌────────▼────────┐
                           │    ACCEPT ✓     │
                           └─────────────────┘

  Restrição forma D: INT_PART sem '.' → expoente obrigatório.
  Ponto isolado sem dígitos → ERRO IsolatedDot.
  Expoente 'e'/'E' sem dígitos → ERRO ExponentMissingDigits.
```

---

## 4. Exemplos Válidos e Inválidos

### ✅ Válidos

| Literal | Forma | Tipo | Valor |
|---------|-------|------|-------|
| `3.14` | A | `double` | 3.14 |
| `3.14f` | A | `float` | 3.14 |
| `3.14L` | A | `long double` | 3.14 |
| `3.` | B | `double` | 3.0 |
| `3.e2` | B+exp | `double` | 300.0 |
| `.5` | C | `double` | 0.5 |
| `.5e-1L` | C+exp | `long double` | 0.05 |
| `1e10` | D | `double` | 1×10¹⁰ |
| `42E-3f` | D | `float` | 0.042 |
| `1.0e+0` | A+exp | `double` | 1.0 |

### ❌ Inválidos

| Literal | Erro | Motivo |
|---------|------|--------|
| `.` | `IsolatedDot` | ponto sem nenhum dígito |
| `1` | `NotAFloat` | inteiro puro, não é float |
| `1.0e` | `ExponentMissingDigits` | 'e' sem dígitos |
| `1.0e+` | `ExponentMissingDigits` | sinal sem dígitos |
| `0x1.8p+1` | `HexNotSupported` | hexadecimal não aceito |
| `abc` | `NotAFloat` | nenhum dígito |

---

## 5. Referência

- ISO/IEC 9899:1999, §6.4.4.2 — *Floating constants*
