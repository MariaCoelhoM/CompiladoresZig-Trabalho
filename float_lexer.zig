const std = @import("std");

// ============================================================
// Definições de tipos públicos
// ============================================================

/// Representa os sufixos aceitos pela linguagem C99.
/// none = double (padrão)
/// f = float
/// l = long double
pub const FloatSuffix = enum {
    none,
    f,
    l,
};

/// Token retornado pelo lexer após o reconhecimento.
pub const FloatToken = struct {
    /// Texto original reconhecido.
    lexeme: []const u8,

    /// Sufixo encontrado (se existir).
    suffix: FloatSuffix,

    /// Valor convertido para f64.
    value: f64,
};

/// Possíveis erros léxicos.
pub const LexError = error{
    /// Não representa um número de ponto flutuante válido.
    NotAFloat,

    /// Apenas "." sem dígitos.
    IsolatedDot,

    /// Expoente sem dígitos após e/E.
    ExponentMissingDigits,

    /// Hexadecimal não é suportado neste projeto.
    HexNotSupported,

    /// Erro ao converter o texto para f64.
    FloatParseError,
};

// ============================================================
// Funções auxiliares
// ============================================================

/// Verifica se um caractere é um dígito decimal.
fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

/// Avança pela sequência de dígitos consecutivos.
///
/// Exemplo:
/// Entrada: "123abc"
/// Retorna posição do 'a'.
fn skipDigits(src: []const u8, pos: usize) usize {
    var i = pos;

    while (i < src.len and isDigit(src[i])) {
        i += 1;
    }

    return i;
}

/// Converte o lexema reconhecido para f64.
///
/// Caso exista um sufixo (f, F, l ou L),
/// ele é removido antes da conversão.
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

// ============================================================
// Lexer principal
// ============================================================

/// Analisa uma string e verifica se ela representa
/// um número de ponto flutuante decimal válido.
///
/// Retorna um FloatToken em caso de sucesso
/// ou um LexError em caso de falha.
pub fn lexFloat(src: []const u8) LexError!FloatToken {

    // Não aceita string vazia.
    if (src.len == 0) {
        return LexError.NotAFloat;
    }

    // Hexadecimais não fazem parte do escopo do projeto.
    if (
        src.len >= 2 and
        src[0] == '0' and
        (src[1] == 'x' or src[1] == 'X')
    ) {
        return LexError.HexNotSupported;
    }

    // Posição atual de leitura.
    var pos: usize = 0;

    // Flags utilizadas para validar as formas
    // descritas na gramática.
    var has_int = false;
    var has_frac = false;
    var has_dot = false;
    var has_exp = false;

    // ========================================================
    // Parte inteira
    // ========================================================

    const after_int = skipDigits(src, pos);

    if (after_int > pos) {
        has_int = true;
        pos = after_int;
    }

    // ========================================================
    // Ponto decimal e parte fracionária
    // ========================================================

    if (pos < src.len and src[pos] == '.') {
        has_dot = true;
        pos += 1;

        const after_frac = skipDigits(src, pos);

        if (after_frac > pos) {
            has_frac = true;
            pos = after_frac;
        }
    }

    // Caso especial: "."
    if (has_dot and !has_int and !has_frac) {
        return LexError.IsolatedDot;
    }

    // Se não existe parte inteira e nem ponto,
    // não é um float válido.
    if (!has_dot and !has_int) {
        return LexError.NotAFloat;
    }

    // ========================================================
    // Parte do expoente
    // ========================================================

    if (pos < src.len and (src[pos] == 'e' or src[pos] == 'E')) {

        has_exp = true;
        pos += 1;

        // Sinal opcional (+ ou -)
        if (pos < src.len and (src[pos] == '+' or src[pos] == '-')) {
            pos += 1;
        }

        const exp_start = pos;

        // Deve existir pelo menos um dígito.
        pos = skipDigits(src, pos);

        if (pos == exp_start) {
            return LexError.ExponentMissingDigits;
        }
    }

    // ========================================================
    // Validação da Forma D
    // ========================================================
    //
    // Exemplo:
    // 1e10
    // 42E-3
    //
    // Se não existe ponto decimal,
    // obrigatoriamente deve existir expoente.
    // Caso contrário seria um inteiro comum.
    // ========================================================

    if (!has_dot and !has_exp) {
        return LexError.NotAFloat;
    }

    // ========================================================
    // Sufixo opcional
    // ========================================================

    var suffix: FloatSuffix = .none;

    if (pos < src.len) {
        switch (src[pos]) {

            // float
            'f', 'F' => {
                suffix = .f;
                pos += 1;
            },

            // long double
            'l', 'L' => {
                suffix = .l;
                pos += 1;
            },

            else => {},
        }
    }

    // Se ainda restarem caracteres,
    // então existe lixo após o número.
    if (pos != src.len) {
        return LexError.NotAFloat;
    }

    // Lexema reconhecido.
    const lexeme = src[0..pos];

    // Conversão para valor numérico.
    const value = toF64(lexeme) catch {
        return LexError.FloatParseError;
    };

    // Construção do token final.
    return FloatToken{
        .lexeme = lexeme,
        .suffix = suffix,
        .value = value,
    };
}