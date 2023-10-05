#include <stdarg.h>

#include "riscv.h"

#define UART_TX_PTR ((volatile int *)(0xff000000))

#define PHYSTOP ((unsigned int)1000 * 1000 * 8)
#define PGSIZE (4096)

struct spinlock {
  unsigned int locked;  // ロックされているかどうか
  unsigned int cpuid;   // cpuのid(hartid) 
};

struct run {
    struct run *next;
};

struct {
    struct spinlock lock;
    struct run *freelist;
} kmem;

void consoleinit();
void uartinit();
void printfinit();
void kinit();

void    memset(char *ptr, char fill, unsigned int size);
void    spinlock_init(struct spinlock *lock);
void    spinlock_acquire(struct spinlock *lock);
void    spinlock_release(struct spinlock *lock);
void    printf(char *fmt, ...);
void    uart_send_char(char c);
void    *kalloc(void);
void    kfree(void*);
void    kinit(void);
void    freerange(void *pa_start, void *pa_end);


struct spinlock prlock;
struct spinlock txlock;
extern char kernel_endaddr[];

void main(void)
{
    uartinit();
    consoleinit();
    printfinit();

    printf("\n");
    printf("[kernel] booting...\n");
    printf("\n");

    kinit();

    panic("not impl");
}

void memset(char *ptr, char fill, unsigned int size)
{
    unsigned int *ptri  = (unsigned int*)ptr;
    unsigned int filli  = (fill << 24) + (fill << 16) + (fill << 8) + (fill);
    unsigned int isize  = size / sizeof(int);

    for (unsigned int i = 0; i < isize; i++)
    {
        ptri[i] = filli;
    }
    
    int offset = isize * sizeof(int);
    for (int i = 0; i < size % sizeof(int); i++)
    {
        ptr[offset + i] = fill;
    }
}

void spinlock_init(struct spinlock *lock)
{
    lock->locked = 0;
    lock->cpuid = 0;
}

void spinlock_acquire(struct spinlock *lock)
{
    __sync_synchronize();
    /*
    intr_off(); // 例外を無効にする

    if (lock->locked && lock->cpuid == mycpu())
        panic();
    */

    // testandsetでlockがアトミックにロックをとる
    // 過去の値が0ならロックをとれている
    // それ以外なら取れてない
    // lock操作はアトミックに行われるので、ここでタイマ割込みされても大丈夫
    while(amoswap(&lock->locked, 1) != 0);
    lock->cpuid = mycpu();

    /*
    intr_on(); // 例外を有効にする
    */
    __sync_synchronize();
}

void spinlock_release(struct spinlock *lock)
{
    __sync_synchronize();
    /*
    intr_off(); // 例外を無効にする

    if (!lock->locked || lock->cpuid != mycpu())
        panic();
    */

    amoswap(&lock->locked, 0);
    
    /*
    intr_on(); // 例外を有効にする
    */
    __sync_synchronize();
}

void uartinit(void)
{
    // uart_txで使うlockを初期化
    spinlock_init(&txlock);
}

void uart_send_char(char c)
{
    spinlock_acquire(&txlock);
    *UART_TX_PTR = c;
    spinlock_release(&txlock);
}

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

void consoleinit(void)
{
    
}

void printfinit(void)
{
    spinlock_init(&prlock);
}

void kinit()
{
    spinlock_init(&kmem.lock);
    freerange(kernel_endaddr, (void*)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
    char    *p;
    int     count;
    
    p = (char*)(((unsigned int)pa_start + PGSIZE - 1) / PGSIZE * PGSIZE);

    // pa_startをpagesizeでroundupしたアドレスからpa_endまでページを初期化する
    for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    {
        kfree(p);
        count++;
        //printf("[kernel] kfree %d\n", p);
    }
    printf("[kernel] freed %d pages\n", count);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    struct run *r;

    if (((unsigned int)pa % PGSIZE) != 0)
        panic("kfree : unaligned pa");
    if ((char*)pa < kernel_endaddr)
        panic("kfree : pa is kernel program address");
    if ((unsigned int)pa >= PHYSTOP)
        panic("kfree : pa is not in valid memory space");

    // Fill with junk to catch dangling refs.
    // memset(pa, 1, PGSIZE);

    r = (struct run*)pa;

    // kmemにrunを追加～
    // nextは先頭を使う。ページを使用中は使わないのでこういう実装でOK
    spinlock_acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    spinlock_release(&kmem.lock);
}