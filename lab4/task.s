.text
	.align	2
	.global	myrandom
myrandom:
	li	a5,-14671872
	lw	a0,256(a5)
	srai	a5,a0,8
	andi	a5,a5,255
	xor	a0,a5,a0
	ret
	.global	waithalfasec
waithalfasec:
	slli	a5,a0,1
	add	a5,a5,a0
	slli	a5,a5,6
	sub	a5,a5,a0
	slli	a5,a5,2
	sub	a5,a5,a0
	slli	a5,a5,4
	sub	a5,a5,a0
	slli	a5,a5,5
	add	a5,a5,a0
	slli	a5,a5,7
	li	a4,-14671872
	li	a3,8
	sw	a3,4(a4)
	sw	zero,0(a4)
	li	a3,65536
	addi	a3,a3,-1
	and	a3,a5,a3
	sw	a3,8(a4)
	srli	a5,a5,16
	sw	a5,12(a4)
	li	a5,4
	sw	a5,4(a4)
.L3:
	lw	a5,0(a4)
	andi	a5,a5,1
	beq	a5,zero,.L3
	li	a5,-14671872
	sw	zero,0(a5)
	ret
.data
	.align	2
hexseg7:
	.ascii	"?\006[Ofm}\007\177gw|9^yq"
	.align 2
seq_in:
	.space 11
.text
	.align 2
	.global	HEXDISPLAY
HEXDISPLAY:
	lui	a4,%hi(hexseg7)
	addi	a4,a4,%lo(hexseg7)
	srli	a5,a0,8
	add	a5,a4,a5
	lbu	a5,0(a5)
	slli	a5,a5,16
	andi	a3,a0,15
	add	a3,a4,a3
	lbu	a3,0(a3)
	or	a5,a5,a3
	srli	a0,a0,4
	andi	a0,a0,15
	add	a4,a4,a0
	lbu	a4,0(a4)
	slli	a4,a4,8
	or	a5,a5,a4
	li	a4,-14680064
	sw	a5,32(a4)
	ret

	.global _start
_start:
	li sp, 0x10000
##########################################
# ADD YOUR CODE STARTING FROM HERE ###########################################

StartOver:
	li   s3, 1
SimonLOOP:
	la a0, seq_in # *seq_in
	mv a1, s3 # seq_n
	call SimonGenerate
	li s4, 0 # counter
	la s5, seq_in
	li s6, 5 # stop main loop when seq_n = 11 (right after completing seq_n = 10)
	mv  a0, s3
	call HEXDISPLAY # display seq_n
	li a0, 1
	call waithalfasec
DisplayLEDLOOP:
	li t0, 0xff200000
	lbu  t1, 0(s5)
	li t2, 1
	sll t1, t2, t1 # shift 1 to the left by the current number in seq_in
	sw t1, 0(t0)
	li a0, 2
	call waithalfasec
	li t0, 0xff200000
	sw zero, 0(t0)
	li a0, 2
	call waithalfasec
	addi s4, s4, 1 # increment counter
	addi s5, s5, 1 # increment seq_in address by 1 (1 char is 1 byte)
	bne s3, s4, DisplayLEDLOOP # check if all chars in array were displayed
DoneDisplay:
	li t0, 0xff200000
	sw zero, 0(t0)
	li s4, 0 # counter
	la s5, seq_in
WaitButtonLOOP:
	lbu a0, 0(s5)
	call WaitForButton
	addi s4, s4, 1 # increment counter
	addi s5, s5, 1 # increment seq_in address by 1 (1 char is 1 byte)
	beq a0, zero, Unsuccessful # wrong button pressed
	bne s4, s3, WaitButtonLOOP # check for end of sequence
Successful:
	li a0, 0xFAB
	call HEXDISPLAY
	li a0, 6
	call waithalfasec
	addi s3, s3, 1
	ble s3, s6, SimonLOOP # check if seq_n > 10
	j EndRound
Unsuccessful:
	li a0, 0xBAD
	call HEXDISPLAY
	li a0, 6
	call waithalfasec
	j StartOver
EndRound:
	li a0, 0xFABFAB
	call HEXDISPLAY
	li a0, 10
	call waithalfasec
	j InfLOOP # comment out, just for testing purposes
	j StartOver
InfLOOP:
	j InfLOOP
	

SimonGenerate:
	addi sp, sp, -16
	sw ra, 0(sp)
	sw s0, 4(sp)
	sw s1, 8(sp)
	sw s2, 12(sp)
	mv s0, a0 # first input, pointer to an array of up to 11 characters
	mv s1, a1 # second input, number up to 10
	li s2, 0 # counter
	bge  s2, s1, DoneGenerate # check if second input is 0
RandomLOOP:
	call myrandom
	andi a0, a0, 0b11 #isolate last two bits for number from 0-3
	sb a0, 0(s0) # a0 has a random number 0-3, store byte because it is array of characters
	addi s0, s0, 1 # increment array pointer, one char is 1 byte
	addi s2, s2, 1 # increment counter
	bne s2, s1, RandomLOOP
DoneGenerate:	
	lw ra, 0(sp)
	lw s0, 4(sp)
	lw s1, 8(sp)
	lw s2, 12(sp)
	addi sp, sp, 16
	ret
	
WaitForButton:
	addi sp, sp, -4
	sw ra, 0(sp)
	li a1, 0xff200050

ReadEdge:
	lw a2, 12(a1) # read button PIT EDGE
	andi a4, a2, 0xF # check bit 0-3
	beq a4, zero, ReadEdge

pressed:
	li   t0, 1
	sll  t0, t0, a0 # isolate the bit identified in which
	and a3, a2, t0 # check the which bit in DR
	sw a2, 12(a1)   # write same value back to PIT EDGE to clear it
	beq a3, zero, WrongButton
	addi a0, zero, 1
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

WrongButton:
	addi a0, zero, 0
	lw ra, 0(sp)
	addi sp, sp, 4
	ret
	
	
	
	
