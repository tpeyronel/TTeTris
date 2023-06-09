	.include "./constants.s"
	.include "./rectangle.s"
	.include "./tetris_cell.s"


        .equ MOVEMENT_PER_STEP,         20

        .equ SQUARE_SIZE,               20

		.equ DESTROY_PARTICLE_RADIUS,	10

        .equ BOARD_WIDTH,               10
        .equ BOARD_HEIGHT,              20
        .equ BOARD_SIZE,                BOARD_WIDTH * BOARD_HEIGHT
        .equ BOARD_SIZE_IN_BYTES,       BOARD_SIZE * 1


        .equ TETROMINO_ID_BIAS,                 1


        .equ MS_PER_TICK,               50
        .equ US_PER_TICK,               MS_PER_TICK * 1000
        .equ BACK_BUFFER_ADDRESS,       0x1000000

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
        .equ MS_PER_DROP,               500
        .equ US_PER_AUTO_DROP,          MS_PER_DROP * 1000

        BG_COLORS: .word 0x00FF0000, 0x000FF000, 0x0000FF00, 0x00000FF0, 0x000000FF, 0x00F0000F
        BG_COLOR: .dword 0xFFFFFFFF
        PLAYER_COLOR: .dword 0xFFFFFFFF

	.globl main
/* enum CollisionResult */
        .equ COLLISION_RESULT_NO_COLLISION,     0b00
        .equ COLLISION_RESULT_OUT_OF_BOUNDS,    0b01
        .equ COLLISION_RESULT_EXISTING_BLOCK,   0b10

/* struct GameState */
        .equ LAST_DROP,                 0                                       // u32
        .equ GAME_STATS,                LAST_DROP + 4
        .equ INPUT_STATE,               GAME_STATS + STRUCT_GS_SIZE             // struct InputState
        .equ TETROMINO_STATE,           INPUT_STATE + STRUCT_INPUT_STATE_SIZE   // struct TetrominoState
        .equ BOARD_STATE,               TETROMINO_STATE + STRUCT_TSTATE_SIZE    // struct BoardState      
        
        .equ STRUCT_GAME_STATE_SIZE,    BOARD_STATE + STRUCT_BSTATE_SIZE

/* struct GameStats */
        .equ GS_SCORE,                  0                       // u64
        .equ GS_COMPLETED_ROWS,         GS_SCORE + 8            // u64

        .equ STRUCT_GS_SIZE,            GS_COMPLETED_ROWS + 8 

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
        .equ BSTATE_BOARD,              0                                       // u8[22][10] = u8[BOARD_HEIGHT][BOARD_WIDTH]
	.equ BSTATE_DESTROYED_ROWS,	BSTATE_BOARD + BOARD_SIZE_IN_BYTES	// u8[4]

        .equ STRUCT_BSTATE_SIZE,        BSTATE_DESTROYED_ROWS + 4



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
	sub     sp, sp, 8
	str     x0, [sp]        // Save framebuffer to stack

	ldr     x28, =BACK_BUFFER_ADDRESS

	// Allocate struct GameState
	sub     sp, sp, STRUCT_GAME_STATE_SIZE
	// TODO: implement init_game_state subroutine
	add     x0, sp, INPUT_STATE
	bl      init_input_state
	add     x0, sp, TETROMINO_STATE
	bl      init_tetromino_state
	add x0, sp, BOARD_STATE
	bl init_board_state


	mov x0, 0
	mov x1, 0
	mov x2, SCREEN_WIDTH-1
	mov x3, SCREEN_HEIGH-1
	mov x4, x28
	mov x5, 0xFFFFFF
	bl draw_filled_rectangle


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
    sturb w1, [x0, 24]
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
        sturb w1, [x0, 10]
        sturb w1, [x0, 11]

	add x0, sp, TETROMINO_STATE
	mov x1, 4
	stur x1, [x0, TSTATE_ID]
	mov x1, 7
	stur x1, [x0, TSTATE_POS_X]
	mov x1, 14
	stur x1, [x0, TSTATE_POS_Y]
	mov x1, 1
	stur x1, [x0, TSTATE_ROT]

	bl get_time
	stur w0, [sp, LAST_DROP]

	/*
inf:
	mov x0, 0
	mov x1, 0

	ldr x2, =TETROMINOS	

	mov x3, x28
	bl draw_tetris_cell

	mov     x0, x28
	ldr     x1, [sp, STRUCT_GAME_STATE_SIZE]        // restore original framebuffer address from stack
	bl      copy_framebuffer
	b inf
	*/

justfall2:
	mov x0, sp
	mov x1, x28
	bl draw_board

justfall:
	mov x0, sp
	bl tetromino_fall
	mov x21, x0

	cbnz x0, newTetro

	mov x0, x28
	bl erase_destroy_particles

	mov x0, sp
	mov x1, x28
	bl draw_destroy_particles

	mov x0, sp
	mov x1, x28
	bl draw_board

	mov     x0, x28
	ldr     x1, [sp, STRUCT_GAME_STATE_SIZE]    // restore original framebuffer address from stack
	bl      copy_framebuffer

	add x0, sp, INPUT_STATE
	bl read_input   // Constantly read input

	add x0, sp, INPUT_STATE
	add x1, sp, TETROMINO_STATE
	add x2, sp, BOARD_STATE
	bl process_input

	b justfall

newTetro:
	add x0, sp, TETROMINO_STATE
	mov x1, 3
	stur x1, [x0, TSTATE_ID]
	mov x1, 4
	stur x1, [x0, TSTATE_POS_X]
	mov x1, 16
	stur x1, [x0, TSTATE_POS_Y]
	mov x1, 2
	stur x1, [x0, TSTATE_ROT]

	b justfall2

	b game_over


	
/*
	Params:	
		x0:	u8			<- id of tetromino
	Returns:	
		x0:	u32			<- diffuse color
		x1:	u32			<- specular color
		x2:	u32			<- ambient color
*/
get_tetromino_color:
	mov x1, STRUCT_TETROMINO_SIZE
	mul x0, x0, x1						
	ldr x2, =TETROMINOS
	add x2, x0, x2					// x0 = TETROMINOS + STRUCT_TETROMINO_SIZE*id

	ldur w0, [x2, TETROMINO_DIFFUSE_COLOR]
	ldur w1, [x2, TETROMINO_SPECULAR_COLOR]
	ldur w2, [x2, TETROMINO_AMBIENT_COLOR]
	br lr

/*
 * Params:
 *      x0: in struct TetrominoState*
 * Returns:
 *	x0: in struct TetrominoData* -> matrix of tetromino
 *	x1: i64                      -> pos x	
 *	x2: i64                      -> pos y
 *	x3: u32                      -> color
 */
get_tetromino:	
	mov x4, x0
	
	ldur x5, [x4, TSTATE_ID]			
	mov x1, STRUCT_TETROMINO_SIZE
	mul x5, x5, x1						
	ldr x6, =TETROMINOS
	add x5, x5, x6				// x5 = TETROMINOS + STRUCT_TETROMINO_SIZE*id

	ldur x6, [x4, TSTATE_ROT]
	mov x0, STRUCT_TDATA_SIZE
	mul x0, x0, x6
	add x0, x0, TETROMINO_ROTS
	add x0, x0, x5				// x0 = x5 + TETROMINO_ROTS + STRUCT_TDATA_SIZE*TSTATE_ROT

	ldur x1, [x4, TSTATE_POS_X]

	ldur x2, [x4, TSTATE_POS_Y]

	ldur w3, [x5, TETROMINO_SPECULAR_COLOR]

	br lr


/*
 * Params:
 *      x0: out struct GameState*       <- game_state
 */
init_game_state:
        stp     lr, x19, [sp, -16]!

        mov     x19, x0                 // x19 <- game_state

        bl      get_time
        str     w0, [x19, LAST_DROP]

        add     x0, x19, INPUT_STATE
        bl      init_input_state

        add     x0, x19, TETROMINO_STATE
        bl      init_tetromino_state

	add	x0, x19, BOARD_STATE
	bl	init_board_state

        ldp     lr, x19, [sp], 16
        ret


/*  params:
 *	  x0: u8[BOARD_WIDTH][BOARD_HEIGHT]			-> address of board
 *    x1: u8									-> line to erase
 *  functionality:
 *    eliminates everything on the line
 */
erase_board_line:
    sub sp, sp, 8
    stur lr, [sp]

    movz x2, 0   // black
    mov x6, BOARD_WIDTH
    mul x6, x6, x1
    add x6, x0, x6  // x6 points to the first element of the line x8

    mov x11, BOARD_WIDTH
erase_board_line_turn_squares_off:
    sturb w2, [x6]
    add x6, x6, 1
    sub x11, x11, 1
    cbnz x11, erase_board_line_turn_squares_off

    ldur lr, [sp]
    add sp, sp, 8

    br lr

/*  params
 *	  x0: u8[BOARD_WIDTH][BOARD_HEIGHT]			-> address of board
 *        x1: u8						-> line from which lines will start to fall
 *  functionality
 *    lowers by 1 block all the elements on the grid avobe line at height x1
 */
fall_one_block:
    sub sp, sp, 8
    stur lr, [sp]
    mov x7, BOARD_SIZE

    mov x15, BOARD_WIDTH
    mul x15, x15, x1
    add x15, x15, x0    // starts at first square from desired line x8

keepgoing:
    add x5, x15, 10

    ldur x2, [x5]         // get info from square avobe
    sturb w2, [x15]       // replace current square with new info

    add x15, x15, 1       // move on to the next square (-->)

    sub x5, x5, x0
    cmp x5, BOARD_SIZE-1
    bne keepgoing         // stop before reaching top line of grid (x15 at square #189, x5 at #199)
    
    mov x1, 19
    bl erase_board_line   // Erase anything on top line

    ldur lr, [sp]
    add sp, sp, 8

    br lr



/*
	Params:
		x0: in/out u8[BOARD_WIDTH][BOARD_HEIGHT]	
 */
init_board_state:	
	sub sp, sp, 8
	stur x19, [sp]
	
	mov x19, x0
	
	add x0, x19, BSTATE_BOARD
    mov x2, BOARD_SIZE_IN_BYTES
    create_grid_loop:
    sturb wzr, [x0]
    add x0, x0, 1
    sub x2, x2, 1
    cbz x2, create_grid_end
    b create_grid_loop

create_grid_end:	
	mov x2, 4
	add x0, x19, BSTATE_DESTROYED_ROWS
	movz x3, 0x00ff, lsl 00
init_board_state__destroyed_rows_loop:	
	sturb w3, [x0]
	add x0, x0, 1
	sub x2, x2, 1
	cbz x2, init_board_state__end
	b init_board_state__destroyed_rows_loop

init_board_state__end:	
	ldur x19, [sp]
	add sp, sp, 8
    br lr

/*
	Params:
		mut x0: struct GameState*
		mut x1: framebuffer address
	
 */
draw_board:
	sub sp, sp, 48
	stur lr, [sp]
	stur x19, [sp, 8]
	stur x20, [sp, 16]
	stur x21, [sp, 24]
	stur x22, [sp, 32]
	stur x23, [sp, 40]

	mov x23, x0

    add x9, x0, (BOARD_STATE + BSTATE_BOARD)

    mov x11, x1

	add x0, x0, TETROMINO_STATE
	bl get_tetromino
	mov x19, x0			// x19 -> tetromino matrix
	mov x20, x1			// x20 -> tetromino x pos
	mov x21, x2			// x21 -> tetromino y pos
	mov x22, x3			// x22 -> tetromino color
	


    mov x14, 0             // row iterator
    draw_board_outer:
    mov x15, 0             // column iterator
    draw_board_inner:

	cmp x15, x20
	b.lt draw_board_not_tetromino

	add x12, x20, (TETROMINO_BOARD_WIDTH-1)
	cmp x15, x12
	b.gt draw_board_not_tetromino

	cmp x14, x21
	b.lt draw_board_not_tetromino

	add x12, x21, (TETROMINO_BOARD_WIDTH-1)
	cmp x14, x12
	b.gt draw_board_not_tetromino
	// if I got here, then I'm currently on a square of the tetromino
	sub x0, x15, x20
	sub x1, x14, x21

	mov x4, TETROMINO_BOARD_WIDTH
	mul x1, x1, x4

	add x0, x0, x1

	add x0, x0, x19

	ldurb w1, [x0]

	cbz x1, draw_board_not_tetromino		// draw whatever there is in the board
	ldur x12, [x23, TETROMINO_STATE + TSTATE_ID]
	b draw_board__draw_tetris_cell


draw_board_not_tetromino:	
	ldurb w12, [x9]		
    mov x4, 0
    cbz x12, draw_board_no_square

    sub x12, x12, TETROMINO_ID_BIAS

	/*
	mov x0, x12
    bl get_tetromino_color
	mov x4, x0
	*/

draw_board__draw_tetris_cell:	
    mov x0, x15
    mov x1, x14
    mov x2, SQUARE_SIZE
	mul x0, x0, x2
	add x0, x0, ( (SCREEN_WIDTH - BOARD_WIDTH * SQUARE_SIZE) / 2 )
	mul x1, x1, x2
	add x1, x1, ( (SCREEN_HEIGH - BOARD_HEIGHT * SQUARE_SIZE) / 2 )

	mov x2, x12
	mov x3, STRUCT_TETROMINO_SIZE
	mul x2, x2, x3
	ldr x3, =TETROMINOS
	add x2, x2, x3

	mov x3, x11

	sub sp, sp, 48
	stur x11, [sp]
	stur x12, [sp, 8]
	stur x13, [sp, 16]
	stur x14, [sp, 24]
	stur x15, [sp, 32]
	stur x9, [sp, 40]
	
	bl draw_tetris_cell

	ldur x11, [sp]
	ldur x12, [sp, 8]
	ldur x13, [sp, 16]
	ldur x14, [sp, 24]
	ldur x15, [sp, 32]
	ldur x9, [sp, 40]
	add sp, sp, 48

	b draw_board__finished_tetris_cell

    draw_board_no_square:    // draw bakcground
    mov x0, x15
    mov x1, x14
    mov x2, SQUARE_SIZE
	mul x0, x0, x2
	add x0, x0, ( (SCREEN_WIDTH - BOARD_WIDTH * SQUARE_SIZE) / 2 )
	mul x1, x1, x2
	add x1, x1, ( (SCREEN_HEIGH - BOARD_HEIGHT * SQUARE_SIZE) / 2 )
	mov x3, x11
	
	bl draw_filled_square

draw_board__finished_tetris_cell:	
    add x15, x15, 1
    add x9, x9, 1
	cmp x15, BOARD_WIDTH
    b.lt draw_board_inner

    add x14, x14, 1
	cmp x14, BOARD_HEIGHT
	b.eq draw_board_end

    b draw_board_outer

    draw_board_end:


	ldur lr, [sp]
	ldur x19, [sp, 8]
	ldur x20, [sp, 16]
	ldur x21, [sp, 24]
	ldur x22, [sp, 32]
	ldur x23, [sp, 40]

    add sp, sp, 48

    br lr
/*
 * Params:
 *      x0: struct GameState*
 */
tetromino_fall:
	sub sp, sp, 56
	stur lr, [sp]
	stur x19, [sp, 8]
	stur x20, [sp, 16]
	stur x21, [sp, 24]
	stur x22, [sp, 32]
	stur x24, [sp, 40]
	stur x25, [sp, 48]

	mov x19, x0

	ldur    w0, [x19, LAST_DROP]      // w0 = last time tetromino moved
	bl      get_elapsed_time          // Sets w0, w1

	ldr     x9, =US_PER_AUTO_DROP
	cmp     x0, x9                         // Check time to see if tetromino should fall
	b.lt    tetromino_fall__end

	stur x1, [x19, LAST_DROP]      // update LAST_DROP with LAST ATTEMPTED DROP time.

	// am, destruir las partículas que haya
	sub sp, sp, 16
	stur x0, [sp]	
	stur x1, [sp, 8]	
	mov x0, x19
	bl update_destroy_particles
	ldur x0, [sp]
	ldur x1, [sp, 8]	
	add sp, sp, 16

	// Try to drop tetromino 1 block. Don't move if not possible.
	add x0, x19, TETROMINO_STATE 
	add x1, x19, BOARD_STATE
	bl try_drop_tetromino

	cbnz x0, tetromino_fall__end

	// Try to integrate tetromino with board, if not possible, then GAME OVER.
	add x0, x19, TETROMINO_STATE
	add x1, x19, BOARD_STATE
	bl try_place_tetromino

	// Check full lines and update board matrix. 
	add x0, x19, BOARD_STATE
	add x1, x19, (TETROMINO_STATE + TSTATE_POS_Y)
	ldur x1, [x1]                                  // x1 = posY of tetromino
	bl update_board

	mov x0, 1
	b tetromino_fall__fullend
        // Spawn new Tetromino at the top.
        // TO-DO MARAS

tetromino_fall__end:
        mov x0, 0
tetromino_fall__fullend:
	ldur lr, [sp]
	ldur x19, [sp, 8]
	ldur x20, [sp, 16]
	ldur x21, [sp, 24]
	ldur x22, [sp, 32]
        ldur x24, [sp, 40]
        ldur x25, [sp, 48]

        add sp, sp, 56

        br lr

/* erases destroy particles
	Params:
		x0:	 framebuffer
*/
erase_destroy_particles:	
	sub sp, sp, 8
	stur lr, [sp]
	
	mov x0, 0
	mov x1, 0
	mov x2, ( (SCREEN_WIDTH - BOARD_WIDTH * SQUARE_SIZE) / 2 )
	mov x3, SCREEN_HEIGH-1
	mov x4, x28
	mov x5, 0xFFFFFF
	bl draw_filled_rectangle
	
	mov x0, ( (SCREEN_WIDTH - BOARD_WIDTH * SQUARE_SIZE) / 2 )
	mov x1, SCREEN_WIDTH
	sub x0, x1, x0
	mov x1, 0
	mov x2, SCREEN_WIDTH-1
	mov x3, SCREEN_HEIGH-1
	mov x4, x28
	mov x5, 0xFFFFFF
	bl draw_filled_rectangle

	ldur lr, [sp]
	add sp, sp, 8

	br lr

/*
	Params:
		x0:	in/out struct BoardState*
		x1:	i64							<- tetromino y position
	Returns:	
		x0:	u64							<- number of rows removed
*/
update_board:	
	sub sp, sp, 8
	stur lr, [sp]

	mov x9, x0
	mov x10, 0

	mov x2, 4
	add x0, x9, BSTATE_DESTROYED_ROWS
	movz x3, 0x00ff, lsl 00
update_board__reset_destroyed:
	sturb w3, [x0]
	add x0, x0, 1
	sub x2, x2, 1
	cbz x2, update_board__reset_destroyed

	// x0 = max(x1, 0)
	cmp x1, 0
	b.lt update_board__max_branch0
	mov x0, x1
	b update_board__next_row

update_board__max_branch0:	
	mov x0, 0

	// x0 is the row i'm currently checking
update_board__next_row:	
	add x2, x1, TETROMINO_BOARD_WIDTH
	cmp x0, x2
	b.ge update_board__end

	mov x2, BOARD_WIDTH
	mul x2, x0, x2
	add x2, x2, x9			// x2 points to first element of current row
	
	mov x3, 0

update_board__next_elem:	
	add x5, x2, x3
	ldurb w4, [x5]	// x4 is element of board

	cbz x4, update_board__row_not_complete

	add x3, x3, 1
	cmp x3, BOARD_WIDTH
	b.eq update_board__row_complete
	b update_board__next_elem

update_board__row_complete:
	add x6, x9, x10
	add x7, x0, x10
	sturb w7, [x6, BSTATE_DESTROYED_ROWS]
	
	add x10, x10, 1

	sub sp, sp, 32
	stur x0, [sp]
	stur x1, [sp, 8]
	stur x9, [sp, 16]
	stur x10, [sp, 24]

	mov x1, x0
	mov x0, x9

	bl erase_board_line

	ldur x1, [sp]
	ldur x0, [sp, 16]

	bl fall_one_block	

	ldur x0, [sp]
	ldur x1, [sp, 8]
	ldur x9, [sp, 16]
	ldur x10, [sp, 24]
	add sp, sp, 32

	sub x1, x1, 1
	b update_board__next_row

update_board__row_not_complete:	
	add x0, x0, 1
	b update_board__next_row

update_board__end:
	ldur lr, [sp]
	add sp, sp, 8

	mov x0, x10
	
	br lr


// Tries to move tetromino one position down.
/*
 * Params:
 *      x0: in/out struct TetrominoState*
 *      x1: in struct BoardState*
 * Returns:
 *      x0: bool
 */
try_drop_tetromino:
	sub sp, sp, 24
	stur lr, [sp]
	stur x20, [sp, 8]
        stur x19, [sp, 16]

        mov x20, x0

        ldur x9, [x20, TSTATE_POS_Y]
        sub x9, x9, 1                       // new TSTATE_POS_Y = previous TSTATE_POS_Y - 1
        stur x9, [x20, TSTATE_POS_Y]

        // check if tetromino is colliding
        bl check_collision
        cbz x0, try_drop_tetromino__success
        b try_drop_tetromino__failure

try_drop_tetromino__success:
        mov x0, 1
        b try_drop_tetromino__end


try_drop_tetromino__failure:
        ldur x9, [x20, TSTATE_POS_Y]
        add x9, x9, 1                       // new TSTATE_POS_Y = previous TSTATE_POS_Y + 1 = original TSTATE_POS_Y
        stur x9, [x20, TSTATE_POS_Y]

        mov x0, 0
        b try_drop_tetromino__end

try_drop_tetromino__end:
        // go back to tetromino_fall to try to place it on the board.
	ldur lr, [sp]
	ldur x20, [sp, 8]
        ldur x19, [sp, 16]
	add sp, sp, 24
        br lr

// Tries to place tetromino in its current position. Does it if possible, GAME OVER if not.
// INTENDED USE: COLLISION CHECK POSITIVE & PLACE TETROMINO NEGATIVE => GAME OVER
//               COLLISION CHECK POSITIVE & PLACE TETROMINO => SELECT NEXT TETROMINO TO DROP
/*
 * Params:
 *      x0: in struct TetrominoState*
 *      x1: in/out struct BoardState*
 * Returns:
 *      x0: bool
 */
try_place_tetromino:
	sub sp, sp, 64
	stur lr, [sp]
	stur x19, [sp, 8]
	stur x20, [sp, 16]
	stur x21, [sp, 24]
	stur x22, [sp, 32]
        stur x23, [sp, 40]
        stur x24, [sp, 48]
        stur x25, [sp, 56]

        mov x21, x0
        mov x20, x1

        bl check_collision
        cbnz x0, game_over  //??

        mov x0, x21
        bl get_tetromino 
/*	CURRENT KNOWN DATA
 *      x0: in struct TetrominoData* -> matrix of tetromino
 *	x1: i64                      -> pos x	
 *	x2: i64                      -> pos y
 *	x3: u32                      -> color
*/
        add x26, x0, TETROMINO_BOARD_SIZE

        mov x3, BOARD_WIDTH
        mul x3, x2, x3
        add x3, x3, x1

        add x3, x3, x20  // x3 = Board[x][y]*

        ldur x27, [x21, TSTATE_ID]
        add x27, x27, TETROMINO_ID_BIAS

        mov x4, 0
        // place tetromino on board.
        b try_place_tetromino__loop

try_place_tetromino__bigloop:
        add x3, x3, (BOARD_WIDTH-TETROMINO_BOARD_WIDTH)  // Jump to next Tetromino Matrix's Line.
        mov x4, 0
try_place_tetromino__loop:
        ldurb w22, [x0]

        cmp x22, 0
        b.eq try_place_tetromino__next_cell  // If Tetromino's cell is empty, move on.

        sturb w27, [x3]   // else, place full Tetromino Matrix's cell into it's corresponding BoardState position.

try_place_tetromino__next_cell: 
        add x0, x0, 1        // move to next Tetromino Matrix cell.
        add x3, x3, 1        // move to next board cell.
        add x4, x4, 1        // increase count per line.

        cmp x0, x26
        b.eq try_place_tetromino__end  // If x0 reached the end, then game IS NOT over and BoardState IS Updated.

        cmp x4, 4    // if tetromino matrix line is done, jump to next line.
        b.eq try_place_tetromino__bigloop

        b try_place_tetromino__loop

try_place_tetromino__end:
        mov x0, 1
	ldur lr, [sp]
	ldur x19, [sp, 8]
	ldur x20, [sp, 16]
	ldur x21, [sp, 24]
	ldur x22, [sp, 32]
        ldur x23, [sp, 40]
        ldur x24, [sp, 48]
        ldur x25, [sp, 56]

    add sp, sp, 64

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
 *      x0: bottom left x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x1: bottom left y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x2: top right x coordinate         (left) 0 <= x < SCREEN_WIDTH (right)
 *      x3: top right y coordinate       (bottom) 0 <= y < SCREEN_HEIGHT (top)
 *      x4: beginning of framebuffer
 *      w5: color
 */


/*
 * Params:
 *      x0: in struct TetrominoState*   <- tetromino_state
 *      x1: in struct BoardState*       <- board_state
 * Returns:
 *      x0: enum CollisionResult        <- collision_result
 */
check_collision:
        stp     lr, x19, [sp, -64]!
        stp     x20, x21, [sp, 16]
        stp     x22, x23, [sp, 32]
        stp     x24, x25, [sp, 48]

        mov x25, x1

        bl get_tetromino
/*       CURRENT INFO:
 *	x0: in struct TetrominoData* -> matrix of tetromino
 *	x1: i64                      -> pos x	
 *	x2: i64                      -> pos y
 *	x3: u32                      -> color
 */
        mov x24, 0
        add x26, x0, TETROMINO_BOARD_SIZE

        mov x22, BOARD_WIDTH
        mul x22, x2, x22
        add x22, x22, x1

        add x22, x22, x25  // x22 = Board[x][y]

        // Check overlap.
        b check_collision__loop

check_collision__bigloop:
        add x22, x22, (BOARD_WIDTH-TETROMINO_BOARD_WIDTH)  // Jump to next Tetromino Matrix's Line.
        mov x24, 0
check_collision__loop:
        ldurb w19, [x0]
        cmp x19, 0             // If Tetromino Matrix's cell IS empty, move on.
        b.eq check_collision__next_cell

        ldurb w23, [x22]
        cmp x23, 0
        b.eq check_collision__next_cell  // If Tetromino Matrix's cell IS NOT empty but grid's cell IS available, move on.

        mov x0, 1         // If grid cell IS NOT available && Tetromino Matrix's cell IS NOT empty, then there IS collision.
        b check_collision__badending

check_collision__next_cell: 
        add x0, x0, 1        // move to next Tetromino Matrix cell.
        add x22, x22, 1      // move to next board cell.
        add x24, x24, 1      // increase count per line.

        cmp x0, x26
        b.eq check_collision__end     // If x0 reached the end, then there was NO collision.

        cmp x24, 4    // if tetromino matrix line is done, jump to next line.
        b.eq check_collision__bigloop

        b check_collision__loop

check_collision__end:
        mov x0, 0
check_collision__badending:
        stp     x24, x25, [sp, 48]
        ldp     x22, x23, [sp, 32]
        ldp     x20, x21, [sp, 16]
        ldp     lr, x19, [sp], 64
        ret


/*
 * Params:
 *      x0: struct GameState*
 *		x1: framebuffer	
 */
draw_destroy_particles:
	sub sp, sp, 56
	stur lr, [sp]
	stur x19, [sp, 8]
	stur x20, [sp, 16]
	stur x21, [sp, 24]
	stur x22, [sp, 32]
	stur x23, [sp, 40]
	stur x24, [sp, 48]

	add x19, x0, (BOARD_STATE + BSTATE_DESTROYED_ROWS)
	mov x24, x0

	add x0, x0, LAST_DROP
	ldur x0, [x0]
	mov x20, x0

	mov x21, ( (SCREEN_WIDTH - BOARD_WIDTH * SQUARE_SIZE) / 2 )
	sub x21, x21, SQUARE_SIZE
	
	mov x22, ( (SQUARE_SIZE + SCREEN_HEIGH - BOARD_HEIGHT * SQUARE_SIZE) / 2 )

	mov x23, x1

	mov x2, 4

draw_destroy_particles__loop:	
	ldurb w3, [x19]

	cmp x3, 0xff
	b.eq draw_destroy_particles__end

	sub sp, sp, 8
	stur x2, [sp]

	mov x0, x20
	bl get_elapsed_time
	lsl x0, x0, 5
	ldr w2, =US_PER_AUTO_DROP
	udiv x4, x0, x2
	mov x5, 1
	lsl x5, x5, 5
	sub x5, x5, x4
	mov x0, DESTROY_PARTICLE_RADIUS
	mul x2, x5, x0
	lsr x2, x2, 5
	mov x10, x2

	/*
	cmp x10, 0
	b.le draw_destroy_particles__destroy
	*/

	mov x2, 50
	mul x4, x4, x2
	lsr x4, x4, 5
	mov x11, x4

	
	sub x0, x21, x11
	mov x4, SQUARE_SIZE
	mul x4, x4, x3
	add x1, x22, x4
	mov x4, 0xff0000
	mov x2, x23
	mov x3, x10

	bl draw_circle_at

	mov x0, SCREEN_WIDTH
	sub x0, x0, x21
	add x0, x0, x11
	mov x4, 0xff0000
	mov x3, x10

	bl draw_circle_at

	ldur x2, [sp]
	add sp, sp, 8

	sub x2, x2, 1
	add x19, x19, 1
	cbnz x2, draw_destroy_particles__loop
	b draw_destroy_particles__end

draw_destroy_particles__destroy:	
	/*
	mov x0, x24
	add x0, x0, BOARD_STATE + BSTATE_DESTROYED_ROWS
	movz x1, 0xff, lsl 00
	sturb w1, [x0]
	*/

draw_destroy_particles__end:	
	
	ldur lr, [sp]
	ldur x19, [sp, 8]
	ldur x20, [sp, 16]
	ldur x21, [sp, 24]
	ldur x22, [sp, 32]
	ldur x23, [sp, 40]
	ldur x24, [sp, 48]
	add sp, sp, 56

	br lr

/*
	Params:	
		x0:	struct GameState*
*/	
update_destroy_particles:	
	sub sp, sp, 24
	stur x0, [sp]
	stur x1, [sp, 8]
	stur x2, [sp, 16]

	add x0, x0, ( BOARD_STATE + BSTATE_DESTROYED_ROWS )
	movz x1, 0xff, lsl 00
	mov x2, 4

update_destroy_particles__loop:	
	sturb w1, [x0]
	add x0, x0, 1
	sub x2, x2, 1
	cbnz x2, update_destroy_particles__loop

	ldur x0, [sp]
	ldur x1, [sp, 8]
	ldur x2, [sp, 16]
	add sp, sp, 24

	br lr

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
 *		x2: const struct BoardState*      // Para chequear colision en los handle
 */
process_input:
        stp     lr, x19, [sp, -32]!
        stp     x20, x21, [sp, 16]

        mov     x19, x0         // x19 = const struct InputState*
        mov     x20, x1         // x20 = mut struct TetrominoState*

        ldr     w0, [x19, ON_PRESS_STATE]
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
 *		x2: const struct BoardState*
 */
handle_w:
        stp     lr, x19, [sp, -16]!

	    and     x19, x0, GPIO_W
        cbz     x19, handle_w__end

        ldr     x19, [x1, TSTATE_ROT]

        add     x19, x19, #1
        cmp     x19, 4
        csel    x19, x19, xzr, lt         // Set x19 to zero if it's equal to 4

        str     x19, [x1, TSTATE_ROT]

		mov x0, x1
		mov x1, x2
		bl check_collision
		cbz x0, handle_w__end
        // SI HAY COLISION TRAS ROTAR, REVERTIR LOS CAMBIOS
		sub     x19, x19, #1
        cmp     x19, -1
        csel    x19, x19, xzr, lt         // Set x19 to 4 if it's equal to -1

        str     x19, [x1, TSTATE_ROT]


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
 *		x2: const struct BoardState*
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
 *		x2: const struct BoardState*
 */
handle_d:
        stp     lr, x19, [sp, -16]!

		and     x19, x0, GPIO_D
        cbz     x19, handle_d__end

        ldr     x19, [x1, TSTATE_POS_X]
        cmp     x19, (BOARD_WIDTH - 3)         // Check if player is touching right edge
        b.eq    handle_d__end

        add     x19, x19, 1                     // Move player one position right
        str     x19, [x1, TSTATE_POS_X]

		mov x0, x1
		mov x1, x2
		bl check_collision    
		cbz x0, handle_d__end

        sub     x19, x19, 1                     // Move player one position right
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
 *      x0: in/out struct TetrominoState*
 */
clamp_player_coords:
        /* Clamp x coordinate */
        ldr     x9, [x0, TSTATE_POS_X]

        cmp     x9, 0
        b.ge    clamp_player_coords__end_left
        mov     x9, 0
clamp_player_coords__end_left:

        cmp     x9, (SCREEN_WIDTH - 1)
        b.le    clamp_player_coords__end_right
        mov     x9, (SCREEN_WIDTH - 1)
clamp_player_coords__end_right:

        str     x9, [x0, TSTATE_POS_X]


        /* Clamp y coordinate */
        ldr     x9, [x0, TSTATE_POS_Y]

        cmp     x9, 0
        b.ge    clamp_player_coords__end_bottom
        mov     x9, 0
clamp_player_coords__end_bottom:

        cmp     x9, (SCREEN_HEIGH - 1)
        b.le    clamp_player_coords__end_top
        mov     x9, (SCREEN_HEIGH - 1)
clamp_player_coords__end_top:

        str     x9, [x0, TSTATE_POS_Y]

        ret


/*
 * Returns:
 *      w0: current time
 */
get_time:
        ldr     x0, =SYS_TIMER_VALUE_ADDRESS
        ldr     w0, [x0]
        ret

game_over:
        b game_over
/*
 * Params:
 *      x0: in u32*             <- src framebuffer
 *      x1: out u32*            <- dst framebuffer
 */
copy_framebuffer:
        stp     lr, x19, [sp, -16]!

        mov     x19, SCREEN_WIDTH
        mov     x9, SCREEN_HEIGH
        mul     x19, x19, x9            // x19 = width * height

copy_framebuffer__next_pixel:
        ldr     w9, [x0]
        str     w9, [x1]

        add     x0, x0, BYTES_PER_PIXEL
        add     x1, x1, BYTES_PER_PIXEL
        subs    x19, x19, 1
        b.gt    copy_framebuffer__next_pixel


        ldp     lr, x19, [sp], 16
        ret
