	org 0x7c00
	mov ax, cx
	mov ds, ax
	mov es, ax
	call displayString
end:
	hlt
	jmp end

displayString:
	mov ax, BootMessage
	mov bp, ax
	mov cx, 21
	mov ax, 01301h
	mov bx, 000ch
	mov dl, 0
	int 10h
	ret
BootMessage: db "Loading the system..."
times 510 - ($ - $$) db 0
dw 0xaa55
