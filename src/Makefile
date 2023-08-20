FILES = test.sv \
		main.sv \
		Core.sv \
		ALU.sv \
		CSRStage.sv \
		DAccessCntr.sv \
		DivNbit.sv \
		DivUnsignedNbit.sv \
		Memory.sv \
		InstQueue.sv \
		IDecode.sv \
		ImmDecode.sv \
		DataSelectStage.sv \
		ExecuteStage.sv \
		MemoryStage.sv \
		MemCmdCntr.sv \
		MemMapCntr.sv \
		MemoryMapped_MachineTimeRegister.sv \
		MemoryMappedIO_Uart_rx.sv \
		MemoryMappedIO_Uart_tx.sv \
		MultNbit.sv \
		MultUnsignedNbit.sv \
		PageTableWalker.sv \
		WriteBackStage.sv \
		TwoBitCounter.sv \
		SyncQueue.sv \
		FastSyncQueue.sv \
		Uart_rx.sv \
		Uart_tx.sv

DEFINE_DEBUG = -DDEBUG
DEFINE_RISCV_TESTS = $(DEFINE_DEBUG) -DRISCV_TEST -DPRINT_DEBUGINFO
DEFINE_MEMORY_UART = $(DEFINE_DEBUG) -DMEMORY_UART

OPTION=""

d:
	iverilog $(DEFINE_DEBUG) $(OPTION) -DPRINT_DEBUGINFO -g2005-sv -o debug.o -s test $(FILES)
	vvp debug.o
df:
	iverilog $(DEFINE_DEBUG) $(OPTION) -DFAST_UART -DPRINT_DEBUGINFO -g2005-sv -o debug.o -s test $(FILES)
	vvp debug.o

dn:
	iverilog $(DEFINE_DEBUG) $(OPTION) -DFAST_UART -g2005-sv -o debug.o -s test $(FILES)
	vvp debug.o

riscv-tests:
	iverilog $(DEFINE_RISCV_TESTS) $(OPTION) -g2005-sv -o debug.o -s test $(FILES)
	vvp debug.o

dm:
	iverilog $(DEFINE_MEMORY_UART) $(OPTION) -g2005-sv -o debug.o -s test  $(FILES)
	vvp debug.o

dv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	verilator --cc $(DEFINE_DEBUG) $(OPTION) -DFAST_UART test_verilator.sv --exe test_kenel_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dvrv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	verilator --cc $(DEFINE_DEBUG) $(OPTION) -DPRINT_DEBUGINFO $(DEFINE_RISCV_TESTS) -DFAST_UART test_verilator.sv --exe test_kenel_verilator_main.cpp
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