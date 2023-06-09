.ifndef LINE_S
LINE_S:

.include "./constants.s"

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


.endif
