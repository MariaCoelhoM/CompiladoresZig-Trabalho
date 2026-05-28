//! Lexer de Ponto Flutuante Decimal — C99
//!
//! Reconhece APENAS literais decimais conforme ISO/IEC 9899:1999 §6.4.4.2
//!
//! Gramática (BNF):
//!
//!   decimal-floating-constant
//!       ::= fractional-constant [ exponent-part ] [ floating-suffix ]
//!         | digit-sequence exponent-part [ floating-suffix ]
//!
//!   fractional-constant
//!       ::= [ digit-sequence ] "." digit-sequence   (forma A e C)
//!         | digit-sequence "."                       (forma B)
//!
//!   exponent-part  ::= ("e" | "E") [ sign ] digit-sequence
//!   sign           ::= "+" | "-"
//!   digit-sequence ::= digit { digit }
//!   digit          ::= "0" | "1" | ... | "9"
//!   floating-suffix ::= "f" | "F" | "l" | "L"
//!
//! Formas aceitas:
//!   A)  digits . digits [exp] [suf]   → 3.14, 3.14e2f
//!   B)  digits .        [exp] [suf]   → 3.,   3.e2
//!   C)         . digits [exp] [suf]   → .5,   .5e-1L
//!   D)  digits          exp   [suf]   → 1e10, 42E-3f

const std = @import("std");

// ─── Tipos públicos ────────────────────────────────────────────────────────

/// Sufixo de tipo do literal
pub const FloatSuffix = enum {
    none, // double  (padrão C99)
    f,    // float
    l,    // long double
};

/// Token produzido pelo lexer
pub const FloatToken = struct {
    /// Slice do input original (sem cópia)
    lexeme: []const u8,
    /// Sufixo de tipo
    suffix: FloatSuffix,
    /// Valor numérico convertido para f64
    value: f64,
};

/// Erros possíveis
pub const LexError = error{
    /// String vazia ou não começa com dígito/ponto
    NotAFloat,
    /// Ponto isolado sem nenhum dígito adjacente
    IsolatedDot,
    /// 'e'/'E' presente mas sem dígitos no expoente
    ExponentMissingDigits,
    /// Input começa com '0x'/'0X' — hexadecimal não é aceito
    HexNotSupported,
    /// Falha na conversão numérica final
    FloatParseError,
};

// ─── Funções internas ──────────────────────────────────────────────────────

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

/// Avança `pos` enquanto o caractere satisfaz `pred`; retorna nova posição.
fn skipDigits(src: []const u8, pos: usize) usize {
    var i = pos;
    while (i < src.len and isDigit(src[i])) i += 1;
    return i;
}

/// Remove sufixo e converte o lexeme para f64.
fn toF64(lexeme: []const u8) !f64 {
    var end = lexeme.len;
    if (end > 0) {
        const last = lexeme[end - 1];
        if (last == 'f' or last == 'F' or last == 'l' or last == 'L')
            end -= 1;
    }
    return std.fmt.parseFloat(f64, lexeme[0..end]);
}

// ─── Lexer principal ───────────────────────────────────────────────────────

/// Tenta reconhecer um literal de ponto flutuante **decimal** C99
/// a partir do início de `src`.
///
/// Retorna `FloatToken` em caso de sucesso, ou `LexError` caso contrário.
pub fn lexFloat(src: []const u8) LexError!FloatToken {
    if (src.len == 0) return LexError.NotAFloat;

    // Rejeita hexadecimal explicitamente
    if (src.len >= 2 and src[0] == '0' and (src[1] == 'x' or src[1] == 'X'))
        return LexError.HexNotSupported;

    var pos: usize = 0;
    var has_int  = false; // consumiu dígitos antes do ponto
    var has_frac = false; // consumiu dígitos após o ponto
    var has_dot  = false; // consumiu '.'
    var has_exp  = false; // consumiu expoente e/E

    // ── 1. Parte inteira (opcional) ────────────────────────────────────────
    const after_int = skipDigits(src, pos);
    if (after_int > pos) {
        has_int = true;
        pos = after_int;
    }

    // ── 2. Ponto decimal (opcional) ────────────────────────────────────────
    if (pos < src.len and src[pos] == '.') {
        has_dot = true;
        pos += 1;

        // ── 3. Parte fracionária (opcional após o ponto) ───────────────────
        const after_frac = skipDigits(src, pos);
        if (after_frac > pos) {
            has_frac = true;
            pos = after_frac;
        }
    }

    // ── 4. Expoente: e/E [+/-] digits ─────────────────────────────────────
    if (pos < src.len and (src[pos] == 'e' or src[pos] == 'E')) {
        pos += 1; // consome 'e' ou 'E'

        // sinal opcional
        if (pos < src.len and (src[pos] == '+' or src[pos] == '-'))
            pos += 1;

        const after_exp = skipDigits(src, pos);
        if (after_exp == pos) return LexError.ExponentMissingDigits;
        pos = after_exp;
        has_exp = true;
    }

    // ── 5. Validações semânticas ───────────────────────────────────────────

    // Ponto isolado: "." sem nenhum dígito ao redor
    if (has_dot and !has_int and !has_frac)
        return LexError.IsolatedDot;

    // Nenhuma parte numérica reconhecida
    if (!has_int and !has_frac)
        return LexError.NotAFloat;

    // Forma D: só parte inteira sem ponto → obrigatório expoente
    //   ex.: "1e10" ✓   "1" ✗ (seria inteiro, não float)
    if (has_int and !has_dot and !has_exp)
        return LexError.NotAFloat;

    // ── 6. Sufixo: f/F/l/L ────────────────────────────────────────────────
    const suffix: FloatSuffix = if (pos < src.len) switch (src[pos]) {
        'f', 'F' => blk: { pos += 1; break :blk .f; },
        'l', 'L' => blk: { pos += 1; break :blk .l; },
        else     => .none,
    } else .none;

    // ── 7. Monta token ─────────────────────────────────────────────────────
    const lexeme = src[0..pos];
    const value  = toF64(lexeme) catch return LexError.FloatParseError;

    return FloatToken{ .lexeme = lexeme, .suffix = suffix, .value = value };
}
