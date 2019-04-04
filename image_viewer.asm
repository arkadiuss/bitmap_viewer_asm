ASSUME cs:code1

data1 segment
; program arguments (file name)    
image_name_len  db  0
image_name      db  32 dup(0)
; properties of bitmap    
bitmap_header   db  14 dup(?)
image_header    db  40 dup(?)
bytes_per_pixel dw  1
; handle to file 
handle          dw  ?
; start pixel (left top) to start rendering bitmap 
start_y         dw  0
start_x         dw  100

; position of current pixel to show
x               dw  0
y               dw  0
; scale from 1 to 3 for zoom in and zoom out
scale           db  1
; mode 1 - zoom out, 0 - zoom in
mode            db  1 
; color of current pixel
r               db  ?
g               db  ?
b               db  ?

; color mapping from rgb to vga
color_pallette  db  0x00,0x68,0x6B,0x6B,0x76,0x01,0x7F,0x7F,0x79,0x20,0x95,0x03,0x32,0x7B,0x2F,0x36,0x6F,0x69,0x21,0x21,0x73,0x13,0x80,0x80,0x78,0x78,0x36,0x01,0x7B,0x2F,0xD9,0xD9,0x04,0x6C,0x05,0x05,0x06,0xB8,0x6B,0x83,0x73,0x8E,0x19,0x38,0x75,0x75,0xDE,0x4A,0x04,0x6D,0x05,0x05,0x71,0xCF,0x0D,0x3A,0x73,0xBB,0x1B,0x3A,0xBD,0xBD,0x1A,0x0F
; for 8bits bitmaps - value is mapped to rgb color
color_map       db  1024 dup(?)
; one row of the image
pixel_row       db  5000 dup(?) ; max size: bytes*width < 5000 

; last entered key
key             db  0
data1 ends

code1 segment
start1:
    ; set stack pointer 
    mov ax, seg ws1
    mov ss, ax
    mov sp, offset ws1 
    
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
    mov ah, 3dh 
    int 21h
    mov word ptr ds:[handle], ax
    
    ; constants
    SCREEN_WIDTH equ 320
    SCREEN_HEIGHT equ 200
    PIXEL_OFFSET equ bitmap_header + 10
    WIDTH equ image_header + 4
    HEIGHT equ image_header + 8
    BITS_PER_PIXEL equ image_header + 14
       
    ; bitmap header reading
    mov dx, offset bitmap_header
    mov cx, 14 
    call read_file
    
    ; file header reading
    mov dx, offset image_header
    mov cx, 40
    call read_file
    
    ; count bytes per pixel
    mov dx, 0
    mov ax, word ptr ds:[BITS_PER_PIXEL]
    mov bx, 8
    div bx
    mov byte ptr ds:[bytes_per_pixel], al 
    
    ; color map reading (only for 8 bits per color)
    cmp word ptr ds:[bytes_per_pixel], 1
    jnz no_color_map
    mov dx, offset color_map
    mov cx, 1024 ; 256 colors*4 bytes in color map
    call read_file
no_color_map:
    ; graphical mode
    mov al, 13h
    mov ah, 0
    int 10h

; program_loop
prog: 
    ; set pointer to the end of file
    mov ax, word ptr ds:[start_y]
    inc ax
    mul word ptr ds:[bytes_per_pixel]
    mul word ptr ds:[WIDTH]
    mov cx, 0xFFFF
    sub cx, dx
    mov dx, 0
    sub dx, ax
    mov al, 02h
    call set_file_ptr 
     
    mov word ptr ds:[y], 0
    mov cx, SCREEN_HEIGHT
ly: push cx
    mov ax, word ptr ds:[WIDTH]
    mul word ptr ds:[bytes_per_pixel]
    mov cx, ax
    mov dx, offset pixel_row
    call read_file
    ; clear x                      
    mov word ptr ds:[x], 0
    
    mov cx, SCREEN_WIDTH
lx: push cx
    
    mov ax, word ptr ds:[x]
    ; apply zoom
    call apply_zoom       
    mov bx, ax
    ; apply start x offset
    add bx, word ptr ds:[start_x]
    mov ax, 0
    cmp word ptr ds:[bytes_per_pixel], 1
    jnz read_directly
    ; for 8bits map read pointer to color map and then value
read_from_color_map: 
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
    jmp after_reading
    ; for 24bits read directly rgb values
read_directly:
    mov ax,bx
    mov bx,3h
    mul bx
    mov bx, ax
    mov al, byte ptr ds:[pixel_row + bx]
    mov byte ptr ds:[b], al
    inc bx
    mov al, byte ptr ds:[pixel_row + bx]
    mov byte ptr ds:[g], al
    inc bx
    mov al, byte ptr ds:[pixel_row + bx]
    mov byte ptr ds:[r], al
after_reading:
    call set_pixel
    
    inc word ptr ds:[x]
    pop cx
    loop lx
    
    inc word ptr ds:[y] 
    
    
    ; apply y zoom
    ; skip reading lines or read it one more time
    cmp byte ptr ds:[mode], 1
    jnz zoom_y_in:
zoom_y_out:
    mov ax, 0    
    mov al, byte ptr ds:[scale] 
    jmp after_zoom_y
zoom_y_in:
    mov ax, word ptr ds:[y]
    mov bx, 0
    mov bl, byte ptr ds:[scale]
    mov dx, 0
    div bx
    mov ax, 0
    cmp dx, 0
    jnz after_zoom_y
    inc ax       
after_zoom_y:
    inc ax
    
    ; back reading
    mul word ptr ds:[bytes_per_pixel]
    mul word ptr ds:[WIDTH]
    mov cx, 0xFFFF
    sub cx, dx 
    mov dx, 0
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
    
    cmp al, 28 ; enter
    jz end1
    
cmp_r_arr:    
    cmp al, 77 ; right arrow
    jnz cmp_l_arr
    call check_bounds_x
    jge continue 
    inc word ptr ds:[start_x]
    
cmp_l_arr:
    cmp al, 75 ; left arrow
    jnz cmp_u_arr
    cmp word ptr ds:[start_x], 0
    jz continue
    dec word ptr ds:[start_x]
    
cmp_u_arr:
    cmp al, 72 ; up arrow
    jnz cmp_d_arr
    cmp word ptr ds:[start_y], 0
    jz continue
    dec word ptr ds:[start_y]
    
cmp_d_arr:
    cmp al, 80 ; down arrow
    jnz cmp_plus
    call check_bounds_y
    jge continue
    inc word ptr ds:[start_y]
    jmp continue
    
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

; end of the program loop        
continue:        
    jmp prog
     
; check if part of the image won't be small to show horizontally
check_bounds_x:
    push ax
    mov ax, SCREEN_WIDTH
    call apply_zoom
    add ax, word ptr ds:[start_x]
    cmp ax, word ptr ds:[WIDTH]
    pop ax
    ret

; check if part of the image won't be small to show vertically    
check_bounds_y:
    push ax
    mov ax, SCREEN_HEIGHT
    call apply_zoom
    add ax, word ptr ds:[start_y]
    cmp ax, word ptr ds:[HEIGHT]
    pop ax
    ret         
     
end1:    
    ; file closing   
    mov bx, word ptr ds:[handle]
    mov ax, 0
    mov ah, 3eh ; close
    int 21h
    
    mov al, 3h
    mov ah, 0
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

; set pixel (x,y) to color from rgb       
set_pixel:
    mov ax, 0a000h
    mov es, ax
    mov bx, SCREEN_WIDTH
    mov ax, word ptr ds:[y]
    mul bx 
    mov bx, word ptr ds:[x]
    add bx, ax
    push bx
    call convert_from_rgb
    pop bx
    mov byte ptr es:[bx], al
    ret

; convert rgb values to color from pallette (r,g,b will be detroyed)    
convert_from_rgb:
    mov ax, 0
    mov al, byte ptr ds:[r]
    mov bl, 64
    div bl
    mov byte ptr ds:[r], al
    
    mov ax, 0
    mov al, byte ptr ds:[g]
    mov bl, 64
    div bl
    mov byte ptr ds:[g], al
    
    mov ax, 0
    mov al, byte ptr ds:[b]
    mov bl, 64
    div bl
    mov byte ptr ds:[b], al
    
    mov ax, 0
    mov bx, 0
    mov bl, byte ptr ds:[r]
    shl bl, 4h
    add al, bl
    mov bl, byte ptr ds:[g]
    shl bl, 2h
    add al, bl
    add al, byte ptr ds:[b]
    
    mov bx,ax
    mov al, byte ptr ds:[color_pallette + bx]
    ret

; validate and change scale of the image
update_scale:
    cmp byte ptr ds:[scale], 1
    jnz no_mode_change
    mov byte ptr ds:[mode], al
    jmp inc_scale

; if current mode is different than previous ine than 
; decrease the scale in other case increase it     
no_mode_change:    
    cmp al, byte ptr ds:[mode]
    jnz dec_scale
inc_scale:
    cmp byte ptr ds:[scale], 3
    jz end_scale
    ; apply scale and check bounds 
    inc byte ptr ds:[scale]
    call check_bounds_x
    jge back_scale_inc
    call check_bounds_y
    jge back_scale_inc
    jmp end_scale
    ; revert scale if it doesn't match size
back_scale_inc:    
    dec byte ptr ds:[scale]
    jmp end_scale
dec_scale:
    ; apply scale and check bounds
    cmp byte ptr ds:[scale], 0
    jz end_scale
    dec byte ptr ds:[scale]
    call check_bounds_x
    jge back_scale_dec
    call check_bounds_y
    jge back_scale_dec
    jmp end_scale
    ; revert scale if it doesn't match size
back_scale_dec:    
    inc byte ptr ds:[scale]
end_scale:    
    ret

; zoom in or out based on mode and scale    
apply_zoom:
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
    ret                        
    
code1 ends

stack1 segment STACK
	dw 400 dup(?)   
ws1 dw ?	
stack1 ends

end start1