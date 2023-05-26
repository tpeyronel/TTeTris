	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32
	.equ BYTES_PER_PIXEL, 4
	.equ BYTES_PER_PIXEL_SHIFT, 2
    .equ BYTES_PER_SCREEN_ROW, SCREEN_WIDTH * BYTES_PER_PIXEL

	.equ MOVEMENT_PER_STEP,			20
	.equ SQUARE_SIZE,				20

	.equ BOARD_WIDTH,               10
	.equ BOARD_HEIGHT,              20
	.equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
	.equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1

	.equ TETROMINO_BOARD_WIDTH,             4
	.equ TETROMINO_BOARD_SIZE,              TETROMINO_BOARD_WIDTH * TETROMINO_BOARD_WIDTH
	.equ TETROMINO_BOARD_SIZE_IN_BYTES,     TETROMINO_BOARD_SIZE * 1
	.equ NUM_ORIENTATIONS,                  4

	.equ NUM_TETROMINOS,                    7

	.equ TETROMINO_ID_BIAS,					1


	.equ GPIO_BASE,                 0x3f200000
	.equ GPIO_GPFSEL0,              0x00
	.equ GPIO_GPLEV0,               0x34
        .equ GPIO_W,                    0b000010        // (GPIO_1)
        .equ GPIO_A,                    0b000100        // (GPIO_2)
        .equ GPIO_S,                    0b001000        // (GPIO_3)
        .equ GPIO_D,                    0b010000        // (GPIO_4)
        .equ GPIO_SPACE,                0b100000        // (GPIO_5)
        .equ RNG_BASE,                  0x3f104000
        .equ RNG_NUMBER_ADDRESS,        0x3f104008
        .equ SYS_TIMER_BASE_ADDRESS,    0x3f003000
        .equ SYS_TIMER_VALUE_ADDRESS,   0x3f003004      // 32 bit number in microseconds
        // .equ GPIO_CLK_DIV_ADDRESS,      0x3f101074
        // .equ GPIO_CLK_CTL_ADDRESS,      0x3f101070
        // .equ GPIO_CLK_DIV,              0x5A0C0000
        // .equ GPIO_CLK_CTL,              0x5A000011
        .equ MS_PER_STEP,               500
        .equ US_PER_STEP,               MS_PER_STEP * 1000

        BG_COLORS: .word 0x00FF0000, 0x000FF000, 0x0000FF00, 0x00000FF0, 0x000000FF, 0x00F0000F
        BG_COLOR: .dword 0xFFFFFFFF
        PLAYER_COLOR: .dword 0xFFFFFFFF

	.globl main
/* enum CollisionResult */
        .equ COLLISION_RESULT_NO_COLLISION,     0b00
        .equ COLLISION_RESULT_OUT_OF_BOUNDS,    0b01
        .equ COLLISION_RESULT_EXISTING_BLOCK,   0b10

/* struct GameState */
        .equ LAST_TICK,                 0                                       // u32
        .equ INPUT_STATE,               LAST_TICK + 4                         // struct InputState
        .equ TETROMINO_STATE,           INPUT_STATE + STRUCT_INPUT_STATE_SIZE   // struct TetrominoState
        .equ BOARD_STATE,               TETROMINO_STATE + STRUCT_TSTATE_SIZE    // struct BoardState

        .equ STRUCT_GAME_STATE_SIZE,    BOARD_STATE + STRUCT_BSTATE_SIZE

/* struct InputState */
        .equ PRESSED_STATE,             0                       // u32
        .equ ON_PRESS_STATE,            PRESSED_STATE + 4       // u32

        .equ STRUCT_INPUT_STATE_SIZE,   ON_PRESS_STATE + 4

/* struct TetrominoState */
        .equ TSTATE_ID,                 0                       // u64
        .equ TSTATE_ROT,                TSTATE_ID + 8           // u64
        .equ TSTATE_POS_X,              TSTATE_ROT + 8          // i64
        .equ TSTATE_POS_Y,              TSTATE_POS_X + 8        // i64

        .equ STRUCT_TSTATE_SIZE,        TSTATE_POS_Y + 8

/* struct BoardState */
        .equ BSTATE_BOARD,              0                       // u8[22][10] = u8[BOARD_HEIGHT][BOARD_WIDTH]

        .equ STRUCT_BSTATE_SIZE,        BSTATE_BOARD + BOARD_SIZE_IN_BYTES

/* struct Tetromino */
        .equ TETROMINO_COLOR,           0                           // u32
        .equ TETROMINO_ROTS,            TETROMINO_COLOR + 4         // struct TetrominoData[4] = struct TetrominoData[NUM_ORIENTATIONS]

        .equ STRUCT_TETROMINO_SIZE,     TETROMINO_ROTS + (STRUCT_TDATA_SIZE * NUM_ORIENTATIONS)

/* struct TetrominoData */
        .equ TDATA,                     0                       // u8[4][4]             [0][0] is bottom left, [0][3] is bottom right

        .equ STRUCT_TDATA_SIZE,         TDATA + TETROMINO_BOARD_SIZE_IN_BYTES


/* Data for all 7 tetrominos */
TETROMINOS:
/* Tetromino I: */
// id: 0
        .word 0x31C7EF  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010101
        .word 0x00000000

        .word 0x00010000
        .word 0x00010000
        .word 0x00010000
        .word 0x00010000

        .word 0x00000000
        .word 0x01010101
        .word 0x00000000
        .word 0x00000000

        .word 0x00000100
        .word 0x00000100
        .word 0x00000100
        .word 0x00000100


/* Tetromino J: */
// id: 1
        .word 0x5A65AD  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010100
        .word 0x01000000

        .word 0x00000000
        .word 0x01010000
        .word 0x00010000
        .word 0x00010000

        .word 0x00000000
        .word 0x00000100
        .word 0x01010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00010000
        .word 0x00010000
        .word 0x00010100

/* Tetromino L: */
// id: 2
        .word 0xEF7921  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010100
        .word 0x00000100

        .word 0x00000000
        .word 0x00010000
        .word 0x00010000
        .word 0x01010000

        .word 0x00000000
        .word 0x01000000
        .word 0x01010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00010100
        .word 0x00010000
        .word 0x00010000

/* Tetromino O: */
// id: 3
        .word 0xF7D308  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x00010100

/* Tetromino S: */
// id: 4
        .word 0x42B642  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010000
        .word 0x00010100

        .word 0x00000000
        .word 0x00010000
        .word 0x01010000
        .word 0x01000000

        .word 0x00000000
        .word 0x01010000
        .word 0x00010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00000100
        .word 0x00010100
        .word 0x00010000

/* Tetromino Z: */
// id: 5
        .word 0xEF2029  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x00010100
        .word 0x01010000

        .word 0x00000000
        .word 0x01000000
        .word 0x01010000
        .word 0x00010000

        .word 0x00000000
        .word 0x00010100
        .word 0x01010000
        .word 0x00000000

        .word 0x00000000
        .word 0x00010000
        .word 0x00010100
        .word 0x00000100

/* Tetromino T: */
// id: 6
        .word 0xAD4D9C  // Color

        .word 0x00000000
        .word 0x00000000
        .word 0x01010100
        .word 0x00010000

        .word 0x00000000
        .word 0x00010000
        .word 0x01010000
        .word 0x00010000

        .word 0x00000000
        .word 0x00010000
        .word 0x01010100
        .word 0x00000000

        .word 0x00000000
        .word 0x00010000
        .word 0x00010100
        .word 0x00010000


/*
 * x19: framebuffer address (could be x9-15 ?)
 * x20: player x
 * x21: player y
 * x22: bg color index
 * w23: bg color
 * w24: player color
 * x25: remaining columns of row
 * x26: remaining rows
 * x28 (const): beginning of framebuffer
 */
main:
	mov     x28, x0         // Save framebuffer address to x28

	// Allocate struct GameState
	sub     sp, sp, STRUCT_GAME_STATE_SIZE
	// TODO: implement init_game_state subroutine
	add     x0, sp, INPUT_STATE
	bl      init_input_state
	add     x0, sp, TETROMINO_STATE
	bl      init_tetromino_state
	add x0, sp, BOARD_STATE
	bl init_board_state


	stur xzr, [sp, TETROMINO_STATE + TSTATE_ID]
	stur xzr, [sp, TETROMINO_STATE + TSTATE_ROT]
	stur xzr, [sp, TETROMINO_STATE + TSTATE_POS_X]
	mov x0, 16
	stur x0, [sp, TETROMINO_STATE + TSTATE_POS_Y]

	mov x0, 0
	mov x1, 0
	mov x2, SCREEN_WIDTH-1
	mov x3, SCREEN_HEIGH-1
	mov x4, x28
	mov x5, 0xFFFFFF
	bl draw_filled_rectangle


	/*
    add x0, sp, BOARD_STATE

	mov x1, 5
	add x1, x1, TETROMINO_ID_BIAS
    sturb w1, [x0, 30]
    sturb w1, [x0, 40]
    sturb w1, [x0, 50]
    sturb w1, [x0, 60]

	mov x1, 6
	add x1, x1, TETROMINO_ID_BIAS
    sturb w1, [x0, 20]
    sturb w1, [x0, 21]
    sturb w1, [x0, 22]
    sturb w1, [x0, 31]

	mov x1, 1
	add x1, x1, TETROMINO_ID_BIAS
    sturb w1, [x0, 12]
    sturb w1, [x0, 13]
    sturb w1, [x0, 23]
    sturb w1, [x0, 33]

	mov x1, 5
	add x1, x1, TETROMINO_ID_BIAS
    sturb w1, [x0, 14]
    sturb w1, [x0, 15]
    sturb w1, [x0, 16]
    sturb w1, [x0, 17]


	mov x1, 0
	add x1, x1, TETROMINO_ID_BIAS
    sturb w1, [x0]
    sturb w1, [x0, 1]
    sturb w1, [x0, 2]
    sturb w1, [x0, 3]
    sturb w1, [x0, 4]
    sturb w1, [x0, 5]
    sturb w1, [x0, 6]
    sturb w1, [x0, 7]
    sturb w1, [x0, 8]
    sturb w1, [x0, 9]

	add x0, sp, (BOARD_STATE + 190)
	mov x1, 0
	add x1, x1, TETROMINO_ID_BIAS
    sturb w1, [x0]
    sturb w1, [x0, 1]
    sturb w1, [x0, 2]
    sturb w1, [x0, 3]
    sturb w1, [x0, 4]
    sturb w1, [x0, 5]
    sturb w1, [x0, 6]
    sturb w1, [x0, 7]
    sturb w1, [x0, 8]
    sturb w1, [x0, 9]

	add x0, sp, BOARD_STATE
	mov x1, 1
	add x1, x1, TETROMINO_ID_BIAS
	sturb w1, [x0, 9]
	sturb w1, [x0, 19]
	sturb w1, [x0, 29]

	mov x1, 2
	add x1, x1, TETROMINO_ID_BIAS
	sturb w1, [x0, 39]
	sturb w1, [x0, 49]
	sturb w1, [x0, 59]

	mov x1, 3
	add x1, x1, TETROMINO_ID_BIAS
	sturb w1, [x0, 69]
	sturb w1, [x0, 79]
	sturb w1, [x0, 89]
	*/

	add x0, sp, TETROMINO_STATE
	mov x1, 2
	stur x1, [x0, TSTATE_ID]
	mov x1, 0
	stur x1, [x0, TSTATE_POS_X]
	mov x1, 0
	stur x1, [x0, TSTATE_POS_Y]
	mov x1, 0
	stur x1, [x0, TSTATE_ROT]
	
	mov x0, sp
	mov x1, x28
	bl draw_game


	/*
    movz x5, 0x2FFF, lsl 16
wait:
    sub x5, x5, 1
    cbnz x5, wait

    add x0, sp, BOARD_STATE
    mov x1, 0 
    bl erase_board_line

	mov x0, sp
	mov x1, x28
	bl draw_game

	add x0, sp, BOARD_STATE
    mov x1, 0 
    bl fall_one_block

	mov x0, sp
	mov x1, x28
	bl draw_game
	*/


inf:	
	b inf


/*
	Params:	
		x0:	u8			<- id of tetromino
	Returns:	
		x0:	u32			<- color
*/
get_tetromino_color:
	mov x1, STRUCT_TETROMINO_SIZE
	mul x0, x0, x1						
	ldr x2, =TETROMINOS
	add x0, x0, x2					// x0 = TETROMINOS + STRUCT_TETROMINO_SIZE*id

	ldur w0, [x0]
	br lr

/*
 * Params:
 *      x0: struct TetrominoState*
 * Returns:
 *		x0: struct TetrominoData*    -> matrix of tetromino
 *		x1: i64                      -> pos x	
 *		x2: i64                      -> pos y
 *		x3: u32                      -> color
 */
get_tetromino:	
	mov x4, x0
	
	ldur x5, [x4, TSTATE_ID]			
	mov x1, STRUCT_TETROMINO_SIZE
	mul x5, x5, x1						
	ldr x6, =TETROMINOS
	add x5, x5, x6					// x5 = TETROMINOS + STRUCT_TETROMINO_SIZE*id

	ldur x6, [x4, TSTATE_ROT]
	mov x0, STRUCT_TDATA_SIZE
	mul x0, x0, x6
	add x0, x0, TETROMINO_ROTS
	add x0, x0, x5					// x0 = x5 + TETROMINO_ROTS + STRUCT_TDATA_SIZE*TSTATE_ROT

	ldur x1, [x4, TSTATE_POS_X]

	ldur x2, [x4, TSTATE_POS_Y]

	ldur w3, [x5, TETROMINO_COLOR]

	br lr


/*
 * Params:
 *      x0: out struct GameState*       <- game_state
 */
init_game_state:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0                 // x19 <- game_state

        bl      get_time
        str     w0, [x19, LAST_TICK]

        add     x0, x19, INPUT_STATE
        bl      init_input_state

        add     x0, x19, TETROMINO_STATE
        bl      init_tetromino_state

		add		x0, x19, BOARD_STATE
		bl		init_board_state

        ldp     lr, x19, [sp], 16
        ret


/*  params:
 *	  x0: u8[BOARD_WIDTH][BOARD_HEIGHT]			-> address of board
 *    x1: u8									-> line to erase
 *  functionality:
 *    eliminates everything on the line
 */
erase_board_line:	
    mov x2, 0   // black
    mov x6, 10
    mul x6, x6, x1
    add x6, x0, x6  // x6 points to the first element of the line x8

    mov x11, BOARD_WIDTH
erase_board_line_turn_squares_off:
    sturb w2, [x6]
    add x6, x6, 1
    sub x11, x11, 1
    cbnz x11, erase_board_line_turn_squares_off

    br lr

/*  params
 *	  x0: u8[BOARD_WIDTH][BOARD_HEIGHT]			-> address of board
 *    x1: u8									-> line from which lines will start to fall
 *  functionality
 *    lowers by 1 block all the elements on the grid avobe x1
 */
fall_one_block:
    mov x7, BOARD_SIZE

    mov x15, BOARD_WIDTH
    mul x15, x15, x1
    add x15, x15, x0    // starts at first square from desired line x8

keepgoing:
    add x5, x15, 10		// cambié de sub a add porque ahora la
						// board crece de más abajo a más arriba

    ldur x2, [x5]        // get info from square avobe
    sturb w2, [x15]      // replace current square with new info

    add x15, x15, 1      // move on to the next square (-->)

    sub x5, x5, x0
    cmp x5, BOARD_SIZE-1
    bne keepgoing         // stop before reaching top line of grid (x15 at square #189, x5 at #199)
    
    mov x1, 19
    sub sp, sp, 8
    stur lr, [sp]
    bl erase_board_line // Erase anything on top line
    ldur lr, [sp]
    add sp, sp, 8

    br lr


/*
	Params:
		x0: in/out u8[BOARD_WIDTH][BOARD_HEIGHT]	 
 */
init_board_state:	
    mov x2, BOARD_SIZE_IN_BYTES
    create_grid_loop:
    sturb wzr, [x0]
    add x0, x0, 1
    sub x2, x2, 1
    cbz x2, create_grid_return
    b create_grid_loop

    create_grid_return:
    br lr

/*
	Params:
		mut x0: struct GameState*
		mut x1: framebuffer address
	
 */
draw_game:
	sub sp, sp, 40
	stur lr, [sp]
	stur x19, [sp, 8]
	stur x20, [sp, 16]
	stur x21, [sp, 24]
	stur x22, [sp, 32]

    add x9, x0, (BOARD_STATE + BSTATE_BOARD)

    mov x11, x1                

	add x0, x0, TETROMINO_STATE
	bl get_tetromino
	mov x19, x0			// x19 -> tetromino matrix
	mov x20, x1			// x20 -> tetromino x pos
	mov x21, x2			// x21 -> tetromino y pos
	mov x22, x3			// x22 -> tetromino color
	



    mov x14, 0             // row iterator
    draw_game_outer:
    mov x15, 0             // column iterator
    draw_game_inner:

	cmp x15, x20
	b.lt draw_game_not_tetromino

	add x12, x20, (TETROMINO_BOARD_WIDTH-1)
	cmp x15, x12
	b.gt draw_game_not_tetromino

	cmp x14, x21
	b.lt draw_game_not_tetromino

	add x12, x21, (TETROMINO_BOARD_WIDTH-1)
	cmp x14, x12
	b.gt draw_game_not_tetromino
	// if I got here, then I'm currently on a square of the tetromino
	sub x0, x15, x20
	sub x1, x14, x21

	mov x4, TETROMINO_BOARD_WIDTH
	mul x1, x1, x4

	add x0, x0, x1
	add x0, x0, x19

	ldurb w1, [x0]

	mov x4, 0
	cbz x1, draw_game_no_square
	mov x4, x22
	b draw_game_no_square


draw_game_not_tetromino:	
	ldurb w12, [x9]		  
    mov x4, 0
    cbz x12, draw_game_no_square

    sub x12, x12, TETROMINO_ID_BIAS

    mov x0, x12

    bl get_tetromino_color

    mov x4, x0

    draw_game_no_square:
    mov x0, x15
    mov x1, x14
    mov x2, SQUARE_SIZE
	mul x0, x0, x2
	add x0, x0, ( (SCREEN_WIDTH - BOARD_WIDTH * SQUARE_SIZE) / 2 )
	mul x1, x1, x2
	add x1, x1, ( (SCREEN_HEIGH - BOARD_HEIGHT * SQUARE_SIZE) / 2 )
	mov x3, x11
	
	bl draw_filled_square

    add x15, x15, 1
    add x9, x9, 1
	cmp x15, BOARD_WIDTH
    b.lt draw_game_inner

    add x14, x14, 1
	cmp x14, BOARD_HEIGHT
	b.eq draw_game_end

    b draw_game_outer

    draw_game_end:


	ldur lr, [sp]
	ldur x19, [sp, 8]
	ldur x20, [sp, 16]
	ldur x21, [sp, 24]
	ldur x22, [sp, 32]

    add sp, sp, 40

    br lr


/*
 * Params:
 *      x0: mut struct InputState*
 */
init_input_state:
        stur    wzr, [x0, PRESSED_STATE]
        stur    wzr, [x0, ON_PRESS_STATE]
        ret

/*
 * Params:
 *      x0: mut struct TetrominoState*
 */
init_tetromino_state:
        stur    xzr, [x0, TSTATE_ID]
        mov     x9, (SCREEN_WIDTH / 2)
        stur    x9, [x0, TSTATE_POS_X]
        mov     x9, (SCREEN_HEIGH / 2)
        stur    x9, [x0, TSTATE_POS_Y]
        stur    xzr, [x0, TSTATE_ROT]
        ret


/*
 * Params:
 *      x0: mut struct InputState*
 */
read_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        ldr     w19, [x0, PRESSED_STATE]        // Save last pressed state to compute on press state

	mov     x20, GPIO_BASE
	ldr     w20, [x20, GPIO_GPLEV0]         // w20 = new pressed state

        // Input in bit 'n' is "on press" if current pressed state is 1 and previous pressed state is 0
        mvn     w19, w19                        // Bitwise NOT last pressed state
        and     w21, w20, w19                   // w21 = new on press state

        str     w20, [x0, PRESSED_STATE]
        str     w21, [x0, ON_PRESS_STATE]

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret

/*
 * Params:
 *      x0: const struct InputState*
 *      x1: mut struct TetrominoState*
 */
process_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, x0         // x19 = const struct InputState*
        mov     x20, x1         // x20 = mut struct TetrominoState*

        ldr     w0, [x19, PRESSED_STATE]
        mov     x1, x20

        bl      handle_w
        bl      handle_a
        bl      handle_s
        bl      handle_d
        bl      handle_space

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_w:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_W
        cbz     x19, handle_w__end

        ldr     x19, [x1, TSTATE_POS_Y]
        cmp     x19, (SCREEN_HEIGH - 1)   // Check if player is touching top edge
        b.eq    handle_w__end

        add     x19, x19, 1               // Move player one position up
        str     x19, [x1, TSTATE_POS_Y]

handle_w__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_s:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_S
        cbz     x19, handle_s__end

        ldr     x19, [x1, TSTATE_POS_Y]
        cmp     x19, 0                   // Check if player is touching bottom edge
        b.eq    handle_s__end

        sub     x19, x19, 1               // Move player one position down
        str     x19, [x1, TSTATE_POS_Y]

handle_s__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_a:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_A
        cbz     x19, handle_a__end

        ldr     x19, [x1, TSTATE_POS_X]
        cmp     x19, 0                          // Check if player is touching left edge
        b.eq    handle_a__end

        sub     x19, x19, 1                     // Move player one position left
        str     x19, [x1, TSTATE_POS_X]

handle_a__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_d:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_D
        cbz     x19, handle_d__end

        ldr     x19, [x1, TSTATE_POS_X]
        cmp     x19, (SCREEN_WIDTH - 1)         // Check if player is touching right edge
        b.eq    handle_d__end

        add     x19, x19, 1                     // Move player one position right
        str     x19, [x1, TSTATE_POS_X]

handle_d__end:
        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: u32 (on press flags)
 *      x1: mut struct TetrominoState*
 */
handle_space:
        stp     lr, x19, [sp, -16]!

	and     x19, x0, GPIO_SPACE
        cbz     x19, handle_space__end

        ldr     x19, [x1, TSTATE_ID]

        add     x19, x19, #1
        cmp     x19, 6
        csel    x19, x19, xzr, lt         // Set x19 to zero if it's equal to 6

        str     x19, [x1, TSTATE_ID]

handle_space__end:
        ldp     lr, x19, [sp], 16
        ret


/*
 * Params:
 *      x0: background color index
 * Returns:
 *      w0: background color
 */
index_bg_color:
        stp     lr, x19, [sp, -16]!

        lsl     x0, x0, 2       // x0 = i * 4
        ldr     x19, =BG_COLORS // x19 = &BG_COLORS[0]
        add     x0, x19, x0     // x0 = &BG_COLORS[0] + (i * 4) = &BG_COLORS[i]
        ldr     w0, [x0]        // w0 = BG_COLORS[i]

        ldp     lr, x19, [sp], 16
        ret

/*
 * Params:
 *      x0: x coordinate
 *      x1: y coordinate
 *      x2: beginning of framebuffer
 *      x3: radius
 *      w4: color
 * Returns:
 *      x0: unmodified x coordinate
 *      x1: unmodified y coordinate
 *      x2: unmodified beginning of framebuffer
 *      w3: -
 */
draw_circle_at:
        stp     lr, x19, [sp, -48]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]

        add     x19, x3, 1
        mul     x19, x3, x19     // x19 "=" r^2 === r*(r+1)


        sub     x21, xzr, x3    // x21 = current circle y coordinate
circle_next_row:
        sub     x20, xzr, x3    // x20 = current circle x coordinate
circle_next_col:

        mul     x22, x20, x20   // x22 = x^2
        mul     x23, x21, x21   // x23 = y^2
        add     x22, x22, x23   // x22 = x^2 + y^2
        cmp     x22, x19
        b.gt    skip_circle_pixel       // only draw if x^2 + y^2 <= r^2



        stp     x0, x1, [sp, -16]!
        mov     x22, x3
        mov     w3, w4

        add     x0, x0, x20
        cmp     x0, SCREEN_WIDTH
        b.hs    pixel_out_of_bounds       // Out of screen
        add     x1, x1, x21
        cmp     x1, SCREEN_HEIGH
        b.hs    pixel_out_of_bounds       // Out of screen
        bl      draw_pixel_at

pixel_out_of_bounds:
        mov     x3, x22
        ldp     x0, x1, [sp], 16


skip_circle_pixel:
        add     x20, x20, 1
        cmp     x20, x3
        b.le    circle_next_col

        add     x21, x21, 1
        cmp     x21, x3
        b.le    circle_next_row


        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 48
        ret



/*
 * Params:
 *      x0: x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: beginning of framebuffer
 *      w3: color
 * Returns:
 *      x0: unmodified x coordinate
 *      x1: unmodified y coordinate
 *      x2: unmodified beginning of framebuffer
 *      w3: unmodified color
 */
draw_pixel_at:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, (SCREEN_HEIGH - 1)
        sub     x19, x19, x1

        mov     x20, SCREEN_WIDTH
        mul     x20, x20, x19                   // x20 = vertical offset
        add     x20, x20, x0                    // x20 = vertical offset + horizontal offset
        lsl     x20, x20, BYTES_PER_PIXEL_SHIFT // x20 = total offset
        add     x20, x2, x20                    // x20 = &framebuffer[y][x]

        str     w3, [x20]

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: bottom left x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: bottom left y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: top right x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: top right y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_filled_rectangle:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        // TODO: check bounds?

        // We need to move the framebuffer pointer to the initial position
        mov     x19, (SCREEN_HEIGH - 1)
        sub     x19, x19, x3                    // x19 = first row from top
        mov     x20, SCREEN_WIDTH
        mul     x19, x19, x20                   // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['rectangle's top left pixel']

        sub     x19, x2, x0                     // x19 = rectangle width - 1
        add     x19, x19, 1                     // x19 = rectangle width
        sub     x20, x20, x19                   // x20 = pixels between the end of a row and the beginning of the next row
        lsl     x20, x20, BYTES_PER_PIXEL_SHIFT // x20 = bytes between the end of a row and the beginning of the next row


draw_filled_rectangle__next_row:
        mov     x21, x19                        // x19 = rectangle width

draw_filled_rectangle__next_col:
        str     w5, [x4]                        // Paint pixel
        add     x4, x4, BYTES_PER_PIXEL         // Advance to next pixel

        subs    x21, x21, 1                     // Check if we finished current row
        b.gt    draw_filled_rectangle__next_col // If not, then draw next column



        add     x4, x4, x20                     // Advance to beginning of next row
        add     x1, x1, 1
        cmp     x1, x3
        b.le    draw_filled_rectangle__next_row


        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret


/*
 * Params:
 *      x0: bottom left x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: bottom left y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: size
 *      x3: beginning of framebuffer
 *      w4: color
 */
draw_filled_square:
        stp     lr, x19, [sp, -16]!

        mov     w5, w4
        mov     x4, x3
        sub     x2, x2, 1       // Top right (x', y') = (x + size - 1, y + size - 1)
        add     x3, x1, x2
        add     x2, x0, x2
        bl      draw_filled_rectangle

        ldp     lr, x19, [sp], 16
        ret

/*
 * Returns:
 *      w0: current time
 */
get_time:
        ldr     x0, =SYS_TIMER_VALUE_ADDRESS
        ldr     w0, [x0]
        ret

/*
 * Params:
 *      w0: previous_time
 * Returns:
 *      w0: elapsed_time
 *      w1: current_time
 */
get_elapsed_time:
        ldr     x1, =SYS_TIMER_VALUE_ADDRESS
        ldr     w1, [x1]
        sub     w0, w1, w0
        ret



/*
 * Params:
 *      x0: square x coordinate
 *      x1: square y coordinate
 *      w2: previous step
 *      x3: square size
 * Returns:
 *      x0: new square x coordinate
 *      x1: new square y coordinate
 *      w2: previous or new step
 */
advance_square_maybe:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x20, x0                 // x20 = x coordinate
        mov     x21, x1                 // x21 = y coordinate
        mov     w19, w2                 // w19 = previous step

        mov     w0, w19
        bl      get_elapsed_time        // Sets w0, w1

        ldr     w2, =US_PER_STEP
        cmp     w0, w2                         // Check if we should move square
        b.lt    advance_square_maybe__end

        // Enough time has passed since last step
        mov     w19, w1                         // Set last step as current time
        add     x20, x20, x3                    // Advance square position by its size

        ldr     x0, =SCREEN_WIDTH
        sub     x0, x0, x3
        cmp     x20, x0                         // Check if square is horizontally out of bounds
        b.lt    advance_square_maybe__end

        // Square is at end of row
        mov     x20, 0                          // Set square at beginning of row
        add     x21, x21, x3                    // Move square one row up


        ldr     x0, =SCREEN_HEIGH
        sub     x0, x0, x3
        cmp     x21, x0                         // Check if square is vertically out of bounds
        b.lt    advance_square_maybe__end

        // Square is vertically out of bounds
        mov     x21, 0                          // Set square at bottom row

advance_square_maybe__end:
        mov     x0, x20
        mov     x1, x21
        mov     w2, w19

        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret



/*
 * Params:
 *      x0: first point x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: first point y coordinate      (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: second point x coordinate       (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: second point y coordinate     (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        // TODO: implement hor. line and ver. line subroutines?

        // Convert game y coordinates to screen y coordinates
        mov     x19, (SCREEN_HEIGH - 1)
        sub     x1, x19, x1
        sub     x3, x19, x3


        subs    x19, x2, x0                     // x19 = dx = x1 - x0
        b.ge    draw_line__end_abs_dx
        sub     x19, xzr, x19                   // dx = -dx
draw_line__end_abs_dx:
        /* x19 = |x1 - x0| = |dx| */


        subs    x20, x3, x1                     // x20 = dy = y1 - y0
        b.ge    draw_line__end_abs_dy
        sub     x20, xzr, x20                   // dy = -dy
draw_line__end_abs_dy:
        /* x20 = |y1 - y0| = |dy| */


        cmp     x20, x19                  // (|y1 - y0| < |x1 - x0|)?  (is line low slope?)
        b.le    draw_line__case_low_slope
        b.gt    draw_line__case_high_slope



draw_line__case_low_slope:
        cmp     x0, x2          // x0 <= x1 ?
        b.gt    draw_line__case_low_slope_invert

        bl      draw_line_low_slope
        b       draw_line__end

draw_line__case_low_slope_invert:
        mov     x19, x0
        mov     x0, x2
        mov     x2, x19
        mov     x19, x1
        mov     x1, x3
        mov     x3, x19
        bl      draw_line_low_slope
        b       draw_line__end



draw_line__case_high_slope:
        cmp     x1, x3          // y0 <= y1 ?
        b.gt    draw_line__case_high_slope_invert

        bl      draw_line_high_slope
        b       draw_line__end

draw_line__case_high_slope_invert:
        mov     x19, x0
        mov     x0, x2
        mov     x2, x19
        mov     x19, x1
        mov     x1, x3
        mov     x3, x19
        bl      draw_line_high_slope
        b       draw_line__end


draw_line__end:
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 32
        ret


/*
 * Params:
 *      x0: left point x coordinate            (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: left point y coordinate          (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: right point x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: right point y coordinate         (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line_low_slope:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]


        mov     x19, SCREEN_WIDTH               // x19 = screen width
        mul     x19, x19, x1                    // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['line's leftmost pixel']



        sub     x19, x2, x0                     // x19 = dx = x1 - x0
        sub     x20, x3, x1                     // x20 = dy = y1 - y0
        mov     x22, 1                          // x22 = yi = 1 (assume dy >= 0)
        mov     x23, SCREEN_WIDTH
        lsl     x23, x23, BYTES_PER_PIXEL_SHIFT // x23 = "fi" = offset in bytes between two consecutive rows


        cmp     x20, 0                          // dy < 0 ?
        b.ge    draw_line_low_slope__nneg_dy    // continue if dy >= 0
        sub     x20, xzr, x20                   // dy = -dy
        sub     x22, xzr, x22                   // yi = -yi TODO: remove? (unused)
        sub     x23, xzr, x23                   // fi = -fi
draw_line_low_slope__nneg_dy:


        lsl     x21, x20, 1     // x21 = 2*dy
        sub     x21, x21, x19   // x21 = 2*dy - dx = D

        lsl     x24, x19, 1      // x24 = 2*dx
        lsl     x25, x20, 1      // x25 = 2*dy

        mov     x26, x0         // x26 = x
        mov     x27, x1         // x27 = y (unused)


draw_line_low_slope__next_col:
        str     w5, [x4]                        // Paint pixel at (x,y)
        add     x4, x4, BYTES_PER_PIXEL         // Move framebuffer one pixel right

        cmp     x21, 0                          // D > 0 ?
        b.le    draw_line_low_slope__keep_y     // if D <= 0 then stay in the same row
        add     x27, x27, x22                   // y = y + yi
        sub     x21, x21, x24                   // D = D - 2*dx
        add     x4, x4, x23                     // f = f + fi   move framebuffer by fi (+/- one row)
draw_line_low_slope__keep_y:

        add     x21, x21, x25           // D = D + 2*dy
        add     x26, x26, 1             // x = x + 1
        // Check if we finished drawing line
        cmp     x26, x2                 // x <= x1?
        b.le    draw_line_low_slope__next_col



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret



/*
 * Params:
 *      x0: top point screen x coordinate           (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: top point screen y coordinate            (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x2: bottom point screen x coordinate        (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: bottom point screen y coordinate         (top) 0 <= y < SCREEN_HEIGHT (bottom)
 *      x4: beginning of framebuffer
 *      w5: color
 */
draw_line_high_slope:
        stp     lr, x19, [sp, -80]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]
        stp     x26, x27, [sp, 64]

        mov     x19, SCREEN_WIDTH               // x19 = screen width
        mul     x19, x19, x1                    // x19 = initial vertical offset
        add     x19, x19, x0                    // x19 = initial vertical offset + initial horizontal offset
        lsl     x19, x19, BYTES_PER_PIXEL_SHIFT // x19 = total offset
        add     x4, x4, x19                     // x4 = &framebuffer['line's topmost pixel']



        sub     x19, x2, x0                     // x19 = dx = x1 - x0
        sub     x20, x3, x1                     // x20 = dy = y1 - y0
        mov     x22, 1                          // x22 = xi = 1 (assume dx >= 0)
        mov     x23, BYTES_PER_PIXEL            // x23 = "fi" = how much to move framebuffer when moving to the next column


        cmp     x19, 0                          // dx < 0 ?
        b.ge    draw_line_high_slope__nneg_dx   // continue if dx >= 0
        sub     x19, xzr, x19                   // dx = -dx
        sub     x22, xzr, x22                   // xi = -xi TODO: remove? (unused)
        sub     x23, xzr, x23                   // fi = -fi
draw_line_high_slope__nneg_dx:


        lsl     x21, x19, 1     // x21 = 2*dx
        sub     x21, x21, x20   // x21 = 2*dx - dy = D

        lsl     x24, x19, 1      // x24 = 2*dx
        lsl     x25, x20, 1      // x25 = 2*dy

        mov     x27, x1         // x27 = y = y0
        mov     x26, x0         // x26 = x = x0 (unused)


draw_line_high_slope__next_row:
        str     w5, [x4]                        // Paint pixel at (x,y)
        add     x4, x4, BYTES_PER_SCREEN_ROW    // Move framebuffer one row down

        cmp     x21, 0                          // D > 0 ?
        b.le    draw_line_high_slope__keep_x    // if D <= 0 then stay in the same column
        add     x26, x26, x22                   // x = x + xi
        sub     x21, x21, x25                   // D = D - 2*dy
        add     x4, x4, x23                     // f = f + fi   move framebuffer by fi (+/- one column)
draw_line_high_slope__keep_x:

        add     x21, x21, x24           // D = D + 2*dx
        add     x27, x27, 1             // y = y + 1
        // Check if we finished drawing line
        cmp     x27, x3                 // y <= y1 ?
        b.le    draw_line_high_slope__next_row



        ldp     x26, x27, [sp, 64]
        ldp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 80
        ret
