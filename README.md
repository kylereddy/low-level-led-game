# Low-Level LED Game
*This is a program which I wrote as a final project for my Computer Science IV class from spring 2020.*

This LED game is written in ARM assembly for a Raspberry Pi 3 Model B+. The program is meant to be run without an existing operating system on the device and interacts directly with the CPU's registers.

The circuit the game needs is simple: five LEDs (preferably one of a different color) and a single push-button.

## The Game
1. When the game first starts (upon powering the Pi), a "countdown" of sorts will display to show that the game is starting:

> ![Countdown GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/countdown.gif)

2. Next, the game loop will begin. Each LED will turn on then off in sequence and then in reverse, as seen below:

> ![Game Loop GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/gameloop.gif)

3. During the game loop, the player's goal is to press the pushbutton when the center LED (blue in these examples) is turned on. If the player does this successfully, the LED will flash three times and they will gain one point, after which their remaining lives will be displayed using the three center LEDs--if all three LEDs are lit, they have three lives remaining. This can be seen here:

> ![Correct LED and Remaining Life Total GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/lifetotal.gif)

4. If, however, the player presses the button when a non-center LED is lit (red in these examples) during the game loop, the LED will flash three times, they will not gain a point, and they will lose one life from their starting total of three. 
* Below, you can see the player pressing the button at the wrong time:
> ![Wrong LED GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/wrongLED.gif)

* And below is their resulting life total displayed after doing so. Only two LEDs remain lit to indicate they have lost their first life:
> ![Remaining Life Total after Mistake GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/lifeloss.gif)

5. Regardless of whether the player selects the correct LED, their life total will be displayed until they press the button again to continue the game. Once they press the button, a countdown, like the one at the start of the game, is displayed to show that the game is continuing. In the GIF below, you will see the player's life total being displayed (3 in this case) and, once they press the button, the countdown begins:
> ![Continuing the Game GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/countdownafterpress.gif)

* The game loop (step 2) will now continue. However, each time the player presses the button during the game loop (which will be either step 3 or 4), the speed of the next loop will increase, whether or not they selected the correct LED. As seen below, the speed in the second loop is slightly faster than that of the first loop:

* Loop 1 (the second GIF in this description and the game's initial speed):

> ![Game Loop 1 GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/gameloop.gif)

* Loop 2 (after the first loop, where the player selected an LED):

> ![Game Loop 2 GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/gameloop2.gif)

6. The game will continue looping until the player loses three lives. Once this happens, all five LEDs will flash five times to show that the game has ended. Lastly, the players accumulated score (recall that selecting the center LED adds one to their total) will be displayed in 5-bit binary using the LEDs where the furthest right LED symbolizes the least significant bit. So, in the example below, the array of LEDs is `OFF-ON-OFF-OFF-ON` or `01001` which is a total of 9 points:

> ![End of Game GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/endgame.gif)

7. Finally, while the score is being displayed the player may restart the game by pressing the button. Their score will be reduced to zero, their lives increased to three, and step 1 and 2 will start again:

> ![Game Restart GIF](https://github.com/kylereddy/low-level-led-game/blob/main/demo/gamerestart.gif)
