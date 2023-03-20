ELFFILE="kernel.elf"
BINFILE="kernel.bin"
DUMPFILE="${BINFILE}.dump"
GCC_OPTION="-O3"
#
riscv32-unknown-elf-gcc -march=rv32im $GCC_OPTION -c -o entry.S.o entry.S
riscv32-unknown-elf-gcc -march=rv32im $GCC_OPTION -c -o start.c.o start.c
riscv32-unknown-elf-gcc -march=rv32im $GCC_OPTION -c -o kernelvec.S.o kernelvec.S
riscv32-unknown-elf-gcc -march=rv32im $GCC_OPTION -c -o main.c.o main.c
#
riscv32-unknown-elf-ld entry.S.o start.c.o kernelvec.S.o main.c.o -lc -L/opt/riscv32/riscv32-unknown-elf/lib/ -Tlink.ld -nostartfiles -static -o $ELFFILE
riscv32-unknown-elf-objcopy -O binary $ELFFILE $BINFILE
#
echo $BINFILE | python3 ../test/bin2hex.py
riscv32-unknown-elf-objdump -d $ELFFILE > $DUMPFILE
rm $BINFILE $ELFFILE entry.S.o start.c.o kernelvec.S.o main.c.o