/**************************************************************************/
/* CH32V006F8P7 RV32E ThreadX timer interrupt core.                       */
/* Kept in C because the upstream RV32I assembly uses x16-x31 registers   */
/* which do not exist in the RV32E ABI.                                   */
/**************************************************************************/

#include "tx_api.h"

extern volatile ULONG       _tx_timer_system_clock;
extern ULONG                _tx_timer_time_slice;
extern UINT                 _tx_timer_expired;
extern UINT                 _tx_timer_expired_time_slice;
extern TX_TIMER_INTERNAL  **_tx_timer_current_ptr;
extern TX_TIMER_INTERNAL  **_tx_timer_list_start;
extern TX_TIMER_INTERNAL  **_tx_timer_list_end;

extern VOID _tx_timer_expiration_process(VOID);
extern VOID _tx_thread_time_slice(VOID);

/* CH32V006 port diagnostic.  Defined in User/tx_port_ch32v006.c. */
extern volatile ULONG tx_diag_timer_phase;

VOID _tx_timer_interrupt(VOID)
{
    UINT expired = 0U;

    tx_diag_timer_phase = 1U;
    _tx_timer_system_clock++;
    tx_diag_timer_phase = 2U;

    if (_tx_timer_time_slice != 0UL)
    {
        _tx_timer_time_slice--;
        if (_tx_timer_time_slice == 0UL)
        {
            _tx_timer_expired_time_slice = TX_TRUE;
            expired |= 1U;
        }
    }

    if (*_tx_timer_current_ptr != TX_NULL)
    {
        _tx_timer_expired = TX_TRUE;
        expired |= 2U;
    }
    else
    {
        _tx_timer_current_ptr++;
        if (_tx_timer_current_ptr == _tx_timer_list_end)
        {
            _tx_timer_current_ptr = _tx_timer_list_start;
        }
    }

    if ((expired & 2U) != 0U)
    {
        tx_diag_timer_phase = 3U;
        _tx_timer_expiration_process();
        tx_diag_timer_phase = 4U;
    }

    if ((expired & 1U) != 0U)
    {
        tx_diag_timer_phase = 5U;
        _tx_thread_time_slice();
        tx_diag_timer_phase = 6U;
    }

    tx_diag_timer_phase = 7U;
}
