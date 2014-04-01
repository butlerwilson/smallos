%include "pm.inc"

	org 0x0100
	jmp LABEL_START

[SECTION .gdt]
GDT_LABEL:	   Descriptor 0,              0, 0
LABEL_DESC_NORMAL: Descriptor 0,         0ffffh, DA_DRW
LABEL_DESC_CODE32: Descriptor 0, SegCode32Len-1, DA_C + DA_32
LABEL_DESC_CODE16: Descriptor 0,        0x0ffff, DA_C
LABEL_DESC_DATA:   Descriptor 0,   SegDataLen-1, DA_DPL1 + DA_DRW
LABEL_DESC_STACK:  Descriptor 0,     TopOfStack, DA_32 + DA_DRWA
LABEL_DESC_LDT:	   Descriptor 0,       LDTLen-1, DA_LDT
LABEL_DESC_VIDOE:  Descriptor 0b8000h,   0ffffh, DA_DRW

GDTLen equ $ - GDT_LABEL
GDTPtr	dw GDTLen - 1
	dd 0

;construc selector
SelectorNormal  equ	LABEL_DESC_NORMAL - GDT_LABEL
SelectorCode32	equ	LABEL_DESC_CODE32 - GDT_LABEL
SelectorCode16	equ	LABEL_DESC_CODE16 - GDT_LABEL
SelectorData	equ	LABEL_DESC_DATA - GDT_LABEL
SelectorStack	equ	LABEL_DESC_STACK - GDT_LABEL
SelectorLDT	equ	LABEL_DESC_LDT - GDT_LABEL
SelectorVidoe	equ	LABEL_DESC_VIDOE - GDT_LABEL

[SECTION .data]
ALIGN 32
[BITS 32]
LABEL_DATA:
	SPValueInRealMode dw 0
	message db "The LOAD program will Loading system...", 0
	OffsetMessage equ message - LABEL_DATA
	SegDataLen equ $ - LABEL_DATA
	
LABEL_LDT_DATA:
	ldtmessage db "---Here we in LDT environment---", 0
	OffsetLdtMessage equ ldtmessage - LABEL_LDT_DATA
	SegLdtDataLen equ $ - LABEL_LDT_DATA
;end label data

[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0
	TopOfStack equ $ - LABEL_STACK - 1

LABEL_LDT_STACK:
	times 512 db 0
	LdtTopOfStack equ $ - LABEL_LDT_STACK - 1

[SECTION .s16]
[BITS 16]
LABEL_START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x0100

	mov [LABEL_GO_BACK_TO_REAL + 3], ax
	mov [SPValueInRealMode], sp

	;init the GDT

	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE16
	mov word [LABEL_DESC_CODE16 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE16 + 4], al
	mov byte [LABEL_DESC_CODE16 + 7], ah

	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE32
	mov word [LABEL_DESC_CODE32 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32 + 4], al
	mov byte [LABEL_DESC_CODE32 + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_DATA
	mov word [LABEL_DESC_DATA + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_DATA + 4], al
	mov byte [LABEL_DESC_DATA + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_STACK
	mov word [LABEL_DESC_STACK + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_STACK + 4], al
	mov byte [LABEL_DESC_STACK + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_LDT
	mov word [LABEL_DESC_LDT + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_LDT + 4], al
	mov byte [LABEL_DESC_LDT + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_CODE_A
	mov word [LABEL_LDT_DESC_CODE + 2], ax
	shr eax, 16
	mov byte [LABEL_LDT_DESC_CODE + 4], al
	mov byte [LABEL_LDT_DESC_CODE + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_LDT_STACK
	mov word [LABEL_LDT_DESC_STACK + 2], ax
	shr eax, 16
	mov byte [LABEL_LDT_DESC_STACK + 4], al
	mov byte [LABEL_LDT_DESC_STACK + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_LDT_DATA
	mov word [LABEL_LDT_DESC_DATA + 2], ax
	shr eax, 16
	mov byte [LABEL_LDT_DESC_DATA + 4], al
	mov byte [LABEL_LDT_DESC_DATA + 7], ah

	;ready for load gdt
	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, GDT_LABEL
	mov dword [GDTPtr + 2], eax
	lgdt [GDTPtr]

	; close interrupts
	cli

	;open A20 address for using more memory
	in al, 92h
	or al, 00000010b
	out 92h, al

	;enable protect mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	;jmp into 32 protect mode
	jmp dword SelectorCode32:0

LABEL_REAL_ENTRY:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov sp, [SPValueInRealMode]

	;open A20 address
	in al, 92h
	and al, 11111101b
	out 92h, al

	;switch to real mode
	mov eax, cr0
	and eax, 11111111b
	mov cr0, eax

	;open interrupt
	sti

	mov ax, 0x4c00
	int 21h

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
	mov ax, SelectorData	;last time I used SelectorCode32
	mov ds, ax
	mov ax, SelectorVidoe
	mov gs, ax

	mov ax, SelectorStack
	mov ss, ax
	mov esp, TopOfStack

	mov ah, 0ch
	xor esi, esi
	xor edi, edi
	mov esi, OffsetMessage
	mov edi, (80 * 10 + 0) * 2
	call ShowString

	;load LDT
	mov ax, SelectorLDT
	lldt ax

	jmp SelectorLDTCodeA:0

ShowString:
	push eax
	push esi
	push edi

	cld
.1:
	lodsb
	test al, al
	je .2
	mov [gs:edi], ax
	add edi, 2
	jmp .1
.2:
	call DispReturn
	pop edi
	pop esi
	pop eax
	ret

DispReturn:
	push	eax
	push	ebx
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	ebx
	pop	eax

	ret

SegCode32Len equ $ - LABEL_SEG_CODE32

[SECTION .s16]
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
	and eax, 11111110b	;first time I forgot 'b'
	mov cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY
Code16Len equ $ - LABEL_SEG_CODE16

[SECTION .ldt]
ALIGN 32
LABEL_LDT:
LABEL_LDT_DESC_CODE:	Descriptor 0, LDTCodeLen - 1, DA_C + DA_32
LABEL_LDT_DESC_STACK:   Descriptor 0,  LdtTopOfStack, DA_DRWA + DA_32
LABEL_LDT_DESC_DATA:	Descriptor 0,  SegLdtDataLen, DA_DPL1 + DA_DRW
LDTLen equ $ - LABEL_LDT

SelectorLDTCodeA equ LABEL_LDT_DESC_CODE - LABEL_LDT + SA_TIL
SelectorLDTStack equ LABEL_LDT_DESC_STACK - LABEL_LDT + SA_TIL
SelectorLDTData  equ LABEL_LDT_DESC_DATA - LABEL_LDT + SA_TIL

[SECTION .la]
ALIGN 32
[BITS 32]
LABEL_CODE_A:
	mov ax, SelectorLDTData
	mov ds, ax
	mov ax, SelectorVidoe
	mov gs, ax

	mov ax, SelectorLDTStack
	mov ss, ax
	mov esp, LdtTopOfStack

	mov ah, 0ch
	
;	mov al, 'O'			;I test the stack can use
;	mov bx, ax
;	push bx
	xor esi, esi
	xor edi, edi
	mov esi, OffsetLdtMessage
	mov edi, (80 * 12 + 0) * 2
	;call ShowString
;	pop bx
;	mov ax, bx	
	mov [gs:edi], ax

	jmp SelectorCode16:0
LDTCodeLen equ $ - LABEL_CODE_A
