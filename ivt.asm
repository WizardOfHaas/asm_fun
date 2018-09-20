;Interrupt vector table

db 'ivt.asm'

;List of interrupts to register to generic handler, terminated with 0xFF
load_isr_stubs:
	db 0x00, 	;Divide by 0
	db 0x01,	;Debug
	db 0x05,	;Bound Range Exceeded
	db 0x06,	;Invalid Op-code
	db 0x07,	;Device not Available
	;db 0x08,	;Double Fault
	db 0x0A,	;Invalid TSS
	db 0x0B,	;Segment not Present
	db 0x0C,	;Stack-Segment Fault
	db 0x0D,	;GPF
	db 0x0E,	;Page Fault
	;db 0x10,	;FPU Exception
	db 0x11,	;Alignment Check
	db 0x13,	;SIMD Exception
	db 0x14,	;Virtualization Exception
	db 0xFF	;Terminate list

;Setup IVT
init_ivt:
	pusha
	cli

	;Initialize keyboard handler
	mov ax, 0x09
	mov si, keybd_isr
	call register_ivt

	;Register generic ISRs for errors
	mov di, load_isr_stubs
	mov si, isr_stub
.loop:
	movzx ax, byte [di]
	cmp ax, 0xFF
	je .done

	call new_line
	call hprint

	call register_ivt
	inc di
	jmp .loop

.done:

	mov si, .msg
	call sprint
	
	sti
	popa
	ret

	.msg db 'DONE', 0

;Simple ISR stub
isr_stub:
	pusha

	mov al, 0x0A
	out 0xA0, al
	out 0x20, al

	xor ax, ax
	xor bx, bx
	in al, 0xA0
	mov ah, al
	in al, 0x20

	call new_line
	call print_regs

	popa
	iret

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