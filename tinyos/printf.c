#include <stdarg.h>
#include "spinlock.h"
#include "uart.h"

struct spinlock prlock;

void printint(int value)
{
    char    buf[11];
    int     len     = 1;
    int     isneg   = value < 0;

    // 符号
    buf[0] = '-';
    if (isneg) len += 1;

    // 文字数を求める
    int tmp = value;
    while (tmp > 9 || tmp < -9)
    {
       len++;
       tmp /= 10;
    }

    // bufに文字を詰める
    tmp = value;
    for (int i = 0; i < len - isneg; i++)
    {
        int offset = tmp % 10;
        offset = offset > 0 ? offset : -offset;
        buf[len - i - 1] = '0' + offset;
        tmp /= 10;
    }

    // 送信
    for (int i = 0; i < len; i++)
    {
        uart_send_char(buf[i]);
    }
}

// 雑なprintf
// %d, %c, %sのみ対応
void printf(char *fmt, ...)
{
    va_list ap;
    
    va_start(ap, fmt);

    if (fmt == 0)
        return;

    spinlock_acquire(&prlock);

    for(int i = 0; fmt[i] != '\0'; i++)
    {
        if(fmt[i] != '%'){
            uart_send_char(fmt[i]);
            continue;
        }

        switch(fmt[++i])
        {
            case 'd':
                printint(va_arg(ap, int));
                break;
            case 's':
            {
                char *str = va_arg(ap, char *);
                if (str == 0)
                    str = "(null)";
                for (; *str != '\0'; str++)
                    uart_send_char(*str);
                break;
            }
            case 'c':
            {
                uart_send_char(va_arg(ap, int));
                break;
            }
        }
    }

    spinlock_release(&prlock);

    va_end(ap);
}

void panic(char *s)
{
    prlock.locked = 0;

    printf("panic : ");
    printf(s);
    printf("\n");

    volatile int a = 0;
    while (1) a++;
}

void printfinit(void)
{
    spinlock_init(&prlock);
}
