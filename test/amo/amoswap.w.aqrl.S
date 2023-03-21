.section .text
.global main
main:
    li a0, 0
    li a1, 4
    li a2, 100
    li a3, 15
    sw a1, 100(a0) # 100に4を入れる
    amoswap.w.aqrl t0, a3, (a2) # 100を読んでt0に入れて、100に15を入れる
    lw t1, 100(a0) # 100を読み込む

riscv32-unknown-elf-ld amoswap.w.aqrl.S -lc -L/opt/riscv32/riscv32-unknown-elf/lib/ -T../c/link.ld -nostartfiles -static -o amoswap.w.aqrl.elf
