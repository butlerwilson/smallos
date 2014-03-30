%include "pm.inc"

org 0x0100
	jmp LABEL_BEGIN

;the global descriptor table
[SECTION .gdt]
LABEL_GDT:		Descriptor   0, 0, 0
LABEL_DESC_NORMAL:	Descriptor   0, 0x0ffff, DA_DRW
LABEL_DESC_CODE32:	Descriptor   0, SegCode32Len - 1, DA_C + DA_32
LABEL_DESC_CODE16:	Descriptor   0, 0x0ffff, DA_C
LABEL_DESC_DATA:	Descriptor   0, DataLen - 1, DA_DRW
LABEL_DESC_STACK:	Descriptor   0, TopOfStack - 1, DA_DRWA+DA_32
LABEL_DESC_TEST:	Descriptor   0x0500000, 0x0ffff, DA_DRW
LABEL_DESC_VIDEO:	Descriptor   0xB8000, 0Xffff, DA_DRW
GdtLen	EQU	$ - LABEL_GDT

GdtPtr	dw GdtLen - 1
	dd	0

;selector
SelectorNormal	EQU	LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32	EQU	LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16	EQU	LABEL_DESC_CODE16 - LABEL_GDT
SelectorData	EQU	LABEL_DESC_DATA - LABEL_GDT
SelectorStack	EQU	LABEL_DESC_STACK - LABEL_GDT
SelectorTest	EQU	LABEL_DESC_TEST - LABEL_GDT
SelectorVideo	EQU	LABEL_DESC_VIDEO - LABEL_GDT

[SECTION .data]
ALIGN 32
[BITS 32]
LABEL_DATA:
	SPValueInRealMode dw 0
	message db "In protecting mode... ^.^", 0
	OffsetMessage EQU message - $$
	strtest db "Hello, youngcy. This is OS...", 0
	OffsetStrTest EQU strtest - $$
	DataLen EQU $ - LABEL_DATA

[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0
TopOfStack EQU $ - LABEL_STACK - 1

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x100

	;store the mode 16 cs address
	mov [LABEL_GO_BACK_TO_REAL_MODE + 3], ax
	mov [SPValueInRealMode], ax

	;init the 16 bits codes
	xor eax, eax
	mov ax, cs
	;in real mode, the hardware address = addr * 10h + offset
	shl eax, 4	;shift 4bits forward left, equals "* 10h"
	add eax, LABEL_SEG_CODE16
	mov word [LABEL_DESC_CODE16 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE16 + 4], al
	mov byte [LABEL_DESC_CODE16 + 7], ah


	;init the 32 code registers
	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE32
	mov word [LABEL_DESC_CODE32 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32 + 4], al
	mov byte [LABEL_DESC_CODE32 + 7], ah

	;init the data descriptor
	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_DATA
	mov word [LABEL_DESC_DATA + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_DATA + 4], al
	mov byte [LABEL_DESC_DATA + 7], ah

	;init the stack descriptor
	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_STACK
	mov word [LABEL_DESC_STACK + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_STACK + 4], al
	mov byte [LABEL_DESC_STACK + 7], ah

	;ready for load the gdt
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_GDT
	mov dword [GdtPtr + 2], eax

	;load the gdt
	lgdt [GdtPtr]

	;close interrupt
	cli

	;open the address A20
	in al, 92H
	or al, 00000010b
	out 92H, al

	;ready to switch protect mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp dword SelectorCode32:0

;go back to real mode
LABEL_REAL_MODE_ENTRY:
	mov ax, cs
	mov ds, ax
	mov ss, ax
	mov es, ax

	mov sp, [SPValueInRealMode]

	;close A20
	in al, 0x92
	and al, 11111101b
	out 0x92, al

	;allow interrupt
	sti

	mov ax, 0x4c00
	int 21h

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	mov ax, SelectorData
	mov ds, ax
	mov ax, SelectorTest
	mov es, ax
	mov ax, SelectorVideo
	mov gs, ax
	mov ax, SelectorStack
	mov ss, ax

	mov esp, TopOfStack

	mov ah, 0x0c
	xor esi, esi
	xor edi, edi
	mov esi, OffsetMessage
	mov edi, (80 * 11 + 0) * 2

	cld

.1:
	lodsb
	test al, al
	jz .2
	mov [gs:edi], ax
	add edi, 2
	jmp .1
.2:
	call DispReturn
	call TestRead
	call TestWrite
	call TestRead

	jmp SelectorCode16:0

TestRead:
	xor esi, esi
	mov ecx, 8
.loop:
	mov al, [es:esi]
	call DisAL
	inc esi
	loop .loop
	call DispReturn
	ret

TestWrite:
	push esi
	push edi
	xor esi, esi
	xor edi, edi
	mov esi, OffsetStrTest
	cld
.1:
	lodsb
	test al, al
	jz .2
	mov [es:edi], ax
	inc edi
	jmp .1
.2:
	pop edi
	pop esi
	ret

DisAL:
	push ecx
	push edx

	mov ah, 0x0c
	mov dl, al
	shr al, 4
	mov ecx, 2
.begin:
	and al, 01111b
	cmp al, 9
	ja .1
	add al, '0'
	jmp .2
.1:
	sub al, 0x0A
	add al, 'A'
.2:
	mov [gs:edi], ax
	add edi, 2
	mov al, dl
	loop .begin
	add edi, 2

	pop edx
	pop ecx
	ret

DispReturn:
	push eax
	push ebx
	mov eax, edi
	mov bl, 160
	div bl
	and eax, 0x0ff
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop ebx
	pop eax
	ret
SegCode32Len	EQU	$ - LABEL_SEG_CODE32

[SECTION .S16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
	mov ax, SelectorNormal
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov eax, cr0
	and eax, 11111110b
	mov cr0, eax

LABEL_GO_BACK_TO_REAL_MODE:
	jmp 0:LABEL_REAL_MODE_ENTRY
CodeLen EQU $ - LABEL_SEG_CODE16
