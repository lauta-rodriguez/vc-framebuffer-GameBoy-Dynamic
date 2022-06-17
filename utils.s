.ifndef utils_s
.equ utils_s, 0

.include "data.s"

// la valores en base a los que se calcula el tamaño de las 
// figuras es arbitrario. Se eligieron en función de como queda
// el resultado (imagen) final

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

cleanFrameBuffer:
    //------------------
    sub sp, sp, 16
    stur x0, [sp,8]
    stur lr, [sp,0]
    //------------------

    movz x10, 0x3B, lsl 16
    movk x10, 0x3E45, lsl 00
    mov x2, SCREEN_HEIGH
    
    loopCFB0:
    mov x1, SCREEN_WIDTH
    loopCFB1:
    stur w10, [x0]
    add x0, x0, #4
    sub x1, x1, #1
    cbnz x1, loopCFB1
    sub x2,x2,#1							// substract row from counter
    cbnz x2, loopCFB0	

    //------------------
    ldur x0, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 16
    ret
    //------------------    

delay:
    sub sp, sp, 16
    stur x9, [sp,8]
    stur lr, [sp,0]

	mov x9, #0xFFFFFF
    delayLoop:
    	cbz x9, endDelay
    	sub x9, x9, #1				
    	b delayLoop
    
    endDelay:
    ldur x9, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 16
    ret

delayZzzlow: 
    sub sp, sp, 16
    stur x9, [sp,8]
    stur lr, [sp,0]

	mov x9, 50
    delayZzzlowLoop:
    	cbz x9, endDelayZzz
    	sub x9, x9, #1
        bl delay				
    	b delayZzzlowLoop
    
    endDelayZzz:
    ldur x9, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 16
    ret

delaySonic:
    sub sp, sp, 16
    stur x9, [sp,8]
    stur lr, [sp,0]

	mov x9, #0xFFFF
    delayLoopSonic:
    	cbz x9, endDelaySonic
    	sub x9, x9, #1				
    	b delayLoop
    
    endDelaySonic:
    ldur x9, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 16
    ret

paintPixel:
    //------------------
    // do pixel in the given (x,y) coordinates
    // x -> x1 
    // y -> x2 
    // colour -> x10

    sub sp, sp, 40
    stur x8, [sp,32]
    stur x9, [sp,24]
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp,0]
    //------------------

    // checking that the coordinates belong to the framebuffer
    cmp x1, SCREEN_WIDTH
    b.ge endPP
    cmp x2, SCREEN_HEIGH
    b.ge endPP

    // calculate the initial address 
    // address = fb_base_address + 4 * [x + (y * 640)]
    mov x8, SCREEN_WIDTH
    mul x9, x2, x8
    add x9, x9, x1
    lsl x9, x9, 2
    add x9, x9, x0

    stur w10, [x9]

    endPP:
    //------------------
    ldur x8, [sp,32]
    ldur x9, [sp,24]
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 40
    ret
    //------------------

paintRectangle:
    //------------------
    //  x10 -> color 
    //  x1 -> x coord
    //  x2 -> y coord
    //  x3 -> base
    //  x4 -> height

    sub sp, sp, 64      // reserve memory in the stack
    stur x10,[sp,56]    // save parameters, temp registers and return pointer in the stack
    stur x8, [sp,48]    
    stur x9, [sp,40]
    stur x1, [sp,32]
    stur x2, [sp,24]
    stur x3, [sp,16]
    stur x4, [sp,8]
    stur lr, [sp]
    //------------------

    mov x9, x4                              // saves height in the temp register x9

    loop1:
        cbz x9, loop1End                    // if height==0 or finished painting the rectangle, exits
        //cmp x2, SCREEN_HEIGH                // y_coord - SCREEN_HEIGH ≥ 0 ?
        //b.ge loop1End                       // we exceeded the boundaries of the framebuffer, exits
        ldur x1, [sp, 32]
        mov x8, x3                         // saves base in the temp register x9     
        loop0:
            cbz x8, loop0End               // finished painting an horizontal line, exits
            cmp x1, SCREEN_WIDTH           
            b.ge loop0End                  //  we exceeded the boundaries of the framebuffer, exits
            bl paintPixel
            add x1,x1,1
            sub x8,x8,1
            b loop0
        loop0End:
        add x2, x2, 1
        sub x9, x9, 1
        b loop1
    loop1End:

    //------------------
    ldur x10,[sp,56]
    ldur x8,[sp,48]
    ldur x9,[sp,40]
    ldur x1, [sp,32]
    ldur x2, [sp,24]
    ldur x3, [sp,16]
    ldur x4, [sp,8]
    ldur lr, [sp]
    add sp, sp, 64
    br lr
    //------------------

paintTriangle:
    //------------------
    // Paramétros de entrada:
    // x1  --> x coordinate
    // x2  --> y coordinate
    // x5  --> triangle height
    //
    // Otras variables:
    // x12 --> registro auxiliar para la heigth
    // x15 --> base en cada iteracion
    // x16 --> controla la base en cada iteración

    sub sp, sp, 48      // reserve memory in the stack
    stur x1,[sp,40]    // save parameters, temp registers and return pointer in the stack
    stur x2, [sp,32]
    stur x5, [sp,24]
    stur x15, [sp,16]
    stur x13, [sp,8]
    stur lr, [sp,0]
    //------------------

    //dividir la altura por 2
    //determinar el vértice más alto como el punto que
    //está exactamente altura/2 pixeles sobre la coordenada
    //del punto medio

    add x16, xzr, xzr
    add x15, xzr, xzr
    sub x15, x15, #1  // x13 empieza en -1 -> valores impares
   
    //  Calculo del vértice más alto a partir del punto medio
        // lsr x13, x5, 1 // divide la altura por 2
    // a la coordenada del punto medio le resto la 
    // mitad de la altura
    // sub x13, x2, x13 
    mov x13, x1
   
   //tengo que guardar el valor de x15 cada vez
   // si no siempre oscila entre ser 0 y 1
    triangle_height:
        cbz x5, end_triangle // x5 -> triangle height
        add x15, x15, #2  // la base crece simétricamente
        mov x16, x15
    //  modificar el pixel de inicio para la línea horizontal
        triangle_base:
    //  pintar la línea horizontal necesaria
            cbz x16, end_base
            bl paintPixel
            add x1, x1, 1 // MUEVE UN PIXEL A LA DERECHA
            sub x16, x16, #1 //un pixel menos que pintar
            b triangle_base
        
    // ESTA PINTANDO SIEMPRE UN SOLO PIXEL

        end_base:
            sub x5, x5, #1 // capaz vaya al final de base
            sub x13, x13, #1  // x coordinate
    //      NUEVAS coordenadas para paintpixel
            mov x1, x13
            add x2, x2, #1 // BAJA UN PIXEL
            b triangle_height

        
    end_triangle:

    //------------------
    ldur x1,[sp,40]    // save parameters, temp registers and return pointer in the stack
    ldur x2, [sp,32]
    ldur x5, [sp,24]
    ldur x15, [sp,16]
    ldur x13, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 48      // give back memory to the stack
    br lr 
    //------------------

ifPixelInCirclePaintIT:
    //------------------
    // This procedure checks if the point
    // (x1,x2) belongs to the circle and
    // paints it if it does
    // 
    // parameters:
    // x10 → colour 
    // (x1,x2) → current pixel
    // (x4,x5) → center of the circle
    // x3 -> r
    // "(x1-x4)² + (x2-x5)² ≤ x3²" is true if  "(x1,x2) ∈ Circle"

    sub sp, sp, 72
    stur x15,[sp,64]
    stur x14,[sp,56]
    stur x13,[sp,48]
    stur x5, [sp,40]
    stur x4, [sp,32]
    stur x3, [sp,24]
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp]
    //------------------

    mul x15,x3,x3    //r²

    sub x13, x1, x4
    mul x13, x13, x13  // (x1-x4)²

    sub x14, x2, x5 
    mul x14, x14, x14  // (x2-x5)²
    
    add x13, x13, x14  // (x1-x4)² + (x2-x5)²
    cmp x13, x15

    b.gt endPiC

    // paints the pixel (x1,x2)
    bl paintPixel

    endPiC:
    //------------------
    ldur x15,[sp,64]
    ldur x14,[sp,56]
    ldur x13,[sp,48]
    ldur x5, [sp,40]
    ldur x4, [sp,32]
    ldur x3, [sp,24]
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp]
    add sp, sp, 72
    br lr
    //------------------
paintCircle:
    //------------------
    //  circle of radius r, centered in (x0,y0)
    //  x10 -> colour 
    //  x3 -> r
    //  (x4,x5) -> (x0,y0)

    sub sp, sp, 88
    stur x10,[sp,80]    // colour 
    stur x9, [sp,72]    // square heigth 
    stur x8, [sp,64]    // square base 
    stur x7, [sp,56]    // temp for x1 
    stur x6, [sp,48]    // diameter
    stur x5, [sp,40]    // y0
    stur x4, [sp,32]    // x0
    stur x3, [sp,24]    // radius
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp]       // return pointer
    //------------------

    // calculate the side length of the minimum square that contains the circle 
    add x6, x3, x3
    
    subs x1, x4, x3
    b.lt setx1_0
    b skip_x1
    setx1_0: 
        add x1, xzr, xzr
    skip_x1:
        subs x2, x5, x3   // (x1,x2) apunto al primer pixel del cuadrado que contiene al circulo
        b.lt setx2_0
        b skip_x2
    setx2_0: 
        add x2, xzr, xzr
    skip_x2:

    mov x7, x1
    mov x9, x6
    loopPC1:
        cbz x9, endLoopPC1
        cmp x2, SCREEN_HEIGH
        b.ge endLoopPC1
        mov x1, x7
        mov x8, x6
        loopPC0:
            cbz x8, endLoopPC0
            cmp x1, SCREEN_WIDTH
            b.ge endLoopPC0
            bl ifPixelInCirclePaintIT
            add x1, x1, 1
            sub x8, x8, 1
            b loopPC0

    endLoopPC0:
        add x2, x2, 1
        sub x9, x9, 1
        b loopPC1
    
    endLoopPC1:
    //------------------
    ldur x10,[sp,80]
    ldur x9, [sp,72]
    ldur x8, [sp,64]
    ldur x7, [sp,56]
    ldur x6, [sp,48] 
    ldur x5, [sp,40]
    ldur x4, [sp,32]    
    ldur x3, [sp,24]   
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp]
    add sp, sp, 88
    ret
    //------------------

paintRoundedRectangle:
    //------------------
    sub sp, sp, 104      
    stur x1, [sp,96]        // starting x coordinate
    stur x2, [sp,88]        // starting y coordinate
    stur x3, [sp,80]        // width
    stur x4, [sp,72]        // height
    stur x5, [sp,64]    
    stur x6, [sp,56]    
    stur x7, [sp,48]    
    stur x8, [sp,40]        // determines how pronounced is the corner's curve
    stur x9, [sp,32]
    stur x10,[sp,24]     
    stur x11,[sp,16]
    stur x12,[sp,8]
    stur lr, [sp,0]
    //------------------

    // a bigger x8 makes the corner's curve less pronounced

    // Initializes registers
    mov x5, xzr
    mov x6, xzr
    mov x9, xzr

    // RECTANGLE SIZE
    //calculates corner's side
    udiv x8, x4, x8     
    add x8, x8, x9      // radius of the circle that shapes the corner
    add x9, x8, x8      // x9 contains the diameter

    mov x11, x3         // saves original base width temporarily

    add x1, x1, x8      // moves radius pixels right
    sub x3, x3, x9      // substracts diameter from the base width 
    mov x7, x3          // horizontal distance between two center points

    bl paintRectangle   // paints horizontal rectangle

    add x2, x2, x8      // moves radius pixels down

    mov x6, x1          // temp: paintCircle expects x coordinate at x4
    mov x5, x2          // paintCircle expects y coordinate at x5

    sub x1, x1, x8      // moves radius pixels left
    mov x3, x11         // restores base width
    sub x4, x4, x9      // substracts diameter pixels from the height
    mov x12, x4         // vertical distance between two center points

    bl paintRectangle   // paints vertical rectangle

    // CORNERS
    mov x3, x8          // x3 now contains the radius
    mov x4, x6          // x4 contains the x coordinate for the center point of the circle
    bl paintCircle      // paints top-left corner
    
    add x4, x4, x7      // x7 contains the horizontal distance between two central points
    bl paintCircle      // paints top-right corner

    add x5, x5, x12     // x12 contains the vertical distance between two central points
    bl paintCircle      // paints bottom-right corner

    sub x4, x4, x7
    bl paintCircle      // paints bottom-left corner

    //------------------
    ldur x1, [sp,96]    
    ldur x2, [sp,88]    
    ldur x3, [sp,80]    
    ldur x4, [sp,72]    
    ldur x5, [sp,64]    
    ldur x6, [sp,56]    
    ldur x7, [sp,48]    
    ldur x8, [sp,40]
    ldur x9, [sp,32]
    ldur x10,[sp,24]    
    ldur x11,[sp,16]
    ldur x12,[sp,8]
    ldur lr, [sp,0]
    add sp, sp, 104     // free memory in the stack
    br lr
    //------------------

taylor_sen:
    //------------------
    // calculates sen(x3) using taylor series center at 0 and n = 5
    // x13 is aprox x3 - x3³/6 + x3⁵/120 - x3⁷/5040 + x3⁹/362880
    sub sp, sp, 56
    stur x23, [sp,48]
    stur x22, [sp,40]
    stur x21, [sp,32]
    stur s3, [sp,24]
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp,0]
    //------------------

    fmov s13, s3         // x3 
    fmul s1, s3, s3      // x3²
    fmul s1, s1, s3      // x3³
    fmov s21, 6          // s21←6 
    fdiv s2, s1, s21     // x3³/6
    fsub s13, s13, s2    // x3 - x3³/6
    fmul s1, s1, s3      // x3⁴
    fmul s1, s1, s3      // x3⁵
    fmov s22, 20         // s22←20
    fmul s21, s21, s22   // s21←120
    fdiv s2, s1, s21     // x3⁵/120
    fadd s13, s13, s2    // x3 - x3³/6 + x3⁵/120
    fmul s1, s1, s3      // x3⁶
    fmul s1, s1, s3      // x3⁷
    fmov s23, 22         // s23←22
    fadd s22, s22, s23   // s22←42 
    fmul s21, s21, s22   // s21←5040
    fdiv s2, s1, s21     // x3⁷/5040
    fsub s13, s13, s2    // x3 - x3³/6 + x3⁵/120 - x3⁷/5040
    fmul s1, s1, s3      // x3⁸
    fmul s1, s1, s3      // x3⁹
    fmov s23, 20         // s23←20
    fadd s22, s22, s23   // s22←62
    fmov s23, 10         // s23←10
    fadd s22, s22, s23   // s22←72
    fmul s21, s21, s22   // s21←362880
    fdiv s2, s1, s21     // x3⁹/362880
    fadd s13, s13, s2    // x3 - x3³/6 + x3⁵/120 - x3⁷/5040 + x3⁹/362880

    //------------------
    ldur x23, [sp,48]
    ldur x22, [sp,40]
    ldur x21, [sp,32]
    ldur s3, [sp,24]
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 56
    //------------------
    ret

taylor_cos:
    //------------------
    // calculates cos(x3) using taylor series center at 0 and n = 5
    // cos(x3) aprox = 1 - x3²/2 + x3⁴/24 - x3⁶/720 + x3⁸/40320
    sub sp, sp, 56
    stur x23, [sp,48]
    stur x22, [sp,40]
    stur x21, [sp,32]
    stur x3, [sp,24]
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp,0]
    //------------------

    fmov s14, 1         // 1 
    fmul s1, s3, s3     // x3²
    fmov s21, 2         // s21←2
    fdiv s2, s1, s21    // x3²/2
    fsub s14, s14, s2   // 1 - x3²/2 
    fmul s1, s1, s1     // x3⁴
    fmov s22, 12        // s22←12
    fmul s21, s21, s22  // s21←24   
    fdiv s2, s1, s21    // x3⁴/24
    fadd s14, s14, s2   // 1 - x3²/2 + x3⁴/24
    fmul s1, s1, s3     // x3⁵
    fmul s1, s1, s3     // x3⁶
    fmov s23, 18        // s23←18
    fadd s22, s22, s23  // s22←30
    fmul s21, s21, s22  // s21←720
    fdiv s2, s1, s21    // x3⁶/720
    fsub s14, s14, s2   // 1 - x3²/2 + x3⁴/24 - x3⁶/720
    fmul s1, s1, s3     // x3⁷
    fmul s1, s1, s3     // x3⁸
    fmov s23, 26        // s23←26
    fadd s22, s22, s23  // s22←56
    fmul s21, s21, s22  // s21←40320
    fdiv s2, s1, s21    // x3⁸/40320
    fadd s14, s14, s2   // 1 - x3²/2 + x3⁴/24 - x3⁶/720 + x3⁸/40320

    //------------------
    ldur x23, [sp,48]
    ldur x22, [sp,40]
    ldur x21, [sp,32]
    ldur x3, [sp,24]
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp,0]
    add sp, sp, 56
    ret
    //------------------

ifPixelInEllipsePaintIT:
    //------------------
    //  This procedure checks if the point
    //  (x1,x2) belongs to the ellipse and
    //  paints it if it does
    //  
    //  parameters:
    //  x10 → colour 
    //  (x1,x2) → current pixel
    //  (x4,x5) → center of the elipse
    //  x6 -> x axis
    //  x7 -> y axis
    //  x3 -> a rotation (range must be between [-pi, pi])
    //
    // "(x7·((x1-x4)·cos(x3)-(x2-x5)·sen(x3)))² + (x6·((x1-x4)·sen(x3)+(x2-x5)·cos(x3)))² ≤ (x6·x7)² is true if (x1,x2) belongs to the ellipse "

    sub sp, sp, 80
    stur x19,[sp,72]
    stur x18,[sp,64]
    stur x17,[sp,56]
    stur x16,[sp,48]
    stur x15,[sp,40]
    stur x14,[sp,32]     //cos(x3)
    stur x13,[sp,24]     //sen(x3)
    stur x12,[sp,16]     //(x2-x5)
    stur x11,[sp,8]      //(x1-x4)
    stur lr, [sp]
    //------------------

    // covert int values to float 
    scvtf s1, w1
    scvtf s2, w2
    scvtf s4, w4
    scvtf s5, w5
    scvtf s6, w6
    scvtf s7, w7

    // ellipse equation
    fsub s11, s1, s4   // (x1-x4)
    fsub s12, s2, s5   // (x2-x5)

    fmul s15, s11, s14 // (x1-x4)·cos(x3)
    fmul s16, s12, s13 // (x2-x5)·sen(x3)
    fsub s17, s15, s16 // (x1-x4)·cos(x3)-(x2-x5)·sen(x3)
    fmul s17, s17, s7  // x7·((x1-x4)·cos(x3)-(x2-x5)·sen(x3))
    fmul s17, s17, s17 // (x7·((x1-x4)·cos(x3)-(x2-x5)·sen(x3)))²

    fmul s15, s11, s13 // (x1-x4)·sen(x3)
    fmul s16, s12, s14 // (x2-x5)·cos(x3)
    fadd s18, s15, s16 // (x1-x4)·sen(x3)+(x2-x5)·cos(x3)
    fmul s18, s18, s6  // x6·((x1-x4)·sen(x3)+(x2-x5)·cos(x3))
    fmul s18, s18, s18 // (x6·((x1-x4)·sen(x3)+(x2-x5)·cos(x3)))² 

    fadd s17, s17, s18 // (x7·((x1-x4)·cos(x3)-(x2-x5)·sen(x3)))² + (x6·((x1-x4)·sen(x3)+(x2-x5)·cos(x3)))²

    fmul s19, s6, s7   // (x6·x7)
    fmul s19, s19, s19 // (x6·x7)²

    fcmp s17, s19

    b.gt endPiE

    // paints the pixel (x1,x2)
    bl paintPixel

    endPiE: 
    //------------------
    ldur x19,[sp,72]
    ldur x18,[sp,64]
    ldur x17,[sp,56]
    ldur x16, [sp,48]
    ldur x15, [sp,40]
    ldur x14, [sp,32]   
    ldur x13, [sp,24]     
    ldur x12, [sp,16]     
    ldur x11, [sp,8]      
    ldur lr, [sp]
    add sp, sp, 80
    ret
    //------------------

paintEllipse:
    //------------------
    //  centered in (x0,y0), x axis, y axis, a rotation
    //  x10 -> colour
    //  x7 -> y axis 
    //  x6 -> x axis
    //  (x4,x5) -> (x0,y0)
    //  x3 -> a rotation (range must be between [-pi, pi])

    sub sp, sp, 120
    stur x14,[sp,112]   // cos(a)
    stur x13,[sp,104]   // sen(a)
    stur x12,[sp,96]    // temp for x1 
    stur x11,[sp,88]    // max(x6, x7)
    stur x10,[sp,80]    // colour  
    stur x9, [sp,72]    // square heigth 
    stur x8, [sp,64]    // square base 
    stur x7, [sp,56]    // y axis
    stur x6, [sp,48]    // x axis
    stur x5, [sp,40]    // y0
    stur x4, [sp,32]    // x0
    stur x3, [sp,24]    // a
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp]       // return pointer
    //------------------

    // calculate max(x6, x7)
    cmp x6, x7
    b.gt max_x6
    mov x11, x7
    b end_max
    max_x6:
    mov x11, x6
    end_max:
    
    // calculate the coordinates of the most top left pixel in the square
    subs x1, x4, x11 
    b.lt set_x1_ellipse
    b skip_x1_ellipse
    set_x1_ellipse: 
    add x1, xzr, xzr
    skip_x1_ellipse:
    subs x2, x5, x11   
    b.lt set_x2_ellipse
    b skip_x2_ellipse
    set_x2_ellipse: 
    add x2, xzr, xzr
    skip_x2_ellipse:

    // calculate sen(x3) and cos(x3) and store them in s13 and s14
    bl taylor_sen //s13 -> sen(x3)
    bl taylor_cos //s14 -> cos(x3)

    add x9, x11, x11 // Height
    mov x12, x1 // Temp for x1
    loopPC1_ellipse:
        cbz x9, endLoopPC1_ellipse
        cmp x2, SCREEN_HEIGH
        b.ge endLoopPC1_ellipse
        mov x1, x12
        add x8, x11, x11 // Base (same as height)
        loopPC0_ellipse:
            cbz x8, endLoopPC0_ellipse
            cmp x1, SCREEN_WIDTH
            b.ge endLoopPC0_ellipse
            bl ifPixelInEllipsePaintIT
            add x1, x1, 1
            sub x8, x8, 1
            b loopPC0_ellipse
    endLoopPC0_ellipse:
        add x2, x2, 1
        sub x9, x9, 1
        b loopPC1_ellipse
    endLoopPC1_ellipse:

    //------------------
    ldur x14,[sp,112]  
    ldur x13,[sp,104]  
    ldur x12,[sp,96]   
    ldur x11,[sp,88]    
    ldur x10,[sp,80]    
    ldur x9, [sp,72]     
    ldur x8, [sp,64]    
    ldur x7, [sp,56]    
    ldur x6, [sp,48]    
    ldur x5, [sp,40]    
    ldur x4, [sp,32]    
    ldur x3, [sp,24]    
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp]       
    add sp, sp, 120
    br lr
    //------------------

drawFurniture:
    //------------------
    sub sp, sp, 56      // reserve memory in the stack 
    stur x1, [sp,48]    // floor's initial x coordinate
    stur x2, [sp,40]    // floor's initial y coordinate
    stur x3, [sp,32]    // furniture width
    stur x4, [sp,24]     // furniture height
    stur x11,[sp,16]      // aux register  
    stur x12,[sp,8]      // aux register
    stur lr, [sp,0]
    //------------------

    // FURNITURE
	// accents
	mov x1, 20
	sub x2, x2, 60
	mov x3, 200				// width of the furniture
	mov x4, 80				// height of the furniture

	mov x11, x1				// saves x coordinate
	mov x12, x2				// saves y coordinate

	movz x10, 0x84, lsl 16	// dark brown
    movk x10, 0x4838, lsl 00		
	bl paintRectangle

    // doors
	add x1, x1, 5			// dark margin is 5 pixels wide
	add x2, x2, 5			// dark margin is 5 pixels tall
   	mov x3, 90				// first door
	sub x4, x4, 10

	movz x10, 0x93, lsl 16	// lighter brown
    movk x10, 0x513F, lsl 00		
	bl paintRectangle

	add x1, x1, 100
	bl paintRectangle		// second door
 
  // TV
    // restores x and y coordinates
	mov x1, x11			
	mov x2, x12			

	add x1, x1, 20
 	sub x2, x2, 70

	mov x3, 160				// width of the tv
	mov x4, 60				// height of the tv

	movz x10, 0x00, lsl 16	// black
    movk x10, 0x0000, lsl 00
	bl paintRectangle 

	add x1, x1, 80
	mov x5, 12
	add x2, x2, 58

	bl paintTriangle

    //------------------
    ldur x1, [sp,48]    // floor's initial x coordinate
    ldur x2, [sp,40]    // floor's initial y coordinate
    ldur x3, [sp,32]    // furniture width
    ldur x4, [sp,24]     // furniture height
    ldur x11,[sp,16]      // aux register  
    ldur x12,[sp,8]      // aux register
    ldur lr, [sp,0]
    add sp, sp, 104     // free memory in the stack
    br lr
    //------------------



drawWindow:
    //
    //  DESCRIPCIÓN DE LA FUNCIÓN   
    //

    //------------------
    sub sp, sp, 104      // reserve memory in the stack 
    stur x1, [sp,96]
    stur x2, [sp,88]
    stur x3, [sp,80]    
    stur x4, [sp,72]    
    stur x5, [sp,64]    
    stur x6, [sp,56]
    stur x7, [sp,48]    
    stur x8, [sp,40]
    stur x9, [sp,32]
    stur x10,[sp,24]
    stur x11,[sp,16]       
    stur x12,[sp,8]      
    stur lr, [sp,0]
    //------------------

  // DUSK	
	mov x4, 520
	mov x5, 210
	
	mov x3, 160             // radio del circulo    
	movz x9, 0x09, lsl 16
    movk x9, 0x0900, lsl 00 // incremento para x10
	movz x10, 0x33, lsl 16
    movk x10, 0x0fee, lsl 00// base blue color

	mov x7, 7               // decremento del radio en cada iteración
    mov x8, 2               // cantidad de iteraciones
    blue_block: 
        cbz x8, end_blue

        bl paintCircle

        add x10, x10, x9
        
        sub x3, x3, x7
        sub x8, x8, 1
        b blue_block

    end_blue:

    movz x9, 0x0f, lsl 16
    movk x9, 0x0400, lsl 00 // incremento para x10
    movz x11, 0x00, lsl 16
    movk x11, 0x0015, lsl 00// decremento para x10

    mov x8, 6               // cantidad de iteraciones
    purple_block: 
        cbz x8, end_purple

        bl paintCircle

        add x10, x10, x9
        sub x10, x10, x11

        sub x3, x3, x7
        sub x8, x8, 1
        b purple_block

    end_purple:

    mov x8, 6
    movz x9, 0x0f, lsl 16   // incremento para x10
    movk x9, 0x0600, lsl 00
    movz x11, 0x00, lsl 16  // decremento para x10
    movk x11, 0x0015, lsl 00

    mov x8, 6               // cantidad de iteraciones
    orange_block: 
        cbz x8, end_orange

        bl paintCircle

        add x10, x10, x9
        sub x10, x10, x11

        sub x3, x3, x7
        sub x8, x8, 1
        b orange_block

    end_orange:

    movz x9, 0x00, lsl 16   
    movk x9, 0x0f00, lsl 00 // incremento para x10
	movz x10, 0xff, lsl 16  
    movk x10, 0x7a0f, lsl 00// sets new color
  
    mov x8, 6               // cantidad de iteraciones
    yellow_block: 
        cbz x8, end_yellow

        bl paintCircle

        add x10, x10, x9

        sub x3, x3, x7
        sub x8, x8, 1
        b yellow_block

    end_yellow:

  // WINDOW FRAME - a partir de las coordenadas del centro del círculo
    mov x1, x4  //coordenadas del centro
    mov x2, x5 

    // frame dimentions: 210(width) by 110(height)
	movz x10, 0x61, lsl 16	// dark brown
    movk x10, 0x2112, lsl 00

    mov x3, 210         // sets frame width
    lsr x8, x3, 1
    sub x1, x1, x8      // moves half the window's width left
    mov x4, 8           // window frame is 5 pixels tall 
    bl paintRectangle   // BOTTOM FRAME

    mov x3, 8           // frame is 5 pixels wide
    mov x4, 110         // frame is x4 pixels tall
    sub x8, x4, 8       // + frame width
    sub x2, x2, x8  
	bl paintRectangle   // LEFT FRAME

    // saves (x1, x2) in (x11, x12) -> para dibujar las hojas de la ventana
    mov x11, x1          // x coordinate of the top frame
    mov x12, x2          // y coordinate of the top frame
    
    mov x3, 210
    mov x4, 8
    bl paintRectangle   // TOP FRAME

    // antes de ir al right frame, parar al meido y dibujar la línea 
    // que divide la ventana a la mitad

    sub x8, x3, 8       // window width minus frame width
    lsr x8, x8, 1       
    add x1, x1, x8
    mov x3, 8
    mov x4, 110
    bl paintRectangle   // MIDDLE FRAME
          
    add x1, x1, x8
    bl paintRectangle   // RIGHT FRAME
     
  // WALL
    movz x10, 0xC2, lsl 16
    movk x10, 0x8340, lsl 00// brown

    // la coordenada y del tope del borde es la altura del rectángulo a pintar
    mov x4, x2          // altura del top frame
    mov x1, 0
    mov x2, 0
    mov x3, SCREEN_WIDTH
    bl paintRectangle

    mov x2, x4          // x4 es la distancia entre el tope del framebuffer y el tope del window frame
    mov x4, 110         // seteo una nueva altura para el rectángulo a pintar
    sub x3, x3, x5      // x5 contains the x coordinate of the center of the circle (resta la ventana)
    sub x3, x3, 15      // resta lo que queda de pared
    bl paintRectangle

    mov x1, x3          // se mueve al comienzo de la ventana
    add x1, x1, 210     // se mueve a la derecha de la ventana
    mov x3, 15          // ancho de lo que queda de pared
    bl paintRectangle

    mov x1, 0           // se mueve al comienzo del framebuffer
    add x2, x2, 110     // se mueve abajo de la ventana
    mov x3, SCREEN_WIDTH
    mov x4, 300
    bl paintRectangle

  // Hojas de las ventanas
	movz x10, 0x61, lsl 16	// dark brown
    movk x10, 0x2112, lsl 00

    mov x1, x11     // x11 - x1 es la distancia entre el frame y la hoja
    mov x2, x12

    mov x3, 1
    mov x4, 9
    mov x7, xzr
    diagonalRightUp:
        cmp x7, 35   
        b.eq end_diagonalRightUp

        bl paintRectangle
        add x1, x1, 1   // al final del loop queda x1 + 35
        sub x2, x2, 1   // al final del loop queda x2 + 35

        add x7, x7, 1
        b diagonalRightUp
    end_diagonalRightUp:

    mov x3, 8           // ancho del frame
    mov x4, 110         // altura del frame

    add x4, x4, 35      // suma la distancia hasta el tope de la línea diagonal
    add x4, x4, 35      // dos veces
    bl paintRectangle

    sub x1, x1, 35
    add x2, x2, 35
    add x2, x2, 51      // (110/2)-(8/2) -> barra horizontal del medio

    mov x3, 35
    mov x4, 8
    bl paintRectangle

    mov x3, 1
    mov x4, 9
    add x2, x2, 51      // (110/2)-(8/2) -> le resta el borde de abajo
    mov x7, xzr
    diagonalRightDown:
        cmp x7, 35   
        b.eq end_diagonalRightDown

        bl paintRectangle
        add x1, x1, 1   // al final del loop queda x1 + 35
        add x2, x2, 1   // al final del loop queda x2 + 35

        add x7, x7, 1
        b diagonalRightDown
    end_diagonalRightDown:

    // moves to the left rigth frame (moves window width rightwards)

    sub x1, x1, 35
    sub x2, x2, 35
    add x1, x1, 209

    mov x3, 1
    mov x4, 9
    mov x7, xzr
    diagonalLeftDown:
        cmp x7, 35   
        b.eq end_diagonalLeftDown

        bl paintRectangle
        sub x1, x1, 1   // al final del loop queda x1 - 35
        add x2, x2, 1   // al final del loop queda x2 + 35

        add x7, x7, 1
        b diagonalLeftDown
    end_diagonalLeftDown:

    sub x2, x2, 35
    sub x2, x2, 51

    mov x3, 35
    mov x4, 8
    bl paintRectangle

    add x1, x1, 35
    sub x2, x2, 51

    mov x3, 1
    mov x4, 9
    mov x7, xzr
    diagonalLeftUp:
        cmp x7, 35   
        b.eq end_diagonalLeftUp

        bl paintRectangle
        sub x1, x1, 1   // al final del loop queda x1 - 35
        sub x2, x2, 1   // al final del loop queda x2 + 35

        add x7, x7, 1
        b diagonalLeftUp
    end_diagonalLeftUp:

    sub x1, x1, 7
    mov x3, 8
    mov x4,110
    add x4, x4, 35
    add x4, x4, 35

    bl paintRectangle

    //------------------
    ldur x1, [sp,96]
    ldur x2, [sp,88]
    ldur x3, [sp,80]    
    ldur x4, [sp,72]   
    ldur x5, [sp,64]    
    ldur x6, [sp,56]
    ldur x7, [sp,48]     
    ldur x8, [sp,40]
    ldur x9, [sp,32]
    ldur x10,[sp,24]
    ldur x11,[sp,16]        
    ldur x12,[sp,8]      
    ldur lr, [sp,0]
    add sp, sp, 104     // free memory in the stack
    br lr
    //------------------

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
    sub sp, sp, 96      // reserve memory in the stack 
    stur x11,[sp,88]
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
    
    mov x10, x11
    
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
    ldur x11,[sp,88]
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
    add sp, sp, 96     // free memory in the stack
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


drawButtons: // done
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


ifPixelInRoundedTrianglePaintIT:
    ///////////////////////////////////////////
    //  This procedure checks if the point
    //  (x1,x2) belongs to the rounded triangle and
    //  paints it if it does
    //  
    //  parameters:
    //  x10 → colour 
    //  (x1,x2) → current pixel
    //  x17 → square distance bewteen (x3, x4) and (x5, x6)
    //  x18 → square distance bewteen (x3, x4) and (x7, x8)
    //  x19 → square distance bewteen (x5, x6) and (x7, x8)
    ///////////////////////////////////////////
   
    sub sp, sp, 40
    stur x21, [sp,32]     
    stur x9, [sp,24]     
    stur x2, [sp,16]     
    stur x1, [sp,8]      
    stur lr, [sp]

    // calculate the square distance (x21) bewteen (x1, x2) and (x3, x4) 
    sub x21, x1, x3    // (x1-x3)
    mul x21, x21, x21  // (x1-x3)²
    sub x9, x2, x4     // (x2-x4)
    mul x9, x9, x9     // (x2-x4)²
    add x21, x21, x9   // (x1-x3)² + (x2-x4)² => square distance bewteen (x1, x2) and (x3, x4) 

    cmp x21, x17
    b.gt endPiT
    cmp x21, x18
    b.gt endPiT

    // calculate the square distance (x21) bewteen (x1, x2) and (x5, x6) 
    sub x21, x1, x5    // (x1-x5)
    mul x21, x21, x21  // (x1-x5)²
    sub x9, x2, x6     // (x2-x6)
    mul x9, x9, x9     // (x2-x6)²
    add x21, x21, x9   // (x1-x5)² + (x2-x6)² => square distance bewteen (x1, x2) and (x5, x6) 

    cmp x21, x17
    b.gt endPiT
    cmp x21, x19
    b.gt endPiT

    // calculate the square distance (x21) bewteen (x1, x2) and (x7, x8) 
    sub x21, x1, x7    // (x1-x7)
    mul x21, x21, x21  // (x1-x7)²
    sub x9, x2, x8     // (x2-x8)
    mul x9, x9, x9     // (x2-x8)²
    add x21, x21, x9   // (x1-x7)² + (x2-x8)² => square distance bewteen (x1, x2) and (x7, x8) 

    cmp x21, x18
    b.gt endPiT
    cmp x21, x19
    b.gt endPiT

    // paints the pixel (x1,x2)
    bl paintPixel

    endPiT: 
    ldur x21, [sp,32]     
    ldur x9, [sp,24]     
    ldur x2, [sp,16]     
    ldur x1, [sp,8]      
    ldur lr, [sp]
    add sp, sp, 40
    ret

paintRoundedTriangle:
    ///////////////////////////////////////////
    //  given 3 differents points (x3, x4) (x5, x6) (x7, x8)  paints a triangle  
    //  disclaimer: these points must not belong to the same straight line because the 
    //  program does not take that into account
    //  x10 -> colour
    ///////////////////////////////////////////

    sub sp, sp, 160
    stur x19,[sp,152]   // square distance bewteen (x5, x6) and (x7, x8)
    stur x18,[sp,144]   // square distance bewteen (x3, x4) and (x7, x8)
    stur x17,[sp,136]   // square distance bewteen (x3, x4) and (x5, x6)
    stur x16,[sp,128]   // height of the squared
    stur x15,[sp,120]   // base of the squared
    stur x14,[sp,112]   // max(x4, x6, x8)
    stur x13,[sp,104]   // min(x4, x6, x8)
    stur x12,[sp,96]    // max(x3, x5, x7)
    stur x11,[sp,88]    // min(x3, x5, x7) 
    stur x10,[sp,80]   
    stur x9, [sp,72]    // auxiliar
    stur x8, [sp,64]   
    stur x7, [sp,56]   
    stur x6, [sp,48]    
    stur x5, [sp,40]    
    stur x4, [sp,32]    
    stur x3, [sp,24]    
    stur x2, [sp,16]
    stur x1, [sp,8]
    stur lr, [sp]       // return pointer

    // calculate the min(x3, x5, x7) and store it in x11
    cmp x3, x5
    b.gt min_x5
    mov x11, x3 // x3 < x5 => x11<-x3
    b compare_x7_x11
    min_x5:
    mov x11, x5 // x5 < x3 => x11<-x5
    compare_x7_x11:
    cmp x7, x11
    b.gt end_min_x
    mov x11, x7 // x7 < x11 => x11<-x7
    end_min_x:

    // calculate the max(x3, x5, x7) and store it in x12
    cmp x3, x5
    b.gt max_x3
    mov x12, x5 // x5 > x3 => x12<-x5
    b compare_x7_x12
    max_x3:
    mov x12, x3 // x3 > x5 => x12<-x3
    compare_x7_x12:
    cmp x7, x12
    b.lt end_max_x
    mov x12, x7 // x7 > x12 => x12<-x7
    end_max_x:

    // calculate the min(x4, x6, x8) and store it in x13
    cmp x4, x6
    b.gt min_x6
    mov x13, x4 // x4 < x6 => x13<-x4
    b compare_x8_x13
    min_x6:
    mov x13, x6 // x6 < x4 => x13<-x6
    compare_x8_x13:
    cmp x8, x13
    b.gt end_min_y
    mov x13, x8 // x8 < x13 => x13<-x8
    end_min_y:

    // calculate the max(x4, x6, x8) and store it in x14
    cmp x4, x6
    b.gt max_x4
    mov x14, x6 // x6 > x4 => x14<-x6
    b compare_x8_x14
    max_x4:
    mov x14, x4 // x4 > x6 => x14<-x4
    compare_x8_x14:
    cmp x8, x14
    b.lt end_max_y
    mov x14, x8 // x8 > x14 => x14<-x8
    end_max_y:

    // checking if x11, x12, x13 and x14 are outside the limits of the framebuffer
    cmp x11, 0
    b.ge check_x12
    mov x11, 0   // x11 is out of bounds
    check_x12:
    cmp x12, 0
    b.ge check_x13
    mov x12, 0   // x12 is out of bounds
    check_x13:
    cmp x13, SCREEN_WIDTH
    b.lt check_x14
    mov x13, 639 // x13 is out of bounds
    check_x14:
    cmp x14, SCREEN_HEIGH
    b.lt end_check
    mov x14, 479 // x14 is out of bounds
    end_check:
    

    // calculate the square distance (x17) bewteen (x3, x4) and (x5, x6) 
    sub x17, x3, x5    // (x3-x5)
    mul x17, x17, x17  // (x3-x5)²
    sub x9, x4, x6     // (x4-x6)
    mul x9, x9, x9     // (x4-x6)²
    add x17, x17, x9   // (x3-x5)² + (x4-x6)² => square distance bewteen (x3, x4) and (x5, x6) 

    // calculate the square distance (x18) bewteen (x3, x4) and (x7, x8)
    sub x18, x3, x7    // (x3-x7)
    mul x18, x18, x18  // (x3-x7)²
    sub x9, x4, x8     // (x4-x8)
    mul x9, x9, x9     // (x4-x8)²
    add x18, x18, x9   // (x3-x7)² + (x4-x8)² => square distance bewteen (x3, x4) and (x7, x8)

    // calculate the square distance (x19) bewteen (x5, x6) and (x7, x8)
    sub x19, x5, x7    // (x5-x7)
    mul x19, x19, x19  // (x5-x7)²
    sub x9, x6, x8     // (x6-x8)
    mul x9, x9, x9     // (x6-x8)²
    add x19, x19, x9   // (x5-x7)² + (x6-x8)² => square distance bewteen (x5, x6) and (x7, x8)

    // paints the triangle
    sub x16, x14, x13 // Height of the Squared
    mov x2, x13
    loopPC1_triangle:
        cbz x16, endLoopPC1_triangle
        mov x1, x11
        sub x15, x12, x11 // Base of the Squared
        loopPC0_triangle:
            cbz x15, endLoopPC0_triangle
            bl ifPixelInRoundedTrianglePaintIT
            add x1, x1, 1
            sub x15, x15, 1
            b loopPC0_triangle
    endLoopPC0_triangle:
        add x2, x2, 1
        sub x16, x16, 1
        b loopPC1_triangle
    endLoopPC1_triangle:


    exit_failure:
    ldur x19,[sp,152]   
    ldur x18,[sp,144]  
    ldur x17,[sp,136]  
    ldur x16,[sp,128]   
    ldur x15,[sp,120]   
    ldur x14,[sp,112]   
    ldur x13,[sp,104]   
    ldur x12,[sp,96]    
    ldur x11,[sp,88]    
    ldur x10,[sp,80]   
    ldur x9, [sp,72]    
    ldur x8, [sp,64]   
    ldur x7, [sp,56]   
    ldur x6, [sp,48]    
    ldur x5, [sp,40]    
    ldur x4, [sp,32]    
    ldur x3, [sp,24]    
    ldur x2, [sp,16]
    ldur x1, [sp,8]
    ldur lr, [sp]   
    add sp, sp, 160
    br lr

paintPlane:
    // Paints plane centered at (x0, y0) coordenates
    // (x15, x16) -> Center of the Plane
    // x17 -> Direction of the Plane:
    //                             (1) North
    //                             (2) Northeast
    //                             (3) East
    //                             (4) Southeast
    //                             (5) South
    //                             (6) Southwest
    //                             (7) West
    //                             (8) Northwest
    //                             (Other) Failure
    // x18 -> Main Body Colour
    // x19 -> Wings and Tails Colour
    //
    // Disclaimer: The plane will always have the same size

    sub sp, sp, 112
    stur x19, [sp,104]  // Wings and Tails Colour
    stur x18, [sp,96]   // Main Body Colour
    stur x17, [sp,88]   // Direction of the Plane
    stur x16, [sp,80]   // y0
    stur x15, [sp,72]   // x0
    stur x10, [sp,64]   
    stur x9, [sp,56]   
    stur x8, [sp,48]    
    stur x7, [sp,40]    
    stur x6, [sp,32]    
    stur x5, [sp,24]    
    stur x4, [sp,16]
    stur x3, [sp,8]
    stur lr, [sp]       // return pointer

    // First we check the Direction of the Plane 
    cmp x17, 1
    b.eq North
    cmp x17, 2
    b.eq Northeast
    cmp x17, 3
    b.eq East
    cmp x17, 4
    b.eq Southeast
    cmp x17, 5
    b.eq South
    cmp x17, 6
    b.eq Southwest
    cmp x17, 7
    b.eq West
    cmp x17, 8
    b.eq Northwest
    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    North:
    // Paint Wings  

    //// Turbines 
    mov	w3, 62915
	movk w3, 0x3fc8, lsl 16
	fmov s3, w3 // s3 = 1.57

    mov x10, x18

    sub x4, x15, 23
    sub x5, x16, 10

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    add x4, x15, 23
    sub x5, x16, 10

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19
    sub x3, x15, 50  
    mov x4, x16

    mov x5, x15
    sub x6, x16, 23

    mov x7, x15
    add x8, x16, 23

    bl paintRoundedTriangle

    //// Second Wing
    add x3, x15, 50  
    mov x4, x16

    mov x5, x15
    sub x6, x16, 23

    mov x7, x15
    add x8, x16, 23

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    mov x4, x15
    add x5, x16, 55

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    mov x4, x15
    add x5, x16, 53

    mov x6, 9
    mov x7, 4

    bl paintEllipse

    //// First Part
    mov x10, x19
    sub x3, x15, 25
    add x4, x16, 55
   
    sub x5, x15, 10
    add x6, x16, 20

    add x7, x15, 5 
    add x8, x16, 50

    bl paintRoundedTriangle

    //// Second Part
    add x3, x15, 25
    add x4, x16, 55
   
    add x5, x15, 10
    add x6, x16, 20

    sub x7, x15, 5 
    add x8, x16, 50

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 62915
	movk w3, 0x3fc8, lsl 16
	fmov s3, w3 // s3 = 1.57

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane  
    mov x3, x15
    sub x4, x16, 61
    
    sub x5, x15, 10
    sub x6, x16, 41

    add x7, x15, 10
    sub x8, x16, 41

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    mov x4, x15
    sub x5, x16, 10

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    Northeast:
    // Paint Wings  

    //// Turbines
    mov	w3, 26214
	movk w3, 0x3f66, lsl 16
	fmov s3, w3 // s3 = -0.8

    mov x10, x18

    sub x4, x15, 12
    sub x5, x16, 27

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    add x4, x15, 27
    add x5, x16, 7

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19

    sub x3, x15, 60
    sub x4, x16, 46

    sub x5, x15, 22
    add x6, x16, 12

    add x7, x15, 12
    sub x8, x16, 22

    bl paintRoundedTriangle

    //// Second Wing
    add x3, x15, 60
    add x4, x16, 46

    add x5, x15, 22
    sub x6, x16, 12

    sub x7, x15, 12
    add x8, x16, 22

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    sub x4, x15, 35
    add x5, x16, 43

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    sub x4, x15, 34
    add x5, x16, 41

    mov x6, 10
    mov x7, 4

    bl paintEllipse 

    //// First Part
    mov x10, x19
    sub x3, x15, 44
    add x4, x16, 10
   
    sub x5, x15, 12
    add x6, x16, 24

    sub x7, x15, 39
    add x8, x16, 39

    bl paintRoundedTriangle

    //// Second Part
    sub x3, x15, 3
    add x4, x16, 51
   
    sub x5, x15, 17
    add x6, x16, 19

    sub x7, x15, 32
    add x8, x16, 46

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 26214
	movk w3, 0x3f66, lsl 16
	fmov s3, w3 // s3 = -0.8

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane 
    add x3, x15, 43
    sub x4, x16, 52
    
    add x5, x15, 5
    sub x6, x16, 47

    add x7, x15, 48
    sub x8, x16, 9

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    add x4, x15, 8
    sub x5, x16, 10

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    East:
    // Paint Wings  

    //// Turbines 
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x10, x18

    add x4, x15, 10
    sub x5, x16, 23

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    add x4, x15, 10
    add x5, x16, 23

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19
    mov x3, x15 
    sub x4, x16, 50

    sub x5, x15, 23
    mov x6, x16

    add x7, x15, 23
    mov x8, x16

    bl paintRoundedTriangle

    //// Second Wing
    mov x3, x15  
    add x4, x16, 50

    sub x5, x15, 23
    mov x6, x16

    add x7, x15, 23
    mov x8, x16

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    sub x4, x15, 55
    mov x5, x16

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    sub x4, x15, 53
    mov x5, x16

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    //// First Part
    mov x10, x19
    sub x3, x15, 55
    sub x4, x16, 25
   
    sub x5, x15, 20
    sub x6, x16, 10

    sub x7, x15, 50
    add x8, x16, 5 

    bl paintRoundedTriangle

    //// Second Part
    sub x3, x15, 55
    add x4, x16, 25
   
    sub x5, x15, 20
    add x6, x16, 10

    sub x7, x15, 50
    sub x8, x16, 5 

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane  
    add x3, x15, 61
    mov x4, x16
    
    add x5, x15, 41
    sub x6, x16, 10

    add x7, x15, 41
    add x8, x16, 10

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    add x4, x15, 10
    mov x5, x16

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane
 
    ///////////////////////////////////////////////////////////////////////
    Southeast:
    // Paint Wings  

    //// Turbines
    mov	w3, 52429
	movk w3, 0x400c, lsl 16
	fmov s3, w3 // s3 = 0.8

    mov x10, x18

    sub x4, x15, 12
    add x5, x16, 27

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    add x4, x15, 27
    sub x5, x16, 7

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19

    add x3, x15, 60
    sub x4, x16, 46

    add x5, x15, 22
    add x6, x16, 12

    sub x7, x15, 12
    sub x8, x16, 22

    bl paintRoundedTriangle

    //// Second Wing
    sub x3, x15, 60
    add x4, x16, 46

    sub x5, x15, 22
    sub x6, x16, 12

    add x7, x15, 12
    add x8, x16, 22

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    sub x4, x15, 35
    sub x5, x16, 45

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    sub x4, x15, 33
    sub x5, x16, 42

    mov x6, 10
    mov x7, 4

    bl paintEllipse

    //// First Part
    mov x10, x19
    sub x3, x15, 44
    sub x4, x16, 10
   
    sub x5, x15, 12
    sub x6, x16, 24

    sub x7, x15, 39
    sub x8, x16, 39

    bl paintRoundedTriangle

    //// Second Part
    sub x3, x15, 3
    sub x4, x16, 51
   
    sub x5, x15, 17
    sub x6, x16, 19

    sub x7, x15, 32
    sub x8, x16, 46

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 52429
	movk w3, 0x400c, lsl 16
	fmov s3, w3 // s3 = 0.8

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane 
    add x3, x15, 43
    add x4, x16, 55
    
    add x5, x15, 5
    add x6, x16, 50

    add x7, x15, 48
    add x8, x16, 12

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    add x4, x15, 8
    add x5, x16, 10

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    South:
    // Paint Wings  

    //// Turbines 
    mov	w3, 62915
	movk w3, 0x3fc8, lsl 16
	fmov s3, w3 // s3 = 1.57

    mov x10, x18

    sub x4, x15, 23
    add x5, x16, 10

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    add x4, x15, 23
    add x5, x16, 10

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19
    sub x3, x15, 50  
    mov x4, x16

    mov x5, x15
    sub x6, x16, 23

    mov x7, x15
    add x8, x16, 23

    bl paintRoundedTriangle

    //// Second Wing
    add x3, x15, 50  
    mov x4, x16

    mov x5, x15
    sub x6, x16, 23

    mov x7, x15
    add x8, x16, 23

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    mov x4, x15
    sub x5, x16, 55

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    mov x4, x15
    sub x5, x16, 53

    mov x6, 9
    mov x7, 4

    bl paintEllipse

    //// First Part
    mov x10, x19
    sub x3, x15, 25
    sub x4, x16, 55
   
    sub x5, x15, 10
    sub x6, x16, 20

    add x7, x15, 5 
    sub x8, x16, 50

    bl paintRoundedTriangle

    //// Second Part
    add x3, x15, 25
    sub x4, x16, 55
   
    add x5, x15, 10
    sub x6, x16, 20

    sub x7, x15, 5 
    sub x8, x16, 50

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 62915
	movk w3, 0x3fc8, lsl 16
	fmov s3, w3 // s3 = 1.57

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane  
    mov x3, x15
    add x4, x16, 61
    
    sub x5, x15, 10
    add x6, x16, 41

    add x7, x15, 10
    add x8, x16, 41

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    mov x4, x15
    add x5, x16, 10

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    Southwest:
    // Paint Wings  

    //// Turbines
    mov	w3, 26214
	movk w3, 0x3f66, lsl 16
	fmov s3, w3 // s3 = -0.8

    mov x10, x18

    add x4, x15, 12
    add x5, x16, 27

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    sub x4, x15, 27
    sub x5, x16, 7

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19

    sub x3, x15, 60
    sub x4, x16, 46

    sub x5, x15, 22
    add x6, x16, 12

    add x7, x15, 12
    sub x8, x16, 22

    bl paintRoundedTriangle

    //// Second Wing
    add x3, x15, 60
    add x4, x16, 46

    add x5, x15, 22
    sub x6, x16, 12

    sub x7, x15, 12
    add x8, x16, 22

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    add x4, x15, 35
    sub x5, x16, 45

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    add x4, x15, 33
    sub x5, x16, 42

    mov x6, 10
    mov x7, 4

    bl paintEllipse

    //// First Part
    mov x10, x19
    add x3, x15, 44
    sub x4, x16, 10
   
    add x5, x15, 12
    sub x6, x16, 24

    add x7, x15, 39
    sub x8, x16, 39

    bl paintRoundedTriangle

    //// Second Part
    add x3, x15, 3
    sub x4, x16, 51
   
    add x5, x15, 17
    sub x6, x16, 19

    add x7, x15, 32
    sub x8, x16, 46

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 26214
	movk w3, 0x3f66, lsl 16
	fmov s3, w3 // s3 = -0.8

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane 
    sub x3, x15, 43
    add x4, x16, 52
    
    sub x5, x15, 5
    add x6, x16, 47

    sub x7, x15, 48
    add x8, x16, 9

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    sub x4, x15, 8
    add x5, x16, 10

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    West:
    // Paint Wings  

    //// Turbines 
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x10, x18

    sub x4, x15, 10
    sub x5, x16, 23

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    sub x4, x15, 10
    add x5, x16, 23

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19
    mov x3, x15 
    sub x4, x16, 50

    sub x5, x15, 23
    mov x6, x16

    add x7, x15, 23
    mov x8, x16

    bl paintRoundedTriangle

    //// Second Wing
    mov x3, x15  
    add x4, x16, 50

    sub x5, x15, 23
    mov x6, x16

    add x7, x15, 23
    mov x8, x16

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    add x4, x15, 55
    mov x5, x16

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    add x4, x15, 53
    mov x5, x16

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    //// First Part
    mov x10, x19
    add x3, x15, 55
    sub x4, x16, 25
   
    add x5, x15, 20
    sub x6, x16, 10

    add x7, x15, 50
    add x8, x16, 5 

    bl paintRoundedTriangle

    //// Second Part
    add x3, x15, 55
    add x4, x16, 25
   
    add x5, x15, 20
    add x6, x16, 10

    add x7, x15, 50
    sub x8, x16, 5 

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane  
    sub x3, x15, 61
    mov x4, x16
    
    sub x5, x15, 41
    sub x6, x16, 10

    sub x7, x15, 41
    add x8, x16, 10

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    sub x4, x15, 10
    mov x5, x16

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    b end_paint_plane

    ///////////////////////////////////////////////////////////////////////
    Northwest:
    // Paint Wings  

    //// Turbines
    mov	w3, 52429
	movk w3, 0x400c, lsl 16
	fmov s3, w3 // s3 = 0.8

    mov x10, x18

    sub x4, x15, 27
    add x5, x16, 2

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    add x4, x15, 10
    sub x5, x16, 27

    mov x6, 20
    mov x7, 7

    bl paintEllipse 

    //// First Wing
    mov x10, x19

    add x3, x15, 60
    sub x4, x16, 46

    add x5, x15, 22
    add x6, x16, 12

    sub x7, x15, 12
    sub x8, x16, 22

    bl paintRoundedTriangle

    //// Second Wing
    sub x3, x15, 60
    add x4, x16, 46

    sub x5, x15, 22
    sub x6, x16, 12

    add x7, x15, 12
    add x8, x16, 22

    bl paintRoundedTriangle

    // Paint Tail

    //// Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    add x4, x15, 32
    add x5, x16, 43

    mov x6, 12
    mov x7, 7

    bl paintEllipse

    //// Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    add x4, x15, 30
    add x5, x16, 40

    mov x6, 10
    mov x7, 4

    bl paintEllipse 

    //// First Part
    mov x10, x19
    add x3, x15, 44
    add x4, x16, 10
   
    add x5, x15, 12
    add x6, x16, 24

    add x7, x15, 39
    add x8, x16, 39

    bl paintRoundedTriangle

    //// Second Part
    add x3, x15, 3
    add x4, x16, 51
   
    add x5, x15, 17
    add x6, x16, 19

    add x7, x15, 32
    add x8, x16, 46

    bl paintRoundedTriangle

    // Paint Plane

    //// Main body
    mov x10, x18
    mov	w3, 52429
	movk w3, 0x400c, lsl 16
	fmov s3, w3 // s3 = 0.8

    mov x4, x15
    mov x5, x16

    mov x6, 55
    mov x7, 15

    bl paintEllipse 

    //// Nose of Plane 
    sub x3, x15, 43
    sub x4, x16, 55
    
    sub x5, x15, 5
    sub x6, x16, 50

    sub x7, x15, 48
    sub x8, x16, 12

    bl paintRoundedTriangle

    //// WindShield
    movz x10, 0x6b, lsl 16
    movk x10, 0xade3, lsl 0

    sub x4, x15, 8
    sub x5, x16, 10

    mov x6, 20
    mov x7, 10

    bl paintEllipse 

    end_paint_plane:
    
    ldur x19, [sp,104]
    ldur x18, [sp,96]
    ldur x17, [sp,88]
    ldur x16, [sp,80]   
    ldur x15, [sp,72]   
    ldur x10, [sp,64]   
    ldur x9, [sp,56]   
    ldur x8, [sp,48]    
    ldur x7, [sp,40]    
    ldur x6, [sp,32]    
    ldur x5, [sp,24]    
    ldur x4, [sp,16]
    ldur x3, [sp,8]
    ldur lr, [sp]    
    add sp, sp, 112
    ret

paintMissile:
    // Paints a Missile centered at (x0, y0) coordenates
    // (x15, x16) -> Center of the Missile
    // x17 -> Direction of the Missile:
    //                             (1) North
    //                             (2) Northeast
    //                             (3) East
    //                             (4) Southeast
    //                             (5) South
    //                             (6) Southwest
    //                             (7) West
    //                             (8) Northwest
    //                             (Other) Failure
    // x10 -> Colour
    //
    // Disclaimer: The Missile will always have the same size

    sub sp, sp, 104
    stur x18, [sp,96]   // Colour
    stur x17, [sp,88]   // Direction of the Missile
    stur x16, [sp,80]   // y0
    stur x15, [sp,72]   // x0
    stur x10, [sp,64]   
    stur x9, [sp,56]   
    stur x8, [sp,48]    
    stur x7, [sp,40]    
    stur x6, [sp,32]    
    stur x5, [sp,24]    
    stur x4, [sp,16]
    stur x3, [sp,8]
    stur lr, [sp]       // return pointer


    movz x10, 0xe3, lsl 16
	movk x10, 0xe1d3, lsl 0
    // First we check the Direction of the Missile 
    cmp x17, 1
    b.eq North_m
    cmp x17, 2
    b.eq Northeast_m
    cmp x17, 3
    b.eq East_m
    cmp x17, 4
    b.eq Southeast_m
    cmp x17, 5
    b.eq South_m
    cmp x17, 6
    b.eq Southwest_m
    cmp x17, 7
    b.eq West_m
    cmp x17, 8
    b.eq Northwest_m
    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    North_m:
    // Main Body
    mov	w3, 62915
	movk w3, 0x3fc8, lsl 16
	fmov s3, w3 // s3 = 1.57

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 10

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    mov x4, x15
    add x5, x16, 33

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    mov x4, x15
    add x5, x16, 28

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile 
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov x3, x15
    sub x4, x16, 28
    
    sub x5, x15, 10
    sub x6, x16, 8

    add x7, x15, 10
    sub x8, x16, 8

    bl paintRoundedTriangle 

    // Back of Missile 
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0

    mov x3, x15
    add x4, x16, 12
    
    sub x5, x15, 10
    add x6, x16, 32

    add x7, x15, 10
    add x8, x16, 32

    bl paintRoundedTriangle 

    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    Northeast_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 26214
	movk w3, 0x3f66, lsl 16
	fmov s3, w3 // s3 = -0.8

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 9

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    sub x4, x15, 20
    add x5, x16, 25

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    sub x4, x15, 18
    add x5, x16, 22

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    add x3, x15, 20
    sub x4, x16, 27
    
    sub x5, x15, 11
    sub x6, x16, 18

    add x7, x15, 28
    add x8, x16, 16

    // Back of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    sub x3, x15, 7
    add x4, x16, 5
    
    sub x5, x15, 28
    add x6, x16, 14

    add x7, x15, 1
    add x8, x16, 38

    bl paintRoundedTriangle

    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    East_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 10

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    sub x4, x15, 33
    mov x5, x16

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    sub x4, x15, 28
    mov x5, x16

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    add x3, x15, 30
    mov x4, x16
    
    add x5, x15, 10
    sub x6, x16, 10

    add x7, x15, 10
    add x8, x16, 10

    bl paintRoundedTriangle

    // Back of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    sub x3, x15, 10
    mov x4, x16
    
    sub x5, x15, 30
    sub x6, x16, 10

    sub x7, x15, 30
    add x8, x16, 10

    bl paintRoundedTriangle

    b end_paint_missile

 
    ///////////////////////////////////////////////////////////////////////
    Southeast_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 52429
	movk w3, 0x400c, lsl 16
	fmov s3, w3 // s3 = 0.8

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 10

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    sub x4, x15, 20
    sub x5, x16, 27

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    sub x4, x15, 18
    sub x5, x16, 24

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    add x3, x15, 20
    add x4, x16, 23
    
    sub x5, x15, 18
    add x6, x16, 23

    add x7, x15, 25
    sub x8, x16, 12

    bl paintRoundedTriangle

    // Back of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    sub x3, x15, 5
    sub x4, x16, 4
    
    sub x5, x15, 43
    sub x6, x16, 4

    mov x7, x15
    sub x8, x16, 29

    bl paintRoundedTriangle

    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    South_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 62915
	movk w3, 0x3fc8, lsl 16
	fmov s3, w3 // s3 = 1.57

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 10

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    mov x4, x15
    sub x5, x16, 33

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    mov x4, x15
    sub x5, x16, 28

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile 
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov x3, x15
    add x4, x16, 28
    
    sub x5, x15, 10
    add x6, x16, 8

    add x7, x15, 10
    add x8, x16, 8

    bl paintRoundedTriangle 

    // Back of Missile 
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov x3, x15
    sub x4, x16, 12
    
    sub x5, x15, 10
    sub x6, x16, 32

    add x7, x15, 10
    sub x8, x16, 32

    bl paintRoundedTriangle 

    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    Southwest_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 26214
	movk w3, 0x3f66, lsl 16
	fmov s3, w3 // s3 = -0.8

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 9

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    add x4, x15, 18
    sub x5, x16, 25

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    add x4, x15, 16
    sub x5, x16, 22

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    sub x3, x15, 20
    add x4, x16, 27
    
    add x5, x15, 11
    add x6, x16, 18

    sub x7, x15, 28
    sub x8, x16, 16

    // Back of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    add x3, x15, 7
    sub x4, x16, 5
    
    add x5, x15, 28
    sub x6, x16, 14

    sub x7, x15, 1
    sub x8, x16, 38

    bl paintRoundedTriangle

    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    West_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 10

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0
    add x4, x15, 33
    mov x5, x16

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    add x4, x15, 28
    mov x5, x16

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    sub x3, x15, 30
    mov x4, x16
    
    sub x5, x15, 10
    sub x6, x16, 10

    sub x7, x15, 10
    add x8, x16, 10

    bl paintRoundedTriangle

    // Back of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    add x3, x15, 10
    mov x4, x16
    
    add x5, x15, 30
    sub x6, x16, 10

    add x7, x15, 30
    add x8, x16, 10

    bl paintRoundedTriangle

    b end_paint_missile


    ///////////////////////////////////////////////////////////////////////
    Northwest_m:
    // Main Body
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    mov	w3, 52429
	movk w3, 0x400c, lsl 16
	fmov s3, w3 // s3 = 0.8

    mov x4, x15
    mov x5, x16

    mov x6, 22
    mov x7, 10

    bl paintEllipse

    // Red Fire 
    movz x10, 0xe6, lsl 16
	movk x10, 0x1710, lsl 0

    add x4, x15, 19
    add x5, x16, 24

    mov x6, 10
    mov x7, 5

    bl paintEllipse

    // Yellow Fire
    movz x10, 0xed, lsl 16
	movk x10, 0xca02, lsl 0
    add x4, x15, 18
    add x5, x16, 22

    mov x6, 9
    mov x7, 4

    bl paintEllipse 

    // Nose of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0 
    sub x3, x15, 20
    sub x4, x16, 23
    
    add x5, x15, 18
    sub x6, x16, 23

    sub x7, x15, 25
    add x8, x16, 12

    bl paintRoundedTriangle

    // Back of Missile
    movz x10, 0x80, lsl 16
	movk x10, 0x8080, lsl 0
    add x3, x15, 5
    add x4, x16, 4
    
    add x5, x15, 43
    add x6, x16, 4

    mov x7, x15
    add x8, x16, 29

    bl paintRoundedTriangle

    end_paint_missile:
    
    ldur x18,[sp,96]
    ldur x17,[sp,88]
    ldur x16,[sp,80]   
    ldur x15,[sp,72]   
    ldur x10,[sp,64]   
    ldur x9, [sp,56]   
    ldur x8, [sp,48]    
    ldur x7, [sp,40]    
    ldur x6, [sp,32]    
    ldur x5, [sp,24]    
    ldur x4, [sp,16]
    ldur x3, [sp,8]
    ldur lr, [sp]    
    add sp, sp, 104
    ret

paintCloudTypeOne:
    // Paints a Cloud One centered at (x0, y0) coordenates
    // (x15, x16) -> Center of the Cloud
    // x10 -> Colour
    //
    // Disclaimer: The Cloud One will always have the same size

    sub sp, sp, 72
    stur x16,[sp,64]   // y0
    stur x15,[sp,56]   // x0
    stur x10,[sp,48]   // colour 
    stur x7, [sp,40]    
    stur x6, [sp,32]    
    stur x5, [sp,24]    
    stur x4, [sp,16]
    stur x3, [sp,8]
    stur lr, [sp]       // return pointer

    movz x10, 0xff, lsl 16 
    movk x10, 0xffff, lsl 0

    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x4, x15
    mov x5, x16

    mov x6, 40
    mov x7, 15

    bl paintEllipse

    mov x3, 15

    add x4, x15, 30
    add x5, x16, 0 

    bl paintCircle

    add x4, x15, 20
    add x5, x16, 10

    bl paintCircle

    add x4, x15, 0
    add x5, x16, 10

    bl paintCircle

    sub x4, x15, 5
    sub x5, x16, 5

    bl paintCircle

    sub x4, x15, 20
    sub x5, x16, 0

    bl paintCircle

    sub x4, x15, 25
    add x5, x16, 5

    bl paintCircle

    ldur x16, [sp,64]  
    ldur x15, [sp,56]   
    ldur x10, [sp,48]   
    ldur x7, [sp,40]    
    ldur x6, [sp,32]    
    ldur x5, [sp,24]
    ldur x4, [sp,16]
    ldur x3, [sp,8]
    ldur lr, [sp]       // return pointer
    add sp, sp, 72
    ret 

paintCloudTypeTwo:
    // Paints a Cloud Two centered at (x0, y0) coordenates
    // (x15, x16) -> Center of the Cloud
    // x10 -> Colour
    //
    // Disclaimer: The Cloud Two will always have the same size

    sub sp, sp, 72
    stur x16, [sp,64]
    stur x15, [sp,56]   // y0
    stur x10, [sp,48]   // x0
    stur x7, [sp,40]    // colour 
    stur x6, [sp,32]    
    stur x5, [sp,24]    
    stur x4, [sp,16]
    stur x3, [sp,8]
    stur lr, [sp]       // return pointer

    movz x10, 0xff, lsl 16 
    movk x10, 0xffff, lsl 0
    
    mov	w3, 0
	fmov s3, w3 // s3 = 0

    mov x4, x15
    mov x5, x16

    mov x6, 40
    mov x7, 15

    bl paintEllipse

    mov x3, 15

    add x4, x15, 15
    sub x5, x16, 15 

    bl paintCircle

    sub x4, x15, 20
    sub x5, x16, 10

    bl paintCircle

    add x4, x15, 30
    sub x5, x16, 3

    bl paintCircle

    sub x4, x15, 30
    sub x5, x16, 3

    bl paintCircle

    add x4, x15, 0
    sub x5, x16, 10

    bl paintCircle

    sub x4, x15, 15
    add x5, x16, 5

    bl paintCircle

    ldur x16, [sp,64]  
    ldur x15, [sp,56]   
    ldur x10, [sp,48]   
    ldur x7, [sp,40]    
    ldur x6, [sp,32]    
    ldur x5, [sp,24]
    ldur x4, [sp,16]
    ldur x3, [sp,8]
    ldur lr, [sp]       // return pointer
    add sp, sp, 72
    ret

.endif
