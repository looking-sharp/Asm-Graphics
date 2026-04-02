%include '../../../util/util.asm'
%include '../../../render/visual_lib.asm'

global main
section .text

main:
    mov     rdi, 640
    mov     rsi, 480
    mov     rdx, 32
    call    setup_window


    mov     r15, 0xfffff ; about 20 seconds long
    loop_1:
        lea     rdi, [mouse_x]
        lea     rsi, [mouse_y]
        lea     rdx, [mouse_msk]
        call    get_mouse_position
        test    rax, rax
        jnz     is_on_screen
        jmp     end_loop

    is_on_screen:
        ; mask for left click
        mov     rax, 256            ; left button mask
        test    rax, [mouse_msk]    ; check if left button is currently down
        jz      left_released

        ; if left button is pressed now
        cmp     byte [left_pressed], 0
        jne     end_loop            ; still held down, don't toggle again

        ; toggle click_status
        mov     al, [click_status]
        xor     al, 1
        mov     [click_status], al
        call    toggle              ; only happens once per toggle

        ; mark left button as pressed
        mov     byte [left_pressed], 1
        jmp     end_loop

    left_released:
        ; button is released
        mov     byte [left_pressed], 0

    end_loop:
        dec     r15
        cmp     r15, 0
        jnz     loop_1

    call    clean_up_gui
    call    exit0

toggle:
    cmp     byte [click_status], 1
    jne     toggle.make_line
    
    ; first click, place a point where clicked
    mov     rdi, [mouse_x]
    mov     [prev_x], rdi
    mov     rsi, [mouse_y]
    mov     [prev_y], rsi
    mov     rdx, 0x00FFFFFF
    call    draw_pixel
    call    update_window
    jmp     toggle.return_to_main

.make_line:
    ; second click, draw a line from 1st pos to 2nd
    mov     rdi, [mouse_x]
    mov     rsi, [mouse_y]
    mov     rdx, [prev_x]
    mov     rcx, [prev_y]
    mov     r8, 0x00FFFFFF
    call    draw_simple_line
    call    update_window

.return_to_main:
    ret

section .data
    click_status    db 0
    left_pressed    db 0

section .bss
    mouse_x     resq 1
    mouse_y     resq 1
    mouse_msk   resq 1
    prev_x      resq 1
    prev_y      resq 1