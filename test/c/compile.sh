FILE=$1
BINFILE="${FILE}.bin"
OBJFILE="temp.obj"
ELFFILE="temp.elf"
DUMPFILE="${BINFILE}.dump"
echo $FILE
echo $OBJFILE
riscv32-unknown-elf-gcc -march=rv32im -O0 -c -o $OBJFILE $FILE
riscv32-unknown-elf-ld $OBJFILE -lc -L/opt/riscv32/riscv32-unknown-elf/lib/ -Tlink.ld -nostartfiles -static -o $ELFFILE
riscv32-unknown-elf-objcopy -O binary $ELFFILE $BINFILE
echo $BINFILE | python3 ../bin2hex.py
riscv32-unknown-elf-objdump -d $ELFFILE > $DUMPFILE
rm $BINFILE $OBJFILE $ELFFILE
