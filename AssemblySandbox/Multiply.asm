INCLUDELIB legacy_stdio_definitions.lib

EXTERN fgets:PROC
EXTERN strtol:PROC
EXTERN printf:PROC

EXTERN _set_errno:PROC
EXTERN _get_errno:PROC
EXTERN __acrt_iob_func:PROC			; retrieves handle for stdin, stdout, stderr

INPUT_SIZE EQU 16

.data

	mult_msg1	db	"Input %d: ", 0
	mult_msg2	db	"Your result is: %lld", 10, 0

.data?

	input	db	INPUT_SIZE	dup (?)

.code

multiply_main PROC FRAME
	mov		[rsp+8], rbx			; preamble
.savereg rbx, 40+8
	mov		[rsp+16], rbp
.savereg rbx, 40+16
	sub		rsp, 40
.allocstack 40
.endprolog
	mov		ecx, 1					; rbx := get_input_number(1)
	call	get_input_number
	mov		rbx, rax
	lea		rcx, [rsp+40+24]		; if (errno != 0): goto mult_main_exit
	call	_get_errno
	mov		eax, [rsp+40+24]
	test	eax, eax
	jnz		mult_main_exit
	mov		ecx, 2					; rbp := get_input_number(2)
	call	get_input_number
	mov		rbp, rax
	lea		rcx, [rsp+40+24]		; if (errno != 0): goto mult_main_exit
	call	_get_errno
	mov		eax, [rsp+40+24]
	test	eax, eax
	jnz		mult_main_exit
	lea		rcx, mult_msg2			; printf(mult_msg2, rbx * rbp)
	mov		rdx, rbx
	imul	rdx, rbp
	call	printf
mult_main_exit:
	xor		eax, eax				; return 0
	add		rsp, 40					; cleanup
	mov		rbx, [rsp+8]
	mov		rbp, [rsp+16]
	ret
multiply_main ENDP

get_input_number PROC FRAME
	mov		[rsp+8], rbx			; preamble
.savereg rbx, 40+8
	sub		rsp, 40
.allocstack 40
.endprolog
	mov		rbx, rcx
	xor		ecx, ecx				; _set_errno(0)
	call	_set_errno
	lea		rcx, mult_msg1			; printf(mult_msg1, arg0)
	mov		rdx, rbx
	call	printf
	xor		ecx, ecx				; rax := fgets(input, INPUT_SIZE, stdin)
	call	__acrt_iob_func
	lea		rcx, input
	mov		edx, INPUT_SIZE
	mov		r8, rax
	call	fgets
	test	rax, rax				; if (rax == NULL): _set_errno(EIO); goto get_input_exit
	jnz		get_input_parse
	mov		ecx, 5
	call	_set_errno
	jmp		get_input_exit
get_input_parse:
	lea		rcx, input				; rax := strtol(input, endptr, 10)
	lea		rdx, [rsp+40+16]
	mov		r8d, 10
	call	strtol
	mov		rbx, [rsp+40+16]		; if (*endptr == input || **endptr != '\n'): _set_errno(EINVAL)
	lea		rcx, input
	cmp		rbx, rcx
	je		get_input_parse_error
	cmp		byte ptr [rbx], 10
	jne		get_input_parse_error
	jmp		get_input_exit
get_input_parse_error:
	mov		eax, 22
	call	_set_errno
get_input_exit:						; return rax
	add		rsp, 40					; cleanup
	mov		rbx, [rsp+8]
	ret
get_input_number ENDP

END