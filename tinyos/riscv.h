#define CLINT_MTIME ((volatile unsigned int *)0xf0000000)
#define CLINT_MTIMEH ((volatile unsigned int *)0xf0000004)
#define CLINT_MTIMECMP ((volatile unsigned int *)0xf0000008)
#define CLINT_MTIMECMPH ((volatile unsigned int *)0xf000000c)

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

static inline void w_mepc(unsigned int x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
}

static inline void w_medeleg(unsigned int x)
{
  asm volatile("csrw medeleg, %0" : : "r" (x));
}

static inline void w_mideleg(unsigned int x)
{
  asm volatile("csrw mideleg, %0" : : "r" (x));
}

// Machine-mode Interrupt Enable
#define MIE_MEIE (1L << 11) // external
#define MIE_MTIE (1L << 7)  // timer
#define MIE_MSIE (1L << 3)  // software

static inline unsigned int r_mie()
{
  unsigned int x;
  asm volatile("csrr %0, mie" : "=r" (x) );
  return x;
}

static inline void w_mie(unsigned int x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
}

static inline void w_mscratch(unsigned int x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
}

static inline void w_mtvec(unsigned int x)
{
  asm volatile("csrw mtvec, %0" : : "r" (x));
}

static inline void w_pmpaddr0(unsigned int x)
{
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
}

static inline void w_pmpcfg0(unsigned int x)
{
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
}

static inline void w_satp(unsigned int x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
}

// Supervisor Interrupt Enable
#define SIE_SEIE (1L << 9) // external
#define SIE_STIE (1L << 5) // timer
#define SIE_SSIE (1L << 1) // software

static inline unsigned int r_sie()
{
  unsigned int x;
  asm volatile("csrr %0, sie" : "=r" (x) );
  return x;
}

static inline void w_sie(unsigned int x)
{
  asm volatile("csrw sie, %0" : : "r" (x));
}