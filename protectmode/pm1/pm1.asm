%include "pm.inc"

org 0x0100
	jmp LABEL_BEGIN

;the global descriptor table
[SECTION .gdt]
LABEL_GDT:		Descriptor   0, 0, 0
LABEL_DESC_CODE32:	Descriptor   0, SegCode32Len - 1, DA_C + DA_32
LABEL_DESC_VIDEO:	Descriptor   0xB8000, 0XFFFF, DA_DRW

GdtLen	EQU	$ - LABEL_GDT
GdtPtr	dw GdtLen - 1
	dd	0

;selector
SelectorCode32	EQU	LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo	EQU	LABEL_DESC_VIDEO - LABEL_GDT

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
	mov ax, cx
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x100

	;init the 32 code registers
	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE32
	mov word [LABEL_DESC_CODE32 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32 + 4], al
	mov byte [LABEL_DESC_CODE32 + 7], ah

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

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	mov ax, SelectorVideo
	mov gs, ax
	mov edi, (80 * 11 + 79) * 2
	mov ah, 0x0c
	mov al, 'O'
	mov [gs:edi], ax

	jmp $
SegCode32Len	EQU	$ - LABEL_SEG_CODE32
