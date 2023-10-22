export FILE=timeh_test.c
export BINFILE="$FILE.bin"
export OBJFILE="temp.obj"
export ELFFILE="temp.elf"
export DUMPFILE="$BINFILE.dump"
echo $FILE
echo $OBJFILE
riscv32-unknown-elf-gcc -march=rv32im_zicsr -O0 -c -o $OBJFILE $FILE
riscv32-unknown-elf-ld $OBJFILE -L/opt/riscv32/riscv32-unknown-elf/lib/ -Tlink.ld -static -o $ELFFILE
riscv32-unknown-elf-objcopy -O binary $ELFFILE $BINFILE
echo $BINFILE | python3 ../bin2hex.py
riscv32-unknown-elf-objdump -d $ELFFILE > $DUMPFILE
rm $BINFILE $OBJFILE $ELFFILE
