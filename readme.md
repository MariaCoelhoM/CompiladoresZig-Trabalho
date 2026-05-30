# Lexer de Ponto Flutuante Decimal — C99 em Zig 0.16.0

Projeto acadêmico desenvolvido em Zig 0.16.0 para reconhecimento léxico de números de ponto flutuante decimais conforme a especificação C99.

---

# Objetivo

Implementar um lexer capaz de reconhecer números de ponto flutuante decimais da linguagem C99.

O sistema:

* reconhece constantes float decimais
* aceita expoentes
* aceita sufixos
* rejeita hexadecimal
* valida erros léxicos
* executa testes automatizados

---

# Tecnologias

* Zig 0.16.0
* Especificação C99
* Lexer manual
* Testes automatizados

---

# Estrutura do Projeto

```text
.
├── float_grammar.md
├── float_lexer.zig
├── float_test.zig
└── README.md
```

---

# Arquivos

## `float_grammar.md`

Contém:

* gramática BNF
* tabela DNF
* exemplos válidos
* exemplos inválidos
* diagrama de estados
* regras C99

---

## `float_lexer.zig`

Implementa o lexer responsável por:

* analisar o literal
* validar a estrutura
* identificar erros
* converter para `f64`

---

## `float_test.zig`

Contém testes automatizados utilizando:

```zig
std.testing
```

Os testes verificam:

* formas válidas
* formas inválidas
* expoentes
* sufixos
* erros léxicos

---

# Gramática Reconhecida

## Formas válidas

### Forma A

```text
d+ . d+
```

Exemplo:

```text
3.14
```

---

### Forma B

```text
d+ .
```

Exemplo:

```text
3.
```

---

### Forma C

```text
. d+
```

Exemplo:

```text
.5
```

---

### Forma D

```text
d+ e/E [+-] d+
```

Exemplo:

```text
1e10
```

---

# Exemplos Aceitos

```text
3.14
3.
.5
1e10
42E-3f
3.14L
```

---

# Exemplos Rejeitados

```text
.
1
1.0e
0x1.8p+1
abc
```

---

# Como Executar

## Instalar Zig 0.16.0

Verificar instalação:

```bash
zig version
```

Saída esperada:

```text
0.16.0
```

---

# Executar os testes

```bash
zig test float_test.zig
```

Saída esperada:

```text
All tests passed.
```

---

# Características do Lexer

O lexer implementa:

* reconhecimento decimal
* expoente opcional
* sufixos opcionais
* validação léxica
* rejeição de hexadecimal

---

