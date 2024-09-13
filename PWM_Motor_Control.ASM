#include <msp430.h>
#include <stdio.h>
#include "LiquidCrystal_I2C.h"

/*****************************
*     variable definition    *
*****************************/
//keypad initialization
#define keyport P1OUT
#define COL1 (0x10 & P1IN)
#define COL2 (0x20 & P1IN)
#define COL3 (0x40 & P1IN)
#define COL4 (0x80 & P1IN)

unsigned char i, k, key = 0;
unsigned char Key_Value[] = {' ', '1', '2', '3', 'A', '4', '5', '6', 'B', '7', '8', '9', 'C', '*', '0', '#', 'D'};
unsigned int Key_Value_Int[] = {0, 1, 2, 3, 0, 4, 5, 6, 0, 7, 8, 9, 0, 0, 0, 0, 0};
unsigned int input = 0;
unsigned int stageInput;
unsigned int digit = 0;
unsigned char Value = 0;
unsigned int int_value = 0;
unsigned int completed = 0; // set to 1 if a new percentage has been entered
unsigned char get_key(void);

/*****************************
*       main function        *
*****************************/
int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer

    P1DIR = 0x0F;
    P1REN = 0xFF;
    P1OUT = 0xF0;

    P1IE |= BIT4; // col1 interrupt enable
    P1IE |= BIT5; // col2 interrupt enable
    P1IE |= BIT6; // col3 interrupt enable
    P1IE |= BIT7; // col4 interrupt enable

    P1IES |= BIT4; // edge sensitivity HIGH - LOW
    P1IES |= BIT5; // edge sensitivity HIGH - LOW
    P1IES |= BIT6; // edge sensitivity HIGH - LOW
    P1IES |= BIT7; // edge sensitivity HIGH - LOW

    P1IFG &= ~BIT4; // lower flag for column
    P1IFG &= ~BIT5; // lower flag for column
    P1IFG &= ~BIT6; // lower flag for column
    P1IFG &= ~BIT7; // lower flag for column

    P2DIR |= BIT0; // using P2.0 to send signal to H-Bridge
    P2OUT &= ~BIT0; // ensure the motor is off initially

    // using P2.1 for motor direction
    P2DIR |= BIT1;

    // Set up timer
    TB3CTL = TBSSEL__ACLK | MC__UP | TBCLR; // ACLK, up mode, clear TBR

    /* initial on-time and period */
    TB3CCR0 = 655; // period length for LED
    TB3CCR1 = 0;   // 0% duty cycle initial

    /* interrupts */
    TB3CCTL0 |= CCIE; // enable interrupt
    TB3CCTL1 |= CCIE; // enable interrupt

    TB3CCTL0 &= ~CCIFG; // lower flag
    TB3CCTL1 &= ~CCIFG; // lower flag

    PM5CTL0 &= ~LOCKLPM5;       // Remove the Lock
    __enable_interrupt();       // Globally Enable all the interupts

    I2C_Init(0x27);
    LCD_Setup();                // Initialize the LCD
    LCD_SetCursor(4, 0);        // set initial cursor to start of screen

    // Cute Little starter message for the user
    LCD_ClearDisplay();         // Clear Display
    LCD_Write("Hello :D");      // Write "Hello :D" to the user
    __delay_cycles(1080000);    // Forced delay so the hello doesn't immediately disappear
    LCD_ClearDisplay();
    LCD_Write("Enter Number: ");// Prompts the user to enter a number when it initally starts, removes confusion

    while (1) {
        while (completed == 0) {
            // waiting for input to be entered (when # is pressed)
            continue;
        }
        // AFTER input has been entered:
        if (input < 100)
        {
            stageInput = (input * 655) / 100;
            TB3CCR1 = stageInput;
            TB3CCTL1 |= CCIE;

            LCD_ClearDisplay();            // Clear Display
            LCD_Write("Duty Cycle: ");     // Show Duty Cycle
            LCD_WriteNum(input);           // Printing the users input (Duty Cycle)
            LCD_SetCursor(14,0);
            LCD_Write("%");
        }
        else{
            stageInput = 655;
            TB3CCTL1 = stageInput; //anything bigger than
            TB3CCTL1 |= CCIE;
            LCD_ClearDisplay();            // clear display
            LCD_Write("Duty Cycle:100%");  // set value to 100% as max
        }
        input = 0;      // clear input
        digit = 0;      // back to 100s place
        completed = 0;  // reset completed value
    }
    return 0;
}

/*****************************
*      vector interrupts     *
*****************************/

#pragma vector = TIMER3_B0_VECTOR
__interrupt void ISR_TB3_CCR0(void) {
    if (TB3CCR1 != 0) { // turn on led/motor if not zero
        P2OUT |= BIT0;
    }
    TB3CCTL0 &= ~CCIFG; // lower flag
}

#pragma vector = TIMER3_B1_VECTOR
__interrupt void ISR_TB3_CCR1(void) {
    P2OUT &= ~BIT0; // turns motor off
    TB3CCTL1 &= ~CCIFG; // lower flag
}

#pragma vector = PORT1_VECTOR
__interrupt void ISR_KEYPAD_PRESS(void) {
    unsigned int count = 0;
    //scan each row, calculate key value based on row (i) and column (COL#) pressed
    k = 1;
    for (i = 0; i < 4; i++) {
        keyport = ((0x01 << i) ^ 0xFF); //set the row lines to check
        if (!COL1) {
            key = k + 0;
            while (!COL1);
            count = key;
            break;
        }
        if (!COL2) {
            key = k + 1;
            while (!COL2);
            count = key;
            break;
        }
        if (!COL3) {
            key = k + 2;
            while (!COL3);
            count = key;
            break;
        }
        if (!COL4) {
            key = k + 3;
            while (!COL4);
            count = key;
            break;
        }
        k += 4;
        keyport |= (0x01 << i);
    }

    // creating input from key press
    Value = Key_Value[count];
    if ((Value < '0' || Value > '9') && Value != '#') { // clear if not a digit 0-9
        input = 0;
        digit = 0;
    }
    else if (Value == '#' && completed == 0) { // move to stageInput if value is #
                                               // "Sending" the inputed number through the H-Bridge,
                                               // Indicates when the input is finished
        completed = 1;
    }
    else if (Value != '#' && digit == 0) { // value is in 100s place
        int_value = Key_Value_Int[count];
        input = int_value * 100;
        digit += 1;
    }
    else if (Value != '#' && digit == 1) { // value is in 10s place
        int_value = Key_Value_Int[count];
        input += int_value * 10;
        digit += 1;
    }
    else if (Value != '#' && digit == 2) { // value is 1s place
        int_value = Key_Value_Int[count];
        input += int_value;
        digit = 0;
    }
    else if (Value != '#' && digit > 2) { // if value is larger than 999 (overflow) -> clear input
                                          // This prevents the number from going beyond the 100% duty cycle
        input = 0;
        digit = 0;
    }
    else { // clear if any other case
        input = 0;
        digit = 0;
    }

    P1OUT = 0xF0; // reset P1 pins for columns & rows
    P1IFG = 0x00; // lower flags
}
