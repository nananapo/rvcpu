#include <iostream>
#include <verilated.h>
#include "Vtest_verilator.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    Vtest_verilator *dut = new Vtest_verilator();
    dut->clk = 0;

    int count = 0;

    while (1) {
        dut->clk = !dut->clk;
        dut->eval();
        count++;

        //if (count % 100000 == 0)
        //    printf("%d\n", count);
    }

    dut->final();
}
