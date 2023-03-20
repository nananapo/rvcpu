#include "riscv.h"

void start();
void timerinit();

extern void main(void);
extern void timervec(void);

unsigned int timer_scratch[7]; 

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

    // satpを0にすることでページングを無効にする
    // まだページングは実装していないが...
    w_satp(0);

    // 全部のexceptionとinterruptをS-modeに委譲する
    w_medeleg(0xffff);
    w_mideleg(0xffff);
    // S-modeでexception, timer interrupt, software interruptを有効にする
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

    // configure Physical Memory Protection to give supervisor mode
    // access to all of physical memory.
    // ↑メモリプロテクションなんて実装してません...
    w_pmpaddr0(0x3fffffffu);
    w_pmpcfg0(0xf);

    // タイマ割込みの設定をする
    timerinit();

    // keep each CPU's hartid in its tp register, for cpuid().
    // mhartidは常に0なのでメモリを節約させてください
    // int id = r_mhartid();
    // w_tp(id);

    // mretで、S-modeになる
    // そしてmainに飛ぶ
    asm volatile("mret");
}

void
timerinit()
{
    // each CPU has a separate source of timer interrupts.
    // int id = r_mhartid();

    // 次の割り込みを0.1秒後に設定する
    // CPUの実装ではtimeはマイクロ秒単位なので100000になる
    unsigned int interval = 100000;

    unsigned int mtime = *CLINT_MTIME; // 現在の時間
    unsigned int mtimeh = *CLINT_MTIMEH;

    // mtimecmp, mtimecmphを設定
    if (mtime + interval < mtime)
        mtimeh += 1;
    *CLINT_MTIMECMPH = mtimeh;
    *CLINT_MTIMECMP = mtime + interval;
    
    // タイマ割込みの時に使う情報をmscratchに入れる
    // scratch[0..3] : timervecで一時的にレジスタの値を避難させる場所
    // scratch[4] : mtimecmpのアドレス
    // scratch[5] : mtimecmphのアドレス
    // scratch[6] : interval
    unsigned int *scratch = timer_scratch;
    scratch[4] = CLINT_MTIMECMP;
    scratch[5] = CLINT_MTIMECMPH;
    scratch[6] = interval;
    w_mscratch((unsigned int)scratch);

    // トラップ先をtimervecに設定する
    w_mtvec((unsigned int)timervec);

    // M-modeでの割り込みを有効にする
    // 　これが必要な理由がわからない。
    // 　タイマ割込みはS-modeで処理されるのでsieとstieが
    // 　1ならいいのではと思うけれど、何か勘違いしてそうだ
    w_mstatus(r_mstatus() | MSTATUS_MIE);

    // M-modeでのタイマ割込みを有効化
    w_mie(r_mie() | MIE_MTIE);
}
