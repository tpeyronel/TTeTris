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
	// x0 contiene la direccion base del framebuffer
	mov     x28, x0 // Guarda la dirección base del framebuffer en x28
	//---------------- CODE HERE ------------------------------------

        mov     x0, #320        // Player x coordinate        1 (bottom) <= x <= SCREEN_HEIGHT (top)
        mov     x1, #240        // Player y coordinate        1 (right) <= x <= SCREEN_WIDTH (left)

        mov     x2, 0           // bg color index | default 0
        ldr     w3, BG_COLORS   // bg color | default BG_COLORS[0]

        ldr     x14, PLAYER_COLOR

	// Ejemplo de uso de gpios
	mov     x9, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str     wzr, [x9, GPIO_GPFSEL0]

draw_screen:
        mov     x5, x28         // X5 = &framebuffer[0]
	mov     x20, SCREEN_HEIGH // Y Size
next_row:
	mov     x19, SCREEN_WIDTH // X Size
next_col:
        cmp     x19, x0
        b.ne    pxl_bg
        cmp     x20, x1
        b.ne    pxl_bg

pxl_player:
        stur    w14, [x5]               // Fill pixel with player color
        b       cont
pxl_bg:
        stur    w3, [x5]                // Fill pixel with bg color

cont:	add     x5, x5, BYTES_PER_PIXEL // Advance to next pixel

	sub     x19, x19, 1             // Decrementar contador X
	cbnz    x19, next_col           // Si no terminó la fila, salto

	sub     x20, x20, 1             // Decrementar contador Y
	cbnz    x20, next_row           // Si no es la última fila, salto

        // Draw player pixels
        // mov     x8, BYTES_PER_PIXEL
        // mul     x6, x3, x8
        // mov     x7, SCREEN_WIDTH
        // mul     x7, x7, x8
        // mul     x7, x7, x4
        // add     x6, x6, x7
        // add     x6, x20, x6
        // stur    x13, [x6]       // Colorear pixel player


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

        mov     x3, x2          // Use x3 as bg color index

	mov     x19, GPIO_BASE
	ldr     w2, [x19, GPIO_GPLEV0]

        bl      handle_w
        bl      handle_a
        bl      handle_s
        bl      handle_d
        bl      handle_space

        mov     x2, x3

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
        sub     sp, sp, 16
        str     lr, [sp]
        str     x19, [sp, 8]

	and     x19, x2, GPIO_W
        cbz     x19, end_handle_w

        cmp     x1, SCREEN_HEIGH        // Check if player is at the top
        b.eq    end_handle_w

        add     x1, x1, 1               // Move player one position up

end_handle_w:
        ldr     x19, [sp, 8]
        ldr     lr, [sp]
        add     sp, sp, 16
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

        cmp     x1, 1                   // Check if player is at the bottom
        b.eq    end_handle_s

        sub     x1, x1, 1               // Move player one position up

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
