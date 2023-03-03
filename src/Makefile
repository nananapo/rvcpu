test:
	iverilog -DDEBUG -g2005-sv -o debug.o -s test test.v main.v core.v memory.v fetchstage.v decodestage.v executestage.v memorystage.v memoryinterface.v csrstage.v writebackstage.v
	vvp debug.o > debug.txt