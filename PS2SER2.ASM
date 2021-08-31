; PS2SER2.ASM - AVR firmware for the LameMouseConverter (V0.10B)
; 2021 John "Lameguy" Wilbert Villamor of Meido-Tek KYS Hardware Division
;
; Assembler: AVRA (1.4.2)
;
; Controller: ATmega328P @ 16MHz (or Arduino UNO R3 @ 16MHz)
;
; Todo:
; * Add Watchdog Timer in case the converter enters a deadlock state.
; * Add Logitech protocol.
;
.NOLIST
.INCLUDE "m328Pdef.inc" 
.LIST

; Mouse mode definitions (derived from the Logimouse C7)
;
.EQU MODE_MSYS	= 0			; Mouse Systems
.EQU MODE_TBP	= 1			; Three byte packed mode (C7 native?)
.EQU MODE_HEX	= 2			; Hexadecimal mode (unsupported)
.EQU MODE_PADR	= 3			; Bit Pad One Relative (unsupported)
.EQU MODE_RES	= 4			; Reserved
.EQU MODE_MM	= 5			; MM series (unsupported)
.EQU MODE_PADA	= 6			; Bit Pad One Absolute (unsupported)   
.EQU MODE_MS	= 7			; Microsoft mouse

; Revision number to report on format and revision byte
;
.EQU REPORT_REV	= 1

; Port and pin assignments for PS/2 interface
;
.EQU PS2_PORT	= PORTD
.EQU PS2_DIR	= DDRD
.EQU PS2_IN	= PIND
.EQU PS2_CLK	= PD2			; Must always be pin 2 of PORTD
.EQU PS2_DAT	= PD4

; Port and pin assignments for RS-232 RTS input
;
.EQU RTS_PORT	= PORTD
.EQU RTS_DIR	= DDRD
.EQU RTS_IN	= PIND
.EQU RTS_PIN	= PD7

; Port and pin assignment for status LED output (usually L13)
;
.EQU L13_PORT	= PORTB
.EQU L13_DIR	= DDRB
.EQU L13_PIN	= PB5

;
; Macro definitions section
;

; LDZ - Load pointer to Z macro
;
; Arguments:
;	LDZ[label_name]
;
.MACRO LDZ
	.MESSAGE "This LDZ macro does nothing, for there are no parameters"
.ENDMACRO

.MACRO LDZ_i
	LDI     ZL,LOW(@0<<1)
	LDI     ZH,HIGH(@0<<1)
.ENDMACRO

; Clock control macros
;
.MACRO CLK_LOW				; Drag CLK pin low
	IN	r16,PS2_PORT		; Turn off the pull-up
	CBR	r16,(1<<PS2_CLK)
	OUT	PS2_PORT,r16
	IN	r16,PS2_DIR		; Change direction to output
	SBR	r16,(1<<DDD2)
	OUT	PS2_DIR,r16
.ENDMACRO

.MACRO CLK_HIGH				; Leave CLK pin floating high
	IN	r16,PS2_DIR		; Change direction back to input
	CBR	r16,(1<<DDD2)
	OUT	PS2_DIR,r16
	IN	r16,PS2_PORT
	SBR	r16,(1<<PS2_CLK)
	OUT	PS2_PORT,r16
.ENDMACRO

; Data transmission control macros
;
.MACRO DAT_LOW				; Drag DAT pin low
	IN	r16,PS2_PORT		; Turn off internal pull-up
	CBR	r16,(1<<PS2_DAT)
	OUT	PS2_PORT,r16
	IN	r16,PS2_DIR		; Change direction to output
	SBR	r16,(1<<PS2_DAT)
	OUT	PS2_DIR,r16
.ENDMACRO

.MACRO DAT_HIGH				; Leave DAT pin floating high
	IN	r16,PS2_DIR		; Change direction back to input
	CBR	r16,(1<<PS2_DAT)
	OUT	PS2_DIR,r16
	IN	r16,PS2_PORT		; Turn on internal pull-up
	SBR	r16,(1<<PS2_DAT)
	OUT	PS2_PORT,r16
.ENDMACRO

; Delay macros (tuned for 16MHz)
;
.MACRO delay300us			; Delay ~300us
	LDI	r25,0x04
	LDI	r24,0xB0
    delay_%:
	SBIW	r24,1
	BRNE	delay_%
.ENDMACRO

.MACRO delay10us			; Delay ~10us
	LDI	r24,0xA0
    delay10_%:
	NOP
    	SUBI	r24,1
	BRNE	delay10_%
.ENDMACRO

;
; Start of code segment
;
.CSEG

;
; Interrupt vectors area
;
.ORG 0x0000				; Reset vector
	JMP	reset
.ORG 0x0002				; Interrupt 0 request
	JMP	ps2_int
.ORG 0x0024				; USART receive
	JMP     USART_recvfunc
;
; Begin of program code
;	
.ORG 0x0034

;
; Include files
;
.INCLUDE "USART.INC"
.INCLUDE "UTIL.INC"
.INCLUDE "PACKET.INC"
.INCLUDE "PS2MOUSE.INC"

; Reset routine
;
reset:
	CLR     r1			; Clear SREG
	OUT     SREG,r1
	LDI     r28,LOW(RAMEND)		; Initialize stack pointer
	LDI     r29,HIGH(RAMEND)
	OUT     SPL,r28
	OUT     SPH,r29
	IN	r16,PS2_DIR		; Set CLK and DAT pins as input
	CBR	r16,(1<<PS2_CLK)|(1<<PS2_DAT)
	OUT	PS2_DIR,r16
	IN	r16,PS2_PORT		; Enable pull-up on CLK and DAT pins
	SBR	r16,(1<<PS2_CLK)|(1<<PS2_DAT)
	OUT	PS2_PORT,r16
	CLR	r16
	SBR	r16,(1<<ISC01)		; Enable IRQ on pin 2 to trigger on
	STS	EICRA,r16		; falling edge of signal
	CLR	r16
	SBR	r16,(1<<INT0)		; Enable interrupt
	OUT	EIMSK,r16
	CLR	r16			; Not required, but clear the flag
	SBR	r16,(1<<INTF0)		; bit just in case
	OUT	EIFR,r16
	IN	r16,RTS_DIR		; Configure RTS input
	CBR	r16,(1<<RTS_PIN)
	OUT	RTS_DIR,r16
	IN	r16,RTS_PORT		; Enable pull-up
	SBR	r16,(1<<RTS_PIN)
	OUT	RTS_PORT,r16
	IN	r16,L13_DIR		; Configure status LED as output
	SBR	r16,(1<<L13_PIN)
	OUT	L13_DIR,r16
	RCALL	USART_init		; Initialize USART
	LDI	r19,0			; Set initial baud rate (1200)
	RCALL	USART_setbaud
	RCALL	ps2_flushbuff		; Reset recv buffer
	CLR	r16
	STS	ps2_clkhead,r16
	STS	ps2_clktail,r16
	STS	ps2_clkcount,r16
	STS	ps2_lastclk,r16
	STS	mousemode,r16
	STS	setrateval,r16
	CLR	r20			; Wait 100ms to let things settle
	LDI	r19,100
	RCALL	delayms
	CLR	r17			; Clear IRQ flag just in case
	SBR	r17,(1<<INTF0)
	OUT	EIFR,r17
	SEI
	RJMP	main
	; reset
	
; Main routine
;
main:
	RCALL	ps2_init		; Initialize mouse
	IN	r16,L13_PORT		; Turn on status LED
	SBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	CLR	r20			; Blink L13
	LDI	r19,100
	RCALL	delayms
	IN	r16,L13_PORT		; Turn off status LED
	CBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	WDR
	RCALL	ps2_enable		; Enable mouse (starts streaming)
	RCALL	SetMSYSmode		; Set Mouse Systems as initial mode
    idleloop:
    	LDS	r16,mousemode		; Skip RTS cycle check if forced to
	ANDI	r16,0x80		; Mouse Systems mode
	BRNE	skip_rts
	LDS	r18,mousemode		; Load mouse mode value
	MOV	r16,r18
	ANDI	r16,4
	IN	r17,RTS_IN		; Read RTS pin state
	BST	r17,RTS_PIN
	BLD	r17,2
	BLD	r18,2			; Copy bit to mouse mode as well to
	STS	mousemode,r18		; keep track of last state
	ANDI	r17,4
	CP	r16,r17			; Only do RTS sequence when last
	BREQ	skip_rts		; state was off
	BRMI	skip_rts
	RCALL	rts_cycle		; Proceed to RTS cycle + MS mode
    skip_rts:
	LDS	r16,setrateval		; Check if mouse rate needs updating
	AND	r16,r16
	BRNE	dochangerate
    	LDS	r16,ps2_clkcount	; Check for any click events
	AND	r16,r16
	BRNE	hasevent
	MOV	r16,r22			; Check for mouse movements
	OR	r16,r23
	BRNE	hasevent
	MOV	r16,r24
	OR	r16,r25
	BRNE	hasevent
	RJMP	idleloop
    hasevent:
	LDS	r16,ps2_clkcount	; Check for any buffered click events
	AND	r16,r16
	BREQ	noclick
	DEC	r16			; Decrement and update
	STS	ps2_clkcount,r16
	LDI	XH,HIGH(ps2_clkstack)	; Fetch click state from FILO buffer
	LDS	XL,ps2_clktail
	LD	r19,X+
	ANDI	XL,0x7
	STS	ps2_clktail,XL		; Store updated tail pointer
    noclick:
    	LDS	r19,ps2_lastclk		; Otherwise use last click state
    clickdone:
    	IN	r16,L13_PORT		; Turn on status LED (debug)
	SBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	LDS	r16,mousemode
	ANDI	r16,0x70
	CPI	r16,(MODE_MSYS<<4)
	BREQ	send_msys
	CPI	r16,(MODE_MS<<4)
	BREQ	send_ms
    send_tbp:
	RCALL	sendpacketTBP
	RJMP	senddone
    send_msys:
	RCALL	sendpacketMSYS		; Send event as a Mouse Systems packet
	RJMP	senddone
    send_ms:
	RCALL	sendpacketMS		; Send event as a Microsoft packet
    senddone:
	IN	r16,L13_PORT		; Turn off status LED (debug)
	CBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	RJMP	idleloop		; Return to idle loop
    dochangerate:
    	RCALL	ps2_flushbuff
	LDI	r17,5			; Retry attempts +1
    changerate_retry:
	DEC	r17			; Skip mouse rate when all attempts
	BREQ	changerate_done		; has failed
    	CLI
	LDI	r19,0xF3		; Issue setrate command
	RCALL	ps2_write
	LDS	r19,setrateval		; Send new mouse rate
	RCALL	ps2_write
	RCALL	ps2_flushbuff
	SEI
	RCALL	ps2_read
	BRTS	changerate_retry	; Retry command on timeout
	RCALL	ps2_flushbuff
	CPI	r16,0xFC		; Error response
	BREQ	changerate_done
	CPI	r16,0xFA		; FA response means OK
	BRNE	changerate_retry
    changerate_done:
	CLR	r19			; Clear rate value and return to loop
	STS	setrateval,r19
	RJMP	idleloop
	; main
	
; rts_cycle - Reports an M character and sets the converter to Microsoft mode
;
rts_cycle:
    	CLR	r19			; Revert to 1200 baud
	RCALL	USART_setbaud
	RCALL	SetMSmode		; Set converter to MS mode
	CLR	r20			; Send 'M' character for Microsoft
	LDI	r19,14
	RCALL	delayms
	LDI	r19,'M'
	RCALL	USART_write
	;CLR	r20			; Send '3' character for Logitech mode
	;LDI	r19,40
	;RCALL	delayms
	;LDI	r19,'3'
	;RCALL	USART_write
	CLI				; Reset all buffered mouse events
	CLR	r22
	CLR	r23
	CLR	r24
	CLR	r25
	STS	ps2_clkcount,r22
	STS	ps2_lastclk,r22
	STS	ps2_clkhead,r22
	STS	ps2_clktail,r22
	SEI
	RET
	; rts_cycle
	
; SetTBPmode - Set Three Byte Packed mode
;
SetTBPmode:
	LDS	r16,mousemode		; Set new mouse mode
	ANDI	r16,0x8F
	ORI	r16,(MODE_TBP<<4)
	STS	mousemode,r16
	LDI	r19,1			; Set to 8-bit frame format
	RCALL	USART_setbits
	RET
	; SetTBPmode
	
; SetMSYSmode - Configure converter for Mouse Systems mode
;
SetMSYSmode:
	LDS	r16,mousemode		; Set new mouse mode
	ANDI	r16,0x8F
	ORI	r16,(MODE_MSYS<<4)
	STS	mousemode,r16
	LDI	r19,1			; Set to 8-bit frame format
	RCALL	USART_setbits
	RET
	; SetMSYSmode

; SetMSmode - Configure converter for Microsoft mode
;
; Arguments: none
;
; Destroys: r16, r19
;
SetMSmode:
	LDS	r16,mousemode		; Set new mouse mode
	ANDI	r16,0x8F
	ORI	r16,(MODE_MS<<4)
	STS	mousemode,r16
	LDI	r19,0			; Set to 7-bit frame format
	RCALL	USART_setbits
	RET
	; SetMSmode
	
; Interrupt handler for the receive routine
;
USART_recvfunc:
	PUSH	r16
	IN	r16,SREG
	PUSH	r16
	PUSH	r17
	PUSH	r18
	PUSH	r19
	LDS	r16,UDR0		; Get serial byte
	ANDI	r16,0x7F		; Mask 8th bit off just in case
	LDZ	[ratetable]
    rateloop:
	LPM	r17,Z+
	AND	r17,r17			; Exit sequence if zero (terminator)
	BREQ	ratedone
	CP	r16,r17
	BREQ	setrate
    ratenext:
    	LDI	r17,1
    	ADD	ZL,r17
	CLR	r17
	ADC	ZH,r17
	RJMP	rateloop
    ratedone:
	LDS	r18,mousemode		; Check if in special command
	MOV	r17,r18			; sequence
	ANDI	r17,0x4
	BRNE	specialcmd
	CPI	r16,'*'			; Start of speed change escape
	BREQ	startescape
	CPI	r16,'m'
	BREQ	disablerts
	CPI	r16,'T'
	BREQ	usethreebyte
	CPI	r16,'U'
	BREQ	usemousesys
	CPI	r16,'V'
	BREQ	usemicrosoft
	CPI	r16,'c'			; Report copyright string and version
	BREQ	sendcopyright
	CPI	r16,'t'			; Send status hex
	BREQ	sendstatushex
	CPI	r16,'f'			; Send status byte
	BREQ	sendstatusbyte
	RJMP	USART_done
    setrate:
	LPM	r19,Z
	STS	setrateval,r19
    	RJMP	USART_done
    startescape:
	SBR	r18,0x4			; Set special command bit
	STS	mousemode,r18
	RJMP	USART_done
    specialcmd:				; Parse special command
    	CBR	r18,0x4			; Clear special command bit
	STS	mousemode,r18
	CPI	r16,'n'			; Ignore invalid speeds
	BRMI	USART_done
	CPI	r16,'q'+1
	BRSH	USART_done
	MOV	r19,r16			; Set new baud rate
	SUBI	r19,'n'
	RCALL	USART_setbaud
	RJMP	USART_done
    disablerts:				; Disable RTS to force Mouse Systems
    	LDS	r16,mousemode
	SBR	r16,0x80
	STS	mousemode,r16
    	CLR	r19
	RCALL	USART_setbaud
	RCALL	SetMSYSmode
	RJMP	USART_done
    sendstatushex:			; Send status hex
    	LDS	r19,mousemode
	ANDI	r19,0x70
	LSR	r19
	LSR	r19
	LSR	r19
	ORI	r19,(REPORT_REV<<4)
	RCALL	printhex8
	RJMP	USART_done
    sendstatusbyte:			; Send status byte
    	LDS	r19,mousemode
	ANDI	r19,0x70
	LSR	r19
	LSR	r19
	LSR	r19
	ORI	r19,(REPORT_REV<<4)
	RCALL	USART_write		; Transmit byte
	RJMP	USART_done
    sendcopyright:			; Send copyright string
    	LDZ	[copyright_str]
	RCALL	USART_writestrZ
	LDI	r19,0
	RCALL	USART_write
	RJMP	USART_done
    usethreebyte:
    	RCALL	SetTBPmode
	RJMP	USART_done
    usemousesys:
    	RCALL	SetMSYSmode
	RJMP	USART_done
    usemicrosoft:
    	RCALL	SetMSmode
	RJMP	USART_done
    USART_done:
	POP	r19
	POP	r18
	POP	r17
	POP	r16
	OUT	SREG,r16
	POP	r16
	RETI
	; USART_recvfunc

; Mouse rate table for mouse rate configuration
;
ratetable:
	; command,rate
	.DB	'J',10
	.DB	'K',20
	.DB	'L',40
	.DB	'R',40
	.DB	'M',60
	.DB	'Q',100
	.DB	'N',200
	.DB	0,0

; Copyright (or rather copyleft) string... May require changing if MouseWare
; drivers check this string
;
copyright_str:
	.DB	13,10
	.DB	"LAMEMOUSECONVERTER V0.10B FOR CIRC. REV.1 "
	.DB	"BY JOHN ",0x22,"LAMEGUY",0x22," WILBERT VILLAMOR",13,10
	.DB	"2021 MEIDO-TEK KYS HARDWARE DIVISION",13,10
	.DB	"THERE NEEDS TO BE A FILTER AGAINST <PROJECTNAME>DEV HANDLES",13,10,0

; Start of data segment
;
.DSEG

ps2_clkstack:	.BYTE 8			; Click event stack (FILO style)
ps2_clkhead:	.BYTE 1			; Stack head offset
ps2_clktail:	.BYTE 1			; Stack tail offset
ps2_clkcount:	.BYTE 1			; Stack count
ps2_lastclk:	.BYTE 1			; Most recent mouse click
ps2rec_count:	.BYTE 1			; Bytes currently received
ps2rec_readoff:	.BYTE 1			; Offset counter for ps2_read
ps2rec_maxpkt:	.BYTE 1			; PS/2 maximum packet length

setrateval:	.BYTE 1			; Mouse rate change value

mousemode:	.BYTE 1			; Mouse converter mode
					;   bit0: Parse PS/2 stream
					;   bit1: last middle mouse state
					;   bit2: RTS last state
					;   bit3: Reserved
					;   bit4-6: Mouse protocol mode
					;   bit7: Disable RTS detection

