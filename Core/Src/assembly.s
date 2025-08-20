/*
 * assembly.s
 *
 */

 @ DO NOT EDIT
	.syntax unified
    .text
    .global ASM_Main
    .thumb_func

@ DO NOT EDIT
vectors:
	.word 0x20002000
	.word ASM_Main + 1

@ DO NOT EDIT label ASM_Main
ASM_Main:

	@ Some code is given below for you to start with
	LDR R0, RCC_BASE  		@ Enable clock for GPIOA and B by setting bit 17 and 18 in RCC_AHBENR
	LDR R1, [R0, #0x14]
	LDR R2, AHBENR_GPIOAB	@ AHBENR_GPIOAB is defined under LITERALS at the end of the code
	ORRS R1, R1, R2
	STR R1, [R0, #0x14]

	LDR R0, GPIOA_BASE		@ Enable pull-up resistors for pushbuttons
	MOVS R1, #0b01010101
	STR R1, [R0, #0x0C]
	LDR R1, GPIOB_BASE  	@ Set pins connected to LEDs to outputs
	LDR R2, MODER_OUTPUT
	STR R2, [R1, #0]
	MOVS R2, #0         	@ NOTE: R2 will be dedicated to holding the value on the LEDs

@ TODO: Add code, labels and logic for button checks and LED patterns
	
	@ Initialize variables
	LDR R0, =led_counter
	MOVS R1, #0
	STR R1, [R0]			@ Initialize LED counter to 0
	LDR R0, =increment_value
	MOVS R1, #1
	STR R1, [R0]			@ Initialize increment to 1

main_loop:
	@ Read button states from GPIOA IDR
	LDR R0, GPIOA_BASE
	LDR R3, [R0, #0x10]		@ Read GPIOA IDR
	LDR R1, GPIOB_BASE

	@ Initialize default values
	LDR R0, =increment_value
	MOVS R4, #1
	STR R4, [R0]			@ Default increment = 1
	LDR R0, =delay_mode
	MOVS R4, #0
	STR R4, [R0]			@ Default delay mode = 0 (long delay)

button0:
	@ Check each button and set LEDs accordingly
	@ Button 0 - change increment value to 2, default is 1
	MOVS R4, #1
	TST R3, R4
	BNE button1

	@ While SW0 is being held down, the LEDs should change to 
	@ increment by 2 every 0.7 seconds
	LDR R0, =increment_value
	MOVS R4, #2
	STR R4, [R0]

button1:
	@ Button 1 - changes timing to 0.3, default is 0.7
	MOVS R4, #2
	TST R3, R4
	BNE otherbuttons

	@ While SW1 is being held down, the increment timing 
	@ should change to every 0.3 seconds
	LDR R0, =delay_mode
	MOVS R4, #1
	STR R4, [R0]

otherbuttons:
	@ Button 2 - led pattern changes to 0xAA, stays like this
	MOVS R4, #4
	TST R3, R4
	BEQ button2pressed

	@ Button 3 - freezes pattern
	MOVS R4, #8
	TST R3, R4
	BEQ button3pressed

@ By default, the LEDs should increment by 1 every 0.7 seconds 
@ (with the count starting from 0)
default:
	@ All LEDs off for default
	MOVS R2, #0x00
	B write_leds

@ While SW2 is being held down, the LED pattern should
@ be set to 0xAA. Naturally, the pattern should stay at 0xAA 
@ until SW2 is released, at which point it will continue counting
@ normally from there
button2pressed:
	@ SW2 is pressed, force LEDs to 0xAA
	MOVS R2, #0xAA
	STR R2, [R1, #0x14]		@ Write directly to LEDs
	B main_loop				@ Skip normal counting, go back to check buttons

@ While SW3 is being held down, the pattern should freeze, 
@ and then resume counting only when SW3 is released
button3pressed:
	@ SW3 is pressed, freeze current pattern
	LDR R0, =led_counter
	LDR R2, [R0]			@ Load current counter value
	STR R2, [R1, #0x14]		@ Write current value to LEDs
	B main_loop				@ Skip increment and delay, go back to check buttons

@ Only one of SW2 or SW3 will be held down at one time, 
@ but SW0 and SW1 may be held at the same time

write_leds:
	STR R2, [R1, #0x14]
	B main_loop

@ LITERALS; DO NOT EDIT
	.align
RCC_BASE: 			.word 0x40021000
AHBENR_GPIOAB: 		.word 0b1100000000000000000
GPIOA_BASE:  		.word 0x48000000
GPIOB_BASE:  		.word 0x48000400
MODER_OUTPUT: 		.word 0x5555

@ TODO: Add your own values for these delays
LONG_DELAY_CNT: 	.word 12000000
SHORT_DELAY_CNT: 	.word 4800000

led_counter: 		.word 0		@ Current LED counter value (0-255)
increment_value: 	.word 1		@ Increment amount (1 or 2)
delay_mode:			.word 0		@ 0 = long delay, 1 = short delay

@ PLAN OF ACTION
@ Need to check if buttons has been pressed

@ Default - have an array to store states, go through array using increment counter, branch if button pressed? ie. idr changes
@ SW0 - changes incrementing value to 2 while being pressed ie. initialise increment value variable
@ SW1 - changes increment timing ie. long_delay_cnt vs short_delay_cnt
@ SW2 - interrupt current pattern to make the led pattern 0xAA ie. save the state it was previously in to a variable and then set to AA
@ SW3 - freeze button ie. save the state ie. idr value ie. base value ie. R3

@ incrementing and timing can be changed at the same time

