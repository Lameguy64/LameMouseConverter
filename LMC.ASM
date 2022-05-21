; LMC.ASM - LameMouseConverter AVR firmware
; 2021-2022 John "Lameguy" Wilbert Villamor of Meido-Tek KYS Hardware Division
;
; Assembler: AVRA (1.4.2)
;
; Controller: ATmega328P @ 16MHz (or Arduino UNO R3 @ 16MHz)
; Can be made to work on smaller controllers with some modifications provided
; a hardware USART and at least one hardware INT pin is available.
;
; Changelog:
;
;   May 21, 2022:
;     * Added quadrature mouse emulation (always active).
;     * Renamed main assembler file from 'PS2SER2.ASM' to 'LMC.ASM'.
;     * Implemented watchdog timer. Not guaranteed if WDT reset preserves
;       mouse settings as bootloaders clear the MCUSR register and was
;       unable to test without a bootloader.
;     * Small restructuring of PS2MOUSE.INC for increased flexibility.
;     * Replaced JMP with RJMPs on reset/interrupt vector table.
;     * Driving the quadrature sense pin sets mouse report rate to 200Hz.
;
;   April 24, 2022:
;     * Version 1.13.
;     * Fixed typo in CAPTO8 macro causing faulty results if value of r23 is
;       positive, resulting in mouse movement jumps during specific movement
;       conditions.
;
;   April 11, 2022:
;     * Version 1.12.
;     * Fixed SummaMouse status command ('s') causing stack corruption.
;     * Added query button count ('k') command.
;     * Fixed inverted Y axis in SummaMouse MM Series protocol mode.
;     * Reactivated 'proper' firmware copyright string.
;     * Changed default PS/2 report rate to 60Hz.
;     * RTS toggle now resets PS/2 report rate to default.
;     * Works with Logitech MouseWare drivers if RTS disconnected (C7 mode).
;     * Added prompt mode ('D') command. Inhibits mouse packet transmission.
;     * Updated SummaMouse status command ('s') to report prompt mode status
;       (required by Windows MouseWare driver).
;     * Fixed mouse rate commands being interpreted during extended mouse
;       command sequence.
;     * Added report request command ('P') for prompt mode.
;     * Optimized code size.
;
;   January 21, 2022:
;     * Added support for SummaMouse MM Series mouse.
;     * Fixed init failure with older Microsoft PS/2 mice by increasing the
;       wait delay to 600ms on init.
;	
;   August 31, 2021:
;     * Initial Version.
;
; Todo:
; * Add Logitech 3-button protocol, possibly with wheel.
; * Compatibility for smaller ATmega controllers.
;
.NOLIST
.INCLUDE "m328Pdef.inc" 
.LIST

;
; Initial PS/2 mouse rate
;
.EQU PS2_RATE	= 60

;
; Mouse mode definitions (derived from the Logimouse C7)
;
.EQU MODE_MSYS	= 0			; Mouse Systems
.EQU MODE_TBP	= 1			; Three byte packed mode (C7 native?)
.EQU MODE_HEX	= 2			; Hexadecimal mode (unsupported)
.EQU MODE_PADR	= 3			; Bit Pad One Relative (unsupported)
.EQU MODE_RES	= 4			; Reserved
.EQU MODE_MM	= 5			; MM series
.EQU MODE_PADA	= 6			; Bit Pad One Absolute (unsupported)   
.EQU MODE_MS	= 7			; Microsoft mouse

;
; Revision number to report on format and revision byte
;
.EQU REPORT_REV	= 1			; Revision 3.0 C7

;
; Port and pin assignments for PS/2 mouse interface
;
.EQU PS2_PORT	= PORTD
.EQU PS2_DIR	= DDRD
.EQU PS2_IN	= PIND
.EQU PS2_CLK	= PD2			; Must always be pin 2 of PORTD
.EQU PS2_DAT	= PD4

;
; Port and pin assignments for RS-232 RTS input
;
.EQU RTS_PORT	= PORTD
.EQU RTS_DIR	= DDRD
.EQU RTS_IN	= PIND
.EQU RTS_PIN	= PD7

;
; Port and pin assignment for status LED output (usually L13)
;
.EQU L13_PORT	= PORTB
.EQU L13_DIR	= DDRB
.EQU L13_PIN	= PB5

;
; Port and pin assignments for quadrature mouse sense pin
;
.EQU QS_PORT	= PORTB
.EQU QS_DDR	= DDRB
.EQU QS_INP	= PIND
.EQU QS_PIN	= PB4

;
; Port and pin assignments for XA,XB quadrature outputs
;
.EQU QX_PORT	= PORTB
.EQU QX_DDR	= DDRB
.EQU QXA_PIN	= PB0
.EQU QXB_PIN	= PB1

;
; Port and pin assignments for YA,YB quadrature outputs
;
.EQU QY_PORT	= PORTB
.EQU QY_DDR	= DDRB
.EQU QYA_PIN	= PB2
.EQU QYB_PIN	= PB3

;
; Port and pin assignments for button outputs (open collector)
;
.EQU QB_PORT	= PORTD
.EQU QB_DDR	= DDRD
.EQU QBL_PIN	= PD5
.EQU QBR_PIN	= PD6

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

;
; Clock line control macros
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

;
; Data line control macros
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

;
; Delay macros (roughly tuned for 16MHz)
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
; Interrupt vector table
;
.ORG 0x0000				; reset vector
	RJMP	reset
.ORG 0x0002				; Interrupt 0 request
	RJMP	ps2_int
.ORG 0x0024				; USART receive
	RJMP     USART_recvfunc
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
	IN	r19,MCUSR		; Read, store then clear MCU reset bits
	STS	resetbits,r19
	CLR	r19
	OUT	MCUSR,r19
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
	IN	r16,QX_DDR		; Configure quadrature outputs
	SBR	r16,(1<<QXA_PIN)|(1<<QXB_PIN)
	OUT	QX_DDR,r16
	IN	r16,QX_PORT
	CBR	r16,(1<<QXA_PIN)|(1<<QXB_PIN)
	OUT	QX_PORT,r16
	IN	r16,QY_DDR
	SBR	r16,(1<<QYA_PIN)|(1<<QYB_PIN)
	OUT	QY_DDR,r16
	IN	r16,QY_PORT
	CBR	r16,(1<<QYA_PIN)|(1<<QYB_PIN)
	OUT	QY_PORT,r16
	IN	r16,QB_DDR		; Configure button outputs
	CBR	r16,(1<<QBL_PIN)|(1<<QBR_PIN)
	OUT	QB_DDR,r16
	IN	r16,QB_PORT
	CBR	r16,(1<<QBL_PIN)|(1<<QBR_PIN)
	OUT	QB_PORT,r16
	IN	r16,QS_DDR		; Setup quadrature sense input
	CBR	r16,(1<<QS_PIN)
	OUT	QS_DDR,r16
	IN	r16,QS_PORT		; Make sure pull-up is disabled
	CBR	r16,(1<<QS_PIN)
	OUT	QS_PORT,r16
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
	WDR				; Setup watchdog timer
	LDI	r16,(1<<WDCE)|(1<<WDE)
	STS	WDTCSR,r16
	LDI	r16,(1<<WDE)|(1<<WDP2)|(1<<WDP1)
	STS	WDTCSR,r16
	LDS	r19,resetbits		; Check if watchdog reset occurred
	ANDI	r19,(1<<WDRF)
	BRNE	noclearmode		; Don't clear settings on WDT reset
	LDI	r19,3
	STS	mousemode2,r19
	LDI	r19,PS2_RATE
	STS	setrateval,r19
	CLR	r16
	STS	quadcount,r16
	LDI	r19,0b0100
	STS	linesetup,r19
	RJMP	cleardone
    noclearmode:
	RJMP	noclearmode
    cleardone:
	STS	ps2_clkhead,r16
	STS	ps2_clktail,r16
	STS	ps2_clkcount,r16
	STS	ps2_lastclk,r16
	STS	mousemode,r16
	CLR	r20			; Wait 100ms to let things settle
	LDI	r19,100
	RCALL	delayms
	CLR	r17			; Clear IRQ flag just in case
	SBR	r17,(1<<INTF0)
	OUT	EIFR,r17
	SEI
	; reset
	
; Main routine
;
main:
	RCALL	ps2_init		; Initialize mouse
	IN	r16,L13_PORT		; Turn on status LED
	SBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	CLR	r20			; Flash L13
	LDI	r19,100
	RCALL	delayms
	IN	r16,L13_PORT		; Turn off status LED
	CBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	WDR
	; Following code is left commented here for possible future use
;	LDI	r19,PS2_MODE_REMOTE	; Set mouse to remote mode to obtain
;	RCALL	ps2_setmode		; the state of the buttons at power-on
;	LDS	r16,ps2rec_maxpkt
;	PUSH	r16
;	LDI	r16,5			; Set packet length to 5 bytes
;	STS	ps2rec_maxpkt,r16
;	CLI
;	LDI	r19,0xEB		; Get a report
;	RCALL	ps2_write
;	SEI
;	CLR	r20			; Delay 100ms
;	LDI	r19,0x64
;	RCALL	delayms
;    	RCALL	ps2_read		; Get response
;    	BRTS	noreport
;    	CPI	r16,0xFA
;    	BRNE	noreport
;	RCALL	ps2_read		; Get button states
;	MOV	r18,r16
;    noreport:
;    	POP	r16			; Revert last packet length
;	STS	ps2rec_maxpkt,r16
	;
	LDS	r19,resetbits		; Check if watchdog reset occurred
	ANDI	r19,(1<<WDRF)
	BREQ	notwdtinit
	LDS	r18,linesetup		; Restore last line settings
	MOV	r19,r18			; Baud rate
	ANDI	r19,0x3
	RCALL	USART_setbaud
	MOV	r19,r18			; Word size
	LSR	r19
	LSR	r19
	ANDI	r19,1
	RCALL	USART_setbits
	ANDI	r19,0b1000		; Parity
	BREQ	noparity
	LDI	r19,3
	RCALL	USART_setparity
    noparity:
	LDS	r19,mouserate		; Use last mouse rate setting
	RJMP	setinitrate
    notwdtinit:
	IN	r16,QS_INP		; Set 200Hz mouse report rate if
	LDI	r19,PS2_RATE		; quadrature sense pin is driven high,
	SBRC	r16,QS_PIN		; otherwise use default rate
	LDI	r19,200
    setinitrate:
    	RCALL	ps2_setrate		; Set initial mouse rate
    	RCALL	ps2_flushbuff		; Set streaming mode
	LDI	r19,PS2_MODE_STREAM
	RCALL	ps2_setmode
	RCALL	ps2_enable		; Start streaming
	RCALL	SetMSYSmode		; Set Mouse Systems as initial protocol
    idleloop:
    	WDR
    	LDS	r16,mousemode		; Skip RTS cycle check if forced to
	ANDI	r16,0x80		; Mouse Systems mode
	BRNE	skip_rts
	LDS	r18,mousemode		; Load mouse mode value
	MOV	r16,r18
	ANDI	r16,0x04
	IN	r17,RTS_IN		; Read RTS pin state
	BST	r17,RTS_PIN
	BLD	r17,2
	BLD	r18,2			; Copy bit to mouse mode as well to
	STS	mousemode,r18		; keep track of last state
	ANDI	r17,0x04
	CP	r16,r17			; Only do RTS sequence when last
	BREQ	skip_rts		; state was off
	BRMI	skip_rts
	RCALL	rts_cycle		; Proceed to RTS cycle + MS mode
    skip_rts:
    	LDS	r16,mousemode2		; Prompt mode inhibits mouse reports
    	SBRC	r16,4
    	RJMP	idleloop
	LDS	r19,setrateval		; Check if mouse rate needs updating
	AND	r19,r19
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
	RCALL	sendevent		; Transmit mouse event
	RJMP	idleloop		; Return to idle loop
    dochangerate:
    	RCALL	ps2_setrate		; Mouse rate change
	CLR	r19			; Clear rate value and return to loop
	STS	setrateval,r19
	RJMP	idleloop
	; main
	
sendevent:
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
    	IN	r16,L13_PORT		; Turn on status LED (debug)
	SBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	LDS	r16,mousemode
	ANDI	r16,0x70
	CPI	r16,(MODE_MM<<4)
	BREQ	send_mm
	CPI	r16,(MODE_MSYS<<4)
	BREQ	send_msys
	CPI	r16,(MODE_MS<<4)
	BREQ	send_ms
    send_tbp:
	RCALL	sendpacketTBP
	RJMP	senddone
    send_mm:
	RCALL	sendpacketMM
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
	RET
	; sendevent
	
; rts_cycle - Reports an M character and sets the converter to Microsoft mode
;
rts_cycle:
    	CLR	r19			; Revert to 1200 baud
	STS	linesetup,r19
	RCALL	USART_setbaud
	RCALL	SetMSmode		; Set converter to MS mode
	CLR	r20			; Send 'M' character for Microsoft
	LDI	r19,14
	RCALL	delayms
	LDI	r19,'M'
	RCALL	USART_write
;	CLR	r20			; Send '3' character for Logitech mouse
;	LDI	r19,40
;	RCALL	delayms
;	LDI	r19,'3'
;	RCALL	USART_write
	LDI	r19,PS2_RATE		; Set default PS/2 mouse rate
	STS	setrateval,r19
	LDS	r19,mousemode2
	ANDI	r19,~0x1F
	ORI	r19,3
	STS	mousemode2,r19
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
	
; SetMMmode - Set SummaMouse MM Series mode
;
SetMMmode:
	LDS	r16,mousemode		; Set new mouse mode
	ANDI	r16,0x8F
	ORI	r16,(MODE_MM<<4)
	STS	mousemode,r16
	LDI	r19,1			; Set to 8-bit frame format
	RCALL	USART_setbits
	LDI	r19,3			; Set odd parity
	RCALL	USART_setparity
	LDS	r19,linesetup
	ANDI	r19,0b0011
	ORI	r19,0b1100
	STS	linesetup,r19
	RET
	; SetMMmode

; SetTBPmode - Set Three Byte Packed mode
;
SetTBPmode:
	LDS	r16,mousemode		; Set new mouse mode
	ANDI	r16,0x8F
	ORI	r16,(MODE_TBP<<4)
	STS	mousemode,r16
	LDI	r19,1			; Set to 8-bit frame format
	RCALL	USART_setbits
	LDS	r19,linesetup
	ANDI	r19,0b0011
	ORI	r19,0b0100
	STS	linesetup,r19
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
	LDS	r19,linesetup
	ANDI	r19,0b0011
	ORI	r19,0b0100
	STS	linesetup,r19
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
	LDS	r19,linesetup
	ANDI	r19,0b0011
	STS	linesetup,r19
	RET
	; SetMSmode
	
; UART receive handler querying commands
;
USART_recvfunc:
	PUSH	r16
	IN	r16,SREG
	PUSH	r16
	PUSH	r17
	PUSH	r18
	PUSH	r19
	LDS	r16,UDR0		; Get serial byte
	ANDI	r16,0x7F		; Mask off 8th bit
	LDS	r18,mousemode
	MOV	r17,r18			; Check if in extended command
	SBRC	r17,3			; sequence (last character was *)
	RJMP	recv_extcmd		; Jump to extended command parser
	CLR	r18
	LDZ	[ratetable]		; Load address of mouse rate table
    recv_rateloop:			; Start of mouse rate searching
	LPM	r17,Z+			; Load command character of mouse rate
	AND	r17,r17			; Exit sequence if zero (terminator)
	BREQ	recv_ratedone
	CP	r16,r17			; Does mouse rate match command?
	BRNE	PC+2			; Otherwise advance to next entry	
	RJMP	recv_setnewrate		; Set new mouse rate
    	LDI	r17,1			; Increment address then repeat
    	ADD	ZL,r17
	CLR	r17
	ADC	ZH,r17
	INC	r18
	RJMP	recv_rateloop
    recv_ratedone:			; Parse regular commands starts here
    	LDS	r18,mousemode
	CPI	r16,'*'			; Is it extended command character?
	BRNE	PC+2	
	RJMP	recv_extchar
	CPI	r16,'D'			; Prompt mode
	BREQ	setpromptmode
	CPI	r16,'P'			; Request report
	BRNE	PC+2
	RJMP	recv_reqreport
	CPI	r16,'S'			; Setup SummaMouse format
	BRNE	PC+2
	RJMP	usemm
	CPI	r16,'T'			; Setup Three-byte packed format
	BRNE	PC+2
	RJMP	usethreebyte
	CPI	r16,'U'			; Setup Mouse Systems format
	BRNE	PC+2
	RJMP	usemousesys
	CPI	r16,'V'			; Setup Microsoft format
	BRNE	PC+2
	RJMP	usemicrosoft
	CPI	r16,'c'			; Report copyright string and version
	BREQ	sendcopyright
	CPI	r16,'f'			; Send format and revision
	BREQ	sendformatbyte
	CPI	r16,'k'			; Query number of buttons
	BREQ	querybuttons
	CPI	r16,'m'			; Disable RTS toggle detection
	BREQ	disablerts
	CPI	r16,'s'			; Send SummaMouse status
	BREQ	sendmmstat
	CPI	r16,'t'			; Send format and revision (hex)
	BREQ	sendformathex
	CPI	r16,0x05		; Send SummaMouse diagnostic report
	BRNE	PC+2
	RJMP	sendmmdiag
	RJMP	USART_done
    setpromptmode:
	LDS	r19,mousemode2		; Set prompt mode flag
    	SBR	r19,0x10
    	STS	mousemode2,r19
    	RJMP	USART_done
    sendcopyright:			; Send copyright string
    	LDZ	[copyright_str]
	RCALL	USART_writestrZ
	LDI	r19,0
	RCALL	USART_write
	RJMP	USART_done
    sendformatbyte:			; Send format byte
    	LDS	r19,mousemode
	ANDI	r19,0x70
	LSR	r19
	LSR	r19
	LSR	r19
	ORI	r19,(REPORT_REV<<4)
	RCALL	USART_write		; Transmit byte
	RJMP	USART_done
    querybuttons:			; Send number of buttons (3)
	LDI	r19,'3'
	RCALL	USART_write
	RJMP	USART_done
    disablerts:				; Disable RTS to force Mouse Systems
    	LDS	r16,mousemode
	SBR	r16,0x80
	STS	mousemode,r16
    	CLR	r19
	RCALL	USART_setbaud
	RCALL	SetMSYSmode
	RJMP	USART_done
    sendmmstat:
	LDS	r19,mousemode2
	BST	r19,4			; Get the prompt mode bit
	LDI	r19,0b00001111
	BLD	r19,6			; Store prompt mode bit to status
	RCALL	USART_write
    	RJMP	USART_done
    sendformathex:			; Send format and rate in ASCII
    	LDZ	[modetable]		; Send mouse mode character
    	MOV	r16,r18
    	LSR	r16
    	LSR	r16
    	LSR	r16
    	LSR	r16
    	ANDI	r16,0x7
    	ADD	ZL,r16
    	CLR	r16
    	ADC	ZH,r16
    	LPM	r19,Z
    	RCALL	USART_write
    	LDS	r16,mousemode2
    	ANDI	r16,0x1F
    	SBRC	r16,4			; Check if in prompt mode
    	RJMP	isprompt
    	LDZ	[reptable]		; Send current mouse report rate
    	ADD	ZL,r16
    	CLR	r16
    	ADC	ZH,r16
    	LPM	r19,Z
    	RCALL	USART_write
    	RJMP	USART_done
    isprompt:
	LDI	r19,'D'
	RCALL	USART_write
	RJMP	USART_done
    sendmmdiag:				; SummaMouse diagnostic (dummy)
    	BST	r19,0
	BLD	r16,2
	BST	r19,2
	BLD	r16,1
	BST	r19,1
	BLD	r16,0
	MOV	r0,r16
	LDI	r18,3
	RCALL	xmitpacket
	RJMP	USART_done
    usemm:
    	RCALL	SetMMmode
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
    recv_reqreport:			; Request report
    	LDS	r19,mousemode2		; Set prompt mode flag
    	SBR	r19,0x10
    	STS	mousemode2,r19
    	RCALL	sendevent		; Send mouse report
    	RJMP	USART_done
    recv_extchar:			; Sets extended command bit
	SBR	r18,0x8
	STS	mousemode,r18
	RJMP	USART_done
    recv_extcmd:			; Parse extended commands start here
    	CBR	r18,0x8			; Clear special command bit
	STS	mousemode,r18
;	CPI	r16,'?'			; C7-M Detection (not reversed yet)
;	BREQ	querymouse
	CPI	r16,'n'			; Ignore invalid speeds
	BRMI	recv_extbadspeed
	CPI	r16,'q'+1
	BRSH	recv_extbadspeed
	MOV	r19,r16
	SUBI	r19,'n'
	RCALL	USART_setbaud		; Set new baud rate
    recv_extbadspeed:
	RJMP	USART_done
;    querymouse:
;	LDI	r19,'C'
;	RCALL	USART_write
;	LDI	r19,'7'
;	RCALL	USART_write
;	RJMP	USART_done
    recv_setnewrate:			; Set new mouse rate
    	LDS	r19,mousemode2		; Clear prompt mode flag and set
    	ANDI	r19,~0x1F		; selected mouse report rate
    	OR	r19,r18
    	STS	mousemode2,r19
	LPM	r19,Z			; Get mouse rate from table
	STS	setrateval,r19		; Set it as desired mouse rate
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

; Decimal mouse mode to ASCII table
;
modetable:
	.DB 'U','T'
	.DB 'W','B'
	.DB '?','S'
	.DB 'A','V'

; Decimal mouse report rate to ASCII table
;
reptable:
	.DB 'J','K'
	.DB 'L','R'	
	.DB 'M','Q'
	.DB 'N','O'
	
; Mouse rate command look-up table
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

; Copyright (or rather copyleft) text data
;
copyright_str:
	.DB	13,10
	.DB	"LAMEMOUSECONVERTER V1.14  "
	.DB	"BY JOHN ",0x22,"LAMEGUY",0x22," WILBERT VILLAMOR",13,10
	.DB	"2021-2022 MEIDO-TEK KYS TECH HARDWARE DIVISION",13,10
	.DB     "RELEASED UNDER MPL V2 ",13,10
	.DB	0x22,"THERE SHOULD BE FILTERS AGAINST <PROJECTNAME>-DEV TYPES",0x22,13,10,0

;
; Start of data segment
;
.DSEG

;
; PS/2 variables
;
ps2_clkstack:	.BYTE 8			; Click event stack (FIFO style)
ps2_clkhead:	.BYTE 1			; Stack head offset
ps2_clktail:	.BYTE 1			; Stack tail offset
ps2_clkcount:	.BYTE 1			; Stack count
ps2_lastclk:	.BYTE 1			; Most recent mouse click
ps2rec_count:	.BYTE 1			; Bytes currently received
ps2rec_readoff:	.BYTE 1			; Offset counter for ps2_read
ps2rec_maxpkt:	.BYTE 1			; PS/2 maximum packet length
setrateval:	.BYTE 1			; Mouse rate change value
mouserate:	.BYTE 1			; Current mouse report rate

;
; Quadrature emulation counters
;
quadcount:	.BYTE 1

resetbits:	.BYTE 1

;
; Line settings
;
linesetup:	.BYTE 1			; bit0-1  : Baud rate
					;             0-1200, 1-2400
					;             2-4800, 3-9600
					; bit2    : Word size
					;             0:7bit, 1:8bit
					; bit3    : Parity

;
; C7 emulation variables
;
mousemode:	.BYTE 1			; Mouse mode
					;   bit0  : Parse PS/2 stream
					;   bit1  : Last middle mouse state
					;   bit2  : RTS last state
					;   bit3  : Extended command flag
					;   bit4-6: Mouse protocol mode
					;   bit7  : Disable RTS detection
					
mousemode2:	.BYTE 1			; Mouse mode 2
					;   bit0-3: Mouse report rate
					;   bit4  : Prompt mode
					;   bit5-7: Reserved
