FILES = test.v \
		main.v \
		Core.v \
		DivNbit.v \
		DivUnsignedNbit.v \
		Memory.v \
		FetchStage.v \
		DecodeStage.v \
		ExecuteStage.v \
		MemoryStage.v \
		MemoryInterface.v \
		MemoryMapController.v \
		MemoryMapped_MachineTimeRegister.v \
		MemoryMappedIO_Uart_rx.v \
		MemoryMappedIO_Uart_tx.v \
		MemoryUnalignedAccessController.v \
		MultNbit.v \
		MultUnsignedNbit.v \
		CSRStage.v \
		WriteBackStage.v

UART_FILES = Uart_rx.v \
			Uart_tx.v \
			UARTMemory.v

DEFINE_DEBUG = -DDEBUG
DEFINE_RISCV_TESTS = $(DEFINE_DEBUG) -DRISCV_TEST
DEFINE_MEMORY_UART = $(DEFINE_DEBUG) -DMEMORY_UART

d:
	iverilog $(DEFINE_DEBUG) -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

riscv-tests:
	iverilog $(DEFINE_RISCV_TESTS) -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

dm:
	iverilog $(DEFINE_MEMORY_UART) -g2005-sv -o debug.o -s test  $(FILES) $(UART_FILES)
	vvp debug.o

v:
	verilator --lint-only -DDEBUG -DEXCLUDE_RV32M main.v
	verilator --lint-only $(DEFINE_DEBUG) main.v
	verilator --lint-only $(DEFINE_RISCV_TESTS) main.v
	verilator --lint-only $(DEFINE_MEMORY_UART) main.v

test_div:
	iverilog -DDEBUG -DPRINT_ALU_MODULE -g2005-sv -o debug.o -s test_div test_div.v DivUnsignedNbit.v DivNbit.v
	vvp debug.o

test_mult:
	iverilog -DDEBUG -DPRINT_ALU_MODULE -g2005-sv -o debug.o -s test_mult test_mult.v MultUnsignedNbit.v MultNbit.v
	vvp debug.o

.PHONY: d v