%ifndef MATRIX_LIB_ASM
%define MATRIX_LIB_ASM

%include 'vector/vector_lib.asm'

section .text


struc Mat3
  .c1 resb Vec3_size
  .c2 resb Vec3_size
  .c3 resb Vec3_size
endstruc


do_thing:
    ret


%endif