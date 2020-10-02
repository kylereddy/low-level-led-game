# Low-Level LED Game
*This is a program which I wrote as a final project for my Computer Science IV class from spring 2020.*

This LED game is written in ARM assembly for a Raspberry Pi 3 Model B+. The program is meant to be run without an existing operating system on the device, as it interacts directly with the CPU's registers.

The circuit the game needs is simple: an LED of one color with two LEDs of another color on either side and a single push-button.

## The Game
When the game starts, the LEDs will start turning on, then off in a row and then in reverse. The player's goal is to press the button when the center LED (blue in the video below) is lit. The player starts the game with three "lives," which allows them to accidentally press the button when a non-center LED is lit twice. The game will end once all three of the player's lives have been lost.

If the button is pressed when the center LED is lit:
* The LED flashes 3 times
* The player gains 1 point
* The player's remaining lives are displayed (1-3) using the three LEDs in the middle

If the button is pressed when a non-center LED is lit: 
* The LED flashes 3 times
* The player loses one life
* The player's remaining lives are displayed (1-3) using the three LEDs in the middle

Each time the player "selects" an LED during the game, the speed at which the LEDs turn off and on increases, regardless of whether their selection was the center LED or not. This makes getting a high score difficult.

If the button is pressed when a non-center LED is lit and the player only has one life remaining, the game will end, which is signified by all five of the LEDs blinking at the same time. The player's score will now be displayed in binary, where the least significant bit is indicated by the LED furthest from the push-button (if set up like the example video). An LED being on indicates that that bit is a 1, while it being off indicates a 0.