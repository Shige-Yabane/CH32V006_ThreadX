/*
 * ThreadX-aware CH32V006 RV32E Software IRQ wrapper.
 * SysTick_Handler only requests this deferred context switch after its timer
 * processing has finished.
 */

    .section .text
    .align  2
    .extern _tx_thread_context_save
    .extern _tx_thread_context_restore
    .extern _tx_thread_current_ptr
    .extern _tx_thread_execute_ptr
    .extern _tx_thread_system_state
    .extern threadx_software_irq_entry_count
    .extern threadx_software_irq_switch_count
    .extern threadx_software_irq_stale_count
    .extern tx_diag_software_stage
    .global SW_Handler
    .type   SW_Handler, @function
SW_Handler:
    /* The entire deferred switch stays non-reentrant until its final mret. */
    csrci   mstatus, 0x08

    /* Complete the frame before using GPRs or calling ThreadX. */
    addi    sp, sp, -20*4
    sw      ra, 1*4(sp)
    sw      gp, 2*4(sp)
    sw      tp, 3*4(sp)
    sw      t0, 4*4(sp)
    sw      t1, 5*4(sp)
    sw      t2, 6*4(sp)
    sw      s0, 7*4(sp)
    sw      s1, 8*4(sp)
    sw      a0, 9*4(sp)
    sw      a1, 10*4(sp)
    sw      a2, 11*4(sp)
    sw      a3, 12*4(sp)
    sw      a4, 13*4(sp)
    sw      a5, 14*4(sp)
    csrr    t0, mepc
    sw      t0, 15*4(sp)
    csrr    t0, mstatus
    sw      t0, 16*4(sp)
    li      t0, 1
    sw      t0, 0*4(sp)
    la      t0, tx_diag_software_stage
    li      t1, 1
    sw      t1, 0(t0)

    /*
     * CH32V00x retains the Software_IRQn pending bit after vector entry.
     * Acknowledge this request after preserving t0/t1.  Unlike CH32V203,
     * leaving it pending blocks further SysTick delivery on this PFIC.
     */
    lui     t0, 0xe000e
    li      t1, 0x4000
    sw      t1, 0x280(t0)
    la      t0, tx_diag_software_stage
    li      t1, 2
    sw      t1, 0(t0)

    la      t0, threadx_software_irq_entry_count
    lw      t1, 0(t0)
    addi    t1, t1, 1
    sw      t1, 0(t0)

    la      t0, _threadx_software_switch_active
    li      t1, 1
    sw      t1, 0(t0)

    /* Ignore a stale pending request; no saved thread frame is needed. */
    la      t0, _tx_thread_current_ptr
    lw      t0, 0(t0)
    beqz    t0, .Lsw_no_switch
    la      t1, _tx_thread_execute_ptr
    lw      t1, 0(t1)
    beq     t0, t1, .Lsw_no_switch

    la      t0, tx_diag_software_stage
    li      t1, 3
    sw      t1, 0(t0)
    la      t0, threadx_software_irq_switch_count
    lw      t1, 0(t0)
    addi    t1, t1, 1
    sw      t1, 0(t0)
    call    _tx_thread_context_save

    /* This is a first-level deferred IRQ; avoid stale nesting state. */
    la      t0, _tx_thread_system_state
    li      t1, 1
    sw      t1, 0(t0)
    la      t0, tx_diag_software_stage
    li      t1, 4
    sw      t1, 0(t0)
    j       _tx_thread_context_restore

.Lsw_no_switch:
    la      t0, tx_diag_software_stage
    li      t1, 5
    sw      t1, 0(t0)
    la      t0, threadx_software_irq_stale_count
    lw      t1, 0(t0)
    addi    t1, t1, 1
    sw      t1, 0(t0)
    la      t0, _threadx_software_switch_active
    sw      zero, 0(t0)
    lw      ra, 1*4(sp)
    lw      gp, 2*4(sp)
    lw      tp, 3*4(sp)
    lw      t2, 6*4(sp)
    lw      s0, 7*4(sp)
    lw      s1, 8*4(sp)
    lw      a0, 9*4(sp)
    lw      a1, 10*4(sp)
    lw      a2, 11*4(sp)
    lw      a3, 12*4(sp)
    lw      a4, 13*4(sp)
    lw      a5, 14*4(sp)
    lw      t0, 4*4(sp)
    lw      t1, 5*4(sp)
    addi    sp, sp, 20*4
    mret
    .size   SW_Handler, .-SW_Handler

    .section .bss
    .align  2
    .global _threadx_software_switch_active
_threadx_software_switch_active:
    .word   0
