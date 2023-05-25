	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32
	.equ BYTES_PER_PIXEL, 4
	.equ BYTES_PER_PIXEL_SHIFT, 2
        .equ BYTES_PER_SCREEN_ROW, SCREEN_WIDTH * BYTES_PER_PIXEL


        .equ BOARD_WIDTH,               10
        .equ BOARD_HEIGHT,              22
        .equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
        .equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1

        .equ TETROMINO_BOARD_WIDTH,             4
        .equ TETROMINO_BOARD_SIZE,              TETROMINO_BOARD_WIDTH * TETROMINO_BOARD_WIDTH
        .equ TETROMINO_BOARD_SIZE_IN_BYTES,     TETROMINO_BOARD_SIZE * 1
        .equ NUM_ORIENTATIONS,                  4

        .equ NUM_TETROMINOS,                    7


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
        .equ MS_PER_STEP,               500
        .equ US_PER_STEP,               MS_PER_STEP * 1000

        BG_COLORS: .word 0x00FF0000, 0x000FF000, 0x0000FF00, 0x00000FF0, 0x000000FF, 0x00F0000F
        BG_COLOR: .dword 0xFFFFFFFF
        PLAYER_COLOR: .dword 0xFFFFFFFF

	.globl main

/* struct GameState */
        .equ INPUT_STATE,               0                                       // struct InputState
        .equ TETROMINO_STATE,           INPUT_STATE + STRUCT_INPUT_STATE_SIZE   // struct TetrominoState
        .equ BOARD_STATE,               TETROMINO_STATE + STRUCT_TSTATE_SIZE    // u8[22][10]

        .equ STRUCT_GAME_STATE_SIZE,    BOARD_STATE + BOARD_SIZE_IN_BYTES

/* struct InputState */
        .equ PRESSED_STATE,             0                       // u32
        .equ ON_PRESS_STATE,            PRESSED_STATE + 4       // u32

        .equ STRUCT_INPUT_STATE_SIZE,   ON_PRESS_STATE + 4

/* struct TetrominoState */
        .equ TSTATE_ID,                 0                       // u64
        .equ TSTATE_POS_X,              TSTATE_ID + 8           // i64
        .equ TSTATE_POS_Y,              TSTATE_POS_X + 8        // i64
        .equ TSTATE_ROT,                TSTATE_POS_Y + 8        // u64

        .equ STRUCT_TSTATE_SIZE,        TSTATE_ROT + 8

/* struct Tetromino */
        .equ TETROMINO_COLOR,           0                           // u32
        .equ TETROMINO_DATAS,           TETROMINO_COLOR + 4         // struct TetrominoData[4]

        .equ STUCT_TETROMINO_SIZE,      TETROMINO_DATAS + (TDATA_SIZE * NUM_ORIENTATIONS)

/* struct TetrominoData */
        .equ TDATA,                     0                       // u8[4][4]             [0][0] is bottom left, [0][3] is bottom right

        .equ TDATA_SIZE,                TDATA + TETROMINO_BOARD_SIZE_IN_BYTES


/* Data for all 7 tetrominos */
TETROMINOS:
/* Tetromino I: */
        .word 0x31C7EF  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010101
        .word 0x00000000

        .word 0x00010000
        .word 0x00010000
        .word 0x00010000
        .word 0x00010000

        .word 0x00000000
        .word 0x01010101
        .word 0x00000000
        .word 0x00000000

        .word 0x00000100
        .word 0x00000100
        .word 0x00000100
        .word 0x00000100


/* Tetromino J: */
        .word 0x5A65AD  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010100
        .word 0x01000000

        .word 0x00000000
        .word 0x01010000
        .word 0x00010000
        .word 0x00010000

        .word 0x00000000
        .word 0x00000100
        .word 0x01010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00010000
        .word 0x00010000
        .word 0x00010100

/* Tetromino L: */
        .word 0xEF7921  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010100
        .word 0x00000100

        .word 0x00000000
        .word 0x00010000
        .word 0x00010000
        .word 0x01010000

        .word 0x00000000
        .word 0x01000000
        .word 0x01010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00010100
        .word 0x00010000
        .word 0x00010000

/* Tetromino O: */
        .word 0xF7D308  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

/* Tetromino S: */
        .word 0x42B642  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010000
        .word 0x00010100

        .word 0x00000000
        .word 0x00010000
        .word 0x01010000
        .word 0x01000000

        .word 0x00000000
        .word 0x01010000
        .word 0x00010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00000100
        .word 0x00010100
        .word 0x00010000

/* Tetromino Z: */
        .word 0xEF2029  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x01010000

        .word 0x00000000
        .word 0x01000000
        .word 0x01010000
        .word 0x00010000

        .word 0x00000000
        .word 0x00010100
        .word 0x01010000
        .word 0x00000000

        .word 0x00000000
        .word 0x00010000
        .word 0x00010100
        .word 0x00000100

/* Tetromino T: */
        .word 0xAD4D9C  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010100
        .word 0x00010000

        .word 0x00000000
        .word 0x00010000
        .word 0x01010000
        .word 0x00010000

        .word 0x00000000
        .word 0x00010000
        .word 0x01010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00010000
        .word 0x00010100
        .word 0x00010000



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


        // Allocate struct GameState
        sub     sp, sp, STRUCT_GAME_STATE_SIZE
        // TODO: implement init_game_state subroutine
        add     x0, sp, INPUT_STATE
        bl      init_input_state
        add     x0, sp, TETROMINO_STATE
        bl      init_tetromino_state



        ldr     x0, =TETROMINOS

        mov     x20, #320               // Player x coordinate        (bottom) 1 <= x <= SCREEN_HEIGHT (top)
        mov     x21, #240               // Player y coordinate         (right) 1 <= x <= SCREEN_WIDTH (left)
        mov     x22, 0                  // bg color index | default 0
        ldr     w23, BG_COLORS          // bg color | default BG_COLORS[0]
        ldr     w24, PLAYER_COLOR       // player color | default PLAYER_COLOR

        mov     x10, 0                  // square x coordinate
        mov     x11, 0                  // square y coordinate
        mov     x12, 50                 // square size
        bl      get_time
        mov     w13, w0                 // w13 last movement

	// Ejemplo de uso de gpios
	mov     x9, GPIO_BASE

	// Setea gpios 0 - 9 como lectura
	str     wzr, [x9, GPIO_GPFSEL0]

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
        cmp     x25, x20                 // Check if we are in same column as player
        b.ne    pxl_bg
        cmp     x26, x21                 // Check if we are in same row as player
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


        mov     x0, x10
        mov     x1, x11
        mov     w2, w13
        mov     x3, x12
        bl      advance_square_maybe
        mov     x10, x0
        mov     x11, x1
        mov     w13, w2


        mov     x0, x10
        mov     x1, x11
        mov     x2, x12
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

        b game_loop

/*
 * Params:
 *      x0: mut struct InputState*
 */
init_input_state:
        stur    wzr, [x0, PRESSED_STATE]
        stur    wzr, [x0, ON_PRESS_STATE]
        ret

/*
 * Params:
 *      x0: mut struct TetrominoState*
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
 *      x0: mut struct InputState*
 */
read_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     w19, [x0, PRESSED_STATE]        // Save last pressed state to compute on press state

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

        ldr     w0, [x19, PRESSED_STATE]
        mov     x1, x20

        bl      handle_w
        bl      handle_a
        bl      handle_s
        bl      handle_d
        bl      handle_space

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
        cmp     x19, (SCREEN_HEIGH - 1)   // Check if player is touching top edge
        b.eq    handle_w__end

        add     x19, x19, 1               // Move player one position up
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
        cmp     x19, 0                   // Check if player is touching bottom edge
        b.eq    handle_s__end

        sub     x19, x19, 1               // Move player one position down
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
        cmp     x19, 0                          // Check if player is touching left edge
        b.eq    handle_a__end

        sub     x19, x19, 1                     // Move player one position left
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
        cmp     x19, (SCREEN_WIDTH - 1)         // Check if player is touching right edge
        b.eq    handle_d__end

        add     x19, x19, 1                     // Move player one position right
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
        mov     w19, w1                         // Set last step as current time
        add     x20, x20, x3                    // Advance square position by its size

        ldr     x0, =SCREEN_WIDTH
        sub     x0, x0, x3
        cmp     x20, x0                         // Check if square is horizontally out of bounds
        b.lt    advance_square_maybe__end

        // Square is at end of row
        mov     x20, 0                          // Set square at beginning of row
        add     x21, x21, x3                    // Move square one row up


        ldr     x0, =SCREEN_HEIGH
        sub     x0, x0, x3
        cmp     x21, x0                         // Check if square is vertically out of bounds
        b.lt    advance_square_maybe__end

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
 *      x0: left point x coordinate            (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: left point y coordinate          (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: right point x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: right point y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
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
