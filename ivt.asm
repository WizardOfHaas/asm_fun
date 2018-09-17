;Interrupt vector table

db 'ivt.asm'

init_ivt:
	pusha

	xor di, di		;Point to start og IVT

	mov ax, 0x20
	mov si, int_0
	call register_ivt

	popa
	ret

;Register IVT handler
;	SI - ISR address
;	AX - IVT number
register_ivt:
	pusha
	push es

	xor bx, bx
	mov es, bx

	mov bx, 4
	mul bx
	mov di, ax
	mov word [di], si
	mov word [di + 2], cs

	call new_line
	mov si, di
	mov ax, 16
	call dump_mem

	pop es
	popa
	ret

int_0:
	mov si, .msg
	call sprint

	call print_regs

	iret

	.msg db 'INT 0', 10, 0