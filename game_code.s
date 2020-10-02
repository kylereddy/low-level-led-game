            .text

            /*
            ==================================================================
            | LED Chaser Game
            ==================================================================
            How to play:
                1. To start the game, press the button
                    A countdown to the start of the game will display
                2. Next, the LEDs will start cycling. Your goal is to press
                    the button when the center LED (blue) is lit.
                    If you do, you will earn one point
                    If you press the button when a red LED is lit, you will
                        lose one life
                3. After pressing the button when any LED is lit, your 
                    number of remaining lives will be displayed using the
                    3 center LEDs. If 3 LEDs are lit, you have 3 lives
                    remaining, if 2 LEDs are lit, you have 2 lives, etc.
                4. Press the button to start a countdown to continue the LED
                    cycling.
                5. Keep pressing the button when the LED is blue to accumulate
                    the best score possible.
                6. Once you have lost all of your lives, all 5 LEDs will blink
                    in succession to show you have lost. Your total score will
                    then be displayed in binary where the least significant
                    bit is displayed using the LED connected to pin 12.
                    If your score is > 31, all of the LEDs will flash three
                    times instead.
            Note:
                Every time you press the button, the cycling will increase
                  in speed -- making the timing of your button press more
                  difficult.

            ==================================================================
             */

            .equ    GPIO_GPFSEL1, 0x3F200004 
            .equ    GPIO_GPFSEL2, 0x3F200008
            .equ    GPIO_GPSET0, 0x3F20001C
            .equ    GPIO_GPCLR0, 0x3F200028
            .equ    GPIO_GPEDS0, 0x3F200040
            .equ    GPIO_GPFEN0, 0x3F200058
            .equ    FIRST_BIT_MASK, 0x1

            .global _start

_start:
            @ Set pins 12, 16 - 19 as output
            LDR     R0, =GPIO_GPFSEL1
            LDR     R1, =set_pins_out
            LDR     R1, [R1]
            STR     R1, [R0]

            @ Set pin 20 as input
            LDR     R0, =GPIO_GPFSEL2
            LDR     R1, [R0]
            LDR     R2, =set_pin_20_in
            LDR     R2, [R2]
            AND     R1, R1, R2
            STR     R1, [R0]

            @ Set pin 20 as falling edge detect
            MOV     R3, #20
            BL      falling_edge_set

            @ Wait for a button press to start the game
            BL      wait_for_press  @ Waits to continue until button is pressed
            BL      countdown
            BL      event_clear

            @ After the game has ended, the player can play again by pressing the button.
            @ The program will branch to the game_over_jump label instead of _start to
            @ skip the code above.
game_over_jump:
            MOV     R4, #0x100000   @ Initial timer value
            MOV     R6, #0          @ Score
            MOV     R7, #3          @ Lives

            @ Cycles back and forth through each of the 5 LEDs, turning them on,
            @ checking for a button press, turning them off, and branching to
            @ game_over if necessary.
activate_led_loop:
            MOV     R3, #12     @ Select pin #
            BL      led_proc    @ Perform the LED functions for LED in R3
            CMP     R7, #0      @ Check if lives = 0
            BEQ     game_over   @ Branch if true

            MOV     R3, #16
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over

            MOV     R3, #17
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over

            MOV     R3, #18
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over

            MOV     R3, #19
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over

            MOV     R3, #18
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over

            MOV     R3, #17
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over

            MOV     R3, #16
            BL      led_proc
            CMP     R7, #0
            BEQ     game_over
            
            B       activate_led_loop

            @ Perform the LED functions for the LED being referenced with R3
led_proc:
            STMFD   SP!, {LR}

            BL      led_high            @ Turn on LED R3
            BL      delay_global_r4     @ Delay for R4 "time"
            STMFD   SP!, {R3}           @ Store LED pin number
            MOV     R3, #20             @ Place pin number for button in R3
            BL      event_check         @ Check for an input event on pin R3
            LDMFD   SP!, {R3}           @ Restore the LED pin number
            CMP     R0, #1              @ Check if a button event was detected
            BLNE    led_low             @ Turn off LED if false
            BLEQ    button_pressed      @ Branch to button_pressed if true

            LDMFD   SP!, {LR}       
            MOV     PC, LR              @ Return



button_pressed:
            STMFD   SP!, {LR}

            @ Flashes "pressed" LED three times to clearly indicate which was "pressed"
            BL      led_low
            MOV     R5, #0x50000
            BL      delay_with_parameter
            BL      led_high
            MOV     R5, #0x50000
            BL      delay_with_parameter
            BL      led_low
            MOV     R5, #0x50000
            BL      delay_with_parameter
            BL      led_high
            MOV     R5, #0x50000
            BL      delay_with_parameter
            BL      led_low
            MOV     R5, #0x50000
            BL      delay_with_parameter
            BL      led_high
            MOV     R5, #0x50000
            BL      delay_with_parameter
            BL      led_low

            @ Modify R4 to decrease the amount of time delay_global_r4 takes to run
            CMP     R4, #0x20000
            SUBGT   R4, R4, #0x15000

            @ Checks if the "pressed" LED is the center LED
            CMP     R3, #17     @ Checks if current LED pin number is that of the center LED
            ADDEQ   R6, #1      @ +1 point to score (R6) if true
            SUBNE   R7, #1      @ -1 life (R7) if false
            CMP     R7, #0      @ Check if life total (R7) = 0
            LDMEQFD SP!, {LR}   @ Returns early if life count (R7) = 0
            MOVEQ   PC, LR      @ ^^^

            @ This section displays the current life total. If the player has 3 lives
            @ remaining, LED 2, 3, and 4 will be lit. If they have 2 lives left, LED
            @ 2 and 3 will be lit. Lastly, if the player has one life remaining, only
            @ LED 2 will be lit.
            CMP     R7, #3
            MOVEQ   R3, #18
            BLEQ    led_high
            CMP     R7, #2
            MOVGE   R3, #17
            BLGE    led_high
            CMP     R7, #1
            MOVGE   R3, #16
            BLGE    led_high

            BL      wait_for_press  @ Waits to continue until button is pressed

            @ Turn off necessary LEDs that were used above to display the life total
            CMP     R7, #3
            MOVEQ   R3, #18
            BLEQ    led_low
            CMP     R7, #2
            MOVGE   R3, #17
            BLGE    led_low
            CMP     R7, #1
            MOVGE   R3, #16
            BLGE    led_low

            BL      countdown       @ Displays countdown before returning

            BL      event_clear     @ Ensures that button events have been cleared

            LDMFD   SP!, {LR}
            MOV     PC, LR          @ Return

            @ Will not return until a button press is detected
wait_for_press:
            STMFD   SP!, {LR} 

            MOV     R3, #20
            BL      event_clear     @ Clear event reg at bit 20 before checking for input
wait_loop:
            BL      event_check     @ Check for input
            CMP     R0, #1          @ 0 = no input, 1 = an input 
            BNE     wait_loop       @ Continue looping if no input is detected

            BL      event_clear     @ Clear event reg at bit 20 before returning
            LDMFD   SP!, {LR}
            MOV     PC, LR


            @ COUNTDOWN - Turns on and off LEDs 1 & 5, 2 & 4, and then 3 to give the player an indication of when the game will continue
countdown:
            STMFD   SP!, {LR} 

            MOV     R3, #12
            BL      led_high
            MOV     R3, #19
            BL      led_high

            MOV     R5, #0xF0000
            BL      delay_with_parameter

            BL      led_low
            MOV     R3, #12
            BL      led_low

            MOV     R3, #16
            BL      led_high
            MOV     R3, #18
            BL      led_high

            MOV     R5, #0xF0000
            BL      delay_with_parameter

            BL      led_low
            MOV     R3, #16
            BL      led_low

            MOV     R3, #17
            BL      led_high

            MOV     R5, #0xF0000
            BL      delay_with_parameter

            BL      led_low

            MOV     R5, #0xF0000
            BL      delay_with_parameter

            LDMFD   SP!, {LR} 

            MOV     PC, LR


            @ DELAY - Delays according to the value stored in R4. Will return with the original value of R4 restored.
delay_global_r4:
            STMFD   SP!, {R4}
delay_loop:   
            SUB     R4, #1
            CMP     R4, #0
            BGT     delay_loop

            LDMFD   SP!, {R4}
            MOV     PC, LR


            @ DELAY - Delays according to a value passed in using R5. This should be used for times when a specific delay length is desired.
delay_with_parameter:
            SUB     R5, #1
            CMP     R5, #0
            BGT     delay_with_parameter

            MOV     PC, LR


            @ TURN LED ON
led_high:
            LDR     R0, =GPIO_GPSET0    @ Get the GPSET0 register
            LDR     R1, [R0]            @ Load the contents
            MOV     R2, #1              @ Store #1 in R2
            LSL     R2, R2, R3          @ Bitshift the #1 left (pin N) many times
            ORR     R1, R1, R2          @ Set the pin in the FSEL register to true
            STR     R1, [R0]            @ Store the updated register

            MOV     PC, LR              @ Return


            @ TURN LED OFF
led_low:
            LDR     R0, =GPIO_GPCLR0    @ Get the GPCLR0 register
            LDR     R1, [R0]            @ Load the contents
            MOV     R2, #1              @ Store #1 in R2
            LSL     R2, R2, R3          @ Bitshift the #1 left (pin N) many times
            EOR     R1, R1, R2          @ Set the correct pin to true to clear pin N
            STR     R1, [R0]            @ Store the updated register

            MOV     PC, LR              @ Return


            @ SET PIN AS FALLING EDGE DETECT ENABLED
falling_edge_set:
            LDR     R0, =GPIO_GPFEN0    @ Get the GPFEN0 register
            LDR     R1, [R0]            @ Load the contents 
            MOV     R2, #1              @ Store #1 in R2
            LSL     R2, R2, R3          @ Bitshift the #1 left (pin N) many times
            ORR     R1, R1, R2          @ Set the correct bit in GPFEN0 to true
            STR     R1, [R0]            @ Store the updated register

            MOV     PC, LR              @ Return


            @ CHECK IF AN EVENT HAS BEEN DETECTED FOR PIN R3
event_check:
            LDR     R0, =GPIO_GPEDS0    @ Get the GPEDS0 register
            LDR     R1, [R0]            @ Load the contents 
            MOV     R2, #1              @ Store #1 in R2
            LSR     R1, R1, R3          @ Bitshift the register right (pin N) many times
            AND     R1, R1, R2          @ Store the result of R1 AND #1 in R1
            CMP     R1, #1              @ Check if result = 1
            MOVEQ   R0, #1              @ Set R0 return value to 1 if true (indicates that an event was detected)
            MOVNE   R0, #0              @ Set R0 return value to 0 if false (indicates that no event was detected)

            MOV     PC, LR              @ Return


            @ CLEAR EVENT DETECTED REGISTER BIT FOR PIN R3
event_clear:
            LDR     R0, =GPIO_GPEDS0    @ Get the GPEDS0 register
            LDR     R1, [R0]            @ Load the contents 
            MOV     R2, #1              @ Store 1 in R2
            LSL     R2, R2, R3          @ Bitshift the #1 left (pin N) many times
            ORR     R1, R1, R2          @ Set (pin N) in the GPEDS0 register
            STR     R1, [R0]            @ Store the updated register

            MOV     PC, LR              @ Return


game_over:
            @ Flash all LEDs five times to show the game has ended
            BL      flash_all_leds
            BL      flash_all_leds
            BL      flash_all_leds
            BL      flash_all_leds
            BL      flash_all_leds

            @ Check score against 32
            CMP     R6, #32

            @ Display score in binary using display_score if score < 32
            BLLT    display_score

            @ Flash all LEDs three times if score >= 32
            MOVGE   R5, #0xA0000
            BLGE    delay_with_parameter
            BLGE    flash_all_leds
            MOVGE   R5, #0xA0000
            BLGE    delay_with_parameter
            BLGE    flash_all_leds
            MOVGE   R5, #0xA0000
            BLGE    delay_with_parameter
            BLGE    flash_all_leds

            BL      wait_for_press  @ Wait for button press

            @ Turn off all LEDs if score < 32 (these would have been on from the display_score call)
            CMP     R6, #32
            MOVLT   R3, #12
            BLLT    led_low
            MOVLT   R3, #16
            BLLT    led_low
            MOVLT   R3, #17
            BLLT    led_low
            MOVLT   R3, #18
            BLLT    led_low
            MOVLT   R3, #19
            BLLT    led_low

            BL      countdown       @ Displays countdown before returning
            BL      event_clear     @ Ensures that button presses are cleared

            B       game_over_jump  @ Restart game from (near the) beginning (will skip unnecessary loads and stores)



flash_all_leds:
            STMFD   SP!, {LR}

            @ Turn on all LEDs
            MOV     R3, #12
            BL      led_high
            MOV     R3, #16
            BL      led_high
            MOV     R3, #17
            BL      led_high
            MOV     R3, #18
            BL      led_high
            MOV     R3, #19
            BL      led_high

            MOV     R5, #0xA0000
            BL      delay_with_parameter

            @ Turn off all LEDs
            MOV     R3, #12
            BL      led_low
            MOV     R3, #16
            BL      led_low
            MOV     R3, #17
            BL      led_low
            MOV     R3, #18
            BL      led_low
            MOV     R3, #19
            BL      led_low

            MOV     R5, #0xA0000
            BL      delay_with_parameter

            LDMFD   SP!, {LR}
            MOV     PC, LR          @ Return



display_score:
            STMFD   SP!, {R6, LR}   @ Store R6 (score) and LR

            AND     R1, R6, #FIRST_BIT_MASK 
            CMP     R1, #1          @ Checks if bit 0 in score is a 1
            MOVEQ   R3, #12
            BLEQ    led_high        @ Turn on LED connected to pin 12 if true

            LSR     R6, R6, #1
            AND     R1, R6, #FIRST_BIT_MASK
            CMP     R1, #1          @ Checks if bit 1 in score is a 1
            MOVEQ   R3, #16
            BLEQ    led_high        @ Turn on LED connected to pin 16 if true

            LSR     R6, R6, #1
            AND     R1, R6, #FIRST_BIT_MASK
            CMP     R1, #1          @ Checks if bit 2 in score is a 1
            MOVEQ   R3, #17
            BLEQ    led_high        @ Turn on LED connected to pin 17 if true

            LSR     R6, R6, #1
            AND     R1, R6, #FIRST_BIT_MASK
            CMP     R1, #1          @ Checks if bit 3 in score is a 1
            MOVEQ   R3, #18
            BLEQ    led_high        @ Turn on LED connected to pin 18 if true

            LSR     R6, R6, #1
            AND     R1, R6, #FIRST_BIT_MASK
            CMP     R1, #1          @ Checks if bit 4 in score is a 1
            MOVEQ   R3, #19
            BLEQ    led_high        @ Turn on LED connected to pin 19 if true

            LDMFD   SP!, {R6, LR}   @ Restore R6 (score) and LR
            MOV     PC, LR          @ Return

            .data
set_pins_out:   .word   0x9240040
set_pin_20_in:  .word   0xFFFFFFF8

