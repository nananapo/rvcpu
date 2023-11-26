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
		CombinationalKeyValueStore.sv \
		MemBusCntr.sv \
		MemICache.sv \
		MemDCache.sv \
		MemCacheCmdArbiter.sv \
		MemMisalignCntr.sv \
		MemoryKeyValueStore.sv \
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

VERILATOR = verilator
VERILATOR_OPT = --unroll-stmts 100000

DEFINE_DEBUG = -DDEBUG -DFAST_UART
DEFINE_RISCV_TESTS = $(DEFINE_DEBUG) -DRISCV_TESTS

OPTION = ""


d:
	iverilog $(DEFINE_DEBUG) -DPRINT_DEBUGINFO -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

dl:
	iverilog $(DEFINE_DEBUG) -DPRINT_LIGHT_WBLOG -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

dn:
	iverilog $(DEFINE_DEBUG) -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

riscv-tests:
	iverilog $(DEFINE_RISCV_TESTS) -g2005-sv -o debug.o -s test ${OPTION} $(FILES)
	vvp debug.o

dv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	$(VERILATOR) $(VERILATOR_OPT) --cc $(DEFINE_DEBUG) ${OPTION} test_verilator.sv --exe test_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dvrv:
	echo "$$VERILATOR_ROOT is ${VERILATOR_ROOT}"
	rm -rf obj_dir
	$(VERILATOR) $(VERILATOR_OPT) --cc $(DEFINE_RISCV_TESTS) ${OPTION} test_verilator.sv --exe test_verilator_main.cpp
	make -j -C obj_dir/ -f Vtest_verilator.mk Vtest_verilator
	obj_dir/Vtest_verilator

dk:
	cd ../tinyos && ./build.sh
	make dv

v:
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DPRED_TBC main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DPRED_LOCAL main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DPRED_GLOBAL main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" $(DEFINE_DEBUG) main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" $(DEFINE_RISCV_TESTS) main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" $(DEFINE_MEMORY_UART) main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DDETECT_ABNORMAL_STALL main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DDEBUG -DDETECT_ABNORMAL_STALL main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DXZSTOP main.sv
	$(VERILATOR) $(VERILATOR_OPT) --lint-only --top-module main -DMEM_FILE=\"\" -DPRINT_LIGHT_WBLOG main.sv

icanon:
	gcc icanon.c -o icanon

clean:
	-rm icanon
	-rm debug.o debug.vcd
	-rm -rf obj_dir/

.PHONY: d v
