ENTRY(_start)

PROVIDE(UART_BASE = 0x10000000);
MEMORY
{
    FLASH (rx) : ORIGIN = 0x80000000, LENGTH = 32K
    RAM   (rwx): ORIGIN = 0x80008000, LENGTH = 10K
}

SECTIONS
{
    .text : {
        *(.text*)
    } > FLASH

    .rodata : {
        *(.rodata*)
    } > FLASH

    _flash_free_start = .;

    .data : {
        *(.data*)
    } > RAM AT> FLASH

    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM

    _dataEnd = .;
}