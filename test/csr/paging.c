#define MSTATUS_MPP_S (1L << 11)
#define PAGE_SIZE 4096
#define PAGE_POS ((void*)0x00020000)
#define PAGE_TABLE_POS ((void*)0x00010000)

void main(void);
void pageinit(void);
void pagetableinit(void);
void wsatp(void);
void to_smode(void);
void success(void);
void uart_send_char(char c);


void main(void)
{
    pageinit(); // ページを用意する
    pagetableinit(); // ページテーブルを用意する
    wsatp(); // satpを設定する
    to_smode(); // S-modeに移動
}

void pageinit(void)
{
    volatile unsigned int *ptr = PAGE_POS;
    //unsigned int *page_end = (unsigned int)PAGE_POS + (unsigned int)PAGE_SIZE;

    // 先頭をecallに設定する。つまり、ページの先頭の命令が実行されるとmmodeに戻る
    *ptr = 0b00000000000000000000000001110011;
    // for (ptr++; ptr < page_end; ptr++) *ptr = 0;
}

void pagetableinit(void)
{
    volatile unsigned int *ptr = PAGE_TABLE_POS;
    //unsigned int *page_end = (unsigned int)PAGE_TABLE_POS + (unsigned int)PAGE_SIZE;
    
    // 先頭がPAGE_POSを指すようにする
    *ptr = 0;
    // PPN1はPAGE_POSの上位12bitのうち10bit (たぶん)
    *ptr |= ((unsigned int)PAGE_POS >> 2) & (0xfff << 20);
    // PPN0は設定しない
    *ptr |= 0b00001010; // pte.r and pte.x = 1

    // 他は0初期化
    // for (ptr++; ptr < page_end; ptr++) *ptr = 0;
}

void wsatp(void)
{
    unsigned int satp = 0;
    satp |= 1 << 31; // Sv32
    satp |= (unsigned int)PAGE_TABLE_POS >> 12; // rootの上位22bit(20bit)
    asm volatile("csrw satp, %0" : : "r" (satp));
}

void to_smode(void)
{
    // mtvecを設定する
    asm volatile("csrw mtvec, %0" : : "r" ((unsigned int)&success));

    // mppをS-modeにする
    unsigned int mstatus = 0;
    mstatus |= MSTATUS_MPP_S;
    asm volatile("csrw mstatus, %0" : : "r" (mstatus));

    // mepcを設定する
    unsigned int mepc = 0;
    // vpn1 = 0
    mepc |= ((unsigned int)PAGE_POS & 0x003ff000); // vpn0 = PAGE_POSの[21:12]
    // offsetは0
    asm volatile("csrw mepc, %0" : : "r" (mepc));

    // S-modeに移動
    asm volatile("mret");
}

void success(void)
{
    while (1) uart_send_char('o');
}

/* UART */
#define UART_TX_TAILPTR ((volatile char *)(0xff000100))
#define UART_TX_HEADPTR ((volatile char *)(0xff000104))
#define UART_TX_DATAPTR ((volatile char *)(0xff000000))
#define UART_TX_BUFSIZE 256

void uart_send_char(char c)
{
    int tail = *UART_TX_TAILPTR;
    int tailTo = (tail + 1) % UART_TX_BUFSIZE;
    UART_TX_DATAPTR[tail] = c;
    *UART_TX_TAILPTR = tailTo;
    while (*UART_TX_HEADPTR != tailTo);
}