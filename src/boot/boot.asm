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
  mov eax, 1
  mov ecx, 100
  mov edi, 0x0100000 ; = 1mb
  call ata_lba_read
  jmp CODE_SEG:0x0100000

ata_lba_read:
  mov ebx, eax ; Backup the LBA

  ; Send the highest 8 bits of the LBA to hard disk controller
  shr eax, 24 ; 32-24 = 8, shifting the 24bits to the right.
  or eax, 0xE0 ; Select the Master Drive
  mov dx, 0x1F6 ; 0x1F6 the port that is expecting for the 8 bits
  out dx, al ; OUTPUT byte (8 bits) in AL to the port specified in dx
  ; Finished sending the 8 bits

  ; Send the total of sectors to hard disk controller
  mov eax, ecx
  mov dx, 0x1F2
  out dx, al
  ; Finished sending total of sectors
  
  ; Send more bits of LBA
  mov eax, ebx ; Restoring Backup
  mov dx, 0x1F3
  out dx, al
  ; Finished sending more bits of LBA

  ; Sending more bits of LBA
  mov dx, 0x1F4
  mov eax, ebx ; Restoring Backup
  shr eax, 8 ; 32-8 = 24, shifting the 24bits to the right.
  out dx, al
  ; Finished sending more bits of LBA

  ; Sending 16 upper bits of the LBA
  mov dx, 0x1F5
  mov eax, ebx ; Restoring Backup
  shr eax, 16 
  out dx, al
  ; Finished sending more bits

  mov dx, 0x1f7
  mov al, 0x20
  out dx, al

; Read all sectors into memory
.next_sector:
  push ecx

; Checking if we need to read
.try_again:
  mov dx, 0x1f7
  in al, dx
  test al, 8
  jz .try_again

  ; We need to read 256 words at a time
  mov ecx, 256
  mov dx, 0x1F0
  rep insw
  pop ecx
  loop .next_sector
  ; End of reading sectors into memory
  ret


times 510-($ - $$) db 0
dw 0xAA55
