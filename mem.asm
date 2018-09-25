;Memory management routines

db 'mem.asm'

free_msg:		db ' bytes free', 10, 0

;Linked list node struct(16 bytes)
struc ll_node
    .size: 		resw	2
    .address:	resw	2
    .prev:		resw 	2
    .next: 		resw 	2
endstruc

free_mem_ll: dw 0
used_mem_ll: dw 0

total_mem: dw 0

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
	
	push ax
	mov ax, cs
	mov es, ax					;|Set segment for node to code segment
	mov fs, ax					;|Set segment for address to next segment
	pop ax

	mov si, start_free_mem		;Make start of free_mem linked lists
	mov [free_mem_ll], si		;Save over location of free mem ll

	mov di, si					;Address size of first element, directly after ll struct
	add di, 16

	call init_ll 				;Initialize linked list

	;Initialize linked list struct for used mem
	;Calculate used mem size
	mov ax, word [start_free_mem]
	sub ax, 0x100

	push ax
	mov ax, cs
	mov es, ax					;|Set segment for node to code segment
	mov fs, ax					;|Set segment for address to next segment
	pop ax

	mov si, start				;Place used mem node right before start of kernel
	sub si, 16
	mov [used_mem_ll], si		;Save location of start of used mem list
	mov di, 0x100				;Addresses to start of kernel

	call init_ll
	
	popa
	ret

;Initialize empty linked list
;	ES:SI - location for first node of linked list
;	FS:DI - Address attribute
;	AX - Size Attribute
init_ll:
	pusha

	mov word [es:si + ll_node.prev], 0			;Prev segment
	mov word [es:si + ll_node.prev + 2], 0		;Prev offset
	mov word [es:si + ll_node.next], 0			;Next segment
	mov word [es:si + ll_node.next + 2], 0		;Next offset

	mov word [es:si + ll_node.address], fs		;Address segment
	mov word [es:si + ll_node.address + 2], di	;Address offset

	mov word [es:si + ll_node.size], ax			;Size

	popa
	ret

;Print out linked list struct
;	ES:SI - Start of linked list
print_ll:
	pusha

.mem_loop:
	mov ax, 16
 	call dump_mem

 	mov bx, word [es:si + ll_node.next]
 	mov cx, word [es:si + ll_node.next + 2]
 	add bx, cx

 	cmp bx, 0
 	je .done

 	mov di, word [es:si + ll_node.next + 2]
 	mov bx, word [es:si + ll_node.next]
 	mov es, bx
 	mov si, di

 	jmp .mem_loop

.done:
	popa
	ret

;Get last node of linked list
;	ES:SI - location of first node of linked list
last_node_ll:
	push di
	push bx
	push cx

.loop:
	mov bx, word [es:si + ll_node.next]
 	mov cx, word [es:si + ll_node.next + 2]
 	add bx, cx

 	cmp bx, 0
 	je .done

 	mov di, word [es:si + ll_node.next + 2]
 	mov bx, word [es:si + ll_node.next]
 	mov es, bx
 	mov si, di
	jmp .loop

.done:

	pop cx
	pop bx
	pop di
	ret

;Add node to linked list struct
;	ES:SI - address of node to add
;	FS:DI - location of start of linked list to add to
add_to_ll:
	pusha

	push si
	push es

	;Swap around parameters to get last node
	mov ax, fs
	mov es, ax
	mov si, di

	call last_node_ll 						;Get to end of list (in SI)

	pop fs
	pop di

	;	FS:DI is now new node
	;	ES:SI is now end of ll

	mov word [es:si + ll_node.next], fs		;Set segment to new node
	mov word [es:si + ll_node.next + 2], di	;Set offset to new node

	mov word [fs:di + ll_node.prev], es		;Set segment to last node
	mov word [fs:di + ll_node.prev + 2], si	;Set offset to last node

	popa	
	ret

;Remove from linked list struct
;	ES:SI - address of list member to remove
remove_from_ll:
	pusha
	mov ax, es
	mov gs, ax

	mov ax, word [gs:si + ll_node.prev]		;Get segment of previous node
	mov bx, word [gs:si + ll_node.next]		;Get segment of next node
	mov es, ax
	mov fs, bx
	mov di, word [gs:si + ll_node.next + 2]	;Get offset of next node
	mov si, word [gs:si + ll_node.prev + 2]	;Get offset of previous node

	;	ES:SI - prev node
	;	FS:DI - next node


	;Set adjacent nodes to now point to eachother
	mov ax, es
	add ax, si
	cmp si, 0								;Move on if there is no prev node
	je .next
	mov [es:si + ll_node.next], fs
	mov [es:si + ll_node.next + 2], di

.next:
	mov ax, fs
	add ax, di
	cmp di, 0
	je .done								;Move on if there is no next node
	mov [fs:di + ll_node.prev], es
	mov [fs:di + ll_node.prev + 2], si

.done:
	popa
	ret

;Allocate memory
;	AX - bytes to allocate
;Returns
;	ES:SI - pointer to linked list struct describing allocated memory
;###########NEED TO EXTEND TO WORK WITH MULTIPLE SEGMENTS(?)
malloc:
	pusha

	;Get start of free mem block list
	mov si, [free_mem_ll]
	mov bx, cs
	mov es, bx

	;Save 1st entry as current largest
	mov word [.largest_block], es
	mov word [.largest_block + 2], si
.loop:
	mov word [.curr_block + 2], si			;Keep track of current block
	mov word [.curr_block], es

	cmp word [es:si + ll_node.size], ax		;Do we have the size chunk caller wants?
	je .done

	;Get size of current largest block
	mov di, word [.largest_block + 2]
	mov fs, word[.largest_block]
	mov bx, word [fs:di + ll_node.size]

	cmp word [es:si + ll_node.size], bx		;Do we have a new largest block of free mem?
	jg .update_largest

.check_done:
	mov bx, word [es:si + ll_node.next]
	add bx, word [es:si + ll_node.next + 2]
	cmp bx, 0								;Check if we have reached the end of the list
	je .make_block

.next:
	mov si, word [es:si + ll_node.next + 2]	;Go to next list node
	mov bx, word [es:si + ll_node.next]
	mov es, bx

	jmp .loop

.update_largest:
	mov word [.largest_block], es
	mov word [.largest_block + 2], si
	jmp .next

	;Make a new block of needed size by carving largest free block
.make_block:
	mov si, word [.largest_block + 2]		;Get largest block to slice
	mov es, word [.largest_block]

	add ax, 16								;Calculate size of block to allocate + ll node

	;Test if we have enough RAM, die otherwise
	mov cx, word [es:si + ll_node.size]
	cmp ax, cx
	jl kernel_panic							;We outta RAM! PANIC!

	mov di, si
	add di, word [es:si + ll_node.size]		;Get to end of block

	sub word [es:si + ll_node.size], ax		;Shrink block we are chopping

	sub di, ax								;Make space to allcoate new block
	mov word [.curr_block], es
	mov word [.curr_block + 2], di			;Save over lcoation of new ll node

	;Initialize new linked list node
	mov bx, di
	add bx, 16
	mov word [es:di + ll_node.address + 2], bx	;Set location of memory block
	mov word [es:di + ll_node.address], es

	sub ax, 16							
	mov word [es:di + ll_node.size], ax		;Set size attribute
	mov word [es:di + ll_node.size + 2], 0x00

	mov si, di
	mov di, word [used_mem_ll]				;Get start of used_mem_ll
	mov ax, cs
	mov fs, ax

	call add_to_ll 							;Add to used_mem_ll

	mov si, word [.curr_block]				;Make sure to get out of the edge case catch

.done:
	cmp si, word [free_mem_ll]				;Check we allocated something
	je .make_block							;If not, we only have one block so split it up
	popa

	mov si, word [.curr_block + 2]			;Return current block
	mov ax, word [.curr_block]
	mov es, ax
	ret

	.largest_block dw 0, 0
	.curr_block dw 0, 0

;Free memory
;	SI - ll node for malloc'd block
free:
	pusha

	call remove_from_ll 					;Remove from current list

	;Add to free mem list
	mov di, word [free_mem_ll]				;Add to free mem list
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

	mov cx, ax							;Get iterater loaded
	mov ax, 16							;Do 16 byte lines
.loop:
	call dump_mem_line 					;Do one line
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

	call advence_cursor				;Make some space

	push ax							;Save for later

	mov cx, ax						;Prepare iterator
	mov ax, es
	call hprint
	mov al, ':'
	call cprint
	mov ax, si
	call hprint						;Print address

	mov al, '|'				
	call cprint
.hex_loop:							;Print out hex string of RAM
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
.chr_loop:							;Print out char string of RAM
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
	cmp ax, 0						;Have we copied everything?
	je .done

	;Move over the next byte
	mov bx, [es:si]
	mov [fs:di], bx

	;Increment the source and destinations
	inc si
	inc di
	dec ax							;Decrement the bytes counter
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
	cmp ax, 0						;Are we done with chunk?
	je .done

	mov [fs:di], bx					;Set to specified value

	;Increment counter and location
	inc di
	dec ax

	jmp .loop

.done:
	popa
	ret