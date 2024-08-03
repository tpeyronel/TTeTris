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


.endif
