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

%DEFINE _F_HIDDEN 80h
%DEFINE _F_IMMEDIATE 20h
%DEFINE _F_COMPILE_ONLY 10h

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
	mov [FORTH_WORDLIST.var], eax
	add eax, INITIAL_DATA_SEGMENT_SIZE
	mov ebx, eax
	mov eax, 45
	int 80h
	
	mov eax, esp
	mov [DZ.data], eax
	mov ebp, return_stack_top
	mov esi, cold_start
NEXT

	align 4, db 0
cold_start:
	dd QUIT.code

VARIABLE 'STATE', STATE, 0
VARIABLE 'S0', SZ
VARIABLE 'BASE', BASE, 0x0A

CONSTANT 'R0', RZ, return_stack_top
CONSTANT 'D0', DZ
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

CONSTANT 'F_HIDDEN', F_HIDDEN, _F_HIDDEN
CONSTANT 'F_IMMEDIATE', F_IMMEDIATE, _F_IMMEDIATE
CONSTANT 'F_COMPILE_ONLY', F_COMPILE_ONLY, _F_COMPILE_ONLY



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

MCREATE '?DUP', QDUP
CODE
	mov eax, [esp]
	test eax, eax
	jz .AFTER
	push eax
.AFTER:
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
	add edi, 8
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
WORDDEF
	dd PRINTSTACK.code
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd FETCH.code
	dd DUP.code
	dd NROT.code
	dd STORE.code
	dd CELLPLUS.code
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd STORE.code
	dd EXIT.code

MCREATE 'C,', CCOMMA
WORDDEF
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd FETCH.code
	dd DUP.code
	dd NROT.code
	dd CSTORE.code
	dd CHARPLUS.code
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd STORE.code
	dd EXIT.code

MCREATE 'ALIGN', _ALIGN
WORDDEF
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd FETCH.code
	dd LIT.code, 3
	dd ADD.code
	dd LIT.code, ~3
	dd AND.code
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd STORE.code
	dd EXIT.code

MCREATE 'HEAD,', HEADCOMMA
WORDDEF
	dd _ALIGN.code
	dd HERE.code
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd TOLATEST.code
	dd FETCH.code
	dd COMMA.code
	
	dd DUP.code
	
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd TOLATEST.code
	
	dd STORE.code
	dd LIT.code, 0
	dd CCOMMA.code
	dd PARSE_WORD.code
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
	dd ZEQUAL.code
	dd ZBRANCH.code
	dd .1-$
	dd TWODROP.code
	dd _ALIGN.code
	dd COMMA.code
	dd EXIT.code

MCREATE 'CREATE', CREATE
WORDDEF
	dd HEADCOMMA.code
	dd DOVAR.code
	dd COMMA.code
	dd EXIT.code
	
MCREATE 'PARSE-WORD', PARSE_WORD
CODE
	mov ecx, [LINE_BUFFER_COUNT.data]
	mov eax, [SIN.data]
	add ecx, 1
	sub ecx, eax
	mov ebx, [LINE_BUFFER.data]
	add ebx, eax
	mov edi, ebx
	mov al, ' '
	repe SCASB
	add ecx, 1
	sub edi, 1
	push edi
	mov ebx, edi
	repne SCASB
;	add ecx, 1
	sub edi, 1
	mov eax, [LINE_BUFFER_COUNT.data]
	sub eax, ecx
	mov [SIN.data], eax
	mov ecx, edi
	sub ecx, ebx
	push ecx	
NEXT

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
	dd TWODUP.code
	dd LT.code
	dd ZBRANCH.code
	dd .1-$
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

MCREATE ']', RIGHT_BRACKET
WORDDEF
	dd LIT.code, 1
	dd STATE.code
	dd STORE.code
	dd EXIT.code
	
MCREATE '[', LEFT_BRACKET, _F_IMMEDIATE
WORDDEF
	dd LIT.code, 0
	dd STATE.code
	dd STORE.code
	dd EXIT.code
	
MCREATE 'LITERAL', LITERAL, _F_IMMEDIATE
WORDDEF
	dd LIT.code, LIT.code
	dd COMMA.code
	dd COMMA.code
	dd EXIT.code

MCREATE "[']", CTICK, _F_IMMEDIATE
WORDDEF
	dd LIT.code, LIT.code
	dd COMMA.code
	dd EXIT.code
	
MCREATE "'", TICK
WORDDEF
	dd PARSE_WORD.code
	dd FIND.code
	dd TWOSWAP.code
	dd TWODROP.code
	dd PRINTSTACK.code
	dd ZBRANCH.code
	dd .EXIT-$
	dd EXIT.code
.EXIT:
	dd DROP.code
	dd LIT.code, 0
	dd EXIT.code
	
MCREATE ':', COLON
WORDDEF
	dd HEADCOMMA.code
	dd COLON_NONAME.code
	dd DROP.code
	dd EXIT.code

MCREATE ':NONAME', COLON_NONAME
WORDDEF
	dd HERE.code
	dd DOCOL.code
	dd COMMA.code
	dd RIGHT_BRACKET.code
	dd EXIT.code
	
MCREATE ';', SEMICOLON, _F_IMMEDIATE
WORDDEF
	dd LEFT_BRACKET.code
	dd LIT.code
	dd EXIT.code
	dd COMMA.code
	dd EXIT.code

MCREATE 'DIGIT?', DIGIT
WORDDEF
	dd LIT.code, '0'
	dd SUB.code
	dd LIT.code, 9
	dd OVER.code
	dd LT.code
	dd ZBRANCH.code
	dd .LTA-$
	dd LIT.code, 7
	dd SUB.code
.LTA:
	dd DUP.code
	dd BASE.code
	dd FETCH.code
	dd LT.code
	dd EXIT.code
	
	
MCREATE '>NUMBER', TONUMBER
WORDDEF
.START:
	dd DUP.code
	dd ZBRANCH.code
	dd .END-$
	dd OVER.code
	dd CFETCH.code
	dd DIGIT.code
	dd ZBRANCH.code
	dd .END-$
	dd TOR.code
	dd ROT.code
	dd BASE.code
	dd FETCH.code
	dd MUL.code
	dd FROMR.code
	dd ADD.code
	dd NROT.code
	dd ONEMINUS.code
	dd SWAP.code
	dd ONEPLUS.code
	dd SWAP.code
	dd BRANCH.code
	dd .START-$
.END:
	dd EXIT.code

MCREATE 'INTERPRET', INTERPRET
WORDDEF
	dd LIT.code, ' ', LIT.code, '>', EMIT.code, EMIT.code
	dd LIT.code, 0
	dd LIT.code, SOURCE_ID.data
	dd STORE.code
	dd LINE_BUFFER.code
	dd LIT.code, 1024
	dd ACCEPT.code
	dd LINE_BUFFER_COUNT.code
	dd STORE.code
	dd LIT.code, 10, EMIT.code
	dd LIT.code, 0
	dd SIN.code
	dd STORE.code
.START:
	dd PARSE_WORD.code
	dd DUP.code
	dd ZBRANCH.code
	dd .END-$
	dd FIND.code
	
	dd QDUP.code
	dd ZBRANCH.code
	dd .NUMBER-$

	dd LIT.code, -1
	
	dd EQUAL.code
	
	dd ZBRANCH.code
	dd .IMMEDIATE-$
	dd STATE.code
	dd FETCH.code
	dd ZBRANCH.code
	dd .IMMEDIATE-$
	
	dd NROT.code
	dd TWODROP.code
	
	dd COMMA.code
	dd BRANCH.code
	dd .START-$
.IMMEDIATE:
	dd NROT.code
	dd TWODROP.code
	
	dd EXECUTE.code
		
	dd BRANCH.code
	dd .START-$
.NUMBER:
	dd LIT.code, 0
	dd NROT.code
	dd TONUMBER.code
	dd ZEQUAL.code
	dd ZBRANCH.code
	dd .ERROR-$
	dd DROP.code
	dd STATE.code
	dd FETCH.code
	dd ZBRANCH.code
	dd .START-$
	dd LIT.code
	dd LIT.code
	dd COMMA.code
	dd COMMA.code
	
	dd BRANCH.code
	dd .START-$
.END:
	dd LIT.code, 10, EMIT.code
	dd TWODROP.code
	dd EXIT.code
.ERROR:
	dd EXIT.code
	
VARIABLE 'ACTIVE-WORDLIST', ACTIVE_WORDLIST, FORTH_WORDLIST.data
VARIABLE 'COMPILE-WORDLIST', COMPILE_WORDLIST, FORTH_WORDLIST.data

VARIABLE 'FORTH-WORDLIST', FORTH_WORDLIST
.LATEST:
	dd QUIT
.NEXTWORDLIST:
	dd 0
	
MCREATE 'FIND', FIND
WORDDEF
	dd TWODUP.code
	dd ACTIVE_WORDLIST.code
	dd FETCH.code
.START:
	dd DUP.code
	dd ZBRANCH.code
	dd .NOTFOUND-$	
	dd DUP.code
	dd TOR.code
	dd SEARCH_WORDLIST.code
	dd QDUP.code
	dd ZEQUAL.code
	dd ZBRANCH.code
	dd .FOUND-$
	dd TWODUP.code
	dd FROMR.code
	dd LIT.code, 2
	dd CELLS.code
	dd ADD.code
	dd FETCH.code
	dd BRANCH.code
	dd .START-$
.NOTFOUND:
	dd DROP.code
	dd TWODROP.code
	dd LIT.code, 0
	dd EXIT.code
.FOUND:
	dd FROMR.code
	dd DROP.code
	dd EXIT.code

MCREATE 'HIDDEN', HIDDEN
WORDDEF
	dd FROMCFA.code
	dd CELLPLUS.code
	dd DUP.code
	dd CFETCH.code
	dd F_HIDDEN.code
	dd XOR.code
	dd SWAP.code
	dd CSTORE.code
	dd EXIT.code
	
MCREATE 'IMMEDIATE', IMMEDIATE, _F_IMMEDIATE
WORDDEF
	dd LATEST.code
	dd FETCH.code
	dd CELLPLUS.code
	dd DUP.code
	dd CFETCH.code
	dd F_IMMEDIATE.code
	dd XOR.code
	dd SWAP.code
	dd CSTORE.code
	dd EXIT.code
	
MCREATE 'LATEST', LATEST
WORDDEF
	dd ACTIVE_WORDLIST.code
	dd FETCH.code
	dd CELLPLUS.code
	dd EXIT.code
	
MCREATE 'HERE', HERE
WORDDEF
	dd COMPILE_WORDLIST.code
	dd FETCH.code
	dd FETCH.code
	dd EXIT.code
	
MCREATE '>LATEST', TOLATEST
WORDDEF
	dd CELLPLUS.code
	dd EXIT.code

MCREATE 'SEARCH-WORDLIST', SEARCH_WORDLIST
WORDDEF
	dd TOLATEST.code 	;(c-addr, u, latest)
.START:
	dd FETCH.code 		;(c-addr, u, latest)
	dd DUP.code 		;(c-addr, u, latest, latest)
	dd ZBRANCH.code 	;(c-addr, u, latest)
	dd .NOTFOUND-$
	dd DUP.code 		;(c-addr, u, latest, latest)
	dd TOR.code 		;(c-addr, u, latest)				;(R: latest)
	dd CELLPLUS.code	;(c-addr, u, latest+flag)				;(R: latest)
	dd DUP.code			;(c-addr, u, latest+flag, latest+flag)				;(R: latest)
	dd CFETCH.code		;(c-addr, u, latest+flag, flag)				;(R: latest)
	dd F_HIDDEN.code	;(c-addr, u, latest+flag, flag, F_HIDDEN)				;(R: latest)
	dd AND.code			;(c-addr, u, latest+flag, flag&F_HIDDEN)				;(R: latest)
	dd ZEQUAL.code		;(c-addr, u, latest+flag, ZE)				;(R: latest)
	dd ZBRANCH.code		;(c-addr, u, latest+flag)				;(R: latest)
	dd .HIDDEN-$
	dd CHARPLUS.code	;(c-addr, u, latest+len)				;(R: latest)
	dd DUP.code			;(c-addr, u, latest+len, latest+len)				;(R: latest)
	dd CFETCH.code		;(c-addr, u, latest+len, len)				;(R: latest)
	dd SWAP.code		;(c-addr, u, len, latest+len)				;(R: latest)
	dd CHARPLUS.code	;(c-addr, u, len, c-addr)				;(R: latest)
	dd SWAP.code		;(c-addr, u, c-addr, len)				;(R: latest)
	dd TWOOVER.code		;(c-addr, u, c-addr, len, c-addr, u)				;(R: latest)
	dd ROT.code			;(c-addr, u, c-addr, c-addr, u, len)				;(R: latest)
	dd DUP.code			;(c-addr, u, c-addr, c-addr, u, len, len)				;(R: latest)
	dd ROT.code			;(c-addr, u, c-addr, c-addr, len, len, u)				;(R: latest)
	dd EQUAL.code		;(c-addr, u, c-addr, c-addr, len, e)				;(R: latest)
	dd ZBRANCH.code		;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd .DIFCOUNT-$
	dd ONEMINUS.code
.COMPARE:					;(c-addr, u, c-addr, c-addr, len, len)				;(R: latest)
	dd DUP.code				;(c-addr, u, c-addr, c-addr, len, len)				;(R: latest)
	dd TWOOVER.code			;(c-addr, u, c-addr, c-addr, len, len, c-addr, c-addr)				;(R: latest)
	dd CFETCH.code			;(c-addr, u, c-addr, c-addr, len, len, c-addr, c)				;(R: latest)
	dd SWAP.code			;(c-addr, u, c-addr, c-addr, len, len, c, c-addr)				;(R: latest)
	dd CFETCH.code			;(c-addr, u, c-addr, c-addr, len, len, c, c)				;(R: latest)
	dd EQUAL.code			;(c-addr, u, c-addr, c-addr, len, len, e)				;(R: latest)
	dd ZBRANCH.code
	dd .DIFCONTENT-$		;(c-addr, u, c-addr, c-addr, len, len)				;(R: latest)
	dd ZBRANCH.code			;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd .FOUND-$				
	dd ONEMINUS.code		;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd TOR.code				;(c-addr, u, c-addr, c-addr)				;(R: latest, len)
	dd CHARPLUS.code		;(c-addr, u, c-addr, c-addr)				;(R: latest, len)
	dd SWAP.code			;(c-addr, u, c-addr, c-addr)				;(R: latest, len)
	dd CHARPLUS.code		;(c-addr, u, c-addr, c-addr)				;(R: latest, len)
	dd SWAP.code			;(c-addr, u, c-addr, c-addr)				;(R: latest, len)
	dd FROMR.code			;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd BRANCH.code			;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd .COMPARE-$
.HIDDEN:				;(c-addr, u, latest+flag)				;(R: latest)
	dd DROP.code
	dd FROMR.code
	dd BRANCH.code
	dd .START-$
.DIFCONTENT:			;(c-addr, u, c-addr, c-addr, len, len)				;(R: latest)
	dd DROP.code		;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
.DIFCOUNT:				;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd DROP.code		;(c-addr, u, c-addr, c-addr)				;(R: latest)
	dd TWODROP.code		;(c-addr, u)				;(R: latest)
	dd FROMR.code		;(c-addr, u, latest)
	dd BRANCH.code		;(c-addr, u, latest)
	dd .START-$
.NOTFOUND:				;(c-addr, u, latest)
	dd DROP.code		;(c-addr, u)
	dd TWODROP.code		;()
	dd LIT.code, 0		;(0)
	dd EXIT.code
.FOUND:					;(c-addr, u, c-addr, c-addr, len)				;(R: latest)
	dd TWODROP.code		;(c-addr, u, c-addr)				;(R: latest)
	dd TWODROP.code		;(c-addr)				;(R: latest)
	dd DROP.code		;()				;(R: latest)
	dd FROMR.code		;(latest)
	dd DUP.code			;(latest, latest)
	dd CELLPLUS.code	;(latest, latest+f)
	dd CFETCH.code		;(latest, flag)
	dd F_IMMEDIATE.code	;(latest, flag, immed)
	dd AND.code			;(latest, is_immed)
	dd ZBRANCH.code		;(latest)
	dd .NOTIMMEDIATE-$
	dd LIT.code, 1		;(latest, 1)
	dd BRANCH.code
	dd .IMMEDIATE-$
.NOTIMMEDIATE:
	dd LIT.code, -1		;(latest, -1)
.IMMEDIATE:
	dd SWAP.code		;(1| -1, latest)
	dd TOCFA.code		;(1| -1, xt)
	dd SWAP.code		;(xt, 1| -1)
	dd EXIT.code
	
	
	
MCREATE 'EXECUTE', EXECUTE
CODE
	pop eax
	jmp [eax]
	
MCREATE '.S', PRINTSTACK
WORDDEF
	dd DSPFETCH.code
	dd DUP.code
	dd DZ.code
	dd LT.code
	dd ZBRANCH.code
	dd .END-$
.START:
	dd DUP.code
	dd FETCH.code
	dd DOT.code
	dd LIT.code, 32, EMIT.code
	dd CELLPLUS.code
	dd DUP.code
	dd DZ.code
	dd GE.code
	dd ZBRANCH.code
	dd .START-$
.END:
	dd DROP.code
	dd LIT.code, 10, EMIT.code
	dd EXIT.code
	
MCREATE 'QUIT', QUIT
WORDDEF
	dd RZ.code
	dd RSPSTORE.code
	dd UNCANONICAL.code
.LOOP:
    dd INTERPRET.code
	dd BRANCH.code
	dd .LOOP-$
