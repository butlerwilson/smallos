	jmp START_LABEL

msg db "Program Loaded succeed...", $0

START_LABEL:
	mov ax, cs
	mov ds, ax
	mov es, ax

	mov si, msg
print:
	lodsb
	cmp al, 0
	je END
	mov ah, 0eh
	mov bx, 7
	int 0x10
	jmp print

END:
	jmp END
times 512 - ($ - $$) db 0
dw 0xaa55
