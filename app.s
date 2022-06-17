// Grupo:
// Nieto, Manuel
// Kurtz, Lara
// Rodriguez, Lautaro

.include "utils.s"

.globl main

main:

	adr x1, dir_frameBuffer
	str x0, [x1] // Guardo la dirección de memoria del frame-buffer en dir_frameBuffer
	ldr x0, =bufferSecundario // Pongo en x0 la dirección base del buffer secundario

	//---------------- CODE HERE ------------------------------------
	bl drawWindow

  	// FLOOR
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

  	// Mueble
	bl drawFurniture

	//----------------------GAMEBOY----------------------------
	// Todo se calcula en función de las coordenadas del top-left
	// corner del borde de la pantalla (x1, x2) y las dimensiones
	// del borde (x3, x4) que es el cuadrado que incluye al display

	// Para aumentar el tamaño del gameboy modificar (x3, x4)
	// Se va a centrar todo en función de ese rectángulo

	// Para hacer el zoom in quitar el offset y cambiar (x3, x4)
	// a (640,480)

    //Inicializo los registros
    mov x1, xzr		// gameboy display x coordinate
    mov x2, xzr		// gameboy display y coordinate
	mov x3, xzr		// 
	mov x4, xzr		// 
	mov x13, xzr	// temp
	mov x14, xzr	// temp

	// Parámetros del frame del display del gameboy ("del" combo x3) 
	mov x3, 160		// width
	mov x4, 100		// height
    mov x13, SCREEN_WIDTH // framebuffer width
    mov x14, SCREEN_HEIGH // framebuffer height 

    // center border horizontally in the framebuffer
    sub x13, x13, x3      // substracts base width from framebuffer width 
    lsr x13, x13, 1       // divides it in half
    add x1, x1, x13       // move that amount of pixels right
   
    // center border vertically in the framebuffer
    sub x14, x14, x4      // substracts base height from framebuffer height 
    lsr x14, x14, 1       // divides it in half
    add x2, x2, x14       // move that amount of pixels right

	// Agrego un offset negativo de 10 pixeles a la dimensión 
	// vertical para que entre la animación del cartucho
	// smoothly move the gameboy upwards 10 pixels and thennn
	// zoom in 
	sub x2, x2, 10
	//----------------------GAMEBOY END-------------------------
	//----------------------ZOOM IN GAMEBOY DISPLAY-------------
	zoomIn:

		cmp x4, 472
		b.ge endZoomIn

		//Inicializo los registros
	    mov x1, xzr		// gameboy display x coordinate
	    mov x2, xzr		// gameboy display y coordinate
	
		mov x13, xzr	// temp
		mov x14, xzr	// temp

	    add x13, x13, SCREEN_WIDTH // framebuffer width
	    add x14, x14, SCREEN_HEIGH // framebuffer height 

	    // center border horizontally in the framebuffer
	    sub x13, x13, x3      // substracts base width from framebuffer width 
	    lsr x13, x13, 1       // divides it in half
	    add x1, x1, x13       // move that amount of pixels right
	
	    // center border vertically in the framebuffer
	    sub x14, x14, x4      // substracts base height from framebuffer height 
	    lsr x14, x14, 1       // divides it in half
	    add x2, x2, x14       // move that amount of pixels right

		// Agrego un offset negativo de 10 pixeles a la dimensión 
		// vertical para que entre la animación del cartucho
		// smoothly move the gameboy upwards 10 pixels and thennn
		// zoom in 
		//sub x2, x2, 10

		bl drawCartridge
	    bl drawBase

		// led colour
		movz x11, 0xAD, lsl 16
    	movk x11, 0x0952, lsl 0
		bl drawScreen
		bl drawButtons

		bl actualizarFrameBuffer

		bl delay
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
    mov x9, x5             
    add x1, x1, x5      // moves that amount of pixels right

    // calculates y coordinate for the display
    mov x6, 8
    udiv x6, x4, x6     // vertical margin between display and border
    add x2, x2, x6      // moves that amount of pixels down

	sub x2, x2, 1

	movz x10, 0x8d, lsl 16
    movk x10, 0xebff, lsl 0 
	
	// calculates display width
    add x5, x5, x5       // doubles the horizontal margin
    sub x3, x3, x5      // substracts it from border width

    // calculates display height
    add x6, x6, x6       // doubles that distance
    sub x4, x4, x6       // substracts it from border height
	add x4, x4, 1		 // fix nidea
 
	// turns on the display & the red led
	bl paintRectangle
	bl delay
	bl delay
	bl delay
	bl delay

	//----------------------ANIMATION------------------------

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

//	mov x21, xzr
//	loopAnimationRetreatBoost:
//		// paints the sky 
//		bl paintRectangle
//
//		// compare and branch
//		cmp x21, 70
//		b.eq endAnimationRetreatBoost
//
//		// nubes top left
//		mov x15, 153
//		mov x16, 90
//		add x15, x15, x21
//		bl paintCloudTypeOne
//		
//		mov x15, 238
//		mov x16, 110
//		add x15, x15, x21
//		bl paintCloudTypeTwo
//		
//		// nubes mid right
//		mov x15, 365
//		mov x16, 250
//		sub x15, x15, x21
//		bl paintCloudTypeOne
//		
//		mov x15, 450
//		mov x16, 270
//		sub x15, x15, x21
//		bl paintCloudTypeTwo
//		
//		// nubes bottom mid
//		mov x15, 185
//		mov x16, 370
//		add x15, x15, x21
//		bl paintCloudTypeOne
//
//		// plane going down
//		movz x18, 0x41, lsl 16
//		movk x18, 0x533b, lsl 0
//
//		movz x19, 0x9e, lsl 16
//		movk x19, 0x9a75, lsl 0
//
//		mov x17, 5
//		mov x15, 325
//		mov x16, 270
//		add x16, x16, x21
//		bl paintPlane
//
//
//		bl actualizarFrameBuffer
//		bl delaySonic
//		add x21, x21, 1
//		b loopAnimationRetreatBoost
//
//	endAnimationRetreatBoost:

	// tenemos que girar el avion y ponerlo en la posicion inicial 
	// 320, 340. Ademas podemos hacer tiempo con las nubes hasta que queden en sus
	// posiciones iniciales para sincronizarlas con el primer loop
	// la posicion del loop loopAnimationRetreatBoost quedo en
	// 325+70, 270+70 mirando para abajo

//	mov x21, xzr
//	loopAnimationRestart:
//		// paints the sky 
//		bl paintRectangle
//
//		// compare and branch
//		cmp x21, 5
//		b.eq endAnimationRestart
//
//		// nubes top left
//		mov x15, 231
//		mov x16, 90
//		sub x15, x15, x21
//		bl paintCloudTypeOne
//		
//		mov x15, 316
//		mov x16, 110
//		sub x15, x15, x21
//		bl paintCloudTypeTwo
//		
//		// nubes mid right
//		mov x15, 287
//		mov x16, 250
//		add x15, x15, x21
//		bl paintCloudTypeOne
//		
//		mov x15, 372
//		mov x16, 270
//		add x15, x15, x21
//		bl paintCloudTypeTwo
//		
//		// nubes bottom mid
//		mov x15, 263
//		mov x16, 370
//		sub x15, x15, x21
//		bl paintCloudTypeOne
//
//
//		// plane turning around to the right
//		movz x18, 0x41, lsl 16
//		movk x18, 0x533b, lsl 0
//
//		movz x19, 0x9e, lsl 16
//		movk x19, 0x9a75, lsl 0
//
//		mov x17, 5
//		add x17, x17, x21
//		cmp x17, 9
//		b.lt rotate
//		mov x17, 1
//		rotate:
//		mov x15, 325
//		mov x16, 340
//		sub x15, x15, x21
//		bl paintPlane
//
//		bl actualizarFrameBuffer
//		bl delaySonic
//		add x21, x21, 1
//		b loopAnimationRestart
//	endAnimationRestart: b loopAnimationUP
//
infloop: b infloop
