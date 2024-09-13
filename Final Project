
Problem Description: For this assignment, we are building off of the fourth project and still using the LCD screen, Motor, and H bridge to send and display the output. 
However, we are using WIFI enabled ESP 32 to get input from the user as opposed to the previous 4x4 keypad. We have a website with a user interface from which we obtain a speed percentage as input from the user. We then pass this onto the MCU using a Tx -> Rx UART communication protocol where the ESP32 transmits and MCU receives. After getting the values on the MCU side we use a USCI_A1 interrupt to handle the received data and process it.  We also use Timer B interrupts to turn the motor on and off. The value put in by the user gets displayed on the LCD screen using an I2C communication protocol which is the same as we did for assignment 4. As far as the ports are concerned we used P2.0 and P2.1 for IN1 and IN2 on the H bridge, P4.6 and P4.7 for SDA and SCL on the LCD screen, and 5V and GND go into the breadboard. We also used the RXD pin on the MCU to connect to the TXD pin on ESP32.

Pseudocode (For the Main and ESP):
Main.c

START

INITIALIZE global variables and buffers

MAIN FUNCTION
    STOP watchdog timer

    CONFIGURE UART
        PUT eUSCI in reset
        SET clock source to SMCLK
        SET baud rate to 115200
        CONFIGURE UART pins
        DISABLE GPIO power-on default high-impedance mode
        INITIALIZE eUSCI
        ENABLE USCI_A1 RX interrupt
        ENABLE global interrupt

    CONFIGURE motor and timer
        SET P2.0 as output for motor signal
        ENSURE motor is off initially
        SET P2.1 as output for motor direction

        SET timer to ACLK, up mode, clear TBR
        SET initial on-time and period
        ENABLE timer interrupts
        LOWER interrupt flags

    CONFIGURE LCD
        INITIALIZE LCD
        SET initial cursor to start of screen
        DISPLAY "Hello!" message
        DELAY
        CLEAR display
        DISPLAY "Enter Number:"

    WHILE (TRUE)
        IF (completed == 1)
            CLEAR display
            DISPLAY "Duty Cycle: "
            DISPLAY Number
            CALCULATE input as (Number * 655) / 100
            SET TB3CCR1 to input (Duty Cycle to Motor)

            RESET bufferIndex, completed

    RETURN 0

TIMER3_B0 INTERRUPT SERVICE ROUTINE
    IF TB3CCR1 != 0
        TURN ON motor
    LOWER interrupt flag

TIMER3_B1 INTERRUPT SERVICE ROUTINE
    TURN OFF motor
    LOWER interrupt flag

USCI_A1 INTERRUPT SERVICE ROUTINE
    RECEIVE character into rxData

    IF rxData is newline character
        SET completed flag

    IF rxData is digit AND bufferIndex < buffer size - 1
        STORE character in uartBuffer
        CAPTURE digit in uartBuffer3 based on rxData
        INCREMENT COUNT
        INCREMENT bufferIndex

        IF single digit case
            SET Number to uartBuffer3[2]
            RESET COUNT

        IF double digit case
            CALCULATE Number from uartBuffer3[0] and uartBuffer3[1]
            RESET COUNT

        IF triple digit case
            SET Number to 100
            RESET COUNT

ESP Arduino Sketch


START

INITIALIZE Wi-Fi library and HardwareSerial

DEFINE network credentials
DEFINE web server port number
INITIALIZE variable to store HTTP request

SETUP FUNCTION
    INITIALIZE MySerial1 at 115200 baud rate with RX=16, TX=17
    INITIALIZE Serial for debugging at 115200 baud rate
    PRINT "ESP32 UART Test" to Serial

    CONNECT to Wi-Fi network with SSID and password
    PRINT "Setting AP (Access Point)…"
    PRINT Access Point IP address

    START web server

LOOP FUNCTION
    LISTEN for incoming clients

    IF a new client connects
        PRINT "New Client." to Serial
        INITIALIZE String to hold incoming data from client

        WHILE client is connected
            IF there are bytes to read from the client
                READ a byte from the client
                PRINT the byte to Serial
                APPEND the byte to the header String

                IF the byte is a newline character
                    IF currentLine is empty (two newline characters in a row)
                        SEND HTTP response headers to client
                        
                        IF HTTP request contains "GET /send?value="
                            EXTRACT numeric value from the request
                            PRINT "Received value: " and the value to Serial

                            SEND each character of the value over UART
                            PRINT each character for debugging
                            ADD newline character to mark the end

                        DISPLAY HTML web page to client
                            Web Page Heading
                            Form to send numeric values
                            Submit button
                        
                        SEND HTTP response end to client
                        BREAK out of the while loop
                    ELSE
                        CLEAR currentLine
                ELSE IF the byte is not a carriage return
                    APPEND the byte to currentLine

        CLEAR header variable
        CLOSE the connection
        PRINT "Client disconnected." to Serial

END

