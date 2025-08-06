ORG 0x7c0
BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
  jmp short start
  nop

times 33 db 0

start:
  jmp 0:step2

step2:
  cli ; clear interrupts, we dont want to hardware interrupt, cause we are going change some segments registers
  mov ax, 0x00
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7c00
  sti ; enables interrupts  

.load_protected:
  cli
  lgdt[gdt_descriptor] ; load global descriptor table
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax
  jmp CODE_SEG:load32


; GDT
gdt_start:
gdt_null:
  dd 0x0
  dd 0x0
; offset 0x8
gdt_code: ; CS SHOULD POINT TO THIS
  dw 0xffff ; Segment limit first 0-15
  dw 0 ; Base first 0-15 bits
  db 0 ; Base 16-23 bits
  db 0x9a ; Acess byte
  db 11001111b ; High 4 bit flag and the low 4 bit flag
  db 0 ; Base 24-31 bits

; offset 0x10
gdt_data: ; DS, ES, SS, FS, GS
  dw 0xffff ; Segment limit first 0-15
  dw 0 ; Base first 0-15 bits
  db 0 ; Base 16-23 bits
  db 0x92 ; Acess byte
  db 11001111b ; High 4 bit flag and the low 4 bit flag
  db 0 ; Base 24-31 bits

gdt_end:

gdt_descriptor:
  dw gdt_end - gdt_start - 1 ; size
  dd gdt_start ; when we load gdt, it looks for the size and the offset <- then loads 

[BITS 32]
load32:
  mov ax, DATA_SEG
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov fs, ax
  mov gs, ax
  mov ebp, 0x00200000
  mov esp, ebp
  ; Enable the A20 line
  in al, 0x92
  or al, 2
  out 0x92, al
  jmp $


times 510-($ - $$) db 0
dw 0xAA55
