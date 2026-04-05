%ifndef MATRIX_LIB_ASM
%define MATRIX_LIB_ASM

%include 'vector/vector_lib.asm'
%include 'trig/sine.asm'
%include 'trig/cos.asm'
%include 'util/util.asm'

section .text
global Mat3, Matrix3_multiply_vector, Matrix3_build_cam_rotation_matrix

struc Mat3
  .c1 resb Vec3_size
  .c2 resb Vec3_size
  .c3 resb Vec3_size
endstruc

; ###############################################
; # Matrix3_multiply_vector                     #
; #                                             #
; # Parameters:                                 #
; #     rdi: matrix pointer                     #
; #     rsi: vector pointer                     #
; #     rdx: return vector pointer              #
; #                                             #
; ###############################################
Matrix3_multiply_vector:
    mov     rbx, rdi        ; matrix base
    mov     rcx, rdx        ; result base
    mov     r8, rsi

    mov     rdi, [rbx + Mat3.c1]   ; &matrix.c1
    mov     rsi, r8
    lea     rdx, [rcx + Vec3.x]    ; &result.x
    call    vector3_dot_product

    mov     rdi, [rbx + Mat3.c2]
    mov     rsi, r8
    lea     rdx, [rcx + Vec3.y]
    call    vector3_dot_product

    mov     rdi, [rbx + Mat3.c3]
    mov     rsi, r8
    lea     rdx, [rcx + Vec3.z]
    call    vector3_dot_product

    ret

; ###############################################
; # Matrix3_build_cam_rotation_matrix           #
; #                                             #
; # Parameters:                                 #
; #     rdi: cam location vector pointer        #
; #     rsi: cam looking at vector pointer      #
; #     rdx: global up vector pointer           #
; #     rdx: return matrix pointer              #
; #                                             #
; ###############################################
Matrix3_build_cam_rotation_matrix:
    push    r8
    push    r9
    push    r10
    push    r11

    mov     r8, rdi     ; looking
    mov     r9, rsi     ; pos
    mov     r10, rdx    ; global up
    mov     r11, rcx    ; matrix

    push    rbp
    mov     rbp, rsp

    sub     rsp, 32

    ; calc forward vector
    mov     rdi, r8
    mov     rsi, r9
    lea     rdx, [rbp-32]
    call    vector3_subtract

    lea     rdi, [rbp-32]
    call    vector3_to_unit    
    lea     rdi, [rbp-32]
    call    vector3_negate

    ; copy to matrix
    lea     rdi, [rbp-32]
    movsd   xmm0, [rdi + Vec3.x]
    movsd   [r11 + Mat3.c3 + Vec3.x], xmm0
    movsd   xmm0, [rdi + Vec3.y]
    movsd   [r11 + Mat3.c3 + Vec3.y], xmm0
    movsd   xmm0, [rdi + Vec3.z]
    movsd   [r11 + Mat3.c3 + Vec3.z], xmm0

    ; calc right vector
    mov     rdi, r10
    lea     rsi, [r11 + Mat3.c3]
    lea     rdx, [rbp-32]
    call    vector3_cross_product
    lea     rdi, [rbp-32]
    call    vector3_to_unit

    ; copy to matrix
    lea     rdi, [rbp-32]
    movsd   xmm0, [rdi + Vec3.x]
    movsd   [r11 + Mat3.c1 + Vec3.x], xmm0
    movsd   xmm0, [rdi + Vec3.y]
    movsd   [r11 + Mat3.c1 + Vec3.y], xmm0
    movsd   xmm0, [rdi + Vec3.z]
    movsd   [r11 + Mat3.c1 + Vec3.z], xmm0

    ; calc camera up (flipped from what it should be cause forward was negated)
    lea     rdi, [r11 + Mat3.c1]
    lea     rsi, [r11 + Mat3.c3]
    lea     rdx, [rbp-32]
    call    vector3_cross_product
    
    ; copy to matrix
    lea     rdi, [rbp-32]
    movsd   xmm0, [rdi + Vec3.x]
    movsd   [r11 + Mat3.c2 + Vec3.x], xmm0
    movsd   xmm0, [rdi + Vec3.y]
    movsd   [r11 + Mat3.c2 + Vec3.y], xmm0
    movsd   xmm0, [rdi + Vec3.z]
    movsd   [r11 + Mat3.c2 + Vec3.z], xmm0

    mov     rsp, rbp
    pop     rbp

    pop     r11
    pop     r10
    pop     r9
    pop     r8
    ret

; rdi: axis (0:x 1:y 2:z)
; rsi: matrix pointer
; Xmm0: theta (in radians)
Matrix3_get_rotation_matrix:
    push    rbp
    mov     rbp, rsp

    sub     rsp, 160
    ;       [rbp - 64]: sin
    ;       [rbp - 128]: cos
    movsd   xmm1, xmm0  ; save origional theta
    mov     rdx, rdi    ; save axis choice

    mov     rdi, [cordic_itr]
    movsd   xmm0, xmm1
    call    sine_cordic
    movsd   [rbp], xmm0

    mov     rdi, [cordic_itr]
    movsd   xmm0, xmm1
    call    cosine_cordic
    movsd   [rbp-128], xmm0

    movsd   xmm2, [rbp-128]  ; cos
    movsd   xmm3, [rbp-64]   ; sin
    movsd   xmm0, [zero]
    movsd   xmm1, [one]
    movsd   xmm5, xmm3
    movsd   xmm6, [neg_mask]
    xorpd   xmm5, xmm6      ; -sin

    mov     rax, rdx
    cmp     rax, 1
    jl      Matrix3_get_rotation_matrix.x_axis
    jg      Matrix3_get_rotation_matrix.z_axis
    je      Matrix3_get_rotation_matrix.y_axis

.x_axis:
    ; |1    0     0|
    movsd   [rsi + Mat3.c1 + Vec3.x], xmm1
    movsd   [rsi + Mat3.c1 + Vec3.y], xmm0
    movsd   [rsi + Mat3.c1 + Vec3.z], xmm0
    ; |0    cos -sin|
    movsd   [rsi + Mat3.c2 + Vec3.x], xmm0
    movsd   [rsi + Mat3.c2 + Vec3.y], xmm2
    movsd   [rsi + Mat3.c2 + Vec3.z], xmm5
    ; |0    sin  cos|
    movsd   [rsi + Mat3.c3 + Vec3.x], xmm0
    movsd   [rsi + Mat3.c3 + Vec3.y], xmm3
    movsd   [rsi + Mat3.c3 + Vec3.z], xmm2
    jmp     Matrix3_get_rotation_matrix.return_func
.y_axis:
    ; |cos  0   sin|
    movsd   [rsi + Mat3.c1 + Vec3.x], xmm2
    movsd   [rsi + Mat3.c1 + Vec3.y], xmm0
    movsd   [rsi + Mat3.c1 + Vec3.z], xmm3
    ; |0    1     0|
    movsd   [rsi + Mat3.c2 + Vec3.x], xmm0
    movsd   [rsi + Mat3.c2 + Vec3.y], xmm1
    movsd   [rsi + Mat3.c2 + Vec3.z], xmm0
    ; |-sin 0   cos|
    movsd   [rsi + Mat3.c3 + Vec3.x], xmm5
    movsd   [rsi + Mat3.c3 + Vec3.y], xmm0
    movsd   [rsi + Mat3.c3 + Vec3.z], xmm2
    jmp     Matrix3_get_rotation_matrix.return_func
.z_axis:
    ; |cos  -sin  0|
    movsd   [rsi + Mat3.c1 + Vec3.x], xmm2
    movsd   [rsi + Mat3.c1 + Vec3.y], xmm5
    movsd   [rsi + Mat3.c1 + Vec3.z], xmm0
    ; |sin  cos   0|
    movsd   [rsi + Mat3.c2 + Vec3.x], xmm3
    movsd   [rsi + Mat3.c2 + Vec3.y], xmm2
    movsd   [rsi + Mat3.c2 + Vec3.z], xmm0
    ; |0    0     1|
    movsd   [rsi + Mat3.c3 + Vec3.x], xmm0
    movsd   [rsi + Mat3.c3 + Vec3.y], xmm0
    movsd   [rsi + Mat3.c3 + Vec3.z], xmm1
    jmp     Matrix3_get_rotation_matrix.return_func
.return_func:
    mov     rsp, rbp
    pop     rbp
    ret

section .data
    cordic_itr: dq 8
    one: dq 1.0
    zero: dq 0


%endif