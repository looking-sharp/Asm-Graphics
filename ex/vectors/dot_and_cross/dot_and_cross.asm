%include '/util/util.asm'
%include '/vector/vector_lib.asm'
%include '/trig/sine.asm'
%include '/trig/cos.asm'
%include '/trig/tan.asm'

global main
section .text

main:
    mov     rdi, vec_1
    call    print_vector
    call    endl

    mov     rdi, vec_2
    call    print_vector
    call    endl

    mov     rdi, vec_1
    mov     rsi, vec_2
    mov     rdx, dot
    call    vector3_dot_product

    ; print out dot product result
    mov     rdi, dot_msg
    call    printstr
    movsd   xmm0, [dot]
    call    printflt
    call    endl

    mov     rdi, vec_1
    mov     rsi, vec_2
    mov     rdx, cross
    call    vector3_cross_product

    mov     rdi, crs_msg
    call    printstr
    mov     rdi, cross
    call    print_vector
    call    endl

    call    exit0

section .data
    vec_1:   dq 1.5, 2.0, 3.0
    vec_2:   dq 2.0, 3.0, 1.0
    dot_msg: db "dot: ", 0
    crs_msg: db "cross: ", 0

section .bss
    dot:    resq 1
    cross:  resb Vec3_size  