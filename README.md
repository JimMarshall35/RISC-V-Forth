# A Forth for the CH32V203G6 microcontroller

This is a forth written in assembly and forth for CH32 microcontroller. You can connect to it over uart using a usb serial adaptor and access a forth repl to write and execute forth code on the microcontroller.
It relies on a python script that compiles forth source code into threaded code, which bootstraps the forth interpreter and compiler.

# Files

- Forth/
  - The core assembly and forth code, should largely portable between different risc-v chips
    - Implementations of primitive words in vm.S
    - String helper functions in utils.S
    - UART driver in uart.S (arguably belongs in ch32)
    - Important macros for threaded code execution in VmMacros.S
    - UART base address define in defines.S (again, arguably ch32 specific)
    - Forth code for the forth interpreter and compiller in system.forth
      - compiled to threaded code in system.S using the compiler tool
    - Forth code for a 32bit riscv assembler in assembler.forth ( unused and incomplete )
- ch32/
  - non portable code specific to the ch32v203G6, code to initialize the microcontroller clock and uart
    - C code taken from https://github.com/openwch/ch32v20x/tree/main
    - in time i hope to replace it with a much simpler and smaller asm implementation
- tools/
  - python tools to initially compile forth into threaded code
    - Compiler.py - compile forth to threaded code
    - AssemblySrcParser.py - a library needed by Compiler.py, parses assembly word header macros in vm.S to link new words into the dictionary
    - ResolveTraceAddress.py - a simple debugging tool that will parse the .map file generated and match printed addresses to the name of words
  - forth_shell/
    - a rust program to connect to the microcontroller over serial, basically the same as using minicom but will be extended with new features such as debugging, will always remain an optional enhancement, with the forth being usable with just a serial communication terminal like minicom


# Boards tested on:
- [Adafruit dev board](https://www.adafruit.com/product/5996?srsltid=AfmBOorn9M97Aqk2NByeKiGZFeXM_srwdjtc68xdrYgTiuJvrQ0qo3R4)
