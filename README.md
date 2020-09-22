x86 Bootloader crash course
=================

In this Crash Curse we will try to learn by writing and debugging bootloaders for x86.
Most of the examples are done on Linux with help of QEMU which should make it very easy for everyone, as we use available well described tools

Working environment 
-----------------

For bootloaders we will use following tools:
 - NASM : Assembly compiler
 - GCC or CLANG : For C code
 - Qemu : For running our code
 - SeaBIOS : For Bios Emulation

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

### How to debug asembly code or even BIOS??

#### Debug assembly code:
Run our floppy disk code but run GDB server and stop on the first instruction

```
qemu-system-i386 -fda myfirst.flp -S -s
```
Now we need to connect gdb
```
# run gdb via 'gdb' command , then connect to the gdb server run by qemu
(gdb) target remote localhost:1234
# for realmode code setup architecture to 16 bits 
(gdb) set architecture i8086
# Break entry to bootloader code
(gdb) break *0x7c00
# continue (hit breakpoint)
(gdb) c
# Step single instruction or step 
(gdb) si (or) s
```

#### Debug BIOS using debugger
We have to compile first our BIOS (for example we will use SeaBIOS listed above).
We do run with same options `-S -s` gdb server + stop before executing first instruction

```
qemu-system-i386 -bios bios.bin -fda myfirst.flp - S -s
```
Now we break some BIOS location that we want to investigate
```
gdb bios.bin

(gdb) target remote localhost:1234
# for realmode code setup architecture to 16 bits 
(gdb) set architecture i8086
# Break entry to bootloader code
(gdb) break some_bios_symbol
```

#### PRINTF from BIOS code!
Debugging with `gdb` is class, but sometimes it can be bit time consuming. In such cases usually printing different messages can help.
Unfortunately BIOS cannot easily print to graphic environment and we need to add additional interface.
In case of seabios we can simply add custom char device that will emulate serial port.

```
qemu-system-i386 -bios bios.bin  -fda myfirst.flp  -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios
```

After we run we will start getting additional verbose messages from SeaBIOS, plus we can start adding our to the code!

Compile and run x86 Bootloader
-----------------

### First Stage Bootloader

### Second Stage Bootloader: Load kernel binary
When kernel boot in this format we need to extract binary into memory to prepare running environment for kernel program.
Yes we have to do that because there is no magical loader on the bare metal, so main task of second stage bootloader is to load executable structures inside the memory.
Binary can be in the different format, we will consider 2 formats: PE (Portable Executable) known from Windows systems and ELF widely used on UNIX systems. 

#### Kernel in PE format
PE -  is one of the format  for executable files, basic one widely used on Windows machines.


#### Kernel in ELF format

Acknowledgements
=================
Special thanks to Gynvael Coldwind and Mateusz Jurczyk for x86 bootloader tutorial with full bootloader for PE kernel. Without that I wouldn't encounter many issues and due to that start researching area in more details and create this github page.  

Bibliography
=================
 - Wikipedia: PE, ELF, Real Mode, Unreal-Mode, 
 - OSDEV: A20, Unreal mode, BIOS, GDT Tutorial
 - Intel Minimal Architecture boot-loader paper .pdf
 - QEMU: (Fast crash course) QEMU for impatients 
 - Only for serious curious students/reaserchers: Intel 64 and IA-32 Architectures Software Developemnt Manual  
 
