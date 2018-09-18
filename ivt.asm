;Interrupt vector table

db 'ivt.asm'

;Setup IVT
init_ivt:
	pusha
	cli

	xor di, di		;Point to start og IVT

	mov ax, 0x09
	mov si, master_isr
	call register_ivt

	sti
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
	mov word [es:di], si
	mov word [es:di + 2], cs

	pop es
	popa
	ret

master_isr:
	push ax
	mov si, .msg
	call sprint
	pop ax
	call hprint

	call new_line
	call print_regs

	iret

	.msg db 'INT 0x', 0