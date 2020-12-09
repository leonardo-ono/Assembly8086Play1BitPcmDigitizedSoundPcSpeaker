; Playing 1-bit PCM sound through the PC-Speaker
; Written by Leonardo Ono (ono.leo@gmail.com)
; Dec 9, 2020
; Target OS: DOS
; Executable extension: *.COM
; use: nasm 1bitpcm.asm -o 1bitpcm.com -f bin

	cpu 8086
	bits 16
	org 100h
	
start:
	; setup es to get the system
	; timer count correctly
	mov ax, 0
	mov es, ax

	; change timer 0 to 4KHz
	call start_fast_clock
	
	mov si, 0 ; sound index
	
next_sample:

	mov dl, [sound_data + si]
	
	mov cl, 7
	shr dl, cl ; convert to 1-bit sound
	
	cmp dl, 1
	jae on
	jmp off

on:
	call speaker_on
	jmp short continue

off:
	call speaker_off

continue:

	; wait 0.25ms
	call delay

	; exit if keypress
	mov ah, 1
	int 16h
	jnz exit
	
	inc si
	cmp si, [sound_size]
	jae restart_sound
	
	jmp next_sample
	
restart_sound:
	mov si, 0
	jmp next_sample
		
exit:

	; restore timer 0 to the original 18.2Hz
	mov bl, 0
	call change_timer_0

	; return to DOS
	mov ax, 4c00h
	int 21h
	
speaker_on:
	in al, 61h
	or al, 2
	out 61h, al
	ret
	
speaker_off:
	in al, 61h
	and al, 11111100b
	out 61h, al
	ret
	
; delay for 0.25ms
; for every timer 0 tick, the irq 0 (int 8)
; will update the system timer count at 
; memory location 0000:046ch	
delay:
	mov di, [es:046ch]
_wait:
	cmp di, [es:046ch]
	jz _wait
	ret
	
; bl = 0 -> restore original 18.2Hz timer 0
;      1 -> change timer 0 to 1193180Hz
change_timer_0:
	cli
	mov al, 16h
	out 43h, al
	mov al, bl
	out 40h, al
	sti
	ret
	
; count = 1193180 / sampling_rate
; sampling_rate = 4000 cycles per second
; count = 1193180 / 4000 = 298 (in decimal) = 12a (in hex) 
start_fast_clock:
	cli
	mov al, 36h
	out 43h, al
	mov al, 2ah ; low 2ah
	out 40h, al
	mov al, 1h ; high 1h
	out 40h, al
	sti
	ret


sound_size dw 44782 ; size in bytes
	
sound_data:
	incbin "digdug.wav" ; Unsigned 8-bit PCM 4KHz
	
	
	
	
	
	










