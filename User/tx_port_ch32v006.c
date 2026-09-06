/*******************************************************************************
 * ThreadX hardware initialization for CH32V006.
 * SysTick generates the ThreadX 100 Hz system tick from the 48 MHz HSE PLL.
 ******************************************************************************/

#include "ch32v00X.h"
#include "tx_api.h"

#define TX_DIAG_BUILD_ID  0x20260923UL

extern char _end;
extern VOID *_tx_thread_system_stack_ptr;
extern VOID *_tx_initialize_unused_memory;
extern volatile ULONG _tx_thread_system_state;
extern VOID _tx_timer_interrupt(VOID);
extern TX_THREAD *_tx_thread_current_ptr;
extern TX_THREAD *_tx_thread_execute_ptr;
/* Stored in C so MountRiver Watch can resolve their types and addresses. */
volatile ULONG threadx_software_irq_entry_count;
volatile ULONG threadx_software_irq_switch_count;
volatile ULONG threadx_software_irq_stale_count;

/* Read-only debugger diagnostics for the SysTick -> Software IRQ path. */
volatile ULONG tx_systick_irq_count;
/* Whole seconds elapsed since SysTick was enabled (for the Watch window). */
volatile ULONG tx_systick_seconds;
volatile ULONG tx_systick_ctlr_after_init;
volatile ULONG tx_systick_cmp_after_init;
volatile ULONG tx_systick_ctlr_at_irq_entry;
volatile ULONG tx_systick_cmp_at_irq_entry;
volatile ULONG tx_systick_timer_complete_count;
volatile ULONG tx_systick_switch_request_count;
volatile ULONG tx_systick_system_state_after;
volatile ULONG tx_systick_current_ptr;
volatile ULONG tx_systick_execute_ptr;
volatile ULONG tx_restore_preempt_count;
volatile ULONG tx_restore_current_count;
/* Frame-path counters written by tx_thread_schedule.S. */
volatile ULONG tx_schedule_initial_start_count;
volatile ULONG tx_schedule_interrupt_resume_count;
volatile ULONG tx_schedule_solicited_return_count;

/* Retained across a reset to diagnose the deferred-switch mret target. */
volatile ULONG tx_diag_solicited_mret_sp __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_mret_type __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_mret_mepc __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_mret_mstatus __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_return_sp __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_return_ra __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_return_current __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_return_saved_sp __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_return_stack_field __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_selected_thread __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_selected_stack_ptr __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_mret_current __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_mret_execute __attribute__((section(".noinit")));
volatile ULONG tx_diag_low_level_reached __attribute__((section(".noinit")));
volatile ULONG tx_diag_systick_ctlr_started __attribute__((section(".noinit")));
volatile ULONG tx_diag_systick_cmp_started __attribute__((section(".noinit")));
/* Progress marker inside _tx_timer_interrupt: survives an unexpected reset. */
volatile ULONG tx_diag_timer_phase __attribute__((section(".noinit")));
volatile ULONG tx_diag_initial_mstatus_after_write __attribute__((section(".noinit")));
volatile ULONG tx_diag_mstatus_before_mret __attribute__((section(".noinit")));
volatile ULONG tx_diag_systick_stage __attribute__((section(".noinit")));
volatile ULONG tx_diag_software_stage __attribute__((section(".noinit")));
volatile ULONG tx_diag_restore_stage __attribute__((section(".noinit")));
volatile ULONG tx_diag_restore_sp __attribute__((section(".noinit")));
volatile ULONG tx_diag_restore_mepc __attribute__((section(".noinit")));
volatile ULONG tx_diag_hold_reached __attribute__((section(".noinit")));
volatile ULONG tx_diag_build_id __attribute__((section(".noinit")));
volatile ULONG tx_diag_boot_count __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_stage __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_frame_type __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_frame_ra __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_mepc __attribute__((section(".noinit")));
/* Values physically loaded by the scheduler immediately before mret. */
volatile ULONG tx_diag_schedule_loaded_ra __attribute__((section(".noinit")));
volatile ULONG tx_diag_schedule_resume_sp __attribute__((section(".noinit")));
/* Progress marker for the first instruction stream after a scheduler mret. */
volatile ULONG tx_diag_shell_stage __attribute__((section(".noinit")));
volatile ULONG tx_diag_timer_thread_stage __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_return_stage __attribute__((section(".noinit")));
/* Captured by the diagnostic HardFault handler before the default reset path. */
volatile ULONG tx_diag_fault_seen __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_mcause __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_mepc __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_mtval __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_mstatus __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_ra __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_sp __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_stack_ra_slot __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_stack_s0_slot __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_stack_s1_slot __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_current_thread __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_execute_thread __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_system_state __attribute__((section(".noinit")));
volatile ULONG tx_diag_fault_software_switch_active __attribute__((section(".noinit")));
volatile ULONG tx_diag_timer_outer_s1 __attribute__((section(".noinit")));
volatile ULONG tx_diag_timer_outer_s0 __attribute__((section(".noinit")));
volatile ULONG tx_diag_timer_outer_ra __attribute__((section(".noinit")));
/* Compiler frame outside the complete system-return frame (system_suspend). */
volatile ULONG tx_diag_system_suspend_outer_s1 __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_suspend_outer_s0 __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_suspend_outer_ra __attribute__((section(".noinit")));
/* Caller frame outside _tx_thread_system_suspend (normally tx_thread_sleep). */
volatile ULONG tx_diag_system_suspend_caller_s1 __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_suspend_caller_s0 __attribute__((section(".noinit")));
volatile ULONG tx_diag_system_suspend_caller_ra __attribute__((section(".noinit")));
/* Captured from the selected short frame immediately before its mret. */
volatile ULONG tx_diag_solicited_outer_s1 __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_outer_s0 __attribute__((section(".noinit")));
volatile ULONG tx_diag_solicited_outer_ra __attribute__((section(".noinit")));
/* Last complete interrupt frame written by the Software IRQ context save. */
volatile ULONG tx_diag_context_save_current __attribute__((section(".noinit")));
volatile ULONG tx_diag_context_save_sp __attribute__((section(".noinit")));
volatile ULONG tx_diag_context_save_mepc __attribute__((section(".noinit")));
volatile ULONG tx_diag_context_save_stack_field __attribute__((section(".noinit")));

/*
 * ThreadX uses this stack while it schedules/restores a thread from the
 * deferred Software IRQ.  512 bytes was sufficient for the basic blink but
 * not for repeated timer-thread preemptions.  CH32V006 has only 8 KiB RAM,
 * unlike the 20 KiB CH32V203 reference, so retain 512 bytes and leave RAM
 * available for ThreadX's dynamically allocated timer/thread stacks.
 */
static ULONG tx_system_stack[128] __attribute__((aligned(16)));

/*
 * This is the verified C replacement for the former assembly implementation.
 * If Startup/tx_initialize_low_level.S is retained for legacy MounRiver build
 * metadata, it must be an empty stub and must not define this symbol.
 */
VOID _tx_initialize_low_level(VOID)
{
    /* Clear only for a newly downloaded diagnostic build, not after a reset. */
    if (tx_diag_build_id != TX_DIAG_BUILD_ID)
    {
        tx_diag_solicited_mret_sp = 0U;
        tx_diag_solicited_mret_type = 0U;
        tx_diag_solicited_mret_mepc = 0U;
        tx_diag_solicited_mret_mstatus = 0U;
        tx_diag_system_return_sp = 0U;
        tx_diag_system_return_ra = 0U;
        tx_diag_system_return_current = 0U;
        tx_diag_system_return_saved_sp = 0U;
        tx_diag_system_return_stack_field = 0U;
        tx_diag_schedule_selected_thread = 0U;
        tx_diag_schedule_selected_stack_ptr = 0U;
        tx_diag_solicited_mret_current = 0U;
        tx_diag_solicited_mret_execute = 0U;
        tx_diag_hold_reached = 0U;
        tx_diag_systick_ctlr_started = 0U;
        tx_diag_systick_cmp_started = 0U;
        tx_diag_timer_phase = 0U;
        tx_diag_initial_mstatus_after_write = 0U;
        tx_diag_mstatus_before_mret = 0U;
        tx_diag_systick_stage = 0U;
        tx_diag_software_stage = 0U;
        tx_diag_restore_stage = 0U;
        tx_diag_restore_sp = 0U;
        tx_diag_restore_mepc = 0U;
        tx_diag_schedule_stage = 0U;
        tx_diag_schedule_frame_type = 0U;
        tx_diag_schedule_frame_ra = 0U;
        tx_diag_schedule_mepc = 0U;
        tx_diag_schedule_loaded_ra = 0U;
        tx_diag_schedule_resume_sp = 0U;
        tx_diag_shell_stage = 0U;
        tx_diag_timer_thread_stage = 0U;
        tx_diag_system_return_stage = 0U;
        tx_diag_fault_seen = 0U;
        tx_diag_fault_mcause = 0U;
        tx_diag_fault_mepc = 0U;
        tx_diag_fault_mtval = 0U;
        tx_diag_fault_mstatus = 0U;
        tx_diag_fault_ra = 0U;
        tx_diag_fault_sp = 0U;
        tx_diag_fault_stack_ra_slot = 0U;
        tx_diag_fault_stack_s0_slot = 0U;
        tx_diag_fault_stack_s1_slot = 0U;
        tx_diag_fault_current_thread = 0U;
        tx_diag_fault_execute_thread = 0U;
        tx_diag_fault_system_state = 0U;
        tx_diag_fault_software_switch_active = 0U;
        tx_diag_timer_outer_s1 = 0U;
        tx_diag_timer_outer_s0 = 0U;
        tx_diag_timer_outer_ra = 0U;
        tx_diag_system_suspend_outer_s1 = 0U;
        tx_diag_system_suspend_outer_s0 = 0U;
        tx_diag_system_suspend_outer_ra = 0U;
        tx_diag_system_suspend_caller_s1 = 0U;
        tx_diag_system_suspend_caller_s0 = 0U;
        tx_diag_system_suspend_caller_ra = 0U;
        tx_diag_solicited_outer_s1 = 0U;
        tx_diag_solicited_outer_s0 = 0U;
        tx_diag_solicited_outer_ra = 0U;
        tx_diag_context_save_current = 0U;
        tx_diag_context_save_sp = 0U;
        tx_diag_context_save_mepc = 0U;
        tx_diag_context_save_stack_field = 0U;
        tx_diag_boot_count = 0U;
        tx_diag_build_id = TX_DIAG_BUILD_ID;
    }
    tx_diag_boot_count++;
    tx_diag_low_level_reached = 1U;

    _tx_thread_system_stack_ptr = &tx_system_stack[128];
    _tx_initialize_unused_memory = &_end;
    /* CH32 SysTick: system clock, interrupt enabled, automatic reload. */
    SysTick->CTLR = 0U;
    SysTick->SR = 0U;
    SysTick->CNT = 0U;
    SysTick->CMP = SystemCoreClock / TX_TIMER_TICKS_PER_SECOND;

    /*
     * SysTick produces the timer event.  Software_IRQn performs the deferred
     * ThreadX context switch requested by SysTick_Handler, so both PFIC
     * sources must be enabled.  Setting a pending bit alone is insufficient.
     */
    NVIC_SetPriority(SysTick_IRQn, 0xF0U);
    NVIC_SetPriority(Software_IRQn, 0xF0U);
    NVIC_EnableIRQ(SysTick_IRQn);
    NVIC_EnableIRQ(Software_IRQn);
    SysTick->CTLR = 0x0FU;
    tx_diag_systick_ctlr_started = SysTick->CTLR;
    tx_diag_systick_cmp_started = SysTick->CMP;
    tx_systick_ctlr_after_init = SysTick->CTLR;
    tx_systick_cmp_after_init = SysTick->CMP;
}

/*
 * SysTick updates the ThreadX timer state but never switches a thread in
 * this hardware IRQ.  If the selected thread changes, the PFIC Software IRQ
 * performs the saved-context switch after this handler has completed.
 */
/*
 * Use GCC's standard RISC-V machine-interrupt ABI.  Unlike the WCH fast
 * ABI, it preserves caller-saved registers across the C timer processing.
 */
void SysTick_Handler(void) __attribute__((interrupt("machine")));
void SysTick_Handler(void)
{
    /* Keep the complete ThreadX timer update non-nestable.  The pending
       Software IRQ is deliberately accepted only after this handler mret's. */
    __asm volatile ("csrci mstatus, 0x08" ::: "memory");
    tx_diag_systick_stage = 1U;
    SysTick->SR = 0U;
    tx_systick_irq_count++;
    tx_systick_ctlr_at_irq_entry = SysTick->CTLR;
    tx_systick_cmp_at_irq_entry = SysTick->CMP;
    if ((tx_systick_irq_count % TX_TIMER_TICKS_PER_SECOND) == 0U)
    {
        tx_systick_seconds++;
    }
    _tx_thread_system_state++;
    _tx_timer_interrupt();
    _tx_thread_system_state--;
    tx_systick_timer_complete_count++;
    tx_diag_systick_stage = 2U;
    tx_systick_system_state_after = _tx_thread_system_state;
    tx_systick_current_ptr = (ULONG)_tx_thread_current_ptr;
    tx_systick_execute_ptr = (ULONG)_tx_thread_execute_ptr;

    if (_tx_thread_execute_ptr != _tx_thread_current_ptr)
    {
        tx_systick_switch_request_count++;
        tx_diag_systick_stage = 3U;
        NVIC_SetPendingIRQ(Software_IRQn);
    }
    tx_diag_systick_stage = 4U;
}
