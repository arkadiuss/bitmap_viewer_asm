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
scale           db  1
mode            db  1
r               db  ?
g               db  ?
b               db  ?

color_map       db  1024 dup(?)
pixel_row       db  1024 dup(?)
key             db  0
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
    
    ; constants
    PIXEL_OFFSET equ bitmap_header + 10
    WIDTH equ image_header + 4
    HEIGHT equ image_header + 8
    
    ; bitmap header reading
    mov dx, offset bitmap_header
    mov cx, 14 
    call read_file
    
    ; file header reading
    mov dx, offset image_header
    mov cx, 40
    call read_file
    
    ; color map reading
    ; TODO: only if 256 colors
    mov dx, offset color_map
    mov cx, 1024 ; ONLY FOR 8 bits per color!!!
    call read_file
    
    ; point file to pixels and set file ptr
    mov dx, word ptr ds:[PIXEL_OFFSET]  ; pixels offset
    mov word ptr ds:[image_ptr], dx
    
    ; graphical mode
    mov al, 13h
    mov ah, 0
    int 10h

; program_loop
prog: 
    ; set pointer to the end of file
    mov ax, word ptr ds:[start_y]
    inc ax
    mul word ptr ds:[WIDTH]
    mov cx, 0xFFFF
    sub cx, dx
    mov dx, 0
    sub dx, ax
    mov al, 02h
    call set_file_ptr 
     
    mov word ptr ds:[y], 0
    mov cx, 200
ly: push cx
    mov dx, offset pixel_row
    mov cx, 1024
    call read_file
    ; clear x                      
    mov word ptr ds:[x], 0
    
    mov cx, 320
lx: push cx
    
    mov ax, word ptr ds:[x]
    ; apply zoom
    mov bx, 0
    mov bl, byte ptr ds:[scale]
    cmp byte ptr ds:[mode], 1
    jnz zoom_in
zoom_out:    
    mul bx
    jmp after_zoom
zoom_in:
    mov dx, 0
    div bx
after_zoom:        
    mov bx, ax
    ; apply start x offset
    add bx, word ptr ds:[start_x]
    mov ax, 0
    ; only for 8bits per color -----  
    mov al, byte ptr ds:[pixel_row + bx]
    mov bx, 0
    mov bl, 4
    mul bl
    mov bx, ax
    mov ax, 0
    add bx, offset color_map
    mov al, byte ptr ds:[bx]
    inc bx
    mov byte ptr ds:[b], al
    mov al, byte ptr ds:[bx]
    inc bx
    mov byte ptr ds:[g], al
    mov al, byte ptr ds:[bx]
    mov byte ptr ds:[r], al
    ; ------------------------------
    call set_pixel
    
    inc word ptr ds:[x]
    pop cx
    loop lx
    
    inc word ptr ds:[y] 
    
    ; back ptr 2*width
    mov cx, 0xFFFF 
    mov dx, 0xFFFF
    mov ax, word ptr ds:[WIDTH]
    mov bx, 2h
    mul bx
    sub dx, ax
    mov al, 01h
    call set_file_ptr
    pop cx    
    loop ly
    
    ; keyboard
keybord_input:    
    in al, 60h
    cmp al, byte ptr ds:[key]
    jz keybord_input
    mov byte ptr cs:[key], al    
    
    cmp al, 1 ; esc
    jz end1
    
    cmp al, 28 ; esc
    jz end1
    
cmp_r_arr:    
    cmp al, 77 ; right arrow
    jnz cmp_l_arr
    inc word ptr ds:[start_x]
    
cmp_l_arr:
    cmp al, 75 ; left arrow
    jnz cmp_u_arr
    dec word ptr ds:[start_x]
    
cmp_u_arr:
    cmp al, 72 ; up arrow
    jnz cmp_d_arr
    dec word ptr ds:[start_y]
    
cmp_d_arr:
    cmp al, 80 ; down arrow
    jnz cmp_plus
    inc word ptr ds:[start_y]
    
cmp_plus:    
    cmp al, 2
    jnz cmp_minus   
    mov al, 0
    call update_scale
    
cmp_minus:
    cmp al, 3
    jnz continue   
    mov al, 1
    call update_scale
        
continue:        
    jmp prog
    
end1:    
    ; file closing   
    mov bx, word ptr ds:[handle]
    mov ax, 0
    mov ah, 3eh ; close
    int 21h
    
    mov al, 3h ; tryb tekstowy
    mov ah, 0 ; zmien tryb vga
    int 10h 
    mov ax, 4c00h
    int 21h
    
    
set_file_ptr:
    mov bx, word ptr ds:[handle]
    mov ah, 42h
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
    push bx
    call convert_from_rgb
    pop bx
    mov byte ptr es:[bx], al
    ret
    
convert_from_rgb:
    mov ax, 0
    mov al, byte ptr ds:[r]
    mov bx, 32
    div bx
    mov byte ptr ds:[r], al
    
    mov ax, 0
    mov al, byte ptr ds:[g]
    mov bx, 32
    div bx
    mov byte ptr ds:[g], al
    
    mov ax, 0
    mov al, byte ptr ds:[b]
    mov bx, 64
    div bx
    mov byte ptr ds:[b], al
    
    mov ax, 0
    mov al, byte ptr ds:[r]
    shl al, 3h
    add al, byte ptr ds:[g]
    shl al, 2h
    add al, byte ptr ds:[b]
    ret

update_scale:
    cmp byte ptr ds:[scale], 1
    jnz no_mode_change
    mov byte ptr ds:[mode], al
    jmp inc_scale
    
no_mode_change:    
    cmp al, byte ptr ds:[mode]
    jnz dec_scale
inc_scale:
    cmp byte ptr ds:[scale], 3
    jz end_scale
    inc byte ptr ds:[scale]
    jmp end_scale
dec_scale:
    cmp byte ptr ds:[scale], 0
    jz end_scale
    dec byte ptr ds:[scale]
end_scale:    
    ret                    
    
code1 ends

stack1 segment STACK
	dw 400 dup(?)   
ws1 dw ?	
stack1 ends

end start1