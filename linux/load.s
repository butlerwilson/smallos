	org 0x7c00
	jmp START_LABEL

START_LABEL:
	mov ax, cs
	mov ds, ax
	mov es, ax

RESET:
	mov ax, 0
	mov dl, 0	;reset drive=0(A)
	int 0x13	;disk operate interrupt
	jc RESET

READ:
	mov ax, 0x1000
	mov es, ax
	mov bx, 0

	mov ah, 2
	mov al, 1
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, 0
	int 0x13

	jc READ

	jmp 0x1000:000
times 510 - ($ - $$) db 0
dw 0xaa55
