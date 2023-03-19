#define MTIME_ADDR      ((unsigned int *)0xf0000000)
#define MTIMEH_ADDR     ((unsigned int *)0xf0000004)
#define MTIMECMP_ADDR   ((unsigned int *)0xf0000008)
#define MTIMECMPH_ADDR  ((unsigned int *)0xf000000c)

#define DEBUG_COUNT ((unsigned int *)0xf0000010)

#define MSTATUS_MIE (1 << 3)
#define MIE_MTIE (1 << 7)

#define INTERVAL 1000000

extern void timervec(void);

int  main(void);
void set_next_timecmp(unsigned int interval);
void timerinit();

int main(void)
{
    timerinit();

    *DEBUG_COUNT = 0;
    while (1)
    {
        *DEBUG_COUNT = *DEBUG_COUNT + 1;
    }
}

#include "uart.h"

void timer_interrupt(void)
{
    //send_uint(*DEBUG_COUNT);

    uart_send_char('t');
    uart_send_char('i');
    uart_send_char('m');
    uart_send_char('e');
    uart_send_char('r');
    uart_send_char(' ');
    uart_send_char('i');
    uart_send_char('n');
    uart_send_char('t');
    uart_send_char('e');
    uart_send_char('r');
    uart_send_char('r');
    uart_send_char('u');
    uart_send_char('p');
    uart_send_char('t');

    uart_send_char('\n');
    set_next_timecmp(INTERVAL);
}

void set_next_timecmp(unsigned int interval)
{
    unsigned int mtime  = *MTIME_ADDR;
    unsigned int mtimeh = *MTIMEH_ADDR;

    if (mtime + interval < mtime)
        mtimeh += 1;
    mtime += interval;

    *MTIMECMPH_ADDR = mtimeh;
    *MTIMECMP_ADDR = mtime;
}

static inline void w_mtvec(unsigned int x)
{
    asm volatile("csrw mtvec, %0" : : "r" (x));
}

static inline void w_mstatus(unsigned int x)
{
    asm volatile("csrw mstatus, %0" : : "r" (x));
}

static inline unsigned int r_mstatus(void)
{
    unsigned int x;
    asm volatile("csrr %0, mstatus" : "=r" (x));
    return x;
}

static inline void w_mie(unsigned int x)
{
    asm volatile("csrw mie, %0" : : "r" (x));
}

static inline unsigned int r_mie(void)
{
    unsigned int x;
    asm volatile("csrr %0, mie" : "=r" (x));
    return x;
}

void timerinit()
{
    set_next_timecmp(INTERVAL);

    w_mtvec((unsigned int)timervec);

    w_mstatus(r_mstatus() | MSTATUS_MIE);

    // enable machine-mode timer interrupts.
    w_mie(r_mie() | MIE_MTIE);
}
