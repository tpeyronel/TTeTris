.ifndef PIXEL_S
PIXEL_S:

        .include "./constants.s"


        .macro triple_lerp_comp, Rd, Ra, Rt, Rc1, Rc2, Rc3, Rw1, Rw2, Rw3, offset
        mov     \Ra, 0          // \Ra <- component accumulator      (Q32)

        ubfx    \Rt, \Rc1, \offset, 8   // \Rt = c1.?
        mul     \Rt, \Rt, \Rw1          // \Rt = c1.? * w1   (Q32)
        add     \Ra, \Ra, \Rt           // \Ra = c1.? * w1                              (Q32)

        ubfx    \Rt, \Rc2, \offset, 8   // \Rt = c2.?
        mul     \Rt, \Rt, \Rw2          // \Rt = c2.? * w2   (Q32)
        add     \Ra, \Ra, \Rt           // \Ra = c1.? * w1 + c2.? * w2                  (Q32)

        ubfx    \Rt, \Rc3, \offset, 8   // \Rt = c3.?
        mul     \Rt, \Rt, \Rw3          // \Rt = c3.? * w3   (Q32)
        add     \Ra, \Ra, \Rt           // \Ra = c1.? * w1 + c2.? * w2 + c3.? * w3      (Q32)

        lsr     \Ra, \Ra, 32            // \Ra = c1.? * w1 + c2.? * w2 + c3.? * w3
        bfi     \Rd, \Ra, \offset, 8
        .endm



/*
 * Params:
 *      w0: u32 (ARGB)          <- argb color
 *      x1: in/out u32*         <- pointer in which to write pixel
 */
draw_argb_pixel:
        stp     lr, x19, [sp, -16]!

        /* Store source color for loading into vector */
        str     w0, [sp, -4]!

        /* Load source color into V0 */
        ld1     { v0.b }[0], [sp], #1
        ld1     { v0.b }[4], [sp], #1
        ld1     { v0.b }[8], [sp], #1
        sub     sp, sp, 3

        /* Load dest color into V6 */
        ld1     { v6.b }[0], [x1], #1
        ld1     { v6.b }[4], [x1], #1
        ld1     { v6.b }[8], [x1], #1
        sub     x1, x1, 3

        /* Setup V1 for di */
        lsr     w11, w0, 24     // w11 = Fs = src.alpha
        str     w11, [sp]

        /* Fill V1 with src.alpha */
        ld1r    { v1.4s }, [sp]

        /* Fill V7 with 255 - src.alpha */
        mov     w12, 0xFF
        sub     w11, w12, w11   // w11 = Fd = 255 - src.alpha
        str     w11, [sp]
        ld1r    { v7.4s }, [sp]

        /* Setup V3 for dividing by 255 */
        mov     w19, 32897      // w19 (const) = 32897 (for dividing (compiler magic)))
        str     w19, [sp]
        ld1r    { v3.4s }, [sp]

        mul     v2.4s, v0.4s, v1.4s     // V2 = Fs * V0
        mul     v4.4s, v2.4s, v3.4s     // V4 = Magic * Fs * V0
        ushr    v5.4s, v4.4s, 23        // V5 = final contribution by source color

        mul     v8.4s, v6.4s, v7.4s     // V8 = Fd * V6
        mul     v9.4s, v8.4s, v3.4s     // V9 = Magic * Fd * V6
        ushr    v10.4s, v9.4s, 23       // V10 = final contribution by dest color

        add     v11.4s, v5.4s, v10.4s   // V11 = final color

        st1     { v0.b }[0], [x1], #1
        st1     { v0.b }[4], [x1], #1
        st1     { v0.b }[8], [x1], #1

        add     sp, sp, 4
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      w0: u32 (ARGB)          <- color A
 *      w1: u32 (ARGB)          <- color B
 *      w2: u32                 <- interpolation coefficient (0 <= w2 < 256)
 */
lerp_colors:
        stp     lr, x19, [sp, -16]!

        mov     x19, 0xFF       // const x19 = 255 (for dividing)


        mov     w11, w2         // w11 = Fs = src.alpha
        mov     w12, 0xFF
        sub     w12, w12, w11   // w12 = Fd = 255 - src.alpha

        mov     w14, 0x0        // w14 = result


        /* Blue */
        ubfx    w9, w0, 0, 8    // w9 = src.b
        mul     x9, x9, x11     // w9 = src.b * Fs

        ubfx    w10, w1, 0, 8  // w10 = dst.b
        mul     x10, x10, x12   // w10 = dst.b * Fd

        add     x9, x9, x10     // w9 = (src.b * Fs) + (dst.b * Fd)
        udiv    x9, x9, x19     // w9 = ((src.b * Fs) + (dst.b * Fd)) / 255

        lsl     w9, w9, 0       // Shift to position
        add     w14, w14, w9    // Add to result


        /* Green */
        ubfx    w9, w0, 8, 8    // w9 = src.g
        mul     x9, x9, x11     // w9 = src.g * Fs

        ubfx    w10, w1, 8, 8  // w10 = dst.g
        mul     x10, x10, x12   // w10 = dst.g * Fd

        add     x9, x9, x10     // w9 = (src.g * Fs) + (dst.g * Fd)
        udiv    x9, x9, x19     // w9 = ((src.g * Fs) + (dst.g * Fd)) / 255

        lsl     w9, w9, 8       // Shift to position
        add     w14, w14, w9    // Add to result


        /* Red */
        ubfx    w9, w0, 16, 8   // w9 = src.r
        mul     x9, x9, x11     // w9 = src.r * Fs

        ubfx    w10, w1, 16, 8 // w10 = dst.r
        mul     x10, x10, x12   // w10 = dst.r * Fd

        add     x9, x9, x10     // w9 = (src.r * Fs) + (dst.r * Fd)
        udiv    x9, x9, x19     // w9 = ((src.r * Fs) + (dst.r * Fd)) / 255

        lsl     w9, w9, 16      // Shift to position
        add     w14, w14, w9    // Add to result


        /* Alpha */
        ubfx    w9, w0, 24, 8   // w9 = src.a
        mul     x9, x9, x11     // w9 = src.a * Fs

        ubfx    w10, w1, 24, 8 // w10 = dst.a
        mul     x10, x10, x12   // w10 = dst.a * Fd

        add     x9, x9, x10     // w9 = (src.a * Fs) + (dst.a * Fd)
        udiv    x9, x9, x19     // w9 = ((src.a * Fs) + (dst.a * Fd)) / 255

        lsl     w9, w9, 24      // Shift to position
        add     w14, w14, w9    // Add to result

        mov     w0, w14

        ldp     lr, x19, [sp], 16
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
draw_argb_pixel_at:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, (SCREEN_HEIGH - 1)
        sub     x19, x19, x1

        mov     x20, SCREEN_WIDTH
        mul     x20, x20, x19                   // x20 = vertical offset
        add     x20, x20, x0                    // x20 = vertical offset + horizontal offset
        lsl     x20, x20, BYTES_PER_PIXEL_SHIFT // x20 = total offset
        add     x20, x2, x20                    // x20 = &framebuffer[y][x]


        /* Save x0, x1 */
        mov     x19, x0
        mov     x21, x1

        mov     w0, w3          // w0 = color
        mov     x1, x20         // x1 = pointer to pixel
        bl      draw_argb_pixel

        /* Restore x0, x1 */
        mov     x0, x19
        mov     x1, x21

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret




/*
 * Params:
 *      w0: u32         <- argb color 1
 *      w1: u32         <- argb color 2
 *      w2: u32         <- argb color 3
 *      x3: u64         <- weight 1     (Q32)
 *      x4: u64         <- weight 2     (Q32)
 *      x5: u64         <- weight 3     (Q32)
 * Returns:
 *      w0: u32         <- mixed color
 */
triple_color_lerp:
        stp     lr, x19, [sp, -16]!

        mov     x19, 0  // x19 <- result

        triple_lerp_comp x19, x10, x9, x0, x1, x2, x3, x4, x5, 0        // Blue
        triple_lerp_comp x19, x10, x9, x0, x1, x2, x3, x4, x5, 8        // Green
        triple_lerp_comp x19, x10, x9, x0, x1, x2, x3, x4, x5, 16       // Red
        triple_lerp_comp x19, x10, x9, x0, x1, x2, x3, x4, x5, 24       // Alpha

        mov     w0, w19

        ldp     lr, x19, [sp], 16
        ret


.endif
