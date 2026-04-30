/********************************** (C) COPYRIGHT *******************************
 * File Name          : ch32v20x_it.c
 * Author             : WCH
 * Version            : V1.0.0
 * Date               : 2023/12/29
 * Description        : Main Interrupt Service Routines.
*********************************************************************************
* Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
* Attention: This software (modified or not) and binary are used for 
* microcontroller manufactured by Nanjing Qinheng Microelectronics.
*******************************************************************************/
#include "ch32v20x_it.h"
#include "debug.h"

void NMI_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
void HardFault_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));

/*********************************************************************
 * @fn      NMI_Handler
 *
 * @brief   This function handles NMI exception.
 *
 * @return  none
 */
void NMI_Handler(void)
{
  while (1)
  {
  }
}
const char* gMTVALString  = "mtval:  ";
const char* gMEPCString   = "mepc:   ";
const char* gMCAUSEString = "mcause: ";
const char* gLineEnd = "\n\r";

/*********************************************************************
 * @fn      HardFault_Handler
 *
 * @brief   This function handles Hard Fault exception.
 *
 * @return  none
 */
void HardFault_Handler(void)
{
  asm volatile (
        "csrr t3, mepc\n\t"
        "csrr t4, mcause\n\t"
        "csrr t5, mtval\n\t"
        // print mepc
        "mv a0, %1\n\t"
        "li a1, %0\n\t"
        "call puts\n\t"
        "mv a0, t3\n\t"
        "call print_int\n\t"
        "mv a0, %3\n\t"
        "li a1, %0\n\t"
        "call puts\n\t"

        // print mcause
        "mv a0, %2\n\t"
        "li a1, %0\n\t"
        "call puts\n\t"
        "mv a0, t4\n\t"
        "call print_int\n\t"
        "mv a0, %3\n\t"
        "li a1, %0\n\t"
        "call puts\n\t"

        // print mval
        "mv a0, %4\n\t"
        "li a1, %0\n\t"
        "call puts\n\t"
        "mv a0, t5\n\t"
        "call print_int\n\t"
        "mv a0, %3\n\t"
        "li a1, %0\n\t"
        "call puts\n\t"

        "1:\n\t"
        "j 1b\n\t"
        :
        : "i"(UART_BASE_CDEF), "r"(gMEPCString), "r"(gMCAUSEString), "r"(gLineEnd), "r"(gMTVALString)
    );
}


