FILE=$1
#PATH=$PATH:/opt/riscv32/bin/
riscv32-unknown-elf-gcc -march=rv32i -c -o temp.o $FILE
riscv32-unknown-elf-ld temp.o -lc -L/opt/riscv32/riscv32-unknown-elf/lib/ -Tlink.ld -nostartfiles -static -o temp.elf
riscv32-unknown-elf-objcopy -O binary temp.elf temp.bin
echo "temp.bin" | python ../bin2hex.py