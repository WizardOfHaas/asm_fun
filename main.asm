	org 100h	;Assemble as dos-style com file

	jmp short start	;Jump to startup

start:
	cli
	xor ax, ax		;make it zero
	mov ss, ax		;stack starts at 0
	mov sp, 0FFFFh
 	sti

 	call cursor_on
 	call clear_screen

 	mov si, boot_msg
 	call sprint

 	mov si, mm_msg
 	call sprint
 	call init_mm
 	call print_ok

 	mov cx, 2

.loop:
	mov ax, cx
	call malloc

	dec cx
	cmp cx, 0
	jne .loop

;	mov si, word [used_mem_ll]
;.mem_loop:
;	mov ax, 16
; 	call dump_mem
;
; 	cmp word [si + ll_node.next], 0
; 	je end
;
; 	mov si, word [si + ll_node.next]
;
; 	jmp .mem_loop

	jmp end

boot_msg: 		db 'Booting up...', 10, 0
panic_msg:		db 'Kernel Panic!', 10, 0
mm_msg:			db 'Init memory manager...   ', 0

%include "tty.asm"
%include "mem.asm"
%include "string.asm"

kernel_panic:
	mov si, panic_msg
	mov al, 0x04
	call attr_sprint

end:
	jmp end

start_free_mem:
