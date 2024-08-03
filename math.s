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
F32_0_225: .float  0.225



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
    ldr     s1, F32_FRAC_TAU_4
    fsub    s0, s0, s1      // x -= TAU/4
    bl      cos
    ret



.endif
