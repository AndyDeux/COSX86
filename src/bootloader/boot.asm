org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A 



;
; Bios parameter book FAT12 header
;
jmp short start
nop

bdb_oem: 					db 'MSWIN4.1'   		; 8 bytes		
bdb_bytes_per_sector:		dw 512
bdb_sectors_per_cluster: 	db 1
bdb_reserved_sectors: 		dw 1
bdb_fat_count: 				db 2
bdb_dir_entries_count: 		dw 0E0h
bdb_total_sectors: 			dw 2880					; 2880 * 512 = 1.44MB
bdb_media_descriptor_type: 	db 0F0h
bdb_sectors_per_fat: 		dw 9
bdb_sectors_per_track: 		dw 18
bdb_heads: 					dw 2
bdb_hidden_sectors: 		dd 0
bdb_large_sector_count: 	dd 0

; Extended boot record (EBR)

ebr_drive_number: 			db 0					; 0x00 floppy, 0x80 hdd, not much use
							db 0					; reserved
ebr_signature: 				db 29h		
ebr_volume_id: 				db 12h, 34h, 56h, 78h	; serial number, value does not matter
ebr_volume_label: 			db 'ANDR OS    '       	; 11 butes, padded with spaces
ebr_system_id: 				db 'FAT12   ' 			; 8 bytes

start: 
	; Setting up data segments
	mov ax, 0
	mov ds, ax
	mov es, ax

	; Settings up the stack
	mov ss, ax
	mov sp, 0x7C00

	;Some BIOSes can load the memory location wrongly such as 07C0:0000 instead of 0000:07C0. You have to be sure you start reading from the right location
	push es
	push word .after
	retf

.after:



	; Reading something from the floppy disk
	; BIOS sets DL to drive number
	mov [ebr_drive_number], dl

	

	;Print the loading message...
	mov si, msg_loading
	call puts

	;Reading the drive parameters - more specifically the (sectors per track) and (head count) 
	push es
	mov ah, 08h
	int 13h
	jc floppy_error
	pop es

	and cl, 0x3F							; Shave off the top 2 bits
	xor ch, ch
	mov [bdb_sectors_per_track], cx			; The sector count


	inc dh
	mov [bdb_heads], dh						; The head count

	;Read the FAT root directory
	mov ax, [bdb_sectors_per_fat]			; Compute the LBA of root directory = reserved + fats * sectors_per_fat
	mov bl, [bdb_fat_count]		
	xor bh, bh
	mul bx									; ax = (fats * sectors_per_fat)
	add ax, [bdb_reserved_sectors]			; ax = LBA of root directory, assignment
	push ax

	; Computing the size of the root directory = (32 * number_of_entries) / bytes_per_sector
	mov ax, [bdb_dir_entries_count]    		
	shl ax, 5 								; ax *= 32
	xor dx, dx 								; dx = 0
	div word [bdb_bytes_per_sector]			

	test dx, dx 							; If dx != 0 add a 1

	jz .root_dir_after
	inc ax 									; If the division remainder is != 0 add a 1
											; means a partially filled sector

.root_dir_after:

	; Reading the root directory
	mov cl, al								; cl = The number of sectors to read is the size of the root directory
	pop ax									; ax = LBA of root dir
	mov dl, [ebr_drive_number]				; dl = drive_number
	mov bx, buffer							; es:bx -> buffer
	call disk_read


	;Searching for kernel.bin
	xor bx, bx
	mov di, buffer

.search_kernel:
	mov si, file_kernel_bin
	mov cx, 11 								;Comparing up to 11 chars
	push di
	repe cmpsb
	pop di
	je .found_kernel

	add di, 32
	inc bx
	cmp bx, [bdb_dir_entries_count]
	jl .search_kernel

	;Else kernel not found 
	jmp kernel_not_found_error

.found_kernel:

	; di should still point to dir entry
	mov ax, [di+26]							; First logical cluster field (the offset is always 26 per FAT docs)
	mov [kernel_cluster], ax

	;Loading the File Allocation Table from the disk into the memory
	mov ax, [bdb_reserved_sectors]
	mov bx, buffer
	mov cl, [bdb_sectors_per_fat]
	mov dl, [ebr_drive_number]
	call disk_read

	;Reading the File Allocation Table and processing the FAT chain
	mov bx, KERNEL_LOAD_SEGMENT
	mov es, bx
	mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop:

	;Read the next cluster...
	mov ax, [kernel_cluster]

	; Hardcoded...
	add ax, 31 								; The first cluster = (kernel_cluster - 2) * sectors_per_cluster + start_sector
											; The start sector = reserved + FATs + root directory size = 1 + 18 + 134 = 33

	mov cl, 1 
	mov dl, [ebr_drive_number]
	call disk_read

	add bx, [bdb_bytes_per_sector]

	;Computing the location of the next cluster...
	mov ax, [kernel_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx									; ax = Index of entry in the File Allocation Table, dx = Cluster % 2

	mov si, buffer
	add si, ax
	mov ax, [ds:si]							; Read an entry from the File Allocation Table at index ax

	or dx, dx
	jz .even 

.odd:
	shr ax, 4
	jmp .next_cluster_after

.even:
	and ax, 0x0FFF

.next_cluster_after:
	cmp ax, 0x0FF8							; End of chain
	jae .read_finish

	mov [kernel_cluster], ax
	jmp .load_kernel_loop


.read_finish:
	; Jumping to the kernel

	mov dl, [ebr_drive_number]				;Boot device is in dl


	mov ax, KERNEL_LOAD_SEGMENT				;Set the segment registers
	mov ds, ax
	mov es, ax

	jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET

	jmp wait_key_and_reboot					; This should basically never happen but in any case...

	cli    									; Disable interrupts so the CPU can get out of the "halt" state
	hlt
	

;
;		Error handlers
;

floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot

kernel_not_found_error:
	mov si, msg_kernel_not_found
	call puts
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 16h							; Wait for the keypress
	jmp 0FFFFh:0					; Jump to the beggining of the BIOS, it should reboot


.halt:
	cli 							; Disable interrupts. This way the CPU cannot get out of the "halt" state
	hlt



puts:
    ; Saving the registers that will be modified
    push si
    push ax
    push bx

.loop:
    lodsb               ; Loads the next character in al
    or al, al           ; Verifies if the next character is = NULL
    jz .done

    mov ah, 0x0E        ; Calls the BIOS interrupt
    mov bh, 0           ; Sets the page number to zero
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret

;
; Disk routines
;

;
; Converts an LBA address to a CHS address
; Parameters:
;	-ax : LBA address
; Returns:
;	- cx [bits from 1 to 5]: sector number;
;	- cx [bits from 6 to 15]: cylinder
;	- dh: head
;

lba_to_chs:

	push ax
	push dx


	xor dx, dx							; dx = 0
	div word [bdb_sectors_per_track]	; dx = LBA / SectorsPerTrack
										; dx = LBA % SectorsPerTrack

	inc dx								; dx = (LBA % SectorsPerTrack + 1) = sector
	mov cx, dx							; cx = sector

	xor dx, dx 							; dx initialized to 0 again
	div word [bdb_heads]				; ax = (LBA / SectorsPerTrack) / Heads = cylinder
										; dx = (LBA / SectorsPerTrack) % Heads = head
										; dh = head
	
	mov dh, dl							; ch = cylinder (lower 8 bits)
	mov ch, al
	shl ah, 6
	or cl, ah							; put upper 2 bits of the cylinder into CL
	
	pop ax
	mov dl, al							; restore DL
	pop ax
	ret


;
; Reads sectors from a disk
; Parameters:
;	- ax: LBA address
;	- cl: number of sectors to read (up to 128)
;	- dl: drive number
; 	- ex:bx: memory address where to store read data

disk_read:

	push ax								; Save registers that are modified
	push bx
	push cx
	push dx
	push di



	push cx 							; Save CL temporarily (Where CL is the number of sectors to read)
	call lba_to_chs						; Computer CHS
	pop ax 								; AL = number of sectors to read
	
	mov ah, 02h
	mov di, 3							; Number of times to retry

.retry:
	pusha								; Save all of the registers, no idea what the bios modifies
	stc 								; Set carry flag, some bioses are known not to set it
	int 13h								; Carry flag cleared = success
	jnc .done							; Jump if the carry is not set
	
	; If read failed
	popa
	call disk_reset

	dec di
	test di, di
	jnz .retry

.fail:
	; No more attemps left/All attemps exhausted
	jmp floppy_error

.done:
	popa

	pop di
	pop dx
	pop cx
	pop bx
	pop ax								; Restore registers modified
	ret

;
;	This function resets the disk controller
; 	Parameters:
;		dl: drive number
;
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret

msg_loading: 			db 'Loading...', ENDL, 0
msg_read_failed: 		db 'Read from disk failed!', ENDL, 0
msg_kernel_not_found: 	db 'KERNEL.BIN file not found!', ENDL, 0
file_kernel_bin: 		db 'KERNEL  BIN'
kernel_cluster: 		dw 0

KERNEL_LOAD_SEGMENT		equ 0x2000		; Basically a preprocessor directive in C
KERNEL_LOAD_OFFSET 		equ 0

times 510-($-$$) db 0
dw 0AA55h

buffer:
