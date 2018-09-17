;Memory management routines

db 'mem.asm'

free_msg:		db ' bytes free', 10, 0

;Linked list node struct(8 bytes)
struc ll_node
    .address:	resw	1
    .size: 		resw	1
    .prev:		resw 	1
    .next: 		resw 	1
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
	mov word [total_mem], ax	;Save over detected lower mem

	;Initialize linked list struct for free mem
	;Calculate size of free memory
	mov ax, word [total_mem]	;Get total RAM size
	mov bx, 1024				;|kb -> b
	mul bx						;|
	sub ax, start_free_mem		;Subtract off end of kernal
	
	mov si, start_free_mem		;Make start of free_mem linked lists
	mov [free_mem_ll], si		;Save over location of free mem ll

	mov di, si					;Address size of first element, directly after ll struct
	add di, 8

	call init_ll 				;Initialize linked list

	;Initialize linked list struct for used mem
	;Calculate used mem size
	mov ax, word [end]
	sub ax, 0x100

	mov si, start				;Place used mem node right before start of kernel
	sub si, 8
	mov [used_mem_ll], si		;Save location of start of used mem list
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

print_ll:
	pusha

.mem_loop:
	mov ax, 16
 	call dump_mem

 	cmp word [si + ll_node.next], 0
 	je .done

 	mov si, word [si + ll_node.next]

 	jmp .mem_loop

.done:
	popa
	ret

;Get last node of linked list
;	SI - location of first node of linked list
last_node_ll:
.loop:
	cmp word [si + ll_node.next], 0
	je .done	

	mov si, word [si + ll_node.next]
	jmp .loop
.done:
	ret

;Add node to linked list struct
;	DI - location of start of linked list
;	SI - address of node to add
add_to_ll:
	pusha

	xchg si, di
	call last_node_ll 					;Get to end of list (in SI)

	xchg si, di
	mov word [di + ll_node.next], si	;Set new node as next node
	mov word [si + ll_node.prev], di	;Set new node's prev to old last node

	popa	
	ret

;Remove from linked list struct
;	SI - address of list member to remove
remove_from_ll:
	pusha

	mov ax, word [si + ll_node.prev]		;Get location of previous node
	mov bx, word [si + ll_node.next]		;Get location of next node

	;Set adjacent nodes to now point to eachother
	mov di, ax
	cmp di, 0								;Move on if there is no prev node
	je .next
	mov [di + ll_node.next], bx

.next:
	mov di, bx
	cmp di, 0
	je .done								;Move on if there is no next node
	mov [di + ll_node.prev], ax	

.done:
	popa
	ret

;Allocate memory
;	AX - bytes to allocate
;Returns
;	SI - pointer to linked list struct describing allocated memory
malloc:
	pusha

	mov si, [free_mem_ll]
	mov word [.largest_block], si
.next_node:
	mov word [.curr_block], si			;Keep track of current block
	cmp word [si + ll_node.size], ax	;Do we have the size chunk caller wants?
	je .done

	mov bx, word [.largest_block]
	cmp word [si + ll_node.size], bx	;Do we have a new largest block of free mem?
	jg .update_largest

.check_done:
	cmp word [si + ll_node.next], 0		;Check if we have reached the end of the list
	je .make_block

.next:
	mov si, word [si + ll_node.next]	;Go to next list node

	jmp .check_done

.update_largest:
	mov word [.largest_block], bx
	jmp .next

	;Make a new block of needed size by carving largest free block
.make_block:
	mov si, word [.largest_block]		;Get largest block to slice
	mov di, si							
	add di, word [si + ll_node.size]	;Get to end of block
	add ax, 8							;Calculate size of block to allocate + ll node

	;Test if we have enough RAM, die otherwise
	mov cx, word [si + ll_node.size]
	cmp ax, cx
	jl kernel_panic

	sub word [si + ll_node.size], ax	;Shrink block we are chopping

	sub di, ax							;Make space to allcoate new block
	mov word [.curr_block], di			;Save over lcoation of new node

	;Initialize new linked list node
	mov bx, di
	add bx, 8
	mov word [di + ll_node.address], bx	;Set location of memory block

	sub ax, 8							
	mov word [di + ll_node.size], ax	;Set size attribute

	mov si, di
	mov di, word [used_mem_ll]			;Get start of used_mem_ll

	call add_to_ll 						;Add to used_mem_ll

	mov si, word [.curr_block]			;Make sure to get out of the edge case catch

.done:
	cmp si, word [free_mem_ll]			;Check we allocated something
	je .make_block						;If not, we only have one block so split it up
	popa

	mov si, word [.curr_block]			;Return current block
	ret

	.largest_block dw 0
	.curr_block dw 0

;Free memory
;	SI - ll node for malloc'd block
free:
	pusha

	call remove_from_ll 				;Remove from current list

	;Add to free mem list
	mov di, word [free_mem_ll]			;Add to free mem list
	call add_to_ll

	mov ax, 16
	;call dump_mem

	popa
	ret

;Dump chumk of memory to screen
;	ES:SI - location to dump
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
	mov ax, es
	call hprint
	mov al, ':'
	call cprint
	mov ax, si
	call hprint				;Print address

	mov al, '|'				
	call cprint
.hex_loop:					;Print out hex string of RAM
	mov al, byte [es:si]
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
	mov al, byte[es:si]
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
