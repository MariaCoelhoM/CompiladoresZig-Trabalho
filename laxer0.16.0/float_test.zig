//! Testes do Lexer de Float Decimal — Zig 0.16.0

const std = @import("std");
const lexer = @import("float_lexer.zig");

const lexFloat = lexer.lexFloat;
const LexError = lexer.LexError;
const FloatSuffix = lexer.FloatSuffix;

fn ok(src: []const u8, suf: FloatSuffix, expected: f64) !void {
    const tok = try lexFloat(src);

    try std.testing.expectEqualStrings(src, tok.lexeme);
    try std.testing.expectEqual(suf, tok.suffix);

    const diff = @abs(tok.value - expected);

    try std.testing.expect(diff < 1e-10);
}

fn fail(src: []const u8, expected_err: LexError) !void {
    try std.testing.expectError(expected_err, lexFloat(src));
}

// ─────────────────────────────────────────────────────────────
// Forma A
// ─────────────────────────────────────────────────────────────

test "A: inteiro.fração" {
    try ok("3.14", .none, 3.14);
    try ok("1.0", .none, 1.0);
}

test "A com expoente" {
    try ok("3.14e2", .none, 314.0);
    try ok("2.0E-1", .none, 0.2);
}

test "A com sufixo" {
    try ok("3.14f", .f, 3.14);
    try ok("3.14L", .l, 3.14);
}

// ─────────────────────────────────────────────────────────────
// Forma B
// ─────────────────────────────────────────────────────────────

test "B: inteiro." {
    try ok("3.", .none, 3.0);
    try ok("100.", .none, 100.0);
}

// ─────────────────────────────────────────────────────────────
// Forma C
// ─────────────────────────────────────────────────────────────

test "C: .fração" {
    try ok(".5", .none, 0.5);
    try ok(".001", .none, 0.001);
}

// ─────────────────────────────────────────────────────────────
// Forma D
// ─────────────────────────────────────────────────────────────

test "D: expoente obrigatório" {
    try ok("1e10", .none, 1e10);
    try ok("42E-3f", .f, 0.042);
}

// ─────────────────────────────────────────────────────────────
// Casos inválidos
// ─────────────────────────────────────────────────────────────

test "inválidos" {
    try fail(".", LexError.IsolatedDot);
    try fail("1", LexError.NotAFloat);
    try fail("1.0e", LexError.ExponentMissingDigits);
    try fail("0x1.8p+1", LexError.HexNotSupported);
}