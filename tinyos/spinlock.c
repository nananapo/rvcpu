#include "riscv.h"
#include "spinlock.h"

// なんで例外を起こさないようにするんだっけ...

void spinlock_init(struct spinlock *lock)
{
    lock->locked = 0;
    lock->cpuid = 0;
}

void spinlock_acquire(struct spinlock *lock)
{
    __sync_synchronize();
    /*
    intr_off(); // 例外を無効にする

    if (lock->locked && lock->cpuid == mycpu())
        panic();
    */

    // testandsetでlockがアトミックにロックをとる
    // 過去の値が0ならロックをとれている
    // それ以外なら取れてない
    // lock操作はアトミックに行われるので、ここでタイマ割込みされても大丈夫
    while(amoswap(&lock->locked, 1) != 0);
    lock->cpuid = mycpu();

    /*
    intr_on(); // 例外を有効にする
    */
    __sync_synchronize();
}

void spinlock_release(struct spinlock *lock)
{
    __sync_synchronize();
    /*
    intr_off(); // 例外を無効にする

    if (!lock->locked || lock->cpuid != mycpu())
        panic();
    */

    amoswap(&lock->locked, 0);
    
    /*
    intr_on(); // 例外を有効にする
    */
    __sync_synchronize();
}