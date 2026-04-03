%include '/util/util.asm'
%include '/vector/vector_lib.asm'
%include '/vector/matrix_lib.asm'
%include '/trig/sine.asm'
%include '/trig/cos.asm'
%include '/trig/tan.asm'

global main
section .text

main:
    mov     rdi, msg1
    call    printstr
    mov     rdi, pos
    call    print_vector
    call    endl

    mov     rdi, msg2
    call    printstr
    mov     rdi, looking
    call    print_vector
    call    endl

    ; calc forward vector
    mov     rdi, looking
    mov     rsi, pos
    mov     rdx, forward
    call    vector3_subtract
    mov     rdi, forward
    call    vector3_to_unit

    mov     rdi, msg3
    call    printstr
    mov     rdi, forward
    call    print_vector
    call    endl

    ; calc right vector
    mov     rdi, global_up
    mov     rsi, forward
    mov     rdx, right
    call    vector3_cross_product
    mov     rdi, right
    call    vector3_to_unit

    mov     rdi, msg4
    call    printstr
    mov     rdi, right
    call    print_vector
    call    endl

    ; calc camera up
    mov     rdi, forward
    mov     rsi, right
    mov     rdx, cam_up
    call    vector3_cross_product

    mov     rdi, msg5
    call    printstr
    mov     rdi, cam_up
    call    print_vector
    call    endl


    mov     rdi, msg6
    call    printstr
    call    endl
    mov     rdi, right
    call    print_vector
    call    endl
    mov     rdi, cam_up
    call    print_vector
    call    endl
    mov     rdi, forward
    call    vector3_negate
    call    print_vector
    call    endl



    call    exit0

section .data
    pos:        dq 5.0, 2.0, 0.0    ; camera at
    looking:    dq 0.0, 0.0, 0.0    ; looking at 
    global_up:  dq 0.0, 1.0, 0.0    ; which was is 'up'

    msg1:       db "Position:   ", 0
    msg2:       db "Looking at: ", 0
    msg3:       db "Forward:    ", 0
    msg4:       db "Right:      ", 0
    msg5:       db "Camera Up:  ", 0
    msg6:       db "Rotation Matrix:", 0



section .bss
    forward:  resb Vec3_size
    right:    resb Vec3_size    
    cam_up:   resb Vec3_size
    rot_mtx   resb Mat3_size