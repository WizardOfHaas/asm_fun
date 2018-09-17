	org 100h	;Assemble as dos-style com file

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

 	mov cx, 1
.loop:
	mov ax, cx
	call malloc
	call free

	mov di, word [si + ll_node.address]
	mov word [di], cx

	inc cx
	cmp cx, 10
	jne .loop

	mov si, word [free_mem_ll]
	call print_ll

	jmp end

boot_msg: 		db 'Booting up...', 10, 0
panic_msg:		db 'Kernel Panic!', 10, 0
mm_msg:			db 'Init memory manager...   ', 0

%include "mem.asm"
%include "string.asm"
%include "tty.asm"

kernel_panic:
	mov si, panic_msg
	mov al, 0x04
	call attr_sprint

end:
	jmp end

start_free_mem:
