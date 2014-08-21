%DEFINE LINE_SIZE 1024
%DEFINE INITIAL_DATA_SEGMENT_SIZE 65536

section .bss

%MACRO PUSHRSP 1
	lea ebp, [ebp-4]
	mov [ebp], %1
%ENDMACRO

%MACRO POPRSP 1
	mov %1, [ebp]
	lea ebp, [ebp+4]
%ENDMACRO

%DEFINE F_HIDDEN 80h
%DEFINE F_IMMEDIATE 20h
%DEFINE F_COMPILE_ONLY 10h

%DEFINE LAST 0
%MACRO MCREATE 2-3 0
	align 4, db 0
	global %2
%2:
	dd LAST
%define LAST %2
	db %3
	db .name_end - .name
.name:
	db %1
.name_end:
	align 4, db 0
.link_back:
	dd %2
.code:
%ENDMACRO

%MACRO CODE 0
	dd .data
.data:
%ENDMACRO

%MACRO WORDDEF 0
	dd DOCOL.data
.data:
%ENDMACRO

%MACRO NEXT 0
	lodsd
	jmp [eax]
%ENDMACRO

%MACRO VARIABLE 2-3 0
MCREATE %1, %2
	dd DOVAR.data
.data:
.var:
	dd %3
%ENDMACRO

%MACRO CONSTANT 2-3 0
MCREATE %1, %2
	dd DOCON.data
.data:
.var:
	dd %3
%ENDMACRO



return_stack:
	resd 4096
return_stack_top:

section .text
global _start

_start:

	xor ebx, ebx
	mov eax, 45
	int 80h
	mov [LINE_BUFFER.data], eax
	add eax, 1024
	mov [HERE.var], eax
	add eax, INITIAL_DATA_SEGMENT_SIZE
	mov ebx, eax
	mov eax, 45
	int 80h
	
	mov ebp, return_stack_top
	mov esi, cold_start
NEXT

	align 4, db 0
cold_start:
	dd TEST.code

VARIABLE 'HERE', HERE
VARIABLE 'STATE', STATE
VARIABLE 'LATEST', LATEST, QUIT
VARIABLE 'S0', SZ
VARIABLE 'BASE', BASE, 0x0A

CONSTANT 'R0', RZ, return_stack_top
MCREATE 'DOCOL', DOCOL
	dd DOVAR.data
.data:
PUSHRSP esi
	add eax, 4
	mov esi, eax
NEXT

MCREATE 'DOVAR', DOVAR
	dd DOVAR.data
.data:
	add eax, 4
	push eax
NEXT

MCREATE 'DOCON', DOCON
	dd DOVAR.data
.data:
	add eax, 4
	mov ebx, [eax]
	push ebx
NEXT

CONSTANT 'F_HIDDEN', __F_HIDDEN, F_HIDDEN
CONSTANT 'F_IMMEDIATE', __F_IMMEDIATE, F_IMMEDIATE
CONSTANT 'F_COMPILE_ONLY', __F_COMPILE_ONLY, F_COMPILE_ONLY



MCREATE '!', STORE
CODE
	pop eax
	pop ebx
	mov [eax], ebx
NEXT

MCREATE '@', FETCH
CODE
	pop ebx
	mov eax, [ebx]
	push eax
NEXT

MCREATE 'C!', CSTORE
CODE
	pop eax
	pop ebx
	mov [eax], bl
NEXT

MCREATE 'C@', CFETCH
CODE
	pop ebx
	xor eax, eax
	mov al, [ebx]
	push eax
NEXT

MCREATE 'CELL+', CELLPLUS
WORDDEF
	dd LIT.code, 4
	dd ADD.code
	dd EXIT.code
	
MCREATE 'CELL-', CELLMINUS
WORDDEF
	dd LIT.code, 4
	dd ADD.code
	dd EXIT.code

MCREATE 'CELLS', CELLS
WORDDEF
	dd LIT.code, 4
	dd MUL.code
	dd EXIT.code

MCREATE 'CHAR+', CHARPLUS
WORDDEF
	dd ONEPLUS.code
	dd EXIT.code
	
MCREATE 'CHAR-', CHARMINUS
WORDDEF
	dd ONEMINUS.code
	dd EXIT.code

MCREATE 'CHARS', CHARS
WORDDEF
	dd EXIT.code

MCREATE '*', MUL
CODE
	pop eax
	pop ebx
	imul ebx
	push eax
NEXT

MCREATE '+', ADD
CODE
	pop eax
	add [esp], eax
NEXT

MCREATE '-', SUB
CODE
	pop eax
	sub [esp], eax
NEXT

MCREATE '/MOD', SLASHMOD
CODE
	pop ebx
	pop eax
	xor edx, edx
	idiv ebx
	push edx
	push eax
NEXT

MCREATE '1+', ONEPLUS
CODE
	inc dword [esp]
NEXT

MCREATE '1-', ONEMINUS
CODE
	dec dword [esp]
NEXT

MCREATE '=', EQUAL
CODE
	pop eax
	pop ebx
	cmp ebx, eax
	setne al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '<>', NEQUAL
CODE
	pop eax
	pop ebx
	cmp ebx, eax
	sete al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '<', LT
CODE
	pop eax
	pop ebx
	cmp ebx, eax
	setge al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '>', GT
CODE
	pop eax
	pop ebx
	cmp ebx, eax
	setle al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '<=', LE
CODE
	pop eax
	pop ebx
	cmp ebx, eax
	setg al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '>=', GE
CODE
	pop eax
	pop ebx
	cmp ebx, eax
	setl al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '0=', ZEQUAL
CODE
	pop eax
	test eax, eax
	setne al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '0<>', ZNEQUAL
CODE
	pop eax
	test eax, eax
	sete al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '0<', ZLT
CODE
	pop eax
	test eax, eax
	setge al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '0>', ZGT
CODE
	pop eax
	test eax, eax
	setle al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '0<=', ZLE
CODE
	pop eax
	test eax, eax
	setg al
	movzx eax, al
	dec eax
	push eax
NEXT

MCREATE '0>=', ZGE
CODE
	pop eax
	test eax, eax
	setl al
	movzx eax, al
	dec eax
	push eax
NEXT


MCREATE 'AND', AND
CODE
	pop eax
	and [esp], eax
NEXT

MCREATE 'OR', OR
CODE
	pop eax
	or [esp], eax
NEXT

MCREATE 'XOR', XOR
CODE
	pop eax
	xor [esp], eax
NEXT

MCREATE 'INVERT', INVERT
CODE
	not dword [esp]
NEXT


MCREATE 'DUP', DUP
CODE
	mov eax, [esp]
	push eax
NEXT

MCREATE '2DUP', TWODUP
CODE
	mov eax, [esp+4]
	mov ebx, [esp]
	push eax
	push ebx
NEXT

MCREATE 'OVER', OVER
CODE
	mov eax, [esp+4]
	push eax
NEXT

MCREATE '2OVER', TWOOVER
CODE
	mov eax, [esp+12]
	mov ebx, [esp+8]
	push eax
	push ebx
NEXT

MCREATE 'SWAP', SWAP
CODE
	pop eax
	pop ebx
	push eax
	push ebx
NEXT

MCREATE '2SWAP', TWOSWAP
CODE
	pop eax
	pop ebx
	pop ecx
	pop edx
	push ebx
	push eax
	push edx
	push ecx
NEXT

MCREATE 'DROP', DROP
CODE
	pop eax
NEXT

MCREATE '2DROP', TWODROP
CODE
	pop eax
	pop eax
NEXT

MCREATE 'ROT', ROT
CODE
	pop eax
	pop ebx
	pop ecx
	push ebx
	push eax
	push ecx
NEXT

MCREATE '-ROT', NROT
CODE
	pop eax
	pop ebx
	pop ecx
	push eax
	push ecx
	push ebx
NEXT

MCREATE 'DSP@', DSPFETCH
CODE
	mov eax, esp
	push eax
NEXT

MCREATE 'DSP!', DSPSTORE
CODE
	pop esp
NEXT

MCREATE 'RSP@', RSPFETCH
CODE
	push ebp
NEXT

MCREATE 'RSP!', RSPSTORE
CODE
	pop ebp
NEXT

MCREATE '>R', TOR
CODE
	pop eax
	PUSHRSP eax
NEXT

MCREATE 'R>', FROMR
CODE
	POPRSP eax
	push eax
NEXT

MCREATE 'RDROP', RDROP
CODE
	add ebp, 4
NEXT


MCREATE 'EMIT', EMIT
CODE
	pop eax
	mov ebx, 1
	mov [EMIT.scratch], al
	mov ecx, EMIT.scratch
	mov edx, 1
	mov eax, 4
	int 80h
NEXT
.scratch:
	db 0

MCREATE 'LIT', LIT
CODE
	lodsd
	push eax
NEXT

MCREATE "BRANCH", BRANCH
CODE
	add esi, [esi]
NEXT

MCREATE "0BRANCH", ZBRANCH
CODE
	pop eax
	test eax, eax
	jz .zero
	lodsd
NEXT
.zero:
	add esi, [esi]
NEXT

MCREATE 'SHUTDOWN', SHUTDOWN
CODE
	mov eax, 1
	mov ebx, 0
	int 80h
NEXT

MCREATE 'EXIT', EXIT
CODE
	POPRSP esi
NEXT


MCREATE 'KEY?', KEYQ
CODE
	mov eax, 168
	mov ebx, .poll_fd
	mov ecx, 1
	mov edx, 0
	int 80h
	cmp eax, 1
	setne al
	movzx eax, al
	push eax
NEXT
.poll_fd:
	dd 1
	dw 1
.poll_revents:
	dw 0

MCREATE 'CANONICAL', CANONICAL
CODE
	mov eax, 54
	mov ebx, 0
	mov ecx, 5401h
	mov edx, .termios
	int 80h
	
	or dword [.l_flag], 0x0A
	
	mov eax, 54
	mov ebx, 0
	mov ecx, 5402h
	mov edx, .termios
	int 80h
	
NEXT
.termios:
.i_flag:
	dd 0
.o_flag:
	dd 0
.c_flag:
	dd 0
.l_flag:
	dd 0
	db 0
	times 19 db 0

MCREATE 'UNCANONICAL', UNCANONICAL
CODE
	mov eax, 54
	mov ebx, 0
	mov ecx, 5401h
	mov edx, .termios
	int 80h
	
	and dword [.l_flag], dword ~(0x0A)
	
	mov eax, 54
	mov ebx, 0
	mov ecx, 5402h
	mov edx, .termios
	int 80h
	
NEXT
.termios:
.i_flag:
	dd 0
.o_flag:
	dd 0
.c_flag:
	dd 0
.l_flag:
	dd 0
	db 0
	times 19 db 0

MCREATE 'KEY', KEY
CODE
	mov eax, 3
	mov ebx, 0
	mov ecx, .buf
	mov edx, 1
	int 80h
	
	test eax, eax
	jle .exit
	mov al, [.buf]
	movzx eax, al
	push eax
NEXT
.exit:
	mov eax, 1
	mov ebx, 0
	int 80h
.buf:
	db 0
	
MCREATE '>CFA', TOCFA
CODE
	pop edi
	add edi, 5
	xor eax, eax
	mov al, [edi]
	add edi, eax
	add edi, 7
	and edi, ~3
	push edi
NEXT

MCREATE 'CFA>', FROMCFA
CODE
	pop edi
	sub edi, 4
	mov eax, [edi]
	push eax
NEXT

MCREATE '>DFA', TODFA
CODE
	pop edi
	add edi, 5
	xor eax, eax
	mov al, [edi]
	add edi, eax
	add edi, 11
	and edi, ~3
	push edi
NEXT

MCREATE 'DFA>', FROMDFA
CODE
	pop edi
	sub edi, 8
	mov eax, [edi]
	push eax
NEXT

MCREATE ',', COMMA
CODE
	pop eax
	mov edi, [HERE.var]
	stosd
	mov [HERE.var], edi
NEXT

MCREATE 'C,', CCOMMA
CODE
	pop eax
	mov edi, [HERE.var]
	stosb
	mov [HERE.var], edi
NEXT

MCREATE 'ALIGN', _ALIGN
CODE
	mov eax, [HERE.var]
	add eax, 3
	and eax, ~3
	mov [HERE.var], eax

MCREATE 'CREATE', CREATE
WORDDEF
	dd HERE.code
	dd LATEST.code
	dd FETCH.code
	dd _ALIGN.code
	dd COMMA.code
	dd DUP.code
	dd LATEST.code
	dd STORE.code
	dd LIT.code, 0
	dd CCOMMA.code
	dd _WORD.code
	dd COUNT.code
	dd DUP.code
	dd CCOMMA.code
.1:
	dd SWAP.code
	dd DUP.code
	dd CFETCH.code
	dd CCOMMA.code
	dd CHARPLUS.code
	dd SWAP.code
	dd ONEMINUS.code
	dd DUP.code
	dd ZBRANCH.code
	dd .1-$
	dd _ALIGN.code
	dd DOVAR.code
	dd COMMA.code
	dd EXIT.code
	
MCREATE 'WORD', _WORD
CODE
PUSHRSP esi
	mov ecx, [LINE_BUFFER_COUNT.data]
	mov eax, [SIN.data]
	sub ecx, eax
	mov ebx, [LINE_BUFFER.data]
	add ebx, eax
	mov edi, ebx
	mov al, ' '
	repe SCASB
	sub ecx, 1
	sub edi, 1
	mov ebx, edi
	repne SCASB
	sub ecx, 2
	sub edi, 1
	mov [SIN.data], ecx
	mov ecx, edi
	sub ecx, ebx
	mov [.buflen], ecx
	mov esi, ebx
	mov edi, .buf
	rep MOVSB
	
	push dword .buflen
POPRSP esi
NEXT
.buflen:
	dd 0
.buf:
	times 32 db 0

MCREATE '.', DOT
WORDDEF
	dd BASE.code
	dd FETCH.code
	dd SLASHMOD.code
	dd DUP.code
	dd ZBRANCH.code
	dd .1-$
	dd .code
	dd BRANCH.code
	dd .2-$
.1:
	dd DROP.code
.2:
	dd LIT.code, '0'
	dd ADD.code
	dd EMIT.code
	dd EXIT.code
	
MCREATE 'ACCEPT', ACCEPT
WORDDEF
	dd DROP.code
	dd DUP.code
.1:
	dd KEY.code
	dd DUP.code
	dd LIT.code, 127
	dd EQUAL.code
	dd ZBRANCH.code
	dd .2-$
	dd DROP.code
	dd LIT.code, 8
	dd EMIT.code
	dd LIT.code, 32
	dd EMIT.code
	dd LIT.code, 8
	dd EMIT.code
	dd CHARMINUS.code
	dd BRANCH.code
	dd .1-$
.2:
	dd DUP.code
	dd LIT.code, 10
	dd NEQUAL.code
	dd ZBRANCH.code
	dd .3-$
	dd DUP.code
	dd EMIT.code
	dd SWAP.code
	dd DUP.code
	dd ROT.code
	dd SWAP.code
	dd CSTORE.code
	dd CHARPLUS.code
	dd BRANCH.code
	dd .1-$
.3:
	dd DROP.code
	dd SWAP.code
	dd SUB.code
	dd EXIT.code
	
	
CONSTANT 'LINE_BUFFER', LINE_BUFFER, 0
VARIABLE 'LINE_BUFFER_COUNT', LINE_BUFFER_COUNT, 0
CONSTANT 'SOURCE-ID', SOURCE_ID, 0
VARIABLE '>IN', SIN, 0

MCREATE 'SOURCE', SOURCE
WORDDEF
	dd LINE_BUFFER.code
	dd LINE_BUFFER_COUNT.code
	dd FETCH.code
	dd EXIT.code
	
MCREATE 'COUNT', COUNT
WORDDEF
	dd DUP.code
	dd FETCH.code
	dd SWAP.code
	dd CELLPLUS.code
	dd SWAP.code
	dd EXIT.code
	
MCREATE 'TYPE', TYPE
CODE
	pop edx
	pop ecx
	mov ebx, 1
	mov eax, 4
	int 80h
NEXT

MCREATE 'INTERPRET', INTERPRET
CODE
	dd LIT.code, 0
	dd LIT.code, SOURCE_ID.data
	dd STORE.code
	dd LINE_BUFFER.code
	dd LIT.code, 1024
	dd ACCEPT.code
	dd LINE_BUFFER_COUNT.code
	dd STORE.code
	
	
NEXT

MCREATE 'TEST', TEST
WORDDEF
	dd UNCANONICAL.code

	dd LIT.code, 10
	dd BASE.code
	dd STORE.code
	
	dd LINE_BUFFER.code
	dd LIT.code, 4096
	dd ACCEPT.code
	dd LINE_BUFFER_COUNT.code
	dd STORE.code
	
	dd LIT.code, 10, EMIT.code
	dd SIN.code
	dd FETCH.code
	dd DOT.code
	
	dd _WORD.code
	dd DUP.code
	dd COUNT.code
	dd LIT.code, 10, EMIT.code
	dd TYPE.code
	
	dd LIT.code, 10, EMIT.code
	dd SIN.code
	dd FETCH.code
	dd DOT.code
	
	dd _WORD.code
	dd COUNT.code
	dd LIT.code, 10, EMIT.code
	dd TYPE.code
	
	dd CANONICAL.code
	dd SHUTDOWN.code

MCREATE 'QUIT', QUIT
WORDDEF
	dd RZ.code
	dd RSPSTORE.code
	dd UNCANONICAL.code
;    dd INTERPRET.code
	dd BRANCH, -8
