#!/bin/bash

syntax="intel"
name="camera_test"

#compile
nasm -f elf64 $name.asm -o $name.o -I ../../../lib
#link
gcc -no-pie -m64 -o $name $name.o -lX11
#run
./$name
#cleanup
rm -rf $name.o
rm -rf $name