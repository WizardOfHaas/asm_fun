;TTY routines - text screen control and such

db 'tty.asm'

tty_buffer: times 80*26*2 db 0 ;TTY text memory buffer
xpos: db 0
ypos: db 0
char_attr: db 0x07

;Set character attribute byte
;	AL - new char attribute
set_char_attr:
	mov byte [char_attr], al
	ret

;Print [  OK  ] message
print_ok:
	pusha

	mov ah, byte [char_attr]

	mov al, 0x07				;Go grey on black
	call set_char_attr

	mov al, '['
	call cprint

	mov al, 0x02				;Set green on black
	mov si, .ok
	call attr_sprint

	mov al, 0x07
	call set_char_attr

	mov al, ']'
	call cprint

	mov al, ah
	call set_char_attr

	popa
	ret

	.ok db '   OK   ',0

;Print string with given attr
;	SI - string
;	AL - attribute
attr_sprint:
	pusha

	mov ah, byte [char_attr]
	call set_char_attr

	call sprint

	mov al, ah
	call set_char_attr

	popa
	ret

;Print an integer to the screen in dec
;	AX - integer to print
iprint:
	pusha

	call itoa
	call sprint

	popa
	ret

;Print an integer to the screen in hex
;	AX - integer to print
hprint:
	pusha

	call htoa
	call sprint

	popa
	ret

;Print a string to the screen
;	SI - address of string to print
sprint:
	pusha

.loop:				;Loop over string in [si]
	mov al, [si]
	cmp al, 0		;Have we reached the end?
	je .done
	inc si			;Go to next char

	call cprint 	;Print character

	jmp .loop

.done:
	popa
	ret

;Print a char directly to the screen(buffered)
;al - character to print to screen
cprint:
	pusha

	push ax					;Save ax

	movzx ax, byte [ypos]	;Get y cursor position
	mov dx, 160				;2 bytes (char/attrib)
	mul dx					;for 80 columns
	movzx bx, byte [xpos]	;Get x cursor position
	shl bx, 1				;times 2 to skip attrib
 	
 	mov di, tty_buffer		;start of video memory
	add di, ax      		;add y offset
	add di, bx      		;add x offset

	;Setup char and attributes to write
 	pop ax					;Retrive char value
 	mov ah, byte [char_attr];Set char attribute
	
 	cmp al, 10
 	je .nl

	mov word[di], ax		;Do the direct write to text ram

	call advence_cursor
	jmp .done

.nl:
	call new_line

.done:
	call dsiplay_buffer

 	popa
 	ret

;Scroll buffer and update tty
scroll:
	call scroll_buffer
	call dsiplay_buffer
	ret

;Scroll buffer
scroll_buffer:
	pusha

	;Scroll screen buffer
	mov ax, 0x50				;Set fs to text memory
	mov fs, ax
	mov es, ax

	mov di, tty_buffer			;Sex di to start of tty_buffer
	mov si, tty_buffer + 80*2	;Set si to 2nd line of tty buffer

	mov ax, 80*25*2				;80x24 section of screen

	call memcpy					;Shift buffer down

	;Scroll cursor
	mov byte [xpos], 0
	mov byte [ypos], 24

	popa
	ret

;Push buffer into text memory
dsiplay_buffer:
	pusha

	mov ax, 0xB800			;Set fs to text memory
	mov fs, ax
	xor di, di				;Sex di to start of memory

	mov ax, 0x50			;Set es to code/data segment
	mov es, ax
	mov si, tty_buffer 		;Set si to tty text buffer

	mov ax, 80*25*2			;80x25 screen

	call memcpy				;Copy over buffer

	popa
	ret

;Set all text memory to '0'
clear_screen:
	pusha

	mov ax, 0x50			;Set es to code/data segment
	mov fs, ax
	mov di, tty_buffer 		;Set si to tty btext buffer

	mov ax, 80*25*2			;80x25 screen

 	mov bh, 0x0F			;White on black attribute
 	mov bl, 0				;ascii value of 0 to display
 	
 	call memset				;Set buffer memory

 	;Reset cursor position
 	mov byte [xpos], 0
	mov byte [ypos], 0

	call dsiplay_buffer 	;Push buffer into text memory

	popa
	ret

;Move cursor to (xpos, ypos)
update_cursor:
	pusha

	cmp byte [xpos], 80		;Do we need to wrap?
	jle .next

	;Wrap cursor
	mov byte [xpos], 0
	add byte [ypos], 1

.next:
	cmp byte [ypos], 25		;Do we need to scroll?
	jl .done

	call scroll_buffer
	jmp .done

.done:

	mov dl, byte [xpos]
	mov dh, byte [ypos]

    mov  ah, 2
    mov  bh, 0
    int  10h

	popa
	ret

;Turn on cursor
cursor_on:
   mov  ah, 1
   mov  cx, 4
   int  10h
   ret

;Advance cursor
advence_cursor:
	pusha

	add byte [xpos], 1		;advance to right
 	
	call update_cursor
	
	popa
	ret

new_line:
	pusha

	mov byte [xpos], 0
	add byte[ypos], 1
	call update_cursor

	popa
	ret

;Print regesters to TTY
print_regs:
	pusha

	;Push regs to display to stack
	push di
	push si
	push dx
	push cx
	push bx
	push ax

	xor cx, cx
.loop:					;Iterate over registers on stack
	mov si, .labels		;Fetch register's label
	mov ax, 6
	mul cx
	add si, ax

	call sprint 		;Print register

	inc cx				;Inc for next loop

	pop bx				;Grab register from stack
	mov al, bh			;Do higher byte
	call hprint
	mov al, bl			;Do lower bytes
	call hprint

	cmp cx, 6			;Loop until we print out all registers
	jne .loop

	call new_line

	popa
	ret

	.labels:
		db ' ax: ', 0
		db ' bx: ', 0
		db ' cx: ', 0
		db ' dx: ', 0
		db ' si: ', 0
		db ' di: ', 0