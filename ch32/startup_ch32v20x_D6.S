;/********************************** (C) COPYRIGHT *******************************
;* File Name          : startup_ch32v20x_D6.s
;* Author             : WCH
;* Version            : V1.0.2
;* Date               : 2025/10/21
;* Description        : CH32V203F6-CH32V203F8-CH32V203G6-CH32V203G8-CH32V203K8-CH32V203C6-CH32V203C8-CH32V203G8
;*                      Startup File.
;*********************************************************************************
;* Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
;* Attention: This software (modified or not) and binary are used for 
;* microcontroller manufactured by Nanjing Qinheng Microelectronics.
*******************************************************************************/
#define R32_EXTEN_CTR 0x40023800
#define EXTEN_PLL_HSI_PRE 0x00000010 /* Bit 4 */
#define R32_RCC_CFGR0 0x40021004
#define R32_RCC_CTLR 0x40021000
#define R32_RCC_INTR 0x40021008
#define RCC_HPRE_DIV1 0x00000000 /* SYSCLK not divided */
#define RCC_PPRE2_DIV1 0x00000000 /* PPRE2 not divided */
#define RCC_PPRE1_DIV2 0x00000400 /* PPRE1 divided by 2 */
#define RCC_PLLSRC 0x00010000 /* PLL entry clock source */

#define RCC_PLLXTPRE 0x00020000 /* HSE divider for PLL entry */

#define RCC_PLLMULL 0x003C0000 /* PLLMUL[3:0] bits (PLL multiplication factor) */
#define RCC_PLLMULL12 0x00280000 /* PLL input clock*12 */
#define RCC_PLLSRC_HSI_Div2 0x00000000 /* HSI clock divided by 2 selected as PLL entry clock source */
#define RCC_PLLON 0x01000000 /* PLL enable */
#define RCC_PLLRDY 0x02000000 /* PLL clock ready flag */
#define RCC_SWS 0x0000000C /* SWS[1:0] bits (System Clock Switch Status) */
#define RCC_SW 0x00000003 /* SW[1:0] bits (System clock Switch) */
#define RCC_SW_PLL 0x00000002 /* PLL selected as system clock */

.macro or_exten_ctr val
    li t0, R32_EXTEN_CTR
    lw t0, (t0)
    li t1, \val
    or t0, t0, t1
    li t1, R32_EXTEN_CTR
    sw t0, (t1)
.endm

.macro or_rcc_ctrl val
    li t0, R32_RCC_CTLR
    lw t0, (t0)
    li t1, \val
    or t0, t0, t1
    li t1, R32_RCC_CTLR
    sw t0, (t1)
.endm

.macro and_rcc_ctrl val
    li t0, R32_RCC_CTLR
    lw t0, (t0)
    li t1, \val
    and t0, t0, t1
    li t1, R32_RCC_CTLR
    sw t0, (t1)
.endm

.macro or_rcc_cfg0 val
    li t0, R32_RCC_CFGR0
    lw t0, (t0)
    li t1, \val
    or t0, t0, t1
    li t1, R32_RCC_CFGR0
    sw t0, (t1)
.endm

.macro and_rcc_cfg0 val
    li t0, R32_RCC_CFGR0
    lw t0, (t0)
    li t1, \val
    and t0, t0, t1
    li t1, R32_RCC_CFGR0
    sw t0, (t1)
.endm


    // SystemInit in asm end
    


	.section	.init,"ax",@progbits
	.global	_start
	.align	1
_start:
	j	handle_reset

    .section    .vector,"ax",@progbits
    .align  1
_vector_base:
    .option norvc;
    .word   _start
    .word   0
    .word   NMI_Handler                /* NMI */
    .word   HardFault_Handler          /* Hard Fault */
    .word   0
    .word   Ecall_M_Mode_Handler       /* Ecall M Mode */
    .word   0
    .word   0
    .word   Ecall_U_Mode_Handler       /* Ecall U Mode */
    .word   Break_Point_Handler        /* Break Point */
    .word   0
    .word   0
    .word   SysTick_Handler            /* SysTick */
    .word   0
    .word   SW_Handler                 /* SW */
    .word   0
    /* External Interrupts */
    .word   WWDG_IRQHandler            /* Window Watchdog */
    .word   PVD_IRQHandler             /* PVD through EXTI Line detect */
    .word   TAMPER_IRQHandler          /* TAMPER */
    .word   RTC_IRQHandler             /* RTC */
    .word   FLASH_IRQHandler           /* Flash */
    .word   RCC_IRQHandler             /* RCC */
    .word   EXTI0_IRQHandler           /* EXTI Line 0 */
    .word   EXTI1_IRQHandler           /* EXTI Line 1 */
    .word   EXTI2_IRQHandler           /* EXTI Line 2 */
    .word   EXTI3_IRQHandler           /* EXTI Line 3 */
    .word   EXTI4_IRQHandler           /* EXTI Line 4 */
    .word   DMA1_Channel1_IRQHandler   /* DMA1 Channel 1 */
    .word   DMA1_Channel2_IRQHandler   /* DMA1 Channel 2 */
    .word   DMA1_Channel3_IRQHandler   /* DMA1 Channel 3 */
    .word   DMA1_Channel4_IRQHandler   /* DMA1 Channel 4 */
    .word   DMA1_Channel5_IRQHandler   /* DMA1 Channel 5 */
    .word   DMA1_Channel6_IRQHandler   /* DMA1 Channel 6 */
    .word   DMA1_Channel7_IRQHandler   /* DMA1 Channel 7 */
    .word   ADC1_2_IRQHandler          /* ADC1_2 */
    .word   USB_HP_CAN1_TX_IRQHandler  /* USB HP and CAN1 TX */
    .word   USB_LP_CAN1_RX0_IRQHandler /* USB LP and CAN1RX0 */
    .word   CAN1_RX1_IRQHandler        /* CAN1 RX1 */
    .word   CAN1_SCE_IRQHandler        /* CAN1 SCE */
    .word   EXTI9_5_IRQHandler         /* EXTI Line 9..5 */
    .word   TIM1_BRK_IRQHandler        /* TIM1 Break */
    .word   TIM1_UP_IRQHandler         /* TIM1 Update */
    .word   TIM1_TRG_COM_IRQHandler    /* TIM1 Trigger and Commutation */
    .word   TIM1_CC_IRQHandler         /* TIM1 Capture Compare */
    .word   TIM2_IRQHandler            /* TIM2 */
    .word   TIM3_IRQHandler            /* TIM3 */
    .word   TIM4_IRQHandler            /* TIM4 */
    .word   I2C1_EV_IRQHandler         /* I2C1 Event */
    .word   I2C1_ER_IRQHandler         /* I2C1 Error */
    .word   I2C2_EV_IRQHandler         /* I2C2 Event */
    .word   I2C2_ER_IRQHandler         /* I2C2 Error */
    .word   SPI1_IRQHandler            /* SPI1 */
    .word   SPI2_IRQHandler            /* SPI2 */
    .word   USART1_IRQHandler          /* USART1 */
    .word   USART2_IRQHandler          /* USART2 */
    .word   USART3_IRQHandler          /* USART3 */
    .word   EXTI15_10_IRQHandler       /* EXTI Line 15..10 */
    .word   RTCAlarm_IRQHandler        /* RTC Alarm through EXTI Line */
    .word   USBWakeUp_IRQHandler       /* USB Wake up from suspend */
    .word   USBFS_IRQHandler           /* USBFS Break */
    .word   USBFSWakeUp_IRQHandler     /* USBFS Wake up from suspend */
    .word   UART4_IRQHandler           /* UART4 */
    .word   DMA1_Channel8_IRQHandler   /* DMA1 Channel8 */

    .option rvc;
    .section    .text.vector_handler, "ax", @progbits
    .weak   NMI_Handler                /* NMI */
    .weak   HardFault_Handler          /* Hard Fault */
    .weak   Ecall_M_Mode_Handler       /* Ecall M Mode */
    .weak   Ecall_U_Mode_Handler       /* Ecall U Mode */
    .weak   Break_Point_Handler        /* Break Point */
    .weak   SysTick_Handler            /* SysTick */
    .weak   SW_Handler                 /* SW */
    .weak   WWDG_IRQHandler            /* Window Watchdog */
    .weak   PVD_IRQHandler             /* PVD through EXTI Line detect */
    .weak   TAMPER_IRQHandler          /* TAMPER */
    .weak   RTC_IRQHandler             /* RTC */
    .weak   FLASH_IRQHandler           /* Flash */
    .weak   RCC_IRQHandler             /* RCC */
    .weak   EXTI0_IRQHandler           /* EXTI Line 0 */
    .weak   EXTI1_IRQHandler           /* EXTI Line 1 */
    .weak   EXTI2_IRQHandler           /* EXTI Line 2 */
    .weak   EXTI3_IRQHandler           /* EXTI Line 3 */
    .weak   EXTI4_IRQHandler           /* EXTI Line 4 */
    .weak   DMA1_Channel1_IRQHandler   /* DMA1 Channel 1 */
    .weak   DMA1_Channel2_IRQHandler   /* DMA1 Channel 2 */
    .weak   DMA1_Channel3_IRQHandler   /* DMA1 Channel 3 */
    .weak   DMA1_Channel4_IRQHandler   /* DMA1 Channel 4 */
    .weak   DMA1_Channel5_IRQHandler   /* DMA1 Channel 5 */
    .weak   DMA1_Channel6_IRQHandler   /* DMA1 Channel 6 */
    .weak   DMA1_Channel7_IRQHandler   /* DMA1 Channel 7 */
    .weak   ADC1_2_IRQHandler          /* ADC1_2 */
    .weak   USB_HP_CAN1_TX_IRQHandler  /* USB HP and CAN1 TX */
    .weak   USB_LP_CAN1_RX0_IRQHandler /* USB LP and CAN1RX0 */
    .weak   CAN1_RX1_IRQHandler        /* CAN1 RX1 */
    .weak   CAN1_SCE_IRQHandler        /* CAN1 SCE */
    .weak   EXTI9_5_IRQHandler         /* EXTI Line 9..5 */
    .weak   TIM1_BRK_IRQHandler        /* TIM1 Break */
    .weak   TIM1_UP_IRQHandler         /* TIM1 Update */
    .weak   TIM1_TRG_COM_IRQHandler    /* TIM1 Trigger and Commutation */
    .weak   TIM1_CC_IRQHandler         /* TIM1 Capture Compare */
    .weak   TIM2_IRQHandler            /* TIM2 */
    .weak   TIM3_IRQHandler            /* TIM3 */
    .weak   TIM4_IRQHandler            /* TIM4 */
    .weak   I2C1_EV_IRQHandler         /* I2C1 Event */
    .weak   I2C1_ER_IRQHandler         /* I2C1 Error */
    .weak   I2C2_EV_IRQHandler         /* I2C2 Event */
    .weak   I2C2_ER_IRQHandler         /* I2C2 Error */
    .weak   SPI1_IRQHandler            /* SPI1 */
    .weak   SPI2_IRQHandler            /* SPI2 */
    .weak   USART1_IRQHandler          /* USART1 */
    .weak   USART2_IRQHandler          /* USART2 */
    .weak   USART3_IRQHandler          /* USART3 */
    .weak   EXTI15_10_IRQHandler       /* EXTI Line 15..10 */
    .weak   RTCAlarm_IRQHandler        /* RTC Alarm through EXTI Line */
    .weak   USBWakeUp_IRQHandler       /* USB Wakeup from suspend */
    .weak   USBFS_IRQHandler           /* USBFS */
    .weak   USBFSWakeUp_IRQHandler     /* USBFS Wake Up */
    .weak   UART4_IRQHandler           /* UART4 */
    .weak   DMA1_Channel8_IRQHandler   /* DMA1 Channel8 */

NMI_Handler:
HardFault_Handler:
Ecall_M_Mode_Handler:
Ecall_U_Mode_Handler:
Break_Point_Handler:
SysTick_Handler:
SW_Handler:
WWDG_IRQHandler:
PVD_IRQHandler:
TAMPER_IRQHandler:
RTC_IRQHandler:
FLASH_IRQHandler:
RCC_IRQHandler:
EXTI0_IRQHandler:
EXTI1_IRQHandler:
EXTI2_IRQHandler:
EXTI3_IRQHandler:
EXTI4_IRQHandler:
DMA1_Channel1_IRQHandler:
DMA1_Channel2_IRQHandler:
DMA1_Channel3_IRQHandler:
DMA1_Channel4_IRQHandler:
DMA1_Channel5_IRQHandler:
DMA1_Channel6_IRQHandler:
DMA1_Channel7_IRQHandler:
ADC1_2_IRQHandler:
USB_HP_CAN1_TX_IRQHandler:
USB_LP_CAN1_RX0_IRQHandler:
CAN1_RX1_IRQHandler:
CAN1_SCE_IRQHandler:
EXTI9_5_IRQHandler:
TIM1_BRK_IRQHandler:
TIM1_UP_IRQHandler:
TIM1_TRG_COM_IRQHandler:
TIM1_CC_IRQHandler:
TIM2_IRQHandler:
TIM3_IRQHandler:
TIM4_IRQHandler:
I2C1_EV_IRQHandler:
I2C1_ER_IRQHandler:
I2C2_EV_IRQHandler:
I2C2_ER_IRQHandler:
SPI1_IRQHandler:
SPI2_IRQHandler:
USART1_IRQHandler:
USART2_IRQHandler:
USART3_IRQHandler:
EXTI15_10_IRQHandler:
RTCAlarm_IRQHandler:
USBWakeUp_IRQHandler:
USBFS_IRQHandler:
USBFSWakeUp_IRQHandler:
UART4_IRQHandler:
DMA1_Channel8_IRQHandler:
1:
	j 1b

	.section	.text.handle_reset,"ax",@progbits
	.weak	handle_reset
	.align	1
handle_reset:
.option push 
.option	norelax 
	la gp, __global_pointer$
.option	pop 

	la sp, _eusrstack 

/* Load data section from flash to RAM */
	la a0, _data_lma
	la a1, _data_vma
	la a2, _edata
	bgeu a1, a2, 2f
1:
	lw t0, (a0)
	sw t0, (a1)
	addi a0, a0, 4
	addi a1, a1, 4
	bltu a1, a2, 1b
2:
/* Clear bss section */
	la a0, _sbss
	la a1, _ebss
	bgeu a0, a1, 2f
1:
	sw zero, (a0)
	addi a0, a0, 4
	bltu a0, a1, 1b
2:
/* Configure pipelining and instruction prediction */
    li t0, 0x1f
    csrw 0xbc0, t0
/* Enable interrupt nesting and hardware stack */
	li t0, 0x3
	csrw 0x804, t0
/* Enable global interrupt and configure privileged mode */
   	li t0, 0x88           
   	csrw mstatus, t0
/* Configure the interrupt vector table recognition mode and entry address mode */
 	la t0, _vector_base
    ori t0, t0, 3           
	csrw mtvec, t0

    //jal  SystemInit
    // SystemInit in asm begin

    #RCC->CTLR |= (uint32_t)0x00000001;
    or_rcc_ctrl 1

    #RCC->CFGR0 &= (uint32_t)0xF0FF0000;
    and_rcc_cfg0 0xF0FF0000

    #RCC->CTLR &= (uint32_t)0xFEF6FFFF;
    and_rcc_ctrl 0xFEF6FFFF

    #RCC->CTLR &= (uint32_t)0xFFFBFFFF;
    and_rcc_ctrl 0xFFFBFFFF

    #RCC->CFGR0 &= (uint32_t)0xFF00FFFF;
    and_rcc_cfg0 0xFF00FFFF
    
    #RCC->INTR = 0x009F0000;    
    li t0, R32_RCC_INTR
    li t1, 0x009F0000
    sw t1, (t0)


    #SetSysClock();
    or_exten_ctr EXTEN_PLL_HSI_PRE
    or_rcc_cfg0 RCC_HPRE_DIV1
    or_rcc_cfg0 RCC_PPRE2_DIV1
    or_rcc_cfg0 RCC_PPRE1_DIV2
    and_rcc_cfg0 ~(RCC_PLLSRC | RCC_PLLXTPRE | RCC_PLLMULL)
    or_rcc_cfg0 (RCC_PLLSRC_HSI_Div2 | RCC_PLLMULL12)
    or_rcc_ctrl RCC_PLLON
1:
    li t0, R32_RCC_CTLR
    lw t0, (t0)
    li t1, RCC_PLLRDY
    and t0, t0, t1
    beq t0, zero, 1b

    and_rcc_cfg0 ~(RCC_SW)
    or_rcc_cfg0 RCC_SW_PLL
1:
    li t0, R32_RCC_CFGR0
    lw t0, (t0)
    li t1, RCC_SWS
    and t0, t0, t1
    li t1, 8
    bne t0, t1, 1b

    // SystemInit in asm end
    


	la t0, main
	csrw mepc, t0
	mret


