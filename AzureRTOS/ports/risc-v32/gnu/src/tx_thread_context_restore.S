/* Eclipse ThreadX - CH32V006F8P7 RV32E context restore. */

    .section .text
    .align  2
    .extern tx_restore_preempt_count
    .extern tx_restore_current_count
    .extern tx_diag_restore_stage
    .extern tx_diag_restore_sp
    .extern tx_diag_restore_mepc
    .global _tx_thread_context_restore
    .type   _tx_thread_context_restore, @function

_tx_thread_context_restore:
    csrci   mstatus, 0x08
    la      t0, tx_diag_restore_stage
    li      t1, 1
    sw      t1, 0(t0)

    la      t0, _tx_thread_system_state
    lw      t1, 0(t0)
    addi    t1, t1, -1
    sw      t1, 0(t0)
    bnez    t1, .Lrestore_full_current_sp

    la      t0, tx_diag_restore_stage
    li      t1, 2
    sw      t1, 0(t0)

    la      t0, _tx_thread_current_ptr
    lw      t1, 0(t0)
    beqz    t1, .Lrestore_idle

    la      t0, _tx_thread_preempt_disable
    lw      t2, 0(t0)
    bnez    t2, .Lrestore_no_preempt

    la      t0, _tx_thread_execute_ptr
    lw      t2, 0(t0)
    bne     t1, t2, .Lrestore_preempt

    /* No preemption: resume the interrupted current thread. */
.Lrestore_no_preempt:
    la      t0, tx_diag_restore_stage
    li      t2, 6
    sw      t2, 0(t0)
    lw      sp, 8(t1)
    j       .Lrestore_full_current_sp

.Lrestore_preempt:
    /* The interrupted thread already owns a complete frame. */
    la      t0, tx_diag_restore_stage
    li      t2, 5
    sw      t2, 0(t0)
    la      t0, _tx_thread_current_ptr
    lw      t1, 0(t0)
    la      t2, tx_restore_preempt_count
    lw      t2, 0(t2)
    addi    t2, t2, 1
    la      t0, tx_restore_preempt_count
    sw      t2, 0(t0)
    la      t0, _tx_timer_time_slice
    lw      t2, 0(t0)
    beqz    t2, .Lpreempt_no_slice
    sw      t2, 24(t1)
    sw      zero, 0(t0)
.Lpreempt_no_slice:
    la      t0, _tx_thread_current_ptr
    sw      zero, 0(t0)
    la      t0, _threadx_interrupt_return_active
    li      t1, 1
    sw      t1, 0(t0)
    j       _tx_thread_schedule

.Lrestore_idle:
    /* The idle scheduler frame was made on system SP. */
    addi    sp, sp, 20*4
    la      t0, tx_diag_restore_stage
    li      t1, 3
    sw      t1, 0(t0)
    la      t0, _threadx_interrupt_return_active
    li      t1, 1
    sw      t1, 0(t0)
    j       _tx_thread_schedule

.Lrestore_full_current_sp:
    /*
     * This return also completes a deferred PFIC Software IRQ when no
     * thread preemption was required (for example while ThreadX temporarily
     * holds preemption disabled).  Do not leave the scheduler's IRQ marker
     * set, otherwise its next entry keeps MIE disabled indefinitely.
     */
    la      t2, tx_restore_current_count
    lw      t2, 0(t2)
    addi    t2, t2, 1
    la      t0, tx_restore_current_count
    sw      t2, 0(t0)
    la      t0, _threadx_software_switch_active
    sw      zero, 0(t0)

    lw      t0, 15*4(sp)
    la      t1, tx_diag_restore_sp
    sw      sp, 0(t1)
    la      t1, tx_diag_restore_mepc
    sw      t0, 0(t1)
    csrw    mepc, t0
    /* Restore exactly the status captured at the matching interrupt entry. */
    lw      t0, 16*4(sp)
    csrw    mstatus, t0
    la      t1, tx_diag_restore_stage
    li      t0, 8
    sw      t0, 0(t1)

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

    .size _tx_thread_context_restore, .-_tx_thread_context_restore
