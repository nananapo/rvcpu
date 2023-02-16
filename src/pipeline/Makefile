test:
	iverilog -g2005-sv -o debug.o -s test test.v main.v core.v ../memory.v decodestage.v executestage.v
	vvp debug.o