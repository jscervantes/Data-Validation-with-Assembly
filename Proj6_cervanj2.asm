TITLE Designing Low-Level I/O Procedures     (Proj6_cervanj2.asm)

; Author: Jose S. Cervantes
; Last Modified: 03/05/2024
; OSU email address: cervanj2@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 03/17/2024
; Description: This program implements two new (to me) concepts--macros and string primitives--to 
;				validate, process, and present user input "the hard way" (convert ascii to decimal 
;				and back to ascii).

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Takes input from user as string and stores string in specified memory location.
;
; Preconditions: do not use edx, ecx, or eax as arguments
;
; Receives:
; prompt = array address
; input_buffer = array address
; length = array length
;
; returns: bytes_read = length of input read
; [input_buffer] = read string
; ---------------------------------------------------------------------------------
mGetString		MACRO	prompt, input_buffer, length, bytes_read
	push	edx
	push	ecx
	push	eax

	mov		edx, prompt
	call	WriteString
	mov		edx, input_buffer
	mov		ecx, length
	call	ReadString
	mov		[bytes_read], eax

	pop		eax
	pop		ecx
	pop		edx
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints provided string to output.
;
; Preconditions: do not use edx as argument
;
; Receives:
; string = array address
;
; returns: 
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	string
	push	edx
	mov		edx, 	string
	call	WriteString
	pop		edx
ENDM

MAX_LENGTH		= 12
BUFFER_SIZE		= 50
ASCII_CONSTANT	= 48
HI				= 2147483647
LO				= 2147483648
TEST_LENGTH		= 10

.data
header			byte	"		Project 6: Macros and String Primitives			By Jose S. Cervantes",0
intro1			byte	"To test out this program, I will need your help.",0
intro2			byte	"Enter 10 signed decimal integers below. Each of",0
intro3			byte	"these signed decimal integers must fit in a 32 ",0
intro4			byte	"bit register, so please keep these within the",0
intro5			byte	"range of -2147483647 < n < 2147483647.",0
intro6			byte	"Following this, I will show you...",0
intro7			byte	"	...what numbers you inserted...",0
intro8			byte	"		...their sum...",0
intro9			byte	"			...and their average value.",0
farewell		byte	"Have a good life...",0

prompt1			byte	"Enter a signed number: ",0
invalid_prompt	byte	"That does not work! Try another value please.",0
input_str		byte	BUFFER_SIZE dup(?)
string_len		dword	?
input_num		sdword	?
is_valid		byte	0
is_neg			byte	0

print_str		byte	MAX_LENGTH dup(?)
reverse_str		byte	MAX_LENGTH dup(?)

test_array		sdword	TEST_LENGTH dup(?)

.code
main PROC
	; Display title and intro
	mDisplayString	offset header
	call			CrLf
	call			CrLf
	mDisplayString	offset	intro1
	call			CrLf
	mDisplayString	offset	intro2
	call			CrLf
	mDisplayString	offset	intro3
	call			CrLf
	mDisplayString	offset	intro4
	call			CrLf
	mDisplayString	offset	intro5
	call			CrLf
	call			CrLf
	mDisplayString	offset	intro6
	call			CrLf
	mDisplayString	offset	intro7
	call			CrLf
	mDisplayString	offset	intro8
	call			CrLf
	mDisplayString	offset	intro9
	call			CrLf
	call			CrLf

	;------ TEST PROGRAM ------
	; prompt user for signed integer 10 times
	cld
	mov				ecx, TEST_LENGTH
	mov				edi, offset test_array
_testLoop:
	push			offset	invalid_prompt
	push			offset	is_valid
	push			offset	is_neg
	push			offset	input_num
	push			offset	string_len
	push			offset	input_str
	push			offset	prompt1
	call			ReadVal 

	; store numeric values in an array
	mov				eax, input_num
	STOSD
	loop			_testLoop

	; display the integers
	cld
	mov				ecx, TEST_LENGTH
	mov				edi, offset test_array
_printLoop:
	lodsd
	push			offset reverse_str
	push			offset print_str
	push			eax
	call			WriteVal
	loop			_printLoop


	; display their sum


	; display their truncated average


	;--- END OF TEST PROGRAM ---

	; Say bye
	call			CrLf
	call			CrLf
	mDisplayString	offset	farewell
	call			CrLf

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Reads input string from user, converts it to its numeric value, and stores the
; numeric value in provided value address
;
; Preconditions: the string's numeric value fits in an SDWORD register
;
; Postconditions:
;
; Receives:
; [ebp+32] = address of invalid_prompt array 
; [ebp+28] = address of is_valid flag (byte value)
; [ebp+24] = address of negative flag (byte value)
; [ebp+20] = address of numeric value variable
; [ebp+16] = address of string length variable
; [ebp+12] = address of array to store input
; [ebp+8] = address of prompt array
;
; returns: 
; ---------------------------------------------------------------------------------

ReadVal		PROC
	push		ebp
	mov			ebp, esp
	pushad

_restartLoop:
	; reset is_valid flag
	mov			ebx, [ebp+28]
	mov			eax, 0
	mov			[ebx], eax

	; get user input using mGetString
	mov			ebx, [ebp+16]
	mGetString	[ebp+8], [ebp+12], BUFFER_SIZE, ebx

	; check if anything was entered
	mov			eax, [ebx]
	cmp			eax, 0
	je			_abortLoop

	; Convert ascii to numeric value representation (SDWORD) using string primitives
	CLD
	mov			edi, 0
	mov			eax, 0
	mov			ecx, [ebx]
	mov			esi, [ebp+12]

	; validate user input 
_valStart:
	lodsb
	; check for + or -
	cmp			al, 43
	je			_isFirst
	cmp			al, 45
	je			_isNeg

	; make sure element is within 0-9
	cmp			al, 48
	jl			_abortLoop
	cmp			al, 57
	jg			_abortLoop
	jmp			_addElement

_isNeg:
	; set isNeg flag
	mov			ebx, [ebp+24]
	mov			eax, 1
	mov			[ebx], eax
_isFirst:
	; if + or -, make sure it is the first element of string
	mov			ebx, [ebp+16]
	cmp			ecx, [ebx]	
	jne			_abortLoop
	; if + or -, make sure it is not the only character entered
	mov			eax, 1
	cmp			[ebx], eax
	je			_abortLoop
	jmp			_continue

_addElement:
	; element is GOOD. add to output.
	sub			al, byte ptr ASCII_CONSTANT
	push		eax
	mov			eax, edi
	mov			ebx, 10
	mul			ebx
	mov			edi, eax	
	pop			eax
	jo			_sizeVal
	add			edi, dword ptr eax
	jo			_sizeVal
	jmp			_continue

_sizeVal:
	; ensure that -2147483648 <= n <= 2147483647
	mov			eax, LO
	cmp			edi, eax
	jg			_abortLoop
	je			_checkSign
	jmp			_continue

_checkSign:
	mov			eax, [ebp+24]
	mov			ebx, [eax]
	cmp			ebx, 0
	je			_abortLoop

_continue:
	loop		_valStart
	; check if value is negative; if so, turn negative
	mov			ebx, [ebp+24]
	mov			eax, 0
	cmp			[ebx], eax
	je			_storeVal
	neg			edi

_storeVal:
	mov			eax, [ebp+20]
	mov			[eax], edi
	jmp			_endRead

_abortLoop:
	mDisplayString [ebp+32]
	call		CrLf
	; set is_valid flag
	mov			ebx, [ebp+28]
	mov			eax, 1
	mov			[ebx], eax
	jmp			_restartLoop

_endRead:
	popad
	pop			ebp
	ret			20
ReadVal		ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a numerical value to string of ASCII digits and prints to output
;
; Preconditions: 
;
; Postconditions: 
;
; Receives:
; [ebp+8] = numeric value
; [ebp+12] = address of initial string read
; [ebp+16] = address of final return string
;
; returns: 
; --------------------------------------------------------------------------------
WriteVal	PROC
	local		is_neg_local:byte
	pushad
	; convert numeric SDWORD value into a string of ascii digits
	mov			ecx, MAX_LENGTH
	mov			edi, [ebp+12]
	mov			eax, [ebp+8]
	; check if value is negative. if so, convert to positive. add
	; hyphen as final element in string
	mov			is_neg_local, 0
	mov			ebx, 0
	add			ebx, eax
	jns			_startWrite
	; value is negative, set is_neg_local flag and two's complement value
	inc			is_neg_local
	neg			eax
	cld
_startWrite:
	mov			edx, 0
	mov			ebx, 10
	idiv		ebx			; remainder is now in edx, which is the last digit in our number
	push		eax
	mov			eax, edx
	add			eax, ASCII_CONSTANT
	stosb
	pop			eax
	cmp			eax, 0
	je			_reverseWrite
	loop		_startWrite

_reverseWrite:
	; reverse initial string
	mov			eax, MAX_LENGTH
	sub			eax, ecx
	mov			ecx, eax
	inc			ecx
	mov			edi, [ebp+16]
	mov			esi, [ebp+12]
	add			esi, ecx
	dec			esi
	;check is_neg_local
	cmp			is_neg_local, 1
	jne			_reverseLoop
	cld
	mov			al, 45
	stosb
_reverseLoop:
	std
	lodsb
	cld
	stosb
	loop		_reverseLoop

	; use mDisplayString to print ascii representation on screen
_printString:
	mDisplayString [ebp+16]

	popad
	ret			12
WriteVal	ENDP

END main
