.ifndef PARTICLE_S
PARTICLE_S:

        .include "./time.s"
        .include "./star.s"
        .include "./util.s"
        .include "./fixed_point.s"
        .include "./line.s"
        .include "./rand.s"
        .include "./tetris_cell.s"

        .equ MAX_PARTICLES,     256

        .equ MAX_STRUCT_PS_SIZE,        8 * 16  // Must be multiple of 32 to work with particle_state_copy

/* struct ParticleState */
        .equ PS_PARTICLE_TYPE,          0                               // u64
        .equ PS_USER_DATA,              PS_PARTICLE_TYPE + 8            // size: MAX_STRUCT_PS_SIZE - 8

/* struct StarParticleState */
        .equ PSSTAR_TIMESTAMP,          PS_PARTICLE_TYPE + 8            // u32
        .equ PSSTAR_COLOR,              PSSTAR_TIMESTAMP + 4            // u32
        .equ PSSTAR_POS_X,              PSSTAR_COLOR + 4                // u64
        .equ PSSTAR_POS_Y,              PSSTAR_POS_X + 8                // u64
        .equ PSSTAR_SIZE,               PSSTAR_POS_Y + 8                // u64
        .equ PSSTAR_PHASE,              PSSTAR_SIZE + 8                 // u64 (Q32)
        .equ PSSTAR_FREQUENCY,          PSSTAR_PHASE + 8                // u64 (Q32)

/* struct SparkParticleState */
        .equ PSSPARK_TIMESTAMP,         PS_PARTICLE_TYPE + 8            // u32
        .equ PSSPARK_COLOR,             PSSPARK_TIMESTAMP + 4           // u32
        .equ PSSPARK_POS_X,             PSSPARK_COLOR + 4               // u64
        .equ PSSPARK_POS_Y,             PSSPARK_POS_X + 8               // u64
        .equ PSSPARK_DURATION,          PSSPARK_POS_Y + 8               // u64 <- duration in us
        .equ PSSPARK_VELOCITY_X,        PSSPARK_DURATION + 8            // u64 (Q32)
        .equ PSSPARK_VELOCITY_Y,        PSSPARK_VELOCITY_X + 8          // u64 (Q32)

/* struct ParticleManager */
        .equ PM_PARTICLE_COUNT,         0                               // u64 in [0..MAX_PARTICLES]
        .equ PM_PARTICLE_ARRAY,         PM_PARTICLE_COUNT + 8           // struct ParticleState[MAX_PARTICLES]

        .equ STRUCT_PM_SIZE,            PM_PARTICLE_ARRAY + (MAX_STRUCT_PS_SIZE * MAX_PARTICLES)


/* struct ParticleType */
        .equ PT_UPDATE,         0               // u64/usize: (in/out struct ParticleState*) -> bool
        .equ PT_DRAW,           PT_UPDATE + 8   // u64/usize: (in struct ParticleState*, framebuffer: in/out u32*) -> void

        .equ STRUCT_PARTICLE_TYPE_SIZE,         PT_DRAW + 8
        .equ STRUCT_PARTICLE_TYPE_SIZE_SHIFT,   4

/* struct ParticleType[] */
PARTICLE_TYPES:
/* Particle Star */
        .equ PARTICLE_TYPE_STAR,        0
        .dword particle_star_update
        .dword particle_star_draw
/* Particle Spark */
        .equ PARTICLE_TYPE_SPARK,        1
        .dword particle_spark_update
        .dword particle_spark_draw







/*
 * Params:
 *      x0: out struct ParticleManager*
 */
particle_manager_init:
        stp     lr, x19, [sp, -16]!

        str     xzr, [x0, PM_PARTICLE_COUNT]

        ldp     lr, x19, [sp], 16
        ret





/*
 * Params:
 *      x0: in/out struct ParticleManager*
 *      x1: u64                                 <- x coordinate
 *      x2: u64                                 <- y coordinate
 *      x3: u64                                 <- size
 *      w4: u32                                 <- color
 *      x5: u64                                 <- phase (Q32)
 *      x6: u64                                 <- frequency (Q32)
 */
particle_manager_create_star:
        stp     lr, x19, [sp, -16]!

        ldr     x9, [x0, PM_PARTICLE_COUNT]
        cmp     x9, MAX_PARTICLES
        b.ge    particle_manager_create_star__end

        // Calculate offset in bytes to new ParticleState
        mov     x10, MAX_STRUCT_PS_SIZE
        mul     x10, x9, x10                    // x10 <- offset in bytes to new particle from beginning of array
        add     x10, x10, PM_PARTICLE_ARRAY     // x10 <- offset in bytes to new particle from beginning of struct
        add     x10, x0, x10                    // x10 <- &particles[particle_count]

        // Increment particle count
        add     x9, x9, 1
        str     x9, [x0, PM_PARTICLE_COUNT]

        mov     x9, PARTICLE_TYPE_STAR
        str     x9, [x10, PS_PARTICLE_TYPE]
        str     x1, [x10, PSSTAR_POS_X]
        str     x2, [x10, PSSTAR_POS_Y]
        str     x3, [x10, PSSTAR_SIZE]
        str     w4, [x10, PSSTAR_COLOR]
        str     x5, [x10, PSSTAR_PHASE]
        str     x6, [x10, PSSTAR_FREQUENCY]

        bl      get_time
        str     w0, [x10, PSSTAR_TIMESTAMP]


particle_manager_create_star__end:
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: out struct ParticleState*   <- dest
 *      x1: in struct ParticleState*    <- src
 */
particle_state_copy:
        mov     x9, MAX_STRUCT_PS_SIZE

particle_state_copy__next_block:
        ldp     x10, x11, [x1]
        ldp     x12, x13, [x1, 16]
        stp     x10, x11, [x0]
        stp     x12, x13, [x0, 16]

        add     x0, x0, 32
        add     x1, x1, 32
        sub     x9, x9, 32
        cbnz    x9, particle_state_copy__next_block

        ret



/*
 * Params:
 *      x0: in/out struct ParticleManager*  <- particle manager
 */
particle_manager_update:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        ldr     x19, [x0, PM_PARTICLE_COUNT]    // x19 <- remaining particles
        add     x20, x0, PM_PARTICLE_ARRAY      // x20 <- pointer to current particle
        mov     x21, x0                         // x21 <- particle manager
        ldr     x22, =PARTICLE_TYPES            // x22 <- pointer to global ParticleType array

particle_manager_update__next:
        cbz     x19, particle_manager_update__end       // Check if any particles remain to be updated
        sub     x19, x19, 1     // Decrement remaining particles

        ldr     x9, [x20, PS_PARTICLE_TYPE]
        lsl     x9, x9, STRUCT_PARTICLE_TYPE_SIZE_SHIFT
        add     x9, x22, x9             // x9 <- pointer to current particle type
        ldr     x9, [x9, PT_UPDATE]     // x9 <- particle update function

        mov     x0, x20         // x0 <- current ParticleState*
        blr     x9              // Update particle
        cbnz    x0, particle_manager_update__still_alive

        /* Particle is dead, remove it by inserting last particle in this slot */
        ldr     x9, [x21, PM_PARTICLE_COUNT]    // x9 should not be 0   (0 < x19 (+ 1) <= x9)
        sub     x9, x9, 1                       // x9 <- index of last particle state
        str     x9, [x21, PM_PARTICLE_COUNT]    // Decrement particle count

        mov     x10, MAX_STRUCT_PS_SIZE
        mul     x10, x9, x10                    // x10 <- offset in bytes to last particle state
        add     x10, x10, PM_PARTICLE_ARRAY     // x10 <- offset in bytes to last particle state from beginning of particle manager
        add     x10, x21, x10                   // x10 <- pointer to last particle state (may be equal to x20)

        mov     x0, x20         // x0 <- current ParticleState*
        mov     x1, x10         // x1 <- last ParticleState*
        bl      particle_state_copy     // Copy ParticleState* of last particle into current slot

        b       particle_manager_update__next

particle_manager_update__still_alive:
        add     x20, x20, MAX_STRUCT_PS_SIZE    // Advance pointer to next particle
        b       particle_manager_update__next


particle_manager_update__end:
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: in struct ParticleManager*  <- particle manager
 *      x1: out u32*                    <- framebuffer
 */
particle_manager_render:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        ldr     x19, [x0, PM_PARTICLE_COUNT]    // x19 <- remaining particles
        add     x20, x0, PM_PARTICLE_ARRAY      // x20 <- pointer to current particle
        mov     x21, x1                         // x21 <- framebuffer
        ldr     x22, =PARTICLE_TYPES            // x22 <- pointer to global ParticleType array

particle_manager_render__next:
        cbz     x19, particle_manager_render__end       // Check if any particles remain to be drawn

        ldr     x9, [x20, PS_PARTICLE_TYPE]
        lsl     x9, x9, STRUCT_PARTICLE_TYPE_SIZE_SHIFT
        add     x9, x22, x9             // x9 <- pointer to current particle type
        ldr     x9, [x9, PT_DRAW]       // x9 <- particle draw function

        mov     x0, x20         // x0 <- current ParticleState*
        mov     x1, x21         // x1 <- framebuffer
        blr     x9              // Draw particle

        sub     x19, x19, 1                     // Decrement remaining particles
        add     x20, x20, MAX_STRUCT_PS_SIZE    // Advance pointer to next particle
        b       particle_manager_render__next


particle_manager_render__end:
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: in/out struct ParticleState*        <- particle state
 * Returns:
 *      x0: bool                                <- is alive
 */
particle_star_update:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x0, 1

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: in struct ParticleState*    <- particle state
 *      x1: out u32*                    <- framebuffer
 */
particle_star_draw:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x20, x0         // x20 <- particle state
        mov     x21, x1         // x21 <- framebuffer

        bl      get_time
        lsl     x0, x0, 32              // x0 <- time in us             (Q32)
        ldr     x9, =US_PER_SECOND
        udiv    x0, x0, x9              // x0 <- time in seconds        (Q32)

        orr     x1, xzr, 4 << 32        // x1 <- amplitude
        ldr     x2, [x20, PSSTAR_FREQUENCY] // x2 <- frequency
        ldr     x3, [x20, PSSTAR_PHASE]     // x3 <- phase
        bl      sine_wave_advanced

        q32_to_int      x9, x0, x9      // x9 <- delta size


        ldr     x0, [x20, PSSTAR_POS_X]
        ldr     x1, [x20, PSSTAR_POS_Y]
        ldr     x2, [x20, PSSTAR_SIZE]
        add     x2, x2, x9
        ldr     w3, [x20, PSSTAR_COLOR]
        mov     x4, x21
        bl      draw_four_point_star

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: in/out struct ParticleManager*
 *      x1: u64                                 <- x coordinate
 *      x2: u64                                 <- y coordinate
 *      w3: u32                                 <- color
 *      x4: u64                                 <- duration
 *      x5: u64                                 <- velocity x (Q32)
 *      x6: u64                                 <- velocity y (Q32)
 */
particle_manager_create_spark:
        stp     lr, x19, [sp, -16]!
        /* TODO: implement particle_manager_push */

        ldr     x9, [x0, PM_PARTICLE_COUNT]
        cmp     x9, MAX_PARTICLES
        b.ge    particle_manager_create_spark__end
        /* x9 <= MAX_PARTICLES - 1 */
        // Calculate offset in bytes to new ParticleState
        mov     x10, MAX_STRUCT_PS_SIZE
        mul     x10, x9, x10                    // x10 <- offset in bytes to new particle from beginning of array
        add     x10, x10, PM_PARTICLE_ARRAY     // x10 <- offset in bytes to new particle from beginning of struct
        add     x10, x0, x10                    // x10 <- &particles[particle_count]

        // Increment particle count
        add     x9, x9, 1
        str     x9, [x0, PM_PARTICLE_COUNT]

        mov     x9, PARTICLE_TYPE_SPARK
        str     x9, [x10, PS_PARTICLE_TYPE]
        str     x1, [x10, PSSPARK_POS_X]
        str     x2, [x10, PSSPARK_POS_Y]
        str     w3, [x10, PSSPARK_COLOR]
        str     x4, [x10, PSSPARK_DURATION]
        str     x5, [x10, PSSPARK_VELOCITY_X]
        str     x6, [x10, PSSPARK_VELOCITY_Y]

        bl      get_time
        str     w0, [x10, PSSPARK_TIMESTAMP]


particle_manager_create_spark__end:
        ldp     lr, x19, [sp], 16
        ret




/*
 * Params:
 *      x0: in/out struct ParticleState*        <- particle state
 * Returns:
 *      x0: bool                                <- is alive
 */
particle_spark_update:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, x0

        ldr     w0, [x19, PSSPARK_TIMESTAMP]
        bl      get_elapsed_time
        ldr     x9, [x19, PSSPARK_DURATION]
        cmp     x0, x9
        cset    x0, lt

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: in struct ParticleState*    <- particle state
 *      x1: out u32*                    <- framebuffer
 */
particle_spark_draw:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x20, x0         // x20 <- particle state
        mov     x21, x1         // x21 <- framebuffer

        ldr     w0, [x20, PSSPARK_TIMESTAMP]
        bl      get_elapsed_time
        lsl     x0, x0, 32              // x0 <- elapsed time   (Q32)
        ldr     x9, [x20, PSSPARK_DURATION]
        udiv    x9, x0, x9              // x9 <- stage          (Q32)
        mov     x10, 1 << 32
        sub     x0, x10, x9             // x0 <- 1 - stage
        lsl     x0, x0, 1               // x0 <- 2 * (1 - stage)
        bl      smooth_step             // x0 <- alpha multiplier       (Q32)
        mov     x9, 0xFF
        mul     x9, x0, x9              // x9 <- alpha                  (Q32)
        lsr     x9, x9, 32              // x9 <- alpha
        ldr     w19, [x20, PSSPARK_COLOR]
        mov     w19, 0
        bfi     w19, w9, 16, 8
        bfi     w19, w9, 8, 8
        bfi     w19, w9, 0, 8
        mov     x9, 0xFF
        bfi     w19, w9, 24, 8




        orr     x1, xzr, 4 << 32        // x1 <- amplitude
        ldr     x2, [x20, PSSTAR_FREQUENCY] // x2 <- frequency
        ldr     x3, [x20, PSSTAR_PHASE]     // x3 <- phase
        bl      sine_wave_advanced


        ldr     w0, [x20, PSSPARK_TIMESTAMP]
        bl      get_elapsed_time
        lsl     x0, x0, 16              // x0 <- elapsed time in us     (Q16)
        ldr     x9, =US_PER_SECOND
        udiv    x0, x0, x9              // x0 <- time in seconds        (Q16)

        ldr     x9, [x20, PSSPARK_VELOCITY_X]         // x9 <- velocity x      (Q32)
        ldr     x10, [x20, PSSPARK_VELOCITY_Y]        // x10 <- velocity y     (Q32)
        asr     x9, x9, 16                      // x9 <- velocity x      (Q16)
        asr     x10, x10, 16                    // x10 <- velocity y     (Q16)

        mul     x2, x9, x0      // x2 <- delta x       (Q32)
        mul     x3, x10, x0     // x3 <- delta y       (Q32)
        q32_to_int x2, x2, x9   // x2 <- delta x
        q32_to_int x3, x3, x9   // x3 <- delta y

        ldr     x0, [x20, PSSPARK_POS_X]
        ldr     x1, [x20, PSSPARK_POS_Y]
        add     x0, x0, x2      // x2 <- end x coordinate
        add     x1, x1, x3      // x3 <- end y coordinate

        mov     x2, x21
        mov     w3, w19
        bl      draw_argb_pixel_at

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: u64                                 <- left x coordinate
 *      x1: u64                                 <- y coordinate
 *      x2: in/out struct ParticleManager*      <- particle manager
 */
create_spark_cluster:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov     x20, x0
        mov     x21, x1
        mov     x19, x2

        mov     x25, 64

create_spark_cluster__next:
        mov     x0, 0
        mov     x1, TETRIS_CELL_SIZE
        bl      rand_gen_in_range
        add     x22, x20, x0    // x22 <- spark x pos

        sub     x9, x0, (TETRIS_CELL_SIZE / 2)
        bl      rand_gen_fixedp // x0 <- [0.0, 1.0)
        mul     x23, x0, x9     // x23 <- velocity x
        mov     x9, 15
        mul     x23, x23, x9

        bl      rand_gen_fixedp
        mov     x9, 1 << 31
        sub     x0, x0, x9      // x0 <- [-0.5, 0.5)
        mov     x9, 150
        mul     x24, x0, x9     // x24 <- [-5.0, 5.0) <- velocity y

        mov     x0, x19
        mov     x1, x22
        mov     x2, x21
        ldr     w3, =0xFFFFFF
        ldr     x4, =(1000 * 1000)
        mov     x5, x23
        mov     x6, x24
        bl      particle_manager_create_spark

        sub     x25, x25, 1
        cbnz    x25, create_spark_cluster__next


        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret



.endif
