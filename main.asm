	org 100h		;Assemble as dos-style com file

	jmp short start	;Jump to startup

	db 'main.asm'

start:
	cli
	xor ax, ax		;make it zero
	mov ss, ax		;stack starts at 0
	mov sp, 0FFFFh
 	sti

 	;Setup cursor and screen
 	call cursor_on
 	call clear_screen

 	;Print booting message
 	mov si, boot_msg
 	call sprint

 	;Initialize memory manager
 	mov si, mm_msg
 	call sprint
 	call init_mm
 	call print_ok

	;Initialize and fill out IVT
	mov si, ivt_msg
	call sprint
	call init_ivt
	call print_ok

	mov si, keybd_test
	mov ax, 0x01
	call register_keybd_event
	mov si, keybd_event_table
	mov ax, 32
	call dump_mem

	jmp end

boot_msg: 		db 'Booting up...', 10, 0
panic_msg:		db 'Kernel Panic!', 10, 0
mm_msg:			db 'Init memory manager...   ', 0
ivt_msg:		db 'Init IVT...              ', 0

%include "mem.asm"
%include "string.asm"
%include "tty.asm"
%include "keybd.asm"
%include "ivt.asm"

keybd_test:
	pusha

	mov si, .msg
	call sprint

	mov ax, 0x01
	mov si, keybd_test
	call remove_keybd_event

	popa
	ret

	.msg db 'Keyboard Event Test', 10, 0

kernel_panic:
	mov si, panic_msg
	mov al, 0x04
	call attr_sprint

end:
	;cli
	;hlt
	jmp end

start_free_mem:
