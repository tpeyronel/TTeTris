.ifndef TETRIS_CELL_S
TETRIS_CELL_S:

        .include "./constants.s"
        .include "./rectangle.s"
        .include "./line.s"

        .equ TETRIS_CELL_SIZE,          21
        .equ TETRIS_CELL_BORDER_SIZE,   4



/*
 * TODO: coordinates are actually screen coordinates
 * Params:
 *      x0: u64                 <- bottom left x position (game coordinates)
 *      x1: u64                 <- bottom left y position (game coordinates)
 *      x2: in Tetromino*       <- tetromino
 *      x3: out u32*            <- framebuffer
 */
draw_tetris_cell:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        /* First, draw border trapezoids */

        /* Convert coordinates */
        mov     x9, SCREEN_HEIGH - 1
        sub     x1, x9, x1                      // x1 = bottom left y coordinate (screen coordinates)
        sub     x1, x1, TETRIS_CELL_SIZE - 1    // x1 = top left y coordinate (screen coordiantes)


        /* Initialize framebuffer pointers */
        mov     x24, SCREEN_WIDTH               // x24 = SCREEN_WIDTH
        mul     x24, x24, x1                    // x24 = SCREEN_WIDTH * y = vertical offset
        add     x24, x24, x0                    // x24 = (SCREEN_WIDTH * y) + x = vertical + horizontal offset
        lsl     x24, x24, BYTES_PER_PIXEL_SHIFT // x24 = total offset in bytes

        add     x24, x3, x24                    // x24 = top left of square
        mov     x9, 0xFF
        str     w9, [x24]

        mov     x9, TETRIS_CELL_SIZE - 1        // x9 = size - 1 = space between corners
        mov     x10, SCREEN_WIDTH
        mul     x10, x9, x10                    // x10 = space between corners * screen width = pixels between vertically aligned corners

        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT   // x9 = space in bytes between horizontal corners
        lsl     x10, x10, BYTES_PER_PIXEL_SHIFT // x10 = space in bytes between vertical corners

        add     x25, x24, x10                   // x25 = bottom left of square
        mov     x26, x24                        // x26 = top left of square
        add     x27, x24, x9                    // x27 = top right of square
        /* End initialize framebuffer pointers */

        // x24 = top trapezoid iterator
        // x25 = bottom trapezoid iterator
        // x26 = left trapezoid iterator
        // x27 = right trapezoid iterator

        mov     x10, SCREEN_WIDTH - TETRIS_CELL_SIZE    // x10 = how many bytes to move to pointer framebuffer to beginning of next row


        mov     x20, 0          // x iterator
        mov     x21, 0          // y iterator


        ldr     w22, [x2, TETROMINO_SPECULAR_COLOR]     // w22 = specular color
        ldr     w23, [x2, TETROMINO_AMBIENT_COLOR]      // w23 = ambient color

        mov     x15, TETRIS_CELL_SIZE           // x15 = current row size

draw_tetris_cell__next_row:
        cmp     x21, TETRIS_CELL_BORDER_SIZE
        b.ge    draw_tetris_cell__end_border

draw_tetris_cell__next_col:
        cmp     x20, x15                        // check if we are at the end of the row
        b.ge    draw_tetris_cell__end_border_row


        str     w22, [x24]
        str     w23, [x25]
        str     w22, [x26]
        str     w23, [x27]

        add     x24, x24, BYTES_PER_PIXEL
        add     x25, x25, BYTES_PER_PIXEL

        mov     x9, SCREEN_WIDTH
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT
        add     x26, x26, x9
        add     x27, x27, x9

        add     x20, x20, 1
        b       draw_tetris_cell__next_col


draw_tetris_cell__end_border_row:

        sub     x9, xzr, x15
        add     x9, x9, SCREEN_WIDTH    // Move pointer to beginning of next row (old size)
        add     x9, x9, 1               // Move pointer to beginning of next row (new size)
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT

        add     x24, x24, x9


        sub     x9, xzr, x15
        sub     x9, x9, SCREEN_WIDTH    // Move pointer to beginning of next row (old size)
        add     x9, x9, 1               // Move pointer to beginning of next row (new size)
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT

        add     x25, x25, x9


        mov     x9, SCREEN_WIDTH
        mul     x9, x9, x15             // Point to beginning of column
        sub     x9, xzr, x9             // Negate
        add     x9, x9, 1               // Point to beginning of next column (old size)
        add     x9, x9, SCREEN_WIDTH    // Point to beginning of next column (new size)
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT

        add     x26, x26, x9


        mov     x9, SCREEN_WIDTH
        mul     x9, x9, x15             // Point to beginning of column
        sub     x9, xzr, x9             // Negate
        sub     x9, x9, 1               // Point to beginning of next column (old size)
        add     x9, x9, SCREEN_WIDTH    // Point to beginning of next column (new size)
        lsl     x9, x9, BYTES_PER_PIXEL_SHIFT

        add     x27, x27, x9

        sub     x15, x15, 2
        mov     x20, 0
        add     x21, x21, 1
        b       draw_tetris_cell__next_row

draw_tetris_cell__end_border:

        mov     x20, x0         // x20 = bottom left x

        /* Reconvert coordinates */
        mov     x9, SCREEN_HEIGH - 1
        sub     x21, x9, x1                     // x21 = top left y (game coordinates)
        sub     x21, x21, TETRIS_CELL_SIZE - 1  // x21 = bottom left y (game coordinates)

        mov     x22, x2         // x22 = tetromino*
        mov     x23, x3         // x23 = framebuffer






        /* Now we draw inner rectangle */
        add     x0, x20, TETRIS_CELL_BORDER_SIZE        // x0 = inner rectangle bottom left x
        add     x1, x21, TETRIS_CELL_BORDER_SIZE        // x1 = inner rectangle bottom left y

        add     x2, x20, TETRIS_CELL_SIZE - 1
        sub     x2, x2, TETRIS_CELL_BORDER_SIZE         // x2 = inner rectangle top right x

        add     x3, x21, TETRIS_CELL_SIZE - 1
        sub     x3, x3, TETRIS_CELL_BORDER_SIZE         // x3 = inner rectangle top right y

        mov     x4, x23                                 // x4 = framebuffer
        ldr     w5, [x22, TETROMINO_DIFFUSE_COLOR]      // w5 = diffuse color

        bl      draw_filled_rectangle



        /* Draw bottom left diagonal line */
        mov     x0, x20
        mov     x1, x21
        add     x2, x0, TETRIS_CELL_BORDER_SIZE - 1
        add     x3, x1, TETRIS_CELL_BORDER_SIZE - 1
        mov     x4, x23                                 // x4 = framebuffer
        ldr     w5, [x22, TETROMINO_DIFFUSE_COLOR]      // w5 = diffuse color
        bl      draw_line

        /* Draw top right diagonal line */
        add     x0, x20, TETRIS_CELL_SIZE - 1
        add     x1, x21, TETRIS_CELL_SIZE - 1
        sub     x2, x0, TETRIS_CELL_BORDER_SIZE - 1
        sub     x3, x1, TETRIS_CELL_BORDER_SIZE - 1
        mov     x4, x23                                 // x4 = framebuffer
        ldr     w5, [x22, TETROMINO_DIFFUSE_COLOR]      // w5 = diffuse color
        bl      draw_line



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret








.endif
