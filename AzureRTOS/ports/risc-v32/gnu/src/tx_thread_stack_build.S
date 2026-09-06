/* Eclipse ThreadX - CH32V006F8P7 RV32E initial stack frame. */

    .section .text
    .align  2
    .global _tx_thread_stack_build
    .type   _tx_thread_stack_build, @function

/* a0 = TX_THREAD *, a1 = _tx_thread_shell_entry */
_tx_thread_stack_build:
    lw      t0, 16(a0)
    li      t1, -16
    and     t0, t0, t1
    addi    t0, t0, -20*4

    li      t1, 2
    sw      t1, 0*4(t0)
    sw      zero, 1*4(t0)
    sw      gp, 2*4(t0)
    sw      tp, 3*4(t0)
    sw      zero, 4*4(t0)
    sw      zero, 5*4(t0)
    sw      zero, 6*4(t0)
    sw      zero, 7*4(t0)
    sw      zero, 8*4(t0)
    sw      zero, 9*4(t0)
    sw      zero, 10*4(t0)
    sw      zero, 11*4(t0)
    sw      zero, 12*4(t0)
    sw      zero, 13*4(t0)
    sw      zero, 14*4(t0)
    sw      a1, 15*4(t0)
    li      t1, 0x1880
    sw      t1, 16*4(t0)
    sw      zero, 17*4(t0)
    sw      zero, 18*4(t0)
    sw      zero, 19*4(t0)
    sw      t0, 8(a0)
    ret

    .size _tx_thread_stack_build, .-_tx_thread_stack_build
