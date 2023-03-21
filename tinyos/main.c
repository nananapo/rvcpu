#include "riscv.h"

void consoleinit();
void uartinit();
void printfinit();

void main(void)
{
    uartinit();
    consoleinit();
    printfinit();

    panic("hello");
}