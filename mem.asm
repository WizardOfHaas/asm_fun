;Memory management routines

db 'mem.asm'

total_mem: db 0, 0

initmm:
	pusha

	;Get and store memory size
	clc
	int 0x12
	mov word [total_mem], ax

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

malloc:

free: