#include <iostream>
#include <verilated.h>
#include "Vtest_verilator.h"

int main(int argc, char** argv) {

  Verilated::commandArgs(argc, argv);

  // Instantiate DUT
  Vtest_verilator *dut = new Vtest_verilator();

  dut->clk = 0;

  while (1) {
    dut->clk = !dut->clk;
    dut->eval();
  }

  dut->final();
}
