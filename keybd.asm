;Keyboard control routines

	db 'keybd.asm'

keylayoutlower:
	db 0x00, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0x0e, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 10, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',';', "'", '`', 0, 0, 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0

keylayoutupper:
	db 0x00, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0x0e, 0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 10, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, 0, 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0
	;;  0e = backspace

shift_state: db 0
caps_lock: db 0

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

	mov al, 0x20				;End of Interrupt
	out 0x20, al	

	pop ax						;Make sure AX just show AL data
	mov ah, 0

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

	cmp ax, 0x81				;Do we have a key up scancode?
	jge .key_up

	;Are we shifted?
	mov si, keylayoutlower 		;Get un-shifted scancode table

	mov bl, byte [caps_lock]
	mov bh, byte [shift_state]
	xor bl, bh

	cmp bl, 0
	je .decode

	mov si, keylayoutupper 		;Get shifter scancode table, if shifted

.decode:
	;Decode scancode -> character
	add si, ax
	mov al, byte [si]

	call cprint
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

.key_up:
.done:
	popad
	iret