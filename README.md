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
- qemu/
  - contains code specific to qemu build
    - startup code
    - linker script
    - uart driver
- tools/
  - python tools to initially compile forth into threaded code
    - Compiler.py - compile forth to threaded code
    - AssemblySrcParser.py - a library needed by Compiler.py, parses assembly word header macros in vm.S to link new words into the dictionary
    - ResolveTraceAddress.py - a simple debugging tool that will parse the .map file generated and match printed addresses to the name of words
    - test_e2e.py
      - run tests on either a connected MCU over serial or a qemu instance. If `--hardware` is passed the tests will be run on a minicom instance, else it will spawn a qemu process
      - imports `hardware_test_runner/bootloader.py` if --hardware is passed
    - hardware_test_runner/
      - autoflash.sh - automatically flash a connected MCU, pass flags `--elf`, `--wchisp` and `--bootloader` with the locations of the elf file to flash, the whchisp tool, and the bootloader.py script respectively
      - bootloader.py - use raspberry pi GPIO pins to put a connected chip into bootloader mode and reset it. Wire GPIO pin 20 to the boot pad and GPIO pin 21 to the reset pad
    - forth_shell/
      - a rust program to connect to the microcontroller over serial, basically the same as using minicom but it calls forth words in the background (showWords and showLastWord) to learn the contents of memory, which it displays in panes on the right. You can scroll through the list of words and inspect the memory of each one. It also converts addresses of word implementations into their assembler label. Not required to use the forth - a debugging tool.
- Dockerfile
  - Dockerfile builds a docker container containing the cross compiler risc-v gcc toolchain, make, and python
  - When this file is changed and pushed to github, a CI job will build the new container and publish it to ghcr.io/jimmarshall35/risc-v-forth/toolchain:main
  - The container is then used in the build CI job, and can be used for local development
- flash.sh
  - script to flash the MCU using the wchisp tool
- wchisp
  - binary of open source wchisp flashing tool
- serial.sh
  - open minicom to communicate with MCU
- run_qemu.sh
  - run the qemu build (doesn't currently work)
- Makefile
  - top level (and only) makefile
  - builds targets Forth and QEMUForth

# QEMU

- In addition to the microcontroller version a qemu version is built sharing the same core forth code
- The advantage of the qemu version is it's easily debugable with gdb and can easily be used for testing in CI

# Boards tested on:
- [Adafruit dev board](https://www.adafruit.com/product/5996?srsltid=AfmBOorn9M97Aqk2NByeKiGZFeXM_srwdjtc68xdrYgTiuJvrQ0qo3R4)
