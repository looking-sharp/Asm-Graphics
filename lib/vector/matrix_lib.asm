%ifndef MATRIX_LIB_ASM
%define MATRIX_LIB_ASM

%include 'vector/vector_lib.asm'

section .text
global Mat3, Matrix3_multiply_vector, Matrix3_build_rotation_matrix

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
; # Matrix3_multiply_vector                     #
; #                                             #
; # Parameters:                                 #
; #     rdi: cam location vector pointer        #
; #     rsi: cam looking at vector pointer      #
; #     rdx: global up vector pointer           #
; #     rdx: return matrix pointer              #
; #                                             #
; ###############################################
Matrix3_build_rotation_matrix:
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
    mov     rdx, [rbp]
    call    vector3_subtract

    mov     rdi, [rbp]
    call    vector3_to_unit    
    mov     rdi, [rbp]
    call    vector3_negate

    ; copy to matrix
    mov     rdi, [rbp]
    movsd   xmm0, [rdi + Vec3.x]
    movsd   [r11 + Mat3.c3 + Vec3.x], xmm0
    movsd   xmm0, [rdi + Vec3.y]
    movsd   [r11 + Mat3.c3 + Vec3.y], xmm0
    movsd   xmm0, [rdi + Vec3.z]
    movsd   [r11 + Mat3.c3 + Vec3.z], xmm0

    ; calc right vector
    mov     rdi, r10
    lea     rsi, [r11 + Mat3.c3]
    mov     rdx, [rbp]
    call    vector3_cross_product
    mov     rdi, [rbp]
    call    vector3_to_unit

    ; copy to matrix
    mov     rdi, [rbp]
    movsd   xmm0, [rdi + Vec3.x]
    movsd   [r11 + Mat3.c1 + Vec3.x], xmm0
    movsd   xmm0, [rdi + Vec3.y]
    movsd   [r11 + Mat3.c1 + Vec3.y], xmm0
    movsd   xmm0, [rdi + Vec3.z]
    movsd   [r11 + Mat3.c1 + Vec3.z], xmm0

    ; calc camera up (flipped from what it should be cause forward was negated)
    lea     rdi, [r11 + Mat3.c1]
    lea     rsi, [r11 + Mat3.c3]
    mov     rdx, [rbp]
    call    vector3_cross_product
    
    ; copy to matrix
    mov     rdi, [rbp]
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





%endif