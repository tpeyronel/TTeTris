	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32
	.equ BYTES_PER_PIXEL, 4

	.equ GPIO_BASE,    0x3f200000
	.equ GPIO_GPFSEL0, 0x00
	.equ GPIO_GPLEV0,  0x34
        .equ GPIO_W,            0b000010        // (GPIO_1)
        .equ GPIO_A,            0b000100        // (GPIO_2)
        .equ GPIO_S,            0b001000        // (GPIO_3)
        .equ GPIO_D,            0b010000        // (GPIO_4)
        .equ GPIO_SPACE,        0b100000        // (GPIO_5)

        BG_COLORS: .word 0x00FF0000, 0x000FF000, 0x0000FF00, 0x00000FF0, 0x000000FF, 0x00F0000F
        BG_COLOR: .dword 0xFFFFFFFF
        PLAYER_COLOR: .dword 0xFFFFFFFF

	.globl main

main:
	mov     x28, x0         // Save framebuffer address to x28

        mov     x0, #320                // Player x coordinate        (bottom) 1 <= x <= SCREEN_HEIGHT (top)
        mov     x1, #240                // Player y coordinate         (right) 1 <= x <= SCREEN_WIDTH (left)
        mov     x2, 0                   // bg color index | default 0
        ldr     w3, BG_COLORS           // bg color | default BG_COLORS[0]
        ldr     w4, PLAYER_COLOR        // player color | default PLAYER_COLOR

	// Ejemplo de uso de gpios
	mov     x9, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str     wzr, [x9, GPIO_GPFSEL0]

draw_screen:
        mov     x19, x28                // Set x19 to beginning of framebuffer
	mov     x21, SCREEN_HEIGH       // Set x21 to remaining rows
next_row:
	mov     x20, SCREEN_WIDTH       // Set x20 to remaining columns
next_col:
        cmp     x20, x0                 // Check if we are in same column as player
        b.ne    pxl_bg
        cmp     x21, x1                 // Check if we are in same row as player
        b.ne    pxl_bg

pxl_player:
        stur    w4, [x19]              // Fill pixel with player color
        b       cont

pxl_bg:
        stur    w3, [x19]               // Fill pixel with bg color

cont:	add     x19, x19, BYTES_PER_PIXEL // Advance to next framebuffer pixel

	sub     x20, x20, 1             // Decrement remaining columns
	cbnz    x20, next_col           // If not at end of row, draw next column

	sub     x21, x21, 1             // Decrement remaining rows
	cbnz    x21, next_row           // If not at last row, draw next row

	// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
	// al inmediato se lo refiere como "máscara" en este caso:
	// - Al hacer AND revela el estado del bit 2
	// - Al hacer OR "setea" el bit 2 en 1
	// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)

        bl      handle_input
        bl      sel_bg_color

redraw:
        b draw_screen

InfLoop:
	b InfLoop


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
 *      x2: background color index
 *      x3: -
 * Returns:
 *      x2: unmodified background color index
 *      w3: background color
 */
sel_bg_color:
        stp     lr, x19, [sp, -16]!

        mov     x3, x2          // x3 = i
        lsl     x3, x3, 2       // x3 = i * 4
        ldr     x19, =BG_COLORS
        add     x3, x19, x3     // x3 = &BG_COLORS[0] + (i * 4) = &BG_COLORS[i]
        ldr     w3, [x3]        // w3 = BG_COLORS[i]

        ldp     lr, x19, [sp], 16
        ret
