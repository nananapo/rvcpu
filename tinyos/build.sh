ELFFILE="kernel.elf"
BINFILE="kernel.bin"
DUMPFILE="${BINFILE}.dump"
GCC_OPTION="-march=rv32ima -c -O3"
LD_OPTION="-lc -L/opt/riscv32/riscv32-unknown-elf/lib/ -Tlink.ld -nostartfiles -static"
OBJS="entry.S.o start.c.o kernelvec.S.o main.c.o"
#
riscv32-unknown-elf-gcc $GCC_OPTION -o entry.S.o entry.S
riscv32-unknown-elf-gcc $GCC_OPTION -o start.c.o start.c
riscv32-unknown-elf-gcc $GCC_OPTION -o kernelvec.S.o kernelvec.S
riscv32-unknown-elf-gcc $GCC_OPTION -o main.c.o main.c
#
riscv32-unknown-elf-ld $LD_OPTION $OBJS -o $ELFFILE
riscv32-unknown-elf-objcopy -O binary $ELFFILE $BINFILE
#
echo $BINFILE | python3 ../test/bin2hex.py
riscv32-unknown-elf-objdump -d $ELFFILE > $DUMPFILE
rm $BINFILE $ELFFILE $OBJS