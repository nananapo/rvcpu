test:
	iverilog -DDEBUG -g2005-sv -o debug.o -s test test.v main.v Core.v Memory.v FetchStage.v DecodeStage.v ExecuteStage.v MemoryStage.v MemoryInterface.v CSRStage.v WriteBackStage.v
	vvp debug.o > debug.txt