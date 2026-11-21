/********** 
 * Turn on every 4th LED and rotate them, as well as increment a counter
 * shown on the 7segment displays.
 *
 * September 11 2007: Peter Yiannacouras
 * Updated for DE1/DE2 Media Computer by Ehsan Nasiri.
 * Updated November 22, 2012: Blair Fort
 * Updated July 22, 2015: Arjun Gandhi : For DE1-SoC
 * Updated June 24, 2024: Jonathan Schneider Malamud : For Nios V assembly
 *********/
 
.text

/* NOTE: writing a "1" turns the LED "ON" and a "0" turns the LED "OFF" */
.equ ADDR_7SEG,			0xFF200020
.equ ADDR_REDLEDS,		0xFF200000	/* 10 bits corresponding to 10 LEDRd starting at this address */   

.global _start

_start:


  li sp,  0x20000		/* setup the stack pointer */  
  la t0, ADDR_REDLEDS
  la t1, ADDR_7SEG
  li t2, 0x88888888		/* Turn on every 4th LED */
  li  t3, 0				/* Initialize counter to 0 */
  li t4, 0xFFFF0001		/* Initialize increment amount */

LOOP:
  li a0, 1
  mv a1, t2
  jal ROTATE_LEFT
  
  mv t2, a0 
  sw t2, 0(t0)			/* Write to Red LEDs */

  add   a0,  t3, zero		/* Set data argument for Display subroutine */ 
  add   a1,  t1, zero		/* Set address argument for Display subroutine */ 
  jal  DISPLAY				/* Write to lower 7-segment displays */

  srli  a0,  t3, 16		/* Set data argument for Display subroutine */ 
  addi  a1,  t1, 16		/* Set address argument for Display subroutine */ 
  jal  DISPLAY				/* Write to upper 7-segment displays */

  add   t3, t3, t4		/* Increment counter */
  
  li s1,  10000000
DELAY:						/* Delay loop to slow down */
  addi  s1,  s1, -1			/*   the program */
  bne   s1,  zero, DELAY
  j    LOOP

/* DISPLAY subroutine
 *  Converts a number of the form 0x1234 to that which can be displayed 
 *  on the HEX displays
 *
 * Subroutine arguments:
 * R4: the number in binary to be written to the 7-Seg
 * R5: address of the 7-Seg display
 *
 * Subroutine registers:
 * R8 : converted number
 * R9 : counter for the loop. counts from 4 to 1
 * R10: current digit to be converted
 * R11: current digit in 7-Seg form
 */
  
DISPLAY:
  /* store registers used by this subroutine to the stack */
  addi  sp,  sp,-28			/* First reserve space on the stack */ 
  sw   a0,  0(sp)			/* Storing r4 on the stack */
  sw   a1,  4(sp)			/* Storing r5 on the stack */
  sw   s0,  8(sp)			/* Storing r8 on the stack */
  sw   s1,  12(sp)			/* Storing r9 on the stack */
  sw   s2, 16(sp)			/* Storing r10 on the stack */
  sw   s3, 20(sp)			/* Storing r11 on the stack */
  sw   ra, 24(sp)			/* Storing r11 on the stack */


  li  s0,  0				/* Clear the result register */
  li  s1,  4				/* Initialize the loop counter */

DIGIT_LOOP:

  andi  s2, a0, 0x0F		/* Get the current digit */
  la s3, PATTERNS
  add s3, s3, s2
  lbu  s3, (s3)	/* Load the 7-Seg format */
  or	s0,  s0, s3		/* Include the new digit */
  
  addi sp, sp, -8
  sw a0,0(sp)
  sw a1,4(sp)
 
  li a0, 24
  mv a1, s0
  
  call ROTATE_LEFT

	mv s0, a0
	
  lw a0,0(sp)
  lw a1,4(sp)
  
  addi sp, sp, 8
  
  srli  a0,  a0, 4			/* Go to the next digit */

  addi  s1,  s1, -1			/* Decrement loop counter */
  bgtu  s1,  zero, DIGIT_LOOP	/* Loop if more digits need to be converted */ 
  
  sw s0,  0(a1)			/* Store converted digits to 7-seg display */
DISPLAY_DONE:
  /* restore registers used by this subroutine from the stack */
  lw   a0,  0(sp)			/* Loading r4 from the stack */
  lw   a1,  4(sp)			/* Loading r5 from the stack */
  lw   s0,  8(sp)			/* Loading r8 from the stack */
  lw   s1,  12(sp)			/* Loading r9 from the stack */
  lw   s2, 16(sp)			/* Loading r11 from the stack */
  lw   s3, 20(sp)			/* Loading r11 from the stack */
  lw   ra, 24(sp)			/* Storing r11 on the stack */
  addi  sp,  sp, 28			/* Lastly, free up the space on the stack */

  ret						/* Return from the subroutine */
  
  ROTATE_LEFT: #a0 is the amount to rotate, #a1 is the number to rotate
  addi  sp,  sp,-12		/* First reserve space on the stack */ 
  sw   s0,  0(sp)			/* Storing r4 on the stack */
  sw   s1,  4(sp)			/* Storing r5 on the stack */
  sw   s2,  8(sp)			/* Storing r5 on the stack */
  
  	li s0, 32
	neg s2, a0 #negate a0
	
	add s2, s0, s2 #We have 30 in s0
	
	li s1, -1
	sll s1, s1,s2 #Have the exact amount of ones needed #We have 0xc000... in s1
	
	and s0, s1, a1 #In s0 we have saved the upper bits
	
	sll s1, a1 , a0 #In s0 is the upper part of the final number
	
	srl s0, s0, s2 #We shift the upper part by the amount of bits
	
	or a0, s0, s1 #This contains the final number
	
	  
  lw   s0,  0(sp)			/* Storing r4 on the stack */
  lw   s1,  4(sp)			/* Storing r5 on the stack */
  lw   s2,  8(sp)			/* Storing r4 on the stack */

	addi  sp,  sp, 12		/* First reserve space on the stack */ 
  ret

.data
  
/* Store the 7-segment patterns starting at memory address 0x200 */
PATTERNS:
.byte  0x3f           		/* 0 */
.byte  0x06           		/* 1 */
.byte  0x5b           		/* 2 */
.byte  0x4f           		/* 3 */
.byte  0x66           		/* 4 */
.byte  0x6d           		/* 5 */
.byte  0x7d           		/* 6 */
.byte  0x07           		/* 7 */
.byte  0xff           		/* 8 */
.byte  0x6f           		/* 9 */
.byte  0x77           		/* A */
.byte  0xfc           		/* B */
.byte  0x39           		/* C */
.byte  0x5e           		/* D */
.byte  0xf9           		/* E */
.byte  0xf1           		/* F */
	
/**** END ****/ 