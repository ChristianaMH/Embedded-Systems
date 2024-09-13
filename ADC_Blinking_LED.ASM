;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
init:
		clr.b P3OUT						;clear P3OUT
		clr.w R4						;clear register 4
		mov.w #0FFh, &P3DIR 			;turn P3 at output
		bis.b #BIT2, &P1SEL0			;select ADC as input channel = 11 (P1.2)
		bis.b #BIT2, &P1SEL1
		bic.w #0001h, &PM5CTL0			; enable I/O

;ADC set up
		mov.w #0210h, &ADCCTL0			;enable ADC
		mov.w #0220h, &ADCCTL1			;select clock source as ACLK and divide each time by 1
		mov.w #0020h, &ADCCTL2			;set ADC resolution to 12-bit resolution
		mov.w #0002h, &ADCMCTL0			;voltage reference set to A2 channel

		bis.w #ADCIE0, &ADCIE			;enable interrupt for ADCMEM0
		nop
		bis.w #GIE, SR					;enable global interrupt flag
		nop

;timer set up
		bis.w #TBCLR, &TB0CTL			;set the clear bit in the control register
		bis.w #TBSSEL__ACLK, &TB0CTL	;select ACLK as source
		mov.w #8000h, &TB0CCR0			;set the timer to reset at 2^15 -> equates to one second
		bis.w #MC__UP, &TB0CTL			;counts up to CCR0 value set above
		bis.w #TBIE, &TB0CTL			;enable interrupt on overflow
		bic.w #TBIFG, &TB0CTL			;clear timer flag
		nop

		mov.w #0213h, &ADCCTL0			;start conversion

main: 	jmp main
		nop
;-------------------------------------------------------------------------------
; ISR
;-------------------------------------------------------------------------------
ISR_ADC:
		mov.w ADCMEM0, R4				;move result to R4
		add.w #0FFFFh, R4				;increasing R4 to see change in LED with human eye
		mov.w R4, &TB0CCR0				;set R4 as new reset value
		mov.w #0213h, &ADCCTL0			;enable conversion again
		reti

ISR_TB0:
		xor.b #BIT0, &P3OUT				;toggle LED
		bic.w #TBIFG, &TB0CTL			;clear flag
		reti

;-------------------------------------------------------------------------------
; Memory Allocation
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

			.sect ".int29"					; ADC Vector
			.short ISR_ADC

			.sect ".int42"					; Timer B0 Vector
			.short ISR_TB0
