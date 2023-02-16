test: clean
	iverilog -g2005-sv -o debug.o -s test test.v main.v core.v ../memory.v decodestage.v
	vvp debug.o
	-rm -rf debug.o

clean:
	-rm -rf debug.o