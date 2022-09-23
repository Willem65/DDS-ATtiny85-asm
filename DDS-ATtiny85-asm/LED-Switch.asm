.DEVICE ATtiny85	;for gavrasm

.def temp = r18

;***************************************************************************
         
.Org	$0000
		rjmp	RESET		; Reset Handler
		



;--------- BEGIN -----------------------------------------------
RESET:	

        LDI		R16, HIGH(RAMEND)  //Initialized the stack
		OUT		SPH, R16
		LDI		R16, LOW(RAMEND)
		OUT		SPL, R16
		CLR		R16

;--------- DELAY -----------------------------------------------
		rcall wacht

;***************************************************************************

setup:
		ldi	r16,0b00010001 	; set output
		out	PORTB,r16		; 1 = pull-up , 0 = float

		ldi	r16,0b00010000 	; low 2 bits are output, 1 = output , 0 = input
		out	DDRB,r16       	; to data direction register

		ldi r16, 0b0000_0001
		out PORTB, r16



loop:


		
		
		rcall wacht
		in temp, PINB          ; get state of pins on Port B
		rcall wacht
		andi temp, 0b0000_0001    ; you should mask to get only what you want
		cpi temp, 0            ; compare result to 0 (pushbutton is pressed)
		brne loop           ; if != 0, go check again

		ldi r16, 0b0001_0000
		out PORTB, r16
		rcall wacht
		ldi r16, 0b0000_0000
		out PORTB, r16
		rcall wacht
		 
loop2:	
		rcall wacht	
		in temp, PINB          ; get state of pins on Port B
		andi temp, 0b0000_0001    ; you should mask to get only what you want
		cpi temp, 0            ; compare result to 0 (pushbutton is pressed)
		breq loop2 
		rcall wacht
		;ldi temp, 0b0000_0001 
		rjmp loop





;--------- DELAY -----------------------------------------------
wacht:
		push r19
		push r20
		push r21

		ldi  r21,0
lus_111:  INC  r21

		ldi  r20,0
lus_122:  INC  r20

        ldi  r19,0
lus_133:  INC  r19
		
	    CPI  r19,0x0f	
        BRCS lus_133
			
	    CPI  r20,0xf	
        BRCS lus_122

	    CPI  r21,0xff	
        BRCS lus_111
		pop r21
		pop r20
		pop r19

		ret