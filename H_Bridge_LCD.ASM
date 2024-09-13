#include <msp430.h>
#include <stdio.h>
#include "LiquidCrystal_I2C.h"

/*****************************
*     variable definition    *
*****************************/
char uartBuffer[8] = {0}; // Buffer to store original received characters
char uartBuffer2[4] = {0}; // Buffer used for testing the capturing of the characters
int uartBuffer3[4] = {0}; // Buffer used to store the original characters as ints instead of chars

unsigned int bufferIndex = 0;  // Index for the UART buffer
unsigned long input = 0;       // to store the final number
unsigned char completed = 0;   // set to 1 if a new percentage has been entered
int COUNT = 0;                // COUNT is used to help differentiate between Single, Double, and Triple digit characters.
//unsigned int stageInput = 0;
unsigned int Number = 0;       // Number that is used to send to the TB3CCR1 register to control the Duty Cycle
int flag = 0;
/*****************************
*       main function        *
*****************************/
int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer

    // UART Configuration
    UCA1CTLW0 |= UCSWRST;                     // Put eUSCI in reset
    UCA1CTLW0 |= UCSSEL__SMCLK;               // Clock source SMCLK
    UCA1BR0 = 8;                              // 1000000/115200 = 8.68
    UCA1MCTLW = 0xD600;                       // 1000000/115200 - INT(1000000/115200)=0.68
    P4SEL1 &= ~BIT2;                          // Configure UART pins
    P4SEL0 |= BIT2;
    P4SEL1 &= ~BIT3;                          // Configure UART pins
    P4SEL0 |= BIT3;

    PM5CTL0 &= ~LOCKLPM5;                     // Disable the GPIO power-on default high-impedance mode
                                              // to activate previously configured port settings
    UCA1CTLW0 &= ~UCSWRST;                    // Initialize eUSCI

    UCA1IE |= UCRXIE;                         // Enable USCI_A1 RX interrupt
    __enable_interrupt();                     // Enable global interrupt

    // Motor and Timer Configuration
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

    // LCD Configuration
    I2C_Init(0x27);
    LCD_Setup();                // Initialize the LCD
    LCD_SetCursor(4, 0);        // set initial cursor to start of screen

    // Cute Little starter message for the user
    LCD_ClearDisplay();         // Clear Display
    LCD_Write("Hello!");      // Write "Hello!" to the user
    __delay_cycles(1080000);    // Forced delay so the hello doesn't immediately disappear
    LCD_ClearDisplay();
    LCD_Write("Enter Number: ");// Prompts the user to enter a number when it initially starts, removes confusion

    //TB3CCR1 = 491; // Motor Value
    //TB3CCTL1 |= CCIE;

    while (1) {
        if (completed == 1) {
            // Process the input value
            LCD_ClearDisplay();
            LCD_Write("Duty Cycle: ");

            LCD_WriteNum(Number); // Writing the Number to the LCD (sometimes is iffy if the ESP disconnects mid communication)
            input = (Number * 655) / 100; // Calculation for Duty Cycle
//            if(Number == 100){
//                Number = Number - 1;
//            }
            TB3CCR1 = input; // Duty Cycle to Motor


            // Hard Code Testing
            //TB3CCR1 = 491; // Motor Value

            // Reset variables
            bufferIndex = 0;
            completed = 0;
            //COUNT = 0;
        }

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

#pragma vector = USCI_A1_VECTOR
__interrupt void USCI_A1_ISR(void)
{
    unsigned char rxData = UCA1RXBUF;

   if (rxData == '\n') {
    //if(bufferIndex == 7){

       //input = atol(uartBuffer);

        // Set the completed flag
        completed = 1;

    }

    if (rxData >= '0' && rxData <= '9' && bufferIndex < sizeof(uartBuffer) - 1) {
        // Accumulate digits into the buffer
        uartBuffer[bufferIndex] = rxData;

        //Cases to capture each character from the ESP
        if(rxData =='0')                                // Capturing 0
          {
              //uartBuffer2[bufferIndex] = 'x';
              uartBuffer3[bufferIndex] = 0;
              COUNT++;

          }
        if(rxData =='1')                                // Capturing 1
          {
              //uartBuffer2[bufferIndex] = 'y';
              uartBuffer3[bufferIndex] = 1;
              COUNT++;

          }
        if(rxData =='2')                                // Capturing 2
          {
              //uartBuffer2[bufferIndex] = 'u';
              uartBuffer3[bufferIndex] = 2;
              COUNT++;

          }
        if(rxData =='3')                                // Capturing 3
                  {
                      uartBuffer3[bufferIndex] = 3;
                      COUNT++;

                  }
        if(rxData =='4')                                // Capturing 4
                  {
                      uartBuffer3[bufferIndex] = 4;
                      COUNT++;

                  }
        if(rxData =='5')                                // Capturing 5
                  {
                      uartBuffer3[bufferIndex] = 5;
                      COUNT++;

                  }
        if(rxData =='6')                                // Capturing 6
                  {
                      uartBuffer3[bufferIndex] = 6;
                      COUNT++;

                  }
        if(rxData =='7')                                // Capturing 7
                  {
                      uartBuffer3[bufferIndex] = 7;
                      COUNT++;
                  }
        if(rxData =='8')                               // Capturing 8
                  {
                      uartBuffer3[bufferIndex] = 8;
                      COUNT++;

                  }
        if(rxData =='9')                                // Capturing 9
                  {
                      uartBuffer3[bufferIndex] = 9;
                      COUNT++;

                  }

        bufferIndex++;                                  // Move to the next character that is sent

        if(uartBuffer3[0] == 0 && uartBuffer3[1] == 0){ // Single Digit # Case i.e. "007" = 7
                    Number = uartBuffer3[2];            // This is where the number would be
                    COUNT = 0;
                }

       if(COUNT == 12 || COUNT == 16 || COUNT == 9 || COUNT == 2){ // Double Digit # Case i.e. "025" = 25

//            Number = 0;
            Number = uartBuffer3[0] * 10;                       // 10's Place
            Number += uartBuffer3[1];                           // 1's Place
            COUNT = 0;
        }

        if(uartBuffer3[1] == 0 && uartBuffer3[2] == 0){ // Triple Digit # i.e. "100" = 100s
            Number = 100;
            COUNT = 0;
        }
    }
}
