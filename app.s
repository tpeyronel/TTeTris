	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32
	.equ BYTES_PER_PIXEL, 4
	.equ BYTES_PER_PIXEL_SHIFT, 2
        .equ BYTES_PER_SCREEN_ROW, SCREEN_WIDTH * BYTES_PER_PIXEL

        .equ MOVEMENT_PER_STEP,         40

        .equ SQUARE_SIZE,               40

        .equ BOARD_WIDTH,               10
        .equ BOARD_HEIGHT,              22
        .equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
        .equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1

        .equ BYTES_PER_TETROMINO_BLOCK,         1
        .equ BYTES_PER_TETROMINO_BLOCK_SHIFT,   0

        .equ TETROMINO_BOARD_WIDTH,             4
        .equ TETROMINO_BOARD_SIZE,              TETROMINO_BOARD_WIDTH * TETROMINO_BOARD_WIDTH
        .equ TETROMINO_BOARD_SIZE_IN_BYTES,     TETROMINO_BOARD_SIZE * BYTES_PER_TETROMINO_BLOCK
        .equ NUM_ORIENTATIONS,                  4

        .equ NUM_TETROMINOS,                    7

        .equ TEST_BINARY_TO_DECIMAL_MAX,        10000

        .equ MS_PER_TICK,               50
        .equ US_PER_TICK,               MS_PER_TICK * 1000

	.equ GPIO_BASE,                 0x3f200000
	.equ GPIO_GPFSEL0,              0x00
	.equ GPIO_GPLEV0,               0x34
        .equ GPIO_W,                    0b000010        // (GPIO_1)
        .equ GPIO_A,                    0b000100        // (GPIO_2)
        .equ GPIO_S,                    0b001000        // (GPIO_3)
        .equ GPIO_D,                    0b010000        // (GPIO_4)
        .equ GPIO_SPACE,                0b100000        // (GPIO_5)
        .equ RNG_BASE,                  0x3f104000
        .equ RNG_NUMBER_ADDRESS,        0x3f104008
        .equ SYS_TIMER_BASE_ADDRESS,    0x3f003000
        .equ SYS_TIMER_VALUE_ADDRESS,   0x3f003004      // 32 bit number in microseconds
        // .equ GPIO_CLK_DIV_ADDRESS,      0x3f101074
        // .equ GPIO_CLK_CTL_ADDRESS,      0x3f101070
        // .equ GPIO_CLK_DIV,              0x5A0C0000
        // .equ GPIO_CLK_CTL,              0x5A000011
        .equ MS_PER_STEP,               250
        .equ US_PER_STEP,               MS_PER_STEP * 1000


        /* Bit flags used for drawing digits. */
        .equ DIGIT_SEGMENT_0,           1 << 0
        .equ DIGIT_SEGMENT_1,           1 << 1
        .equ DIGIT_SEGMENT_2,           1 << 2
        .equ DIGIT_SEGMENT_3,           1 << 3
        .equ DIGIT_SEGMENT_4,           1 << 4
        .equ DIGIT_SEGMENT_5,           1 << 5
        .equ DIGIT_SEGMENT_6,           1 << 6


        BG_COLORS: .word 0x00FF0000, 0x000FF000, 0x0000FF00, 0x00000FF0, 0x000000FF, 0x00F0000F
        BG_COLOR: .dword 0xFFFFFFFF
        PLAYER_COLOR: .dword 0xFFFFFFFF

	.globl main

/* enum CollisionResult */
        .equ COLLISION_RESULT_NO_COLLISION,     0b00
        .equ COLLISION_RESULT_OUT_OF_BOUNDS,    0b01
        .equ COLLISION_RESULT_EXISTING_BLOCK,   0b10

/* struct GameState */
        .equ LAST_TICK,                 0                                               // u32
        .equ INPUT_STATE,               LAST_TICK + 4                                   // struct InputState
        .equ TETROMINO_STATE,           INPUT_STATE + STRUCT_INPUT_STATE_SIZE           // struct TetrominoState
        .equ CHOOSER_BAG_STATE,         TETROMINO_STATE + STRUCT_TSTATE_SIZE            // struct ChooserBagState
        .equ BOARD_STATE,               CHOOSER_BAG_STATE + STRUCT_CBAG_STATE_SIZE      // struct BoardState

        .equ STRUCT_GAME_STATE_SIZE,    BOARD_STATE + STRUCT_BSTATE_SIZE

/* struct GameStats */
        .equ GS_SCORE,                  0                       // u64
        .equ GS_COMPLETED_ROWS,         GS_SCORE + 8            // u64

        .equ STRUCT_GS_SIZE,            GS_COMPLETED_ROWS + 8

/* struct InputState */
        .equ PRESSED_STATE,             0                       // u32
        .equ ON_PRESS_STATE,            PRESSED_STATE + 4       // u32

        .equ STRUCT_INPUT_STATE_SIZE,   ON_PRESS_STATE + 4

/* struct TetrominoState */
        .equ TSTATE_ID,                 0                       // u64
        .equ TSTATE_ROT,                TSTATE_ID + 8           // u64
        .equ TSTATE_POS_X,              TSTATE_ROT + 8          // i64
        .equ TSTATE_POS_Y,              TSTATE_POS_X + 8        // i64

        .equ STRUCT_TSTATE_SIZE,        TSTATE_POS_Y + 8

/* struct ChooserBagState */
        .equ CBAG_REMAINING,            0                       // u8
        .equ CBAG_VALUES,               CBAG_REMAINING + 1      // u8[7] = u8[NUM_TETROMINOS]

        .equ STRUCT_CBAG_STATE_SIZE,    CBAG_VALUES + (NUM_TETROMINOS * 1)

/* struct BoardState */
        .equ BSTATE_BOARD,              0                       // u8[22][10] = u8[BOARD_HEIGHT][BOARD_WIDTH]

        .equ STRUCT_BSTATE_SIZE,        BSTATE_BOARD + BOARD_SIZE_IN_BYTES

/* struct Tetromino */
        .equ TETROMINO_COLOR,           0                           // u32
        .equ TETROMINO_ROTS,            TETROMINO_COLOR + 4         // struct TetrominoData[4] = struct TetrominoData[NUM_ORIENTATIONS]

        .equ STRUCT_TETROMINO_SIZE,     TETROMINO_ROTS + (STRUCT_TDATA_SIZE * NUM_ORIENTATIONS)

/* struct TetrominoData */
        .equ TDATA,                     0                       // u8[4][4]             [0][0] is bottom left, [0][3] is bottom right

        .equ STRUCT_TDATA_SIZE,         TDATA + TETROMINO_BOARD_SIZE_IN_BYTES


/* struct DrawNumberInfo */
        .equ DNI_POS_X,                 0                       // u64
        .equ DNI_POS_Y,                 DNI_POS_X + 8           // u64
        .equ DNI_VALUE,                 DNI_POS_Y + 8           // u64
        .equ DNI_MAX_DIGITS,            DNI_VALUE + 8           // u64
        .equ DNI_DIGIT_WIDTH,           DNI_MAX_DIGITS + 8      // u64
        .equ DNI_DIGIT_THICKNESS,       DNI_DIGIT_WIDTH + 8     // u64
        .equ DNI_DIGIT_SPACING,         DNI_DIGIT_THICKNESS + 8 // u64
        .equ DNI_COLOR,                 DNI_DIGIT_SPACING + 8   // u32

        .equ STRUCT_DNI_SIZE,           DNI_COLOR + 4


/* Data for all 7 tetrominos */
/* struct Tetromino[NUM_TETROMINOS] */
/* Data is mirrored both horizontally and vertically, due to endianness and array indexing respectively */
TETROMINOS:
/* Tetromino I: */
        .word 0x31C7EF  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0xFFFFFFFF
        .word 0x00000000

        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x0000FF00

        .word 0x00000000
        .word 0xFFFFFFFF
        .word 0x00000000
        .word 0x00000000

        .word 0x00FF0000
        .word 0x00FF0000
        .word 0x00FF0000
        .word 0x00FF0000


/* Tetromino J: */
        .word 0x5A65AD  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFFFF
        .word 0x000000FF

        .word 0x00000000
        .word 0x0000FFFF
        .word 0x0000FF00
        .word 0x0000FF00

        .word 0x00000000
        .word 0x00FF0000
        .word 0x00FFFFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x00FFFF00

/* Tetromino L: */
        .word 0xEF7921  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFFFF
        .word 0x00FF0000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x0000FFFF

        .word 0x00000000
        .word 0x000000FF
        .word 0x00FFFFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x00FFFF00
        .word 0x0000FF00
        .word 0x0000FF00

/* Tetromino O: */
        .word 0xF7D308  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

/* Tetromino S: */
        .word 0x42B642  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x0000FFFF
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FFFF
        .word 0x000000FF

        .word 0x00000000
        .word 0x0000FFFF
        .word 0x00FFFF00
        .word 0x00000000

        .word 0x00000000
        .word 0x00FF0000
        .word 0x00FFFF00
        .word 0x0000FF00

/* Tetromino Z: */
        .word 0xEF2029  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x0000FFFF

        .word 0x00000000
        .word 0x000000FF
        .word 0x0000FFFF
        .word 0x0000FF00

        .word 0x00000000
        .word 0x00FFFF00
        .word 0x0000FFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x00FFFF00
        .word 0x00FF0000

/* Tetromino T: */
        .word 0xAD4D9C  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFFFF
        .word 0x0000FF00

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FFFF
        .word 0x0000FF00

        .word 0x00000000
        .word 0x0000FF00
        .word 0x00FFFFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x00FFFF00
        .word 0x0000FF00


/* Data for drawing decimal digits */
/* u32[10] */
DIGITS_FONT:
/* Digit 0: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 1: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_5
/* Digit 2: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 3: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 4: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5
/* Digit 5: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_6
/* Digit 6: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_6
/* Digit 7: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 8: */
        .word DIGIT_SEGMENT_0 | DIGIT_SEGMENT_1 | DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6
/* Digit 9: */
        .word DIGIT_SEGMENT_2 | DIGIT_SEGMENT_3 | DIGIT_SEGMENT_4 | DIGIT_SEGMENT_5 | DIGIT_SEGMENT_6



/*
 * x19: framebuffer address (could be x9-15 ?)
 * x20: player x
 * x21: player y
 * x22: bg color index
 * w23: bg color
 * w24: player color
 * x25: remaining columns of row
 * x26: remaining rows
 * x28 (const): beginning of framebuffer
 */
main:
	mov     x28, x0         // Save framebuffer address to x28

        // Allocate and init struct GameState
        sub     sp, sp, STRUCT_GAME_STATE_SIZE
        mov     x0, sp
        bl      init_game_state

	// Set GPIOs 0..9 to read
	mov     x9, GPIO_BASE
	str     wzr, [x9, GPIO_GPFSEL0]


        ldr     w23, BG_COLORS          // w23 <- bg color | default BG_COLORS[0]
        ldr     w24, PLAYER_COLOR       // w24 <- player color | default PLAYER_COLOR

        mov     x20, 0                  // x20 <- square x coordinate
        mov     x21, 0                  // x21 <- square y coordinate
        bl      get_time
        mov     w22, w0                 // w22 <- square's last movement



game_loop:

        add     x0, sp, INPUT_STATE
        bl      read_input

        add     x0, sp, INPUT_STATE
        add     x1, sp, TETROMINO_STATE
        bl      process_input

        ldr     x0, [sp, TETROMINO_STATE + TSTATE_ID]
        bl      index_bg_color
        mov     w23, w0


        /* Draw background */
        mov     x19, x28                // Set x19 to beginning of framebuffer
	mov     x26, SCREEN_HEIGH       // Set x21 to remaining rows
next_row:
	mov     x25, SCREEN_WIDTH       // Set x25 to remaining columns
next_col:
        ldr     x9, [sp, TETROMINO_STATE + TSTATE_POS_X]
        cmp     x25, x9                 // Check if we are in same column as player
        b.ne    pxl_bg
        ldr     x9, [sp, TETROMINO_STATE + TSTATE_POS_Y]
        cmp     x26, x9                 // Check if we are in same row as player
        b.ne    pxl_bg

pxl_player:
        stur    w24, [x19]              // Fill pixel with player color
        b       cont

pxl_bg:
        stur    w23, [x19]               // Fill pixel with bg color

cont:	add     x19, x19, BYTES_PER_PIXEL // Advance to next framebuffer pixel

	sub     x25, x25, 1             // Decrement remaining columns
	cbnz    x25, next_col           // If not at end of row, draw next column

	sub     x26, x26, 1             // Decrement remaining rows
	cbnz    x26, next_row           // If not at last row, draw next row
        /* Finished drawing background */

        // mov     x0, 16
        // mov     x1, 16
        // mov     x2, 16
        // mov     w3, w24
        // mov     x4, x28
        // bl      draw_horizontal_line

        // mov     x0, 32
        // mov     x1, 32
        // mov     x2, 16
        // mov     w3, w24
        // mov     x4, x28
        // bl      draw_vertical_line


        mov     x0, 638
        mov     x1, 1
        mov     w2, w24
        mov     x3, x28
        bl      draw_time

//         mov     x6, 64
//         mov     w7, 0
//
// next_digit:
//         mov     x0, x6
//         mov     x1, 64
//         mov     x2, 28
//         mov     w3, w7
//         mov     w4, w24
//         mov     x5, x28
//         bl      draw_decimal_digit
//         add     x6, x6, 40
//         add     w7, w7, 1
//         cmp     w7, 10
//         b.lt    next_digit



        // ldr     x0, [sp, (TETROMINO_STATE + TSTATE_POS_X)]
        // ldr     x1, [sp, (TETROMINO_STATE + TSTATE_POS_Y)]
        // mov     x2, x28
        // mov     x3, 100
        // mov     w4, w24
        // bl      draw_circle_at


        // mov     x0, 80
        // mov     x1, 100
        // mov     x2, 400
        // mov     x3, 300
        // mov     x4, x28
        // mov     w5, w24
        // bl      draw_filled_rectangle


        // mov     x0, 400
        // mov     x1, 350
        // mov     x2, 100
        // mov     x3, x28
        // mov     w4, w24
        // bl      draw_filled_square


        mov     x0, x20
        mov     x1, x21
        mov     w2, w22
        mov     x3, SQUARE_SIZE
        bl      advance_square_maybe
        mov     x20, x0
        mov     x21, x1
        mov     w22, w2


        mov     x0, x20
        mov     x1, x21
        mov     x2, SQUARE_SIZE
        mov     x3, x28
        mov     w4, w24
        bl      draw_filled_square


        mov     x0, (SCREEN_WIDTH / 2)
        mov     x1, (SCREEN_HEIGH / 2)
        ldr     x2, [sp, TETROMINO_STATE + TSTATE_POS_X]
        ldr     x3, [sp, TETROMINO_STATE + TSTATE_POS_Y]
        mov     x4, x28
        mov     w5, 0xFFFF00
        bl      draw_line


game_loop__sleep:
        ldr     w0, [sp, LAST_TICK]
        bl      get_elapsed_time
        mov     w2, US_PER_TICK
        cmp     w0, w2
        b.lt    game_loop__sleep
        ldr     w0, [sp, LAST_TICK]
        add     w0, w0, w2
        str     w0, [sp, LAST_TICK]

        b game_loop


/*
 * Params:
 *      x0: out struct GameState*       <- game_state
 */
init_game_state:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0                 // x19 <- game_state

        bl      get_time
        str     w0, [x19, LAST_TICK]

        add     x0, x19, INPUT_STATE
        bl      init_input_state

        add     x0, x19, TETROMINO_STATE
        bl      init_tetromino_state

        add     x0, x19, CHOOSER_BAG_STATE
        bl      recreate_chooser_bag

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: out struct InputState*
 */
init_input_state:
        stur    wzr, [x0, PRESSED_STATE]
        stur    wzr, [x0, ON_PRESS_STATE]
        ret


/*
 * Params:
 *      x0: out struct TetrominoState*
 */
init_tetromino_state:
        stur    xzr, [x0, TSTATE_ID]
        mov     x9, (SCREEN_WIDTH / 2)
        stur    x9, [x0, TSTATE_POS_X]
        mov     x9, (SCREEN_HEIGH / 2)
        stur    x9, [x0, TSTATE_POS_Y]
        stur    xzr, [x0, TSTATE_ROT]
        ret


/*
 * Params:
 *      x0: in/out struct InputState*
 */
read_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     w19, [x0, PRESSED_STATE]        // Load last pressed state to compute on press state

	mov     x20, GPIO_BASE
	ldr     w20, [x20, GPIO_GPLEV0]         // w20 = new pressed state

        // Input in bit 'n' is "on press" if current pressed state is 1 and previous pressed state is 0
        mvn     w19, w19                        // Bitwise NOT last pressed state
        and     w21, w20, w19                   // w21 = new on press state

        str     w20, [x0, PRESSED_STATE]
        str     w21, [x0, ON_PRESS_STATE]

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret

/*
 * Params:
 *      x0: const struct InputState*
 *      x1: mut struct TetrominoState*
 */
process_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, x0         // x19 = const struct InputState*
        mov     x20, x1         // x20 = mut struct TetrominoState*

        ldr     w0, [x19, ON_PRESS_STATE]
        mov     x1, x20

        bl      handle_w
        bl      handle_a
        bl      handle_s
        bl      handle_d
        bl      handle_space

        mov     x0, x20
        bl      clamp_player_coords


        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_w:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_W
        cbz     x19, handle_w__end

        ldr     x19, [x1, TSTATE_POS_Y]
        add     x19, x19, MOVEMENT_PER_STEP     // Move player up
        str     x19, [x1, TSTATE_POS_Y]

handle_w__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_s:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_S
        cbz     x19, handle_s__end

        ldr     x19, [x1, TSTATE_POS_Y]
        sub     x19, x19, MOVEMENT_PER_STEP     // Move player down
        str     x19, [x1, TSTATE_POS_Y]

handle_s__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_a:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_A
        cbz     x19, handle_a__end

        ldr     x19, [x1, TSTATE_POS_X]
        sub     x19, x19, MOVEMENT_PER_STEP     // Move player left
        str     x19, [x1, TSTATE_POS_X]

handle_a__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_d:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_D
        cbz     x19, handle_d__end

        ldr     x19, [x1, TSTATE_POS_X]
        add     x19, x19, MOVEMENT_PER_STEP     // Move player one position right
        str     x19, [x1, TSTATE_POS_X]

handle_d__end:
        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_space:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_SPACE
        cbz     x19, handle_space__end

        ldr     x19, [x1, TSTATE_ID]

        add     x19, x19, #1
        cmp     x19, 6
        csel    x19, x19, xzr, lt         // Set x19 to zero if it's equal to 6

        str     x19, [x1, TSTATE_ID]

handle_space__end:
        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: in/out struct TetrominoState*
 */
clamp_player_coords:
        /* Clamp x coordinate */
        ldr     x9, [x0, TSTATE_POS_X]

        cmp     x9, 0
        b.ge    clamp_player_coords__end_left
        mov     x9, 0
clamp_player_coords__end_left:

        cmp     x9, (SCREEN_WIDTH - 1)
        b.le    clamp_player_coords__end_right
        mov     x9, (SCREEN_WIDTH - 1)
clamp_player_coords__end_right:

        str     x9, [x0, TSTATE_POS_X]


        /* Clamp y coordinate */
        ldr     x9, [x0, TSTATE_POS_Y]

        cmp     x9, 0
        b.ge    clamp_player_coords__end_bottom
        mov     x9, 0
clamp_player_coords__end_bottom:

        cmp     x9, (SCREEN_HEIGH - 1)
        b.le    clamp_player_coords__end_top
        mov     x9, (SCREEN_HEIGH - 1)
clamp_player_coords__end_top:

        str     x9, [x0, TSTATE_POS_Y]

        ret


/*
 * Params:
 *      x0: background color index
 * Returns:
 *      w0: background color
 */
index_bg_color:
        stp     lr, x19, [sp, -16]!

        lsl     x0, x0, 2       // x0 = i * 4
        ldr     x19, =BG_COLORS // x19 = &BG_COLORS[0]
        add     x0, x19, x0     // x0 = &BG_COLORS[0] + (i * 4) = &BG_COLORS[i]
        ldr     w0, [x0]        // w0 = BG_COLORS[i]

        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: x coordinate
 *      x1: y coordinate
 *      x2: beginning of framebuffer
 *      x3: radius
 *      w4: color
 * Returns:
 *      x0: unmodified x coordinate
 *      x1: unmodified y coordinate
 *      x2: unmodified beginning of framebuffer
 *      w3: -
 */
draw_circle_at:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        add     x19, x3, 1
        mul     x19, x3, x19     // x19 "=" r^2 === r*(r+1)


        sub     x21, xzr, x3    // x21 = current circle y coordinate
circle_next_row:
        sub     x20, xzr, x3    // x20 = current circle x coordinate
circle_next_col:

        mul     x22, x20, x20   // x22 = x^2
        mul     x23, x21, x21   // x23 = y^2
        add     x22, x22, x23   // x22 = x^2 + y^2
        cmp     x22, x19
        b.gt    skip_circle_pixel       // only draw if x^2 + y^2 <= r^2



        stp     x0, x1, [sp, -16]!
        mov     x22, x3
        mov     w3, w4

        add     x0, x0, x20
        cmp     x0, SCREEN_WIDTH
        b.hs    pixel_out_of_bounds       // Out of screen
        add     x1, x1, x21
        cmp     x1, SCREEN_HEIGH
        b.hs    pixel_out_of_bounds       // Out of screen
        bl      draw_pixel_at

pixel_out_of_bounds:
        mov     x3, x22
        ldp     x0, x1, [sp], 16


skip_circle_pixel:
        add     x20, x20, 1
        cmp     x20, x3
        b.le    circle_next_col

        add     x21, x21, 1
        cmp     x21, x3
        b.le    circle_next_row


        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: beginning of framebuffer
 *      w3: color
 * Returns:
 *      x0: unmodified x coordinate
 *      x1: unmodified y coordinate
 *      x2: unmodified beginning of framebuffer
 *      w3: unmodified color
 */
draw_pixel_at:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, (SCREEN_HEIGH - 1)
        sub     x19, x19, x1

        mov     x20, SCREEN_WIDTH
        mul     x20, x20, x19                   // x20 = vertical offset
        add     x20, x20, x0                    // x20 = vertical offset + horizontal offset
        lsl     x20, x20, BYTES_PER_PIXEL_SHIFT // x20 = total offset
        add     x20, x2, x20                    // x20 = &framebuffer[y][x]

        str     w3, [x20]

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: bottom left x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: bottom left y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: top right x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: top right y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_filled_rectangle:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        // TODO: check bounds?

        // We need to move the framebuffer pointer to the initial position
        mov     x19, (SCREEN_HEIGH - 1)
        sub     x19, x19, x3                    // x19 = first row from top
        mov     x20, SCREEN_WIDTH
        mul     x19, x19, x20                   // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['rectangle's top left pixel']

        sub     x19, x2, x0                     // x19 = rectangle width - 1
        add     x19, x19, 1                     // x19 = rectangle width
        sub     x20, x20, x19                   // x20 = pixels between the end of a row and the beginning of the next row
        lsl     x20, x20, BYTES_PER_PIXEL_SHIFT // x20 = bytes between the end of a row and the beginning of the next row


draw_filled_rectangle__next_row:
        mov     x21, x19                        // x19 = rectangle width

draw_filled_rectangle__next_col:
        str     w5, [x4]                        // Paint pixel
        add     x4, x4, BYTES_PER_PIXEL         // Advance to next pixel

        subs    x21, x21, 1                     // Check if we finished current row
        b.gt    draw_filled_rectangle__next_col // If not, then draw next column



        add     x4, x4, x20                     // Advance to beginning of next row
        add     x1, x1, 1
        cmp     x1, x3
        b.le    draw_filled_rectangle__next_row


        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret


/*
 * Params:
 *      x0: bottom left x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: bottom left y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: size
 *      x3: beginning of framebuffer
 *      w4: color
 */
draw_filled_square:
        stp     lr, x19, [sp, -16]!

        mov     w5, w4
        mov     x4, x3
        sub     x2, x2, 1       // Top right (x', y') = (x + size - 1, y + size - 1)
        add     x3, x1, x2
        add     x2, x0, x2
        bl      draw_filled_rectangle

        ldp     lr, x19, [sp], 16
        ret

/*
 * Returns:
 *      w0: current time
 */
get_time:
        ldr     x0, =SYS_TIMER_VALUE_ADDRESS
        ldr     w0, [x0]
        ret

/*
 * Params:
 *      w0: previous_time
 * Returns:
 *      w0: elapsed_time
 *      w1: current_time
 */
get_elapsed_time:
        ldr     x1, =SYS_TIMER_VALUE_ADDRESS
        ldr     w1, [x1]
        sub     w0, w1, w0
        ret



/*
 * Params:
 *      x0: square x coordinate
 *      x1: square y coordinate
 *      w2: previous step
 *      x3: square size
 * Returns:
 *      x0: new square x coordinate
 *      x1: new square y coordinate
 *      w2: previous or new step
 */
advance_square_maybe:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x20, x0                 // x20 = x coordinate
        mov     x21, x1                 // x21 = y coordinate
        mov     w19, w2                 // w19 = previous step

        mov     w0, w19
        bl      get_elapsed_time        // Sets w0, w1

        ldr     w2, =US_PER_STEP
        cmp     w0, w2                         // Check if we should move square
        b.lt    advance_square_maybe__end

        // Enough time has passed since last step
        add     w19, w19, w2                    // Advance last step by time per step
        add     x20, x20, x3                    // Advance square position by its size

        ldr     x0, =SCREEN_WIDTH
        sub     x0, x0, x3
        cmp     x20, x0                         // Check if square is horizontally out of bounds
        b.le    advance_square_maybe__end

        // Square is at end of row
        mov     x20, 0                          // Set square at beginning of row
        add     x21, x21, x3                    // Move square one row up


        ldr     x0, =SCREEN_HEIGH
        sub     x0, x0, x3
        cmp     x21, x0                         // Check if square is vertically out of bounds
        b.le    advance_square_maybe__end

        // Square is vertically out of bounds
        mov     x21, 0                          // Set square at bottom row

advance_square_maybe__end:
        mov     x0, x20
        mov     x1, x21
        mov     w2, w19

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: first point x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: first point y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: second point x coordinate       (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: second point y coordinate     (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        // TODO: implement hor. line and ver. line subroutines?

        // Convert game y coordinates to screen y coordinates
        mov     x19, (SCREEN_HEIGH - 1)
        sub     x1, x19, x1
        sub     x3, x19, x3


        subs    x19, x2, x0                     // x19 = dx = x1 - x0
        b.ge    draw_line__end_abs_dx
        sub     x19, xzr, x19                   // dx = -dx
draw_line__end_abs_dx:
        /* x19 = |x1 - x0| = |dx| */


        subs    x20, x3, x1                     // x20 = dy = y1 - y0
        b.ge    draw_line__end_abs_dy
        sub     x20, xzr, x20                   // dy = -dy
draw_line__end_abs_dy:
        /* x20 = |y1 - y0| = |dy| */


        cmp     x20, x19                  // (|y1 - y0| < |x1 - x0|)?  (is line low slope?)
        b.le    draw_line__case_low_slope
        b.gt    draw_line__case_high_slope



draw_line__case_low_slope:
        cmp     x0, x2          // x0 <= x1 ?
        b.gt    draw_line__case_low_slope_invert

        bl      draw_line_low_slope
        b       draw_line__end

draw_line__case_low_slope_invert:
        mov     x19, x0
        mov     x0, x2
        mov     x2, x19
        mov     x19, x1
        mov     x1, x3
        mov     x3, x19
        bl      draw_line_low_slope
        b       draw_line__end



draw_line__case_high_slope:
        cmp     x1, x3          // y0 <= y1 ?
        b.gt    draw_line__case_high_slope_invert

        bl      draw_line_high_slope
        b       draw_line__end

draw_line__case_high_slope_invert:
        mov     x19, x0
        mov     x0, x2
        mov     x2, x19
        mov     x19, x1
        mov     x1, x3
        mov     x3, x19
        bl      draw_line_high_slope
        b       draw_line__end


draw_line__end:
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret


/*
 * Params:
 *      x0: left point x coordinate          (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: left point y coordinate           (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x2: right point x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: right point y coordinate          (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line_low_slope:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]


        mov     x19, SCREEN_WIDTH               // x19 = screen width
        mul     x19, x19, x1                    // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['line's leftmost pixel']



        sub     x19, x2, x0                     // x19 = dx = x1 - x0
        sub     x20, x3, x1                     // x20 = dy = y1 - y0
        mov     x22, 1                          // x22 = yi = 1 (assume dy >= 0)
        mov     x23, SCREEN_WIDTH
        lsl     x23, x23, BYTES_PER_PIXEL_SHIFT // x23 = "fi" = offset in bytes between two consecutive rows


        cmp     x20, 0                          // dy < 0 ?
        b.ge    draw_line_low_slope__nneg_dy    // continue if dy >= 0
        sub     x20, xzr, x20                   // dy = -dy
        sub     x22, xzr, x22                   // yi = -yi TODO: remove? (unused)
        sub     x23, xzr, x23                   // fi = -fi
draw_line_low_slope__nneg_dy:


        lsl     x21, x20, 1     // x21 = 2*dy
        sub     x21, x21, x19   // x21 = 2*dy - dx = D

        lsl     x24, x19, 1      // x24 = 2*dx
        lsl     x25, x20, 1      // x25 = 2*dy

        mov     x26, x0         // x26 = x
        mov     x27, x1         // x27 = y (unused)


draw_line_low_slope__next_col:
        str     w5, [x4]                        // Paint pixel at (x,y)
        add     x4, x4, BYTES_PER_PIXEL         // Move framebuffer one pixel right

        cmp     x21, 0                          // D > 0 ?
        b.le    draw_line_low_slope__keep_y     // if D <= 0 then stay in the same row
        add     x27, x27, x22                   // y = y + yi
        sub     x21, x21, x24                   // D = D - 2*dx
        add     x4, x4, x23                     // f = f + fi   move framebuffer by fi (+/- one row)
draw_line_low_slope__keep_y:

        add     x21, x21, x25           // D = D + 2*dy
        add     x26, x26, 1             // x = x + 1
        // Check if we finished drawing line
        cmp     x26, x2                 // x <= x1?
        b.le    draw_line_low_slope__next_col



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



/*
 * Params:
 *      x0: top point screen x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: top point screen y coordinate            (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x2: bottom point screen x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: bottom point screen y coordinate         (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line_high_slope:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x19, SCREEN_WIDTH               // x19 = screen width
        mul     x19, x19, x1                    // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['line's topmost pixel']



        sub     x19, x2, x0                     // x19 = dx = x1 - x0
        sub     x20, x3, x1                     // x20 = dy = y1 - y0
        mov     x22, 1                          // x22 = xi = 1 (assume dx >= 0)
        mov     x23, BYTES_PER_PIXEL            // x23 = "fi" = how much to move framebuffer when moving to the next column


        cmp     x19, 0                          // dx < 0 ?
        b.ge    draw_line_high_slope__nneg_dx   // continue if dx >= 0
        sub     x19, xzr, x19                   // dx = -dx
        sub     x22, xzr, x22                   // xi = -xi TODO: remove? (unused)
        sub     x23, xzr, x23                   // fi = -fi
draw_line_high_slope__nneg_dx:


        lsl     x21, x19, 1     // x21 = 2*dx
        sub     x21, x21, x20   // x21 = 2*dx - dy = D

        lsl     x24, x19, 1      // x24 = 2*dx
        lsl     x25, x20, 1      // x25 = 2*dy

        mov     x27, x1         // x27 = y = y0
        mov     x26, x0         // x26 = x = x0 (unused)


draw_line_high_slope__next_row:
        str     w5, [x4]                        // Paint pixel at (x,y)
        add     x4, x4, BYTES_PER_SCREEN_ROW    // Move framebuffer one row down

        cmp     x21, 0                          // D > 0 ?
        b.le    draw_line_high_slope__keep_x    // if D <= 0 then stay in the same column
        add     x26, x26, x22                   // x = x + xi
        sub     x21, x21, x25                   // D = D - 2*dy
        add     x4, x4, x23                     // f = f + fi   move framebuffer by fi (+/- one column)
draw_line_high_slope__keep_x:

        add     x21, x21, x24           // D = D + 2*dx
        add     x27, x27, 1             // y = y + 1
        // Check if we finished drawing line
        cmp     x27, x3                 // y <= y1 ?
        b.le    draw_line_high_slope__next_row



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret


/*
 * Params:
 *      x0: u64         <- x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- length > 0
 *      w3: u32         <- color
 *      x4: out u32*    <- beginning of framebuffer
 * Comments:
 *      Draws a line from (x0, x1) to (x0 + x2, x1)
 */
draw_horizontal_line:
        stp     lr, x19, [sp, -16]!

        mov     x5, x4
        mov     w4, w3
        mov     x3, x2
        mov     x2, BYTES_PER_PIXEL
        bl      draw_line_by_offset

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: u64         <- x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- length > 0
 *      w3: u32         <- color
 *      x4: out u32*    <- beginning of framebuffer
 * Comments:
 *      Draws a line from (x0, x1) to (x0, x1 + x2)
 */
draw_vertical_line:
        stp     lr, x19, [sp, -16]!

        mov     x5, x4
        mov     w4, w3
        mov     x3, x2
        mov     x2, SCREEN_WIDTH
        lsl     x2, x2, BYTES_PER_PIXEL_SHIFT
        sub     x2, xzr, x2
        bl      draw_line_by_offset

        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: u64         <- x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- offset in bytes
 *      x3: u64         <- steps > 0
 *      w4: u32         <- color
 *      x5: out u32*    <- beginning of framebuffer
 * Comments:
 *      Draws a line from (x0, x1) to (x0 + x2, x1)
 */
draw_line_by_offset:
        stp     lr, x19, [sp, -16]!

        // Convert game y coordinates to screen y coordinates
        mov     x9, (SCREEN_HEIGH - 1)
        sub     x1, x9, x1

        mov     x9, SCREEN_WIDTH              // x9 = screen width
        mul     x9, x9, x1                    // x9 = initial vertical offset
        add     x9, x9, x0                    // x9 = initial vertical offset + initial horizontal offset
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT // x9 = total offset
        add     x5, x5, x9                    // x5 = &framebuffer['first pixel of line']


draw_line_by_offset__next_pixel:
        str     w4, [x5]                                // Color pixel
        add     x5, x5, x2                              // Advance to next pixel by offset parameter
        subs    x3, x3, 1                               // Decrement remaining steps
        b.gt    draw_line_by_offset__next_pixel         // Loop only if line has not been completed

        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: in struct TetrominoState*   <- tetromino_state
 *      x1: in struct BoardState*       <- board_state
 * Returns:
 *      x0: enum CollisionResult        <- collision_result
 */
check_collision:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]


        ldr     x19, [x0, TSTATE_ID]                    // x19 <- current tetromino index
        mov     x9, STRUCT_TETROMINO_SIZE               //  x9 <- sizeof(struct Tetromino)
        mul     x19, x19, x9                            // x19 <- offset in bytes to current tetromino (relative to start of array)
        add     x19, x19, TETROMINOS + TETROMINO_ROTS   // x19 <- pointer to rotations of current tetromino

        ldr     x20, [x0, TSTATE_ROT]           // x20 <- current rotation index
        mov     x9, STRUCT_TDATA_SIZE           //  x9 <- sizeof(struct TetrominoData)
        mul     x20, x20, x9                    // x20 <- offset in bytes to current rotation

        add     x1, x1, BSTATE_BOARD            //  x1 <- pointer to board matrix
        ldr     x10, [x0, TSTATE_POS_X]         // x10 <- tetromino pos x
        ldr     x11, [x0, TSTATE_POS_Y]         // x11 <- tetromino pos y
        add     x19, x19, x20                   // x19 <- pointer to current rotation

        /* Iterators */
        mov     x20, 0                          // x20 <- x coordinate in tetromino matrix
        mov     x21, 0                          // x21 <- y coordinate in tetromino matrix

        /* Start loop for each block in tetromino */
check_collision__check_next_block:
        /* Index block at (x20, x21) of tetromino */
        mov     x9, TETROMINO_BOARD_WIDTH
        mul     x9, x9, x21                             // x9 <- vertical offset to current tetromino block
        add     x9, x9, x20                             // x9 <- vertical + horizontal offset to current tetromino block
        lsl     x9, x9, BYTES_PER_TETROMINO_BLOCK_SHIFT // x9 <- vertical + horizontal offset in bytes to current tetromino block
        add     x9, x19, x9                             // x9 <- pointer to current tetromino block
        ldr     x9, [x9]                                // x9 <- current tetromino block

        cbz     x9, check_collision__next       // go to next block if current block is zero (nothing to check)

        /* Current block is not air */

        add     x22, x20, x10   // x22 <- pos x of block to check relative to origin of board
        add     x23, x21, x11   // x23 <- pos y of block to check relative to origin of board

        // Check 0 <= x22 < BOARD_WIDTH
        cmp     x22, 0
        b.lt    check_collision__out_of_bounds
        cmp     x22, BOARD_WIDTH
        b.ge    check_collision__out_of_bounds
        // Check 0 <= x23 < BOARD_HEIGHT
        cmp     x23, 0
        b.lt    check_collision__out_of_bounds
        cmp     x23, BOARD_HEIGHT
        b.ge    check_collision__out_of_bounds

        /* Block is inside board */

        /* Index block at (x22, x23) in board */
        mov     x9, BOARD_WIDTH
        mul     x9, x9, x23                             // x9 <- vertical offset to block in board
        add     x9, x9, x22                             // x9 <- vertical + horizontal offset to block in board
        lsl     x9, x9, BYTES_PER_TETROMINO_BLOCK_SHIFT // x9 <- vertical + horizontal offset in bytes to block in board
        add     x9, x1, x9                              // x9 <- pointer to block in board
        ldr     x9, [x9]                                // x9 <- block at (x22, x23) in board

        cbnz    x9, check_collision__existing_block     // branch if there's already a block in board

        /* Block is not on top of another one. Check finished */

check_collision__next:
        add     x20, x20, 1                     // advance x pos
        cmp     x20, TETROMINO_BOARD_WIDTH      // check if there are remaining blocks in current row
        b.lt    check_collision__check_next_block
        /* We are at end of row */

        mov     x20, 0                          // set x to beginning of row
        add     x21, x21, 1                     // advance y pos
        cmp     x20, TETROMINO_BOARD_WIDTH      // check if there are remaining rows of tetromino
        b.lt    check_collision__check_next_block
        /* We finished checking entire tetromino */

        mov     x0, COLLISION_RESULT_NO_COLLISION
        b       check_collision__end

check_collision__out_of_bounds:
        mov     x0, COLLISION_RESULT_OUT_OF_BOUNDS
        b       check_collision__end

check_collision__existing_block:
        mov     x0, COLLISION_RESULT_EXISTING_BLOCK
        b       check_collision__end


check_collision__end:
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret


/*
 * Params:
 *      x0: out struct ChooserBagState*  <- chooser_bag_state
 */
recreate_chooser_bag:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        mov     w19, NUM_TETROMINOS             // x19 <- NUM_TETROMINOS
        strb    w19, [x0, CBAG_REMAINING]       // chooser_bag_state.remaining = NUM_TETROMINOS

        add     x20, x0, CBAG_VALUES    // x20 = &chooser_bag_state.values[0]

        mov     x21, 0                  // i = 0
recreate_chooser_bag__init_values:
        strb    w21, [x20]              // chooser_bag_state.values[i] = i
        add     x20, x20, 1             // x20 = &chooser_bag_state.values[i + 1] (move to next byte)
        add     x21, x21, 1             // i += 1
        cmp     x21, NUM_TETROMINOS     // i < NUM_TETROMINOS ?
        b.lt    recreate_chooser_bag__init_values
        /* values == [0, 1, 2, 3, ..., NUM_TETROMINOS - 1] */


        add     x20, x0, CBAG_VALUES    // x20 <- pointer to the beginning of the array's segment that remains 'not randomized'
        mov     w21, NUM_TETROMINOS     // w21 <- amount of remaining (non randomized) tetrominos

recreate_chooser_bag__randomize:
        /* Gen random number in range [0..rem_tetrominos) */
        mov     w0, 0
        mov     w1, w21
        bl      rand_gen_in_range
        /* x0 contains random index */

        // Swap a[0] with a[r]
        add     x9, x20, x0     // x9 = &a[r] = pointer to the randomly chosen element
        ldrb    w22, [x20]      // w22 = a[0]
        ldrb    w23, [x9]       // w23 = a[r]
        strb    w23, [x20]      // a[0] = a[r]
        strb    w22, [x9]       // a[r] = a[0]

        add     x20, x20, 1             // advance array pointer to the beginning of the next segment
        subs    w21, w21, 1             // decrement remaining tetrominos
        b.gt    recreate_chooser_bag__randomize // loop only if more than 1 tetromino is not yet randomized
        /* values = [randomized] */


        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: in/out struct ChooserBagState*  <- chooser_bag_state
 * Returns:
 *      x0: u64         <- tetromino_id
 */
choose_next_tetromino:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0         // x19 <- struct ChooserBagState*

        ldrb    w9, [x19, CBAG_REMAINING]               // w9 = chooser_bag_state.remaining
        cmp     w9, 0                                   // chooser_bag_state.remaining == 0 ?
        b.gt    choose_next_tetromino__dont_recreate
        /* Bag out of values, we need to recreate it */
        mov     x0, x19
        bl      recreate_chooser_bag
choose_next_tetromino__dont_recreate:

        /* Load last value and decrement remaining count */
        ldrb    w9, [x19, CBAG_REMAINING]       // x9 = chooser_bag_state.remaining
        sub     w9, w9, 1                       // x9 <- index of last element in bag
        strb    w9, [x19, CBAG_REMAINING]       // chooser_bag_state.remaining -= 1
        add     x9, x9, CBAG_VALUES             // x9 <- offset to start of array + index of last element
        add     x9, x19, x9                     // x9 <- pointer to last element of array
        ldrb    w0, [x9]                        // x0 = chooser_bag_state.values[LAST]


        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      w0: u32         <- min (inclusive)
 *      w1: u32         <- max (exclusive)
 * Returns:
 *      w0: u32         <- random number in range [min; max)
 */
rand_gen_in_range:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     x19, =RNG_NUMBER_ADDRESS
        ldr     w19, [x19]              // w19 <- random number in range [0..U32_MAX]

        sub     w20, w1, w0             // w20 <- max - min == length of range
        udiv    w21, w19, w20           // w21 <- R div (max - min)
        mul     w21, w21, w20           // w21 <- (R div (max - min)) * (max - min)

        sub     w19, w19, w21           // w19 <- remainder of R / (max - min), in range [0..(max - min))
        add     w0, w19, w0             //  w0 <- offseted remainder, in range [min..max)

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: u64         <- binary number
 *      x1: out u8*     <- output buffer
 *      x2: u64         <- buffer length
 * Returns:
 *      x0: u64         <- amount of digits of decimal number
 * Comments:
 *      Number is converted to binary and written to the buffer pointed by x1,
 *      where each element represents a decimal digit.
 *      Least significant digits are written to the beginning of the array.
 *      E.g.: convert 0xFF to decimal (255)
 *              -> x1 = [5, 5, 2]
 */
binary_to_decimal:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, x0                 // x19 <- current dividend
        mov     x20, 10                 // x20 <- divisor (always 10)
        mov     x21, 0                  // x21 <- i (current digit, from right to left, used for indexing buffer)

binary_to_decimal__next_digit:
        cmp     x21, x2                 // check if there is buffer remaining
        b.ge    binary_to_decimal__end  // break if buffer ended

        udiv    x9, x19, x20            //  x9 <- dividend `div` 10             (quotient)
        mul     x10, x9, x20            // x10 <- (dividend `div` 10) * 10      (quotient times divisor)
        sub     x10, x19, x10           // x10 <- remainder of x19 / 10         (remainder, in range [0..9])

        strb    w10, [x1]               // store digit in buffer
        mov     x19, x9                 // use quotient as new dividend
        add     x1, x1, 1               // advance pointer to next element
        add     x21, x21, 1             // increment index
        cbnz    x19, binary_to_decimal__next_digit      // loop only if new dividend is not 0

binary_to_decimal__end:
        mov     x0, x21         // x0 <- amount of digits of converted decimal number

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: u64         <- bottom left x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- bottom left y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- width  =>  height = 2 * width - 1
 *      w3: u8          <- binary digit in range [0..9]
 *      w4: u32         <- color
 *      x5: out u8*     <- beginning of framebuffer
 */
draw_decimal_digit:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov     x20, x0                 // x20 <- bottom left x coordinate
        mov     x21, x1                 // x21 <- bottom left y coordinate
        mov     x22, x2                 // x22 <- segment size
        mov     w23, w4                 // w23 <- color
        mov     x24, x5                 // x24 <- beginning of framebuffer

        ldr     x19, =DIGITS_FONT       // x19 <- pointer to array of digits font
        lsl     x9, x3, 2               // Convert index (digit) to offset in bytes (u32)
        add     x19, x19, x9            // x19 <- pointer to data for our digit
        ldr     w19, [x19]              // w19 <- segment flags of our digit


        and     w9, w19, DIGIT_SEGMENT_0
        cbz     w9, draw_decimal_digit__skip_seg_0

        mov     x0, x20
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line
draw_decimal_digit__skip_seg_0:


        and     w9, w19, DIGIT_SEGMENT_1
        cbz     w9, draw_decimal_digit__skip_seg_1

        mov     x0, x20
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_1:


        and     w9, w19, DIGIT_SEGMENT_2
        cbz     w9, draw_decimal_digit__skip_seg_2

        add     x0, x20, x22
        sub     x0, x0, 1
        mov     x1, x21
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_2:


        and     w9, w19, DIGIT_SEGMENT_3
        cbz     w9, draw_decimal_digit__skip_seg_3

        mov     x0, x20
        add     x1, x21, x22
        sub     x1, x1, 1
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line
draw_decimal_digit__skip_seg_3:


        and     w9, w19, DIGIT_SEGMENT_4
        cbz     w9, draw_decimal_digit__skip_seg_4

        mov     x0, x20
        add     x1, x21, x22
        sub     x1, x1, 1
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_4:


        and     w9, w19, DIGIT_SEGMENT_5
        cbz     w9, draw_decimal_digit__skip_seg_5

        add     x0, x20, x22
        sub     x0, x0, 1
        add     x1, x21, x22
        sub     x1, x1, 1
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_vertical_line
draw_decimal_digit__skip_seg_5:


        and     w9, w19, DIGIT_SEGMENT_6
        cbz     w9, draw_decimal_digit__skip_seg_6

        mov     x0, x20
        add     x1, x21, x22
        add     x1, x1, x22
        sub     x1, x1, 2
        mov     x2, x22
        mov     w3, w23
        mov     x4, x24
        bl      draw_horizontal_line
draw_decimal_digit__skip_seg_6:


        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret



/*
 * Params:
 *      x0: u64         <- bottom left x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- bottom left y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: u64         <- width  =>  height = 2 * width - (thickness % 2)
 *      x3: u64         <- thickness
 *      w4: u8          <- binary digit in range [0..9]
 *      w5: u32         <- color
 *      x6: out u8*     <- beginning of framebuffer
 */
draw_decimal_digit_with_thickness:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x20, x0                 // x20 <- bottom left x coordinate
        mov     x21, x1                 // x21 <- bottom left y coordinate
        mov     w22, w5                 // w22 <- color
        mov     x23, x6                 // x23 <- beginning of framebuffer


        sub     x24, x2, 1              // x24 <- A = width - 1
        sub     x25, x3, 1              // x25 <- B = thickness - 1
        lsr     x26, x3, 1              // x26 <- C = thickness / 2
        add     x27, x24, x26           // x27 <- D = A + C

        sub     sp, sp, 8
        and     x9, x3, 0b1             // 1 if odd, 0 if even
        eor     x9, x9, 0b1             // 1 if even, 0 if odd
        add     x9, x24, x9             // x9 = A + (0|1)
        sub     x9, x9, x26             // x9 = A - C + (0|1)
        str     x9, [sp]                // [sp] = A - C + (0|1)



        ldr     x19, =DIGITS_FONT       // x19 <- pointer to array of digits font
        lsl     x9, x4, 2               // Convert index (digit) to offset in bytes (u32)
        add     x19, x19, x9            // x19 <- pointer to data for our digit
        ldr     w19, [x19]              // w19 <- segment flags of our digit





        and     w9, w19, DIGIT_SEGMENT_0
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_0

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x25    // x3 <- y + B
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_0:


        and     w9, w19, DIGIT_SEGMENT_1
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_1

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x25    // x2 <- x + B
        add     x3, x21, x27    // x3 <- y + D
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_1:


        and     w9, w19, DIGIT_SEGMENT_2
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_2

        add     x0, x20, x24    // x0 <- x + A
        sub     x0, x0, x25     // x0 <- x + A - B
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x27    // x3 <- y + D
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_2:


        ldr     x9, [sp]
        add     x21, x21, x9    // y = y + (A - C + (0|1))


        and     w9, w19, DIGIT_SEGMENT_3
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_3

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x25    // x3 <- y + B
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_3:


        and     w9, w19, DIGIT_SEGMENT_4
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_4

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x25    // x2 <- x + B
        add     x3, x21, x24    // x3 <- y + A
        add     x3, x3, x26     // x3 <- y + A + C
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_4:


        and     w9, w19, DIGIT_SEGMENT_5
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_5

        add     x0, x20, x24    // x0 <- x + A
        sub     x0, x0, x25     // x0 <- x + A - B
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x24    // x3 <- y + A
        add     x3, x3, x26     // x3 <- y + A + C
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_5:


        ldr     x9, [sp]
        add     x21, x21, x9    // y = y + (A - C + (0|1))


        and     w9, w19, DIGIT_SEGMENT_6
        cbz     w9, draw_decimal_digit_with_thickness__skip_seg_6

        mov     x0, x20         // x0 <- x
        mov     x1, x21         // x1 <- y
        add     x2, x20, x24    // x2 <- x + A
        add     x3, x21, x25    // x3 <- y + B
        mov     x4, x23         // x4 <- framebuffer
        mov     w5, w22         // w5 <- color
        bl      draw_filled_rectangle
draw_decimal_digit_with_thickness__skip_seg_6:

        add     sp, sp, 8

        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret


/*
 * Params:
 *      x0: u64         <- bottom right x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: u64         <- bottom right y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      w2: u32         <- color
 *      x3: out u8*     <- beginning of framebuffer
 */
draw_time:
        stp     lr, x19, [sp, -16]!

        sub     sp, sp, STRUCT_DNI_SIZE

        str     x0, [sp, DNI_POS_X]
        str     x1, [sp, DNI_POS_Y]
        mov     x9, 5
        str     x9, [sp, DNI_MAX_DIGITS]
        mov     x9, 33
        str     x9, [sp, DNI_DIGIT_WIDTH]
        mov     x9, 8
        str     x9, [sp, DNI_DIGIT_THICKNESS]
        mov     x9, 8
        str     x9, [sp, DNI_DIGIT_SPACING]
        str     w2, [sp, DNI_COLOR]

        bl      get_time
        mov     w9, 1000
        udiv    w0, w0, w9      // w0 <- time in milliseconds

        str     x0, [sp, DNI_VALUE]

        mov     x0, sp
        mov     x1, x3          // x1 <- beginning of framebuffer
        bl      draw_number

        add     sp, sp, STRUCT_DNI_SIZE

        ldp     lr, x19, [sp], 16
        ret




/*
 * Params:
 *      x0: in/out struct DrawNumberInfo*       <- draw_number_info   (consumed)
 *      x1: out u8*                             <- beginning of framebuffer
 */
draw_number:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        /* (dni.pos_x, dni.pos_y) represents the bottom right coordinate of the drawn number */

        mov     x19, x1                 // const x19 <- beginning of framebuffer
        mov     x20, x0                 // const x20 <- in/out struct DrawNumberInfo*

        ldr     x9, [x20, DNI_MAX_DIGITS]
        sub     sp, sp, x9              // Make space for digits array
        mov     x21, sp                 // x21: const u8* <- pointer to beginning of digits array

        // Convert number to decimal
        ldr     x0, [x20, DNI_VALUE]    // x0 <- number to draw
        mov     x1, x21                 // x1 <- pointer to digits array
        mov     x2, x9                  // x2 <- max digits
        bl      binary_to_decimal

        mov     x22, x0                 // x22 <- amount of digits to draw (<= max digits)

draw_number__next_digit:
        ldr     x9, [x20, DNI_POS_X]            // x9 = dni.pos_x
        ldr     x10, [x20, DNI_DIGIT_WIDTH]     // x10 = dni.digit_width
        sub     x9, x9, x10                     // x9 -= dni.digit_width <- move x coordinate left by digit width
        add     x9, x9, 1                       // x9 += 1 <- x coordinate points to bottom left coordinate of digit
        str     x9, [x20, DNI_POS_X]            // dni.pos_x = x9

        ldr     x0, [x20, DNI_POS_X]            // x0 <- x coordinate
        ldr     x1, [x20, DNI_POS_Y]            // x1 <- y coordinate
        ldr     x2, [x20, DNI_DIGIT_WIDTH]      // x2 <- digit width
        ldr     x3, [x20, DNI_DIGIT_THICKNESS]  // x3 <- thickness
        ldrb    w4, [x21]                       // w4 <- digits[i]
        ldr     w5, [x20, DNI_COLOR]            // w5 <- color
        mov     x6, x19                         // x6 <- beginning of framebuffer
        bl      draw_decimal_digit_with_thickness // draw digit

        ldr     x9, [x20, DNI_POS_X]            // x9 = dni.pos_x
        ldr     x10, [x20, DNI_DIGIT_SPACING]   // x10 = dni.digit_spacing
        sub     x9, x9, x10                     // x9 -= dni.digit_spacing <- move x by digit spacing for drawing next digit
        sub     x9, x9, 1                       // (off by one)
        str     x9, [x20, DNI_POS_X]            // dni.pos_x = x9
        add     x21, x21, 1                     // x21 = &digits[i + 1] <- pointer to next digit
        subs    x22, x22, 1                     // x22 <- decrement remaining digits and check if any remain
        b.gt    draw_number__next_digit

        /* All digits are drawn */

        ldr     x9, [x20, DNI_MAX_DIGITS]
        add     sp, sp, x9              // Pop digits array from stack

        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret

















test_binary_to_decimal:
        stp     lr, x19, [sp, -16]!


        sub     sp, sp, 4       // reserve space for 4 digits
        mov     x0, 0           // use 0 as initial number
test_binary_to_decimal__again:
        mov     x1, sp
        mov     x2, 4
        bl      binary_to_decimal

        mov     w0, 0
        ldr     w1, =TEST_BINARY_TO_DECIMAL_MAX
        bl      rand_gen_in_range
        b       test_binary_to_decimal__again
        add     sp, sp, 4


        ldp     lr, x19, [sp], 16
        ret



