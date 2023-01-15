test: gen
	-mkdir results
	sh run_test.sh
gen: clean
	-mkdir riscv-tests
	sh gen_tests.sh
clean:
	-rm riscv-tests/*.bin riscv-tests/*.aligned
	rm -rf results 
.PHONY: gen clean test