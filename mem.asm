;Memory management routines

db 'mem.asm'

free_msg:		db ' bytes free', 10, 0

struc ll_node
    .size: 		resw	1
    .address:	resw	1
    .next: 		resw 	1
    .prev:		resw 	1
endstruc

free_mem: dw 0
used_mem: dw 0

total_mem: db 0, 0

init_mm:
	pusha

	;Get and store memory size
	clc
	int 0x12
	mov word [total_mem], ax

	;Make start of free_mem linked lists
	mov si, start_free_mem
	mov word [si + ll_node.prev], 0
	mov word [si + ll_node.next], 0
	mov word [si + ll_node.address], start_free_mem

	mov ax, start_free_mem
	call iprint
	call new_line

	;Calculate size of free memory
	mov ax, word[total_mem]
	mov bx, 1024
	mul bx
	sub ax, start_free_mem
	mov word [si + ll_node.size], ax

	call iprint

	mov si, free_msg
	call sprint

	popa
	ret

;Copy chunk of memory to new location
;	ES:SI - source data to copy from
;	FS:DI - destination to copy to
;	AX - number of bytes to copy
memcpy:
	pusha

.loop:
	cmp ax, 0			;Have we copied everything?
	je .done

	;Move over the next byte
	mov bx, [es:si]
	mov [fs:di], bx

	;Increment the source and destinations
	inc si
	inc di
	dec ax				;Decrement the bytes counter
	jmp .loop

.done:
	popa
	ret

;Set chunk of memory to given value
;	FS:DI - destination to set
;	AX - number of bytes to set
;	BX - value to set location to
memset:
	pusha

.loop:
	cmp ax, 0			;Are we done with chunk?
	je .done

	mov [fs:di], bx		;Set to specified value

	;Increment counter and location
	inc di
	dec ax

	jmp .loop

.done:
	popa
	ret

add_to_ll:
	ret

remove_from_ll:
	ret

malloc:
	ret

free:
	ret