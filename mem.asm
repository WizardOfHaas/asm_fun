;Memory management routines

db 'mem.asm'

free_msg:		db ' bytes free', 10, 0

;Linked list node struct(8 bytes)
struc ll_node
    .address:	resw	1
    .size: 		resw	1
    .next: 		resw 	1
    .prev:		resw 	1
endstruc

free_mem_ll: dw 0
used_mem_ll: dw 0

total_mem: db 0, 0

;Do needed setup for memory management, mainly setting up structs for malloc
init_mm:
	pusha

	;Get lower memory size
	clc
	int 0x12
	mov word [total_mem], ax		;Save over detected lower mem

	;Initialize linked list struct for free mem
	;Calculate size of free memory
	mov ax, word [total_mem]		;Get total RAM size
	mov bx, 1024				;|kb -> b
	mul bx					;|
	sub ax, start_free_mem			;Subtract off end of kernal
	
	mov si, start_free_mem			;Make start of free_mem linked lists
	mov [free_mem_ll], si			;Save over location of free mem ll

	mov di, si				;Address size of first element, directly after ll struct
	add di, 8

	call init_ll 				;Initialize linked list

	;Initialize linked list struct for used mem
	;Calculate used mem size
	mov ax, word [end]
	sub ax, 0x100

	mov si, start				;Place used mem node right before start of kernel
	sub si, 16
	mov [used_mem_ll], si			;Save location of start of used mem list
	mov di, 0x100				;Addresses to start of kernel

	call init_ll
	
	popa
	ret

;Initialize empty linked list
;	SI - location for first node of linked list
;	AX - Size Attribute
;	DI - Address attribute
init_ll:
	pusha

	mov word [si + ll_node.prev], 0
	mov word [si + ll_node.next], 0
	mov word [si + ll_node.address], di
	mov word [si + ll_node.size], ax

	popa
	ret

;Add to linked list struct
add_to_ll:
	ret

;Remove from linked list struct
remove_from_ll:
	ret

;Allocate memory
malloc:
	pusha

	mov si, [free_mem_ll]
.next_node:
	mov word [.curr_block], si		;Keep track of current block
	cmp word [si + ll_node.size], ax	;Do we have the size chunk caller wants?
	je .done

	cmp word [si + ll_node.next], 0		;Check if we have reached the end of the list
	jne .next_node

	mov si, word [si + ll_node.next]	;Go to next list node

	jmp .done

.make_block:

.done:
	popa

	mov si, word [.curr_block]			;Return current block
	ret

	.largest_block dw 0
	.curr_block dw 0

;Free memory
free:
	ret

;Dump chumk of memory to screen
;	SI - location to dump
;	AX - number of bytes to display
dump_mem:
	pusha

	mov cx, ax				;Get iterater loaded
	mov ax, 16				;Do 16 byte lines
.loop:
	call dump_mem_line 			;Do one line
	call new_line

	;Update iterators, addresses
	sub cx, 16
	add si, 16
	cmp cx, 16
	jge .loop

	popa
	ret

dump_mem_line:
	pusha

	call advence_cursor		;Make some space

	push ax					;Save for later

	mov cx, ax				;Prepare iterator
	mov ax, si
	call hprint				;Print address

	mov al, '|'				
	call cprint
.hex_loop:					;Print out hex string of RAM
	mov al, byte [si]
	call hprint_byte
	call advence_cursor

	dec cx
	inc si
	cmp cx, 0
	jne .hex_loop

	mov al, '|'
	call cprint

	pop cx
	sub si, cx
.chr_loop:					;Print out char string of RAM
	mov al, byte[si]
	call cprint

	inc si
	dec cx
	cmp cx, 0
	jne .chr_loop

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
