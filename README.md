x86 Bootloader crash course
=================

In this Crasg Curse we will try to learn by writing and debugging bootloaders for x86.

Working environment 
-----------------

For bootloaders we will use following tools:
NASM : Assembly compiler
GCC or CLANG : For C code
Qemu : For running our code
SeaBIOS : For Bios Emulation

### NASM:
 - [NASM Installation](https://www.nasm.us/)
 - [NASM Tutorial](https://cs.lmu.edu/~ray/notes/nasmtutorial/)


### QEMU:
 - [QEMU installation](https://www.qemu.org/download/)
 - [QEMU Tutorial](https://freeptr.io/2016/06/13/qemu-for-the-impatients/)

### SeaBIOS:
Run qemu with your compiled BIOS!! (Not sure how you feel about it but I think is dope ;)

```
git clone https://github.com/coreboot/seabios
cd seabios
make
qemu -bios out/bios.bin
```

Hello World From first 512B of Floppy Disk
-----------------
BIOS can load at once only 512B from medium such as Floppy Disk/CD-ROM/USB-FDD-HDD
That causes Bootloader code to be divided into 2 sectrion, as the only task of first bootloader is just to load more code from medium into memory.
However we can also use that for our programs that will run on CPU in 16bit mode.

Below to show hello world example, we will compile small assembly program and run it under qemu.

```assembly
	BITS 16

start:
	mov ax, 07C0h		; Set data segment to magic 0x07c0h (BIOS load point)
	mov ds, ax

	mov si, welcome_text	; Put string position into SI
	call bios_print		; Call print
	jmp $			; End infinite loop


	welcome_text	db 'Hello World!', 0


bios_print:			; Print text using INT 10H (BIOS functionality)
				; for each char until you hit zero (EOS)
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
	ret


	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
```

### Compile Hello World (via NASM)

```
nasm -f bin -o myfirst.bin myfirst.asm 
```

### Prepare Floppy Disk image (using dd)
```
dd status=noxfer conv=notrunc if=myfirst.bin of=myfirst.flp
```

### Run qemu 
You should see in qemu terminal your hello world!

```
qemu-system-i386 -fda myfirst.flp
```

Compile and run x86 Bootloader
-----------------
//To be done....

Bibliography
=================
