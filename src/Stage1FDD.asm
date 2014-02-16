[bits 16]
[org 0x7c00]

start:
   ; DL register contains the number (ID) 
   ; The drive from which it was loaded Boot 
   ; Loader.

   ; For unsure what segment / offset set this 
   ; CS = 0, IP = address code below.
  jmp word 0:code

code:

   ; Calculate the number of sectors to load. 
   ; The 0xBAADC0D3 will be swapped 
   ; By our code builds the image.
  mov eax, 0xBAADC0D3
  
   ; Divide by 512 The number of sectors will 
   ; The part of AL.
  shr eax, 9

   ; Set the INT13/AH = 2 (READ SECTORS). 
   ; AL (number of sectors) is already set. 
   ; DL (drive) is already set.
  mov ah, 2  ; Function number.

  mov cl, 2  ; Second sector.
  xor ch, ch ; The first cylinder (0).
  mov dh, ch ; The first head (0).
  
  mov bx, 0x2000 ; \ Target
  mov es, bx     ; / segment.
  xor bx, bx     ; Target Offset.

  int 0x13  ; Call READ SECTORS.

  ; Go to the second stage boot loader.
  jmp word 0x2000:0x0000

; Alignment to the full sector.
times (0x1FE-($-start)) db 0

; Boot sector signature .
db 0x55, 0xAA

