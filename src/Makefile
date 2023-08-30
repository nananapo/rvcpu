FILES = test.sv \
		main.sv \
		Uart_rx.sv \
		Uart_tx.sv \
		Memory.sv \
		Core.sv \
		IDecode.sv \
		ImmDecode.sv \
		InstQueue.sv \
		SyncQueue.sv \
		MemBusCntr.sv \
		MemICache.sv \
		MemDCache.sv \
		MMIO_Cntr.sv \
		MMIO_clint.sv \
		MMIO_uart_rx.sv \
		MMIO_uart_tx.sv \
		PageTableWalker.sv \
		DAccessCntr.sv \
		ALU.sv \
		CSRStage.sv \
		DivNbit.sv \
		DivUnsignedNbit.sv \
		DataSelectStage.sv \
		ExecuteStage.sv \
		MemoryStage.sv \
		MultNbit.sv \
		MultUnsignedNbit.sv \
		WriteBackStage.sv \
		TwoBitCounter.sv \
		LocalHistory2bit.sv \
		GlobalHistory2bit.sv \
		FastSyncQueue.sv \

DEFINE_DEBUG = -DDEBUG
DEFINE_RISCV_TESTS = $(DEFINE_DEBUG) -DRISCV_TEST -DPRINT_DEBUGINFO
DEFINE_MEMORY_UART = $(DEFINE_DEBUG) -DMEMORY_UART

OPTION = ""


d:
	iverilog $(DEFINE_DEBUG) -DPRINT_DEBUGINFO -g2005-sv -o debug.o -s test ${OPTION} $(FILES) 
	vvp debug.o

df:
	iverilog $(DEFINE_DEBUG) -DFAST_UART -DPRINT_DEBUGINFO -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

dn:
	iverilog $(DEFINE_DEBUG) -DFAST_UART -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

riscv-tests:
	iverilog $(DEFINE_RISCV_TESTS) -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

dm:
	iverilog $(DEFINE_MEMORY_UART) -g2005-sv -o debug.o -s test  ${OPTION} $(FILES)
	vvp debug.o

dv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	verilator --cc $(DEFINE_DEBUG) -DFAST_UART ${OPTION} test_verilator.sv --exe test_kenel_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dvrv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	verilator --cc $(DEFINE_DEBUG) -DPRINT_DEBUGINFO $(DEFINE_RISCV_TESTS) -DFAST_UART ${OPTION} test_verilator.sv --exe test_kenel_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dk:
	cd ../tinyos && ./build.sh
	make dv

v:
	verilator --lint-only --top-module main -DDEBUG -DEXCLUDE_RV32M main.sv
	verilator --lint-only --top-module main -DDEBUG -DEXCLUDE_RV32A main.sv
	verilator --lint-only --top-module main -DDEBUG -DEXCLUDE_RV32M -DEXCLUDE_RV32A main.sv
	verilator --lint-only --top-module main -DDEBUG -DEXCLUDE_PREDICTION_MODULE main.sv
	verilator --lint-only --top-module main $(DEFINE_DEBUG) main.sv
	verilator --lint-only --top-module main $(DEFINE_RISCV_TESTS) main.sv
	verilator --lint-only --top-module main $(DEFINE_MEMORY_UART) main.sv

test_div:
	iverilog -DDEBUG -DPRINT_ALU_MODULE -g2005-sv -o debug.o -s test_div test_div.sv DivUnsignedNbit.sv DivNbit.sv
	vvp debug.o

test_mult:
	iverilog -DDEBUG -DPRINT_ALU_MODULE -g2005-sv -o debug.o -s test_mult test_mult.sv MultUnsignedNbit.sv MultNbit.sv
	vvp debug.o

.PHONY: d v
