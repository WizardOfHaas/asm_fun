;Generic event handling

;Check for registered events and run them as needed
;	AX - Event number
;	SI - Address of event table
run_events:
	pusha
.loop:
	mov bx, [si + 2]					;Do we have an event?
	cmp bx, 0
	je .next

	cmp si, keybd_event_table + 256
	je .done

	cmp ax, [si]
	je .exec

.next:
	add si, 4
	jmp .loop

.exec:
	mov di, [si + 2]
	call di
	jmp .next

.done:
	popa
	ret

;Register an event to fire
;	DI - Address of event handler
;	AX - Event number
register_event:
	pusha

	push ax
.loop:
	mov ax, [di + 2]
	cmp ax, 0
	je .register
	add di, 4
	jmp .loop

.register:
	pop ax

	mov [di], ax
	mov [di + 2], si

	popa
	ret

;Remove event from tables
;	SI - Address of event handler
;	DI - Event table
;	AX - Event number
remove_event:
	pusha

	mov cx, di
	add cx, 256
.loop:
	cmp di, cx							;Go over whole table
	je .done

	mov bx, [di + 2]					;Do we have the correct address?
	cmp bx, si
	jne .next

	mov bx, [di]						;Do we have the correct scancode
	cmp bx, ax
	jne .next

	;Clear out table entry
	mov word [di], 0
	mov word [di + 2], 0

.next:
	add di, 4							;Increment to next entry
	jmp .loop

.done:
	popa
	ret