//! Testes do Lexer de Ponto Flutuante Decimal — C99       Mudar a versão pra 0.16.0
//! Execute com: zig test float_test.zig

const std = @import("std");
const lexer = @import("float_lexer.zig");
const lexFloat = lexer.lexFloat;
const LexError = lexer.LexError;
const FloatSuffix = lexer.FloatSuffix;

// ─── Helpers ───────────────────────────────────────────────────────────────

/// Espera sucesso: confere lexeme, sufixo e valor numérico.
fn ok(src: []const u8, suf: FloatSuffix, expected: f64) !void {
    const tok = try lexFloat(src);
    try std.testing.expectEqualStrings(src, tok.lexeme);
    try std.testing.expectEqual(suf, tok.suffix);
    const diff = @abs(tok.value - expected);
    if (diff > 1e-10) {
        std.debug.print("VALOR [{s}]: esperado={d} obtido={d}\n", .{ src, expected, tok.value });
        return error.TestUnexpectedResult;
    }
}

/// Espera erro específico.
fn fail(src: []const u8, expected_err: LexError) !void {
    const result = lexFloat(src);
    if (result) |tok| {
        std.debug.print("DEVERIA FALHAR [{s}] mas retornou '{s}'\n", .{ src, tok.lexeme });
        return error.TestExpectedError;
    } else |err| {
        try std.testing.expectEqual(expected_err, err);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Forma A: digits . digits [exp] [suf]
// ═══════════════════════════════════════════════════════════════════════════

test "A: inteiro.fração básico" {
    try ok("3.14", .none, 3.14);
    try ok("0.0", .none, 0.0);
    try ok("123.456", .none, 123.456);
    try ok("1.0", .none, 1.0);
}

test "A+exp: inteiro.fração com expoente" {
    try ok("3.14e2", .none, 314.0);
    try ok("1.5e+3", .none, 1500.0);
    try ok("2.0E-1", .none, 0.2);
    try ok("1.0e0", .none, 1.0);
}

test "A+suf: inteiro.fração com sufixo" {
    try ok("3.14f", .f, 3.14);
    try ok("3.14F", .f, 3.14);
    try ok("3.14l", .l, 3.14);
    try ok("3.14L", .l, 3.14);
}

test "A+exp+suf: inteiro.fração com expoente e sufixo" {
    try ok("1.5e3f", .f, 1500.0);
    try ok("2.0E2L", .l, 200.0);
    try ok("1.0e+0f", .f, 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Forma B: digits . [exp] [suf]   (sem parte fracionária)
// ═══════════════════════════════════════════════════════════════════════════

test "B: inteiro com ponto final" {
    try ok("3.", .none, 3.0);
    try ok("0.", .none, 0.0);
    try ok("100.", .none, 100.0);
}

test "B+exp: inteiro. com expoente" {
    try ok("3.e2", .none, 300.0);
    try ok("1.E-1", .none, 0.1);
}

test "B+suf: inteiro. com sufixo" {
    try ok("3.f", .f, 3.0);
    try ok("3.L", .l, 3.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Forma C: . digits [exp] [suf]   (sem parte inteira)
// ═══════════════════════════════════════════════════════════════════════════

test "C: ponto seguido de fração" {
    try ok(".5", .none, 0.5);
    try ok(".001", .none, 0.001);
    try ok(".0", .none, 0.0);
    try ok(".9999", .none, 0.9999);
}

test "C+exp: .fração com expoente" {
    try ok(".5e1", .none, 5.0);
    try ok(".1E+2", .none, 10.0);
    try ok(".5e-1", .none, 0.05);
}

test "C+suf: .fração com sufixo" {
    try ok(".5f", .f, 0.5);
    try ok(".5L", .l, 0.5);
}

// ═══════════════════════════════════════════════════════════════════════════
// Forma D: digits exponent [suf]  (sem ponto — expoente obrigatório)
// ═══════════════════════════════════════════════════════════════════════════

test "D: inteiro com expoente (sem ponto)" {
    try ok("1e10", .none, 1e10);
    try ok("42E0", .none, 42.0);
    try ok("1e+5", .none, 1e5);
    try ok("2E-3", .none, 0.002);
}

test "D+suf: inteiro+expoente com sufixo" {
    try ok("1e10f", .f, 1e10);
    try ok("1E2L", .l, 100.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Valores especiais
// ═══════════════════════════════════════════════════════════════════════════

test "zero em todas as formas" {
    try ok("0.0", .none, 0.0);
    try ok("0.", .none, 0.0);
    try ok(".0", .none, 0.0);
    try ok("0e0", .none, 0.0);
}

test "números muito pequenos e grandes" {
    try ok("1e-300", .none, 1e-300);
    try ok("1e+300", .none, 1e+300);
    try ok("1.7e308", .none, 1.7e308);
}

// ═══════════════════════════════════════════════════════════════════════════
// Casos de ERRO — devem falhar
// ═══════════════════════════════════════════════════════════════════════════

test "erro: string vazia" {
    try fail("", LexError.NotAFloat);
}

test "erro: ponto isolado" {
    try fail(".", LexError.IsolatedDot);
}

test "erro: inteiro puro sem ponto nem expoente" {
    // "1" sozinho é inteiro, não float
    try fail("1", LexError.NotAFloat);
    try fail("42", LexError.NotAFloat);
}

test "erro: expoente sem dígitos" {
    try fail("1.0e", LexError.ExponentMissingDigits);
    try fail("1.0e+", LexError.ExponentMissingDigits);
    try fail("1.0E-", LexError.ExponentMissingDigits);
    try fail("1e", LexError.ExponentMissingDigits);
}

test "erro: hexadecimal rejeitado" {
    try fail("0x1.8p+1", LexError.HexNotSupported);
    try fail("0X0p0", LexError.HexNotSupported);
}

test "erro: letras sem sentido" {
    try fail("abc", LexError.NotAFloat);
    try fail("xyz", LexError.NotAFloat);
}

// ═══════════════════════════════════════════════════════════════════════════
// Integridade do slice (lexeme aponta para o input original)
// ═══════════════════════════════════════════════════════════════════════════

test "lexeme é slice do input original" {
    const src = "3.14";
    const tok = try lexFloat(src);
    try std.testing.expectEqual(src.ptr, tok.lexeme.ptr);
    try std.testing.expectEqual(src.len, tok.lexeme.len);
}
