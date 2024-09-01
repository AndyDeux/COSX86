org 0x0
bits 16

%define ENDL 0x0D, 0x0A 

start: 
	;Prints the string

	mov si, msg_hello
	call puts
	

.halt:
	cli
	hlt


;
; Prints a string to the screen
; Parameters:
;   - ds:si pointing to string
;
puts:
    ; Saving the register that will be modified
    push si
    push ax
    push bx

.loop:
    lodsb               ; Loads the next character in al
    or al, al           ; Verifies if the next character is NULL
    jz .done

    mov ah, 0x0E        ; Calls the BIOS interrupt
    mov bh, 0           ; Sets the page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret


msg_hello: db 'Hello World!', ENDL, 0
