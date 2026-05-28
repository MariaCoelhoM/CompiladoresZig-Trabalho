#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define OUTPUT_FILE "passo-a-passo.txt"

static FILE *out;

/*
 * Resta Um - Peg Solitaire
 * Tabuleiro 9x9 onde '#' = fora, 'o' = pino, ' ' = vazio
 *
 * Layout do tabuleiro (índices 0-8):
 *   colunas válidas nas linhas 0,1,7,8: apenas cols 3,4,5
 *   colunas válidas nas linhas 2-6: cols 1..7
 *   (mas representamos tudo em 9x9, usando '#' nas bordas)
 */

#define ROWS 9
#define COLS 9
#define MAX_MOVES 31

typedef struct {
    int ar, ac; /* posição A (peça que salta) */
    int br, bc; /* posição B (peça removida)  */
    int cr, cc; /* posição C (destino vazio)  */
} Move;

/* Estado do tabuleiro */
char board[ROWS][COLS];
Move history[MAX_MOVES];
int move_count;

/* Inicializa o tabuleiro conforme o arquivo .out:
 * '#' nas bordas inválidas, 'o' nos pinos, ' ' no centro (4,4)
 */
void init_board(void) {
    int r, c;
    /* Preenche tudo com '#' */
    for (r = 0; r < ROWS; r++)
        for (c = 0; c < COLS; c++)
            board[r][c] = '#';

    /* Linhas 1-7 (índices), colunas 3-5: zona superior/inferior do cruz */
    /* Zona horizontal: linhas 3-5, colunas 1-7 */
    /* Zona vertical:   linhas 1-7, colunas 3-5 */

    for (r = 1; r <= 7; r++)
        for (c = 3; c <= 5; c++)
            board[r][c] = 'o';

    for (r = 3; r <= 5; r++)
        for (c = 1; c <= 7; c++)
            board[r][c] = 'o';

    /* Centro começa vazio */
    board[4][4] = ' ';

    move_count = 0;
}

/* Imprime o tabuleiro */
void print_board(void) {
    int r, c;
    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++)
            fputc(board[r][c], out);
        fputc('\n', out);
    }
    fputc('\n', out);
}

/* Conta pinos no tabuleiro */
int count_pegs(void) {
    int r, c, cnt = 0;
    for (r = 0; r < ROWS; r++)
        for (c = 0; c < COLS; c++)
            if (board[r][c] == 'o')
                cnt++;
    return cnt;
}

/* Verifica se a célula é uma posição válida do tabuleiro (não é '#') */
int valid_cell(int r, int c) {
    if (r < 0 || r >= ROWS || c < 0 || c >= COLS) return 0;
    return board[r][c] != '#';
}

/* Realiza o movimento: A salta sobre B para C */
void do_move(Move m) {
    board[m.ar][m.ac] = ' ';
    board[m.br][m.bc] = ' ';
    board[m.cr][m.cc] = 'o';
}

/* Desfaz o movimento */
void undo_move(Move m) {
    board[m.ar][m.ac] = 'o';
    board[m.br][m.bc] = 'o';
    board[m.cr][m.cc] = ' ';
}

/*
 * Backtracking:
 * Tenta realizar 31 movimentos para deixar apenas o pino central (4,4).
 * Retorna 1 se encontrou solução, 0 caso contrário.
 */
int solve(int depth) {
    if (depth == MAX_MOVES) {
        /* Verifica se sobrou apenas o pino central */
        if (board[4][4] == 'o' && count_pegs() == 1)
            return 1;
        return 0;
    }

    int r, c, dr, dc;
    /* Direções: horizontal e vertical */
    int dirs[4][2] = {{0,1},{0,-1},{1,0},{-1,0}};

    for (r = 0; r < ROWS; r++) {
        for (c = 0; c < COLS; c++) {
            if (board[r][c] != 'o') continue;
            int d;
            for (d = 0; d < 4; d++) {
                dr = dirs[d][0];
                dc = dirs[d][1];
                int br = r + dr,   bc = c + dc;
                int cr = r + 2*dr, cc = c + 2*dc;

                /* Posições B e C devem ser válidas */
                if (!valid_cell(br, bc) || !valid_cell(cr, cc)) continue;
                /* B deve ter pino, C deve estar vazio */
                if (board[br][bc] != 'o') continue;
                if (board[cr][cc] != ' ') continue;

                Move m = {r, c, br, bc, cr, cc};
                do_move(m);
                history[depth] = m;

                if (solve(depth + 1))
                    return 1;

                undo_move(m);
            }
        }
    }
    return 0;
}

int main(void) {
    out = fopen(OUTPUT_FILE, "w");
    if (!out) {
        fprintf(stderr, "Erro ao abrir arquivo %s\n", OUTPUT_FILE);
        return 1;
    }
    printf("O processamento pode demorar alguns segundos...\n");
    fprintf(out, "O processamento pode demorar alguns segundos...\n");

    init_board();
    print_board(); /* Estado inicial */

    if (!solve(0)) {
        fprintf(stderr, "Nenhuma solucao encontrada.\n");
        fclose(out);
        return 1;
    }

    /* Reproduz a sequência de movimentos imprimindo o tabuleiro após cada um */
    init_board();
    int i;
    for (i = 0; i < MAX_MOVES; i++) {
        do_move(history[i]);
        print_board();
    }

    fclose(out);
    printf("Saida gravada em %s\n", OUTPUT_FILE);
    return 0;
}