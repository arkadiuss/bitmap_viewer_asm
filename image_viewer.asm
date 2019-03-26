ASSUME cs:code1

data1 segment
image_name_len  db  0
image_name      db  32 dup(0) 
handle          db  ?    
bitmap_header   db  14 dup(?)
image_header    db  40 dup(?)
file_ptr        dw  ?
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
    mov byte ptr es:[offset image_name_len], al
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
    
    ; bitmap header reading
    mov word ptr ds:[handle], ax
    mov dx, offset bitmap_header
    mov bx, word ptr ds:[handle]
    mov ax, 0
    mov ah, 3fh ; read
    mov cx, 14
    int 21h
    
    ; file header reading
    mov dx, offset image_header
    mov ax, 0
    mov ah, 3fh ; read
    mov cx, 40
    int 21h
    
    ; point file to pixels and set file ptr
    mov dx, word ptr ds:[bitmap_header + 10]  ; pixels offset
    mov word ptr ds:[file_ptr], dx
    call set_file_ptr
    
    ; graphical mode
    mov al, 13h
    mov ah, 0
    int 10h
    
    mov cx, 320
lh: 
    push cx
    mov cx, 200
lw: push cx
    
    pop cx
    loop lw
    add word ptr ds:[file_ptr]
    pop cx    
    loop lh       
    
    ; file closing   
    mov bx, word ptr ds:[handle]
    mov ax, 0
    mov ah, 3eh ; close
    int 21h
    
end1: 
    mov ax, 4c00h
    int 21h
    
    
set_file_ptr:
    mov ah, 42h
    mov al, 00
    mov bx, word ptr ds:[handle]
    int 21h
    ret        
    
    
code1 ends

stack1 segment STACK
	dw 400 dup(?)   
ws1 dw ?	
stack1 ends

end start1