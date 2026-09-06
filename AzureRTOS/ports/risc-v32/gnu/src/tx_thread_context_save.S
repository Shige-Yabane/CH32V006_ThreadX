/*
 * Eclipse ThreadX - CH32V006F8P7 RV32E context save.
 *
 * Full frame (20 words, 16-byte aligned):
 *   0 type, 1 ra, 2 gp, 3 tp, 4 t0, 5 t1, 6 t2, 7 s0,
 *   8 s1, 9 a0, 10 a1, 11 a2, 12 a3, 13 a4, 14 a5,
 *   15 mepc, 16 mstatus, 17..19 reserved.
 */

    .section .text
    .align  2
    .extern tx_diag_context_save_current
    .extern tx_diag_context_save_sp
    .extern tx_diag_context_save_mepc
    .extern tx_diag_context_save_stack_field
    .global _tx_thread_context_save
    .type   _tx_thread_context_save, @function

_tx_thread_context_save:
    /* The vector wrapper has already completed the immutable 80-byte frame. */
    la      t0, _tx_thread_system_state
    lw      t1, 0(t0)
    addi    t1, t1, 1
    sw      t1, 0(t0)

    /* Read diagnostics from the frame; do not re-sample the CSRs here. */
    lw      t0, 15*4(sp)
    la      t2, tx_diag_context_save_mepc
    sw      t0, 0(t2)

    /* A nested interrupt is already using the ThreadX system stack. */
    li      t0, 1
    bgt     t1, t0, .Lsave_done

    la      t0, _tx_thread_current_ptr
    lw      t1, 0(t0)
    beqz    t1, .Lsave_done

    /* Save the interrupted thread SP and run the ISR on the system stack. */
    la      t0, tx_diag_context_save_current
    sw      t1, 0(t0)
    la      t0, tx_diag_context_save_sp
    sw      sp, 0(t0)
    sw      sp, 8(t1)
    lw      t2, 8(t1)
    la      t0, tx_diag_context_save_stack_field
    sw      t2, 0(t0)
    la      t0, _tx_thread_system_stack_ptr
    lw      sp, 0(t0)

.Lsave_done:
    ret

    .size _tx_thread_context_save, .-_tx_thread_context_save
