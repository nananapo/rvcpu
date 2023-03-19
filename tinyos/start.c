#include "csr.h"

void start(void)
{
    unsigned int mstatus;
    
    // mretはMPPに指定された権限モードに移行する(3.1.6.1)ので、
    // MPPを1(S-mode)(1.2 Table 1.1)に設定する
    mstatus = r_mstatus();
    mstatus &= ~MSTATUS_MPP_MASK;
    mstatus |= MSTATUS_MPP_S;
    w_mstatus(mstatus);

    // mretはmepcにpcを設定する(3.1.14)ので、
    // mepcにmainのアドレスを設定することでmainに戻れるようにする
    w_mepc((unsigned int)main);

    // mretで、S-modeになる
    // そしてmainに飛ぶ
    asm volatile("mret");
}