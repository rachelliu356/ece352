.equ  TIMER_BASE,      0xFF202000
.equ  TIMER_STATUS,    0
.equ  TIMER_CONTROL,   4
.equ  TIMER_PERIODL,   8
.equ  TIMER_PERIODH,   12
.equ  TIMER_SNAPL,     16
.equ  TIMER_SNAPH,     20
.equ  TICKSPERSEC,     100000000

.equ JTAG_UART_BASE, 0xFF201000
.equ RR, 0
.equ TR, 0
.equ CSR, 4

/*    Subroutine to display a four-bit quantity as a hex digits (from 0 to F) 
      on one of the six HEX 7-segment displays on the DE1_SoC.
*
 *    Parameters: the low-order 4 bits of register a0 contain the digit to be displayed
		  if bit 4 of a1 is a one, then the display should be blanked
 *    		  the low order 3 bits of a0 say which HEX display number 0-5 to put the digit on
 *    Returns: a0 = bit patterm that is written to HEX display
 */

 #Updated to Nios V by Jonathan Schneider, July, 2024

.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030

.text
	.align	2
	.globl	myrandom
	
.global _start
_start:
	li sp, 0x20000
	li s0, TIMER_BASE
    li s1, JTAG_UART_BASE
    li s3, 0 # assume we add alternating digits and spaces, s3 = 1 means last char was a digit

	la t0, line
    li t1, 50
    li t2, 32 # ASCII for space
	
initial_loop:
	sb t2, 0(t0)
    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, initial_loop # put 50 spaces into line
	
	reset_timer:
	# stop the timer
	li    t1, 0x8 # 0x8 = 1000, write 1 to STOP
	sw    t1, TIMER_CONTROL(s0)

	li   t0, TICKSPERSEC # split period into two 16-bit halves
	li   t2, 0xFFFF
	and  t1, t0, t2
	sw   t1, TIMER_PERIODL(s0)
	srli t1, t0, 16
	sw   t1, TIMER_PERIODH(s0)

	# tell the counter to start over automatically and start counting
	li    t1, 0x6  # 0x6 = 0110, write 1 to START and to CONT
	sw    t1, TIMER_CONTROL(s0)

li s5, -1 # counter for Task 2.1
MAIN_POLL: 
	addi s5, s5, 1 # increment counter after every main poll loop
	mv   s6, s5             
	li   s7, 0 # hex display number
hex_loop:
	andi a0, s6, 0xF # lowest 4 bits (digit 0-8)
	mv   a1, s7 # which HEX display
	call HEX_DISP
	srli s6, s6, 4 # shift right so last 4 bits (digit) is removed
	addi s7, s7, 1
	li   t0, 6
	blt  s7, t0, hex_loop # loop 6 times for the 6 hex displays
	
	lw    t1, TIMER_STATUS(s0)   # check if the TO bit of the status register is 1
	andi  t1, t1, 0x1
	beq   t1, x0, check_key_pressed # if 1 sec has not passed, check if a key was pressed
	
	# times up, clear the TO bit and check if left char was cleared or not
	sw    x0, TIMER_STATUS(s0)
	
	la t1, line
    lbu t0, 0(t1) # leftmost character
    li t2, 32 # ASCII for space
    bne t0, t2, game_over # left char was not cleared, so game over
	
	# last char was cleared, so shift line
	li t3, 49
	shift_loop:
	lbu t0, 1(t1)
    sb t0, 0(t1) # shift, line[i] = line[i+1]
    addi t1, t1, 1
    addi t3, t3, -1
    bnez t3, shift_loop # loop 49 times
	
	li s4, 32 # ASCII for space
	beqz s3, add_digit # if s3 == 1, then last char added was a digit so we add a space
	li s3, 0
	j add_char
	
	# if last char added was a space, generate a random number
	add_digit: 
	li s3, 1
    call myrandom
	andi a0, a0, 15 # keep last 4 bits
	li t2, 10
	blt a0, t2, is_digit # random number is 0 - 9 -> already a digit
	addi a0, a0, -9  # take difference between number and 9 if it is > 9
	is_digit:
	addi s4, a0, '0' # convert to ASCII
	
	add_char:
	sb s4, 0(t1)
	call put_line
	
	check_key_pressed:
	lw t0, RR(s1) # data register
	li t2, 0x8000 # 15th bit - VALID bit
	and t3, t0, t2 # check if data valid
	beqz t3, MAIN_POLL # nothing typed, keep polling
	andi t0, t0, 0xFF # received character
	li t2, 32
	beq t0, t2, MAIN_POLL # if space was pressed, ignore and keep polling

	# non-space key pressed, remove all instances of that char
	la t1, line
	li t3, 50 # counter, loop over entire line
	li t4, 32 # ASCII for space
remove_char:
    lbu t5, 0(t1) # get first char in line
    bne t5, t0, not_same
    sb  t4, 0(t1) # replace with space
not_same:
    addi t1, t1, 1
    addi t3, t3, -1 # counter
    bnez t3, remove_char # loop over entire line
    call put_line
    j MAIN_POLL
	
game_over:
	li    t1, 0x8      
	sw    t1, TIMER_CONTROL(s0)
	
	li    t0, 100
	divu  s6, s5, t0
	li   s7, 0 # hex display number
hex_loop_end:
	andi a0, s6, 0xF # lowest 4 bits (digit 0-8)
	mv   a1, s7 # which HEX display
	call HEX_DISP
	srli s6, s6, 4 # shift right so last 4 bits (digit) is removed
	addi s7, s7, 1
	li   t0, 6
	blt  s7, t0, hex_loop_end # loop 6 times for the 6 hex displays
	
	la t0, game_over_str
print_game_over:
    lbu a0, 0(t0)
    beqz a0, inf
    call put_c
    addi t0, t0, 1
    j print_game_over
inf:
	j inf
	
	
myrandom:
	li	a5,-14671872
	lw	a0,256(a5)
	srai	a5,a0,8
	andi	a5,a5,255
	xor	a0,a5,a0
	ret
	
put_c: 
	li a1, JTAG_UART_BASE
wait:
	lw a2, CSR(a1) # load CSR value
	srli a2, a2, 16
	beq a2, x0, wait # loop until there is space
	sw a0, TR(a1) # write to UART TR
	ret

put_line:
    addi sp, sp, -16  # allocate (keeps 16-byte alignment)
    sw   ra, 0(sp) # save ra
    li   a0, '\r'
    call put_c
    la   t0, line
    li   t1, 50
pl_loop:
    lbu  a0, 0(t0)
    call put_c
    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, pl_loop
    lw   ra, 0(sp) # restore ra
    addi sp, sp, 16 # deallocate
    ret

HEX_DISP:   
		addi sp, sp, -16
		sw s0,0(sp)
		sw s1,0x4(sp)
		sw s2,0x8(sp)
		sw s3,0xC(sp)
	
		la   s0, BIT_CODES         # starting address of the bit codes
	    andi     s1, a0, 0x10	       # get bit 4 of the input into r6
	    beq      s1, zero, not_blank 
	    mv      s2, zero
	    j       DO_DISP
not_blank:  andi     a0, a0, 0x0f	   # r4 is only 4-bit
            add      a0, a0, s0        # add the offset to the bit codes
            lb      s2, 0(a0)         # index into the bit codes

#Display it on the target HEX display
DO_DISP:    
			la       s0, HEX_BASE1         # load address
			li       s1,  4
			blt      a1,s1, FIRST_SET      # hex4 and hex 5 are on 0xff200030
			sub      a1, a1, s1            # if hex4 or hex5, we need to adjust the shift
			addi     s0, s0, 0x0010        # we also need to adjust the address
FIRST_SET:
			slli     a1, a1, 3             # hex*8 shift is needed
			addi     s3, zero, 0xff        # create bit mask so other values are not corrupted
			sll      s3, s3, a1 
			li     	 a0, -1
			xor      s3, s3, a0  
    		sll      a0, s2, a1            # shift the hex code we want to write
			lw    	 a1, 0(s0)             # read current value       
			and      a1, a1, s3            # and it with the mask to clear the target hex
			or       a1, a1, a0	           # or with the hex code
			sw    	 a1, 0(s0)		       # store back
END:			
			mv 		 a0, s2				   # put bit pattern on return register
			
			
			lw s0,0(sp)
			lw s1,0x4(sp)
			lw s2,0x8(sp)
			lw s3,0xC(sp)
			addi sp, sp, 16
			ret

.data
line: .skip 50 
game_over_str: .asciz  "\r\nGAME OVER\r\n"
BIT_CODES:  .byte     0b00111111, 0b00000110, 0b01011011, 0b01001111
			.byte     0b01100110, 0b01101101, 0b01111101, 0b00000111
			.byte     0b01111111, 0b01100111, 0b01110111, 0b01111100
			.byte     0b00111001, 0b01011110, 0b01111001, 0b01110001
			
			.end 
			

	
	