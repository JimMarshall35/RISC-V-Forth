# asm benchmark 
#
# 1.) initialize the serial in the same way as for forth
# 2.) wait for a '\r' character from the serial
# 3.) calculate the nth fibonacci number, where n is some large number defined at compile time
# 4.) print the number to the serial, using the same underlying routine as the '.' forth world

.global vm_run
.global vm_flags # just a fake one to satisfy the linker - not used, an implicit dependency between utils.S and vm.S

.include "defines.S"
.text

title_string: .ascii "asm benchmark\n\r"
waiting_for_cr: .ascii "waiting for carriage return...\n\r"
vm_flags: .word 0
.balign 4

.equ N, 1000000
# 0x928b54e2
fib:
    SaveReturnAddress
    li t0, 0
    li t1, 1
    li t2, N
    addi t2, t2, -2
1:
    add t3, t1, t0
    mv t0, t1
    mv t1, t3

    addi t2, t2, -1
    bne t2, zero, 1b
    mv a0, t1
    call print_int

    li a0, '\n'
    la a1, UART_BASE
    call putc

    li a0, '\r'
    la a1, UART_BASE
    call putc

    RestoreReturnAddress
    ret

vm_run:
    SaveReturnAddress
    la a1, UART_BASE
    la a0, title_string
    call puts 
1:    
    la a1, UART_BASE
    la a0, waiting_for_cr
    call puts
    la a0, UART_BASE
    call getc_block
    li t0, '\r'
    bne a0, t0, 1b
    call fib
    j 1b

    RestoreReturnAddress
    ret
