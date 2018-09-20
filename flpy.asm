;Floppy disk drivers

	db 'flpy.asm'

	flpy_ack: db 0

init_flpy:
	pusha

	;Register IRQ 6
	mov ax, 0x26
	mov si, flpy_irq
	call register_ivt

	mov byte [flpy_ack], 0		;Clear floppy ack

	call flpy_init_dma

	popa
	ret

flpy_init_dma:
	pusha

	mov al, 0x06
	out 0x0A, al				;mask dma channel

	mov al, 0xFF
	out 0xD8, al				;reset master flip-fl

	mov ax, 0x00				;Buffer at physical address 0x1000
	out 0x04, al

	mov al, 0x10
	out 0x04, al

	mov al, 0xFF
	out 0xd8, al				;reset master flip-fl
	out 0x05, al				;count to 0x23ff (number of bytes in a 3.5" floppy disk track)

	mov al, 0x23
	out 0x05, al

	mov al, 0
	out 0x80, al 			    ;external page register

	mov al, 0x02
	out 0x0a, al				;unmask dma channel

	popa
	ret

flpy_irq:
	pusha
	cli

	mov byte [flpy_ack], 1		;Set floppy ack

	sti
	popa
	iret