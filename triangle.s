.ifndef TRIANGLE_S
TRIANGLE_S:

        .include "./constants.s"
        .include "./pixel.s"



/*
 * Params:
 *      x0: u64         <- x0 coord (game coordinates)
 *      x1: u64         <- y0 coord (game coordinates) (y0 != y1, y2)
 *      x2: u64         <- x1 coord (game coordinates) (x1 <= x2)
 *      x3: u64         <- y1 coord (game coordinates) (y1 == y2)
 *      x4: u64         <- x2 coord (game coordinates) (x1 <= x2)
 *      x5: u64         <- y2 coord (game coordinates) (y1 == y2)
 *      w6: u32         <- argb color
 *      x7: out* u32    <- framebuffer
 */
draw_flat_bottom_triangle:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]
        sub     sp, sp, 8       // Make space for bottom y coord (TODO: clean)


        lsl     x20, x0, 32     // x20 <- left line x   (Q32)
        lsl     x21, x0, 32     // x21 <- right line x  (Q32)

        sub     x9, x2, x0      // x9 <- x1 - x0
        lsl     x9, x9, 32      // x9 <- x1 - x0        (Q32)
        sub     x10, x3, x1     // x10 <- y1 - y0
        sdiv    x22, x9, x10    // x22 <- (x1 - x0) / (y1 - y0)         (Q32)

        sub     x9, x4, x0      // x9 <- x2 - x0
        lsl     x9, x9, 32      // x9 <- x2 - x0        (Q32)
        sub     x10, x5, x1     // x10 <- y2 - y0
        sdiv    x23, x9, x10    // x23 <- (x2 - x0) / (y2 - y0)         (Q32)


        mov     x19, x1         // x19 <- y scanline
        str     x3, [sp]        // [sp] <- bottom y coord (last scanline)
        mov     w26, w6         // w26 <- color
        mov     x27, x7         // x27 <- framebuffer

draw_flat_bottom_triangle__next_line:
        mov     x25, ROUNDING_CONSTANT
        add     x24, x20, x25   // x24 <- left line x coordinate (Q32)
        lsr     x24, x24, 32    // x24 <- scanline x coordinate (rounded).

        add     x25, x21, x25   // x25 <- right line x coordinate (Q32)
        lsr     x25, x25, 32    // x25 <- right line x coordinate (rounded)

draw_flat_bottom_triangle__next_pixel:
        mov     x0, x24         // x0 <- line's pixel x
        mov     x1, x19         // x1 <- line y
        mov     x2, x27         // x2 <- framebuffer
        mov     w3, w26         // w3 <- color
        bl      draw_argb_pixel_at


        add     x24, x24, 1     // Advance scanline x
        cmp     x24, x25        // Check if we finished scanline
        b.le    draw_flat_bottom_triangle__next_pixel
        /* We finished drawing scanline */

        sub     x20, x20, x22   // Move left line x by slope
        sub     x21, x21, x23   // Move right line x by slope
        sub     x19, x19, 1
        ldr     x9, [sp]        // x9 <- last scanline y coordinate
        cmp     x19, x9         // Check if we are at or before last line
        b.ge    draw_flat_bottom_triangle__next_line
        /* We finished drawing triangle */


        add     sp, sp, 8
        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



.endif
