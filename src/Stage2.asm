[bits 16]
[org 0x0000]

; Assumptions:
; CS:IP = 2000:0000

start:

   ; The inclusion of the A20. 
   ; Method 1: INT15/AX = 2401 (ENABLE GATE A20).
  mov ax, 0x2401
  int 0x15

   ; Method 2: Fast A20 Gate.
  mov al, 2
  out 0x92, al

   ; Blocking masked interrupts.
  cli

   ; Macros section:

; Macro PADDR: Calculate the physical address.
%define PADDR(a,b) (a * 0x10 + b)

; Macro SEG: Calculate segment identifier,
;            from the index, rights and selector
;            GDT/LDT.
%define SEG(idx,t,rpl) (idx*8+t*4+rpl)
  
   ; The following table put GDT and its 
   ; Descriptor. We must remember that 
   ; The processor should skip it and not 
   ; Try to interpret the code;)
  jmp load_gdt

  ; Alignment to 0x20.
  times (0x20 - ($-start) % 0x20) db 0

  ; GDT Array.
initial_gdt:

  ; Mandatory empty descriptor.
  dd 0, 0

  ; Code Segments.
  dw 0xffff    ; Lower limit
  dw 0x0000    ; Lower base
  db 00000000b ; Mid base
  db 10011010b ; Type        = 1010 (kod)
               ; S           = 1 (kod lub dane)
               ; DPL (Priv)  = 0 (one ring to 
               ;                  rule them all)
               ; P (Present) = 1
  db 11001111b ; Mid limit   = 0xf
               ; AVL         = 0
               ; L (64-bit)  = 0
               ; D/B (16/32) = 1 (32-bit)
               ; Granularity = 1 (4KB)
  db 00000000b ; High base
  
  ; Data and Stack Segment
  dw 0xffff    ; Lower limit
  dw 0x0000    ; Lower base
  db 00000000b ; Mid base
  db 10010010b ; Type        = 0010 (Data, Read/Write)
               ; S           = 1 (code or data)
               ; DPL (Priv)  = 0 (one ring to
               ;                  rule them all)
               ; P (Present) = 1 (yep)
  db 11001111b ; Mid limit   = 0xf
               ; AVL         = 0 (nope)
               ; L (64-bit)  = 0 (nope)
               ; D/B (16/32) = 1 (32-bit)
               ; Granularity = 1 (4KB) 
  db 00000000b ; High base 

  ; Complement.
  dd 0
  dd 0

; Descriptor Table GDT.
initial_gdt_desc:

  ; Mask is: 
  ; There are four entries, each with 8 bytes.
  ; 4 * 8 = 0x20
  ; So the mask will be:
  ; 0x20-1 -> 0x1F -> 0000 0000 0001 1111
  dw 0000000000011111b

  ; The physical address of GDT table:
  dd PADDR(0x2000, initial_gdt)
  
  ; Continuation of the code.
load_gdt:
 
  ; Load address GDT do GDTR.
  mov ax, cs
  mov ds, ax ; LGDT use DS.

  lgdt [initial_gdt_desc]

  ; Enable Protected Mode (Turn On a bit 0 in CR0).
  mov eax, cr0
  or al, 1
  mov cr0, eax

  ; Go through 32 bits env!
  jmp dword SEG(1,0,0):PADDR(0x2000,pmode_start)

[bits 32]
pmode_start:

  ; Here processor is in 32-bit mode!

   ; Select the appropriate segment for the data and 
   ; Stack.
  mov ax, SEG(2,0,0)
  mov ds, ax
  mov es, ax
  mov ss, ax

  ; Stack (64KB before the boot loader).
  mov esp, 0x20000

; Some useful constants and macros:

; Struct IMAGE_DOS_HEADER
IDH_LFANEW equ 0x3C   ; field e_lfanew

; Struct IMAGE_NT_HEADERS
INTH_SIGSIZE equ 4    ; signature size PE

; Struct IMAGE_FILE_HEADER
IFH_SIZE equ 0x14     ; the size of the structure
IFH_NSEC equ 0x2      ; field NumberOfSections
IFH_OPTSIZE equ 0x10  ; field SizeOfOptionalHeader

; Struct IMAGE_OPTIONAL_HEADER
IOPTH_ENTRYPOINT equ 16; field AddressOfEntryPoint
IOPTH_IMGBASE equ 0x1C ; field ImageBase
IOPTH_IMGSIZE equ 0x38 ; field SizeOfImage
IOPTH_HDRSIZE equ 0x3C ; field SizeOfHeaders

; Struct IMAGE_SECTION_HEADER
ISH_SIZE    equ 0x28  ; the size of the structure
ISH_RVA     equ 0x0c  ; field VirtualAddress
ISH_RAWSIZE equ 0x10  ; field SizeOfRawData
ISH_RAWOFF  equ 0x14  ; field PointerToRawData

; Macro IFH: Having header address PE calculate 
;            The address of the field in the structure
;            IMAGE_FILE_HEADER.
%define IFH(pe,f) (pe+INTH_SIGSIZE+f)

; Macro IOPTH: Having the PE header calculate address
;              the field address in the structure
;              IMAGE_OPTIONAL_HEADER.
%define IOPTH(pe,f) (pe+INTH_SIGSIZE+IFH_SIZE+f)

  ; Calculate the address of the PE image.
  mov esi, PADDR(0x2000, pe_image)
  
  ; Load address of the PE header with header DOS.
  mov ebp, esi
  add ebp, [esi + IDH_LFANEW]

  ; Prepare memory:
  ; Step 1. Download header destination address.
  ; Step 2. Download the header image size.
  ; Step 3. Reset all memory the image.
  mov edx, [IOPTH(ebp, IOPTH_IMGBASE)]
  mov ecx, [IOPTH(ebp, IOPTH_IMGSIZE)]

  ; Nulling by DWORDs (4 bytes).
  mov edi, edx ; Target address.
  shr ecx, 2   ; Size (in DWORDs).
  xor eax, eax
  rep stosd    ; Reset.

  ; Copy headlines:
  ; Step 1. Get the size of headers.
  ; Step 2. Copy headlines.
  mov ecx, [IOPTH(ebp, IOPTH_HDRSIZE)]

  ; Copy (byte for byte).
  mov edi, edx ; Adres docelowy.
  ; ESI still contains the address pe_image.
  rep movsb    ; Copying.

   ; Copying the data section: 
   ; Step 1 Get the number of the section. 
   ; Step 2 For each section: 
   ; Step A. Download source and destination addresses. 
   ; Step B. Get the size of the data. 
   ; Step C. Copy the data.
  movzx ecx, word [IFH(ebp, IFH_NSEC)]

   ; EBX has to point to the first section header.
  lea ebx, [ebp + INTH_SIGSIZE + IFH_SIZE]
  movzx eax, word [IFH(ebp, IFH_OPTSIZE)]
  add ebx, eax

  ; Load the sections.
load_next_section:

   ; Put the remaining number of sections on the stack.
  push ecx 

   ; Load the size of the section.
  mov ecx, [ebx + ISH_RAWSIZE]

   ; Calculate the source address.
  mov esi, PADDR(0x2000, pe_image)
  add esi, [ebx + ISH_RAWOFF]

   ; Calculate the destination address.
  mov edi, edx ; add ImageBase
  add edi, [ebx + ISH_RVA]

   ; Copy the data.
  rep movsb

   ; Skip to the next section.
  add ebx, ISH_SIZE

   ; If there exists any other sections?
  pop ecx
  dec ecx
  jnz load_next_section

   ; Prepare a packet of data to the kernel.

   ; For Dummy example we will pass only to the kernel
   ; whis own address (by stack).
  push edx

   ; Place the address of the data on the stack as a parameter.
  push esp

   ; Jump to first kernel function.
  mov eax, edx
  add eax, [IOPTH(ebp, IOPTH_ENTRYPOINT)]
  call eax

  ; In case if kernel want to return...
inf_loop:
  hlt
  jmp inf_loop  

  ; Next will be stuck on the kernel address.
pe_image:


    
  
