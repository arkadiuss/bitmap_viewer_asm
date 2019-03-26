ASSUME cs:code1

data1 segment
image_name_len  db  0
image_name      db  32 dup(0) 
image_ptr       db  ?    
image           db  200 dup(0)
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
    rep movsb
    
    ; file reading
    mov ax, seg image_name
    mov ds, ax
    mov dx, offset image_name
    mov ah, 3dh ; open
    int 21h
    mov word ptr ds:[image_ptr], ax
    mov dx, offset image
    mov bx, word ptr ds:[image_ptr]
    mov ah, 3fh ; read
    mov cx, 50
    int 21h   
    mov bx, word ptr ds:[image_ptr]
    mov ah, 3eh ; close
    int 21h
    
    
    
    
end1: 
    mov ax, 4c00h
    int 21h
    
    
code1 ends

stack1 segment STACK
	dw 400 dup(?)   
ws1 dw ?	
stack1 ends

end start1