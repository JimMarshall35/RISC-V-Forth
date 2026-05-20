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

- Previously this project was in a different repo, and built an image that was runnable in qemu
  - This repo had a script that ran end to end tests on the qemu build, which ran in CI
  - The forth has changed a bit since then and has notions of flash and ram regions baked in, so qemu build needs changing before it will work
- I want to reinstate this qemu build, and have this repo produce both a microcontroller and a *working* qemu build
- The advantage of the qemu version is it's easily debugable with gdb and can easily be used for testing in CI

# Hardware testing

- What i ultimately want to do is have a self hosted github runner that will flash the mcu in a fully automated manner and run pre-merge tests
  - it will use the same pexpect python library as the qemu test script did, but will interface with a minicom process instead of qemu
  - adafruit dev board has boot and reset pads underneath - I have accidently ripped mine off, need to order more dev boards
- Another docker container will be the test runner, and it will contain:
  - wchisp
  - minicom
  - python
    - pexpect library
  - python script to flash mcu
    - manipulate boot and reset pins with raspberry pi gpio to put chip into bootloader mode
    - flash with chisp
    - reset mcu
  - python script to run tests
    - start minicom process
    - connect to it with pexpect
    - run tests - send input and expect certain output from stdin/out
      - should also be able to reset the MCU via the reset pin in order to test flash programming
      - tests could also involve reading raspberry pi gpio pins
    - report results

# Boards tested on:
- [Adafruit dev board](https://www.adafruit.com/product/5996?srsltid=AfmBOorn9M97Aqk2NByeKiGZFeXM_srwdjtc68xdrYgTiuJvrQ0qo3R4)
