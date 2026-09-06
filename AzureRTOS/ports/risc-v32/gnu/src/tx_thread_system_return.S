/* Eclipse ThreadX - CH32V006F8P7 RV32E voluntary context save.
 *
 * All saved thread contexts use the same 20-word layout.  A voluntary
 * ThreadX service therefore resumes with mret just like an interrupted
 * context; there is no shorter ret-only frame to interpret. */

    .section .text
    .align  2
    .extern tx_diag_system_return_sp
    .extern tx_diag_system_return_ra
    .extern tx_diag_system_return_current
    .extern tx_diag_system_return_saved_sp
    .extern tx_diag_system_return_stack_field
    .extern tx_diag_system_return_stage
    .extern tx_diag_timer_outer_s1
    .extern tx_diag_timer_outer_s0
    .extern tx_diag_timer_outer_ra
    .extern tx_diag_system_suspend_outer_s1
    .extern tx_diag_system_suspend_outer_s0
    .extern tx_diag_system_suspend_outer_ra
    .extern tx_diag_system_suspend_caller_s1
    .extern tx_diag_system_suspend_caller_s0
    .extern tx_diag_system_suspend_caller_ra
    .extern _tx_timer_thread
    .global _tx_thread_system_return
    .type   _tx_thread_system_return, @function

_tx_thread_system_return:
    /* Preserve the solicited-save inputs across a subsequent core reset. */
    la      t0, tx_diag_system_return_sp
    sw      sp, 0(t0)
    la      t0, tx_diag_system_return_ra
    sw      ra, 0(t0)

    /*
     * Complete RV32E frame, shared with interrupt context save:
     *  0 type (=1), 1 ra, 2 gp, 3 tp, 4..6 t0..t2,
     *  7..8 s0..s1, 9..14 a0..a5, 15 mepc, 16 mstatus.
     */
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
    sw      ra, 15*4(sp)
    csrr    t0, mstatus
    sw      t0, 16*4(sp)
    li      t0, 1
    sw      t0, 0*4(sp)

    la      t0, tx_diag_system_return_stage
    li      t1, 1
    sw      t1, 0(t0)

    csrci   mstatus, 0x08
    la      t0, _tx_thread_current_ptr
    lw      t1, 0(t0)
    la      t0, tx_diag_system_return_current
    sw      t1, 0(t0)
    sw      sp, 8(t1)
    la      t0, tx_diag_system_return_stage
    li      t2, 2
    sw      t2, 0(t0)
    la      t0, tx_diag_system_return_saved_sp
    sw      sp, 0(t0)
    lw      t2, 8(t1)
    la      t0, tx_diag_system_return_stack_field
    sw      t2, 0(t0)

    /* _tx_thread_system_suspend has an 8-byte local area above its
       12-byte compiler save frame.  Record that outer frame for every
       voluntary switch; it is the return path after mepc=0x15e2. */
    lw      t2, 22*4(sp)
    la      t0, tx_diag_system_suspend_outer_s1
    sw      t2, 0(t0)
    lw      t2, 23*4(sp)
    la      t0, tx_diag_system_suspend_outer_s0
    sw      t2, 0(t0)
    lw      t2, 24*4(sp)
    la      t0, tx_diag_system_suspend_outer_ra
    sw      t2, 0(t0)
    /* The next compiler frame is the caller of system_suspend.  In the
       observed sleep path it must return to Preemptor_Thread_Entry, never
       to the ThreadX stack-fill pattern. */
    lw      t2, 25*4(sp)
    la      t0, tx_diag_system_suspend_caller_s1
    sw      t2, 0(t0)
    lw      t2, 26*4(sp)
    la      t0, tx_diag_system_suspend_caller_s0
    sw      t2, 0(t0)
    lw      t2, 27*4(sp)
    la      t0, tx_diag_system_suspend_caller_ra
    sw      t2, 0(t0)

    /* Record the compiler frame to which the timer thread will return. */
    la      t0, _tx_timer_thread
    bne     t1, t0, .Lnot_timer_return
    lw      t2, 22*4(sp)
    la      t0, tx_diag_timer_outer_s1
    sw      t2, 0(t0)
    lw      t2, 23*4(sp)
    la      t0, tx_diag_timer_outer_s0
    sw      t2, 0(t0)
    lw      t2, 24*4(sp)
    la      t0, tx_diag_timer_outer_ra
    sw      t2, 0(t0)
.Lnot_timer_return:

    la      t2, _tx_timer_time_slice
    lw      t0, 0(t2)
    beqz    t0, .Lreturn_no_slice
    sw      t0, 24(t1)
    sw      zero, 0(t2)
.Lreturn_no_slice:
    la      t0, _tx_thread_current_ptr
    sw      zero, 0(t0)
    la      t0, _tx_thread_system_stack_ptr
    lw      sp, 0(t0)
    la      t0, tx_diag_system_return_stage
    li      t1, 3
    sw      t1, 0(t0)
    j       _tx_thread_schedule

    .size _tx_thread_system_return, .-_tx_thread_system_return
