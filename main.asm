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

	jmp end

boot_msg: 		db 'Booting up...', 10, 0
panic_msg:		db 'Kernel Panic!', 10, 0
mm_msg:			db 'Init memory manager...   ', 0
ivt_msg:		db 'Init IVT...              ', 0

%include "mem.asm"
%include "string.asm"
%include "ivt.asm"
%include "tty.asm"

kernel_panic:
	mov si, panic_msg
	mov al, 0x04
	call attr_sprint

end:
	hlt
	jmp end

start_free_mem:
