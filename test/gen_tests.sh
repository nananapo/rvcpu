find riscv-tests -type file ! -name "*\.*" -exec sh -c "riscv64-unknown-elf-objcopy -O binary {} {}.bin" \;
find riscv-tests -type file ! -name "*\.*" -exec sh -c "echo \"{}.bin\" | python3 bin2hex.py" \;