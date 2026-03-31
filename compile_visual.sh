#!/bin/bash

syntax="intel"


# Verify parameter 1 exists and is .asm
if [ -z "$1" ]; then
    echo "Error: first parameter must be <filename>"
    echo ""
    echo "Try: ./compile.sh <filename> <exename>"
    exit 1
fi
if [[ $1 != *.asm ]]; then 
    echo "Error: <filename> must be .asm"
    echo ""
    echo "Try: ./compile.sh <filename> <exename>"
    exit 1
fi

#Verify parameter 2 exists
if [ -z "$2" ]; then
    echo "Error: second parameter must be <exename>"
    echo ""
    echo "Try: ./compile.sh <filename> <exename>"
    exit 1
fi

#compile
nasm -f elf64 $1 -o $2.o
#link
gcc -no-pie -m64 -o $2 $2.o -lX11
#run
./$2
#cleanup
rm -rf $2.o