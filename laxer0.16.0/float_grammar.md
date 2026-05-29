# Gramática de Ponto Flutuante Decimal — C99 (Zig 0.16.0)

Especificação baseada na norma:

* **(C99)**
* Restrita apenas a números decimais.
* Compatível com o lexer implementado em **Zig 0.16.0**.

---

# Objetivo

Este projeto implementa um lexer capaz de reconhecer constantes de ponto flutuante decimais conforme a especificação C99.

O lexer:

* aceita apenas floats decimais
* reconhece expoentes (`e` e `E`)
* reconhece sufixos (`f/F/l/L`)
* rejeita números hexadecimais
* identifica erros léxicos

---

# Gramática BNF

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

# Formas Reconhecidas

## Forma A — Parte inteira + fração

```text
d+ . d+
```

Exemplos:

```text
3.14
10.25
1.0e2
```

---

## Forma B — Parte inteira + ponto

```text
d+ .
```

Exemplos:

```text
3.
7.e2
100.
```

---

## Forma C — Apenas fração

```text
. d+
```

Exemplos:

```text
.5
.25
.5e-1
```

---

## Forma D — Expoente obrigatório

```text
d+ e/E [+-] d+
```

Exemplos:

```text
1e10
42E-3
7e+2
```

---

# Tabela DNF

| Forma | Parte Inteira | Ponto       | Fração      | Expoente    | Sufixo   | Exemplo |
| ----- | ------------- | ----------- | ----------- | ----------- | -------- | ------- |
| A     | obrigatório   | obrigatório | obrigatório | opcional    | opcional | `3.14`  |
| B     | obrigatório   | obrigatório | vazio       | opcional    | opcional | `3.`    |
| C     | vazio         | obrigatório | obrigatório | opcional    | opcional | `.5`    |
| D     | obrigatório   | ausente     | ausente     | obrigatório | opcional | `1e10`  |

---

# Sufixos Aceitos

| Sufixo     | Tipo C99      |
| ---------- | ------------- |
| ausente    | `double`      |
| `f` ou `F` | `float`       |
| `l` ou `L` | `long double` |

---

# Diagrama de Estados

```text
START
 │
 ├── digit ─────────► INT_PART
 │                       │
 │                       ├── '.' ─► AFTER_DOT
 │                       │              │
 │                       │              └── digit+ ─► FRAC_PART
 │                       │
 │                       └── e/E ─► EXPONENT
 │
 └── '.' ───────────► FRAC_PART
```

---

# Regras Implementadas

## Aceita

```text
3.14
3.
.5
1e10
42E-3f
3.14L
```

---

## Rejeita

```text
.
1
1.0e
0x1.8p+1
abc
```

---

# Erros Léxicos

| Erro                    | Descrição                   |
| ----------------------- | --------------------------- |
| `NotAFloat`             | não representa float válido |
| `IsolatedDot`           | ponto isolado               |
| `ExponentMissingDigits` | expoente sem dígitos        |
| `HexNotSupported`       | hexadecimal não suportado   |
| `FloatParseError`       | falha ao converter valor    |

---

# Compatibilidade

Este projeto foi desenvolvido para:

```text
Zig 0.16.0
```

---

# Referência

* ISO/IEC 9899:1999 — Programming Languages C
* Seção §6.4.4.2 — Floating Constants
