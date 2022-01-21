; USART.INC - USART serial routines
;
; Part of the LameMouseConverter project by John "Lameguy" Wilbert Villamor
; 2021 Meido-Tek KYS Hardware Division
;
; Protected under Mozilla Public License v2

; USART_init - Initialize the USART for UART serial communications
;
; Arguments:
;   None
;
; Return value:
;   None
;
; Destroys: r16, r19
;
USART_init:
	LDI	r16,(1<<RXEN0)|(1<<TXEN0)|(1<<RXCIE0)   ; Enable transceiver
	STS	UCSR0B,r16		; and receiver with receive IRQs
	LDI	r16,0b00000110		; Configure for 8-bit characters
	STS	UCSR0C,r16		; and 1 stop bit
	RET
	; USART_init

; USART_setbaud - Set USART baud rate
;
; This function can be called anytime to change the baudrate if desired.
;
; Arguments:
;   r19         Baud rate number (see USART_baudtbl)
;
; Returns:
;   None
;
; Destroys: r19, Z
;
USART_setbaud:
	PUSH	r16
	PUSH	r17
	LDI	ZL,LOW(USART_baudtbl<<1)   ; Get address of baud rate table
	LDI	ZH,HIGH(USART_baudtbl<<1)
	LSL	r19			; Bit-shift left to multiply by 2
	ADD	ZL,r19			; Add speed number to address
	CLR	r19
	ADC	ZH,r19
	LPM	r16,Z+			; Load the baudrate value
	LPM	r17,Z
	STS	UBRR0H,r17		; Set the values to USART
	STS	UBRR0L,r16
	POP	r17
	POP	r16
	RET
	; USART_setbaud
	
; USART_setbits - Sets the number of bits of a serial frame
;
; Arguments:
;	r19	0: Transmit with 7 bits, 1: Transmit with 8 bits
;
; Destroys: r19
;
USART_setbits:
	CPI	r19,1
	BREQ	USART_set8
	LDI	r19,0b00000100		; Configure for 7-bit characters
	STS	UCSR0C,r19
	RET
    USART_set8:
	LDI	r19,0b00000110		; Configure for 8-bit characters
	STS	UCSR0C,r19
	RET
	; USART_setbits
	
; USART_setparity
;
USART_setparity:
	PUSH	r16
	LDS	r16,UCSR0C
	ANDI	r16,0b11001111
	BST	r19,0
	BLD	r16,4
	BST	r19,1
	BLD	r16,5
	STS	UCSR0C,r16
	POP	r16
	RET
	; USART_setparity
	
; USART_write - Write a byte to USART
;
; This function will not transmit a byte until CTS pin is clear.
;
; Arguments:
;	r19	Byte value to write.
;
; Returns:
;   None
;
; Destroys: r19
;
USART_write:
	PUSH	r19
    USART_waitwrite:
	LDS	r19,UCSR0A		; Wait for transmit buffer
	SBRS	r19,UDRE0		; until it becomes ready
	RJMP	USART_waitwrite
	POP	r19
	STS	UDR0,r19		; Write byte value into USART
	RET
	; USART_write

; USART_read - Read a byte from USART
;
; This function blocks until a byte has received.
;
; Return value:
;   None
;
USART_read:
	LDS     r16, UCSR0A
	SBRC    r16, UDRE0
	RJMP    USART_read
	LDS     r16, UDR0
	RET
	; USART_read
	
; = Write a string from Z pointer register
;
; Normally used to send strings stored in the program (flash) memory section.
;
; Arguments:
;   Z - Pointer to zero terminated string to write.
;
; Returns:
;   None
;
; Destroys: r16, r19, Z
;
USART_writestrZ:
	PUSH	ZL
	PUSH	ZH
	PUSH	r19
    USART_writeloopZ:
	LPM     r19, Z+			; Get byte
	AND     r19, r19		; Check if zero terminator
	BREQ    USART_writeendZ
	RCALL   USART_write		; Send the byte
	RJMP    USART_writeloopZ
    USART_writeendZ:
    	POP	r19
	POP	ZH
	POP	ZL
	RET
	; USART_writestrZ
	
; = Serial USART baud rate table
;
; The following values are for 16MHz MCUs
;
USART_baudtbl:
	.DW 832	    ; 1200
	.DW 416     ; 2400
	.DW 207     ; 4800
	.DW 103     ; 9600
	; USART_baudtbl
