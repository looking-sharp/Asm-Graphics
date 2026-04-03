%include 'util/util.asm'
%include 'render/visual_lib.asm'

global main
section .text

main:
    mov     rdi, 640
    mov     rsi, 480
    mov     rdx, 32
    call    setup_window
    mov     r12, 10
    ; center = (320, 240)

    ; Octant 1 (right, shallow up)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 400
    mov     rcx, 270
    mov     r8, 0x00ff0000
    call    draw_simple_line

    ; Octant 2 (right, steep up)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 350
    mov     rcx, 350
    mov     r8, 0x0000ff00
    call    draw_simple_line

    ; Octant 3 (left, steep up)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 290
    mov     rcx, 350
    mov     r8, 0x000000ff
    call    draw_simple_line

    ; Octant 4 (left, shallow up)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 240
    mov     rcx, 270
    mov     r8, 0x00ffff00
    call    draw_simple_line

    ; Octant 5 (left, shallow down)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 240
    mov     rcx, 210
    mov     r8, 0x00ff00ff
    call    draw_simple_line

    ; Octant 6 (left, steep down)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 290
    mov     rcx, 130
    mov     r8, 0x0000ffff
    call    draw_simple_line

    ; Octant 7 (right, steep down)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 350
    mov     rcx, 130
    mov     r8, 0x00ffffff
    call    draw_simple_line

    ; Octant 8 (right, shallow down)
    mov     rdi, 320
    mov     rsi, 240
    mov     rdx, 400
    mov     rcx, 210
    mov     r8, 0x00888888
    call    draw_simple_line

    call    update_window


    mov     rcx, 0x3ffffffff ; about 5 seconds sleep
    loop_1:
        nop
        dec rcx
        cmp rcx, 0
        jnz loop_1

    call    clean_up_gui
    call    exit0