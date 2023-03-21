#include "uart.h"
#include "spinlock.h"

#define UART_TX_TAILPTR ((volatile char *)(0xff000100))
#define UART_TX_HEADPTR ((volatile char *)(0xff000104))
#define UART_TX_DATAPTR ((volatile char *)(0xff000000))
#define UART_TX_BUFSIZE 256

struct spinlock txlock;

void uartinit(void)
{
    // uart_txで使うlockを初期化
    spinlock_init(&txlock);
}

void uart_send_char(char c)
{
    spinlock_acquire(&txlock);

    int tail = *UART_TX_TAILPTR;
    int tailTo = (tail + 1) % UART_TX_BUFSIZE;
    UART_TX_DATAPTR[tail] = c;
    *UART_TX_TAILPTR = tailTo;
    while (*UART_TX_HEADPTR != tailTo); // 送信完了を待つ

    spinlock_release(&txlock);
}