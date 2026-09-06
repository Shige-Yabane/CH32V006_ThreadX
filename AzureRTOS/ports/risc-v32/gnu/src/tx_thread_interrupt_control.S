/***************************************************************************
 * Copyright (c) 2025 10xEngineers
 *
 * This program and the accompanying materials are made available under the
 * terms of the MIT License which is available at
 * https://opensource.org/licenses/MIT.
 *
 * SPDX-License-Identifier: MIT
 **************************************************************************/


/**************************************************************************/
/**************************************************************************/
/**                                                                       */
/** ThreadX Component                                                     */
/**                                                                       */
/**   Thread                                                              */
/**                                                                       */
/**************************************************************************/
/**************************************************************************/


    .section .text
/**************************************************************************/
/*                                                                        */
/*  FUNCTION                                               RELEASE        */
/*                                                                        */
/*    _tx_thread_interrupt_control                       RISC-V32/GNU     */
/*                                                           6.4.x        */
/*  AUTHOR                                                                */
/*                                                                        */
/*    Akif Ejaz, 10xEngineers                                             */
/*                                                                        */
/*  DESCRIPTION                                                           */
/*                                                                        */
/*    This function is responsible for changing the interrupt lockout     */
/*    posture of the system.                                              */
/*                                                                        */
/*  INPUT                                                                 */
/*                                                                        */
/*    new_posture                           New interrupt lockout posture */
/*                                                                        */
/*  OUTPUT                                                                */
/*                                                                        */
/*    old_posture                           Old interrupt lockout posture */
/*                                                                        */
/*  CALLS                                                                 */
/*                                                                        */
/*    None                                                                */
/*                                                                        */
/*  CALLED BY                                                             */
/*                                                                        */
/*    Application Code                                                    */
/*                                                                        */
/**************************************************************************/
/* UINT   _tx_thread_interrupt_control(UINT new_posture)
{  */
    .global  _tx_thread_interrupt_control
_tx_thread_interrupt_control:

    /* Pickup current interrupt posture.  */

    /* WCH FreeRTOS controls the global interrupt posture through mstatus.
       CSR 0x800 reads as zero on CH32V203 and must not be used here. */
    csrr    a1, mstatus
    andi    a1, a1, 0x08                        // Return ThreadX posture: 0 or TX_INT_ENABLE

    /* Check for the new posture.  */

    beqz    a0, _tx_thread_interrupt_disable    // If 0, disable interrupts

    /* Enable interrupts.  */

    csrsi   mstatus, 0x08                       // Enable global interrupts (MIE)
    j       _tx_thread_interrupt_control_exit   // Return to caller

_tx_thread_interrupt_disable:

    /* Disable interrupts.  */

    csrci   mstatus, 0x08                       // Disable global interrupts (MIE)

_tx_thread_interrupt_control_exit:

    /* Return the old interrupt posture.  */

    mv      a0, a1                              // Setup return value
    ret                                         // Return to caller

/* }  */
