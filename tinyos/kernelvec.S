.globl timervec
.align 4
timervec:

        # start.c has set up the memory that mscratch points to:
        # scratch[0,4,8,12] : register save area.
        # scratch[16] : address of CLINT's MTIMECMP register.
        # scratch[20] : address of CLINT's MTIMECMPH register.
        # scratch[24] : desired interval between interrupts.
        
        # a0とmscratchを交換する
        csrrw a0, mscratch, a0

        # a1, a2, a3, a4を保存する
        sw a1, 0(a0)
        sw a2, 4(a0)
        sw a3, 8(a0)
        sw a4, 12(a0)

        # 次の割り込みのためにスケジュール
        lw a1, 16(a0)   # mtimecmp
        lw a2, 24(a0)   # interval
        
        lw a3, 0(a1)    # *mtimecmp
        add a4, a2, a3  # a4 = *mtimecmp + interval
        sw a4, 0(a1)    # *mtimecmp = a4
        
        bge a4, a3, notincrement_mtimecmph
        
        # mtimecmph += 1する
        lw a3, 20(a0)   # mtimecmph
        lw a4, 0(a3)    # a4 = *mtimecmph
        addi a4, a4, 1  # a4 += 1
        sw a4, 0(a3)    # *mtimecmph = a4

notincrement_mtimecmph:

        # sip (Supervisor Pending Interrupts)の
        # SSIP (SupervisorのSoftware InterruptのPending)ビットを立てる。
        # これにより、mret後にS-modeでソフトウェア割り込みが発生する
        # (ref 3.1.9)
        li a1, 2
        csrw sip, a1

        # レジスタを復元する
        lw a4, 12(a0)
        lw a3, 8(a0)
        lw a2, 4(a0)
        lw a1, 0(a0)
        csrrw a0, mscratch, a0

        mret
