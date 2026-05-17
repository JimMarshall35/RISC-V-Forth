.include "defines.S"
.global puts
.global putc
.global getc
.global getc_block
.global initUart

#define DATA_R_OFFSET 4
#define DATA_STATUS_OFFSET 0
#define RXNE_BIT 5
#define TXE_BIT 6

.text

putc:
    # Args:
    # a0 - character to output
    # a1 - UART base address

    # wait until TXE_BIT bit is set, indicating a value can be written to data reg
    andi a0, a0, 0xff
1:
    lw t0, DATA_STATUS_OFFSET(a1)
    li t1, (1 << TXE_BIT)
    and t2, t1, t0
    beq zero, t2, 1b

    sb a0, DATA_R_OFFSET(a1)
    ret

getc_block:
    # Args:
    # a0 - UART base address
    # Returns:
    # a0 - char from uart

    # stash UART base address in t3
    mv t3, a0

    # wait until RXNE bit is set, indicating a value can be read from data reg
1:
    lw t0, DATA_STATUS_OFFSET(a0)
    li t1, (1 << RXNE_BIT)
    and t2, t1, t0
    beq zero, t2, 1b

    # load return value with value read from uart
    lbu a0, DATA_R_OFFSET(a0)

    # clear RXNE bit
    lw t0, DATA_STATUS_OFFSET(t3)
    li t1, ~(1 << RXNE_BIT)
    and t2, t0, t1
    sw t2, DATA_STATUS_OFFSET(t3)
    ret

puts:
    # Args:
    # a0 - string address
    # a1 - UART base address
    # while string byte not null
    SaveReturnAddress
    mv t3, a0
1:
    lb t0, 0(t3)
    beq t0, zero, 2f
    mv a0, t0
    call putc
    addi t3, t3, 1
    j 1b
2:
    RestoreReturnAddress
    ret


 