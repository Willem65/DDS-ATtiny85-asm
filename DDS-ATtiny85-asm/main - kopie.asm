.DEVICE ATtiny85	;for gavrasm

;.DEF	A = R19             ;GENERAL PURPOSE ACCUMULATOR 
.def	sweepcnt	= r18		; sweeplen counter

;***************************************************************************
         
.Org	$0000
		rjmp	RESET		; Reset Handler
		reti		; IRQ0 Handler
		reti		; PCINT0 Handler
		reti		; Timer1 CompareA Handler
		reti		; Timer1 Overflow Handler
rjmp	TIM0_OVF	; Timer0 Overflow Handle


;***************************************************************************
; Interrupt-Service-Routine Timer0 Overflow Handler
;***************************************************************************

TIM0_OVF:
		in	r15,SREG			; save the flag register
		;sbi	PinB, PB0		; Flip Pb0 @ 30.5 ms 
		
		;sbis	PINB, PINB2
		rjmp	T0_sweep		; if low, sweep 
T0_start:								
;		sbi	Portb, ADconv		; short pulse
		ldi	r17, 0b11010110 	; get ADC value	for frequency setting 
/*		out	ADCSRA,temp1		; Start A/D Conversion*/
T0_waitc1:
/*		sbis	ADCSRA, ADIF
		rjmp 	T0_waitc1      		; add result
		in	temp1, ADCL
		add	av_l, temp1
		in	temp1, ADCH
		adc	av_h, temp1		; Add new value to old value
		cbi	Portb, ADconv*/
		
		tst	r10			; no zeros in phase register
		brne	T0_go
		tst	r11
		brne	T0_go
		inc	r10			; else inc if zero
		
T0_go:		
		mov 	r26, r10 		; move to phase 
		mov 	r27, r11 		; range 1..2046 

		lsr		r11
		ror		r10			; average div by 2
		
T0_ex:
		out	SREG,r15 		; restore flag register
		reti 				; Return from interrupt

T0_sweep:
		subi	r26, -1	; sweep up from old frequency 
		adc	r27, r12
		dec	r18		; reached end ?
		brne	T0_ex			; 0x07ff
		rjmp	T0_start		; set phase to sweep start frequency	


;--------- BEGIN -----------------------------------------------
RESET:	
		ldi	r16, low(RAMEND)
		out	SPL, r16		; setup stack pointer
		ldi	r16, high(RAMEND)
		out	SPH, r16		; setup stack pointer

		nop

;***************************************************************************
; PLL setup
;***************************************************************************
		ldi 	r16, (1<<PLLE)		; Enable PLL
		out	PLLCSR, r16

waitPLL:
		in	r16, PLLCSR		; Wait for PLL to lock (approx. 100ms)
		sbrs 	r16, PLOCK			
		rjmp 	waitPLL 	
	
		in	r16, PLLCSR		; Set PLL as PWM clock source 
		ldi	r17, (1<<PCKE)
		or	r16, r17
		out	PLLCSR, r16
;***************************************************************************
; Port B setup
;***************************************************************************
		ldi	r16,0b00000100 	; set output
		out	PORTB,r16		; 1 = pull-up , 0 = float
		ldi	r16,0b00001011 	; low 2 bits are output, 1 = output , 0 = input
		out	DDRB,r16       	; to data direction register

		sbi	AcsR,	Acd		; Disable Comparator                     
      			 
	   	sbi	DidR0,	Adc3d		; Disable Adc3d Digital Input
	   	sbi	DidR0,	Adc2d		; Disable Adc2d Digital Input
		
		ldi  	ZH,High(2*SinTab)  	; Point ZH to Sine Table	



;***************************************************************************
; AD-Converter setup:
;***************************************************************************
;T0_start:
		ldi	r16,0b01100001	; PCk  230 kHz
		out	TCCR1,r16		; 



;***************************************************************************
; ; AD-Converter setup:
;***************************************************************************						

		ldi	r17, 0b11010000	; ADC init single conversion prescale 16
		out	ADCSRA,r17	
					
		ldi	r16, 0b00000000
		mov r10,r16

		ldi	r16, 0b1000
		mov	r11, r16           ; r11 , r17


			
		mov 	r26, r10 		; move to phase 
		mov 	r27, r11 		; range 1..2046 


;***************************************************************************
; timer 0  interrupt used
;***************************************************************************

		ldi 	r16,0b00000000		;normal mode	
		out 	TCNT0,r16		;Clear timer byte						
		out 	TCCR0A,r16		;TCCR0A: COM0A1 COM0A0 COM0B1 COM0B0 – – WGM01 WGM00 
						 
		ldi 	r16,0b00000101		;TCCR0B: FOC0A FOC0B – – WGM02 CS02 CS01 CS00
		out 	TCCR0B,r16		;clk / 1024
		ldi 	r16,0b00000010		;
		out	TIFR,r16		;Clear pending timer interrupt
		out	TIMSK,r16		;Enable Timer 0 ovfl interrupt
/*
;***************************************************************************
; timer 1 setup as pwm:				;clocks abt 230 kHz
;***************************************************************************
		ldi	r16,255		;Timer/Counter 1 top count 0xFF
		out	OCR1C,r16		; 
		ldi	r16,128		;Timer/Counter 1 compare val
		out	OCR1A,r16		; 

		ldi	r16,0b01100001	; PCk  230 kHz		;Timer/Counter 1 start
		out	TCCR1,r16		; 

		sei
		;ldi	sweepL, 16
		;ldi	sweepcnt, sweeplen


T0_ex:
		out	SREG,r15 		; restore flag register
		reti 				; Return from interrupt

		lsr	    r27

		dec	sweepcnt		; reached end ?
		brne	T0_ex			; 0x07ff
		
		rjmp	T0_start		; set phase to sweep start frequency	*/

;***************************************************************************

loop:		; 16 bit DDS			; @ 8 cycles
	 	add  	r29,	r26		
	 	adc  	r30,	r27 		
	 	lpm  	r0,z					; load program memmory
		out		OCR1A, r0			; sine wave pwm

		;lsr	av_h
		;ror	r27	

		rjmp	loop

		
;----------------------------------------------------	




;***************************************************************************
.org    $0100	

	; force table to begin at 256 byte boundary
		
;***************************************************************************
SinTab: 	; 256 step sine wave table 

.db	0x80,0x83,0x86,0x89,0x8c,0x8f,0x92,0x95,0x98,0x9c,0x9f,0xa2,0xa5,0xa8,0xab,0xae
.db	0xb0,0xb3,0xb6,0xb9,0xbc,0xbf,0xc1,0xc4,0xc7,0xc9,0xcc,0xce,0xd1,0xd3,0xd5,0xd8
.db	0xda,0xdc,0xde,0xe0,0xe2,0xe4,0xe6,0xe8,0xea,0xec,0xed,0xef,0xf0,0xf2,0xf3,0xf5
.db	0xf6,0xf7,0xf8,0xf9,0xfa,0xfb,0xfc,0xfc,0xfd,0xfe,0xfe,0xff,0xff,0xff,0xff,0xff
.db	0xff,0xff,0xff,0xff,0xff,0xff,0xfe,0xfe,0xfd,0xfc,0xfc,0xfb,0xfa,0xf9,0xf8,0xf7
.db	0xf6,0xf5,0xf3,0xf2,0xf0,0xef,0xed,0xec,0xea,0xe8,0xe6,0xe4,0xe2,0xe0,0xde,0xdc
.db	0xda,0xd8,0xd5,0xd3,0xd1,0xce,0xcc,0xc9,0xc7,0xc4,0xc1,0xbf,0xbc,0xb9,0xb6,0xb3
.db	0xb0,0xae,0xab,0xa8,0xa5,0xa2,0x9f,0x9c,0x98,0x95,0x92,0x8f,0x8c,0x89,0x86,0x83
.db	0x80,0x7c,0x79,0x76,0x73,0x70,0x6d,0x6a,0x67,0x63,0x60,0x5d,0x5a,0x57,0x54,0x51
.db	0x4f,0x4c,0x49,0x46,0x43,0x40,0x3e,0x3b,0x38,0x36,0x33,0x31,0x2e,0x2c,0x2a,0x27
.db	0x25,0x23,0x21,0x1f,0x1d,0x1b,0x19,0x17,0x15,0x13,0x12,0x10,0x0f,0x0d,0x0c,0x0a
.db	0x09,0x08,0x07,0x06,0x05,0x04,0x03,0x03,0x02,0x01,0x01,0x00,0x00,0x00,0x00,0x00
.db	0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x02,0x03,0x03,0x04,0x05,0x06,0x07,0x08
.db	0x09,0x0a,0x0c,0x0d,0x0f,0x10,0x12,0x13,0x15,0x17,0x19,0x1b,0x1d,0x1f,0x21,0x23
.db	0x25,0x27,0x2a,0x2c,0x2e,0x31,0x33,0x36,0x38,0x3b,0x3e,0x40,0x43,0x46,0x49,0x4c
.db	0x4f,0x51,0x54,0x57,0x5a,0x5d,0x60,0x63,0x67,0x6a,0x6d,0x70,0x73,0x76,0x79,0x7c



