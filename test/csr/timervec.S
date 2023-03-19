.global timervec
.global timer_interrupt
timervec:
    # make room to save registers.
    addi sp, sp, -256

    # save the registers.
    sw ra, 0(sp)
    sw sp, 8(sp)
    sw gp, 16(sp)
    sw tp, 24(sp)
    sw t0, 32(sp)
    sw t1, 40(sp)
    sw t2, 48(sp)
    sw s0, 56(sp)
    sw s1, 64(sp)
    sw a0, 72(sp)
    sw a1, 80(sp)
    sw a2, 88(sp)
    sw a3, 96(sp)
    sw a4, 104(sp)
    sw a5, 112(sp)
    sw a6, 120(sp)
    sw a7, 128(sp)
    sw s2, 136(sp)
    sw s3, 144(sp)
    sw s4, 152(sp)
    sw s5, 160(sp)
    sw s6, 168(sp)
    sw s7, 176(sp)
    sw s8, 184(sp)
    sw s9, 192(sp)
    sw s10, 200(sp)
    sw s11, 208(sp)
    sw t3, 216(sp)
    sw t4, 224(sp)
    sw t5, 232(sp)
    sw t6, 240(sp)

    call timer_interrupt

    # restore registers.
    lw ra, 0(sp)
    lw sp, 8(sp)
    lw gp, 16(sp)
    lw tp, 24(sp)
    lw t0, 32(sp)
    lw t1, 40(sp)
    lw t2, 48(sp)
    lw s0, 56(sp)
    lw s1, 64(sp)
    lw a0, 72(sp)
    lw a1, 80(sp)
    lw a2, 88(sp)
    lw a3, 96(sp)
    lw a4, 104(sp)
    lw a5, 112(sp)
    lw a6, 120(sp)
    lw a7, 128(sp)
    lw s2, 136(sp)
    lw s3, 144(sp)
    lw s4, 152(sp)
    lw s5, 160(sp)
    lw s6, 168(sp)
    lw s7, 176(sp)
    lw s8, 184(sp)
    lw s9, 192(sp)
    lw s10, 200(sp)
    lw s11, 208(sp)
    lw t3, 216(sp)
    lw t4, 224(sp)
    lw t5, 232(sp)
    lw t6, 240(sp)

    addi sp, sp, 256

    mret