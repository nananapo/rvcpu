#ifndef SPINLOCK_H
# define SPINLOCK_H

struct spinlock {
  unsigned int locked;  // ロックされているかどうか
  unsigned int cpuid;   // cpuのid(hartid) 
};

void spinlock_init(struct spinlock *lock);
void spinlock_acquire(struct spinlock *lock);
void spinlock_release(struct spinlock *lock);

#endif