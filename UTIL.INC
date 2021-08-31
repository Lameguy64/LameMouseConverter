; UTIL.INC - Utility/debugging functions
;
; Part of the LameMouseConverter project by John "Lameguy" Wilbert Villamor
; 2021 Meido-Tek KYS Hardware Division
;
; Protected under Mozilla Public License v2

; delayms - Delay in specified milliseconds
;
; This routine is tuned for 16MHz MCUs
;
; Arguments: r20:r19 - Number of ms to wait
;
delayms:
	PUSH	r16
    delayloopD:
	MOV	r16,r19
	OR	r16,r20
	AND	r16,r16
	BREQ	delayexit
    	CLR	r16
	SUBI	r19,1
	SBC	r20,r16
	LDI	r16,15
    delayloopB:				; wastes about 196608 cycles
	PUSH	r16
	CLR	r16
	DEC	r16
    delayloopA:				; this wastes about 768 cycles
    	DEC	r16
	BRNE	delayloopA
	POP	r16
	DEC	r16
	BRNE	delayloopB
	RJMP	delayloopD
    delayexit:
	POP	r16
	RET
	; delayms

; printhex8 - Print 8-bit value as hexadecimal text to USART
;
; Arguments:
;	r19	- Value to print
;
printhex8:
	PUSH	r16
	PUSH	r17
	PUSH	r18
	LDI	r18,2
    numloophex8:
    	MOV	r16,r18			; perform bit shift right when
	DEC	r16			; generating first digit
	MOV	r16,r19
	BREQ	noshift8
	LSR	r16
	LSR	r16
	LSR	r16
	LSR	r16
    noshift8:
    	ANDI	r16,0xF
	PUSH	r19
	LDI	r19,'0'			; for hex characters 0-9
	ADD	r19,r16
	CPI	r19,'9'+1
	BRLO	printaway8
	SUBI	r16,10			; for hex characters A-F
	LDI	r19,'A'
	ADD	r19,r16
    printaway8:
    	RCALL	USART_write
	POP	r19
    	DEC	r18
	BRNE	numloophex8
	POP	r18
	POP	r17
	POP	r16
	RET
	; printhex8
