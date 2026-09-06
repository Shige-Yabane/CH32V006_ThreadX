/********************************** (C) COPYRIGHT *******************************
 * File Name          : main.c
 * Description        : ThreadX main1 recheck after RV32E context-frame changes.
 *******************************************************************************/

#include "debug.h"
#include "tx_api.h"

/* PD4 --- resistor --- LED anode; LED cathode --- GND. */
#define LED_GPIO_PORT       GPIOD
#define LED_GPIO_PIN        GPIO_Pin_4
#define MAIN1_BLINK_TICKS   (TX_TIMER_TICKS_PER_SECOND / 2U)
#define MAIN1_LED_PRIORITY  5U

static TX_THREAD main1_led_thread;
static ULONG main1_led_stack[128] __attribute__((aligned(16))); /* 512 bytes. */

/* Watch variables. main1_test_magic == 0x4D315246 ("M1RF"). */
volatile ULONG main1_test_magic;
volatile ULONG main1_thread_create_count;
volatile ULONG main1_sleep_request_count;
volatile ULONG main1_sleep_resume_count;
volatile ULONG main1_led_toggle_count;
volatile ULONG main1_error_count;
volatile UINT  main1_last_status;

static void Main1_LED_Init(void)
{
    GPIO_InitTypeDef gpio = {0};

    RCC_PB2PeriphClockCmd(RCC_PB2Periph_GPIOD, ENABLE);

    gpio.GPIO_Pin = LED_GPIO_PIN;
    gpio.GPIO_Speed = GPIO_Speed_30MHz;
    gpio.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_Init(LED_GPIO_PORT, &gpio);

    /* Keep the active-high LED off until the first toggle. */
    GPIO_ResetBits(LED_GPIO_PORT, LED_GPIO_PIN);
}

static void Main1_Fail(UINT status)
{
    main1_last_status = status;
    main1_error_count++;
    GPIO_ResetBits(LED_GPIO_PORT, LED_GPIO_PIN);
    for (;;) { }
}

/* Each cycle exercises system return, SysTick, Software IRQ, scheduling and mret. */
static void Main1_LED_Thread_Entry(ULONG thread_input)
{
    UINT status;

    (void)thread_input;
    for (;;)
    {
        main1_sleep_request_count++;
        status = tx_thread_sleep(MAIN1_BLINK_TICKS);
        main1_last_status = status;
        if (status != TX_SUCCESS)
        {
            Main1_Fail(status);
        }
        main1_sleep_resume_count++;
        LED_GPIO_PORT->OUTDR ^= LED_GPIO_PIN;
        main1_led_toggle_count++;
    }
}

/* Called by ThreadX after its kernel objects have been initialized. */
void tx_application_define(void *first_unused_memory)
{
    UINT status;

    (void)first_unused_memory;

    main1_test_magic = 0x4D315246UL;
    Main1_LED_Init();
    status = tx_thread_create(&main1_led_thread, "main1 LED",
                              Main1_LED_Thread_Entry, 0U,
                              main1_led_stack, sizeof(main1_led_stack),
                              MAIN1_LED_PRIORITY, MAIN1_LED_PRIORITY,
                              TX_NO_TIME_SLICE, TX_AUTO_START);
    main1_last_status = status;
    if (status != TX_SUCCESS)
    {
        Main1_Fail(status);
    }
    main1_thread_create_count++;
}

int main(void)
{
    SystemCoreClockUpdate();
    tx_kernel_enter();

    for (;;) { }
}
