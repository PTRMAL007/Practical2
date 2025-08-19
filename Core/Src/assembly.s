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

main_loop:
	@ Read button states from GPIOA IDR
	LDR R0, GPIOA_BASE
	LDR R3, [R0, #0x10]		@ Read GPIOA IDR
	LDR R1, GPIOB_BASE

	@ Check SW2 first (pattern override)
	MOVS R4, #4
	TST R3, R4
	BEQ button2

	@ Check SW3 (freeze)
	MOVS R4, #8
	TST R3, R4
	BEQ button3

	@ Check SW0 and SW1 for increment and timing modifications
	@ Set default increment value
	LDR R6, =increment_value
	MOVS R5, #1
	STR R5, [R6]

	@ Check SW0 for increment by 2
	MOVS R4, #1
	TST R3, R4
	BNE check_sw1
	MOVS R5, #2
	STR R5, [R6]

check_sw1:
	@ Set delay based on SW1
	MOVS R4, #2
	TST R3, R4
	BNE use_short_delay
	LDR R0, LONG_DELAY_CNT    @ 0.7 seconds
	B default
	
use_short_delay:
	LDR R0, SHORT_DELAY_CNT   @ 0.3 seconds
	B default

@ By default, the LEDs should increment by 1 every 0.7 seconds 
@ (with the count starting from 0)
default:
    @ Load current table pointer
    LDR R6, =table_pointer
    LDR R7, [R6]              @ R7 = current position in table
    
    @ Get LED pattern from table
    LDR R2, [R7]              @ Load current pattern into R2
    
    @ Load increment value
    LDR R4, =increment_value
    LDR R5, [R4]              @ Load increment (1 or 2)
    
    @ Advance table pointer by increment value
    LSLS R5, R5, #2           @ Multiply by 4 (word size)
    ADDS R7, R7, R5           @ Advance pointer
    
    @ Check if we've reached end of table
    LDR R4, =BlinkTableEnd
    CMP R7, R4
    BGE reset_table           @ If at or past end, reset
    B store_pointer
    
reset_table:
    @ Reset to beginning of table
    LDR R7, =BlinkTable
    
store_pointer:
    STR R7, [R6]              @ Store updated pointer
    B write_leds_with_delay

@ While SW2 is being held down, the LED pattern should
@ be set to 0xAA. Naturally, the pattern should stay at 0xAA 
@ until SW2 is released, at which point it will continue counting
@ normally from there
button2:
	MOVS R2, #0xAA
	B write_leds_no_delay

@ While SW3 is being held down, the pattern should freeze, 
@ and then resume counting only when SW3 is released
button3:
	@ Keep current LED state (don't update table pointer)
	LDR R6, =table_pointer
	LDR R7, [R6]
	LDR R2, [R7]              @ Load current pattern (frozen)
	B write_leds_no_delay

write_leds_with_delay:
	@ Write pattern to LEDs
	STR R2, [R1, #0x14]
	
	@ Delay
delay_loop:
    SUBS R0, R0, #1
    BNE delay_loop
    
    B main_loop

write_leds_no_delay:
	@ Write pattern to LEDs without advancing table
	STR R2, [R1, #0x14]
	
	@ Short delay to prevent button bounce
	LDR R0, =500000
short_delay:
    SUBS R0, R0, #1
    BNE short_delay
    
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

BlinkTable:			.word 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
BlinkTableEnd:		
table_pointer: 		.word BlinkTable
increment_value: 	.word 1