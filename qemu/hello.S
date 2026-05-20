.equ RAM_END, 0x8000A800
.global _start	      # Provide program starting address


.section .text

_start:
    call main

main:
    li sp, RAM_END
    la a0, UART_BASE
    call initUart

    la a1, UART_BASE
    la a0, title_string
    call puts

    call vm_run

 loop:
    j loop
    
    ret
 
title_string: .ascii "RISC-V Forth CH32V203\n\r"

