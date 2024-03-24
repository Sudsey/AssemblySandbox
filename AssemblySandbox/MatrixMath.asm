INCLUDELIB legacy_stdio_definitions.lib

EXTERN printf:PROC

.data

ALIGN 16
	mat1		dd	4.5, 3.8, 0.2, 1.0, 3.6, 7.6, 9.9, 6.6, 9.7, 1.3, 6.0, 6.4, 3.8, 6.4, 3.7, 2.3
ALIGN 16
	mat2		dd	9.4, 1.3, 6.2, 3.8, 8.3, 0.9, 7.9, 1.2, 6.1, 2.3, 4.0, 0.8, 9.7, 6.9, 0.5, 2.1

	mat_msg1	db	"Matrix 1", 10, 0
	mat_msg2	db	"Matrix 2", 10, 0
	mat_msg3	db	"Transposed matrix 1: ", 10, 0
	mat_msg4	db	"Multiplied matrix 1, 2: ", 10, 0
	mat_msg5	db	"[ %6.4g %6.4g %6.4g %6.4g ]", 10, 0
	mat_msg6	db	10, 0

.data?

ALIGN 16
	matt	dd	16	dup	(?)
ALIGN 16
	matm	dd	16	dup	(?)

.code

matrixmath_main PROC FRAME
	sub		rsp, 40										; preamble
.allocstack 40
.endprolog
	lea		rcx, mat_msg1								; printf(mat_msg1)
	call	printf
	lea		rcx, mat1									; mat_print(mat1)
	call	mat_print
	lea		rcx, mat_msg2								; printf(mat_msg2)
	call	printf
	lea		rcx, mat2									; mat_print(mat2)
	call	mat_print
	lea		rcx, mat1									; mat_transpose(mat1, output: matt)
	lea		rdx, matt
	call	mat_transpose
	lea		rcx, mat_msg3								; printf(mat_mgs3)
	call	printf
	lea		rcx, matt									; mat_print(matt)
	call	mat_print
	lea		rcx, mat1									; mat_multiply(mat1, mat2, output: matm)
	lea		rdx, mat2
	lea		r8, matm
	call	mat_multiply
	lea		rcx, mat_msg4								; printf(mat_mgs4)
	call	printf
	lea		rcx, matm									; mat_print(matm)
	call	mat_print
	xor		eax, eax									; return 0
	add		rsp, 40										; cleanup
	ret
matrixmath_main ENDP

mat_print PROC FRAME
	mov			[rsp+8], rbx							; preamble
.savereg rbx, 40+8
	mov			[rsp+16], rbp
.savereg rbx, 40+8
	sub			rsp, 40
.allocstack 40
.endprolog
	mov			rbx, rcx
	xor			ebp, ebp								; i := 0
mat_print_loop:
	vpxor		xmm4, xmm4, xmm4						; printf(mat_mgs5, arg0[i], arg0[i+1], arg0[i+2], arg0[i+3])
	vcvtss2sd	xmm0, xmm4, dword ptr [rbx+rbp*4]		; first converting elements to double precision
	vcvtss2sd	xmm1, xmm4, dword ptr [rbx+rbp*4+4]
	vcvtss2sd	xmm2, xmm4, dword ptr [rbx+rbp*4+4*2]
	vcvtss2sd	xmm3, xmm4, dword ptr [rbx+rbp*4+4*3]
	lea			rcx, mat_msg5
	vmovq		rdx, xmm0
	vmovq		r8, xmm1
	vmovq		r9, xmm2
	vmovq		qword ptr [rsp+32], xmm3
	call		printf
	add			ebp, 4									; i += 4
	cmp			ebp, 16									; if (i != 16): goto mat_print_loop
	jne			mat_print_loop
	lea			rcx, mat_msg6							; printf("\n")
	call		printf
	add			rsp, 40									; cleanup
	mov			rbx, [rsp+8]
	mov			rbp, [rsp+16]
	ret
mat_print ENDP

mat_transpose PROC FRAME
.endprolog
	vmovaps	xmm0, [rcx]
	vmovaps	xmm1, [rcx+4*4]
	vmovaps	xmm2, [rcx+4*4*2]
	vmovaps	xmm3, [rcx+4*4*3]
	vshufps	xmm4, xmm0, xmm1, 01000100b					; transpose algorithm
	vshufps	xmm5, xmm0, xmm1, 11101110b					; two-step collect pairs of eventual same-row elements
	vshufps	xmm6, xmm2, xmm3, 01000100b					; then redistribute into transposed matrix
	vshufps	xmm7, xmm2, xmm3, 11101110b
	vshufps	xmm0, xmm4, xmm6, 10001000b
	vshufps	xmm1, xmm4, xmm6, 11011101b
	vshufps	xmm2, xmm5, xmm7, 10001000b
	vshufps	xmm3, xmm5, xmm7, 11011101b
	vmovaps	[rdx], xmm0
	vmovaps	[rdx+4*4], xmm1
	vmovaps	[rdx+4*4*2], xmm2
	vmovaps	[rdx+4*4*3], xmm3
	ret
mat_transpose ENDP

mat_multiply PROC FRAME
.endprolog
	xor				r9d, r9d							; i := 0
mat_mul_row:
	xor				r10d, r10d							; j := 0
	vpxor			xmm0, xmm0, xmm0					; xmm0 := 0
mat_mul_col:
	vbroadcastss	xmm2, dword ptr [rcx+r9*4]			; broadcast element i into xmm2
	vmovaps			xmm3, [rdx+r10*4]					; multiply against row starting at j
	vmulps			xmm1, xmm2, xmm3				
	vaddps			xmm0, xmm0, xmm1					; aggregate into partially complete row
	add				r9d, 1								; i += 1
	add				r10d, 4								; j += 4
	test			r9d, 4-1							; if (!(4 | n)): goto mat_mul_col
	jnz				mat_mul_col
	vmovaps			[r8+r9*4-16], xmm0					; one row finished. store
	cmp				r9d, 16								; if (r9d != 16): goto mat_mul_row
	jne				mat_mul_row
	ret
mat_multiply ENDP

END