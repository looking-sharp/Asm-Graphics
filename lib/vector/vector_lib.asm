%ifndef VECTOR_LIB_ASM
%define VECTOR_LIB_ASM

section .text
global Vec3, vector3_dot_product, vector3_cross_product, vector3_to_unit, vector3_negate, vector3_subtract

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
; #     rsi: vec2 pointer                       #
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
; #     rsi: vec2 pointer                       #
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

; ###############################################
; # vector3_to_unit                             #
; #                                             #
; # Parameters:                                 #
; #     rdi: vecter pointer                     #
; #                                             #
; ###############################################
vector3_to_unit:
    movsd   xmm0, [rdi + Vec3.x]
    mulsd   xmm0, xmm0        ; x^2
    movsd   xmm1, [rdi + Vec3.y]
    mulsd   xmm1, xmm1        ; y^2
    movsd   xmm2, [rdi + Vec3.z]
    mulsd   xmm2, xmm2        ; z^2
    
    addsd   xmm1, xmm2
    addsd   xmm0, xmm1        ; length^2 in xmm0
    
    sqrtsd  xmm0, xmm0        ; sqrt(length^2) -> length

    ; normalize x
    movsd   xmm1, [rdi + Vec3.x]
    divsd   xmm1, xmm0
    movsd   [rdi + Vec3.x], xmm1

    ; normalize y
    movsd   xmm1, [rdi + Vec3.y]
    divsd   xmm1, xmm0
    movsd   [rdi + Vec3.y], xmm1

    ; normalize z
    movsd   xmm1, [rdi + Vec3.z]
    divsd   xmm1, xmm0
    movsd   [rdi + Vec3.z], xmm1

    ret


; ###############################################
; # vector3_subtract                            #
; #                                             #
; # Parameters:                                 #
; #     rdi: vec1 pointer                       #
; #     rsi: - vec2 pointer                     #
; #     rdx: result vector pointer              #
; #                                             #
; ###############################################
vector3_subtract:
    movsd   xmm0, [rdi + Vec3.x]
    movsd   xmm1, [rsi + Vec3.x]
    subsd   xmm0, xmm1
    movsd   [rdx + Vec3.x], xmm0

    movsd   xmm0, [rdi + Vec3.y]
    movsd   xmm1, [rsi + Vec3.y]
    subsd   xmm0, xmm1
    movsd   [rdx + Vec3.y], xmm0

    movsd   xmm0, [rdi + Vec3.z]
    movsd   xmm1, [rsi + Vec3.z]
    subsd   xmm0, xmm1
    movsd   [rdx + Vec3.z], xmm0
    ret


; ###############################################
; # vector3_negate                              #
; #                                             #
; # Parameters:                                 #
; #     rdi: vecter pointer                     #
; #                                             #
; ###############################################
vector3_negate:
    movsd   xmm1, [neg_mask]
    movsd   xmm0, [rdi + Vec3.x]
    xorpd   xmm0, xmm1
    movsd   [rdi + Vec3.x], xmm0

    movsd   xmm0, [rdi + Vec3.y]
    xorpd   xmm0, xmm1
    movsd   [rdi + Vec3.y], xmm0

    movsd   xmm0, [rdi + Vec3.z]
    xorpd   xmm0, xmm1
    movsd   [rdi + Vec3.z], xmm0
    ret


section .data
    neg_mask: dq 0x8000000000000000

%endif