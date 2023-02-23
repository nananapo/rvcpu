test:
	iverilog -g2005-sv -o debug.o -s testPipeline test.v main.v core.v memory.v fetchstage.v decodestage.v executestage.v memorystage.v memoryinterface.v
	vvp debug.o > debug.txt