;Interrupt vector table

db 'ivt.asm'

;List of interrupts to register to generic handler, terminated with 0xFF
load_isr_stubs:
	db 0x00 	;Divide by 0
	dw isr_0

	db 0x01		;Debug
	dw isr_1

	db 0x05		;Bound Range Exceeded
	dw isr_5

	db 0x06		;Invalid Op-code
	dw isr_6

	db 0x07		;Device not Available
	dw isr_7

	db 0x08		;Double Fault
	dw isr_8

	db 0x0A		;Invalid TSS
	dw isr_A

	db 0x0B		;Segment not Present
	dw isr_B

	db 0x0C		;Stack-Segment Fault
	dw isr_C

	db 0x0D		;GPF
	dw isr_D

	db 0x0E		;Page Fault
	dw isr_E

	;db 0x10	;FPU Exception
	;dw	isr_10

	db 0x11		;Alignment Check
	dw isr_11

	;db 0x13		;SIMD Exception
	;dw isr_13

	db 0x14		;Virtualization Exception
	dw isr_14

	db 0xFF	;Terminate list

;Setup IVT
init_ivt:
	pusha
	cli

	;Relocate BIOS handlers
	;Shift them all up to int 0x00 -> int 0x30
	xor ax, ax

	mov es, ax
	mov si, ax		;Start of IVT

	mov fs, ax
	mov di, 0xC0	;Location of int 0x30

	mov ax, 0x400	;Whole table (hamfisted approach, as always)
	call memcpy

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
.loop:
	movzx ax, byte [di]
	cmp ax, 0xFF
	je .done

	mov si, word [di + 1]
	call register_ivt
	add di, 3
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

;Simple ISR stubs
isr_0:
	mov ax, 0x00
	jmp isr_stub

isr_1:
	mov ax, 0x01
	jmp isr_stub

isr_5:
	mov ax, 0x05
	jmp isr_stub

isr_6:
	mov ax, 0x06
	jmp isr_stub

isr_7:
	mov ax, 0x07
	jmp isr_stub

isr_8:
	mov ax, 0x08
	jmp isr_stub

isr_A:
	mov ax, 0x0A
	jmp isr_stub

isr_B:
	mov ax, 0x0B
	jmp isr_stub

isr_C:
	mov ax, 0x0C
	jmp isr_stub

isr_D:
	mov ax, 0x0D
	jmp isr_stub

isr_E:
	mov ax, 0x0E
	jmp isr_stub

isr_10:
	mov ax, 0x10
	jmp isr_stub

isr_11:
	mov ax, 0x11
	jmp isr_stub

isr_13:
	call print_regs
	int 0x43
	jmp isr_stub

isr_14:
	mov ax, 0x14
	jmp isr_stub

isr_stub:
	pusha

	push ax
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

	pop ax
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