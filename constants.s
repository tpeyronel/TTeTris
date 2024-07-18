.include "./tetris_cell.s"
.ifndef CONSTANTS_S
CONSTANTS_S:

        .equ TICKS_PER_SECOND,          60
        .equ MS_PER_TICK,               1000 / TICKS_PER_SECOND         // unused
        .equ US_PER_TICK,               1000000 / TICKS_PER_SECOND
        F32_TICK_TIME: .float           0.01666666666666666666666666666667

        F32_SPARK_GRAVITY: .float               -50.0
        F32_SPARK_CLUSTER_DENSITY: .float       2.5

	.equ SCREEN_WIDTH,                      640
	.equ SCREEN_HEIGH,                      480
        .equ SCREEN_PIXELS,                     SCREEN_WIDTH * SCREEN_HEIGH
	.equ BITS_PER_PIXEL,                    32
	.equ BYTES_PER_PIXEL,                   4
	.equ BYTES_PER_PIXEL_SHIFT,             2
        .equ BYTES_PER_SCREEN_ROW,              SCREEN_WIDTH * BYTES_PER_PIXEL

        .equ BYTES_PER_TETROMINO_BLOCK,         1
        .equ BYTES_PER_TETROMINO_BLOCK_SHIFT,   0

        .equ BOARD_WIDTH,               10
        .equ BOARD_HEIGHT,              20
        .equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
        .equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1

        .equ TETROMINO_BOARD_WIDTH,             4
        .equ TETROMINO_BOARD_HEIGHT,            4
        .equ TETROMINO_BOARD_SIZE,              TETROMINO_BOARD_WIDTH * TETROMINO_BOARD_WIDTH
        .equ TETROMINO_BOARD_SIZE_IN_BYTES,     TETROMINO_BOARD_SIZE * BYTES_PER_TETROMINO_BLOCK
        .equ NUM_ORIENTATIONS,                  4

        .equ NUM_TETROMINOS,                    7

        .equ TETROMINO_ORIGIN_X,                (BOARD_WIDTH / 2) - (TETROMINO_BOARD_WIDTH / 2)
        .equ TETROMINO_ORIGIN_Y,                BOARD_HEIGHT - TETROMINO_BOARD_HEIGHT

        // (origin = bottom left)
        .equ BOARD_ORIGIN_X,                    ((SCREEN_WIDTH / 2) - (TETRIS_CELL_SIZE * ((BOARD_WIDTH / 2) + 1)))
        .equ BOARD_ORIGIN_Y,                    ((SCREEN_HEIGH / 2) - (TETRIS_CELL_SIZE * ((BOARD_HEIGHT / 2) + 1)))
        .equ INNER_BOARD_ORIGIN_X,              BOARD_ORIGIN_X + TETRIS_CELL_SIZE
        .equ INNER_BOARD_ORIGIN_Y,              BOARD_ORIGIN_Y + TETRIS_CELL_SIZE


f32_0_9:
        .float                  0.9
f32_1000000:
        .float                  1000000


/* struct Tetromino */
        .equ TETROMINO_DIFFUSE_COLOR,   0                               // u32
        .equ TETROMINO_SPECULAR_COLOR,  TETROMINO_DIFFUSE_COLOR + 4     // u32
        .equ TETROMINO_AMBIENT_COLOR,   TETROMINO_SPECULAR_COLOR + 4    // u32
        .equ TETROMINO_ROTS,            TETROMINO_AMBIENT_COLOR + 4     // struct TetrominoData[4] = struct TetrominoData[NUM_ORIENTATIONS]

        .equ STRUCT_TETROMINO_SIZE,     TETROMINO_ROTS + (STRUCT_TDATA_SIZE * NUM_ORIENTATIONS)

/* struct TetrominoData */
        .equ TDATA,                     0                       // u8[4][4]             [0][0] is bottom left, [0][3] is bottom right

        .equ STRUCT_TDATA_SIZE,         TDATA + TETROMINO_BOARD_SIZE_IN_BYTES



        .equ FRAME_DIFFUSE_COLOR,       0xFF777777
        .equ FRAME_SPECULAR_COLOR,      0xFF999999
        .equ FRAME_AMBIENT_COLOR,       0xFF333333

        .equ GHOST_TETROMINO_ALPHA_MULTIPLIER,  0x80



/* Data for all 7 tetrominos */
/* struct Tetromino[NUM_TETROMINOS] */
/* Data is mirrored both horizontally and vertically, due to endianness and array indexing respectively */
TETROMINOS:
/* Tetromino I: */
        .word 0xFF00CCCC  // Diffuse color
        .word 0xFF00FFFF  // Specular color
        .word 0xFF009999  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0xFFFFFFFF
        .word 0x00000000

        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x0000FF00

        .word 0x00000000
        .word 0xFFFFFFFF
        .word 0x00000000
        .word 0x00000000

        .word 0x00FF0000
        .word 0x00FF0000
        .word 0x00FF0000
        .word 0x00FF0000


/* Tetromino J: */
        .word 0xFF0000CC  // Diffuse color
        .word 0xFF0000FF  // Specular color
        .word 0xFF000099  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFFFF
        .word 0x000000FF

        .word 0x00000000
        .word 0x0000FFFF
        .word 0x0000FF00
        .word 0x0000FF00

        .word 0x00000000
        .word 0x00FF0000
        .word 0x00FFFFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x00FFFF00

/* Tetromino L: */
        .word 0xFFCC6600  // Diffuse color
        .word 0xFFFF8800  // Specular color
        .word 0xFF994400  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFFFF
        .word 0x00FF0000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FF00
        .word 0x0000FFFF

        .word 0x00000000
        .word 0x000000FF
        .word 0x00FFFFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x00FFFF00
        .word 0x0000FF00
        .word 0x0000FF00

/* Tetromino O: */
        .word 0xFFCCCC00  // Diffuse color
        .word 0xFFFFFF00  // Specular color
        .word 0xFF999900  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x00FFFF00

/* Tetromino S: */
        .word 0xFF00CC00  // Diffuse color
        .word 0xFF00FF00  // Specular color
        .word 0xFF009900  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0x0000FFFF
        .word 0x00FFFF00

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FFFF
        .word 0x000000FF

        .word 0x00000000
        .word 0x0000FFFF
        .word 0x00FFFF00
        .word 0x00000000

        .word 0x00000000
        .word 0x00FF0000
        .word 0x00FFFF00
        .word 0x0000FF00

/* Tetromino Z: */
        .word 0xFFCC0000  // Diffuse color
        .word 0xFFFF0000  // Specular color
        .word 0xFF990000  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFF00
        .word 0x0000FFFF

        .word 0x00000000
        .word 0x000000FF
        .word 0x0000FFFF
        .word 0x0000FF00

        .word 0x00000000
        .word 0x00FFFF00
        .word 0x0000FFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x00FFFF00
        .word 0x00FF0000

/* Tetromino T: */
        .word 0xFF9900CC  // Diffuse color
        .word 0xFFCC00FF  // Specular color
        .word 0xFF660099  // Ambient color

        .word 0x00000000
        .word 0x00000000
        .word 0x00FFFFFF
        .word 0x0000FF00

        .word 0x00000000
        .word 0x0000FF00
        .word 0x0000FFFF
        .word 0x0000FF00

        .word 0x00000000
        .word 0x0000FF00
        .word 0x00FFFFFF
        .word 0x00000000

        .word 0x00000000
        .word 0x0000FF00
        .word 0x00FFFF00
        .word 0x0000FF00

.endif
