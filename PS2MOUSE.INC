; PS2MOUSE.INC - PS/2 mouse transmit and receive routines
;
; Part of the LameMouseConverter project by John "Lameguy" Wilbert Villamor
; 2021 Meido-Tek KYS Hardware Division
;
; Protected under Mozilla Public License v2

.EQU PS2_MODE_REMOTE = 0xF0
.EQU PS2_MODE_STREAM = 0xEA

; Mouse fail routine (shows a blinking status light before retrying)
;
mousefail:
	LDI	r17,5
    blink_loop:
	IN	r16,L13_PORT		; Turn on status LED
	SBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	LDI	r20,0x01
	LDI	r19,0xF4
	WDR
	RCALL	delayms
	IN	r16,L13_PORT		; Turn off status LED
	CBR	r16,(1<<L13_PIN)
	OUT	L13_PORT,r16
	LDI	r20,0x01
	LDI	r19,0xF4
	WDR
	RCALL	delayms
	DEC	r17
	BRNE	blink_loop
	; mousefail

; ps2_init - PS2 mouse initialization routine
;
ps2_init:
	LDI	r17,5			; Init attempts +1
    init_retry:
    	DEC	r17			; Enter fail condition when all
	BREQ	mousefail		; attempts fail
	CLI
	LDI	r19,0xFF		; Initialize
	RCALL	ps2_write
	SEI
	CPI	r16,0			; Check if write failed (no device)
	BRNE	mousefail
	RCALL	ps2_read		; Read acknowledge byte
	BRTS	init_retry		; Retry on receive timeout
	RCALL	ps2_flushbuff
	CPI	r16,0xFA		; Retry init if response is not ACK
	BRNE	init_retry
	LDI	r20,0x02		; Delay 600ms before reading init result
	LDI	r19,0x58
	RCALL	delayms
	RCALL	ps2_read		; Get init result byte
	MOV	r17,r16
	RCALL	ps2_read		; Eat dummy byte
	RCALL	ps2_flushbuff
	CPI	r17,0xAA		; Init result must be AA
	BREQ	mouseok			; Otherwise show init error to
	RJMP	mousefail		; indicate attached mouse is bad
    mouseok:
	LDI	r16,3			; Set max packet length to 3 bytes
	STS	ps2rec_maxpkt,r16	; (for standard 3-button mouse mode)
    	CLR	r22			; Accumulated X motion
	CLR	r23
	CLR	r24			; Accumulated Y motion
	CLR	r25
	RET
	; ps2_init
    	
; ps2_setrate - Set mouse report rate
;
; Arguments:
;	r19	Desired mouse report rate
;
ps2_setrate:
	RCALL	ps2_flushbuff
    	LDI	r17,5			; Retry attempts +1
    mouserate_retry:
    	DEC	r17			; Skip mouse rate when all attempts
	BREQ	mouserate_skip		; has failed
	PUSH	r19
    	CLI
    	LDI	r19,0xF3		; Set mouse rate to specified rate
	RCALL	ps2_write
	POP	r19
	RCALL	ps2_write
	SEI
	RCALL	ps2_read
	BRTS	mouserate_retry		; Retry command on timeout
	RCALL	ps2_flushbuff
	CPI	r16,0xFC		; Error response (maybe not supported)
	BREQ	mouserate_skip
	CPI	r16,0xFA		; Response byte FA means OK
	BRNE	mouserate_retry
	STS	mouserate,r19
    mouserate_skip:
	RET
	; ps2_setrate
	
; ps2_setmode - Set mouse mode
;
ps2_setmode:
	LDI	r17,5			; Retry count + 1
    mousemode_retry:
    	DEC	r17
	BREQ	mousemode_fail
	CLI
	RCALL	ps2_write		; Set stream mode
	SEI
	RCALL	ps2_read
	RCALL	ps2_flushbuff
	BRTS	mousemode_retry
	CPI	r16,0xFA
	BREQ	mousemode_ok
	RJMP	mousemode_retry
    mousemode_fail:
    	RJMP	mousefail		; Streaming mode is required
    mousemode_ok:
    	RET
    	; ps2_setmode
    	
; ps2_enable - Enable mouse for streaming mode
;
ps2_enable:
	SET
	LDI	r17,5			; Retry count +1
    ps2enable_retry:
    	DEC	r17
	BREQ	ps2enable_fail
	CLI
	LDI	r19,0xF4		; Enable mouse
	RCALL	ps2_write
	SEI
	RCALL	ps2_read
	RCALL	ps2_flushbuff
	BRTS	ps2enable_retry
	CPI	r16,0xFA
	BREQ	ps2enable_ok
	RJMP	ps2enable_retry
    ps2enable_fail:
	CLT
    ps2enable_ok:
    	LDS	r16,mousemode
	SBR	r16,1			; Tell IRQ handler to parse packets
	STS	mousemode,r16
	RET
	; ps2_enable
	
; ps2_flushbuff - Flush read buffer
;
ps2_flushbuff:
	PUSH	r16
	CLR	r16			; Clear variables
	STS	ps2rec_count,r16
	STS	ps2rec_readoff,r16
	POP	r16
	RET
	; ps2_flushbuff
	
; ps2_read - Read a byte received from the PS/2 device
;
; This function fetches bytes that have been stored in the PS/2 mouse receive
; buffer. It is not recommended to call this function while the mouse is in
; streaming mode and the receive handler is parsing mouse packets.
;
; Arguments:
;	None
;
; Returns:
;	r16 - Byte value read when T flag clear. Otherwise read timeout
;
ps2_read:
	PUSH	r17
	PUSH	r18
	PUSH	r19
	PUSH	XL
	PUSH	XH
	SET
	CLR	r17
	CLR	r18
    ps2_read_wait:
        LDI	r19,1			; Simple timeout in case PS/2
	ADD	r17,r19			; device is not responding
	LDI	r19,0
	ADC	r18,r19
	CPI	r18,200
	BREQ	ps2_read_done
	LDS	r16,ps2rec_count	; Wait until a byte is present
	LDS	r19,ps2rec_readoff
	SUB	r16,r19
	BRMI	ps2_read_wait
	BREQ	ps2_read_wait
	CLR	XH			; Get read pointer
	LDI	XL,8
	ADD	XL,r19
	INC	r19			; Increment read offset
	STS	ps2rec_readoff,r19
	LD	r16,X			; Get byte
	CLT				; Clear T flag on success
    ps2_read_done:
	POP	XH
	POP	XL
    	POP	r19
	POP	r18
	POP	r17
	RET
	; ps2_read

; ps2_write - Transmit a byte to the PS/2 device
;
; Must disable IRQs before calling this function as the byte transmission
; cycle will trigger the IRQ routine intended for receive cycles
;
; Arguments:
;	r19 - Byte to send
;
; Returns:
;	r16 - Zero on success, otherwise no PS/2 device present
;
ps2_write:
	PUSH	r17
	PUSH	r18
	PUSH	r19
	CLK_HIGH			; Make sure CLK and DAT are floating
	DAT_HIGH
	delay300us
	CLK_LOW				; Drag CLK low for 300us
	delay300us
	DAT_LOW				; Then bring DAT low for 10us
	delay10us
	CLK_HIGH			; Bring CLK high
	delay10us
	CLR	r16
	CLR	r17
    write_wait_ini:			; Then wait for CLK to go low
    	LDI	r18,1			; Simple timeout in case no PS/2
	ADD	r16,r18			; device is connected
	LDI	r18,0
	ADC	r17,r18
	CPI	r17,10
	BREQ	write_fail
	SBIC	PS2_IN,PS2_CLK
	RJMP	write_wait_ini
	RJMP	write_ready
    write_fail:
	CLK_HIGH
	DAT_HIGH
        LDI	r16,1
	RJMP	write_ret
    write_ready:			; Device is in receive mode past this
	LDI	r18,8			; Number of bits to shift
	LDI	r17,1			; Parity bit
    write_loop:
    	MOV	r16,r19			; Shift the byte bit by bit to the
	ANDI	r16,0x01		; peripheral
	PUSH	r16
	BREQ	set_low
	DAT_HIGH
	RJMP	set_done
    set_low:
    	DAT_LOW
    set_done:
    	POP	r16			; Parity compute
    	EOR	r17,r16
    write_wait_high_d:			; Wait for clock pin to go high
    	SBIS	PS2_IN,PS2_CLK
	RJMP	write_wait_high_d
    write_wait_low_d:			; Then wait for pin to go low
    	SBIC	PS2_IN,PS2_CLK
	RJMP	write_wait_low_d
    	LSR	r19
    	DEC	r18
	BRNE	write_loop
	AND	r17,r17			; Send the parity bit
	BREQ	parity_low
	DAT_HIGH
	RJMP	parity_write_wait_h
    parity_low:
    	DAT_LOW
    parity_write_wait_h:		; Wait for clock cycle
    	SBIS	PS2_IN,PS2_CLK
	RJMP	parity_write_wait_h
    parity_write_wait_l:
    	SBIC	PS2_IN,PS2_CLK
	RJMP	parity_write_wait_l
	DAT_HIGH			; And finally the stop bit
    write_wait_high_s:
    	SBIS	PS2_IN,PS2_CLK
	RJMP	write_wait_high_s
    write_wait_low_s:
    	SBIC	PS2_IN,PS2_CLK
	RJMP	write_wait_low_s
    write_wait_high_e:
    	SBIS	PS2_IN,PS2_CLK
	RJMP	write_wait_high_e
	CLR	r16
    write_ret:
	CLR	r17			; Clear IRQ flag just in case
	SBR	r17,(1<<INTF0)
	OUT	EIFR,r17
	POP	r19
	POP	r18
	POP	r17
	RET
	; ps2_write

; Interrupt driven PS/2 receive handler
;
; Modifies:
;	r22:r23	Accumulated X movement (signed 16-bit)
;	r24:r25 Accumulated Y movement (signed 16-bit)
;
ps2_int:
	PUSH	r16
	IN	r16,SREG
	PUSH	r16
	PUSH	r17
	PUSH	r18
	PUSH	r19
	PUSH	r20
	PUSH	XL
	PUSH	XH
    int0repeat:
    	CLR	r16
	CLR	r17
    init_bitA:				; Make sure clock has settled low
	LDI	r18,1			; Timeout as the converter tends to
	ADD	r16,r18			; exhibit false IRQs and gets stuck
	CLR	r18			; here preventing RTS
	ADC	r17,r18
	CPI	r17,1
	BREQ	init_timeout
	SBIC	PS2_IN,PS2_CLK
    	RJMP	init_bitA
	RJMP	init_bitB
    init_timeout:
	RJMP	int0ret
    init_bitB:				; Wait for clock to go high
    	SBIS	PS2_IN,PS2_CLK
    	RJMP	init_bitB
	SBIC	PS2_IN,PS2_DAT		; Start bit must be low
	RJMP	resend
	CLR	r20			; Parity
	LDI	r18,8			; Number of bits
	CLR	r16			; Clear storage register
    bit_loop:				; Byte-wide data step
    	SBIC	PS2_IN,PS2_CLK		; Wait for signal to go low
	RJMP	bit_loop
    bit_wait:				; Wait for clock to go high
    	SBIS	PS2_IN,PS2_CLK
	RJMP	bit_wait
    	LDI	r17,0x80		; Set or clear bit if DAT pin
	SBIS	PS2_IN,PS2_DAT		; is high or not
	CLR	r17
	LSR	r16			; Shift bits left
	OR	r16,r17			; Merge received bit to byte
	EOR	r20,r17			; Compute parity
	DEC	r18			; Loop for next bit
	BRNE	bit_loop
	MOV	r19,r16
    parity_bitA:			; Parity bit cycle
    	SBIC	PS2_IN,PS2_CLK
	RJMP	parity_bitA
    parity_bitB:
    	SBIS	PS2_IN,PS2_CLK
	RJMP	parity_bitB
	LDI	r17,0x80		; Get parity bit
	SBIC	PS2_IN,PS2_DAT
	CLR	r17
    stop_bitA:				; Stop bit
    	SBIC	PS2_IN,PS2_CLK
	RJMP	stop_bitA
    stop_bitB:
	SBIS	PS2_IN,PS2_CLK
	RJMP	stop_bitB
	SBIS	PS2_IN,PS2_DAT		; Stop bit must be high
	RJMP	resend			; Otherwise perform a data resend
	CP	r17,r20
	BREQ	paritygood
    resend:
    	RCALL	ps2_flushbuff
	LDI	r19,0xFE
	RCALL	ps2_write
	RJMP	init_bitA		; Start receive all over
    paritygood:
	LDS	r16,ps2rec_count	; Get buffer length
	CPI	r16,8			; Check if full
	BRNE	getevent
	RJMP	int0ret
    getevent:
	CLR	XH			; Prepare pointer going to
	LDI	XL,8			; register file (r8-r15)
	ADD	XL,r16
	INC	r16			; Increment buffer length	
	STS	ps2rec_count,r16
	ST	X,r19			; Store byte read
	LDS	r16,mousemode		; Check if set to stream mode
	MOV	r17,r16
	ANDI	r17,0x1
	BREQ	int0ret			; Skip if not stream mode
	LDS	r16,ps2rec_count	; Check if bytes received matches
	LDS	r17,ps2rec_maxpkt	; buffer count
	CP	r16,r17
	BRMI	int0ret			; If not enough bytes of a packet
	RCALL	processQuad		; Relay quadrature signals
	SBRC	r8,4			; Check X sign bit
	RJMP	xminus
	ADD	r22,r9			; Accumulate X axis on positive
	CLR	r9
	ADC	r23,r9
	RJMP	xdone
    xminus:
    	NEG	r9			; Invert value for negative arithmetic
	SUB	r22,r9
	SBCI	r23,0
    xdone:
	SBRS	r8,5			; Check Y sign bit
	RJMP	yminus			; Y axis is inverted from PS/2 mouse
	NEG	r10
	ADD	r24,r10
	CLR	r10
	ADC	r25,r10
	RJMP	ydone
    yminus:
	SUB	r24,r10
	SBCI	r25,0
    ydone:
	MOV	r17,r8
	ANDI	r17,0x7			; Keep only first three bits for btns
	LDS	r16,ps2_lastclk		; Load last click state
	CP	r16,r17			; Check if different from last
	BREQ	skipclick		; Skip if no change
	STS	ps2_lastclk,r17		; Store new click
    	LDS	r16,ps2_clkcount	; Check if click stack is full
	CPI	r16,8
	BREQ	skipclick
	INC	r16			; Increment and update
	STS	ps2_clkcount,r16
	LDI	XH,HIGH(ps2_clkstack)	; Load pointer to the click stack
	LDS	XL,ps2_clkhead		; Increment head offset
	ST	X+,r17			; Store mouse status
	ANDI	XL,0x7			; Mask head pointer for wrap-around
	STS	ps2_clkhead,XL		; Store new head offset
    skipclick:
	RCALL	ps2_flushbuff		; Flush buffer for next packet
    int0ret:
    	CLR	r16			; Clear IRQ flag just in case
	SBR	r16,(1<<INTF0)
	OUT	EIFR,r16
	POP	XH
	POP	XL
	POP	r20
	POP	r19
	POP	r18
	POP	r17
	POP	r16
	OUT	SREG,r16
	POP	r16
	RETI
	; ps2_int
	

; Relays mouse inputs as simulated quadrature mouse signals (interrupt driven)
;
; Registers r8 to r10 are expected to contain PS/2 mouse packet data.
;
processQuad:
	IN	r16,QB_DDR		; Relay mouse button states
	BST	r8,0
	BLD	r16,QBL_PIN
	BST	r8,1
	BLD	r16,QBR_PIN
	OUT	QB_DDR,r16
	LDI	r20,2			; Double the movement signals as
    q_double:				; otherwise most mice will be too slow
	MOV	r19,r9
	CPI	r19,0
	BREQ	qx_nomove
	LDS	r18,quadcount		; Get counter of X quadrature
	ANDI	r18,0b0011
	SBRC	r8,4
	NEG	r19
    qx_pulseloop:
    	SBRC	r8,4
    	INC	r18
    	SBRS	r8,4
    	DEC	r18
	LDI	r17,0b1100		; Quadrature pattern
	ANDI	r18,0b0011
	BREQ	qx_skipshft		; Skip shifting if counter is zero
	MOV	r16,r18
    qx_shftloop:
    	LSR	r17
    	DEC	r16
    	BRNE	qx_shftloop
    qx_skipshft:
    	IN	r16,QX_PORT		; Set shifted bits to output pins
    	BST	r17,2
    	BLD	r16,QXA_PIN
    	BST	r17,3
    	BLD	r16,QXB_PIN
    	OUT	QX_PORT,r16
    	PUSH	r24			; Delay even though the Microsoft InPort
    	delay10us			; card still responds without it, but a
    	POP	r24			; delay is here nonetheless
    	DEC	r19
    	BRNE	qx_pulseloop
    	LDS	r16,quadcount
    	ANDI	r16,~0b0011
    	OR	r16,r18
    	STS	quadcount,r16
    qx_nomove:
    qy_double:
	MOV	r19,r10
	CPI	r19,0
	BREQ	qy_nomove
	LDS	r18,quadcount		; Get counter of Y quadrature
	LSR	r18
	LSR	r18
	ANDI	r18,0b0011
	SBRC	r8,5
	NEG	r19
    qy_pulseloop:
    	SBRS	r8,5
    	INC	r18
    	SBRC	r8,5
    	DEC	r18
	LDI	r17,0b1100		; Quadrature pattern
	ANDI	r18,0b0011
	BREQ	qy_skipshft		; Skip shifting if counter is zero
	MOV	r16,r18
    qy_shftloop:
    	LSR	r17
    	DEC	r16
    	BRNE	qy_shftloop
    qy_skipshft:
    	IN	r16,QY_PORT		; Set shifted bits to output pins
    	BST	r17,2
    	BLD	r16,QYA_PIN
    	BST	r17,3
    	BLD	r16,QYB_PIN
    	OUT	QY_PORT,r16
    	PUSH	r24
    	delay10us
    	POP	r24
    	DEC	r19
    	BRNE	qy_pulseloop
    	LDS	r16,quadcount
    	ANDI	r16,~0b1100
    	LSL	r18
    	LSL	r18
    	OR	r16,r18
    	STS	quadcount,r16
    qy_nomove:
        DEC	r20
    	BREQ	q_exit
    	RJMP	q_double
    q_exit:
	RET
	; processQuad
