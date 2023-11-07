FILES = test.sv \
		main.sv \
		Uart_rx.sv \
		Uart_tx.sv \
		Memory.sv \
		Core.sv \
		IDecode.sv \
		ImmDecode.sv \
		SyncQueue.sv \
		ALU.sv \
		ALU_MulDivModule.sv \
		ALU_DivNbit.sv \
		ALU_DivUnsignedNbit.sv \
		ALU_MultNbit.sv \
		ALU_MultUnsignedNbit.sv \
		BP_TwoBitCounter.sv \
		BP_LocalHistory2bit.sv \
		BP_GlobalHistory2bit.sv \
		MemBusCntr.sv \
		MemICache.sv \
		MemDCache.sv \
		MemCacheCmdArbiter.sv \
		MemMisalignCntr.sv \
		MMIO_Cntr.sv \
		MMIO_CLINT.sv \
		MMIO_EDisk.sv \
		MMIO_UART_RX.sv \
		MMIO_UART_TX.sv \
		PageTableWalker.sv \
		Stage_Fetch.sv \
		Stage_RegSel.sv \
		Stage_Exe.sv \
		Stage_Mem.sv \
		Stage_CSR.sv \
		Stage_WB.sv

DEFINE_DEBUG = -DDEBUG
DEFINE_RISCV_TESTS = $(DEFINE_DEBUG) -DRISCV_TESTS
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
	verilator --cc $(DEFINE_DEBUG) -DFAST_UART ${OPTION} test_verilator.sv --exe test_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dvrv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	verilator --cc $(DEFINE_RISCV_TESTS) -DFAST_UART ${OPTION} test_verilator.sv --exe test_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dk:
	cd ../tinyos && ./build.sh
	make dv

v:
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DPRED_TBC main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DPRED_LOCAL main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DPRED_GLOBAL main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" $(DEFINE_DEBUG) main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" $(DEFINE_RISCV_TESTS) main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" $(DEFINE_MEMORY_UART) main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DDETECT_ABNORMAL_STALL main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DDETECT_ABNORMAL_STALL main.sv
	verilator --lint-only --top-module main -DMEM_FILE=\"\" -DXZSTOP main.sv

icanon:
	gcc icanon.c -o icanon

clean:
	-rm icanon
	-rm debug.o debug.vcd
	-rm -rf obj_dir/

.PHONY: d v
