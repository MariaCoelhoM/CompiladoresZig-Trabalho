# Gramática de Ponto Flutuante Decimal — C99

---

## Gramática BNF

```bnf
decimal-floating-constant
    ::= fractional-constant [ exponent-part ] [ floating-suffix ]
      | digit-sequence exponent-part [ floating-suffix ]

fractional-constant
    ::= [ digit-sequence ] "." digit-sequence
      | digit-sequence "."

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
    ::= "f" | "F"
      | "l" | "L"
```

---

## Tabela DNF

| Forma | Parte Inteira | Ponto       | Fração      | Expoente    | Sufixo   | Exemplo |
| ----- | ------------- | ----------- | ----------- | ----------- | -------- | ------- |
| A     | obrigatório   | obrigatório | obrigatório | opcional    | opcional | `3.14`  |
| B     | obrigatório   | obrigatório | vazio       | opcional    | opcional | `3.`    |
| C     | vazio         | obrigatório | obrigatório | opcional    | opcional | `.5`    |
| D     | obrigatório   | ausente     | ausente     | obrigatório | opcional | `1e10`  |

---

## Diagrama de Estados

```text
START
 │
 ├── digit ──────────────► INT_PART
 │                            │
 │                            ├── '.' ──► AFTER_DOT
 │                            │              │
 │                            │              ├── digit+ ──► FRAC_PART
 │                            │              │                  │
 │                            │              └── (vazio) ──► ACCEPT_OR_EXP
 │                            │
 │                            └── e/E ──► EXP_MARKER
 │
 └── '.' ───────────────► FRAC_ONLY
          digit+               │
                               └── digit+ ──► FRAC_PART

FRAC_PART / ACCEPT_OR_EXP
 │
 └── e/E ──► EXP_MARKER
                 │
                 ├── '+'/'-' ──► EXP_SIGN
                 │                   │
                 └───────────────────┴── digit+ ──► EXP_DIGITS
                                                        │
                                                        └── f/F/l/L ──► SUFFIX ──► ACCEPT ✓
                                                        └── (vazio)             ──► ACCEPT ✓
```