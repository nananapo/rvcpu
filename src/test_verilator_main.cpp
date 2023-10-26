using namespace std;

#include <iostream>
#include <verilated.h>
#include "Vtest_verilator.h"
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

bool uart_idle = true;
bool uart_start;
bool uart_end;
char uart_char;
int  uart_clock_count;

#define DELAY_FRAME 2

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtest_verilator *dut = new Vtest_verilator();
    dut->clk        = 0;
    dut->uart_rx    = 1;

    fcntl(0, F_SETFL, O_NONBLOCK);

    while (1) {
        dut->clk = !dut->clk;

        if (dut->clk == 1)
        {
            if (uart_idle) {
                dut->uart_rx = 1;
                char buf;
                int readres = read(0, &buf, 1);
                if (readres == 1)
                {
                    uart_char   = buf;
                    uart_idle   = false;
                    uart_start  = true;
                    uart_end    = false;
                    uart_clock_count = 0;
                }
            } else {
                // 61 -> 0110 0001
                uart_clock_count++;
                if (uart_start) {
                    dut->uart_rx = 0;
                    if (uart_clock_count == DELAY_FRAME)
                    {
                        uart_start = false;
                        uart_clock_count = 0;
                    }
                } else if (uart_end) {
                    dut->uart_rx = 1;
                    if (uart_clock_count == DELAY_FRAME)
                    {
                        uart_idle   = true;
                        uart_end    = false;
                        uart_clock_count = 0;
                    }
                } else {
                    dut->uart_rx = (uart_char >> (uart_clock_count-1)/2) % 2;
                    if (uart_clock_count == DELAY_FRAME * 8)
                    {
                        uart_end = true;
                        uart_clock_count = 0;
                    }
                }
                // printf("%d\n", dut->uart_rx);
            }
        }
        dut->eval();
    }

    dut->final();
}
