#define TAILPTR ((volatile int *)(0xff000600))
#define DATAPTR ((volatile char *)(0xff000200))
#define BUFSIZE 1024

int main(void)
{
    int buf_head = 0;

    while (1)
    {
        if (*TAILPTR == buf_head) continue;
        
        char data = DATAPTR[buf_head];
        buf_head = (buf_head + 1) % BUFSIZE;

        if (data == '1')
            __asm__("li gp, 1");
        else if (data == '2')
            __asm__("li gp, 2");
        else if (data == '3')
            __asm__("li gp, 3");
        else
            __asm__("li gp, 0");
    }
}
