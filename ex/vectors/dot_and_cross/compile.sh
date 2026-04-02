#!/bin/bash

syntax="intel"
name="dot_and_cross"

#compile
nasm -f elf64 $name.asm -o $name.o
#link
gcc -no-pie -m64 -o $name $name.o -lX11
#run
./$name
#cleanup
rm -rf $name.o
rm -rf $name