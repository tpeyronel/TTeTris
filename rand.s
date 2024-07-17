.ifndef RAND_S
RAND_S:

        .include "./addresses.s"

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
 * Returns:
 *      x0: u64 (Q32)           <- random number in range [0.0, 1.0)
 */
rand_gen_fixedp:
        ldr     x0, =RNG_NUMBER_ADDRESS
        ldr     w0, [x0]              // w0 <- random number in range [0.0, 1.0)        (Q32)
        ret



/*
 * Returns:
 *      s0: f32                 <- random number in range [0.0, 1.0)
 */
rand_gen_f32:
        ldr     x9, =RNG_NUMBER_ADDRESS
        ldr     w9, [x9]                // w9 <- random number in range 0, ..., (2^32 - 1)     (i.e., [0.0, 1.0) in Q32)
        ucvtf   s0, w9, #32             // s0 <- random number in range [0.0, 1.0)
        ret



/*
 * Params:
 *      s0: f32                 <- min (inclusive)
 *      s1: f32                 <- max (exclusive)
 * Returns:
 *      s0: f32                 <- random number in range [0.0, 1.0)
 */
rand_gen_f32_in_range:
        fsub    s2, s1, s0              // s2 <- range

        ldr     x9, =RNG_NUMBER_ADDRESS
        ldr     w9, [x9]                // w9 <- random number in range 0, ..., (2^32 - 1)     (i.e., [0.0, 1.0) in Q32)
        ucvtf   s1, w9, #32             // s1 <- random number in range [0.0, 1.0)

        fmadd   s0, s1, s2, s0          // s0 <- random number in range [min, max)
        ret



.endif
