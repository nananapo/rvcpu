FILES = test.sv \
		main.sv \
		Core.sv \
		DivNbit.sv \
		DivUnsignedNbit.sv \
		Memory.sv \
		FetchStage.sv \
		DecodeStage.sv \
		ExecuteStage.sv \
		MemoryStage.sv \
		MemoryInterface.sv \
		MemoryMapController.sv \
		MemoryMapped_MachineTimeRegister.sv \
		MemoryMappedIO_Uart_rx.sv \
		MemoryMappedIO_Uart_tx.sv \
		MemoryUnalignedAccessController.sv \
		MultNbit.sv \
		MultUnsignedNbit.sv \
		CSRStage.sv \
		WriteBackStage.sv

UART_FILES = Uart_rx.sv \
			Uart_tx.sv \
			UARTMemory.sv

DEFINE_DEBUG = -DDEBUG
DEFINE_RISCV_TESTS = $(DEFINE_DEBUG) -DRISCV_TEST -DPRINT_DEBUGINFO
DEFINE_MEMORY_UART = $(DEFINE_DEBUG) -DMEMORY_UART

d:
	iverilog $(DEFINE_DEBUG) -DPRINT_DEBUGINFO -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

dn:
	iverilog $(DEFINE_DEBUG) -DFAST_UART -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

riscv-tests:
	iverilog $(DEFINE_RISCV_TESTS) -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

dm:
	iverilog $(DEFINE_MEMORY_UART) -g2005-sv -o debug.o -s test  $(FILES) $(UART_FILES)
	vvp debug.o

dv:
	rm -rf obj_dir
	verilator --cc $(DEFINE_DEBUG) -DFAST_UART test_verilator.sv --exe test_kenel_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dk:
	cd ../tinyos && ./build.sh
	make dv

v:
	verilator --lint-only -DDEBUG -DEXCLUDE_RV32M main.sv
	verilator --lint-only -DDEBUG -DEXCLUDE_RV32A main.sv
	verilator --lint-only -DDEBUG -DEXCLUDE_RV32M -DEXCLUDE_RV32A main.sv
	verilator --lint-only $(DEFINE_DEBUG) main.sv
	verilator --lint-only $(DEFINE_RISCV_TESTS) main.sv
	verilator --lint-only $(DEFINE_MEMORY_UART) main.sv

test_div:
	iverilog -DDEBUG -DPRINT_ALU_MODULE -g2005-sv -o debug.o -s test_div test_div.sv DivUnsignedNbit.sv DivNbit.sv
	vvp debug.o

test_mult:
	iverilog -DDEBUG -DPRINT_ALU_MODULE -g2005-sv -o debug.o -s test_mult test_mult.sv MultUnsignedNbit.sv MultNbit.sv
	vvp debug.o

.PHONY: d v