#ifndef TX_USER_H
#define TX_USER_H

/* CH32V006F8P7 base configuration. */
#define TX_MAX_PRIORITIES                  32
#define TX_TIMER_TICKS_PER_SECOND          100UL
#define TX_MINIMUM_STACK                   256
#define TX_TIMER_THREAD_STACK_SIZE         384
#define TX_TIMER_THREAD_PRIORITY           0

/*
 * Test both builds:
 *   defined   : timer callbacks run in the SysTick ISR
 *   undefined : callbacks run in ThreadX's system timer thread
 * tx_thread_sleep() must work in both configurations.
 */
/* #define TX_TIMER_PROCESS_IN_ISR */

/* Leave WFI disabled during initial port bring-up. */
/* #define TX_NO_WFI */

#endif
