[ORG 7C00h]
[BITS 16]

main:
	mov ax,0x0000
	mov ds,ax

	mov ah,02h 
	mov al,1
	mov ch,0x0
	mov cl,0x01
	mov dh,00
	mov dl,81h	;aca estabamos poniendo 80h pero eso es para el primer disco duro o sea -hda (creo), no importa, lo q es seguro es 
			;q esto rompia todo 
	mov bx,08E0h   ;cargo la direccion del buffer
	push bx
	int 0x13
	cmp ah,0
	jne err
	pop bx
	add bx,1C2h	;me muevo a la direcc supuestamente donde se encuentra el byte q me determina el tipo de particion, ojo
			;capaz q cambia si la maquina es little o big endian,xq de hecho esta deberia ser 1C3h
   mov dx,0
   

loop:
	mov al,[ES:BX]
   cmp dx,4
   je salir

   
   mov si, Particion	; Load the string into position for the procedure.
 	call PutStr	; Call/start the procedure
	  	
	push ax
	push dx

	call printhex	;imprimo ese byte en binario, pero al reves como lo habiamos hecho en el dcc
			;es lo de menos, era para saber si lo que estabamos leyendo estaba bien, despues esta funcion no la vamos a usar
	pop dx
   pop ax

	call nombreParticion

   add bx,16
	add dx,1   
	jmp loop
			;creense un disco, haganle una particion y le tienen que dar un tipo a la particion
			;compilan este archivo como lo veniamos haciendo y despues correr qemu: qemu-system-i386 -hdb disco.img bootl.bin

salir:
   jmp $


nombreParticion:	
	cmp al,05h
	jne .win	
	mov si, Extendida	; Load the string into position for the procedure.
	jmp .imp   
	
 .win
	 cmp al,0Bh
	 jne .lin	
	 mov si, Windows	; Load the string into position for the procedure.
	 jmp .imp 

 .lin
	 cmp al,83h
	 jne .cero	
	 mov si, Linux	; Load the string into position for the procedure.
    jmp .imp 

 .cero
	 cmp al,00h
	 jne .otra	
	 mov si, Nula	; Load the string into position for the procedure.
    jmp .imp 

 .otra
	 mov si, Otra	; Load the string into position for the procedure.

 .imp
	 call PutStr	; Call/start the procedure

err:
	ret

printhex:
   mov cl,16
	div cl
	push ax
	call printd
	pop ax
	mov al,ah
	push ax
	call printd
	pop ax
	ret

printd:
	cmp al,10
	jge mayor
	add al,48
	jmp imprime

mayor:
	add al,55
	jmp imprime

imprime:
   push bx
	mov dl,0
	mov bx,0x1
	mov ah,0xe	
	int 0x10
   pop bx
	ret

printbyte:
	push bx
	mov dl,0
	mov bx,0x1
	mov ah,0xe
	

next:
	mov cl,al
	and al,1	
	cmp al,0
	je cero
	shr cl,1
	mov al,'1'
	int 0x10
	mov al,cl
	jmp retorno 

cero:
	shr cl,1
	mov al,'0'
	int 0x10
	mov al,cl
	
retorno:
	inc dl
	cmp dl,16
	jne next
	pop bx
	ret	

; Procedures
PutStr:		; Procedure label/start
 ; Set up the registers for the interrupt call
 push bx
 push dx
 push ax	

 mov ah,0x0E	; The function to display a chacter (teletype)
 mov bh,0x00	; Page number
 mov bl,0x07	; Normal text attribute

.nextchar	; Internal label (needed to loop round for the next character)
 lodsb		; I think of this as LOaD String Block 
		; (Not sure if thats the real meaning though)
		; Loads [SI] into AL and increases SI by one
 ; Check for end of string '0' 
 or al,al	; Sets the zero flag if al = 0 
		; (OR outputs 0's where there is a zero bit in the register)
 jz .return	; If the zero flag has been set go to the end of the procedure.
		; Zero flag gets set when an instruction returns 0 as the answer.
 int 0x10	; Run the BIOS video interrupt 
 jmp .nextchar	; Loop back round tothe top
.return		; Label at the end to jump to when complete

 pop ax
 pop dx
 pop bx
 

 ret		; Return to main program

; Data

Particion db 'Particion : ',13,10,0
Extendida db 'Extendida.',13,10,0
Windows db 'Windows.',13,10,0
Linux db 'Linux.',13,10,0
Otra db 'Otro tipo.',13,10,0
Nula db 'Nula.',13,10,0

times 510-($-$$) db 0
dw 0xAA55
