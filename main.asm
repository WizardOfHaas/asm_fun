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

	;Initialize floppy disk drive
	mov si, flpy_msg
	call sprint
	call init_flpy
	call print_ok

	;Print out total memory detected
	call new_line
	mov ax, [total_mem]
	call iprint
	mov si, kb_msg
	call sprint

	;Register keyboard event on enter key down
	mov si, keybd_test
	mov ax, 0x1C
	mov di, keybd_event_table
	call register_event

	mov ax, 0x00
	mov es, ax
	mov si, 0x1000
	mov ax, 128
	call dump_mem

	jmp end

boot_msg: 		
    db "     ______               ____  _____", 10
   	db "    / ____/_  ______     / __ \/ ___/", 10
  	db "   / /_  / / / / __ \   / / / /\__ \------------Hobby-----", 10
	db "  / __/ / /_/ / / / /  / /_/ /___/ /----------Operating--", 10
	db " /_/    \__,_/_/ /_/   \____//____/------------System---", 10
	db 0

panic_msg:		db 'Kernel Panic!', 10, 0
mm_msg:			db 'Init memory manager...   ', 0
ivt_msg:		db 'Init IVT...              ', 0
flpy_msg:		db 'Init floppy disk...      ', 0

kb_msg:			db 'kb detected', 10, 0

%include "mem.asm"
%include "string.asm"
%include "tty.asm"
%include "keybd.asm"
%include "ivt.asm"
%include "event.asm"
%include "flpy.asm"

keybd_test:
	pusha

	mov si, keybd_buff
	call sprint
	call new_line

	mov ax, 16
	call dump_mem

	call clear_keybd_buff

	popa
	ret

kernel_panic:
	mov si, panic_msg
	mov al, 0x04
	call attr_sprint

end:
	;cli
	;hlt
	jmp end

start_free_mem:
