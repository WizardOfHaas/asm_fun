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

	;Prep for read
	call flpy_dma_read
	mov al, 0xE6
	call flpy_cmd

	mov al, 0x00				;Head << 2
	call flpy_cmd

	mov al, 0x00				;Track
	call flpy_cmd

	mov al, 0x00				;Head
	call flpy_cmd

	mov al, 0x00				;Sector
	call flpy_cmd

	mov al, 0x00				;Somehting
	call flpy_cmd

.loop
	cmp byte [flpy_ack], 0
	je .loop

	mov byte [flpy_ack], 0

	popa
	ret

;Send command to floppy disk
;	AL - command to send
flpy_cmd:
	push ax
	;Wait for floppy to be ready
.wait:
	in al, 0x3F2
	and al, 128
	jz .wait

	pop ax

	out 0x3F5, al

	call new_line
	call print_regs

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

flpy_dma_read:
	pusha

	mov al, 0x06
	out 0x0a, al	;mask dma channel 2

	mov al, 0x56
	out 0x0b, al 	;single transfer, address increment, autoinit, read, channel 2

	mov al, 0x02
	out 0x0a, al	;Unmask channel 2

	popa
	ret

flpy_irq:
	pusha
	cli

	mov byte [flpy_ack], 1		;Set floppy ack

	sti
	popa
	iret