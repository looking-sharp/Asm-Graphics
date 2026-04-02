# ASM Graphics
**A graphics library written in assembly**

This project is a personal attempt at creating some kind of graphics library using only assembly language. While there is no long term plan for this project currently, I intend to add features here and there when I get ideas.

This project is designed only to work on 64-bit GNU-Linux. There are no gaurentees it will work on any other system. It also uses nasm for compiling and gcc for linking.

## Instilation Steps
First, clone this repository wherever you may want it using:
```bash
git clone https://github.com/looking-sharp/Asm-Graphics.git
```

There are a few libraries you'll need to run this project, including:

NASM: (for compiling assembly)
```bash
sudo apt update
sudo apt install nasm
```

GCC: (for linking)
```bash
sudo apt update
sudo apt install build-essential
```

x11:
```
sudo apt update
sudo apt install libx11-dev
```

From there you can either run any of the examples in the ex directory, or build your own.

To build and run an example program, ensure you are in the correct directory, then run
```bash
./compile.sh
```
To run the script. (You may need to update the permissions on this file)

To include it in any of your own projects, just add
```asm
%include <path>/<to>/render/visual_lib.asm
```

Thanks for checking out my project!
