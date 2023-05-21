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
	mov x20, x0 // Guarda la dirección base del framebuffer en x20
	//---------------- CODE HERE ------------------------------------

        mov     x5, 0                   // X5 -> index of bg_color
        ldr     x12, BG_COLORS          // X12 = BG_COLORS[0]

        mov x3, #320      // Player x coordinate 1 (bottom) <= x <= SCREEN_HEIGHT (top)
        mov x4, #240      // Player y coordinate 1 (right) <= x <= SCREEN_WIDTH (left)

	// movz x10, 0xC7, lsl 16
	// movk x10, 0x1585, lsl 00
        // ldr     x12, BG_COLOR
        ldr     x14, PLAYER_COLOR

	// Ejemplo de uso de gpios
	mov x9, GPIO_BASE

	// Atención: se utilizan registros w porque la documentación de broadcom
	// indica que los registros que estamos leyendo y escribiendo son de 32 bits

	// Setea gpios 0 - 9 como lectura
	str     wzr, [x9, GPIO_GPFSEL0]

draw_screen:
	mov     x2, SCREEN_HEIGH // Y Size
next_row:
	mov     x1, SCREEN_WIDTH // X Size
next_col:
        cmp     x1, x3
        b.ne    pxl_bg
        cmp     x2, x4
        b.ne    pxl_bg

pxl_player:
        stur    w14, [x0]
        b       cont
pxl_bg:
        stur    w12, [x0]       // Colorear el pixel N

cont:	add     x0, x0, BYTES_PER_PIXEL // Apuntar al siguiente pixel

	sub     x1, x1, 1       // Decrementar contador X
	cbnz    x1, next_col    // Si no terminó la fila, salto

	sub     x2, x2, 1       // Decrementar contador Y
	cbnz    x2, next_row    // Si no es la última fila, salto

        // Draw player pixels
        // mov     x8, BYTES_PER_PIXEL
        // mul     x6, x3, x8
        // mov     x7, SCREEN_WIDTH
        // mul     x7, x7, x8
        // mul     x7, x7, x4
        // add     x6, x6, x7
        // add     x6, x20, x6
        // stur    x13, [x6]       // Colorear pixel player


	// Lee el estado de los GPIO 0 - 31
	ldr w10, [x9, GPIO_GPLEV0]

	// And bit a bit mantiene el resultado del bit 2 en w10 (notar 0b... es binario)
	// al inmediato se lo refiere como "máscara" en este caso:
	// - Al hacer AND revela el estado del bit 2
	// - Al hacer OR "setea" el bit 2 en 1
	// - Al hacer AND con el complemento "limpia" el bit 2 (setea el bit 2 en 0)

check_space:
	and w11, w10, GPIO_SPACE
        cbz w11, check_w

        add x5, x5, #1
        cmp x5, 6
        b.lt skip_mod
        mov x5, 0
skip_mod:
        // Select new background color
        mov     x12, x5         // x12 = i
        lsl     x12, x12, 2     // x12 = i * 4
        ldr     x13, =BG_COLORS
        add     x12, x12, x13   // x12 = &BG_COLORS[0] + (i * 4) = &BG_COLORS[i]
        ldr     w12, [x12]      // x12 = BG_COLORS[i]

check_w:
	and w11, w10, GPIO_W
        cbz w11, check_s

        cmp x4, SCREEN_HEIGH            // Don't add if y == SCREEN_HEIGH (top)
        b.eq check_s
        add x4, x4, 1

check_s:
	and w11, w10, GPIO_S
        cbz w11, check_a

        cmp x4, 1                       // Don't subtract if y == 1 (bottom)
        b.eq check_a
        sub x4, x4, 1

check_a:
	and w11, w10, GPIO_A
        cbz w11, check_d

        cmp x3, SCREEN_WIDTH            // Don't add if x == SCREEN_WIDTH (left)
        b.eq check_d
        add x3, x3, 1

check_d:
	and w11, w10, GPIO_D
        cbz w11, redraw

        cmp x3, 1                       // Don't subtract if x == 1 (right)
        b.eq redraw
        sub x3, x3, 1

redraw:
        mov x0, x20
        b draw_screen

InfLoop:
	b InfLoop
