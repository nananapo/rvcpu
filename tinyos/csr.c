#define MSTATUS_MPP_MASK (3L << 11) // previous mode.
#define MSTATUS_MPP_M (3L << 11)
#define MSTATUS_MPP_S (1L << 11)
#define MSTATUS_MPP_U (0L << 11)
#define MSTATUS_MIE (1L << 3)    // machine-mode interrupt enable.

static inline unsigned int r_mstatus()
{
  unsigned int x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
  return x;
}


static inline void w_mstatus(unsigned int x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
}