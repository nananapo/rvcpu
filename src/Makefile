FILES = test.v \
		main.v \
		Core.v \
		Memory.v \
		FetchStage.v \
		DecodeStage.v \
		ExecuteStage.v \
		MemoryStage.v \
		MemoryInterface.v \
		MemoryMapController.v \
		MemoryMappedIO_Uart_rx.v \
		MemoryMappedIO_Uart_tx.v \
		MemoryUnlignedAccessController.v \
		CSRStage.v \
		WriteBackStage.v

UART_FILES = Uart_rx.v \
			Uart_tx.v \
			UARTMemory.v

DEFINE_DEBUG = -DDEBUG -DRV32M
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
	verilator --lint-only main.v

.PHONY: d v