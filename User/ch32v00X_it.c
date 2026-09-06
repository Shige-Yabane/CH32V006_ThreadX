/********************************** (C) COPYRIGHT *******************************
 * File Name          : ch32v00x_it.c
 * Description        : Interrupt handlers for ThreadX main1 context recheck.
 *******************************************************************************/
#include "ch32v00X_it.h"

extern volatile uint32_t tx_diag_fault_seen, tx_diag_fault_mcause, tx_diag_fault_mepc;
extern volatile uint32_t tx_diag_fault_mtval, tx_diag_fault_mstatus, tx_diag_fault_ra;
extern volatile uint32_t tx_diag_fault_sp, tx_diag_fault_stack_ra_slot;
extern volatile uint32_t tx_diag_fault_stack_s0_slot, tx_diag_fault_stack_s1_slot;
extern volatile uint32_t tx_diag_fault_current_thread, tx_diag_fault_execute_thread;
extern volatile uint32_t tx_diag_fault_system_state, tx_diag_fault_software_switch_active;
extern void *_tx_thread_current_ptr;
extern void *_tx_thread_execute_ptr;
extern volatile uint32_t _tx_thread_system_state;
extern volatile uint32_t _threadx_software_switch_active;

void NMI_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
void HardFault_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));

void NMI_Handler(void)
{
    for (;;) { }
}

void HardFault_Handler(void)
{
    __asm volatile ("csrr %0, mcause" : "=r" (tx_diag_fault_mcause));
    __asm volatile ("csrr %0, mepc" : "=r" (tx_diag_fault_mepc));
    __asm volatile ("csrr %0, mtval" : "=r" (tx_diag_fault_mtval));
    __asm volatile ("csrr %0, mstatus" : "=r" (tx_diag_fault_mstatus));
    __asm volatile ("mv %0, ra" : "=r" (tx_diag_fault_ra));
    __asm volatile ("mv %0, sp" : "=r" (tx_diag_fault_sp));
    __asm volatile ("lw %0, -4(sp)" : "=r" (tx_diag_fault_stack_ra_slot));
    __asm volatile ("lw %0, -8(sp)" : "=r" (tx_diag_fault_stack_s0_slot));
    __asm volatile ("lw %0, -12(sp)" : "=r" (tx_diag_fault_stack_s1_slot));
    tx_diag_fault_current_thread = (uint32_t)_tx_thread_current_ptr;
    tx_diag_fault_execute_thread = (uint32_t)_tx_thread_execute_ptr;
    tx_diag_fault_system_state = _tx_thread_system_state;
    tx_diag_fault_software_switch_active = _threadx_software_switch_active;
    tx_diag_fault_seen = 1U;
    for (;;) { }
}
