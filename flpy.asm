;Floppy disk drivers

	db 'flpy.asm'

flpy_buffer: dw 0

init_flpy:
	pusha

	call reset_flpy

	mov ax, 0x00
	call lba2chs

	mov ch, cl		;Set cylinder
	mov cl, al		;Set sectors
	mov dh, bl		;Set head
	mov dl, 0x00	;Set drive (A:)

	mov ax, 512
	call malloc
	mov word [flpy_buffer], si
	mov bx, word [si + ll_node.address]

	push es
	push ax
	mov ax, 0x00
	mov es, ax		;Set buffer segment
	;mov bx, 0x1000	;Set buffer offset
	pop ax

	call new_line
	call print_regs

	mov ah, 0x02	;Set to read
	mov al, 0x01	;Set number sectors to read
	
	clc
	int 0x13
	jc kernel_panic

	call print_regs
	pop es

.done:
	popa
	ret

reset_flpy:
	pusha

	mov ax, 0
	mov dl, 0
	stc
	int 0x13

	popa	
	ret

;LBA to CHS address
;In
;	AX - LBA
;Out
;	AX - sector
;	BX - head
;	CX - cylinder
lba2chs:
	push dx
	xor dx, dx
	mov bx, [sectors_per_track]
	div bx
	inc dx
	push dx

	xor dx, dx
	mov bx, [num_heads]
	div bx

	mov cx, ax
	mov bx, dx
	pop ax
	pop dx

	ret

sectors_per_track:	dw 18
num_heads:			dw 2