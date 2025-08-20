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
	@ Read button states from GPIOA IDR (Input Data Register)
	LDR R0, GPIOA_BASE
	LDR R3, [R0, #0x10]     @ Load input data register
	
	@ Check SW3 first (freeze functionality) - bit 3
	@ Buttons are active LOW (pressed = 0), so we check if bit is clear
	MOVS R4, #8             @ Mask for SW3 (bit 3)
	TST R3, R4              @ Test if SW3 bit is set
	BNE check_sw2           @ If bit is set (not pressed), continue
	
	@ SW3 is pressed (bit is 0) - freeze pattern, just delay and loop back
	BL delay_routine
	B write_leds

check_sw2:
	@ Check SW2 (pattern 0xAA) - bit 2
	@ Buttons are active LOW
	MOVS R4, #4             @ Mask for SW2 (bit 2)
	TST R3, R4              @ Test if SW2 bit is set
	BNE check_increment     @ If bit is set (not pressed), continue with normal counting
	
	@ SW2 is pressed - set pattern to 0xAA
	MOVS R2, #0xAA          @ Set LED pattern to 0xAA
	BL delay_routine
	B write_leds

check_increment:
	@ Determine increment value based on SW0 - bit 0
	@ Buttons are active LOW
	MOVS R6, #1             @ Default increment = 1
	MOVS R4, #1             @ Mask for SW0 (bit 0)
	TST R3, R4              @ Test if SW0 bit is set
	BNE determine_delay     @ If bit is set (not pressed), keep increment = 1
	MOVS R6, #2             @ SW0 pressed (bit is 0), increment = 2

determine_delay:
	@ Determine delay based on SW1 - bit 1
	@ Buttons are active LOW
	MOVS R4, #2             @ Mask for SW1 (bit 1)
	TST R3, R4              @ Test if SW1 bit is set
	BNE use_long_delay      @ If bit is set (not pressed), use long delay (0.7s)
	BL short_delay          @ SW1 pressed (bit is 0), use short delay (0.3s)
	B update_leds

use_long_delay:
	BL long_delay

update_leds:
	@ Increment the LED pattern and wrap at 256
	ADDS R2, R2, R6         @ Add increment value to LED pattern

	@ Simple wrap-around check
	CMP R2, #255
	BLS write_leds          @ If R2 <= 255, continue to write_leds
	SUBS R2, R2, #255       @ Subtract 255
	SUBS R2, R2, #1         @ Subtract 1 more (total 256 subtraction)

write_leds:
	LDR R1, GPIOB_BASE      @ Reload GPIOB base address
	STR R2, [R1, #0x14]     @ Write to ODR (Output Data Register)
	B main_loop

@ Delay routines
delay_routine:
	@ Check which delay to use based on SW1
	LDR R0, GPIOA_BASE
	LDR R7, [R0, #0x10]     @ Read button states again (use R7 to avoid conflicts)
	MOVS R4, #2             @ Mask for SW1
	TST R7, R4              @ Test SW1
	BNE long_delay          @ If SW1 not pressed (bit set), use long delay
	B short_delay           @ SW1 pressed (bit clear), use short delay

long_delay:
	PUSH {R0, LR}           @ Save registers (minimal set)
	LDR R0, LONG_DELAY_CNT
delay_loop_long:
	SUBS R0, R0, #1
	BNE delay_loop_long
	POP {R0, PC}            @ Restore registers and return

short_delay:
	PUSH {R0, LR}           @ Save registers (minimal set)
	LDR R0, SHORT_DELAY_CNT
delay_loop_short:
	SUBS R0, R0, #1
	BNE delay_loop_short
	POP {R0, PC}            @ Restore registers and return

@ LITERALS; DO NOT EDIT
	.align
RCC_BASE: 			.word 0x40021000
AHBENR_GPIOAB: 		.word 0b1100000000000000000
GPIOA_BASE:  		.word 0x48000000
GPIOB_BASE:  		.word 0x48000400
MODER_OUTPUT: 		.word 0x5555

@ TODO: Add your own values for these delays
LONG_DELAY_CNT: 	.word 1400000    @ 0.7 seconds
SHORT_DELAY_CNT: 	.word 600000     @ 0.3 seconds
