.ifndef gameboy_s
.equ gameboy_s, 0

.include "utils.s"

drawBase: // done
    //------------------
    sub sp, sp, 104     // reserve memory in the stack 
    stur x1, [sp,96]    // display frame x coordinate
    stur x2, [sp,88]    // display frame y coordinate
    stur x3, [sp,80]    // display frame width
    stur x4, [sp,72]    // display frame height
    stur x5, [sp,64]    // base width
    stur x6, [sp,56]    // base height
    stur x7, [sp,48]    // temp for calculations
    stur x8, [sp,40]    // corner's curve pronunciation
    stur x9, [sp,32]    // temp for calculations
    stur x10,[sp,24]    // contains gameboy base color
    stur x11,[sp,16]    // aux register
    stur x12,[sp,8]     // aux register
    stur lr, [sp,0]
    //------------------

    // Base color
	movz x10, 0xF6, lsl 16
	movk x10, 0xCF57, lsl 0

    // Initialize registers
    mov x5, xzr
    mov x6, xzr
    mov x7, xzr
    mov x8, xzr
    mov x9, xzr
    mov x11, xzr

    add x11, x11, 5

    // calculate x coordinate for the top-left corner for the base
    add x5, x5, 8
    udiv x5, x3, x5     // horizontal margin between border and base
    sub x1, x1, x5      // moves that amount of pixels left
    add x5, x5, x5      
    add x3, x3, x5      // base width is border width plus margins

    // calculate y coordinate for the top-left corner for the base
    add x6, x6, 8       
    udiv x6, x3, x6     // vertical margin between border and base
    sub x2, x2, x6      // moves that amount of pixels up  
    add x7, x7, 10
    mul x6, x6, x7      
    add x4, x4, x6      // base height is 10 times the margin

    add x8, x8, 25      // determines how pronounces is the corner's curve
    bl paintRoundedRectangle    // paint gameboy case

    // draw the shadow with respect to x5 and x6
    // dividirlos por 3

    // "Shadow" color
	  movz x10, 0x9A, lsl 16
	  movk x10, 0x9A9A, lsl 0

    udiv x12, x5, x11   // divides horizontal margin by 3
    add x1, x1, x12     // moves that amount of pixels right
    mov x3, x11
    //sub x3, x3, 1
  //  bl paintRectangle

    //------------------ 
    ldur x1, [sp,96]    // x coordinate
    ldur x2, [sp,88]    // y coordinate
    ldur x3, [sp,80]    // border width
    ldur x4, [sp,72]    // border height
    ldur x5, [sp,64]    // base width
    ldur x6, [sp,56]    // base height
    ldur x7, [sp,48]    // temp for calculations
    ldur x8, [sp,40]    // temp for calculations
    ldur x9, [sp,32]    // temp for calculations
    ldur x10,[sp,24]    // contains gameboy base color
    ldur x11,[sp,16]
    ldur x12,[sp,8]
    ldur lr, [sp,0]
    add sp, sp, 104     // free memory in the stack
    br lr
    //------------------

drawScreen: // done 
    //------------------
    sub sp, sp, 88      // reserve memory in the stack 
    stur x1, [sp,80]    // x coordinate
    stur x2, [sp,72]    // y coordinate
    stur x3, [sp,64]    // border width
    stur x4, [sp,56]    // border height
    stur x5, [sp,48]    // display width
    stur x6, [sp,40]    // display height
    stur x7, [sp,32]    // temp register
    stur x8, [sp,24]
    stur x9, [sp,16]
    stur x10,[sp,8]     // contains gameboy base color
    stur lr, [sp,0]
    //------------------

    // BORDER
    // Border color
    movz x10, 0x5E, lsl 16
    movk x10, 0x6768, lsl 0

    mov x8, xzr
    add x8, x8, 11      // determines how pronounced is the corner's curve
    bl paintRoundedRectangle

    // DISPLAY
    // Display color
    movz x10, 0x90, lsl 16
    movk x10, 0x9A3E, lsl 0

    ldur x1, [sp,80]    // x coordinate
    ldur x2, [sp,72]    // y coordinate
    ldur x3, [sp,64]    // border width
    ldur x4, [sp,56]    // border height

    // Initializes registers
    mov x5, xzr
    mov x6, xzr

    // calculates x coordinate for the display
    add x5, x5, 8
    udiv x5, x3, x5     // horizontal margin between display and border
    mov x9, x5             
    add x1, x1, x5      // moves that amount of pixels right

    // calculates y coordinate for the display
    add x6, x6, 8
    udiv x6, x4, x6     // vertical margin between display and border
    add x2, x2, x6      // moves that amount of pixels down

    // calculates display width
    add x5, x5, x5       // doubles the horizontal margin
    sub x3, x3, x5      // substracts it from border width

    // calculates display height
    add x6, x6, x6       // doubles that distance
    sub x4, x4, x6      // substracts it from border height
    
    bl paintRectangle   // paints display

    // LIGHT
    // Light color
	movz x10, 0xAD, lsl 16
    movk x10, 0x0952, lsl 0
     
    // restores:
    ldur x1, [sp,80]    // x coordinate
    ldur x2, [sp,72]    // y coordinate
    ldur x4, [sp,56]    // border height

    // calculates light's size and saves it to the radius parameter
    lsr x3, x4, 5       // divides border height by 32

    // calculates x coordinate for the light
    sub x9, x9, x3      // substracts light's size from the distance between border and display
    lsr x9, x9, 1       // divides the result by two
    add x1, x1, x9      // moves that amount of pixels right

    // calculates y coordinate for the light
    sub x4, x4, x3      // substracts light's size from border height
    lsr x4, x4, 1       // divides the by two
    add x2, x2, x4      // moves that amount of pixels down

    mov x4, x1          // paintCircle expects x coordinate at x4
    mov x5, x2          // paintCircle expects y coordinate at x5

    bl paintCircle   // paints light

    //------------------
    ldur x1, [sp,80]    // x coordinate
    ldur x2, [sp,72]    // y coordinate
    ldur x3, [sp,64]    // border width
    ldur x4, [sp,56]    // border height
    ldur x5, [sp,48]    // display width
    ldur x6, [sp,40]    // display height
    ldur x7, [sp,32]    // temp register
    ldur x8, [sp,24]
    ldur x9, [sp,16]
    ldur x10,[sp,8]     // contains gameboy base color
    ldur lr, [sp,0]
    add sp, sp, 88     // free memory in the stack
    br lr
    //------------------

drawCartridge: // done
    //------------------
    sub sp, sp, 104      // reserve memory in the stack 
    stur x1, [sp,96]    // x coordinate
    stur x2, [sp,88]    // y coordinate
    stur x3, [sp,80]    // border width
    stur x4, [sp,72]    // border height
    stur x5, [sp,64]    // display width
    stur x6, [sp,56]    // display height
    stur x7, [sp,48]    // temp register
    stur x8, [sp,40]
    stur x9, [sp,32]
    stur x10,[sp,24]     // contains gameboy base color
    stur x11,[sp,16]
    stur x12,[sp,8]
    stur lr, [sp,0]
    //------------------

	// Cartdrige color
	movz x10, 0x80, lsl 16
	movk x10, 0xB425, lsl 0

    // Initializes registers
    mov x5, xzr
    mov x8, xzr
    mov x9, xzr
    
    // calculates cartdrige height
    add x5, x5, 2
    udiv x5, x4, x5
    sub x2, x2, x5      // moves x5 pixels up

    add x8, x8, 5      // determines how pronounced is the corner's curve
    bl paintRoundedRectangle

    //------------------
    ldur x1, [sp,96]    // x coordinate
    ldur x2, [sp,88]    // y coordinate
    ldur x3, [sp,80]    // border width
    ldur x4, [sp,72]    // border height
    ldur x5, [sp,64]    // display width
    ldur x6, [sp,56]    // display height
    ldur x7, [sp,48]    // temp register
    ldur x8, [sp,40]
    ldur x9, [sp,32]
    ldur x10,[sp,24]     // contains gameboy base color
    ldur x11,[sp,16]
    ldur x12,[sp,8]
    ldur lr, [sp,0]
    add sp, sp, 104     // free memory in the stack
    br lr
    //------------------


drawButtons: // incomplete
    //------------------
    sub sp, sp, 80      // reserve memory in the stack
    stur x7, [sp,72]    // temp
    stur x6, [sp,64]    // temp
    stur x10,[sp,56]    // contains gameboy base color
    stur x14,[sp,48]    // arrows height
    stur x13,[sp,40]    // arrows width
    stur x1, [sp,32]    // display frame x coordinate
    stur x2, [sp,24]    // display frame y coordinate
    stur x3, [sp,16]    // display frame width
    stur x4, [sp,8]     // display frame height
    stur lr, [sp]
    //------------------

    // ARROWS
    // calculates the arrows position
    lsr x5, x4, 1       // divides the display frame height by two
    add x5, x5, x4      // 3/2 de la altura del display frame
    add x2, x2, x5      // moves that amount of pixels down
    add x2, x2, 30

    // calculate arrow's size
    lsr x3, x3, 2       // divides fisplay frame width by two 
    mov x7, 7
    udiv x4, x4, x7

    movz x10, 0x01, lsl 16
    movk x10, 0x386a, lsl 0
    bl paintRectangle   // pinta el rectángulo acostado

    // center the coordinates with respect to the rectangle just drawn
    mov x5, x3          // saves the rectangles width
    sub x5, x5, x4      // substract height from its width
    lsr x5, x5, 1       // divides that by two
    add x1, x1, x5      // moves that amount of pixels right
    sub x2, x2, x5      // moves that amount of pixels up

    // swap dimensions -> el ancho pasa a ser el alto y viceversa
    mov x6, x3          
    mov x3, x4          // arrows width
    mov x4, x6          // arrows height
  
    bl paintRectangle   // cambiar por elipses

    // BUTTONS
    // color
    movz x10, 0xac, lsl 16
    movk x10, 0x3823, lsl 0

    // calculos para x1
    ldur x1, [sp,32]
    mov x6, x4
    mov x7, 3
    mul x6, x6, x7
    mov x4, x1
    add x4, x4, x6
    
    // calculos para el x2
    mov x6, x5
    mov x5, x2
    add x5, x5, x6
    add x5, x5, x6
    add x5, x5, x6


    // calculates the radius of the red buttons based on the width of the display frame
    mov x7, 12
    ldur x3, [sp,16]        // restores display frame width
    udiv x3, x3, x7 
    // the radius is stored in x3
     
    bl paintCircle

    movz x10, 0x00, lsl 16
    movk x10, 0xdb96, lsl 0

    mov x7, xzr
    add x7, x3, x3
    add x4, x4, x7
    sub x5, x5, x7
    bl paintCircle

    //------------------
    ldur x7, [sp,72]    // temp
    ldur x6, [sp,64]    // temp
    ldur x10,[sp,56]
    ldur x14,[sp,48]
    ldur x13,[sp,40]
    ldur x1, [sp,32]
    ldur x2, [sp,24]
    ldur x3, [sp,16]
    ldur x4, [sp,8]
    ldur lr, [sp]
    add sp, sp, 80
    br lr
    //------------------



.endif
