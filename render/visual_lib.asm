%ifndef VISUAL_LIB_ASM
%define VISUAL_LIB_ASM

extern XOpenDisplay
extern XDefaultScreen
extern XRootWindow
extern XCreateSimpleWindow
extern XMapWindow
extern XDefaultGC
extern XCreateImage
extern XPutImage
extern XFlush
extern XDestroyImage
extern XDefaultVisual
extern XInitImage
extern XPutPixel
extern XCloseDisplay
extern XNextEvent
extern XSelectInput
extern XQueryPointer
extern calloc

section .text
global setup_window, update_window, clean_up_gui, draw_pixel, draw_simple_line, get_mouse_position

; ###############################################
; # setup_window                                #
; #                                             #
; # Parameters:                                 #
; #     rdi: x resolution                       #
; #     rsi: y resolution                       #
; #     rdx: bits per pixel (32)                #
; #                                             #
; ###############################################
setup_window:
    mov     [x_res], rdi
    mov     [y_res], rsi
    mov     [bpp], rdx

    ; Open X display
    xor     rdi, rdi            ; Display* = NULL -> default display
    call    XOpenDisplay
    cmp     rax, 0
    je      setup_window.open_error
    jmp     setup_window.continue_setup
.open_error:
    mov     rdi, err_msg_vlasm
    call    printstr
    call    endl
    mov     rdi, 1
    call    exit
.continue_setup:
    mov     [disp], rax         ; save Display* in rdi for later

    ; Get default screen
    mov     rdi, [disp]
    call    XDefaultScreen
    mov     [screen], eax

    ; Get root window
    mov     rdi, [disp]
    mov     rsi, [screen]
    call    XRootWindow
    mov     [root_win], rax

    ; Create simple window
    mov     rdi, [disp]
    mov     rsi, [root_win]     ; parent
    mov     rdx, 100            ; x
    mov     rcx, 100            ; y
    mov     r8, [x_res]         ; width
    mov     r9, [y_res]         ; height
    ; Push remaining 3 args in reverse order
    sub     rsp, 32                     ; allocate 3 qwords on stack
    mov     qword [rsp], 0xffffff       ; background
    mov     qword [rsp+8], 0x000000     ; border
    mov     qword [rsp+16], 0           ; border width
    call    XCreateSimpleWindow

    add     rsp, 32             ; restore stack
    mov     [window], rax

    mov     rdi, [disp]         ; Display*
    mov     rsi, [window]       ; Window
    mov     rdx, 0x8000         ; ExposureMask
    call    XSelectInput


    ; Map window (make it visible)
    mov     rdi, [disp]         ; Display*
    mov     rsi, [window]
    call    XMapWindow
    mov     rdi, [disp]
    call    XFlush

    ; Get default graphics context
    mov     rdi, [disp]
    call    XDefaultGC
    mov     [gc], rax

    ; Create XImage
    mov     rdi, [disp]
    mov     rsi, [screen]
    call    XDefaultVisual
    mov     r15, rax
    

    ; initilize xImage -> data
    ; size = width * height * (bpp / 8)
    mov     rax, [x_res]
    imul    rax, [y_res]    ; width*height
    mov     rdi, rax
    mov     rax, [bpp]
    shr     rax, 3          ; convert bits -> bytes
    mov     rsi, rax
    call    calloc          ; returns pointer in rax

; 	XImage *XCreateImage(
;       Display *display, 
;       Visual *visual, 
;       unsigned int depth, 
;       int format, 
;       int offset, 
;       char *data, 
;       unsigned int width, 
;       unsigned int height, 
;       int bitmap_pad, 
;       int bytes_per_line);    
    mov     rdi, [disp]         ; display*
    mov     rsi, r15            ; Visual* from XDefaultVisual
    mov     rdx, 24             ; depth
    mov     rcx, 2              ; ZPixmap
    xor     r8, r8              ; offset
    mov     r9, rax             ; data = NULL

    ; 7th-10th args on stack: width, height, bitmap_pad, bytes_per_line
    ; align stack to 16 bytes before call
    sub     rsp, 32             ; allocate 32 bytes (stack args + alignment)
    mov     rax, [x_res]
    mov     qword [rsp], rax    ; width
    mov     rax, [y_res]
    mov     qword [rsp+8], rax  ; height
    mov     qword [rsp+16], 32  ; bitmap_pad
    mov     qword [rsp+24], 0   ; bytes_per_line
    call    XCreateImage
    add     rsp, 32
    mov     [ximage], rax
    test    rax, rax
    jz      .open_error

    call    wait_for_exposure

    ret


get_mouse_position:
    mov     r10, rdi        ; x_out
    mov     r11, rsi        ; y_out
    mov     r12, rdx        ; mouse mask
    
    push    r10
    push    r11

    mov qword [root_x], 0
    mov qword [root_y], 0

    sub     rsp, 32

    mov     rdi, [disp]
    mov     rsi, [window]

    lea     rdx, [root_ret]
    lea     rcx, [child_ret]

    lea     r8,  [root_x]
    lea     r9,  [root_y]

    lea     rax, [mask_ret]
    mov     [rsp + 16], rax
    lea     rax, [win_x]
    mov     [rsp + 0], rax
    lea     rax, [win_y]
    mov     [rsp + 8], rax

    call    XQueryPointer
    add     rsp, 32
    ;       win x now contains x pos 
    ;       win y now contains y pos
    
    mov     r13, rax    ; save output
    ; run bounds checks on win_x and win_y
    mov     eax, [win_x]
    cmp     eax, 0
    jl      get_mouse_position.invalid_win
    mov     ebx, [x_res]
    cmp     eax, ebx
    jg      get_mouse_position.invalid_win

.verify_win_y
    mov     eax, [win_y]
    cmp     eax, 0
    jl      get_mouse_position.invalid_win
    mov     ebx, [y_res]
    cmp     eax, ebx
    jg      get_mouse_position.invalid_win
    jmp     get_mouse_position.end_checks

.invalid_win:
    ; set response to invalid position
    mov     r13, 0

.end_checks:

    pop     r11
    pop     r10

    mov     rax, [win_x]
    mov     [r10], rax

    mov     rax, [win_y]
    mov     [r11], rax

    mov     rax, [mask_ret]
    mov     [r12], rax

    mov     rax, r13

    ret

; ###############################################
; # update_window                               #
; #                                             #
; ###############################################
update_window:
    mov     rdi, [disp]         ; Display*
    mov     rsi, [window]       ; Drawable
    mov     rdx, [gc]           ; GC
    mov     rcx, [ximage]       ; XImage*
    xor     r8, r8              ; src_x = 0
    xor     r9, r9              ; src_y = 0
    ; 6th-9th args on stack: width, height, dest_x, dest_y
    mov     rax, [y_res]
    push    rax ; height
    mov     rax, [x_res]
    push    rax   ; width
    xor     rax, rax
    push    rax ; dest_y = 0
    push    rax ; dest_x = 0
    call    XPutImage
    add     rsp, 32
    mov     rdi, [disp]
    call    XFlush
    ret

; ###############################################
; # clean_up_gui                                #
; #                                             #
; ###############################################
clean_up_gui:
    mov     rdi, [ximage]
    call    XDestroyImage
    mov     rdi, [disp]
    call    XCloseDisplay
    ret

wait_for_exposure:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 192        ; allocate XEvent
.exposure_loop:
    mov     rdi, [disp]     ; Display*
    mov     rsi, rsp        ; XEvent*
    call    XNextEvent
    mov     eax, [rsp]
    cmp     eax, 12
    jne     wait_for_exposure.exposure_loop
    mov     rsp, rbp
    pop     rbp
    ret

; ###############################################
; # draw_pixel                                  #
; #                                             #
; # Parameters:                                 #
; #     rdi: x pos                              #
; #     rsi: y pos                              #
; #     rdx: color (0xAARRGGBB)                 #
; #                                             #
; ###############################################
draw_pixel:
    push    rcx
    push    r8
    push    r9
    push    r10 

    mov     r8, rdi
    mov     r9, rsi
    mov     r10, rdx

    mov     rdi, [ximage]
    mov     rsi, r8
    mov     rdx, r9
    mov     rcx, r10
    call    XPutPixel

    pop     r10
    pop     r9
    pop     r8
    pop     rcx
    ret     

; ###############################################
; # draw_simple_line                            #
; #                                             #
; # Parameters:                                 #
; #     rdi: x0 pos                             #
; #     rsi: y0 pos                             #
; #     rdx: x1 pos                             #
; #     rcx: x1 pos                             #
; #     r8: color (0xAARRGGBB)                  #
; #                                             #
; ###############################################
draw_simple_line:
    push    rbp
    mov     rbp, rsp
    
    ;Set up stack
    sub     rsp, 64
    mov     [rbp-8], rdi    ;x0
    mov     [rbp-16], rsi   ;y0
    mov     [rbp-24], rdx   ;x1
    mov     [rbp-32], rcx   ;y1
    mov     [rbp-40], r8    ;color
    ;       [rbp-48] abs(dy)
    ;       [rbp-56] abs(dx)

    mov     rax, [rbp-24]
    sub     rax, [rbp-8]
    mov     [rbp-56], rax   ; dx = x1 - x0
    cmp     rax, 0
    jge     draw_simple_line.calc_dy
    neg     rax
    mov     [rbp-56], rax   ; dx = -dx
.calc_dy:
    mov     rax, [rbp-32]
    sub     rax, [rbp-16]
    mov     [rbp-48], rax   ;dy = y1 - y0
    cmp     rax, 0
    jge     draw_simple_line.determine_plot
    neg     rax
    mov     [rbp-48], rax   ; dy = -dy
.determine_plot:
    mov     rax, [rbp-48]
    cmp     rax, [rbp-56]   ; dy cmp dx
    jge     draw_simple_line.small_dx
.small_dy:
    ; abs(dy) < abs(dx)
    mov     rax, [rbp-8]
    cmp     rax, [rbp-24]   ;x0 cmp x1
    jle     draw_simple_line.small_x0    
    .large_x0:
    mov     rdi, [rbp-24]   ;x1
    mov     rsi, [rbp-32]   ;y1
    mov     rdx, [rbp-8]    ;x0
    mov     rcx, [rbp-16]   ;y0
    mov     r8, [rbp-40]
    call    draw_line_low
    jmp     draw_simple_line.clean_stack_ret
    .small_x0:
    mov     rdi, [rbp-8]    ;x0
    mov     rsi, [rbp-16]   ;y0
    mov     rdx, [rbp-24]   ;x1
    mov     rcx, [rbp-32]   ;y1
    mov     r8, [rbp-40]
    call    draw_line_low
    jmp     draw_simple_line.clean_stack_ret
.small_dx:
    ; abs(dy) >= abs(dx)
    mov     rax, [rbp-16]
    cmp     rax, [rbp-32]   ;y0 cmp y1
    jle     draw_simple_line.small_y0    
    .large_y0:
    mov     rdi, [rbp-24]   ;x1
    mov     rsi, [rbp-32]   ;y1
    mov     rdx, [rbp-8]    ;x0
    mov     rcx, [rbp-16]   ;y0
    mov     r8, [rbp-40]
    call    draw_line_high
    jmp     draw_simple_line.clean_stack_ret
    .small_y0:
    mov     rdi, [rbp-8]    ;x0
    mov     rsi, [rbp-16]   ;y0
    mov     rdx, [rbp-24]   ;x1
    mov     rcx, [rbp-32]   ;y1
    mov     r8, [rbp-40]
    call    draw_line_high
    jmp     draw_simple_line.clean_stack_ret
.clean_stack_ret:
    mov     rsp, rbp
    pop     rbp
    ret


draw_line_low:
    push    rbp
    mov     rbp, rsp
    
    ;Set up stack
    sub     rsp, 80
    mov     [rbp-8], rdi    ;x0 / x
    mov     [rbp-16], rsi   ;y0 / y
    mov     [rbp-24], rdx   ;x1
    mov     [rbp-32], rcx   ;y1
    mov     [rbp-40], r8    ;color
    ;       [rbp-48] dy
    ;       [rbp-56] dx
    ;       [rbp-64] yi
    ;       [rbp-72] D

    mov     rax, [rbp-24]
    sub     rax, [rbp-8]
    mov     [rbp-56], rax   ; dx = x1 - x0

    mov     rax, [rbp-32]
    sub     rax, [rbp-16]
    mov     [rbp-48], rax   ;dy = y1 - y0

    mov     rax, 1
    mov     [rbp-64], rax
    mov     rax, [rbp-48]
    cmp     rax, 0
    jge     draw_line_low.calculate_d
    mov     rax, [rbp-48]
    neg     rax 
    mov     [rbp-48], rax   ; dy = -dy
    mov     rax, -1
    mov     [rbp-64], rax   ;yi = -1

.calculate_d:
    mov     rax, [rbp-48]
    shl     rax, 1
    sub     rax, [rbp-56]
    mov     [rbp-72], rax   ; D = (2 * dy) - dx

.loop:
    mov     rdi, [rbp-8]
    mov     rsi, [rbp-16]
    mov     rdx, [rbp-40]
    call    draw_pixel

    mov     rax, [rbp-72]
    cmp     rax, 0
    jle     draw_line_low.negative_d
    ; D > 0
    mov     rax, [rbp-16]
    add     rax, [rbp-64]
    mov     [rbp-16], rax   ; y = y + yi

    mov     rbx, [rbp-72]
    mov     rax, [rbp-48]
    sub     rax, [rbp-56]
    shl     rax, 1
    add     rax, rbx
    mov     [rbp-72], rax   ; D = D + (2 * (dy - dx))
    jmp     draw_line_low.continue_loop
.negative_d:
    ; D <= 0
    mov     rbx, [rbp-72]
    mov     rax, [rbp-48]
    shl     rax, 1
    add     rax, rbx
    mov     [rbp-72], rax   ; D = D + 2 * dy

.continue_loop:
    mov     rax, [rbp-8]
    inc     rax
    mov     [rbp-8], rax
    cmp     rax, [rbp-24]
    jle     draw_line_low.loop

    mov     rsp, rbp
    pop     rbp
    ret



draw_line_high:
    push    rbp
    mov     rbp, rsp
    
    ;Set up stack
    sub     rsp, 80
    mov     [rbp-8], rdi    ;x0 / x
    mov     [rbp-16], rsi   ;y0 / y
    mov     [rbp-24], rdx   ;x1
    mov     [rbp-32], rcx   ;y1
    mov     [rbp-40], r8    ;color
    ;       [rbp-48] dy
    ;       [rbp-56] dx
    ;       [rbp-64] xi
    ;       [rbp-72] D

    mov     rax, [rbp-24]
    sub     rax, [rbp-8]
    mov     [rbp-56], rax   ; dx = x1 - x0

    mov     rax, [rbp-32]
    sub     rax, [rbp-16]
    mov     [rbp-48], rax   ; dy = y1 - y0

    mov     rax, 1
    mov     [rbp-64], rax
    mov     rax, [rbp-56]
    cmp     rax, 0
    jge     draw_line_high.calculate_d
    mov     rax, [rbp-56]
    neg     rax
    mov     [rbp-56], rax   ; dx = -dx
    mov     rax, -1
    mov     [rbp-64], rax   ; xi = -1

.calculate_d:
    mov     rax, [rbp-56]
    shl     rax, 1
    sub     rax, [rbp-48]
    mov     [rbp-72], rax   ; D = (2 * dx) - dy

.loop:
    mov     rdi, [rbp-8]
    mov     rsi, [rbp-16]
    mov     rdx, [rbp-40]
    call    draw_pixel

    mov     rax, [rbp-72]
    cmp     rax, 0
    jle     draw_line_high.negative_d
    ; D > 0
    mov     rax, [rbp-8]
    add     rax, [rbp-64]
    mov     [rbp-8], rax    ; x = x + xi

    mov     rbx, [rbp-72]
    mov     rax, [rbp-56]
    sub     rax, [rbp-48]
    shl     rax, 1
    add     rax, rbx
    mov     [rbp-72], rax   ; D = D + (2 * (dx - dy))
    jmp     draw_line_high.continue_loop
.negative_d:
    ; D <= 0
    mov     rbx, [rbp-72]
    mov     rax, [rbp-56]
    shl     rax, 1
    add     rax, rbx
    mov     [rbp-72], rax   ; D = D + 2 * dx

.continue_loop:
    mov     rax, [rbp-16]
    inc     rax
    mov     [rbp-16], rax
    cmp     rax, [rbp-32]
    jle     draw_line_high.loop

    mov     rsp, rbp
    pop     rbp
    ret

section .data
    err_msg_vlasm   db "Failed to open X display",0

section .bss
    x_res       resq 1
    y_res       resq 1
    bpp         resq 1
    screen      resd 1
    disp        resq 1      ; display pointer
    root_win    resq 1
    window      resq 1      
    gc          resq 1      ; graphics context pointer
    ximage      resq 1      ; pixel buffer pointer

    root_ret    resq 1      ; Window
    child_ret   resq 1      ; Window

    root_x      resq 1
    root_y      resq 1
    win_x       resq 1
    win_y       resq 1
    mask_ret    resq 1

%endif