;Interrupt vector table

db 'ivt.asm'

;Setup IVT
init_ivt:
	pusha
	cli

	;Initialize keyboard handler
	mov ax, 0x09
	mov si, keybd_isr
	call register_ivt

	sti
	popa
	ret

;Register IVT handler
;	SI - ISR address
;	AX - INT number to register
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
	pushad
	cld

	push ax
	mov si, .msg
	call sprint
	pop ax
	call hprint

	call new_line
	call print_regs

	popad
	iret

	.msg db 'INT 0x', 0