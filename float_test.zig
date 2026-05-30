//! Testes do Lexer de Float Decimal — Zig 0.16.0
//! Este arquivo contém os testes automatizados do lexer.
//! O objetivo é verificar se o analisador léxico reconhece
//! corretamente números de ponto flutuante decimais conforme
//! a especificação C99.

const std = @import("std");

// Importa o lexer implementado no arquivo principal.
const lexer = @import("float_lexer.zig");

// Atalhos para facilitar a escrita dos testes.
const lexFloat = lexer.lexFloat;
const LexError = lexer.LexError;
const FloatSuffix = lexer.FloatSuffix;

// ============================================================
// Funções auxiliares de teste
// ============================================================

/// Verifica se uma entrada é reconhecida corretamente.
///
/// Parâmetros:
/// - src: texto de entrada
/// - suf: sufixo esperado
/// - expected: valor numérico esperado
///
/// Esta função:
/// 1. Executa o lexer.
/// 2. Verifica o lexema retornado.
/// 3. Verifica o sufixo reconhecido.
/// 4. Compara o valor numérico calculado.
fn ok(src: []const u8, suf: FloatSuffix, expected: f64) !void {

    // Executa o lexer.
    const tok = try lexFloat(src);

    // Verifica se o lexema retornado é exatamente igual
    // ao texto fornecido.
    try std.testing.expectEqualStrings(src, tok.lexeme);

    // Verifica se o sufixo identificado está correto.
    try std.testing.expectEqual(suf, tok.suffix);

    // Calcula a diferença absoluta entre
    // o valor esperado e o valor obtido.
    const diff = @abs(tok.value - expected);

    // Como estamos trabalhando com ponto flutuante,
    // usamos uma tolerância numérica.
    try std.testing.expect(diff < 1e-10);
}

/// Verifica se o lexer produz o erro esperado.
///
/// Utilizado para testar entradas inválidas.
fn fail(src: []const u8, expected_err: LexError) !void {
    try std.testing.expectError(expected_err, lexFloat(src));
}

// ============================================================
// Testes da Forma A
//
// Forma A:
// d+ . d+
//
// Exemplos:
// 3.14
// 1.0
// ============================================================

test "A: inteiro.fração" {

    // Float decimal simples.
    try ok("3.14", .none, 3.14);

    // Float decimal com valor inteiro.
    try ok("1.0", .none, 1.0);
}

test "A com expoente" {

    // 3.14 × 10² = 314.0
    try ok("3.14e2", .none, 314.0);

    // 2.0 × 10⁻¹ = 0.2
    try ok("2.0E-1", .none, 0.2);
}

test "A com sufixo" {

    // Sufixo float.
    try ok("3.14f", .f, 3.14);

    // Sufixo long double.
    try ok("3.14L", .l, 3.14);
}

// ============================================================
// Testes da Forma B
//
// Forma B:
// d+ .
//
// Exemplos:
// 3.
// 100.
// ============================================================

test "B: inteiro." {

    // Parte inteira seguida de ponto.
    try ok("3.", .none, 3.0);

    // Outro exemplo válido.
    try ok("100.", .none, 100.0);
}

// ============================================================
// Testes da Forma C
//
// Forma C:
// . d+
//
// Exemplos:
// .5
// .001
// ============================================================

test "C: .fração" {

    // Float iniciado pelo ponto.
    try ok(".5", .none, 0.5);

    // Float pequeno.
    try ok(".001", .none, 0.001);
}

// ============================================================
// Testes da Forma D
//
// Forma D:
// d+ e/E [+-] d+
//
// Nesta forma não existe ponto decimal.
// O expoente é obrigatório.
//
// Exemplos:
// 1e10
// 42E-3
// ============================================================

test "D: expoente obrigatório" {

    // Notação científica.
    try ok("1e10", .none, 1e10);

    // Expoente negativo e sufixo float.
    try ok("42E-3f", .f, 0.042);
}

// ============================================================
// Testes de entradas inválidas
// ============================================================

test "inválidos" {

    // Apenas um ponto não representa um float válido.
    try fail(".", LexError.IsolatedDot);

    // Número inteiro puro não é considerado float.
    try fail("1", LexError.NotAFloat);

    // Expoente sem dígitos.
    try fail("1.0e", LexError.ExponentMissingDigits);

    // Hexadecimal não faz parte do escopo do projeto.
    try fail("0x1.8p+1", LexError.HexNotSupported);
}