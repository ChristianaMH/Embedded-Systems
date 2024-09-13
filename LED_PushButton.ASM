;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
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
; Main loop here - creates a blinking LED
;-------------------------------------------------------------------------------
init:

			CLR.b	P6OUT					;Clear Port 6 output

			mov.b	#01000000b, P6DIR		;P6.6 output (LED2, GREEN)

			mov.b	#00000000b, P2DIR		;set P2 as inout for Switch2
			bis.b	#BIT3, &P2REN			;enable P2.3 as pull up/down
			bis.b	#BIT3, &P2OUT			;select P2.3 as pull up

			bic.w	#0001h, &PM5CTL0		;GPIO power on

main_loop:

check_S2:
			bit.b	#BIT3, &P2IN			;we check the switch bit value (pull up)
			jnz		check_S2				;jump back to start of check_S1 if button not hit

led2_toggle:
			xor.b	#01000000b, P6OUT			;toggle bit P6OUT

			jmp		main_loop					;repeat to main forever

			nop



                                            

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
            
