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

main_loop:
	@ Read button states from GPIOA IDR
	LDR R0, GPIOA_BASE
	LDR R3, [R0, #0x10]		@ Read GPIOA IDR
	LDR R1, GPIOB_BASE

	@ Check each button and set LEDs accordingly
	@ Button 0
	MOVS R4, #1
	TST R3, R4
	BEQ button0

	@ Button 1
	MOVS R4, #2
	TST R3, R4
	BEQ button1

	@ Button 2
	MOVS R4, #4
	TST R3, R4
	BEQ button2

	@ Button 3
	MOVS R4, #8
	TST R3, R4
	BEQ button3

@ By default, the LEDs should increment by 1 every 0.7 seconds 
@ (with the count starting from 0)
default:
	@ All LEDs off for default
	MOVS R2, #0x00
	B write_leds

@ While SW0 is being held down, the LEDs should change to 
@ increment by 2 every 0.7 seconds
button0:
	@ Half on, half off for button 0
	MOVS R2, #0x0F
	B write_leds

@ While SW1 is being held down, the increment timing 
@ should change to every 0.3 seconds
button1:
	@ All LEDs on for button 1
	MOVS R2, #0xFF
	B write_leds

@ While SW2 is being held down, the LED pattern should
@ be set to 0xAA. Naturally, the pattern should stay at 0xAA 
@ until SW2 is released, at which point it will continue counting
@ normally from there
button2:
	@ LED 2 on for button 2
	MOVS R2, #0x02
	B write_leds

@ While SW3 is being held down, the pattern should freeze, 
@ and then resume counting only when SW3 is released
button3:
	@ LED 3 on for button 3
	MOVS R2, #0x04
	B write_leds

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

BlinkTable:			.word 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80  @ Example 8-step pattern
BlinkTableEnd :		
table_pointer: 		.word BlinkTable
counter_value: 		.word 0
delay_counter: 		.word 0
increment_value: 	.word 1