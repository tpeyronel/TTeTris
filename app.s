	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32
	.equ BYTES_PER_PIXEL, 4
	.equ BYTES_PER_PIXEL_SHIFT, 2


        .equ BOARD_WIDTH,               10
        .equ BOARD_HEIGHT,              22
        .equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
        .equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1

        .equ TETROMINO_BOARD_WIDTH,             4
        .equ TETROMINO_BOARD_SIZE,              TETROMINO_BOARD_WIDTH * TETROMINO_BOARD_WIDTH
        .equ TETROMINO_BOARD_SIZE_IN_BYTES,     TETROMINO_BOARD_SIZE * 1
        .equ NUM_ORIENTATIONS,                  4

        .equ NUM_TETROMINOS,                    4


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
        .equ CURRENT_TETROMINO,         0                                            // struct TetrominoState
        .equ BOARD_STATE,               CURRENT_TETROMINO + STRUCT_TSTATE_SIZE       // u8[22][10]

        .equ STRUCT_GAME_STATE_SIZE,    BOARD_STATE + BOARD_SIZE_IN_BYTES

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

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str     wzr, [x9, GPIO_GPFSEL0]

draw_screen:
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

	// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
	// al inmediato se lo refiere como "máscara" en este caso:
	// - Al hacer AND revela el estado del bit 2
	// - Al hacer OR "setea" el bit 2 en 1
	// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)

        mov     x0, x20         // x0 = player x
        mov     x1, x21         // x1 = player y
        mov     x2, x22         // x2 = bg color index
        bl      handle_input
        mov     x20, x0
        mov     x21, x1
        mov     x22, x2

redraw:
        b draw_screen


/*
 * Params:
 *      x0: player x position
 *      x1: player y position
 *      x2: background color index
 * Returns:
 *      x0: modified player x position
 *      x1: modified player y position
 *      x2: modified background color index
 */
handle_input:
        sub     sp, sp, 32
        str     lr, [sp]
        str     x19, [sp, 8]
        str     x20, [sp, 16]

        mov     x22, x3         // Save x3
        mov     x3, x2          // Use x3 as bg color index

	mov     x19, GPIO_BASE
	ldr     w2, [x19, GPIO_GPLEV0]

        bl      handle_w
        bl      handle_a
        bl      handle_s
        bl      handle_d
        bl      handle_space

        mov     x2, x3          // Move bg color index back to x2
        mov     x3, x22         // Restore x3

        ldr     x20, [sp, 16]
        ldr     x19, [sp, 8]
        ldr     lr, [sp]
        add     sp, sp, 32
        ret

/*
 * Params:
 *      x0: player x position
 *      x1: player y position
 *      x2: GPIO_GPLEV0 flags
 * Returns:
 *      x0: modified player x position
 *      x1: modified player y position
 */
handle_w:
        stp     lr, x19, [sp, -16]!

	and     x19, x2, GPIO_W
        cbz     x19, end_handle_w

        cmp     x1, SCREEN_HEIGH        // Check if player is touching top edge
        b.eq    end_handle_w

        add     x1, x1, 1               // Move player one position up

end_handle_w:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: player x position
 *      x1: player y position
 *      x2: GPIO_GPLEV0 flags
 * Returns:
 *      x0: modified player x position
 *      x1: modified player y position
 */
handle_s:
        stp     lr, x19, [sp, -16]!

	and     x19, x2, GPIO_S
        cbz     x19, end_handle_s

        cmp     x1, 1                   // Check if player is touching bottom edge
        b.eq    end_handle_s

        sub     x1, x1, 1               // Move player one position down

end_handle_s:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: player x position
 *      x1: player y position
 *      x2: GPIO_GPLEV0 flags
 * Returns:
 *      x0: modified player x position
 *      x1: modified player y position
 */
handle_a:
        stp     lr, x19, [sp, -16]!

	and     x19, x2, GPIO_A
        cbz     x19, end_handle_a

        cmp     x0, SCREEN_WIDTH        // Check if player is touching left edge
        b.eq    end_handle_a

        add     x0, x0, 1               // Move player one position left

end_handle_a:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: player x position
 *      x1: player y position
 *      x2: GPIO_GPLEV0 flags
 * Returns:
 *      x0: modified player x position
 *      x1: modified player y position
 */
handle_d:
        stp     lr, x19, [sp, -16]!

	and     x19, x2, GPIO_D
        cbz     x19, end_handle_d

        cmp     x0, 1                   // Check if player is touching right edge
        b.eq    end_handle_d

        sub     x0, x0, 1               // Move player one position right

end_handle_d:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: player x position
 *      x1: player y position
 *      x2: GPIO_GPLEV0 flags
 *      x3: background color index
 * Returns:
 *      x0: modified player x position
 *      x1: modified player y position
 *      w2: -
 *      x3: modified background color index
 */
handle_space:
        stp     lr, x19, [sp, -16]!

	and     x19, x2, GPIO_SPACE
        cbz     x19, end_handle_space

        add     x3, x3, #1
        cmp     x3, 6
        csel    x3, x3, xzr, lt         // Set x3 to zero if equal to 6

end_handle_space:
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
