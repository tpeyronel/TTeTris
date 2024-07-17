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
        .equ PS_LAYER,                  PS_PARTICLE_TYPE + 8            // u64
        .equ PS_USER_DATA,              PS_LAYER + 8                    // size: MAX_STRUCT_PS_SIZE - 8

/* struct StarParticleState */
        .equ PSSTAR_TIMESTAMP,          PS_LAYER + 8                    // u32
        .equ PSSTAR_COLOR,              PSSTAR_TIMESTAMP + 4            // u32
        .equ PSSTAR_POS_X,              PSSTAR_COLOR + 4                // u64
        .equ PSSTAR_POS_Y,              PSSTAR_POS_X + 8                // u64
        .equ PSSTAR_SIZE,               PSSTAR_POS_Y + 8                // u64
        .equ PSSTAR_PHASE,              PSSTAR_SIZE + 8                 // u64 (Q32)
        .equ PSSTAR_FREQUENCY,          PSSTAR_PHASE + 8                // u64 (Q32)

/* struct SparkParticleState */
        .equ PSSPARK_TIMESTAMP,         PS_LAYER + 8                    // u32
        .equ PSSPARK_COLOR,             PSSPARK_TIMESTAMP + 4           // u32
        .equ PSSPARK_POS_X,             PSSPARK_COLOR + 4               // f32
        .equ PSSPARK_POS_Y,             PSSPARK_POS_X + 4               // f32
        .equ PSSPARK_DURATION,          PSSPARK_POS_Y + 4               // u64 <- duration in us
        .equ PSSPARK_VELOCITY_X,        PSSPARK_DURATION + 8            // f32
        .equ PSSPARK_VELOCITY_Y,        PSSPARK_VELOCITY_X + 4          // f32

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




        .equ SPARK_COLOR_COLD,          0xFFFFFFFF
        .equ SPARK_COLOR_WARM,          0xFFFFC18D



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
        mov     x9, 0
        str     x9, [x10, PS_LAYER]
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
 *      x0: in/out struct ParticleManager*      <- particle manager
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
 *      x1: u32                         <- layer to render
 *      x2: out u32*                    <- framebuffer
 */
particle_manager_render:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        ldr     x19, [x0, PM_PARTICLE_COUNT]    // x19 <- remaining particles
        add     x20, x0, PM_PARTICLE_ARRAY      // x20 <- pointer to current particle
        mov     x21, x2                         // x21 <- framebuffer
        ldr     x22, =PARTICLE_TYPES            // x22 <- pointer to global ParticleType array
        mov     x23, x1                         // x23 <- layer to render

particle_manager_render__next:
        cbz     x19, particle_manager_render__end       // Check if any particles remain to be drawn

        /* Skip rendering if layer is not correct */
        ldr     x9, [x20, PS_LAYER]
        cmp     x9, x23
        b.ne    particle_manager_render__skip

        ldr     x9, [x20, PS_PARTICLE_TYPE]
        lsl     x9, x9, STRUCT_PARTICLE_TYPE_SIZE_SHIFT
        add     x9, x22, x9             // x9 <- pointer to current particle type
        ldr     x9, [x9, PT_DRAW]       // x9 <- particle draw function

        mov     x0, x20         // x0 <- current ParticleState*
        mov     x1, x21         // x1 <- framebuffer
        blr     x9              // Draw particle

        particle_manager_render__skip:
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
 *      w1: u32                                 <- color
 *      x2: u64                                 <- duration
 * * * * * *
 *      s0: f32                                 <- x coordinate
 *      s1: f32                                 <- y coordinate
 *      s2: f32                                 <- x velocity
 *      s3: f32                                 <- y velocity
 *
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
        mov     x9, 2
        str     x9, [x10, PS_LAYER]
        str     w1, [x10, PSSPARK_COLOR]
        str     x2, [x10, PSSPARK_DURATION]
        str     s0, [x10, PSSPARK_POS_X]
        str     s1, [x10, PSSPARK_POS_Y]
        str     s2, [x10, PSSPARK_VELOCITY_X]
        str     s3, [x10, PSSPARK_VELOCITY_Y]

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

        mov     x19, x0         // x19 <- particle state

        ldr     s0, [x19, PSSPARK_POS_X]        // s0 <- coordinate x
        ldr     s1, [x19, PSSPARK_POS_Y]        // s1 <- coordinate y
        ldr     s2, [x19, PSSPARK_VELOCITY_X]   // s2 <- velocity x
        ldr     s3, [x19, PSSPARK_VELOCITY_Y]   // s3 <- velocity y

        ldr     s4, F32_TICK_TIME

        fmadd   s0, s2, s4, s0                  // s0 += delta x
        fmadd   s1, s3, s4, s1                  // s1 += delta y

        str     s0, [x19, PSSPARK_POS_X]
        str     s1, [x19, PSSPARK_POS_Y]

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
        stp     lr, x19, [sp, -16]!
        stp     x20, x21, [sp, -16]!
        stp     x22, x23, [sp, -16]!

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
        // TODO: use x9 again (or similar) to implement dimming of the spark (or maybe color warming)
        // mov     w19, 0
        // bfi     w19, w9, 16, 8
        // bfi     w19, w9, 8, 8
        // bfi     w19, w9, 0, 8
        // mov     x9, 0xFF
        // bfi     w19, w9, 24, 8


        ldr     s0, [x20, PSSPARK_POS_X]        // s0 <- x coordinate
        ldr     s1, [x20, PSSPARK_POS_Y]        // s1 <- y coordinate

        fcvtzs  x22, s0                         // x22 <- x coordinate
        fcvtzs  x23, s1                         // x23 <- y coordinate

        mov     x0, x22
        mov     x1, x23
        mov     x2, x21
        mov     w3, w19
        bl      draw_argb_pixel_at

        /* Set alpha of border pixels to 0.5 */
        mov     w9, 0x80
        bfi     w19, w9, 24, 8

        /* x + 1 */
        add     x0, x22, 1
        mov     x1, x23
        mov     x2, x21
        mov     w3, w19
        bl      draw_argb_pixel_at

        /* x - 1 */
        sub     x0, x22, 1
        mov     x1, x23
        mov     x2, x21
        mov     w3, w19
        bl      draw_argb_pixel_at

        /* y + 1 */
        mov     x0, x22
        add     x1, x23, 1
        mov     x2, x21
        mov     w3, w19
        bl      draw_argb_pixel_at

        /* y - 1 */
        mov     x0, x22
        sub     x1, x23, 1
        mov     x2, x21
        mov     w3, w19
        bl      draw_argb_pixel_at

        ldp     x22, x23, [sp], 16
        ldp     x20, x21, [sp], 16
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: u64                                 <- left x coordinate
 *      x1: u64                                 <- y coordinate
 *      x2: u64                                 <- cluster width
 *      x3: in/out struct ParticleManager*      <- particle manager
 */
create_spark_cluster:
        stp     lr, x19, [sp, -16]!
        stp     x20, x21, [sp, -16]!
        stp     x22, x23, [sp, -16]!
        stp     x24, x25, [sp, -16]!
        stp     x26, x27, [sp, -16]!
        stp     s19, s20, [sp, -8]!
        stp     s21, s22, [sp, -8]!
        stp     s23, s24, [sp, -8]!

        mov     x20, x0         // x20 <- left x coordinate
        mov     x21, x1         // x21 <- y coordinate
        mov     x26, x2         // x26 <- cluster width
        mov     x19, x3         // x19 <- particle manager

        scvtf   s19, x20        // s19 <- left x coordinate
        scvtf   s20, x26        // s20 <- ClusterWidth
        fmov    s21, 0.5
        fmul    s21, s20, s21   // s21 <- ClusterWidth / 2


        mov     x25, 64

create_spark_cluster__next:
        movi    d0, 0
        fmov    s1, s20
        bl      rand_gen_f32_in_range   // s0 <- [0.0, ClusterWidth)
        fadd    s22, s19, s0            // s22 <- spark x pos

        fsub    s23, s0, s21            // s23 <- [-ClusterWidth / 2, ClusterWidth / 2)
        bl      rand_gen_f32            // s0 <- [0.0, 1.0)
        fmul    s23, s0, s23            // s23 <- x velocity
        fmov    s9, 8
        fmul    s23, s23, s9            // s23 <- x velocity scaled

        bl      rand_gen_f32    // s0 <- [0.0, 1.0)
        fmov    s9, 0.5
        fsub    s24, s0, s9     // s0 <- [-0.5, 0.5)
        fmov    s9, 8
        fmul    s9, s9, s9
        fmul    s24, s24, s9    // s24 <- y velocity

        mov     w0, 0
        mov     w1, 256
        bl      rand_gen_in_range

        mov     w2, w0
        ldr     w0, =SPARK_COLOR_COLD
        ldr     w1, =SPARK_COLOR_WARM
        bl      lerp_colors
        mov     w1, w0

        mov     x0, x19
        ldr     x2, =(1000 * 500)
        fmov    s9, w9
        fmov    s0, s22
        scvtf   s1, x21
        fmov    s2, s23
        fmov    s3, s24
        bl      particle_manager_create_spark

        sub     x25, x25, 1
        cbnz    x25, create_spark_cluster__next


        ldp     s23, s24, [sp], 8
        ldp     s21, s22, [sp], 8
        ldp     s19, s20, [sp], 8
        ldp     x26, x27, [sp], 16
        ldp     x24, x25, [sp], 16
        ldp     x22, x23, [sp], 16
        ldp     x20, x21, [sp], 16
        ldp     lr, x19, [sp], 16
        ret



.endif
