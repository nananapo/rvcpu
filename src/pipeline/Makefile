test:
	iverilog -g2005-sv -o debug.o -s test test.v main.v core.v memory.v fetchstage.v decodestage.v executestage.v memorystage.v memoryinterface.sv
	vvp debug.o > debug.txt