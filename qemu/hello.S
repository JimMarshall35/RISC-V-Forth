.equ RAM_END, 0x8000A800
.global _start	      # Provide program starting address


.section .text

_start:
    call main

main:
    li sp, RAM_END
    la a0, UART_BASE
    call initUart

    call vm_run

 loop:
    j loop
    
    ret
 
