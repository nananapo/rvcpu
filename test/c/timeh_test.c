#define UART_TX_PTR ((volatile int *)(0xff000000))

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
        uart_send_char('u');
        uart_send_char('s');
        uart_send_char('e');
        uart_send_char('c');
        uart_send_char('\n');
    }
}

void uart_send_char(char c)
{
    #ifndef DEBUG
        *UART_TX_PTR = c;
    #else
        printf("%c", c);
    #endif
}

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