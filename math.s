.ifndef MATH_S
MATH_S:

/* struct Vec4 */
        .equ VEC4_X,        0       // f32
        .equ VEC4_Y,        4       // f32
        .equ VEC4_Z,        8       // f32
        .equ VEC4_W,        12      // f32

        .equ STRUCT_VEC4_SIZE,  16

/* struct Mat4 */
        .equ MAT4_COL0,     0       // Vec4
        .equ MAT4_COL1,     16      // Vec4
        .equ MAT4_COL2,     32      // Vec4
        .equ MAT4_COL3,     48      // Vec4

        .equ STRUCT_MAT4_SIZE,  64

F32_PI: .float          3.1415926535897932384626433832795
F32_TAU: .float         6.2831853071795864769252867665590
F32_FRAC_1_TAU: .float  0.1591549430918953357688837633725
F32_FRAC_TAU_2: .float  3.1415926535897932384626433832795
F32_FRAC_TAU_3: .float  2.0943951023931954923084289221863
F32_FRAC_TAU_4: .float  1.5707963267948966192313216916398
F32_FRAC_TAU_6: .float  1.0471975511965977461542144610932
F32_FRAC_TAU_8: .float  0.7853981633974483096156608458198
F32_FRAC_TAU_10: .float 0.6283185307179586476925286766559
F32_FRAC_TAU_12: .float 0.5235987755982988730771072305465
F32_FRAC_TAU_15: .float 0.4188790204786390984616857844372
F32_FRAC_TAU_16: .float 0.3926990816987241548078304229099
F32_0_225: .float  0.225



/*
 * Params:
 *      x0: out Vec4*
 * * * * *
 *      s0: f32         <- x
 *      s1: f32         <- y
 *      s2: f32         <- z
 *      s3: f32         <- w
 */
vec4_init:
    str     s0, [x0, VEC4_X]
    str     s1, [x0, VEC4_Y]
    str     s2, [x0, VEC4_Z]
    str     s3, [x0, VEC4_W]
    ret



/*
 * Params:
 *      x0: out Vec4*
 * * * * *
 *      s0: f32         <- x
 *      s1: f32         <- y
 *      s2: f32         <- z
 */
vec4_new_position:
    str     s0, [x0, VEC4_X]
    str     s1, [x0, VEC4_Y]
    str     s2, [x0, VEC4_Z]
    fmov    s0, 1.0
    str     s0, [x0, VEC4_W]
    ret



/*
 * Params:
 *      x0: in/out Vec4*
 *      x1: in Mat4*
 */
vec4_mul_mat4_inplace:
    /* Load vector column into v0 */
    ld1     { v0.4s }, [x0]

    /* Load all matrix columns into v1 - v4 */
    ld1     { v1.4s }, [x1], #16
    ld1     { v2.4s }, [x1], #16
    ld1     { v3.4s }, [x1], #16
    ld1     { v4.4s }, [x1], #16

    fmul    v1.4s, v1.4s, v0.4s[0]
    fmla    v1.4s, v2.4s, v0.4s[1]
    fmla    v1.4s, v3.4s, v0.4s[2]
    fmla    v1.4s, v4.4s, v0.4s[3]

    st1     { v1.4s }, [x0]
    ret



/*
 * Params:
 *      x0: in Vec4*
 *      x1: in Mat4*
 *      x2: out Vec4*
 */
vec4_mul_mat4_new:
    /* Load vector column into v0 */
    ld1     { v0.4s }, [x0]

    /* Load all matrix columns into v1 - v4 */
    ld1     { v1.4s }, [x1], #16
    ld1     { v2.4s }, [x1], #16
    ld1     { v3.4s }, [x1], #16
    ld1     { v4.4s }, [x1], #16

    fmul    v1.4s, v1.4s, v0.4s[0]
    fmla    v1.4s, v2.4s, v0.4s[1]
    fmla    v1.4s, v3.4s, v0.4s[2]
    fmla    v1.4s, v4.4s, v0.4s[3]

    st1     { v1.4s }, [x2]
    ret



/*
 * Params:
 *      x0: in Vec4*
 *      x1: in Mat4*
 *      x2: out Vec4*
 * Description:
 *      Same as vec4_mul_mat4 but with perspective divide done at the end.
 */
vec4_mul_mat4_and_perspective_divide_new:
    /* Load vector column into v0 */
    ld1     { v0.4s }, [x0]

    /* Load all matrix columns into v1 - v4 */
    ld1     { v1.4s }, [x1], #16
    ld1     { v2.4s }, [x1], #16
    ld1     { v3.4s }, [x1], #16
    ld1     { v4.4s }, [x1], #16

    fmul    v1.4s, v1.4s, v0.4s[0]
    fmla    v1.4s, v2.4s, v0.4s[1]
    fmla    v1.4s, v3.4s, v0.4s[2]
    fmla    v1.4s, v4.4s, v0.4s[3]

    /* Perspective divide */
    mov     s0, v1.4s[3]            // s0 <- vec.w
    fmov    s9, 1.0
    fdiv    s0, s9, s0              // s0 <- 1.0 / vec.w
    fmul    v1.4s, v1.4s, v0.4s[0]

    st1     { v1.4s }, [x2]
    ret



/*
 * Params:
 *      v0.4s: f32         <- row 0
 *      v1.4s: f32         <- row 1
 *      v2.4s: f32         <- row 2
 *      v3.4s: f32         <- row 3
 *      x0: out Mat4*
 */
mat4_init:
    st1     { v0.4s }, [x0], #16
    st1     { v1.4s }, [x0], #16
    st1     { v2.4s }, [x0], #16
    st1     { v3.4s }, [x0], #16
    ret



/*
 * Params:
 *      x0: in/out Mat4*
 *      x1: in Mat4*
 * Note:
 *      The resulting matrix is mathematically equivalent to x1 * x0,
 *      i.e., first x0 is applied, then x1 is applied.
 */
mat4_mul_mat4_inplace:
    /* Load all of this' matrix columns into v0-v3 */
    ld1     { v0.4s }, [x0], #16
    ld1     { v1.4s }, [x0], #16
    ld1     { v2.4s }, [x0], #16
    ld1     { v3.4s }, [x0], #16

    /* Undo post index additions, as we will need original x0 later */
    sub     x0, x0, #64

    /* Load all of others' matrix columns into v4-v7 */
    ld1     { v4.4s }, [x1], #16
    ld1     { v5.4s }, [x1], #16
    ld1     { v6.4s }, [x1], #16
    ld1     { v7.4s }, [x1], #16

    /* First column */
    fmul    v8.4s, v4.4s, v0.4s[0]
    fmla    v8.4s, v5.4s, v0.4s[1]
    fmla    v8.4s, v6.4s, v0.4s[2]
    fmla    v8.4s, v7.4s, v0.4s[3]
    st1     { v8.4s }, [x0], #16

    /* Second column */
    fmul    v8.4s, v4.4s, v1.4s[0]
    fmla    v8.4s, v5.4s, v1.4s[1]
    fmla    v8.4s, v6.4s, v1.4s[2]
    fmla    v8.4s, v7.4s, v1.4s[3]
    st1     { v8.4s }, [x0], #16

    /* Third column */
    fmul    v8.4s, v4.4s, v2.4s[0]
    fmla    v8.4s, v5.4s, v2.4s[1]
    fmla    v8.4s, v6.4s, v2.4s[2]
    fmla    v8.4s, v7.4s, v2.4s[3]
    st1     { v8.4s }, [x0], #16

    /* Fourth column */
    fmul    v8.4s, v4.4s, v3.4s[0]
    fmla    v8.4s, v5.4s, v3.4s[1]
    fmla    v8.4s, v6.4s, v3.4s[2]
    fmla    v8.4s, v7.4s, v3.4s[3]
    st1     { v8.4s }, [x0], #16

    ret


/*
 * Params:
 *      x0: out Mat4*
 */
mat4_new_identity:
    /*
     * -----------------------------------------
     * |    1    |    0    |    0    |    0    |
     * |    0    |    1    |    0    |    0    |
     * |    0    |    0    |    1    |    0    |
     * |    0    |    0    |    0    |    1    |
     * -----------------------------------------
     */
    fmov    s0, 1.0

    str     s0,  [x0, MAT4_COL0 + VEC4_X]
    str     wzr, [x0, MAT4_COL0 + VEC4_Y]
    str     wzr, [x0, MAT4_COL0 + VEC4_Z]
    str     wzr, [x0, MAT4_COL0 + VEC4_W]

    str     wzr, [x0, MAT4_COL1 + VEC4_X]
    str     s0,  [x0, MAT4_COL1 + VEC4_Y]
    str     wzr, [x0, MAT4_COL1 + VEC4_Z]
    str     wzr, [x0, MAT4_COL1 + VEC4_W]

    str     wzr, [x0, MAT4_COL2 + VEC4_X]
    str     wzr, [x0, MAT4_COL2 + VEC4_Y]
    str     s0,  [x0, MAT4_COL2 + VEC4_Z]
    str     wzr, [x0, MAT4_COL2 + VEC4_W]

    str     wzr, [x0, MAT4_COL3 + VEC4_X]
    str     wzr, [x0, MAT4_COL3 + VEC4_Y]
    str     wzr, [x0, MAT4_COL3 + VEC4_Z]
    str     s0,  [x0, MAT4_COL3 + VEC4_W]

    ret



/*
 * Params:
 *      x0: out Mat4*
 * * * * *
 *      s0: f32         <- rotation angle (radians)
 */
mat4_new_rotation_y:
    /*
     * -----------------------------------------
     * |  cos(r) |    0    |  sin(r) |    0    |
     * |    0    |    1    |    0    |    0    |
     * | -sin(r) |    0    |  cos(r) |    0    |
     * |    0    |    0    |    0    |    1    |
     * -----------------------------------------
     */
    str     lr, [sp, -8]!
    str     s19, [sp, -8]!

    fmov    s19, s0     // s19 = r
    bl      cos         // s0 = cos(r)
    str     s0, [x0, MAT4_COL0 + VEC4_X]
    str     s0, [x0, MAT4_COL2 + VEC4_Z]

    fmov    s0, s19     // s0 = r
    bl      sin         // s0 = sin(r)
    str     s0, [x0, MAT4_COL2 + VEC4_X]
    fneg    s0, s0      // s0 = -sin(r)
    str     s0, [x0, MAT4_COL0 + VEC4_Z]

    str     wzr, [x0, MAT4_COL0 + VEC4_Y]
    str     wzr, [x0, MAT4_COL0 + VEC4_W]

    fmov    s0, 1.0

    str     wzr, [x0, MAT4_COL1 + VEC4_X]
    str     s0, [x0, MAT4_COL1 + VEC4_Y]
    str     wzr, [x0, MAT4_COL1 + VEC4_Z]
    str     wzr, [x0, MAT4_COL1 + VEC4_W]

    str     wzr, [x0, MAT4_COL2 + VEC4_Y]
    str     wzr, [x0, MAT4_COL2 + VEC4_W]

    str     wzr, [x0, MAT4_COL3 + VEC4_X]
    str     wzr, [x0, MAT4_COL3 + VEC4_Y]
    str     wzr, [x0, MAT4_COL3 + VEC4_Z]
    str     s0, [x0, MAT4_COL3 + VEC4_W]

    ldr     s19, [sp], 8
    ldr     lr, [sp], 8
    ret



/*
 * Params:
 *      x0: out Mat4*
 * * * * *
 *      s0: f32         <- rotation angle (radians)
 */
mat4_new_rotation_x:
    /*
     * -----------------------------------------
     * |    1    |    0    |    0    |    0    |
     * |    0    |  cos(r) | -sin(r) |    0    |
     * |    0    |  sin(r) |  cos(r) |    0    |
     * |    0    |    0    |    0    |    1    |
     * -----------------------------------------
     */
    str     lr, [sp, -8]!
    str     s19, [sp, -8]!

    fmov    s19, s0     // s19 = r
    bl      cos         // s0 = cos(r)
    str     s0, [x0, MAT4_COL1 + VEC4_Y]
    str     s0, [x0, MAT4_COL2 + VEC4_Z]

    fmov    s0, s19     // s0 = r
    bl      sin         // s0 = sin(r)
    str     s0, [x0, MAT4_COL1 + VEC4_Z]
    fneg    s0, s0      // s0 = -sin(r)
    str     s0, [x0, MAT4_COL2 + VEC4_Y]

    str     wzr, [x0, MAT4_COL1 + VEC4_X]
    str     wzr, [x0, MAT4_COL1 + VEC4_W]

    fmov    s0, 1.0

    str     s0,  [x0, MAT4_COL0 + VEC4_X]
    str     wzr, [x0, MAT4_COL0 + VEC4_Y]
    str     wzr, [x0, MAT4_COL0 + VEC4_Z]
    str     wzr, [x0, MAT4_COL0 + VEC4_W]

    str     wzr, [x0, MAT4_COL2 + VEC4_X]
    str     wzr, [x0, MAT4_COL2 + VEC4_W]

    str     wzr, [x0, MAT4_COL3 + VEC4_X]
    str     wzr, [x0, MAT4_COL3 + VEC4_Y]
    str     wzr, [x0, MAT4_COL3 + VEC4_Z]
    str     s0,  [x0, MAT4_COL3 + VEC4_W]

    ldr     s19, [sp], 8
    ldr     lr, [sp], 8
    ret



/*
 * Params:
 *      x0: out Mat4*
 * * * * *
 *      s0: f32         <- scale x
 *      s1: f32         <- scale y
 *      s2: f32         <- scale z
 */
mat4_new_scale:
    /*
     * -----------------------------------------
     * |   s_x   |    0    |    0    |    0    |
     * |    0    |   s_y   |    0    |    0    |
     * |    0    |    0    |   s_z   |    0    |
     * |    0    |    0    |    0    |    1    |
     * -----------------------------------------
     */
    str     s0,  [x0, MAT4_COL0 + VEC4_X]
    str     wzr, [x0, MAT4_COL0 + VEC4_Y]
    str     wzr, [x0, MAT4_COL0 + VEC4_Z]
    str     wzr, [x0, MAT4_COL0 + VEC4_W]

    str     wzr, [x0, MAT4_COL1 + VEC4_X]
    str     s1,  [x0, MAT4_COL1 + VEC4_Y]
    str     wzr, [x0, MAT4_COL1 + VEC4_Z]
    str     wzr, [x0, MAT4_COL1 + VEC4_W]

    str     wzr, [x0, MAT4_COL2 + VEC4_X]
    str     wzr, [x0, MAT4_COL2 + VEC4_Y]
    str     s2,  [x0, MAT4_COL2 + VEC4_Z]
    str     wzr, [x0, MAT4_COL2 + VEC4_W]

    fmov    s0, 1.0
    str     wzr, [x0, MAT4_COL3 + VEC4_X]
    str     wzr, [x0, MAT4_COL3 + VEC4_Y]
    str     wzr, [x0, MAT4_COL3 + VEC4_Z]
    str     s0,  [x0, MAT4_COL3 + VEC4_W]

    ret



/*
 * Params:
 *      x0: out Mat4*
 * * * * *
 *      s0: f32         <- translation x
 *      s1: f32         <- translation y
 *      s2: f32         <- translation z
 */
mat4_new_translation:
    /*
     * -----------------------------------------
     * |    1    |    0    |    0    |   t_x   |
     * |    0    |    1    |    0    |   t_y   |
     * |    0    |    0    |    1    |   t_z   |
     * |    0    |    0    |    0    |    1    |
     * -----------------------------------------
     */
    str     s0,  [x0, MAT4_COL3 + VEC4_X]
    str     s1,  [x0, MAT4_COL3 + VEC4_Y]
    str     s2,  [x0, MAT4_COL3 + VEC4_Z]

    fmov    s0, 1.0

    str     s0,  [x0, MAT4_COL3 + VEC4_W]

    str     s0,  [x0, MAT4_COL0 + VEC4_X]
    str     wzr, [x0, MAT4_COL0 + VEC4_Y]
    str     wzr, [x0, MAT4_COL0 + VEC4_Z]
    str     wzr, [x0, MAT4_COL0 + VEC4_W]

    str     wzr, [x0, MAT4_COL1 + VEC4_X]
    str     s0,  [x0, MAT4_COL1 + VEC4_Y]
    str     wzr, [x0, MAT4_COL1 + VEC4_Z]
    str     wzr, [x0, MAT4_COL1 + VEC4_W]

    str     wzr, [x0, MAT4_COL2 + VEC4_X]
    str     wzr, [x0, MAT4_COL2 + VEC4_Y]
    str     s0,  [x0, MAT4_COL2 + VEC4_Z]
    str     wzr, [x0, MAT4_COL2 + VEC4_W]


    ret



/*
 * Params:
 *      x0: out Mat4*
 * * * * *
 *      s0: f32         <- near
 *      s1: f32         <- far
 *      s2: f32         <- fov (in radians)
 *      s3: f32         <- aspect ratio
 * Note:
 *      near and far must both be positive (the z axis gets inverted)
 */
mat4_new_perspective:
    /*
     * ----------------------------------------------------
     * | 1 / (ar * t) |   0   |      0      |      0      |
     * |       0      | 1 / t |      0      |      0      |
     * |       0      |   0   | (n+f)/(n-f) | 2*n*f/(n-f) |
     * |       0      |   0   |     -1      |      0      |
     * ----------------------------------------------------
     * where:
     *      a = aspect ratio
     *      t = tan(fov / 2)
     */
    stp     lr, x19, [sp, -16]!

    mov     x19, x0         // x19 <- matrix pointer

    fsub    s9, s0, s1      // s9 = near - far
    fmov    s10, 1.0
    fdiv    s9, s10, s9     // s9 = 1 / (near - far)

    fadd    s10, s0, s1     // s10 = near + far
    fmul    s10, s10, s9    // s10 = (near + far) / (near - far)
    str     s10, [x19, MAT4_COL2 + VEC4_Z]

    fmov    s10, 2.0        // s10 = 2
    fmul    s10, s10, s0    // s10 = 2 * near
    fmul    s10, s10, s1    // s10 = 2 * near * far
    fmul    s10, s10, s9    // s10 = 2 * near * far / (near - far)
    str     s10, [x19, MAT4_COL3 + VEC4_Z]



    sub     sp, sp, 16
    str     s3, [sp]        // Save aspect ratio to stack

    fmov    s9, 0.5
    fmul    s0, s2, s9      // s0 = fov / 2
    bl      tan             // s0 = tan(fov / 2)

    ldr     s1, [sp]        // s1 = aspect ratio
    add     sp, sp, 16

    fmul    s0, s1, s0      // s0 = aspect ratio * tan(fov / 2)

    fmov    s9, 1.0
    fdiv    s0, s9, s0      // s0 = 1 / (aspect ratio * tan(fov / 2))
    str     s0, [x19, MAT4_COL0 + VEC4_X]

    fmul    s0, s0, s1      // s0 = 1 / tan(fov / 2)
    str     s0, [x19, MAT4_COL1 + VEC4_Y]

    fmov    s0, -1.0
    str     s0, [x19, MAT4_COL2 + VEC4_W]



    str     wzr, [x19, MAT4_COL0 + VEC4_Y]
    str     wzr, [x19, MAT4_COL0 + VEC4_Z]
    str     wzr, [x19, MAT4_COL0 + VEC4_W]

    str     wzr, [x19, MAT4_COL1 + VEC4_X]
    str     wzr, [x19, MAT4_COL1 + VEC4_Z]
    str     wzr, [x19, MAT4_COL1 + VEC4_W]

    str     wzr, [x19, MAT4_COL2 + VEC4_X]
    str     wzr, [x19, MAT4_COL2 + VEC4_Y]

    str     wzr, [x19, MAT4_COL3 + VEC4_X]
    str     wzr, [x19, MAT4_COL3 + VEC4_Y]
    str     wzr, [x19, MAT4_COL3 + VEC4_W]


    ldp     lr, x19, [sp], 16
    ret



/*
 * Params:
 *      x0: out Mat4*
 * * * * *
 *      s0: f32         <- aspect ratio
 */
mat4_new_orthographic:
    /*
     * ----------------------------------
     * |   1   |    0   |   0   |   0   |
     * |   0   | aspect |   0   |   0   |
     * |   0   |    0   |   1   |   0   |
     * |   0   |    0   |   0   |   1   |
     * ----------------------------------
     */
    str     s0,  [x0, MAT4_COL1 + VEC4_Y]

    fmov    s0, 1.0

    str     s0,  [x0, MAT4_COL0 + VEC4_X]
    str     wzr, [x0, MAT4_COL0 + VEC4_Y]
    str     wzr, [x0, MAT4_COL0 + VEC4_Z]
    str     wzr, [x0, MAT4_COL0 + VEC4_W]

    str     wzr, [x0, MAT4_COL1 + VEC4_X]
    str     wzr, [x0, MAT4_COL1 + VEC4_Z]
    str     wzr, [x0, MAT4_COL1 + VEC4_W]

    str     wzr, [x0, MAT4_COL2 + VEC4_X]
    str     wzr, [x0, MAT4_COL2 + VEC4_Y]
    str     s0,  [x0, MAT4_COL2 + VEC4_Z]
    str     wzr, [x0, MAT4_COL2 + VEC4_W]

    str     wzr, [x0, MAT4_COL3 + VEC4_X]
    str     wzr, [x0, MAT4_COL3 + VEC4_Y]
    str     wzr, [x0, MAT4_COL3 + VEC4_Z]
    str     s0,  [x0, MAT4_COL3 + VEC4_W]

    ret



/*
 * Params:
 *      s0: f32     <- angle in radians
 * Returns:
 *      s0: f32     <- cos(x)
 * Based on https://stackoverflow.com/a/28050328
 */
cos:
    ldr     s1, F32_FRAC_1_TAU
    fmul    s0, s0, s1      // x *= 1/TAU
    fmov    s1, 0.25        // s1 = 0.25
    fadd    s2, s0, s1      // s2 = x + 0.25
    frintm  s2, s2          // s2 = floor(x + 0.25)
    fadd    s1, s1, s2      // s1 = 0.25 + floor(x + 0.25)
    fsub    s0, s0, s1      // x -= 0.25 + floor(x + 0.25)
    fabs    s1, s0          // s1 = abs(x)
    fmov    s2, -0.5        // s2 = -0.5
    fadd    s1, s1, s2      // s1 = abs(x) - 0.5
    fmov    s2, 16.0        // s2 = 16.0
    fmul    s1, s1, s2      // s1 = 16.0 * (abs(x) - 0.5)
    fmul    s0, s0, s1      // x *= 16.0 * (abs(x) - 0.5)
    fmov    s1, -1.0        // s1 = -1.0
    fabs    s2, s0          // s2 = abs(x)
    fadd    s2, s2, s1      // s2 = abs(x) - 1
    fmul    s2, s0, s2      // s2 = x * (abs(x) - 1.0)
    ldr     s1, F32_0_225   // s1 = 0.225
    fmul    s1, s1, s2      // s1 = 0.225 * x * (abs(x) - 1.0)
    fadd    s0, s0, s1      // x += 0.225 * x * (abs(x) - 1.0)
    ret



/*
 * Params:
 *      s0: f32     <- angle in radians
 * Returns:
 *      s0: f32     <- sin(x)
 */
sin:
    str     lr, [sp, -8]!

    ldr     s1, F32_FRAC_TAU_4
    fsub    s0, s0, s1      // x -= TAU/4
    bl      cos

    ldr     lr, [sp], 8
    ret



/*
 * Params:
 *      s0: f32     <- angle in radians
 * Returns:
 *      s0: f32     <- tan(x)
 */
tan:
    str     lr, [sp, -16]!
    str     s19, [sp, 8]

    fmov    s19, s0     // s19 <- x

    bl      cos         // s0 <- cos(x)
    fmov    s1, s0      // s1 <- cos(x)
    fmov    s0, s19     // s0 <- x
    fmov    s19, s1     // s19 <- cos(x)

    bl      sin         // s0 <- sin(x)
    fdiv    s0, s0, s19 // s0 <- sin(x) / cos(x) = tan(x)

    ldr     s19, [sp, 8]
    ldr     lr, [sp], 16
    ret



.endif
