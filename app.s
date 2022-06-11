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
	bl drawScreen
	bl drawButtons

	bl actualizarFrameBuffer

	bl delay
	add x3,x3,4
	add x4,x4,4
	b zoomIn

	
endZoomIn: 
	

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

	movz x10, 0xd6, lsl 16
    movk x10, 0xffff, lsl 0
	
	// calculates display width
    add x5, x5, x5       // doubles the horizontal margin
    sub x3, x3, x5      // substracts it from border width

    // calculates display height
    add x6, x6, x6       // doubles that distance
    sub x4, x4, x6      // substracts it from border height
	
	bl paintRectangle
	bl actualizarFrameBuffer	
	


infloop: b infloop
