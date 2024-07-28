.ifndef TETROMINO_GENERATOR_S
        .include "./constants.s"
        .include "./rand.s"

        .equ BAG_SIZE,                  NUM_TETROMINOS * 1

/* struct TetrominoGenerator */
        .equ TGEN_CURRENT_BAG,          0                               // u8
        .equ TGEN_BAG_REMAINING,        TGEN_CURRENT_BAG + 1            // u8
        .equ TGEN_BAG_A,                TGEN_BAG_REMAINING + 1          // u8[7] = u8[NUM_TETROMINOS]
        .equ TGEN_BAG_B,                TGEN_BAG_A + BAG_SIZE           // u8[7] = u8[NUM_TETROMINOS]

        .equ STRUCT_TETROMINO_GENERATOR_SIZE,   TGEN_BAG_B + BAG_SIZE



/*
 * Params:
 *      x0: out struct TetrominoGenerator*  <- tetromino_generator
 */
tetromino_generator_init:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0         // x19 <- struct TetrominoGenerator*

        strb    wzr, [x19, TGEN_CURRENT_BAG]    // tetromino_generator.current_bag = 0

        mov     w9, NUM_TETROMINOS
        strb    w9, [x19, TGEN_BAG_REMAINING]   // tetromino_generator.bag_remaining = NUM_TETROMINOS

        add     x0, x19, TGEN_BAG_A
        bl      recreate_chooser_bag

        add     x0, x19, TGEN_BAG_B
        bl      recreate_chooser_bag

        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: in/out struct TetrominoGenerator*  <- tetromino_generator
 * Returns:
 *      x0: u64         <- tetromino_id
 */
tetromino_generator_advance:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0         // x19 <- struct TetrominoGenerator*

        ldrb    w9, [x19, TGEN_BAG_REMAINING]           // w9 = tetromino_generator.remaining
        cmp     w9, 0                                   // tetromino_generator.remaining == 0 ?
        b.gt    tetromino_generator_advance__same_bag

        /* Bag out of values, we need to recreate it */
        ldrb    w9, [x19, TGEN_CURRENT_BAG]
        add     w10, w9, 1
        and     w10, w10, 1                     // w10 = (w9 + 1) % 2
        strb    w10, [x19, TGEN_CURRENT_BAG]    // tetromino_generator.current_bag = "other"

        mov     w10, BAG_SIZE
        mul     w9, w9, w10             // w9 <- offset in bytes to the previous bag, relative to the first bag (i.e. 0 or BAG_SIZE)
        add     w9, w9, TGEN_BAG_A      // w9 <- offest in bytes to the previous bag, relative to &tetromino_generator

        add     x0, x19, x9
        bl      recreate_chooser_bag

        mov     w9, NUM_TETROMINOS
        strb    w9, [x19, TGEN_BAG_REMAINING]   // tetromino_generator.bag_remaining = NUM_TETROMINOS

        tetromino_generator_advance__same_bag:

        /* Load last value and decrement remaining count */
        ldrb    w9, [x19, TGEN_BAG_REMAINING]   // w9 = tetromino_generator.remaining
        sub     w9, w9, 1                       // w9 <- index of last element in bag
        strb    w9, [x19, TGEN_BAG_REMAINING]   // tetromino_generator.remaining -= 1

        ldrb    w10, [x19, TGEN_CURRENT_BAG]    // w10 <- tetromino_generator.current_bag
        mov     w11, BAG_SIZE
        mul     w10, w10, w11                   // w10 <- offset in bytes to the current bag, relative to the first bag (i.e. 0 or BAG_SIZE)
        add     w10, w10, TGEN_BAG_A            // w10 <- offest in bytes to the current bag, relative to &tetromino_generator

        add     w9, w9, w10                     // w9 <- offset to start of array + index of last element
        add     x9, x19, x9                     // x9 <- pointer to last element of array
        ldrb    w0, [x9]                        // w0 = chooser_bag_state.values[LAST]

        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: out u32[NUM_TETROMINOS]     <- bag state
 */
recreate_chooser_bag:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        mov     x20, x0
        mov     x21, 0                  // i = 0
        recreate_chooser_bag__init_next_value:
                strb    w21, [x20]              // values[i] = i
                add     x20, x20, 1             // x20 = &values[i + 1] (move to next element)
                add     x21, x21, 1             // i += 1
                cmp     x21, NUM_TETROMINOS     // i < NUM_TETROMINOS ?
                b.lt    recreate_chooser_bag__init_next_value

        /* values == [0, 1, 2, 3, ..., NUM_TETROMINOS - 1] */

        mov     x20, x0                 // x20 <- pointer to the beginning of the array's segment that remains 'not randomized'
        mov     w21, NUM_TETROMINOS     // w21 <- amount of remaining (non randomized) tetrominos

        recreate_chooser_bag__randomize_next:
                /* Gen random number in range [0..rem_tetrominos) */
                mov     w0, 0
                mov     w1, w21
                bl      rand_gen_in_range
                /* x0 contains random index */

                // Swap a[0] with a[r]
                add     x9, x20, x0     // x9 = &a[r] = pointer to the randomly chosen element
                ldrb    w22, [x20]      // w22 = a[0]
                ldrb    w23, [x9]       // w23 = a[r]
                strb    w23, [x20]      // a[0] = a[r]
                strb    w22, [x9]       // a[r] = a[0]

                add     x20, x20, 1             // advance array pointer to the beginning of the next segment
                subs    w21, w21, 1             // decrement remaining tetrominos
                b.gt    recreate_chooser_bag__randomize_next    // loop only if more than 1 tetromino is not yet randomized

        /* values = [randomized] */

        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret


.endif
