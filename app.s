// Grupo:
// Nieto, Manuel
// Kurtz, Lara
// Rodriguez, Lautaro

.include "utils.s"

.globl main
main:

	// Secondary framebuffer
	adr x1, dir_frameBuffer
	str x0, [x1] // Save the framebuffer memory address in dir_FrameBuffer
	ldr x0, =bufferSecundario // Load the secondary framebuffer base address in x0

	//---------------- CODE HERE ------------------------------------
	bl drawWindow

  	// Floor
	movz x10, 0x55, lsl 16	// grey (floor)
    movk x10, 0x5864, lsl 00	

	mov x1, 0
	mov x2, 3
    mov x3, SCREEN_WIDTH 	// framebuffer width
    mov x4, SCREEN_HEIGH 	// framebuffer height

	udiv x4, x4, x2			// divides the framebuffer height by 3
	add x2, x2, x4
	add x2, x2, x4  		// moves down 2/3 of the framebuffer height
	bl paintRectangle

  	// Furniture
	bl drawFurniture

	// Every single component dimensions of the gameboy are calculated 
	// based on the top-left corner of the display frame (x1, x2) and
	// its dimensions (x3,x4)

	// To readjust the gameboy size, modify the coordinates (x3, x4)
	// Everything will be centered in relation to that rectangle

	// Gameboy's display frame dimensions
	mov x3, 160		// width
	mov x4, 100		// height

	//----------------------ZOOM IN GAMEBOY DISPLAY-------------
	zoomIn:

		// stops when the display frame is 472 pixels tall
		cmp x4, 472
		b.ge endZoomIn

	    mov x13, SCREEN_WIDTH // framebuffer width
	    mov x14, SCREEN_HEIGH // framebuffer height 

	    // center display frame horizontally in the framebuffer
	    sub x13, x13, x3      // substracts display frame width from framebuffer width 
	    lsr x13, x13, 1       // divides it in half
	    mov x1, x13			  // starting x coordinate for the display frame
	
	    // center display frame vertically in the framebuffer
	    sub x14, x14, x4      // substracts base height from framebuffer height 
	    lsr x14, x14, 1       // divides it in half
	    mov x2, x14      	  // starting y coordinate for the display frame

		bl drawCartridge
	    bl drawBase

		// led colour
		movz x11, 0xAD, lsl 16
    	movk x11, 0x0952, lsl 0
		bl drawScreen
		bl drawButtons

		bl actualizarFrameBuffer

		bl delay
		// increment in the display's frame size each time 
		add x3,x3,4
		add x4,x4,4
		b zoomIn


	endZoomIn: 
	//----------------------ZOOM IN GAMEBOY DISPLAY END---------
	
	// turning on the led light
	// led colour
	movz x11, 0xff, lsl 16
    movk x11, 0x160c, lsl 0
	bl drawScreen
	bl actualizarFrameBuffer

	// calculates x coordinate for the display
    mov x5, 8
    udiv x5, x3, x5     // horizontal margin between display and border
    add x1, x1, x5      // moves that amount of pixels right

    // calculates y coordinate for the display
    mov x6, 8
    udiv x6, x4, x6     // vertical margin between display and border
    add x2, x2, x6      // moves that amount of pixels down
	
	// calculates display width
    add x5, x5, x5       // doubles the horizontal margin
    sub x3, x3, x5       // substracts it from border width

    // calculates display height
    add x6, x6, x6       // doubles that distance
    sub x4, x4, x6       // substracts it from border height
 
	// turns on the display
	movz x10, 0x8d, lsl 16
    movk x10, 0xebff, lsl 0// sky color
	bl paintRectangle
	bl delay
	bl delay
	bl delay
	bl delay

	//----------------------ANIMATION------------------------

reset:

	// aux register x21
	mov x21, xzr

	loopAnimationUP:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 180
		b.eq endAnimationUP

		// nubes top left
		mov x15, 165
		mov x16, 90
		add x15, x15, x21
		bl paintCloudTypeOne

		mov x15, 250
		mov x16, 110
		add x15, x15, x21
		bl paintCloudTypeTwo

		// nubes mid right
		mov x15, 350
		mov x16, 250
		sub x15, x15, x21
		bl paintCloudTypeOne

		mov x15, 435
		mov x16, 270
		sub x15, x15, x21
		bl paintCloudTypeTwo

		// nubes bottom mid
		mov x15, 200
		mov x16, 370
		add x15, x15, x21
		bl paintCloudTypeOne

		// Missile
		
		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 6
		mov x15, 480
		mov x16, 170
		sub x15, x15, x21
		add x16, x16, x21
		bl paintMissile

		// plane going up
		movz x18, 0x41, lsl 16
    	movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
    	movk x19, 0x9a75, lsl 0

		mov x17, 1
		mov x15, 320
		mov x16, 340
		sub x16, x16, x21
		bl paintPlane


		bl actualizarFrameBuffer

		bl delaySonic
		add x21, x21, 1
		b loopAnimationUP

	endAnimationUP:

	mov x21, xzr
	loopAnimationTurnAround:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 5
		b.eq endAnimationTurnAround

		// nubes top left
		mov x15, 345
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 430
		mov x16, 110
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 170
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 255
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 380
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne

		// missile

		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 6
		mov x15, 300
		mov x16, 350
		sub x15, x15, x21
		add x16, x16, x21
		bl paintMissile

		// plane turning around to the right
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 1
		add x17, x17, x21
		mov x15, 320
		mov x16, 160
		bl paintPlane


		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationTurnAround
	endAnimationTurnAround:

	mov x21, xzr
	loopAnimationRetreat:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 130
		b.eq endAnimationRetreat

		// nubes top left
		mov x15, 340
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 425
		mov x16, 110
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 175
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 260
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 375
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne

		// missile
		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 6
		mov x15, 295
		mov x16, 355
		sub x15, x15, x21
		add x16, x16, x21
		cmp x16, 435
		b.gt deleteMissile
		bl paintMissile

		deleteMissile:
		// plane going down
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 5
		mov x15, 320
		mov x16, 160
		add x16, x16, x21
		bl paintPlane


		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationRetreat

	endAnimationRetreat:

	mov x21, xzr
	loopAnimationDVDCorner:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 50
		b.eq endAnimationDVDCorner

		// nubes top left
		mov x15, 211	//fix nube toca borde
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 296	//fix nube toca borde
		mov x16, 110	
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 305
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 390
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 245
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne


		// plane going down
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 6
		mov x15, 320
		mov x16, 290

		sub x15, x15, x21
		add x16, x16, x21

		bl paintPlane


		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationDVDCorner


	endAnimationDVDCorner:

	mov x21, xzr
	loopAnimationOoosoo:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 4
		b.eq endAnimationOoosoo

		// nubes top left
		mov x15, 163	//fix nube toca borde
		mov x16, 90
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 248	//fix nube toca borde
		mov x16, 110
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 355
		mov x16, 250
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 440
		mov x16, 270
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 195
		mov x16, 370
		add x15, x15, x21
		bl paintCloudTypeOne

		mov x17, 6
		add x17, x17, x21
		cmp x17, 9
		b.lt skip
		mov x17, 1
		skip:

		// plane turning around until it faces north
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x15, 270
		mov x16, 340

		sub x15, x15, x21

		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		bl delay
		add x21, x21, 1
		b loopAnimationOoosoo

	endAnimationOoosoo:

	mov x21, xzr
	loopAnimationUP2:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 150
		b.eq endAnimationUP2

		// nubes top left
		mov x15, 167
		mov x16, 90
		add x15, x15, x21
		bl paintCloudTypeOne

		mov x15, 252
		mov x16, 110
		add x15, x15, x21
		bl paintCloudTypeTwo

		// nubes mid right
		mov x15, 351
		mov x16, 250
		sub x15, x15, x21
		bl paintCloudTypeOne

		mov x15, 436
		mov x16, 270
		sub x15, x15, x21
		bl paintCloudTypeTwo

		// nubes bottom mid
		mov x15, 199
		mov x16, 370
		add x15, x15, x21
		bl paintCloudTypeOne
		
		cmp x21, 130
		b.lt doNotPaintMissile

		// missile
		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 2
		mov x15, 20
		mov x16, 300
		add x15, x15, x21
		sub x16, x16, x21
		bl paintMissile

		doNotPaintMissile:
		// plane going up
		movz x18, 0x41, lsl 16
    	movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
    	movk x19, 0x9a75, lsl 0

		mov x17, 1
		mov x15, 266
		mov x16, 344
		sub x16, x16, x21
		bl paintPlane


		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationUP2
	endAnimationUP2:

	mov x21, xzr
	loopAnimationDVDCorner2:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 50
		b.eq endAnimationDVDCorner2

		// nubes top left
		mov x15, 317
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 402
		mov x16, 110	
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 201
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 286
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 349
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne

		// missile
		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 2
		mov x15, 170
		mov x16, 150
		add x15, x15, x21
		sub x16, x16, x21
		bl paintMissile

		// plane diagonal right
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 2
		mov x15, 266
		mov x16, 194

		add x15, x15, x21
		sub x16, x16, x21

		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationDVDCorner2

	endAnimationDVDCorner2: 

	mov x21, xzr
	loopAnimationOoosoo2:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 4
		b.eq endAnimationOoosoo2

		// nubes top left
		mov x15, 267
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 352
		mov x16, 110
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 251
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 336
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 299
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne

		// missile
		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 2
		mov x15, 220
		mov x16, 100
		add x15, x15, x21
		sub x16, x16, x21
		bl paintMissile

		// plane turning around until it faces south

		mov x17, 2
		add x17, x17, x21
		
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x15, 316
		mov x16, 144

		add x15, x15, x21

		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationOoosoo2

	endAnimationOoosoo2: 

	mov x21, xzr
	loopAnimationRetreat2:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 100
		b.eq endAnimationRetreat2

		// nubes top left
		mov x15, 263
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 348
		mov x16, 110
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 255
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 340
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 295
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne
	
		// missile
		cmp x21, 50
		b.gt noMissile
		movz x18, 0xed, lsl 16
    	movk x18, 0xca02, lsl 0 

		mov x17, 2
		mov x15, 224
		mov x16, 96
		add x15, x15, x21
		sub x16, x16, x21
		bl paintMissile

		noMissile:
		// plane going down
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 5
		mov x15, 325
		mov x16, 160
		add x16, x16, x21
		bl paintPlane


		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationRetreat2

	endAnimationRetreat2:

	mov x21, xzr
	loopAnimationRetreatBoost:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 80 // llegar a 340
		b.eq endAnimationRetreatBoost

		// nubes top left
		mov x15, 163
		mov x16, 90
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 248
		mov x16, 110
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 355
		mov x16, 250
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 440
		mov x16, 270
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 195
		mov x16, 370
		add x15, x15, x21
		bl paintCloudTypeOne

		// plane going down
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 5
		mov x15, 325
		mov x16, 260
		add x16, x16, x21
		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationRetreatBoost

	endAnimationRetreatBoost:

	mov x21, xzr
	loopAnimationRestart:
		// paints the sky 
		bl paintRectangle

		// compare and branch
		cmp x21, 5
		b.eq endAnimationRestart

		// paints the sky 
		bl paintRectangle

		// nubes top left
		mov x15, 243
		mov x16, 90
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 328
		mov x16, 110
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 275
		mov x16, 250
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 360
		mov x16, 270
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 275
		mov x16, 370
		add x15, x15, x21
		bl paintCloudTypeOne

		// plane turning around to the right
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 5
		add x17, x17, x21
		cmp x17, 9
		b.lt rotate
		mov x17, 1
		rotate:
		mov x15, 325
		mov x16, 340
		sub x15, x15, x21
		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationRestart
	endAnimationRestart:

	// synchronizes the last frame with the initial frame 
	// to achieve a smooth infinite loop
	mov x21, xzr
	loopAnimationSync:

		// compare and branch
		cmp x21, 108
		b.eq endAnimationSync

		// paints the sky 
		bl paintRectangle

		// nubes top left
		mov x15, 248
		mov x16, 90
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 333
		mov x16, 110
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 270
		mov x16, 250
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 355
		mov x16, 270
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 280
		mov x16, 370
		add x15, x15, x21
		bl paintCloudTypeOne

		// plane turning around to the right
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 1
		mov x15, 320
		mov x16, 340
		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationSync
	endAnimationSync:

	mov x21, xzr
	loopAnimationSync2:
		// compare and branch
		cmp x21, 191
		b.eq endAnimationSync2

		// paints the sky 
		bl paintRectangle

		// nubes top left
		mov x15, 356
		mov x16, 90
		sub x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 441
		mov x16, 110
		sub x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes mid right
		mov x15, 162
		mov x16, 250
		add x15, x15, x21
		bl paintCloudTypeOne
		
		mov x15, 247
		mov x16, 270
		add x15, x15, x21
		bl paintCloudTypeTwo
		
		// nubes bottom mid
		mov x15, 388
		mov x16, 370
		sub x15, x15, x21
		bl paintCloudTypeOne

		// plane turning around to the right
		movz x18, 0x41, lsl 16
		movk x18, 0x533b, lsl 0

		movz x19, 0x9e, lsl 16
		movk x19, 0x9a75, lsl 0

		mov x17, 1
		mov x15, 320
		mov x16, 340
		bl paintPlane

		bl actualizarFrameBuffer
		bl delaySonic
		add x21, x21, 1
		b loopAnimationSync2

	endAnimationSync2:

infloop: b reset
