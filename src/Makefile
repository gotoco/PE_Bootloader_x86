CC=gcc
LD=ld
NASM=nasm
CFLAGS= -nostdinc - fno-builtin \
	- std=c99 - fno-leading-underscore
LDFLAGS= -nostdlib  \
	 -section-alignment 0x1000 \
	 -file-alignment 0x1 \
	 -image-base 0x100000  \
	 -e KernelInit 

all:
	$(CC) -c *.c ${CFLAGS}
	$(LD) *.o -o kernel.exe -Map kernel.map --cref ${LDFLAGS}
	$(NASM) Stage1PXE.asm
	$(NASM) Stage1FDD.asm
	$(NASM) Stage2.asm
	./build.py

