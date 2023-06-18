.ifndef PARTICLE_S
PARTICLE_S:

        .include "./time.s"
        .include "./star.s"
        .include "./util.s"
        .include "./fixed_point.s"

        .equ MAX_PARTICLES,     256

/* struct ParticleState */
        .equ PS_PARTICLE_TYPE,  0                       // u64
        .equ PS_TIMESTAMP,      PS_PARTICLE_TYPE + 8    // u32
        .equ PS_COLOR,          PS_TIMESTAMP + 4        // u32
        .equ PS_POS_X,          PS_COLOR + 4            // u64
        .equ PS_POS_Y,          PS_POS_X + 8            // u64
        .equ PS_SIZE,           PS_POS_Y + 8            // u64
        .equ PS_PHASE,          PS_SIZE + 8             // u64 (Q32)
        .equ PS_FREQUENCY,      PS_PHASE + 8            // u64 (Q32)

        .equ STRUCT_PS_SIZE,    PS_FREQUENCY + 8

/* struct ParticleManager */
        .equ PM_PARTICLE_ARRAY,         0                                                       // struct ParticleState[MAX_PARTICLES]
        .equ PM_PARTICLE_COUNT,         PM_PARTICLE_ARRAY + (STRUCT_PS_SIZE * MAX_PARTICLES)    // u64 in [0..MAX_PARTICLES]

        .equ STRUCT_PM_SIZE,            PM_PARTICLE_COUNT + 8


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
        mov     x10, STRUCT_PS_SIZE
        mul     x10, x9, x10                    // x10 <- offset in bytes to new particle from beginning of array
        add     x10, x10, PM_PARTICLE_ARRAY     // x10 <- offset in bytes to new particle from beginning of struct
        add     x10, x0, x10                    // x10 <- &particles[particle_count]

        // Increment particle count
        add     x9, x9, 1
        str     x9, [x0, PM_PARTICLE_COUNT]

        mov     x9, PARTICLE_TYPE_STAR
        str     x9, [x10, PS_PARTICLE_TYPE]
        str     x1, [x10, PS_POS_X]
        str     x2, [x10, PS_POS_Y]
        str     x3, [x10, PS_SIZE]
        str     w4, [x10, PS_COLOR]
        str     x5, [x10, PS_PHASE]
        str     x6, [x10, PS_FREQUENCY]

        bl      get_time
        str     w0, [x10, PS_TIMESTAMP]


particle_manager_create_star__end:
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: out struct ParticleState*   <- dest
 *      x1: in struct ParticleState*    <- src
 */
particle_state_copy:
        ldr     x9, [x1, PS_PARTICLE_TYPE]
        ldr     w10, [x1, PS_TIMESTAMP]
        ldr     w11, [x1, PS_COLOR]
        ldr     x12, [x1, PS_POS_X]
        ldr     x13, [x1, PS_POS_Y]
        ldr     x14, [x1, PS_SIZE]
        ldr     x15, [x1, PS_PHASE]
        ldr     x8, [x1, PS_FREQUENCY]

        str     x9, [x0, PS_PARTICLE_TYPE]
        str     w10, [x0, PS_TIMESTAMP]
        str     w11, [x0, PS_COLOR]
        str     x12, [x0, PS_POS_X]
        str     x13, [x0, PS_POS_Y]
        str     x14, [x0, PS_SIZE]
        str     x15, [x0, PS_PHASE]
        str     x8, [x0, PS_FREQUENCY]

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

        mov     x10, STRUCT_PS_SIZE
        mul     x10, x9, x10                    // x10 <- offset in bytes to last particle state
        add     x10, x10, PM_PARTICLE_ARRAY     // x10 <- offset in bytes to last particle state from beginning of particle manager
        add     x10, x21, x10                   // x10 <- pointer to last particle state (may be equal to x20)

        mov     x0, x20         // x0 <- current ParticleState*
        mov     x1, x10         // x1 <- last ParticleState*
        bl      particle_state_copy     // Copy ParticleState* of last particle into current slot

        b       particle_manager_update__next

particle_manager_update__still_alive:
        add     x20, x20, STRUCT_PS_SIZE        // Advance pointer to next particle
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
        add     x20, x20, STRUCT_PS_SIZE        // Advance pointer to next particle
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
        ldr     x2, [x20, PS_FREQUENCY] // x2 <- frequency
        ldr     x3, [x20, PS_PHASE]     // x3 <- phase
        bl      sine_wave_advanced

        q32_to_int      x9, x0, x9      // x9 <- delta size


        ldr     x0, [x20, PS_POS_X]
        ldr     x1, [x20, PS_POS_Y]
        ldr     x2, [x20, PS_SIZE]
        add     x2, x2, x9
        ldr     w3, [x20, PS_COLOR]
        mov     x4, x21
        bl      draw_four_point_star

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret






.endif
