#define UART_TX_TAILPTR ((volatile char *)(0xff000100))
#define UART_TX_HEADPTR ((volatile char *)(0xff000104))
#define UART_TX_DATAPTR ((volatile char *)(0xff000000))
#define UART_TX_BUFSIZE 256

void uart_send_char(char c);
void send_int(int value);
void send_uint(unsigned int value);

static inline unsigned int r_time();

int main(void)
{
    while (1)
    {
        unsigned int rdtime = r_time();
        send_uint(rdtime);
        uart_send_char('\n');

        for (volatile int i = 0; i < 1000000; i++);
    }
}

#ifndef DEBUG
void uart_send_char(char c)
{
    // TODO バッファが空くのを待った後、ロックを取りたい
    int tail = *UART_TX_TAILPTR;
    int tailTo = (tail + 1) % UART_TX_BUFSIZE;
    UART_TX_DATAPTR[tail] = c;
    *UART_TX_TAILPTR = tailTo;
    while (*UART_TX_HEADPTR != tailTo); // 送信完了を待つ
}
#else
void uart_send_char(char c)
{
    printf("%c", c);
}
#endif

void send_int(int value)
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

void send_uint(unsigned int value)
{
    char    buf[11];
    int     len = 1;

    // 文字数を求める
    int tmp = value;
    while (tmp > 9)
    {
       len++;
       tmp /= 10;
    }

    // bufに文字を詰める
    tmp = value;
    for (int i = 0; i < len; i++)
    {
        int offset = tmp % 10;
        buf[len - i - 1] = '0' + offset;
        tmp /= 10;
    }

    // 送信
    for (int i = 0; i < len; i++)
    {
        uart_send_char(buf[i]);
    }
}

#ifndef DEBUG
static inline unsigned int r_time()
{
  unsigned int x;
  __asm__ volatile("csrr %0, time" : "=r" (x));
  return x;
}
#else
static unsigned int r_time()
{
    return 10100010;
}
#endif