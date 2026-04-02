%include '../../util/util.asm'
%include '../../render/visual_lib.asm'

global main
section .text

main:
    mov     rdi, 640
    mov     rsi, 480
    mov     rdx, 32
    call    setup_window


    mov     r15, 0xfffff ; about 5 seconds sleep
    loop_1:
        lea     rdi, [mouse_x]
        lea     rsi, [mouse_y]
        lea     rdx, [mouse_msk]
        call    get_mouse_position
        test    rax, rax
        jnz     is_on_screen
        mov     rdi, nos_msg
        call    printstr
        call    endl
        jmp     end_loop

    is_on_screen:
        call    parse_mouse_data
    
    end_loop:
        dec     r15
        cmp     r15, 0
        jnz     loop_1

    call    clean_up_gui
    call    exit0


parse_mouse_data:
    mov     rdi, parse_msg1
    call    printstr
    mov     rdi, [mouse_x]
    call    printint
    mov     rdi, parse_msg2
    call    printstr
    mov     rdi, [mouse_y]
    call    printint
    mov     rdi, parse_msg3
    call    printstr
    mov     rdi, [mouse_msk]
    call    printint
    call    endl
    ret


section .data
    nos_msg     db "Not on screen",0
    parse_msg1  db "X: ",0
    parse_msg2  db ", Y: ",0
    parse_msg3  db " Msk: "

section .bss
    mouse_x     resq 1
    mouse_y     resq 1
    mouse_msk   resq 1