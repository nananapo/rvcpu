FILES = test.v \
		main.v \
		Core.v \
		Memory.v \
		FetchStage.v \
		DecodeStage.v \
		ExecuteStage.v \
		MemoryStage.v \
		MemoryInterface.v \
		MemoryMappedIO_Uart_tx.v \
		MemoryAccessController.v \
		CSRStage.v \
		WriteBackStage.v

UART_FILES = Uart_rx.v \
			Uart_tx.v \
			UARTMemory.v

DEFALUT_DEFINE = -DDEBUG

d:
	iverilog $(DEFALUT_DEFINE) -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

riscv-tests:
	iverilog $(DEFALUT_DEFINE) -DRISCV_TEST -g2005-sv -o debug.o -s test $(FILES) $(UART_FILES)
	vvp debug.o

dm:
	iverilog $(DEFALUT_DEFINE) -DMEMORY_UART -g2005-sv -o debug.o -s test  $(FILES) $(UART_FILES)
	vvp debug.o

v:
	verilator --lint-only main.v

.PHONY: d v