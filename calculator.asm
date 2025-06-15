SYS_EXIT equ 1
SYS_READ equ 3
SYS_WRITE equ 4
STDIN equ 0
STDOUT equ 1

section .data
	text1 db  'Enter the first number: ', 0xA
	len1 equ $ - text1
	text2 db  'Enter the second number: ', 0xA
	len2 equ $ - text2
	operation db 'Enter operation + - / *', 0xA
	op_len equ $ - operation
	text3 db  'Result: ', 0xA
	len3 equ $ - text3
	text4 db 'Invalid operation', 0xA
	len4 equ $ - text4
	div_error_text db 'Error: Floating-point exception.', 0xA
	len5 equ $ - div_error_text
	E_for_exit db  '(E for exit)', 0xA
	exit_len equ $ - E_for_exit

section .bss
	num1 resb 16
	num2 resb 16
	operand resb 2
	res resb 32

section .text				;START
	global _start

_start:
	mov eax, SYS_WRITE 		; E for exit text
	mov ebx, STDOUT
	mov ecx, E_for_exit
	mov edx, exit_len
	int 0x80

	mov eax, SYS_WRITE 		; enter first number text
	mov ebx, STDOUT
	mov ecx, text1
	mov edx, len1
	int 0x80
	
	mov eax, SYS_READ 		; first input
	mov ebx, STDIN
	mov ecx, num1
	mov edx, 17
	int 0x80
	
	cmp byte [ecx], 'E' 	; if the input is E jump to exit
	je exit
	
	mov eax, SYS_WRITE 		; enter second number text
	mov ebx, STDOUT
	mov ecx, text2
	mov edx, len2
	int 0x80
	
	mov eax, SYS_READ 		; second input
	mov ebx, STDIN
	mov ecx, num2
	mov edx, 17
	int 0x80

	mov eax, SYS_WRITE 		; "enter operation" text
	mov ebx, STDOUT
	mov ecx, operation
	mov edx, op_len
	int 0x80
	
	mov eax, SYS_READ 		; operand input
	mov ebx, STDIN
	mov ecx, operand
	mov edx, 17
	int 0x80
	
	mov esi, num1 			; point to the input string
	call ascii_to_int 
	mov [num1], eax 		;write the converted int number in eax to memory address num1
	mov esi, num2
	call ascii_to_int
	mov [num2], eax
	
	mov al, [operand]

	cmp al, '+'
	je addition

	cmp al, '-'
	je subtraction

	cmp al, '*'
	je multiplication

	cmp al, '/'
	je division
	
	jmp invalid_operation

addition:
	mov eax, [num1] ; put the value in the mem. ad. num1 to eax
	add eax, [num2]
	call int_to_ascii
	jmp print_result
	
subtraction:
	mov eax, [num1]
	sub eax, [num2]
	call int_to_ascii
	jmp print_result
	
multiplication:
	mov eax, [num1]
	mov ebx, [num2]
	imul ebx
	call int_to_ascii
	jmp print_result
	
division:
	xor edx, edx 			; clear edx for division
	mov eax, [num1]
	mov ebx, [num2]
	
	cmp ebx, 0				; check if divider is 0
	je div_error
	
	div ebx
	call int_to_ascii
	jmp print_result
	
invalid_operation:
	mov eax, SYS_WRITE 		; "invalid operation" text
	mov ebx, STDOUT
	mov ecx, text4
	mov edx, len4
	int 0x80
	
div_error:					; Division by 0 error
	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, div_error_text
	mov edx, len5
	int 0x80
	
print_result:				; PRINT RESULT
	mov eax, SYS_WRITE
	mov ebx, STDOUT
	mov ecx, res
	mov edx, 32
	int 0x80
		
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	xor esi, esi
	xor edi, edi
	
	jmp _start

ascii_to_int:
	xor eax, eax 			; clear eax so it can hold the result
.loop:
	mov bl, [esi] 			; get the next char
	cmp bl, 0xA 			; if its newline "\n" end
	je .done
	
	sub bl, "0" 			; to convert ascii to num. 0 is 48 in ASCII
	mov ecx, eax 			; copy eax value
	
							;multiply eax by 10 to "make place" for next digit
	shl eax, 3 				; shift eax left by 3 bits. (x8) eax = eax * 8
	add eax, ecx
	add eax, ecx
	
	add eax, ebx 			; add (next) digit
	
	inc esi 				;move to next char
	
	jmp .loop
	
.done:
	ret
							; eax now contains the full integer
	
int_to_ascii:
	mov ebx, 10
	mov edi, res 			; edi points to start of the result buffer / mem address named res 
	add edi, 31 			; move to end of the buffer (to write backwards)
	mov byte [edi], 0 		; null terminator 
.loop:
	xor edx, edx 			; clear remainder for division
	mov ecx, 10
	div ecx 				; eax ÷ ecx → eax = quotient, edx = remainder
	
	dec edi 				; move buffer pointer one back
	add dl, '0' 			; int --> ascii
	mov [edi], dl 			; put the ascii result in buffer
	
	test eax, eax 			; check if 0
	jnz .loop				; if not loop
	
	ret
	
exit:
	mov eax, SYS_EXIT
	xor ebx, ebx
	int 0x80
