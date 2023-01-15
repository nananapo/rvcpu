debug:
	iverilog -g2001 -o debug.o -s test test.v main.v memory.v core.v csr.v
	vvp debug.o
clean:
	rm debug.o debug.vcd
