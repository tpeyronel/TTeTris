.ifndef MESH_S
MESH_S:
        .include "./constants.s"
        .include "./math.s"
        .include "./line.s"
        .include "./time.s"

/* struct Mesh */
        .equ MESH_TRIANGLE_COUNT,       0       // u32
        .equ MESH_VERTEX_COUNT,         4       // u32
        .equ MESH_DATA,                 8       // u32[3 * TRIANGLE_COUNT "= INDEX_COUNT"] followed by Vec4[VERTEX_COUNT]


F32_TIME_TO_ANGLE: .float       0.000001

CUBE_MESH:
        .word   12
        .word   8

        .word   0
        .word   1
        .word   3

        .word   0
        .word   3
        .word   2

        .word   1
        .word   5
        .word   7

        .word   1
        .word   7
        .word   3

        .word   5
        .word   4
        .word   6

        .word   5
        .word   6
        .word   7

        .word   4
        .word   0
        .word   2

        .word   4
        .word   2
        .word   6

        .word   3
        .word   7
        .word   6

        .word   3
        .word   6
        .word   2

        .word   0
        .word   4
        .word   5

        .word   0
        .word   5
        .word   1

        // Far bottom left
        .float  -1.0
        .float  -1.0
        .float  -1.0
        .float   1.0

        // Near bottom left
        .float  -1.0
        .float  -1.0
        .float   1.0
        .float   1.0

        // Far top left
        .float  -1.0
        .float   1.0
        .float  -1.0
        .float   1.0

        // Near top left
        .float  -1.0
        .float   1.0
        .float   1.0
        .float   1.0

        // Far bottom right
        .float   1.0
        .float  -1.0
        .float  -1.0
        .float   1.0

        // Near bottom right
        .float   1.0
        .float  -1.0
        .float   1.0
        .float   1.0

        // Far top right
        .float   1.0
        .float   1.0
        .float  -1.0
        .float   1.0

        // Near top right
        .float   1.0
        .float   1.0
        .float   1.0
        .float   1.0



/*
 * Params:
 *      x0: in Mesh*            <- mesh to draw
 *      x1: in/out u32*         <- framebuffer
 */
draw_mesh:
        stp     lr, x19, [sp, -16]!
        stp     x20, x21, [sp, -16]!
        stp     x22, x23, [sp, -16]!

        mov     x19, x1                         // x19 <- framebuffer

        ldr     w20, [x0, MESH_TRIANGLE_COUNT]  // x20 <- triangle count (later: remaining triangles)

        add     x21, x20, x20                   // x21 <- triangle count * 2
        add     x21, x21, x20                   // x21 <- triangle count * 3 = index count
        lsl     x21, x21, 2                     // x21 <- index count * 4
        add     x21, x21, MESH_DATA             // x21 <- offset to the first vertex of the mesh
        add     x21, x0, x21                    // x21 <- pointer to the first vertex of the mesh

        add     x22, x0, MESH_DATA              // x22 <- pointer to the first triangle of the mesh


        /* Create MVP matrix */
        sub     sp, sp, STRUCT_MAT4_SIZE
        mov     x23, sp                         // x23 <- MVP matrix

        mov     x0, x23
        bl      mat4_new_identity

        /* Setup MVP matrix */
                sub     sp, sp, STRUCT_MAT4_SIZE

                mov     x0, sp
                fmov    s0, 0.25
                fmov    s1, 0.25
                fmov    s2, 0.25
                bl      mat4_new_scale

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                bl      get_time
                scvtf   s0, w0
                ldr     s1, F32_TIME_TO_ANGLE
                fmul    s0, s0, s1

                mov     x0, sp
                bl      mat4_new_rotation_y

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                mov     x0, sp
                ldr     s0, F32_FRAC_TAU_16
                bl      mat4_new_rotation_x

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                mov     x0, sp
                movi    d0, 0
                movi    d1, 0
                ldr     s2, F32_1
                fneg    s2, s2
                bl      mat4_new_translation

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                mov     x0, sp
                ldr     s0, F32_1
                ldr     s1, F32_16
                ldr     s2, F32_FRAC_TAU_4
                ldr     s3, F32_ASPECT_RATIO
                bl      mat4_new_perspective

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                // mov     x0, sp
                // ldr     s0, F32_ASPECT_RATIO
                // bl      mat4_new_orthographic

                // mov     x0, x23
                // mov     x1, sp
                // bl      mat4_mul_mat4_inplace


                /* Convert from NDC space to screen space */
                mov     x0, sp
                ldr     s0, F32_320
                ldr     s1, F32_240
                ldr     s2, F32_1
                bl      mat4_new_scale

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                mov     x0, sp
                ldr     s0, F32_320
                ldr     s1, F32_240
                movi    d2, 0
                bl      mat4_new_translation

                mov     x0, x23
                mov     x1, sp
                bl      mat4_mul_mat4_inplace


                add     sp, sp, STRUCT_MAT4_SIZE
        /* MVP matrix ready */


        draw_mesh__next_triangle:
                ldr     w0, [x22]               // w0 <- first index of triangle
                lsl     x0, x0, 4               // x0 <- offset to the first vertex of the triangle
                add     x0, x0, x21             // x0 <- pointer to the first vertex of the triangle

                // Same thing for second and third vertices
                ldr     w1, [x22, 4]
                lsl     x1, x1, 4
                add     x1, x1, x21

                ldr     w2, [x22, 8]
                lsl     x2, x2, 4
                add     x2, x2, x21

                // Draw the triangle
                mov     x3, x23
                mov     x4, x19
                bl      draw_mesh_triangle

                // Advance x22 pointer by 12 bytes
                add     x22, x22, 3 * 4
                // Decrement remaining triangles
                subs    x20, x20, 1
                b.gt    draw_mesh__next_triangle


        add     sp, sp, STRUCT_MAT4_SIZE

        ldp     x22, x23, [sp], 16
        ldp     x20, x21, [sp], 16
        ldp     lr, x19, [sp], 16
        ret



/*
 * Params:
 *      x0: in Vec4*            <- first vertex
 *      x1: in Vec4*            <- second vertex
 *      x2: in Vec4*            <- third vertex
 *      x3: in Mat4*            <- MVP matrix
 *      x4: in/out u32*         <- framebuffer
 */
draw_mesh_triangle:
        stp     lr, x19, [sp, -16]!
        stp     x20, x21, [sp, -16]!
        stp     x22, x23, [sp, -16]!

        mov     x19, x4         // x19 <- framebuffer
        mov     x20, x3         // x20 <- MVP matrix
        mov     x21, x1         // x21 <- second vertex
        mov     x22, x2         // x22 <- third vertex

        sub     sp, sp, STRUCT_VEC4_SIZE
        /* (x0 = first vertex) */
        mov     x1, x20
        mov     x2, sp
        bl      vec4_mul_mat4_and_perspective_divide_new

        sub     sp, sp, STRUCT_VEC4_SIZE
        mov     x0, x21
        mov     x1, x20
        mov     x2, sp
        bl      vec4_mul_mat4_and_perspective_divide_new

        sub     sp, sp, STRUCT_VEC4_SIZE
        mov     x0, x22
        mov     x1, x20
        mov     x2, sp
        bl      vec4_mul_mat4_and_perspective_divide_new


        ldr     s9, [sp, VEC4_X]
        fcvtzs  w0, s9          // w9 <- third vertex x coordinate
        ldr     s9, [sp, VEC4_Y]
        fcvtzs  w1, s9         // w10 <- third vertex y coordinate

        ldr     s9, [sp, STRUCT_VEC4_SIZE + VEC4_X]
        fcvtzs  w2, s9          // w9 <- second vertex x coordinate
        ldr     s9, [sp, STRUCT_VEC4_SIZE + VEC4_Y]
        fcvtzs  w3, s9         // w10 <- second vertex y coordinate

        mov     x4, x19
        ldr     w5, =0xFFFFFFFF
        bl      draw_line


        ldr     s9, [sp, VEC4_X]
        fcvtzs  w0, s9          // w9 <- third vertex x coordinate
        ldr     s9, [sp, VEC4_Y]
        fcvtzs  w1, s9         // w10 <- third vertex y coordinate

        ldr     s9, [sp, (2 * STRUCT_VEC4_SIZE) + VEC4_X]
        fcvtzs  w2, s9          // w9 <- first vertex x coordinate
        ldr     s9, [sp, (2 * STRUCT_VEC4_SIZE) + VEC4_Y]
        fcvtzs  w3, s9         // w10 <- first vertex y coordinate

        mov     x4, x19
        ldr     w5, =0xFFFFFFFF
        bl      draw_line


        ldr     s9, [sp, STRUCT_VEC4_SIZE + VEC4_X]
        fcvtzs  w0, s9          // w9 <- second vertex x coordinate
        ldr     s9, [sp, STRUCT_VEC4_SIZE + VEC4_Y]
        fcvtzs  w1, s9         // w10 <- second vertex y coordinate

        ldr     s9, [sp, (2 * STRUCT_VEC4_SIZE) + VEC4_X]
        fcvtzs  w2, s9          // w9 <- first vertex x coordinate
        ldr     s9, [sp, (2 * STRUCT_VEC4_SIZE) + VEC4_Y]
        fcvtzs  w3, s9         // w10 <- first vertex y coordinate

        mov     x4, x19
        ldr     w5, =0xFFFFFFFF
        bl      draw_line


        add     sp, sp, STRUCT_VEC4_SIZE
        add     sp, sp, STRUCT_VEC4_SIZE
        add     sp, sp, STRUCT_VEC4_SIZE


        ldp     x22, x23, [sp], 16
        ldp     x20, x21, [sp], 16
        ldp     lr, x19, [sp], 16
        ret



.endif
