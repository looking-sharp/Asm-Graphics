%ifndef VECTOR_LIB_ASM
%define VECTOR_LIB_ASM

section .text
global Vec3, vector3_dot_product, vector3_cross_product

struc Vec3
  .x resq 1
  .y resq 1
  .z resq 1
endstruc

; ###############################################
; # vector3_dot_product                         #
; #                                             #
; # Parameters:                                 #
; #     rdi: vec1 pointer                       #
; #     rsi: vec2 pointwe                       #
; #     rdx: result pointer                     #
; #                                             #
; ###############################################
vector3_dot_product:
    ; x component
    movsd xmm0, [rdi + Vec3.x]
    movsd xmm1, [rsi + Vec3.x]
    mulsd xmm0, xmm1            ; x1 * x2

    ; y component
    movsd xmm1, [rdi + Vec3.y]
    movsd xmm2, [rsi + Vec3.y]
    mulsd xmm1, xmm2            ; y1 * y2
    addsd xmm0, xmm1            ; add to previous x1*x2

    ; z component
    movsd xmm1, [rdi + Vec3.z]
    movsd xmm2, [rsi + Vec3.z]
    mulsd xmm1, xmm2            ; z1 * z2
    addsd xmm0, xmm1

    movsd [rdx], xmm0
    ret

; ###############################################
; # vector3_cross_product                       #
; #                                             #
; # Parameters:                                 #
; #     rdi: vec1 pointer                       #
; #     rsi: vec2 pointwe                       #
; #     rdx: result vector pointer              #
; #                                             #
; ###############################################
vector3_cross_product:
    ; initilize the return vector
    pxor    xmm0, xmm0
    movsd   [rdx + Vec3.x], xmm0
    movsd   [rdx + Vec3.y], xmm0
    movsd   [rdx + Vec3.z], xmm0
    
    ; start computing cross product
    ; calculate return x
    movsd   xmm0, [rdi + Vec3.y]
    movsd   xmm1, [rsi + Vec3.z]
    mulsd   xmm0, xmm1  ; saved in xmm0
    movsd   xmm1, [rsi + Vec3.y]
    movsd   xmm2, [rdi + Vec3.z]
    mulsd   xmm1, xmm2
    
    subsd   xmm0, xmm1
    movsd   [rdx + Vec3.x], xmm0

    ; calculate return y
    movsd   xmm0, [rdi + Vec3.x]
    movsd   xmm1, [rsi + Vec3.z]
    mulsd   xmm0, xmm1  ; saved in xmm0
    movsd   xmm1, [rsi + Vec3.x]
    movsd   xmm2, [rdi + Vec3.z]
    mulsd   xmm1, xmm2

    subsd   xmm1, xmm0
    movsd   [rdx + Vec3.y], xmm1

    ; calculate return z
    movsd   xmm0, [rdi + Vec3.x]
    movsd   xmm1, [rsi + Vec3.y]
    mulsd   xmm0, xmm1  ; saved in xmm0
    movsd   xmm1, [rsi + Vec3.x]
    movsd   xmm2, [rdi + Vec3.y]
    mulsd   xmm1, xmm2
    
    subsd   xmm0, xmm1
    movsd   [rdx + Vec3.z], xmm0
    ret


%endif