;Keyboard control routines

	db 'keybd.asm'

keylayoutlower:
	db 0x00, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0x0e, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',';', "'", '`', 0, 0, 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0

keylayoutupper:
	db 0x00, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0x0e, 0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 10, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, 0, 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0
	;;  0e = backspace

shift_state: db 0
caps_lock: db 0

keybd_buff: times 256 db 0	;Keyboard buffer
keybd_buff_i: db 0, 0				;Keyboard buffer index

keybd_event_table: times 256 db 0

keybd_isr:
	pushad

	in al, 0x60					;Get key data
	push ax

	in al, 0x61					;Keybrd control
	mov ah, al
	or al, 0x80					;Disable bit 7
	out 0x61, al				;Send it back
	xchg ah, al					;Get original
	out 0x61, al				;Send that back

	pop ax						;Make sure AX just show AL data
	mov ah, 0

	;Check for and run any registered keybd events
	mov si, keybd_event_table
	call run_events

	;Handle shift, capslock, meta-keys
	cmp ax, 0x2A				;Left-shift down
	je .shift_down
	cmp ax, 0x36				;Right-shift down
	je .shift_down

	cmp ax, 0xAA				;Left-shift up
	je .shift_up
	cmp ax, 0xB6				;Right-shift up
	je .shift_up

	cmp ax, 0x3A				;Caps lock down
	je .shift_toggle

	cmp ax, 0x0E				;Backspace
	je .backspace

	cmp ax, 0x81				;Do we have a key up scancode?
	jge .key_up

	;Are we shifted?
	mov si, keylayoutlower 		;Use un-shifted scancode table

	;Handle compination of caps lock and shifts
	mov bl, byte [caps_lock]
	mov bh, byte [shift_state]
	xor bl, bh

	cmp bl, 0
	je .decode

	mov si, keylayoutupper 		;Use shifter scancode table, if shifted

.decode:
	;Decode scancode -> character
	add si, ax
	mov al, byte [si]

	call cprint

	;Add to buffer
	movzx di, byte [keybd_buff_i]
	add di, keybd_buff
	mov byte [di], al
	inc byte [keybd_buff_i]

	jmp .done

.shift_toggle:
	mov al, byte [caps_lock]
	xor al, 1
	mov byte [caps_lock], al
	jmp .done

.shift_down:
	mov byte [shift_state], 1	;We are shifted up
	jmp .done

.shift_up:
	mov byte [shift_state], 0	;We are not shifted
	jmp .done

.backspace:
	;Remove from buffer
	movzx di, byte [keybd_buff_i]
	add di, keybd_buff
	sub di, 1
	mov byte [di], 0
	dec byte [keybd_buff_i]

	jmp .done

.key_up:
.done:
	;Send EOI
	mov al, 0x20
	out 0xA0, al
	out 0x20, al

	popad
	iret

;Clear keyboard buffer and reset buffer index
clear_keybd_buff:
	pusha
	cli

	mov word [keybd_buff_i], 0	;Reset buffer index

	;Reset buffer to 0's
	mov ax, 254
	mov di, keybd_buff
	mov cx, cs
	mov fs, cx
	mov bx, 0

	call memset

	sti
	popa
	ret