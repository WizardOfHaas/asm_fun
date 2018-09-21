;Interrupt vector table

db 'ivt.asm'

;List of interrupts to register to generic handler, terminated with 0xFF
load_isr_stubs:
	db 0x00, 	;Divide by 0
	db 0x01,	;Debug
	db 0x05,	;Bound Range Exceeded
	db 0x06,	;Invalid Op-code
	db 0x07,	;Device not Available
	db 0x08,	;Double Fault
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

	;Start PIC init (ICW 1)
	mov al, 0x11
	out 0x20, al
	out 0xA0, al

	;Remap (ICW 2)
	mov al, 0x20
	out 0x21, al	;IRQ 0 -> INT 0x20

	mov al, 0x28
	out 0xA1, al	;IRQ 8 -> INT 0x28

	;Setup PIC master/slave (ICW 3)
	mov al, 0x04
	out 0x21, al	;Init master PIC

	mov al, 0x02
	out 0xA1, al	;Init slave PIC

	;Set x86 mode (ICW 4)
	mov al, 0x01
	out 0x21, al
	out 0xA1, al

	;Clear command PIC bytes
	mov al, 0
	out 0x21, al
	out 0xA1, al

	;Register generic ISRs for errors
	mov di, load_isr_stubs
	mov si, isr_stub
.loop:
	movzx ax, byte [di]
	cmp ax, 0xFF
	je .done

	call register_ivt
	inc di
	jmp .loop

.done:
	;Register timer handler (IRQ 0)
	mov ax, 0x20
	mov si, timer_isr
	call register_ivt

	;Register keyboard handler (IRQ 1)
	mov ax, 0x21
	mov si, keybd_isr
	call register_ivt

	sti
	popa
	ret

	.msg db 10, 'DONE', 10, 0

timer_isr:
	pusha

	inc word [.ticks]
	;mov ax, word [.ticks]
	;call iprint
	;call new_line

	mov al, 0x20
	out 0xA0, al
	out 0x20, al

	popa
	iret

	.ticks dw 0

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
	push si
	mov si, .msg
	call sprint
	pop si
	call print_regs

	mov al, 0x20
	out 0xA0, al
	out 0x20, al

	popa
	iret

	.msg db 'INT ', 0

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