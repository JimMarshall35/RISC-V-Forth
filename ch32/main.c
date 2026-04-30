/********************************** (C) COPYRIGHT *******************************
 * File Name          : main.c
 * Author             : WCH
 * Version            : V1.0.0
 * Date               : 2021/06/06
 * Description        : Main program body.
 *********************************************************************************
 * Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
 * Attention: This software (modified or not) and binary are used for 
 * microcontroller manufactured by Nanjing Qinheng Microelectronics.
 *******************************************************************************/

/*
 *@Note
 *USART Print debugging routine:
 *USART1_Tx(PA9).
 *This example demonstrates using USART1(PA9) as a print debug port output.
 *
 */

#include "debug.h"

/* Global typedef */

/* Global define */

/* Global Variable */
const char* gTitleString = "RISC-V Forth CH32V203\n\r";

/*********************************************************************
 * @fn      main
 *
 * @brief   Main program.
 *
 * @return  none
 */
int main(void)
{
    USART_Printf_Init(115200);

    asm volatile (
        "li sp, %0\n\t"
        "li a1, %1\n\t"
        "mv a0, %2\n\t"
        "call puts\n\t"
        "call vm_run\n\t"
        "1:\n\t"
        "j 1b\n\t"
        :
        : "i"(RAM_END), "i"(UART_BASE_CDEF), "r"(gTitleString)
    );

    while(1)
    {
    }
}
