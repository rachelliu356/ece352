/*********
 * 
 * Write the assembly function:
 *     printn ( char * , ... ) ;
 * Use the following C functions:
 *     printHex ( int ) ;
 *     printOct ( int ) ;
 *     printDec ( int ) ;
 * 
 * Note that 'a' is a valid integer, so movi a0, 'a' is valid, and you don't need to look up ASCII values.
 *********/

.global	printn
printn:
	addi sp, sp, -48 # decrement stack
	sw   ra, 0(sp)
    sw   s0, 4(sp) # save callee saved registers
    sw   s1, 8(sp)
	
	mv s0, a0 # s0 is the first argument (pointer to the string)
	
	sw   a1, 20(sp) # copy arguments (a1-7 by calling conventions) into stack
    sw   a2, 24(sp)
    sw   a3, 28(sp)
    sw   a4, 32(sp)
    sw   a5, 36(sp)
    sw   a6, 40(sp)
    sw   a7, 44(sp) # next word, 48(sp), is the caller's first stack arg (next argument that doesnt fit in a1-7)
	
	addi s1, sp, 20 # s1 is pointer to the first integer argument (pointer to the stack)

loop:
    lbu  t0, 0(s0)          # t0 is first character in string
    beqz t0, done           # if character is null: done

    lw   a0, 0(s1)          # a0 is the integer to print 
							# -> only argument for calling the printOct/Hex/Dec functions, so put in a0

    li   t1, 'O'
    beq  t0, t1, oct
    li   t1, 'H'
    beq  t0, t1, hex
    call printDec           
    addi s0, s0, 1          # increment string pointer to next character (chars = 1 byte in C)
    addi s1, s1, 4          # increment integer pointer to next int (ints = 4 bytes in C)
    j    loop

oct:
    call printOct
    addi s0, s0, 1          
    addi s1, s1, 4         
    j    loop

hex:
    call printHex
	addi s0, s0, 1         
    addi s1, s1, 4      
    j    loop

done:
    lw   ra, 0(sp) # restore ra
    lw   s0, 4(sp) # restore callee saved registers
    lw   s1, 8(sp)
    addi sp, sp, 48 # increment stack
    ret
	
