.global _start
_start:
	li sp, 0x10000
	li a0, 3
	call WaitForButton
done:
	j    done  
	
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