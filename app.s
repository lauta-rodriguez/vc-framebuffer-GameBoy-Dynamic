// Grupo:
// Nieto, Manuel
// Kurtz, Lara
// Rodriguez, Lautaro

.include "gameboy.s"

.globl main
//test

.equ SCREEN_PIXELS_div_2_menos_1, SCREEN_PIXELS/2 - 1
screen_pixels_div_2_menos_1: .dword SCREEN_PIXELS_div_2_menos_1 // Último indice tomando los elementos como dword
actualizarFrameBuffer:

		sub sp, sp, 32 
		stur x11,[sp,24]
		stur x10,[sp,16]
		stur x9, [sp,8]
		stur lr, [sp]

        ldr x9, dir_frameBuffer
        ldr x10, screen_pixels_div_2_menos_1
    loop_actualizarFrameBuffer:
        cmp x10, #0
        b.lt end_loop_actualizarFrameBuffer
        ldr x11, [x0, x10, lsl #3] // Voy copiando los colores de a 2
        str x11, [x9, x10, lsl #3]
        sub x10, x10, #1
        b loop_actualizarFrameBuffer
    end_loop_actualizarFrameBuffer:
		ldur x11,[sp,24]
		ldur x10,[sp,16]
		ldur x9, [sp,8]
		ldur lr, [sp]
		add sp, sp, 32 
		br lr // return


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
// 	mov x3, xzr		// 
//  mov x4, xzr		// 
//	mov x13, xzr	// temp
//  mov x14, xzr	// temp

	// Parámetros del frame del display del gameboy ("del" combo x3) 
	mov x3, 140		// width
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
	

	// Todo se calcula en función de las coordenadas del top-left
	// corner del borde de la pantalla (x1, x2) y las dimensiones
	// del borde (x3, x4) que es el cuadrado que incluye al display

	// Para aumentar el tamaño del gameboy modificar (x3, x4)
	// Se va a centrar todo en función de ese rectángulo

	// Para hacer el zoom in quitar el offset y cambiar (x3, x4)
	// a (640,480)    

	// Parámetros del frame del display del gameboy ("del" combo x3) 
	mov x3, 160		// width
	mov x4, 100		// height

zoomIn:

	cmp x4, 480
	b.gt endZoomIn

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

	
endZoomIn: b endZoomIn
