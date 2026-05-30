//! Lexer de Ponto Flutuante Decimal — C99
//! Compatível com Zig 0.16.0

const std = @import("std");

// ─────────────────────────────────────────────────────────────
// Tipos públicos
// ─────────────────────────────────────────────────────────────

pub const FloatSuffix = enum {
    none,
    f,
    l,
};

pub const FloatToken = struct {
    lexeme: []const u8,
    suffix: FloatSuffix,
    value: f64,
};

pub const LexError = error{
    NotAFloat,
    IsolatedDot,
    ExponentMissingDigits,
    HexNotSupported,
    FloatParseError,
};

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn skipDigits(src: []const u8, pos: usize) usize {
    var i = pos;

    while (i < src.len and isDigit(src[i])) {
        i += 1;
    }

    return i;
}

fn toF64(lexeme: []const u8) !f64 {
    var end = lexeme.len;

    if (end > 0) {
        const last = lexeme[end - 1];

        if (
            last == 'f' or
            last == 'F' or
            last == 'l' or
            last == 'L'
        ) {
            end -= 1;
        }
    }

    return std.fmt.parseFloat(f64, lexeme[0..end]);
}

// ─────────────────────────────────────────────────────────────
// Lexer principal
// ─────────────────────────────────────────────────────────────

pub fn lexFloat(src: []const u8) LexError!FloatToken {
    if (src.len == 0) {
        return LexError.NotAFloat;
    }

    // Hexadecimal não suportado
    if (
        src.len >= 2 and
        src[0] == '0' and
        (src[1] == 'x' or src[1] == 'X')
    ) {
        return LexError.HexNotSupported;
    }

    var pos: usize = 0;

    var has_int = false;
    var has_frac = false;
    var has_dot = false;
    var has_exp = false;

    // Parte inteira
    const after_int = skipDigits(src, pos);

    if (after_int > pos) {
        has_int = true;
        pos = after_int;
    }

    // Ponto decimal
    if (pos < src.len and src[pos] == '.') {
        has_dot = true;
        pos += 1;

        // Parte fracionária
        const after_frac = skipDigits(src, pos);

        if (after_frac > pos) {
            has_frac = true;
            pos = after_frac;
        }
    }

    // '.' sozinho
    if (has_dot and !has_int and !has_frac) {
        return LexError.IsolatedDot;
    }

    // Caso sem ponto precisa obrigatoriamente de expoente
    if (!has_dot and !has_int) {
        return LexError.NotAFloat;
    }

    // Expoente
    if (pos < src.len and (src[pos] == 'e' or src[pos] == 'E')) {
        has_exp = true;
        pos += 1;

        // sinal opcional
        if (pos < src.len and (src[pos] == '+' or src[pos] == '-')) {
            pos += 1;
        }

        const exp_start = pos;
        pos = skipDigits(src, pos);

        if (pos == exp_start) {
            return LexError.ExponentMissingDigits;
        }
    }

    // Forma D
    if (!has_dot and !has_exp) {
        return LexError.NotAFloat;
    }

    // Sufixo opcional
    var suffix: FloatSuffix = .none;

    if (pos < src.len) {
        switch (src[pos]) {
            'f', 'F' => {
                suffix = .f;
                pos += 1;
            },
            'l', 'L' => {
                suffix = .l;
                pos += 1;
            },
            else => {},
        }
    }

    // Não pode sobrar lixo
    if (pos != src.len) {
        return LexError.NotAFloat;
    }

    const lexeme = src[0..pos];

    const value = toF64(lexeme) catch {
        return LexError.FloatParseError;
    };

    return FloatToken{
        .lexeme = lexeme,
        .suffix = suffix,
        .value = value,
    };
}