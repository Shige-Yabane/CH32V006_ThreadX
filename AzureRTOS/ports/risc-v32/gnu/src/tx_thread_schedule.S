/* Eclipse ThreadX - CH32V006F8P7 RV32E scheduler. */

    .section .text
    .align  2
    .global _tx_thread_schedule
    .type   _tx_thread_schedule, @function
    .extern tx_schedule_initial_start_count
    .extern tx_schedule_interrupt_resume_count
    .extern tx_diag_schedule_selected_thread
    .extern tx_diag_schedule_selected_stack_ptr
    .extern tx_diag_hold_reached
    .extern tx_diag_initial_mstatus_after_write
    .extern tx_diag_mstatus_before_mret
    .extern tx_diag_schedule_stage
    .extern tx_diag_schedule_frame_type
    .extern tx_diag_schedule_frame_ra
    .extern tx_diag_schedule_mepc
    .extern tx_diag_schedule_loaded_ra
    .extern tx_diag_schedule_resume_sp

_tx_thread_schedule:
    la      t0, tx_diag_schedule_stage
    li      t1, 1
    sw      t1, 0(t0)
    /*
     * A scheduler entry from the PFIC Software IRQ must stay atomic until
     * the selected task is resumed with mret.  Enabling MIE here lets a new
     * SysTick nest inside the unfinished Software IRQ and leaves PFIC's IRQ
     * state inconsistent after a few switches.  Normal service-call and
     * kernel-start entries retain the original interrupt-enabled behaviour.
     */
    la      t0, _threadx_software_switch_active
    lw      t1, 0(t0)
    bnez    t1, .Lschedule_loop
    csrsi   mstatus, 0x08

.Lschedule_loop:
    la      t0, _tx_thread_execute_ptr
    lw      t1, 0(t0)
    bnez    t1, .Lready
#ifdef TX_NO_WFI
    wfi
#endif
    j       .Lschedule_loop

.Lready:
    csrci   mstatus, 0x08
    lw      t1, 0(t0)
    beqz    t1, _tx_thread_schedule

    /* Retain the selected thread and its saved stack pointer for diagnosis. */
    la      t0, tx_diag_schedule_selected_thread
    sw      t1, 0(t0)
    lw      t2, 8(t1)
    la      t0, tx_diag_schedule_selected_stack_ptr
    sw      t2, 0(t0)

    la      t0, _tx_thread_current_ptr
    sw      t1, 0(t0)
    lw      t2, 4(t1)
    addi    t2, t2, 1
    sw      t2, 4(t1)

    lw      t2, 24(t1)
    la      t0, _tx_timer_time_slice
    sw      t2, 0(t0)

    lw      sp, 8(t1)
    lw      t0, 0(sp)
    la      t1, tx_diag_schedule_frame_type
    sw      t0, 0(t1)
    lw      t2, 1*4(sp)
    la      t1, tx_diag_schedule_frame_ra
    sw      t2, 0(t1)
    /* Initial, voluntary, and interrupt contexts share this layout. */
.Lfull_frame:
    li      t1, 2
    beq     t0, t1, .Linitial_frame
    la      t1, tx_schedule_interrupt_resume_count
    lw      t2, 0(t1)
    addi    t2, t2, 1
    sw      t2, 0(t1)
    j       .Lresume_interrupt_frame

.Linitial_frame:
    la      t1, tx_diag_schedule_stage
    li      t2, 3
    sw      t2, 0(t1)
    la      t1, tx_schedule_initial_start_count
    lw      t2, 0(t1)
    addi    t2, t2, 1
    sw      t2, 0(t1)
    /* Zephyr restores the initial frame's saved interrupt posture. */
    lw      t0, 16*4(sp)
    la      t1, tx_diag_initial_mstatus_after_write
    sw      t0, 0(t1)
    csrw    mstatus, t0
    j       .Lresume_complete_frame

.Lresume_interrupt_frame:
    /* Every frame carries the exact mstatus to restore with its mepc. */
.Lresume_complete_frame:
    la      t0, _threadx_software_switch_active
    sw      zero, 0(t0)
    lw      t0, 15*4(sp)
    la      t1, tx_diag_schedule_mepc
    sw      t0, 0(t1)
    csrw    mepc, t0
    lw      t0, 16*4(sp)
    csrw    mstatus, t0
    csrr    t0, mstatus
    la      t1, tx_diag_mstatus_before_mret
    sw      t0, 0(t1)
    la      t1, tx_diag_schedule_stage
    li      t0, 4
    sw      t0, 0(t1)

    lw      ra, 1*4(sp)
    /* Record the actual register value loaded immediately before mret. */
    la      t0, tx_diag_schedule_loaded_ra
    sw      ra, 0(t0)
    lw      gp, 2*4(sp)
    lw      tp, 3*4(sp)
    lw      s0, 7*4(sp)
    lw      s1, 8*4(sp)
    lw      a0, 9*4(sp)
    lw      a1, 10*4(sp)
    lw      a2, 11*4(sp)
    lw      a3, 12*4(sp)
    lw      a4, 13*4(sp)
    lw      a5, 14*4(sp)
    addi    t2, sp, 20*4
    la      t0, tx_diag_schedule_resume_sp
    sw      t2, 0(t0)
    lw      t2, 6*4(sp)
    lw      t0, 4*4(sp)
    lw      t1, 5*4(sp)
    addi    sp, sp, 20*4
    mret

    .size _tx_thread_schedule, .-_tx_thread_schedule

    .section .bss
    .align  2
    .global _threadx_interrupt_return_active
_threadx_interrupt_return_active:
    .word   0
