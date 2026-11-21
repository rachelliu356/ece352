# Print ten in octal, hexadecimal, and decimal
# Use the following C functions:
#     printHex ( int ) ;
#     printOct ( int ) ;
#     printDec ( int ) ;

.global main

main:
    addi sp, sp, -16      # decrement stack, keep 16-byte aligned because RISC-V calling conventions
    sw   ra, 0(sp)       # save ra

    li   a0, 10
    call printOct
    li   a0, 10
    call printHex
    li   a0, 10
    call printDec

    lw   ra, 0(sp)       # restore return address
    addi sp, sp, 16       # increment stack
    ret
