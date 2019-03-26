ASSUME cs:code1

data1 segment
image_name_len  db  0
image_name      db  32 dup(0)    
bitmap_header   db  14 dup(?)
image_header    db  40 dup(?) 
handle          dw  ?
image_ptr       dw  ? 
start_y         dw  0
start_x         dw  0

x               dw  0
y               dw  0
color           db  ?

pixel_row       db  200 dup(?)
data1 ends

code1 segment
start1:
    ; set stack pointer 
    mov ax, seg ws1
    mov ss, ax
    mov sp, offset ws1 ;w. stosu -> ss:sp
    
    ; read program arguments
    mov ax, seg image_name
    mov es, ax
    mov di, offset image_name ; destination
    mov si, 82h              
    mov al, byte ptr ds:[80h]
    mov byte ptr es:[image_name_len], al
    mov cx, 0               
    mov cl, al
    dec cl     ; workaround for additional sign in emulator
    rep movsb
    
    ; file opening
    mov ax, seg image_name
    mov ds, ax
    mov dx, offset image_name
    mov ax, 0
    mov ah, 3dh ; open
    int 21h
    mov word ptr ds:[handle], ax
    
    ; bitmap header reading
    mov dx, offset bitmap_header
    mov cx, 14 
    call read_file
    
    ; file header reading
    mov dx, offset image_header
    mov cx, 40
    call read_file
    
    ; point file to pixels and set file ptr
    mov dx, word ptr ds:[bitmap_header + 10]  ; pixels offset
    mov word ptr ds:[image_ptr], dx
    
    ; graphical mode
    mov al, 13h
    mov ah, 0
    int 10h
    
    mov ax, word ptr ds:[start_y]
    mov word ptr ds:[y], ax
    mov cx, 200
ly: 
    mov ax, word ptr ds:[y]
    mov word ptr ds:[x], 0
    push cx
    mov dx, word ptr ds:[image_header + 4]
    mov ax, word ptr ds:[y]
    mul bx
    mov bx, word ptr ds:[x]
    add bx, ax
    add bx, 58
    mov dx, bx
    mov cx, 0
    call set_file_ptr
    mov dx, offset pixel_row
    mov cx, 250
    call read_file
    
    mov cx, 250
lx: push cx
    
    mov bx, word ptr ds:[x]  
    mov al, byte ptr ds:[pixel_row + bx]
    mov byte ptr ds:[color], al
    call set_pixel
    inc word ptr ds:[x]
    pop cx
    loop lx
    
    inc word ptr ds:[y]
    pop cx    
    loop ly
    
    ; file closing   
    mov bx, word ptr ds:[handle]
    mov ax, 0
    mov ah, 3eh ; close
    int 21h
    
end1:
    xor ax,ax
    int 16h ; czekaj na dowolny klawisz
    
    mov al, 3h ; tryb tekstowy
    mov ah, 0 ; zmien tryb vga
    int 10h 
    mov ax, 4c00h
    int 21h
    
    
set_file_ptr:
    mov bx, word ptr ds:[handle]
    mov ah, 42h
    mov al, 00
    int 21h
    ret
    
read_file: 
    mov bx, word ptr ds:[handle]
    mov ax, 0
    mov ah, 3fh ; read
    int 21h
    ret            
       
set_pixel:
    mov ax, 0a000h
    mov es, ax
    mov bx, 320
    mov ax, word ptr ds:[y]
    mul bx 
    mov bx, word ptr ds:[x]
    add bx, ax
    mov al, byte ptr ds:[color]
    mov byte ptr es:[bx], al
    ret          
    
code1 ends

stack1 segment STACK
	dw 400 dup(?)   
ws1 dw ?	
stack1 ends

end start1