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

	jmp end

boot_msg: db 'Booting up...', 10, 0

%include "tty.asm"
%include "mem.asm"
%include "string.asm"

end:
	jmp end

start_free_mem: