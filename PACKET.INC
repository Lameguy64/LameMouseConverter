; PACKET.INC - Routines for generating mouse packets for various protocols
;
; Part of the LameMouseConverter project by John "Lameguy" Wilbert Villamor
; 2021 Meido-Tek KYS Hardware Division
;
; Protected under Mozilla Public License v2

; Cap a 16-bit signed register pair to a signed 8-bit value
;
; CAPTO8[dest,lo:high]
;
.MACRO CAPTO8
	.MESSAGE "This CAPTO8 macro does nothing for there are no parameters"
.ENDMACRO

.MACRO CAPTO8_8_16
	MOV	@0,@1			; Cap within -128 to 127
	SBRS	@2,7			; Check sign bit
	RJMP	nonegcap_%
	PUSH	r16
	PUSH	r17
	MOV	r16,@1			; Peform negative cap
	MOV	r17,@2
	NEG	r16			; Turn negative values to positive
	COM	r17
	CPI	r17,0			; Test HI byte
	BRMI	negdone_%
	BRNE	donegcap_%
	CPI	r16,0x80		; Test LO byte
	BRLO	negdone_%
    donegcap_%:
	LDI	@0,0x80
    negdone_%:
    	POP	r17
	POP	r16
	RJMP	capdone_%	
    nonegcap_%:
	CPI	r23,0
	BRMI	capdone_%
	BRNE	docap_%
	CPI	@1,0x7F
	BRLO	capdone_%
    docap_%:
	LDI	@0,0x7F
    capdone_%:
.ENDMACRO

; Perform subtraction of a 16-bit register pair by a signed 8-bit register
;
.MACRO SUB16
	.MESSAGE "This SUB16 macro does nothing for there are no parameters"
.ENDMACRO

.MACRO SUB16_16_8
	SBRS	@2,7			; Test sign bit
	RJMP	ispos_%
	NEG	@2
	ADD	@0,@2
	CLR	@2
	ADC	@1,@2
    ispos_%:
	SUB	@0,@2
	SBCI	@1,0
.ENDMACRO

; sendpacketMM - Transmit a SummaMouse MM Series mouse packet
;
; Reminder: MM packets must be sent at 8 data bits, 1 stop, odd parity
;
sendpacketMM:
	CLI
	CAPTO8	[r20,r22:r23]		; Cap mouse movements to 8-bit signed
	CAPTO8	[r21,r24:r25]
	CLR	r22			; Clear coordinates once latched
	CLR	r23			; (does not have the 'jello' effect)
	CLR	r24
	CLR	r25
	SEI
	CLR	r16			; Setup button bits
	BST	r19,0
	BLD	r16,2
	BST	r19,2
	BLD	r16,1
	BST	r19,1
	BLD	r16,0
	BST	r20,7			; Transfer sign bits
	BLD	r16,4
	BST	r21,7
	BLD	r16,3
	LDI	r17,0b10011000		; Invert bits
	EOR	r16,r17
	SBRC	r20,7			; Perform ABS on movement coords
	NEG	r20
	SBRC	r21,7
	NEG	r21
	MOV	r0,r16			; Transfer results and transmit
	MOV	r1,r20
	MOV	r2,r21
	LDI	r18,3
	RCALL	xmitpacket
	RET
	; sendpacketMM
	
; sendpacketTBP - Transmits a Three Byte Packed mouse packet
;
sendpacketTBP:
	CLI
	CAPTO8	[r20,r22:r23]		; Cap mouse movements to 8-bit signed
	CAPTO8	[r21,r24:r25]
	CLR	r22			; Clear coordinates once latched
	CLR	r23			; (does not have the 'jello' effect)
	CLR	r24
	CLR	r25
	SEI
	CLR	r16
	BST	r19,0
	BLD	r16,2
	BST	r19,2
	BLD	r16,1
	BST	r19,1
	BLD	r16,0
	MOV	r0,r16
	MOV	r1,r20			; Transfer mouse movements
	MOV	r2,r21
	LDI	r18,3			; Transmit the packet
	RCALL	xmitpacket
	RET
	; sendpacketTBP

; sendpacketMSYS - Transmits a Mouse Systems mouse packet
;
; Make sure the USART is set to transmit in 8-bit frames.
;
; Arguments:
;	r19	Mouse state
;	r22:r23	Accumulated X movement (16-bit signed two's complement)
;	r24:r25	Accumulated Y movement (16-bit signed two's complement)
;
sendpacketMSYS:
	CLI
	CAPTO8	[r20,r22:r23]		; Cap mouse movements to 8-bit signed
	CAPTO8	[r21,r24:r25]
	CLR	r22			; Clear coordinates once latched
	CLR	r23			; (does not have the 'jello' effect)
	CLR	r24
	CLR	r25
	SEI
	NEG	r21
	CLR	r16			; Construct the first half of packet
	BST	r19,0
	BLD	r16,2
	BST	r19,2
	BLD	r16,1
	BST	r19,1
	BLD	r16,0
	LDI	r17,0x7			; Invert button states
	EOR	r16,r17
	SBR	r16,0x80		; Set start of packet bit
	MOV	r0,r16
	MOV	r1,r20			; Transfer mouse movements
	MOV	r2,r21
	LDI	r18,3			; Transmit the first half of packet
	RCALL	xmitpacket
	CLI				; Transmit second half
	CAPTO8	[r20,r22:r23]
	CAPTO8	[r21,r24:r25]
	CLR	r22
	CLR	r23
	CLR	r24
	CLR	r25
	SEI
	NEG	r21
	MOV	r0,r20
	MOV	r1,r21
	LDI	r18,2
	RCALL	xmitpacket
	RET
	; sendpacketMSYS

; sendpacketMS - Transmits a Microsoft mouse packet w/ 3-button capability
;
; Make sure the USART is set to transmit in 7-bit frames.
;
; Arguments:
;	r19	Mouse state
;	r22:r23	Accumulated X movement (16-bit signed two's complement)
;	r24:r25	Accumulated Y movement (16-bit signed two's complement)
;
sendpacketMS:
	CLI
	CAPTO8	[r20,r22:r23]		; Cap mouse movements to 8-bit signed
	CAPTO8	[r21,r24:r25]
	CLR	r22			; Clear coordinates once latched
	CLR	r23			; (does not have the 'jello' effect)
	CLR	r24
	CLR	r25
	SEI
	CLR	r17
	BST	r19,2			; Get middle button bit
	BLD	r17,1			; Store to bit 1
	LDS	r18,mousemode		; Get last middle state
	MOV	r16,r18
	ANDI	r16,0x2
	CP	r16,r17			; Compare bits
	BREQ	nomid
	BLD	r18,1			; Store last middle button state
	STS	mousemode,r18
	LDI	r16,0x40		; Prepare double report packet
	BST	r19,0			; Left and right buttons
	BLD	r16,5
	BST	r19,1
	BLD	r16,4
	MOV	r0,r16
	CLR	r1			; No movement
	CLR	r2
   	LDI	r18,3			; Transmit duplicate click packet to
	RCALL	xmitpacket		; signal middle button
	AND	r20,r20			; Continue sending a normal packet if
	BRNE	nomid			; there is mouse movement pending
	AND	r21,r21
	BRNE	nomid
	RJMP	skippkt
    nomid:
	CLR	r16			; Begin creating the mouse packet
	BST	r19,0			; Left and right buttons
	BLD	r16,5
	BST	r19,1
	BLD	r16,4
	BST	r20,6			; X bits 6-7
	BLD	r16,0
	BST	r20,7
	BLD	r16,1
	BST	r21,6			; Y bits 6-7
	BLD	r16,2
	BST	r21,7
	BLD	r16,3
	SBR	r16,0x40		; Start bit
	MOV	r0,r16
	MOV	r16,r20			; X bits 0-5
	ANDI	r16,0x3F
	MOV	r1,r16
	MOV	r16,r21			; Y bits 0-5
	ANDI	r16,0x3F
	MOV	r2,r16
	LDI	r18,3			; Transmit the packet
	RCALL	xmitpacket
	;CLI
	;SUB16	[r22:r23,r20]		; Subtract mouse movements by the
	;SUB16	[r24:r25,r21]		; capped amount (not good, results in
	;SEI				; the jello effect)
    skippkt:
	RET
	; sendpacketMS
	
xmitpacket:
	PUSH	r19
    	CLR	XH			; Transmit the mouse packet
	CLR	XL
    sendloop:
    	LD	r19,X+
	RCALL	USART_write
    	DEC	r18
	BRNE	sendloop
	POP	r19
	RET
	; xmitpacket

