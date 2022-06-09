.ifndef utils_s
.equ utils_s, 0

.include "data.s"

// la valores en base a los que se calcula el tamaño de las 
// figuras es arbitrario. Se eligieron en función de como queda
// el resultado (imagen) final

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
        cmp x2, SCREEN_HEIGH                // y_coord - SCREEN_HEIGH ≥ 0 ?
        b.ge loop1End                       // we exceeded the boundaries of the framebuffer, exits
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
    //------------------
    sub sp, sp, 56      // reserve memory in the stack 
    stur x3, [sp,48]    // floor's initial x coordinate
    stur x4, [sp,40]    // floor's initial y coordinate
    stur x5, [sp,32]    // furniture width
    stur x7, [sp,24]     // furniture height
    stur x11,[sp,16]      // aux register  
    stur x12,[sp,8]      // aux register
    stur lr, [sp,0]
    //------------------

  // DUSK	
	mov x4, 520
	mov x5, 210
    mov x1, x4
    mov x2, x5 
	
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
    movz x10, 0x00, lsl 16
    movk x10, 0x0000, lsl 00    // border color

    mov x3, 210         // sets frame width
    lsr x8, x3, 1
    sub x1, x1, x8      // moves half the window's width left
    mov x4, 5           // window frame is 5 pixels tall 
    bl paintRectangle   // bottom frame

    mov x3, 5           // frame is 5 pixels wide
    mov x4, 110         // frame is x4 pixels tall
    sub x8, x4, 5
    sub x2, x2, x8
	bl paintRectangle   // left frame

    mov x3, 210
    mov x4, 5
    bl paintRectangle   // top frame

    sub x8, x3, 5
    add x1, x1, x8
    mov x3, 5
    mov x4, 110
    bl paintRectangle
     
  // WALL
    movz x10, 0xD0, lsl 16
    movk x10, 0xDDE4, lsl 00// grey

    // la coordenada y del tope del borde es la altura del rectángulo a pintar
    mov x4, x2          
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

.endif
