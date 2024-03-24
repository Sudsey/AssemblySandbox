INCLUDELIB legacy_stdio_definitions.lib

EXTERN printf:PROC

.data

	nnb_msg1	db	"%d bottles of beer on the wall,", 10, \
					"%d bottles of beer.", 10, \
					"Take one down, pass it around,", 10, 0
	nnb_msg2	db	"%d bottles of beer on the wall.", 10, 0
	nnb_msg3	db	"1 bottle of beer on the wall.", 10, \
					"1 bottle of beer on the wall,", 10, \
					"1 bottle of beer.", 10, \
					"Take one down, pass it around,", 10, \
					"No more bottles of beer on the wall.", 10, \
					"No more bottles of beer on the wall,", 10, \
					"no more bottles of beer.", 10, \
					"Go to the store and buy some more,", 10, \
					"99 bottles of beer on the wall...", 10, 0

.code

;	mov		[rsp+8], rcx
;.savereg rcx, 40+8
;	push	rbp
;.pushreg rbp
;	mov		rbp, rsp
;.setframe rbp, 0
;	sub		rsp, 40
;.allocstack 40

;	add		rsp, 40
;	mov		rsp, rbp
;	pop		rbp

nnbottles_main PROC FRAME
	mov		[rsp+8], rbx		; preamble
.savereg rbx, 40+8
	sub		rsp, 40
.allocstack 40
.endprolog
	mov		ebx, 99				; i := 99
nnb_main_loop:
	lea		rcx, nnb_msg1		; printf(nnb_msg1, i, i)
	mov		edx, ebx
	mov		r8d, ebx
	call	printf
	sub		ebx, 1				; i--
	cmp		ebx, 1				; if (i == 1): goto nnb_main_end
	je		nnb_main_end
	lea		rcx, nnb_msg2		; printf(nnb_mgs2, i)
	mov		edx, ebx
	call	printf
	jmp		nnb_main_loop		; goto nnb_main_loop
nnb_main_end:
	lea		rcx, nnb_msg3		; printf(nnb_msg3)
	call	printf
	xor		eax, eax			; return 0
	add		rsp, 40				; cleanup
	mov		rbx, [rsp+8]
	ret
nnbottles_main ENDP

END