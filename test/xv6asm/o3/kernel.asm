
kernel/kernel:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <_entry>:
       0:	0000d117          	auipc	sp,0xd
       4:	40010113          	add	sp,sp,1024 # d400 <stack0>
       8:	00001537          	lui	a0,0x1
       c:	f14025f3          	csrr	a1,mhartid
      10:	00158593          	add	a1,a1,1
      14:	02b50533          	mul	a0,a0,a1
      18:	00a10133          	add	sp,sp,a0
      1c:	008000ef          	jal	24 <start>

00000020 <junk>:
      20:	0000006f          	j	20 <junk>

00000024 <start>:
void uartputc(int c);

// entry.S jumps here in machine mode on stack0.
void
start()
{
      24:	ff010113          	add	sp,sp,-16
      28:	00812623          	sw	s0,12(sp)
      2c:	01010413          	add	s0,sp,16

static inline uint32
r_mstatus()
{
  uint32 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
      30:	300027f3          	csrr	a5,mstatus
  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
      34:	ffffe737          	lui	a4,0xffffe
      38:	7ff70713          	add	a4,a4,2047 # ffffe7ff <end+0xfffda7eb>
      3c:	00e7f7b3          	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
      40:	00001737          	lui	a4,0x1
      44:	80070713          	add	a4,a4,-2048 # 800 <printf+0xd0>
      48:	00e7e7b3          	or	a5,a5,a4
}

static inline void 
w_mstatus(uint32 x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
      4c:	30079073          	csrw	mstatus,a5
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint32 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
      50:	0000b797          	auipc	a5,0xb
      54:	0e078793          	add	a5,a5,224 # b130 <main>
      58:	34179073          	csrw	mepc,a5
// supervisor address translation and protection;
// holds the address of the page table.
static inline void 
w_satp(uint32 x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
      5c:	00000793          	li	a5,0
      60:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
      64:	000107b7          	lui	a5,0x10
      68:	fff78793          	add	a5,a5,-1 # ffff <stack0+0x2bff>
      6c:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
      70:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
      74:	f1402673          	csrr	a2,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  uint32 interval = 100000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
      78:	f00005b7          	lui	a1,0xf0000
      7c:	0005a703          	lw	a4,0(a1) # f0000000 <end+0xeffdbfec>
      80:	000186b7          	lui	a3,0x18
      84:	0045a803          	lw	a6,4(a1)
      88:	6a068693          	add	a3,a3,1696 # 186a0 <proc+0x2fbc>
      8c:	00d70533          	add	a0,a4,a3
      90:	00160793          	add	a5,a2,1
      94:	00e53733          	sltu	a4,a0,a4
      98:	00379793          	sll	a5,a5,0x3
      9c:	00b787b3          	add	a5,a5,a1
      a0:	01070733          	add	a4,a4,a6
      a4:	00e7a223          	sw	a4,4(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint32 *scratch = &mscratch0[32 * id];
      a8:	00761613          	sll	a2,a2,0x7
      ac:	0000d717          	auipc	a4,0xd
      b0:	f5470713          	add	a4,a4,-172 # d000 <mscratch0>
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
      b4:	00a7a023          	sw	a0,0(a5)
  uint32 *scratch = &mscratch0[32 * id];
      b8:	00c70733          	add	a4,a4,a2
  scratch[4] = CLINT_MTIMECMP(id);
      bc:	00f72823          	sw	a5,16(a4)
  scratch[5] = interval;
      c0:	00d72a23          	sw	a3,20(a4)
}

static inline void 
w_mscratch(uint32 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
      c4:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
      c8:	0000a797          	auipc	a5,0xa
      cc:	cc878793          	add	a5,a5,-824 # 9d90 <timervec>
      d0:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
      d4:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint32)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
      d8:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
      dc:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
      e0:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  #define MIE_SEIE (1 << 9)
  w_mie(r_mie() | MIE_MTIE | MIE_SEIE);
      e4:	2807e793          	or	a5,a5,640
  asm volatile("csrw mie, %0" : : "r" (x));
      e8:	30479073          	csrw	mie,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
      ec:	f14027f3          	csrr	a5,mhartid
}

static inline void 
w_tp(uint32 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
      f0:	00078213          	mv	tp,a5
  asm volatile("mret");
      f4:	30200073          	mret
}
      f8:	00c12403          	lw	s0,12(sp)
      fc:	01010113          	add	sp,sp,16
     100:	00008067          	ret

00000104 <timerinit>:
{
     104:	ff010113          	add	sp,sp,-16
     108:	00812623          	sw	s0,12(sp)
     10c:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
     110:	f1402673          	csrr	a2,mhartid
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
     114:	f00005b7          	lui	a1,0xf0000
     118:	0005a703          	lw	a4,0(a1) # f0000000 <end+0xeffdbfec>
     11c:	000186b7          	lui	a3,0x18
     120:	0045a803          	lw	a6,4(a1)
     124:	6a068693          	add	a3,a3,1696 # 186a0 <proc+0x2fbc>
     128:	00d70533          	add	a0,a4,a3
     12c:	00160793          	add	a5,a2,1
     130:	00e53733          	sltu	a4,a0,a4
     134:	00379793          	sll	a5,a5,0x3
     138:	00b787b3          	add	a5,a5,a1
     13c:	01070733          	add	a4,a4,a6
     140:	00e7a223          	sw	a4,4(a5)
  uint32 *scratch = &mscratch0[32 * id];
     144:	00761613          	sll	a2,a2,0x7
     148:	0000d717          	auipc	a4,0xd
     14c:	eb870713          	add	a4,a4,-328 # d000 <mscratch0>
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
     150:	00a7a023          	sw	a0,0(a5)
  uint32 *scratch = &mscratch0[32 * id];
     154:	00c70733          	add	a4,a4,a2
  scratch[4] = CLINT_MTIMECMP(id);
     158:	00f72823          	sw	a5,16(a4)
  scratch[5] = interval;
     15c:	00d72a23          	sw	a3,20(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
     160:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
     164:	0000a797          	auipc	a5,0xa
     168:	c2c78793          	add	a5,a5,-980 # 9d90 <timervec>
     16c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
     170:	300027f3          	csrr	a5,mstatus
  w_mstatus(r_mstatus() | MSTATUS_MIE);
     174:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
     178:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
     17c:	304027f3          	csrr	a5,mie
  w_mie(r_mie() | MIE_MTIE | MIE_SEIE);
     180:	2807e793          	or	a5,a5,640
  asm volatile("csrw mie, %0" : : "r" (x));
     184:	30479073          	csrw	mie,a5
}
     188:	00c12403          	lw	s0,12(sp)
     18c:	01010113          	add	sp,sp,16
     190:	00008067          	ret

00000194 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint32 dst, int n)
{
     194:	fc010113          	add	sp,sp,-64
     198:	02812c23          	sw	s0,56(sp)
     19c:	02912a23          	sw	s1,52(sp)
     1a0:	03212823          	sw	s2,48(sp)
     1a4:	03312623          	sw	s3,44(sp)
     1a8:	03412423          	sw	s4,40(sp)
     1ac:	03512223          	sw	s5,36(sp)
     1b0:	03612023          	sw	s6,32(sp)
     1b4:	02112e23          	sw	ra,60(sp)
     1b8:	01712e23          	sw	s7,28(sp)
     1bc:	04010413          	add	s0,sp,64
     1c0:	00050b13          	mv	s6,a0
  uint target;
  int c;
  char cbuf;

  target = n;
  acquire(&cons.lock);
     1c4:	00015517          	auipc	a0,0x15
     1c8:	23c50513          	add	a0,a0,572 # 15400 <cons>
{
     1cc:	00060993          	mv	s3,a2
     1d0:	00058a93          	mv	s5,a1
  target = n;
     1d4:	00060a13          	mv	s4,a2
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
     1d8:	00015497          	auipc	s1,0x15
     1dc:	22848493          	add	s1,s1,552 # 15400 <cons>
  acquire(&cons.lock);
     1e0:	00001097          	auipc	ra,0x1
     1e4:	f90080e7          	jalr	-112(ra) # 1170 <acquire>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
     1e8:	00015917          	auipc	s2,0x15
     1ec:	2a490913          	add	s2,s2,676 # 1548c <cons+0x8c>
  while(n > 0){
     1f0:	03304663          	bgtz	s3,21c <consoleread+0x88>
     1f4:	0840006f          	j	278 <consoleread+0xe4>
      if(myproc()->killed){
     1f8:	00003097          	auipc	ra,0x3
     1fc:	22c080e7          	jalr	556(ra) # 3424 <myproc>
     200:	00050793          	mv	a5,a0
     204:	0187a783          	lw	a5,24(a5)
      sleep(&cons.r, &cons.lock);
     208:	00048593          	mv	a1,s1
     20c:	00090513          	mv	a0,s2
      if(myproc()->killed){
     210:	08079063          	bnez	a5,290 <consoleread+0xfc>
      sleep(&cons.r, &cons.lock);
     214:	00004097          	auipc	ra,0x4
     218:	e58080e7          	jalr	-424(ra) # 406c <sleep>
    while(cons.r == cons.w){
     21c:	08c4a783          	lw	a5,140(s1)
     220:	0904a703          	lw	a4,144(s1)
     224:	fce78ae3          	beq	a5,a4,1f8 <consoleread+0x64>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];
     228:	07f7f713          	and	a4,a5,127
     22c:	00e48733          	add	a4,s1,a4
     230:	00c74b83          	lbu	s7,12(a4)
     234:	00178713          	add	a4,a5,1
     238:	08e4a623          	sw	a4,140(s1)

    if(c == C('D')){  // end-of-file
     23c:	00400713          	li	a4,4
     240:	08eb8863          	beq	s7,a4,2d0 <consoleread+0x13c>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
     244:	015a05b3          	add	a1,s4,s5
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
     248:	00100693          	li	a3,1
     24c:	fcf40613          	add	a2,s0,-49
     250:	413585b3          	sub	a1,a1,s3
     254:	000b0513          	mv	a0,s6
    cbuf = c;
     258:	fd7407a3          	sb	s7,-49(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
     25c:	00004097          	auipc	ra,0x4
     260:	068080e7          	jalr	104(ra) # 42c4 <either_copyout>
     264:	fff00793          	li	a5,-1
     268:	00f50863          	beq	a0,a5,278 <consoleread+0xe4>
      break;

    dst++;
    --n;

    if(c == '\n'){
     26c:	00a00793          	li	a5,10
    --n;
     270:	fff98993          	add	s3,s3,-1
    if(c == '\n'){
     274:	f6fb9ee3          	bne	s7,a5,1f0 <consoleread+0x5c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
     278:	00015517          	auipc	a0,0x15
     27c:	18850513          	add	a0,a0,392 # 15400 <cons>
     280:	00001097          	auipc	ra,0x1
     284:	07c080e7          	jalr	124(ra) # 12fc <release>

  return target - n;
     288:	413a0533          	sub	a0,s4,s3
     28c:	0180006f          	j	2a4 <consoleread+0x110>
        release(&cons.lock);
     290:	00015517          	auipc	a0,0x15
     294:	17050513          	add	a0,a0,368 # 15400 <cons>
     298:	00001097          	auipc	ra,0x1
     29c:	064080e7          	jalr	100(ra) # 12fc <release>
        return -1;
     2a0:	fff00513          	li	a0,-1
}
     2a4:	03c12083          	lw	ra,60(sp)
     2a8:	03812403          	lw	s0,56(sp)
     2ac:	03412483          	lw	s1,52(sp)
     2b0:	03012903          	lw	s2,48(sp)
     2b4:	02c12983          	lw	s3,44(sp)
     2b8:	02812a03          	lw	s4,40(sp)
     2bc:	02412a83          	lw	s5,36(sp)
     2c0:	02012b03          	lw	s6,32(sp)
     2c4:	01c12b83          	lw	s7,28(sp)
     2c8:	04010113          	add	sp,sp,64
     2cc:	00008067          	ret
      if(n < target){
     2d0:	fb49f4e3          	bgeu	s3,s4,278 <consoleread+0xe4>
        cons.r--;
     2d4:	08f4a623          	sw	a5,140(s1)
     2d8:	fa1ff06f          	j	278 <consoleread+0xe4>

000002dc <consolewrite>:
{
     2dc:	fd010113          	add	sp,sp,-48
     2e0:	02812423          	sw	s0,40(sp)
     2e4:	02912223          	sw	s1,36(sp)
     2e8:	03212023          	sw	s2,32(sp)
     2ec:	01312e23          	sw	s3,28(sp)
     2f0:	01612823          	sw	s6,16(sp)
     2f4:	02112623          	sw	ra,44(sp)
     2f8:	01412c23          	sw	s4,24(sp)
     2fc:	01512a23          	sw	s5,20(sp)
     300:	03010413          	add	s0,sp,48
     304:	00050993          	mv	s3,a0
     308:	00060913          	mv	s2,a2
  acquire(&cons.lock);
     30c:	00015517          	auipc	a0,0x15
     310:	0f450513          	add	a0,a0,244 # 15400 <cons>
{
     314:	00058493          	mv	s1,a1
     318:	00b60b33          	add	s6,a2,a1
  acquire(&cons.lock);
     31c:	00001097          	auipc	ra,0x1
     320:	e54080e7          	jalr	-428(ra) # 1170 <acquire>
  for(i = 0; i < n; i++){
     324:	05205463          	blez	s2,36c <consolewrite+0x90>
     328:	fff00a13          	li	s4,-1
     32c:	00024a97          	auipc	s5,0x24
     330:	cd4a8a93          	add	s5,s5,-812 # 24000 <panicked>
    if(either_copyin(&c, user_src, src+i, 1) == -1)
     334:	00048613          	mv	a2,s1
     338:	00100693          	li	a3,1
     33c:	00098593          	mv	a1,s3
     340:	fdf40513          	add	a0,s0,-33
     344:	00004097          	auipc	ra,0x4
     348:	05c080e7          	jalr	92(ra) # 43a0 <either_copyin>
  for(i = 0; i < n; i++){
     34c:	00148493          	add	s1,s1,1
    if(either_copyin(&c, user_src, src+i, 1) == -1)
     350:	01450e63          	beq	a0,s4,36c <consolewrite+0x90>
  if(panicked){
     354:	000aa783          	lw	a5,0(s5)
     358:	04079863          	bnez	a5,3a8 <consolewrite+0xcc>
    uartputc(c);
     35c:	fdf44503          	lbu	a0,-33(s0)
     360:	00001097          	auipc	ra,0x1
     364:	a24080e7          	jalr	-1500(ra) # d84 <uartputc>
  for(i = 0; i < n; i++){
     368:	fd6496e3          	bne	s1,s6,334 <consolewrite+0x58>
  release(&cons.lock);
     36c:	00015517          	auipc	a0,0x15
     370:	09450513          	add	a0,a0,148 # 15400 <cons>
     374:	00001097          	auipc	ra,0x1
     378:	f88080e7          	jalr	-120(ra) # 12fc <release>
}
     37c:	02c12083          	lw	ra,44(sp)
     380:	02812403          	lw	s0,40(sp)
     384:	02412483          	lw	s1,36(sp)
     388:	01c12983          	lw	s3,28(sp)
     38c:	01812a03          	lw	s4,24(sp)
     390:	01412a83          	lw	s5,20(sp)
     394:	01012b03          	lw	s6,16(sp)
     398:	00090513          	mv	a0,s2
     39c:	02012903          	lw	s2,32(sp)
     3a0:	03010113          	add	sp,sp,48
     3a4:	00008067          	ret
    for(;;)
     3a8:	0000006f          	j	3a8 <consolewrite+0xcc>

000003ac <consputc>:
  if(panicked){
     3ac:	00024717          	auipc	a4,0x24
     3b0:	c5472703          	lw	a4,-940(a4) # 24000 <panicked>
     3b4:	00071a63          	bnez	a4,3c8 <consputc+0x1c>
  if(c == BACKSPACE){
     3b8:	10000713          	li	a4,256
     3bc:	00e50863          	beq	a0,a4,3cc <consputc+0x20>
    uartputc(c);
     3c0:	00001317          	auipc	t1,0x1
     3c4:	9c430067          	jr	-1596(t1) # d84 <uartputc>
    for(;;)
     3c8:	0000006f          	j	3c8 <consputc+0x1c>
{
     3cc:	ff010113          	add	sp,sp,-16
     3d0:	00112623          	sw	ra,12(sp)
     3d4:	00812423          	sw	s0,8(sp)
     3d8:	01010413          	add	s0,sp,16
    uartputc('\b'); uartputc(' '); uartputc('\b');
     3dc:	00800513          	li	a0,8
     3e0:	00001097          	auipc	ra,0x1
     3e4:	9a4080e7          	jalr	-1628(ra) # d84 <uartputc>
     3e8:	02000513          	li	a0,32
     3ec:	00001097          	auipc	ra,0x1
     3f0:	998080e7          	jalr	-1640(ra) # d84 <uartputc>
}
     3f4:	00812403          	lw	s0,8(sp)
     3f8:	00c12083          	lw	ra,12(sp)
    uartputc('\b'); uartputc(' '); uartputc('\b');
     3fc:	00800513          	li	a0,8
}
     400:	01010113          	add	sp,sp,16
    uartputc('\b'); uartputc(' '); uartputc('\b');
     404:	00001317          	auipc	t1,0x1
     408:	98030067          	jr	-1664(t1) # d84 <uartputc>

0000040c <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
     40c:	fe010113          	add	sp,sp,-32
     410:	00812c23          	sw	s0,24(sp)
     414:	00912a23          	sw	s1,20(sp)
     418:	01212823          	sw	s2,16(sp)
     41c:	00112e23          	sw	ra,28(sp)
     420:	01312623          	sw	s3,12(sp)
     424:	02010413          	add	s0,sp,32
  acquire(&cons.lock);
     428:	00015917          	auipc	s2,0x15
     42c:	fd890913          	add	s2,s2,-40 # 15400 <cons>
{
     430:	00050493          	mv	s1,a0
  acquire(&cons.lock);
     434:	00090513          	mv	a0,s2
     438:	00001097          	auipc	ra,0x1
     43c:	d38080e7          	jalr	-712(ra) # 1170 <acquire>

  switch(c){
     440:	01500793          	li	a5,21
     444:	10f48e63          	beq	s1,a5,560 <consoleintr+0x154>
     448:	0497c263          	blt	a5,s1,48c <consoleintr+0x80>
     44c:	00800793          	li	a5,8
     450:	0cf48463          	beq	s1,a5,518 <consoleintr+0x10c>
     454:	01000793          	li	a5,16
     458:	16f49e63          	bne	s1,a5,5d4 <consoleintr+0x1c8>
  case C('P'):  // Print process list.
    procdump();
     45c:	00004097          	auipc	ra,0x4
     460:	020080e7          	jalr	32(ra) # 447c <procdump>
    }
    break;
  }
  
  release(&cons.lock);
}
     464:	01812403          	lw	s0,24(sp)
     468:	01c12083          	lw	ra,28(sp)
     46c:	01412483          	lw	s1,20(sp)
     470:	01012903          	lw	s2,16(sp)
     474:	00c12983          	lw	s3,12(sp)
  release(&cons.lock);
     478:	00015517          	auipc	a0,0x15
     47c:	f8850513          	add	a0,a0,-120 # 15400 <cons>
}
     480:	02010113          	add	sp,sp,32
  release(&cons.lock);
     484:	00001317          	auipc	t1,0x1
     488:	e7830067          	jr	-392(t1) # 12fc <release>
  switch(c){
     48c:	07f00793          	li	a5,127
     490:	08f48463          	beq	s1,a5,518 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
     494:	09492703          	lw	a4,148(s2)
     498:	08c92683          	lw	a3,140(s2)
     49c:	40d70733          	sub	a4,a4,a3
     4a0:	fce7e2e3          	bltu	a5,a4,464 <consoleintr+0x58>
  if(panicked){
     4a4:	00024797          	auipc	a5,0x24
     4a8:	b5c7a783          	lw	a5,-1188(a5) # 24000 <panicked>
     4ac:	18079663          	bnez	a5,638 <consoleintr+0x22c>
  if(c == BACKSPACE){
     4b0:	10000793          	li	a5,256
     4b4:	18f49463          	bne	s1,a5,63c <consoleintr+0x230>
    uartputc('\b'); uartputc(' '); uartputc('\b');
     4b8:	00800513          	li	a0,8
     4bc:	00001097          	auipc	ra,0x1
     4c0:	8c8080e7          	jalr	-1848(ra) # d84 <uartputc>
     4c4:	02000513          	li	a0,32
     4c8:	00001097          	auipc	ra,0x1
     4cc:	8bc080e7          	jalr	-1860(ra) # d84 <uartputc>
     4d0:	00800513          	li	a0,8
     4d4:	00001097          	auipc	ra,0x1
     4d8:	8b0080e7          	jalr	-1872(ra) # d84 <uartputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
     4dc:	09492783          	lw	a5,148(s2)
     4e0:	07f7f713          	and	a4,a5,127
     4e4:	00e90733          	add	a4,s2,a4
     4e8:	00178793          	add	a5,a5,1
     4ec:	08f92a23          	sw	a5,148(s2)
     4f0:	00070623          	sb	zero,12(a4)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
     4f4:	08c92703          	lw	a4,140(s2)
     4f8:	08070713          	add	a4,a4,128
     4fc:	f6f714e3          	bne	a4,a5,464 <consoleintr+0x58>
        wakeup(&cons.r);
     500:	00015517          	auipc	a0,0x15
     504:	f8c50513          	add	a0,a0,-116 # 1548c <cons+0x8c>
        cons.w = cons.e;
     508:	08f92823          	sw	a5,144(s2)
        wakeup(&cons.r);
     50c:	00004097          	auipc	ra,0x4
     510:	c4c080e7          	jalr	-948(ra) # 4158 <wakeup>
     514:	f51ff06f          	j	464 <consoleintr+0x58>
    if(cons.e != cons.w){
     518:	09492783          	lw	a5,148(s2)
     51c:	09092703          	lw	a4,144(s2)
     520:	f4e782e3          	beq	a5,a4,464 <consoleintr+0x58>
      cons.e--;
     524:	fff78793          	add	a5,a5,-1
     528:	08f92a23          	sw	a5,148(s2)
  if(panicked){
     52c:	00024797          	auipc	a5,0x24
     530:	ad47a783          	lw	a5,-1324(a5) # 24000 <panicked>
     534:	08079e63          	bnez	a5,5d0 <consoleintr+0x1c4>
    uartputc('\b'); uartputc(' '); uartputc('\b');
     538:	00800513          	li	a0,8
     53c:	00001097          	auipc	ra,0x1
     540:	848080e7          	jalr	-1976(ra) # d84 <uartputc>
     544:	02000513          	li	a0,32
     548:	00001097          	auipc	ra,0x1
     54c:	83c080e7          	jalr	-1988(ra) # d84 <uartputc>
     550:	00800513          	li	a0,8
     554:	00001097          	auipc	ra,0x1
     558:	830080e7          	jalr	-2000(ra) # d84 <uartputc>
}
     55c:	f09ff06f          	j	464 <consoleintr+0x58>
    while(cons.e != cons.w &&
     560:	09492783          	lw	a5,148(s2)
     564:	09092703          	lw	a4,144(s2)
     568:	00a00493          	li	s1,10
  if(panicked){
     56c:	00024997          	auipc	s3,0x24
     570:	a9498993          	add	s3,s3,-1388 # 24000 <panicked>
    while(cons.e != cons.w &&
     574:	eee788e3          	beq	a5,a4,464 <consoleintr+0x58>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
     578:	fff78793          	add	a5,a5,-1
     57c:	07f7f713          	and	a4,a5,127
     580:	00e90733          	add	a4,s2,a4
    while(cons.e != cons.w &&
     584:	00c74703          	lbu	a4,12(a4)
    uartputc('\b'); uartputc(' '); uartputc('\b');
     588:	00800513          	li	a0,8
    while(cons.e != cons.w &&
     58c:	ec970ce3          	beq	a4,s1,464 <consoleintr+0x58>
  if(panicked){
     590:	0009a703          	lw	a4,0(s3)
      cons.e--;
     594:	08f92a23          	sw	a5,148(s2)
  if(panicked){
     598:	02071a63          	bnez	a4,5cc <consoleintr+0x1c0>
    uartputc('\b'); uartputc(' '); uartputc('\b');
     59c:	00000097          	auipc	ra,0x0
     5a0:	7e8080e7          	jalr	2024(ra) # d84 <uartputc>
     5a4:	02000513          	li	a0,32
     5a8:	00000097          	auipc	ra,0x0
     5ac:	7dc080e7          	jalr	2012(ra) # d84 <uartputc>
     5b0:	00800513          	li	a0,8
     5b4:	00000097          	auipc	ra,0x0
     5b8:	7d0080e7          	jalr	2000(ra) # d84 <uartputc>
    while(cons.e != cons.w &&
     5bc:	09492783          	lw	a5,148(s2)
     5c0:	09092703          	lw	a4,144(s2)
     5c4:	fae79ae3          	bne	a5,a4,578 <consoleintr+0x16c>
     5c8:	e9dff06f          	j	464 <consoleintr+0x58>
    for(;;)
     5cc:	0000006f          	j	5cc <consoleintr+0x1c0>
     5d0:	0000006f          	j	5d0 <consoleintr+0x1c4>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
     5d4:	e80488e3          	beqz	s1,464 <consoleintr+0x58>
     5d8:	09492783          	lw	a5,148(s2)
     5dc:	08c92683          	lw	a3,140(s2)
     5e0:	07f00713          	li	a4,127
     5e4:	40d787b3          	sub	a5,a5,a3
     5e8:	e6f76ee3          	bltu	a4,a5,464 <consoleintr+0x58>
      c = (c == '\r') ? '\n' : c;
     5ec:	00d00793          	li	a5,13
     5f0:	02f49e63          	bne	s1,a5,62c <consoleintr+0x220>
  if(panicked){
     5f4:	00024797          	auipc	a5,0x24
     5f8:	a0c7a783          	lw	a5,-1524(a5) # 24000 <panicked>
     5fc:	02079e63          	bnez	a5,638 <consoleintr+0x22c>
    uartputc(c);
     600:	00a00513          	li	a0,10
     604:	00000097          	auipc	ra,0x0
     608:	780080e7          	jalr	1920(ra) # d84 <uartputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
     60c:	09492783          	lw	a5,148(s2)
     610:	00a00693          	li	a3,10
     614:	07f7f713          	and	a4,a5,127
     618:	00e90733          	add	a4,s2,a4
     61c:	00178793          	add	a5,a5,1
     620:	08f92a23          	sw	a5,148(s2)
     624:	00d70623          	sb	a3,12(a4)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
     628:	ed9ff06f          	j	500 <consoleintr+0xf4>
  if(panicked){
     62c:	00024797          	auipc	a5,0x24
     630:	9d47a783          	lw	a5,-1580(a5) # 24000 <panicked>
     634:	00078463          	beqz	a5,63c <consoleintr+0x230>
    for(;;)
     638:	0000006f          	j	638 <consoleintr+0x22c>
    uartputc(c);
     63c:	00048513          	mv	a0,s1
     640:	00000097          	auipc	ra,0x0
     644:	744080e7          	jalr	1860(ra) # d84 <uartputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
     648:	09492783          	lw	a5,148(s2)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
     64c:	00a00693          	li	a3,10
      cons.buf[cons.e++ % INPUT_BUF] = c;
     650:	07f7f713          	and	a4,a5,127
     654:	00e90733          	add	a4,s2,a4
     658:	00178793          	add	a5,a5,1
     65c:	08f92a23          	sw	a5,148(s2)
     660:	00970623          	sb	s1,12(a4)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
     664:	e8d48ee3          	beq	s1,a3,500 <consoleintr+0xf4>
     668:	00400713          	li	a4,4
     66c:	e8e48ae3          	beq	s1,a4,500 <consoleintr+0xf4>
     670:	e85ff06f          	j	4f4 <consoleintr+0xe8>

00000674 <consoleinit>:

void
consoleinit(void)
{
     674:	ff010113          	add	sp,sp,-16
     678:	00112623          	sw	ra,12(sp)
     67c:	00812423          	sw	s0,8(sp)
     680:	01010413          	add	s0,sp,16
  initlock(&cons.lock, "cons");
     684:	0000b597          	auipc	a1,0xb
     688:	bc458593          	add	a1,a1,-1084 # b248 <main+0x118>
     68c:	00015517          	auipc	a0,0x15
     690:	d7450513          	add	a0,a0,-652 # 15400 <cons>
     694:	00001097          	auipc	ra,0x1
     698:	ab8080e7          	jalr	-1352(ra) # 114c <initlock>

  uartinit();
     69c:	00000097          	auipc	ra,0x0
     6a0:	6d0080e7          	jalr	1744(ra) # d6c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
  devsw[CONSOLE].write = consolewrite;
}
     6a4:	00c12083          	lw	ra,12(sp)
     6a8:	00812403          	lw	s0,8(sp)
  devsw[CONSOLE].read = consoleread;
     6ac:	00022797          	auipc	a5,0x22
     6b0:	83078793          	add	a5,a5,-2000 # 21edc <devsw>
     6b4:	00000717          	auipc	a4,0x0
     6b8:	ae070713          	add	a4,a4,-1312 # 194 <consoleread>
     6bc:	00e7a423          	sw	a4,8(a5)
  devsw[CONSOLE].write = consolewrite;
     6c0:	00000717          	auipc	a4,0x0
     6c4:	c1c70713          	add	a4,a4,-996 # 2dc <consolewrite>
     6c8:	00e7a623          	sw	a4,12(a5)
}
     6cc:	01010113          	add	sp,sp,16
     6d0:	00008067          	ret

000006d4 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
     6d4:	ff010113          	add	sp,sp,-16
     6d8:	00112623          	sw	ra,12(sp)
     6dc:	00812423          	sw	s0,8(sp)
     6e0:	00912223          	sw	s1,4(sp)
     6e4:	01010413          	add	s0,sp,16
     6e8:	00050493          	mv	s1,a0
  pr.locking = 0;
  printf("panic: ");
     6ec:	0000b517          	auipc	a0,0xb
     6f0:	b6450513          	add	a0,a0,-1180 # b250 <main+0x120>
  pr.locking = 0;
     6f4:	00015797          	auipc	a5,0x15
     6f8:	da07a823          	sw	zero,-592(a5) # 154a4 <pr+0xc>
  printf("panic: ");
     6fc:	00000097          	auipc	ra,0x0
     700:	034080e7          	jalr	52(ra) # 730 <printf>
  printf(s);
     704:	00048513          	mv	a0,s1
     708:	00000097          	auipc	ra,0x0
     70c:	028080e7          	jalr	40(ra) # 730 <printf>
  printf("\n");
     710:	0000b517          	auipc	a0,0xb
     714:	bc850513          	add	a0,a0,-1080 # b2d8 <main+0x1a8>
     718:	00000097          	auipc	ra,0x0
     71c:	018080e7          	jalr	24(ra) # 730 <printf>
  panicked = 1; // freeze other CPUs
     720:	00100793          	li	a5,1
     724:	00024717          	auipc	a4,0x24
     728:	8cf72e23          	sw	a5,-1828(a4) # 24000 <panicked>
  for(;;)
     72c:	0000006f          	j	72c <panic+0x58>

00000730 <printf>:
{
     730:	f7010113          	add	sp,sp,-144
     734:	06812423          	sw	s0,104(sp)
     738:	07212023          	sw	s2,96(sp)
     73c:	06112623          	sw	ra,108(sp)
     740:	06912223          	sw	s1,100(sp)
     744:	05312e23          	sw	s3,92(sp)
     748:	05412c23          	sw	s4,88(sp)
     74c:	05512a23          	sw	s5,84(sp)
     750:	05612823          	sw	s6,80(sp)
     754:	05712623          	sw	s7,76(sp)
     758:	05812423          	sw	s8,72(sp)
     75c:	05912223          	sw	s9,68(sp)
     760:	05a12023          	sw	s10,64(sp)
     764:	03b12e23          	sw	s11,60(sp)
     768:	07010413          	add	s0,sp,112
  locking = pr.locking;
     76c:	00015317          	auipc	t1,0x15
     770:	d2c30313          	add	t1,t1,-724 # 15498 <pr>
     774:	00c32e03          	lw	t3,12(t1)
{
     778:	00b42223          	sw	a1,4(s0)
     77c:	00c42423          	sw	a2,8(s0)
  locking = pr.locking;
     780:	f9c42c23          	sw	t3,-104(s0)
{
     784:	00d42623          	sw	a3,12(s0)
     788:	00e42823          	sw	a4,16(s0)
     78c:	00f42a23          	sw	a5,20(s0)
     790:	01042c23          	sw	a6,24(s0)
     794:	01142e23          	sw	a7,28(s0)
     798:	00050913          	mv	s2,a0
  if(locking)
     79c:	420e1c63          	bnez	t3,bd4 <printf+0x4a4>
  if (fmt == 0)
     7a0:	56090863          	beqz	s2,d10 <printf+0x5e0>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
     7a4:	00094503          	lbu	a0,0(s2)
  va_start(ap, fmt);
     7a8:	00440793          	add	a5,s0,4
     7ac:	faf42623          	sw	a5,-84(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
     7b0:	00000493          	li	s1,0
     7b4:	1c050c63          	beqz	a0,98c <printf+0x25c>
    if(c != '%'){
     7b8:	02500a13          	li	s4,37
    switch(c){
     7bc:	07000a93          	li	s5,112
     7c0:	0000bb97          	auipc	s7,0xb
     7c4:	0bcb8b93          	add	s7,s7,188 # b87c <digits>
     7c8:	07300c93          	li	s9,115
     7cc:	fb040993          	add	s3,s0,-80
     7d0:	06400c13          	li	s8,100
    buf[i++] = digits[x % base];
     7d4:	00a00b13          	li	s6,10
    if(c != '%'){
     7d8:	33451c63          	bne	a0,s4,b10 <printf+0x3e0>
    c = fmt[++i] & 0xff;
     7dc:	00148493          	add	s1,s1,1
     7e0:	009907b3          	add	a5,s2,s1
     7e4:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
     7e8:	1a078263          	beqz	a5,98c <printf+0x25c>
    switch(c){
     7ec:	35578c63          	beq	a5,s5,b44 <printf+0x414>
     7f0:	1efae063          	bltu	s5,a5,9d0 <printf+0x2a0>
     7f4:	3d478863          	beq	a5,s4,bc4 <printf+0x494>
     7f8:	31879063          	bne	a5,s8,af8 <printf+0x3c8>
      printint(va_arg(ap, int), 10, 1);
     7fc:	fac42783          	lw	a5,-84(s0)
     800:	0007a603          	lw	a2,0(a5)
     804:	00478793          	add	a5,a5,4
     808:	faf42623          	sw	a5,-84(s0)
  if(sign && (sign = xx < 0))
     80c:	40064463          	bltz	a2,c14 <printf+0x4e4>
    buf[i++] = digits[x % base];
     810:	00a00793          	li	a5,10
     814:	02f675b3          	remu	a1,a2,a5
     818:	0000b717          	auipc	a4,0xb
     81c:	06470713          	add	a4,a4,100 # b87c <digits>
  } while((x /= base) != 0);
     820:	00900513          	li	a0,9
    x = xx;
     824:	00060693          	mv	a3,a2
    buf[i++] = digits[x % base];
     828:	00b705b3          	add	a1,a4,a1
     82c:	0005c583          	lbu	a1,0(a1)
  } while((x /= base) != 0);
     830:	02f657b3          	divu	a5,a2,a5
    buf[i++] = digits[x % base];
     834:	fab40823          	sb	a1,-80(s0)
  } while((x /= base) != 0);
     838:	48c57c63          	bgeu	a0,a2,cd0 <printf+0x5a0>
     83c:	06300513          	li	a0,99
    buf[i++] = digits[x % base];
     840:	0367f5b3          	remu	a1,a5,s6
     844:	00b705b3          	add	a1,a4,a1
     848:	0005c583          	lbu	a1,0(a1)
  } while((x /= base) != 0);
     84c:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     850:	fab408a3          	sb	a1,-79(s0)
  } while((x /= base) != 0);
     854:	42d57463          	bgeu	a0,a3,c7c <printf+0x54c>
     858:	3e700513          	li	a0,999
    buf[i++] = digits[x % base];
     85c:	0367f5b3          	remu	a1,a5,s6
     860:	00b705b3          	add	a1,a4,a1
     864:	0005c583          	lbu	a1,0(a1)
  } while((x /= base) != 0);
     868:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     86c:	fab40923          	sb	a1,-78(s0)
  } while((x /= base) != 0);
     870:	42d57263          	bgeu	a0,a3,c94 <printf+0x564>
     874:	000025b7          	lui	a1,0x2
     878:	70f58593          	add	a1,a1,1807 # 270f <uvmunmap+0x7f>
    buf[i++] = digits[x % base];
     87c:	0367f533          	remu	a0,a5,s6
     880:	00a70533          	add	a0,a4,a0
     884:	00054503          	lbu	a0,0(a0)
  } while((x /= base) != 0);
     888:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     88c:	faa409a3          	sb	a0,-77(s0)
  } while((x /= base) != 0);
     890:	40d5f863          	bgeu	a1,a3,ca0 <printf+0x570>
     894:	000185b7          	lui	a1,0x18
     898:	69f58593          	add	a1,a1,1695 # 1869f <proc+0x2fbb>
    buf[i++] = digits[x % base];
     89c:	0367f533          	remu	a0,a5,s6
     8a0:	00a70533          	add	a0,a4,a0
     8a4:	00054503          	lbu	a0,0(a0)
  } while((x /= base) != 0);
     8a8:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     8ac:	faa40a23          	sb	a0,-76(s0)
  } while((x /= base) != 0);
     8b0:	40d5fa63          	bgeu	a1,a3,cc4 <printf+0x594>
     8b4:	000f45b7          	lui	a1,0xf4
     8b8:	23f58593          	add	a1,a1,575 # f423f <end+0xd022b>
    buf[i++] = digits[x % base];
     8bc:	0367f533          	remu	a0,a5,s6
     8c0:	00a70533          	add	a0,a4,a0
     8c4:	00054503          	lbu	a0,0(a0)
  } while((x /= base) != 0);
     8c8:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     8cc:	faa40aa3          	sb	a0,-75(s0)
  } while((x /= base) != 0);
     8d0:	40d5fe63          	bgeu	a1,a3,cec <printf+0x5bc>
     8d4:	009895b7          	lui	a1,0x989
     8d8:	67f58593          	add	a1,a1,1663 # 98967f <end+0x96566b>
    buf[i++] = digits[x % base];
     8dc:	0367f533          	remu	a0,a5,s6
     8e0:	00a70533          	add	a0,a4,a0
     8e4:	00054503          	lbu	a0,0(a0)
  } while((x /= base) != 0);
     8e8:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     8ec:	faa40b23          	sb	a0,-74(s0)
  } while((x /= base) != 0);
     8f0:	36d5fa63          	bgeu	a1,a3,c64 <printf+0x534>
     8f4:	05f5e5b7          	lui	a1,0x5f5e
     8f8:	0ff58593          	add	a1,a1,255 # 5f5e0ff <end+0x5f3a0eb>
    buf[i++] = digits[x % base];
     8fc:	0367f533          	remu	a0,a5,s6
     900:	00a70533          	add	a0,a4,a0
     904:	00054503          	lbu	a0,0(a0)
  } while((x /= base) != 0);
     908:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     90c:	faa40ba3          	sb	a0,-73(s0)
  } while((x /= base) != 0);
     910:	3ed5f463          	bgeu	a1,a3,cf8 <printf+0x5c8>
     914:	3b9ad5b7          	lui	a1,0x3b9ad
     918:	9ff58593          	add	a1,a1,-1537 # 3b9ac9ff <end+0x3b9889eb>
    buf[i++] = digits[x % base];
     91c:	0367f533          	remu	a0,a5,s6
     920:	00a70533          	add	a0,a4,a0
     924:	00054503          	lbu	a0,0(a0)
  } while((x /= base) != 0);
     928:	0367d7b3          	divu	a5,a5,s6
    buf[i++] = digits[x % base];
     92c:	faa40c23          	sb	a0,-72(s0)
  } while((x /= base) != 0);
     930:	3cd5fa63          	bgeu	a1,a3,d04 <printf+0x5d4>
    buf[i++] = digits[x % base];
     934:	00f707b3          	add	a5,a4,a5
     938:	0007c683          	lbu	a3,0(a5)
     93c:	00a00713          	li	a4,10
     940:	00900793          	li	a5,9
     944:	fad40ca3          	sb	a3,-71(s0)
  if(sign)
     948:	00065c63          	bgez	a2,960 <printf+0x230>
    buf[i++] = '-';
     94c:	fc070793          	add	a5,a4,-64
     950:	008787b3          	add	a5,a5,s0
     954:	02d00693          	li	a3,45
     958:	fed78823          	sb	a3,-16(a5)
     95c:	00070793          	mv	a5,a4
     960:	00f98d33          	add	s10,s3,a5
    consputc(buf[i]);
     964:	000d4503          	lbu	a0,0(s10)
     968:	00000097          	auipc	ra,0x0
     96c:	a44080e7          	jalr	-1468(ra) # 3ac <consputc>
  while(--i >= 0)
     970:	000d0713          	mv	a4,s10
     974:	fffd0d13          	add	s10,s10,-1
     978:	fee996e3          	bne	s3,a4,964 <printf+0x234>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
     97c:	00148493          	add	s1,s1,1
     980:	009907b3          	add	a5,s2,s1
     984:	0007c503          	lbu	a0,0(a5)
     988:	e40518e3          	bnez	a0,7d8 <printf+0xa8>
  if(locking)
     98c:	f9842783          	lw	a5,-104(s0)
     990:	1a079063          	bnez	a5,b30 <printf+0x400>
}
     994:	06c12083          	lw	ra,108(sp)
     998:	06812403          	lw	s0,104(sp)
     99c:	06412483          	lw	s1,100(sp)
     9a0:	06012903          	lw	s2,96(sp)
     9a4:	05c12983          	lw	s3,92(sp)
     9a8:	05812a03          	lw	s4,88(sp)
     9ac:	05412a83          	lw	s5,84(sp)
     9b0:	05012b03          	lw	s6,80(sp)
     9b4:	04c12b83          	lw	s7,76(sp)
     9b8:	04812c03          	lw	s8,72(sp)
     9bc:	04412c83          	lw	s9,68(sp)
     9c0:	04012d03          	lw	s10,64(sp)
     9c4:	03c12d83          	lw	s11,60(sp)
     9c8:	09010113          	add	sp,sp,144
     9cc:	00008067          	ret
    switch(c){
     9d0:	1d978263          	beq	a5,s9,b94 <printf+0x464>
     9d4:	07800713          	li	a4,120
     9d8:	12e79063          	bne	a5,a4,af8 <printf+0x3c8>
      printint(va_arg(ap, int), 16, 1);
     9dc:	fac42783          	lw	a5,-84(s0)
     9e0:	0007a683          	lw	a3,0(a5)
     9e4:	00478793          	add	a5,a5,4
     9e8:	faf42623          	sw	a5,-84(s0)
  if(sign && (sign = xx < 0))
     9ec:	1e06cc63          	bltz	a3,be4 <printf+0x4b4>
    buf[i++] = digits[x % base];
     9f0:	0000b717          	auipc	a4,0xb
     9f4:	e8c70713          	add	a4,a4,-372 # b87c <digits>
     9f8:	00f6f793          	and	a5,a3,15
     9fc:	00f707b3          	add	a5,a4,a5
     a00:	0007c583          	lbu	a1,0(a5)
  } while((x /= base) != 0);
     a04:	00f00613          	li	a2,15
    x = xx;
     a08:	00068793          	mv	a5,a3
    buf[i++] = digits[x % base];
     a0c:	fab40823          	sb	a1,-80(s0)
  } while((x /= base) != 0);
     a10:	0046d593          	srl	a1,a3,0x4
     a14:	2cd67263          	bgeu	a2,a3,cd8 <printf+0x5a8>
    buf[i++] = digits[x % base];
     a18:	00f5f613          	and	a2,a1,15
     a1c:	00c70633          	add	a2,a4,a2
     a20:	00064603          	lbu	a2,0(a2)
  } while((x /= base) != 0);
     a24:	00f00813          	li	a6,15
     a28:	0087d513          	srl	a0,a5,0x8
    buf[i++] = digits[x % base];
     a2c:	fac408a3          	sb	a2,-79(s0)
  } while((x /= base) != 0);
     a30:	24b87063          	bgeu	a6,a1,c70 <printf+0x540>
    buf[i++] = digits[x % base];
     a34:	00f57613          	and	a2,a0,15
     a38:	00c70633          	add	a2,a4,a2
     a3c:	00064603          	lbu	a2,0(a2)
  } while((x /= base) != 0);
     a40:	00c7d593          	srl	a1,a5,0xc
    buf[i++] = digits[x % base];
     a44:	fac40923          	sb	a2,-78(s0)
  } while((x /= base) != 0);
     a48:	24a87063          	bgeu	a6,a0,c88 <printf+0x558>
    buf[i++] = digits[x % base];
     a4c:	00f5f613          	and	a2,a1,15
     a50:	00c70633          	add	a2,a4,a2
     a54:	00064603          	lbu	a2,0(a2)
  } while((x /= base) != 0);
     a58:	0107d513          	srl	a0,a5,0x10
    buf[i++] = digits[x % base];
     a5c:	fac409a3          	sb	a2,-77(s0)
  } while((x /= base) != 0);
     a60:	24b87663          	bgeu	a6,a1,cac <printf+0x57c>
    buf[i++] = digits[x % base];
     a64:	00f57613          	and	a2,a0,15
     a68:	00c70633          	add	a2,a4,a2
     a6c:	00064603          	lbu	a2,0(a2)
  } while((x /= base) != 0);
     a70:	0147d593          	srl	a1,a5,0x14
    buf[i++] = digits[x % base];
     a74:	fac40a23          	sb	a2,-76(s0)
  } while((x /= base) != 0);
     a78:	24a87063          	bgeu	a6,a0,cb8 <printf+0x588>
    buf[i++] = digits[x % base];
     a7c:	00f5f613          	and	a2,a1,15
     a80:	00c70633          	add	a2,a4,a2
     a84:	00064603          	lbu	a2,0(a2)
  } while((x /= base) != 0);
     a88:	0187d513          	srl	a0,a5,0x18
    buf[i++] = digits[x % base];
     a8c:	fac40aa3          	sb	a2,-75(s0)
  } while((x /= base) != 0);
     a90:	24b87863          	bgeu	a6,a1,ce0 <printf+0x5b0>
    buf[i++] = digits[x % base];
     a94:	00f57613          	and	a2,a0,15
     a98:	00c70633          	add	a2,a4,a2
     a9c:	00064603          	lbu	a2,0(a2)
  } while((x /= base) != 0);
     aa0:	01c7d793          	srl	a5,a5,0x1c
    buf[i++] = digits[x % base];
     aa4:	fac40b23          	sb	a2,-74(s0)
  } while((x /= base) != 0);
     aa8:	1aa87863          	bgeu	a6,a0,c58 <printf+0x528>
    buf[i++] = digits[x % base];
     aac:	00f70733          	add	a4,a4,a5
     ab0:	00074603          	lbu	a2,0(a4)
     ab4:	00700793          	li	a5,7
     ab8:	00800713          	li	a4,8
     abc:	fac40ba3          	sb	a2,-73(s0)
  if(sign)
     ac0:	0006dc63          	bgez	a3,ad8 <printf+0x3a8>
    buf[i++] = '-';
     ac4:	fc070793          	add	a5,a4,-64
     ac8:	008787b3          	add	a5,a5,s0
     acc:	02d00693          	li	a3,45
     ad0:	fed78823          	sb	a3,-16(a5)
     ad4:	00070793          	mv	a5,a4
     ad8:	00f98d33          	add	s10,s3,a5
    consputc(buf[i]);
     adc:	000d4503          	lbu	a0,0(s10)
     ae0:	00000097          	auipc	ra,0x0
     ae4:	8cc080e7          	jalr	-1844(ra) # 3ac <consputc>
  while(--i >= 0)
     ae8:	000d0713          	mv	a4,s10
     aec:	fffd0d13          	add	s10,s10,-1
     af0:	fee996e3          	bne	s3,a4,adc <printf+0x3ac>
     af4:	0240006f          	j	b18 <printf+0x3e8>
      consputc('%');
     af8:	02500513          	li	a0,37
     afc:	f8f42e23          	sw	a5,-100(s0)
     b00:	00000097          	auipc	ra,0x0
     b04:	8ac080e7          	jalr	-1876(ra) # 3ac <consputc>
      consputc(c);
     b08:	f9c42783          	lw	a5,-100(s0)
     b0c:	00078513          	mv	a0,a5
     b10:	00000097          	auipc	ra,0x0
     b14:	89c080e7          	jalr	-1892(ra) # 3ac <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
     b18:	00148493          	add	s1,s1,1
     b1c:	009907b3          	add	a5,s2,s1
     b20:	0007c503          	lbu	a0,0(a5)
     b24:	ca051ae3          	bnez	a0,7d8 <printf+0xa8>
  if(locking)
     b28:	f9842783          	lw	a5,-104(s0)
     b2c:	e60784e3          	beqz	a5,994 <printf+0x264>
    release(&pr.lock);
     b30:	00015517          	auipc	a0,0x15
     b34:	96850513          	add	a0,a0,-1688 # 15498 <pr>
     b38:	00000097          	auipc	ra,0x0
     b3c:	7c4080e7          	jalr	1988(ra) # 12fc <release>
}
     b40:	e55ff06f          	j	994 <printf+0x264>
      printptr(va_arg(ap, uint32));
     b44:	fac42783          	lw	a5,-84(s0)
  consputc('0');
     b48:	03000513          	li	a0,48
  consputc('x');
     b4c:	00800d13          	li	s10,8
      printptr(va_arg(ap, uint32));
     b50:	00478613          	add	a2,a5,4
     b54:	0007ad83          	lw	s11,0(a5)
     b58:	fac42623          	sw	a2,-84(s0)
  consputc('0');
     b5c:	00000097          	auipc	ra,0x0
     b60:	850080e7          	jalr	-1968(ra) # 3ac <consputc>
  consputc('x');
     b64:	07800513          	li	a0,120
     b68:	00000097          	auipc	ra,0x0
     b6c:	844080e7          	jalr	-1980(ra) # 3ac <consputc>
    consputc(digits[x >> (sizeof(uint32) * 8 - 4)]);
     b70:	01cdd793          	srl	a5,s11,0x1c
     b74:	00fb87b3          	add	a5,s7,a5
     b78:	0007c503          	lbu	a0,0(a5)
  for (i = 0; i < (sizeof(uint32) * 2); i++, x <<= 4)
     b7c:	fffd0d13          	add	s10,s10,-1
     b80:	004d9d93          	sll	s11,s11,0x4
    consputc(digits[x >> (sizeof(uint32) * 8 - 4)]);
     b84:	00000097          	auipc	ra,0x0
     b88:	828080e7          	jalr	-2008(ra) # 3ac <consputc>
  for (i = 0; i < (sizeof(uint32) * 2); i++, x <<= 4)
     b8c:	fe0d12e3          	bnez	s10,b70 <printf+0x440>
     b90:	f89ff06f          	j	b18 <printf+0x3e8>
      if((s = va_arg(ap, char*)) == 0)
     b94:	fac42703          	lw	a4,-84(s0)
     b98:	00072d83          	lw	s11,0(a4)
     b9c:	00470713          	add	a4,a4,4
     ba0:	fae42623          	sw	a4,-84(s0)
     ba4:	000d9a63          	bnez	s11,bb8 <printf+0x488>
     ba8:	0a00006f          	j	c48 <printf+0x518>
      for(; *s; s++)
     bac:	001d8d93          	add	s11,s11,1
        consputc(*s);
     bb0:	fffff097          	auipc	ra,0xfffff
     bb4:	7fc080e7          	jalr	2044(ra) # 3ac <consputc>
      for(; *s; s++)
     bb8:	000dc503          	lbu	a0,0(s11)
     bbc:	fe0518e3          	bnez	a0,bac <printf+0x47c>
     bc0:	f59ff06f          	j	b18 <printf+0x3e8>
      consputc('%');
     bc4:	02500513          	li	a0,37
     bc8:	fffff097          	auipc	ra,0xfffff
     bcc:	7e4080e7          	jalr	2020(ra) # 3ac <consputc>
      break;
     bd0:	f49ff06f          	j	b18 <printf+0x3e8>
    acquire(&pr.lock);
     bd4:	00030513          	mv	a0,t1
     bd8:	00000097          	auipc	ra,0x0
     bdc:	598080e7          	jalr	1432(ra) # 1170 <acquire>
     be0:	bc1ff06f          	j	7a0 <printf+0x70>
    x = -xx;
     be4:	40d007b3          	neg	a5,a3
    buf[i++] = digits[x % base];
     be8:	0000b717          	auipc	a4,0xb
     bec:	c9470713          	add	a4,a4,-876 # b87c <digits>
     bf0:	00f7f613          	and	a2,a5,15
     bf4:	00c70633          	add	a2,a4,a2
     bf8:	00064503          	lbu	a0,0(a2)
  } while((x /= base) != 0);
     bfc:	ff100613          	li	a2,-15
     c00:	0047d593          	srl	a1,a5,0x4
    buf[i++] = digits[x % base];
     c04:	faa40823          	sb	a0,-80(s0)
  } while((x /= base) != 0);
     c08:	e0c6c8e3          	blt	a3,a2,a18 <printf+0x2e8>
    buf[i++] = digits[x % base];
     c0c:	00100713          	li	a4,1
     c10:	eb5ff06f          	j	ac4 <printf+0x394>
    x = -xx;
     c14:	40c006b3          	neg	a3,a2
    buf[i++] = digits[x % base];
     c18:	00a00793          	li	a5,10
     c1c:	02f6f5b3          	remu	a1,a3,a5
     c20:	0000b717          	auipc	a4,0xb
     c24:	c5c70713          	add	a4,a4,-932 # b87c <digits>
  } while((x /= base) != 0);
     c28:	ff700513          	li	a0,-9
    buf[i++] = digits[x % base];
     c2c:	00b705b3          	add	a1,a4,a1
     c30:	0005c583          	lbu	a1,0(a1)
  } while((x /= base) != 0);
     c34:	02f6d7b3          	divu	a5,a3,a5
    buf[i++] = digits[x % base];
     c38:	fab40823          	sb	a1,-80(s0)
  } while((x /= base) != 0);
     c3c:	c0a640e3          	blt	a2,a0,83c <printf+0x10c>
    buf[i++] = digits[x % base];
     c40:	00100713          	li	a4,1
     c44:	d09ff06f          	j	94c <printf+0x21c>
     c48:	02800513          	li	a0,40
        s = "(null)";
     c4c:	0000ad97          	auipc	s11,0xa
     c50:	60cd8d93          	add	s11,s11,1548 # b258 <main+0x128>
     c54:	f59ff06f          	j	bac <printf+0x47c>
    buf[i++] = digits[x % base];
     c58:	00700713          	li	a4,7
     c5c:	00600793          	li	a5,6
     c60:	e61ff06f          	j	ac0 <printf+0x390>
     c64:	00700713          	li	a4,7
     c68:	00600793          	li	a5,6
     c6c:	cddff06f          	j	948 <printf+0x218>
     c70:	00200713          	li	a4,2
     c74:	00100793          	li	a5,1
     c78:	e49ff06f          	j	ac0 <printf+0x390>
     c7c:	00200713          	li	a4,2
     c80:	00100793          	li	a5,1
     c84:	cc5ff06f          	j	948 <printf+0x218>
     c88:	00300713          	li	a4,3
     c8c:	00200793          	li	a5,2
     c90:	e31ff06f          	j	ac0 <printf+0x390>
     c94:	00300713          	li	a4,3
     c98:	00200793          	li	a5,2
     c9c:	cadff06f          	j	948 <printf+0x218>
     ca0:	00400713          	li	a4,4
     ca4:	00300793          	li	a5,3
     ca8:	ca1ff06f          	j	948 <printf+0x218>
     cac:	00400713          	li	a4,4
     cb0:	00300793          	li	a5,3
     cb4:	e0dff06f          	j	ac0 <printf+0x390>
     cb8:	00500713          	li	a4,5
     cbc:	00400793          	li	a5,4
     cc0:	e01ff06f          	j	ac0 <printf+0x390>
     cc4:	00500713          	li	a4,5
     cc8:	00400793          	li	a5,4
     ccc:	c7dff06f          	j	948 <printf+0x218>
  } while((x /= base) != 0);
     cd0:	00000793          	li	a5,0
     cd4:	c8dff06f          	j	960 <printf+0x230>
     cd8:	00000793          	li	a5,0
     cdc:	dfdff06f          	j	ad8 <printf+0x3a8>
    buf[i++] = digits[x % base];
     ce0:	00600713          	li	a4,6
     ce4:	00500793          	li	a5,5
     ce8:	dd9ff06f          	j	ac0 <printf+0x390>
     cec:	00600713          	li	a4,6
     cf0:	00500793          	li	a5,5
     cf4:	c55ff06f          	j	948 <printf+0x218>
     cf8:	00800713          	li	a4,8
     cfc:	00700793          	li	a5,7
     d00:	c49ff06f          	j	948 <printf+0x218>
     d04:	00900713          	li	a4,9
     d08:	00800793          	li	a5,8
     d0c:	c3dff06f          	j	948 <printf+0x218>
    panic("null fmt");
     d10:	0000a517          	auipc	a0,0xa
     d14:	55050513          	add	a0,a0,1360 # b260 <main+0x130>
     d18:	00000097          	auipc	ra,0x0
     d1c:	9bc080e7          	jalr	-1604(ra) # 6d4 <panic>

00000d20 <printfinit>:
    ;
}

void
printfinit(void)
{
     d20:	ff010113          	add	sp,sp,-16
     d24:	00812423          	sw	s0,8(sp)
     d28:	00912223          	sw	s1,4(sp)
     d2c:	00112623          	sw	ra,12(sp)
     d30:	01010413          	add	s0,sp,16
  initlock(&pr.lock, "pr");
     d34:	00014497          	auipc	s1,0x14
     d38:	76448493          	add	s1,s1,1892 # 15498 <pr>
     d3c:	00048513          	mv	a0,s1
     d40:	0000a597          	auipc	a1,0xa
     d44:	52c58593          	add	a1,a1,1324 # b26c <main+0x13c>
     d48:	00000097          	auipc	ra,0x0
     d4c:	404080e7          	jalr	1028(ra) # 114c <initlock>
  pr.locking = 1;
}
     d50:	00c12083          	lw	ra,12(sp)
     d54:	00812403          	lw	s0,8(sp)
  pr.locking = 1;
     d58:	00100793          	li	a5,1
     d5c:	00f4a623          	sw	a5,12(s1)
}
     d60:	00412483          	lw	s1,4(sp)
     d64:	01010113          	add	sp,sp,16
     d68:	00008067          	ret

00000d6c <uartinit>:
#include "proc.h"
#include "defs.h"

void
uartinit(void)
{
     d6c:	ff010113          	add	sp,sp,-16
     d70:	00812623          	sw	s0,12(sp)
     d74:	01010413          	add	s0,sp,16
}
     d78:	00c12403          	lw	s0,12(sp)
     d7c:	01010113          	add	sp,sp,16
     d80:	00008067          	ret

00000d84 <uartputc>:

// write one output character to the UART.
void
uartputc(int c)
{
     d84:	ff010113          	add	sp,sp,-16
     d88:	00812623          	sw	s0,12(sp)
     d8c:	01010413          	add	s0,sp,16
  volatile unsigned int *addr = (unsigned int*)0xff000000;
  *addr = c;
}
     d90:	00c12403          	lw	s0,12(sp)
  *addr = c;
     d94:	ff0007b7          	lui	a5,0xff000
     d98:	00a7a023          	sw	a0,0(a5) # ff000000 <end+0xfefdbfec>
}
     d9c:	01010113          	add	sp,sp,16
     da0:	00008067          	ret

00000da4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
     da4:	ff010113          	add	sp,sp,-16
     da8:	00812623          	sw	s0,12(sp)
     dac:	01010413          	add	s0,sp,16
  volatile unsigned int *en     = (unsigned int*)0xff000010;
  volatile unsigned int *rdata  = (unsigned int*)0xff000018;
  if(*en & 0x01){
     db0:	ff000737          	lui	a4,0xff000
     db4:	01072783          	lw	a5,16(a4) # ff000010 <end+0xfefdbffc>
     db8:	0017f793          	and	a5,a5,1
     dbc:	00078a63          	beqz	a5,dd0 <uartgetc+0x2c>
    // input data is ready.
    return *rdata;
     dc0:	01872503          	lw	a0,24(a4)
  } else {
    return -1;
  }
}
     dc4:	00c12403          	lw	s0,12(sp)
     dc8:	01010113          	add	sp,sp,16
     dcc:	00008067          	ret
    return -1;
     dd0:	fff00513          	li	a0,-1
     dd4:	ff1ff06f          	j	dc4 <uartgetc+0x20>

00000dd8 <uartintr>:
  if(*en & 0x01){
     dd8:	ff0007b7          	lui	a5,0xff000
     ddc:	0107a783          	lw	a5,16(a5) # ff000010 <end+0xfefdbffc>
     de0:	0017f793          	and	a5,a5,1
     de4:	04078e63          	beqz	a5,e40 <uartintr+0x68>

// trap.c calls here when the uart interrupts.
void
uartintr(void)
{
     de8:	ff010113          	add	sp,sp,-16
     dec:	00812423          	sw	s0,8(sp)
     df0:	00912223          	sw	s1,4(sp)
     df4:	01212023          	sw	s2,0(sp)
     df8:	00112623          	sw	ra,12(sp)
     dfc:	01010413          	add	s0,sp,16
    return *rdata;
     e00:	ff0004b7          	lui	s1,0xff000
  while(1){
    int c = uartgetc();
    if(c == -1)
     e04:	fff00913          	li	s2,-1
     e08:	0180006f          	j	e20 <uartintr+0x48>
      break;
    consoleintr(c);
     e0c:	fffff097          	auipc	ra,0xfffff
     e10:	600080e7          	jalr	1536(ra) # 40c <consoleintr>
  if(*en & 0x01){
     e14:	0104a783          	lw	a5,16(s1) # ff000010 <end+0xfefdbffc>
     e18:	0017f793          	and	a5,a5,1
     e1c:	00078663          	beqz	a5,e28 <uartintr+0x50>
    return *rdata;
     e20:	0184a503          	lw	a0,24(s1)
    if(c == -1)
     e24:	ff2514e3          	bne	a0,s2,e0c <uartintr+0x34>
  }
}
     e28:	00c12083          	lw	ra,12(sp)
     e2c:	00812403          	lw	s0,8(sp)
     e30:	00412483          	lw	s1,4(sp)
     e34:	00012903          	lw	s2,0(sp)
     e38:	01010113          	add	sp,sp,16
     e3c:	00008067          	ret
     e40:	00008067          	ret

00000e44 <kinit>:
  struct run *freelist;
} kmem;

void
kinit()
{
     e44:	fe010113          	add	sp,sp,-32
     e48:	00812c23          	sw	s0,24(sp)
     e4c:	00912a23          	sw	s1,20(sp)
     e50:	00112e23          	sw	ra,28(sp)
     e54:	01212823          	sw	s2,16(sp)
     e58:	01312623          	sw	s3,12(sp)
     e5c:	01412423          	sw	s4,8(sp)
     e60:	01512223          	sw	s5,4(sp)
     e64:	01612023          	sw	s6,0(sp)
     e68:	02010413          	add	s0,sp,32
  initlock(&kmem.lock, "kmem");
     e6c:	0000a597          	auipc	a1,0xa
     e70:	40458593          	add	a1,a1,1028 # b270 <main+0x140>
     e74:	00014517          	auipc	a0,0x14
     e78:	63450513          	add	a0,a0,1588 # 154a8 <kmem>
     e7c:	00000097          	auipc	ra,0x0
     e80:	2d0080e7          	jalr	720(ra) # 114c <initlock>

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint32)pa_start);
     e84:	fffff7b7          	lui	a5,0xfffff
     e88:	00024497          	auipc	s1,0x24
     e8c:	18b48493          	add	s1,s1,395 # 25013 <end+0xfff>
     e90:	00f4f4b3          	and	s1,s1,a5
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     e94:	000017b7          	lui	a5,0x1
     e98:	00f487b3          	add	a5,s1,a5
     e9c:	02000737          	lui	a4,0x2000
     ea0:	06f76063          	bltu	a4,a5,f00 <kinit+0xbc>
     ea4:	00023997          	auipc	s3,0x23
     ea8:	17098993          	add	s3,s3,368 # 24014 <end>
void
kfree(void *pa)
{
  struct run *r;

  if(((uint32)pa % PGSIZE) != 0 || (char*)pa < end || (uint32)pa >= PHYSTOP)
     eac:	0734ee63          	bltu	s1,s3,f28 <kinit+0xe4>
     eb0:	06e4fc63          	bgeu	s1,a4,f28 <kinit+0xe4>
     eb4:	00014917          	auipc	s2,0x14
     eb8:	5f490913          	add	s2,s2,1524 # 154a8 <kmem>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     ebc:	01fffa37          	lui	s4,0x1fff
     ec0:	00001ab7          	lui	s5,0x1
  if(((uint32)pa % PGSIZE) != 0 || (char*)pa < end || (uint32)pa >= PHYSTOP)
     ec4:	02000b37          	lui	s6,0x2000
     ec8:	0100006f          	j	ed8 <kinit+0x94>
     ecc:	015484b3          	add	s1,s1,s5
     ed0:	0534ec63          	bltu	s1,s3,f28 <kinit+0xe4>
     ed4:	0564fa63          	bgeu	s1,s6,f28 <kinit+0xe4>
  // TODO 遅すぎ
  // memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
     ed8:	00090513          	mv	a0,s2
     edc:	00000097          	auipc	ra,0x0
     ee0:	294080e7          	jalr	660(ra) # 1170 <acquire>
  r->next = kmem.freelist;
     ee4:	00c92783          	lw	a5,12(s2)
  kmem.freelist = r;
  release(&kmem.lock);
     ee8:	00090513          	mv	a0,s2
  r->next = kmem.freelist;
     eec:	00f4a023          	sw	a5,0(s1)
  kmem.freelist = r;
     ef0:	00992623          	sw	s1,12(s2)
  release(&kmem.lock);
     ef4:	00000097          	auipc	ra,0x0
     ef8:	408080e7          	jalr	1032(ra) # 12fc <release>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     efc:	fd4498e3          	bne	s1,s4,ecc <kinit+0x88>
}
     f00:	01c12083          	lw	ra,28(sp)
     f04:	01812403          	lw	s0,24(sp)
     f08:	01412483          	lw	s1,20(sp)
     f0c:	01012903          	lw	s2,16(sp)
     f10:	00c12983          	lw	s3,12(sp)
     f14:	00812a03          	lw	s4,8(sp)
     f18:	00412a83          	lw	s5,4(sp)
     f1c:	00012b03          	lw	s6,0(sp)
     f20:	02010113          	add	sp,sp,32
     f24:	00008067          	ret
    panic("kfree");
     f28:	0000a517          	auipc	a0,0xa
     f2c:	35050513          	add	a0,a0,848 # b278 <main+0x148>
     f30:	fffff097          	auipc	ra,0xfffff
     f34:	7a4080e7          	jalr	1956(ra) # 6d4 <panic>

00000f38 <freerange>:
  p = (char*)PGROUNDUP((uint32)pa_start);
     f38:	000017b7          	lui	a5,0x1
{
     f3c:	fd010113          	add	sp,sp,-48
  p = (char*)PGROUNDUP((uint32)pa_start);
     f40:	fff78713          	add	a4,a5,-1 # fff <freerange+0xc7>
{
     f44:	02912223          	sw	s1,36(sp)
  p = (char*)PGROUNDUP((uint32)pa_start);
     f48:	00e504b3          	add	s1,a0,a4
     f4c:	fffff737          	lui	a4,0xfffff
{
     f50:	02812423          	sw	s0,40(sp)
     f54:	02112623          	sw	ra,44(sp)
     f58:	03212023          	sw	s2,32(sp)
     f5c:	01312e23          	sw	s3,28(sp)
     f60:	01412c23          	sw	s4,24(sp)
     f64:	01512a23          	sw	s5,20(sp)
     f68:	01612823          	sw	s6,16(sp)
     f6c:	01712623          	sw	s7,12(sp)
     f70:	03010413          	add	s0,sp,48
  p = (char*)PGROUNDUP((uint32)pa_start);
     f74:	00e4f4b3          	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     f78:	00f487b3          	add	a5,s1,a5
     f7c:	06f5e663          	bltu	a1,a5,fe8 <freerange+0xb0>
  if(((uint32)pa % PGSIZE) != 0 || (char*)pa < end || (uint32)pa >= PHYSTOP)
     f80:	00023a17          	auipc	s4,0x23
     f84:	094a0a13          	add	s4,s4,148 # 24014 <end>
     f88:	0944e663          	bltu	s1,s4,1014 <freerange+0xdc>
     f8c:	020007b7          	lui	a5,0x2000
     f90:	08f4f263          	bgeu	s1,a5,1014 <freerange+0xdc>
     f94:	00058993          	mv	s3,a1
     f98:	00014917          	auipc	s2,0x14
     f9c:	51090913          	add	s2,s2,1296 # 154a8 <kmem>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     fa0:	00002ab7          	lui	s5,0x2
     fa4:	00001b37          	lui	s6,0x1
  if(((uint32)pa % PGSIZE) != 0 || (char*)pa < end || (uint32)pa >= PHYSTOP)
     fa8:	02000bb7          	lui	s7,0x2000
     fac:	0100006f          	j	fbc <freerange+0x84>
     fb0:	016484b3          	add	s1,s1,s6
     fb4:	0744e063          	bltu	s1,s4,1014 <freerange+0xdc>
     fb8:	0574fe63          	bgeu	s1,s7,1014 <freerange+0xdc>
  acquire(&kmem.lock);
     fbc:	00090513          	mv	a0,s2
     fc0:	00000097          	auipc	ra,0x0
     fc4:	1b0080e7          	jalr	432(ra) # 1170 <acquire>
  r->next = kmem.freelist;
     fc8:	00c92783          	lw	a5,12(s2)
  release(&kmem.lock);
     fcc:	00090513          	mv	a0,s2
  r->next = kmem.freelist;
     fd0:	00f4a023          	sw	a5,0(s1)
  kmem.freelist = r;
     fd4:	00992623          	sw	s1,12(s2)
  release(&kmem.lock);
     fd8:	00000097          	auipc	ra,0x0
     fdc:	324080e7          	jalr	804(ra) # 12fc <release>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     fe0:	015487b3          	add	a5,s1,s5
     fe4:	fcf9f6e3          	bgeu	s3,a5,fb0 <freerange+0x78>
}
     fe8:	02c12083          	lw	ra,44(sp)
     fec:	02812403          	lw	s0,40(sp)
     ff0:	02412483          	lw	s1,36(sp)
     ff4:	02012903          	lw	s2,32(sp)
     ff8:	01c12983          	lw	s3,28(sp)
     ffc:	01812a03          	lw	s4,24(sp)
    1000:	01412a83          	lw	s5,20(sp)
    1004:	01012b03          	lw	s6,16(sp)
    1008:	00c12b83          	lw	s7,12(sp)
    100c:	03010113          	add	sp,sp,48
    1010:	00008067          	ret
    panic("kfree");
    1014:	0000a517          	auipc	a0,0xa
    1018:	26450513          	add	a0,a0,612 # b278 <main+0x148>
    101c:	fffff097          	auipc	ra,0xfffff
    1020:	6b8080e7          	jalr	1720(ra) # 6d4 <panic>

00001024 <kfree>:
{
    1024:	ff010113          	add	sp,sp,-16
    1028:	00812423          	sw	s0,8(sp)
    102c:	00112623          	sw	ra,12(sp)
    1030:	00912223          	sw	s1,4(sp)
    1034:	01212023          	sw	s2,0(sp)
    1038:	01010413          	add	s0,sp,16
  if(((uint32)pa % PGSIZE) != 0 || (char*)pa < end || (uint32)pa >= PHYSTOP)
    103c:	01451793          	sll	a5,a0,0x14
    1040:	04079e63          	bnez	a5,109c <kfree+0x78>
    1044:	00023797          	auipc	a5,0x23
    1048:	fd078793          	add	a5,a5,-48 # 24014 <end>
    104c:	00050493          	mv	s1,a0
    1050:	04f56663          	bltu	a0,a5,109c <kfree+0x78>
    1054:	020007b7          	lui	a5,0x2000
    1058:	04f57263          	bgeu	a0,a5,109c <kfree+0x78>
  acquire(&kmem.lock);
    105c:	00014917          	auipc	s2,0x14
    1060:	44c90913          	add	s2,s2,1100 # 154a8 <kmem>
    1064:	00090513          	mv	a0,s2
    1068:	00000097          	auipc	ra,0x0
    106c:	108080e7          	jalr	264(ra) # 1170 <acquire>
  r->next = kmem.freelist;
    1070:	00c92783          	lw	a5,12(s2)
}
    1074:	00812403          	lw	s0,8(sp)
    1078:	00c12083          	lw	ra,12(sp)
  r->next = kmem.freelist;
    107c:	00f4a023          	sw	a5,0(s1)
  kmem.freelist = r;
    1080:	00992623          	sw	s1,12(s2)
  release(&kmem.lock);
    1084:	00090513          	mv	a0,s2
}
    1088:	00412483          	lw	s1,4(sp)
    108c:	00012903          	lw	s2,0(sp)
    1090:	01010113          	add	sp,sp,16
  release(&kmem.lock);
    1094:	00000317          	auipc	t1,0x0
    1098:	26830067          	jr	616(t1) # 12fc <release>
    panic("kfree");
    109c:	0000a517          	auipc	a0,0xa
    10a0:	1dc50513          	add	a0,a0,476 # b278 <main+0x148>
    10a4:	fffff097          	auipc	ra,0xfffff
    10a8:	630080e7          	jalr	1584(ra) # 6d4 <panic>

000010ac <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    10ac:	ff010113          	add	sp,sp,-16
    10b0:	00812423          	sw	s0,8(sp)
    10b4:	00912223          	sw	s1,4(sp)
    10b8:	01212023          	sw	s2,0(sp)
    10bc:	00112623          	sw	ra,12(sp)
    10c0:	01010413          	add	s0,sp,16
  struct run *r;

  acquire(&kmem.lock);
    10c4:	00014497          	auipc	s1,0x14
    10c8:	3e448493          	add	s1,s1,996 # 154a8 <kmem>
    10cc:	00048513          	mv	a0,s1
    10d0:	00000097          	auipc	ra,0x0
    10d4:	0a0080e7          	jalr	160(ra) # 1170 <acquire>
  r = kmem.freelist;
    10d8:	00c4a903          	lw	s2,12(s1)
  if(r)
    10dc:	04090463          	beqz	s2,1124 <kalloc+0x78>
    kmem.freelist = r->next;
    10e0:	00092783          	lw	a5,0(s2)
  release(&kmem.lock);
    10e4:	00048513          	mv	a0,s1
    kmem.freelist = r->next;
    10e8:	00f4a623          	sw	a5,12(s1)
  release(&kmem.lock);
    10ec:	00000097          	auipc	ra,0x0
    10f0:	210080e7          	jalr	528(ra) # 12fc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    10f4:	00090513          	mv	a0,s2
    10f8:	00001637          	lui	a2,0x1
    10fc:	00500593          	li	a1,5
    1100:	00000097          	auipc	ra,0x0
    1104:	584080e7          	jalr	1412(ra) # 1684 <memset>
  return (void*)r;
}
    1108:	00c12083          	lw	ra,12(sp)
    110c:	00812403          	lw	s0,8(sp)
    1110:	00412483          	lw	s1,4(sp)
    1114:	00090513          	mv	a0,s2
    1118:	00012903          	lw	s2,0(sp)
    111c:	01010113          	add	sp,sp,16
    1120:	00008067          	ret
  release(&kmem.lock);
    1124:	00048513          	mv	a0,s1
    1128:	00000097          	auipc	ra,0x0
    112c:	1d4080e7          	jalr	468(ra) # 12fc <release>
}
    1130:	00c12083          	lw	ra,12(sp)
    1134:	00812403          	lw	s0,8(sp)
    1138:	00412483          	lw	s1,4(sp)
    113c:	00090513          	mv	a0,s2
    1140:	00012903          	lw	s2,0(sp)
    1144:	01010113          	add	sp,sp,16
    1148:	00008067          	ret

0000114c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    114c:	ff010113          	add	sp,sp,-16
    1150:	00812623          	sw	s0,12(sp)
    1154:	01010413          	add	s0,sp,16
  lk->name = name;
  lk->locked = 0;
  lk->cpu = 0;
}
    1158:	00c12403          	lw	s0,12(sp)
  lk->name = name;
    115c:	00b52223          	sw	a1,4(a0)
  lk->locked = 0;
    1160:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    1164:	00052423          	sw	zero,8(a0)
}
    1168:	01010113          	add	sp,sp,16
    116c:	00008067          	ret

00001170 <acquire>:

// Acquire the lock.
// Loops (spins) until the lock is acquired.
void
acquire(struct spinlock *lk)
{
    1170:	ff010113          	add	sp,sp,-16
    1174:	00812423          	sw	s0,8(sp)
    1178:	00912223          	sw	s1,4(sp)
    117c:	00112623          	sw	ra,12(sp)
    1180:	01212023          	sw	s2,0(sp)
    1184:	01010413          	add	s0,sp,16
    1188:	00050493          	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    118c:	10002973          	csrr	s2,sstatus
    1190:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    1194:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    1198:	10079073          	csrw	sstatus,a5
push_off(void)
{
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    119c:	00002097          	auipc	ra,0x2
    11a0:	254080e7          	jalr	596(ra) # 33f0 <mycpu>
    11a4:	03c52783          	lw	a5,60(a0)
    11a8:	10078663          	beqz	a5,12b4 <acquire+0x144>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    11ac:	00002097          	auipc	ra,0x2
    11b0:	244080e7          	jalr	580(ra) # 33f0 <mycpu>
    11b4:	03c52783          	lw	a5,60(a0)
    11b8:	00178793          	add	a5,a5,1 # 2000001 <end+0x1fdbfed>
    11bc:	02f52e23          	sw	a5,60(a0)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    11c0:	10002973          	csrr	s2,sstatus
    11c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    11c8:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    11cc:	10079073          	csrw	sstatus,a5
  if(mycpu()->noff == 0)
    11d0:	00002097          	auipc	ra,0x2
    11d4:	220080e7          	jalr	544(ra) # 33f0 <mycpu>
    11d8:	03c52783          	lw	a5,60(a0)
    11dc:	0c078063          	beqz	a5,129c <acquire+0x12c>
  mycpu()->noff += 1;
    11e0:	00002097          	auipc	ra,0x2
    11e4:	210080e7          	jalr	528(ra) # 33f0 <mycpu>
    11e8:	03c52783          	lw	a5,60(a0)
  r = (lk->locked && lk->cpu == mycpu());
    11ec:	0004a703          	lw	a4,0(s1)
    11f0:	00000913          	li	s2,0
  mycpu()->noff += 1;
    11f4:	00178793          	add	a5,a5,1
    11f8:	02f52e23          	sw	a5,60(a0)
  r = (lk->locked && lk->cpu == mycpu());
    11fc:	08071463          	bnez	a4,1284 <acquire+0x114>
}

void
pop_off(void)
{
  struct cpu *c = mycpu();
    1200:	00002097          	auipc	ra,0x2
    1204:	1f0080e7          	jalr	496(ra) # 33f0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1208:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    120c:	0027f793          	and	a5,a5,2
  if(intr_get())
    1210:	0c079e63          	bnez	a5,12ec <acquire+0x17c>
    panic("pop_off - interruptible");
  c->noff -= 1;
    1214:	03c52783          	lw	a5,60(a0)
    1218:	fff78793          	add	a5,a5,-1
    121c:	02f52e23          	sw	a5,60(a0)
  if(c->noff < 0)
    1220:	0a07ce63          	bltz	a5,12dc <acquire+0x16c>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    1224:	02079263          	bnez	a5,1248 <acquire+0xd8>
    1228:	04052783          	lw	a5,64(a0)
    122c:	00078e63          	beqz	a5,1248 <acquire+0xd8>
  asm volatile("csrr %0, sie" : "=r" (x) );
    1230:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    1234:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    1238:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    123c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    1240:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    1244:	10079073          	csrw	sstatus,a5
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    1248:	00100713          	li	a4,1
  if(holding(lk))
    124c:	08091063          	bnez	s2,12cc <acquire+0x15c>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    1250:	00070793          	mv	a5,a4
    1254:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    1258:	fe079ce3          	bnez	a5,1250 <acquire+0xe0>
  __sync_synchronize();
    125c:	0ff0000f          	fence
  lk->cpu = mycpu();
    1260:	00002097          	auipc	ra,0x2
    1264:	190080e7          	jalr	400(ra) # 33f0 <mycpu>
}
    1268:	00c12083          	lw	ra,12(sp)
    126c:	00812403          	lw	s0,8(sp)
  lk->cpu = mycpu();
    1270:	00a4a423          	sw	a0,8(s1)
}
    1274:	00012903          	lw	s2,0(sp)
    1278:	00412483          	lw	s1,4(sp)
    127c:	01010113          	add	sp,sp,16
    1280:	00008067          	ret
  r = (lk->locked && lk->cpu == mycpu());
    1284:	0084a903          	lw	s2,8(s1)
    1288:	00002097          	auipc	ra,0x2
    128c:	168080e7          	jalr	360(ra) # 33f0 <mycpu>
    1290:	40a90933          	sub	s2,s2,a0
    1294:	00193913          	seqz	s2,s2
    1298:	f69ff06f          	j	1200 <acquire+0x90>
  return (x & SSTATUS_SIE) != 0;
    129c:	00195913          	srl	s2,s2,0x1
    mycpu()->intena = old;
    12a0:	00002097          	auipc	ra,0x2
    12a4:	150080e7          	jalr	336(ra) # 33f0 <mycpu>
    12a8:	00197913          	and	s2,s2,1
    12ac:	05252023          	sw	s2,64(a0)
    12b0:	f31ff06f          	j	11e0 <acquire+0x70>
    12b4:	00195913          	srl	s2,s2,0x1
    12b8:	00002097          	auipc	ra,0x2
    12bc:	138080e7          	jalr	312(ra) # 33f0 <mycpu>
    12c0:	00197913          	and	s2,s2,1
    12c4:	05252023          	sw	s2,64(a0)
    12c8:	ee5ff06f          	j	11ac <acquire+0x3c>
    panic("acquire");
    12cc:	0000a517          	auipc	a0,0xa
    12d0:	fd450513          	add	a0,a0,-44 # b2a0 <main+0x170>
    12d4:	fffff097          	auipc	ra,0xfffff
    12d8:	400080e7          	jalr	1024(ra) # 6d4 <panic>
    panic("pop_off");
    12dc:	0000a517          	auipc	a0,0xa
    12e0:	fbc50513          	add	a0,a0,-68 # b298 <main+0x168>
    12e4:	fffff097          	auipc	ra,0xfffff
    12e8:	3f0080e7          	jalr	1008(ra) # 6d4 <panic>
    panic("pop_off - interruptible");
    12ec:	0000a517          	auipc	a0,0xa
    12f0:	f9450513          	add	a0,a0,-108 # b280 <main+0x150>
    12f4:	fffff097          	auipc	ra,0xfffff
    12f8:	3e0080e7          	jalr	992(ra) # 6d4 <panic>

000012fc <release>:
{
    12fc:	ff010113          	add	sp,sp,-16
    1300:	00812423          	sw	s0,8(sp)
    1304:	00912223          	sw	s1,4(sp)
    1308:	00112623          	sw	ra,12(sp)
    130c:	01212023          	sw	s2,0(sp)
    1310:	01010413          	add	s0,sp,16
    1314:	00050493          	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1318:	10002973          	csrr	s2,sstatus
    131c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    1320:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    1324:	10079073          	csrw	sstatus,a5
  if(mycpu()->noff == 0)
    1328:	00002097          	auipc	ra,0x2
    132c:	0c8080e7          	jalr	200(ra) # 33f0 <mycpu>
    1330:	03c52783          	lw	a5,60(a0)
    1334:	0e078e63          	beqz	a5,1430 <release+0x134>
  mycpu()->noff += 1;
    1338:	00002097          	auipc	ra,0x2
    133c:	0b8080e7          	jalr	184(ra) # 33f0 <mycpu>
    1340:	03c52783          	lw	a5,60(a0)
  r = (lk->locked && lk->cpu == mycpu());
    1344:	0004a703          	lw	a4,0(s1)
    1348:	00000913          	li	s2,0
  mycpu()->noff += 1;
    134c:	00178793          	add	a5,a5,1
    1350:	02f52e23          	sw	a5,60(a0)
  r = (lk->locked && lk->cpu == mycpu());
    1354:	0c071263          	bnez	a4,1418 <release+0x11c>
  struct cpu *c = mycpu();
    1358:	00002097          	auipc	ra,0x2
    135c:	098080e7          	jalr	152(ra) # 33f0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1360:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    1364:	0027f793          	and	a5,a5,2
  if(intr_get())
    1368:	0e079863          	bnez	a5,1458 <release+0x15c>
  c->noff -= 1;
    136c:	03c52783          	lw	a5,60(a0)
    1370:	fff78793          	add	a5,a5,-1
    1374:	02f52e23          	sw	a5,60(a0)
  if(c->noff < 0)
    1378:	0c07c863          	bltz	a5,1448 <release+0x14c>
  if(c->noff == 0 && c->intena)
    137c:	06078c63          	beqz	a5,13f4 <release+0xf8>
  if(!holding(lk))
    1380:	0e090463          	beqz	s2,1468 <release+0x16c>
  lk->cpu = 0;
    1384:	0004a423          	sw	zero,8(s1)
  __sync_synchronize();
    1388:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    138c:	0f50000f          	fence	iorw,ow
    1390:	0804a02f          	amoswap.w	zero,zero,(s1)
  struct cpu *c = mycpu();
    1394:	00002097          	auipc	ra,0x2
    1398:	05c080e7          	jalr	92(ra) # 33f0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    139c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    13a0:	0027f793          	and	a5,a5,2
  if(intr_get())
    13a4:	0a079a63          	bnez	a5,1458 <release+0x15c>
  c->noff -= 1;
    13a8:	03c52783          	lw	a5,60(a0)
    13ac:	fff78793          	add	a5,a5,-1
    13b0:	02f52e23          	sw	a5,60(a0)
  if(c->noff < 0)
    13b4:	0807ca63          	bltz	a5,1448 <release+0x14c>
  if(c->noff == 0 && c->intena)
    13b8:	02079263          	bnez	a5,13dc <release+0xe0>
    13bc:	04052783          	lw	a5,64(a0)
    13c0:	00078e63          	beqz	a5,13dc <release+0xe0>
  asm volatile("csrr %0, sie" : "=r" (x) );
    13c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    13c8:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    13cc:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    13d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    13d4:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    13d8:	10079073          	csrw	sstatus,a5
}
    13dc:	00c12083          	lw	ra,12(sp)
    13e0:	00812403          	lw	s0,8(sp)
    13e4:	00412483          	lw	s1,4(sp)
    13e8:	00012903          	lw	s2,0(sp)
    13ec:	01010113          	add	sp,sp,16
    13f0:	00008067          	ret
  if(c->noff == 0 && c->intena)
    13f4:	04052783          	lw	a5,64(a0)
    13f8:	f80784e3          	beqz	a5,1380 <release+0x84>
  asm volatile("csrr %0, sie" : "=r" (x) );
    13fc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    1400:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    1404:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1408:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    140c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    1410:	10079073          	csrw	sstatus,a5
}
    1414:	f6dff06f          	j	1380 <release+0x84>
  r = (lk->locked && lk->cpu == mycpu());
    1418:	0084a903          	lw	s2,8(s1)
    141c:	00002097          	auipc	ra,0x2
    1420:	fd4080e7          	jalr	-44(ra) # 33f0 <mycpu>
    1424:	40a90933          	sub	s2,s2,a0
    1428:	00193913          	seqz	s2,s2
    142c:	f2dff06f          	j	1358 <release+0x5c>
  return (x & SSTATUS_SIE) != 0;
    1430:	00195913          	srl	s2,s2,0x1
    mycpu()->intena = old;
    1434:	00002097          	auipc	ra,0x2
    1438:	fbc080e7          	jalr	-68(ra) # 33f0 <mycpu>
    143c:	00197913          	and	s2,s2,1
    1440:	05252023          	sw	s2,64(a0)
    1444:	ef5ff06f          	j	1338 <release+0x3c>
    panic("pop_off");
    1448:	0000a517          	auipc	a0,0xa
    144c:	e5050513          	add	a0,a0,-432 # b298 <main+0x168>
    1450:	fffff097          	auipc	ra,0xfffff
    1454:	284080e7          	jalr	644(ra) # 6d4 <panic>
    panic("pop_off - interruptible");
    1458:	0000a517          	auipc	a0,0xa
    145c:	e2850513          	add	a0,a0,-472 # b280 <main+0x150>
    1460:	fffff097          	auipc	ra,0xfffff
    1464:	274080e7          	jalr	628(ra) # 6d4 <panic>
    panic("release");
    1468:	0000a517          	auipc	a0,0xa
    146c:	e4050513          	add	a0,a0,-448 # b2a8 <main+0x178>
    1470:	fffff097          	auipc	ra,0xfffff
    1474:	264080e7          	jalr	612(ra) # 6d4 <panic>

00001478 <holding>:
{
    1478:	ff010113          	add	sp,sp,-16
    147c:	00812423          	sw	s0,8(sp)
    1480:	00912223          	sw	s1,4(sp)
    1484:	00112623          	sw	ra,12(sp)
    1488:	01212023          	sw	s2,0(sp)
    148c:	01010413          	add	s0,sp,16
    1490:	00050493          	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1494:	10002973          	csrr	s2,sstatus
    1498:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    149c:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    14a0:	10079073          	csrw	sstatus,a5
  if(mycpu()->noff == 0)
    14a4:	00002097          	auipc	ra,0x2
    14a8:	f4c080e7          	jalr	-180(ra) # 33f0 <mycpu>
    14ac:	03c52783          	lw	a5,60(a0)
    14b0:	0a078063          	beqz	a5,1550 <holding+0xd8>
  mycpu()->noff += 1;
    14b4:	00002097          	auipc	ra,0x2
    14b8:	f3c080e7          	jalr	-196(ra) # 33f0 <mycpu>
    14bc:	03c52783          	lw	a5,60(a0)
  r = (lk->locked && lk->cpu == mycpu());
    14c0:	0004a703          	lw	a4,0(s1)
    14c4:	00000913          	li	s2,0
  mycpu()->noff += 1;
    14c8:	00178793          	add	a5,a5,1
    14cc:	02f52e23          	sw	a5,60(a0)
  r = (lk->locked && lk->cpu == mycpu());
    14d0:	06071463          	bnez	a4,1538 <holding+0xc0>
  struct cpu *c = mycpu();
    14d4:	00002097          	auipc	ra,0x2
    14d8:	f1c080e7          	jalr	-228(ra) # 33f0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    14dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    14e0:	0027f793          	and	a5,a5,2
  if(intr_get())
    14e4:	08079a63          	bnez	a5,1578 <holding+0x100>
  c->noff -= 1;
    14e8:	03c52783          	lw	a5,60(a0)
    14ec:	fff78793          	add	a5,a5,-1
    14f0:	02f52e23          	sw	a5,60(a0)
  if(c->noff < 0)
    14f4:	0607ca63          	bltz	a5,1568 <holding+0xf0>
  if(c->noff == 0 && c->intena)
    14f8:	02079263          	bnez	a5,151c <holding+0xa4>
    14fc:	04052783          	lw	a5,64(a0)
    1500:	00078e63          	beqz	a5,151c <holding+0xa4>
  asm volatile("csrr %0, sie" : "=r" (x) );
    1504:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    1508:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    150c:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1510:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    1514:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    1518:	10079073          	csrw	sstatus,a5
}
    151c:	00c12083          	lw	ra,12(sp)
    1520:	00812403          	lw	s0,8(sp)
    1524:	00412483          	lw	s1,4(sp)
    1528:	00090513          	mv	a0,s2
    152c:	00012903          	lw	s2,0(sp)
    1530:	01010113          	add	sp,sp,16
    1534:	00008067          	ret
  r = (lk->locked && lk->cpu == mycpu());
    1538:	0084a903          	lw	s2,8(s1)
    153c:	00002097          	auipc	ra,0x2
    1540:	eb4080e7          	jalr	-332(ra) # 33f0 <mycpu>
    1544:	40a90933          	sub	s2,s2,a0
    1548:	00193913          	seqz	s2,s2
    154c:	f89ff06f          	j	14d4 <holding+0x5c>
  return (x & SSTATUS_SIE) != 0;
    1550:	00195913          	srl	s2,s2,0x1
    mycpu()->intena = old;
    1554:	00002097          	auipc	ra,0x2
    1558:	e9c080e7          	jalr	-356(ra) # 33f0 <mycpu>
    155c:	00197913          	and	s2,s2,1
    1560:	05252023          	sw	s2,64(a0)
    1564:	f51ff06f          	j	14b4 <holding+0x3c>
    panic("pop_off");
    1568:	0000a517          	auipc	a0,0xa
    156c:	d3050513          	add	a0,a0,-720 # b298 <main+0x168>
    1570:	fffff097          	auipc	ra,0xfffff
    1574:	164080e7          	jalr	356(ra) # 6d4 <panic>
    panic("pop_off - interruptible");
    1578:	0000a517          	auipc	a0,0xa
    157c:	d0850513          	add	a0,a0,-760 # b280 <main+0x150>
    1580:	fffff097          	auipc	ra,0xfffff
    1584:	154080e7          	jalr	340(ra) # 6d4 <panic>

00001588 <push_off>:
{
    1588:	ff010113          	add	sp,sp,-16
    158c:	00812423          	sw	s0,8(sp)
    1590:	00112623          	sw	ra,12(sp)
    1594:	00912223          	sw	s1,4(sp)
    1598:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    159c:	100024f3          	csrr	s1,sstatus
    15a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    15a4:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    15a8:	10079073          	csrw	sstatus,a5
  if(mycpu()->noff == 0)
    15ac:	00002097          	auipc	ra,0x2
    15b0:	e44080e7          	jalr	-444(ra) # 33f0 <mycpu>
    15b4:	03c52783          	lw	a5,60(a0)
    15b8:	02078663          	beqz	a5,15e4 <push_off+0x5c>
  mycpu()->noff += 1;
    15bc:	00002097          	auipc	ra,0x2
    15c0:	e34080e7          	jalr	-460(ra) # 33f0 <mycpu>
    15c4:	03c52783          	lw	a5,60(a0)
}
    15c8:	00c12083          	lw	ra,12(sp)
    15cc:	00812403          	lw	s0,8(sp)
  mycpu()->noff += 1;
    15d0:	00178793          	add	a5,a5,1
    15d4:	02f52e23          	sw	a5,60(a0)
}
    15d8:	00412483          	lw	s1,4(sp)
    15dc:	01010113          	add	sp,sp,16
    15e0:	00008067          	ret
  return (x & SSTATUS_SIE) != 0;
    15e4:	0014d493          	srl	s1,s1,0x1
    mycpu()->intena = old;
    15e8:	00002097          	auipc	ra,0x2
    15ec:	e08080e7          	jalr	-504(ra) # 33f0 <mycpu>
    15f0:	0014f493          	and	s1,s1,1
    15f4:	04952023          	sw	s1,64(a0)
    15f8:	fc5ff06f          	j	15bc <push_off+0x34>

000015fc <pop_off>:
{
    15fc:	ff010113          	add	sp,sp,-16
    1600:	00812423          	sw	s0,8(sp)
    1604:	00112623          	sw	ra,12(sp)
    1608:	01010413          	add	s0,sp,16
  struct cpu *c = mycpu();
    160c:	00002097          	auipc	ra,0x2
    1610:	de4080e7          	jalr	-540(ra) # 33f0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1614:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    1618:	0027f793          	and	a5,a5,2
  if(intr_get())
    161c:	04079c63          	bnez	a5,1674 <pop_off+0x78>
  c->noff -= 1;
    1620:	03c52783          	lw	a5,60(a0)
    1624:	fff78793          	add	a5,a5,-1
    1628:	02f52e23          	sw	a5,60(a0)
  if(c->noff < 0)
    162c:	0207cc63          	bltz	a5,1664 <pop_off+0x68>
  if(c->noff == 0 && c->intena)
    1630:	02079263          	bnez	a5,1654 <pop_off+0x58>
    1634:	04052783          	lw	a5,64(a0)
    1638:	00078e63          	beqz	a5,1654 <pop_off+0x58>
  asm volatile("csrr %0, sie" : "=r" (x) );
    163c:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    1640:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    1644:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    1648:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    164c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    1650:	10079073          	csrw	sstatus,a5
    intr_on();
}
    1654:	00c12083          	lw	ra,12(sp)
    1658:	00812403          	lw	s0,8(sp)
    165c:	01010113          	add	sp,sp,16
    1660:	00008067          	ret
    panic("pop_off");
    1664:	0000a517          	auipc	a0,0xa
    1668:	c3450513          	add	a0,a0,-972 # b298 <main+0x168>
    166c:	fffff097          	auipc	ra,0xfffff
    1670:	068080e7          	jalr	104(ra) # 6d4 <panic>
    panic("pop_off - interruptible");
    1674:	0000a517          	auipc	a0,0xa
    1678:	c0c50513          	add	a0,a0,-1012 # b280 <main+0x150>
    167c:	fffff097          	auipc	ra,0xfffff
    1680:	058080e7          	jalr	88(ra) # 6d4 <panic>

00001684 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    1684:	ff010113          	add	sp,sp,-16
    1688:	00812623          	sw	s0,12(sp)
    168c:	01010413          	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    1690:	0e060463          	beqz	a2,1778 <memset+0xf4>
    1694:	40a006b3          	neg	a3,a0
    1698:	fff60813          	add	a6,a2,-1 # fff <freerange+0xc7>
    169c:	00500893          	li	a7,5
    cdst[i] = c;
    16a0:	0ff5f713          	zext.b	a4,a1
    16a4:	0036f793          	and	a5,a3,3
    16a8:	1108f063          	bgeu	a7,a6,17a8 <memset+0x124>
    16ac:	0e078263          	beqz	a5,1790 <memset+0x10c>
    16b0:	00e50023          	sb	a4,0(a0)
  for(i = 0; i < n; i++){
    16b4:	0026f693          	and	a3,a3,2
    16b8:	0c068663          	beqz	a3,1784 <memset+0x100>
    cdst[i] = c;
    16bc:	fff50693          	add	a3,a0,-1
    16c0:	00e500a3          	sb	a4,1(a0)
  for(i = 0; i < n; i++){
    16c4:	0036f693          	and	a3,a3,3
    16c8:	0c069a63          	bnez	a3,179c <memset+0x118>
    cdst[i] = c;
    16cc:	00e50123          	sb	a4,2(a0)
  for(i = 0; i < n; i++){
    16d0:	00300e13          	li	t3,3
    16d4:	00300893          	li	a7,3
    16d8:	00871693          	sll	a3,a4,0x8
    16dc:	40f605b3          	sub	a1,a2,a5
    16e0:	01071813          	sll	a6,a4,0x10
    16e4:	00d766b3          	or	a3,a4,a3
    16e8:	0106e6b3          	or	a3,a3,a6
    16ec:	01871313          	sll	t1,a4,0x18
    16f0:	00f507b3          	add	a5,a0,a5
    16f4:	ffc5f813          	and	a6,a1,-4
    16f8:	0066e6b3          	or	a3,a3,t1
    16fc:	00f80833          	add	a6,a6,a5
    cdst[i] = c;
    1700:	00d7a023          	sw	a3,0(a5)
  for(i = 0; i < n; i++){
    1704:	00478793          	add	a5,a5,4
    1708:	ff079ce3          	bne	a5,a6,1700 <memset+0x7c>
    170c:	0035f793          	and	a5,a1,3
    1710:	06078463          	beqz	a5,1778 <memset+0xf4>
    1714:	ffc5f793          	and	a5,a1,-4
    1718:	00f888b3          	add	a7,a7,a5
    171c:	01c787b3          	add	a5,a5,t3
    cdst[i] = c;
    1720:	011508b3          	add	a7,a0,a7
    1724:	00e88023          	sb	a4,0(a7)
  for(i = 0; i < n; i++){
    1728:	00178693          	add	a3,a5,1
    172c:	04c6f663          	bgeu	a3,a2,1778 <memset+0xf4>
    cdst[i] = c;
    1730:	00d506b3          	add	a3,a0,a3
    1734:	00e68023          	sb	a4,0(a3)
  for(i = 0; i < n; i++){
    1738:	00278693          	add	a3,a5,2
    173c:	02c6fe63          	bgeu	a3,a2,1778 <memset+0xf4>
    cdst[i] = c;
    1740:	00d506b3          	add	a3,a0,a3
    1744:	00e68023          	sb	a4,0(a3)
  for(i = 0; i < n; i++){
    1748:	00378693          	add	a3,a5,3
    174c:	02c6f663          	bgeu	a3,a2,1778 <memset+0xf4>
    cdst[i] = c;
    1750:	00d506b3          	add	a3,a0,a3
    1754:	00e68023          	sb	a4,0(a3)
  for(i = 0; i < n; i++){
    1758:	00478693          	add	a3,a5,4
    175c:	00c6fe63          	bgeu	a3,a2,1778 <memset+0xf4>
    cdst[i] = c;
    1760:	00d506b3          	add	a3,a0,a3
    1764:	00e68023          	sb	a4,0(a3)
  for(i = 0; i < n; i++){
    1768:	00578793          	add	a5,a5,5
    176c:	00c7f663          	bgeu	a5,a2,1778 <memset+0xf4>
    cdst[i] = c;
    1770:	00f507b3          	add	a5,a0,a5
    1774:	00e78023          	sb	a4,0(a5)
  }
  return dst;
}
    1778:	00c12403          	lw	s0,12(sp)
    177c:	01010113          	add	sp,sp,16
    1780:	00008067          	ret
  for(i = 0; i < n; i++){
    1784:	00100e13          	li	t3,1
    1788:	00100893          	li	a7,1
    178c:	f4dff06f          	j	16d8 <memset+0x54>
    1790:	00000893          	li	a7,0
    1794:	00000e13          	li	t3,0
    1798:	f41ff06f          	j	16d8 <memset+0x54>
    179c:	00200e13          	li	t3,2
    17a0:	00200893          	li	a7,2
    17a4:	f35ff06f          	j	16d8 <memset+0x54>
    17a8:	00000793          	li	a5,0
    17ac:	00000893          	li	a7,0
    17b0:	f71ff06f          	j	1720 <memset+0x9c>

000017b4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    17b4:	ff010113          	add	sp,sp,-16
    17b8:	00812623          	sw	s0,12(sp)
    17bc:	01010413          	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    17c0:	02060a63          	beqz	a2,17f4 <memcmp+0x40>
    17c4:	00c58633          	add	a2,a1,a2
    17c8:	0080006f          	j	17d0 <memcmp+0x1c>
    17cc:	02c58463          	beq	a1,a2,17f4 <memcmp+0x40>
    if(*s1 != *s2)
    17d0:	00054783          	lbu	a5,0(a0)
    17d4:	0005c703          	lbu	a4,0(a1)
      return *s1 - *s2;
    s1++, s2++;
    17d8:	00150513          	add	a0,a0,1
    17dc:	00158593          	add	a1,a1,1
    if(*s1 != *s2)
    17e0:	fee786e3          	beq	a5,a4,17cc <memcmp+0x18>
  }

  return 0;
}
    17e4:	00c12403          	lw	s0,12(sp)
      return *s1 - *s2;
    17e8:	40e78533          	sub	a0,a5,a4
}
    17ec:	01010113          	add	sp,sp,16
    17f0:	00008067          	ret
    17f4:	00c12403          	lw	s0,12(sp)
  return 0;
    17f8:	00000513          	li	a0,0
}
    17fc:	01010113          	add	sp,sp,16
    1800:	00008067          	ret

00001804 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    1804:	ff010113          	add	sp,sp,-16
    1808:	00812623          	sw	s0,12(sp)
    180c:	01010413          	add	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    1810:	02a5fa63          	bgeu	a1,a0,1844 <memmove+0x40>
    1814:	00c587b3          	add	a5,a1,a2
    1818:	02f57663          	bgeu	a0,a5,1844 <memmove+0x40>
    s += n;
    d += n;
    181c:	00c50733          	add	a4,a0,a2
    while(n-- > 0)
    1820:	00060c63          	beqz	a2,1838 <memmove+0x34>
      *--d = *--s;
    1824:	fff7c683          	lbu	a3,-1(a5)
    1828:	fff78793          	add	a5,a5,-1
    182c:	fff70713          	add	a4,a4,-1 # ffffefff <end+0xfffdafeb>
    1830:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    1834:	fef598e3          	bne	a1,a5,1824 <memmove+0x20>
  } else
    while(n-- > 0)
      *d++ = *s++;

  return dst;
}
    1838:	00c12403          	lw	s0,12(sp)
    183c:	01010113          	add	sp,sp,16
    1840:	00008067          	ret
    while(n-- > 0)
    1844:	fe060ae3          	beqz	a2,1838 <memmove+0x34>
    while(n-- > 0)
    1848:	fff60893          	add	a7,a2,-1
    184c:	00600793          	li	a5,6
    1850:	00158713          	add	a4,a1,1
    1854:	0917f463          	bgeu	a5,a7,18dc <memmove+0xd8>
    1858:	40e507b3          	sub	a5,a0,a4
    185c:	0037b793          	sltiu	a5,a5,3
    1860:	06079e63          	bnez	a5,18dc <memmove+0xd8>
    1864:	00a5e7b3          	or	a5,a1,a0
    1868:	0037f793          	and	a5,a5,3
    186c:	06079863          	bnez	a5,18dc <memmove+0xd8>
    1870:	ffc67813          	and	a6,a2,-4
    1874:	00058793          	mv	a5,a1
    1878:	00050713          	mv	a4,a0
    187c:	00b80833          	add	a6,a6,a1
      *d++ = *s++;
    1880:	0007a683          	lw	a3,0(a5)
    1884:	00478793          	add	a5,a5,4
    1888:	00470713          	add	a4,a4,4
    188c:	fed72e23          	sw	a3,-4(a4)
    while(n-- > 0)
    1890:	ff0798e3          	bne	a5,a6,1880 <memmove+0x7c>
    1894:	ffc67793          	and	a5,a2,-4
    1898:	00367613          	and	a2,a2,3
    189c:	00f585b3          	add	a1,a1,a5
    18a0:	00f50733          	add	a4,a0,a5
    18a4:	40f888b3          	sub	a7,a7,a5
    18a8:	f80608e3          	beqz	a2,1838 <memmove+0x34>
      *d++ = *s++;
    18ac:	0005c783          	lbu	a5,0(a1)
    18b0:	00f70023          	sb	a5,0(a4)
    while(n-- > 0)
    18b4:	f80882e3          	beqz	a7,1838 <memmove+0x34>
      *d++ = *s++;
    18b8:	0015c683          	lbu	a3,1(a1)
    while(n-- > 0)
    18bc:	00100793          	li	a5,1
      *d++ = *s++;
    18c0:	00d700a3          	sb	a3,1(a4)
    while(n-- > 0)
    18c4:	f6f88ae3          	beq	a7,a5,1838 <memmove+0x34>
      *d++ = *s++;
    18c8:	0025c783          	lbu	a5,2(a1)
    18cc:	00f70123          	sb	a5,2(a4)
}
    18d0:	00c12403          	lw	s0,12(sp)
    18d4:	01010113          	add	sp,sp,16
    18d8:	00008067          	ret
    18dc:	00c50633          	add	a2,a0,a2
{
    18e0:	00050793          	mv	a5,a0
      *d++ = *s++;
    18e4:	fff74683          	lbu	a3,-1(a4)
    18e8:	00178793          	add	a5,a5,1
    18ec:	00170713          	add	a4,a4,1
    18f0:	fed78fa3          	sb	a3,-1(a5)
    while(n-- > 0)
    18f4:	fec798e3          	bne	a5,a2,18e4 <memmove+0xe0>
}
    18f8:	00c12403          	lw	s0,12(sp)
    18fc:	01010113          	add	sp,sp,16
    1900:	00008067          	ret

00001904 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    1904:	ff010113          	add	sp,sp,-16
    1908:	00812623          	sw	s0,12(sp)
    190c:	01010413          	add	s0,sp,16
  if(s < d && s + n > d){
    1910:	02a5fa63          	bgeu	a1,a0,1944 <memcpy+0x40>
    1914:	00c587b3          	add	a5,a1,a2
    1918:	02f57663          	bgeu	a0,a5,1944 <memcpy+0x40>
    d += n;
    191c:	00c50733          	add	a4,a0,a2
    while(n-- > 0)
    1920:	00060c63          	beqz	a2,1938 <memcpy+0x34>
      *--d = *--s;
    1924:	fff7c683          	lbu	a3,-1(a5)
    1928:	fff78793          	add	a5,a5,-1
    192c:	fff70713          	add	a4,a4,-1
    1930:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    1934:	fef598e3          	bne	a1,a5,1924 <memcpy+0x20>
  return memmove(dst, src, n);
}
    1938:	00c12403          	lw	s0,12(sp)
    193c:	01010113          	add	sp,sp,16
    1940:	00008067          	ret
    while(n-- > 0)
    1944:	fe060ae3          	beqz	a2,1938 <memcpy+0x34>
    while(n-- > 0)
    1948:	fff60893          	add	a7,a2,-1
    194c:	00600793          	li	a5,6
    1950:	00158713          	add	a4,a1,1
    1954:	0917f663          	bgeu	a5,a7,19e0 <memcpy+0xdc>
    1958:	00b567b3          	or	a5,a0,a1
    195c:	0037f793          	and	a5,a5,3
    1960:	00158713          	add	a4,a1,1
    1964:	06079e63          	bnez	a5,19e0 <memcpy+0xdc>
    1968:	40e507b3          	sub	a5,a0,a4
    196c:	0037b793          	sltiu	a5,a5,3
    1970:	06079863          	bnez	a5,19e0 <memcpy+0xdc>
    1974:	ffc67813          	and	a6,a2,-4
    1978:	00058793          	mv	a5,a1
    197c:	00050713          	mv	a4,a0
    1980:	00b80833          	add	a6,a6,a1
      *d++ = *s++;
    1984:	0007a683          	lw	a3,0(a5)
    1988:	00478793          	add	a5,a5,4
    198c:	00470713          	add	a4,a4,4
    1990:	fed72e23          	sw	a3,-4(a4)
    while(n-- > 0)
    1994:	ff0798e3          	bne	a5,a6,1984 <memcpy+0x80>
    1998:	ffc67793          	and	a5,a2,-4
    199c:	00367613          	and	a2,a2,3
    19a0:	00f585b3          	add	a1,a1,a5
    19a4:	00f50733          	add	a4,a0,a5
    19a8:	40f888b3          	sub	a7,a7,a5
    19ac:	f80606e3          	beqz	a2,1938 <memcpy+0x34>
      *d++ = *s++;
    19b0:	0005c783          	lbu	a5,0(a1)
    19b4:	00f70023          	sb	a5,0(a4)
    while(n-- > 0)
    19b8:	f80880e3          	beqz	a7,1938 <memcpy+0x34>
      *d++ = *s++;
    19bc:	0015c683          	lbu	a3,1(a1)
    while(n-- > 0)
    19c0:	00100793          	li	a5,1
      *d++ = *s++;
    19c4:	00d700a3          	sb	a3,1(a4)
    while(n-- > 0)
    19c8:	f6f888e3          	beq	a7,a5,1938 <memcpy+0x34>
      *d++ = *s++;
    19cc:	0025c783          	lbu	a5,2(a1)
    19d0:	00f70123          	sb	a5,2(a4)
}
    19d4:	00c12403          	lw	s0,12(sp)
    19d8:	01010113          	add	sp,sp,16
    19dc:	00008067          	ret
    19e0:	00c50633          	add	a2,a0,a2
{
    19e4:	00050793          	mv	a5,a0
      *d++ = *s++;
    19e8:	fff74683          	lbu	a3,-1(a4)
    19ec:	00178793          	add	a5,a5,1
    19f0:	00170713          	add	a4,a4,1
    19f4:	fed78fa3          	sb	a3,-1(a5)
    while(n-- > 0)
    19f8:	fec798e3          	bne	a5,a2,19e8 <memcpy+0xe4>
}
    19fc:	00c12403          	lw	s0,12(sp)
    1a00:	01010113          	add	sp,sp,16
    1a04:	00008067          	ret

00001a08 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    1a08:	ff010113          	add	sp,sp,-16
    1a0c:	00812623          	sw	s0,12(sp)
    1a10:	01010413          	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    1a14:	00061e63          	bnez	a2,1a30 <strncmp+0x28>
    1a18:	03c0006f          	j	1a54 <strncmp+0x4c>
    1a1c:	0005c703          	lbu	a4,0(a1)
    1a20:	00f71e63          	bne	a4,a5,1a3c <strncmp+0x34>
    n--, p++, q++;
    1a24:	00150513          	add	a0,a0,1
    1a28:	00158593          	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    1a2c:	02060463          	beqz	a2,1a54 <strncmp+0x4c>
    1a30:	00054783          	lbu	a5,0(a0)
    n--, p++, q++;
    1a34:	fff60613          	add	a2,a2,-1
  while(n > 0 && *p && *p == *q)
    1a38:	fe0792e3          	bnez	a5,1a1c <strncmp+0x14>
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
    1a3c:	00054503          	lbu	a0,0(a0)
    1a40:	0005c783          	lbu	a5,0(a1)
}
    1a44:	00c12403          	lw	s0,12(sp)
  return (uchar)*p - (uchar)*q;
    1a48:	40f50533          	sub	a0,a0,a5
}
    1a4c:	01010113          	add	sp,sp,16
    1a50:	00008067          	ret
    1a54:	00c12403          	lw	s0,12(sp)
    return 0;
    1a58:	00000513          	li	a0,0
}
    1a5c:	01010113          	add	sp,sp,16
    1a60:	00008067          	ret

00001a64 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    1a64:	ff010113          	add	sp,sp,-16
    1a68:	00812623          	sw	s0,12(sp)
    1a6c:	01010413          	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    1a70:	00050813          	mv	a6,a0
    1a74:	0140006f          	j	1a88 <strncpy+0x24>
    1a78:	fff5c683          	lbu	a3,-1(a1)
    1a7c:	fed78fa3          	sb	a3,-1(a5)
    1a80:	02068463          	beqz	a3,1aa8 <strncpy+0x44>
    1a84:	00078813          	mv	a6,a5
    1a88:	00060713          	mv	a4,a2
    1a8c:	00158593          	add	a1,a1,1
    1a90:	00180793          	add	a5,a6,1
    1a94:	fff60613          	add	a2,a2,-1
    1a98:	fee040e3          	bgtz	a4,1a78 <strncpy+0x14>
    ;
  while(n-- > 0)
    *s++ = 0;
  return os;
}
    1a9c:	00c12403          	lw	s0,12(sp)
    1aa0:	01010113          	add	sp,sp,16
    1aa4:	00008067          	ret
  while(n-- > 0)
    1aa8:	ffe70593          	add	a1,a4,-2
    1aac:	fe0608e3          	beqz	a2,1a9c <strncpy+0x38>
    1ab0:	00100693          	li	a3,1
    1ab4:	00e6d463          	bge	a3,a4,1abc <strncpy+0x58>
    1ab8:	00060693          	mv	a3,a2
    1abc:	40f00633          	neg	a2,a5
    1ac0:	00700313          	li	t1,7
    1ac4:	00367893          	and	a7,a2,3
    1ac8:	06e35a63          	bge	t1,a4,1b3c <strncpy+0xd8>
  while(n-- > 0 && (*s++ = *t++) != 0)
    1acc:	00078313          	mv	t1,a5
    1ad0:	02088e63          	beqz	a7,1b0c <strncpy+0xa8>
    *s++ = 0;
    1ad4:	00078023          	sb	zero,0(a5)
  while(n-- > 0)
    1ad8:	00267613          	and	a2,a2,2
    *s++ = 0;
    1adc:	00280313          	add	t1,a6,2
  while(n-- > 0)
    1ae0:	ffd70593          	add	a1,a4,-3
    1ae4:	02060463          	beqz	a2,1b0c <strncpy+0xa8>
    *s++ = 0;
    1ae8:	fff78613          	add	a2,a5,-1
    1aec:	000780a3          	sb	zero,1(a5)
  while(n-- > 0)
    1af0:	00367613          	and	a2,a2,3
    *s++ = 0;
    1af4:	00380313          	add	t1,a6,3
  while(n-- > 0)
    1af8:	ffc70593          	add	a1,a4,-4
    1afc:	00061863          	bnez	a2,1b0c <strncpy+0xa8>
    *s++ = 0;
    1b00:	00480313          	add	t1,a6,4
    1b04:	00078123          	sb	zero,2(a5)
  while(n-- > 0)
    1b08:	ffb70593          	add	a1,a4,-5
    1b0c:	41168733          	sub	a4,a3,a7
    1b10:	011787b3          	add	a5,a5,a7
    1b14:	ffc77693          	and	a3,a4,-4
    1b18:	00f686b3          	add	a3,a3,a5
    *s++ = 0;
    1b1c:	0007a023          	sw	zero,0(a5)
  while(n-- > 0)
    1b20:	00478793          	add	a5,a5,4
    1b24:	fed79ce3          	bne	a5,a3,1b1c <strncpy+0xb8>
    1b28:	ffc77693          	and	a3,a4,-4
    1b2c:	00377713          	and	a4,a4,3
    1b30:	00d307b3          	add	a5,t1,a3
    1b34:	40d585b3          	sub	a1,a1,a3
    1b38:	f60702e3          	beqz	a4,1a9c <strncpy+0x38>
    *s++ = 0;
    1b3c:	00078023          	sb	zero,0(a5)
  while(n-- > 0)
    1b40:	f4b05ee3          	blez	a1,1a9c <strncpy+0x38>
    *s++ = 0;
    1b44:	000780a3          	sb	zero,1(a5)
  while(n-- > 0)
    1b48:	00100713          	li	a4,1
    1b4c:	f4e588e3          	beq	a1,a4,1a9c <strncpy+0x38>
    *s++ = 0;
    1b50:	00078123          	sb	zero,2(a5)
  while(n-- > 0)
    1b54:	00200713          	li	a4,2
    1b58:	f4e582e3          	beq	a1,a4,1a9c <strncpy+0x38>
    *s++ = 0;
    1b5c:	000781a3          	sb	zero,3(a5)
  while(n-- > 0)
    1b60:	00300713          	li	a4,3
    1b64:	f2e58ce3          	beq	a1,a4,1a9c <strncpy+0x38>
    *s++ = 0;
    1b68:	00078223          	sb	zero,4(a5)
  while(n-- > 0)
    1b6c:	00400713          	li	a4,4
    1b70:	f2e586e3          	beq	a1,a4,1a9c <strncpy+0x38>
    *s++ = 0;
    1b74:	000782a3          	sb	zero,5(a5)
}
    1b78:	00c12403          	lw	s0,12(sp)
    1b7c:	01010113          	add	sp,sp,16
    1b80:	00008067          	ret

00001b84 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    1b84:	ff010113          	add	sp,sp,-16
    1b88:	00812623          	sw	s0,12(sp)
    1b8c:	01010413          	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    1b90:	02c05663          	blez	a2,1bbc <safestrcpy+0x38>
    1b94:	fff60613          	add	a2,a2,-1
    1b98:	00c586b3          	add	a3,a1,a2
    1b9c:	00050793          	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    1ba0:	00d58c63          	beq	a1,a3,1bb8 <safestrcpy+0x34>
    1ba4:	0005c703          	lbu	a4,0(a1)
    1ba8:	00178793          	add	a5,a5,1
    1bac:	00158593          	add	a1,a1,1
    1bb0:	fee78fa3          	sb	a4,-1(a5)
    1bb4:	fe0716e3          	bnez	a4,1ba0 <safestrcpy+0x1c>
    ;
  *s = 0;
    1bb8:	00078023          	sb	zero,0(a5)
  return os;
}
    1bbc:	00c12403          	lw	s0,12(sp)
    1bc0:	01010113          	add	sp,sp,16
    1bc4:	00008067          	ret

00001bc8 <strlen>:

int
strlen(const char *s)
{
    1bc8:	ff010113          	add	sp,sp,-16
    1bcc:	00812623          	sw	s0,12(sp)
    1bd0:	01010413          	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    1bd4:	00054783          	lbu	a5,0(a0)
    1bd8:	02078463          	beqz	a5,1c00 <strlen+0x38>
    1bdc:	00050713          	mv	a4,a0
    1be0:	00000513          	li	a0,0
    1be4:	00150513          	add	a0,a0,1
    1be8:	00a707b3          	add	a5,a4,a0
    1bec:	0007c783          	lbu	a5,0(a5)
    1bf0:	fe079ae3          	bnez	a5,1be4 <strlen+0x1c>
    ;
  return n;
}
    1bf4:	00c12403          	lw	s0,12(sp)
    1bf8:	01010113          	add	sp,sp,16
    1bfc:	00008067          	ret
    1c00:	00c12403          	lw	s0,12(sp)
  for(n = 0; s[n]; n++)
    1c04:	00000513          	li	a0,0
}
    1c08:	01010113          	add	sp,sp,16
    1c0c:	00008067          	ret

00001c10 <mappages.constprop.0>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint32 va, uint32 size, uint32 pa, int perm)
    1c10:	fd010113          	add	sp,sp,-48
    1c14:	01412c23          	sw	s4,24(sp)
{
  uint32 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
    1c18:	00001a37          	lui	s4,0x1
  a = PGROUNDDOWN(va);
    1c1c:	fffff7b7          	lui	a5,0xfffff
  last = PGROUNDDOWN(va + size - 1);
    1c20:	fffa0a13          	add	s4,s4,-1 # fff <freerange+0xc7>
mappages(pagetable_t pagetable, uint32 va, uint32 size, uint32 pa, int perm)
    1c24:	02812423          	sw	s0,40(sp)
    1c28:	03212023          	sw	s2,32(sp)
    1c2c:	01512a23          	sw	s5,20(sp)
    1c30:	01612823          	sw	s6,16(sp)
    1c34:	01712623          	sw	s7,12(sp)
    1c38:	02112623          	sw	ra,44(sp)
    1c3c:	02912223          	sw	s1,36(sp)
    1c40:	01312e23          	sw	s3,28(sp)
    1c44:	01812423          	sw	s8,8(sp)
    1c48:	03010413          	add	s0,sp,48
  last = PGROUNDDOWN(va + size - 1);
    1c4c:	01458a33          	add	s4,a1,s4
  a = PGROUNDDOWN(va);
    1c50:	00f5f933          	and	s2,a1,a5
mappages(pagetable_t pagetable, uint32 va, uint32 size, uint32 pa, int perm)
    1c54:	00050b13          	mv	s6,a0
    1c58:	00068b93          	mv	s7,a3
  last = PGROUNDDOWN(va + size - 1);
    1c5c:	00fa7a33          	and	s4,s4,a5
    1c60:	41260ab3          	sub	s5,a2,s2
    1c64:	04c0006f          	j	1cb0 <mappages.constprop.0+0xa0>
  return &pagetable[PX(0, va)];
    1c68:	00c95793          	srl	a5,s2,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    1c6c:	00a4d493          	srl	s1,s1,0xa
  return &pagetable[PX(0, va)];
    1c70:	3ff7f793          	and	a5,a5,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    1c74:	00c49493          	sll	s1,s1,0xc
  return &pagetable[PX(0, va)];
    1c78:	00279793          	sll	a5,a5,0x2
    1c7c:	00f484b3          	add	s1,s1,a5
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
    1c80:	08048863          	beqz	s1,1d10 <mappages.constprop.0+0x100>
      return -1;
    if(*pte & PTE_V)
    1c84:	0004a783          	lw	a5,0(s1)
    1c88:	0017f793          	and	a5,a5,1
    1c8c:	0c079063          	bnez	a5,1d4c <mappages.constprop.0+0x13c>
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    1c90:	00c9d793          	srl	a5,s3,0xc
    1c94:	00a79793          	sll	a5,a5,0xa
    1c98:	0177e7b3          	or	a5,a5,s7
    1c9c:	0017e793          	or	a5,a5,1
    1ca0:	00f4a023          	sw	a5,0(s1)
    if(a == last)
    1ca4:	0b2a0063          	beq	s4,s2,1d44 <mappages.constprop.0+0x134>
      break;
    a += PGSIZE;
    1ca8:	000017b7          	lui	a5,0x1
    1cac:	00f90933          	add	s2,s2,a5
    pte_t *pte = &pagetable[PX(level, va)];
    1cb0:	01695c13          	srl	s8,s2,0x16
    1cb4:	002c1c13          	sll	s8,s8,0x2
    1cb8:	018b0c33          	add	s8,s6,s8
    if(*pte & PTE_V) {
    1cbc:	000c2483          	lw	s1,0(s8)
    1cc0:	015909b3          	add	s3,s2,s5
    1cc4:	0014f793          	and	a5,s1,1
    1cc8:	fa0790e3          	bnez	a5,1c68 <mappages.constprop.0+0x58>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    1ccc:	fffff097          	auipc	ra,0xfffff
    1cd0:	3e0080e7          	jalr	992(ra) # 10ac <kalloc>
    1cd4:	00050493          	mv	s1,a0
    1cd8:	02050c63          	beqz	a0,1d10 <mappages.constprop.0+0x100>
      memset(pagetable, 0, PGSIZE);
    1cdc:	00001637          	lui	a2,0x1
    1ce0:	00000593          	li	a1,0
    1ce4:	00000097          	auipc	ra,0x0
    1ce8:	9a0080e7          	jalr	-1632(ra) # 1684 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    1cec:	00c4d713          	srl	a4,s1,0xc
  return &pagetable[PX(0, va)];
    1cf0:	00c95793          	srl	a5,s2,0xc
      *pte = PA2PTE(pagetable) | PTE_V;
    1cf4:	00a71713          	sll	a4,a4,0xa
  return &pagetable[PX(0, va)];
    1cf8:	3ff7f793          	and	a5,a5,1023
      *pte = PA2PTE(pagetable) | PTE_V;
    1cfc:	00176713          	or	a4,a4,1
  return &pagetable[PX(0, va)];
    1d00:	00279793          	sll	a5,a5,0x2
      *pte = PA2PTE(pagetable) | PTE_V;
    1d04:	00ec2023          	sw	a4,0(s8)
  return &pagetable[PX(0, va)];
    1d08:	00f484b3          	add	s1,s1,a5
    1d0c:	f79ff06f          	j	1c84 <mappages.constprop.0+0x74>
      return -1;
    1d10:	fff00513          	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    1d14:	02c12083          	lw	ra,44(sp)
    1d18:	02812403          	lw	s0,40(sp)
    1d1c:	02412483          	lw	s1,36(sp)
    1d20:	02012903          	lw	s2,32(sp)
    1d24:	01c12983          	lw	s3,28(sp)
    1d28:	01812a03          	lw	s4,24(sp)
    1d2c:	01412a83          	lw	s5,20(sp)
    1d30:	01012b03          	lw	s6,16(sp)
    1d34:	00c12b83          	lw	s7,12(sp)
    1d38:	00812c03          	lw	s8,8(sp)
    1d3c:	03010113          	add	sp,sp,48
    1d40:	00008067          	ret
  return 0;
    1d44:	00000513          	li	a0,0
    1d48:	fcdff06f          	j	1d14 <mappages.constprop.0+0x104>
      panic("remap");
    1d4c:	00009517          	auipc	a0,0x9
    1d50:	59050513          	add	a0,a0,1424 # b2dc <main+0x1ac>
    1d54:	fffff097          	auipc	ra,0xfffff
    1d58:	980080e7          	jalr	-1664(ra) # 6d4 <panic>

00001d5c <uvmunmap.constprop.0>:

// Remove mappings from a page table. The mappings in
// the given range must exist. Optionally free the
// physical memory.
void
uvmunmap(pagetable_t pagetable, uint32 va, uint32 size, int do_free)
    1d5c:	fe010113          	add	sp,sp,-32
  uint32 a, last;
  pte_t *pte;
  uint32 pa;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
    1d60:	fff60793          	add	a5,a2,-1 # fff <freerange+0xc7>
uvmunmap(pagetable_t pagetable, uint32 va, uint32 size, int do_free)
    1d64:	00812c23          	sw	s0,24(sp)
    1d68:	01212823          	sw	s2,16(sp)
    1d6c:	01312623          	sw	s3,12(sp)
    1d70:	01412423          	sw	s4,8(sp)
    1d74:	01512223          	sw	s5,4(sp)
    1d78:	01612023          	sw	s6,0(sp)
  a = PGROUNDDOWN(va);
    1d7c:	fffff737          	lui	a4,0xfffff
uvmunmap(pagetable_t pagetable, uint32 va, uint32 size, int do_free)
    1d80:	00112e23          	sw	ra,28(sp)
    1d84:	00912a23          	sw	s1,20(sp)
    1d88:	02010413          	add	s0,sp,32
  last = PGROUNDDOWN(va + size - 1);
    1d8c:	00b787b3          	add	a5,a5,a1
uvmunmap(pagetable_t pagetable, uint32 va, uint32 size, int do_free)
    1d90:	00050993          	mv	s3,a0
  a = PGROUNDDOWN(va);
    1d94:	00e5fb33          	and	s6,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    1d98:	00e7f933          	and	s2,a5,a4
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0){
      printf("va=%p pte=%p\n", a, *pte);
      panic("uvmunmap: not mapped");
    }
    if(PTE_FLAGS(*pte) == PTE_V)
    1d9c:	00100a13          	li	s4,1
      kfree((void*)pa);
    }
    *pte = 0;
    if(a == last)
      break;
    a += PGSIZE;
    1da0:	00001ab7          	lui	s5,0x1
    pte_t *pte = &pagetable[PX(level, va)];
    1da4:	016b5793          	srl	a5,s6,0x16
    if(*pte & PTE_V) {
    1da8:	00279793          	sll	a5,a5,0x2
    1dac:	00f987b3          	add	a5,s3,a5
    1db0:	0007a483          	lw	s1,0(a5) # 1000 <freerange+0xc8>
    1db4:	0014f793          	and	a5,s1,1
    1db8:	00079a63          	bnez	a5,1dcc <uvmunmap.constprop.0+0x70>
      panic("uvmunmap: walk");
    1dbc:	00009517          	auipc	a0,0x9
    1dc0:	52850513          	add	a0,a0,1320 # b2e4 <main+0x1b4>
    1dc4:	fffff097          	auipc	ra,0xfffff
    1dc8:	910080e7          	jalr	-1776(ra) # 6d4 <panic>
  return &pagetable[PX(0, va)];
    1dcc:	00cb5793          	srl	a5,s6,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    1dd0:	00a4d493          	srl	s1,s1,0xa
  return &pagetable[PX(0, va)];
    1dd4:	3ff7f793          	and	a5,a5,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    1dd8:	00c49493          	sll	s1,s1,0xc
  return &pagetable[PX(0, va)];
    1ddc:	00279793          	sll	a5,a5,0x2
    1de0:	00f484b3          	add	s1,s1,a5
    if((pte = walk(pagetable, a, 0)) == 0)
    1de4:	fc048ce3          	beqz	s1,1dbc <uvmunmap.constprop.0+0x60>
    if((*pte & PTE_V) == 0){
    1de8:	0004a603          	lw	a2,0(s1)
    1dec:	00167793          	and	a5,a2,1
    1df0:	04078a63          	beqz	a5,1e44 <uvmunmap.constprop.0+0xe8>
    if(PTE_FLAGS(*pte) == PTE_V)
    1df4:	3ff67793          	and	a5,a2,1023
    1df8:	07478863          	beq	a5,s4,1e68 <uvmunmap.constprop.0+0x10c>
      pa = PTE2PA(*pte);
    1dfc:	00a65613          	srl	a2,a2,0xa
      kfree((void*)pa);
    1e00:	00c61513          	sll	a0,a2,0xc
    1e04:	fffff097          	auipc	ra,0xfffff
    1e08:	220080e7          	jalr	544(ra) # 1024 <kfree>
    *pte = 0;
    1e0c:	0004a023          	sw	zero,0(s1)
    if(a == last)
    1e10:	01690663          	beq	s2,s6,1e1c <uvmunmap.constprop.0+0xc0>
    a += PGSIZE;
    1e14:	015b0b33          	add	s6,s6,s5
    if((pte = walk(pagetable, a, 0)) == 0)
    1e18:	f8dff06f          	j	1da4 <uvmunmap.constprop.0+0x48>
    pa += PGSIZE;
  }
}
    1e1c:	01c12083          	lw	ra,28(sp)
    1e20:	01812403          	lw	s0,24(sp)
    1e24:	01412483          	lw	s1,20(sp)
    1e28:	01012903          	lw	s2,16(sp)
    1e2c:	00c12983          	lw	s3,12(sp)
    1e30:	00812a03          	lw	s4,8(sp)
    1e34:	00412a83          	lw	s5,4(sp)
    1e38:	00012b03          	lw	s6,0(sp)
    1e3c:	02010113          	add	sp,sp,32
    1e40:	00008067          	ret
      printf("va=%p pte=%p\n", a, *pte);
    1e44:	00009517          	auipc	a0,0x9
    1e48:	4b050513          	add	a0,a0,1200 # b2f4 <main+0x1c4>
    1e4c:	000b0593          	mv	a1,s6
    1e50:	fffff097          	auipc	ra,0xfffff
    1e54:	8e0080e7          	jalr	-1824(ra) # 730 <printf>
      panic("uvmunmap: not mapped");
    1e58:	00009517          	auipc	a0,0x9
    1e5c:	4ac50513          	add	a0,a0,1196 # b304 <main+0x1d4>
    1e60:	fffff097          	auipc	ra,0xfffff
    1e64:	874080e7          	jalr	-1932(ra) # 6d4 <panic>
      panic("uvmunmap: not a leaf");
    1e68:	00009517          	auipc	a0,0x9
    1e6c:	4b450513          	add	a0,a0,1204 # b31c <main+0x1ec>
    1e70:	fffff097          	auipc	ra,0xfffff
    1e74:	864080e7          	jalr	-1948(ra) # 6d4 <panic>

00001e78 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    1e78:	f7010113          	add	sp,sp,-144
    1e7c:	000017b7          	lui	a5,0x1
    1e80:	08812423          	sw	s0,136(sp)
    1e84:	08912223          	sw	s1,132(sp)
    1e88:	07912223          	sw	s9,100(sp)
    1e8c:	07a12023          	sw	s10,96(sp)
    1e90:	08112623          	sw	ra,140(sp)
    1e94:	09212023          	sw	s2,128(sp)
    1e98:	07312e23          	sw	s3,124(sp)
    1e9c:	07412c23          	sw	s4,120(sp)
    1ea0:	07512a23          	sw	s5,116(sp)
    1ea4:	07612823          	sw	s6,112(sp)
    1ea8:	07712623          	sw	s7,108(sp)
    1eac:	07812423          	sw	s8,104(sp)
    1eb0:	05b12e23          	sw	s11,92(sp)
    1eb4:	09010413          	add	s0,sp,144
    1eb8:	80078793          	add	a5,a5,-2048 # 800 <printf+0xd0>
    1ebc:	00050493          	mv	s1,a0
    1ec0:	00f50d33          	add	s10,a0,a5
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1ec4:	00050c93          	mv	s9,a0
    pte_t pte = pagetable[i];
    1ec8:	0004a783          	lw	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1ecc:	00100693          	li	a3,1
    1ed0:	00f7f713          	and	a4,a5,15
    1ed4:	04d70c63          	beq	a4,a3,1f2c <freewalk+0xb4>
      // this PTE points to a lower-level page table.
      uint32 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
    1ed8:	0017f793          	and	a5,a5,1
    1edc:	32079663          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    1ee0:	00448493          	add	s1,s1,4
    1ee4:	fe9d12e3          	bne	s10,s1,1ec8 <freewalk+0x50>
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}
    1ee8:	08812403          	lw	s0,136(sp)
    1eec:	08c12083          	lw	ra,140(sp)
    1ef0:	08412483          	lw	s1,132(sp)
    1ef4:	08012903          	lw	s2,128(sp)
    1ef8:	07c12983          	lw	s3,124(sp)
    1efc:	07812a03          	lw	s4,120(sp)
    1f00:	07412a83          	lw	s5,116(sp)
    1f04:	07012b03          	lw	s6,112(sp)
    1f08:	06c12b83          	lw	s7,108(sp)
    1f0c:	06812c03          	lw	s8,104(sp)
    1f10:	06012d03          	lw	s10,96(sp)
    1f14:	05c12d83          	lw	s11,92(sp)
  kfree((void*)pagetable);
    1f18:	000c8513          	mv	a0,s9
}
    1f1c:	06412c83          	lw	s9,100(sp)
    1f20:	09010113          	add	sp,sp,144
  kfree((void*)pagetable);
    1f24:	fffff317          	auipc	t1,0xfffff
    1f28:	10030067          	jr	256(t1) # 1024 <kfree>
      uint32 child = PTE2PA(pte);
    1f2c:	00a7d793          	srl	a5,a5,0xa
    1f30:	00c79b13          	sll	s6,a5,0xc
  for(int i = 0; i < 512; i++){
    1f34:	000017b7          	lui	a5,0x1
    1f38:	80078793          	add	a5,a5,-2048 # 800 <printf+0xd0>
    1f3c:	00fb0db3          	add	s11,s6,a5
      uint32 child = PTE2PA(pte);
    1f40:	000b0b93          	mv	s7,s6
    pte_t pte = pagetable[i];
    1f44:	000ba783          	lw	a5,0(s7) # 2000000 <end+0x1fdbfec>
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1f48:	00100693          	li	a3,1
    1f4c:	00f7f713          	and	a4,a5,15
    1f50:	02d70463          	beq	a4,a3,1f78 <freewalk+0x100>
    } else if(pte & PTE_V){
    1f54:	0017f793          	and	a5,a5,1
    1f58:	2a079863          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    1f5c:	004b8b93          	add	s7,s7,4
    1f60:	ff7d92e3          	bne	s11,s7,1f44 <freewalk+0xcc>
  kfree((void*)pagetable);
    1f64:	000b0513          	mv	a0,s6
    1f68:	fffff097          	auipc	ra,0xfffff
    1f6c:	0bc080e7          	jalr	188(ra) # 1024 <kfree>
      pagetable[i] = 0;
    1f70:	0004a023          	sw	zero,0(s1)
    1f74:	f6dff06f          	j	1ee0 <freewalk+0x68>
      uint32 child = PTE2PA(pte);
    1f78:	00a7d793          	srl	a5,a5,0xa
    1f7c:	00c79913          	sll	s2,a5,0xc
  for(int i = 0; i < 512; i++){
    1f80:	000017b7          	lui	a5,0x1
    1f84:	80078793          	add	a5,a5,-2048 # 800 <printf+0xd0>
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1f88:	fb642823          	sw	s6,-80(s0)
    1f8c:	00f90a33          	add	s4,s2,a5
    1f90:	fb242623          	sw	s2,-84(s0)
    1f94:	00090b13          	mv	s6,s2
    pte_t pte = pagetable[i];
    1f98:	000b2783          	lw	a5,0(s6) # 1000 <freerange+0xc8>
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1f9c:	00100693          	li	a3,1
    1fa0:	00f7f713          	and	a4,a5,15
    1fa4:	02d70863          	beq	a4,a3,1fd4 <freewalk+0x15c>
    } else if(pte & PTE_V){
    1fa8:	0017f793          	and	a5,a5,1
    1fac:	24079e63          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    1fb0:	004b0b13          	add	s6,s6,4
    1fb4:	ff6a12e3          	bne	s4,s6,1f98 <freewalk+0x120>
  kfree((void*)pagetable);
    1fb8:	fac42903          	lw	s2,-84(s0)
    1fbc:	fb042b03          	lw	s6,-80(s0)
    1fc0:	00090513          	mv	a0,s2
    1fc4:	fffff097          	auipc	ra,0xfffff
    1fc8:	060080e7          	jalr	96(ra) # 1024 <kfree>
      pagetable[i] = 0;
    1fcc:	000ba023          	sw	zero,0(s7)
    1fd0:	f8dff06f          	j	1f5c <freewalk+0xe4>
      uint32 child = PTE2PA(pte);
    1fd4:	00a7d793          	srl	a5,a5,0xa
    1fd8:	00c79a93          	sll	s5,a5,0xc
  for(int i = 0; i < 512; i++){
    1fdc:	000017b7          	lui	a5,0x1
    1fe0:	80078793          	add	a5,a5,-2048 # 800 <printf+0xd0>
    1fe4:	00fa87b3          	add	a5,s5,a5
    1fe8:	faf42e23          	sw	a5,-68(s0)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1fec:	fb642423          	sw	s6,-88(s0)
    1ff0:	000a8993          	mv	s3,s5
    pte_t pte = pagetable[i];
    1ff4:	0009a783          	lw	a5,0(s3)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1ff8:	00100693          	li	a3,1
    1ffc:	00f7f713          	and	a4,a5,15
    2000:	02d70863          	beq	a4,a3,2030 <freewalk+0x1b8>
    } else if(pte & PTE_V){
    2004:	0017f793          	and	a5,a5,1
    2008:	20079063          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    200c:	fbc42783          	lw	a5,-68(s0)
    2010:	00498993          	add	s3,s3,4
    2014:	ff3790e3          	bne	a5,s3,1ff4 <freewalk+0x17c>
  kfree((void*)pagetable);
    2018:	fa842b03          	lw	s6,-88(s0)
    201c:	000a8513          	mv	a0,s5
    2020:	fffff097          	auipc	ra,0xfffff
    2024:	004080e7          	jalr	4(ra) # 1024 <kfree>
      pagetable[i] = 0;
    2028:	000b2023          	sw	zero,0(s6)
    202c:	f85ff06f          	j	1fb0 <freewalk+0x138>
      uint32 child = PTE2PA(pte);
    2030:	00a7d793          	srl	a5,a5,0xa
    2034:	00001937          	lui	s2,0x1
    2038:	00c79c13          	sll	s8,a5,0xc
  for(int i = 0; i < 512; i++){
    203c:	80090913          	add	s2,s2,-2048 # 800 <printf+0xd0>
    2040:	012c07b3          	add	a5,s8,s2
    2044:	faf42c23          	sw	a5,-72(s0)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2048:	00100b13          	li	s6,1
    204c:	000c0613          	mv	a2,s8
    pte_t pte = pagetable[i];
    2050:	00062783          	lw	a5,0(a2)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2054:	00f7f693          	and	a3,a5,15
    2058:	03668663          	beq	a3,s6,2084 <freewalk+0x20c>
    } else if(pte & PTE_V){
    205c:	0017f793          	and	a5,a5,1
    2060:	1a079463          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    2064:	fb842783          	lw	a5,-72(s0)
    2068:	00460613          	add	a2,a2,4
    206c:	fec792e3          	bne	a5,a2,2050 <freewalk+0x1d8>
  kfree((void*)pagetable);
    2070:	000c0513          	mv	a0,s8
    2074:	fffff097          	auipc	ra,0xfffff
    2078:	fb0080e7          	jalr	-80(ra) # 1024 <kfree>
      pagetable[i] = 0;
    207c:	0009a023          	sw	zero,0(s3)
    2080:	f8dff06f          	j	200c <freewalk+0x194>
      uint32 child = PTE2PA(pte);
    2084:	00a7d793          	srl	a5,a5,0xa
    2088:	00c79513          	sll	a0,a5,0xc
  for(int i = 0; i < 512; i++){
    208c:	012507b3          	add	a5,a0,s2
    2090:	faf42a23          	sw	a5,-76(s0)
      uint32 child = PTE2PA(pte);
    2094:	00050713          	mv	a4,a0
    2098:	fb542223          	sw	s5,-92(s0)
    209c:	faa42023          	sw	a0,-96(s0)
    20a0:	f8942e23          	sw	s1,-100(s0)
    20a4:	f9442c23          	sw	s4,-104(s0)
    20a8:	f8c42a23          	sw	a2,-108(s0)
    20ac:	0180006f          	j	20c4 <freewalk+0x24c>
    } else if(pte & PTE_V){
    20b0:	0017f793          	and	a5,a5,1
    20b4:	14079a63          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    20b8:	fb442783          	lw	a5,-76(s0)
    20bc:	00470713          	add	a4,a4,4 # fffff004 <end+0xfffdaff0>
    20c0:	14e78c63          	beq	a5,a4,2218 <freewalk+0x3a0>
    pte_t pte = pagetable[i];
    20c4:	00072783          	lw	a5,0(a4)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    20c8:	00f7f693          	and	a3,a5,15
    20cc:	ff6692e3          	bne	a3,s6,20b0 <freewalk+0x238>
      uint32 child = PTE2PA(pte);
    20d0:	00a7d793          	srl	a5,a5,0xa
    20d4:	00c79513          	sll	a0,a5,0xc
  for(int i = 0; i < 512; i++){
    20d8:	01250ab3          	add	s5,a0,s2
      uint32 child = PTE2PA(pte);
    20dc:	f9342623          	sw	s3,-116(s0)
    20e0:	f8a42823          	sw	a0,-112(s0)
    20e4:	f8e42423          	sw	a4,-120(s0)
    20e8:	000a8493          	mv	s1,s5
    20ec:	00050993          	mv	s3,a0
    20f0:	0140006f          	j	2104 <freewalk+0x28c>
    } else if(pte & PTE_V){
    20f4:	0016f693          	and	a3,a3,1
    20f8:	10069863          	bnez	a3,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    20fc:	00498993          	add	s3,s3,4
    2100:	0f348263          	beq	s1,s3,21e4 <freewalk+0x36c>
    pte_t pte = pagetable[i];
    2104:	0009a683          	lw	a3,0(s3)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2108:	00f6f613          	and	a2,a3,15
    210c:	ff6614e3          	bne	a2,s6,20f4 <freewalk+0x27c>
      uint32 child = PTE2PA(pte);
    2110:	00a6d693          	srl	a3,a3,0xa
    2114:	00c69513          	sll	a0,a3,0xc
  for(int i = 0; i < 512; i++){
    2118:	01250ab3          	add	s5,a0,s2
      uint32 child = PTE2PA(pte);
    211c:	f8942023          	sw	s1,-128(s0)
    2120:	00098a13          	mv	s4,s3
    2124:	f8a42223          	sw	a0,-124(s0)
    2128:	000a8493          	mv	s1,s5
    212c:	00050993          	mv	s3,a0
    2130:	0140006f          	j	2144 <freewalk+0x2cc>
    } else if(pte & PTE_V){
    2134:	0017f793          	and	a5,a5,1
    2138:	0c079863          	bnez	a5,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    213c:	00498993          	add	s3,s3,4
    2140:	09348263          	beq	s1,s3,21c4 <freewalk+0x34c>
    pte_t pte = pagetable[i];
    2144:	0009a783          	lw	a5,0(s3)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2148:	00f7f713          	and	a4,a5,15
    214c:	ff6714e3          	bne	a4,s6,2134 <freewalk+0x2bc>
      uint32 child = PTE2PA(pte);
    2150:	00a7d793          	srl	a5,a5,0xa
    2154:	00c79a93          	sll	s5,a5,0xc
      freewalk((pagetable_t)child);
    2158:	000a8793          	mv	a5,s5
  for(int i = 0; i < 512; i++){
    215c:	012a86b3          	add	a3,s5,s2
    2160:	0140006f          	j	2174 <freewalk+0x2fc>
    } else if(pte & PTE_V){
    2164:	00177713          	and	a4,a4,1
    2168:	0a071063          	bnez	a4,2208 <freewalk+0x390>
  for(int i = 0; i < 512; i++){
    216c:	004a8a93          	add	s5,s5,4 # 1004 <freerange+0xcc>
    2170:	03568e63          	beq	a3,s5,21ac <freewalk+0x334>
    pte_t pte = pagetable[i];
    2174:	000aa703          	lw	a4,0(s5)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2178:	00f77613          	and	a2,a4,15
    217c:	ff6614e3          	bne	a2,s6,2164 <freewalk+0x2ec>
      uint32 child = PTE2PA(pte);
    2180:	00a75713          	srl	a4,a4,0xa
      freewalk((pagetable_t)child);
    2184:	00c71513          	sll	a0,a4,0xc
    2188:	f6d42c23          	sw	a3,-136(s0)
    218c:	f6f42e23          	sw	a5,-132(s0)
    2190:	00000097          	auipc	ra,0x0
    2194:	ce8080e7          	jalr	-792(ra) # 1e78 <freewalk>
      pagetable[i] = 0;
    2198:	f7842683          	lw	a3,-136(s0)
    219c:	000aa023          	sw	zero,0(s5)
  for(int i = 0; i < 512; i++){
    21a0:	004a8a93          	add	s5,s5,4
    21a4:	f7c42783          	lw	a5,-132(s0)
    21a8:	fd5696e3          	bne	a3,s5,2174 <freewalk+0x2fc>
  kfree((void*)pagetable);
    21ac:	00078513          	mv	a0,a5
    21b0:	fffff097          	auipc	ra,0xfffff
    21b4:	e74080e7          	jalr	-396(ra) # 1024 <kfree>
  for(int i = 0; i < 512; i++){
    21b8:	00498993          	add	s3,s3,4
      pagetable[i] = 0;
    21bc:	fe09ae23          	sw	zero,-4(s3)
  for(int i = 0; i < 512; i++){
    21c0:	f93492e3          	bne	s1,s3,2144 <freewalk+0x2cc>
  kfree((void*)pagetable);
    21c4:	f8442503          	lw	a0,-124(s0)
    21c8:	f8042483          	lw	s1,-128(s0)
    21cc:	000a0993          	mv	s3,s4
    21d0:	fffff097          	auipc	ra,0xfffff
    21d4:	e54080e7          	jalr	-428(ra) # 1024 <kfree>
  for(int i = 0; i < 512; i++){
    21d8:	00498993          	add	s3,s3,4
      pagetable[i] = 0;
    21dc:	000a2023          	sw	zero,0(s4)
  for(int i = 0; i < 512; i++){
    21e0:	f33492e3          	bne	s1,s3,2104 <freewalk+0x28c>
  kfree((void*)pagetable);
    21e4:	f8842703          	lw	a4,-120(s0)
    21e8:	f9042503          	lw	a0,-112(s0)
    21ec:	f8c42983          	lw	s3,-116(s0)
    21f0:	f8e42823          	sw	a4,-112(s0)
    21f4:	fffff097          	auipc	ra,0xfffff
    21f8:	e30080e7          	jalr	-464(ra) # 1024 <kfree>
      pagetable[i] = 0;
    21fc:	f9042703          	lw	a4,-112(s0)
    2200:	00072023          	sw	zero,0(a4)
    2204:	eb5ff06f          	j	20b8 <freewalk+0x240>
      panic("freewalk: leaf");
    2208:	00009517          	auipc	a0,0x9
    220c:	12c50513          	add	a0,a0,300 # b334 <main+0x204>
    2210:	ffffe097          	auipc	ra,0xffffe
    2214:	4c4080e7          	jalr	1220(ra) # 6d4 <panic>
  kfree((void*)pagetable);
    2218:	f9442603          	lw	a2,-108(s0)
    221c:	fa042503          	lw	a0,-96(s0)
    2220:	fa442a83          	lw	s5,-92(s0)
    2224:	fac42a23          	sw	a2,-76(s0)
    2228:	f9c42483          	lw	s1,-100(s0)
    222c:	f9842a03          	lw	s4,-104(s0)
    2230:	fffff097          	auipc	ra,0xfffff
    2234:	df4080e7          	jalr	-524(ra) # 1024 <kfree>
      pagetable[i] = 0;
    2238:	fb442603          	lw	a2,-76(s0)
    223c:	00062023          	sw	zero,0(a2)
    2240:	e25ff06f          	j	2064 <freewalk+0x1ec>

00002244 <kvminithart>:
{
    2244:	ff010113          	add	sp,sp,-16
    2248:	00812623          	sw	s0,12(sp)
    224c:	01010413          	add	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    2250:	00022797          	auipc	a5,0x22
    2254:	db87a783          	lw	a5,-584(a5) # 24008 <kernel_pagetable>
    2258:	80000737          	lui	a4,0x80000
    225c:	00c7d793          	srl	a5,a5,0xc
    2260:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    2264:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    2268:	12000073          	sfence.vma
}
    226c:	00c12403          	lw	s0,12(sp)
    2270:	01010113          	add	sp,sp,16
    2274:	00008067          	ret

00002278 <walkaddr>:
{
    2278:	ff010113          	add	sp,sp,-16
    227c:	00812623          	sw	s0,12(sp)
    2280:	01010413          	add	s0,sp,16
  if(va >= MAXVA)
    2284:	fff00793          	li	a5,-1
    2288:	06f58663          	beq	a1,a5,22f4 <walkaddr+0x7c>
    pte_t *pte = &pagetable[PX(level, va)];
    228c:	0165d793          	srl	a5,a1,0x16
    if(*pte & PTE_V) {
    2290:	00279793          	sll	a5,a5,0x2
    2294:	00f50533          	add	a0,a0,a5
    2298:	00052783          	lw	a5,0(a0)
    229c:	0017f513          	and	a0,a5,1
    22a0:	02050a63          	beqz	a0,22d4 <walkaddr+0x5c>
  return &pagetable[PX(0, va)];
    22a4:	00c5d593          	srl	a1,a1,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    22a8:	00a7d793          	srl	a5,a5,0xa
  return &pagetable[PX(0, va)];
    22ac:	3ff5f593          	and	a1,a1,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    22b0:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    22b4:	00259593          	sll	a1,a1,0x2
    22b8:	00b787b3          	add	a5,a5,a1
  if(pte == 0)
    22bc:	02078c63          	beqz	a5,22f4 <walkaddr+0x7c>
  if((*pte & PTE_V) == 0)
    22c0:	0007a783          	lw	a5,0(a5)
  if((*pte & PTE_U) == 0)
    22c4:	01100713          	li	a4,17
    return 0;
    22c8:	00000513          	li	a0,0
  if((*pte & PTE_U) == 0)
    22cc:	0117f693          	and	a3,a5,17
    22d0:	00e68863          	beq	a3,a4,22e0 <walkaddr+0x68>
}
    22d4:	00c12403          	lw	s0,12(sp)
    22d8:	01010113          	add	sp,sp,16
    22dc:	00008067          	ret
    22e0:	00c12403          	lw	s0,12(sp)
  pa = PTE2PA(*pte);
    22e4:	00a7d793          	srl	a5,a5,0xa
    22e8:	00c79513          	sll	a0,a5,0xc
}
    22ec:	01010113          	add	sp,sp,16
    22f0:	00008067          	ret
    22f4:	00c12403          	lw	s0,12(sp)
    return 0;
    22f8:	00000513          	li	a0,0
}
    22fc:	01010113          	add	sp,sp,16
    2300:	00008067          	ret

00002304 <kvmpa>:
{
    2304:	ff010113          	add	sp,sp,-16
    2308:	00812423          	sw	s0,8(sp)
    230c:	00112623          	sw	ra,12(sp)
    2310:	01010413          	add	s0,sp,16
  if(va >= MAXVA)
    2314:	fff00613          	li	a2,-1
  pte = walk(kernel_pagetable, va, 0);
    2318:	00022717          	auipc	a4,0x22
    231c:	cf072703          	lw	a4,-784(a4) # 24008 <kernel_pagetable>
  if(va >= MAXVA)
    2320:	06c50c63          	beq	a0,a2,2398 <kvmpa+0x94>
    2324:	01451793          	sll	a5,a0,0x14
    2328:	0147d693          	srl	a3,a5,0x14
    pte_t *pte = &pagetable[PX(level, va)];
    232c:	01655793          	srl	a5,a0,0x16
    if(*pte & PTE_V) {
    2330:	00279793          	sll	a5,a5,0x2
    2334:	00f707b3          	add	a5,a4,a5
    2338:	0007a703          	lw	a4,0(a5)
    233c:	00177793          	and	a5,a4,1
    2340:	00079a63          	bnez	a5,2354 <kvmpa+0x50>
    panic("kvmpa");
    2344:	00009517          	auipc	a0,0x9
    2348:	00850513          	add	a0,a0,8 # b34c <main+0x21c>
    234c:	ffffe097          	auipc	ra,0xffffe
    2350:	388080e7          	jalr	904(ra) # 6d4 <panic>
  return &pagetable[PX(0, va)];
    2354:	00c55793          	srl	a5,a0,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    2358:	00a75713          	srl	a4,a4,0xa
  return &pagetable[PX(0, va)];
    235c:	3ff7f793          	and	a5,a5,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2360:	00c71713          	sll	a4,a4,0xc
  return &pagetable[PX(0, va)];
    2364:	00279793          	sll	a5,a5,0x2
    2368:	00f70733          	add	a4,a4,a5
  if(pte == 0)
    236c:	fc070ce3          	beqz	a4,2344 <kvmpa+0x40>
  if((*pte & PTE_V) == 0)
    2370:	00072783          	lw	a5,0(a4)
    2374:	0017f713          	and	a4,a5,1
    2378:	fc0706e3          	beqz	a4,2344 <kvmpa+0x40>
}
    237c:	00c12083          	lw	ra,12(sp)
    2380:	00812403          	lw	s0,8(sp)
  pa = PTE2PA(*pte);
    2384:	00a7d793          	srl	a5,a5,0xa
    2388:	00c79793          	sll	a5,a5,0xc
}
    238c:	00d78533          	add	a0,a5,a3
    2390:	01010113          	add	sp,sp,16
    2394:	00008067          	ret
    panic("walk");
    2398:	00009517          	auipc	a0,0x9
    239c:	fac50513          	add	a0,a0,-84 # b344 <main+0x214>
    23a0:	ffffe097          	auipc	ra,0xffffe
    23a4:	334080e7          	jalr	820(ra) # 6d4 <panic>

000023a8 <mappages>:
{
    23a8:	fd010113          	add	sp,sp,-48
  a = PGROUNDDOWN(va);
    23ac:	fffff837          	lui	a6,0xfffff
  last = PGROUNDDOWN(va + size - 1);
    23b0:	fff60793          	add	a5,a2,-1
{
    23b4:	02812423          	sw	s0,40(sp)
    23b8:	03212023          	sw	s2,32(sp)
    23bc:	01412c23          	sw	s4,24(sp)
    23c0:	01512a23          	sw	s5,20(sp)
    23c4:	01612823          	sw	s6,16(sp)
    23c8:	01712623          	sw	s7,12(sp)
    23cc:	02112623          	sw	ra,44(sp)
    23d0:	02912223          	sw	s1,36(sp)
    23d4:	01312e23          	sw	s3,28(sp)
    23d8:	01812423          	sw	s8,8(sp)
    23dc:	03010413          	add	s0,sp,48
  last = PGROUNDDOWN(va + size - 1);
    23e0:	00b787b3          	add	a5,a5,a1
  a = PGROUNDDOWN(va);
    23e4:	0105f933          	and	s2,a1,a6
{
    23e8:	00050b13          	mv	s6,a0
    23ec:	00070b93          	mv	s7,a4
  last = PGROUNDDOWN(va + size - 1);
    23f0:	0107fa33          	and	s4,a5,a6
    23f4:	41268ab3          	sub	s5,a3,s2
    23f8:	04c0006f          	j	2444 <mappages+0x9c>
  return &pagetable[PX(0, va)];
    23fc:	00c95793          	srl	a5,s2,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    2400:	00a4d493          	srl	s1,s1,0xa
  return &pagetable[PX(0, va)];
    2404:	3ff7f793          	and	a5,a5,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2408:	00c49493          	sll	s1,s1,0xc
  return &pagetable[PX(0, va)];
    240c:	00279793          	sll	a5,a5,0x2
    2410:	00f484b3          	add	s1,s1,a5
    if((pte = walk(pagetable, a, 1)) == 0)
    2414:	08048863          	beqz	s1,24a4 <mappages+0xfc>
    if(*pte & PTE_V)
    2418:	0004a783          	lw	a5,0(s1)
    241c:	0017f793          	and	a5,a5,1
    2420:	0c079063          	bnez	a5,24e0 <mappages+0x138>
    *pte = PA2PTE(pa) | perm | PTE_V;
    2424:	00c9d793          	srl	a5,s3,0xc
    2428:	00a79793          	sll	a5,a5,0xa
    242c:	0177e7b3          	or	a5,a5,s7
    2430:	0017e793          	or	a5,a5,1
    2434:	00f4a023          	sw	a5,0(s1)
    if(a == last)
    2438:	0b490063          	beq	s2,s4,24d8 <mappages+0x130>
    a += PGSIZE;
    243c:	000017b7          	lui	a5,0x1
    2440:	00f90933          	add	s2,s2,a5
    pte_t *pte = &pagetable[PX(level, va)];
    2444:	01695c13          	srl	s8,s2,0x16
    2448:	002c1c13          	sll	s8,s8,0x2
    244c:	018b0c33          	add	s8,s6,s8
    if(*pte & PTE_V) {
    2450:	000c2483          	lw	s1,0(s8)
    2454:	015909b3          	add	s3,s2,s5
    2458:	0014f793          	and	a5,s1,1
    245c:	fa0790e3          	bnez	a5,23fc <mappages+0x54>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    2460:	fffff097          	auipc	ra,0xfffff
    2464:	c4c080e7          	jalr	-948(ra) # 10ac <kalloc>
    2468:	00050493          	mv	s1,a0
    246c:	02050c63          	beqz	a0,24a4 <mappages+0xfc>
      memset(pagetable, 0, PGSIZE);
    2470:	00001637          	lui	a2,0x1
    2474:	00000593          	li	a1,0
    2478:	fffff097          	auipc	ra,0xfffff
    247c:	20c080e7          	jalr	524(ra) # 1684 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    2480:	00c4d713          	srl	a4,s1,0xc
  return &pagetable[PX(0, va)];
    2484:	00c95793          	srl	a5,s2,0xc
      *pte = PA2PTE(pagetable) | PTE_V;
    2488:	00a71713          	sll	a4,a4,0xa
  return &pagetable[PX(0, va)];
    248c:	3ff7f793          	and	a5,a5,1023
      *pte = PA2PTE(pagetable) | PTE_V;
    2490:	00176713          	or	a4,a4,1
  return &pagetable[PX(0, va)];
    2494:	00279793          	sll	a5,a5,0x2
      *pte = PA2PTE(pagetable) | PTE_V;
    2498:	00ec2023          	sw	a4,0(s8)
  return &pagetable[PX(0, va)];
    249c:	00f484b3          	add	s1,s1,a5
    24a0:	f79ff06f          	j	2418 <mappages+0x70>
      return -1;
    24a4:	fff00513          	li	a0,-1
}
    24a8:	02c12083          	lw	ra,44(sp)
    24ac:	02812403          	lw	s0,40(sp)
    24b0:	02412483          	lw	s1,36(sp)
    24b4:	02012903          	lw	s2,32(sp)
    24b8:	01c12983          	lw	s3,28(sp)
    24bc:	01812a03          	lw	s4,24(sp)
    24c0:	01412a83          	lw	s5,20(sp)
    24c4:	01012b03          	lw	s6,16(sp)
    24c8:	00c12b83          	lw	s7,12(sp)
    24cc:	00812c03          	lw	s8,8(sp)
    24d0:	03010113          	add	sp,sp,48
    24d4:	00008067          	ret
  return 0;
    24d8:	00000513          	li	a0,0
    24dc:	fcdff06f          	j	24a8 <mappages+0x100>
      panic("remap");
    24e0:	00009517          	auipc	a0,0x9
    24e4:	dfc50513          	add	a0,a0,-516 # b2dc <main+0x1ac>
    24e8:	ffffe097          	auipc	ra,0xffffe
    24ec:	1ec080e7          	jalr	492(ra) # 6d4 <panic>

000024f0 <kvmmap>:
{
    24f0:	ff010113          	add	sp,sp,-16
    24f4:	00812423          	sw	s0,8(sp)
    24f8:	00112623          	sw	ra,12(sp)
    24fc:	01010413          	add	s0,sp,16
    2500:	00068713          	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    2504:	00058693          	mv	a3,a1
    2508:	00050593          	mv	a1,a0
    250c:	00022517          	auipc	a0,0x22
    2510:	afc52503          	lw	a0,-1284(a0) # 24008 <kernel_pagetable>
    2514:	00000097          	auipc	ra,0x0
    2518:	e94080e7          	jalr	-364(ra) # 23a8 <mappages>
    251c:	00051a63          	bnez	a0,2530 <kvmmap+0x40>
}
    2520:	00c12083          	lw	ra,12(sp)
    2524:	00812403          	lw	s0,8(sp)
    2528:	01010113          	add	sp,sp,16
    252c:	00008067          	ret
    panic("kvmmap");
    2530:	00009517          	auipc	a0,0x9
    2534:	e2450513          	add	a0,a0,-476 # b354 <main+0x224>
    2538:	ffffe097          	auipc	ra,0xffffe
    253c:	19c080e7          	jalr	412(ra) # 6d4 <panic>

00002540 <kvminit>:
{
    2540:	ff010113          	add	sp,sp,-16
    2544:	00812423          	sw	s0,8(sp)
    2548:	00912223          	sw	s1,4(sp)
    254c:	00112623          	sw	ra,12(sp)
    2550:	01212023          	sw	s2,0(sp)
    2554:	01010413          	add	s0,sp,16
  kernel_pagetable = (pagetable_t) kalloc();
    2558:	fffff097          	auipc	ra,0xfffff
    255c:	b54080e7          	jalr	-1196(ra) # 10ac <kalloc>
    2560:	00022497          	auipc	s1,0x22
    2564:	aa848493          	add	s1,s1,-1368 # 24008 <kernel_pagetable>
    2568:	00a4a023          	sw	a0,0(s1)
  if (kernel_pagetable == 0) { 
    256c:	0e050e63          	beqz	a0,2668 <kvminit+0x128>
  memset(kernel_pagetable, 0, PGSIZE);
    2570:	00001637          	lui	a2,0x1
    2574:	00000593          	li	a1,0
    2578:	fffff097          	auipc	ra,0xfffff
    257c:	10c080e7          	jalr	268(ra) # 1684 <memset>
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    2580:	0004a503          	lw	a0,0(s1)
    2584:	00600713          	li	a4,6
    2588:	ff0006b7          	lui	a3,0xff000
    258c:	00001637          	lui	a2,0x1
    2590:	ff0005b7          	lui	a1,0xff000
    2594:	00000097          	auipc	ra,0x0
    2598:	e14080e7          	jalr	-492(ra) # 23a8 <mappages>
    259c:	0e051263          	bnez	a0,2680 <kvminit+0x140>
    25a0:	0004a503          	lw	a0,0(s1)
    25a4:	00600713          	li	a4,6
    25a8:	f80006b7          	lui	a3,0xf8000
    25ac:	00001637          	lui	a2,0x1
    25b0:	f80005b7          	lui	a1,0xf8000
    25b4:	00000097          	auipc	ra,0x0
    25b8:	df4080e7          	jalr	-524(ra) # 23a8 <mappages>
    25bc:	0c051263          	bnez	a0,2680 <kvminit+0x140>
    25c0:	0004a503          	lw	a0,0(s1)
    25c4:	00600713          	li	a4,6
    25c8:	f00006b7          	lui	a3,0xf0000
    25cc:	00010637          	lui	a2,0x10
    25d0:	f00005b7          	lui	a1,0xf0000
    25d4:	00000097          	auipc	ra,0x0
    25d8:	dd4080e7          	jalr	-556(ra) # 23a8 <mappages>
    25dc:	0a051263          	bnez	a0,2680 <kvminit+0x140>
    25e0:	0004a503          	lw	a0,0(s1)
  kvmmap(KERNBASE, KERNBASE, (uint32)etext-KERNBASE, PTE_R | PTE_X);
    25e4:	0000a917          	auipc	s2,0xa
    25e8:	a1c90913          	add	s2,s2,-1508 # c000 <initcode>
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    25ec:	00a00713          	li	a4,10
    25f0:	00000693          	li	a3,0
    25f4:	00090613          	mv	a2,s2
    25f8:	00000593          	li	a1,0
    25fc:	00000097          	auipc	ra,0x0
    2600:	dac080e7          	jalr	-596(ra) # 23a8 <mappages>
    2604:	06051e63          	bnez	a0,2680 <kvminit+0x140>
    2608:	0004a503          	lw	a0,0(s1)
    260c:	02000637          	lui	a2,0x2000
    2610:	00600713          	li	a4,6
    2614:	00090693          	mv	a3,s2
    2618:	41260633          	sub	a2,a2,s2
    261c:	00090593          	mv	a1,s2
    2620:	00000097          	auipc	ra,0x0
    2624:	d88080e7          	jalr	-632(ra) # 23a8 <mappages>
    2628:	04051c63          	bnez	a0,2680 <kvminit+0x140>
    262c:	0004a503          	lw	a0,0(s1)
    2630:	00a00713          	li	a4,10
    2634:	00009697          	auipc	a3,0x9
    2638:	9cc68693          	add	a3,a3,-1588 # b000 <trampoline>
    263c:	00001637          	lui	a2,0x1
    2640:	fffff5b7          	lui	a1,0xfffff
    2644:	00000097          	auipc	ra,0x0
    2648:	d64080e7          	jalr	-668(ra) # 23a8 <mappages>
    264c:	02051a63          	bnez	a0,2680 <kvminit+0x140>
}
    2650:	00c12083          	lw	ra,12(sp)
    2654:	00812403          	lw	s0,8(sp)
    2658:	00412483          	lw	s1,4(sp)
    265c:	00012903          	lw	s2,0(sp)
    2660:	01010113          	add	sp,sp,16
    2664:	00008067          	ret
    printf("kalloc failed\n");
    2668:	00009517          	auipc	a0,0x9
    266c:	cf450513          	add	a0,a0,-780 # b35c <main+0x22c>
    2670:	ffffe097          	auipc	ra,0xffffe
    2674:	0c0080e7          	jalr	192(ra) # 730 <printf>
  memset(kernel_pagetable, 0, PGSIZE);
    2678:	0004a503          	lw	a0,0(s1)
    267c:	ef5ff06f          	j	2570 <kvminit+0x30>
    panic("kvmmap");
    2680:	00009517          	auipc	a0,0x9
    2684:	cd450513          	add	a0,a0,-812 # b354 <main+0x224>
    2688:	ffffe097          	auipc	ra,0xffffe
    268c:	04c080e7          	jalr	76(ra) # 6d4 <panic>

00002690 <uvmunmap>:
{
    2690:	fe010113          	add	sp,sp,-32
    2694:	00812c23          	sw	s0,24(sp)
    2698:	00912a23          	sw	s1,20(sp)
    269c:	01312623          	sw	s3,12(sp)
    26a0:	01412423          	sw	s4,8(sp)
    26a4:	01512223          	sw	s5,4(sp)
    26a8:	01612023          	sw	s6,0(sp)
    26ac:	00112e23          	sw	ra,28(sp)
    26b0:	01212823          	sw	s2,16(sp)
    26b4:	02010413          	add	s0,sp,32
  last = PGROUNDDOWN(va + size - 1);
    26b8:	fff60793          	add	a5,a2,-1 # fff <freerange+0xc7>
  a = PGROUNDDOWN(va);
    26bc:	fffff737          	lui	a4,0xfffff
  last = PGROUNDDOWN(va + size - 1);
    26c0:	00b787b3          	add	a5,a5,a1
{
    26c4:	00050b13          	mv	s6,a0
  a = PGROUNDDOWN(va);
    26c8:	00e5f4b3          	and	s1,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    26cc:	00e7fab3          	and	s5,a5,a4
    if(PTE_FLAGS(*pte) == PTE_V)
    26d0:	00100993          	li	s3,1
    a += PGSIZE;
    26d4:	00001a37          	lui	s4,0x1
    26d8:	02069c63          	bnez	a3,2710 <uvmunmap+0x80>
    if(PTE_FLAGS(*pte) == PTE_V)
    26dc:	00100693          	li	a3,1
    a += PGSIZE;
    26e0:	000015b7          	lui	a1,0x1
    pte_t *pte = &pagetable[PX(level, va)];
    26e4:	0164d793          	srl	a5,s1,0x16
    if(*pte & PTE_V) {
    26e8:	00279793          	sll	a5,a5,0x2
    26ec:	00fb07b3          	add	a5,s6,a5
    26f0:	0007a783          	lw	a5,0(a5) # 1000 <freerange+0xc8>
    26f4:	0017f713          	and	a4,a5,1
    26f8:	0a071063          	bnez	a4,2798 <uvmunmap+0x108>
      panic("uvmunmap: walk");
    26fc:	00009517          	auipc	a0,0x9
    2700:	be850513          	add	a0,a0,-1048 # b2e4 <main+0x1b4>
    2704:	ffffe097          	auipc	ra,0xffffe
    2708:	fd0080e7          	jalr	-48(ra) # 6d4 <panic>
    a += PGSIZE;
    270c:	014484b3          	add	s1,s1,s4
    pte_t *pte = &pagetable[PX(level, va)];
    2710:	0164d793          	srl	a5,s1,0x16
    if(*pte & PTE_V) {
    2714:	00279793          	sll	a5,a5,0x2
    2718:	00fb07b3          	add	a5,s6,a5
    271c:	0007a903          	lw	s2,0(a5)
    2720:	00197793          	and	a5,s2,1
    2724:	fc078ce3          	beqz	a5,26fc <uvmunmap+0x6c>
  return &pagetable[PX(0, va)];
    2728:	00c4d793          	srl	a5,s1,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    272c:	00a95913          	srl	s2,s2,0xa
  return &pagetable[PX(0, va)];
    2730:	3ff7f793          	and	a5,a5,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2734:	00c91913          	sll	s2,s2,0xc
  return &pagetable[PX(0, va)];
    2738:	00279793          	sll	a5,a5,0x2
    273c:	00f90933          	add	s2,s2,a5
    if((pte = walk(pagetable, a, 0)) == 0)
    2740:	fa090ee3          	beqz	s2,26fc <uvmunmap+0x6c>
    if((*pte & PTE_V) == 0){
    2744:	00092603          	lw	a2,0(s2)
    2748:	00167793          	and	a5,a2,1
    274c:	08078663          	beqz	a5,27d8 <uvmunmap+0x148>
    if(PTE_FLAGS(*pte) == PTE_V)
    2750:	3ff67793          	and	a5,a2,1023
    2754:	0b378463          	beq	a5,s3,27fc <uvmunmap+0x16c>
      pa = PTE2PA(*pte);
    2758:	00a65613          	srl	a2,a2,0xa
      kfree((void*)pa);
    275c:	00c61513          	sll	a0,a2,0xc
    2760:	fffff097          	auipc	ra,0xfffff
    2764:	8c4080e7          	jalr	-1852(ra) # 1024 <kfree>
    *pte = 0;
    2768:	00092023          	sw	zero,0(s2)
    if(a == last)
    276c:	fb5490e3          	bne	s1,s5,270c <uvmunmap+0x7c>
}
    2770:	01c12083          	lw	ra,28(sp)
    2774:	01812403          	lw	s0,24(sp)
    2778:	01412483          	lw	s1,20(sp)
    277c:	01012903          	lw	s2,16(sp)
    2780:	00c12983          	lw	s3,12(sp)
    2784:	00812a03          	lw	s4,8(sp)
    2788:	00412a83          	lw	s5,4(sp)
    278c:	00012b03          	lw	s6,0(sp)
    2790:	02010113          	add	sp,sp,32
    2794:	00008067          	ret
  return &pagetable[PX(0, va)];
    2798:	00c4d713          	srl	a4,s1,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    279c:	00a7d793          	srl	a5,a5,0xa
  return &pagetable[PX(0, va)];
    27a0:	3ff77713          	and	a4,a4,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    27a4:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    27a8:	00271713          	sll	a4,a4,0x2
    27ac:	00e787b3          	add	a5,a5,a4
    if((pte = walk(pagetable, a, 0)) == 0)
    27b0:	f40786e3          	beqz	a5,26fc <uvmunmap+0x6c>
    if((*pte & PTE_V) == 0){
    27b4:	0007a603          	lw	a2,0(a5)
    27b8:	00167713          	and	a4,a2,1
    27bc:	00070e63          	beqz	a4,27d8 <uvmunmap+0x148>
    if(PTE_FLAGS(*pte) == PTE_V)
    27c0:	3ff67613          	and	a2,a2,1023
    27c4:	02d60c63          	beq	a2,a3,27fc <uvmunmap+0x16c>
    *pte = 0;
    27c8:	0007a023          	sw	zero,0(a5)
    if(a == last)
    27cc:	fa9a82e3          	beq	s5,s1,2770 <uvmunmap+0xe0>
    a += PGSIZE;
    27d0:	00b484b3          	add	s1,s1,a1
  for(;;){
    27d4:	f11ff06f          	j	26e4 <uvmunmap+0x54>
      printf("va=%p pte=%p\n", a, *pte);
    27d8:	00009517          	auipc	a0,0x9
    27dc:	b1c50513          	add	a0,a0,-1252 # b2f4 <main+0x1c4>
    27e0:	00048593          	mv	a1,s1
    27e4:	ffffe097          	auipc	ra,0xffffe
    27e8:	f4c080e7          	jalr	-180(ra) # 730 <printf>
      panic("uvmunmap: not mapped");
    27ec:	00009517          	auipc	a0,0x9
    27f0:	b1850513          	add	a0,a0,-1256 # b304 <main+0x1d4>
    27f4:	ffffe097          	auipc	ra,0xffffe
    27f8:	ee0080e7          	jalr	-288(ra) # 6d4 <panic>
      panic("uvmunmap: not a leaf");
    27fc:	00009517          	auipc	a0,0x9
    2800:	b2050513          	add	a0,a0,-1248 # b31c <main+0x1ec>
    2804:	ffffe097          	auipc	ra,0xffffe
    2808:	ed0080e7          	jalr	-304(ra) # 6d4 <panic>

0000280c <uvmcreate>:
{
    280c:	ff010113          	add	sp,sp,-16
    2810:	00812423          	sw	s0,8(sp)
    2814:	00112623          	sw	ra,12(sp)
    2818:	00912223          	sw	s1,4(sp)
    281c:	01010413          	add	s0,sp,16
  pagetable = (pagetable_t) kalloc();
    2820:	fffff097          	auipc	ra,0xfffff
    2824:	88c080e7          	jalr	-1908(ra) # 10ac <kalloc>
  if(pagetable == 0)
    2828:	02050863          	beqz	a0,2858 <uvmcreate+0x4c>
  memset(pagetable, 0, PGSIZE);
    282c:	00001637          	lui	a2,0x1
    2830:	00000593          	li	a1,0
    2834:	00050493          	mv	s1,a0
    2838:	fffff097          	auipc	ra,0xfffff
    283c:	e4c080e7          	jalr	-436(ra) # 1684 <memset>
}
    2840:	00c12083          	lw	ra,12(sp)
    2844:	00812403          	lw	s0,8(sp)
    2848:	00048513          	mv	a0,s1
    284c:	00412483          	lw	s1,4(sp)
    2850:	01010113          	add	sp,sp,16
    2854:	00008067          	ret
    panic("uvmcreate: out of memory");
    2858:	00009517          	auipc	a0,0x9
    285c:	b1450513          	add	a0,a0,-1260 # b36c <main+0x23c>
    2860:	ffffe097          	auipc	ra,0xffffe
    2864:	e74080e7          	jalr	-396(ra) # 6d4 <panic>

00002868 <uvminit>:
{
    2868:	fe010113          	add	sp,sp,-32
    286c:	00812c23          	sw	s0,24(sp)
    2870:	00112e23          	sw	ra,28(sp)
    2874:	00912a23          	sw	s1,20(sp)
    2878:	01212823          	sw	s2,16(sp)
    287c:	01312623          	sw	s3,12(sp)
    2880:	01412423          	sw	s4,8(sp)
    2884:	02010413          	add	s0,sp,32
  if(sz >= PGSIZE)
    2888:	000017b7          	lui	a5,0x1
    288c:	06f67a63          	bgeu	a2,a5,2900 <uvminit+0x98>
    2890:	00060493          	mv	s1,a2
    2894:	00058993          	mv	s3,a1
  mem = kalloc();
    2898:	00050a13          	mv	s4,a0
    289c:	fffff097          	auipc	ra,0xfffff
    28a0:	810080e7          	jalr	-2032(ra) # 10ac <kalloc>
  memset(mem, 0, PGSIZE);
    28a4:	00001637          	lui	a2,0x1
    28a8:	00000593          	li	a1,0
  mem = kalloc();
    28ac:	00050913          	mv	s2,a0
  memset(mem, 0, PGSIZE);
    28b0:	fffff097          	auipc	ra,0xfffff
    28b4:	dd4080e7          	jalr	-556(ra) # 1684 <memset>
  mappages(pagetable, 0, PGSIZE, (uint32)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    28b8:	00090613          	mv	a2,s2
    28bc:	00000593          	li	a1,0
    28c0:	000a0513          	mv	a0,s4
    28c4:	01e00693          	li	a3,30
    28c8:	fffff097          	auipc	ra,0xfffff
    28cc:	348080e7          	jalr	840(ra) # 1c10 <mappages.constprop.0>
}
    28d0:	01812403          	lw	s0,24(sp)
    28d4:	01c12083          	lw	ra,28(sp)
    28d8:	00812a03          	lw	s4,8(sp)
  memmove(mem, src, sz);
    28dc:	00048613          	mv	a2,s1
    28e0:	00098593          	mv	a1,s3
}
    28e4:	01412483          	lw	s1,20(sp)
    28e8:	00c12983          	lw	s3,12(sp)
  memmove(mem, src, sz);
    28ec:	00090513          	mv	a0,s2
}
    28f0:	01012903          	lw	s2,16(sp)
    28f4:	02010113          	add	sp,sp,32
  memmove(mem, src, sz);
    28f8:	fffff317          	auipc	t1,0xfffff
    28fc:	f0c30067          	jr	-244(t1) # 1804 <memmove>
    panic("inituvm: more than a page");
    2900:	00009517          	auipc	a0,0x9
    2904:	a8850513          	add	a0,a0,-1400 # b388 <main+0x258>
    2908:	ffffe097          	auipc	ra,0xffffe
    290c:	dcc080e7          	jalr	-564(ra) # 6d4 <panic>

00002910 <uvmalloc>:
  if(newsz < oldsz)
    2910:	0cb66263          	bltu	a2,a1,29d4 <uvmalloc+0xc4>
  oldsz = PGROUNDUP(oldsz);
    2914:	000017b7          	lui	a5,0x1
{
    2918:	fe010113          	add	sp,sp,-32
  oldsz = PGROUNDUP(oldsz);
    291c:	fff78793          	add	a5,a5,-1 # fff <freerange+0xc7>
{
    2920:	00812c23          	sw	s0,24(sp)
    2924:	01212823          	sw	s2,16(sp)
    2928:	01312623          	sw	s3,12(sp)
    292c:	01412423          	sw	s4,8(sp)
    2930:	01512223          	sw	s5,4(sp)
  oldsz = PGROUNDUP(oldsz);
    2934:	00f585b3          	add	a1,a1,a5
{
    2938:	00112e23          	sw	ra,28(sp)
    293c:	00912a23          	sw	s1,20(sp)
    2940:	02010413          	add	s0,sp,32
  oldsz = PGROUNDUP(oldsz);
    2944:	fffff7b7          	lui	a5,0xfffff
    2948:	00f5f9b3          	and	s3,a1,a5
{
    294c:	00060a93          	mv	s5,a2
    2950:	00050a13          	mv	s4,a0
  oldsz = PGROUNDUP(oldsz);
    2954:	00098913          	mv	s2,s3
  for(; a < newsz; a += PGSIZE){
    2958:	02c9ec63          	bltu	s3,a2,2990 <uvmalloc+0x80>
    295c:	0800006f          	j	29dc <uvmalloc+0xcc>
    memset(mem, 0, PGSIZE);
    2960:	fffff097          	auipc	ra,0xfffff
    2964:	d24080e7          	jalr	-732(ra) # 1684 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint32)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    2968:	00090593          	mv	a1,s2
    296c:	01e00693          	li	a3,30
    2970:	00048613          	mv	a2,s1
    2974:	000a0513          	mv	a0,s4
    2978:	fffff097          	auipc	ra,0xfffff
    297c:	298080e7          	jalr	664(ra) # 1c10 <mappages.constprop.0>
    2980:	08051263          	bnez	a0,2a04 <uvmalloc+0xf4>
  for(; a < newsz; a += PGSIZE){
    2984:	000017b7          	lui	a5,0x1
    2988:	00f90933          	add	s2,s2,a5
    298c:	05597863          	bgeu	s2,s5,29dc <uvmalloc+0xcc>
    mem = kalloc();
    2990:	ffffe097          	auipc	ra,0xffffe
    2994:	71c080e7          	jalr	1820(ra) # 10ac <kalloc>
    memset(mem, 0, PGSIZE);
    2998:	00001637          	lui	a2,0x1
    299c:	00000593          	li	a1,0
    mem = kalloc();
    29a0:	00050493          	mv	s1,a0
    if(mem == 0){
    29a4:	fa051ee3          	bnez	a0,2960 <uvmalloc+0x50>
  if(newsz >= oldsz)
    29a8:	0329f263          	bgeu	s3,s2,29cc <uvmalloc+0xbc>
  uint32 newup = PGROUNDUP(newsz);
    29ac:	000017b7          	lui	a5,0x1
    29b0:	fff78793          	add	a5,a5,-1 # fff <freerange+0xc7>
    29b4:	fffff737          	lui	a4,0xfffff
    29b8:	00f985b3          	add	a1,s3,a5
  if(newup < PGROUNDUP(oldsz))
    29bc:	00f907b3          	add	a5,s2,a5
  uint32 newup = PGROUNDUP(newsz);
    29c0:	00e5f5b3          	and	a1,a1,a4
  if(newup < PGROUNDUP(oldsz))
    29c4:	00e7f7b3          	and	a5,a5,a4
    29c8:	04f5e663          	bltu	a1,a5,2a14 <uvmalloc+0x104>
      return 0;
    29cc:	00000513          	li	a0,0
    29d0:	0100006f          	j	29e0 <uvmalloc+0xd0>
    29d4:	00058513          	mv	a0,a1
}
    29d8:	00008067          	ret
      return 0;
    29dc:	000a8513          	mv	a0,s5
}
    29e0:	01c12083          	lw	ra,28(sp)
    29e4:	01812403          	lw	s0,24(sp)
    29e8:	01412483          	lw	s1,20(sp)
    29ec:	01012903          	lw	s2,16(sp)
    29f0:	00c12983          	lw	s3,12(sp)
    29f4:	00812a03          	lw	s4,8(sp)
    29f8:	00412a83          	lw	s5,4(sp)
    29fc:	02010113          	add	sp,sp,32
    2a00:	00008067          	ret
      kfree(mem);
    2a04:	00048513          	mv	a0,s1
    2a08:	ffffe097          	auipc	ra,0xffffe
    2a0c:	61c080e7          	jalr	1564(ra) # 1024 <kfree>
    2a10:	f99ff06f          	j	29a8 <uvmalloc+0x98>
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    2a14:	000a0513          	mv	a0,s4
    2a18:	40b90633          	sub	a2,s2,a1
    2a1c:	fffff097          	auipc	ra,0xfffff
    2a20:	340080e7          	jalr	832(ra) # 1d5c <uvmunmap.constprop.0>
      return 0;
    2a24:	00000513          	li	a0,0
    2a28:	fb9ff06f          	j	29e0 <uvmalloc+0xd0>

00002a2c <uvmdealloc>:
  if(newsz >= oldsz)
    2a2c:	06b67e63          	bgeu	a2,a1,2aa8 <uvmdealloc+0x7c>
  uint32 newup = PGROUNDUP(newsz);
    2a30:	000017b7          	lui	a5,0x1
{
    2a34:	ff010113          	add	sp,sp,-16
  uint32 newup = PGROUNDUP(newsz);
    2a38:	fff78793          	add	a5,a5,-1 # fff <freerange+0xc7>
{
    2a3c:	00812423          	sw	s0,8(sp)
    2a40:	00912223          	sw	s1,4(sp)
  uint32 newup = PGROUNDUP(newsz);
    2a44:	fffff6b7          	lui	a3,0xfffff
    2a48:	00f60733          	add	a4,a2,a5
{
    2a4c:	00112623          	sw	ra,12(sp)
    2a50:	01010413          	add	s0,sp,16
  if(newup < PGROUNDUP(oldsz))
    2a54:	00f587b3          	add	a5,a1,a5
  uint32 newup = PGROUNDUP(newsz);
    2a58:	00d77733          	and	a4,a4,a3
  if(newup < PGROUNDUP(oldsz))
    2a5c:	00d7f7b3          	and	a5,a5,a3
    2a60:	00060493          	mv	s1,a2
    2a64:	00f76e63          	bltu	a4,a5,2a80 <uvmdealloc+0x54>
}
    2a68:	00c12083          	lw	ra,12(sp)
    2a6c:	00812403          	lw	s0,8(sp)
    2a70:	00048513          	mv	a0,s1
    2a74:	00412483          	lw	s1,4(sp)
    2a78:	01010113          	add	sp,sp,16
    2a7c:	00008067          	ret
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    2a80:	40e58633          	sub	a2,a1,a4
    2a84:	00070593          	mv	a1,a4
    2a88:	fffff097          	auipc	ra,0xfffff
    2a8c:	2d4080e7          	jalr	724(ra) # 1d5c <uvmunmap.constprop.0>
}
    2a90:	00c12083          	lw	ra,12(sp)
    2a94:	00812403          	lw	s0,8(sp)
    2a98:	00048513          	mv	a0,s1
    2a9c:	00412483          	lw	s1,4(sp)
    2aa0:	01010113          	add	sp,sp,16
    2aa4:	00008067          	ret
    2aa8:	00058513          	mv	a0,a1
    2aac:	00008067          	ret

00002ab0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint32 sz)
{
    2ab0:	fe010113          	add	sp,sp,-32
    2ab4:	00812c23          	sw	s0,24(sp)
    2ab8:	00912a23          	sw	s1,20(sp)
    2abc:	01212823          	sw	s2,16(sp)
    2ac0:	01312623          	sw	s3,12(sp)
    2ac4:	01412423          	sw	s4,8(sp)
    2ac8:	00112e23          	sw	ra,28(sp)
    2acc:	02010413          	add	s0,sp,32
    2ad0:	00001937          	lui	s2,0x1
    2ad4:	00050a13          	mv	s4,a0
    2ad8:	00058613          	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    2adc:	00000593          	li	a1,0
    2ae0:	80090913          	add	s2,s2,-2048 # 800 <printf+0xd0>
    2ae4:	fffff097          	auipc	ra,0xfffff
    2ae8:	278080e7          	jalr	632(ra) # 1d5c <uvmunmap.constprop.0>
  for(int i = 0; i < 512; i++){
    2aec:	000a0493          	mv	s1,s4
    2af0:	012a0933          	add	s2,s4,s2
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2af4:	00100993          	li	s3,1
    2af8:	0140006f          	j	2b0c <uvmfree+0x5c>
    } else if(pte & PTE_V){
    2afc:	00157513          	and	a0,a0,1
    2b00:	04051e63          	bnez	a0,2b5c <uvmfree+0xac>
  for(int i = 0; i < 512; i++){
    2b04:	00448493          	add	s1,s1,4
    2b08:	03248663          	beq	s1,s2,2b34 <uvmfree+0x84>
    pte_t pte = pagetable[i];
    2b0c:	0004a503          	lw	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    2b10:	00f57793          	and	a5,a0,15
    2b14:	ff3794e3          	bne	a5,s3,2afc <uvmfree+0x4c>
      uint32 child = PTE2PA(pte);
    2b18:	00a55513          	srl	a0,a0,0xa
      freewalk((pagetable_t)child);
    2b1c:	00c51513          	sll	a0,a0,0xc
    2b20:	fffff097          	auipc	ra,0xfffff
    2b24:	358080e7          	jalr	856(ra) # 1e78 <freewalk>
  for(int i = 0; i < 512; i++){
    2b28:	00448493          	add	s1,s1,4
      pagetable[i] = 0;
    2b2c:	fe04ae23          	sw	zero,-4(s1)
  for(int i = 0; i < 512; i++){
    2b30:	fd249ee3          	bne	s1,s2,2b0c <uvmfree+0x5c>
  freewalk(pagetable);
}
    2b34:	01812403          	lw	s0,24(sp)
    2b38:	01c12083          	lw	ra,28(sp)
    2b3c:	01412483          	lw	s1,20(sp)
    2b40:	01012903          	lw	s2,16(sp)
    2b44:	00c12983          	lw	s3,12(sp)
  kfree((void*)pagetable);
    2b48:	000a0513          	mv	a0,s4
}
    2b4c:	00812a03          	lw	s4,8(sp)
    2b50:	02010113          	add	sp,sp,32
  kfree((void*)pagetable);
    2b54:	ffffe317          	auipc	t1,0xffffe
    2b58:	4d030067          	jr	1232(t1) # 1024 <kfree>
      panic("freewalk: leaf");
    2b5c:	00008517          	auipc	a0,0x8
    2b60:	7d850513          	add	a0,a0,2008 # b334 <main+0x204>
    2b64:	ffffe097          	auipc	ra,0xffffe
    2b68:	b70080e7          	jalr	-1168(ra) # 6d4 <panic>

00002b6c <uvmcopy>:
  pte_t *pte;
  uint32 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    2b6c:	12060e63          	beqz	a2,2ca8 <uvmcopy+0x13c>
{
    2b70:	fd010113          	add	sp,sp,-48
    2b74:	02812423          	sw	s0,40(sp)
    2b78:	02912223          	sw	s1,36(sp)
    2b7c:	03212023          	sw	s2,32(sp)
    2b80:	01312e23          	sw	s3,28(sp)
    2b84:	01412c23          	sw	s4,24(sp)
    2b88:	02112623          	sw	ra,44(sp)
    2b8c:	01512a23          	sw	s5,20(sp)
    2b90:	01612823          	sw	s6,16(sp)
    2b94:	01712623          	sw	s7,12(sp)
    2b98:	03010413          	add	s0,sp,48
    2b9c:	00060913          	mv	s2,a2
    2ba0:	00050493          	mv	s1,a0
    2ba4:	00058993          	mv	s3,a1
    2ba8:	00000a13          	li	s4,0
    pte_t *pte = &pagetable[PX(level, va)];
    2bac:	016a5793          	srl	a5,s4,0x16
    if(*pte & PTE_V) {
    2bb0:	00279793          	sll	a5,a5,0x2
    2bb4:	00f487b3          	add	a5,s1,a5
    2bb8:	0007a783          	lw	a5,0(a5)
    2bbc:	0017f713          	and	a4,a5,1
    2bc0:	00071a63          	bnez	a4,2bd4 <uvmcopy+0x68>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    2bc4:	00008517          	auipc	a0,0x8
    2bc8:	7e050513          	add	a0,a0,2016 # b3a4 <main+0x274>
    2bcc:	ffffe097          	auipc	ra,0xffffe
    2bd0:	b08080e7          	jalr	-1272(ra) # 6d4 <panic>
  return &pagetable[PX(0, va)];
    2bd4:	00ca5713          	srl	a4,s4,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    2bd8:	00a7d793          	srl	a5,a5,0xa
  return &pagetable[PX(0, va)];
    2bdc:	3ff77713          	and	a4,a4,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2be0:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    2be4:	00271713          	sll	a4,a4,0x2
    2be8:	00e787b3          	add	a5,a5,a4
    if((pte = walk(old, i, 0)) == 0)
    2bec:	fc078ce3          	beqz	a5,2bc4 <uvmcopy+0x58>
    if((*pte & PTE_V) == 0)
    2bf0:	0007a683          	lw	a3,0(a5)
    2bf4:	0016f793          	and	a5,a3,1
    2bf8:	0a078c63          	beqz	a5,2cb0 <uvmcopy+0x144>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    2bfc:	00a6d593          	srl	a1,a3,0xa
    2c00:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    2c04:	3ff6fa93          	and	s5,a3,1023
    if((mem = kalloc()) == 0)
    2c08:	ffffe097          	auipc	ra,0xffffe
    2c0c:	4a4080e7          	jalr	1188(ra) # 10ac <kalloc>
    2c10:	00050b13          	mv	s6,a0
    2c14:	04050863          	beqz	a0,2c64 <uvmcopy+0xf8>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    2c18:	00001637          	lui	a2,0x1
    2c1c:	000b8593          	mv	a1,s7
    2c20:	fffff097          	auipc	ra,0xfffff
    2c24:	be4080e7          	jalr	-1052(ra) # 1804 <memmove>
    if(mappages(new, i, PGSIZE, (uint32)mem, flags) != 0){
    2c28:	000a8693          	mv	a3,s5
    2c2c:	000b0613          	mv	a2,s6
    2c30:	000a0593          	mv	a1,s4
    2c34:	00098513          	mv	a0,s3
    2c38:	fffff097          	auipc	ra,0xfffff
    2c3c:	fd8080e7          	jalr	-40(ra) # 1c10 <mappages.constprop.0>
    2c40:	00051c63          	bnez	a0,2c58 <uvmcopy+0xec>
  for(i = 0; i < sz; i += PGSIZE){
    2c44:	000017b7          	lui	a5,0x1
    2c48:	00fa0a33          	add	s4,s4,a5
    2c4c:	f72a60e3          	bltu	s4,s2,2bac <uvmcopy+0x40>
      kfree(mem);
      goto err;
    }
  }
  return 0;
    2c50:	00000513          	li	a0,0
    2c54:	0280006f          	j	2c7c <uvmcopy+0x110>
      kfree(mem);
    2c58:	000b0513          	mv	a0,s6
    2c5c:	ffffe097          	auipc	ra,0xffffe
    2c60:	3c8080e7          	jalr	968(ra) # 1024 <kfree>

 err:
  uvmunmap(new, 0, i, 1);
    2c64:	00098513          	mv	a0,s3
    2c68:	000a0613          	mv	a2,s4
    2c6c:	00000593          	li	a1,0
    2c70:	fffff097          	auipc	ra,0xfffff
    2c74:	0ec080e7          	jalr	236(ra) # 1d5c <uvmunmap.constprop.0>
  return -1;
    2c78:	fff00513          	li	a0,-1
}
    2c7c:	02c12083          	lw	ra,44(sp)
    2c80:	02812403          	lw	s0,40(sp)
    2c84:	02412483          	lw	s1,36(sp)
    2c88:	02012903          	lw	s2,32(sp)
    2c8c:	01c12983          	lw	s3,28(sp)
    2c90:	01812a03          	lw	s4,24(sp)
    2c94:	01412a83          	lw	s5,20(sp)
    2c98:	01012b03          	lw	s6,16(sp)
    2c9c:	00c12b83          	lw	s7,12(sp)
    2ca0:	03010113          	add	sp,sp,48
    2ca4:	00008067          	ret
  return 0;
    2ca8:	00000513          	li	a0,0
}
    2cac:	00008067          	ret
      panic("uvmcopy: page not present");
    2cb0:	00008517          	auipc	a0,0x8
    2cb4:	71050513          	add	a0,a0,1808 # b3c0 <main+0x290>
    2cb8:	ffffe097          	auipc	ra,0xffffe
    2cbc:	a1c080e7          	jalr	-1508(ra) # 6d4 <panic>

00002cc0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint32 va)
{
    2cc0:	ff010113          	add	sp,sp,-16
    2cc4:	00812423          	sw	s0,8(sp)
    2cc8:	00112623          	sw	ra,12(sp)
    2ccc:	01010413          	add	s0,sp,16
  if(va >= MAXVA)
    2cd0:	fff00793          	li	a5,-1
    2cd4:	06f58263          	beq	a1,a5,2d38 <uvmclear+0x78>
    pte_t *pte = &pagetable[PX(level, va)];
    2cd8:	0165d793          	srl	a5,a1,0x16
    if(*pte & PTE_V) {
    2cdc:	00279793          	sll	a5,a5,0x2
    2ce0:	00f50533          	add	a0,a0,a5
    2ce4:	00052783          	lw	a5,0(a0)
    2ce8:	0017f713          	and	a4,a5,1
    2cec:	00071a63          	bnez	a4,2d00 <uvmclear+0x40>
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
    2cf0:	00008517          	auipc	a0,0x8
    2cf4:	6ec50513          	add	a0,a0,1772 # b3dc <main+0x2ac>
    2cf8:	ffffe097          	auipc	ra,0xffffe
    2cfc:	9dc080e7          	jalr	-1572(ra) # 6d4 <panic>
  return &pagetable[PX(0, va)];
    2d00:	00c5d593          	srl	a1,a1,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    2d04:	00a7d793          	srl	a5,a5,0xa
  return &pagetable[PX(0, va)];
    2d08:	3ff5f593          	and	a1,a1,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2d0c:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    2d10:	00259593          	sll	a1,a1,0x2
    2d14:	00b787b3          	add	a5,a5,a1
  if(pte == 0)
    2d18:	fc078ce3          	beqz	a5,2cf0 <uvmclear+0x30>
  *pte &= ~PTE_U;
    2d1c:	0007a703          	lw	a4,0(a5) # 1000 <freerange+0xc8>
}
    2d20:	00c12083          	lw	ra,12(sp)
    2d24:	00812403          	lw	s0,8(sp)
  *pte &= ~PTE_U;
    2d28:	fef77713          	and	a4,a4,-17
    2d2c:	00e7a023          	sw	a4,0(a5)
}
    2d30:	01010113          	add	sp,sp,16
    2d34:	00008067          	ret
    panic("walk");
    2d38:	00008517          	auipc	a0,0x8
    2d3c:	60c50513          	add	a0,a0,1548 # b344 <main+0x214>
    2d40:	ffffe097          	auipc	ra,0xffffe
    2d44:	994080e7          	jalr	-1644(ra) # 6d4 <panic>

00002d48 <copyout>:
int
copyout(pagetable_t pagetable, uint32 dstva, char *src, uint32 len)
{
  uint32 n, va0, pa0;

  while(len > 0){
    2d48:	10068863          	beqz	a3,2e58 <copyout+0x110>
{
    2d4c:	fd010113          	add	sp,sp,-48
    2d50:	02812423          	sw	s0,40(sp)
    2d54:	03212023          	sw	s2,32(sp)
    2d58:	01312e23          	sw	s3,28(sp)
    2d5c:	01412c23          	sw	s4,24(sp)
    2d60:	01612823          	sw	s6,16(sp)
    2d64:	01712623          	sw	s7,12(sp)
    2d68:	01812423          	sw	s8,8(sp)
    2d6c:	02112623          	sw	ra,44(sp)
    2d70:	02912223          	sw	s1,36(sp)
    2d74:	01512a23          	sw	s5,20(sp)
    2d78:	03010413          	add	s0,sp,48
    2d7c:	00068b13          	mv	s6,a3
    2d80:	00050913          	mv	s2,a0
    2d84:	00060b93          	mv	s7,a2
    va0 = PGROUNDDOWN(dstva);
    2d88:	fffff9b7          	lui	s3,0xfffff
  if((*pte & PTE_U) == 0)
    2d8c:	01100a13          	li	s4,17
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    2d90:	00001c37          	lui	s8,0x1
    va0 = PGROUNDDOWN(dstva);
    2d94:	0135fab3          	and	s5,a1,s3
    pte_t *pte = &pagetable[PX(level, va)];
    2d98:	016ad793          	srl	a5,s5,0x16
    if(*pte & PTE_V) {
    2d9c:	00279793          	sll	a5,a5,0x2
    2da0:	00f907b3          	add	a5,s2,a5
    2da4:	0007a503          	lw	a0,0(a5)
  return &pagetable[PX(0, va)];
    2da8:	00cad713          	srl	a4,s5,0xc
    2dac:	3ff77713          	and	a4,a4,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2db0:	00a55793          	srl	a5,a0,0xa
    2db4:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    2db8:	00271713          	sll	a4,a4,0x2
    if(*pte & PTE_V) {
    2dbc:	00157513          	and	a0,a0,1
  return &pagetable[PX(0, va)];
    2dc0:	00e787b3          	add	a5,a5,a4
    if(*pte & PTE_V) {
    2dc4:	02050863          	beqz	a0,2df4 <copyout+0xac>
    n = PGSIZE - (dstva - va0);
    2dc8:	40ba84b3          	sub	s1,s5,a1
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    2dcc:	41558533          	sub	a0,a1,s5
    n = PGSIZE - (dstva - va0);
    2dd0:	018484b3          	add	s1,s1,s8
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    2dd4:	000b8593          	mv	a1,s7
  if(pte == 0)
    2dd8:	00078e63          	beqz	a5,2df4 <copyout+0xac>
  if((*pte & PTE_V) == 0)
    2ddc:	0007a783          	lw	a5,0(a5)
  pa = PTE2PA(*pte);
    2de0:	00a7d713          	srl	a4,a5,0xa
    2de4:	00c71713          	sll	a4,a4,0xc
  if((*pte & PTE_U) == 0)
    2de8:	0117f793          	and	a5,a5,17
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    2dec:	00e50533          	add	a0,a0,a4
  if((*pte & PTE_U) == 0)
    2df0:	03478c63          	beq	a5,s4,2e28 <copyout+0xe0>
      return -1;
    2df4:	fff00513          	li	a0,-1
    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}
    2df8:	02c12083          	lw	ra,44(sp)
    2dfc:	02812403          	lw	s0,40(sp)
    2e00:	02412483          	lw	s1,36(sp)
    2e04:	02012903          	lw	s2,32(sp)
    2e08:	01c12983          	lw	s3,28(sp)
    2e0c:	01812a03          	lw	s4,24(sp)
    2e10:	01412a83          	lw	s5,20(sp)
    2e14:	01012b03          	lw	s6,16(sp)
    2e18:	00c12b83          	lw	s7,12(sp)
    2e1c:	00812c03          	lw	s8,8(sp)
    2e20:	03010113          	add	sp,sp,48
    2e24:	00008067          	ret
    if(pa0 == 0)
    2e28:	fc0706e3          	beqz	a4,2df4 <copyout+0xac>
    2e2c:	009b7463          	bgeu	s6,s1,2e34 <copyout+0xec>
    2e30:	000b0493          	mv	s1,s6
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    2e34:	00048613          	mv	a2,s1
    2e38:	fffff097          	auipc	ra,0xfffff
    2e3c:	9cc080e7          	jalr	-1588(ra) # 1804 <memmove>
    len -= n;
    2e40:	409b0b33          	sub	s6,s6,s1
    src += n;
    2e44:	009b8bb3          	add	s7,s7,s1
    dstva = va0 + PGSIZE;
    2e48:	018a85b3          	add	a1,s5,s8
  while(len > 0){
    2e4c:	f40b14e3          	bnez	s6,2d94 <copyout+0x4c>
  return 0;
    2e50:	00000513          	li	a0,0
    2e54:	fa5ff06f          	j	2df8 <copyout+0xb0>
    2e58:	00000513          	li	a0,0
}
    2e5c:	00008067          	ret

00002e60 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint32 srcva, uint32 len)
{
  uint32 n, va0, pa0;

  while(len > 0){
    2e60:	10068863          	beqz	a3,2f70 <copyin+0x110>
{
    2e64:	fd010113          	add	sp,sp,-48
    2e68:	02812423          	sw	s0,40(sp)
    2e6c:	03212023          	sw	s2,32(sp)
    2e70:	01312e23          	sw	s3,28(sp)
    2e74:	01412c23          	sw	s4,24(sp)
    2e78:	01612823          	sw	s6,16(sp)
    2e7c:	01712623          	sw	s7,12(sp)
    2e80:	01812423          	sw	s8,8(sp)
    2e84:	02112623          	sw	ra,44(sp)
    2e88:	02912223          	sw	s1,36(sp)
    2e8c:	01512a23          	sw	s5,20(sp)
    2e90:	03010413          	add	s0,sp,48
    2e94:	00068b13          	mv	s6,a3
    2e98:	00050913          	mv	s2,a0
    2e9c:	00058b93          	mv	s7,a1
    va0 = PGROUNDDOWN(srcva);
    2ea0:	fffff9b7          	lui	s3,0xfffff
  if((*pte & PTE_U) == 0)
    2ea4:	01100a13          	li	s4,17
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    2ea8:	00001c37          	lui	s8,0x1
    va0 = PGROUNDDOWN(srcva);
    2eac:	01367ab3          	and	s5,a2,s3
    pte_t *pte = &pagetable[PX(level, va)];
    2eb0:	016ad793          	srl	a5,s5,0x16
    if(*pte & PTE_V) {
    2eb4:	00279793          	sll	a5,a5,0x2
    2eb8:	00f907b3          	add	a5,s2,a5
    2ebc:	0007a803          	lw	a6,0(a5)
  return &pagetable[PX(0, va)];
    2ec0:	00cad713          	srl	a4,s5,0xc
    2ec4:	3ff77713          	and	a4,a4,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2ec8:	00a85793          	srl	a5,a6,0xa
    2ecc:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    2ed0:	00271713          	sll	a4,a4,0x2
    if(*pte & PTE_V) {
    2ed4:	00187813          	and	a6,a6,1
  return &pagetable[PX(0, va)];
    2ed8:	00e787b3          	add	a5,a5,a4
    if(*pte & PTE_V) {
    2edc:	02080863          	beqz	a6,2f0c <copyin+0xac>
    n = PGSIZE - (srcva - va0);
    2ee0:	40ca84b3          	sub	s1,s5,a2
    2ee4:	018484b3          	add	s1,s1,s8
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    2ee8:	41560633          	sub	a2,a2,s5
    2eec:	000b8513          	mv	a0,s7
  if(pte == 0)
    2ef0:	00078e63          	beqz	a5,2f0c <copyin+0xac>
  if((*pte & PTE_V) == 0)
    2ef4:	0007a783          	lw	a5,0(a5)
  pa = PTE2PA(*pte);
    2ef8:	00a7d713          	srl	a4,a5,0xa
    2efc:	00c71713          	sll	a4,a4,0xc
  if((*pte & PTE_U) == 0)
    2f00:	0117f793          	and	a5,a5,17
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    2f04:	00e605b3          	add	a1,a2,a4
  if((*pte & PTE_U) == 0)
    2f08:	03478c63          	beq	a5,s4,2f40 <copyin+0xe0>
      return -1;
    2f0c:	fff00513          	li	a0,-1
    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}
    2f10:	02c12083          	lw	ra,44(sp)
    2f14:	02812403          	lw	s0,40(sp)
    2f18:	02412483          	lw	s1,36(sp)
    2f1c:	02012903          	lw	s2,32(sp)
    2f20:	01c12983          	lw	s3,28(sp)
    2f24:	01812a03          	lw	s4,24(sp)
    2f28:	01412a83          	lw	s5,20(sp)
    2f2c:	01012b03          	lw	s6,16(sp)
    2f30:	00c12b83          	lw	s7,12(sp)
    2f34:	00812c03          	lw	s8,8(sp)
    2f38:	03010113          	add	sp,sp,48
    2f3c:	00008067          	ret
    if(pa0 == 0)
    2f40:	fc0706e3          	beqz	a4,2f0c <copyin+0xac>
    2f44:	009b7463          	bgeu	s6,s1,2f4c <copyin+0xec>
    2f48:	000b0493          	mv	s1,s6
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    2f4c:	00048613          	mv	a2,s1
    2f50:	fffff097          	auipc	ra,0xfffff
    2f54:	8b4080e7          	jalr	-1868(ra) # 1804 <memmove>
    len -= n;
    2f58:	409b0b33          	sub	s6,s6,s1
    dst += n;
    2f5c:	009b8bb3          	add	s7,s7,s1
    srcva = va0 + PGSIZE;
    2f60:	018a8633          	add	a2,s5,s8
  while(len > 0){
    2f64:	f40b14e3          	bnez	s6,2eac <copyin+0x4c>
  return 0;
    2f68:	00000513          	li	a0,0
    2f6c:	fa5ff06f          	j	2f10 <copyin+0xb0>
    2f70:	00000513          	li	a0,0
}
    2f74:	00008067          	ret

00002f78 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint32 srcva, uint32 max)
{
    2f78:	ff010113          	add	sp,sp,-16
    2f7c:	00812623          	sw	s0,12(sp)
    2f80:	01010413          	add	s0,sp,16
  uint32 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    2f84:	04068c63          	beqz	a3,2fdc <copyinstr+0x64>
    2f88:	00060813          	mv	a6,a2
    2f8c:	fffffeb7          	lui	t4,0xfffff
    2f90:	01100f13          	li	t5,17
    2f94:	00001e37          	lui	t3,0x1
    va0 = PGROUNDDOWN(srcva);
    2f98:	01d87333          	and	t1,a6,t4
    pte_t *pte = &pagetable[PX(level, va)];
    2f9c:	01635793          	srl	a5,t1,0x16
    if(*pte & PTE_V) {
    2fa0:	00279793          	sll	a5,a5,0x2
    2fa4:	00f507b3          	add	a5,a0,a5
    2fa8:	0007a783          	lw	a5,0(a5)
    2fac:	0017f713          	and	a4,a5,1
    2fb0:	02070663          	beqz	a4,2fdc <copyinstr+0x64>
  return &pagetable[PX(0, va)];
    2fb4:	00c35713          	srl	a4,t1,0xc
      pagetable = (pagetable_t)PTE2PA(*pte);
    2fb8:	00a7d793          	srl	a5,a5,0xa
  return &pagetable[PX(0, va)];
    2fbc:	3ff77713          	and	a4,a4,1023
      pagetable = (pagetable_t)PTE2PA(*pte);
    2fc0:	00c79793          	sll	a5,a5,0xc
  return &pagetable[PX(0, va)];
    2fc4:	00271713          	sll	a4,a4,0x2
    2fc8:	00e787b3          	add	a5,a5,a4
  if(pte == 0)
    2fcc:	00078863          	beqz	a5,2fdc <copyinstr+0x64>
  if((*pte & PTE_V) == 0)
    2fd0:	0007a783          	lw	a5,0(a5)
  if((*pte & PTE_U) == 0)
    2fd4:	0117f713          	and	a4,a5,17
    2fd8:	01e70a63          	beq	a4,t5,2fec <copyinstr+0x74>
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}
    2fdc:	00c12403          	lw	s0,12(sp)
      return -1;
    2fe0:	fff00513          	li	a0,-1
}
    2fe4:	01010113          	add	sp,sp,16
    2fe8:	00008067          	ret
  pa = PTE2PA(*pte);
    2fec:	00a7d793          	srl	a5,a5,0xa
    2ff0:	00c79793          	sll	a5,a5,0xc
    if(pa0 == 0)
    2ff4:	fe0784e3          	beqz	a5,2fdc <copyinstr+0x64>
    n = PGSIZE - (srcva - va0);
    2ff8:	41030633          	sub	a2,t1,a6
    2ffc:	01c60633          	add	a2,a2,t3
    3000:	00c6f463          	bgeu	a3,a2,3008 <copyinstr+0x90>
    3004:	00068613          	mv	a2,a3
    char *p = (char *) (pa0 + (srcva - va0));
    3008:	40680833          	sub	a6,a6,t1
    300c:	00f80833          	add	a6,a6,a5
    while(n > 0){
    3010:	06060063          	beqz	a2,3070 <copyinstr+0xf8>
    3014:	00058793          	mv	a5,a1
    3018:	40b80833          	sub	a6,a6,a1
    301c:	00b60633          	add	a2,a2,a1
    3020:	0100006f          	j	3030 <copyinstr+0xb8>
        *dst = *p;
    3024:	00e78023          	sb	a4,0(a5)
      dst++;
    3028:	00178793          	add	a5,a5,1
    while(n > 0){
    302c:	02c78463          	beq	a5,a2,3054 <copyinstr+0xdc>
      if(*p == '\0'){
    3030:	01078733          	add	a4,a5,a6
    3034:	00074703          	lbu	a4,0(a4) # fffff000 <end+0xfffdafec>
    3038:	00078893          	mv	a7,a5
    303c:	fe0714e3          	bnez	a4,3024 <copyinstr+0xac>
        *dst = '\0';
    3040:	00078023          	sb	zero,0(a5)
}
    3044:	00c12403          	lw	s0,12(sp)
        *dst = '\0';
    3048:	00000513          	li	a0,0
}
    304c:	01010113          	add	sp,sp,16
    3050:	00008067          	ret
    3054:	fff68713          	add	a4,a3,-1 # ffffefff <end+0xfffdafeb>
    3058:	00b70733          	add	a4,a4,a1
      --max;
    305c:	411706b3          	sub	a3,a4,a7
    srcva = va0 + PGSIZE;
    3060:	01c30833          	add	a6,t1,t3
  while(got_null == 0 && max > 0){
    3064:	f6e88ce3          	beq	a7,a4,2fdc <copyinstr+0x64>
{
    3068:	00078593          	mv	a1,a5
    306c:	f2dff06f          	j	2f98 <copyinstr+0x20>
    srcva = va0 + PGSIZE;
    3070:	00001837          	lui	a6,0x1
    3074:	00058793          	mv	a5,a1
    3078:	01030833          	add	a6,t1,a6
{
    307c:	00078593          	mv	a1,a5
    3080:	f19ff06f          	j	2f98 <copyinstr+0x20>

00003084 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    3084:	ff010113          	add	sp,sp,-16
    3088:	00812423          	sw	s0,8(sp)
    308c:	00112623          	sw	ra,12(sp)
    3090:	00912223          	sw	s1,4(sp)
    3094:	01010413          	add	s0,sp,16
  push_off();
    3098:	ffffe097          	auipc	ra,0xffffe
    309c:	4f0080e7          	jalr	1264(ra) # 1588 <push_off>
  asm volatile("mv %0, tp" : "=r" (x) );
    30a0:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    30a4:	00471793          	sll	a5,a4,0x4
    30a8:	00e787b3          	add	a5,a5,a4
    30ac:	00279793          	sll	a5,a5,0x2
    30b0:	00012717          	auipc	a4,0x12
    30b4:	40870713          	add	a4,a4,1032 # 154b8 <cpus>
    30b8:	00f707b3          	add	a5,a4,a5
    30bc:	0007a483          	lw	s1,0(a5)
  pop_off();
    30c0:	ffffe097          	auipc	ra,0xffffe
    30c4:	53c080e7          	jalr	1340(ra) # 15fc <pop_off>
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    30c8:	00048513          	mv	a0,s1
    30cc:	ffffe097          	auipc	ra,0xffffe
    30d0:	230080e7          	jalr	560(ra) # 12fc <release>

  if (first) {
    30d4:	00009797          	auipc	a5,0x9
    30d8:	f647a783          	lw	a5,-156(a5) # c038 <first.1>
    30dc:	00079e63          	bnez	a5,30f8 <forkret+0x74>
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}
    30e0:	00812403          	lw	s0,8(sp)
    30e4:	00c12083          	lw	ra,12(sp)
    30e8:	00412483          	lw	s1,4(sp)
    30ec:	01010113          	add	sp,sp,16
  usertrapret();
    30f0:	00001317          	auipc	t1,0x1
    30f4:	79430067          	jr	1940(t1) # 4884 <usertrapret>
    fsinit(ROOTDEV);
    30f8:	00100513          	li	a0,1
    first = 0;
    30fc:	00009797          	auipc	a5,0x9
    3100:	f207ae23          	sw	zero,-196(a5) # c038 <first.1>
    fsinit(ROOTDEV);
    3104:	00003097          	auipc	ra,0x3
    3108:	a30080e7          	jalr	-1488(ra) # 5b34 <fsinit>
}
    310c:	00812403          	lw	s0,8(sp)
    3110:	00c12083          	lw	ra,12(sp)
    3114:	00412483          	lw	s1,4(sp)
    3118:	01010113          	add	sp,sp,16
  usertrapret();
    311c:	00001317          	auipc	t1,0x1
    3120:	76830067          	jr	1896(t1) # 4884 <usertrapret>

00003124 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    3124:	ff010113          	add	sp,sp,-16
    3128:	00812423          	sw	s0,8(sp)
    312c:	00912223          	sw	s1,4(sp)
    3130:	00112623          	sw	ra,12(sp)
    3134:	01010413          	add	s0,sp,16
    3138:	00050493          	mv	s1,a0
  if(!holding(&p->lock))
    313c:	ffffe097          	auipc	ra,0xffffe
    3140:	33c080e7          	jalr	828(ra) # 1478 <holding>
    3144:	02050c63          	beqz	a0,317c <wakeup1+0x58>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    3148:	0144a783          	lw	a5,20(s1)
    314c:	00978c63          	beq	a5,s1,3164 <wakeup1+0x40>
    p->state = RUNNABLE;
  }
}
    3150:	00c12083          	lw	ra,12(sp)
    3154:	00812403          	lw	s0,8(sp)
    3158:	00412483          	lw	s1,4(sp)
    315c:	01010113          	add	sp,sp,16
    3160:	00008067          	ret
  if(p->chan == p && p->state == SLEEPING) {
    3164:	00c7a683          	lw	a3,12(a5)
    3168:	00100713          	li	a4,1
    316c:	fee692e3          	bne	a3,a4,3150 <wakeup1+0x2c>
    p->state = RUNNABLE;
    3170:	00200713          	li	a4,2
    3174:	00e7a623          	sw	a4,12(a5)
}
    3178:	fd9ff06f          	j	3150 <wakeup1+0x2c>
    panic("wakeup1");
    317c:	00008517          	auipc	a0,0x8
    3180:	26c50513          	add	a0,a0,620 # b3e8 <main+0x2b8>
    3184:	ffffd097          	auipc	ra,0xffffd
    3188:	550080e7          	jalr	1360(ra) # 6d4 <panic>

0000318c <allocproc>:
{
    318c:	ff010113          	add	sp,sp,-16
    3190:	00812423          	sw	s0,8(sp)
    3194:	00912223          	sw	s1,4(sp)
    3198:	01212023          	sw	s2,0(sp)
    319c:	00112623          	sw	ra,12(sp)
    31a0:	01010413          	add	s0,sp,16
  for(p = proc; p < &proc[NPROC]; p++) {
    31a4:	00012497          	auipc	s1,0x12
    31a8:	54048493          	add	s1,s1,1344 # 156e4 <proc>
    31ac:	00015917          	auipc	s2,0x15
    31b0:	53890913          	add	s2,s2,1336 # 186e4 <tickslock>
    31b4:	0140006f          	j	31c8 <allocproc+0x3c>
    31b8:	0c048493          	add	s1,s1,192
      release(&p->lock);
    31bc:	ffffe097          	auipc	ra,0xffffe
    31c0:	140080e7          	jalr	320(ra) # 12fc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    31c4:	11248263          	beq	s1,s2,32c8 <allocproc+0x13c>
    acquire(&p->lock);
    31c8:	00048513          	mv	a0,s1
    31cc:	ffffe097          	auipc	ra,0xffffe
    31d0:	fa4080e7          	jalr	-92(ra) # 1170 <acquire>
    if(p->state == UNUSED) {
    31d4:	00c4a783          	lw	a5,12(s1)
      release(&p->lock);
    31d8:	00048513          	mv	a0,s1
    if(p->state == UNUSED) {
    31dc:	fc079ee3          	bnez	a5,31b8 <allocproc+0x2c>
  acquire(&pid_lock);
    31e0:	00012517          	auipc	a0,0x12
    31e4:	4f850513          	add	a0,a0,1272 # 156d8 <pid_lock>
    31e8:	ffffe097          	auipc	ra,0xffffe
    31ec:	f88080e7          	jalr	-120(ra) # 1170 <acquire>
  pid = nextpid;
    31f0:	00009797          	auipc	a5,0x9
    31f4:	e4c78793          	add	a5,a5,-436 # c03c <nextpid>
    31f8:	0007a903          	lw	s2,0(a5)
  release(&pid_lock);
    31fc:	00012517          	auipc	a0,0x12
    3200:	4dc50513          	add	a0,a0,1244 # 156d8 <pid_lock>
  nextpid = nextpid + 1;
    3204:	00190713          	add	a4,s2,1
    3208:	00e7a023          	sw	a4,0(a5)
  release(&pid_lock);
    320c:	ffffe097          	auipc	ra,0xffffe
    3210:	0f0080e7          	jalr	240(ra) # 12fc <release>
  p->pid = allocpid();
    3214:	0324a023          	sw	s2,32(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    3218:	ffffe097          	auipc	ra,0xffffe
    321c:	e94080e7          	jalr	-364(ra) # 10ac <kalloc>
    3220:	02a4a823          	sw	a0,48(s1)
    3224:	08050c63          	beqz	a0,32bc <allocproc+0x130>
  pagetable = uvmcreate();
    3228:	fffff097          	auipc	ra,0xfffff
    322c:	5e4080e7          	jalr	1508(ra) # 280c <uvmcreate>
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    3230:	00a00713          	li	a4,10
    3234:	00008697          	auipc	a3,0x8
    3238:	dcc68693          	add	a3,a3,-564 # b000 <trampoline>
    323c:	00001637          	lui	a2,0x1
    3240:	fffff5b7          	lui	a1,0xfffff
  pagetable = uvmcreate();
    3244:	00050913          	mv	s2,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    3248:	fffff097          	auipc	ra,0xfffff
    324c:	160080e7          	jalr	352(ra) # 23a8 <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    3250:	0304a683          	lw	a3,48(s1)
    3254:	00600713          	li	a4,6
    3258:	00001637          	lui	a2,0x1
    325c:	ffffe5b7          	lui	a1,0xffffe
    3260:	00090513          	mv	a0,s2
    3264:	fffff097          	auipc	ra,0xfffff
    3268:	144080e7          	jalr	324(ra) # 23a8 <mappages>
  memset(&p->context, 0, sizeof p->context);
    326c:	03800613          	li	a2,56
  p->pagetable = proc_pagetable(p);
    3270:	0324a623          	sw	s2,44(s1)
  memset(&p->context, 0, sizeof p->context);
    3274:	00000593          	li	a1,0
    3278:	03448513          	add	a0,s1,52
    327c:	ffffe097          	auipc	ra,0xffffe
    3280:	408080e7          	jalr	1032(ra) # 1684 <memset>
  p->context.sp = p->kstack + PGSIZE;
    3284:	0244a783          	lw	a5,36(s1)
    3288:	00001737          	lui	a4,0x1
    328c:	00e787b3          	add	a5,a5,a4
  p->context.ra = (uint32)forkret;
    3290:	00000717          	auipc	a4,0x0
    3294:	df470713          	add	a4,a4,-524 # 3084 <forkret>
    3298:	02e4aa23          	sw	a4,52(s1)
  p->context.sp = p->kstack + PGSIZE;
    329c:	02f4ac23          	sw	a5,56(s1)
}
    32a0:	00c12083          	lw	ra,12(sp)
    32a4:	00812403          	lw	s0,8(sp)
    32a8:	00012903          	lw	s2,0(sp)
    32ac:	00048513          	mv	a0,s1
    32b0:	00412483          	lw	s1,4(sp)
    32b4:	01010113          	add	sp,sp,16
    32b8:	00008067          	ret
    release(&p->lock);
    32bc:	00048513          	mv	a0,s1
    32c0:	ffffe097          	auipc	ra,0xffffe
    32c4:	03c080e7          	jalr	60(ra) # 12fc <release>
  return 0;
    32c8:	00000493          	li	s1,0
    32cc:	fd5ff06f          	j	32a0 <allocproc+0x114>

000032d0 <procinit>:
{
    32d0:	fd010113          	add	sp,sp,-48
    32d4:	02812423          	sw	s0,40(sp)
    32d8:	03212023          	sw	s2,32(sp)
    32dc:	01312e23          	sw	s3,28(sp)
    32e0:	01412c23          	sw	s4,24(sp)
    32e4:	01512a23          	sw	s5,20(sp)
    32e8:	01612823          	sw	s6,16(sp)
    32ec:	01712623          	sw	s7,12(sp)
    32f0:	02112623          	sw	ra,44(sp)
    32f4:	02912223          	sw	s1,36(sp)
    32f8:	03010413          	add	s0,sp,48
  initlock(&pid_lock, "nextpid");
    32fc:	00008597          	auipc	a1,0x8
    3300:	0f458593          	add	a1,a1,244 # b3f0 <main+0x2c0>
    3304:	00012517          	auipc	a0,0x12
    3308:	3d450513          	add	a0,a0,980 # 156d8 <pid_lock>
  for(p = proc; p < &proc[NPROC]; p++) {
    330c:	00012997          	auipc	s3,0x12
    3310:	3d898993          	add	s3,s3,984 # 156e4 <proc>
      uint32 va = KSTACK((int) (p - proc));
    3314:	aaaab937          	lui	s2,0xaaaab
  initlock(&pid_lock, "nextpid");
    3318:	ffffe097          	auipc	ra,0xffffe
    331c:	e34080e7          	jalr	-460(ra) # 114c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    3320:	00098b93          	mv	s7,s3
      initlock(&p->lock, "proc");
    3324:	00008b17          	auipc	s6,0x8
    3328:	0d4b0b13          	add	s6,s6,212 # b3f8 <main+0x2c8>
      uint32 va = KSTACK((int) (p - proc));
    332c:	aab90913          	add	s2,s2,-1365 # aaaaaaab <end+0xaaa86a97>
    3330:	fffffab7          	lui	s5,0xfffff
  for(p = proc; p < &proc[NPROC]; p++) {
    3334:	00015a17          	auipc	s4,0x15
    3338:	3b0a0a13          	add	s4,s4,944 # 186e4 <tickslock>
      initlock(&p->lock, "proc");
    333c:	000b0593          	mv	a1,s6
    3340:	000b8513          	mv	a0,s7
    3344:	ffffe097          	auipc	ra,0xffffe
    3348:	e08080e7          	jalr	-504(ra) # 114c <initlock>
      char *pa = kalloc();
    334c:	ffffe097          	auipc	ra,0xffffe
    3350:	d60080e7          	jalr	-672(ra) # 10ac <kalloc>
    3354:	00050593          	mv	a1,a0
      if(pa == 0)
    3358:	06050663          	beqz	a0,33c4 <procinit+0xf4>
      uint32 va = KSTACK((int) (p - proc));
    335c:	413b84b3          	sub	s1,s7,s3
    3360:	4064d493          	sra	s1,s1,0x6
    3364:	032484b3          	mul	s1,s1,s2
      kvmmap(va, (uint32)pa, PGSIZE, PTE_R | PTE_W);
    3368:	00600693          	li	a3,6
    336c:	00001637          	lui	a2,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    3370:	0c0b8b93          	add	s7,s7,192
      uint32 va = KSTACK((int) (p - proc));
    3374:	00148493          	add	s1,s1,1
    3378:	00d49493          	sll	s1,s1,0xd
    337c:	409a84b3          	sub	s1,s5,s1
      kvmmap(va, (uint32)pa, PGSIZE, PTE_R | PTE_W);
    3380:	00048513          	mv	a0,s1
    3384:	fffff097          	auipc	ra,0xfffff
    3388:	16c080e7          	jalr	364(ra) # 24f0 <kvmmap>
      p->kstack = va;
    338c:	f69ba223          	sw	s1,-156(s7)
  for(p = proc; p < &proc[NPROC]; p++) {
    3390:	fb4b96e3          	bne	s7,s4,333c <procinit+0x6c>
}
    3394:	02812403          	lw	s0,40(sp)
    3398:	02c12083          	lw	ra,44(sp)
    339c:	02412483          	lw	s1,36(sp)
    33a0:	02012903          	lw	s2,32(sp)
    33a4:	01c12983          	lw	s3,28(sp)
    33a8:	01812a03          	lw	s4,24(sp)
    33ac:	01412a83          	lw	s5,20(sp)
    33b0:	01012b03          	lw	s6,16(sp)
    33b4:	00c12b83          	lw	s7,12(sp)
    33b8:	03010113          	add	sp,sp,48
  kvminithart();
    33bc:	fffff317          	auipc	t1,0xfffff
    33c0:	e8830067          	jr	-376(t1) # 2244 <kvminithart>
        panic("kalloc");
    33c4:	00008517          	auipc	a0,0x8
    33c8:	03c50513          	add	a0,a0,60 # b400 <main+0x2d0>
    33cc:	ffffd097          	auipc	ra,0xffffd
    33d0:	308080e7          	jalr	776(ra) # 6d4 <panic>

000033d4 <cpuid>:
{
    33d4:	ff010113          	add	sp,sp,-16
    33d8:	00812623          	sw	s0,12(sp)
    33dc:	01010413          	add	s0,sp,16
    33e0:	00020513          	mv	a0,tp
}
    33e4:	00c12403          	lw	s0,12(sp)
    33e8:	01010113          	add	sp,sp,16
    33ec:	00008067          	ret

000033f0 <mycpu>:
mycpu(void) {
    33f0:	ff010113          	add	sp,sp,-16
    33f4:	00812623          	sw	s0,12(sp)
    33f8:	01010413          	add	s0,sp,16
    33fc:	00020713          	mv	a4,tp
}
    3400:	00c12403          	lw	s0,12(sp)
  struct cpu *c = &cpus[id];
    3404:	00471793          	sll	a5,a4,0x4
    3408:	00e787b3          	add	a5,a5,a4
    340c:	00279793          	sll	a5,a5,0x2
}
    3410:	00012517          	auipc	a0,0x12
    3414:	0a850513          	add	a0,a0,168 # 154b8 <cpus>
    3418:	00f50533          	add	a0,a0,a5
    341c:	01010113          	add	sp,sp,16
    3420:	00008067          	ret

00003424 <myproc>:
myproc(void) {
    3424:	ff010113          	add	sp,sp,-16
    3428:	00812423          	sw	s0,8(sp)
    342c:	00112623          	sw	ra,12(sp)
    3430:	00912223          	sw	s1,4(sp)
    3434:	01010413          	add	s0,sp,16
  push_off();
    3438:	ffffe097          	auipc	ra,0xffffe
    343c:	150080e7          	jalr	336(ra) # 1588 <push_off>
    3440:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    3444:	00471793          	sll	a5,a4,0x4
    3448:	00e787b3          	add	a5,a5,a4
    344c:	00279793          	sll	a5,a5,0x2
    3450:	00012717          	auipc	a4,0x12
    3454:	06870713          	add	a4,a4,104 # 154b8 <cpus>
    3458:	00f707b3          	add	a5,a4,a5
    345c:	0007a483          	lw	s1,0(a5)
  pop_off();
    3460:	ffffe097          	auipc	ra,0xffffe
    3464:	19c080e7          	jalr	412(ra) # 15fc <pop_off>
}
    3468:	00c12083          	lw	ra,12(sp)
    346c:	00812403          	lw	s0,8(sp)
    3470:	00048513          	mv	a0,s1
    3474:	00412483          	lw	s1,4(sp)
    3478:	01010113          	add	sp,sp,16
    347c:	00008067          	ret

00003480 <allocpid>:
allocpid() {
    3480:	ff010113          	add	sp,sp,-16
    3484:	00112623          	sw	ra,12(sp)
    3488:	00812423          	sw	s0,8(sp)
    348c:	00912223          	sw	s1,4(sp)
    3490:	01212023          	sw	s2,0(sp)
    3494:	01010413          	add	s0,sp,16
  acquire(&pid_lock);
    3498:	00012917          	auipc	s2,0x12
    349c:	24090913          	add	s2,s2,576 # 156d8 <pid_lock>
    34a0:	00090513          	mv	a0,s2
    34a4:	ffffe097          	auipc	ra,0xffffe
    34a8:	ccc080e7          	jalr	-820(ra) # 1170 <acquire>
  pid = nextpid;
    34ac:	00009797          	auipc	a5,0x9
    34b0:	b9078793          	add	a5,a5,-1136 # c03c <nextpid>
    34b4:	0007a483          	lw	s1,0(a5)
  release(&pid_lock);
    34b8:	00090513          	mv	a0,s2
  nextpid = nextpid + 1;
    34bc:	00148713          	add	a4,s1,1
    34c0:	00e7a023          	sw	a4,0(a5)
  release(&pid_lock);
    34c4:	ffffe097          	auipc	ra,0xffffe
    34c8:	e38080e7          	jalr	-456(ra) # 12fc <release>
}
    34cc:	00c12083          	lw	ra,12(sp)
    34d0:	00812403          	lw	s0,8(sp)
    34d4:	00012903          	lw	s2,0(sp)
    34d8:	00048513          	mv	a0,s1
    34dc:	00412483          	lw	s1,4(sp)
    34e0:	01010113          	add	sp,sp,16
    34e4:	00008067          	ret

000034e8 <proc_pagetable>:
{
    34e8:	ff010113          	add	sp,sp,-16
    34ec:	00112623          	sw	ra,12(sp)
    34f0:	00812423          	sw	s0,8(sp)
    34f4:	00912223          	sw	s1,4(sp)
    34f8:	01010413          	add	s0,sp,16
    34fc:	01212023          	sw	s2,0(sp)
    3500:	00050913          	mv	s2,a0
  pagetable = uvmcreate();
    3504:	fffff097          	auipc	ra,0xfffff
    3508:	308080e7          	jalr	776(ra) # 280c <uvmcreate>
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    350c:	00a00713          	li	a4,10
    3510:	00008697          	auipc	a3,0x8
    3514:	af068693          	add	a3,a3,-1296 # b000 <trampoline>
    3518:	00001637          	lui	a2,0x1
    351c:	fffff5b7          	lui	a1,0xfffff
  pagetable = uvmcreate();
    3520:	00050493          	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    3524:	fffff097          	auipc	ra,0xfffff
    3528:	e84080e7          	jalr	-380(ra) # 23a8 <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    352c:	03092683          	lw	a3,48(s2)
    3530:	00048513          	mv	a0,s1
    3534:	00600713          	li	a4,6
    3538:	00001637          	lui	a2,0x1
    353c:	ffffe5b7          	lui	a1,0xffffe
    3540:	fffff097          	auipc	ra,0xfffff
    3544:	e68080e7          	jalr	-408(ra) # 23a8 <mappages>
}
    3548:	00c12083          	lw	ra,12(sp)
    354c:	00812403          	lw	s0,8(sp)
    3550:	00012903          	lw	s2,0(sp)
    3554:	00048513          	mv	a0,s1
    3558:	00412483          	lw	s1,4(sp)
    355c:	01010113          	add	sp,sp,16
    3560:	00008067          	ret

00003564 <proc_freepagetable>:
{
    3564:	ff010113          	add	sp,sp,-16
    3568:	00812423          	sw	s0,8(sp)
    356c:	00912223          	sw	s1,4(sp)
    3570:	01212023          	sw	s2,0(sp)
    3574:	00112623          	sw	ra,12(sp)
    3578:	01010413          	add	s0,sp,16
    357c:	00058913          	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    3580:	00000693          	li	a3,0
    3584:	00001637          	lui	a2,0x1
    3588:	fffff5b7          	lui	a1,0xfffff
{
    358c:	00050493          	mv	s1,a0
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    3590:	fffff097          	auipc	ra,0xfffff
    3594:	100080e7          	jalr	256(ra) # 2690 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    3598:	00000693          	li	a3,0
    359c:	00001637          	lui	a2,0x1
    35a0:	ffffe5b7          	lui	a1,0xffffe
    35a4:	00048513          	mv	a0,s1
    35a8:	fffff097          	auipc	ra,0xfffff
    35ac:	0e8080e7          	jalr	232(ra) # 2690 <uvmunmap>
  if(sz > 0)
    35b0:	00091e63          	bnez	s2,35cc <proc_freepagetable+0x68>
}
    35b4:	00c12083          	lw	ra,12(sp)
    35b8:	00812403          	lw	s0,8(sp)
    35bc:	00412483          	lw	s1,4(sp)
    35c0:	00012903          	lw	s2,0(sp)
    35c4:	01010113          	add	sp,sp,16
    35c8:	00008067          	ret
    35cc:	00812403          	lw	s0,8(sp)
    35d0:	00c12083          	lw	ra,12(sp)
    uvmfree(pagetable, sz);
    35d4:	00090593          	mv	a1,s2
    35d8:	00048513          	mv	a0,s1
}
    35dc:	00012903          	lw	s2,0(sp)
    35e0:	00412483          	lw	s1,4(sp)
    35e4:	01010113          	add	sp,sp,16
    uvmfree(pagetable, sz);
    35e8:	fffff317          	auipc	t1,0xfffff
    35ec:	4c830067          	jr	1224(t1) # 2ab0 <uvmfree>

000035f0 <userinit>:
{
    35f0:	ff010113          	add	sp,sp,-16
    35f4:	00112623          	sw	ra,12(sp)
    35f8:	00812423          	sw	s0,8(sp)
    35fc:	00912223          	sw	s1,4(sp)
    3600:	01010413          	add	s0,sp,16
  p = allocproc();
    3604:	00000097          	auipc	ra,0x0
    3608:	b88080e7          	jalr	-1144(ra) # 318c <allocproc>
    360c:	00050493          	mv	s1,a0
  uvminit(p->pagetable, initcode, sizeof(initcode));
    3610:	02c52503          	lw	a0,44(a0)
    3614:	03800613          	li	a2,56
    3618:	00009597          	auipc	a1,0x9
    361c:	9e858593          	add	a1,a1,-1560 # c000 <initcode>
  initproc = p;
    3620:	00021797          	auipc	a5,0x21
    3624:	9e97a623          	sw	s1,-1556(a5) # 2400c <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    3628:	fffff097          	auipc	ra,0xfffff
    362c:	240080e7          	jalr	576(ra) # 2868 <uvminit>
  p->tf->epc = 0;      // user program counter
    3630:	0304a783          	lw	a5,48(s1)
  p->sz = PGSIZE;
    3634:	00001737          	lui	a4,0x1
    3638:	02e4a423          	sw	a4,40(s1)
  p->tf->epc = 0;      // user program counter
    363c:	0007a623          	sw	zero,12(a5)
  p->tf->sp = PGSIZE;  // user stack pointer
    3640:	00e7ac23          	sw	a4,24(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    3644:	01000613          	li	a2,16
    3648:	00008597          	auipc	a1,0x8
    364c:	dc058593          	add	a1,a1,-576 # b408 <main+0x2d8>
    3650:	0b048513          	add	a0,s1,176
    3654:	ffffe097          	auipc	ra,0xffffe
    3658:	530080e7          	jalr	1328(ra) # 1b84 <safestrcpy>
  p->cwd = namei("/");
    365c:	00008517          	auipc	a0,0x8
    3660:	db850513          	add	a0,a0,-584 # b414 <main+0x2e4>
    3664:	00004097          	auipc	ra,0x4
    3668:	b80080e7          	jalr	-1152(ra) # 71e4 <namei>
  p->state = RUNNABLE;
    366c:	00200793          	li	a5,2
}
    3670:	00812403          	lw	s0,8(sp)
  p->cwd = namei("/");
    3674:	0aa4a623          	sw	a0,172(s1)
}
    3678:	00c12083          	lw	ra,12(sp)
  p->state = RUNNABLE;
    367c:	00f4a623          	sw	a5,12(s1)
  release(&p->lock);
    3680:	00048513          	mv	a0,s1
}
    3684:	00412483          	lw	s1,4(sp)
    3688:	01010113          	add	sp,sp,16
  release(&p->lock);
    368c:	ffffe317          	auipc	t1,0xffffe
    3690:	c7030067          	jr	-912(t1) # 12fc <release>

00003694 <growproc>:
{
    3694:	ff010113          	add	sp,sp,-16
    3698:	00812423          	sw	s0,8(sp)
    369c:	00912223          	sw	s1,4(sp)
    36a0:	00112623          	sw	ra,12(sp)
    36a4:	01212023          	sw	s2,0(sp)
    36a8:	01010413          	add	s0,sp,16
    36ac:	00050493          	mv	s1,a0
  push_off();
    36b0:	ffffe097          	auipc	ra,0xffffe
    36b4:	ed8080e7          	jalr	-296(ra) # 1588 <push_off>
    36b8:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    36bc:	00471793          	sll	a5,a4,0x4
    36c0:	00e787b3          	add	a5,a5,a4
    36c4:	00279793          	sll	a5,a5,0x2
    36c8:	00012717          	auipc	a4,0x12
    36cc:	df070713          	add	a4,a4,-528 # 154b8 <cpus>
    36d0:	00f707b3          	add	a5,a4,a5
    36d4:	0007a903          	lw	s2,0(a5)
  pop_off();
    36d8:	ffffe097          	auipc	ra,0xffffe
    36dc:	f24080e7          	jalr	-220(ra) # 15fc <pop_off>
  sz = p->sz;
    36e0:	02892583          	lw	a1,40(s2)
  if(n > 0){
    36e4:	02904463          	bgtz	s1,370c <growproc+0x78>
  } else if(n < 0){
    36e8:	04049263          	bnez	s1,372c <growproc+0x98>
  p->sz = sz;
    36ec:	02b92423          	sw	a1,40(s2)
  return 0;
    36f0:	00000513          	li	a0,0
}
    36f4:	00c12083          	lw	ra,12(sp)
    36f8:	00812403          	lw	s0,8(sp)
    36fc:	00412483          	lw	s1,4(sp)
    3700:	00012903          	lw	s2,0(sp)
    3704:	01010113          	add	sp,sp,16
    3708:	00008067          	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    370c:	02c92503          	lw	a0,44(s2)
    3710:	00b48633          	add	a2,s1,a1
    3714:	fffff097          	auipc	ra,0xfffff
    3718:	1fc080e7          	jalr	508(ra) # 2910 <uvmalloc>
    371c:	00050593          	mv	a1,a0
    3720:	fc0516e3          	bnez	a0,36ec <growproc+0x58>
      return -1;
    3724:	fff00513          	li	a0,-1
    3728:	fcdff06f          	j	36f4 <growproc+0x60>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    372c:	02c92503          	lw	a0,44(s2)
    3730:	00b48633          	add	a2,s1,a1
    3734:	fffff097          	auipc	ra,0xfffff
    3738:	2f8080e7          	jalr	760(ra) # 2a2c <uvmdealloc>
    373c:	00050593          	mv	a1,a0
    3740:	fadff06f          	j	36ec <growproc+0x58>

00003744 <fork>:
{
    3744:	fe010113          	add	sp,sp,-32
    3748:	00812c23          	sw	s0,24(sp)
    374c:	00112e23          	sw	ra,28(sp)
    3750:	00912a23          	sw	s1,20(sp)
    3754:	01212823          	sw	s2,16(sp)
    3758:	01312623          	sw	s3,12(sp)
    375c:	01412423          	sw	s4,8(sp)
    3760:	01512223          	sw	s5,4(sp)
    3764:	02010413          	add	s0,sp,32
  push_off();
    3768:	ffffe097          	auipc	ra,0xffffe
    376c:	e20080e7          	jalr	-480(ra) # 1588 <push_off>
    3770:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    3774:	00471793          	sll	a5,a4,0x4
    3778:	00e787b3          	add	a5,a5,a4
    377c:	00279793          	sll	a5,a5,0x2
    3780:	00012717          	auipc	a4,0x12
    3784:	d3870713          	add	a4,a4,-712 # 154b8 <cpus>
    3788:	00f707b3          	add	a5,a4,a5
    378c:	0007aa83          	lw	s5,0(a5)
  pop_off();
    3790:	ffffe097          	auipc	ra,0xffffe
    3794:	e6c080e7          	jalr	-404(ra) # 15fc <pop_off>
  if((np = allocproc()) == 0){
    3798:	00000097          	auipc	ra,0x0
    379c:	9f4080e7          	jalr	-1548(ra) # 318c <allocproc>
    37a0:	18050063          	beqz	a0,3920 <fork+0x1dc>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    37a4:	02c52583          	lw	a1,44(a0)
    37a8:	00050a13          	mv	s4,a0
    37ac:	028aa603          	lw	a2,40(s5) # fffff028 <end+0xfffdb014>
    37b0:	02caa503          	lw	a0,44(s5)
    37b4:	fffff097          	auipc	ra,0xfffff
    37b8:	3b8080e7          	jalr	952(ra) # 2b6c <uvmcopy>
    37bc:	0e054063          	bltz	a0,389c <fork+0x158>
  np->sz = p->sz;
    37c0:	028aa703          	lw	a4,40(s5)
  *(np->tf) = *(p->tf);
    37c4:	030aa783          	lw	a5,48(s5)
    37c8:	030a2883          	lw	a7,48(s4)
  np->sz = p->sz;
    37cc:	02ea2423          	sw	a4,40(s4)
  np->parent = p;
    37d0:	015a2823          	sw	s5,16(s4)
  *(np->tf) = *(p->tf);
    37d4:	00088713          	mv	a4,a7
    37d8:	09078813          	add	a6,a5,144
    37dc:	0007a503          	lw	a0,0(a5)
    37e0:	0047a583          	lw	a1,4(a5)
    37e4:	0087a603          	lw	a2,8(a5)
    37e8:	00c7a683          	lw	a3,12(a5)
    37ec:	00a72023          	sw	a0,0(a4)
    37f0:	00b72223          	sw	a1,4(a4)
    37f4:	00c72423          	sw	a2,8(a4)
    37f8:	00d72623          	sw	a3,12(a4)
    37fc:	01078793          	add	a5,a5,16
    3800:	01070713          	add	a4,a4,16
    3804:	fd079ce3          	bne	a5,a6,37dc <fork+0x98>
  np->tf->a0 = 0;
    3808:	0208ac23          	sw	zero,56(a7)
  for(i = 0; i < NOFILE; i++)
    380c:	06ca8493          	add	s1,s5,108
    3810:	06ca0913          	add	s2,s4,108
    3814:	0aca8993          	add	s3,s5,172
    if(p->ofile[i])
    3818:	0004a503          	lw	a0,0(s1)
  for(i = 0; i < NOFILE; i++)
    381c:	00448493          	add	s1,s1,4
    if(p->ofile[i])
    3820:	00050863          	beqz	a0,3830 <fork+0xec>
      np->ofile[i] = filedup(p->ofile[i]);
    3824:	00004097          	auipc	ra,0x4
    3828:	2b4080e7          	jalr	692(ra) # 7ad8 <filedup>
    382c:	00a92023          	sw	a0,0(s2)
  for(i = 0; i < NOFILE; i++)
    3830:	00490913          	add	s2,s2,4
    3834:	ff3492e3          	bne	s1,s3,3818 <fork+0xd4>
  np->cwd = idup(p->cwd);
    3838:	0acaa503          	lw	a0,172(s5)
    383c:	00002097          	auipc	ra,0x2
    3840:	68c080e7          	jalr	1676(ra) # 5ec8 <idup>
    3844:	0aaa2623          	sw	a0,172(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    3848:	01000613          	li	a2,16
    384c:	0b0a8593          	add	a1,s5,176
    3850:	0b0a0513          	add	a0,s4,176
    3854:	ffffe097          	auipc	ra,0xffffe
    3858:	330080e7          	jalr	816(ra) # 1b84 <safestrcpy>
  np->state = RUNNABLE;
    385c:	00200793          	li	a5,2
    3860:	00fa2623          	sw	a5,12(s4)
  release(&np->lock);
    3864:	000a0513          	mv	a0,s4
  pid = np->pid;
    3868:	020a2483          	lw	s1,32(s4)
  release(&np->lock);
    386c:	ffffe097          	auipc	ra,0xffffe
    3870:	a90080e7          	jalr	-1392(ra) # 12fc <release>
}
    3874:	01c12083          	lw	ra,28(sp)
    3878:	01812403          	lw	s0,24(sp)
    387c:	01012903          	lw	s2,16(sp)
    3880:	00c12983          	lw	s3,12(sp)
    3884:	00812a03          	lw	s4,8(sp)
    3888:	00412a83          	lw	s5,4(sp)
    388c:	00048513          	mv	a0,s1
    3890:	01412483          	lw	s1,20(sp)
    3894:	02010113          	add	sp,sp,32
    3898:	00008067          	ret
  if(p->tf)
    389c:	030a2503          	lw	a0,48(s4)
    38a0:	00050663          	beqz	a0,38ac <fork+0x168>
    kfree((void*)p->tf);
    38a4:	ffffd097          	auipc	ra,0xffffd
    38a8:	780080e7          	jalr	1920(ra) # 1024 <kfree>
  if(p->pagetable)
    38ac:	02ca2483          	lw	s1,44(s4)
  p->tf = 0;
    38b0:	020a2823          	sw	zero,48(s4)
  if(p->pagetable)
    38b4:	02048e63          	beqz	s1,38f0 <fork+0x1ac>
    proc_freepagetable(p->pagetable, p->sz);
    38b8:	028a2903          	lw	s2,40(s4)
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    38bc:	00000693          	li	a3,0
    38c0:	00001637          	lui	a2,0x1
    38c4:	fffff5b7          	lui	a1,0xfffff
    38c8:	00048513          	mv	a0,s1
    38cc:	fffff097          	auipc	ra,0xfffff
    38d0:	dc4080e7          	jalr	-572(ra) # 2690 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    38d4:	00000693          	li	a3,0
    38d8:	00001637          	lui	a2,0x1
    38dc:	ffffe5b7          	lui	a1,0xffffe
    38e0:	00048513          	mv	a0,s1
    38e4:	fffff097          	auipc	ra,0xfffff
    38e8:	dac080e7          	jalr	-596(ra) # 2690 <uvmunmap>
  if(sz > 0)
    38ec:	02091e63          	bnez	s2,3928 <fork+0x1e4>
  p->pagetable = 0;
    38f0:	020a2623          	sw	zero,44(s4)
  p->sz = 0;
    38f4:	020a2423          	sw	zero,40(s4)
  p->pid = 0;
    38f8:	020a2023          	sw	zero,32(s4)
  p->parent = 0;
    38fc:	000a2823          	sw	zero,16(s4)
  p->name[0] = 0;
    3900:	0a0a0823          	sb	zero,176(s4)
  p->chan = 0;
    3904:	000a2a23          	sw	zero,20(s4)
  p->killed = 0;
    3908:	000a2c23          	sw	zero,24(s4)
  p->xstate = 0;
    390c:	000a2e23          	sw	zero,28(s4)
  p->state = UNUSED;
    3910:	000a2623          	sw	zero,12(s4)
    release(&np->lock);
    3914:	000a0513          	mv	a0,s4
    3918:	ffffe097          	auipc	ra,0xffffe
    391c:	9e4080e7          	jalr	-1564(ra) # 12fc <release>
    return -1;
    3920:	fff00493          	li	s1,-1
    3924:	f51ff06f          	j	3874 <fork+0x130>
    uvmfree(pagetable, sz);
    3928:	00090593          	mv	a1,s2
    392c:	00048513          	mv	a0,s1
    3930:	fffff097          	auipc	ra,0xfffff
    3934:	180080e7          	jalr	384(ra) # 2ab0 <uvmfree>
    3938:	fb9ff06f          	j	38f0 <fork+0x1ac>

0000393c <reparent>:
{
    393c:	fe010113          	add	sp,sp,-32
    3940:	00812c23          	sw	s0,24(sp)
    3944:	00912a23          	sw	s1,20(sp)
    3948:	01212823          	sw	s2,16(sp)
    394c:	01312623          	sw	s3,12(sp)
    3950:	01412423          	sw	s4,8(sp)
    3954:	00112e23          	sw	ra,28(sp)
    3958:	02010413          	add	s0,sp,32
    395c:	00050913          	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    3960:	00012497          	auipc	s1,0x12
    3964:	d8448493          	add	s1,s1,-636 # 156e4 <proc>
    3968:	00015997          	auipc	s3,0x15
    396c:	d7c98993          	add	s3,s3,-644 # 186e4 <tickslock>
      pp->parent = initproc;
    3970:	00020a17          	auipc	s4,0x20
    3974:	69ca0a13          	add	s4,s4,1692 # 2400c <initproc>
    3978:	00c0006f          	j	3984 <reparent+0x48>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    397c:	0c048493          	add	s1,s1,192
    3980:	03348a63          	beq	s1,s3,39b4 <reparent+0x78>
    if(pp->parent == p){
    3984:	0104a783          	lw	a5,16(s1)
    3988:	ff279ae3          	bne	a5,s2,397c <reparent+0x40>
      acquire(&pp->lock);
    398c:	00048513          	mv	a0,s1
    3990:	ffffd097          	auipc	ra,0xffffd
    3994:	7e0080e7          	jalr	2016(ra) # 1170 <acquire>
      pp->parent = initproc;
    3998:	000a2783          	lw	a5,0(s4)
      release(&pp->lock);
    399c:	00048513          	mv	a0,s1
  for(pp = proc; pp < &proc[NPROC]; pp++){
    39a0:	0c048493          	add	s1,s1,192
      pp->parent = initproc;
    39a4:	f4f4a823          	sw	a5,-176(s1)
      release(&pp->lock);
    39a8:	ffffe097          	auipc	ra,0xffffe
    39ac:	954080e7          	jalr	-1708(ra) # 12fc <release>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    39b0:	fd349ae3          	bne	s1,s3,3984 <reparent+0x48>
}
    39b4:	01c12083          	lw	ra,28(sp)
    39b8:	01812403          	lw	s0,24(sp)
    39bc:	01412483          	lw	s1,20(sp)
    39c0:	01012903          	lw	s2,16(sp)
    39c4:	00c12983          	lw	s3,12(sp)
    39c8:	00812a03          	lw	s4,8(sp)
    39cc:	02010113          	add	sp,sp,32
    39d0:	00008067          	ret

000039d4 <scheduler>:
{
    39d4:	fe010113          	add	sp,sp,-32
    39d8:	00812c23          	sw	s0,24(sp)
    39dc:	00112e23          	sw	ra,28(sp)
    39e0:	00912a23          	sw	s1,20(sp)
    39e4:	01212823          	sw	s2,16(sp)
    39e8:	01312623          	sw	s3,12(sp)
    39ec:	01412423          	sw	s4,8(sp)
    39f0:	01512223          	sw	s5,4(sp)
    39f4:	01612023          	sw	s6,0(sp)
    39f8:	02010413          	add	s0,sp,32
    39fc:	00020713          	mv	a4,tp
  c->proc = 0;
    3a00:	00471793          	sll	a5,a4,0x4
    3a04:	00e787b3          	add	a5,a5,a4
    3a08:	00012a97          	auipc	s5,0x12
    3a0c:	ab0a8a93          	add	s5,s5,-1360 # 154b8 <cpus>
    3a10:	00279793          	sll	a5,a5,0x2
    3a14:	00fa8a33          	add	s4,s5,a5
        swtch(&c->scheduler, &p->context);
    3a18:	00478793          	add	a5,a5,4
  c->proc = 0;
    3a1c:	000a2023          	sw	zero,0(s4)
        swtch(&c->scheduler, &p->context);
    3a20:	00fa8ab3          	add	s5,s5,a5
    3a24:	00015997          	auipc	s3,0x15
    3a28:	cc098993          	add	s3,s3,-832 # 186e4 <tickslock>
      if(p->state == RUNNABLE) {
    3a2c:	00200913          	li	s2,2
        p->state = RUNNING;
    3a30:	00300b13          	li	s6,3
  asm volatile("csrr %0, sie" : "=r" (x) );
    3a34:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    3a38:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    3a3c:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3a40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    3a44:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    3a48:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    3a4c:	00012497          	auipc	s1,0x12
    3a50:	c9848493          	add	s1,s1,-872 # 156e4 <proc>
      acquire(&p->lock);
    3a54:	00048513          	mv	a0,s1
    3a58:	ffffd097          	auipc	ra,0xffffd
    3a5c:	718080e7          	jalr	1816(ra) # 1170 <acquire>
      if(p->state == RUNNABLE) {
    3a60:	00c4a783          	lw	a5,12(s1)
      release(&p->lock);
    3a64:	00048513          	mv	a0,s1
      if(p->state == RUNNABLE) {
    3a68:	03278663          	beq	a5,s2,3a94 <scheduler+0xc0>
    for(p = proc; p < &proc[NPROC]; p++) {
    3a6c:	0c048493          	add	s1,s1,192
      release(&p->lock);
    3a70:	ffffe097          	auipc	ra,0xffffe
    3a74:	88c080e7          	jalr	-1908(ra) # 12fc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    3a78:	fb348ee3          	beq	s1,s3,3a34 <scheduler+0x60>
      acquire(&p->lock);
    3a7c:	00048513          	mv	a0,s1
    3a80:	ffffd097          	auipc	ra,0xffffd
    3a84:	6f0080e7          	jalr	1776(ra) # 1170 <acquire>
      if(p->state == RUNNABLE) {
    3a88:	00c4a783          	lw	a5,12(s1)
      release(&p->lock);
    3a8c:	00048513          	mv	a0,s1
      if(p->state == RUNNABLE) {
    3a90:	fd279ee3          	bne	a5,s2,3a6c <scheduler+0x98>
        swtch(&c->scheduler, &p->context);
    3a94:	03448593          	add	a1,s1,52
    3a98:	000a8513          	mv	a0,s5
        p->state = RUNNING;
    3a9c:	0164a623          	sw	s6,12(s1)
        c->proc = p;
    3aa0:	009a2023          	sw	s1,0(s4)
        swtch(&c->scheduler, &p->context);
    3aa4:	00001097          	auipc	ra,0x1
    3aa8:	ac8080e7          	jalr	-1336(ra) # 456c <swtch>
      release(&p->lock);
    3aac:	00048513          	mv	a0,s1
    for(p = proc; p < &proc[NPROC]; p++) {
    3ab0:	0c048493          	add	s1,s1,192
        c->proc = 0;
    3ab4:	000a2023          	sw	zero,0(s4)
      release(&p->lock);
    3ab8:	ffffe097          	auipc	ra,0xffffe
    3abc:	844080e7          	jalr	-1980(ra) # 12fc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    3ac0:	f9349ae3          	bne	s1,s3,3a54 <scheduler+0x80>
    3ac4:	f71ff06f          	j	3a34 <scheduler+0x60>

00003ac8 <sched>:
{
    3ac8:	fe010113          	add	sp,sp,-32
    3acc:	00812c23          	sw	s0,24(sp)
    3ad0:	00112e23          	sw	ra,28(sp)
    3ad4:	00912a23          	sw	s1,20(sp)
    3ad8:	01212823          	sw	s2,16(sp)
    3adc:	01312623          	sw	s3,12(sp)
    3ae0:	02010413          	add	s0,sp,32
  push_off();
    3ae4:	ffffe097          	auipc	ra,0xffffe
    3ae8:	aa4080e7          	jalr	-1372(ra) # 1588 <push_off>
  asm volatile("mv %0, tp" : "=r" (x) );
    3aec:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    3af0:	00471793          	sll	a5,a4,0x4
    3af4:	00e787b3          	add	a5,a5,a4
    3af8:	00279793          	sll	a5,a5,0x2
    3afc:	00012497          	auipc	s1,0x12
    3b00:	9bc48493          	add	s1,s1,-1604 # 154b8 <cpus>
    3b04:	00f487b3          	add	a5,s1,a5
    3b08:	0007a903          	lw	s2,0(a5)
  pop_off();
    3b0c:	ffffe097          	auipc	ra,0xffffe
    3b10:	af0080e7          	jalr	-1296(ra) # 15fc <pop_off>
  if(!holding(&p->lock))
    3b14:	00090513          	mv	a0,s2
    3b18:	ffffe097          	auipc	ra,0xffffe
    3b1c:	960080e7          	jalr	-1696(ra) # 1478 <holding>
    3b20:	0a050663          	beqz	a0,3bcc <sched+0x104>
    3b24:	00020713          	mv	a4,tp
  if(mycpu()->noff != 1)
    3b28:	00471793          	sll	a5,a4,0x4
    3b2c:	00e787b3          	add	a5,a5,a4
    3b30:	00279793          	sll	a5,a5,0x2
    3b34:	00f487b3          	add	a5,s1,a5
    3b38:	03c7a703          	lw	a4,60(a5)
    3b3c:	00100793          	li	a5,1
    3b40:	0af71e63          	bne	a4,a5,3bfc <sched+0x134>
  if(p->state == RUNNING)
    3b44:	00c92703          	lw	a4,12(s2)
    3b48:	00300793          	li	a5,3
    3b4c:	0af70063          	beq	a4,a5,3bec <sched+0x124>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3b50:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    3b54:	0027f793          	and	a5,a5,2
  if(intr_get())
    3b58:	08079263          	bnez	a5,3bdc <sched+0x114>
  asm volatile("mv %0, tp" : "=r" (x) );
    3b5c:	00020713          	mv	a4,tp
  intena = mycpu()->intena;
    3b60:	00471793          	sll	a5,a4,0x4
    3b64:	00e787b3          	add	a5,a5,a4
    3b68:	00279793          	sll	a5,a5,0x2
    3b6c:	00f487b3          	add	a5,s1,a5
    3b70:	0407a983          	lw	s3,64(a5)
    3b74:	00020793          	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    3b78:	00479593          	sll	a1,a5,0x4
    3b7c:	00f585b3          	add	a1,a1,a5
    3b80:	00259593          	sll	a1,a1,0x2
    3b84:	00458593          	add	a1,a1,4 # ffffe004 <end+0xfffd9ff0>
    3b88:	00b485b3          	add	a1,s1,a1
    3b8c:	03490513          	add	a0,s2,52
    3b90:	00001097          	auipc	ra,0x1
    3b94:	9dc080e7          	jalr	-1572(ra) # 456c <swtch>
    3b98:	00020713          	mv	a4,tp
  mycpu()->intena = intena;
    3b9c:	00471793          	sll	a5,a4,0x4
    3ba0:	00e787b3          	add	a5,a5,a4
}
    3ba4:	01c12083          	lw	ra,28(sp)
    3ba8:	01812403          	lw	s0,24(sp)
  mycpu()->intena = intena;
    3bac:	00279793          	sll	a5,a5,0x2
    3bb0:	00f484b3          	add	s1,s1,a5
    3bb4:	0534a023          	sw	s3,64(s1)
}
    3bb8:	01012903          	lw	s2,16(sp)
    3bbc:	01412483          	lw	s1,20(sp)
    3bc0:	00c12983          	lw	s3,12(sp)
    3bc4:	02010113          	add	sp,sp,32
    3bc8:	00008067          	ret
    panic("sched p->lock");
    3bcc:	00008517          	auipc	a0,0x8
    3bd0:	84c50513          	add	a0,a0,-1972 # b418 <main+0x2e8>
    3bd4:	ffffd097          	auipc	ra,0xffffd
    3bd8:	b00080e7          	jalr	-1280(ra) # 6d4 <panic>
    panic("sched interruptible");
    3bdc:	00008517          	auipc	a0,0x8
    3be0:	86850513          	add	a0,a0,-1944 # b444 <main+0x314>
    3be4:	ffffd097          	auipc	ra,0xffffd
    3be8:	af0080e7          	jalr	-1296(ra) # 6d4 <panic>
    panic("sched running");
    3bec:	00008517          	auipc	a0,0x8
    3bf0:	84850513          	add	a0,a0,-1976 # b434 <main+0x304>
    3bf4:	ffffd097          	auipc	ra,0xffffd
    3bf8:	ae0080e7          	jalr	-1312(ra) # 6d4 <panic>
    panic("sched locks");
    3bfc:	00008517          	auipc	a0,0x8
    3c00:	82c50513          	add	a0,a0,-2004 # b428 <main+0x2f8>
    3c04:	ffffd097          	auipc	ra,0xffffd
    3c08:	ad0080e7          	jalr	-1328(ra) # 6d4 <panic>

00003c0c <exit>:
{
    3c0c:	fe010113          	add	sp,sp,-32
    3c10:	00812c23          	sw	s0,24(sp)
    3c14:	01512223          	sw	s5,4(sp)
    3c18:	00112e23          	sw	ra,28(sp)
    3c1c:	00912a23          	sw	s1,20(sp)
    3c20:	01212823          	sw	s2,16(sp)
    3c24:	01312623          	sw	s3,12(sp)
    3c28:	01412423          	sw	s4,8(sp)
    3c2c:	02010413          	add	s0,sp,32
    3c30:	00050a93          	mv	s5,a0
  push_off();
    3c34:	ffffe097          	auipc	ra,0xffffe
    3c38:	954080e7          	jalr	-1708(ra) # 1588 <push_off>
    3c3c:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    3c40:	00471793          	sll	a5,a4,0x4
    3c44:	00e787b3          	add	a5,a5,a4
    3c48:	00279793          	sll	a5,a5,0x2
    3c4c:	00012717          	auipc	a4,0x12
    3c50:	86c70713          	add	a4,a4,-1940 # 154b8 <cpus>
    3c54:	00f707b3          	add	a5,a4,a5
    3c58:	0007a983          	lw	s3,0(a5)
  if(p == initproc)
    3c5c:	00020a17          	auipc	s4,0x20
    3c60:	3b0a0a13          	add	s4,s4,944 # 2400c <initproc>
  pop_off();
    3c64:	ffffe097          	auipc	ra,0xffffe
    3c68:	998080e7          	jalr	-1640(ra) # 15fc <pop_off>
  if(p == initproc)
    3c6c:	000a2783          	lw	a5,0(s4)
    3c70:	06c98493          	add	s1,s3,108
    3c74:	0ac98913          	add	s2,s3,172
    3c78:	0f378063          	beq	a5,s3,3d58 <exit+0x14c>
    if(p->ofile[fd]){
    3c7c:	0004a503          	lw	a0,0(s1)
    3c80:	00050863          	beqz	a0,3c90 <exit+0x84>
      fileclose(f);
    3c84:	00004097          	auipc	ra,0x4
    3c88:	ec4080e7          	jalr	-316(ra) # 7b48 <fileclose>
      p->ofile[fd] = 0;
    3c8c:	0004a023          	sw	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    3c90:	00448493          	add	s1,s1,4
    3c94:	ff2494e3          	bne	s1,s2,3c7c <exit+0x70>
  begin_op();
    3c98:	00003097          	auipc	ra,0x3
    3c9c:	7ac080e7          	jalr	1964(ra) # 7444 <begin_op>
  iput(p->cwd);
    3ca0:	0ac9a503          	lw	a0,172(s3)
    3ca4:	00002097          	auipc	ra,0x2
    3ca8:	3e0080e7          	jalr	992(ra) # 6084 <iput>
  end_op();
    3cac:	00004097          	auipc	ra,0x4
    3cb0:	834080e7          	jalr	-1996(ra) # 74e0 <end_op>
  acquire(&initproc->lock);
    3cb4:	000a2503          	lw	a0,0(s4)
  p->cwd = 0;
    3cb8:	0a09a623          	sw	zero,172(s3)
  acquire(&initproc->lock);
    3cbc:	ffffd097          	auipc	ra,0xffffd
    3cc0:	4b4080e7          	jalr	1204(ra) # 1170 <acquire>
  wakeup1(initproc);
    3cc4:	000a2503          	lw	a0,0(s4)
    3cc8:	fffff097          	auipc	ra,0xfffff
    3ccc:	45c080e7          	jalr	1116(ra) # 3124 <wakeup1>
  release(&initproc->lock);
    3cd0:	000a2503          	lw	a0,0(s4)
    3cd4:	ffffd097          	auipc	ra,0xffffd
    3cd8:	628080e7          	jalr	1576(ra) # 12fc <release>
  acquire(&p->lock);
    3cdc:	00098513          	mv	a0,s3
    3ce0:	ffffd097          	auipc	ra,0xffffd
    3ce4:	490080e7          	jalr	1168(ra) # 1170 <acquire>
  struct proc *original_parent = p->parent;
    3ce8:	0109a483          	lw	s1,16(s3)
  release(&p->lock);
    3cec:	00098513          	mv	a0,s3
    3cf0:	ffffd097          	auipc	ra,0xffffd
    3cf4:	60c080e7          	jalr	1548(ra) # 12fc <release>
  acquire(&original_parent->lock);
    3cf8:	00048513          	mv	a0,s1
    3cfc:	ffffd097          	auipc	ra,0xffffd
    3d00:	474080e7          	jalr	1140(ra) # 1170 <acquire>
  acquire(&p->lock);
    3d04:	00098513          	mv	a0,s3
    3d08:	ffffd097          	auipc	ra,0xffffd
    3d0c:	468080e7          	jalr	1128(ra) # 1170 <acquire>
  reparent(p);
    3d10:	00098513          	mv	a0,s3
    3d14:	00000097          	auipc	ra,0x0
    3d18:	c28080e7          	jalr	-984(ra) # 393c <reparent>
  wakeup1(original_parent);
    3d1c:	00048513          	mv	a0,s1
    3d20:	fffff097          	auipc	ra,0xfffff
    3d24:	404080e7          	jalr	1028(ra) # 3124 <wakeup1>
  p->state = ZOMBIE;
    3d28:	00400793          	li	a5,4
  release(&original_parent->lock);
    3d2c:	00048513          	mv	a0,s1
  p->state = ZOMBIE;
    3d30:	00f9a623          	sw	a5,12(s3)
  p->xstate = status;
    3d34:	0159ae23          	sw	s5,28(s3)
  release(&original_parent->lock);
    3d38:	ffffd097          	auipc	ra,0xffffd
    3d3c:	5c4080e7          	jalr	1476(ra) # 12fc <release>
  sched();
    3d40:	00000097          	auipc	ra,0x0
    3d44:	d88080e7          	jalr	-632(ra) # 3ac8 <sched>
  panic("zombie exit");
    3d48:	00007517          	auipc	a0,0x7
    3d4c:	72050513          	add	a0,a0,1824 # b468 <main+0x338>
    3d50:	ffffd097          	auipc	ra,0xffffd
    3d54:	984080e7          	jalr	-1660(ra) # 6d4 <panic>
    panic("init exiting");
    3d58:	00007517          	auipc	a0,0x7
    3d5c:	70050513          	add	a0,a0,1792 # b458 <main+0x328>
    3d60:	ffffd097          	auipc	ra,0xffffd
    3d64:	974080e7          	jalr	-1676(ra) # 6d4 <panic>

00003d68 <wait>:
{
    3d68:	fe010113          	add	sp,sp,-32
    3d6c:	00812c23          	sw	s0,24(sp)
    3d70:	01512223          	sw	s5,4(sp)
    3d74:	00112e23          	sw	ra,28(sp)
    3d78:	00912a23          	sw	s1,20(sp)
    3d7c:	01212823          	sw	s2,16(sp)
    3d80:	01312623          	sw	s3,12(sp)
    3d84:	01412423          	sw	s4,8(sp)
    3d88:	01612023          	sw	s6,0(sp)
    3d8c:	02010413          	add	s0,sp,32
    3d90:	00050a93          	mv	s5,a0
  push_off();
    3d94:	ffffd097          	auipc	ra,0xffffd
    3d98:	7f4080e7          	jalr	2036(ra) # 1588 <push_off>
    3d9c:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    3da0:	00471793          	sll	a5,a4,0x4
    3da4:	00e787b3          	add	a5,a5,a4
    3da8:	00279793          	sll	a5,a5,0x2
    3dac:	00011b17          	auipc	s6,0x11
    3db0:	70cb0b13          	add	s6,s6,1804 # 154b8 <cpus>
    3db4:	00fb07b3          	add	a5,s6,a5
    3db8:	0007a903          	lw	s2,0(a5)
  pop_off();
    3dbc:	ffffe097          	auipc	ra,0xffffe
    3dc0:	840080e7          	jalr	-1984(ra) # 15fc <pop_off>
        if(np->state == ZOMBIE){
    3dc4:	00400a13          	li	s4,4
  acquire(&p->lock);
    3dc8:	00090513          	mv	a0,s2
    for(np = proc; np < &proc[NPROC]; np++){
    3dcc:	00015997          	auipc	s3,0x15
    3dd0:	91898993          	add	s3,s3,-1768 # 186e4 <tickslock>
  acquire(&p->lock);
    3dd4:	ffffd097          	auipc	ra,0xffffd
    3dd8:	39c080e7          	jalr	924(ra) # 1170 <acquire>
    havekids = 0;
    3ddc:	00000713          	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    3de0:	00012497          	auipc	s1,0x12
    3de4:	90448493          	add	s1,s1,-1788 # 156e4 <proc>
    3de8:	00c0006f          	j	3df4 <wait+0x8c>
    3dec:	0c048493          	add	s1,s1,192
    3df0:	03348c63          	beq	s1,s3,3e28 <wait+0xc0>
      if(np->parent == p){
    3df4:	0104a783          	lw	a5,16(s1)
    3df8:	ff279ae3          	bne	a5,s2,3dec <wait+0x84>
        acquire(&np->lock);
    3dfc:	00048513          	mv	a0,s1
    3e00:	ffffd097          	auipc	ra,0xffffd
    3e04:	370080e7          	jalr	880(ra) # 1170 <acquire>
        if(np->state == ZOMBIE){
    3e08:	00c4a783          	lw	a5,12(s1)
        release(&np->lock);
    3e0c:	00048513          	mv	a0,s1
        if(np->state == ZOMBIE){
    3e10:	09478e63          	beq	a5,s4,3eac <wait+0x144>
        release(&np->lock);
    3e14:	ffffd097          	auipc	ra,0xffffd
    3e18:	4e8080e7          	jalr	1256(ra) # 12fc <release>
    for(np = proc; np < &proc[NPROC]; np++){
    3e1c:	0c048493          	add	s1,s1,192
        havekids = 1;
    3e20:	00100713          	li	a4,1
    for(np = proc; np < &proc[NPROC]; np++){
    3e24:	fd3498e3          	bne	s1,s3,3df4 <wait+0x8c>
    if(!havekids || p->killed){
    3e28:	18070a63          	beqz	a4,3fbc <wait+0x254>
    3e2c:	01892783          	lw	a5,24(s2)
    3e30:	18079663          	bnez	a5,3fbc <wait+0x254>
  push_off();
    3e34:	ffffd097          	auipc	ra,0xffffd
    3e38:	754080e7          	jalr	1876(ra) # 1588 <push_off>
    3e3c:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    3e40:	00471793          	sll	a5,a4,0x4
    3e44:	00e787b3          	add	a5,a5,a4
    3e48:	00279793          	sll	a5,a5,0x2
    3e4c:	00fb07b3          	add	a5,s6,a5
    3e50:	0007a483          	lw	s1,0(a5)
  pop_off();
    3e54:	ffffd097          	auipc	ra,0xffffd
    3e58:	7a8080e7          	jalr	1960(ra) # 15fc <pop_off>
  if(lk != &p->lock){  //DOC: sleeplock0
    3e5c:	12990863          	beq	s2,s1,3f8c <wait+0x224>
    acquire(&p->lock);  //DOC: sleeplock1
    3e60:	00048513          	mv	a0,s1
    3e64:	ffffd097          	auipc	ra,0xffffd
    3e68:	30c080e7          	jalr	780(ra) # 1170 <acquire>
    release(lk);
    3e6c:	00090513          	mv	a0,s2
    3e70:	ffffd097          	auipc	ra,0xffffd
    3e74:	48c080e7          	jalr	1164(ra) # 12fc <release>
  p->state = SLEEPING;
    3e78:	00100793          	li	a5,1
    3e7c:	00f4a623          	sw	a5,12(s1)
  p->chan = chan;
    3e80:	0124aa23          	sw	s2,20(s1)
  sched();
    3e84:	00000097          	auipc	ra,0x0
    3e88:	c44080e7          	jalr	-956(ra) # 3ac8 <sched>
    release(&p->lock);
    3e8c:	00048513          	mv	a0,s1
  p->chan = 0;
    3e90:	0004aa23          	sw	zero,20(s1)
    release(&p->lock);
    3e94:	ffffd097          	auipc	ra,0xffffd
    3e98:	468080e7          	jalr	1128(ra) # 12fc <release>
    acquire(lk);
    3e9c:	00090513          	mv	a0,s2
    3ea0:	ffffd097          	auipc	ra,0xffffd
    3ea4:	2d0080e7          	jalr	720(ra) # 1170 <acquire>
    3ea8:	f35ff06f          	j	3ddc <wait+0x74>
          pid = np->pid;
    3eac:	0204aa03          	lw	s4,32(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    3eb0:	020a8063          	beqz	s5,3ed0 <wait+0x168>
    3eb4:	02c92503          	lw	a0,44(s2)
    3eb8:	00400693          	li	a3,4
    3ebc:	01c48613          	add	a2,s1,28
    3ec0:	000a8593          	mv	a1,s5
    3ec4:	fffff097          	auipc	ra,0xfffff
    3ec8:	e84080e7          	jalr	-380(ra) # 2d48 <copyout>
    3ecc:	10054263          	bltz	a0,3fd0 <wait+0x268>
  if(p->tf)
    3ed0:	0304a503          	lw	a0,48(s1)
    3ed4:	00050663          	beqz	a0,3ee0 <wait+0x178>
    kfree((void*)p->tf);
    3ed8:	ffffd097          	auipc	ra,0xffffd
    3edc:	14c080e7          	jalr	332(ra) # 1024 <kfree>
  if(p->pagetable)
    3ee0:	02c4a983          	lw	s3,44(s1)
  p->tf = 0;
    3ee4:	0204a823          	sw	zero,48(s1)
  if(p->pagetable)
    3ee8:	02098e63          	beqz	s3,3f24 <wait+0x1bc>
    proc_freepagetable(p->pagetable, p->sz);
    3eec:	0284aa83          	lw	s5,40(s1)
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    3ef0:	00000693          	li	a3,0
    3ef4:	00001637          	lui	a2,0x1
    3ef8:	fffff5b7          	lui	a1,0xfffff
    3efc:	00098513          	mv	a0,s3
    3f00:	ffffe097          	auipc	ra,0xffffe
    3f04:	790080e7          	jalr	1936(ra) # 2690 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    3f08:	00000693          	li	a3,0
    3f0c:	00001637          	lui	a2,0x1
    3f10:	ffffe5b7          	lui	a1,0xffffe
    3f14:	00098513          	mv	a0,s3
    3f18:	ffffe097          	auipc	ra,0xffffe
    3f1c:	778080e7          	jalr	1912(ra) # 2690 <uvmunmap>
  if(sz > 0)
    3f20:	080a9463          	bnez	s5,3fa8 <wait+0x240>
          release(&np->lock);
    3f24:	00048513          	mv	a0,s1
  p->pagetable = 0;
    3f28:	0204a623          	sw	zero,44(s1)
  p->sz = 0;
    3f2c:	0204a423          	sw	zero,40(s1)
  p->pid = 0;
    3f30:	0204a023          	sw	zero,32(s1)
  p->parent = 0;
    3f34:	0004a823          	sw	zero,16(s1)
  p->name[0] = 0;
    3f38:	0a048823          	sb	zero,176(s1)
  p->chan = 0;
    3f3c:	0004aa23          	sw	zero,20(s1)
  p->killed = 0;
    3f40:	0004ac23          	sw	zero,24(s1)
  p->xstate = 0;
    3f44:	0004ae23          	sw	zero,28(s1)
  p->state = UNUSED;
    3f48:	0004a623          	sw	zero,12(s1)
          release(&np->lock);
    3f4c:	ffffd097          	auipc	ra,0xffffd
    3f50:	3b0080e7          	jalr	944(ra) # 12fc <release>
          release(&p->lock);
    3f54:	00090513          	mv	a0,s2
    3f58:	ffffd097          	auipc	ra,0xffffd
    3f5c:	3a4080e7          	jalr	932(ra) # 12fc <release>
}
    3f60:	01c12083          	lw	ra,28(sp)
    3f64:	01812403          	lw	s0,24(sp)
    3f68:	01412483          	lw	s1,20(sp)
    3f6c:	01012903          	lw	s2,16(sp)
    3f70:	00c12983          	lw	s3,12(sp)
    3f74:	00412a83          	lw	s5,4(sp)
    3f78:	00012b03          	lw	s6,0(sp)
    3f7c:	000a0513          	mv	a0,s4
    3f80:	00812a03          	lw	s4,8(sp)
    3f84:	02010113          	add	sp,sp,32
    3f88:	00008067          	ret
  p->state = SLEEPING;
    3f8c:	00100793          	li	a5,1
  p->chan = chan;
    3f90:	01292a23          	sw	s2,20(s2)
  p->state = SLEEPING;
    3f94:	00f92623          	sw	a5,12(s2)
  sched();
    3f98:	00000097          	auipc	ra,0x0
    3f9c:	b30080e7          	jalr	-1232(ra) # 3ac8 <sched>
  p->chan = 0;
    3fa0:	00092a23          	sw	zero,20(s2)
  if(lk != &p->lock){
    3fa4:	e39ff06f          	j	3ddc <wait+0x74>
    uvmfree(pagetable, sz);
    3fa8:	000a8593          	mv	a1,s5
    3fac:	00098513          	mv	a0,s3
    3fb0:	fffff097          	auipc	ra,0xfffff
    3fb4:	b00080e7          	jalr	-1280(ra) # 2ab0 <uvmfree>
    3fb8:	f6dff06f          	j	3f24 <wait+0x1bc>
      release(&p->lock);
    3fbc:	00090513          	mv	a0,s2
    3fc0:	ffffd097          	auipc	ra,0xffffd
    3fc4:	33c080e7          	jalr	828(ra) # 12fc <release>
            return -1;
    3fc8:	fff00a13          	li	s4,-1
    3fcc:	f95ff06f          	j	3f60 <wait+0x1f8>
            release(&np->lock);
    3fd0:	00048513          	mv	a0,s1
    3fd4:	ffffd097          	auipc	ra,0xffffd
    3fd8:	328080e7          	jalr	808(ra) # 12fc <release>
            release(&p->lock);
    3fdc:	00090513          	mv	a0,s2
    3fe0:	ffffd097          	auipc	ra,0xffffd
    3fe4:	31c080e7          	jalr	796(ra) # 12fc <release>
            return -1;
    3fe8:	fff00a13          	li	s4,-1
    3fec:	f75ff06f          	j	3f60 <wait+0x1f8>

00003ff0 <yield>:
{
    3ff0:	ff010113          	add	sp,sp,-16
    3ff4:	00812423          	sw	s0,8(sp)
    3ff8:	00112623          	sw	ra,12(sp)
    3ffc:	00912223          	sw	s1,4(sp)
    4000:	01010413          	add	s0,sp,16
  push_off();
    4004:	ffffd097          	auipc	ra,0xffffd
    4008:	584080e7          	jalr	1412(ra) # 1588 <push_off>
    400c:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    4010:	00471793          	sll	a5,a4,0x4
    4014:	00e787b3          	add	a5,a5,a4
    4018:	00279793          	sll	a5,a5,0x2
    401c:	00011717          	auipc	a4,0x11
    4020:	49c70713          	add	a4,a4,1180 # 154b8 <cpus>
    4024:	00f707b3          	add	a5,a4,a5
    4028:	0007a483          	lw	s1,0(a5)
  pop_off();
    402c:	ffffd097          	auipc	ra,0xffffd
    4030:	5d0080e7          	jalr	1488(ra) # 15fc <pop_off>
  acquire(&p->lock);
    4034:	00048513          	mv	a0,s1
    4038:	ffffd097          	auipc	ra,0xffffd
    403c:	138080e7          	jalr	312(ra) # 1170 <acquire>
  p->state = RUNNABLE;
    4040:	00200793          	li	a5,2
    4044:	00f4a623          	sw	a5,12(s1)
  sched();
    4048:	00000097          	auipc	ra,0x0
    404c:	a80080e7          	jalr	-1408(ra) # 3ac8 <sched>
}
    4050:	00812403          	lw	s0,8(sp)
    4054:	00c12083          	lw	ra,12(sp)
  release(&p->lock);
    4058:	00048513          	mv	a0,s1
}
    405c:	00412483          	lw	s1,4(sp)
    4060:	01010113          	add	sp,sp,16
  release(&p->lock);
    4064:	ffffd317          	auipc	t1,0xffffd
    4068:	29830067          	jr	664(t1) # 12fc <release>

0000406c <sleep>:
{
    406c:	fe010113          	add	sp,sp,-32
    4070:	00812c23          	sw	s0,24(sp)
    4074:	01212823          	sw	s2,16(sp)
    4078:	01312623          	sw	s3,12(sp)
    407c:	00112e23          	sw	ra,28(sp)
    4080:	00912a23          	sw	s1,20(sp)
    4084:	02010413          	add	s0,sp,32
    4088:	00050993          	mv	s3,a0
    408c:	00058913          	mv	s2,a1
  push_off();
    4090:	ffffd097          	auipc	ra,0xffffd
    4094:	4f8080e7          	jalr	1272(ra) # 1588 <push_off>
    4098:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    409c:	00471793          	sll	a5,a4,0x4
    40a0:	00e787b3          	add	a5,a5,a4
    40a4:	00279793          	sll	a5,a5,0x2
    40a8:	00011717          	auipc	a4,0x11
    40ac:	41070713          	add	a4,a4,1040 # 154b8 <cpus>
    40b0:	00f707b3          	add	a5,a4,a5
    40b4:	0007a483          	lw	s1,0(a5)
  pop_off();
    40b8:	ffffd097          	auipc	ra,0xffffd
    40bc:	544080e7          	jalr	1348(ra) # 15fc <pop_off>
  if(lk != &p->lock){  //DOC: sleeplock0
    40c0:	07248263          	beq	s1,s2,4124 <sleep+0xb8>
    acquire(&p->lock);  //DOC: sleeplock1
    40c4:	00048513          	mv	a0,s1
    40c8:	ffffd097          	auipc	ra,0xffffd
    40cc:	0a8080e7          	jalr	168(ra) # 1170 <acquire>
    release(lk);
    40d0:	00090513          	mv	a0,s2
    40d4:	ffffd097          	auipc	ra,0xffffd
    40d8:	228080e7          	jalr	552(ra) # 12fc <release>
  p->state = SLEEPING;
    40dc:	00100793          	li	a5,1
  p->chan = chan;
    40e0:	0134aa23          	sw	s3,20(s1)
  p->state = SLEEPING;
    40e4:	00f4a623          	sw	a5,12(s1)
  sched();
    40e8:	00000097          	auipc	ra,0x0
    40ec:	9e0080e7          	jalr	-1568(ra) # 3ac8 <sched>
    release(&p->lock);
    40f0:	00048513          	mv	a0,s1
  p->chan = 0;
    40f4:	0004aa23          	sw	zero,20(s1)
    release(&p->lock);
    40f8:	ffffd097          	auipc	ra,0xffffd
    40fc:	204080e7          	jalr	516(ra) # 12fc <release>
}
    4100:	01812403          	lw	s0,24(sp)
    4104:	01c12083          	lw	ra,28(sp)
    4108:	01412483          	lw	s1,20(sp)
    410c:	00c12983          	lw	s3,12(sp)
    acquire(lk);
    4110:	00090513          	mv	a0,s2
}
    4114:	01012903          	lw	s2,16(sp)
    4118:	02010113          	add	sp,sp,32
    acquire(lk);
    411c:	ffffd317          	auipc	t1,0xffffd
    4120:	05430067          	jr	84(t1) # 1170 <acquire>
  p->state = SLEEPING;
    4124:	00100793          	li	a5,1
  p->chan = chan;
    4128:	0134aa23          	sw	s3,20(s1)
  p->state = SLEEPING;
    412c:	00f4a623          	sw	a5,12(s1)
  sched();
    4130:	00000097          	auipc	ra,0x0
    4134:	998080e7          	jalr	-1640(ra) # 3ac8 <sched>
}
    4138:	01c12083          	lw	ra,28(sp)
    413c:	01812403          	lw	s0,24(sp)
  p->chan = 0;
    4140:	0004aa23          	sw	zero,20(s1)
}
    4144:	01012903          	lw	s2,16(sp)
    4148:	01412483          	lw	s1,20(sp)
    414c:	00c12983          	lw	s3,12(sp)
    4150:	02010113          	add	sp,sp,32
    4154:	00008067          	ret

00004158 <wakeup>:
{
    4158:	fe010113          	add	sp,sp,-32
    415c:	00812c23          	sw	s0,24(sp)
    4160:	00912a23          	sw	s1,20(sp)
    4164:	01212823          	sw	s2,16(sp)
    4168:	01312623          	sw	s3,12(sp)
    416c:	01412423          	sw	s4,8(sp)
    4170:	01512223          	sw	s5,4(sp)
    4174:	00112e23          	sw	ra,28(sp)
    4178:	02010413          	add	s0,sp,32
    417c:	00050a13          	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    4180:	00011497          	auipc	s1,0x11
    4184:	56448493          	add	s1,s1,1380 # 156e4 <proc>
    4188:	00014997          	auipc	s3,0x14
    418c:	55c98993          	add	s3,s3,1372 # 186e4 <tickslock>
    if(p->state == SLEEPING && p->chan == chan) {
    4190:	00100913          	li	s2,1
      p->state = RUNNABLE;
    4194:	00200a93          	li	s5,2
    4198:	0140006f          	j	41ac <wakeup+0x54>
  for(p = proc; p < &proc[NPROC]; p++) {
    419c:	0c048493          	add	s1,s1,192
    release(&p->lock);
    41a0:	ffffd097          	auipc	ra,0xffffd
    41a4:	15c080e7          	jalr	348(ra) # 12fc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    41a8:	03348c63          	beq	s1,s3,41e0 <wakeup+0x88>
    acquire(&p->lock);
    41ac:	00048513          	mv	a0,s1
    41b0:	ffffd097          	auipc	ra,0xffffd
    41b4:	fc0080e7          	jalr	-64(ra) # 1170 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    41b8:	00c4a783          	lw	a5,12(s1)
    release(&p->lock);
    41bc:	00048513          	mv	a0,s1
    if(p->state == SLEEPING && p->chan == chan) {
    41c0:	fd279ee3          	bne	a5,s2,419c <wakeup+0x44>
    41c4:	0144a783          	lw	a5,20(s1)
    41c8:	fd479ae3          	bne	a5,s4,419c <wakeup+0x44>
      p->state = RUNNABLE;
    41cc:	0154a623          	sw	s5,12(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    41d0:	0c048493          	add	s1,s1,192
    release(&p->lock);
    41d4:	ffffd097          	auipc	ra,0xffffd
    41d8:	128080e7          	jalr	296(ra) # 12fc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    41dc:	fd3498e3          	bne	s1,s3,41ac <wakeup+0x54>
}
    41e0:	01c12083          	lw	ra,28(sp)
    41e4:	01812403          	lw	s0,24(sp)
    41e8:	01412483          	lw	s1,20(sp)
    41ec:	01012903          	lw	s2,16(sp)
    41f0:	00c12983          	lw	s3,12(sp)
    41f4:	00812a03          	lw	s4,8(sp)
    41f8:	00412a83          	lw	s5,4(sp)
    41fc:	02010113          	add	sp,sp,32
    4200:	00008067          	ret

00004204 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    4204:	fe010113          	add	sp,sp,-32
    4208:	00812c23          	sw	s0,24(sp)
    420c:	00912a23          	sw	s1,20(sp)
    4210:	01212823          	sw	s2,16(sp)
    4214:	01312623          	sw	s3,12(sp)
    4218:	00112e23          	sw	ra,28(sp)
    421c:	02010413          	add	s0,sp,32
    4220:	00050913          	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    4224:	00011497          	auipc	s1,0x11
    4228:	4c048493          	add	s1,s1,1216 # 156e4 <proc>
    422c:	00014997          	auipc	s3,0x14
    4230:	4b898993          	add	s3,s3,1208 # 186e4 <tickslock>
    4234:	0140006f          	j	4248 <kill+0x44>
    4238:	0c048493          	add	s1,s1,192
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    423c:	ffffd097          	auipc	ra,0xffffd
    4240:	0c0080e7          	jalr	192(ra) # 12fc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    4244:	07348063          	beq	s1,s3,42a4 <kill+0xa0>
    acquire(&p->lock);
    4248:	00048513          	mv	a0,s1
    424c:	ffffd097          	auipc	ra,0xffffd
    4250:	f24080e7          	jalr	-220(ra) # 1170 <acquire>
    if(p->pid == pid){
    4254:	0204a783          	lw	a5,32(s1)
    release(&p->lock);
    4258:	00048513          	mv	a0,s1
    if(p->pid == pid){
    425c:	fd279ee3          	bne	a5,s2,4238 <kill+0x34>
      if(p->state == SLEEPING){
    4260:	00c4a703          	lw	a4,12(s1)
      p->killed = 1;
    4264:	00100793          	li	a5,1
    4268:	00f4ac23          	sw	a5,24(s1)
      if(p->state == SLEEPING){
    426c:	00f71663          	bne	a4,a5,4278 <kill+0x74>
        p->state = RUNNABLE;
    4270:	00200793          	li	a5,2
    4274:	00f4a623          	sw	a5,12(s1)
      release(&p->lock);
    4278:	00048513          	mv	a0,s1
    427c:	ffffd097          	auipc	ra,0xffffd
    4280:	080080e7          	jalr	128(ra) # 12fc <release>
  }
  return -1;
}
    4284:	01c12083          	lw	ra,28(sp)
    4288:	01812403          	lw	s0,24(sp)
    428c:	01412483          	lw	s1,20(sp)
    4290:	01012903          	lw	s2,16(sp)
    4294:	00c12983          	lw	s3,12(sp)
      return 0;
    4298:	00000513          	li	a0,0
}
    429c:	02010113          	add	sp,sp,32
    42a0:	00008067          	ret
    42a4:	01c12083          	lw	ra,28(sp)
    42a8:	01812403          	lw	s0,24(sp)
    42ac:	01412483          	lw	s1,20(sp)
    42b0:	01012903          	lw	s2,16(sp)
    42b4:	00c12983          	lw	s3,12(sp)
  return -1;
    42b8:	fff00513          	li	a0,-1
}
    42bc:	02010113          	add	sp,sp,32
    42c0:	00008067          	ret

000042c4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint32 dst, void *src, uint32 len)
{
    42c4:	fe010113          	add	sp,sp,-32
    42c8:	00812c23          	sw	s0,24(sp)
    42cc:	00912a23          	sw	s1,20(sp)
    42d0:	01212823          	sw	s2,16(sp)
    42d4:	01312623          	sw	s3,12(sp)
    42d8:	01412423          	sw	s4,8(sp)
    42dc:	00112e23          	sw	ra,28(sp)
    42e0:	01512223          	sw	s5,4(sp)
    42e4:	02010413          	add	s0,sp,32
    42e8:	00050a13          	mv	s4,a0
    42ec:	00058493          	mv	s1,a1
    42f0:	00060913          	mv	s2,a2
    42f4:	00068993          	mv	s3,a3
  push_off();
    42f8:	ffffd097          	auipc	ra,0xffffd
    42fc:	290080e7          	jalr	656(ra) # 1588 <push_off>
    4300:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    4304:	00471793          	sll	a5,a4,0x4
    4308:	00e787b3          	add	a5,a5,a4
    430c:	00279793          	sll	a5,a5,0x2
    4310:	00011717          	auipc	a4,0x11
    4314:	1a870713          	add	a4,a4,424 # 154b8 <cpus>
    4318:	00f707b3          	add	a5,a4,a5
    431c:	0007aa83          	lw	s5,0(a5)
  pop_off();
    4320:	ffffd097          	auipc	ra,0xffffd
    4324:	2dc080e7          	jalr	732(ra) # 15fc <pop_off>
  struct proc *p = myproc();
  if(user_dst){
    4328:	020a0e63          	beqz	s4,4364 <either_copyout+0xa0>
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    432c:	01812403          	lw	s0,24(sp)
    return copyout(p->pagetable, dst, src, len);
    4330:	02caa503          	lw	a0,44(s5)
}
    4334:	01c12083          	lw	ra,28(sp)
    4338:	00812a03          	lw	s4,8(sp)
    433c:	00412a83          	lw	s5,4(sp)
    return copyout(p->pagetable, dst, src, len);
    4340:	00098693          	mv	a3,s3
    4344:	00090613          	mv	a2,s2
}
    4348:	00c12983          	lw	s3,12(sp)
    434c:	01012903          	lw	s2,16(sp)
    return copyout(p->pagetable, dst, src, len);
    4350:	00048593          	mv	a1,s1
}
    4354:	01412483          	lw	s1,20(sp)
    4358:	02010113          	add	sp,sp,32
    return copyout(p->pagetable, dst, src, len);
    435c:	fffff317          	auipc	t1,0xfffff
    4360:	9ec30067          	jr	-1556(t1) # 2d48 <copyout>
    memmove((char *)dst, src, len);
    4364:	00098613          	mv	a2,s3
    4368:	00090593          	mv	a1,s2
    436c:	00048513          	mv	a0,s1
    4370:	ffffd097          	auipc	ra,0xffffd
    4374:	494080e7          	jalr	1172(ra) # 1804 <memmove>
}
    4378:	01c12083          	lw	ra,28(sp)
    437c:	01812403          	lw	s0,24(sp)
    4380:	01412483          	lw	s1,20(sp)
    4384:	01012903          	lw	s2,16(sp)
    4388:	00c12983          	lw	s3,12(sp)
    438c:	00812a03          	lw	s4,8(sp)
    4390:	00412a83          	lw	s5,4(sp)
    4394:	00000513          	li	a0,0
    4398:	02010113          	add	sp,sp,32
    439c:	00008067          	ret

000043a0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint32 src, uint32 len)
{
    43a0:	fe010113          	add	sp,sp,-32
    43a4:	00812c23          	sw	s0,24(sp)
    43a8:	00912a23          	sw	s1,20(sp)
    43ac:	01212823          	sw	s2,16(sp)
    43b0:	01312623          	sw	s3,12(sp)
    43b4:	01412423          	sw	s4,8(sp)
    43b8:	00112e23          	sw	ra,28(sp)
    43bc:	01512223          	sw	s5,4(sp)
    43c0:	02010413          	add	s0,sp,32
    43c4:	00050493          	mv	s1,a0
    43c8:	00058a13          	mv	s4,a1
    43cc:	00060913          	mv	s2,a2
    43d0:	00068993          	mv	s3,a3
  push_off();
    43d4:	ffffd097          	auipc	ra,0xffffd
    43d8:	1b4080e7          	jalr	436(ra) # 1588 <push_off>
    43dc:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    43e0:	00471793          	sll	a5,a4,0x4
    43e4:	00e787b3          	add	a5,a5,a4
    43e8:	00279793          	sll	a5,a5,0x2
    43ec:	00011717          	auipc	a4,0x11
    43f0:	0cc70713          	add	a4,a4,204 # 154b8 <cpus>
    43f4:	00f707b3          	add	a5,a4,a5
    43f8:	0007aa83          	lw	s5,0(a5)
  pop_off();
    43fc:	ffffd097          	auipc	ra,0xffffd
    4400:	200080e7          	jalr	512(ra) # 15fc <pop_off>
  struct proc *p = myproc();
  if(user_src){
    4404:	020a0e63          	beqz	s4,4440 <either_copyin+0xa0>
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    4408:	01812403          	lw	s0,24(sp)
    return copyin(p->pagetable, dst, src, len);
    440c:	02caa503          	lw	a0,44(s5)
}
    4410:	01c12083          	lw	ra,28(sp)
    4414:	00812a03          	lw	s4,8(sp)
    4418:	00412a83          	lw	s5,4(sp)
    return copyin(p->pagetable, dst, src, len);
    441c:	00098693          	mv	a3,s3
    4420:	00090613          	mv	a2,s2
}
    4424:	00c12983          	lw	s3,12(sp)
    4428:	01012903          	lw	s2,16(sp)
    return copyin(p->pagetable, dst, src, len);
    442c:	00048593          	mv	a1,s1
}
    4430:	01412483          	lw	s1,20(sp)
    4434:	02010113          	add	sp,sp,32
    return copyin(p->pagetable, dst, src, len);
    4438:	fffff317          	auipc	t1,0xfffff
    443c:	a2830067          	jr	-1496(t1) # 2e60 <copyin>
    memmove(dst, (char*)src, len);
    4440:	00098613          	mv	a2,s3
    4444:	00090593          	mv	a1,s2
    4448:	00048513          	mv	a0,s1
    444c:	ffffd097          	auipc	ra,0xffffd
    4450:	3b8080e7          	jalr	952(ra) # 1804 <memmove>
}
    4454:	01c12083          	lw	ra,28(sp)
    4458:	01812403          	lw	s0,24(sp)
    445c:	01412483          	lw	s1,20(sp)
    4460:	01012903          	lw	s2,16(sp)
    4464:	00c12983          	lw	s3,12(sp)
    4468:	00812a03          	lw	s4,8(sp)
    446c:	00412a83          	lw	s5,4(sp)
    4470:	00000513          	li	a0,0
    4474:	02010113          	add	sp,sp,32
    4478:	00008067          	ret

0000447c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    447c:	fd010113          	add	sp,sp,-48
    4480:	02812423          	sw	s0,40(sp)
    4484:	02912223          	sw	s1,36(sp)
    4488:	03212023          	sw	s2,32(sp)
    448c:	01312e23          	sw	s3,28(sp)
    4490:	01412c23          	sw	s4,24(sp)
    4494:	01512a23          	sw	s5,20(sp)
    4498:	01612823          	sw	s6,16(sp)
    449c:	01712623          	sw	s7,12(sp)
    44a0:	02112623          	sw	ra,44(sp)
    44a4:	03010413          	add	s0,sp,48
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    44a8:	00007517          	auipc	a0,0x7
    44ac:	e3050513          	add	a0,a0,-464 # b2d8 <main+0x1a8>
    44b0:	ffffc097          	auipc	ra,0xffffc
    44b4:	280080e7          	jalr	640(ra) # 730 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    44b8:	00011497          	auipc	s1,0x11
    44bc:	2dc48493          	add	s1,s1,732 # 15794 <proc+0xb0>
    44c0:	00014997          	auipc	s3,0x14
    44c4:	2d498993          	add	s3,s3,724 # 18794 <bcache+0xa4>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    44c8:	00400b93          	li	s7,4
      state = states[p->state];
    else
      state = "???";
    44cc:	00007a17          	auipc	s4,0x7
    44d0:	fa8a0a13          	add	s4,s4,-88 # b474 <main+0x344>
    printf("%d %s %s", p->pid, state, p->name);
    44d4:	00007917          	auipc	s2,0x7
    44d8:	fa490913          	add	s2,s2,-92 # b478 <main+0x348>
    printf("\n");
    44dc:	00007b17          	auipc	s6,0x7
    44e0:	dfcb0b13          	add	s6,s6,-516 # b2d8 <main+0x1a8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    44e4:	00007a97          	auipc	s5,0x7
    44e8:	3aca8a93          	add	s5,s5,940 # b890 <states.0>
    44ec:	0240006f          	j	4510 <procdump+0x94>
    printf("%d %s %s", p->pid, state, p->name);
    44f0:	f704a583          	lw	a1,-144(s1)
    44f4:	ffffc097          	auipc	ra,0xffffc
    44f8:	23c080e7          	jalr	572(ra) # 730 <printf>
    printf("\n");
    44fc:	000b0513          	mv	a0,s6
    4500:	ffffc097          	auipc	ra,0xffffc
    4504:	230080e7          	jalr	560(ra) # 730 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    4508:	0c048493          	add	s1,s1,192
    450c:	03348a63          	beq	s1,s3,4540 <procdump+0xc4>
    if(p->state == UNUSED)
    4510:	f5c4a783          	lw	a5,-164(s1)
    printf("%d %s %s", p->pid, state, p->name);
    4514:	00048693          	mv	a3,s1
    4518:	00090513          	mv	a0,s2
    if(p->state == UNUSED)
    451c:	fe0786e3          	beqz	a5,4508 <procdump+0x8c>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    4520:	00279713          	sll	a4,a5,0x2
    4524:	00ea8733          	add	a4,s5,a4
      state = "???";
    4528:	000a0613          	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    452c:	fcfbe2e3          	bltu	s7,a5,44f0 <procdump+0x74>
    4530:	00072603          	lw	a2,0(a4)
    4534:	fa061ee3          	bnez	a2,44f0 <procdump+0x74>
      state = "???";
    4538:	000a0613          	mv	a2,s4
    453c:	fb5ff06f          	j	44f0 <procdump+0x74>
  }
}
    4540:	02c12083          	lw	ra,44(sp)
    4544:	02812403          	lw	s0,40(sp)
    4548:	02412483          	lw	s1,36(sp)
    454c:	02012903          	lw	s2,32(sp)
    4550:	01c12983          	lw	s3,28(sp)
    4554:	01812a03          	lw	s4,24(sp)
    4558:	01412a83          	lw	s5,20(sp)
    455c:	01012b03          	lw	s6,16(sp)
    4560:	00c12b83          	lw	s7,12(sp)
    4564:	03010113          	add	sp,sp,48
    4568:	00008067          	ret

0000456c <swtch>:
    456c:	00152023          	sw	ra,0(a0)
    4570:	00252223          	sw	sp,4(a0)
    4574:	00852423          	sw	s0,8(a0)
    4578:	00952623          	sw	s1,12(a0)
    457c:	01252823          	sw	s2,16(a0)
    4580:	01352a23          	sw	s3,20(a0)
    4584:	01452c23          	sw	s4,24(a0)
    4588:	01552e23          	sw	s5,28(a0)
    458c:	03652023          	sw	s6,32(a0)
    4590:	03752223          	sw	s7,36(a0)
    4594:	03852423          	sw	s8,40(a0)
    4598:	03952623          	sw	s9,44(a0)
    459c:	03a52823          	sw	s10,48(a0)
    45a0:	03b52a23          	sw	s11,52(a0)
    45a4:	0005a083          	lw	ra,0(a1) # ffffe000 <end+0xfffd9fec>
    45a8:	0045a103          	lw	sp,4(a1)
    45ac:	0085a403          	lw	s0,8(a1)
    45b0:	00c5a483          	lw	s1,12(a1)
    45b4:	0105a903          	lw	s2,16(a1)
    45b8:	0145a983          	lw	s3,20(a1)
    45bc:	0185aa03          	lw	s4,24(a1)
    45c0:	01c5aa83          	lw	s5,28(a1)
    45c4:	0205ab03          	lw	s6,32(a1)
    45c8:	0245ab83          	lw	s7,36(a1)
    45cc:	0285ac03          	lw	s8,40(a1)
    45d0:	02c5ac83          	lw	s9,44(a1)
    45d4:	0305ad03          	lw	s10,48(a1)
    45d8:	0345ad83          	lw	s11,52(a1)
    45dc:	00008067          	ret

000045e0 <usertrap>:
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void
usertrap(void)
{
    45e0:	ff010113          	add	sp,sp,-16
    45e4:	00812423          	sw	s0,8(sp)
    45e8:	00112623          	sw	ra,12(sp)
    45ec:	00912223          	sw	s1,4(sp)
    45f0:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    45f4:	100027f3          	csrr	a5,sstatus
  int which_dev = 0;

  if((r_sstatus() & SSTATUS_SPP) != 0)
    45f8:	1007f793          	and	a5,a5,256
    45fc:	22079463          	bnez	a5,4824 <usertrap+0x244>
  asm volatile("csrw stvec, %0" : : "r" (x));
    4600:	00005797          	auipc	a5,0x5
    4604:	68078793          	add	a5,a5,1664 # 9c80 <kernelvec>
    4608:	10579073          	csrw	stvec,a5

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint32)kernelvec);

  struct proc *p = myproc();
    460c:	fffff097          	auipc	ra,0xfffff
    4610:	e18080e7          	jalr	-488(ra) # 3424 <myproc>
  
  // save user program counter.
  p->tf->epc = r_sepc();
    4614:	03052703          	lw	a4,48(a0)
  struct proc *p = myproc();
    4618:	00050493          	mv	s1,a0
  asm volatile("csrr %0, sepc" : "=r" (x) );
    461c:	141027f3          	csrr	a5,sepc
  p->tf->epc = r_sepc();
    4620:	00f72623          	sw	a5,12(a4)
  asm volatile("csrr %0, scause" : "=r" (x) );
    4624:	14202673          	csrr	a2,scause
  
  if(r_scause() == 8){
    4628:	00800693          	li	a3,8
    462c:	0ed61463          	bne	a2,a3,4714 <usertrap+0x134>
    // system call

    if(p->killed)
    4630:	01852683          	lw	a3,24(a0)
    4634:	14069463          	bnez	a3,477c <usertrap+0x19c>
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->tf->epc += 4;
    4638:	00478793          	add	a5,a5,4
    463c:	00f72623          	sw	a5,12(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    4640:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    4644:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    4648:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    464c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    4650:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    4654:	10079073          	csrw	sstatus,a5

    // an interrupt will change sstatus &c registers,
    // so don't enable until done with those registers.
    intr_on();

    syscall();
    4658:	00001097          	auipc	ra,0x1
    465c:	a04080e7          	jalr	-1532(ra) # 505c <syscall>
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    p->killed = 1;
  }

  if(p->killed)
    4660:	0184a783          	lw	a5,24(s1)
    4664:	10079463          	bnez	a5,476c <usertrap+0x18c>
// return to user space
//
void
usertrapret(void)
{
  struct proc *p = myproc();
    4668:	fffff097          	auipc	ra,0xfffff
    466c:	dbc080e7          	jalr	-580(ra) # 3424 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    4670:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    4674:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    4678:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    467c:	00007617          	auipc	a2,0x7
    4680:	98460613          	add	a2,a2,-1660 # b000 <trampoline>
    4684:	00006797          	auipc	a5,0x6
    4688:	97c78793          	add	a5,a5,-1668 # a000 <virtio_disk_rw+0x12c>
    468c:	40c787b3          	sub	a5,a5,a2
  asm volatile("csrw stvec, %0" : : "r" (x));
    4690:	10579073          	csrw	stvec,a5

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    4694:	03052783          	lw	a5,48(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    4698:	180025f3          	csrr	a1,satp
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    469c:	02452703          	lw	a4,36(a0)
    46a0:	000016b7          	lui	a3,0x1
  p->tf->kernel_satp = r_satp();         // kernel page table
    46a4:	00b7a023          	sw	a1,0(a5)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    46a8:	00d70733          	add	a4,a4,a3
    46ac:	00e7a223          	sw	a4,4(a5)
  p->tf->kernel_trap = (uint32)usertrap;
    46b0:	00000717          	auipc	a4,0x0
    46b4:	f3070713          	add	a4,a4,-208 # 45e0 <usertrap>
    46b8:	00e7a423          	sw	a4,8(a5)
  asm volatile("mv %0, tp" : "=r" (x) );
    46bc:	00020713          	mv	a4,tp
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    46c0:	00e7a823          	sw	a4,16(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    46c4:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    46c8:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    46cc:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    46d0:	10071073          	csrw	sstatus,a4
  asm volatile("csrw sepc, %0" : : "r" (x));
    46d4:	00c7a783          	lw	a5,12(a5)
    46d8:	14179073          	csrw	sepc,a5

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);

  // tell trampoline.S the user page table to switch to.
  uint32 satp = MAKE_SATP(p->pagetable);
    46dc:	02c52703          	lw	a4,44(a0)
}
    46e0:	00812403          	lw	s0,8(sp)
    46e4:	00c12083          	lw	ra,12(sp)
    46e8:	00412483          	lw	s1,4(sp)

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    46ec:	00007797          	auipc	a5,0x7
    46f0:	9b478793          	add	a5,a5,-1612 # b0a0 <userret>
  uint32 satp = MAKE_SATP(p->pagetable);
    46f4:	00c75713          	srl	a4,a4,0xc
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    46f8:	40c787b3          	sub	a5,a5,a2
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    46fc:	800005b7          	lui	a1,0x80000
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    4700:	40d787b3          	sub	a5,a5,a3
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    4704:	00b765b3          	or	a1,a4,a1
    4708:	ffffe537          	lui	a0,0xffffe
}
    470c:	01010113          	add	sp,sp,16
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    4710:	00078067          	jr	a5
  asm volatile("csrr %0, scause" : "=r" (x) );
    4714:	142027f3          	csrr	a5,scause
{
  uint32 scause = r_scause();

  // printf("devintr scause : %p\n", scause);

  if((scause & 0x80000000L) &&
    4718:	0007de63          	bgez	a5,4734 <usertrap+0x154>
     (scause & 0xff) == 9){
    471c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x80000000L) &&
    4720:	00900693          	li	a3,9
    4724:	06d70863          	beq	a4,a3,4794 <usertrap+0x1b4>
    } else {
    }

    // plic_complete(irq);
    return 1;
  } else if(scause == 0x80000001L){
    4728:	80000737          	lui	a4,0x80000
    472c:	00170713          	add	a4,a4,1 # 80000001 <end+0x7ffdbfed>
    4730:	06e78c63          	beq	a5,a4,47a8 <usertrap+0x1c8>
    4734:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    4738:	0204a603          	lw	a2,32(s1)
    473c:	00007517          	auipc	a0,0x7
    4740:	d9050513          	add	a0,a0,-624 # b4cc <main+0x39c>
    4744:	ffffc097          	auipc	ra,0xffffc
    4748:	fec080e7          	jalr	-20(ra) # 730 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    474c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    4750:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    4754:	00007517          	auipc	a0,0x7
    4758:	da450513          	add	a0,a0,-604 # b4f8 <main+0x3c8>
    475c:	ffffc097          	auipc	ra,0xffffc
    4760:	fd4080e7          	jalr	-44(ra) # 730 <printf>
    p->killed = 1;
    4764:	00100793          	li	a5,1
    4768:	00f4ac23          	sw	a5,24(s1)
    exit(-1);
    476c:	fff00513          	li	a0,-1
    4770:	fffff097          	auipc	ra,0xfffff
    4774:	49c080e7          	jalr	1180(ra) # 3c0c <exit>
  if(which_dev == 2)
    4778:	ef1ff06f          	j	4668 <usertrap+0x88>
      exit(-1);
    477c:	fff00513          	li	a0,-1
    4780:	fffff097          	auipc	ra,0xfffff
    4784:	48c080e7          	jalr	1164(ra) # 3c0c <exit>
    p->tf->epc += 4;
    4788:	0304a703          	lw	a4,48(s1)
    478c:	00c72783          	lw	a5,12(a4)
    4790:	ea9ff06f          	j	4638 <usertrap+0x58>
      uartintr();
    4794:	ffffc097          	auipc	ra,0xffffc
    4798:	644080e7          	jalr	1604(ra) # dd8 <uartintr>
  if(p->killed)
    479c:	0184a783          	lw	a5,24(s1)
    47a0:	ec0784e3          	beqz	a5,4668 <usertrap+0x88>
    47a4:	fc9ff06f          	j	476c <usertrap+0x18c>
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if(cpuid() == 0){
    47a8:	fffff097          	auipc	ra,0xfffff
    47ac:	c2c080e7          	jalr	-980(ra) # 33d4 <cpuid>
    47b0:	02050263          	beqz	a0,47d4 <usertrap+0x1f4>
  asm volatile("csrr %0, sip" : "=r" (x) );
    47b4:	144027f3          	csrr	a5,sip
      clockintr();
    }
    
    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);
    47b8:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    47bc:	14479073          	csrw	sip,a5
  if(p->killed)
    47c0:	0184a783          	lw	a5,24(s1)
    47c4:	04079863          	bnez	a5,4814 <usertrap+0x234>
    yield();
    47c8:	00000097          	auipc	ra,0x0
    47cc:	828080e7          	jalr	-2008(ra) # 3ff0 <yield>
    47d0:	e99ff06f          	j	4668 <usertrap+0x88>
  acquire(&tickslock);
    47d4:	00014517          	auipc	a0,0x14
    47d8:	f1050513          	add	a0,a0,-240 # 186e4 <tickslock>
    47dc:	ffffd097          	auipc	ra,0xffffd
    47e0:	994080e7          	jalr	-1644(ra) # 1170 <acquire>
  ticks++;
    47e4:	00020517          	auipc	a0,0x20
    47e8:	82c50513          	add	a0,a0,-2004 # 24010 <ticks>
    47ec:	00052783          	lw	a5,0(a0)
    47f0:	00178793          	add	a5,a5,1
    47f4:	00f52023          	sw	a5,0(a0)
  wakeup(&ticks);
    47f8:	00000097          	auipc	ra,0x0
    47fc:	960080e7          	jalr	-1696(ra) # 4158 <wakeup>
  release(&tickslock);
    4800:	00014517          	auipc	a0,0x14
    4804:	ee450513          	add	a0,a0,-284 # 186e4 <tickslock>
    4808:	ffffd097          	auipc	ra,0xffffd
    480c:	af4080e7          	jalr	-1292(ra) # 12fc <release>
}
    4810:	fa5ff06f          	j	47b4 <usertrap+0x1d4>
    exit(-1);
    4814:	fff00513          	li	a0,-1
    4818:	fffff097          	auipc	ra,0xfffff
    481c:	3f4080e7          	jalr	1012(ra) # 3c0c <exit>
  if(which_dev == 2)
    4820:	fa9ff06f          	j	47c8 <usertrap+0x1e8>
    panic("usertrap: not from user mode");
    4824:	00007517          	auipc	a0,0x7
    4828:	c8850513          	add	a0,a0,-888 # b4ac <main+0x37c>
    482c:	ffffc097          	auipc	ra,0xffffc
    4830:	ea8080e7          	jalr	-344(ra) # 6d4 <panic>

00004834 <trapinit>:
{
    4834:	ff010113          	add	sp,sp,-16
    4838:	00812623          	sw	s0,12(sp)
    483c:	01010413          	add	s0,sp,16
}
    4840:	00c12403          	lw	s0,12(sp)
  initlock(&tickslock, "time");
    4844:	00007597          	auipc	a1,0x7
    4848:	cd458593          	add	a1,a1,-812 # b518 <main+0x3e8>
    484c:	00014517          	auipc	a0,0x14
    4850:	e9850513          	add	a0,a0,-360 # 186e4 <tickslock>
}
    4854:	01010113          	add	sp,sp,16
  initlock(&tickslock, "time");
    4858:	ffffd317          	auipc	t1,0xffffd
    485c:	8f430067          	jr	-1804(t1) # 114c <initlock>

00004860 <trapinithart>:
{
    4860:	ff010113          	add	sp,sp,-16
    4864:	00812623          	sw	s0,12(sp)
    4868:	01010413          	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    486c:	00005797          	auipc	a5,0x5
    4870:	41478793          	add	a5,a5,1044 # 9c80 <kernelvec>
    4874:	10579073          	csrw	stvec,a5
}
    4878:	00c12403          	lw	s0,12(sp)
    487c:	01010113          	add	sp,sp,16
    4880:	00008067          	ret

00004884 <usertrapret>:
{
    4884:	ff010113          	add	sp,sp,-16
    4888:	00812423          	sw	s0,8(sp)
    488c:	00112623          	sw	ra,12(sp)
    4890:	01010413          	add	s0,sp,16
  struct proc *p = myproc();
    4894:	fffff097          	auipc	ra,0xfffff
    4898:	b90080e7          	jalr	-1136(ra) # 3424 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    489c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    48a0:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    48a4:	10079073          	csrw	sstatus,a5
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    48a8:	00006617          	auipc	a2,0x6
    48ac:	75860613          	add	a2,a2,1880 # b000 <trampoline>
    48b0:	00005797          	auipc	a5,0x5
    48b4:	75078793          	add	a5,a5,1872 # a000 <virtio_disk_rw+0x12c>
    48b8:	40c787b3          	sub	a5,a5,a2
  asm volatile("csrw stvec, %0" : : "r" (x));
    48bc:	10579073          	csrw	stvec,a5
  p->tf->kernel_satp = r_satp();         // kernel page table
    48c0:	03052783          	lw	a5,48(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    48c4:	180025f3          	csrr	a1,satp
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    48c8:	02452703          	lw	a4,36(a0)
    48cc:	000016b7          	lui	a3,0x1
  p->tf->kernel_satp = r_satp();         // kernel page table
    48d0:	00b7a023          	sw	a1,0(a5)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    48d4:	00d70733          	add	a4,a4,a3
    48d8:	00e7a223          	sw	a4,4(a5)
  p->tf->kernel_trap = (uint32)usertrap;
    48dc:	00000717          	auipc	a4,0x0
    48e0:	d0470713          	add	a4,a4,-764 # 45e0 <usertrap>
    48e4:	00e7a423          	sw	a4,8(a5)
  asm volatile("mv %0, tp" : "=r" (x) );
    48e8:	00020713          	mv	a4,tp
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    48ec:	00e7a823          	sw	a4,16(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    48f0:	10002773          	csrr	a4,sstatus
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    48f4:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    48f8:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    48fc:	10071073          	csrw	sstatus,a4
  asm volatile("csrw sepc, %0" : : "r" (x));
    4900:	00c7a783          	lw	a5,12(a5)
    4904:	14179073          	csrw	sepc,a5
  uint32 satp = MAKE_SATP(p->pagetable);
    4908:	02c52703          	lw	a4,44(a0)
}
    490c:	00812403          	lw	s0,8(sp)
    4910:	00c12083          	lw	ra,12(sp)
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    4914:	00006797          	auipc	a5,0x6
    4918:	78c78793          	add	a5,a5,1932 # b0a0 <userret>
  uint32 satp = MAKE_SATP(p->pagetable);
    491c:	00c75713          	srl	a4,a4,0xc
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    4920:	40c787b3          	sub	a5,a5,a2
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    4924:	800005b7          	lui	a1,0x80000
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    4928:	40d787b3          	sub	a5,a5,a3
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    492c:	00b765b3          	or	a1,a4,a1
    4930:	ffffe537          	lui	a0,0xffffe
}
    4934:	01010113          	add	sp,sp,16
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    4938:	00078067          	jr	a5

0000493c <kerneltrap>:
{
    493c:	ff010113          	add	sp,sp,-16
    4940:	00812423          	sw	s0,8(sp)
    4944:	00112623          	sw	ra,12(sp)
    4948:	00912223          	sw	s1,4(sp)
    494c:	01212023          	sw	s2,0(sp)
    4950:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, sepc" : "=r" (x) );
    4954:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    4958:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    495c:	142025f3          	csrr	a1,scause
  if((sstatus & SSTATUS_SPP) == 0)
    4960:	1004f793          	and	a5,s1,256
    4964:	12078463          	beqz	a5,4a8c <kerneltrap+0x150>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    4968:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    496c:	0027f793          	and	a5,a5,2
  if(intr_get() != 0)
    4970:	10079663          	bnez	a5,4a7c <kerneltrap+0x140>
  asm volatile("csrr %0, scause" : "=r" (x) );
    4974:	142027f3          	csrr	a5,scause
  if((scause & 0x80000000L) &&
    4978:	0007de63          	bgez	a5,4994 <kerneltrap+0x58>
     (scause & 0xff) == 9){
    497c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x80000000L) &&
    4980:	00900693          	li	a3,9
    4984:	0ad70063          	beq	a4,a3,4a24 <kerneltrap+0xe8>
  } else if(scause == 0x80000001L){
    4988:	80000737          	lui	a4,0x80000
    498c:	00170713          	add	a4,a4,1 # 80000001 <end+0x7ffdbfed>
    4990:	02e78e63          	beq	a5,a4,49cc <kerneltrap+0x90>
    printf("scause %p\n", scause);
    4994:	00007517          	auipc	a0,0x7
    4998:	bd450513          	add	a0,a0,-1068 # b568 <main+0x438>
    499c:	ffffc097          	auipc	ra,0xffffc
    49a0:	d94080e7          	jalr	-620(ra) # 730 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    49a4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    49a8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    49ac:	00007517          	auipc	a0,0x7
    49b0:	b5850513          	add	a0,a0,-1192 # b504 <main+0x3d4>
    49b4:	ffffc097          	auipc	ra,0xffffc
    49b8:	d7c080e7          	jalr	-644(ra) # 730 <printf>
    panic("kerneltrap");
    49bc:	00007517          	auipc	a0,0x7
    49c0:	bb850513          	add	a0,a0,-1096 # b574 <main+0x444>
    49c4:	ffffc097          	auipc	ra,0xffffc
    49c8:	d10080e7          	jalr	-752(ra) # 6d4 <panic>
    if(cpuid() == 0){
    49cc:	fffff097          	auipc	ra,0xfffff
    49d0:	a08080e7          	jalr	-1528(ra) # 33d4 <cpuid>
    49d4:	04050e63          	beqz	a0,4a30 <kerneltrap+0xf4>
  asm volatile("csrr %0, sip" : "=r" (x) );
    49d8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    49dc:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    49e0:	14479073          	csrw	sip,a5
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    49e4:	fffff097          	auipc	ra,0xfffff
    49e8:	a40080e7          	jalr	-1472(ra) # 3424 <myproc>
    49ec:	00050c63          	beqz	a0,4a04 <kerneltrap+0xc8>
    49f0:	fffff097          	auipc	ra,0xfffff
    49f4:	a34080e7          	jalr	-1484(ra) # 3424 <myproc>
    49f8:	00c52703          	lw	a4,12(a0)
    49fc:	00300793          	li	a5,3
    4a00:	06f70863          	beq	a4,a5,4a70 <kerneltrap+0x134>
  asm volatile("csrw sepc, %0" : : "r" (x));
    4a04:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    4a08:	10049073          	csrw	sstatus,s1
}
    4a0c:	00c12083          	lw	ra,12(sp)
    4a10:	00812403          	lw	s0,8(sp)
    4a14:	00412483          	lw	s1,4(sp)
    4a18:	00012903          	lw	s2,0(sp)
    4a1c:	01010113          	add	sp,sp,16
    4a20:	00008067          	ret
      uartintr();
    4a24:	ffffc097          	auipc	ra,0xffffc
    4a28:	3b4080e7          	jalr	948(ra) # dd8 <uartintr>
    return 1;
    4a2c:	fd9ff06f          	j	4a04 <kerneltrap+0xc8>
  acquire(&tickslock);
    4a30:	00014517          	auipc	a0,0x14
    4a34:	cb450513          	add	a0,a0,-844 # 186e4 <tickslock>
    4a38:	ffffc097          	auipc	ra,0xffffc
    4a3c:	738080e7          	jalr	1848(ra) # 1170 <acquire>
  ticks++;
    4a40:	0001f517          	auipc	a0,0x1f
    4a44:	5d050513          	add	a0,a0,1488 # 24010 <ticks>
    4a48:	00052783          	lw	a5,0(a0)
    4a4c:	00178793          	add	a5,a5,1
    4a50:	00f52023          	sw	a5,0(a0)
  wakeup(&ticks);
    4a54:	fffff097          	auipc	ra,0xfffff
    4a58:	704080e7          	jalr	1796(ra) # 4158 <wakeup>
  release(&tickslock);
    4a5c:	00014517          	auipc	a0,0x14
    4a60:	c8850513          	add	a0,a0,-888 # 186e4 <tickslock>
    4a64:	ffffd097          	auipc	ra,0xffffd
    4a68:	898080e7          	jalr	-1896(ra) # 12fc <release>
}
    4a6c:	f6dff06f          	j	49d8 <kerneltrap+0x9c>
    yield();
    4a70:	fffff097          	auipc	ra,0xfffff
    4a74:	580080e7          	jalr	1408(ra) # 3ff0 <yield>
    4a78:	f8dff06f          	j	4a04 <kerneltrap+0xc8>
    panic("kerneltrap: interrupts enabled");
    4a7c:	00007517          	auipc	a0,0x7
    4a80:	acc50513          	add	a0,a0,-1332 # b548 <main+0x418>
    4a84:	ffffc097          	auipc	ra,0xffffc
    4a88:	c50080e7          	jalr	-944(ra) # 6d4 <panic>
    panic("kerneltrap: not from supervisor mode");
    4a8c:	00007517          	auipc	a0,0x7
    4a90:	a9450513          	add	a0,a0,-1388 # b520 <main+0x3f0>
    4a94:	ffffc097          	auipc	ra,0xffffc
    4a98:	c40080e7          	jalr	-960(ra) # 6d4 <panic>

00004a9c <clockintr>:
{
    4a9c:	ff010113          	add	sp,sp,-16
    4aa0:	00112623          	sw	ra,12(sp)
    4aa4:	00812423          	sw	s0,8(sp)
    4aa8:	00912223          	sw	s1,4(sp)
    4aac:	01010413          	add	s0,sp,16
  acquire(&tickslock);
    4ab0:	00014497          	auipc	s1,0x14
    4ab4:	c3448493          	add	s1,s1,-972 # 186e4 <tickslock>
    4ab8:	00048513          	mv	a0,s1
    4abc:	ffffc097          	auipc	ra,0xffffc
    4ac0:	6b4080e7          	jalr	1716(ra) # 1170 <acquire>
  ticks++;
    4ac4:	0001f517          	auipc	a0,0x1f
    4ac8:	54c50513          	add	a0,a0,1356 # 24010 <ticks>
    4acc:	00052783          	lw	a5,0(a0)
    4ad0:	00178793          	add	a5,a5,1
    4ad4:	00f52023          	sw	a5,0(a0)
  wakeup(&ticks);
    4ad8:	fffff097          	auipc	ra,0xfffff
    4adc:	680080e7          	jalr	1664(ra) # 4158 <wakeup>
}
    4ae0:	00812403          	lw	s0,8(sp)
    4ae4:	00c12083          	lw	ra,12(sp)
  release(&tickslock);
    4ae8:	00048513          	mv	a0,s1
}
    4aec:	00412483          	lw	s1,4(sp)
    4af0:	01010113          	add	sp,sp,16
  release(&tickslock);
    4af4:	ffffd317          	auipc	t1,0xffffd
    4af8:	80830067          	jr	-2040(t1) # 12fc <release>

00004afc <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    4afc:	142027f3          	csrr	a5,scause

    return 2;
  } else {
    return 0;
    4b00:	00000513          	li	a0,0
  if((scause & 0x80000000L) &&
    4b04:	0207de63          	bgez	a5,4b40 <devintr+0x44>
{
    4b08:	ff010113          	add	sp,sp,-16
    4b0c:	00812423          	sw	s0,8(sp)
    4b10:	00112623          	sw	ra,12(sp)
    4b14:	01010413          	add	s0,sp,16
     (scause & 0xff) == 9){
    4b18:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x80000000L) &&
    4b1c:	00900693          	li	a3,9
    4b20:	04d70263          	beq	a4,a3,4b64 <devintr+0x68>
  } else if(scause == 0x80000001L){
    4b24:	80000737          	lui	a4,0x80000
    4b28:	00170713          	add	a4,a4,1 # 80000001 <end+0x7ffdbfed>
    4b2c:	00e78c63          	beq	a5,a4,4b44 <devintr+0x48>
  }
}
    4b30:	00c12083          	lw	ra,12(sp)
    4b34:	00812403          	lw	s0,8(sp)
    4b38:	01010113          	add	sp,sp,16
    4b3c:	00008067          	ret
    4b40:	00008067          	ret
    if(cpuid() == 0){
    4b44:	fffff097          	auipc	ra,0xfffff
    4b48:	890080e7          	jalr	-1904(ra) # 33d4 <cpuid>
    4b4c:	02050463          	beqz	a0,4b74 <devintr+0x78>
  asm volatile("csrr %0, sip" : "=r" (x) );
    4b50:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    4b54:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    4b58:	14479073          	csrw	sip,a5
    4b5c:	00200513          	li	a0,2
    4b60:	fd1ff06f          	j	4b30 <devintr+0x34>
      uartintr();
    4b64:	ffffc097          	auipc	ra,0xffffc
    4b68:	274080e7          	jalr	628(ra) # dd8 <uartintr>
    return 1;
    4b6c:	00100513          	li	a0,1
    4b70:	fc1ff06f          	j	4b30 <devintr+0x34>
  acquire(&tickslock);
    4b74:	00014517          	auipc	a0,0x14
    4b78:	b7050513          	add	a0,a0,-1168 # 186e4 <tickslock>
    4b7c:	ffffc097          	auipc	ra,0xffffc
    4b80:	5f4080e7          	jalr	1524(ra) # 1170 <acquire>
  ticks++;
    4b84:	0001f517          	auipc	a0,0x1f
    4b88:	48c50513          	add	a0,a0,1164 # 24010 <ticks>
    4b8c:	00052783          	lw	a5,0(a0)
    4b90:	00178793          	add	a5,a5,1
    4b94:	00f52023          	sw	a5,0(a0)
  wakeup(&ticks);
    4b98:	fffff097          	auipc	ra,0xfffff
    4b9c:	5c0080e7          	jalr	1472(ra) # 4158 <wakeup>
  release(&tickslock);
    4ba0:	00014517          	auipc	a0,0x14
    4ba4:	b4450513          	add	a0,a0,-1212 # 186e4 <tickslock>
    4ba8:	ffffc097          	auipc	ra,0xffffc
    4bac:	754080e7          	jalr	1876(ra) # 12fc <release>
}
    4bb0:	fa1ff06f          	j	4b50 <devintr+0x54>

00004bb4 <fetchaddr>:
#include "defs.h"

// Fetch the uint32 at addr from the current process.
int
fetchaddr(uint32 addr, uint32 *ip)
{
    4bb4:	ff010113          	add	sp,sp,-16
    4bb8:	00812423          	sw	s0,8(sp)
    4bbc:	00912223          	sw	s1,4(sp)
    4bc0:	01212023          	sw	s2,0(sp)
    4bc4:	00112623          	sw	ra,12(sp)
    4bc8:	01010413          	add	s0,sp,16
    4bcc:	00050493          	mv	s1,a0
    4bd0:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    4bd4:	fffff097          	auipc	ra,0xfffff
    4bd8:	850080e7          	jalr	-1968(ra) # 3424 <myproc>
  if(addr >= p->sz || addr+sizeof(uint32) > p->sz)
    4bdc:	02852783          	lw	a5,40(a0)
    4be0:	04f4f263          	bgeu	s1,a5,4c24 <fetchaddr+0x70>
    4be4:	00448713          	add	a4,s1,4
    4be8:	02e7ee63          	bltu	a5,a4,4c24 <fetchaddr+0x70>
    return -1;
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    4bec:	02c52503          	lw	a0,44(a0)
    4bf0:	00400693          	li	a3,4
    4bf4:	00048613          	mv	a2,s1
    4bf8:	00090593          	mv	a1,s2
    4bfc:	ffffe097          	auipc	ra,0xffffe
    4c00:	264080e7          	jalr	612(ra) # 2e60 <copyin>
    4c04:	00a03533          	snez	a0,a0
    4c08:	40a00533          	neg	a0,a0
    return -1;
  return 0;
}
    4c0c:	00c12083          	lw	ra,12(sp)
    4c10:	00812403          	lw	s0,8(sp)
    4c14:	00412483          	lw	s1,4(sp)
    4c18:	00012903          	lw	s2,0(sp)
    4c1c:	01010113          	add	sp,sp,16
    4c20:	00008067          	ret
    return -1;
    4c24:	fff00513          	li	a0,-1
    4c28:	fe5ff06f          	j	4c0c <fetchaddr+0x58>

00004c2c <fetchstr>:

// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int
fetchstr(uint32 addr, char *buf, int max)
{
    4c2c:	fe010113          	add	sp,sp,-32
    4c30:	00812c23          	sw	s0,24(sp)
    4c34:	00912a23          	sw	s1,20(sp)
    4c38:	01212823          	sw	s2,16(sp)
    4c3c:	01312623          	sw	s3,12(sp)
    4c40:	00112e23          	sw	ra,28(sp)
    4c44:	02010413          	add	s0,sp,32
    4c48:	00060993          	mv	s3,a2
    4c4c:	00050913          	mv	s2,a0
    4c50:	00058493          	mv	s1,a1
  struct proc *p = myproc();
    4c54:	ffffe097          	auipc	ra,0xffffe
    4c58:	7d0080e7          	jalr	2000(ra) # 3424 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    4c5c:	02c52503          	lw	a0,44(a0)
    4c60:	00098693          	mv	a3,s3
    4c64:	00090613          	mv	a2,s2
    4c68:	00048593          	mv	a1,s1
    4c6c:	ffffe097          	auipc	ra,0xffffe
    4c70:	30c080e7          	jalr	780(ra) # 2f78 <copyinstr>
  if(err < 0)
    4c74:	02054463          	bltz	a0,4c9c <fetchstr+0x70>
    return err;
  return strlen(buf);
}
    4c78:	01812403          	lw	s0,24(sp)
    4c7c:	01c12083          	lw	ra,28(sp)
    4c80:	01012903          	lw	s2,16(sp)
    4c84:	00c12983          	lw	s3,12(sp)
  return strlen(buf);
    4c88:	00048513          	mv	a0,s1
}
    4c8c:	01412483          	lw	s1,20(sp)
    4c90:	02010113          	add	sp,sp,32
  return strlen(buf);
    4c94:	ffffd317          	auipc	t1,0xffffd
    4c98:	f3430067          	jr	-204(t1) # 1bc8 <strlen>
}
    4c9c:	01c12083          	lw	ra,28(sp)
    4ca0:	01812403          	lw	s0,24(sp)
    4ca4:	01412483          	lw	s1,20(sp)
    4ca8:	01012903          	lw	s2,16(sp)
    4cac:	00c12983          	lw	s3,12(sp)
    4cb0:	02010113          	add	sp,sp,32
    4cb4:	00008067          	ret

00004cb8 <argint>:
}

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    4cb8:	ff010113          	add	sp,sp,-16
    4cbc:	00812423          	sw	s0,8(sp)
    4cc0:	00912223          	sw	s1,4(sp)
    4cc4:	01212023          	sw	s2,0(sp)
    4cc8:	00112623          	sw	ra,12(sp)
    4ccc:	01010413          	add	s0,sp,16
    4cd0:	00050493          	mv	s1,a0
    4cd4:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    4cd8:	ffffe097          	auipc	ra,0xffffe
    4cdc:	74c080e7          	jalr	1868(ra) # 3424 <myproc>
  switch (n) {
    4ce0:	00500793          	li	a5,5
    4ce4:	1097e863          	bltu	a5,s1,4df4 <argint+0x13c>
    4ce8:	00007717          	auipc	a4,0x7
    4cec:	bbc70713          	add	a4,a4,-1092 # b8a4 <states.0+0x14>
    4cf0:	00249493          	sll	s1,s1,0x2
    4cf4:	00e484b3          	add	s1,s1,a4
    4cf8:	0004a783          	lw	a5,0(s1)
    4cfc:	00e787b3          	add	a5,a5,a4
    4d00:	00078067          	jr	a5
    return p->tf->a4;
    4d04:	03052783          	lw	a5,48(a0)
  *ip = argraw(n);
  return 0;
}
    4d08:	00c12083          	lw	ra,12(sp)
    4d0c:	00812403          	lw	s0,8(sp)
    return p->tf->a4;
    4d10:	0487a783          	lw	a5,72(a5)
}
    4d14:	00412483          	lw	s1,4(sp)
    4d18:	00000513          	li	a0,0
  *ip = argraw(n);
    4d1c:	00f92023          	sw	a5,0(s2)
}
    4d20:	00012903          	lw	s2,0(sp)
    4d24:	01010113          	add	sp,sp,16
    4d28:	00008067          	ret
    return p->tf->a5;
    4d2c:	03052783          	lw	a5,48(a0)
}
    4d30:	00c12083          	lw	ra,12(sp)
    4d34:	00812403          	lw	s0,8(sp)
    return p->tf->a5;
    4d38:	04c7a783          	lw	a5,76(a5)
}
    4d3c:	00412483          	lw	s1,4(sp)
    4d40:	00000513          	li	a0,0
  *ip = argraw(n);
    4d44:	00f92023          	sw	a5,0(s2)
}
    4d48:	00012903          	lw	s2,0(sp)
    4d4c:	01010113          	add	sp,sp,16
    4d50:	00008067          	ret
    return p->tf->a0;
    4d54:	03052783          	lw	a5,48(a0)
}
    4d58:	00c12083          	lw	ra,12(sp)
    4d5c:	00812403          	lw	s0,8(sp)
    return p->tf->a0;
    4d60:	0387a783          	lw	a5,56(a5)
}
    4d64:	00412483          	lw	s1,4(sp)
    4d68:	00000513          	li	a0,0
  *ip = argraw(n);
    4d6c:	00f92023          	sw	a5,0(s2)
}
    4d70:	00012903          	lw	s2,0(sp)
    4d74:	01010113          	add	sp,sp,16
    4d78:	00008067          	ret
    return p->tf->a1;
    4d7c:	03052783          	lw	a5,48(a0)
}
    4d80:	00c12083          	lw	ra,12(sp)
    4d84:	00812403          	lw	s0,8(sp)
    return p->tf->a1;
    4d88:	03c7a783          	lw	a5,60(a5)
}
    4d8c:	00412483          	lw	s1,4(sp)
    4d90:	00000513          	li	a0,0
  *ip = argraw(n);
    4d94:	00f92023          	sw	a5,0(s2)
}
    4d98:	00012903          	lw	s2,0(sp)
    4d9c:	01010113          	add	sp,sp,16
    4da0:	00008067          	ret
    return p->tf->a2;
    4da4:	03052783          	lw	a5,48(a0)
}
    4da8:	00c12083          	lw	ra,12(sp)
    4dac:	00812403          	lw	s0,8(sp)
    return p->tf->a2;
    4db0:	0407a783          	lw	a5,64(a5)
}
    4db4:	00412483          	lw	s1,4(sp)
    4db8:	00000513          	li	a0,0
  *ip = argraw(n);
    4dbc:	00f92023          	sw	a5,0(s2)
}
    4dc0:	00012903          	lw	s2,0(sp)
    4dc4:	01010113          	add	sp,sp,16
    4dc8:	00008067          	ret
    return p->tf->a3;
    4dcc:	03052783          	lw	a5,48(a0)
}
    4dd0:	00c12083          	lw	ra,12(sp)
    4dd4:	00812403          	lw	s0,8(sp)
    return p->tf->a3;
    4dd8:	0447a783          	lw	a5,68(a5)
}
    4ddc:	00412483          	lw	s1,4(sp)
    4de0:	00000513          	li	a0,0
  *ip = argraw(n);
    4de4:	00f92023          	sw	a5,0(s2)
}
    4de8:	00012903          	lw	s2,0(sp)
    4dec:	01010113          	add	sp,sp,16
    4df0:	00008067          	ret
  panic("argraw");
    4df4:	00006517          	auipc	a0,0x6
    4df8:	78c50513          	add	a0,a0,1932 # b580 <main+0x450>
    4dfc:	ffffc097          	auipc	ra,0xffffc
    4e00:	8d8080e7          	jalr	-1832(ra) # 6d4 <panic>

00004e04 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint32 *ip)
{
    4e04:	ff010113          	add	sp,sp,-16
    4e08:	00812423          	sw	s0,8(sp)
    4e0c:	00912223          	sw	s1,4(sp)
    4e10:	01212023          	sw	s2,0(sp)
    4e14:	00112623          	sw	ra,12(sp)
    4e18:	01010413          	add	s0,sp,16
    4e1c:	00050493          	mv	s1,a0
    4e20:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    4e24:	ffffe097          	auipc	ra,0xffffe
    4e28:	600080e7          	jalr	1536(ra) # 3424 <myproc>
  switch (n) {
    4e2c:	00500793          	li	a5,5
    4e30:	1097e863          	bltu	a5,s1,4f40 <argaddr+0x13c>
    4e34:	00007717          	auipc	a4,0x7
    4e38:	a8870713          	add	a4,a4,-1400 # b8bc <states.0+0x2c>
    4e3c:	00249493          	sll	s1,s1,0x2
    4e40:	00e484b3          	add	s1,s1,a4
    4e44:	0004a783          	lw	a5,0(s1)
    4e48:	00e787b3          	add	a5,a5,a4
    4e4c:	00078067          	jr	a5
    return p->tf->a4;
    4e50:	03052783          	lw	a5,48(a0)
  *ip = argraw(n);
  return 0;
}
    4e54:	00c12083          	lw	ra,12(sp)
    4e58:	00812403          	lw	s0,8(sp)
    return p->tf->a4;
    4e5c:	0487a783          	lw	a5,72(a5)
}
    4e60:	00412483          	lw	s1,4(sp)
    4e64:	00000513          	li	a0,0
  *ip = argraw(n);
    4e68:	00f92023          	sw	a5,0(s2)
}
    4e6c:	00012903          	lw	s2,0(sp)
    4e70:	01010113          	add	sp,sp,16
    4e74:	00008067          	ret
    return p->tf->a5;
    4e78:	03052783          	lw	a5,48(a0)
}
    4e7c:	00c12083          	lw	ra,12(sp)
    4e80:	00812403          	lw	s0,8(sp)
    return p->tf->a5;
    4e84:	04c7a783          	lw	a5,76(a5)
}
    4e88:	00412483          	lw	s1,4(sp)
    4e8c:	00000513          	li	a0,0
  *ip = argraw(n);
    4e90:	00f92023          	sw	a5,0(s2)
}
    4e94:	00012903          	lw	s2,0(sp)
    4e98:	01010113          	add	sp,sp,16
    4e9c:	00008067          	ret
    return p->tf->a0;
    4ea0:	03052783          	lw	a5,48(a0)
}
    4ea4:	00c12083          	lw	ra,12(sp)
    4ea8:	00812403          	lw	s0,8(sp)
    return p->tf->a0;
    4eac:	0387a783          	lw	a5,56(a5)
}
    4eb0:	00412483          	lw	s1,4(sp)
    4eb4:	00000513          	li	a0,0
  *ip = argraw(n);
    4eb8:	00f92023          	sw	a5,0(s2)
}
    4ebc:	00012903          	lw	s2,0(sp)
    4ec0:	01010113          	add	sp,sp,16
    4ec4:	00008067          	ret
    return p->tf->a1;
    4ec8:	03052783          	lw	a5,48(a0)
}
    4ecc:	00c12083          	lw	ra,12(sp)
    4ed0:	00812403          	lw	s0,8(sp)
    return p->tf->a1;
    4ed4:	03c7a783          	lw	a5,60(a5)
}
    4ed8:	00412483          	lw	s1,4(sp)
    4edc:	00000513          	li	a0,0
  *ip = argraw(n);
    4ee0:	00f92023          	sw	a5,0(s2)
}
    4ee4:	00012903          	lw	s2,0(sp)
    4ee8:	01010113          	add	sp,sp,16
    4eec:	00008067          	ret
    return p->tf->a2;
    4ef0:	03052783          	lw	a5,48(a0)
}
    4ef4:	00c12083          	lw	ra,12(sp)
    4ef8:	00812403          	lw	s0,8(sp)
    return p->tf->a2;
    4efc:	0407a783          	lw	a5,64(a5)
}
    4f00:	00412483          	lw	s1,4(sp)
    4f04:	00000513          	li	a0,0
  *ip = argraw(n);
    4f08:	00f92023          	sw	a5,0(s2)
}
    4f0c:	00012903          	lw	s2,0(sp)
    4f10:	01010113          	add	sp,sp,16
    4f14:	00008067          	ret
    return p->tf->a3;
    4f18:	03052783          	lw	a5,48(a0)
}
    4f1c:	00c12083          	lw	ra,12(sp)
    4f20:	00812403          	lw	s0,8(sp)
    return p->tf->a3;
    4f24:	0447a783          	lw	a5,68(a5)
}
    4f28:	00412483          	lw	s1,4(sp)
    4f2c:	00000513          	li	a0,0
  *ip = argraw(n);
    4f30:	00f92023          	sw	a5,0(s2)
}
    4f34:	00012903          	lw	s2,0(sp)
    4f38:	01010113          	add	sp,sp,16
    4f3c:	00008067          	ret
  panic("argraw");
    4f40:	00006517          	auipc	a0,0x6
    4f44:	64050513          	add	a0,a0,1600 # b580 <main+0x450>
    4f48:	ffffb097          	auipc	ra,0xffffb
    4f4c:	78c080e7          	jalr	1932(ra) # 6d4 <panic>

00004f50 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    4f50:	fe010113          	add	sp,sp,-32
    4f54:	00812c23          	sw	s0,24(sp)
    4f58:	00912a23          	sw	s1,20(sp)
    4f5c:	01212823          	sw	s2,16(sp)
    4f60:	01312623          	sw	s3,12(sp)
    4f64:	00112e23          	sw	ra,28(sp)
    4f68:	02010413          	add	s0,sp,32
    4f6c:	00050493          	mv	s1,a0
    4f70:	00058913          	mv	s2,a1
    4f74:	00060993          	mv	s3,a2
  struct proc *p = myproc();
    4f78:	ffffe097          	auipc	ra,0xffffe
    4f7c:	4ac080e7          	jalr	1196(ra) # 3424 <myproc>
  switch (n) {
    4f80:	00500793          	li	a5,5
    4f84:	0c97e463          	bltu	a5,s1,504c <argstr+0xfc>
    4f88:	00007717          	auipc	a4,0x7
    4f8c:	94c70713          	add	a4,a4,-1716 # b8d4 <states.0+0x44>
    4f90:	00249493          	sll	s1,s1,0x2
    4f94:	00e484b3          	add	s1,s1,a4
    4f98:	0004a783          	lw	a5,0(s1)
    4f9c:	00e787b3          	add	a5,a5,a4
    4fa0:	00078067          	jr	a5
    return p->tf->a4;
    4fa4:	03052783          	lw	a5,48(a0)
    4fa8:	0487a483          	lw	s1,72(a5)
  struct proc *p = myproc();
    4fac:	ffffe097          	auipc	ra,0xffffe
    4fb0:	478080e7          	jalr	1144(ra) # 3424 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    4fb4:	02c52503          	lw	a0,44(a0)
    4fb8:	00098693          	mv	a3,s3
    4fbc:	00048613          	mv	a2,s1
    4fc0:	00090593          	mv	a1,s2
    4fc4:	ffffe097          	auipc	ra,0xffffe
    4fc8:	fb4080e7          	jalr	-76(ra) # 2f78 <copyinstr>
  if(err < 0)
    4fcc:	06054263          	bltz	a0,5030 <argstr+0xe0>
  uint32 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
}
    4fd0:	01812403          	lw	s0,24(sp)
    4fd4:	01c12083          	lw	ra,28(sp)
    4fd8:	01412483          	lw	s1,20(sp)
    4fdc:	00c12983          	lw	s3,12(sp)
  return strlen(buf);
    4fe0:	00090513          	mv	a0,s2
}
    4fe4:	01012903          	lw	s2,16(sp)
    4fe8:	02010113          	add	sp,sp,32
  return strlen(buf);
    4fec:	ffffd317          	auipc	t1,0xffffd
    4ff0:	bdc30067          	jr	-1060(t1) # 1bc8 <strlen>
    return p->tf->a5;
    4ff4:	03052783          	lw	a5,48(a0)
    4ff8:	04c7a483          	lw	s1,76(a5)
    4ffc:	fb1ff06f          	j	4fac <argstr+0x5c>
    return p->tf->a0;
    5000:	03052783          	lw	a5,48(a0)
    5004:	0387a483          	lw	s1,56(a5)
    5008:	fa5ff06f          	j	4fac <argstr+0x5c>
    return p->tf->a1;
    500c:	03052783          	lw	a5,48(a0)
    5010:	03c7a483          	lw	s1,60(a5)
    5014:	f99ff06f          	j	4fac <argstr+0x5c>
    return p->tf->a2;
    5018:	03052783          	lw	a5,48(a0)
    501c:	0407a483          	lw	s1,64(a5)
    5020:	f8dff06f          	j	4fac <argstr+0x5c>
    return p->tf->a3;
    5024:	03052783          	lw	a5,48(a0)
    5028:	0447a483          	lw	s1,68(a5)
    502c:	f81ff06f          	j	4fac <argstr+0x5c>
}
    5030:	01c12083          	lw	ra,28(sp)
    5034:	01812403          	lw	s0,24(sp)
    5038:	01412483          	lw	s1,20(sp)
    503c:	01012903          	lw	s2,16(sp)
    5040:	00c12983          	lw	s3,12(sp)
    5044:	02010113          	add	sp,sp,32
    5048:	00008067          	ret
  panic("argraw");
    504c:	00006517          	auipc	a0,0x6
    5050:	53450513          	add	a0,a0,1332 # b580 <main+0x450>
    5054:	ffffb097          	auipc	ra,0xffffb
    5058:	680080e7          	jalr	1664(ra) # 6d4 <panic>

0000505c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    505c:	ff010113          	add	sp,sp,-16
    5060:	00812423          	sw	s0,8(sp)
    5064:	00912223          	sw	s1,4(sp)
    5068:	01212023          	sw	s2,0(sp)
    506c:	00112623          	sw	ra,12(sp)
    5070:	01010413          	add	s0,sp,16
  int num;
  struct proc *p = myproc();
    5074:	ffffe097          	auipc	ra,0xffffe
    5078:	3b0080e7          	jalr	944(ra) # 3424 <myproc>

  num = p->tf->a7;
    507c:	03052903          	lw	s2,48(a0)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    5080:	01400793          	li	a5,20
  struct proc *p = myproc();
    5084:	00050493          	mv	s1,a0
  num = p->tf->a7;
    5088:	05492683          	lw	a3,84(s2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    508c:	fff68713          	add	a4,a3,-1 # fff <freerange+0xc7>
    5090:	02e7ee63          	bltu	a5,a4,50cc <syscall+0x70>
    5094:	00269713          	sll	a4,a3,0x2
    5098:	00007797          	auipc	a5,0x7
    509c:	85478793          	add	a5,a5,-1964 # b8ec <syscalls>
    50a0:	00e787b3          	add	a5,a5,a4
    50a4:	0007a783          	lw	a5,0(a5)
    50a8:	02078263          	beqz	a5,50cc <syscall+0x70>
    // printf("syscall %p!\n", num);
    p->tf->a0 = syscalls[num]();
    50ac:	000780e7          	jalr	a5
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->tf->a0 = -1;
  }
}
    50b0:	00c12083          	lw	ra,12(sp)
    50b4:	00812403          	lw	s0,8(sp)
    p->tf->a0 = syscalls[num]();
    50b8:	02a92c23          	sw	a0,56(s2)
}
    50bc:	00412483          	lw	s1,4(sp)
    50c0:	00012903          	lw	s2,0(sp)
    50c4:	01010113          	add	sp,sp,16
    50c8:	00008067          	ret
    printf("%d %s: unknown sys call %d\n",
    50cc:	0204a583          	lw	a1,32(s1)
    50d0:	0b048613          	add	a2,s1,176
    50d4:	00006517          	auipc	a0,0x6
    50d8:	4b450513          	add	a0,a0,1204 # b588 <main+0x458>
    50dc:	ffffb097          	auipc	ra,0xffffb
    50e0:	654080e7          	jalr	1620(ra) # 730 <printf>
    p->tf->a0 = -1;
    50e4:	0304a783          	lw	a5,48(s1)
}
    50e8:	00c12083          	lw	ra,12(sp)
    50ec:	00812403          	lw	s0,8(sp)
    p->tf->a0 = -1;
    50f0:	fff00713          	li	a4,-1
    50f4:	02e7ac23          	sw	a4,56(a5)
}
    50f8:	00412483          	lw	s1,4(sp)
    50fc:	00012903          	lw	s2,0(sp)
    5100:	01010113          	add	sp,sp,16
    5104:	00008067          	ret

00005108 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint32
sys_exit(void)
{
    5108:	fe010113          	add	sp,sp,-32
    510c:	00812c23          	sw	s0,24(sp)
    5110:	00112e23          	sw	ra,28(sp)
    5114:	02010413          	add	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    5118:	fec40593          	add	a1,s0,-20
    511c:	00000513          	li	a0,0
    5120:	00000097          	auipc	ra,0x0
    5124:	b98080e7          	jalr	-1128(ra) # 4cb8 <argint>
    5128:	fff00793          	li	a5,-1
    512c:	00054a63          	bltz	a0,5140 <sys_exit+0x38>
    return -1;
  exit(n);
    5130:	fec42503          	lw	a0,-20(s0)
    5134:	fffff097          	auipc	ra,0xfffff
    5138:	ad8080e7          	jalr	-1320(ra) # 3c0c <exit>
  return 0;  // not reached
    513c:	00000793          	li	a5,0
}
    5140:	01c12083          	lw	ra,28(sp)
    5144:	01812403          	lw	s0,24(sp)
    5148:	00078513          	mv	a0,a5
    514c:	02010113          	add	sp,sp,32
    5150:	00008067          	ret

00005154 <sys_getpid>:

uint32
sys_getpid(void)
{
    5154:	ff010113          	add	sp,sp,-16
    5158:	00812423          	sw	s0,8(sp)
    515c:	00112623          	sw	ra,12(sp)
    5160:	01010413          	add	s0,sp,16
  return myproc()->pid;
    5164:	ffffe097          	auipc	ra,0xffffe
    5168:	2c0080e7          	jalr	704(ra) # 3424 <myproc>
}
    516c:	00c12083          	lw	ra,12(sp)
    5170:	00812403          	lw	s0,8(sp)
    5174:	02052503          	lw	a0,32(a0)
    5178:	01010113          	add	sp,sp,16
    517c:	00008067          	ret

00005180 <sys_fork>:

uint32
sys_fork(void)
{
    5180:	ff010113          	add	sp,sp,-16
    5184:	00812623          	sw	s0,12(sp)
    5188:	01010413          	add	s0,sp,16
  return fork();
}
    518c:	00c12403          	lw	s0,12(sp)
    5190:	01010113          	add	sp,sp,16
  return fork();
    5194:	ffffe317          	auipc	t1,0xffffe
    5198:	5b030067          	jr	1456(t1) # 3744 <fork>

0000519c <sys_wait>:

uint32
sys_wait(void)
{
    519c:	fe010113          	add	sp,sp,-32
    51a0:	00812c23          	sw	s0,24(sp)
    51a4:	00112e23          	sw	ra,28(sp)
    51a8:	02010413          	add	s0,sp,32
  uint32 p;
  if(argaddr(0, &p) < 0)
    51ac:	fec40593          	add	a1,s0,-20
    51b0:	00000513          	li	a0,0
    51b4:	00000097          	auipc	ra,0x0
    51b8:	c50080e7          	jalr	-944(ra) # 4e04 <argaddr>
    51bc:	00050793          	mv	a5,a0
    51c0:	fff00513          	li	a0,-1
    51c4:	0007c863          	bltz	a5,51d4 <sys_wait+0x38>
    return -1;
  return wait(p);
    51c8:	fec42503          	lw	a0,-20(s0)
    51cc:	fffff097          	auipc	ra,0xfffff
    51d0:	b9c080e7          	jalr	-1124(ra) # 3d68 <wait>
}
    51d4:	01c12083          	lw	ra,28(sp)
    51d8:	01812403          	lw	s0,24(sp)
    51dc:	02010113          	add	sp,sp,32
    51e0:	00008067          	ret

000051e4 <sys_sbrk>:

uint32
sys_sbrk(void)
{
    51e4:	fe010113          	add	sp,sp,-32
    51e8:	00812c23          	sw	s0,24(sp)
    51ec:	00112e23          	sw	ra,28(sp)
    51f0:	02010413          	add	s0,sp,32
    51f4:	00912a23          	sw	s1,20(sp)
  int addr;
  int n;

  if(argint(0, &n) < 0)
    51f8:	fec40593          	add	a1,s0,-20
    51fc:	00000513          	li	a0,0
    5200:	00000097          	auipc	ra,0x0
    5204:	ab8080e7          	jalr	-1352(ra) # 4cb8 <argint>
    5208:	02054e63          	bltz	a0,5244 <sys_sbrk+0x60>
    return -1;
  addr = myproc()->sz;
    520c:	ffffe097          	auipc	ra,0xffffe
    5210:	218080e7          	jalr	536(ra) # 3424 <myproc>
    5214:	00050793          	mv	a5,a0
  if(growproc(n) < 0)
    5218:	fec42503          	lw	a0,-20(s0)
  addr = myproc()->sz;
    521c:	0287a483          	lw	s1,40(a5)
  if(growproc(n) < 0)
    5220:	ffffe097          	auipc	ra,0xffffe
    5224:	474080e7          	jalr	1140(ra) # 3694 <growproc>
    5228:	00054e63          	bltz	a0,5244 <sys_sbrk+0x60>
    return -1;
  return addr;
}
    522c:	01c12083          	lw	ra,28(sp)
    5230:	01812403          	lw	s0,24(sp)
    5234:	00048513          	mv	a0,s1
    5238:	01412483          	lw	s1,20(sp)
    523c:	02010113          	add	sp,sp,32
    5240:	00008067          	ret
    5244:	01c12083          	lw	ra,28(sp)
    5248:	01812403          	lw	s0,24(sp)
    return -1;
    524c:	fff00493          	li	s1,-1
}
    5250:	00048513          	mv	a0,s1
    5254:	01412483          	lw	s1,20(sp)
    5258:	02010113          	add	sp,sp,32
    525c:	00008067          	ret

00005260 <sys_sleep>:

uint32
sys_sleep(void)
{
    5260:	fd010113          	add	sp,sp,-48
    5264:	02812423          	sw	s0,40(sp)
    5268:	02112623          	sw	ra,44(sp)
    526c:	03010413          	add	s0,sp,48
    5270:	02912223          	sw	s1,36(sp)
    5274:	03212023          	sw	s2,32(sp)
    5278:	01312e23          	sw	s3,28(sp)
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    527c:	fdc40593          	add	a1,s0,-36
    5280:	00000513          	li	a0,0
    5284:	00000097          	auipc	ra,0x0
    5288:	a34080e7          	jalr	-1484(ra) # 4cb8 <argint>
    528c:	06054c63          	bltz	a0,5304 <sys_sleep+0xa4>
    return -1;
  acquire(&tickslock);
    5290:	00013517          	auipc	a0,0x13
    5294:	45450513          	add	a0,a0,1108 # 186e4 <tickslock>
    5298:	ffffc097          	auipc	ra,0xffffc
    529c:	ed8080e7          	jalr	-296(ra) # 1170 <acquire>
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    52a0:	fdc42783          	lw	a5,-36(s0)
  ticks0 = ticks;
    52a4:	0001f497          	auipc	s1,0x1f
    52a8:	d6c48493          	add	s1,s1,-660 # 24010 <ticks>
    52ac:	0004a983          	lw	s3,0(s1)
  while(ticks - ticks0 < n){
    52b0:	06078a63          	beqz	a5,5324 <sys_sleep+0xc4>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    52b4:	00013917          	auipc	s2,0x13
    52b8:	43090913          	add	s2,s2,1072 # 186e4 <tickslock>
    52bc:	01c0006f          	j	52d8 <sys_sleep+0x78>
    52c0:	fffff097          	auipc	ra,0xfffff
    52c4:	dac080e7          	jalr	-596(ra) # 406c <sleep>
  while(ticks - ticks0 < n){
    52c8:	0004a783          	lw	a5,0(s1)
    52cc:	fdc42703          	lw	a4,-36(s0)
    52d0:	413787b3          	sub	a5,a5,s3
    52d4:	04e7f863          	bgeu	a5,a4,5324 <sys_sleep+0xc4>
    if(myproc()->killed){
    52d8:	ffffe097          	auipc	ra,0xffffe
    52dc:	14c080e7          	jalr	332(ra) # 3424 <myproc>
    52e0:	00050793          	mv	a5,a0
    52e4:	0187a783          	lw	a5,24(a5)
    sleep(&ticks, &tickslock);
    52e8:	00090593          	mv	a1,s2
    52ec:	00048513          	mv	a0,s1
    if(myproc()->killed){
    52f0:	fc0788e3          	beqz	a5,52c0 <sys_sleep+0x60>
      release(&tickslock);
    52f4:	00013517          	auipc	a0,0x13
    52f8:	3f050513          	add	a0,a0,1008 # 186e4 <tickslock>
    52fc:	ffffc097          	auipc	ra,0xffffc
    5300:	000080e7          	jalr	ra # 12fc <release>
  }
  release(&tickslock);
  return 0;
}
    5304:	02c12083          	lw	ra,44(sp)
    5308:	02812403          	lw	s0,40(sp)
    530c:	02412483          	lw	s1,36(sp)
    5310:	02012903          	lw	s2,32(sp)
    5314:	01c12983          	lw	s3,28(sp)
    return -1;
    5318:	fff00513          	li	a0,-1
}
    531c:	03010113          	add	sp,sp,48
    5320:	00008067          	ret
  release(&tickslock);
    5324:	00013517          	auipc	a0,0x13
    5328:	3c050513          	add	a0,a0,960 # 186e4 <tickslock>
    532c:	ffffc097          	auipc	ra,0xffffc
    5330:	fd0080e7          	jalr	-48(ra) # 12fc <release>
}
    5334:	02c12083          	lw	ra,44(sp)
    5338:	02812403          	lw	s0,40(sp)
    533c:	02412483          	lw	s1,36(sp)
    5340:	02012903          	lw	s2,32(sp)
    5344:	01c12983          	lw	s3,28(sp)
  return 0;
    5348:	00000513          	li	a0,0
}
    534c:	03010113          	add	sp,sp,48
    5350:	00008067          	ret

00005354 <sys_kill>:

uint32
sys_kill(void)
{
    5354:	fe010113          	add	sp,sp,-32
    5358:	00812c23          	sw	s0,24(sp)
    535c:	00112e23          	sw	ra,28(sp)
    5360:	02010413          	add	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    5364:	fec40593          	add	a1,s0,-20
    5368:	00000513          	li	a0,0
    536c:	00000097          	auipc	ra,0x0
    5370:	94c080e7          	jalr	-1716(ra) # 4cb8 <argint>
    5374:	00050793          	mv	a5,a0
    5378:	fff00513          	li	a0,-1
    537c:	0007c863          	bltz	a5,538c <sys_kill+0x38>
    return -1;
  return kill(pid);
    5380:	fec42503          	lw	a0,-20(s0)
    5384:	fffff097          	auipc	ra,0xfffff
    5388:	e80080e7          	jalr	-384(ra) # 4204 <kill>
}
    538c:	01c12083          	lw	ra,28(sp)
    5390:	01812403          	lw	s0,24(sp)
    5394:	02010113          	add	sp,sp,32
    5398:	00008067          	ret

0000539c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint32
sys_uptime(void)
{
    539c:	ff010113          	add	sp,sp,-16
    53a0:	00112623          	sw	ra,12(sp)
    53a4:	00812423          	sw	s0,8(sp)
    53a8:	00912223          	sw	s1,4(sp)
    53ac:	01010413          	add	s0,sp,16
  uint xticks;

  acquire(&tickslock);
    53b0:	00013517          	auipc	a0,0x13
    53b4:	33450513          	add	a0,a0,820 # 186e4 <tickslock>
    53b8:	ffffc097          	auipc	ra,0xffffc
    53bc:	db8080e7          	jalr	-584(ra) # 1170 <acquire>
  xticks = ticks;
  release(&tickslock);
    53c0:	00013517          	auipc	a0,0x13
    53c4:	32450513          	add	a0,a0,804 # 186e4 <tickslock>
  xticks = ticks;
    53c8:	0001f497          	auipc	s1,0x1f
    53cc:	c484a483          	lw	s1,-952(s1) # 24010 <ticks>
  release(&tickslock);
    53d0:	ffffc097          	auipc	ra,0xffffc
    53d4:	f2c080e7          	jalr	-212(ra) # 12fc <release>
  return xticks;
}
    53d8:	00c12083          	lw	ra,12(sp)
    53dc:	00812403          	lw	s0,8(sp)
    53e0:	00048513          	mv	a0,s1
    53e4:	00412483          	lw	s1,4(sp)
    53e8:	01010113          	add	sp,sp,16
    53ec:	00008067          	ret

000053f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    53f0:	fe010113          	add	sp,sp,-32
    53f4:	00812c23          	sw	s0,24(sp)
    53f8:	00912a23          	sw	s1,20(sp)
    53fc:	01212823          	sw	s2,16(sp)
    5400:	01312623          	sw	s3,12(sp)
    5404:	01412423          	sw	s4,8(sp)
    5408:	01512223          	sw	s5,4(sp)
    540c:	00112e23          	sw	ra,28(sp)
    5410:	02010413          	add	s0,sp,32
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    5414:	00006597          	auipc	a1,0x6
    5418:	19058593          	add	a1,a1,400 # b5a4 <main+0x474>
    541c:	00013517          	auipc	a0,0x13
    5420:	2d450513          	add	a0,a0,724 # 186f0 <bcache>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    5424:	0001b997          	auipc	s3,0x1b
    5428:	16898993          	add	s3,s3,360 # 2058c <bcache+0x7e9c>
  initlock(&bcache.lock, "bcache");
    542c:	ffffc097          	auipc	ra,0xffffc
    5430:	d20080e7          	jalr	-736(ra) # 114c <initlock>
  bcache.head.prev = &bcache.head;
    5434:	0001b917          	auipc	s2,0x1b
    5438:	2bc90913          	add	s2,s2,700 # 206f0 <bcache+0x8000>
  bcache.head.next = &bcache.head;
    543c:	00098a93          	mv	s5,s3
  bcache.head.prev = &bcache.head;
    5440:	ed392423          	sw	s3,-312(s2)
  bcache.head.next = &bcache.head;
    5444:	ed392623          	sw	s3,-308(s2)
    5448:	00098713          	mv	a4,s3
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    544c:	00013497          	auipc	s1,0x13
    5450:	2b048493          	add	s1,s1,688 # 186fc <bcache+0xc>
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    5454:	00006a17          	auipc	s4,0x6
    5458:	158a0a13          	add	s4,s4,344 # b5ac <main+0x47c>
    545c:	0080006f          	j	5464 <binit+0x74>
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    5460:	00078493          	mv	s1,a5
    b->next = bcache.head.next;
    5464:	02e4a823          	sw	a4,48(s1)
    b->prev = &bcache.head;
    5468:	0334a623          	sw	s3,44(s1)
    initsleeplock(&b->lock, "buffer");
    546c:	01048513          	add	a0,s1,16
    5470:	000a0593          	mv	a1,s4
    5474:	00002097          	auipc	ra,0x2
    5478:	3d4080e7          	jalr	980(ra) # 7848 <initsleeplock>
    bcache.head.next->prev = b;
    547c:	ecc92683          	lw	a3,-308(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    5480:	43848793          	add	a5,s1,1080
    5484:	00048713          	mv	a4,s1
    bcache.head.next->prev = b;
    5488:	0296a623          	sw	s1,44(a3)
    bcache.head.next = b;
    548c:	ec992623          	sw	s1,-308(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    5490:	fd5798e3          	bne	a5,s5,5460 <binit+0x70>
  }
}
    5494:	01c12083          	lw	ra,28(sp)
    5498:	01812403          	lw	s0,24(sp)
    549c:	01412483          	lw	s1,20(sp)
    54a0:	01012903          	lw	s2,16(sp)
    54a4:	00c12983          	lw	s3,12(sp)
    54a8:	00812a03          	lw	s4,8(sp)
    54ac:	00412a83          	lw	s5,4(sp)
    54b0:	02010113          	add	sp,sp,32
    54b4:	00008067          	ret

000054b8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    54b8:	fe010113          	add	sp,sp,-32
    54bc:	00812c23          	sw	s0,24(sp)
    54c0:	00912a23          	sw	s1,20(sp)
    54c4:	01212823          	sw	s2,16(sp)
    54c8:	01312623          	sw	s3,12(sp)
    54cc:	00112e23          	sw	ra,28(sp)
    54d0:	02010413          	add	s0,sp,32
    54d4:	00050913          	mv	s2,a0
  acquire(&bcache.lock);
    54d8:	00013517          	auipc	a0,0x13
    54dc:	21850513          	add	a0,a0,536 # 186f0 <bcache>
{
    54e0:	00058993          	mv	s3,a1
  acquire(&bcache.lock);
    54e4:	ffffc097          	auipc	ra,0xffffc
    54e8:	c8c080e7          	jalr	-884(ra) # 1170 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    54ec:	0001b697          	auipc	a3,0x1b
    54f0:	20468693          	add	a3,a3,516 # 206f0 <bcache+0x8000>
    54f4:	ecc6a483          	lw	s1,-308(a3)
    54f8:	0001b797          	auipc	a5,0x1b
    54fc:	09478793          	add	a5,a5,148 # 2058c <bcache+0x7e9c>
    5500:	00f49863          	bne	s1,a5,5510 <bread+0x58>
    5504:	0840006f          	j	5588 <bread+0xd0>
    5508:	0304a483          	lw	s1,48(s1)
    550c:	06f48e63          	beq	s1,a5,5588 <bread+0xd0>
    if(b->dev == dev && b->blockno == blockno){
    5510:	0084a703          	lw	a4,8(s1)
    5514:	fee91ae3          	bne	s2,a4,5508 <bread+0x50>
    5518:	00c4a703          	lw	a4,12(s1)
    551c:	fee996e3          	bne	s3,a4,5508 <bread+0x50>
      b->refcnt++;
    5520:	0284a783          	lw	a5,40(s1)
      release(&bcache.lock);
    5524:	00013517          	auipc	a0,0x13
    5528:	1cc50513          	add	a0,a0,460 # 186f0 <bcache>
      b->refcnt++;
    552c:	00178793          	add	a5,a5,1
    5530:	02f4a423          	sw	a5,40(s1)
      release(&bcache.lock);
    5534:	ffffc097          	auipc	ra,0xffffc
    5538:	dc8080e7          	jalr	-568(ra) # 12fc <release>
      acquiresleep(&b->lock);
    553c:	01048513          	add	a0,s1,16
    5540:	00002097          	auipc	ra,0x2
    5544:	360080e7          	jalr	864(ra) # 78a0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    5548:	0004a783          	lw	a5,0(s1)
    554c:	08079863          	bnez	a5,55dc <bread+0x124>
    virtio_disk_rw(b, 0);
    5550:	00048513          	mv	a0,s1
    5554:	00000593          	li	a1,0
    5558:	00005097          	auipc	ra,0x5
    555c:	97c080e7          	jalr	-1668(ra) # 9ed4 <virtio_disk_rw>
    b->valid = 1;
  }
  return b;
}
    5560:	01c12083          	lw	ra,28(sp)
    5564:	01812403          	lw	s0,24(sp)
    b->valid = 1;
    5568:	00100793          	li	a5,1
    556c:	00f4a023          	sw	a5,0(s1)
}
    5570:	01012903          	lw	s2,16(sp)
    5574:	00c12983          	lw	s3,12(sp)
    5578:	00048513          	mv	a0,s1
    557c:	01412483          	lw	s1,20(sp)
    5580:	02010113          	add	sp,sp,32
    5584:	00008067          	ret
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    5588:	ec86a483          	lw	s1,-312(a3)
    558c:	00f49863          	bne	s1,a5,559c <bread+0xe4>
    5590:	06c0006f          	j	55fc <bread+0x144>
    5594:	02c4a483          	lw	s1,44(s1)
    5598:	06f48263          	beq	s1,a5,55fc <bread+0x144>
    if(b->refcnt == 0) {
    559c:	0284a703          	lw	a4,40(s1)
    55a0:	fe071ae3          	bnez	a4,5594 <bread+0xdc>
      b->refcnt = 1;
    55a4:	00100793          	li	a5,1
    55a8:	02f4a423          	sw	a5,40(s1)
      release(&bcache.lock);
    55ac:	00013517          	auipc	a0,0x13
    55b0:	14450513          	add	a0,a0,324 # 186f0 <bcache>
      b->dev = dev;
    55b4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    55b8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    55bc:	0004a023          	sw	zero,0(s1)
      release(&bcache.lock);
    55c0:	ffffc097          	auipc	ra,0xffffc
    55c4:	d3c080e7          	jalr	-708(ra) # 12fc <release>
      acquiresleep(&b->lock);
    55c8:	01048513          	add	a0,s1,16
    55cc:	00002097          	auipc	ra,0x2
    55d0:	2d4080e7          	jalr	724(ra) # 78a0 <acquiresleep>
  if(!b->valid) {
    55d4:	0004a783          	lw	a5,0(s1)
    55d8:	f6078ce3          	beqz	a5,5550 <bread+0x98>
}
    55dc:	01c12083          	lw	ra,28(sp)
    55e0:	01812403          	lw	s0,24(sp)
    55e4:	01012903          	lw	s2,16(sp)
    55e8:	00c12983          	lw	s3,12(sp)
    55ec:	00048513          	mv	a0,s1
    55f0:	01412483          	lw	s1,20(sp)
    55f4:	02010113          	add	sp,sp,32
    55f8:	00008067          	ret
  panic("bget: no buffers");
    55fc:	00006517          	auipc	a0,0x6
    5600:	fb850513          	add	a0,a0,-72 # b5b4 <main+0x484>
    5604:	ffffb097          	auipc	ra,0xffffb
    5608:	0d0080e7          	jalr	208(ra) # 6d4 <panic>

0000560c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    560c:	ff010113          	add	sp,sp,-16
    5610:	00812423          	sw	s0,8(sp)
    5614:	00912223          	sw	s1,4(sp)
    5618:	00112623          	sw	ra,12(sp)
    561c:	01010413          	add	s0,sp,16
    5620:	00050493          	mv	s1,a0
  if(!holdingsleep(&b->lock))
    5624:	01050513          	add	a0,a0,16
    5628:	00002097          	auipc	ra,0x2
    562c:	35c080e7          	jalr	860(ra) # 7984 <holdingsleep>
    5630:	02050263          	beqz	a0,5654 <bwrite+0x48>
    panic("bwrite");
  virtio_disk_rw(b, 1);
}
    5634:	00812403          	lw	s0,8(sp)
    5638:	00c12083          	lw	ra,12(sp)
  virtio_disk_rw(b, 1);
    563c:	00048513          	mv	a0,s1
}
    5640:	00412483          	lw	s1,4(sp)
  virtio_disk_rw(b, 1);
    5644:	00100593          	li	a1,1
}
    5648:	01010113          	add	sp,sp,16
  virtio_disk_rw(b, 1);
    564c:	00005317          	auipc	t1,0x5
    5650:	88830067          	jr	-1912(t1) # 9ed4 <virtio_disk_rw>
    panic("bwrite");
    5654:	00006517          	auipc	a0,0x6
    5658:	f7450513          	add	a0,a0,-140 # b5c8 <main+0x498>
    565c:	ffffb097          	auipc	ra,0xffffb
    5660:	078080e7          	jalr	120(ra) # 6d4 <panic>

00005664 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    5664:	ff010113          	add	sp,sp,-16
    5668:	00812423          	sw	s0,8(sp)
    566c:	00912223          	sw	s1,4(sp)
    5670:	01212023          	sw	s2,0(sp)
    5674:	00112623          	sw	ra,12(sp)
    5678:	01010413          	add	s0,sp,16
  if(!holdingsleep(&b->lock))
    567c:	01050913          	add	s2,a0,16
{
    5680:	00050493          	mv	s1,a0
  if(!holdingsleep(&b->lock))
    5684:	00090513          	mv	a0,s2
    5688:	00002097          	auipc	ra,0x2
    568c:	2fc080e7          	jalr	764(ra) # 7984 <holdingsleep>
    5690:	08050463          	beqz	a0,5718 <brelse+0xb4>
    panic("brelse");

  releasesleep(&b->lock);
    5694:	00090513          	mv	a0,s2
    5698:	00002097          	auipc	ra,0x2
    569c:	28c080e7          	jalr	652(ra) # 7924 <releasesleep>

  acquire(&bcache.lock);
    56a0:	00013517          	auipc	a0,0x13
    56a4:	05050513          	add	a0,a0,80 # 186f0 <bcache>
    56a8:	ffffc097          	auipc	ra,0xffffc
    56ac:	ac8080e7          	jalr	-1336(ra) # 1170 <acquire>
  b->refcnt--;
    56b0:	0284a783          	lw	a5,40(s1)
    56b4:	fff78793          	add	a5,a5,-1
    56b8:	02f4a423          	sw	a5,40(s1)
  if (b->refcnt == 0) {
    56bc:	02079c63          	bnez	a5,56f4 <brelse+0x90>
    // no one is waiting for it.
    b->next->prev = b->prev;
    56c0:	0304a683          	lw	a3,48(s1)
    56c4:	02c4a703          	lw	a4,44(s1)
    b->prev->next = b->next;
    b->next = bcache.head.next;
    56c8:	0001b797          	auipc	a5,0x1b
    56cc:	02878793          	add	a5,a5,40 # 206f0 <bcache+0x8000>
    b->next->prev = b->prev;
    56d0:	02e6a623          	sw	a4,44(a3)
    b->prev->next = b->next;
    56d4:	02d72823          	sw	a3,48(a4)
    b->next = bcache.head.next;
    56d8:	ecc7a703          	lw	a4,-308(a5)
    b->prev = &bcache.head;
    56dc:	0001b697          	auipc	a3,0x1b
    56e0:	eb068693          	add	a3,a3,-336 # 2058c <bcache+0x7e9c>
    56e4:	02d4a623          	sw	a3,44(s1)
    b->next = bcache.head.next;
    56e8:	02e4a823          	sw	a4,48(s1)
    bcache.head.next->prev = b;
    56ec:	02972623          	sw	s1,44(a4)
    bcache.head.next = b;
    56f0:	ec97a623          	sw	s1,-308(a5)
  }
  
  release(&bcache.lock);
}
    56f4:	00812403          	lw	s0,8(sp)
    56f8:	00c12083          	lw	ra,12(sp)
    56fc:	00412483          	lw	s1,4(sp)
    5700:	00012903          	lw	s2,0(sp)
  release(&bcache.lock);
    5704:	00013517          	auipc	a0,0x13
    5708:	fec50513          	add	a0,a0,-20 # 186f0 <bcache>
}
    570c:	01010113          	add	sp,sp,16
  release(&bcache.lock);
    5710:	ffffc317          	auipc	t1,0xffffc
    5714:	bec30067          	jr	-1044(t1) # 12fc <release>
    panic("brelse");
    5718:	00006517          	auipc	a0,0x6
    571c:	eb850513          	add	a0,a0,-328 # b5d0 <main+0x4a0>
    5720:	ffffb097          	auipc	ra,0xffffb
    5724:	fb4080e7          	jalr	-76(ra) # 6d4 <panic>

00005728 <bpin>:

void
bpin(struct buf *b) {
    5728:	ff010113          	add	sp,sp,-16
    572c:	00812423          	sw	s0,8(sp)
    5730:	00912223          	sw	s1,4(sp)
    5734:	00112623          	sw	ra,12(sp)
    5738:	01010413          	add	s0,sp,16
    573c:	00050493          	mv	s1,a0
  acquire(&bcache.lock);
    5740:	00013517          	auipc	a0,0x13
    5744:	fb050513          	add	a0,a0,-80 # 186f0 <bcache>
    5748:	ffffc097          	auipc	ra,0xffffc
    574c:	a28080e7          	jalr	-1496(ra) # 1170 <acquire>
  b->refcnt++;
    5750:	0284a783          	lw	a5,40(s1)
  release(&bcache.lock);
}
    5754:	00812403          	lw	s0,8(sp)
    5758:	00c12083          	lw	ra,12(sp)
  b->refcnt++;
    575c:	00178793          	add	a5,a5,1
    5760:	02f4a423          	sw	a5,40(s1)
}
    5764:	00412483          	lw	s1,4(sp)
  release(&bcache.lock);
    5768:	00013517          	auipc	a0,0x13
    576c:	f8850513          	add	a0,a0,-120 # 186f0 <bcache>
}
    5770:	01010113          	add	sp,sp,16
  release(&bcache.lock);
    5774:	ffffc317          	auipc	t1,0xffffc
    5778:	b8830067          	jr	-1144(t1) # 12fc <release>

0000577c <bunpin>:

void
bunpin(struct buf *b) {
    577c:	ff010113          	add	sp,sp,-16
    5780:	00812423          	sw	s0,8(sp)
    5784:	00912223          	sw	s1,4(sp)
    5788:	00112623          	sw	ra,12(sp)
    578c:	01010413          	add	s0,sp,16
    5790:	00050493          	mv	s1,a0
  acquire(&bcache.lock);
    5794:	00013517          	auipc	a0,0x13
    5798:	f5c50513          	add	a0,a0,-164 # 186f0 <bcache>
    579c:	ffffc097          	auipc	ra,0xffffc
    57a0:	9d4080e7          	jalr	-1580(ra) # 1170 <acquire>
  b->refcnt--;
    57a4:	0284a783          	lw	a5,40(s1)
  release(&bcache.lock);
}
    57a8:	00812403          	lw	s0,8(sp)
    57ac:	00c12083          	lw	ra,12(sp)
  b->refcnt--;
    57b0:	fff78793          	add	a5,a5,-1
    57b4:	02f4a423          	sw	a5,40(s1)
}
    57b8:	00412483          	lw	s1,4(sp)
  release(&bcache.lock);
    57bc:	00013517          	auipc	a0,0x13
    57c0:	f3450513          	add	a0,a0,-204 # 186f0 <bcache>
}
    57c4:	01010113          	add	sp,sp,16
  release(&bcache.lock);
    57c8:	ffffc317          	auipc	t1,0xffffc
    57cc:	b3430067          	jr	-1228(t1) # 12fc <release>

000057d0 <balloc>:
// Blocks.

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
    57d0:	fd010113          	add	sp,sp,-48
    57d4:	02812423          	sw	s0,40(sp)
    57d8:	01612823          	sw	s6,16(sp)
    57dc:	02112623          	sw	ra,44(sp)
    57e0:	02912223          	sw	s1,36(sp)
    57e4:	03212023          	sw	s2,32(sp)
    57e8:	01312e23          	sw	s3,28(sp)
    57ec:	01412c23          	sw	s4,24(sp)
    57f0:	01512a23          	sw	s5,20(sp)
    57f4:	03010413          	add	s0,sp,48
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    57f8:	0001bb17          	auipc	s6,0x1b
    57fc:	1ccb0b13          	add	s6,s6,460 # 209c4 <sb>
    5800:	004b2783          	lw	a5,4(s6)
    5804:	06078c63          	beqz	a5,587c <balloc+0xac>
    5808:	00050913          	mv	s2,a0
    580c:	00000a93          	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
      m = 1 << (bi % 8);
    5810:	00100a13          	li	s4,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    5814:	000029b7          	lui	s3,0x2
    bp = bread(dev, BBLOCK(b, sb));
    5818:	01cb2783          	lw	a5,28(s6)
    581c:	40dad593          	sra	a1,s5,0xd
    5820:	00090513          	mv	a0,s2
    5824:	00f585b3          	add	a1,a1,a5
    5828:	00000097          	auipc	ra,0x0
    582c:	c90080e7          	jalr	-880(ra) # 54b8 <bread>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    5830:	004b2803          	lw	a6,4(s6)
    5834:	000a8493          	mv	s1,s5
    5838:	00000793          	li	a5,0
    583c:	0304f663          	bgeu	s1,a6,5868 <balloc+0x98>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    5840:	4037d713          	sra	a4,a5,0x3
    5844:	00e50733          	add	a4,a0,a4
    5848:	03874603          	lbu	a2,56(a4)
      m = 1 << (bi % 8);
    584c:	0077f693          	and	a3,a5,7
    5850:	00da16b3          	sll	a3,s4,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    5854:	00d675b3          	and	a1,a2,a3
    5858:	02058a63          	beqz	a1,588c <balloc+0xbc>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    585c:	00178793          	add	a5,a5,1
    5860:	00148493          	add	s1,s1,1
    5864:	fd379ce3          	bne	a5,s3,583c <balloc+0x6c>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
    5868:	00000097          	auipc	ra,0x0
    586c:	dfc080e7          	jalr	-516(ra) # 5664 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    5870:	004b2783          	lw	a5,4(s6)
    5874:	013a8ab3          	add	s5,s5,s3
    5878:	fafae0e3          	bltu	s5,a5,5818 <balloc+0x48>
  }
  panic("balloc: out of blocks");
    587c:	00006517          	auipc	a0,0x6
    5880:	d5c50513          	add	a0,a0,-676 # b5d8 <main+0x4a8>
    5884:	ffffb097          	auipc	ra,0xffffb
    5888:	e50080e7          	jalr	-432(ra) # 6d4 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    588c:	00d66633          	or	a2,a2,a3
    5890:	02c70c23          	sb	a2,56(a4)
        log_write(bp);
    5894:	fca42e23          	sw	a0,-36(s0)
    5898:	00002097          	auipc	ra,0x2
    589c:	e84080e7          	jalr	-380(ra) # 771c <log_write>
        brelse(bp);
    58a0:	fdc42503          	lw	a0,-36(s0)
    58a4:	00000097          	auipc	ra,0x0
    58a8:	dc0080e7          	jalr	-576(ra) # 5664 <brelse>
  bp = bread(dev, bno);
    58ac:	00048593          	mv	a1,s1
    58b0:	00090513          	mv	a0,s2
    58b4:	00000097          	auipc	ra,0x0
    58b8:	c04080e7          	jalr	-1020(ra) # 54b8 <bread>
    58bc:	00050913          	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    58c0:	40000613          	li	a2,1024
    58c4:	00000593          	li	a1,0
    58c8:	03850513          	add	a0,a0,56
    58cc:	ffffc097          	auipc	ra,0xffffc
    58d0:	db8080e7          	jalr	-584(ra) # 1684 <memset>
  log_write(bp);
    58d4:	00090513          	mv	a0,s2
    58d8:	00002097          	auipc	ra,0x2
    58dc:	e44080e7          	jalr	-444(ra) # 771c <log_write>
  brelse(bp);
    58e0:	00090513          	mv	a0,s2
    58e4:	00000097          	auipc	ra,0x0
    58e8:	d80080e7          	jalr	-640(ra) # 5664 <brelse>
}
    58ec:	02c12083          	lw	ra,44(sp)
    58f0:	02812403          	lw	s0,40(sp)
    58f4:	02012903          	lw	s2,32(sp)
    58f8:	01c12983          	lw	s3,28(sp)
    58fc:	01812a03          	lw	s4,24(sp)
    5900:	01412a83          	lw	s5,20(sp)
    5904:	01012b03          	lw	s6,16(sp)
    5908:	00048513          	mv	a0,s1
    590c:	02412483          	lw	s1,36(sp)
    5910:	03010113          	add	sp,sp,48
    5914:	00008067          	ret

00005918 <readi.constprop.0>:
readi(struct inode *ip, int user_dst, uint32 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    5918:	03052783          	lw	a5,48(a0)
    591c:	1ec7ec63          	bltu	a5,a2,5b14 <readi.constprop.0+0x1fc>
readi(struct inode *ip, int user_dst, uint32 dst, uint off, uint n)
    5920:	fb010113          	add	sp,sp,-80
    5924:	04812423          	sw	s0,72(sp)
    5928:	04912223          	sw	s1,68(sp)
    592c:	04112623          	sw	ra,76(sp)
    5930:	05212023          	sw	s2,64(sp)
    5934:	03312e23          	sw	s3,60(sp)
    5938:	03412c23          	sw	s4,56(sp)
    593c:	03512a23          	sw	s5,52(sp)
    5940:	03612823          	sw	s6,48(sp)
    5944:	03712623          	sw	s7,44(sp)
    5948:	03812423          	sw	s8,40(sp)
    594c:	03912223          	sw	s9,36(sp)
    5950:	03a12023          	sw	s10,32(sp)
    5954:	01b12e23          	sw	s11,28(sp)
    5958:	05010413          	add	s0,sp,80
    595c:	01060713          	add	a4,a2,16
    5960:	00060493          	mv	s1,a2
    5964:	1cc76463          	bltu	a4,a2,5b2c <readi.constprop.0+0x214>
    5968:	00050a13          	mv	s4,a0
    596c:	00058993          	mv	s3,a1
    5970:	00000913          	li	s2,0
    return -1;
  if(off + n > ip->size)
    5974:	0ee7ea63          	bltu	a5,a4,5a68 <readi.constprop.0+0x150>
    5978:	01000b13          	li	s6,16
  if(bn < NDIRECT){
    597c:	00b00b93          	li	s7,11
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    5980:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    5984:	fff00c13          	li	s8,-1
    5988:	0ac0006f          	j	5a34 <readi.constprop.0+0x11c>
  bn -= NDIRECT;
    598c:	ff478d93          	add	s11,a5,-12
  if(bn < NINDIRECT){
    5990:	0ff00793          	li	a5,255
    5994:	19b7e463          	bltu	a5,s11,5b1c <readi.constprop.0+0x204>
    if((addr = ip->addrs[NDIRECT]) == 0)
    5998:	064a2583          	lw	a1,100(s4)
    599c:	000a8513          	mv	a0,s5
    59a0:	10058463          	beqz	a1,5aa8 <readi.constprop.0+0x190>
    bp = bread(ip->dev, addr);
    59a4:	00000097          	auipc	ra,0x0
    59a8:	b14080e7          	jalr	-1260(ra) # 54b8 <bread>
    a = (uint*)bp->data;
    59ac:	03850693          	add	a3,a0,56
    if((addr = a[bn]) == 0){
    59b0:	002d9793          	sll	a5,s11,0x2
    59b4:	00f68db3          	add	s11,a3,a5
    59b8:	000dad03          	lw	s10,0(s11)
    bp = bread(ip->dev, addr);
    59bc:	00050713          	mv	a4,a0
    if((addr = a[bn]) == 0){
    59c0:	0a0d0c63          	beqz	s10,5a78 <readi.constprop.0+0x160>
    brelse(bp);
    59c4:	00070513          	mv	a0,a4
    59c8:	00000097          	auipc	ra,0x0
    59cc:	c9c080e7          	jalr	-868(ra) # 5664 <brelse>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    59d0:	000a8513          	mv	a0,s5
    59d4:	000d0593          	mv	a1,s10
    59d8:	00000097          	auipc	ra,0x0
    59dc:	ae0080e7          	jalr	-1312(ra) # 54b8 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
    59e0:	3ff4f793          	and	a5,s1,1023
    59e4:	412b0733          	sub	a4,s6,s2
    59e8:	40fc8ab3          	sub	s5,s9,a5
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    59ec:	00050d93          	mv	s11,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    59f0:	01577463          	bgeu	a4,s5,59f8 <readi.constprop.0+0xe0>
    59f4:	00070a93          	mv	s5,a4
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    59f8:	038d8613          	add	a2,s11,56
    59fc:	000a8693          	mv	a3,s5
    5a00:	00f60633          	add	a2,a2,a5
    5a04:	00098593          	mv	a1,s3
    5a08:	00000513          	li	a0,0
    5a0c:	fffff097          	auipc	ra,0xfffff
    5a10:	8b8080e7          	jalr	-1864(ra) # 42c4 <either_copyout>
    5a14:	0b850663          	beq	a0,s8,5ac0 <readi.constprop.0+0x1a8>
      brelse(bp);
      break;
    }
    brelse(bp);
    5a18:	000d8513          	mv	a0,s11
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    5a1c:	01590933          	add	s2,s2,s5
    brelse(bp);
    5a20:	00000097          	auipc	ra,0x0
    5a24:	c44080e7          	jalr	-956(ra) # 5664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    5a28:	015484b3          	add	s1,s1,s5
    5a2c:	015989b3          	add	s3,s3,s5
    5a30:	0d697e63          	bgeu	s2,s6,5b0c <readi.constprop.0+0x1f4>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    5a34:	00a4d793          	srl	a5,s1,0xa
    5a38:	000a2a83          	lw	s5,0(s4)
  if(bn < NDIRECT){
    5a3c:	f4fbe8e3          	bltu	s7,a5,598c <readi.constprop.0+0x74>
    if((addr = ip->addrs[bn]) == 0)
    5a40:	00279793          	sll	a5,a5,0x2
    5a44:	00fa0db3          	add	s11,s4,a5
    5a48:	034dad03          	lw	s10,52(s11)
    5a4c:	f80d12e3          	bnez	s10,59d0 <readi.constprop.0+0xb8>
      ip->addrs[bn] = addr = balloc(ip->dev);
    5a50:	000a8513          	mv	a0,s5
    5a54:	00000097          	auipc	ra,0x0
    5a58:	d7c080e7          	jalr	-644(ra) # 57d0 <balloc>
    5a5c:	00050d13          	mv	s10,a0
    5a60:	02adaa23          	sw	a0,52(s11)
    5a64:	f6dff06f          	j	59d0 <readi.constprop.0+0xb8>
    n = ip->size - off;
    5a68:	40c78b33          	sub	s6,a5,a2
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    5a6c:	f0c798e3          	bne	a5,a2,597c <readi.constprop.0+0x64>
    5a70:	00000513          	li	a0,0
  }
  return n;
    5a74:	05c0006f          	j	5ad0 <readi.constprop.0+0x1b8>
      a[bn] = addr = balloc(ip->dev);
    5a78:	faa42e23          	sw	a0,-68(s0)
    5a7c:	000a2503          	lw	a0,0(s4)
    5a80:	00000097          	auipc	ra,0x0
    5a84:	d50080e7          	jalr	-688(ra) # 57d0 <balloc>
      log_write(bp);
    5a88:	fbc42703          	lw	a4,-68(s0)
      a[bn] = addr = balloc(ip->dev);
    5a8c:	00ada023          	sw	a0,0(s11)
    5a90:	00050d13          	mv	s10,a0
      log_write(bp);
    5a94:	00070513          	mv	a0,a4
    5a98:	00002097          	auipc	ra,0x2
    5a9c:	c84080e7          	jalr	-892(ra) # 771c <log_write>
    5aa0:	fbc42703          	lw	a4,-68(s0)
    5aa4:	f21ff06f          	j	59c4 <readi.constprop.0+0xac>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    5aa8:	00000097          	auipc	ra,0x0
    5aac:	d28080e7          	jalr	-728(ra) # 57d0 <balloc>
    5ab0:	00050593          	mv	a1,a0
    5ab4:	06ba2223          	sw	a1,100(s4)
    bp = bread(ip->dev, addr);
    5ab8:	000a2503          	lw	a0,0(s4)
    5abc:	ee9ff06f          	j	59a4 <readi.constprop.0+0x8c>
      brelse(bp);
    5ac0:	000d8513          	mv	a0,s11
    5ac4:	00000097          	auipc	ra,0x0
    5ac8:	ba0080e7          	jalr	-1120(ra) # 5664 <brelse>
  return n;
    5acc:	000b0513          	mv	a0,s6
}
    5ad0:	04c12083          	lw	ra,76(sp)
    5ad4:	04812403          	lw	s0,72(sp)
    5ad8:	04412483          	lw	s1,68(sp)
    5adc:	04012903          	lw	s2,64(sp)
    5ae0:	03c12983          	lw	s3,60(sp)
    5ae4:	03812a03          	lw	s4,56(sp)
    5ae8:	03412a83          	lw	s5,52(sp)
    5aec:	03012b03          	lw	s6,48(sp)
    5af0:	02c12b83          	lw	s7,44(sp)
    5af4:	02812c03          	lw	s8,40(sp)
    5af8:	02412c83          	lw	s9,36(sp)
    5afc:	02012d03          	lw	s10,32(sp)
    5b00:	01c12d83          	lw	s11,28(sp)
    5b04:	05010113          	add	sp,sp,80
    5b08:	00008067          	ret
  return n;
    5b0c:	000b0513          	mv	a0,s6
    5b10:	fc1ff06f          	j	5ad0 <readi.constprop.0+0x1b8>
    return -1;
    5b14:	fff00513          	li	a0,-1
}
    5b18:	00008067          	ret
  panic("bmap: out of range");
    5b1c:	00006517          	auipc	a0,0x6
    5b20:	ad450513          	add	a0,a0,-1324 # b5f0 <main+0x4c0>
    5b24:	ffffb097          	auipc	ra,0xffffb
    5b28:	bb0080e7          	jalr	-1104(ra) # 6d4 <panic>
    return -1;
    5b2c:	fff00513          	li	a0,-1
    5b30:	fa1ff06f          	j	5ad0 <readi.constprop.0+0x1b8>

00005b34 <fsinit>:
fsinit(int dev) {
    5b34:	fe010113          	add	sp,sp,-32
    5b38:	00112e23          	sw	ra,28(sp)
    5b3c:	00812c23          	sw	s0,24(sp)
    5b40:	00912a23          	sw	s1,20(sp)
    5b44:	02010413          	add	s0,sp,32
    5b48:	01212823          	sw	s2,16(sp)
    5b4c:	01312623          	sw	s3,12(sp)
  bp = bread(dev, 1);
    5b50:	00100593          	li	a1,1
  memmove(sb, bp->data, sizeof(*sb));
    5b54:	0001b997          	auipc	s3,0x1b
    5b58:	e7098993          	add	s3,s3,-400 # 209c4 <sb>
fsinit(int dev) {
    5b5c:	00050913          	mv	s2,a0
  bp = bread(dev, 1);
    5b60:	00000097          	auipc	ra,0x0
    5b64:	958080e7          	jalr	-1704(ra) # 54b8 <bread>
  memmove(sb, bp->data, sizeof(*sb));
    5b68:	03850593          	add	a1,a0,56
  bp = bread(dev, 1);
    5b6c:	00050493          	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    5b70:	02000613          	li	a2,32
    5b74:	00098513          	mv	a0,s3
    5b78:	ffffc097          	auipc	ra,0xffffc
    5b7c:	c8c080e7          	jalr	-884(ra) # 1804 <memmove>
  brelse(bp);
    5b80:	00048513          	mv	a0,s1
    5b84:	00000097          	auipc	ra,0x0
    5b88:	ae0080e7          	jalr	-1312(ra) # 5664 <brelse>
  if(sb.magic != FSMAGIC)
    5b8c:	0009a703          	lw	a4,0(s3)
    5b90:	102037b7          	lui	a5,0x10203
    5b94:	04078793          	add	a5,a5,64 # 10203040 <end+0x101df02c>
    5b98:	02f71663          	bne	a4,a5,5bc4 <fsinit+0x90>
}
    5b9c:	01812403          	lw	s0,24(sp)
    5ba0:	01c12083          	lw	ra,28(sp)
    5ba4:	01412483          	lw	s1,20(sp)
  initlog(dev, &sb);
    5ba8:	00098593          	mv	a1,s3
    5bac:	00090513          	mv	a0,s2
}
    5bb0:	00c12983          	lw	s3,12(sp)
    5bb4:	01012903          	lw	s2,16(sp)
    5bb8:	02010113          	add	sp,sp,32
  initlog(dev, &sb);
    5bbc:	00001317          	auipc	t1,0x1
    5bc0:	76430067          	jr	1892(t1) # 7320 <initlog>
    panic("invalid file system");
    5bc4:	00006517          	auipc	a0,0x6
    5bc8:	a4050513          	add	a0,a0,-1472 # b604 <main+0x4d4>
    5bcc:	ffffb097          	auipc	ra,0xffffb
    5bd0:	b08080e7          	jalr	-1272(ra) # 6d4 <panic>

00005bd4 <iinit>:
{
    5bd4:	fe010113          	add	sp,sp,-32
    5bd8:	00812c23          	sw	s0,24(sp)
    5bdc:	00912a23          	sw	s1,20(sp)
    5be0:	01212823          	sw	s2,16(sp)
    5be4:	01312623          	sw	s3,12(sp)
    5be8:	00112e23          	sw	ra,28(sp)
    5bec:	02010413          	add	s0,sp,32
  initlock(&icache.lock, "icache");
    5bf0:	00006597          	auipc	a1,0x6
    5bf4:	a2858593          	add	a1,a1,-1496 # b618 <main+0x4e8>
    5bf8:	0001b517          	auipc	a0,0x1b
    5bfc:	dec50513          	add	a0,a0,-532 # 209e4 <icache>
    5c00:	ffffb097          	auipc	ra,0xffffb
    5c04:	54c080e7          	jalr	1356(ra) # 114c <initlock>
  for(i = 0; i < NINODE; i++) {
    5c08:	0001b497          	auipc	s1,0x1b
    5c0c:	df448493          	add	s1,s1,-524 # 209fc <icache+0x18>
    5c10:	0001c997          	auipc	s3,0x1c
    5c14:	23c98993          	add	s3,s3,572 # 21e4c <log+0xc>
    initsleeplock(&icache.inode[i].lock, "inode");
    5c18:	00006917          	auipc	s2,0x6
    5c1c:	a0890913          	add	s2,s2,-1528 # b620 <main+0x4f0>
    5c20:	00048513          	mv	a0,s1
    5c24:	00090593          	mv	a1,s2
  for(i = 0; i < NINODE; i++) {
    5c28:	06848493          	add	s1,s1,104
    initsleeplock(&icache.inode[i].lock, "inode");
    5c2c:	00002097          	auipc	ra,0x2
    5c30:	c1c080e7          	jalr	-996(ra) # 7848 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    5c34:	ff3496e3          	bne	s1,s3,5c20 <iinit+0x4c>
}
    5c38:	01c12083          	lw	ra,28(sp)
    5c3c:	01812403          	lw	s0,24(sp)
    5c40:	01412483          	lw	s1,20(sp)
    5c44:	01012903          	lw	s2,16(sp)
    5c48:	00c12983          	lw	s3,12(sp)
    5c4c:	02010113          	add	sp,sp,32
    5c50:	00008067          	ret

00005c54 <ialloc>:
{
    5c54:	fe010113          	add	sp,sp,-32
    5c58:	00812c23          	sw	s0,24(sp)
    5c5c:	01612023          	sw	s6,0(sp)
    5c60:	00112e23          	sw	ra,28(sp)
    5c64:	00912a23          	sw	s1,20(sp)
    5c68:	01212823          	sw	s2,16(sp)
    5c6c:	01312623          	sw	s3,12(sp)
    5c70:	01412423          	sw	s4,8(sp)
    5c74:	01512223          	sw	s5,4(sp)
    5c78:	02010413          	add	s0,sp,32
  for(inum = 1; inum < sb.ninodes; inum++){
    5c7c:	0001bb17          	auipc	s6,0x1b
    5c80:	d48b0b13          	add	s6,s6,-696 # 209c4 <sb>
    5c84:	00cb2703          	lw	a4,12(s6)
    5c88:	00100793          	li	a5,1
    5c8c:	16e7f863          	bgeu	a5,a4,5dfc <ialloc+0x1a8>
    5c90:	00050a13          	mv	s4,a0
    5c94:	00058a93          	mv	s5,a1
    5c98:	00100493          	li	s1,1
    5c9c:	0180006f          	j	5cb4 <ialloc+0x60>
    brelse(bp);
    5ca0:	00000097          	auipc	ra,0x0
    5ca4:	9c4080e7          	jalr	-1596(ra) # 5664 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    5ca8:	00cb2783          	lw	a5,12(s6)
    5cac:	00148493          	add	s1,s1,1
    5cb0:	14f4f663          	bgeu	s1,a5,5dfc <ialloc+0x1a8>
    bp = bread(dev, IBLOCK(inum, sb));
    5cb4:	018b2783          	lw	a5,24(s6)
    5cb8:	0044d593          	srl	a1,s1,0x4
    5cbc:	000a0513          	mv	a0,s4
    5cc0:	00f585b3          	add	a1,a1,a5
    5cc4:	fffff097          	auipc	ra,0xfffff
    5cc8:	7f4080e7          	jalr	2036(ra) # 54b8 <bread>
    dip = (struct dinode*)bp->data + inum%IPB;
    5ccc:	00f4f793          	and	a5,s1,15
    5cd0:	00679793          	sll	a5,a5,0x6
    5cd4:	03850993          	add	s3,a0,56
    5cd8:	00f989b3          	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    5cdc:	00099783          	lh	a5,0(s3)
    bp = bread(dev, IBLOCK(inum, sb));
    5ce0:	00050913          	mv	s2,a0
    if(dip->type == 0){  // a free inode
    5ce4:	fa079ee3          	bnez	a5,5ca0 <ialloc+0x4c>
      memset(dip, 0, sizeof(*dip));
    5ce8:	04000613          	li	a2,64
    5cec:	00000593          	li	a1,0
    5cf0:	00098513          	mv	a0,s3
    5cf4:	ffffc097          	auipc	ra,0xffffc
    5cf8:	990080e7          	jalr	-1648(ra) # 1684 <memset>
      log_write(bp);   // mark it allocated on the disk
    5cfc:	00090513          	mv	a0,s2
      dip->type = type;
    5d00:	01599023          	sh	s5,0(s3)
      log_write(bp);   // mark it allocated on the disk
    5d04:	00002097          	auipc	ra,0x2
    5d08:	a18080e7          	jalr	-1512(ra) # 771c <log_write>
      brelse(bp);
    5d0c:	00090513          	mv	a0,s2
    5d10:	00000097          	auipc	ra,0x0
    5d14:	954080e7          	jalr	-1708(ra) # 5664 <brelse>
  acquire(&icache.lock);
    5d18:	0001b517          	auipc	a0,0x1b
    5d1c:	ccc50513          	add	a0,a0,-820 # 209e4 <icache>
    5d20:	ffffb097          	auipc	ra,0xffffb
    5d24:	450080e7          	jalr	1104(ra) # 1170 <acquire>
  empty = 0;
    5d28:	00000913          	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    5d2c:	0001b797          	auipc	a5,0x1b
    5d30:	cc478793          	add	a5,a5,-828 # 209f0 <icache+0xc>
    5d34:	0001c617          	auipc	a2,0x1c
    5d38:	10c60613          	add	a2,a2,268 # 21e40 <log>
    5d3c:	0140006f          	j	5d50 <ialloc+0xfc>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    5d40:	0007a683          	lw	a3,0(a5)
    5d44:	06da0e63          	beq	s4,a3,5dc0 <ialloc+0x16c>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    5d48:	06878793          	add	a5,a5,104
    5d4c:	02c78063          	beq	a5,a2,5d6c <ialloc+0x118>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    5d50:	0087a703          	lw	a4,8(a5)
    5d54:	fee046e3          	bgtz	a4,5d40 <ialloc+0xec>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    5d58:	fe0918e3          	bnez	s2,5d48 <ialloc+0xf4>
    5d5c:	08071663          	bnez	a4,5de8 <ialloc+0x194>
    5d60:	00078913          	mv	s2,a5
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    5d64:	06878793          	add	a5,a5,104
    5d68:	fec794e3          	bne	a5,a2,5d50 <ialloc+0xfc>
  if(empty == 0)
    5d6c:	0a090063          	beqz	s2,5e0c <ialloc+0x1b8>
  ip->ref = 1;
    5d70:	00100793          	li	a5,1
  ip->dev = dev;
    5d74:	01492023          	sw	s4,0(s2)
  ip->inum = inum;
    5d78:	00992223          	sw	s1,4(s2)
  ip->ref = 1;
    5d7c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    5d80:	02092223          	sw	zero,36(s2)
  release(&icache.lock);
    5d84:	0001b517          	auipc	a0,0x1b
    5d88:	c6050513          	add	a0,a0,-928 # 209e4 <icache>
    5d8c:	ffffb097          	auipc	ra,0xffffb
    5d90:	570080e7          	jalr	1392(ra) # 12fc <release>
}
    5d94:	01c12083          	lw	ra,28(sp)
    5d98:	01812403          	lw	s0,24(sp)
    5d9c:	01412483          	lw	s1,20(sp)
    5da0:	00c12983          	lw	s3,12(sp)
    5da4:	00812a03          	lw	s4,8(sp)
    5da8:	00412a83          	lw	s5,4(sp)
    5dac:	00012b03          	lw	s6,0(sp)
    5db0:	00090513          	mv	a0,s2
    5db4:	01012903          	lw	s2,16(sp)
    5db8:	02010113          	add	sp,sp,32
    5dbc:	00008067          	ret
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    5dc0:	0047a683          	lw	a3,4(a5)
    5dc4:	f89692e3          	bne	a3,s1,5d48 <ialloc+0xf4>
      ip->ref++;
    5dc8:	00170713          	add	a4,a4,1
      release(&icache.lock);
    5dcc:	0001b517          	auipc	a0,0x1b
    5dd0:	c1850513          	add	a0,a0,-1000 # 209e4 <icache>
      ip->ref++;
    5dd4:	00e7a423          	sw	a4,8(a5)
      return ip;
    5dd8:	00078913          	mv	s2,a5
      release(&icache.lock);
    5ddc:	ffffb097          	auipc	ra,0xffffb
    5de0:	520080e7          	jalr	1312(ra) # 12fc <release>
      return ip;
    5de4:	fb1ff06f          	j	5d94 <ialloc+0x140>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    5de8:	06878793          	add	a5,a5,104
    5dec:	02c78063          	beq	a5,a2,5e0c <ialloc+0x1b8>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    5df0:	0087a703          	lw	a4,8(a5)
    5df4:	f4e046e3          	bgtz	a4,5d40 <ialloc+0xec>
    5df8:	f65ff06f          	j	5d5c <ialloc+0x108>
  panic("ialloc: no inodes");
    5dfc:	00006517          	auipc	a0,0x6
    5e00:	83c50513          	add	a0,a0,-1988 # b638 <main+0x508>
    5e04:	ffffb097          	auipc	ra,0xffffb
    5e08:	8d0080e7          	jalr	-1840(ra) # 6d4 <panic>
    panic("iget: no inodes");
    5e0c:	00006517          	auipc	a0,0x6
    5e10:	81c50513          	add	a0,a0,-2020 # b628 <main+0x4f8>
    5e14:	ffffb097          	auipc	ra,0xffffb
    5e18:	8c0080e7          	jalr	-1856(ra) # 6d4 <panic>

00005e1c <iupdate>:
{
    5e1c:	ff010113          	add	sp,sp,-16
    5e20:	00112623          	sw	ra,12(sp)
    5e24:	00812423          	sw	s0,8(sp)
    5e28:	00912223          	sw	s1,4(sp)
    5e2c:	01010413          	add	s0,sp,16
    5e30:	01212023          	sw	s2,0(sp)
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    5e34:	00452783          	lw	a5,4(a0)
{
    5e38:	00050493          	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    5e3c:	00052503          	lw	a0,0(a0)
    5e40:	0047d793          	srl	a5,a5,0x4
    5e44:	0001b597          	auipc	a1,0x1b
    5e48:	b985a583          	lw	a1,-1128(a1) # 209dc <sb+0x18>
    5e4c:	00b785b3          	add	a1,a5,a1
    5e50:	fffff097          	auipc	ra,0xfffff
    5e54:	668080e7          	jalr	1640(ra) # 54b8 <bread>
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    5e58:	0044a783          	lw	a5,4(s1)
  dip->type = ip->type;
    5e5c:	0284a883          	lw	a7,40(s1)
    5e60:	02c4a803          	lw	a6,44(s1)
  dip->size = ip->size;
    5e64:	0304a683          	lw	a3,48(s1)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    5e68:	00f7f793          	and	a5,a5,15
    5e6c:	00679713          	sll	a4,a5,0x6
    5e70:	03850793          	add	a5,a0,56
    5e74:	00e787b3          	add	a5,a5,a4
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    5e78:	00050913          	mv	s2,a0
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    5e7c:	03448593          	add	a1,s1,52
    5e80:	03400613          	li	a2,52
  dip->type = ip->type;
    5e84:	0117a023          	sw	a7,0(a5)
    5e88:	0107a223          	sw	a6,4(a5)
  dip->size = ip->size;
    5e8c:	00d7a423          	sw	a3,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    5e90:	00c78513          	add	a0,a5,12
    5e94:	ffffc097          	auipc	ra,0xffffc
    5e98:	970080e7          	jalr	-1680(ra) # 1804 <memmove>
  log_write(bp);
    5e9c:	00090513          	mv	a0,s2
    5ea0:	00002097          	auipc	ra,0x2
    5ea4:	87c080e7          	jalr	-1924(ra) # 771c <log_write>
}
    5ea8:	00812403          	lw	s0,8(sp)
    5eac:	00c12083          	lw	ra,12(sp)
    5eb0:	00412483          	lw	s1,4(sp)
  brelse(bp);
    5eb4:	00090513          	mv	a0,s2
}
    5eb8:	00012903          	lw	s2,0(sp)
    5ebc:	01010113          	add	sp,sp,16
  brelse(bp);
    5ec0:	fffff317          	auipc	t1,0xfffff
    5ec4:	7a430067          	jr	1956(t1) # 5664 <brelse>

00005ec8 <idup>:
{
    5ec8:	ff010113          	add	sp,sp,-16
    5ecc:	00112623          	sw	ra,12(sp)
    5ed0:	00812423          	sw	s0,8(sp)
    5ed4:	00912223          	sw	s1,4(sp)
    5ed8:	01010413          	add	s0,sp,16
    5edc:	00050493          	mv	s1,a0
  acquire(&icache.lock);
    5ee0:	0001b517          	auipc	a0,0x1b
    5ee4:	b0450513          	add	a0,a0,-1276 # 209e4 <icache>
    5ee8:	ffffb097          	auipc	ra,0xffffb
    5eec:	288080e7          	jalr	648(ra) # 1170 <acquire>
  ip->ref++;
    5ef0:	0084a783          	lw	a5,8(s1)
  release(&icache.lock);
    5ef4:	0001b517          	auipc	a0,0x1b
    5ef8:	af050513          	add	a0,a0,-1296 # 209e4 <icache>
  ip->ref++;
    5efc:	00178793          	add	a5,a5,1
    5f00:	00f4a423          	sw	a5,8(s1)
  release(&icache.lock);
    5f04:	ffffb097          	auipc	ra,0xffffb
    5f08:	3f8080e7          	jalr	1016(ra) # 12fc <release>
}
    5f0c:	00c12083          	lw	ra,12(sp)
    5f10:	00812403          	lw	s0,8(sp)
    5f14:	00048513          	mv	a0,s1
    5f18:	00412483          	lw	s1,4(sp)
    5f1c:	01010113          	add	sp,sp,16
    5f20:	00008067          	ret

00005f24 <ilock>:
{
    5f24:	ff010113          	add	sp,sp,-16
    5f28:	00812423          	sw	s0,8(sp)
    5f2c:	00112623          	sw	ra,12(sp)
    5f30:	00912223          	sw	s1,4(sp)
    5f34:	01212023          	sw	s2,0(sp)
    5f38:	01010413          	add	s0,sp,16
  if(ip == 0 || ip->ref < 1)
    5f3c:	0c050663          	beqz	a0,6008 <ilock+0xe4>
    5f40:	00852783          	lw	a5,8(a0)
    5f44:	00050493          	mv	s1,a0
    5f48:	0cf05063          	blez	a5,6008 <ilock+0xe4>
  acquiresleep(&ip->lock);
    5f4c:	00c50513          	add	a0,a0,12
    5f50:	00002097          	auipc	ra,0x2
    5f54:	950080e7          	jalr	-1712(ra) # 78a0 <acquiresleep>
  if(ip->valid == 0){
    5f58:	0244a783          	lw	a5,36(s1)
    5f5c:	00078e63          	beqz	a5,5f78 <ilock+0x54>
}
    5f60:	00c12083          	lw	ra,12(sp)
    5f64:	00812403          	lw	s0,8(sp)
    5f68:	00412483          	lw	s1,4(sp)
    5f6c:	00012903          	lw	s2,0(sp)
    5f70:	01010113          	add	sp,sp,16
    5f74:	00008067          	ret
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    5f78:	0044a783          	lw	a5,4(s1)
    5f7c:	0004a503          	lw	a0,0(s1)
    5f80:	0001b597          	auipc	a1,0x1b
    5f84:	a5c5a583          	lw	a1,-1444(a1) # 209dc <sb+0x18>
    5f88:	0047d793          	srl	a5,a5,0x4
    5f8c:	00b785b3          	add	a1,a5,a1
    5f90:	fffff097          	auipc	ra,0xfffff
    5f94:	528080e7          	jalr	1320(ra) # 54b8 <bread>
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    5f98:	0044a783          	lw	a5,4(s1)
    5f9c:	03850593          	add	a1,a0,56
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    5fa0:	00050913          	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    5fa4:	00f7f793          	and	a5,a5,15
    5fa8:	00679793          	sll	a5,a5,0x6
    5fac:	00f585b3          	add	a1,a1,a5
    ip->type = dip->type;
    5fb0:	0045a703          	lw	a4,4(a1)
    ip->size = dip->size;
    5fb4:	0085a783          	lw	a5,8(a1)
    ip->type = dip->type;
    5fb8:	0005a683          	lw	a3,0(a1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    5fbc:	03400613          	li	a2,52
    ip->type = dip->type;
    5fc0:	02e4a623          	sw	a4,44(s1)
    ip->size = dip->size;
    5fc4:	02f4a823          	sw	a5,48(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    5fc8:	00c58593          	add	a1,a1,12
    ip->type = dip->type;
    5fcc:	02d4a423          	sw	a3,40(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    5fd0:	03448513          	add	a0,s1,52
    5fd4:	ffffc097          	auipc	ra,0xffffc
    5fd8:	830080e7          	jalr	-2000(ra) # 1804 <memmove>
    brelse(bp);
    5fdc:	00090513          	mv	a0,s2
    5fe0:	fffff097          	auipc	ra,0xfffff
    5fe4:	684080e7          	jalr	1668(ra) # 5664 <brelse>
    if(ip->type == 0)
    5fe8:	02849783          	lh	a5,40(s1)
    ip->valid = 1;
    5fec:	00100713          	li	a4,1
    5ff0:	02e4a223          	sw	a4,36(s1)
    if(ip->type == 0)
    5ff4:	f60796e3          	bnez	a5,5f60 <ilock+0x3c>
      panic("ilock: no type");
    5ff8:	00005517          	auipc	a0,0x5
    5ffc:	65c50513          	add	a0,a0,1628 # b654 <main+0x524>
    6000:	ffffa097          	auipc	ra,0xffffa
    6004:	6d4080e7          	jalr	1748(ra) # 6d4 <panic>
    panic("ilock");
    6008:	00005517          	auipc	a0,0x5
    600c:	64450513          	add	a0,a0,1604 # b64c <main+0x51c>
    6010:	ffffa097          	auipc	ra,0xffffa
    6014:	6c4080e7          	jalr	1732(ra) # 6d4 <panic>

00006018 <iunlock>:
{
    6018:	ff010113          	add	sp,sp,-16
    601c:	00812423          	sw	s0,8(sp)
    6020:	00112623          	sw	ra,12(sp)
    6024:	00912223          	sw	s1,4(sp)
    6028:	01212023          	sw	s2,0(sp)
    602c:	01010413          	add	s0,sp,16
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    6030:	04050263          	beqz	a0,6074 <iunlock+0x5c>
    6034:	00c50913          	add	s2,a0,12
    6038:	00050493          	mv	s1,a0
    603c:	00090513          	mv	a0,s2
    6040:	00002097          	auipc	ra,0x2
    6044:	944080e7          	jalr	-1724(ra) # 7984 <holdingsleep>
    6048:	02050663          	beqz	a0,6074 <iunlock+0x5c>
    604c:	0084a783          	lw	a5,8(s1)
    6050:	02f05263          	blez	a5,6074 <iunlock+0x5c>
}
    6054:	00812403          	lw	s0,8(sp)
    6058:	00c12083          	lw	ra,12(sp)
    605c:	00412483          	lw	s1,4(sp)
  releasesleep(&ip->lock);
    6060:	00090513          	mv	a0,s2
}
    6064:	00012903          	lw	s2,0(sp)
    6068:	01010113          	add	sp,sp,16
  releasesleep(&ip->lock);
    606c:	00002317          	auipc	t1,0x2
    6070:	8b830067          	jr	-1864(t1) # 7924 <releasesleep>
    panic("iunlock");
    6074:	00005517          	auipc	a0,0x5
    6078:	5f050513          	add	a0,a0,1520 # b664 <main+0x534>
    607c:	ffffa097          	auipc	ra,0xffffa
    6080:	658080e7          	jalr	1624(ra) # 6d4 <panic>

00006084 <iput>:
{
    6084:	fd010113          	add	sp,sp,-48
    6088:	02812423          	sw	s0,40(sp)
    608c:	03212023          	sw	s2,32(sp)
    6090:	02112623          	sw	ra,44(sp)
    6094:	02912223          	sw	s1,36(sp)
    6098:	01312e23          	sw	s3,28(sp)
    609c:	01412c23          	sw	s4,24(sp)
    60a0:	01512a23          	sw	s5,20(sp)
    60a4:	01612823          	sw	s6,16(sp)
    60a8:	01712623          	sw	s7,12(sp)
    60ac:	01812423          	sw	s8,8(sp)
    60b0:	01912223          	sw	s9,4(sp)
    60b4:	01a12023          	sw	s10,0(sp)
    60b8:	03010413          	add	s0,sp,48
    60bc:	00050913          	mv	s2,a0
  acquire(&icache.lock);
    60c0:	0001b517          	auipc	a0,0x1b
    60c4:	92450513          	add	a0,a0,-1756 # 209e4 <icache>
    60c8:	ffffb097          	auipc	ra,0xffffb
    60cc:	0a8080e7          	jalr	168(ra) # 1170 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    60d0:	00892783          	lw	a5,8(s2)
    60d4:	00100713          	li	a4,1
    60d8:	04e78863          	beq	a5,a4,6128 <iput+0xa4>
}
    60dc:	02812403          	lw	s0,40(sp)
  ip->ref--;
    60e0:	fff78793          	add	a5,a5,-1
}
    60e4:	02c12083          	lw	ra,44(sp)
    60e8:	02412483          	lw	s1,36(sp)
    60ec:	01c12983          	lw	s3,28(sp)
    60f0:	01812a03          	lw	s4,24(sp)
    60f4:	01412a83          	lw	s5,20(sp)
    60f8:	01012b03          	lw	s6,16(sp)
    60fc:	00c12b83          	lw	s7,12(sp)
    6100:	00812c03          	lw	s8,8(sp)
    6104:	00412c83          	lw	s9,4(sp)
    6108:	00012d03          	lw	s10,0(sp)
  ip->ref--;
    610c:	00f92423          	sw	a5,8(s2)
}
    6110:	02012903          	lw	s2,32(sp)
  release(&icache.lock);
    6114:	0001b517          	auipc	a0,0x1b
    6118:	8d050513          	add	a0,a0,-1840 # 209e4 <icache>
}
    611c:	03010113          	add	sp,sp,48
  release(&icache.lock);
    6120:	ffffb317          	auipc	t1,0xffffb
    6124:	1dc30067          	jr	476(t1) # 12fc <release>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    6128:	02492703          	lw	a4,36(s2)
    612c:	fa0708e3          	beqz	a4,60dc <iput+0x58>
    6130:	02e91703          	lh	a4,46(s2)
    6134:	fa0714e3          	bnez	a4,60dc <iput+0x58>
    acquiresleep(&ip->lock);
    6138:	00c90b93          	add	s7,s2,12
    613c:	000b8513          	mv	a0,s7
    6140:	00001097          	auipc	ra,0x1
    6144:	760080e7          	jalr	1888(ra) # 78a0 <acquiresleep>
    release(&icache.lock);
    6148:	0001b517          	auipc	a0,0x1b
    614c:	89c50513          	add	a0,a0,-1892 # 209e4 <icache>
    6150:	ffffb097          	auipc	ra,0xffffb
    6154:	1ac080e7          	jalr	428(ra) # 12fc <release>
  for(i = 0; i < NDIRECT; i++){
    6158:	03490b13          	add	s6,s2,52
    615c:	00092503          	lw	a0,0(s2)
    6160:	000b0993          	mv	s3,s6
    6164:	06490a93          	add	s5,s2,100
    6168:	0001ba17          	auipc	s4,0x1b
    616c:	85ca0a13          	add	s4,s4,-1956 # 209c4 <sb>
  m = 1 << (bi % 8);
    6170:	00100c13          	li	s8,1
    6174:	00c0006f          	j	6180 <iput+0xfc>
  for(i = 0; i < NDIRECT; i++){
    6178:	00498993          	add	s3,s3,4
    617c:	073a8863          	beq	s5,s3,61ec <iput+0x168>
    if(ip->addrs[i]){
    6180:	0009a483          	lw	s1,0(s3)
    6184:	fe048ae3          	beqz	s1,6178 <iput+0xf4>
  bp = bread(dev, BBLOCK(b, sb));
    6188:	01ca2783          	lw	a5,28(s4)
    618c:	00d4d593          	srl	a1,s1,0xd
    6190:	00f585b3          	add	a1,a1,a5
    6194:	fffff097          	auipc	ra,0xfffff
    6198:	324080e7          	jalr	804(ra) # 54b8 <bread>
  if((bp->data[bi/8] & m) == 0)
    619c:	4034d793          	sra	a5,s1,0x3
    61a0:	3ff7f793          	and	a5,a5,1023
    61a4:	00f507b3          	add	a5,a0,a5
    61a8:	0387c703          	lbu	a4,56(a5)
  m = 1 << (bi % 8);
    61ac:	0074f493          	and	s1,s1,7
    61b0:	009c14b3          	sll	s1,s8,s1
  if((bp->data[bi/8] & m) == 0)
    61b4:	009776b3          	and	a3,a4,s1
  bp = bread(dev, BBLOCK(b, sb));
    61b8:	00050c93          	mv	s9,a0
  if((bp->data[bi/8] & m) == 0)
    61bc:	24068e63          	beqz	a3,6418 <iput+0x394>
  bp->data[bi/8] &= ~m;
    61c0:	fff4c493          	not	s1,s1
    61c4:	00977733          	and	a4,a4,s1
    61c8:	02e78c23          	sb	a4,56(a5)
  log_write(bp);
    61cc:	00001097          	auipc	ra,0x1
    61d0:	550080e7          	jalr	1360(ra) # 771c <log_write>
  brelse(bp);
    61d4:	000c8513          	mv	a0,s9
    61d8:	fffff097          	auipc	ra,0xfffff
    61dc:	48c080e7          	jalr	1164(ra) # 5664 <brelse>
      ip->addrs[i] = 0;
    61e0:	0009a023          	sw	zero,0(s3)
    61e4:	00092503          	lw	a0,0(s2)
    61e8:	f91ff06f          	j	6178 <iput+0xf4>
  if(ip->addrs[NDIRECT]){
    61ec:	06492583          	lw	a1,100(s2)
    61f0:	12059063          	bnez	a1,6310 <iput+0x28c>
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    61f4:	00492783          	lw	a5,4(s2)
    61f8:	018a2583          	lw	a1,24(s4)
  ip->size = 0;
    61fc:	02092823          	sw	zero,48(s2)
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    6200:	0047d793          	srl	a5,a5,0x4
    6204:	00b785b3          	add	a1,a5,a1
    6208:	fffff097          	auipc	ra,0xfffff
    620c:	2b0080e7          	jalr	688(ra) # 54b8 <bread>
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    6210:	00492783          	lw	a5,4(s2)
  dip->type = ip->type;
    6214:	02892883          	lw	a7,40(s2)
    6218:	02c92803          	lw	a6,44(s2)
  dip->size = ip->size;
    621c:	03092683          	lw	a3,48(s2)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    6220:	00f7f793          	and	a5,a5,15
    6224:	00679713          	sll	a4,a5,0x6
    6228:	03850793          	add	a5,a0,56
    622c:	00e787b3          	add	a5,a5,a4
  dip->type = ip->type;
    6230:	0117a023          	sw	a7,0(a5)
    6234:	0107a223          	sw	a6,4(a5)
  dip->size = ip->size;
    6238:	00d7a423          	sw	a3,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    623c:	03400613          	li	a2,52
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    6240:	00050493          	mv	s1,a0
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    6244:	000b0593          	mv	a1,s6
    6248:	00c78513          	add	a0,a5,12
    624c:	ffffb097          	auipc	ra,0xffffb
    6250:	5b8080e7          	jalr	1464(ra) # 1804 <memmove>
  log_write(bp);
    6254:	00048513          	mv	a0,s1
    6258:	00001097          	auipc	ra,0x1
    625c:	4c4080e7          	jalr	1220(ra) # 771c <log_write>
  brelse(bp);
    6260:	00048513          	mv	a0,s1
    6264:	fffff097          	auipc	ra,0xfffff
    6268:	400080e7          	jalr	1024(ra) # 5664 <brelse>
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    626c:	00492783          	lw	a5,4(s2)
    6270:	018a2583          	lw	a1,24(s4)
    6274:	00092503          	lw	a0,0(s2)
    6278:	0047d793          	srl	a5,a5,0x4
    627c:	00b785b3          	add	a1,a5,a1
    ip->type = 0;
    6280:	02091423          	sh	zero,40(s2)
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    6284:	fffff097          	auipc	ra,0xfffff
    6288:	234080e7          	jalr	564(ra) # 54b8 <bread>
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    628c:	00492783          	lw	a5,4(s2)
  dip->type = ip->type;
    6290:	02892883          	lw	a7,40(s2)
    6294:	02c92803          	lw	a6,44(s2)
  dip->size = ip->size;
    6298:	03092683          	lw	a3,48(s2)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    629c:	00f7f793          	and	a5,a5,15
    62a0:	00679713          	sll	a4,a5,0x6
    62a4:	03850793          	add	a5,a0,56
    62a8:	00e787b3          	add	a5,a5,a4
  dip->type = ip->type;
    62ac:	0117a023          	sw	a7,0(a5)
    62b0:	0107a223          	sw	a6,4(a5)
  dip->size = ip->size;
    62b4:	00d7a423          	sw	a3,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    62b8:	03400613          	li	a2,52
    62bc:	000b0593          	mv	a1,s6
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    62c0:	00050493          	mv	s1,a0
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    62c4:	00c78513          	add	a0,a5,12
    62c8:	ffffb097          	auipc	ra,0xffffb
    62cc:	53c080e7          	jalr	1340(ra) # 1804 <memmove>
  log_write(bp);
    62d0:	00048513          	mv	a0,s1
    62d4:	00001097          	auipc	ra,0x1
    62d8:	448080e7          	jalr	1096(ra) # 771c <log_write>
  brelse(bp);
    62dc:	00048513          	mv	a0,s1
    62e0:	fffff097          	auipc	ra,0xfffff
    62e4:	384080e7          	jalr	900(ra) # 5664 <brelse>
    releasesleep(&ip->lock);
    62e8:	000b8513          	mv	a0,s7
    ip->valid = 0;
    62ec:	02092223          	sw	zero,36(s2)
    releasesleep(&ip->lock);
    62f0:	00001097          	auipc	ra,0x1
    62f4:	634080e7          	jalr	1588(ra) # 7924 <releasesleep>
    acquire(&icache.lock);
    62f8:	0001a517          	auipc	a0,0x1a
    62fc:	6ec50513          	add	a0,a0,1772 # 209e4 <icache>
    6300:	ffffb097          	auipc	ra,0xffffb
    6304:	e70080e7          	jalr	-400(ra) # 1170 <acquire>
  ip->ref--;
    6308:	00892783          	lw	a5,8(s2)
    630c:	dd1ff06f          	j	60dc <iput+0x58>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    6310:	fffff097          	auipc	ra,0xfffff
    6314:	1a8080e7          	jalr	424(ra) # 54b8 <bread>
    6318:	00050c13          	mv	s8,a0
    for(j = 0; j < NINDIRECT; j++){
    631c:	03850c93          	add	s9,a0,56
    6320:	43850993          	add	s3,a0,1080
  m = 1 << (bi % 8);
    6324:	00100a93          	li	s5,1
    6328:	00c0006f          	j	6334 <iput+0x2b0>
    for(j = 0; j < NINDIRECT; j++){
    632c:	004c8c93          	add	s9,s9,4
    6330:	07998663          	beq	s3,s9,639c <iput+0x318>
      if(a[j])
    6334:	000ca483          	lw	s1,0(s9)
    6338:	fe048ae3          	beqz	s1,632c <iput+0x2a8>
  bp = bread(dev, BBLOCK(b, sb));
    633c:	01ca2783          	lw	a5,28(s4)
    6340:	00092503          	lw	a0,0(s2)
    6344:	00d4d593          	srl	a1,s1,0xd
    6348:	00f585b3          	add	a1,a1,a5
    634c:	fffff097          	auipc	ra,0xfffff
    6350:	16c080e7          	jalr	364(ra) # 54b8 <bread>
  if((bp->data[bi/8] & m) == 0)
    6354:	4034d793          	sra	a5,s1,0x3
    6358:	3ff7f793          	and	a5,a5,1023
    635c:	00f507b3          	add	a5,a0,a5
    6360:	0387c703          	lbu	a4,56(a5)
  m = 1 << (bi % 8);
    6364:	0074f493          	and	s1,s1,7
    6368:	009a94b3          	sll	s1,s5,s1
  if((bp->data[bi/8] & m) == 0)
    636c:	009776b3          	and	a3,a4,s1
  bp = bread(dev, BBLOCK(b, sb));
    6370:	00050d13          	mv	s10,a0
  if((bp->data[bi/8] & m) == 0)
    6374:	0a068263          	beqz	a3,6418 <iput+0x394>
  bp->data[bi/8] &= ~m;
    6378:	fff4c493          	not	s1,s1
    637c:	00977733          	and	a4,a4,s1
    6380:	02e78c23          	sb	a4,56(a5)
  log_write(bp);
    6384:	00001097          	auipc	ra,0x1
    6388:	398080e7          	jalr	920(ra) # 771c <log_write>
  brelse(bp);
    638c:	000d0513          	mv	a0,s10
    6390:	fffff097          	auipc	ra,0xfffff
    6394:	2d4080e7          	jalr	724(ra) # 5664 <brelse>
}
    6398:	f95ff06f          	j	632c <iput+0x2a8>
    brelse(bp);
    639c:	000c0513          	mv	a0,s8
    63a0:	fffff097          	auipc	ra,0xfffff
    63a4:	2c4080e7          	jalr	708(ra) # 5664 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    63a8:	06492483          	lw	s1,100(s2)
  bp = bread(dev, BBLOCK(b, sb));
    63ac:	01ca2783          	lw	a5,28(s4)
    63b0:	00092503          	lw	a0,0(s2)
    63b4:	00d4d593          	srl	a1,s1,0xd
    63b8:	00f585b3          	add	a1,a1,a5
    63bc:	fffff097          	auipc	ra,0xfffff
    63c0:	0fc080e7          	jalr	252(ra) # 54b8 <bread>
  if((bp->data[bi/8] & m) == 0)
    63c4:	4034d793          	sra	a5,s1,0x3
    63c8:	3ff7f793          	and	a5,a5,1023
    63cc:	00f507b3          	add	a5,a0,a5
    63d0:	0387c683          	lbu	a3,56(a5)
  m = 1 << (bi % 8);
    63d4:	0074f493          	and	s1,s1,7
    63d8:	00100713          	li	a4,1
    63dc:	00971733          	sll	a4,a4,s1
  if((bp->data[bi/8] & m) == 0)
    63e0:	00e6f633          	and	a2,a3,a4
  bp = bread(dev, BBLOCK(b, sb));
    63e4:	00050993          	mv	s3,a0
  if((bp->data[bi/8] & m) == 0)
    63e8:	02060863          	beqz	a2,6418 <iput+0x394>
  bp->data[bi/8] &= ~m;
    63ec:	fff74713          	not	a4,a4
    63f0:	00e6f6b3          	and	a3,a3,a4
    63f4:	02d78c23          	sb	a3,56(a5)
  log_write(bp);
    63f8:	00001097          	auipc	ra,0x1
    63fc:	324080e7          	jalr	804(ra) # 771c <log_write>
  brelse(bp);
    6400:	00098513          	mv	a0,s3
    6404:	fffff097          	auipc	ra,0xfffff
    6408:	260080e7          	jalr	608(ra) # 5664 <brelse>
    ip->addrs[NDIRECT] = 0;
    640c:	00092503          	lw	a0,0(s2)
    6410:	06092223          	sw	zero,100(s2)
    6414:	de1ff06f          	j	61f4 <iput+0x170>
    panic("freeing free block");
    6418:	00005517          	auipc	a0,0x5
    641c:	25450513          	add	a0,a0,596 # b66c <main+0x53c>
    6420:	ffffa097          	auipc	ra,0xffffa
    6424:	2b4080e7          	jalr	692(ra) # 6d4 <panic>

00006428 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    6428:	fc010113          	add	sp,sp,-64
    642c:	02812c23          	sw	s0,56(sp)
    6430:	02912a23          	sw	s1,52(sp)
    6434:	03512223          	sw	s5,36(sp)
    6438:	01712e23          	sw	s7,28(sp)
    643c:	02112e23          	sw	ra,60(sp)
    6440:	03212823          	sw	s2,48(sp)
    6444:	03312623          	sw	s3,44(sp)
    6448:	03412423          	sw	s4,40(sp)
    644c:	03612023          	sw	s6,32(sp)
    6450:	01812c23          	sw	s8,24(sp)
    6454:	01912a23          	sw	s9,20(sp)
    6458:	01a12823          	sw	s10,16(sp)
    645c:	04010413          	add	s0,sp,64
  struct inode *ip, *next;

  if(*path == '/')
    6460:	00054703          	lbu	a4,0(a0)
    6464:	02f00793          	li	a5,47
{
    6468:	00050493          	mv	s1,a0
    646c:	00058b93          	mv	s7,a1
    6470:	00060a93          	mv	s5,a2
  if(*path == '/')
    6474:	2af70863          	beq	a4,a5,6724 <namex+0x2fc>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    6478:	ffffd097          	auipc	ra,0xffffd
    647c:	fac080e7          	jalr	-84(ra) # 3424 <myproc>
    6480:	0ac52983          	lw	s3,172(a0)
  acquire(&icache.lock);
    6484:	0001a517          	auipc	a0,0x1a
    6488:	56050513          	add	a0,a0,1376 # 209e4 <icache>
    648c:	ffffb097          	auipc	ra,0xffffb
    6490:	ce4080e7          	jalr	-796(ra) # 1170 <acquire>
  ip->ref++;
    6494:	0089a783          	lw	a5,8(s3)
  release(&icache.lock);
    6498:	0001a517          	auipc	a0,0x1a
    649c:	54c50513          	add	a0,a0,1356 # 209e4 <icache>
  ip->ref++;
    64a0:	00178793          	add	a5,a5,1
    64a4:	00f9a423          	sw	a5,8(s3)
  release(&icache.lock);
    64a8:	ffffb097          	auipc	ra,0xffffb
    64ac:	e54080e7          	jalr	-428(ra) # 12fc <release>
  while(*path == '/')
    64b0:	02f00a13          	li	s4,47
  if(len >= DIRSIZ)
    64b4:	00d00c13          	li	s8,13
    64b8:	0001cb17          	auipc	s6,0x1c
    64bc:	988b0b13          	add	s6,s6,-1656 # 21e40 <log>
  while(*path == '/')
    64c0:	0004c783          	lbu	a5,0(s1)
    64c4:	01479863          	bne	a5,s4,64d4 <namex+0xac>
    64c8:	0014c783          	lbu	a5,1(s1)
    path++;
    64cc:	00148493          	add	s1,s1,1
  while(*path == '/')
    64d0:	ff478ce3          	beq	a5,s4,64c8 <namex+0xa0>
  if(*path == 0)
    64d4:	1e078e63          	beqz	a5,66d0 <namex+0x2a8>
  iput(ip);
    64d8:	00048913          	mv	s2,s1
  while(*path != '/' && *path != 0)
    64dc:	00078863          	beqz	a5,64ec <namex+0xc4>
    64e0:	00194783          	lbu	a5,1(s2)
    path++;
    64e4:	00190913          	add	s2,s2,1
  while(*path != '/' && *path != 0)
    64e8:	ff479ae3          	bne	a5,s4,64dc <namex+0xb4>
  len = path - s;
    64ec:	40990633          	sub	a2,s2,s1
  if(len >= DIRSIZ)
    64f0:	0ecc5063          	bge	s8,a2,65d0 <namex+0x1a8>
    memmove(name, s, DIRSIZ);
    64f4:	00e00613          	li	a2,14
    64f8:	00048593          	mv	a1,s1
    64fc:	000a8513          	mv	a0,s5
    6500:	ffffb097          	auipc	ra,0xffffb
    6504:	304080e7          	jalr	772(ra) # 1804 <memmove>
  while(*path == '/')
    6508:	00094783          	lbu	a5,0(s2)
    650c:	01479863          	bne	a5,s4,651c <namex+0xf4>
    6510:	00194783          	lbu	a5,1(s2)
    path++;
    6514:	00190913          	add	s2,s2,1
  while(*path == '/')
    6518:	ff478ce3          	beq	a5,s4,6510 <namex+0xe8>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    651c:	00098513          	mv	a0,s3
    6520:	00000097          	auipc	ra,0x0
    6524:	a04080e7          	jalr	-1532(ra) # 5f24 <ilock>
    if(ip->type != T_DIR){
    6528:	02899703          	lh	a4,40(s3)
    652c:	00100793          	li	a5,1
    6530:	06f71263          	bne	a4,a5,6594 <namex+0x16c>
      iunlockput(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
    6534:	000b8663          	beqz	s7,6540 <namex+0x118>
    6538:	00094783          	lbu	a5,0(s2)
    653c:	28078a63          	beqz	a5,67d0 <namex+0x3a8>
  for(off = 0; off < dp->size; off += sizeof(de)){
    6540:	0309a783          	lw	a5,48(s3)
    6544:	04078863          	beqz	a5,6594 <namex+0x16c>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    6548:	00000493          	li	s1,0
    654c:	01000c93          	li	s9,16
    6550:	00048613          	mv	a2,s1
    6554:	fc040593          	add	a1,s0,-64
    6558:	00098513          	mv	a0,s3
    655c:	fffff097          	auipc	ra,0xfffff
    6560:	3bc080e7          	jalr	956(ra) # 5918 <readi.constprop.0>
    6564:	2b951663          	bne	a0,s9,6810 <namex+0x3e8>
    if(de.inum == 0)
    6568:	fc045783          	lhu	a5,-64(s0)
    656c:	00078e63          	beqz	a5,6588 <namex+0x160>
  return strncmp(s, t, DIRSIZ);
    6570:	00e00613          	li	a2,14
    6574:	fc240593          	add	a1,s0,-62
    6578:	000a8513          	mv	a0,s5
    657c:	ffffb097          	auipc	ra,0xffffb
    6580:	48c080e7          	jalr	1164(ra) # 1a08 <strncmp>
    if(namecmp(name, de.name) == 0){
    6584:	06050463          	beqz	a0,65ec <namex+0x1c4>
  for(off = 0; off < dp->size; off += sizeof(de)){
    6588:	0309a783          	lw	a5,48(s3)
    658c:	01048493          	add	s1,s1,16
    6590:	fcf4e0e3          	bltu	s1,a5,6550 <namex+0x128>
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    6594:	00c98493          	add	s1,s3,12
    6598:	00048513          	mv	a0,s1
    659c:	00001097          	auipc	ra,0x1
    65a0:	3e8080e7          	jalr	1000(ra) # 7984 <holdingsleep>
    65a4:	26050e63          	beqz	a0,6820 <namex+0x3f8>
    65a8:	0089a783          	lw	a5,8(s3)
    65ac:	26f05a63          	blez	a5,6820 <namex+0x3f8>
  releasesleep(&ip->lock);
    65b0:	00048513          	mv	a0,s1
    65b4:	00001097          	auipc	ra,0x1
    65b8:	370080e7          	jalr	880(ra) # 7924 <releasesleep>
  iput(ip);
    65bc:	00098513          	mv	a0,s3
    65c0:	00000097          	auipc	ra,0x0
    65c4:	ac4080e7          	jalr	-1340(ra) # 6084 <iput>
      return 0;
    65c8:	00000993          	li	s3,0
    65cc:	1080006f          	j	66d4 <namex+0x2ac>
    name[len] = 0;
    65d0:	00ca8cb3          	add	s9,s5,a2
    memmove(name, s, len);
    65d4:	00048593          	mv	a1,s1
    65d8:	000a8513          	mv	a0,s5
    65dc:	ffffb097          	auipc	ra,0xffffb
    65e0:	228080e7          	jalr	552(ra) # 1804 <memmove>
    name[len] = 0;
    65e4:	000c8023          	sb	zero,0(s9)
    65e8:	f21ff06f          	j	6508 <namex+0xe0>
  acquire(&icache.lock);
    65ec:	0001a517          	auipc	a0,0x1a
    65f0:	3f850513          	add	a0,a0,1016 # 209e4 <icache>
      inum = de.inum;
    65f4:	fc045d03          	lhu	s10,-64(s0)
      return iget(dp->dev, inum);
    65f8:	0009ac83          	lw	s9,0(s3)
  acquire(&icache.lock);
    65fc:	ffffb097          	auipc	ra,0xffffb
    6600:	b74080e7          	jalr	-1164(ra) # 1170 <acquire>
  empty = 0;
    6604:	00000493          	li	s1,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6608:	0001a797          	auipc	a5,0x1a
    660c:	3e878793          	add	a5,a5,1000 # 209f0 <icache+0xc>
    6610:	0140006f          	j	6624 <namex+0x1fc>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6614:	0007a683          	lw	a3,0(a5)
    6618:	04dc8a63          	beq	s9,a3,666c <namex+0x244>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    661c:	06878793          	add	a5,a5,104
    6620:	03678063          	beq	a5,s6,6640 <namex+0x218>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6624:	0087a703          	lw	a4,8(a5)
    6628:	fee046e3          	bgtz	a4,6614 <namex+0x1ec>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    662c:	fe0498e3          	bnez	s1,661c <namex+0x1f4>
    6630:	0e071063          	bnez	a4,6710 <namex+0x2e8>
    6634:	00078493          	mv	s1,a5
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6638:	06878793          	add	a5,a5,104
    663c:	ff6794e3          	bne	a5,s6,6624 <namex+0x1fc>
  if(empty == 0)
    6640:	1e048863          	beqz	s1,6830 <namex+0x408>
  ip->ref = 1;
    6644:	00100793          	li	a5,1
  ip->dev = dev;
    6648:	0194a023          	sw	s9,0(s1)
  ip->inum = inum;
    664c:	01a4a223          	sw	s10,4(s1)
  ip->ref = 1;
    6650:	00f4a423          	sw	a5,8(s1)
  ip->valid = 0;
    6654:	0204a223          	sw	zero,36(s1)
  release(&icache.lock);
    6658:	0001a517          	auipc	a0,0x1a
    665c:	38c50513          	add	a0,a0,908 # 209e4 <icache>
    6660:	ffffb097          	auipc	ra,0xffffb
    6664:	c9c080e7          	jalr	-868(ra) # 12fc <release>
  return ip;
    6668:	0280006f          	j	6690 <namex+0x268>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    666c:	0047a683          	lw	a3,4(a5)
    6670:	fadd16e3          	bne	s10,a3,661c <namex+0x1f4>
      ip->ref++;
    6674:	00170713          	add	a4,a4,1
      release(&icache.lock);
    6678:	0001a517          	auipc	a0,0x1a
    667c:	36c50513          	add	a0,a0,876 # 209e4 <icache>
      ip->ref++;
    6680:	00e7a423          	sw	a4,8(a5)
      release(&icache.lock);
    6684:	00078493          	mv	s1,a5
    6688:	ffffb097          	auipc	ra,0xffffb
    668c:	c74080e7          	jalr	-908(ra) # 12fc <release>
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    6690:	00c98c93          	add	s9,s3,12
    6694:	000c8513          	mv	a0,s9
    6698:	00001097          	auipc	ra,0x1
    669c:	2ec080e7          	jalr	748(ra) # 7984 <holdingsleep>
    66a0:	18050063          	beqz	a0,6820 <namex+0x3f8>
    66a4:	0089a783          	lw	a5,8(s3)
    66a8:	16f05c63          	blez	a5,6820 <namex+0x3f8>
  releasesleep(&ip->lock);
    66ac:	000c8513          	mv	a0,s9
    66b0:	00001097          	auipc	ra,0x1
    66b4:	274080e7          	jalr	628(ra) # 7924 <releasesleep>
  iput(ip);
    66b8:	00098513          	mv	a0,s3
    66bc:	00000097          	auipc	ra,0x0
    66c0:	9c8080e7          	jalr	-1592(ra) # 6084 <iput>
    66c4:	00048993          	mv	s3,s1
    66c8:	00090493          	mv	s1,s2
    66cc:	df5ff06f          	j	64c0 <namex+0x98>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
    66d0:	ee0b96e3          	bnez	s7,65bc <namex+0x194>
    iput(ip);
    return 0;
  }
  return ip;
}
    66d4:	03c12083          	lw	ra,60(sp)
    66d8:	03812403          	lw	s0,56(sp)
    66dc:	03412483          	lw	s1,52(sp)
    66e0:	03012903          	lw	s2,48(sp)
    66e4:	02812a03          	lw	s4,40(sp)
    66e8:	02412a83          	lw	s5,36(sp)
    66ec:	02012b03          	lw	s6,32(sp)
    66f0:	01c12b83          	lw	s7,28(sp)
    66f4:	01812c03          	lw	s8,24(sp)
    66f8:	01412c83          	lw	s9,20(sp)
    66fc:	01012d03          	lw	s10,16(sp)
    6700:	00098513          	mv	a0,s3
    6704:	02c12983          	lw	s3,44(sp)
    6708:	04010113          	add	sp,sp,64
    670c:	00008067          	ret
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6710:	06878793          	add	a5,a5,104
    6714:	11678e63          	beq	a5,s6,6830 <namex+0x408>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6718:	0087a703          	lw	a4,8(a5)
    671c:	eee04ce3          	bgtz	a4,6614 <namex+0x1ec>
    6720:	f11ff06f          	j	6630 <namex+0x208>
  acquire(&icache.lock);
    6724:	0001a517          	auipc	a0,0x1a
    6728:	2c050513          	add	a0,a0,704 # 209e4 <icache>
    672c:	ffffb097          	auipc	ra,0xffffb
    6730:	a44080e7          	jalr	-1468(ra) # 1170 <acquire>
  empty = 0;
    6734:	00000993          	li	s3,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6738:	0001a797          	auipc	a5,0x1a
    673c:	2b878793          	add	a5,a5,696 # 209f0 <icache+0xc>
    6740:	0001b617          	auipc	a2,0x1b
    6744:	70060613          	add	a2,a2,1792 # 21e40 <log>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6748:	00100593          	li	a1,1
    674c:	0140006f          	j	6760 <namex+0x338>
    6750:	0007a683          	lw	a3,0(a5)
    6754:	04b68a63          	beq	a3,a1,67a8 <namex+0x380>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6758:	06878793          	add	a5,a5,104
    675c:	02c78063          	beq	a5,a2,677c <namex+0x354>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6760:	0087a703          	lw	a4,8(a5)
    6764:	fee046e3          	bgtz	a4,6750 <namex+0x328>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    6768:	fe0998e3          	bnez	s3,6758 <namex+0x330>
    676c:	08071863          	bnez	a4,67fc <namex+0x3d4>
    6770:	00078993          	mv	s3,a5
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6774:	06878793          	add	a5,a5,104
    6778:	fec794e3          	bne	a5,a2,6760 <namex+0x338>
  if(empty == 0)
    677c:	0a098a63          	beqz	s3,6830 <namex+0x408>
  ip->dev = dev;
    6780:	00100793          	li	a5,1
    6784:	00f9a023          	sw	a5,0(s3)
  ip->inum = inum;
    6788:	00f9a223          	sw	a5,4(s3)
  ip->ref = 1;
    678c:	00f9a423          	sw	a5,8(s3)
  ip->valid = 0;
    6790:	0209a223          	sw	zero,36(s3)
  release(&icache.lock);
    6794:	0001a517          	auipc	a0,0x1a
    6798:	25050513          	add	a0,a0,592 # 209e4 <icache>
    679c:	ffffb097          	auipc	ra,0xffffb
    67a0:	b60080e7          	jalr	-1184(ra) # 12fc <release>
  return ip;
    67a4:	d0dff06f          	j	64b0 <namex+0x88>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    67a8:	0047a683          	lw	a3,4(a5)
    67ac:	fab696e3          	bne	a3,a1,6758 <namex+0x330>
      ip->ref++;
    67b0:	00170713          	add	a4,a4,1
      release(&icache.lock);
    67b4:	0001a517          	auipc	a0,0x1a
    67b8:	23050513          	add	a0,a0,560 # 209e4 <icache>
      ip->ref++;
    67bc:	00e7a423          	sw	a4,8(a5)
      return ip;
    67c0:	00078993          	mv	s3,a5
      release(&icache.lock);
    67c4:	ffffb097          	auipc	ra,0xffffb
    67c8:	b38080e7          	jalr	-1224(ra) # 12fc <release>
      return ip;
    67cc:	ce5ff06f          	j	64b0 <namex+0x88>
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    67d0:	00c98493          	add	s1,s3,12
    67d4:	00048513          	mv	a0,s1
    67d8:	00001097          	auipc	ra,0x1
    67dc:	1ac080e7          	jalr	428(ra) # 7984 <holdingsleep>
    67e0:	04050063          	beqz	a0,6820 <namex+0x3f8>
    67e4:	0089a783          	lw	a5,8(s3)
    67e8:	02f05c63          	blez	a5,6820 <namex+0x3f8>
  releasesleep(&ip->lock);
    67ec:	00048513          	mv	a0,s1
    67f0:	00001097          	auipc	ra,0x1
    67f4:	134080e7          	jalr	308(ra) # 7924 <releasesleep>
}
    67f8:	eddff06f          	j	66d4 <namex+0x2ac>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    67fc:	06878793          	add	a5,a5,104
    6800:	02c78863          	beq	a5,a2,6830 <namex+0x408>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6804:	0087a703          	lw	a4,8(a5)
    6808:	f4e044e3          	bgtz	a4,6750 <namex+0x328>
    680c:	f61ff06f          	j	676c <namex+0x344>
      panic("dirlookup read");
    6810:	00005517          	auipc	a0,0x5
    6814:	e7050513          	add	a0,a0,-400 # b680 <main+0x550>
    6818:	ffffa097          	auipc	ra,0xffffa
    681c:	ebc080e7          	jalr	-324(ra) # 6d4 <panic>
    panic("iunlock");
    6820:	00005517          	auipc	a0,0x5
    6824:	e4450513          	add	a0,a0,-444 # b664 <main+0x534>
    6828:	ffffa097          	auipc	ra,0xffffa
    682c:	eac080e7          	jalr	-340(ra) # 6d4 <panic>
    panic("iget: no inodes");
    6830:	00005517          	auipc	a0,0x5
    6834:	df850513          	add	a0,a0,-520 # b628 <main+0x4f8>
    6838:	ffffa097          	auipc	ra,0xffffa
    683c:	e9c080e7          	jalr	-356(ra) # 6d4 <panic>

00006840 <iunlockput>:
{
    6840:	ff010113          	add	sp,sp,-16
    6844:	00812423          	sw	s0,8(sp)
    6848:	00112623          	sw	ra,12(sp)
    684c:	00912223          	sw	s1,4(sp)
    6850:	01212023          	sw	s2,0(sp)
    6854:	01010413          	add	s0,sp,16
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    6858:	04050863          	beqz	a0,68a8 <iunlockput+0x68>
    685c:	00c50913          	add	s2,a0,12
    6860:	00050493          	mv	s1,a0
    6864:	00090513          	mv	a0,s2
    6868:	00001097          	auipc	ra,0x1
    686c:	11c080e7          	jalr	284(ra) # 7984 <holdingsleep>
    6870:	02050c63          	beqz	a0,68a8 <iunlockput+0x68>
    6874:	0084a783          	lw	a5,8(s1)
    6878:	02f05863          	blez	a5,68a8 <iunlockput+0x68>
  releasesleep(&ip->lock);
    687c:	00090513          	mv	a0,s2
    6880:	00001097          	auipc	ra,0x1
    6884:	0a4080e7          	jalr	164(ra) # 7924 <releasesleep>
}
    6888:	00812403          	lw	s0,8(sp)
    688c:	00c12083          	lw	ra,12(sp)
    6890:	00012903          	lw	s2,0(sp)
  iput(ip);
    6894:	00048513          	mv	a0,s1
}
    6898:	00412483          	lw	s1,4(sp)
    689c:	01010113          	add	sp,sp,16
  iput(ip);
    68a0:	fffff317          	auipc	t1,0xfffff
    68a4:	7e430067          	jr	2020(t1) # 6084 <iput>
    panic("iunlock");
    68a8:	00005517          	auipc	a0,0x5
    68ac:	dbc50513          	add	a0,a0,-580 # b664 <main+0x534>
    68b0:	ffffa097          	auipc	ra,0xffffa
    68b4:	e24080e7          	jalr	-476(ra) # 6d4 <panic>

000068b8 <stati>:
{
    68b8:	ff010113          	add	sp,sp,-16
    68bc:	00812623          	sw	s0,12(sp)
    68c0:	01010413          	add	s0,sp,16
  st->type = ip->type;
    68c4:	02e55703          	lhu	a4,46(a0)
    68c8:	02855783          	lhu	a5,40(a0)
  st->dev = ip->dev;
    68cc:	00052803          	lw	a6,0(a0)
  st->ino = ip->inum;
    68d0:	00452603          	lw	a2,4(a0)
  st->size = ip->size;
    68d4:	03052683          	lw	a3,48(a0)
}
    68d8:	00c12403          	lw	s0,12(sp)
  st->type = ip->type;
    68dc:	01071713          	sll	a4,a4,0x10
    68e0:	00e7e7b3          	or	a5,a5,a4
  st->dev = ip->dev;
    68e4:	0105a023          	sw	a6,0(a1)
  st->ino = ip->inum;
    68e8:	00c5a223          	sw	a2,4(a1)
  st->type = ip->type;
    68ec:	00f5a423          	sw	a5,8(a1)
  st->size = ip->size;
    68f0:	00d5a823          	sw	a3,16(a1)
    68f4:	0005aa23          	sw	zero,20(a1)
}
    68f8:	01010113          	add	sp,sp,16
    68fc:	00008067          	ret

00006900 <readi>:
{
    6900:	fb010113          	add	sp,sp,-80
    6904:	04812423          	sw	s0,72(sp)
    6908:	04112623          	sw	ra,76(sp)
    690c:	04912223          	sw	s1,68(sp)
    6910:	05212023          	sw	s2,64(sp)
    6914:	03312e23          	sw	s3,60(sp)
    6918:	03412c23          	sw	s4,56(sp)
    691c:	03512a23          	sw	s5,52(sp)
    6920:	03612823          	sw	s6,48(sp)
    6924:	03712623          	sw	s7,44(sp)
    6928:	03812423          	sw	s8,40(sp)
    692c:	03912223          	sw	s9,36(sp)
    6930:	03a12023          	sw	s10,32(sp)
    6934:	01b12e23          	sw	s11,28(sp)
    6938:	05010413          	add	s0,sp,80
  if(off > ip->size || off + n < off)
    693c:	03052783          	lw	a5,48(a0)
{
    6940:	fab42e23          	sw	a1,-68(s0)
  if(off > ip->size || off + n < off)
    6944:	1ad7e663          	bltu	a5,a3,6af0 <readi+0x1f0>
    6948:	00070b13          	mv	s6,a4
    694c:	00e68733          	add	a4,a3,a4
    6950:	00068493          	mv	s1,a3
    6954:	18d76e63          	bltu	a4,a3,6af0 <readi+0x1f0>
    6958:	00050a13          	mv	s4,a0
    695c:	00060993          	mv	s3,a2
    6960:	00000913          	li	s2,0
  if(off + n > ip->size)
    6964:	18e7e263          	bltu	a5,a4,6ae8 <readi+0x1e8>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    6968:	140b0063          	beqz	s6,6aa8 <readi+0x1a8>
  if(bn < NDIRECT){
    696c:	00b00c13          	li	s8,11
    m = min(n - tot, BSIZE - off%BSIZE);
    6970:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    6974:	fff00c93          	li	s9,-1
    6978:	0ac0006f          	j	6a24 <readi+0x124>
  bn -= NDIRECT;
    697c:	ff478b93          	add	s7,a5,-12
  if(bn < NINDIRECT){
    6980:	0ff00793          	li	a5,255
    6984:	1777ea63          	bltu	a5,s7,6af8 <readi+0x1f8>
    if((addr = ip->addrs[NDIRECT]) == 0)
    6988:	064a2583          	lw	a1,100(s4)
    698c:	000a8513          	mv	a0,s5
    6990:	0e058a63          	beqz	a1,6a84 <readi+0x184>
    bp = bread(ip->dev, addr);
    6994:	fffff097          	auipc	ra,0xfffff
    6998:	b24080e7          	jalr	-1244(ra) # 54b8 <bread>
    if((addr = a[bn]) == 0){
    699c:	002b9793          	sll	a5,s7,0x2
    a = (uint*)bp->data;
    69a0:	03850693          	add	a3,a0,56
    if((addr = a[bn]) == 0){
    69a4:	00f687b3          	add	a5,a3,a5
    69a8:	0007ab83          	lw	s7,0(a5)
    bp = bread(ip->dev, addr);
    69ac:	00050d93          	mv	s11,a0
    if((addr = a[bn]) == 0){
    69b0:	0a0b8463          	beqz	s7,6a58 <readi+0x158>
    brelse(bp);
    69b4:	000d8513          	mv	a0,s11
    69b8:	fffff097          	auipc	ra,0xfffff
    69bc:	cac080e7          	jalr	-852(ra) # 5664 <brelse>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    69c0:	000b8593          	mv	a1,s7
    69c4:	000a8513          	mv	a0,s5
    69c8:	fffff097          	auipc	ra,0xfffff
    69cc:	af0080e7          	jalr	-1296(ra) # 54b8 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
    69d0:	3ff4f713          	and	a4,s1,1023
    69d4:	412b06b3          	sub	a3,s6,s2
    69d8:	40ed0ab3          	sub	s5,s10,a4
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    69dc:	00050b93          	mv	s7,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    69e0:	0156f463          	bgeu	a3,s5,69e8 <readi+0xe8>
    69e4:	00068a93          	mv	s5,a3
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    69e8:	fbc42503          	lw	a0,-68(s0)
    69ec:	038b8613          	add	a2,s7,56
    69f0:	000a8693          	mv	a3,s5
    69f4:	00e60633          	add	a2,a2,a4
    69f8:	00098593          	mv	a1,s3
    69fc:	ffffe097          	auipc	ra,0xffffe
    6a00:	8c8080e7          	jalr	-1848(ra) # 42c4 <either_copyout>
    6a04:	09950c63          	beq	a0,s9,6a9c <readi+0x19c>
    brelse(bp);
    6a08:	000b8513          	mv	a0,s7
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    6a0c:	01590933          	add	s2,s2,s5
    brelse(bp);
    6a10:	fffff097          	auipc	ra,0xfffff
    6a14:	c54080e7          	jalr	-940(ra) # 5664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    6a18:	015484b3          	add	s1,s1,s5
    6a1c:	015989b3          	add	s3,s3,s5
    6a20:	09697463          	bgeu	s2,s6,6aa8 <readi+0x1a8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    6a24:	00a4d793          	srl	a5,s1,0xa
    6a28:	000a2a83          	lw	s5,0(s4)
  if(bn < NDIRECT){
    6a2c:	f4fc68e3          	bltu	s8,a5,697c <readi+0x7c>
    if((addr = ip->addrs[bn]) == 0)
    6a30:	00279793          	sll	a5,a5,0x2
    6a34:	00fa0db3          	add	s11,s4,a5
    6a38:	034dab83          	lw	s7,52(s11)
    6a3c:	f80b92e3          	bnez	s7,69c0 <readi+0xc0>
      ip->addrs[bn] = addr = balloc(ip->dev);
    6a40:	000a8513          	mv	a0,s5
    6a44:	fffff097          	auipc	ra,0xfffff
    6a48:	d8c080e7          	jalr	-628(ra) # 57d0 <balloc>
    6a4c:	00050b93          	mv	s7,a0
    6a50:	02adaa23          	sw	a0,52(s11)
    6a54:	f6dff06f          	j	69c0 <readi+0xc0>
      a[bn] = addr = balloc(ip->dev);
    6a58:	000a2503          	lw	a0,0(s4)
    6a5c:	faf42c23          	sw	a5,-72(s0)
    6a60:	fffff097          	auipc	ra,0xfffff
    6a64:	d70080e7          	jalr	-656(ra) # 57d0 <balloc>
    6a68:	fb842783          	lw	a5,-72(s0)
    6a6c:	00050b93          	mv	s7,a0
    6a70:	00a7a023          	sw	a0,0(a5)
      log_write(bp);
    6a74:	000d8513          	mv	a0,s11
    6a78:	00001097          	auipc	ra,0x1
    6a7c:	ca4080e7          	jalr	-860(ra) # 771c <log_write>
    6a80:	f35ff06f          	j	69b4 <readi+0xb4>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    6a84:	fffff097          	auipc	ra,0xfffff
    6a88:	d4c080e7          	jalr	-692(ra) # 57d0 <balloc>
    6a8c:	00050593          	mv	a1,a0
    6a90:	06ba2223          	sw	a1,100(s4)
    bp = bread(ip->dev, addr);
    6a94:	000a2503          	lw	a0,0(s4)
    6a98:	efdff06f          	j	6994 <readi+0x94>
      brelse(bp);
    6a9c:	000b8513          	mv	a0,s7
    6aa0:	fffff097          	auipc	ra,0xfffff
    6aa4:	bc4080e7          	jalr	-1084(ra) # 5664 <brelse>
  return n;
    6aa8:	000b0513          	mv	a0,s6
}
    6aac:	04c12083          	lw	ra,76(sp)
    6ab0:	04812403          	lw	s0,72(sp)
    6ab4:	04412483          	lw	s1,68(sp)
    6ab8:	04012903          	lw	s2,64(sp)
    6abc:	03c12983          	lw	s3,60(sp)
    6ac0:	03812a03          	lw	s4,56(sp)
    6ac4:	03412a83          	lw	s5,52(sp)
    6ac8:	03012b03          	lw	s6,48(sp)
    6acc:	02c12b83          	lw	s7,44(sp)
    6ad0:	02812c03          	lw	s8,40(sp)
    6ad4:	02412c83          	lw	s9,36(sp)
    6ad8:	02012d03          	lw	s10,32(sp)
    6adc:	01c12d83          	lw	s11,28(sp)
    6ae0:	05010113          	add	sp,sp,80
    6ae4:	00008067          	ret
    n = ip->size - off;
    6ae8:	40d78b33          	sub	s6,a5,a3
    6aec:	e7dff06f          	j	6968 <readi+0x68>
    return -1;
    6af0:	fff00513          	li	a0,-1
    6af4:	fb9ff06f          	j	6aac <readi+0x1ac>
  panic("bmap: out of range");
    6af8:	00005517          	auipc	a0,0x5
    6afc:	af850513          	add	a0,a0,-1288 # b5f0 <main+0x4c0>
    6b00:	ffffa097          	auipc	ra,0xffffa
    6b04:	bd4080e7          	jalr	-1068(ra) # 6d4 <panic>

00006b08 <writei>:
{
    6b08:	fb010113          	add	sp,sp,-80
    6b0c:	04812423          	sw	s0,72(sp)
    6b10:	04112623          	sw	ra,76(sp)
    6b14:	04912223          	sw	s1,68(sp)
    6b18:	05212023          	sw	s2,64(sp)
    6b1c:	03312e23          	sw	s3,60(sp)
    6b20:	03412c23          	sw	s4,56(sp)
    6b24:	03512a23          	sw	s5,52(sp)
    6b28:	03612823          	sw	s6,48(sp)
    6b2c:	03712623          	sw	s7,44(sp)
    6b30:	03812423          	sw	s8,40(sp)
    6b34:	03912223          	sw	s9,36(sp)
    6b38:	03a12023          	sw	s10,32(sp)
    6b3c:	01b12e23          	sw	s11,28(sp)
    6b40:	05010413          	add	s0,sp,80
  if(off > ip->size || off + n < off)
    6b44:	03052783          	lw	a5,48(a0)
{
    6b48:	fab42e23          	sw	a1,-68(s0)
  if(off > ip->size || off + n < off)
    6b4c:	22d7ee63          	bltu	a5,a3,6d88 <writei+0x280>
    6b50:	00e687b3          	add	a5,a3,a4
    6b54:	00068493          	mv	s1,a3
    6b58:	00070b13          	mv	s6,a4
    6b5c:	22d7e663          	bltu	a5,a3,6d88 <writei+0x280>
  if(off + n > MAXFILE*BSIZE)
    6b60:	00043737          	lui	a4,0x43
    6b64:	00000913          	li	s2,0
    6b68:	22f76063          	bltu	a4,a5,6d88 <writei+0x280>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    6b6c:	1c0b0e63          	beqz	s6,6d48 <writei+0x240>
    6b70:	00050993          	mv	s3,a0
    6b74:	00060a13          	mv	s4,a2
  if(bn < NDIRECT){
    6b78:	00b00c13          	li	s8,11
    m = min(n - tot, BSIZE - off%BSIZE);
    6b7c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    6b80:	fff00c93          	li	s9,-1
    6b84:	0b80006f          	j	6c3c <writei+0x134>
  bn -= NDIRECT;
    6b88:	ff478b93          	add	s7,a5,-12
  if(bn < NINDIRECT){
    6b8c:	0ff00793          	li	a5,255
    6b90:	2177e063          	bltu	a5,s7,6d90 <writei+0x288>
    if((addr = ip->addrs[NDIRECT]) == 0)
    6b94:	0649a583          	lw	a1,100(s3)
    6b98:	000a8513          	mv	a0,s5
    6b9c:	10058063          	beqz	a1,6c9c <writei+0x194>
    bp = bread(ip->dev, addr);
    6ba0:	fffff097          	auipc	ra,0xfffff
    6ba4:	918080e7          	jalr	-1768(ra) # 54b8 <bread>
    if((addr = a[bn]) == 0){
    6ba8:	002b9793          	sll	a5,s7,0x2
    a = (uint*)bp->data;
    6bac:	03850693          	add	a3,a0,56
    if((addr = a[bn]) == 0){
    6bb0:	00f687b3          	add	a5,a3,a5
    6bb4:	0007ab83          	lw	s7,0(a5)
    bp = bread(ip->dev, addr);
    6bb8:	00050d93          	mv	s11,a0
    if((addr = a[bn]) == 0){
    6bbc:	0a0b8a63          	beqz	s7,6c70 <writei+0x168>
    brelse(bp);
    6bc0:	000d8513          	mv	a0,s11
    6bc4:	fffff097          	auipc	ra,0xfffff
    6bc8:	aa0080e7          	jalr	-1376(ra) # 5664 <brelse>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    6bcc:	000b8593          	mv	a1,s7
    6bd0:	000a8513          	mv	a0,s5
    6bd4:	fffff097          	auipc	ra,0xfffff
    6bd8:	8e4080e7          	jalr	-1820(ra) # 54b8 <bread>
    m = min(n - tot, BSIZE - off%BSIZE);
    6bdc:	3ff4f793          	and	a5,s1,1023
    6be0:	412b0733          	sub	a4,s6,s2
    6be4:	40fd0bb3          	sub	s7,s10,a5
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    6be8:	00050a93          	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    6bec:	01777463          	bgeu	a4,s7,6bf4 <writei+0xec>
    6bf0:	00070b93          	mv	s7,a4
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    6bf4:	fbc42583          	lw	a1,-68(s0)
    6bf8:	038a8513          	add	a0,s5,56
    6bfc:	000b8693          	mv	a3,s7
    6c00:	000a0613          	mv	a2,s4
    6c04:	00f50533          	add	a0,a0,a5
    6c08:	ffffd097          	auipc	ra,0xffffd
    6c0c:	798080e7          	jalr	1944(ra) # 43a0 <either_copyin>
    6c10:	0b950263          	beq	a0,s9,6cb4 <writei+0x1ac>
    log_write(bp);
    6c14:	000a8513          	mv	a0,s5
    6c18:	00001097          	auipc	ra,0x1
    6c1c:	b04080e7          	jalr	-1276(ra) # 771c <log_write>
    brelse(bp);
    6c20:	000a8513          	mv	a0,s5
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    6c24:	01790933          	add	s2,s2,s7
    brelse(bp);
    6c28:	fffff097          	auipc	ra,0xfffff
    6c2c:	a3c080e7          	jalr	-1476(ra) # 5664 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    6c30:	017484b3          	add	s1,s1,s7
    6c34:	017a0a33          	add	s4,s4,s7
    6c38:	09697463          	bgeu	s2,s6,6cc0 <writei+0x1b8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    6c3c:	00a4d793          	srl	a5,s1,0xa
    6c40:	0009aa83          	lw	s5,0(s3)
  if(bn < NDIRECT){
    6c44:	f4fc62e3          	bltu	s8,a5,6b88 <writei+0x80>
    if((addr = ip->addrs[bn]) == 0)
    6c48:	00279793          	sll	a5,a5,0x2
    6c4c:	00f98db3          	add	s11,s3,a5
    6c50:	034dab83          	lw	s7,52(s11)
    6c54:	f60b9ce3          	bnez	s7,6bcc <writei+0xc4>
      ip->addrs[bn] = addr = balloc(ip->dev);
    6c58:	000a8513          	mv	a0,s5
    6c5c:	fffff097          	auipc	ra,0xfffff
    6c60:	b74080e7          	jalr	-1164(ra) # 57d0 <balloc>
    6c64:	00050b93          	mv	s7,a0
    6c68:	02adaa23          	sw	a0,52(s11)
    6c6c:	f61ff06f          	j	6bcc <writei+0xc4>
      a[bn] = addr = balloc(ip->dev);
    6c70:	0009a503          	lw	a0,0(s3)
    6c74:	faf42c23          	sw	a5,-72(s0)
    6c78:	fffff097          	auipc	ra,0xfffff
    6c7c:	b58080e7          	jalr	-1192(ra) # 57d0 <balloc>
    6c80:	fb842783          	lw	a5,-72(s0)
    6c84:	00050b93          	mv	s7,a0
    6c88:	00a7a023          	sw	a0,0(a5)
      log_write(bp);
    6c8c:	000d8513          	mv	a0,s11
    6c90:	00001097          	auipc	ra,0x1
    6c94:	a8c080e7          	jalr	-1396(ra) # 771c <log_write>
    6c98:	f29ff06f          	j	6bc0 <writei+0xb8>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    6c9c:	fffff097          	auipc	ra,0xfffff
    6ca0:	b34080e7          	jalr	-1228(ra) # 57d0 <balloc>
    6ca4:	00050593          	mv	a1,a0
    6ca8:	06b9a223          	sw	a1,100(s3)
    bp = bread(ip->dev, addr);
    6cac:	0009a503          	lw	a0,0(s3)
    6cb0:	ef1ff06f          	j	6ba0 <writei+0x98>
      brelse(bp);
    6cb4:	000a8513          	mv	a0,s5
    6cb8:	fffff097          	auipc	ra,0xfffff
    6cbc:	9ac080e7          	jalr	-1620(ra) # 5664 <brelse>
    if(off > ip->size)
    6cc0:	0309a783          	lw	a5,48(s3)
    6cc4:	0097f463          	bgeu	a5,s1,6ccc <writei+0x1c4>
      ip->size = off;
    6cc8:	0299a823          	sw	s1,48(s3)
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    6ccc:	0049a783          	lw	a5,4(s3)
    6cd0:	0009a503          	lw	a0,0(s3)
    6cd4:	0001a597          	auipc	a1,0x1a
    6cd8:	d085a583          	lw	a1,-760(a1) # 209dc <sb+0x18>
    6cdc:	0047d793          	srl	a5,a5,0x4
    6ce0:	00b785b3          	add	a1,a5,a1
    6ce4:	ffffe097          	auipc	ra,0xffffe
    6ce8:	7d4080e7          	jalr	2004(ra) # 54b8 <bread>
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    6cec:	0049a783          	lw	a5,4(s3)
  dip->type = ip->type;
    6cf0:	0289a883          	lw	a7,40(s3)
    6cf4:	02c9a803          	lw	a6,44(s3)
  dip->size = ip->size;
    6cf8:	0309a683          	lw	a3,48(s3)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    6cfc:	00f7f793          	and	a5,a5,15
    6d00:	00679713          	sll	a4,a5,0x6
    6d04:	03850793          	add	a5,a0,56
    6d08:	00e787b3          	add	a5,a5,a4
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    6d0c:	00050493          	mv	s1,a0
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    6d10:	03400613          	li	a2,52
    6d14:	03498593          	add	a1,s3,52
  dip->type = ip->type;
    6d18:	0117a023          	sw	a7,0(a5)
    6d1c:	0107a223          	sw	a6,4(a5)
  dip->size = ip->size;
    6d20:	00d7a423          	sw	a3,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    6d24:	00c78513          	add	a0,a5,12
    6d28:	ffffb097          	auipc	ra,0xffffb
    6d2c:	adc080e7          	jalr	-1316(ra) # 1804 <memmove>
  log_write(bp);
    6d30:	00048513          	mv	a0,s1
    6d34:	00001097          	auipc	ra,0x1
    6d38:	9e8080e7          	jalr	-1560(ra) # 771c <log_write>
  brelse(bp);
    6d3c:	00048513          	mv	a0,s1
    6d40:	fffff097          	auipc	ra,0xfffff
    6d44:	924080e7          	jalr	-1756(ra) # 5664 <brelse>
  return n;
    6d48:	000b0513          	mv	a0,s6
}
    6d4c:	04c12083          	lw	ra,76(sp)
    6d50:	04812403          	lw	s0,72(sp)
    6d54:	04412483          	lw	s1,68(sp)
    6d58:	04012903          	lw	s2,64(sp)
    6d5c:	03c12983          	lw	s3,60(sp)
    6d60:	03812a03          	lw	s4,56(sp)
    6d64:	03412a83          	lw	s5,52(sp)
    6d68:	03012b03          	lw	s6,48(sp)
    6d6c:	02c12b83          	lw	s7,44(sp)
    6d70:	02812c03          	lw	s8,40(sp)
    6d74:	02412c83          	lw	s9,36(sp)
    6d78:	02012d03          	lw	s10,32(sp)
    6d7c:	01c12d83          	lw	s11,28(sp)
    6d80:	05010113          	add	sp,sp,80
    6d84:	00008067          	ret
    return -1;
    6d88:	fff00513          	li	a0,-1
    6d8c:	fc1ff06f          	j	6d4c <writei+0x244>
  panic("bmap: out of range");
    6d90:	00005517          	auipc	a0,0x5
    6d94:	86050513          	add	a0,a0,-1952 # b5f0 <main+0x4c0>
    6d98:	ffffa097          	auipc	ra,0xffffa
    6d9c:	93c080e7          	jalr	-1732(ra) # 6d4 <panic>

00006da0 <namecmp>:
{
    6da0:	ff010113          	add	sp,sp,-16
    6da4:	00812623          	sw	s0,12(sp)
    6da8:	01010413          	add	s0,sp,16
}
    6dac:	00c12403          	lw	s0,12(sp)
  return strncmp(s, t, DIRSIZ);
    6db0:	00e00613          	li	a2,14
}
    6db4:	01010113          	add	sp,sp,16
  return strncmp(s, t, DIRSIZ);
    6db8:	ffffb317          	auipc	t1,0xffffb
    6dbc:	c5030067          	jr	-944(t1) # 1a08 <strncmp>

00006dc0 <dirlookup>:
{
    6dc0:	fd010113          	add	sp,sp,-48
    6dc4:	02812423          	sw	s0,40(sp)
    6dc8:	02112623          	sw	ra,44(sp)
    6dcc:	02912223          	sw	s1,36(sp)
    6dd0:	03212023          	sw	s2,32(sp)
    6dd4:	01312e23          	sw	s3,28(sp)
    6dd8:	01412c23          	sw	s4,24(sp)
    6ddc:	01512a23          	sw	s5,20(sp)
    6de0:	03010413          	add	s0,sp,48
  if(dp->type != T_DIR)
    6de4:	02851703          	lh	a4,40(a0)
    6de8:	00100793          	li	a5,1
    6dec:	16f71e63          	bne	a4,a5,6f68 <dirlookup+0x1a8>
  for(off = 0; off < dp->size; off += sizeof(de)){
    6df0:	03052783          	lw	a5,48(a0)
    6df4:	00050913          	mv	s2,a0
    6df8:	00058a13          	mv	s4,a1
    6dfc:	00060a93          	mv	s5,a2
    6e00:	00000493          	li	s1,0
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    6e04:	01000993          	li	s3,16
  for(off = 0; off < dp->size; off += sizeof(de)){
    6e08:	04078463          	beqz	a5,6e50 <dirlookup+0x90>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    6e0c:	00048613          	mv	a2,s1
    6e10:	fd040593          	add	a1,s0,-48
    6e14:	00090513          	mv	a0,s2
    6e18:	fffff097          	auipc	ra,0xfffff
    6e1c:	b00080e7          	jalr	-1280(ra) # 5918 <readi.constprop.0>
    6e20:	13351463          	bne	a0,s3,6f48 <dirlookup+0x188>
    if(de.inum == 0)
    6e24:	fd045783          	lhu	a5,-48(s0)
    6e28:	00078e63          	beqz	a5,6e44 <dirlookup+0x84>
  return strncmp(s, t, DIRSIZ);
    6e2c:	00e00613          	li	a2,14
    6e30:	fd240593          	add	a1,s0,-46
    6e34:	000a0513          	mv	a0,s4
    6e38:	ffffb097          	auipc	ra,0xffffb
    6e3c:	bd0080e7          	jalr	-1072(ra) # 1a08 <strncmp>
    if(namecmp(name, de.name) == 0){
    6e40:	02050e63          	beqz	a0,6e7c <dirlookup+0xbc>
  for(off = 0; off < dp->size; off += sizeof(de)){
    6e44:	03092783          	lw	a5,48(s2)
    6e48:	01048493          	add	s1,s1,16
    6e4c:	fcf4e0e3          	bltu	s1,a5,6e0c <dirlookup+0x4c>
  return 0;
    6e50:	00000493          	li	s1,0
}
    6e54:	02c12083          	lw	ra,44(sp)
    6e58:	02812403          	lw	s0,40(sp)
    6e5c:	02012903          	lw	s2,32(sp)
    6e60:	01c12983          	lw	s3,28(sp)
    6e64:	01812a03          	lw	s4,24(sp)
    6e68:	01412a83          	lw	s5,20(sp)
    6e6c:	00048513          	mv	a0,s1
    6e70:	02412483          	lw	s1,36(sp)
    6e74:	03010113          	add	sp,sp,48
    6e78:	00008067          	ret
      if(poff)
    6e7c:	000a8463          	beqz	s5,6e84 <dirlookup+0xc4>
        *poff = off;
    6e80:	009aa023          	sw	s1,0(s5)
  acquire(&icache.lock);
    6e84:	0001a517          	auipc	a0,0x1a
    6e88:	b6050513          	add	a0,a0,-1184 # 209e4 <icache>
      inum = de.inum;
    6e8c:	fd045983          	lhu	s3,-48(s0)
      return iget(dp->dev, inum);
    6e90:	00092903          	lw	s2,0(s2)
  acquire(&icache.lock);
    6e94:	ffffa097          	auipc	ra,0xffffa
    6e98:	2dc080e7          	jalr	732(ra) # 1170 <acquire>
  empty = 0;
    6e9c:	00000493          	li	s1,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6ea0:	0001a797          	auipc	a5,0x1a
    6ea4:	b5078793          	add	a5,a5,-1200 # 209f0 <icache+0xc>
    6ea8:	0001b617          	auipc	a2,0x1b
    6eac:	f9860613          	add	a2,a2,-104 # 21e40 <log>
    6eb0:	0140006f          	j	6ec4 <dirlookup+0x104>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6eb4:	0007a683          	lw	a3,0(a5)
    6eb8:	04d90a63          	beq	s2,a3,6f0c <dirlookup+0x14c>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6ebc:	06878793          	add	a5,a5,104
    6ec0:	02c78063          	beq	a5,a2,6ee0 <dirlookup+0x120>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6ec4:	0087a703          	lw	a4,8(a5)
    6ec8:	fee046e3          	bgtz	a4,6eb4 <dirlookup+0xf4>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    6ecc:	fe0498e3          	bnez	s1,6ebc <dirlookup+0xfc>
    6ed0:	06071263          	bnez	a4,6f34 <dirlookup+0x174>
    6ed4:	00078493          	mv	s1,a5
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6ed8:	06878793          	add	a5,a5,104
    6edc:	fec794e3          	bne	a5,a2,6ec4 <dirlookup+0x104>
  if(empty == 0)
    6ee0:	06048c63          	beqz	s1,6f58 <dirlookup+0x198>
  ip->ref = 1;
    6ee4:	00100793          	li	a5,1
  ip->dev = dev;
    6ee8:	0124a023          	sw	s2,0(s1)
  ip->inum = inum;
    6eec:	0134a223          	sw	s3,4(s1)
  ip->ref = 1;
    6ef0:	00f4a423          	sw	a5,8(s1)
  ip->valid = 0;
    6ef4:	0204a223          	sw	zero,36(s1)
  release(&icache.lock);
    6ef8:	0001a517          	auipc	a0,0x1a
    6efc:	aec50513          	add	a0,a0,-1300 # 209e4 <icache>
    6f00:	ffffa097          	auipc	ra,0xffffa
    6f04:	3fc080e7          	jalr	1020(ra) # 12fc <release>
  return ip;
    6f08:	f4dff06f          	j	6e54 <dirlookup+0x94>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6f0c:	0047a683          	lw	a3,4(a5)
    6f10:	fad996e3          	bne	s3,a3,6ebc <dirlookup+0xfc>
      ip->ref++;
    6f14:	00170713          	add	a4,a4,1 # 43001 <end+0x1efed>
      release(&icache.lock);
    6f18:	0001a517          	auipc	a0,0x1a
    6f1c:	acc50513          	add	a0,a0,-1332 # 209e4 <icache>
      ip->ref++;
    6f20:	00e7a423          	sw	a4,8(a5)
      return ip;
    6f24:	00078493          	mv	s1,a5
      release(&icache.lock);
    6f28:	ffffa097          	auipc	ra,0xffffa
    6f2c:	3d4080e7          	jalr	980(ra) # 12fc <release>
      return ip;
    6f30:	f25ff06f          	j	6e54 <dirlookup+0x94>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    6f34:	06878793          	add	a5,a5,104
    6f38:	02c78063          	beq	a5,a2,6f58 <dirlookup+0x198>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    6f3c:	0087a703          	lw	a4,8(a5)
    6f40:	f6e04ae3          	bgtz	a4,6eb4 <dirlookup+0xf4>
    6f44:	f8dff06f          	j	6ed0 <dirlookup+0x110>
      panic("dirlookup read");
    6f48:	00004517          	auipc	a0,0x4
    6f4c:	73850513          	add	a0,a0,1848 # b680 <main+0x550>
    6f50:	ffff9097          	auipc	ra,0xffff9
    6f54:	784080e7          	jalr	1924(ra) # 6d4 <panic>
    panic("iget: no inodes");
    6f58:	00004517          	auipc	a0,0x4
    6f5c:	6d050513          	add	a0,a0,1744 # b628 <main+0x4f8>
    6f60:	ffff9097          	auipc	ra,0xffff9
    6f64:	774080e7          	jalr	1908(ra) # 6d4 <panic>
    panic("dirlookup not DIR");
    6f68:	00004517          	auipc	a0,0x4
    6f6c:	72850513          	add	a0,a0,1832 # b690 <main+0x560>
    6f70:	ffff9097          	auipc	ra,0xffff9
    6f74:	764080e7          	jalr	1892(ra) # 6d4 <panic>

00006f78 <dirlink>:
{
    6f78:	fd010113          	add	sp,sp,-48
    6f7c:	02812423          	sw	s0,40(sp)
    6f80:	02112623          	sw	ra,44(sp)
    6f84:	02912223          	sw	s1,36(sp)
    6f88:	03212023          	sw	s2,32(sp)
    6f8c:	01312e23          	sw	s3,28(sp)
    6f90:	01412c23          	sw	s4,24(sp)
    6f94:	01512a23          	sw	s5,20(sp)
    6f98:	01612823          	sw	s6,16(sp)
    6f9c:	03010413          	add	s0,sp,48
  if(dp->type != T_DIR)
    6fa0:	02851703          	lh	a4,40(a0)
    6fa4:	00100793          	li	a5,1
    6fa8:	20f71663          	bne	a4,a5,71b4 <dirlink+0x23c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    6fac:	03052483          	lw	s1,48(a0)
    6fb0:	00050993          	mv	s3,a0
    6fb4:	00058a93          	mv	s5,a1
    6fb8:	00060b13          	mv	s6,a2
    6fbc:	00000913          	li	s2,0
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    6fc0:	01000a13          	li	s4,16
  for(off = 0; off < dp->size; off += sizeof(de)){
    6fc4:	1c048463          	beqz	s1,718c <dirlink+0x214>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    6fc8:	00090613          	mv	a2,s2
    6fcc:	fd040593          	add	a1,s0,-48
    6fd0:	00098513          	mv	a0,s3
    6fd4:	fffff097          	auipc	ra,0xfffff
    6fd8:	944080e7          	jalr	-1724(ra) # 5918 <readi.constprop.0>
    6fdc:	1b451c63          	bne	a0,s4,7194 <dirlink+0x21c>
    if(de.inum == 0)
    6fe0:	fd045783          	lhu	a5,-48(s0)
    6fe4:	00078e63          	beqz	a5,7000 <dirlink+0x88>
  return strncmp(s, t, DIRSIZ);
    6fe8:	00e00613          	li	a2,14
    6fec:	fd240593          	add	a1,s0,-46
    6ff0:	000a8513          	mv	a0,s5
    6ff4:	ffffb097          	auipc	ra,0xffffb
    6ff8:	a14080e7          	jalr	-1516(ra) # 1a08 <strncmp>
    if(namecmp(name, de.name) == 0){
    6ffc:	0a050e63          	beqz	a0,70b8 <dirlink+0x140>
  for(off = 0; off < dp->size; off += sizeof(de)){
    7000:	0309a483          	lw	s1,48(s3)
    7004:	01090913          	add	s2,s2,16
    7008:	fc9960e3          	bltu	s2,s1,6fc8 <dirlink+0x50>
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    700c:	fd040a13          	add	s4,s0,-48
  for(off = 0; off < dp->size; off += sizeof(de)){
    7010:	02048e63          	beqz	s1,704c <dirlink+0xd4>
    7014:	00000493          	li	s1,0
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    7018:	01000913          	li	s2,16
    701c:	0100006f          	j	702c <dirlink+0xb4>
  for(off = 0; off < dp->size; off += sizeof(de)){
    7020:	0309a783          	lw	a5,48(s3)
    7024:	01048493          	add	s1,s1,16
    7028:	02f4f263          	bgeu	s1,a5,704c <dirlink+0xd4>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    702c:	00048613          	mv	a2,s1
    7030:	fd040593          	add	a1,s0,-48
    7034:	00098513          	mv	a0,s3
    7038:	fffff097          	auipc	ra,0xfffff
    703c:	8e0080e7          	jalr	-1824(ra) # 5918 <readi.constprop.0>
    7040:	17251263          	bne	a0,s2,71a4 <dirlink+0x22c>
    if(de.inum == 0)
    7044:	fd045783          	lhu	a5,-48(s0)
    7048:	fc079ce3          	bnez	a5,7020 <dirlink+0xa8>
  strncpy(de.name, name, DIRSIZ);
    704c:	00e00613          	li	a2,14
    7050:	000a8593          	mv	a1,s5
    7054:	fd240513          	add	a0,s0,-46
    7058:	ffffb097          	auipc	ra,0xffffb
    705c:	a0c080e7          	jalr	-1524(ra) # 1a64 <strncpy>
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    7060:	01000713          	li	a4,16
    7064:	00048693          	mv	a3,s1
    7068:	000a0613          	mv	a2,s4
    706c:	00000593          	li	a1,0
    7070:	00098513          	mv	a0,s3
  de.inum = inum;
    7074:	fd641823          	sh	s6,-48(s0)
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    7078:	00000097          	auipc	ra,0x0
    707c:	a90080e7          	jalr	-1392(ra) # 6b08 <writei>
    7080:	01000713          	li	a4,16
  return 0;
    7084:	00000793          	li	a5,0
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    7088:	12e51e63          	bne	a0,a4,71c4 <dirlink+0x24c>
}
    708c:	02c12083          	lw	ra,44(sp)
    7090:	02812403          	lw	s0,40(sp)
    7094:	02412483          	lw	s1,36(sp)
    7098:	02012903          	lw	s2,32(sp)
    709c:	01c12983          	lw	s3,28(sp)
    70a0:	01812a03          	lw	s4,24(sp)
    70a4:	01412a83          	lw	s5,20(sp)
    70a8:	01012b03          	lw	s6,16(sp)
    70ac:	00078513          	mv	a0,a5
    70b0:	03010113          	add	sp,sp,48
    70b4:	00008067          	ret
  acquire(&icache.lock);
    70b8:	0001a517          	auipc	a0,0x1a
    70bc:	92c50513          	add	a0,a0,-1748 # 209e4 <icache>
      inum = de.inum;
    70c0:	fd045a03          	lhu	s4,-48(s0)
      return iget(dp->dev, inum);
    70c4:	0009a903          	lw	s2,0(s3)
  acquire(&icache.lock);
    70c8:	ffffa097          	auipc	ra,0xffffa
    70cc:	0a8080e7          	jalr	168(ra) # 1170 <acquire>
  empty = 0;
    70d0:	00000493          	li	s1,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    70d4:	0001a797          	auipc	a5,0x1a
    70d8:	91c78793          	add	a5,a5,-1764 # 209f0 <icache+0xc>
    70dc:	0001b617          	auipc	a2,0x1b
    70e0:	d6460613          	add	a2,a2,-668 # 21e40 <log>
    70e4:	0140006f          	j	70f8 <dirlink+0x180>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    70e8:	0007a683          	lw	a3,0(a5)
    70ec:	06d90263          	beq	s2,a3,7150 <dirlink+0x1d8>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    70f0:	06878793          	add	a5,a5,104
    70f4:	02c78063          	beq	a5,a2,7114 <dirlink+0x19c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    70f8:	0087a703          	lw	a4,8(a5)
    70fc:	fee046e3          	bgtz	a4,70e8 <dirlink+0x170>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    7100:	fe0498e3          	bnez	s1,70f0 <dirlink+0x178>
    7104:	06071a63          	bnez	a4,7178 <dirlink+0x200>
    7108:	00078493          	mv	s1,a5
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    710c:	06878793          	add	a5,a5,104
    7110:	fec794e3          	bne	a5,a2,70f8 <dirlink+0x180>
  if(empty == 0)
    7114:	0c048063          	beqz	s1,71d4 <dirlink+0x25c>
  ip->ref = 1;
    7118:	00100793          	li	a5,1
  ip->dev = dev;
    711c:	0124a023          	sw	s2,0(s1)
  ip->inum = inum;
    7120:	0144a223          	sw	s4,4(s1)
  ip->ref = 1;
    7124:	00f4a423          	sw	a5,8(s1)
  ip->valid = 0;
    7128:	0204a223          	sw	zero,36(s1)
  release(&icache.lock);
    712c:	0001a517          	auipc	a0,0x1a
    7130:	8b850513          	add	a0,a0,-1864 # 209e4 <icache>
    7134:	ffffa097          	auipc	ra,0xffffa
    7138:	1c8080e7          	jalr	456(ra) # 12fc <release>
    iput(ip);
    713c:	00048513          	mv	a0,s1
    7140:	fffff097          	auipc	ra,0xfffff
    7144:	f44080e7          	jalr	-188(ra) # 6084 <iput>
    return -1;
    7148:	fff00793          	li	a5,-1
    714c:	f41ff06f          	j	708c <dirlink+0x114>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    7150:	0047a683          	lw	a3,4(a5)
    7154:	f8da1ee3          	bne	s4,a3,70f0 <dirlink+0x178>
      ip->ref++;
    7158:	00170713          	add	a4,a4,1
      release(&icache.lock);
    715c:	0001a517          	auipc	a0,0x1a
    7160:	88850513          	add	a0,a0,-1912 # 209e4 <icache>
      ip->ref++;
    7164:	00e7a423          	sw	a4,8(a5)
      release(&icache.lock);
    7168:	00078493          	mv	s1,a5
    716c:	ffffa097          	auipc	ra,0xffffa
    7170:	190080e7          	jalr	400(ra) # 12fc <release>
      return ip;
    7174:	fc9ff06f          	j	713c <dirlink+0x1c4>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    7178:	06878793          	add	a5,a5,104
    717c:	04c78c63          	beq	a5,a2,71d4 <dirlink+0x25c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    7180:	0087a703          	lw	a4,8(a5)
    7184:	f6e042e3          	bgtz	a4,70e8 <dirlink+0x170>
    7188:	f7dff06f          	j	7104 <dirlink+0x18c>
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    718c:	fd040a13          	add	s4,s0,-48
    7190:	ebdff06f          	j	704c <dirlink+0xd4>
      panic("dirlookup read");
    7194:	00004517          	auipc	a0,0x4
    7198:	4ec50513          	add	a0,a0,1260 # b680 <main+0x550>
    719c:	ffff9097          	auipc	ra,0xffff9
    71a0:	538080e7          	jalr	1336(ra) # 6d4 <panic>
      panic("dirlink read");
    71a4:	00004517          	auipc	a0,0x4
    71a8:	50050513          	add	a0,a0,1280 # b6a4 <main+0x574>
    71ac:	ffff9097          	auipc	ra,0xffff9
    71b0:	528080e7          	jalr	1320(ra) # 6d4 <panic>
    panic("dirlookup not DIR");
    71b4:	00004517          	auipc	a0,0x4
    71b8:	4dc50513          	add	a0,a0,1244 # b690 <main+0x560>
    71bc:	ffff9097          	auipc	ra,0xffff9
    71c0:	518080e7          	jalr	1304(ra) # 6d4 <panic>
    panic("dirlink");
    71c4:	00004517          	auipc	a0,0x4
    71c8:	60050513          	add	a0,a0,1536 # b7c4 <main+0x694>
    71cc:	ffff9097          	auipc	ra,0xffff9
    71d0:	508080e7          	jalr	1288(ra) # 6d4 <panic>
    panic("iget: no inodes");
    71d4:	00004517          	auipc	a0,0x4
    71d8:	45450513          	add	a0,a0,1108 # b628 <main+0x4f8>
    71dc:	ffff9097          	auipc	ra,0xffff9
    71e0:	4f8080e7          	jalr	1272(ra) # 6d4 <panic>

000071e4 <namei>:

struct inode*
namei(char *path)
{
    71e4:	fe010113          	add	sp,sp,-32
    71e8:	00812c23          	sw	s0,24(sp)
    71ec:	00112e23          	sw	ra,28(sp)
    71f0:	02010413          	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    71f4:	fe040613          	add	a2,s0,-32
    71f8:	00000593          	li	a1,0
    71fc:	fffff097          	auipc	ra,0xfffff
    7200:	22c080e7          	jalr	556(ra) # 6428 <namex>
}
    7204:	01c12083          	lw	ra,28(sp)
    7208:	01812403          	lw	s0,24(sp)
    720c:	02010113          	add	sp,sp,32
    7210:	00008067          	ret

00007214 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    7214:	ff010113          	add	sp,sp,-16
    7218:	00812623          	sw	s0,12(sp)
    721c:	01010413          	add	s0,sp,16
  return namex(path, 1, name);
}
    7220:	00c12403          	lw	s0,12(sp)
{
    7224:	00058613          	mv	a2,a1
  return namex(path, 1, name);
    7228:	00100593          	li	a1,1
}
    722c:	01010113          	add	sp,sp,16
  return namex(path, 1, name);
    7230:	fffff317          	auipc	t1,0xfffff
    7234:	1f830067          	jr	504(t1) # 6428 <namex>

00007238 <install_trans>:
}

// Copy committed blocks from log to their home location
static void
install_trans(void)
{
    7238:	fe010113          	add	sp,sp,-32
    723c:	00812c23          	sw	s0,24(sp)
    7240:	01312623          	sw	s3,12(sp)
    7244:	00112e23          	sw	ra,28(sp)
    7248:	00912a23          	sw	s1,20(sp)
    724c:	01212823          	sw	s2,16(sp)
    7250:	01412423          	sw	s4,8(sp)
    7254:	01512223          	sw	s5,4(sp)
    7258:	02010413          	add	s0,sp,32
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
    725c:	0001b997          	auipc	s3,0x1b
    7260:	be498993          	add	s3,s3,-1052 # 21e40 <log>
    7264:	0209a783          	lw	a5,32(s3)
    7268:	08f05a63          	blez	a5,72fc <install_trans+0xc4>
    726c:	0001ba97          	auipc	s5,0x1b
    7270:	bf8a8a93          	add	s5,s5,-1032 # 21e64 <log+0x24>
    7274:	00000a13          	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    7278:	00c9a583          	lw	a1,12(s3)
    727c:	01c9a503          	lw	a0,28(s3)
  for (tail = 0; tail < log.lh.n; tail++) {
    7280:	004a8a93          	add	s5,s5,4
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    7284:	00ba05b3          	add	a1,s4,a1
    7288:	00158593          	add	a1,a1,1
    728c:	ffffe097          	auipc	ra,0xffffe
    7290:	22c080e7          	jalr	556(ra) # 54b8 <bread>
    7294:	00050913          	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    7298:	ffcaa583          	lw	a1,-4(s5)
    729c:	01c9a503          	lw	a0,28(s3)
  for (tail = 0; tail < log.lh.n; tail++) {
    72a0:	001a0a13          	add	s4,s4,1
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    72a4:	ffffe097          	auipc	ra,0xffffe
    72a8:	214080e7          	jalr	532(ra) # 54b8 <bread>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    72ac:	40000613          	li	a2,1024
    72b0:	03890593          	add	a1,s2,56
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    72b4:	00050493          	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    72b8:	03850513          	add	a0,a0,56
    72bc:	ffffa097          	auipc	ra,0xffffa
    72c0:	548080e7          	jalr	1352(ra) # 1804 <memmove>
    bwrite(dbuf);  // write dst to disk
    72c4:	00048513          	mv	a0,s1
    72c8:	ffffe097          	auipc	ra,0xffffe
    72cc:	344080e7          	jalr	836(ra) # 560c <bwrite>
    bunpin(dbuf);
    72d0:	00048513          	mv	a0,s1
    72d4:	ffffe097          	auipc	ra,0xffffe
    72d8:	4a8080e7          	jalr	1192(ra) # 577c <bunpin>
    brelse(lbuf);
    72dc:	00090513          	mv	a0,s2
    72e0:	ffffe097          	auipc	ra,0xffffe
    72e4:	384080e7          	jalr	900(ra) # 5664 <brelse>
    brelse(dbuf);
    72e8:	00048513          	mv	a0,s1
    72ec:	ffffe097          	auipc	ra,0xffffe
    72f0:	378080e7          	jalr	888(ra) # 5664 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    72f4:	0209a783          	lw	a5,32(s3)
    72f8:	f8fa40e3          	blt	s4,a5,7278 <install_trans+0x40>
  }
}
    72fc:	01c12083          	lw	ra,28(sp)
    7300:	01812403          	lw	s0,24(sp)
    7304:	01412483          	lw	s1,20(sp)
    7308:	01012903          	lw	s2,16(sp)
    730c:	00c12983          	lw	s3,12(sp)
    7310:	00812a03          	lw	s4,8(sp)
    7314:	00412a83          	lw	s5,4(sp)
    7318:	02010113          	add	sp,sp,32
    731c:	00008067          	ret

00007320 <initlog>:
{
    7320:	fe010113          	add	sp,sp,-32
    7324:	00112e23          	sw	ra,28(sp)
    7328:	00812c23          	sw	s0,24(sp)
    732c:	00912a23          	sw	s1,20(sp)
    7330:	01212823          	sw	s2,16(sp)
  initlock(&log.lock, "log");
    7334:	0001b497          	auipc	s1,0x1b
    7338:	b0c48493          	add	s1,s1,-1268 # 21e40 <log>
{
    733c:	01312623          	sw	s3,12(sp)
    7340:	02010413          	add	s0,sp,32
    7344:	00058993          	mv	s3,a1
    7348:	00050913          	mv	s2,a0
  initlock(&log.lock, "log");
    734c:	00004597          	auipc	a1,0x4
    7350:	36858593          	add	a1,a1,872 # b6b4 <main+0x584>
    7354:	00048513          	mv	a0,s1
    7358:	ffffa097          	auipc	ra,0xffffa
    735c:	df4080e7          	jalr	-524(ra) # 114c <initlock>
  log.start = sb->logstart;
    7360:	0149a583          	lw	a1,20(s3)
  log.size = sb->nlog;
    7364:	0109a783          	lw	a5,16(s3)

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
    7368:	00090513          	mv	a0,s2
  log.start = sb->logstart;
    736c:	00b4a623          	sw	a1,12(s1)
  log.size = sb->nlog;
    7370:	00f4a823          	sw	a5,16(s1)
  log.dev = dev;
    7374:	0124ae23          	sw	s2,28(s1)
  struct buf *buf = bread(log.dev, log.start);
    7378:	ffffe097          	auipc	ra,0xffffe
    737c:	140080e7          	jalr	320(ra) # 54b8 <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
    7380:	03852603          	lw	a2,56(a0)
    7384:	02c4a023          	sw	a2,32(s1)
  for (i = 0; i < log.lh.n; i++) {
    7388:	02c05663          	blez	a2,73b4 <initlog+0x94>
    738c:	00261613          	sll	a2,a2,0x2
    7390:	00050793          	mv	a5,a0
    7394:	0001b717          	auipc	a4,0x1b
    7398:	ad070713          	add	a4,a4,-1328 # 21e64 <log+0x24>
    739c:	00a60633          	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    73a0:	03c7a683          	lw	a3,60(a5)
  for (i = 0; i < log.lh.n; i++) {
    73a4:	00478793          	add	a5,a5,4
    73a8:	00470713          	add	a4,a4,4
    log.lh.block[i] = lh->block[i];
    73ac:	fed72e23          	sw	a3,-4(a4)
  for (i = 0; i < log.lh.n; i++) {
    73b0:	fec798e3          	bne	a5,a2,73a0 <initlog+0x80>
  }
  brelse(buf);
    73b4:	ffffe097          	auipc	ra,0xffffe
    73b8:	2b0080e7          	jalr	688(ra) # 5664 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    73bc:	00000097          	auipc	ra,0x0
    73c0:	e7c080e7          	jalr	-388(ra) # 7238 <install_trans>
  struct buf *buf = bread(log.dev, log.start);
    73c4:	00c4a583          	lw	a1,12(s1)
    73c8:	01c4a503          	lw	a0,28(s1)
  log.lh.n = 0;
    73cc:	0001b797          	auipc	a5,0x1b
    73d0:	a807aa23          	sw	zero,-1388(a5) # 21e60 <log+0x20>
  struct buf *buf = bread(log.dev, log.start);
    73d4:	ffffe097          	auipc	ra,0xffffe
    73d8:	0e4080e7          	jalr	228(ra) # 54b8 <bread>
  hb->n = log.lh.n;
    73dc:	0204a603          	lw	a2,32(s1)
  struct buf *buf = bread(log.dev, log.start);
    73e0:	00050493          	mv	s1,a0
  hb->n = log.lh.n;
    73e4:	02c52c23          	sw	a2,56(a0)
  for (i = 0; i < log.lh.n; i++) {
    73e8:	02c05663          	blez	a2,7414 <initlog+0xf4>
    73ec:	00261613          	sll	a2,a2,0x2
    73f0:	0001b717          	auipc	a4,0x1b
    73f4:	a7470713          	add	a4,a4,-1420 # 21e64 <log+0x24>
    73f8:	00050793          	mv	a5,a0
    73fc:	00a60633          	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    7400:	00072683          	lw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    7404:	00478793          	add	a5,a5,4
    7408:	00470713          	add	a4,a4,4
    hb->block[i] = log.lh.block[i];
    740c:	02d7ac23          	sw	a3,56(a5)
  for (i = 0; i < log.lh.n; i++) {
    7410:	fec798e3          	bne	a5,a2,7400 <initlog+0xe0>
  bwrite(buf);
    7414:	00048513          	mv	a0,s1
    7418:	ffffe097          	auipc	ra,0xffffe
    741c:	1f4080e7          	jalr	500(ra) # 560c <bwrite>
}
    7420:	01812403          	lw	s0,24(sp)
    7424:	01c12083          	lw	ra,28(sp)
    7428:	01012903          	lw	s2,16(sp)
    742c:	00c12983          	lw	s3,12(sp)
  brelse(buf);
    7430:	00048513          	mv	a0,s1
}
    7434:	01412483          	lw	s1,20(sp)
    7438:	02010113          	add	sp,sp,32
  brelse(buf);
    743c:	ffffe317          	auipc	t1,0xffffe
    7440:	22830067          	jr	552(t1) # 5664 <brelse>

00007444 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    7444:	ff010113          	add	sp,sp,-16
    7448:	00812423          	sw	s0,8(sp)
    744c:	00912223          	sw	s1,4(sp)
    7450:	01212023          	sw	s2,0(sp)
    7454:	00112623          	sw	ra,12(sp)
    7458:	01010413          	add	s0,sp,16
  acquire(&log.lock);
    745c:	0001b517          	auipc	a0,0x1b
    7460:	9e450513          	add	a0,a0,-1564 # 21e40 <log>
    7464:	ffffa097          	auipc	ra,0xffffa
    7468:	d0c080e7          	jalr	-756(ra) # 1170 <acquire>
    746c:	0001b497          	auipc	s1,0x1b
    7470:	9d448493          	add	s1,s1,-1580 # 21e40 <log>
  while(1){
    if(log.committing){
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    7474:	01e00913          	li	s2,30
    7478:	00c0006f          	j	7484 <begin_op+0x40>
      sleep(&log, &log.lock);
    747c:	ffffd097          	auipc	ra,0xffffd
    7480:	bf0080e7          	jalr	-1040(ra) # 406c <sleep>
    if(log.committing){
    7484:	0184a783          	lw	a5,24(s1)
      sleep(&log, &log.lock);
    7488:	00048593          	mv	a1,s1
    748c:	0001b517          	auipc	a0,0x1b
    7490:	9b450513          	add	a0,a0,-1612 # 21e40 <log>
    if(log.committing){
    7494:	fe0794e3          	bnez	a5,747c <begin_op+0x38>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    7498:	0144a703          	lw	a4,20(s1)
    749c:	0204a683          	lw	a3,32(s1)
    74a0:	00170713          	add	a4,a4,1
    74a4:	00271793          	sll	a5,a4,0x2
    74a8:	00e787b3          	add	a5,a5,a4
    74ac:	00179793          	sll	a5,a5,0x1
    74b0:	00d787b3          	add	a5,a5,a3
    74b4:	fcf944e3          	blt	s2,a5,747c <begin_op+0x38>
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
}
    74b8:	00812403          	lw	s0,8(sp)
    74bc:	00c12083          	lw	ra,12(sp)
    74c0:	00012903          	lw	s2,0(sp)
      log.outstanding += 1;
    74c4:	00e4aa23          	sw	a4,20(s1)
}
    74c8:	00412483          	lw	s1,4(sp)
      release(&log.lock);
    74cc:	0001b517          	auipc	a0,0x1b
    74d0:	97450513          	add	a0,a0,-1676 # 21e40 <log>
}
    74d4:	01010113          	add	sp,sp,16
      release(&log.lock);
    74d8:	ffffa317          	auipc	t1,0xffffa
    74dc:	e2430067          	jr	-476(t1) # 12fc <release>

000074e0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    74e0:	fe010113          	add	sp,sp,-32
    74e4:	00812c23          	sw	s0,24(sp)
    74e8:	00912a23          	sw	s1,20(sp)
    74ec:	01212823          	sw	s2,16(sp)
  int do_commit = 0;

  acquire(&log.lock);
    74f0:	0001b497          	auipc	s1,0x1b
    74f4:	95048493          	add	s1,s1,-1712 # 21e40 <log>
{
    74f8:	00112e23          	sw	ra,28(sp)
    74fc:	01312623          	sw	s3,12(sp)
    7500:	01412423          	sw	s4,8(sp)
    7504:	01512223          	sw	s5,4(sp)
    7508:	01612023          	sw	s6,0(sp)
    750c:	02010413          	add	s0,sp,32
  acquire(&log.lock);
    7510:	00048513          	mv	a0,s1
    7514:	ffffa097          	auipc	ra,0xffffa
    7518:	c5c080e7          	jalr	-932(ra) # 1170 <acquire>
  log.outstanding -= 1;
    751c:	0144a903          	lw	s2,20(s1)
  if(log.committing)
    7520:	0184a783          	lw	a5,24(s1)
  log.outstanding -= 1;
    7524:	fff90913          	add	s2,s2,-1
    7528:	0124aa23          	sw	s2,20(s1)
  if(log.committing)
    752c:	1e079063          	bnez	a5,770c <end_op+0x22c>
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    7530:	00048513          	mv	a0,s1
  if(log.outstanding == 0){
    7534:	1c091463          	bnez	s2,76fc <end_op+0x21c>
    log.committing = 1;
    7538:	00100793          	li	a5,1
    753c:	00f4ac23          	sw	a5,24(s1)
  release(&log.lock);
    7540:	ffffa097          	auipc	ra,0xffffa
    7544:	dbc080e7          	jalr	-580(ra) # 12fc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    7548:	0204a783          	lw	a5,32(s1)
    754c:	06f04063          	bgtz	a5,75ac <end_op+0xcc>
    acquire(&log.lock);
    7550:	0001b517          	auipc	a0,0x1b
    7554:	8f050513          	add	a0,a0,-1808 # 21e40 <log>
    7558:	ffffa097          	auipc	ra,0xffffa
    755c:	c18080e7          	jalr	-1000(ra) # 1170 <acquire>
    wakeup(&log);
    7560:	0001b517          	auipc	a0,0x1b
    7564:	8e050513          	add	a0,a0,-1824 # 21e40 <log>
    log.committing = 0;
    7568:	0001b797          	auipc	a5,0x1b
    756c:	8e07a823          	sw	zero,-1808(a5) # 21e58 <log+0x18>
    wakeup(&log);
    7570:	ffffd097          	auipc	ra,0xffffd
    7574:	be8080e7          	jalr	-1048(ra) # 4158 <wakeup>
    release(&log.lock);
    7578:	0001b517          	auipc	a0,0x1b
    757c:	8c850513          	add	a0,a0,-1848 # 21e40 <log>
}
    7580:	01812403          	lw	s0,24(sp)
    7584:	01c12083          	lw	ra,28(sp)
    7588:	01412483          	lw	s1,20(sp)
    758c:	01012903          	lw	s2,16(sp)
    7590:	00c12983          	lw	s3,12(sp)
    7594:	00812a03          	lw	s4,8(sp)
    7598:	00412a83          	lw	s5,4(sp)
    759c:	00012b03          	lw	s6,0(sp)
    75a0:	02010113          	add	sp,sp,32
    release(&log.lock);
    75a4:	ffffa317          	auipc	t1,0xffffa
    75a8:	d5830067          	jr	-680(t1) # 12fc <release>
    75ac:	0001ba97          	auipc	s5,0x1b
    75b0:	8b8a8a93          	add	s5,s5,-1864 # 21e64 <log+0x24>
  if (log.lh.n > 0) {
    75b4:	000a8b13          	mv	s6,s5
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    75b8:	00c4a583          	lw	a1,12(s1)
    75bc:	01c4a503          	lw	a0,28(s1)
  for (tail = 0; tail < log.lh.n; tail++) {
    75c0:	004b0b13          	add	s6,s6,4
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    75c4:	00b905b3          	add	a1,s2,a1
    75c8:	00158593          	add	a1,a1,1
    75cc:	ffffe097          	auipc	ra,0xffffe
    75d0:	eec080e7          	jalr	-276(ra) # 54b8 <bread>
    75d4:	00050993          	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    75d8:	ffcb2583          	lw	a1,-4(s6)
    75dc:	01c4a503          	lw	a0,28(s1)
  for (tail = 0; tail < log.lh.n; tail++) {
    75e0:	00190913          	add	s2,s2,1
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    75e4:	ffffe097          	auipc	ra,0xffffe
    75e8:	ed4080e7          	jalr	-300(ra) # 54b8 <bread>
    memmove(to->data, from->data, BSIZE);
    75ec:	03850593          	add	a1,a0,56
    75f0:	40000613          	li	a2,1024
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    75f4:	00050a13          	mv	s4,a0
    memmove(to->data, from->data, BSIZE);
    75f8:	03898513          	add	a0,s3,56
    75fc:	ffffa097          	auipc	ra,0xffffa
    7600:	208080e7          	jalr	520(ra) # 1804 <memmove>
    bwrite(to);  // write the log
    7604:	00098513          	mv	a0,s3
    7608:	ffffe097          	auipc	ra,0xffffe
    760c:	004080e7          	jalr	4(ra) # 560c <bwrite>
    brelse(from);
    7610:	000a0513          	mv	a0,s4
    7614:	ffffe097          	auipc	ra,0xffffe
    7618:	050080e7          	jalr	80(ra) # 5664 <brelse>
    brelse(to);
    761c:	00098513          	mv	a0,s3
    7620:	ffffe097          	auipc	ra,0xffffe
    7624:	044080e7          	jalr	68(ra) # 5664 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    7628:	0204a783          	lw	a5,32(s1)
    762c:	f8f946e3          	blt	s2,a5,75b8 <end_op+0xd8>
  struct buf *buf = bread(log.dev, log.start);
    7630:	00c4a583          	lw	a1,12(s1)
    7634:	01c4a503          	lw	a0,28(s1)
    7638:	ffffe097          	auipc	ra,0xffffe
    763c:	e80080e7          	jalr	-384(ra) # 54b8 <bread>
  hb->n = log.lh.n;
    7640:	0204a603          	lw	a2,32(s1)
  struct buf *buf = bread(log.dev, log.start);
    7644:	00050913          	mv	s2,a0
  hb->n = log.lh.n;
    7648:	02c52c23          	sw	a2,56(a0)
  for (i = 0; i < log.lh.n; i++) {
    764c:	02c05663          	blez	a2,7678 <end_op+0x198>
    7650:	00261613          	sll	a2,a2,0x2
    7654:	00050793          	mv	a5,a0
    7658:	00a60633          	add	a2,a2,a0
    765c:	0001b717          	auipc	a4,0x1b
    7660:	80870713          	add	a4,a4,-2040 # 21e64 <log+0x24>
    hb->block[i] = log.lh.block[i];
    7664:	00072683          	lw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    7668:	00478793          	add	a5,a5,4
    766c:	00470713          	add	a4,a4,4
    hb->block[i] = log.lh.block[i];
    7670:	02d7ac23          	sw	a3,56(a5)
  for (i = 0; i < log.lh.n; i++) {
    7674:	fec798e3          	bne	a5,a2,7664 <end_op+0x184>
  bwrite(buf);
    7678:	00090513          	mv	a0,s2
    767c:	ffffe097          	auipc	ra,0xffffe
    7680:	f90080e7          	jalr	-112(ra) # 560c <bwrite>
  brelse(buf);
    7684:	00090513          	mv	a0,s2
    7688:	ffffe097          	auipc	ra,0xffffe
    768c:	fdc080e7          	jalr	-36(ra) # 5664 <brelse>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    install_trans(); // Now install writes to home locations
    7690:	00000097          	auipc	ra,0x0
    7694:	ba8080e7          	jalr	-1112(ra) # 7238 <install_trans>
  struct buf *buf = bread(log.dev, log.start);
    7698:	00c4a583          	lw	a1,12(s1)
    769c:	01c4a503          	lw	a0,28(s1)
    log.lh.n = 0;
    76a0:	0001a797          	auipc	a5,0x1a
    76a4:	7c07a023          	sw	zero,1984(a5) # 21e60 <log+0x20>
  struct buf *buf = bread(log.dev, log.start);
    76a8:	ffffe097          	auipc	ra,0xffffe
    76ac:	e10080e7          	jalr	-496(ra) # 54b8 <bread>
  hb->n = log.lh.n;
    76b0:	0204a683          	lw	a3,32(s1)
  struct buf *buf = bread(log.dev, log.start);
    76b4:	00050493          	mv	s1,a0
  hb->n = log.lh.n;
    76b8:	02d52c23          	sw	a3,56(a0)
  for (i = 0; i < log.lh.n; i++) {
    76bc:	02d05263          	blez	a3,76e0 <end_op+0x200>
    76c0:	00269693          	sll	a3,a3,0x2
    76c4:	00050793          	mv	a5,a0
    76c8:	00a686b3          	add	a3,a3,a0
    hb->block[i] = log.lh.block[i];
    76cc:	000aa703          	lw	a4,0(s5)
  for (i = 0; i < log.lh.n; i++) {
    76d0:	00478793          	add	a5,a5,4
    76d4:	004a8a93          	add	s5,s5,4
    hb->block[i] = log.lh.block[i];
    76d8:	02e7ac23          	sw	a4,56(a5)
  for (i = 0; i < log.lh.n; i++) {
    76dc:	fef698e3          	bne	a3,a5,76cc <end_op+0x1ec>
  bwrite(buf);
    76e0:	00048513          	mv	a0,s1
    76e4:	ffffe097          	auipc	ra,0xffffe
    76e8:	f28080e7          	jalr	-216(ra) # 560c <bwrite>
  brelse(buf);
    76ec:	00048513          	mv	a0,s1
    76f0:	ffffe097          	auipc	ra,0xffffe
    76f4:	f74080e7          	jalr	-140(ra) # 5664 <brelse>
}
    76f8:	e59ff06f          	j	7550 <end_op+0x70>
    wakeup(&log);
    76fc:	ffffd097          	auipc	ra,0xffffd
    7700:	a5c080e7          	jalr	-1444(ra) # 4158 <wakeup>
  release(&log.lock);
    7704:	00048513          	mv	a0,s1
    7708:	e79ff06f          	j	7580 <end_op+0xa0>
    panic("log.committing");
    770c:	00004517          	auipc	a0,0x4
    7710:	fac50513          	add	a0,a0,-84 # b6b8 <main+0x588>
    7714:	ffff9097          	auipc	ra,0xffff9
    7718:	fc0080e7          	jalr	-64(ra) # 6d4 <panic>

0000771c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    771c:	ff010113          	add	sp,sp,-16
    7720:	00812423          	sw	s0,8(sp)
    7724:	00912223          	sw	s1,4(sp)
    7728:	00112623          	sw	ra,12(sp)
    772c:	01212023          	sw	s2,0(sp)
    7730:	01010413          	add	s0,sp,16
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    7734:	0001a497          	auipc	s1,0x1a
    7738:	70c48493          	add	s1,s1,1804 # 21e40 <log>
    773c:	0204a703          	lw	a4,32(s1)
    7740:	01d00793          	li	a5,29
    7744:	0ee7c263          	blt	a5,a4,7828 <log_write+0x10c>
    7748:	0104a783          	lw	a5,16(s1)
    774c:	fff78793          	add	a5,a5,-1
    7750:	0cf75c63          	bge	a4,a5,7828 <log_write+0x10c>
    panic("too big a transaction");
  if (log.outstanding < 1)
    7754:	0144a783          	lw	a5,20(s1)
    7758:	0ef05063          	blez	a5,7838 <log_write+0x11c>
    775c:	00050913          	mv	s2,a0
    panic("log_write outside of trans");

  acquire(&log.lock);
    7760:	00048513          	mv	a0,s1
    7764:	ffffa097          	auipc	ra,0xffffa
    7768:	a0c080e7          	jalr	-1524(ra) # 1170 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    776c:	0204a603          	lw	a2,32(s1)
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    7770:	00c92583          	lw	a1,12(s2)
  for (i = 0; i < log.lh.n; i++) {
    7774:	0ac05663          	blez	a2,7820 <log_write+0x104>
    7778:	0001a717          	auipc	a4,0x1a
    777c:	6ec70713          	add	a4,a4,1772 # 21e64 <log+0x24>
    7780:	00000793          	li	a5,0
    7784:	0100006f          	j	7794 <log_write+0x78>
    7788:	00178793          	add	a5,a5,1
    778c:	00470713          	add	a4,a4,4
    7790:	04f60263          	beq	a2,a5,77d4 <log_write+0xb8>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    7794:	00072683          	lw	a3,0(a4)
    7798:	feb698e3          	bne	a3,a1,7788 <log_write+0x6c>
      break;
  }
  log.lh.block[i] = b->blockno;
    779c:	00878713          	add	a4,a5,8
    77a0:	00271713          	sll	a4,a4,0x2
    77a4:	00e48733          	add	a4,s1,a4
    77a8:	00b72223          	sw	a1,4(a4)
  if (i == log.lh.n) {  // Add new block to log?
    77ac:	02f60c63          	beq	a2,a5,77e4 <log_write+0xc8>
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
}
    77b0:	00812403          	lw	s0,8(sp)
    77b4:	00c12083          	lw	ra,12(sp)
    77b8:	00412483          	lw	s1,4(sp)
    77bc:	00012903          	lw	s2,0(sp)
  release(&log.lock);
    77c0:	0001a517          	auipc	a0,0x1a
    77c4:	68050513          	add	a0,a0,1664 # 21e40 <log>
}
    77c8:	01010113          	add	sp,sp,16
  release(&log.lock);
    77cc:	ffffa317          	auipc	t1,0xffffa
    77d0:	b3030067          	jr	-1232(t1) # 12fc <release>
  log.lh.block[i] = b->blockno;
    77d4:	00860793          	add	a5,a2,8
    77d8:	00279793          	sll	a5,a5,0x2
    77dc:	00f487b3          	add	a5,s1,a5
    77e0:	00b7a223          	sw	a1,4(a5)
    bpin(b);
    77e4:	00090513          	mv	a0,s2
    77e8:	ffffe097          	auipc	ra,0xffffe
    77ec:	f40080e7          	jalr	-192(ra) # 5728 <bpin>
    log.lh.n++;
    77f0:	0204a783          	lw	a5,32(s1)
}
    77f4:	00812403          	lw	s0,8(sp)
    77f8:	00c12083          	lw	ra,12(sp)
    log.lh.n++;
    77fc:	00178793          	add	a5,a5,1
}
    7800:	00012903          	lw	s2,0(sp)
    log.lh.n++;
    7804:	02f4a023          	sw	a5,32(s1)
}
    7808:	00412483          	lw	s1,4(sp)
  release(&log.lock);
    780c:	0001a517          	auipc	a0,0x1a
    7810:	63450513          	add	a0,a0,1588 # 21e40 <log>
}
    7814:	01010113          	add	sp,sp,16
  release(&log.lock);
    7818:	ffffa317          	auipc	t1,0xffffa
    781c:	ae430067          	jr	-1308(t1) # 12fc <release>
  for (i = 0; i < log.lh.n; i++) {
    7820:	00000793          	li	a5,0
    7824:	f79ff06f          	j	779c <log_write+0x80>
    panic("too big a transaction");
    7828:	00004517          	auipc	a0,0x4
    782c:	ea050513          	add	a0,a0,-352 # b6c8 <main+0x598>
    7830:	ffff9097          	auipc	ra,0xffff9
    7834:	ea4080e7          	jalr	-348(ra) # 6d4 <panic>
    panic("log_write outside of trans");
    7838:	00004517          	auipc	a0,0x4
    783c:	ea850513          	add	a0,a0,-344 # b6e0 <main+0x5b0>
    7840:	ffff9097          	auipc	ra,0xffff9
    7844:	e94080e7          	jalr	-364(ra) # 6d4 <panic>

00007848 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    7848:	ff010113          	add	sp,sp,-16
    784c:	00812423          	sw	s0,8(sp)
    7850:	00912223          	sw	s1,4(sp)
    7854:	01212023          	sw	s2,0(sp)
    7858:	00112623          	sw	ra,12(sp)
    785c:	01010413          	add	s0,sp,16
    7860:	00050493          	mv	s1,a0
    7864:	00058913          	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    7868:	00450513          	add	a0,a0,4
    786c:	00004597          	auipc	a1,0x4
    7870:	e9058593          	add	a1,a1,-368 # b6fc <main+0x5cc>
    7874:	ffffa097          	auipc	ra,0xffffa
    7878:	8d8080e7          	jalr	-1832(ra) # 114c <initlock>
  lk->name = name;
  lk->locked = 0;
  lk->pid = 0;
}
    787c:	00c12083          	lw	ra,12(sp)
    7880:	00812403          	lw	s0,8(sp)
  lk->name = name;
    7884:	0124a823          	sw	s2,16(s1)
  lk->locked = 0;
    7888:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    788c:	0004aa23          	sw	zero,20(s1)
}
    7890:	00012903          	lw	s2,0(sp)
    7894:	00412483          	lw	s1,4(sp)
    7898:	01010113          	add	sp,sp,16
    789c:	00008067          	ret

000078a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    78a0:	ff010113          	add	sp,sp,-16
    78a4:	00812423          	sw	s0,8(sp)
    78a8:	00912223          	sw	s1,4(sp)
    78ac:	01212023          	sw	s2,0(sp)
    78b0:	00112623          	sw	ra,12(sp)
    78b4:	01010413          	add	s0,sp,16
  acquire(&lk->lk);
    78b8:	00450913          	add	s2,a0,4
{
    78bc:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    78c0:	00090513          	mv	a0,s2
    78c4:	ffffa097          	auipc	ra,0xffffa
    78c8:	8ac080e7          	jalr	-1876(ra) # 1170 <acquire>
  while (lk->locked) {
    78cc:	0004a783          	lw	a5,0(s1)
    78d0:	00078e63          	beqz	a5,78ec <acquiresleep+0x4c>
    sleep(lk, &lk->lk);
    78d4:	00090593          	mv	a1,s2
    78d8:	00048513          	mv	a0,s1
    78dc:	ffffc097          	auipc	ra,0xffffc
    78e0:	790080e7          	jalr	1936(ra) # 406c <sleep>
  while (lk->locked) {
    78e4:	0004a783          	lw	a5,0(s1)
    78e8:	fe0796e3          	bnez	a5,78d4 <acquiresleep+0x34>
  }
  lk->locked = 1;
    78ec:	00100793          	li	a5,1
    78f0:	00f4a023          	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    78f4:	ffffc097          	auipc	ra,0xffffc
    78f8:	b30080e7          	jalr	-1232(ra) # 3424 <myproc>
    78fc:	02052783          	lw	a5,32(a0)
  release(&lk->lk);
}
    7900:	00812403          	lw	s0,8(sp)
    7904:	00c12083          	lw	ra,12(sp)
  lk->pid = myproc()->pid;
    7908:	00f4aa23          	sw	a5,20(s1)
  release(&lk->lk);
    790c:	00090513          	mv	a0,s2
}
    7910:	00412483          	lw	s1,4(sp)
    7914:	00012903          	lw	s2,0(sp)
    7918:	01010113          	add	sp,sp,16
  release(&lk->lk);
    791c:	ffffa317          	auipc	t1,0xffffa
    7920:	9e030067          	jr	-1568(t1) # 12fc <release>

00007924 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    7924:	ff010113          	add	sp,sp,-16
    7928:	00112623          	sw	ra,12(sp)
    792c:	00812423          	sw	s0,8(sp)
    7930:	00912223          	sw	s1,4(sp)
    7934:	01212023          	sw	s2,0(sp)
    7938:	01010413          	add	s0,sp,16
  acquire(&lk->lk);
    793c:	00450913          	add	s2,a0,4
{
    7940:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    7944:	00090513          	mv	a0,s2
    7948:	ffffa097          	auipc	ra,0xffffa
    794c:	828080e7          	jalr	-2008(ra) # 1170 <acquire>
  lk->locked = 0;
  lk->pid = 0;
  wakeup(lk);
    7950:	00048513          	mv	a0,s1
  lk->locked = 0;
    7954:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    7958:	0004aa23          	sw	zero,20(s1)
  wakeup(lk);
    795c:	ffffc097          	auipc	ra,0xffffc
    7960:	7fc080e7          	jalr	2044(ra) # 4158 <wakeup>
  release(&lk->lk);
}
    7964:	00812403          	lw	s0,8(sp)
    7968:	00c12083          	lw	ra,12(sp)
    796c:	00412483          	lw	s1,4(sp)
  release(&lk->lk);
    7970:	00090513          	mv	a0,s2
}
    7974:	00012903          	lw	s2,0(sp)
    7978:	01010113          	add	sp,sp,16
  release(&lk->lk);
    797c:	ffffa317          	auipc	t1,0xffffa
    7980:	98030067          	jr	-1664(t1) # 12fc <release>

00007984 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    7984:	fe010113          	add	sp,sp,-32
    7988:	00812c23          	sw	s0,24(sp)
    798c:	00912a23          	sw	s1,20(sp)
    7990:	01212823          	sw	s2,16(sp)
    7994:	00112e23          	sw	ra,28(sp)
    7998:	01312623          	sw	s3,12(sp)
    799c:	02010413          	add	s0,sp,32
  int r;
  
  acquire(&lk->lk);
    79a0:	00450913          	add	s2,a0,4
{
    79a4:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    79a8:	00090513          	mv	a0,s2
    79ac:	ffff9097          	auipc	ra,0xffff9
    79b0:	7c4080e7          	jalr	1988(ra) # 1170 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    79b4:	0004a783          	lw	a5,0(s1)
    79b8:	02079a63          	bnez	a5,79ec <holdingsleep+0x68>
    79bc:	00000493          	li	s1,0
  release(&lk->lk);
    79c0:	00090513          	mv	a0,s2
    79c4:	ffffa097          	auipc	ra,0xffffa
    79c8:	938080e7          	jalr	-1736(ra) # 12fc <release>
  return r;
}
    79cc:	01c12083          	lw	ra,28(sp)
    79d0:	01812403          	lw	s0,24(sp)
    79d4:	01012903          	lw	s2,16(sp)
    79d8:	00c12983          	lw	s3,12(sp)
    79dc:	00048513          	mv	a0,s1
    79e0:	01412483          	lw	s1,20(sp)
    79e4:	02010113          	add	sp,sp,32
    79e8:	00008067          	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    79ec:	0144a983          	lw	s3,20(s1)
    79f0:	ffffc097          	auipc	ra,0xffffc
    79f4:	a34080e7          	jalr	-1484(ra) # 3424 <myproc>
    79f8:	02052483          	lw	s1,32(a0)
    79fc:	413484b3          	sub	s1,s1,s3
    7a00:	0014b493          	seqz	s1,s1
    7a04:	fbdff06f          	j	79c0 <holdingsleep+0x3c>

00007a08 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    7a08:	ff010113          	add	sp,sp,-16
    7a0c:	00812623          	sw	s0,12(sp)
    7a10:	01010413          	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
}
    7a14:	00c12403          	lw	s0,12(sp)
  initlock(&ftable.lock, "ftable");
    7a18:	00004597          	auipc	a1,0x4
    7a1c:	cf058593          	add	a1,a1,-784 # b708 <main+0x5d8>
    7a20:	0001a517          	auipc	a0,0x1a
    7a24:	50c50513          	add	a0,a0,1292 # 21f2c <ftable>
}
    7a28:	01010113          	add	sp,sp,16
  initlock(&ftable.lock, "ftable");
    7a2c:	ffff9317          	auipc	t1,0xffff9
    7a30:	72030067          	jr	1824(t1) # 114c <initlock>

00007a34 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    7a34:	ff010113          	add	sp,sp,-16
    7a38:	00812423          	sw	s0,8(sp)
    7a3c:	00912223          	sw	s1,4(sp)
    7a40:	00112623          	sw	ra,12(sp)
    7a44:	01010413          	add	s0,sp,16
  struct file *f;

  acquire(&ftable.lock);
    7a48:	0001a517          	auipc	a0,0x1a
    7a4c:	4e450513          	add	a0,a0,1252 # 21f2c <ftable>
    7a50:	ffff9097          	auipc	ra,0xffff9
    7a54:	720080e7          	jalr	1824(ra) # 1170 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    7a58:	0001a497          	auipc	s1,0x1a
    7a5c:	4e048493          	add	s1,s1,1248 # 21f38 <ftable+0xc>
    7a60:	0001b717          	auipc	a4,0x1b
    7a64:	fc870713          	add	a4,a4,-56 # 22a28 <ftable+0xafc>
    7a68:	00c0006f          	j	7a74 <filealloc+0x40>
    7a6c:	01c48493          	add	s1,s1,28
    7a70:	02e48e63          	beq	s1,a4,7aac <filealloc+0x78>
    if(f->ref == 0){
    7a74:	0044a783          	lw	a5,4(s1)
    7a78:	fe079ae3          	bnez	a5,7a6c <filealloc+0x38>
      f->ref = 1;
    7a7c:	00100793          	li	a5,1
    7a80:	00f4a223          	sw	a5,4(s1)
      release(&ftable.lock);
    7a84:	0001a517          	auipc	a0,0x1a
    7a88:	4a850513          	add	a0,a0,1192 # 21f2c <ftable>
    7a8c:	ffffa097          	auipc	ra,0xffffa
    7a90:	870080e7          	jalr	-1936(ra) # 12fc <release>
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}
    7a94:	00c12083          	lw	ra,12(sp)
    7a98:	00812403          	lw	s0,8(sp)
    7a9c:	00048513          	mv	a0,s1
    7aa0:	00412483          	lw	s1,4(sp)
    7aa4:	01010113          	add	sp,sp,16
    7aa8:	00008067          	ret
  release(&ftable.lock);
    7aac:	0001a517          	auipc	a0,0x1a
    7ab0:	48050513          	add	a0,a0,1152 # 21f2c <ftable>
    7ab4:	ffffa097          	auipc	ra,0xffffa
    7ab8:	848080e7          	jalr	-1976(ra) # 12fc <release>
}
    7abc:	00c12083          	lw	ra,12(sp)
    7ac0:	00812403          	lw	s0,8(sp)
  return 0;
    7ac4:	00000493          	li	s1,0
}
    7ac8:	00048513          	mv	a0,s1
    7acc:	00412483          	lw	s1,4(sp)
    7ad0:	01010113          	add	sp,sp,16
    7ad4:	00008067          	ret

00007ad8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    7ad8:	ff010113          	add	sp,sp,-16
    7adc:	00812423          	sw	s0,8(sp)
    7ae0:	00912223          	sw	s1,4(sp)
    7ae4:	00112623          	sw	ra,12(sp)
    7ae8:	01010413          	add	s0,sp,16
    7aec:	00050493          	mv	s1,a0
  acquire(&ftable.lock);
    7af0:	0001a517          	auipc	a0,0x1a
    7af4:	43c50513          	add	a0,a0,1084 # 21f2c <ftable>
    7af8:	ffff9097          	auipc	ra,0xffff9
    7afc:	678080e7          	jalr	1656(ra) # 1170 <acquire>
  if(f->ref < 1)
    7b00:	0044a783          	lw	a5,4(s1)
    7b04:	02f05a63          	blez	a5,7b38 <filedup+0x60>
    panic("filedup");
  f->ref++;
    7b08:	00178793          	add	a5,a5,1
    7b0c:	00f4a223          	sw	a5,4(s1)
  release(&ftable.lock);
    7b10:	0001a517          	auipc	a0,0x1a
    7b14:	41c50513          	add	a0,a0,1052 # 21f2c <ftable>
    7b18:	ffff9097          	auipc	ra,0xffff9
    7b1c:	7e4080e7          	jalr	2020(ra) # 12fc <release>
  return f;
}
    7b20:	00c12083          	lw	ra,12(sp)
    7b24:	00812403          	lw	s0,8(sp)
    7b28:	00048513          	mv	a0,s1
    7b2c:	00412483          	lw	s1,4(sp)
    7b30:	01010113          	add	sp,sp,16
    7b34:	00008067          	ret
    panic("filedup");
    7b38:	00004517          	auipc	a0,0x4
    7b3c:	bd850513          	add	a0,a0,-1064 # b710 <main+0x5e0>
    7b40:	ffff9097          	auipc	ra,0xffff9
    7b44:	b94080e7          	jalr	-1132(ra) # 6d4 <panic>

00007b48 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    7b48:	fe010113          	add	sp,sp,-32
    7b4c:	00812c23          	sw	s0,24(sp)
    7b50:	00912a23          	sw	s1,20(sp)
    7b54:	00112e23          	sw	ra,28(sp)
    7b58:	01212823          	sw	s2,16(sp)
    7b5c:	01312623          	sw	s3,12(sp)
    7b60:	01412423          	sw	s4,8(sp)
    7b64:	02010413          	add	s0,sp,32
    7b68:	00050493          	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    7b6c:	0001a517          	auipc	a0,0x1a
    7b70:	3c050513          	add	a0,a0,960 # 21f2c <ftable>
    7b74:	ffff9097          	auipc	ra,0xffff9
    7b78:	5fc080e7          	jalr	1532(ra) # 1170 <acquire>
  if(f->ref < 1)
    7b7c:	0044a783          	lw	a5,4(s1)
    7b80:	0ef05a63          	blez	a5,7c74 <fileclose+0x12c>
    panic("fileclose");
  if(--f->ref > 0){
    7b84:	fff78793          	add	a5,a5,-1
    7b88:	00f4a223          	sw	a5,4(s1)
    7b8c:	04079c63          	bnez	a5,7be4 <fileclose+0x9c>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    7b90:	0004a903          	lw	s2,0(s1)
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);
    7b94:	0001a517          	auipc	a0,0x1a
    7b98:	39850513          	add	a0,a0,920 # 21f2c <ftable>
  f->type = FD_NONE;
    7b9c:	0004a023          	sw	zero,0(s1)
  ff = *f;
    7ba0:	0094ca03          	lbu	s4,9(s1)
    7ba4:	00c4a983          	lw	s3,12(s1)
    7ba8:	0104a483          	lw	s1,16(s1)
  release(&ftable.lock);
    7bac:	ffff9097          	auipc	ra,0xffff9
    7bb0:	750080e7          	jalr	1872(ra) # 12fc <release>

  if(ff.type == FD_PIPE){
    7bb4:	00100793          	li	a5,1
    7bb8:	08f90863          	beq	s2,a5,7c48 <fileclose+0x100>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    7bbc:	ffe90913          	add	s2,s2,-2
    7bc0:	0527f863          	bgeu	a5,s2,7c10 <fileclose+0xc8>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    7bc4:	01c12083          	lw	ra,28(sp)
    7bc8:	01812403          	lw	s0,24(sp)
    7bcc:	01412483          	lw	s1,20(sp)
    7bd0:	01012903          	lw	s2,16(sp)
    7bd4:	00c12983          	lw	s3,12(sp)
    7bd8:	00812a03          	lw	s4,8(sp)
    7bdc:	02010113          	add	sp,sp,32
    7be0:	00008067          	ret
    7be4:	01812403          	lw	s0,24(sp)
    7be8:	01c12083          	lw	ra,28(sp)
    7bec:	01412483          	lw	s1,20(sp)
    7bf0:	01012903          	lw	s2,16(sp)
    7bf4:	00c12983          	lw	s3,12(sp)
    7bf8:	00812a03          	lw	s4,8(sp)
    release(&ftable.lock);
    7bfc:	0001a517          	auipc	a0,0x1a
    7c00:	33050513          	add	a0,a0,816 # 21f2c <ftable>
}
    7c04:	02010113          	add	sp,sp,32
    release(&ftable.lock);
    7c08:	ffff9317          	auipc	t1,0xffff9
    7c0c:	6f430067          	jr	1780(t1) # 12fc <release>
    begin_op();
    7c10:	00000097          	auipc	ra,0x0
    7c14:	834080e7          	jalr	-1996(ra) # 7444 <begin_op>
    iput(ff.ip);
    7c18:	00048513          	mv	a0,s1
    7c1c:	ffffe097          	auipc	ra,0xffffe
    7c20:	468080e7          	jalr	1128(ra) # 6084 <iput>
}
    7c24:	01812403          	lw	s0,24(sp)
    7c28:	01c12083          	lw	ra,28(sp)
    7c2c:	01412483          	lw	s1,20(sp)
    7c30:	01012903          	lw	s2,16(sp)
    7c34:	00c12983          	lw	s3,12(sp)
    7c38:	00812a03          	lw	s4,8(sp)
    7c3c:	02010113          	add	sp,sp,32
    end_op();
    7c40:	00000317          	auipc	t1,0x0
    7c44:	8a030067          	jr	-1888(t1) # 74e0 <end_op>
}
    7c48:	01812403          	lw	s0,24(sp)
    7c4c:	01c12083          	lw	ra,28(sp)
    7c50:	01412483          	lw	s1,20(sp)
    7c54:	01012903          	lw	s2,16(sp)
    pipeclose(ff.pipe, ff.writable);
    7c58:	000a0593          	mv	a1,s4
    7c5c:	00098513          	mv	a0,s3
}
    7c60:	00812a03          	lw	s4,8(sp)
    7c64:	00c12983          	lw	s3,12(sp)
    7c68:	02010113          	add	sp,sp,32
    pipeclose(ff.pipe, ff.writable);
    7c6c:	00000317          	auipc	t1,0x0
    7c70:	4e430067          	jr	1252(t1) # 8150 <pipeclose>
    panic("fileclose");
    7c74:	00004517          	auipc	a0,0x4
    7c78:	aa450513          	add	a0,a0,-1372 # b718 <main+0x5e8>
    7c7c:	ffff9097          	auipc	ra,0xffff9
    7c80:	a58080e7          	jalr	-1448(ra) # 6d4 <panic>

00007c84 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint32 addr)
{
    7c84:	fc010113          	add	sp,sp,-64
    7c88:	02812c23          	sw	s0,56(sp)
    7c8c:	02912a23          	sw	s1,52(sp)
    7c90:	03212823          	sw	s2,48(sp)
    7c94:	02112e23          	sw	ra,60(sp)
    7c98:	03312623          	sw	s3,44(sp)
    7c9c:	04010413          	add	s0,sp,64
    7ca0:	00050493          	mv	s1,a0
    7ca4:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    7ca8:	ffffb097          	auipc	ra,0xffffb
    7cac:	77c080e7          	jalr	1916(ra) # 3424 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    7cb0:	0004a783          	lw	a5,0(s1)
    7cb4:	00100713          	li	a4,1
    7cb8:	ffe78793          	add	a5,a5,-2
    7cbc:	06f76463          	bltu	a4,a5,7d24 <filestat+0xa0>
    ilock(f->ip);
    7cc0:	00050993          	mv	s3,a0
    7cc4:	0104a503          	lw	a0,16(s1)
    7cc8:	ffffe097          	auipc	ra,0xffffe
    7ccc:	25c080e7          	jalr	604(ra) # 5f24 <ilock>
    stati(f->ip, &st);
    7cd0:	0104a503          	lw	a0,16(s1)
    7cd4:	fc840593          	add	a1,s0,-56
    7cd8:	fffff097          	auipc	ra,0xfffff
    7cdc:	be0080e7          	jalr	-1056(ra) # 68b8 <stati>
    iunlock(f->ip);
    7ce0:	0104a503          	lw	a0,16(s1)
    7ce4:	ffffe097          	auipc	ra,0xffffe
    7ce8:	334080e7          	jalr	820(ra) # 6018 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    7cec:	02c9a503          	lw	a0,44(s3)
    7cf0:	01800693          	li	a3,24
    7cf4:	fc840613          	add	a2,s0,-56
    7cf8:	00090593          	mv	a1,s2
    7cfc:	ffffb097          	auipc	ra,0xffffb
    7d00:	04c080e7          	jalr	76(ra) # 2d48 <copyout>
    7d04:	41f55513          	sra	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    7d08:	03c12083          	lw	ra,60(sp)
    7d0c:	03812403          	lw	s0,56(sp)
    7d10:	03412483          	lw	s1,52(sp)
    7d14:	03012903          	lw	s2,48(sp)
    7d18:	02c12983          	lw	s3,44(sp)
    7d1c:	04010113          	add	sp,sp,64
    7d20:	00008067          	ret
      return -1;
    7d24:	fff00513          	li	a0,-1
    7d28:	fe1ff06f          	j	7d08 <filestat+0x84>

00007d2c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint32 addr, int n)
{
    7d2c:	fe010113          	add	sp,sp,-32
    7d30:	00812c23          	sw	s0,24(sp)
    7d34:	00112e23          	sw	ra,28(sp)
    7d38:	00912a23          	sw	s1,20(sp)
    7d3c:	01212823          	sw	s2,16(sp)
    7d40:	01312623          	sw	s3,12(sp)
    7d44:	02010413          	add	s0,sp,32
  int r = 0;

  if(f->readable == 0)
    7d48:	00854783          	lbu	a5,8(a0)
    7d4c:	10078263          	beqz	a5,7e50 <fileread+0x124>
    return -1;

  if(f->type == FD_PIPE){
    7d50:	00052783          	lw	a5,0(a0)
    7d54:	00100713          	li	a4,1
    7d58:	00050493          	mv	s1,a0
    7d5c:	0ce78863          	beq	a5,a4,7e2c <fileread+0x100>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    7d60:	00300713          	li	a4,3
    7d64:	06e78e63          	beq	a5,a4,7de0 <fileread+0xb4>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    7d68:	00200713          	li	a4,2
    7d6c:	0ee79663          	bne	a5,a4,7e58 <fileread+0x12c>
    ilock(f->ip);
    7d70:	01052503          	lw	a0,16(a0)
    7d74:	00058913          	mv	s2,a1
    7d78:	00060993          	mv	s3,a2
    7d7c:	ffffe097          	auipc	ra,0xffffe
    7d80:	1a8080e7          	jalr	424(ra) # 5f24 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    7d84:	0144a683          	lw	a3,20(s1)
    7d88:	0104a503          	lw	a0,16(s1)
    7d8c:	00090613          	mv	a2,s2
    7d90:	00098713          	mv	a4,s3
    7d94:	00100593          	li	a1,1
    7d98:	fffff097          	auipc	ra,0xfffff
    7d9c:	b68080e7          	jalr	-1176(ra) # 6900 <readi>
    7da0:	00050913          	mv	s2,a0
    7da4:	00a05863          	blez	a0,7db4 <fileread+0x88>
      f->off += r;
    7da8:	0144a783          	lw	a5,20(s1)
    7dac:	00a787b3          	add	a5,a5,a0
    7db0:	00f4aa23          	sw	a5,20(s1)
    iunlock(f->ip);
    7db4:	0104a503          	lw	a0,16(s1)
    7db8:	ffffe097          	auipc	ra,0xffffe
    7dbc:	260080e7          	jalr	608(ra) # 6018 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    7dc0:	01c12083          	lw	ra,28(sp)
    7dc4:	01812403          	lw	s0,24(sp)
    7dc8:	01412483          	lw	s1,20(sp)
    7dcc:	00c12983          	lw	s3,12(sp)
    7dd0:	00090513          	mv	a0,s2
    7dd4:	01012903          	lw	s2,16(sp)
    7dd8:	02010113          	add	sp,sp,32
    7ddc:	00008067          	ret
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    7de0:	01851783          	lh	a5,24(a0)
    7de4:	00900713          	li	a4,9
    7de8:	01079693          	sll	a3,a5,0x10
    7dec:	0106d693          	srl	a3,a3,0x10
    7df0:	06d76063          	bltu	a4,a3,7e50 <fileread+0x124>
    7df4:	00379793          	sll	a5,a5,0x3
    7df8:	0001a717          	auipc	a4,0x1a
    7dfc:	0e470713          	add	a4,a4,228 # 21edc <devsw>
    7e00:	00f707b3          	add	a5,a4,a5
    7e04:	0007a783          	lw	a5,0(a5)
    7e08:	04078463          	beqz	a5,7e50 <fileread+0x124>
}
    7e0c:	01812403          	lw	s0,24(sp)
    7e10:	01c12083          	lw	ra,28(sp)
    7e14:	01412483          	lw	s1,20(sp)
    7e18:	01012903          	lw	s2,16(sp)
    7e1c:	00c12983          	lw	s3,12(sp)
    r = devsw[f->major].read(1, addr, n);
    7e20:	00100513          	li	a0,1
}
    7e24:	02010113          	add	sp,sp,32
    r = devsw[f->major].read(1, addr, n);
    7e28:	00078067          	jr	a5
}
    7e2c:	01812403          	lw	s0,24(sp)
    7e30:	01c12083          	lw	ra,28(sp)
    7e34:	01412483          	lw	s1,20(sp)
    7e38:	01012903          	lw	s2,16(sp)
    7e3c:	00c12983          	lw	s3,12(sp)
    r = piperead(f->pipe, addr, n);
    7e40:	00c52503          	lw	a0,12(a0)
}
    7e44:	02010113          	add	sp,sp,32
    r = piperead(f->pipe, addr, n);
    7e48:	00000317          	auipc	t1,0x0
    7e4c:	50c30067          	jr	1292(t1) # 8354 <piperead>
    return -1;
    7e50:	fff00913          	li	s2,-1
    7e54:	f6dff06f          	j	7dc0 <fileread+0x94>
    panic("fileread");
    7e58:	00004517          	auipc	a0,0x4
    7e5c:	8cc50513          	add	a0,a0,-1844 # b724 <main+0x5f4>
    7e60:	ffff9097          	auipc	ra,0xffff9
    7e64:	874080e7          	jalr	-1932(ra) # 6d4 <panic>

00007e68 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint32 addr, int n)
{
    7e68:	fd010113          	add	sp,sp,-48
    7e6c:	02812423          	sw	s0,40(sp)
    7e70:	02112623          	sw	ra,44(sp)
    7e74:	02912223          	sw	s1,36(sp)
    7e78:	03212023          	sw	s2,32(sp)
    7e7c:	01312e23          	sw	s3,28(sp)
    7e80:	01412c23          	sw	s4,24(sp)
    7e84:	01512a23          	sw	s5,20(sp)
    7e88:	01612823          	sw	s6,16(sp)
    7e8c:	01712623          	sw	s7,12(sp)
    7e90:	03010413          	add	s0,sp,48
  int r, ret = 0;

  if(f->writable == 0)
    7e94:	00954783          	lbu	a5,9(a0)
    7e98:	1a078063          	beqz	a5,8038 <filewrite+0x1d0>
    return -1;

  if(f->type == FD_PIPE){
    7e9c:	00052783          	lw	a5,0(a0)
    7ea0:	00100713          	li	a4,1
    7ea4:	00050493          	mv	s1,a0
    7ea8:	14e78e63          	beq	a5,a4,8004 <filewrite+0x19c>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    7eac:	00300713          	li	a4,3
    7eb0:	0ee78c63          	beq	a5,a4,7fa8 <filewrite+0x140>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    7eb4:	00200713          	li	a4,2
    7eb8:	18e79463          	bne	a5,a4,8040 <filewrite+0x1d8>
    7ebc:	00060a93          	mv	s5,a2
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    7ec0:	0ac05863          	blez	a2,7f70 <filewrite+0x108>
      int n1 = n - i;
      if(n1 > max)
    7ec4:	00001b37          	lui	s6,0x1
    7ec8:	00058b93          	mv	s7,a1
    int i = 0;
    7ecc:	00000993          	li	s3,0
      if(n1 > max)
    7ed0:	c00b0b13          	add	s6,s6,-1024 # c00 <printf+0x4d0>
    7ed4:	0300006f          	j	7f04 <filewrite+0x9c>
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;
    7ed8:	0144a783          	lw	a5,20(s1)
      iunlock(f->ip);
    7edc:	0104a503          	lw	a0,16(s1)
        f->off += r;
    7ee0:	012787b3          	add	a5,a5,s2
    7ee4:	00f4aa23          	sw	a5,20(s1)
      iunlock(f->ip);
    7ee8:	ffffe097          	auipc	ra,0xffffe
    7eec:	130080e7          	jalr	304(ra) # 6018 <iunlock>
      end_op();
    7ef0:	fffff097          	auipc	ra,0xfffff
    7ef4:	5f0080e7          	jalr	1520(ra) # 74e0 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    7ef8:	072a1463          	bne	s4,s2,7f60 <filewrite+0xf8>
        panic("short filewrite");
      i += r;
    7efc:	014989b3          	add	s3,s3,s4
    while(i < n){
    7f00:	0759da63          	bge	s3,s5,7f74 <filewrite+0x10c>
      int n1 = n - i;
    7f04:	413a8a33          	sub	s4,s5,s3
      if(n1 > max)
    7f08:	014b5463          	bge	s6,s4,7f10 <filewrite+0xa8>
    7f0c:	000b0a13          	mv	s4,s6
      begin_op();
    7f10:	fffff097          	auipc	ra,0xfffff
    7f14:	534080e7          	jalr	1332(ra) # 7444 <begin_op>
      ilock(f->ip);
    7f18:	0104a503          	lw	a0,16(s1)
    7f1c:	ffffe097          	auipc	ra,0xffffe
    7f20:	008080e7          	jalr	8(ra) # 5f24 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    7f24:	0144a683          	lw	a3,20(s1)
    7f28:	0104a503          	lw	a0,16(s1)
    7f2c:	000a0713          	mv	a4,s4
    7f30:	01798633          	add	a2,s3,s7
    7f34:	00100593          	li	a1,1
    7f38:	fffff097          	auipc	ra,0xfffff
    7f3c:	bd0080e7          	jalr	-1072(ra) # 6b08 <writei>
    7f40:	00050913          	mv	s2,a0
    7f44:	f8a04ae3          	bgtz	a0,7ed8 <filewrite+0x70>
      iunlock(f->ip);
    7f48:	0104a503          	lw	a0,16(s1)
    7f4c:	ffffe097          	auipc	ra,0xffffe
    7f50:	0cc080e7          	jalr	204(ra) # 6018 <iunlock>
      end_op();
    7f54:	fffff097          	auipc	ra,0xfffff
    7f58:	58c080e7          	jalr	1420(ra) # 74e0 <end_op>
      if(r < 0)
    7f5c:	00091c63          	bnez	s2,7f74 <filewrite+0x10c>
        panic("short filewrite");
    7f60:	00003517          	auipc	a0,0x3
    7f64:	7d050513          	add	a0,a0,2000 # b730 <main+0x600>
    7f68:	ffff8097          	auipc	ra,0xffff8
    7f6c:	76c080e7          	jalr	1900(ra) # 6d4 <panic>
    int i = 0;
    7f70:	00000993          	li	s3,0
    }
    ret = (i == n ? n : -1);
    7f74:	0d3a9263          	bne	s5,s3,8038 <filewrite+0x1d0>
  } else {
    panic("filewrite");
  }

  return ret;
}
    7f78:	02c12083          	lw	ra,44(sp)
    7f7c:	02812403          	lw	s0,40(sp)
    7f80:	02412483          	lw	s1,36(sp)
    7f84:	02012903          	lw	s2,32(sp)
    7f88:	01812a03          	lw	s4,24(sp)
    7f8c:	01412a83          	lw	s5,20(sp)
    7f90:	01012b03          	lw	s6,16(sp)
    7f94:	00c12b83          	lw	s7,12(sp)
    7f98:	00098513          	mv	a0,s3
    7f9c:	01c12983          	lw	s3,28(sp)
    7fa0:	03010113          	add	sp,sp,48
    7fa4:	00008067          	ret
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    7fa8:	01851783          	lh	a5,24(a0)
    7fac:	00900713          	li	a4,9
    7fb0:	01079693          	sll	a3,a5,0x10
    7fb4:	0106d693          	srl	a3,a3,0x10
    7fb8:	08d76063          	bltu	a4,a3,8038 <filewrite+0x1d0>
    7fbc:	00379793          	sll	a5,a5,0x3
    7fc0:	0001a717          	auipc	a4,0x1a
    7fc4:	f1c70713          	add	a4,a4,-228 # 21edc <devsw>
    7fc8:	00f707b3          	add	a5,a4,a5
    7fcc:	0047a783          	lw	a5,4(a5)
    7fd0:	06078463          	beqz	a5,8038 <filewrite+0x1d0>
}
    7fd4:	02812403          	lw	s0,40(sp)
    7fd8:	02c12083          	lw	ra,44(sp)
    7fdc:	02412483          	lw	s1,36(sp)
    7fe0:	02012903          	lw	s2,32(sp)
    7fe4:	01c12983          	lw	s3,28(sp)
    7fe8:	01812a03          	lw	s4,24(sp)
    7fec:	01412a83          	lw	s5,20(sp)
    7ff0:	01012b03          	lw	s6,16(sp)
    7ff4:	00c12b83          	lw	s7,12(sp)
    ret = devsw[f->major].write(1, addr, n);
    7ff8:	00100513          	li	a0,1
}
    7ffc:	03010113          	add	sp,sp,48
    ret = devsw[f->major].write(1, addr, n);
    8000:	00078067          	jr	a5
}
    8004:	02812403          	lw	s0,40(sp)
    8008:	02c12083          	lw	ra,44(sp)
    800c:	02412483          	lw	s1,36(sp)
    8010:	02012903          	lw	s2,32(sp)
    8014:	01c12983          	lw	s3,28(sp)
    8018:	01812a03          	lw	s4,24(sp)
    801c:	01412a83          	lw	s5,20(sp)
    8020:	01012b03          	lw	s6,16(sp)
    8024:	00c12b83          	lw	s7,12(sp)
    ret = pipewrite(f->pipe, addr, n);
    8028:	00c52503          	lw	a0,12(a0)
}
    802c:	03010113          	add	sp,sp,48
    ret = pipewrite(f->pipe, addr, n);
    8030:	00000317          	auipc	t1,0x0
    8034:	1c830067          	jr	456(t1) # 81f8 <pipewrite>
    return -1;
    8038:	fff00993          	li	s3,-1
    803c:	f3dff06f          	j	7f78 <filewrite+0x110>
    panic("filewrite");
    8040:	00003517          	auipc	a0,0x3
    8044:	70050513          	add	a0,a0,1792 # b740 <main+0x610>
    8048:	ffff8097          	auipc	ra,0xffff8
    804c:	68c080e7          	jalr	1676(ra) # 6d4 <panic>

00008050 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8050:	fe010113          	add	sp,sp,-32
    8054:	00812c23          	sw	s0,24(sp)
    8058:	01212823          	sw	s2,16(sp)
    805c:	01312623          	sw	s3,12(sp)
    8060:	00112e23          	sw	ra,28(sp)
    8064:	00912a23          	sw	s1,20(sp)
    8068:	01412423          	sw	s4,8(sp)
    806c:	02010413          	add	s0,sp,32
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8070:	0005a023          	sw	zero,0(a1)
    8074:	00052023          	sw	zero,0(a0)
{
    8078:	00050913          	mv	s2,a0
    807c:	00058993          	mv	s3,a1
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8080:	00000097          	auipc	ra,0x0
    8084:	9b4080e7          	jalr	-1612(ra) # 7a34 <filealloc>
    8088:	00a92023          	sw	a0,0(s2)
    808c:	0a050063          	beqz	a0,812c <pipealloc+0xdc>
    8090:	00000097          	auipc	ra,0x0
    8094:	9a4080e7          	jalr	-1628(ra) # 7a34 <filealloc>
    8098:	00a9a023          	sw	a0,0(s3)
    809c:	08050063          	beqz	a0,811c <pipealloc+0xcc>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80a0:	ffff9097          	auipc	ra,0xffff9
    80a4:	00c080e7          	jalr	12(ra) # 10ac <kalloc>
    80a8:	00050493          	mv	s1,a0
    80ac:	08050c63          	beqz	a0,8144 <pipealloc+0xf4>
    goto bad;
  pi->readopen = 1;
    80b0:	00100a13          	li	s4,1
    80b4:	21452a23          	sw	s4,532(a0)
  pi->writeopen = 1;
    80b8:	21452c23          	sw	s4,536(a0)
  pi->nwrite = 0;
    80bc:	20052823          	sw	zero,528(a0)
  pi->nread = 0;
    80c0:	20052623          	sw	zero,524(a0)
  initlock(&pi->lock, "pipe");
    80c4:	00003597          	auipc	a1,0x3
    80c8:	68858593          	add	a1,a1,1672 # b74c <main+0x61c>
    80cc:	ffff9097          	auipc	ra,0xffff9
    80d0:	080080e7          	jalr	128(ra) # 114c <initlock>
  (*f0)->type = FD_PIPE;
    80d4:	00092703          	lw	a4,0(s2)
  (*f0)->pipe = pi;
  (*f1)->type = FD_PIPE;
  (*f1)->readable = 0;
  (*f1)->writable = 1;
  (*f1)->pipe = pi;
  return 0;
    80d8:	00000513          	li	a0,0
  (*f0)->readable = 1;
    80dc:	01471423          	sh	s4,8(a4)
  (*f1)->type = FD_PIPE;
    80e0:	0009a783          	lw	a5,0(s3)
  (*f0)->type = FD_PIPE;
    80e4:	01472023          	sw	s4,0(a4)
  (*f0)->pipe = pi;
    80e8:	00972623          	sw	s1,12(a4)
  (*f1)->readable = 0;
    80ec:	10000713          	li	a4,256
  (*f1)->type = FD_PIPE;
    80f0:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80f4:	00e79423          	sh	a4,8(a5)
  (*f1)->pipe = pi;
    80f8:	0097a623          	sw	s1,12(a5)
  if(*f0)
    fileclose(*f0);
  if(*f1)
    fileclose(*f1);
  return -1;
}
    80fc:	01c12083          	lw	ra,28(sp)
    8100:	01812403          	lw	s0,24(sp)
    8104:	01412483          	lw	s1,20(sp)
    8108:	01012903          	lw	s2,16(sp)
    810c:	00c12983          	lw	s3,12(sp)
    8110:	00812a03          	lw	s4,8(sp)
    8114:	02010113          	add	sp,sp,32
    8118:	00008067          	ret
  if(*f0)
    811c:	00092503          	lw	a0,0(s2)
    8120:	00050e63          	beqz	a0,813c <pipealloc+0xec>
    fileclose(*f0);
    8124:	00000097          	auipc	ra,0x0
    8128:	a24080e7          	jalr	-1500(ra) # 7b48 <fileclose>
  if(*f1)
    812c:	0009a503          	lw	a0,0(s3)
    8130:	00050663          	beqz	a0,813c <pipealloc+0xec>
    fileclose(*f1);
    8134:	00000097          	auipc	ra,0x0
    8138:	a14080e7          	jalr	-1516(ra) # 7b48 <fileclose>
  return -1;
    813c:	fff00513          	li	a0,-1
    8140:	fbdff06f          	j	80fc <pipealloc+0xac>
  if(*f0)
    8144:	00092503          	lw	a0,0(s2)
    8148:	fc051ee3          	bnez	a0,8124 <pipealloc+0xd4>
    814c:	fe1ff06f          	j	812c <pipealloc+0xdc>

00008150 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8150:	ff010113          	add	sp,sp,-16
    8154:	00812423          	sw	s0,8(sp)
    8158:	00912223          	sw	s1,4(sp)
    815c:	01212023          	sw	s2,0(sp)
    8160:	00112623          	sw	ra,12(sp)
    8164:	01010413          	add	s0,sp,16
    8168:	00058913          	mv	s2,a1
    816c:	00050493          	mv	s1,a0
  acquire(&pi->lock);
    8170:	ffff9097          	auipc	ra,0xffff9
    8174:	000080e7          	jalr	ra # 1170 <acquire>
  if(writable){
    8178:	06090663          	beqz	s2,81e4 <pipeclose+0x94>
    pi->writeopen = 0;
    817c:	2004ac23          	sw	zero,536(s1)
    wakeup(&pi->nread);
    8180:	20c48513          	add	a0,s1,524
    8184:	ffffc097          	auipc	ra,0xffffc
    8188:	fd4080e7          	jalr	-44(ra) # 4158 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    818c:	2144a783          	lw	a5,532(s1)
    release(&pi->lock);
    8190:	00048513          	mv	a0,s1
  if(pi->readopen == 0 && pi->writeopen == 0){
    8194:	00079663          	bnez	a5,81a0 <pipeclose+0x50>
    8198:	2184a783          	lw	a5,536(s1)
    819c:	02078063          	beqz	a5,81bc <pipeclose+0x6c>
    kfree((char*)pi);
  } else
    release(&pi->lock);
}
    81a0:	00812403          	lw	s0,8(sp)
    81a4:	00c12083          	lw	ra,12(sp)
    81a8:	00412483          	lw	s1,4(sp)
    81ac:	00012903          	lw	s2,0(sp)
    81b0:	01010113          	add	sp,sp,16
    release(&pi->lock);
    81b4:	ffff9317          	auipc	t1,0xffff9
    81b8:	14830067          	jr	328(t1) # 12fc <release>
    release(&pi->lock);
    81bc:	ffff9097          	auipc	ra,0xffff9
    81c0:	140080e7          	jalr	320(ra) # 12fc <release>
}
    81c4:	00812403          	lw	s0,8(sp)
    81c8:	00c12083          	lw	ra,12(sp)
    81cc:	00012903          	lw	s2,0(sp)
    kfree((char*)pi);
    81d0:	00048513          	mv	a0,s1
}
    81d4:	00412483          	lw	s1,4(sp)
    81d8:	01010113          	add	sp,sp,16
    kfree((char*)pi);
    81dc:	ffff9317          	auipc	t1,0xffff9
    81e0:	e4830067          	jr	-440(t1) # 1024 <kfree>
    pi->readopen = 0;
    81e4:	2004aa23          	sw	zero,532(s1)
    wakeup(&pi->nwrite);
    81e8:	21048513          	add	a0,s1,528
    81ec:	ffffc097          	auipc	ra,0xffffc
    81f0:	f6c080e7          	jalr	-148(ra) # 4158 <wakeup>
    81f4:	f99ff06f          	j	818c <pipeclose+0x3c>

000081f8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint32 addr, int n)
{
    81f8:	fc010113          	add	sp,sp,-64
    81fc:	02812c23          	sw	s0,56(sp)
    8200:	02912a23          	sw	s1,52(sp)
    8204:	03412423          	sw	s4,40(sp)
    8208:	03512223          	sw	s5,36(sp)
    820c:	03612023          	sw	s6,32(sp)
    8210:	02112e23          	sw	ra,60(sp)
    8214:	03212823          	sw	s2,48(sp)
    8218:	03312623          	sw	s3,44(sp)
    821c:	01712e23          	sw	s7,28(sp)
    8220:	04010413          	add	s0,sp,64
    8224:	00050493          	mv	s1,a0
    8228:	00060a13          	mv	s4,a2
    822c:	00058a93          	mv	s5,a1
  int i;
  char ch;
  struct proc *pr = myproc();
    8230:	ffffb097          	auipc	ra,0xffffb
    8234:	1f4080e7          	jalr	500(ra) # 3424 <myproc>
    8238:	00050b13          	mv	s6,a0

  acquire(&pi->lock);
    823c:	00048513          	mv	a0,s1
    8240:	ffff9097          	auipc	ra,0xffff9
    8244:	f30080e7          	jalr	-208(ra) # 1170 <acquire>
  for(i = 0; i < n; i++){
    8248:	0f405663          	blez	s4,8334 <pipewrite+0x13c>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    824c:	2104a703          	lw	a4,528(s1)
    8250:	015a0bb3          	add	s7,s4,s5
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    8254:	20c48913          	add	s2,s1,524
      sleep(&pi->nwrite, &pi->lock);
    8258:	21048993          	add	s3,s1,528
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    825c:	20c4a783          	lw	a5,524(s1)
    8260:	20078793          	add	a5,a5,512
    8264:	04f70463          	beq	a4,a5,82ac <pipewrite+0xb4>
    8268:	0880006f          	j	82f0 <pipewrite+0xf8>
      if(pi->readopen == 0 || myproc()->killed){
    826c:	ffffb097          	auipc	ra,0xffffb
    8270:	1b8080e7          	jalr	440(ra) # 3424 <myproc>
    8274:	00050793          	mv	a5,a0
    8278:	0187a783          	lw	a5,24(a5)
      wakeup(&pi->nread);
    827c:	00090513          	mv	a0,s2
      if(pi->readopen == 0 || myproc()->killed){
    8280:	02079a63          	bnez	a5,82b4 <pipewrite+0xbc>
      wakeup(&pi->nread);
    8284:	ffffc097          	auipc	ra,0xffffc
    8288:	ed4080e7          	jalr	-300(ra) # 4158 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    828c:	00048593          	mv	a1,s1
    8290:	00098513          	mv	a0,s3
    8294:	ffffc097          	auipc	ra,0xffffc
    8298:	dd8080e7          	jalr	-552(ra) # 406c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    829c:	20c4a783          	lw	a5,524(s1)
    82a0:	2104a703          	lw	a4,528(s1)
    82a4:	20078793          	add	a5,a5,512
    82a8:	04f71463          	bne	a4,a5,82f0 <pipewrite+0xf8>
      if(pi->readopen == 0 || myproc()->killed){
    82ac:	2144a783          	lw	a5,532(s1)
    82b0:	fa079ee3          	bnez	a5,826c <pipewrite+0x74>
        release(&pi->lock);
    82b4:	00048513          	mv	a0,s1
    82b8:	ffff9097          	auipc	ra,0xffff9
    82bc:	044080e7          	jalr	68(ra) # 12fc <release>
        return -1;
    82c0:	fff00513          	li	a0,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return n;
}
    82c4:	03c12083          	lw	ra,60(sp)
    82c8:	03812403          	lw	s0,56(sp)
    82cc:	03412483          	lw	s1,52(sp)
    82d0:	03012903          	lw	s2,48(sp)
    82d4:	02c12983          	lw	s3,44(sp)
    82d8:	02812a03          	lw	s4,40(sp)
    82dc:	02412a83          	lw	s5,36(sp)
    82e0:	02012b03          	lw	s6,32(sp)
    82e4:	01c12b83          	lw	s7,28(sp)
    82e8:	04010113          	add	sp,sp,64
    82ec:	00008067          	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    82f0:	02cb2503          	lw	a0,44(s6)
    82f4:	00100693          	li	a3,1
    82f8:	000a8613          	mv	a2,s5
    82fc:	fcf40593          	add	a1,s0,-49
    8300:	ffffb097          	auipc	ra,0xffffb
    8304:	b60080e7          	jalr	-1184(ra) # 2e60 <copyin>
    8308:	fff00793          	li	a5,-1
    830c:	02f50463          	beq	a0,a5,8334 <pipewrite+0x13c>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8310:	2104a783          	lw	a5,528(s1)
    8314:	fcf44683          	lbu	a3,-49(s0)
  for(i = 0; i < n; i++){
    8318:	001a8a93          	add	s5,s5,1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    831c:	00178713          	add	a4,a5,1
    8320:	1ff7f793          	and	a5,a5,511
    8324:	20e4a823          	sw	a4,528(s1)
    8328:	00f487b3          	add	a5,s1,a5
    832c:	00d78623          	sb	a3,12(a5)
  for(i = 0; i < n; i++){
    8330:	f37a96e3          	bne	s5,s7,825c <pipewrite+0x64>
  wakeup(&pi->nread);
    8334:	20c48513          	add	a0,s1,524
    8338:	ffffc097          	auipc	ra,0xffffc
    833c:	e20080e7          	jalr	-480(ra) # 4158 <wakeup>
  release(&pi->lock);
    8340:	00048513          	mv	a0,s1
    8344:	ffff9097          	auipc	ra,0xffff9
    8348:	fb8080e7          	jalr	-72(ra) # 12fc <release>
  return n;
    834c:	000a0513          	mv	a0,s4
    8350:	f75ff06f          	j	82c4 <pipewrite+0xcc>

00008354 <piperead>:

int
piperead(struct pipe *pi, uint32 addr, int n)
{
    8354:	fd010113          	add	sp,sp,-48
    8358:	02112623          	sw	ra,44(sp)
    835c:	02812423          	sw	s0,40(sp)
    8360:	02912223          	sw	s1,36(sp)
    8364:	03212023          	sw	s2,32(sp)
    8368:	01312e23          	sw	s3,28(sp)
    836c:	01412c23          	sw	s4,24(sp)
    8370:	01512a23          	sw	s5,20(sp)
    8374:	03010413          	add	s0,sp,48
    8378:	01612823          	sw	s6,16(sp)
    837c:	00050493          	mv	s1,a0
    8380:	00058a13          	mv	s4,a1
    8384:	00060993          	mv	s3,a2
  int i;
  struct proc *pr = myproc();
    8388:	ffffb097          	auipc	ra,0xffffb
    838c:	09c080e7          	jalr	156(ra) # 3424 <myproc>
    8390:	00050a93          	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    8394:	00048513          	mv	a0,s1
    8398:	ffff9097          	auipc	ra,0xffff9
    839c:	dd8080e7          	jalr	-552(ra) # 1170 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    83a0:	2104a703          	lw	a4,528(s1)
    83a4:	20c4a783          	lw	a5,524(s1)
    83a8:	20c48913          	add	s2,s1,524
    83ac:	02f70c63          	beq	a4,a5,83e4 <piperead+0x90>
    83b0:	03c0006f          	j	83ec <piperead+0x98>
    if(myproc()->killed){
    83b4:	ffffb097          	auipc	ra,0xffffb
    83b8:	070080e7          	jalr	112(ra) # 3424 <myproc>
    83bc:	00050793          	mv	a5,a0
    83c0:	0187a783          	lw	a5,24(a5)
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    83c4:	00048593          	mv	a1,s1
    83c8:	00090513          	mv	a0,s2
    if(myproc()->killed){
    83cc:	0a079e63          	bnez	a5,8488 <piperead+0x134>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    83d0:	ffffc097          	auipc	ra,0xffffc
    83d4:	c9c080e7          	jalr	-868(ra) # 406c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    83d8:	20c4a783          	lw	a5,524(s1)
    83dc:	2104a703          	lw	a4,528(s1)
    83e0:	00e79663          	bne	a5,a4,83ec <piperead+0x98>
    83e4:	2184a683          	lw	a3,536(s1)
    83e8:	fc0696e3          	bnez	a3,83b4 <piperead+0x60>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    83ec:	00000913          	li	s2,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    83f0:	fff00b13          	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    83f4:	03304a63          	bgtz	s3,8428 <piperead+0xd4>
    83f8:	04c0006f          	j	8444 <piperead+0xf0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    83fc:	20a4a623          	sw	a0,524(s1)
    8400:	00c84783          	lbu	a5,12(a6) # 100c <freerange+0xd4>
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8404:	02caa503          	lw	a0,44(s5)
    ch = pi->data[pi->nread++ % PIPESIZE];
    8408:	fcf40fa3          	sb	a5,-33(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    840c:	ffffb097          	auipc	ra,0xffffb
    8410:	93c080e7          	jalr	-1732(ra) # 2d48 <copyout>
    8414:	03650863          	beq	a0,s6,8444 <piperead+0xf0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8418:	00190913          	add	s2,s2,1
    841c:	03298463          	beq	s3,s2,8444 <piperead+0xf0>
    8420:	2104a703          	lw	a4,528(s1)
    8424:	20c4a783          	lw	a5,524(s1)
    ch = pi->data[pi->nread++ % PIPESIZE];
    8428:	1ff7f693          	and	a3,a5,511
    842c:	00d48833          	add	a6,s1,a3
    8430:	00178513          	add	a0,a5,1
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8434:	014905b3          	add	a1,s2,s4
    8438:	00100693          	li	a3,1
    843c:	fdf40613          	add	a2,s0,-33
    if(pi->nread == pi->nwrite)
    8440:	fae79ee3          	bne	a5,a4,83fc <piperead+0xa8>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8444:	21048513          	add	a0,s1,528
    8448:	ffffc097          	auipc	ra,0xffffc
    844c:	d10080e7          	jalr	-752(ra) # 4158 <wakeup>
  release(&pi->lock);
    8450:	00048513          	mv	a0,s1
    8454:	ffff9097          	auipc	ra,0xffff9
    8458:	ea8080e7          	jalr	-344(ra) # 12fc <release>
  return i;
}
    845c:	02c12083          	lw	ra,44(sp)
    8460:	02812403          	lw	s0,40(sp)
    8464:	02412483          	lw	s1,36(sp)
    8468:	01c12983          	lw	s3,28(sp)
    846c:	01812a03          	lw	s4,24(sp)
    8470:	01412a83          	lw	s5,20(sp)
    8474:	01012b03          	lw	s6,16(sp)
    8478:	00090513          	mv	a0,s2
    847c:	02012903          	lw	s2,32(sp)
    8480:	03010113          	add	sp,sp,48
    8484:	00008067          	ret
      release(&pi->lock);
    8488:	00048513          	mv	a0,s1
    848c:	ffff9097          	auipc	ra,0xffff9
    8490:	e70080e7          	jalr	-400(ra) # 12fc <release>
      return -1;
    8494:	fff00913          	li	s2,-1
    8498:	fc5ff06f          	j	845c <piperead+0x108>

0000849c <exec>:

static int loadseg(pde_t *pgdir, uint32 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    849c:	ed010113          	add	sp,sp,-304
    84a0:	12112623          	sw	ra,300(sp)
    84a4:	12812423          	sw	s0,296(sp)
    84a8:	12912223          	sw	s1,292(sp)
    84ac:	13212023          	sw	s2,288(sp)
    84b0:	13010413          	add	s0,sp,304
    84b4:	11312e23          	sw	s3,284(sp)
    84b8:	11412c23          	sw	s4,280(sp)
    84bc:	11512a23          	sw	s5,276(sp)
    84c0:	11612823          	sw	s6,272(sp)
    84c4:	11712623          	sw	s7,268(sp)
    84c8:	11812423          	sw	s8,264(sp)
    84cc:	11912223          	sw	s9,260(sp)
    84d0:	11a12023          	sw	s10,256(sp)
    84d4:	0fb12e23          	sw	s11,252(sp)
    84d8:	00050913          	mv	s2,a0
    84dc:	ecb42e23          	sw	a1,-292(s0)
    84e0:	eca42c23          	sw	a0,-296(s0)
  uint32 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    84e4:	ffffb097          	auipc	ra,0xffffb
    84e8:	f40080e7          	jalr	-192(ra) # 3424 <myproc>
    84ec:	00050493          	mv	s1,a0

  begin_op();
    84f0:	fffff097          	auipc	ra,0xfffff
    84f4:	f54080e7          	jalr	-172(ra) # 7444 <begin_op>

  if((ip = namei(path)) == 0){
    84f8:	00090513          	mv	a0,s2
    84fc:	fffff097          	auipc	ra,0xfffff
    8500:	ce8080e7          	jalr	-792(ra) # 71e4 <namei>
    8504:	16050263          	beqz	a0,8668 <exec+0x1cc>
    end_op();
    return -1;
  }
  ilock(ip);
    8508:	00050993          	mv	s3,a0
    850c:	ffffe097          	auipc	ra,0xffffe
    8510:	a18080e7          	jalr	-1512(ra) # 5f24 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint32)&elf, 0, sizeof(elf)) != sizeof(elf))
    8514:	03400713          	li	a4,52
    8518:	00000693          	li	a3,0
    851c:	f0840613          	add	a2,s0,-248
    8520:	00000593          	li	a1,0
    8524:	00098513          	mv	a0,s3
    8528:	ffffe097          	auipc	ra,0xffffe
    852c:	3d8080e7          	jalr	984(ra) # 6900 <readi>
    8530:	03400793          	li	a5,52
    8534:	12f51463          	bne	a0,a5,865c <exec+0x1c0>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8538:	f0842703          	lw	a4,-248(s0)
    853c:	464c47b7          	lui	a5,0x464c4
    8540:	57f78793          	add	a5,a5,1407 # 464c457f <end+0x464a056b>
    8544:	10f71c63          	bne	a4,a5,865c <exec+0x1c0>
    goto bad;

  if((pagetable = proc_pagetable(p)) == 0)
    8548:	00048513          	mv	a0,s1
    854c:	ffffb097          	auipc	ra,0xffffb
    8550:	f9c080e7          	jalr	-100(ra) # 34e8 <proc_pagetable>
    8554:	00050a13          	mv	s4,a0
    8558:	10050263          	beqz	a0,865c <exec+0x1c0>
  // Load program into memory.

  // printf("phnum: %p\n", elf.phnum);
  // printf("phoff: %p\n", elf.phoff);

  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    855c:	f3445783          	lhu	a5,-204(s0)
    8560:	f2442b83          	lw	s7,-220(s0)
    8564:	34078463          	beqz	a5,88ac <exec+0x410>
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
    8568:	00001937          	lui	s2,0x1
  uint32 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    856c:	00000493          	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8570:	00000c13          	li	s8,0
    if(readi(ip, 0, (uint32)&ph, off, sizeof(ph)) != sizeof(ph))
    8574:	02000713          	li	a4,32
    8578:	000b8693          	mv	a3,s7
    857c:	ee840613          	add	a2,s0,-280
    8580:	00000593          	li	a1,0
    8584:	00098513          	mv	a0,s3
    8588:	ffffe097          	auipc	ra,0xffffe
    858c:	378080e7          	jalr	888(ra) # 6900 <readi>
    8590:	02000793          	li	a5,32
    8594:	24f51663          	bne	a0,a5,87e0 <exec+0x344>
    if(ph.type != ELF_PROG_LOAD)
    8598:	ee842783          	lw	a5,-280(s0)
    859c:	00100713          	li	a4,1
    85a0:	10e79a63          	bne	a5,a4,86b4 <exec+0x218>
    if(ph.memsz < ph.filesz)
    85a4:	efc42703          	lw	a4,-260(s0)
    85a8:	ef842783          	lw	a5,-264(s0)
    85ac:	22f76a63          	bltu	a4,a5,87e0 <exec+0x344>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    85b0:	ef042783          	lw	a5,-272(s0)
    85b4:	00f70633          	add	a2,a4,a5
    85b8:	22e66463          	bltu	a2,a4,87e0 <exec+0x344>
    if(ph.vaddr % PGSIZE != 0)
    85bc:	00001d37          	lui	s10,0x1
    85c0:	fffd0713          	add	a4,s10,-1 # fff <freerange+0xc7>
    85c4:	00e7f7b3          	and	a5,a5,a4
    85c8:	20079c63          	bnez	a5,87e0 <exec+0x344>
      goto bad;
    uint32 sz1;
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    85cc:	00048593          	mv	a1,s1
    85d0:	000a0513          	mv	a0,s4
    85d4:	ffffa097          	auipc	ra,0xffffa
    85d8:	33c080e7          	jalr	828(ra) # 2910 <uvmalloc>
    85dc:	00050c93          	mv	s9,a0
    85e0:	20050063          	beqz	a0,87e0 <exec+0x344>
      goto bad;
    sz = sz1;
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    85e4:	ef042a83          	lw	s5,-272(s0)
loadseg(pagetable_t pagetable, uint32 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint32 pa;

  if((va % PGSIZE) != 0)
    85e8:	fffd0793          	add	a5,s10,-1
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    85ec:	eec42b03          	lw	s6,-276(s0)
  if((va % PGSIZE) != 0)
    85f0:	00fafdb3          	and	s11,s5,a5
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    85f4:	ef842483          	lw	s1,-264(s0)
  if((va % PGSIZE) != 0)
    85f8:	2e0d9263          	bnez	s11,88dc <exec+0x440>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    85fc:	00049863          	bnez	s1,860c <exec+0x170>
    8600:	0b00006f          	j	86b0 <exec+0x214>
    8604:	012d8db3          	add	s11,s11,s2
    8608:	0a9df463          	bgeu	s11,s1,86b0 <exec+0x214>
    pa = walkaddr(pagetable, va + i);
    860c:	01ba85b3          	add	a1,s5,s11
    8610:	000a0513          	mv	a0,s4
    8614:	ffffa097          	auipc	ra,0xffffa
    8618:	c64080e7          	jalr	-924(ra) # 2278 <walkaddr>
    861c:	00050613          	mv	a2,a0
    if(pa == 0)
    8620:	26050e63          	beqz	a0,889c <exec+0x400>
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8624:	41b48d33          	sub	s10,s1,s11
    8628:	01a97463          	bgeu	s2,s10,8630 <exec+0x194>
    862c:	00001d37          	lui	s10,0x1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint32)pa, offset+i, n) != n)
    8630:	000d0713          	mv	a4,s10
    8634:	01bb06b3          	add	a3,s6,s11
    8638:	00000593          	li	a1,0
    863c:	00098513          	mv	a0,s3
    8640:	ffffe097          	auipc	ra,0xffffe
    8644:	2c0080e7          	jalr	704(ra) # 6900 <readi>
    8648:	faad0ee3          	beq	s10,a0,8604 <exec+0x168>
    proc_freepagetable(pagetable, sz);
    864c:	000c8593          	mv	a1,s9
    8650:	000a0513          	mv	a0,s4
    8654:	ffffb097          	auipc	ra,0xffffb
    8658:	f10080e7          	jalr	-240(ra) # 3564 <proc_freepagetable>
    iunlockput(ip);
    865c:	00098513          	mv	a0,s3
    8660:	ffffe097          	auipc	ra,0xffffe
    8664:	1e0080e7          	jalr	480(ra) # 6840 <iunlockput>
    end_op();
    8668:	fffff097          	auipc	ra,0xfffff
    866c:	e78080e7          	jalr	-392(ra) # 74e0 <end_op>
    return -1;
    8670:	fff00513          	li	a0,-1
}
    8674:	12c12083          	lw	ra,300(sp)
    8678:	12812403          	lw	s0,296(sp)
    867c:	12412483          	lw	s1,292(sp)
    8680:	12012903          	lw	s2,288(sp)
    8684:	11c12983          	lw	s3,284(sp)
    8688:	11812a03          	lw	s4,280(sp)
    868c:	11412a83          	lw	s5,276(sp)
    8690:	11012b03          	lw	s6,272(sp)
    8694:	10c12b83          	lw	s7,268(sp)
    8698:	10812c03          	lw	s8,264(sp)
    869c:	10412c83          	lw	s9,260(sp)
    86a0:	10012d03          	lw	s10,256(sp)
    86a4:	0fc12d83          	lw	s11,252(sp)
    86a8:	13010113          	add	sp,sp,304
    86ac:	00008067          	ret
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    86b0:	000c8493          	mv	s1,s9
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    86b4:	f3445783          	lhu	a5,-204(s0)
    86b8:	001c0c13          	add	s8,s8,1 # 1001 <freerange+0xc9>
    86bc:	020b8b93          	add	s7,s7,32
    86c0:	eafc4ae3          	blt	s8,a5,8574 <exec+0xd8>
  sz = PGROUNDUP(sz);
    86c4:	000017b7          	lui	a5,0x1
    86c8:	fff78793          	add	a5,a5,-1 # fff <freerange+0xc7>
    86cc:	00f484b3          	add	s1,s1,a5
    86d0:	fffff7b7          	lui	a5,0xfffff
    86d4:	00f4f4b3          	and	s1,s1,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    86d8:	00002937          	lui	s2,0x2
    86dc:	01248933          	add	s2,s1,s2
  iunlockput(ip);
    86e0:	00098513          	mv	a0,s3
    86e4:	ffffe097          	auipc	ra,0xffffe
    86e8:	15c080e7          	jalr	348(ra) # 6840 <iunlockput>
  end_op();
    86ec:	fffff097          	auipc	ra,0xfffff
    86f0:	df4080e7          	jalr	-524(ra) # 74e0 <end_op>
  p = myproc();
    86f4:	ffffb097          	auipc	ra,0xffffb
    86f8:	d30080e7          	jalr	-720(ra) # 3424 <myproc>
    86fc:	00050b93          	mv	s7,a0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8700:	00090613          	mv	a2,s2
    8704:	00048593          	mv	a1,s1
    8708:	000a0513          	mv	a0,s4
  uint32 oldsz = p->sz;
    870c:	028bac03          	lw	s8,40(s7)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8710:	ffffa097          	auipc	ra,0xffffa
    8714:	200080e7          	jalr	512(ra) # 2910 <uvmalloc>
    8718:	00050b13          	mv	s6,a0
    871c:	1a050663          	beqz	a0,88c8 <exec+0x42c>
  uvmclear(pagetable, sz-2*PGSIZE);
    8720:	ffffe5b7          	lui	a1,0xffffe
    8724:	00b505b3          	add	a1,a0,a1
    8728:	000a0513          	mv	a0,s4
    872c:	ffffa097          	auipc	ra,0xffffa
    8730:	594080e7          	jalr	1428(ra) # 2cc0 <uvmclear>
  for(argc = 0; argv[argc]; argc++) {
    8734:	edc42783          	lw	a5,-292(s0)
  stackbase = sp - PGSIZE;
    8738:	fffff9b7          	lui	s3,0xfffff
    873c:	013b09b3          	add	s3,s6,s3
  for(argc = 0; argv[argc]; argc++) {
    8740:	0007a503          	lw	a0,0(a5) # fffff000 <end+0xfffdafec>
    8744:	16050a63          	beqz	a0,88b8 <exec+0x41c>
    8748:	f3c40493          	add	s1,s0,-196
    874c:	fbc40a93          	add	s5,s0,-68
    8750:	000b0c93          	mv	s9,s6
    8754:	00000913          	li	s2,0
    8758:	0080006f          	j	8760 <exec+0x2c4>
    875c:	000d0913          	mv	s2,s10
    sp -= strlen(argv[argc]) + 1;
    8760:	ffff9097          	auipc	ra,0xffff9
    8764:	468080e7          	jalr	1128(ra) # 1bc8 <strlen>
    8768:	00150793          	add	a5,a0,1
    876c:	40fc87b3          	sub	a5,s9,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8770:	ff07fc93          	and	s9,a5,-16
    if(sp < stackbase)
    8774:	053cec63          	bltu	s9,s3,87cc <exec+0x330>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8778:	edc42783          	lw	a5,-292(s0)
    877c:	0007ad03          	lw	s10,0(a5)
    8780:	000d0513          	mv	a0,s10
    8784:	ffff9097          	auipc	ra,0xffff9
    8788:	444080e7          	jalr	1092(ra) # 1bc8 <strlen>
    878c:	00150693          	add	a3,a0,1
    8790:	000d0613          	mv	a2,s10
    8794:	000c8593          	mv	a1,s9
    8798:	000a0513          	mv	a0,s4
    879c:	ffffa097          	auipc	ra,0xffffa
    87a0:	5ac080e7          	jalr	1452(ra) # 2d48 <copyout>
    87a4:	02054463          	bltz	a0,87cc <exec+0x330>
  for(argc = 0; argv[argc]; argc++) {
    87a8:	edc42783          	lw	a5,-292(s0)
    ustack[argc] = sp;
    87ac:	0194a023          	sw	s9,0(s1)
  for(argc = 0; argv[argc]; argc++) {
    87b0:	00190d13          	add	s10,s2,1 # 2001 <freewalk+0x189>
    87b4:	0047a503          	lw	a0,4(a5)
    87b8:	00478793          	add	a5,a5,4
    87bc:	ecf42e23          	sw	a5,-292(s0)
    87c0:	02050463          	beqz	a0,87e8 <exec+0x34c>
    if(argc >= MAXARG)
    87c4:	00448493          	add	s1,s1,4
    87c8:	f9549ae3          	bne	s1,s5,875c <exec+0x2c0>
    proc_freepagetable(pagetable, sz);
    87cc:	000b0593          	mv	a1,s6
    87d0:	000a0513          	mv	a0,s4
    87d4:	ffffb097          	auipc	ra,0xffffb
    87d8:	d90080e7          	jalr	-624(ra) # 3564 <proc_freepagetable>
  if(ip){
    87dc:	e95ff06f          	j	8670 <exec+0x1d4>
  for(last=s=path; *s; s++)
    87e0:	00048c93          	mv	s9,s1
    87e4:	e69ff06f          	j	864c <exec+0x1b0>
  sp -= (argc+1) * sizeof(uint32);
    87e8:	00290693          	add	a3,s2,2
    87ec:	00269693          	sll	a3,a3,0x2
  ustack[argc] = 0;
    87f0:	002d1793          	sll	a5,s10,0x2
    87f4:	fc078793          	add	a5,a5,-64
    87f8:	008787b3          	add	a5,a5,s0
  sp -= (argc+1) * sizeof(uint32);
    87fc:	40dc84b3          	sub	s1,s9,a3
  ustack[argc] = 0;
    8800:	f607ae23          	sw	zero,-132(a5)
  sp -= sp % 16;
    8804:	ff04f493          	and	s1,s1,-16
  if(sp < stackbase)
    8808:	fd34e2e3          	bltu	s1,s3,87cc <exec+0x330>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint32)) < 0)
    880c:	f3c40613          	add	a2,s0,-196
    8810:	00048593          	mv	a1,s1
    8814:	000a0513          	mv	a0,s4
    8818:	ffffa097          	auipc	ra,0xffffa
    881c:	530080e7          	jalr	1328(ra) # 2d48 <copyout>
    8820:	fa0546e3          	bltz	a0,87cc <exec+0x330>
  p->tf->a1 = sp;
    8824:	030ba783          	lw	a5,48(s7)
  for(last=s=path; *s; s++)
    8828:	ed842583          	lw	a1,-296(s0)
  p->tf->a1 = sp;
    882c:	0297ae23          	sw	s1,60(a5)
  for(last=s=path; *s; s++)
    8830:	0005c783          	lbu	a5,0(a1) # ffffe000 <end+0xfffd9fec>
    8834:	02078463          	beqz	a5,885c <exec+0x3c0>
    if(*s == '/')
    8838:	02f00713          	li	a4,47
      last = s+1;
    883c:	ed842683          	lw	a3,-296(s0)
    8840:	00168693          	add	a3,a3,1
    8844:	ecd42c23          	sw	a3,-296(s0)
    if(*s == '/')
    8848:	00e79463          	bne	a5,a4,8850 <exec+0x3b4>
      last = s+1;
    884c:	00068593          	mv	a1,a3
  for(last=s=path; *s; s++)
    8850:	ed842783          	lw	a5,-296(s0)
    8854:	0007c783          	lbu	a5,0(a5)
    8858:	fe0792e3          	bnez	a5,883c <exec+0x3a0>
  safestrcpy(p->name, last, sizeof(p->name));
    885c:	01000613          	li	a2,16
    8860:	0b0b8513          	add	a0,s7,176
    8864:	ffff9097          	auipc	ra,0xffff9
    8868:	320080e7          	jalr	800(ra) # 1b84 <safestrcpy>
  p->tf->epc = elf.entry;  // initial program counter = main
    886c:	030ba783          	lw	a5,48(s7)
    8870:	f2042703          	lw	a4,-224(s0)
  oldpagetable = p->pagetable;
    8874:	02cba503          	lw	a0,44(s7)
  p->sz = sz;
    8878:	036ba423          	sw	s6,40(s7)
  p->pagetable = pagetable;
    887c:	034ba623          	sw	s4,44(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    8880:	00e7a623          	sw	a4,12(a5)
  p->tf->sp = sp; // initial stack pointer
    8884:	0097ac23          	sw	s1,24(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8888:	000c0593          	mv	a1,s8
    888c:	ffffb097          	auipc	ra,0xffffb
    8890:	cd8080e7          	jalr	-808(ra) # 3564 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8894:	000d0513          	mv	a0,s10
    8898:	dddff06f          	j	8674 <exec+0x1d8>
      panic("loadseg: address should exist");
    889c:	00003517          	auipc	a0,0x3
    88a0:	edc50513          	add	a0,a0,-292 # b778 <main+0x648>
    88a4:	ffff8097          	auipc	ra,0xffff8
    88a8:	e30080e7          	jalr	-464(ra) # 6d4 <panic>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    88ac:	00002937          	lui	s2,0x2
    88b0:	00000493          	li	s1,0
    88b4:	e2dff06f          	j	86e0 <exec+0x244>
  for(argc = 0; argv[argc]; argc++) {
    88b8:	000b0c93          	mv	s9,s6
    88bc:	00400693          	li	a3,4
    88c0:	00000d13          	li	s10,0
    88c4:	f2dff06f          	j	87f0 <exec+0x354>
    proc_freepagetable(pagetable, sz);
    88c8:	00048593          	mv	a1,s1
    88cc:	000a0513          	mv	a0,s4
    88d0:	ffffb097          	auipc	ra,0xffffb
    88d4:	c94080e7          	jalr	-876(ra) # 3564 <proc_freepagetable>
  if(ip){
    88d8:	d99ff06f          	j	8670 <exec+0x1d4>
    panic("loadseg: va must be page aligned");
    88dc:	00003517          	auipc	a0,0x3
    88e0:	e7850513          	add	a0,a0,-392 # b754 <main+0x624>
    88e4:	ffff8097          	auipc	ra,0xffff8
    88e8:	df0080e7          	jalr	-528(ra) # 6d4 <panic>

000088ec <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    88ec:	fd010113          	add	sp,sp,-48
    88f0:	02812423          	sw	s0,40(sp)
    88f4:	01312e23          	sw	s3,28(sp)
    88f8:	01412c23          	sw	s4,24(sp)
    88fc:	01512a23          	sw	s5,20(sp)
    8900:	03010413          	add	s0,sp,48
    8904:	02112623          	sw	ra,44(sp)
    8908:	02912223          	sw	s1,36(sp)
    890c:	03212023          	sw	s2,32(sp)
    8910:	01612823          	sw	s6,16(sp)
    8914:	00058a93          	mv	s5,a1
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8918:	fd040593          	add	a1,s0,-48
{
    891c:	00060a13          	mv	s4,a2
    8920:	00068993          	mv	s3,a3
  if((dp = nameiparent(path, name)) == 0)
    8924:	fffff097          	auipc	ra,0xfffff
    8928:	8f0080e7          	jalr	-1808(ra) # 7214 <nameiparent>
    892c:	08050e63          	beqz	a0,89c8 <create+0xdc>
    8930:	00050913          	mv	s2,a0
    return 0;

  ilock(dp);
    8934:	ffffd097          	auipc	ra,0xffffd
    8938:	5f0080e7          	jalr	1520(ra) # 5f24 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    893c:	00000613          	li	a2,0
    8940:	fd040593          	add	a1,s0,-48
    8944:	00090513          	mv	a0,s2
    8948:	ffffe097          	auipc	ra,0xffffe
    894c:	478080e7          	jalr	1144(ra) # 6dc0 <dirlookup>
    8950:	00050493          	mv	s1,a0
    8954:	06050e63          	beqz	a0,89d0 <create+0xe4>
    iunlockput(dp);
    8958:	00090513          	mv	a0,s2
    895c:	ffffe097          	auipc	ra,0xffffe
    8960:	ee4080e7          	jalr	-284(ra) # 6840 <iunlockput>
    ilock(ip);
    8964:	00048513          	mv	a0,s1
    8968:	ffffd097          	auipc	ra,0xffffd
    896c:	5bc080e7          	jalr	1468(ra) # 5f24 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8970:	00200793          	li	a5,2
    8974:	04fa9463          	bne	s5,a5,89bc <create+0xd0>
    8978:	0284d783          	lhu	a5,40(s1)
    897c:	00100713          	li	a4,1
    8980:	ffe78793          	add	a5,a5,-2
    8984:	01079793          	sll	a5,a5,0x10
    8988:	0107d793          	srl	a5,a5,0x10
    898c:	02f76863          	bltu	a4,a5,89bc <create+0xd0>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8990:	02c12083          	lw	ra,44(sp)
    8994:	02812403          	lw	s0,40(sp)
    8998:	02012903          	lw	s2,32(sp)
    899c:	01c12983          	lw	s3,28(sp)
    89a0:	01812a03          	lw	s4,24(sp)
    89a4:	01412a83          	lw	s5,20(sp)
    89a8:	01012b03          	lw	s6,16(sp)
    89ac:	00048513          	mv	a0,s1
    89b0:	02412483          	lw	s1,36(sp)
    89b4:	03010113          	add	sp,sp,48
    89b8:	00008067          	ret
    iunlockput(ip);
    89bc:	00048513          	mv	a0,s1
    89c0:	ffffe097          	auipc	ra,0xffffe
    89c4:	e80080e7          	jalr	-384(ra) # 6840 <iunlockput>
    return 0;
    89c8:	00000493          	li	s1,0
    89cc:	fc5ff06f          	j	8990 <create+0xa4>
  if((ip = ialloc(dp->dev, type)) == 0)
    89d0:	00092503          	lw	a0,0(s2) # 2000 <freewalk+0x188>
    89d4:	000a8593          	mv	a1,s5
    89d8:	ffffd097          	auipc	ra,0xffffd
    89dc:	27c080e7          	jalr	636(ra) # 5c54 <ialloc>
    89e0:	00050493          	mv	s1,a0
    89e4:	0c050263          	beqz	a0,8aa8 <create+0x1bc>
  ilock(ip);
    89e8:	ffffd097          	auipc	ra,0xffffd
    89ec:	53c080e7          	jalr	1340(ra) # 5f24 <ilock>
  ip->nlink = 1;
    89f0:	00100b13          	li	s6,1
  ip->major = major;
    89f4:	03449523          	sh	s4,42(s1)
  ip->minor = minor;
    89f8:	03349623          	sh	s3,44(s1)
  ip->nlink = 1;
    89fc:	03649723          	sh	s6,46(s1)
  iupdate(ip);
    8a00:	00048513          	mv	a0,s1
    8a04:	ffffd097          	auipc	ra,0xffffd
    8a08:	418080e7          	jalr	1048(ra) # 5e1c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8a0c:	036a8663          	beq	s5,s6,8a38 <create+0x14c>
  if(dirlink(dp, name, ip->inum) < 0)
    8a10:	0044a603          	lw	a2,4(s1)
    8a14:	fd040593          	add	a1,s0,-48
    8a18:	00090513          	mv	a0,s2
    8a1c:	ffffe097          	auipc	ra,0xffffe
    8a20:	55c080e7          	jalr	1372(ra) # 6f78 <dirlink>
    8a24:	06054a63          	bltz	a0,8a98 <create+0x1ac>
  iunlockput(dp);
    8a28:	00090513          	mv	a0,s2
    8a2c:	ffffe097          	auipc	ra,0xffffe
    8a30:	e14080e7          	jalr	-492(ra) # 6840 <iunlockput>
  return ip;
    8a34:	f5dff06f          	j	8990 <create+0xa4>
    dp->nlink++;  // for ".."
    8a38:	02e95783          	lhu	a5,46(s2)
    iupdate(dp);
    8a3c:	00090513          	mv	a0,s2
    dp->nlink++;  // for ".."
    8a40:	00178793          	add	a5,a5,1
    8a44:	02f91723          	sh	a5,46(s2)
    iupdate(dp);
    8a48:	ffffd097          	auipc	ra,0xffffd
    8a4c:	3d4080e7          	jalr	980(ra) # 5e1c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8a50:	0044a603          	lw	a2,4(s1)
    8a54:	00003597          	auipc	a1,0x3
    8a58:	d5458593          	add	a1,a1,-684 # b7a8 <main+0x678>
    8a5c:	00048513          	mv	a0,s1
    8a60:	ffffe097          	auipc	ra,0xffffe
    8a64:	518080e7          	jalr	1304(ra) # 6f78 <dirlink>
    8a68:	02054063          	bltz	a0,8a88 <create+0x19c>
    8a6c:	00492603          	lw	a2,4(s2)
    8a70:	00003597          	auipc	a1,0x3
    8a74:	d4858593          	add	a1,a1,-696 # b7b8 <main+0x688>
    8a78:	00048513          	mv	a0,s1
    8a7c:	ffffe097          	auipc	ra,0xffffe
    8a80:	4fc080e7          	jalr	1276(ra) # 6f78 <dirlink>
    8a84:	f80556e3          	bgez	a0,8a10 <create+0x124>
      panic("create dots");
    8a88:	00003517          	auipc	a0,0x3
    8a8c:	d2450513          	add	a0,a0,-732 # b7ac <main+0x67c>
    8a90:	ffff8097          	auipc	ra,0xffff8
    8a94:	c44080e7          	jalr	-956(ra) # 6d4 <panic>
    panic("create: dirlink");
    8a98:	00003517          	auipc	a0,0x3
    8a9c:	d2450513          	add	a0,a0,-732 # b7bc <main+0x68c>
    8aa0:	ffff8097          	auipc	ra,0xffff8
    8aa4:	c34080e7          	jalr	-972(ra) # 6d4 <panic>
    panic("create: ialloc");
    8aa8:	00003517          	auipc	a0,0x3
    8aac:	cf050513          	add	a0,a0,-784 # b798 <main+0x668>
    8ab0:	ffff8097          	auipc	ra,0xffff8
    8ab4:	c24080e7          	jalr	-988(ra) # 6d4 <panic>

00008ab8 <sys_dup>:
{
    8ab8:	fe010113          	add	sp,sp,-32
    8abc:	00812c23          	sw	s0,24(sp)
    8ac0:	00112e23          	sw	ra,28(sp)
    8ac4:	02010413          	add	s0,sp,32
    8ac8:	00912a23          	sw	s1,20(sp)
    8acc:	01212823          	sw	s2,16(sp)
  if(argint(n, &fd) < 0)
    8ad0:	fec40593          	add	a1,s0,-20
    8ad4:	00000513          	li	a0,0
    8ad8:	ffffc097          	auipc	ra,0xffffc
    8adc:	1e0080e7          	jalr	480(ra) # 4cb8 <argint>
    8ae0:	0a054e63          	bltz	a0,8b9c <sys_dup+0xe4>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8ae4:	fec42703          	lw	a4,-20(s0)
    8ae8:	00f00793          	li	a5,15
    8aec:	0ae7e863          	bltu	a5,a4,8b9c <sys_dup+0xe4>
    8af0:	ffffb097          	auipc	ra,0xffffb
    8af4:	934080e7          	jalr	-1740(ra) # 3424 <myproc>
    8af8:	fec42783          	lw	a5,-20(s0)
    8afc:	01878793          	add	a5,a5,24
    8b00:	00279793          	sll	a5,a5,0x2
    8b04:	00f50533          	add	a0,a0,a5
    8b08:	00c52903          	lw	s2,12(a0)
    8b0c:	08090863          	beqz	s2,8b9c <sys_dup+0xe4>
  struct proc *p = myproc();
    8b10:	ffffb097          	auipc	ra,0xffffb
    8b14:	914080e7          	jalr	-1772(ra) # 3424 <myproc>
    if(p->ofile[fd] == 0){
    8b18:	06c52783          	lw	a5,108(a0)
    8b1c:	08078e63          	beqz	a5,8bb8 <sys_dup+0x100>
    8b20:	07052783          	lw	a5,112(a0)
    8b24:	0c078863          	beqz	a5,8bf4 <sys_dup+0x13c>
    8b28:	07452783          	lw	a5,116(a0)
    8b2c:	0c078c63          	beqz	a5,8c04 <sys_dup+0x14c>
    8b30:	07852783          	lw	a5,120(a0)
    8b34:	0c078c63          	beqz	a5,8c0c <sys_dup+0x154>
    8b38:	07c52783          	lw	a5,124(a0)
    8b3c:	0c078c63          	beqz	a5,8c14 <sys_dup+0x15c>
    8b40:	08052783          	lw	a5,128(a0)
    8b44:	0c078c63          	beqz	a5,8c1c <sys_dup+0x164>
    8b48:	08452783          	lw	a5,132(a0)
    8b4c:	0c078c63          	beqz	a5,8c24 <sys_dup+0x16c>
    8b50:	08852783          	lw	a5,136(a0)
    8b54:	0c078c63          	beqz	a5,8c2c <sys_dup+0x174>
    8b58:	08c52783          	lw	a5,140(a0)
    8b5c:	0c078c63          	beqz	a5,8c34 <sys_dup+0x17c>
    8b60:	09052783          	lw	a5,144(a0)
    8b64:	0c078c63          	beqz	a5,8c3c <sys_dup+0x184>
    8b68:	09452783          	lw	a5,148(a0)
    8b6c:	0c078c63          	beqz	a5,8c44 <sys_dup+0x18c>
    8b70:	09852783          	lw	a5,152(a0)
    8b74:	08078463          	beqz	a5,8bfc <sys_dup+0x144>
    8b78:	09c52783          	lw	a5,156(a0)
    8b7c:	0c078863          	beqz	a5,8c4c <sys_dup+0x194>
    8b80:	0a052783          	lw	a5,160(a0)
    8b84:	0c078863          	beqz	a5,8c54 <sys_dup+0x19c>
    8b88:	0a452783          	lw	a5,164(a0)
    8b8c:	0c078863          	beqz	a5,8c5c <sys_dup+0x1a4>
    8b90:	0a852783          	lw	a5,168(a0)
  for(fd = 0; fd < NOFILE; fd++){
    8b94:	00f00493          	li	s1,15
    if(p->ofile[fd] == 0){
    8b98:	02078263          	beqz	a5,8bbc <sys_dup+0x104>
}
    8b9c:	01c12083          	lw	ra,28(sp)
    8ba0:	01812403          	lw	s0,24(sp)
    8ba4:	01412483          	lw	s1,20(sp)
    8ba8:	01012903          	lw	s2,16(sp)
    return -1;
    8bac:	fff00513          	li	a0,-1
}
    8bb0:	02010113          	add	sp,sp,32
    8bb4:	00008067          	ret
  for(fd = 0; fd < NOFILE; fd++){
    8bb8:	00000493          	li	s1,0
      p->ofile[fd] = f;
    8bbc:	01848793          	add	a5,s1,24
    8bc0:	00279793          	sll	a5,a5,0x2
    8bc4:	00f507b3          	add	a5,a0,a5
    8bc8:	0127a623          	sw	s2,12(a5)
  filedup(f);
    8bcc:	00090513          	mv	a0,s2
    8bd0:	fffff097          	auipc	ra,0xfffff
    8bd4:	f08080e7          	jalr	-248(ra) # 7ad8 <filedup>
}
    8bd8:	01c12083          	lw	ra,28(sp)
    8bdc:	01812403          	lw	s0,24(sp)
    8be0:	01012903          	lw	s2,16(sp)
  return fd;
    8be4:	00048513          	mv	a0,s1
}
    8be8:	01412483          	lw	s1,20(sp)
    8bec:	02010113          	add	sp,sp,32
    8bf0:	00008067          	ret
  for(fd = 0; fd < NOFILE; fd++){
    8bf4:	00100493          	li	s1,1
    8bf8:	fc5ff06f          	j	8bbc <sys_dup+0x104>
    8bfc:	00b00493          	li	s1,11
    8c00:	fbdff06f          	j	8bbc <sys_dup+0x104>
    8c04:	00200493          	li	s1,2
    8c08:	fb5ff06f          	j	8bbc <sys_dup+0x104>
    8c0c:	00300493          	li	s1,3
    8c10:	fadff06f          	j	8bbc <sys_dup+0x104>
    8c14:	00400493          	li	s1,4
    8c18:	fa5ff06f          	j	8bbc <sys_dup+0x104>
    8c1c:	00500493          	li	s1,5
    8c20:	f9dff06f          	j	8bbc <sys_dup+0x104>
    8c24:	00600493          	li	s1,6
    8c28:	f95ff06f          	j	8bbc <sys_dup+0x104>
    8c2c:	00700493          	li	s1,7
    8c30:	f8dff06f          	j	8bbc <sys_dup+0x104>
    8c34:	00800493          	li	s1,8
    8c38:	f85ff06f          	j	8bbc <sys_dup+0x104>
    8c3c:	00900493          	li	s1,9
    8c40:	f7dff06f          	j	8bbc <sys_dup+0x104>
    8c44:	00a00493          	li	s1,10
    8c48:	f75ff06f          	j	8bbc <sys_dup+0x104>
    8c4c:	00c00493          	li	s1,12
    8c50:	f6dff06f          	j	8bbc <sys_dup+0x104>
    8c54:	00d00493          	li	s1,13
    8c58:	f65ff06f          	j	8bbc <sys_dup+0x104>
    8c5c:	00e00493          	li	s1,14
    8c60:	f5dff06f          	j	8bbc <sys_dup+0x104>

00008c64 <sys_read>:
{
    8c64:	fe010113          	add	sp,sp,-32
    8c68:	00812c23          	sw	s0,24(sp)
    8c6c:	00112e23          	sw	ra,28(sp)
    8c70:	02010413          	add	s0,sp,32
    8c74:	00912a23          	sw	s1,20(sp)
  if(argint(n, &fd) < 0)
    8c78:	fec40593          	add	a1,s0,-20
    8c7c:	00000513          	li	a0,0
    8c80:	ffffc097          	auipc	ra,0xffffc
    8c84:	038080e7          	jalr	56(ra) # 4cb8 <argint>
    8c88:	08054063          	bltz	a0,8d08 <sys_read+0xa4>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8c8c:	fec42703          	lw	a4,-20(s0)
    8c90:	00f00793          	li	a5,15
    8c94:	06e7ea63          	bltu	a5,a4,8d08 <sys_read+0xa4>
    8c98:	ffffa097          	auipc	ra,0xffffa
    8c9c:	78c080e7          	jalr	1932(ra) # 3424 <myproc>
    8ca0:	fec42783          	lw	a5,-20(s0)
    8ca4:	01878793          	add	a5,a5,24
    8ca8:	00279793          	sll	a5,a5,0x2
    8cac:	00f50533          	add	a0,a0,a5
    8cb0:	00c52483          	lw	s1,12(a0)
    8cb4:	04048a63          	beqz	s1,8d08 <sys_read+0xa4>
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8cb8:	fe840593          	add	a1,s0,-24
    8cbc:	00200513          	li	a0,2
    8cc0:	ffffc097          	auipc	ra,0xffffc
    8cc4:	ff8080e7          	jalr	-8(ra) # 4cb8 <argint>
    8cc8:	04054063          	bltz	a0,8d08 <sys_read+0xa4>
    8ccc:	fec40593          	add	a1,s0,-20
    8cd0:	00100513          	li	a0,1
    8cd4:	ffffc097          	auipc	ra,0xffffc
    8cd8:	130080e7          	jalr	304(ra) # 4e04 <argaddr>
    8cdc:	02054663          	bltz	a0,8d08 <sys_read+0xa4>
  return fileread(f, p, n);
    8ce0:	fe842603          	lw	a2,-24(s0)
    8ce4:	fec42583          	lw	a1,-20(s0)
    8ce8:	00048513          	mv	a0,s1
    8cec:	fffff097          	auipc	ra,0xfffff
    8cf0:	040080e7          	jalr	64(ra) # 7d2c <fileread>
}
    8cf4:	01c12083          	lw	ra,28(sp)
    8cf8:	01812403          	lw	s0,24(sp)
    8cfc:	01412483          	lw	s1,20(sp)
    8d00:	02010113          	add	sp,sp,32
    8d04:	00008067          	ret
    8d08:	01c12083          	lw	ra,28(sp)
    8d0c:	01812403          	lw	s0,24(sp)
    8d10:	01412483          	lw	s1,20(sp)
    return -1;
    8d14:	fff00513          	li	a0,-1
}
    8d18:	02010113          	add	sp,sp,32
    8d1c:	00008067          	ret

00008d20 <sys_write>:
{
    8d20:	fe010113          	add	sp,sp,-32
    8d24:	00812c23          	sw	s0,24(sp)
    8d28:	00112e23          	sw	ra,28(sp)
    8d2c:	02010413          	add	s0,sp,32
    8d30:	00912a23          	sw	s1,20(sp)
  if(argint(n, &fd) < 0)
    8d34:	fec40593          	add	a1,s0,-20
    8d38:	00000513          	li	a0,0
    8d3c:	ffffc097          	auipc	ra,0xffffc
    8d40:	f7c080e7          	jalr	-132(ra) # 4cb8 <argint>
    8d44:	08054063          	bltz	a0,8dc4 <sys_write+0xa4>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8d48:	fec42703          	lw	a4,-20(s0)
    8d4c:	00f00793          	li	a5,15
    8d50:	06e7ea63          	bltu	a5,a4,8dc4 <sys_write+0xa4>
    8d54:	ffffa097          	auipc	ra,0xffffa
    8d58:	6d0080e7          	jalr	1744(ra) # 3424 <myproc>
    8d5c:	fec42783          	lw	a5,-20(s0)
    8d60:	01878793          	add	a5,a5,24
    8d64:	00279793          	sll	a5,a5,0x2
    8d68:	00f50533          	add	a0,a0,a5
    8d6c:	00c52483          	lw	s1,12(a0)
    8d70:	04048a63          	beqz	s1,8dc4 <sys_write+0xa4>
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8d74:	fe840593          	add	a1,s0,-24
    8d78:	00200513          	li	a0,2
    8d7c:	ffffc097          	auipc	ra,0xffffc
    8d80:	f3c080e7          	jalr	-196(ra) # 4cb8 <argint>
    8d84:	04054063          	bltz	a0,8dc4 <sys_write+0xa4>
    8d88:	fec40593          	add	a1,s0,-20
    8d8c:	00100513          	li	a0,1
    8d90:	ffffc097          	auipc	ra,0xffffc
    8d94:	074080e7          	jalr	116(ra) # 4e04 <argaddr>
    8d98:	02054663          	bltz	a0,8dc4 <sys_write+0xa4>
  return filewrite(f, p, n);
    8d9c:	fe842603          	lw	a2,-24(s0)
    8da0:	fec42583          	lw	a1,-20(s0)
    8da4:	00048513          	mv	a0,s1
    8da8:	fffff097          	auipc	ra,0xfffff
    8dac:	0c0080e7          	jalr	192(ra) # 7e68 <filewrite>
}
    8db0:	01c12083          	lw	ra,28(sp)
    8db4:	01812403          	lw	s0,24(sp)
    8db8:	01412483          	lw	s1,20(sp)
    8dbc:	02010113          	add	sp,sp,32
    8dc0:	00008067          	ret
    8dc4:	01c12083          	lw	ra,28(sp)
    8dc8:	01812403          	lw	s0,24(sp)
    8dcc:	01412483          	lw	s1,20(sp)
    return -1;
    8dd0:	fff00513          	li	a0,-1
}
    8dd4:	02010113          	add	sp,sp,32
    8dd8:	00008067          	ret

00008ddc <sys_close>:
{
    8ddc:	fe010113          	add	sp,sp,-32
    8de0:	00812c23          	sw	s0,24(sp)
    8de4:	00112e23          	sw	ra,28(sp)
    8de8:	02010413          	add	s0,sp,32
    8dec:	00912a23          	sw	s1,20(sp)
    8df0:	01212823          	sw	s2,16(sp)
  if(argint(n, &fd) < 0)
    8df4:	fec40593          	add	a1,s0,-20
    8df8:	00000513          	li	a0,0
    8dfc:	ffffc097          	auipc	ra,0xffffc
    8e00:	ebc080e7          	jalr	-324(ra) # 4cb8 <argint>
    8e04:	06054463          	bltz	a0,8e6c <sys_close+0x90>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8e08:	fec42703          	lw	a4,-20(s0)
    8e0c:	00f00793          	li	a5,15
    8e10:	04e7ee63          	bltu	a5,a4,8e6c <sys_close+0x90>
    8e14:	ffffa097          	auipc	ra,0xffffa
    8e18:	610080e7          	jalr	1552(ra) # 3424 <myproc>
    8e1c:	fec42483          	lw	s1,-20(s0)
    8e20:	01848493          	add	s1,s1,24
    8e24:	00249493          	sll	s1,s1,0x2
    8e28:	00950533          	add	a0,a0,s1
    8e2c:	00c52903          	lw	s2,12(a0)
    8e30:	02090e63          	beqz	s2,8e6c <sys_close+0x90>
  myproc()->ofile[fd] = 0;
    8e34:	ffffa097          	auipc	ra,0xffffa
    8e38:	5f0080e7          	jalr	1520(ra) # 3424 <myproc>
    8e3c:	00950533          	add	a0,a0,s1
    8e40:	00052623          	sw	zero,12(a0)
  fileclose(f);
    8e44:	00090513          	mv	a0,s2
    8e48:	fffff097          	auipc	ra,0xfffff
    8e4c:	d00080e7          	jalr	-768(ra) # 7b48 <fileclose>
  return 0;
    8e50:	00000513          	li	a0,0
}
    8e54:	01c12083          	lw	ra,28(sp)
    8e58:	01812403          	lw	s0,24(sp)
    8e5c:	01412483          	lw	s1,20(sp)
    8e60:	01012903          	lw	s2,16(sp)
    8e64:	02010113          	add	sp,sp,32
    8e68:	00008067          	ret
    return -1;
    8e6c:	fff00513          	li	a0,-1
    8e70:	fe5ff06f          	j	8e54 <sys_close+0x78>

00008e74 <sys_fstat>:
{
    8e74:	fe010113          	add	sp,sp,-32
    8e78:	00812c23          	sw	s0,24(sp)
    8e7c:	00112e23          	sw	ra,28(sp)
    8e80:	02010413          	add	s0,sp,32
    8e84:	00912a23          	sw	s1,20(sp)
  if(argint(n, &fd) < 0)
    8e88:	fec40593          	add	a1,s0,-20
    8e8c:	00000513          	li	a0,0
    8e90:	ffffc097          	auipc	ra,0xffffc
    8e94:	e28080e7          	jalr	-472(ra) # 4cb8 <argint>
    8e98:	06054463          	bltz	a0,8f00 <sys_fstat+0x8c>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8e9c:	fec42703          	lw	a4,-20(s0)
    8ea0:	00f00793          	li	a5,15
    8ea4:	04e7ee63          	bltu	a5,a4,8f00 <sys_fstat+0x8c>
    8ea8:	ffffa097          	auipc	ra,0xffffa
    8eac:	57c080e7          	jalr	1404(ra) # 3424 <myproc>
    8eb0:	fec42783          	lw	a5,-20(s0)
    8eb4:	01878793          	add	a5,a5,24
    8eb8:	00279793          	sll	a5,a5,0x2
    8ebc:	00f50533          	add	a0,a0,a5
    8ec0:	00c52483          	lw	s1,12(a0)
    8ec4:	02048e63          	beqz	s1,8f00 <sys_fstat+0x8c>
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8ec8:	fec40593          	add	a1,s0,-20
    8ecc:	00100513          	li	a0,1
    8ed0:	ffffc097          	auipc	ra,0xffffc
    8ed4:	f34080e7          	jalr	-204(ra) # 4e04 <argaddr>
    8ed8:	02054463          	bltz	a0,8f00 <sys_fstat+0x8c>
  return filestat(f, st);
    8edc:	fec42583          	lw	a1,-20(s0)
    8ee0:	00048513          	mv	a0,s1
    8ee4:	fffff097          	auipc	ra,0xfffff
    8ee8:	da0080e7          	jalr	-608(ra) # 7c84 <filestat>
}
    8eec:	01c12083          	lw	ra,28(sp)
    8ef0:	01812403          	lw	s0,24(sp)
    8ef4:	01412483          	lw	s1,20(sp)
    8ef8:	02010113          	add	sp,sp,32
    8efc:	00008067          	ret
    8f00:	01c12083          	lw	ra,28(sp)
    8f04:	01812403          	lw	s0,24(sp)
    8f08:	01412483          	lw	s1,20(sp)
    return -1;
    8f0c:	fff00513          	li	a0,-1
}
    8f10:	02010113          	add	sp,sp,32
    8f14:	00008067          	ret

00008f18 <sys_link>:
{
    8f18:	ee010113          	add	sp,sp,-288
    8f1c:	10812c23          	sw	s0,280(sp)
    8f20:	10112e23          	sw	ra,284(sp)
    8f24:	12010413          	add	s0,sp,288
    8f28:	10912a23          	sw	s1,276(sp)
    8f2c:	11212823          	sw	s2,272(sp)
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8f30:	08000613          	li	a2,128
    8f34:	f7040593          	add	a1,s0,-144
    8f38:	00000513          	li	a0,0
    8f3c:	ffffc097          	auipc	ra,0xffffc
    8f40:	014080e7          	jalr	20(ra) # 4f50 <argstr>
    8f44:	12054a63          	bltz	a0,9078 <sys_link+0x160>
    8f48:	08000613          	li	a2,128
    8f4c:	ef040593          	add	a1,s0,-272
    8f50:	00100513          	li	a0,1
    8f54:	ffffc097          	auipc	ra,0xffffc
    8f58:	ffc080e7          	jalr	-4(ra) # 4f50 <argstr>
    8f5c:	10054e63          	bltz	a0,9078 <sys_link+0x160>
  begin_op();
    8f60:	ffffe097          	auipc	ra,0xffffe
    8f64:	4e4080e7          	jalr	1252(ra) # 7444 <begin_op>
  if((ip = namei(old)) == 0){
    8f68:	f7040513          	add	a0,s0,-144
    8f6c:	ffffe097          	auipc	ra,0xffffe
    8f70:	278080e7          	jalr	632(ra) # 71e4 <namei>
    8f74:	00050493          	mv	s1,a0
    8f78:	10050e63          	beqz	a0,9094 <sys_link+0x17c>
  ilock(ip);
    8f7c:	ffffd097          	auipc	ra,0xffffd
    8f80:	fa8080e7          	jalr	-88(ra) # 5f24 <ilock>
  if(ip->type == T_DIR){
    8f84:	02849703          	lh	a4,40(s1)
    8f88:	00100793          	li	a5,1
    8f8c:	0cf70c63          	beq	a4,a5,9064 <sys_link+0x14c>
  ip->nlink++;
    8f90:	02e4d783          	lhu	a5,46(s1)
  iupdate(ip);
    8f94:	00048513          	mv	a0,s1
  ip->nlink++;
    8f98:	00178793          	add	a5,a5,1
    8f9c:	02f49723          	sh	a5,46(s1)
  iupdate(ip);
    8fa0:	ffffd097          	auipc	ra,0xffffd
    8fa4:	e7c080e7          	jalr	-388(ra) # 5e1c <iupdate>
  iunlock(ip);
    8fa8:	00048513          	mv	a0,s1
    8fac:	ffffd097          	auipc	ra,0xffffd
    8fb0:	06c080e7          	jalr	108(ra) # 6018 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8fb4:	ee040593          	add	a1,s0,-288
    8fb8:	ef040513          	add	a0,s0,-272
    8fbc:	ffffe097          	auipc	ra,0xffffe
    8fc0:	258080e7          	jalr	600(ra) # 7214 <nameiparent>
    8fc4:	00050913          	mv	s2,a0
    8fc8:	06050c63          	beqz	a0,9040 <sys_link+0x128>
  ilock(dp);
    8fcc:	ffffd097          	auipc	ra,0xffffd
    8fd0:	f58080e7          	jalr	-168(ra) # 5f24 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8fd4:	00092703          	lw	a4,0(s2)
    8fd8:	0004a783          	lw	a5,0(s1)
    8fdc:	04f71c63          	bne	a4,a5,9034 <sys_link+0x11c>
    8fe0:	0044a603          	lw	a2,4(s1)
    8fe4:	ee040593          	add	a1,s0,-288
    8fe8:	00090513          	mv	a0,s2
    8fec:	ffffe097          	auipc	ra,0xffffe
    8ff0:	f8c080e7          	jalr	-116(ra) # 6f78 <dirlink>
    8ff4:	04054063          	bltz	a0,9034 <sys_link+0x11c>
  iunlockput(dp);
    8ff8:	00090513          	mv	a0,s2
    8ffc:	ffffe097          	auipc	ra,0xffffe
    9000:	844080e7          	jalr	-1980(ra) # 6840 <iunlockput>
  iput(ip);
    9004:	00048513          	mv	a0,s1
    9008:	ffffd097          	auipc	ra,0xffffd
    900c:	07c080e7          	jalr	124(ra) # 6084 <iput>
  end_op();
    9010:	ffffe097          	auipc	ra,0xffffe
    9014:	4d0080e7          	jalr	1232(ra) # 74e0 <end_op>
}
    9018:	11c12083          	lw	ra,284(sp)
    901c:	11812403          	lw	s0,280(sp)
    9020:	11412483          	lw	s1,276(sp)
    9024:	11012903          	lw	s2,272(sp)
  return 0;
    9028:	00000513          	li	a0,0
}
    902c:	12010113          	add	sp,sp,288
    9030:	00008067          	ret
    iunlockput(dp);
    9034:	00090513          	mv	a0,s2
    9038:	ffffe097          	auipc	ra,0xffffe
    903c:	808080e7          	jalr	-2040(ra) # 6840 <iunlockput>
  ilock(ip);
    9040:	00048513          	mv	a0,s1
    9044:	ffffd097          	auipc	ra,0xffffd
    9048:	ee0080e7          	jalr	-288(ra) # 5f24 <ilock>
  ip->nlink--;
    904c:	02e4d783          	lhu	a5,46(s1)
  iupdate(ip);
    9050:	00048513          	mv	a0,s1
  ip->nlink--;
    9054:	fff78793          	add	a5,a5,-1
    9058:	02f49723          	sh	a5,46(s1)
  iupdate(ip);
    905c:	ffffd097          	auipc	ra,0xffffd
    9060:	dc0080e7          	jalr	-576(ra) # 5e1c <iupdate>
  iunlockput(ip);
    9064:	00048513          	mv	a0,s1
    9068:	ffffd097          	auipc	ra,0xffffd
    906c:	7d8080e7          	jalr	2008(ra) # 6840 <iunlockput>
  end_op();
    9070:	ffffe097          	auipc	ra,0xffffe
    9074:	470080e7          	jalr	1136(ra) # 74e0 <end_op>
}
    9078:	11c12083          	lw	ra,284(sp)
    907c:	11812403          	lw	s0,280(sp)
    9080:	11412483          	lw	s1,276(sp)
    9084:	11012903          	lw	s2,272(sp)
    return -1;
    9088:	fff00513          	li	a0,-1
}
    908c:	12010113          	add	sp,sp,288
    9090:	00008067          	ret
    end_op();
    9094:	ffffe097          	auipc	ra,0xffffe
    9098:	44c080e7          	jalr	1100(ra) # 74e0 <end_op>
    return -1;
    909c:	fddff06f          	j	9078 <sys_link+0x160>

000090a0 <sys_unlink>:
{
    90a0:	f3010113          	add	sp,sp,-208
    90a4:	0c812423          	sw	s0,200(sp)
    90a8:	0c112623          	sw	ra,204(sp)
    90ac:	0d010413          	add	s0,sp,208
    90b0:	0c912223          	sw	s1,196(sp)
    90b4:	0d212023          	sw	s2,192(sp)
    90b8:	0b312e23          	sw	s3,188(sp)
  if(argstr(0, path, MAXPATH) < 0)
    90bc:	08000613          	li	a2,128
    90c0:	f6040593          	add	a1,s0,-160
    90c4:	00000513          	li	a0,0
    90c8:	ffffc097          	auipc	ra,0xffffc
    90cc:	e88080e7          	jalr	-376(ra) # 4f50 <argstr>
    90d0:	18054e63          	bltz	a0,926c <sys_unlink+0x1cc>
  begin_op();
    90d4:	ffffe097          	auipc	ra,0xffffe
    90d8:	370080e7          	jalr	880(ra) # 7444 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    90dc:	f4040593          	add	a1,s0,-192
    90e0:	f6040513          	add	a0,s0,-160
    90e4:	ffffe097          	auipc	ra,0xffffe
    90e8:	130080e7          	jalr	304(ra) # 7214 <nameiparent>
    90ec:	00050913          	mv	s2,a0
    90f0:	18050263          	beqz	a0,9274 <sys_unlink+0x1d4>
  ilock(dp);
    90f4:	ffffd097          	auipc	ra,0xffffd
    90f8:	e30080e7          	jalr	-464(ra) # 5f24 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    90fc:	00002597          	auipc	a1,0x2
    9100:	6ac58593          	add	a1,a1,1708 # b7a8 <main+0x678>
    9104:	f4040513          	add	a0,s0,-192
    9108:	ffffe097          	auipc	ra,0xffffe
    910c:	c98080e7          	jalr	-872(ra) # 6da0 <namecmp>
    9110:	14050463          	beqz	a0,9258 <sys_unlink+0x1b8>
    9114:	00002597          	auipc	a1,0x2
    9118:	6a458593          	add	a1,a1,1700 # b7b8 <main+0x688>
    911c:	f4040513          	add	a0,s0,-192
    9120:	ffffe097          	auipc	ra,0xffffe
    9124:	c80080e7          	jalr	-896(ra) # 6da0 <namecmp>
    9128:	12050863          	beqz	a0,9258 <sys_unlink+0x1b8>
  if((ip = dirlookup(dp, name, &off)) == 0)
    912c:	f3c40613          	add	a2,s0,-196
    9130:	f4040593          	add	a1,s0,-192
    9134:	00090513          	mv	a0,s2
    9138:	ffffe097          	auipc	ra,0xffffe
    913c:	c88080e7          	jalr	-888(ra) # 6dc0 <dirlookup>
    9140:	00050493          	mv	s1,a0
    9144:	10050a63          	beqz	a0,9258 <sys_unlink+0x1b8>
  ilock(ip);
    9148:	ffffd097          	auipc	ra,0xffffd
    914c:	ddc080e7          	jalr	-548(ra) # 5f24 <ilock>
  if(ip->nlink < 1)
    9150:	02e49783          	lh	a5,46(s1)
    9154:	14f05e63          	blez	a5,92b0 <sys_unlink+0x210>
  if(ip->type == T_DIR && !isdirempty(ip)){
    9158:	02849703          	lh	a4,40(s1)
    915c:	00100793          	li	a5,1
    9160:	0af70063          	beq	a4,a5,9200 <sys_unlink+0x160>
  memset(&de, 0, sizeof(de));
    9164:	01000613          	li	a2,16
    9168:	00000593          	li	a1,0
    916c:	f5040513          	add	a0,s0,-176
    9170:	ffff8097          	auipc	ra,0xffff8
    9174:	514080e7          	jalr	1300(ra) # 1684 <memset>
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    9178:	f3c42683          	lw	a3,-196(s0)
    917c:	01000713          	li	a4,16
    9180:	f5040613          	add	a2,s0,-176
    9184:	00000593          	li	a1,0
    9188:	00090513          	mv	a0,s2
    918c:	ffffe097          	auipc	ra,0xffffe
    9190:	97c080e7          	jalr	-1668(ra) # 6b08 <writei>
    9194:	01000793          	li	a5,16
    9198:	12f51463          	bne	a0,a5,92c0 <sys_unlink+0x220>
  if(ip->type == T_DIR){
    919c:	02849703          	lh	a4,40(s1)
    91a0:	00100793          	li	a5,1
    91a4:	0ef70063          	beq	a4,a5,9284 <sys_unlink+0x1e4>
  iunlockput(dp);
    91a8:	00090513          	mv	a0,s2
    91ac:	ffffd097          	auipc	ra,0xffffd
    91b0:	694080e7          	jalr	1684(ra) # 6840 <iunlockput>
  ip->nlink--;
    91b4:	02e4d783          	lhu	a5,46(s1)
  iupdate(ip);
    91b8:	00048513          	mv	a0,s1
  ip->nlink--;
    91bc:	fff78793          	add	a5,a5,-1
    91c0:	02f49723          	sh	a5,46(s1)
  iupdate(ip);
    91c4:	ffffd097          	auipc	ra,0xffffd
    91c8:	c58080e7          	jalr	-936(ra) # 5e1c <iupdate>
  iunlockput(ip);
    91cc:	00048513          	mv	a0,s1
    91d0:	ffffd097          	auipc	ra,0xffffd
    91d4:	670080e7          	jalr	1648(ra) # 6840 <iunlockput>
  end_op();
    91d8:	ffffe097          	auipc	ra,0xffffe
    91dc:	308080e7          	jalr	776(ra) # 74e0 <end_op>
  return 0;
    91e0:	00000513          	li	a0,0
}
    91e4:	0cc12083          	lw	ra,204(sp)
    91e8:	0c812403          	lw	s0,200(sp)
    91ec:	0c412483          	lw	s1,196(sp)
    91f0:	0c012903          	lw	s2,192(sp)
    91f4:	0bc12983          	lw	s3,188(sp)
    91f8:	0d010113          	add	sp,sp,208
    91fc:	00008067          	ret
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    9200:	0304a703          	lw	a4,48(s1)
    9204:	02000793          	li	a5,32
    9208:	f4e7fee3          	bgeu	a5,a4,9164 <sys_unlink+0xc4>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    920c:	02000993          	li	s3,32
    9210:	0100006f          	j	9220 <sys_unlink+0x180>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    9214:	0304a783          	lw	a5,48(s1)
    9218:	01098993          	add	s3,s3,16 # fffff010 <end+0xfffdaffc>
    921c:	f4f9f4e3          	bgeu	s3,a5,9164 <sys_unlink+0xc4>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    9220:	01000713          	li	a4,16
    9224:	00098693          	mv	a3,s3
    9228:	f5040613          	add	a2,s0,-176
    922c:	00000593          	li	a1,0
    9230:	00048513          	mv	a0,s1
    9234:	ffffd097          	auipc	ra,0xffffd
    9238:	6cc080e7          	jalr	1740(ra) # 6900 <readi>
    923c:	01000793          	li	a5,16
    9240:	06f51063          	bne	a0,a5,92a0 <sys_unlink+0x200>
    if(de.inum != 0)
    9244:	f5045783          	lhu	a5,-176(s0)
    9248:	fc0786e3          	beqz	a5,9214 <sys_unlink+0x174>
    iunlockput(ip);
    924c:	00048513          	mv	a0,s1
    9250:	ffffd097          	auipc	ra,0xffffd
    9254:	5f0080e7          	jalr	1520(ra) # 6840 <iunlockput>
  iunlockput(dp);
    9258:	00090513          	mv	a0,s2
    925c:	ffffd097          	auipc	ra,0xffffd
    9260:	5e4080e7          	jalr	1508(ra) # 6840 <iunlockput>
  end_op();
    9264:	ffffe097          	auipc	ra,0xffffe
    9268:	27c080e7          	jalr	636(ra) # 74e0 <end_op>
    return -1;
    926c:	fff00513          	li	a0,-1
    9270:	f75ff06f          	j	91e4 <sys_unlink+0x144>
    end_op();
    9274:	ffffe097          	auipc	ra,0xffffe
    9278:	26c080e7          	jalr	620(ra) # 74e0 <end_op>
    return -1;
    927c:	fff00513          	li	a0,-1
    9280:	f65ff06f          	j	91e4 <sys_unlink+0x144>
    dp->nlink--;
    9284:	02e95783          	lhu	a5,46(s2)
    iupdate(dp);
    9288:	00090513          	mv	a0,s2
    dp->nlink--;
    928c:	fff78793          	add	a5,a5,-1
    9290:	02f91723          	sh	a5,46(s2)
    iupdate(dp);
    9294:	ffffd097          	auipc	ra,0xffffd
    9298:	b88080e7          	jalr	-1144(ra) # 5e1c <iupdate>
    929c:	f0dff06f          	j	91a8 <sys_unlink+0x108>
      panic("isdirempty: readi");
    92a0:	00002517          	auipc	a0,0x2
    92a4:	54050513          	add	a0,a0,1344 # b7e0 <main+0x6b0>
    92a8:	ffff7097          	auipc	ra,0xffff7
    92ac:	42c080e7          	jalr	1068(ra) # 6d4 <panic>
    panic("unlink: nlink < 1");
    92b0:	00002517          	auipc	a0,0x2
    92b4:	51c50513          	add	a0,a0,1308 # b7cc <main+0x69c>
    92b8:	ffff7097          	auipc	ra,0xffff7
    92bc:	41c080e7          	jalr	1052(ra) # 6d4 <panic>
    panic("unlink: writei");
    92c0:	00002517          	auipc	a0,0x2
    92c4:	53450513          	add	a0,a0,1332 # b7f4 <main+0x6c4>
    92c8:	ffff7097          	auipc	ra,0xffff7
    92cc:	40c080e7          	jalr	1036(ra) # 6d4 <panic>

000092d0 <sys_open>:

uint32
sys_open(void)
{
    92d0:	f5010113          	add	sp,sp,-176
    92d4:	0a812423          	sw	s0,168(sp)
    92d8:	0a112623          	sw	ra,172(sp)
    92dc:	0b010413          	add	s0,sp,176
    92e0:	0a912223          	sw	s1,164(sp)
    92e4:	0b212023          	sw	s2,160(sp)
    92e8:	09312e23          	sw	s3,156(sp)
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    92ec:	08000613          	li	a2,128
    92f0:	f6040593          	add	a1,s0,-160
    92f4:	00000513          	li	a0,0
    92f8:	ffffc097          	auipc	ra,0xffffc
    92fc:	c58080e7          	jalr	-936(ra) # 4f50 <argstr>
    9300:	12054263          	bltz	a0,9424 <sys_open+0x154>
    9304:	f5c40593          	add	a1,s0,-164
    9308:	00100513          	li	a0,1
    930c:	ffffc097          	auipc	ra,0xffffc
    9310:	9ac080e7          	jalr	-1620(ra) # 4cb8 <argint>
    9314:	10054863          	bltz	a0,9424 <sys_open+0x154>
    return -1;

  begin_op();
    9318:	ffffe097          	auipc	ra,0xffffe
    931c:	12c080e7          	jalr	300(ra) # 7444 <begin_op>

  if(omode & O_CREATE){
    9320:	f5c42783          	lw	a5,-164(s0)
    9324:	2007f793          	and	a5,a5,512
    9328:	10078263          	beqz	a5,942c <sys_open+0x15c>
    ip = create(path, T_FILE, 0, 0);
    932c:	00000693          	li	a3,0
    9330:	00000613          	li	a2,0
    9334:	00200593          	li	a1,2
    9338:	f6040513          	add	a0,s0,-160
    933c:	fffff097          	auipc	ra,0xfffff
    9340:	5b0080e7          	jalr	1456(ra) # 88ec <create>
    9344:	00050493          	mv	s1,a0
    if(ip == 0){
    9348:	1a050a63          	beqz	a0,94fc <sys_open+0x22c>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    934c:	02851783          	lh	a5,40(a0)
    9350:	00300713          	li	a4,3
    9354:	00e79863          	bne	a5,a4,9364 <sys_open+0x94>
    9358:	02a4d703          	lhu	a4,42(s1)
    935c:	00900793          	li	a5,9
    9360:	0ae7e863          	bltu	a5,a4,9410 <sys_open+0x140>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    9364:	ffffe097          	auipc	ra,0xffffe
    9368:	6d0080e7          	jalr	1744(ra) # 7a34 <filealloc>
    936c:	00050913          	mv	s2,a0
    9370:	0a050063          	beqz	a0,9410 <sys_open+0x140>
  struct proc *p = myproc();
    9374:	ffffa097          	auipc	ra,0xffffa
    9378:	0b0080e7          	jalr	176(ra) # 3424 <myproc>
    if(p->ofile[fd] == 0){
    937c:	06c52703          	lw	a4,108(a0)
  struct proc *p = myproc();
    9380:	00050793          	mv	a5,a0
    if(p->ofile[fd] == 0){
    9384:	0c070e63          	beqz	a4,9460 <sys_open+0x190>
    9388:	07052703          	lw	a4,112(a0)
    938c:	18070063          	beqz	a4,950c <sys_open+0x23c>
    9390:	07452703          	lw	a4,116(a0)
    9394:	18070063          	beqz	a4,9514 <sys_open+0x244>
    9398:	07852703          	lw	a4,120(a0)
    939c:	18070063          	beqz	a4,951c <sys_open+0x24c>
    93a0:	07c52703          	lw	a4,124(a0)
    93a4:	18070063          	beqz	a4,9524 <sys_open+0x254>
    93a8:	08052703          	lw	a4,128(a0)
    93ac:	18070063          	beqz	a4,952c <sys_open+0x25c>
    93b0:	08452703          	lw	a4,132(a0)
    93b4:	18070063          	beqz	a4,9534 <sys_open+0x264>
    93b8:	08852703          	lw	a4,136(a0)
    93bc:	18070063          	beqz	a4,953c <sys_open+0x26c>
    93c0:	08c52703          	lw	a4,140(a0)
    93c4:	18070063          	beqz	a4,9544 <sys_open+0x274>
    93c8:	09052703          	lw	a4,144(a0)
    93cc:	18070063          	beqz	a4,954c <sys_open+0x27c>
    93d0:	09452703          	lw	a4,148(a0)
    93d4:	18070063          	beqz	a4,9554 <sys_open+0x284>
    93d8:	09852703          	lw	a4,152(a0)
    93dc:	10070c63          	beqz	a4,94f4 <sys_open+0x224>
    93e0:	09c52703          	lw	a4,156(a0)
    93e4:	16070c63          	beqz	a4,955c <sys_open+0x28c>
    93e8:	0a052703          	lw	a4,160(a0)
    93ec:	16070c63          	beqz	a4,9564 <sys_open+0x294>
    93f0:	0a452703          	lw	a4,164(a0)
    93f4:	16070c63          	beqz	a4,956c <sys_open+0x29c>
    93f8:	0a852703          	lw	a4,168(a0)
  for(fd = 0; fd < NOFILE; fd++){
    93fc:	00f00993          	li	s3,15
    if(p->ofile[fd] == 0){
    9400:	06070263          	beqz	a4,9464 <sys_open+0x194>
    if(f)
      fileclose(f);
    9404:	00090513          	mv	a0,s2
    9408:	ffffe097          	auipc	ra,0xffffe
    940c:	740080e7          	jalr	1856(ra) # 7b48 <fileclose>
    iunlockput(ip);
    9410:	00048513          	mv	a0,s1
    9414:	ffffd097          	auipc	ra,0xffffd
    9418:	42c080e7          	jalr	1068(ra) # 6840 <iunlockput>
    end_op();
    941c:	ffffe097          	auipc	ra,0xffffe
    9420:	0c4080e7          	jalr	196(ra) # 74e0 <end_op>
    return -1;
    9424:	fff00513          	li	a0,-1
    9428:	0a00006f          	j	94c8 <sys_open+0x1f8>
    if((ip = namei(path)) == 0){
    942c:	f6040513          	add	a0,s0,-160
    9430:	ffffe097          	auipc	ra,0xffffe
    9434:	db4080e7          	jalr	-588(ra) # 71e4 <namei>
    9438:	00050493          	mv	s1,a0
    943c:	0c050063          	beqz	a0,94fc <sys_open+0x22c>
    ilock(ip);
    9440:	ffffd097          	auipc	ra,0xffffd
    9444:	ae4080e7          	jalr	-1308(ra) # 5f24 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    9448:	02849783          	lh	a5,40(s1)
    944c:	00100713          	li	a4,1
    9450:	f0e790e3          	bne	a5,a4,9350 <sys_open+0x80>
    9454:	f5c42783          	lw	a5,-164(s0)
    9458:	f00786e3          	beqz	a5,9364 <sys_open+0x94>
    945c:	fb5ff06f          	j	9410 <sys_open+0x140>
  for(fd = 0; fd < NOFILE; fd++){
    9460:	00000993          	li	s3,0
      p->ofile[fd] = f;
    9464:	01898713          	add	a4,s3,24
    return -1;
  }

  if(ip->type == T_DEVICE){
    9468:	02849683          	lh	a3,40(s1)
      p->ofile[fd] = f;
    946c:	00271713          	sll	a4,a4,0x2
    9470:	00e787b3          	add	a5,a5,a4
    9474:	0127a623          	sw	s2,12(a5)
  if(ip->type == T_DEVICE){
    9478:	00300793          	li	a5,3
    947c:	06f68463          	beq	a3,a5,94e4 <sys_open+0x214>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    f->off = 0;
    9480:	00092a23          	sw	zero,20(s2)
    f->type = FD_INODE;
    9484:	00200713          	li	a4,2
  }
  f->ip = ip;
  f->readable = !(omode & O_WRONLY);
    9488:	f5c42783          	lw	a5,-164(s0)
    948c:	00e92023          	sw	a4,0(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

  iunlock(ip);
    9490:	00048513          	mv	a0,s1
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    9494:	0037f713          	and	a4,a5,3
    9498:	00e03733          	snez	a4,a4
  f->readable = !(omode & O_WRONLY);
    949c:	fff7c793          	not	a5,a5
    94a0:	00871713          	sll	a4,a4,0x8
    94a4:	0017f793          	and	a5,a5,1
    94a8:	00e7e7b3          	or	a5,a5,a4
    94ac:	00f91423          	sh	a5,8(s2)
  f->ip = ip;
    94b0:	00992823          	sw	s1,16(s2)
  iunlock(ip);
    94b4:	ffffd097          	auipc	ra,0xffffd
    94b8:	b64080e7          	jalr	-1180(ra) # 6018 <iunlock>
  end_op();
    94bc:	ffffe097          	auipc	ra,0xffffe
    94c0:	024080e7          	jalr	36(ra) # 74e0 <end_op>

  return fd;
    94c4:	00098513          	mv	a0,s3
}
    94c8:	0ac12083          	lw	ra,172(sp)
    94cc:	0a812403          	lw	s0,168(sp)
    94d0:	0a412483          	lw	s1,164(sp)
    94d4:	0a012903          	lw	s2,160(sp)
    94d8:	09c12983          	lw	s3,156(sp)
    94dc:	0b010113          	add	sp,sp,176
    94e0:	00008067          	ret
    f->major = ip->major;
    94e4:	02a4d783          	lhu	a5,42(s1)
    f->type = FD_DEVICE;
    94e8:	00300713          	li	a4,3
    f->major = ip->major;
    94ec:	00f91c23          	sh	a5,24(s2)
    94f0:	f99ff06f          	j	9488 <sys_open+0x1b8>
  for(fd = 0; fd < NOFILE; fd++){
    94f4:	00b00993          	li	s3,11
    94f8:	f6dff06f          	j	9464 <sys_open+0x194>
      end_op();
    94fc:	ffffe097          	auipc	ra,0xffffe
    9500:	fe4080e7          	jalr	-28(ra) # 74e0 <end_op>
    return -1;
    9504:	fff00513          	li	a0,-1
    9508:	fc1ff06f          	j	94c8 <sys_open+0x1f8>
  for(fd = 0; fd < NOFILE; fd++){
    950c:	00100993          	li	s3,1
    9510:	f55ff06f          	j	9464 <sys_open+0x194>
    9514:	00200993          	li	s3,2
    9518:	f4dff06f          	j	9464 <sys_open+0x194>
    951c:	00300993          	li	s3,3
    9520:	f45ff06f          	j	9464 <sys_open+0x194>
    9524:	00400993          	li	s3,4
    9528:	f3dff06f          	j	9464 <sys_open+0x194>
    952c:	00500993          	li	s3,5
    9530:	f35ff06f          	j	9464 <sys_open+0x194>
    9534:	00600993          	li	s3,6
    9538:	f2dff06f          	j	9464 <sys_open+0x194>
    953c:	00700993          	li	s3,7
    9540:	f25ff06f          	j	9464 <sys_open+0x194>
    9544:	00800993          	li	s3,8
    9548:	f1dff06f          	j	9464 <sys_open+0x194>
    954c:	00900993          	li	s3,9
    9550:	f15ff06f          	j	9464 <sys_open+0x194>
    9554:	00a00993          	li	s3,10
    9558:	f0dff06f          	j	9464 <sys_open+0x194>
    955c:	00c00993          	li	s3,12
    9560:	f05ff06f          	j	9464 <sys_open+0x194>
    9564:	00d00993          	li	s3,13
    9568:	efdff06f          	j	9464 <sys_open+0x194>
    956c:	00e00993          	li	s3,14
    9570:	ef5ff06f          	j	9464 <sys_open+0x194>

00009574 <sys_mkdir>:

uint32
sys_mkdir(void)
{
    9574:	f7010113          	add	sp,sp,-144
    9578:	08812423          	sw	s0,136(sp)
    957c:	08112623          	sw	ra,140(sp)
    9580:	09010413          	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    9584:	ffffe097          	auipc	ra,0xffffe
    9588:	ec0080e7          	jalr	-320(ra) # 7444 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    958c:	08000613          	li	a2,128
    9590:	f7040593          	add	a1,s0,-144
    9594:	00000513          	li	a0,0
    9598:	ffffc097          	auipc	ra,0xffffc
    959c:	9b8080e7          	jalr	-1608(ra) # 4f50 <argstr>
    95a0:	04054263          	bltz	a0,95e4 <sys_mkdir+0x70>
    95a4:	00000693          	li	a3,0
    95a8:	00000613          	li	a2,0
    95ac:	00100593          	li	a1,1
    95b0:	f7040513          	add	a0,s0,-144
    95b4:	fffff097          	auipc	ra,0xfffff
    95b8:	338080e7          	jalr	824(ra) # 88ec <create>
    95bc:	02050463          	beqz	a0,95e4 <sys_mkdir+0x70>
    end_op();
    return -1;
  }
  iunlockput(ip);
    95c0:	ffffd097          	auipc	ra,0xffffd
    95c4:	280080e7          	jalr	640(ra) # 6840 <iunlockput>
  end_op();
    95c8:	ffffe097          	auipc	ra,0xffffe
    95cc:	f18080e7          	jalr	-232(ra) # 74e0 <end_op>
  return 0;
}
    95d0:	08c12083          	lw	ra,140(sp)
    95d4:	08812403          	lw	s0,136(sp)
  return 0;
    95d8:	00000513          	li	a0,0
}
    95dc:	09010113          	add	sp,sp,144
    95e0:	00008067          	ret
    end_op();
    95e4:	ffffe097          	auipc	ra,0xffffe
    95e8:	efc080e7          	jalr	-260(ra) # 74e0 <end_op>
}
    95ec:	08c12083          	lw	ra,140(sp)
    95f0:	08812403          	lw	s0,136(sp)
    return -1;
    95f4:	fff00513          	li	a0,-1
}
    95f8:	09010113          	add	sp,sp,144
    95fc:	00008067          	ret

00009600 <sys_mknod>:

uint32
sys_mknod(void)
{
    9600:	f6010113          	add	sp,sp,-160
    9604:	08812c23          	sw	s0,152(sp)
    9608:	08112e23          	sw	ra,156(sp)
    960c:	0a010413          	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    9610:	ffffe097          	auipc	ra,0xffffe
    9614:	e34080e7          	jalr	-460(ra) # 7444 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    9618:	08000613          	li	a2,128
    961c:	f7040593          	add	a1,s0,-144
    9620:	00000513          	li	a0,0
    9624:	ffffc097          	auipc	ra,0xffffc
    9628:	92c080e7          	jalr	-1748(ra) # 4f50 <argstr>
    962c:	06054663          	bltz	a0,9698 <sys_mknod+0x98>
     argint(1, &major) < 0 ||
    9630:	f6840593          	add	a1,s0,-152
    9634:	00100513          	li	a0,1
    9638:	ffffb097          	auipc	ra,0xffffb
    963c:	680080e7          	jalr	1664(ra) # 4cb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    9640:	04054c63          	bltz	a0,9698 <sys_mknod+0x98>
     argint(2, &minor) < 0 ||
    9644:	f6c40593          	add	a1,s0,-148
    9648:	00200513          	li	a0,2
    964c:	ffffb097          	auipc	ra,0xffffb
    9650:	66c080e7          	jalr	1644(ra) # 4cb8 <argint>
     argint(1, &major) < 0 ||
    9654:	04054263          	bltz	a0,9698 <sys_mknod+0x98>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    9658:	f6c41683          	lh	a3,-148(s0)
    965c:	f6841603          	lh	a2,-152(s0)
    9660:	00300593          	li	a1,3
    9664:	f7040513          	add	a0,s0,-144
    9668:	fffff097          	auipc	ra,0xfffff
    966c:	284080e7          	jalr	644(ra) # 88ec <create>
     argint(2, &minor) < 0 ||
    9670:	02050463          	beqz	a0,9698 <sys_mknod+0x98>
    end_op();
    return -1;
  }
  // uartputc('1');
  iunlockput(ip);
    9674:	ffffd097          	auipc	ra,0xffffd
    9678:	1cc080e7          	jalr	460(ra) # 6840 <iunlockput>
  end_op();
    967c:	ffffe097          	auipc	ra,0xffffe
    9680:	e64080e7          	jalr	-412(ra) # 74e0 <end_op>
  // uartputc('0');
  return 0;
}
    9684:	09c12083          	lw	ra,156(sp)
    9688:	09812403          	lw	s0,152(sp)
  return 0;
    968c:	00000513          	li	a0,0
}
    9690:	0a010113          	add	sp,sp,160
    9694:	00008067          	ret
    end_op();
    9698:	ffffe097          	auipc	ra,0xffffe
    969c:	e48080e7          	jalr	-440(ra) # 74e0 <end_op>
}
    96a0:	09c12083          	lw	ra,156(sp)
    96a4:	09812403          	lw	s0,152(sp)
    return -1;
    96a8:	fff00513          	li	a0,-1
}
    96ac:	0a010113          	add	sp,sp,160
    96b0:	00008067          	ret

000096b4 <sys_chdir>:

uint32
sys_chdir(void)
{
    96b4:	f7010113          	add	sp,sp,-144
    96b8:	08112623          	sw	ra,140(sp)
    96bc:	08812423          	sw	s0,136(sp)
    96c0:	09212023          	sw	s2,128(sp)
    96c4:	09010413          	add	s0,sp,144
    96c8:	08912223          	sw	s1,132(sp)
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    96cc:	ffffa097          	auipc	ra,0xffffa
    96d0:	d58080e7          	jalr	-680(ra) # 3424 <myproc>
    96d4:	00050913          	mv	s2,a0
  
  begin_op();
    96d8:	ffffe097          	auipc	ra,0xffffe
    96dc:	d6c080e7          	jalr	-660(ra) # 7444 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    96e0:	08000613          	li	a2,128
    96e4:	f7040593          	add	a1,s0,-144
    96e8:	00000513          	li	a0,0
    96ec:	ffffc097          	auipc	ra,0xffffc
    96f0:	864080e7          	jalr	-1948(ra) # 4f50 <argstr>
    96f4:	06054a63          	bltz	a0,9768 <sys_chdir+0xb4>
    96f8:	f7040513          	add	a0,s0,-144
    96fc:	ffffe097          	auipc	ra,0xffffe
    9700:	ae8080e7          	jalr	-1304(ra) # 71e4 <namei>
    9704:	00050493          	mv	s1,a0
    9708:	06050063          	beqz	a0,9768 <sys_chdir+0xb4>
    end_op();
    return -1;
  }
  ilock(ip);
    970c:	ffffd097          	auipc	ra,0xffffd
    9710:	818080e7          	jalr	-2024(ra) # 5f24 <ilock>
  if(ip->type != T_DIR){
    9714:	02849703          	lh	a4,40(s1)
    9718:	00100793          	li	a5,1
    iunlockput(ip);
    971c:	00048513          	mv	a0,s1
  if(ip->type != T_DIR){
    9720:	04f71063          	bne	a4,a5,9760 <sys_chdir+0xac>
    end_op();
    return -1;
  }
  iunlock(ip);
    9724:	ffffd097          	auipc	ra,0xffffd
    9728:	8f4080e7          	jalr	-1804(ra) # 6018 <iunlock>
  iput(p->cwd);
    972c:	0ac92503          	lw	a0,172(s2)
    9730:	ffffd097          	auipc	ra,0xffffd
    9734:	954080e7          	jalr	-1708(ra) # 6084 <iput>
  end_op();
    9738:	ffffe097          	auipc	ra,0xffffe
    973c:	da8080e7          	jalr	-600(ra) # 74e0 <end_op>
  p->cwd = ip;
  return 0;
}
    9740:	08c12083          	lw	ra,140(sp)
    9744:	08812403          	lw	s0,136(sp)
  p->cwd = ip;
    9748:	0a992623          	sw	s1,172(s2)
  return 0;
    974c:	00000513          	li	a0,0
}
    9750:	08412483          	lw	s1,132(sp)
    9754:	08012903          	lw	s2,128(sp)
    9758:	09010113          	add	sp,sp,144
    975c:	00008067          	ret
    iunlockput(ip);
    9760:	ffffd097          	auipc	ra,0xffffd
    9764:	0e0080e7          	jalr	224(ra) # 6840 <iunlockput>
    end_op();
    9768:	ffffe097          	auipc	ra,0xffffe
    976c:	d78080e7          	jalr	-648(ra) # 74e0 <end_op>
}
    9770:	08c12083          	lw	ra,140(sp)
    9774:	08812403          	lw	s0,136(sp)
    9778:	08412483          	lw	s1,132(sp)
    977c:	08012903          	lw	s2,128(sp)
    return -1;
    9780:	fff00513          	li	a0,-1
}
    9784:	09010113          	add	sp,sp,144
    9788:	00008067          	ret

0000978c <sys_exec>:

uint32
sys_exec(void)
{
    978c:	ed010113          	add	sp,sp,-304
    9790:	12812423          	sw	s0,296(sp)
    9794:	12112623          	sw	ra,300(sp)
    9798:	13010413          	add	s0,sp,304
    979c:	12912223          	sw	s1,292(sp)
    97a0:	13212023          	sw	s2,288(sp)
    97a4:	11312e23          	sw	s3,284(sp)
    97a8:	11412c23          	sw	s4,280(sp)
    97ac:	11512a23          	sw	s5,276(sp)
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint32 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    97b0:	08000613          	li	a2,128
    97b4:	ee040593          	add	a1,s0,-288
    97b8:	00000513          	li	a0,0
    97bc:	ffffb097          	auipc	ra,0xffffb
    97c0:	794080e7          	jalr	1940(ra) # 4f50 <argstr>
    97c4:	0a054a63          	bltz	a0,9878 <sys_exec+0xec>
    97c8:	ed840593          	add	a1,s0,-296
    97cc:	00100513          	li	a0,1
    97d0:	ffffb097          	auipc	ra,0xffffb
    97d4:	634080e7          	jalr	1588(ra) # 4e04 <argaddr>
    97d8:	0a054063          	bltz	a0,9878 <sys_exec+0xec>
    return -1;
  }
  // printf("exec %s!\n", path);
  memset(argv, 0, sizeof(argv));
    97dc:	08000613          	li	a2,128
    97e0:	00000593          	li	a1,0
    97e4:	f6040513          	add	a0,s0,-160
    97e8:	f6040493          	add	s1,s0,-160
    97ec:	ffff8097          	auipc	ra,0xffff8
    97f0:	e98080e7          	jalr	-360(ra) # 1684 <memset>
    97f4:	00048993          	mv	s3,s1
  for(i=0;; i++){
    97f8:	00000913          	li	s2,0
    if(i >= NELEM(argv)){
    97fc:	02000a93          	li	s5,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint32)*i, (uint32*)&uarg) < 0){
    9800:	ed842503          	lw	a0,-296(s0)
    9804:	00291a13          	sll	s4,s2,0x2
    9808:	edc40593          	add	a1,s0,-292
    980c:	00aa0533          	add	a0,s4,a0
    9810:	ffffb097          	auipc	ra,0xffffb
    9814:	3a4080e7          	jalr	932(ra) # 4bb4 <fetchaddr>
    9818:	04054063          	bltz	a0,9858 <sys_exec+0xcc>
      goto bad;
    }
    if(uarg == 0){
    981c:	edc42783          	lw	a5,-292(s0)
    9820:	08078063          	beqz	a5,98a0 <sys_exec+0x114>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    9824:	ffff8097          	auipc	ra,0xffff8
    9828:	888080e7          	jalr	-1912(ra) # 10ac <kalloc>
    982c:	00a9a023          	sw	a0,0(s3)
    9830:	00050593          	mv	a1,a0
    if(argv[i] == 0)
    9834:	0a050a63          	beqz	a0,98e8 <sys_exec+0x15c>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    9838:	edc42503          	lw	a0,-292(s0)
    983c:	00001637          	lui	a2,0x1
    9840:	ffffb097          	auipc	ra,0xffffb
    9844:	3ec080e7          	jalr	1004(ra) # 4c2c <fetchstr>
    9848:	00054863          	bltz	a0,9858 <sys_exec+0xcc>
  for(i=0;; i++){
    984c:	00190913          	add	s2,s2,1
    if(i >= NELEM(argv)){
    9850:	00498993          	add	s3,s3,4
    9854:	fb5916e3          	bne	s2,s5,9800 <sys_exec+0x74>
    9858:	fe040913          	add	s2,s0,-32
    985c:	0140006f          	j	9870 <sys_exec+0xe4>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    9860:	00448493          	add	s1,s1,4
    kfree(argv[i]);
    9864:	ffff7097          	auipc	ra,0xffff7
    9868:	7c0080e7          	jalr	1984(ra) # 1024 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    986c:	01248663          	beq	s1,s2,9878 <sys_exec+0xec>
    9870:	0004a503          	lw	a0,0(s1)
    9874:	fe0516e3          	bnez	a0,9860 <sys_exec+0xd4>
    return -1;
    9878:	fff00513          	li	a0,-1
  return -1;
}
    987c:	12c12083          	lw	ra,300(sp)
    9880:	12812403          	lw	s0,296(sp)
    9884:	12412483          	lw	s1,292(sp)
    9888:	12012903          	lw	s2,288(sp)
    988c:	11c12983          	lw	s3,284(sp)
    9890:	11812a03          	lw	s4,280(sp)
    9894:	11412a83          	lw	s5,276(sp)
    9898:	13010113          	add	sp,sp,304
    989c:	00008067          	ret
      argv[i] = 0;
    98a0:	fe0a0793          	add	a5,s4,-32
    98a4:	00878a33          	add	s4,a5,s0
  int ret = exec(path, argv);
    98a8:	f6040593          	add	a1,s0,-160
    98ac:	ee040513          	add	a0,s0,-288
      argv[i] = 0;
    98b0:	f80a2023          	sw	zero,-128(s4)
  int ret = exec(path, argv);
    98b4:	fffff097          	auipc	ra,0xfffff
    98b8:	be8080e7          	jalr	-1048(ra) # 849c <exec>
    98bc:	00050913          	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    98c0:	fe040993          	add	s3,s0,-32
    98c4:	0140006f          	j	98d8 <sys_exec+0x14c>
    98c8:	00448493          	add	s1,s1,4
    kfree(argv[i]);
    98cc:	ffff7097          	auipc	ra,0xffff7
    98d0:	758080e7          	jalr	1880(ra) # 1024 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    98d4:	01348663          	beq	s1,s3,98e0 <sys_exec+0x154>
    98d8:	0004a503          	lw	a0,0(s1)
    98dc:	fe0516e3          	bnez	a0,98c8 <sys_exec+0x13c>
  return ret;
    98e0:	00090513          	mv	a0,s2
    98e4:	f99ff06f          	j	987c <sys_exec+0xf0>
      panic("sys_exec kalloc");
    98e8:	00002517          	auipc	a0,0x2
    98ec:	f1c50513          	add	a0,a0,-228 # b804 <main+0x6d4>
    98f0:	ffff7097          	auipc	ra,0xffff7
    98f4:	de4080e7          	jalr	-540(ra) # 6d4 <panic>

000098f8 <sys_pipe>:

uint32
sys_pipe(void)
{
    98f8:	fd010113          	add	sp,sp,-48
    98fc:	02812423          	sw	s0,40(sp)
    9900:	02912223          	sw	s1,36(sp)
    9904:	03010413          	add	s0,sp,48
    9908:	02112623          	sw	ra,44(sp)
    990c:	03212023          	sw	s2,32(sp)
  uint32 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    9910:	ffffa097          	auipc	ra,0xffffa
    9914:	b14080e7          	jalr	-1260(ra) # 3424 <myproc>
    9918:	00050493          	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    991c:	fdc40593          	add	a1,s0,-36
    9920:	00000513          	li	a0,0
    9924:	ffffb097          	auipc	ra,0xffffb
    9928:	4e0080e7          	jalr	1248(ra) # 4e04 <argaddr>
    992c:	0c054863          	bltz	a0,99fc <sys_pipe+0x104>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
    9930:	fe440593          	add	a1,s0,-28
    9934:	fe040513          	add	a0,s0,-32
    9938:	ffffe097          	auipc	ra,0xffffe
    993c:	718080e7          	jalr	1816(ra) # 8050 <pipealloc>
    9940:	0a054e63          	bltz	a0,99fc <sys_pipe+0x104>
    return -1;
  fd0 = -1;
    9944:	fff00793          	li	a5,-1
    9948:	fef42423          	sw	a5,-24(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    994c:	fe042903          	lw	s2,-32(s0)
  struct proc *p = myproc();
    9950:	ffffa097          	auipc	ra,0xffffa
    9954:	ad4080e7          	jalr	-1324(ra) # 3424 <myproc>
    if(p->ofile[fd] == 0){
    9958:	06c52783          	lw	a5,108(a0)
    995c:	0a078e63          	beqz	a5,9a18 <sys_pipe+0x120>
    9960:	07052783          	lw	a5,112(a0)
    9964:	22078a63          	beqz	a5,9b98 <sys_pipe+0x2a0>
    9968:	07452783          	lw	a5,116(a0)
    996c:	22078a63          	beqz	a5,9ba0 <sys_pipe+0x2a8>
    9970:	07852783          	lw	a5,120(a0)
    9974:	22078a63          	beqz	a5,9ba8 <sys_pipe+0x2b0>
    9978:	07c52783          	lw	a5,124(a0)
    997c:	22078a63          	beqz	a5,9bb0 <sys_pipe+0x2b8>
    9980:	08052783          	lw	a5,128(a0)
    9984:	22078a63          	beqz	a5,9bb8 <sys_pipe+0x2c0>
    9988:	08452783          	lw	a5,132(a0)
    998c:	22078e63          	beqz	a5,9bc8 <sys_pipe+0x2d0>
    9990:	08852783          	lw	a5,136(a0)
    9994:	24078263          	beqz	a5,9bd8 <sys_pipe+0x2e0>
    9998:	08c52783          	lw	a5,140(a0)
    999c:	24078263          	beqz	a5,9be0 <sys_pipe+0x2e8>
    99a0:	09052783          	lw	a5,144(a0)
    99a4:	24078663          	beqz	a5,9bf0 <sys_pipe+0x2f8>
    99a8:	09452783          	lw	a5,148(a0)
    99ac:	24078e63          	beqz	a5,9c08 <sys_pipe+0x310>
    99b0:	09852783          	lw	a5,152(a0)
    99b4:	26078263          	beqz	a5,9c18 <sys_pipe+0x320>
    99b8:	09c52783          	lw	a5,156(a0)
    99bc:	26078263          	beqz	a5,9c20 <sys_pipe+0x328>
    99c0:	0a052783          	lw	a5,160(a0)
    99c4:	26078663          	beqz	a5,9c30 <sys_pipe+0x338>
    99c8:	0a452783          	lw	a5,164(a0)
    99cc:	26078e63          	beqz	a5,9c48 <sys_pipe+0x350>
    99d0:	0a852783          	lw	a5,168(a0)
  for(fd = 0; fd < NOFILE; fd++){
    99d4:	00f00713          	li	a4,15
    if(p->ofile[fd] == 0){
    99d8:	04078263          	beqz	a5,9a1c <sys_pipe+0x124>
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    99dc:	fff00793          	li	a5,-1
    99e0:	fef42423          	sw	a5,-24(s0)
    if(fd0 >= 0)
      p->ofile[fd0] = 0;
    fileclose(rf);
    99e4:	fe042503          	lw	a0,-32(s0)
    99e8:	ffffe097          	auipc	ra,0xffffe
    99ec:	160080e7          	jalr	352(ra) # 7b48 <fileclose>
    fileclose(wf);
    99f0:	fe442503          	lw	a0,-28(s0)
    99f4:	ffffe097          	auipc	ra,0xffffe
    99f8:	154080e7          	jalr	340(ra) # 7b48 <fileclose>
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
}
    99fc:	02c12083          	lw	ra,44(sp)
    9a00:	02812403          	lw	s0,40(sp)
    9a04:	02412483          	lw	s1,36(sp)
    9a08:	02012903          	lw	s2,32(sp)
    return -1;
    9a0c:	fff00513          	li	a0,-1
}
    9a10:	03010113          	add	sp,sp,48
    9a14:	00008067          	ret
  for(fd = 0; fd < NOFILE; fd++){
    9a18:	00000713          	li	a4,0
      p->ofile[fd] = f;
    9a1c:	01870793          	add	a5,a4,24
    9a20:	00279793          	sll	a5,a5,0x2
    9a24:	00f507b3          	add	a5,a0,a5
    9a28:	0127a623          	sw	s2,12(a5)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    9a2c:	fee42423          	sw	a4,-24(s0)
    9a30:	fe442903          	lw	s2,-28(s0)
  struct proc *p = myproc();
    9a34:	ffffa097          	auipc	ra,0xffffa
    9a38:	9f0080e7          	jalr	-1552(ra) # 3424 <myproc>
    if(p->ofile[fd] == 0){
    9a3c:	06c52703          	lw	a4,108(a0)
  struct proc *p = myproc();
    9a40:	00050793          	mv	a5,a0
    if(p->ofile[fd] == 0){
    9a44:	16070e63          	beqz	a4,9bc0 <sys_pipe+0x2c8>
    9a48:	07052703          	lw	a4,112(a0)
    9a4c:	18070263          	beqz	a4,9bd0 <sys_pipe+0x2d8>
    9a50:	07452703          	lw	a4,116(a0)
    9a54:	18070a63          	beqz	a4,9be8 <sys_pipe+0x2f0>
    9a58:	07852703          	lw	a4,120(a0)
    9a5c:	18070e63          	beqz	a4,9bf8 <sys_pipe+0x300>
    9a60:	07c52703          	lw	a4,124(a0)
    9a64:	18070e63          	beqz	a4,9c00 <sys_pipe+0x308>
    9a68:	08052703          	lw	a4,128(a0)
    9a6c:	1a070263          	beqz	a4,9c10 <sys_pipe+0x318>
    9a70:	08452703          	lw	a4,132(a0)
    9a74:	1a070a63          	beqz	a4,9c28 <sys_pipe+0x330>
    9a78:	08852703          	lw	a4,136(a0)
    9a7c:	1a070e63          	beqz	a4,9c38 <sys_pipe+0x340>
    9a80:	08c52703          	lw	a4,140(a0)
    9a84:	1a070e63          	beqz	a4,9c40 <sys_pipe+0x348>
    9a88:	09052703          	lw	a4,144(a0)
    9a8c:	1c070263          	beqz	a4,9c50 <sys_pipe+0x358>
    9a90:	09452703          	lw	a4,148(a0)
    9a94:	04070863          	beqz	a4,9ae4 <sys_pipe+0x1ec>
    9a98:	09852703          	lw	a4,152(a0)
    9a9c:	1a070e63          	beqz	a4,9c58 <sys_pipe+0x360>
    9aa0:	09c52703          	lw	a4,156(a0)
    9aa4:	1a070e63          	beqz	a4,9c60 <sys_pipe+0x368>
    9aa8:	0a052703          	lw	a4,160(a0)
    9aac:	1a070e63          	beqz	a4,9c68 <sys_pipe+0x370>
    9ab0:	0a452703          	lw	a4,164(a0)
    9ab4:	1a070e63          	beqz	a4,9c70 <sys_pipe+0x378>
    9ab8:	0a852703          	lw	a4,168(a0)
    9abc:	1a070e63          	beqz	a4,9c78 <sys_pipe+0x380>
    if(fd0 >= 0)
    9ac0:	fe842783          	lw	a5,-24(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    9ac4:	fff00713          	li	a4,-1
    9ac8:	fee42623          	sw	a4,-20(s0)
    if(fd0 >= 0)
    9acc:	f007cce3          	bltz	a5,99e4 <sys_pipe+0xec>
      p->ofile[fd0] = 0;
    9ad0:	01878793          	add	a5,a5,24
    9ad4:	00279793          	sll	a5,a5,0x2
    9ad8:	00f487b3          	add	a5,s1,a5
    9adc:	0007a623          	sw	zero,12(a5)
    9ae0:	f05ff06f          	j	99e4 <sys_pipe+0xec>
  for(fd = 0; fd < NOFILE; fd++){
    9ae4:	00a00813          	li	a6,10
      p->ofile[fd] = f;
    9ae8:	01880713          	add	a4,a6,24
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    9aec:	02c4a503          	lw	a0,44(s1)
      p->ofile[fd] = f;
    9af0:	00271713          	sll	a4,a4,0x2
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    9af4:	fdc42583          	lw	a1,-36(s0)
      p->ofile[fd] = f;
    9af8:	00e787b3          	add	a5,a5,a4
    9afc:	0127a623          	sw	s2,12(a5)
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    9b00:	00400693          	li	a3,4
    9b04:	fe840613          	add	a2,s0,-24
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    9b08:	ff042623          	sw	a6,-20(s0)
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    9b0c:	ffff9097          	auipc	ra,0xffff9
    9b10:	23c080e7          	jalr	572(ra) # 2d48 <copyout>
    9b14:	04054063          	bltz	a0,9b54 <sys_pipe+0x25c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    9b18:	fdc42583          	lw	a1,-36(s0)
    9b1c:	02c4a503          	lw	a0,44(s1)
    9b20:	00400693          	li	a3,4
    9b24:	fec40613          	add	a2,s0,-20
    9b28:	00458593          	add	a1,a1,4
    9b2c:	ffff9097          	auipc	ra,0xffff9
    9b30:	21c080e7          	jalr	540(ra) # 2d48 <copyout>
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    9b34:	02054063          	bltz	a0,9b54 <sys_pipe+0x25c>
}
    9b38:	02c12083          	lw	ra,44(sp)
    9b3c:	02812403          	lw	s0,40(sp)
    9b40:	02412483          	lw	s1,36(sp)
    9b44:	02012903          	lw	s2,32(sp)
  return 0;
    9b48:	00000513          	li	a0,0
}
    9b4c:	03010113          	add	sp,sp,48
    9b50:	00008067          	ret
    p->ofile[fd0] = 0;
    9b54:	fe842703          	lw	a4,-24(s0)
    p->ofile[fd1] = 0;
    9b58:	fec42783          	lw	a5,-20(s0)
    fileclose(rf);
    9b5c:	fe042503          	lw	a0,-32(s0)
    p->ofile[fd0] = 0;
    9b60:	01870713          	add	a4,a4,24
    9b64:	00271713          	sll	a4,a4,0x2
    p->ofile[fd1] = 0;
    9b68:	01878793          	add	a5,a5,24
    p->ofile[fd0] = 0;
    9b6c:	00e48733          	add	a4,s1,a4
    p->ofile[fd1] = 0;
    9b70:	00279793          	sll	a5,a5,0x2
    p->ofile[fd0] = 0;
    9b74:	00072623          	sw	zero,12(a4)
    p->ofile[fd1] = 0;
    9b78:	00f487b3          	add	a5,s1,a5
    9b7c:	0007a623          	sw	zero,12(a5)
    fileclose(rf);
    9b80:	ffffe097          	auipc	ra,0xffffe
    9b84:	fc8080e7          	jalr	-56(ra) # 7b48 <fileclose>
    fileclose(wf);
    9b88:	fe442503          	lw	a0,-28(s0)
    9b8c:	ffffe097          	auipc	ra,0xffffe
    9b90:	fbc080e7          	jalr	-68(ra) # 7b48 <fileclose>
    return -1;
    9b94:	e69ff06f          	j	99fc <sys_pipe+0x104>
  for(fd = 0; fd < NOFILE; fd++){
    9b98:	00100713          	li	a4,1
    9b9c:	e81ff06f          	j	9a1c <sys_pipe+0x124>
    9ba0:	00200713          	li	a4,2
    9ba4:	e79ff06f          	j	9a1c <sys_pipe+0x124>
    9ba8:	00300713          	li	a4,3
    9bac:	e71ff06f          	j	9a1c <sys_pipe+0x124>
    9bb0:	00400713          	li	a4,4
    9bb4:	e69ff06f          	j	9a1c <sys_pipe+0x124>
    9bb8:	00500713          	li	a4,5
    9bbc:	e61ff06f          	j	9a1c <sys_pipe+0x124>
    9bc0:	00000813          	li	a6,0
    9bc4:	f25ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9bc8:	00600713          	li	a4,6
    9bcc:	e51ff06f          	j	9a1c <sys_pipe+0x124>
    9bd0:	00100813          	li	a6,1
    9bd4:	f15ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9bd8:	00700713          	li	a4,7
    9bdc:	e41ff06f          	j	9a1c <sys_pipe+0x124>
    9be0:	00800713          	li	a4,8
    9be4:	e39ff06f          	j	9a1c <sys_pipe+0x124>
    9be8:	00200813          	li	a6,2
    9bec:	efdff06f          	j	9ae8 <sys_pipe+0x1f0>
    9bf0:	00900713          	li	a4,9
    9bf4:	e29ff06f          	j	9a1c <sys_pipe+0x124>
    9bf8:	00300813          	li	a6,3
    9bfc:	eedff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c00:	00400813          	li	a6,4
    9c04:	ee5ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c08:	00a00713          	li	a4,10
    9c0c:	e11ff06f          	j	9a1c <sys_pipe+0x124>
    9c10:	00500813          	li	a6,5
    9c14:	ed5ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c18:	00b00713          	li	a4,11
    9c1c:	e01ff06f          	j	9a1c <sys_pipe+0x124>
    9c20:	00c00713          	li	a4,12
    9c24:	df9ff06f          	j	9a1c <sys_pipe+0x124>
    9c28:	00600813          	li	a6,6
    9c2c:	ebdff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c30:	00d00713          	li	a4,13
    9c34:	de9ff06f          	j	9a1c <sys_pipe+0x124>
    9c38:	00700813          	li	a6,7
    9c3c:	eadff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c40:	00800813          	li	a6,8
    9c44:	ea5ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c48:	00e00713          	li	a4,14
    9c4c:	dd1ff06f          	j	9a1c <sys_pipe+0x124>
    9c50:	00900813          	li	a6,9
    9c54:	e95ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c58:	00b00813          	li	a6,11
    9c5c:	e8dff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c60:	00c00813          	li	a6,12
    9c64:	e85ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c68:	00d00813          	li	a6,13
    9c6c:	e7dff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c70:	00e00813          	li	a6,14
    9c74:	e75ff06f          	j	9ae8 <sys_pipe+0x1f0>
    9c78:	00f00813          	li	a6,15
    9c7c:	e6dff06f          	j	9ae8 <sys_pipe+0x1f0>

00009c80 <kernelvec>:
    9c80:	f8010113          	add	sp,sp,-128
    9c84:	00112023          	sw	ra,0(sp)
    9c88:	00212223          	sw	sp,4(sp)
    9c8c:	00312423          	sw	gp,8(sp)
    9c90:	00412623          	sw	tp,12(sp)
    9c94:	00512823          	sw	t0,16(sp)
    9c98:	00612a23          	sw	t1,20(sp)
    9c9c:	00712c23          	sw	t2,24(sp)
    9ca0:	00812e23          	sw	s0,28(sp)
    9ca4:	02912023          	sw	s1,32(sp)
    9ca8:	02a12223          	sw	a0,36(sp)
    9cac:	02b12423          	sw	a1,40(sp)
    9cb0:	02c12623          	sw	a2,44(sp)
    9cb4:	02d12823          	sw	a3,48(sp)
    9cb8:	02e12a23          	sw	a4,52(sp)
    9cbc:	02f12c23          	sw	a5,56(sp)
    9cc0:	03012e23          	sw	a6,60(sp)
    9cc4:	05112023          	sw	a7,64(sp)
    9cc8:	05212223          	sw	s2,68(sp)
    9ccc:	05312423          	sw	s3,72(sp)
    9cd0:	05412623          	sw	s4,76(sp)
    9cd4:	05512823          	sw	s5,80(sp)
    9cd8:	05612a23          	sw	s6,84(sp)
    9cdc:	05712c23          	sw	s7,88(sp)
    9ce0:	05812e23          	sw	s8,92(sp)
    9ce4:	07912023          	sw	s9,96(sp)
    9ce8:	07a12223          	sw	s10,100(sp)
    9cec:	07b12423          	sw	s11,104(sp)
    9cf0:	07c12623          	sw	t3,108(sp)
    9cf4:	07d12823          	sw	t4,112(sp)
    9cf8:	07e12a23          	sw	t5,116(sp)
    9cfc:	07f12c23          	sw	t6,120(sp)
    9d00:	c3dfa0ef          	jal	493c <kerneltrap>
    9d04:	00012083          	lw	ra,0(sp)
    9d08:	00412103          	lw	sp,4(sp)
    9d0c:	00812183          	lw	gp,8(sp)
    9d10:	01012283          	lw	t0,16(sp)
    9d14:	01412303          	lw	t1,20(sp)
    9d18:	01812383          	lw	t2,24(sp)
    9d1c:	01c12403          	lw	s0,28(sp)
    9d20:	02012483          	lw	s1,32(sp)
    9d24:	02412503          	lw	a0,36(sp)
    9d28:	02812583          	lw	a1,40(sp)
    9d2c:	02c12603          	lw	a2,44(sp)
    9d30:	03012683          	lw	a3,48(sp)
    9d34:	03412703          	lw	a4,52(sp)
    9d38:	03812783          	lw	a5,56(sp)
    9d3c:	03c12803          	lw	a6,60(sp)
    9d40:	04012883          	lw	a7,64(sp)
    9d44:	04412903          	lw	s2,68(sp)
    9d48:	04812983          	lw	s3,72(sp)
    9d4c:	04c12a03          	lw	s4,76(sp)
    9d50:	05012a83          	lw	s5,80(sp)
    9d54:	05412b03          	lw	s6,84(sp)
    9d58:	05812b83          	lw	s7,88(sp)
    9d5c:	05c12c03          	lw	s8,92(sp)
    9d60:	06012c83          	lw	s9,96(sp)
    9d64:	06412d03          	lw	s10,100(sp)
    9d68:	06812d83          	lw	s11,104(sp)
    9d6c:	06c12e03          	lw	t3,108(sp)
    9d70:	07012e83          	lw	t4,112(sp)
    9d74:	07412f03          	lw	t5,116(sp)
    9d78:	07812f83          	lw	t6,120(sp)
    9d7c:	08010113          	add	sp,sp,128
    9d80:	10200073          	sret
    9d84:	00000013          	nop
    9d88:	00000013          	nop
    9d8c:	00000013          	nop

00009d90 <timervec>:
    9d90:	34051573          	csrrw	a0,mscratch,a0
    9d94:	00b52023          	sw	a1,0(a0)
    9d98:	00c52223          	sw	a2,4(a0)
    9d9c:	00d52423          	sw	a3,8(a0)
    9da0:	00e52623          	sw	a4,12(a0)
    9da4:	01052583          	lw	a1,16(a0)
    9da8:	01452603          	lw	a2,20(a0)
    9dac:	0005a683          	lw	a3,0(a1)
    9db0:	0045a703          	lw	a4,4(a1)
    9db4:	00c686b3          	add	a3,a3,a2
    9db8:	00c6b633          	sltu	a2,a3,a2
    9dbc:	00c70733          	add	a4,a4,a2
    9dc0:	fff00613          	li	a2,-1
    9dc4:	00c5a023          	sw	a2,0(a1)
    9dc8:	00e5a223          	sw	a4,4(a1)
    9dcc:	00d5a023          	sw	a3,0(a1)
    9dd0:	00200593          	li	a1,2
    9dd4:	14459073          	csrw	sip,a1
    9dd8:	00c52703          	lw	a4,12(a0)
    9ddc:	00852683          	lw	a3,8(a0)
    9de0:	00452603          	lw	a2,4(a0)
    9de4:	00052583          	lw	a1,0(a0)
    9de8:	34051573          	csrrw	a0,mscratch,a0
    9dec:	30200073          	mret

00009df0 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    9df0:	ff010113          	add	sp,sp,-16
    9df4:	00812423          	sw	s0,8(sp)
    9df8:	00112623          	sw	ra,12(sp)
    9dfc:	01010413          	add	s0,sp,16
  panic("plicinit");
    9e00:	00002517          	auipc	a0,0x2
    9e04:	a1450513          	add	a0,a0,-1516 # b814 <main+0x6e4>
    9e08:	ffff7097          	auipc	ra,0xffff7
    9e0c:	8cc080e7          	jalr	-1844(ra) # 6d4 <panic>

00009e10 <plicinithart>:
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
}

void
plicinithart(void)
{
    9e10:	ff010113          	add	sp,sp,-16
    9e14:	00812423          	sw	s0,8(sp)
    9e18:	00112623          	sw	ra,12(sp)
    9e1c:	01010413          	add	s0,sp,16
  panic("plicinithart");
    9e20:	00002517          	auipc	a0,0x2
    9e24:	a0050513          	add	a0,a0,-1536 # b820 <main+0x6f0>
    9e28:	ffff7097          	auipc	ra,0xffff7
    9e2c:	8ac080e7          	jalr	-1876(ra) # 6d4 <panic>

00009e30 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint32
plic_pending(void)
{
    9e30:	ff010113          	add	sp,sp,-16
    9e34:	00812423          	sw	s0,8(sp)
    9e38:	00112623          	sw	ra,12(sp)
    9e3c:	01010413          	add	s0,sp,16
  panic("plic_pending");
    9e40:	00002517          	auipc	a0,0x2
    9e44:	9f050513          	add	a0,a0,-1552 # b830 <main+0x700>
    9e48:	ffff7097          	auipc	ra,0xffff7
    9e4c:	88c080e7          	jalr	-1908(ra) # 6d4 <panic>

00009e50 <plic_claim>:
}

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    9e50:	ff010113          	add	sp,sp,-16
    9e54:	00812423          	sw	s0,8(sp)
    9e58:	00112623          	sw	ra,12(sp)
    9e5c:	01010413          	add	s0,sp,16
  panic("plic_claim");
    9e60:	00002517          	auipc	a0,0x2
    9e64:	9e050513          	add	a0,a0,-1568 # b840 <main+0x710>
    9e68:	ffff7097          	auipc	ra,0xffff7
    9e6c:	86c080e7          	jalr	-1940(ra) # 6d4 <panic>

00009e70 <plic_complete>:
}

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    9e70:	ff010113          	add	sp,sp,-16
    9e74:	00812423          	sw	s0,8(sp)
    9e78:	00112623          	sw	ra,12(sp)
    9e7c:	01010413          	add	s0,sp,16
  panic("plic_complete");
    9e80:	00002517          	auipc	a0,0x2
    9e84:	9cc50513          	add	a0,a0,-1588 # b84c <main+0x71c>
    9e88:	ffff7097          	auipc	ra,0xffff7
    9e8c:	84c080e7          	jalr	-1972(ra) # 6d4 <panic>

00009e90 <virtio_disk_init>:
}  __attribute__ ((aligned (PGSIZE)))  disk;
  

void
virtio_disk_init(void)
{
    9e90:	ff010113          	add	sp,sp,-16
    9e94:	00812423          	sw	s0,8(sp)
    9e98:	00112623          	sw	ra,12(sp)
    9e9c:	01010413          	add	s0,sp,16
  initlock(&disk.vdisk_lock, "virtio_disk");
    9ea0:	00002597          	auipc	a1,0x2
    9ea4:	9bc58593          	add	a1,a1,-1604 # b85c <main+0x72c>
    9ea8:	00019517          	auipc	a0,0x19
    9eac:	16050513          	add	a0,a0,352 # 23008 <disk+0x8>
    9eb0:	ffff7097          	auipc	ra,0xffff7
    9eb4:	29c080e7          	jalr	668(ra) # 114c <initlock>
  disk.free = 1;
}
    9eb8:	00c12083          	lw	ra,12(sp)
    9ebc:	00812403          	lw	s0,8(sp)
  disk.free = 1;
    9ec0:	00100793          	li	a5,1
    9ec4:	00019717          	auipc	a4,0x19
    9ec8:	14f70823          	sb	a5,336(a4) # 23014 <disk+0x14>
}
    9ecc:	01010113          	add	sp,sp,16
    9ed0:	00008067          	ret

00009ed4 <virtio_disk_rw>:
#define EDISK_WEN   ((volatile unsigned int*)0xf8000008)
#define EDISK_DATA  ((volatile unsigned int*)0xf8000010)

void
virtio_disk_rw(struct buf *b, int write)
{
    9ed4:	fe010113          	add	sp,sp,-32
    9ed8:	00812c23          	sw	s0,24(sp)
    9edc:	00912a23          	sw	s1,20(sp)
    9ee0:	01212823          	sw	s2,16(sp)
    9ee4:	01312623          	sw	s3,12(sp)
    9ee8:	01412423          	sw	s4,8(sp)
    9eec:	01512223          	sw	s5,4(sp)
    9ef0:	00112e23          	sw	ra,28(sp)
    9ef4:	02010413          	add	s0,sp,32
    9ef8:	00050493          	mv	s1,a0
  // printf("virtio_disk_rw\n");
  acquire(&disk.vdisk_lock);
    9efc:	00019517          	auipc	a0,0x19
    9f00:	10c50513          	add	a0,a0,268 # 23008 <disk+0x8>
  if (disk.free) {
    9f04:	00019997          	auipc	s3,0x19
    9f08:	0fc98993          	add	s3,s3,252 # 23000 <disk>
{
    9f0c:	00058913          	mv	s2,a1
  acquire(&disk.vdisk_lock);
    9f10:	ffff7097          	auipc	ra,0xffff7
    9f14:	260080e7          	jalr	608(ra) # 1170 <acquire>
  if (disk.free) {
    9f18:	0149c783          	lbu	a5,20(s3)
  while (1) {
    if ((idx = alloc_desc()) >= 0) {
      break;
    }
    // 奪えなかったらfreeで寝る
    sleep(&disk.free, &disk.vdisk_lock);
    9f1c:	00019a97          	auipc	s5,0x19
    9f20:	0eca8a93          	add	s5,s5,236 # 23008 <disk+0x8>
    9f24:	00019a17          	auipc	s4,0x19
    9f28:	0f0a0a13          	add	s4,s4,240 # 23014 <disk+0x14>
  if (disk.free) {
    9f2c:	0c078c63          	beqz	a5,a004 <virtio_disk_rw+0x130>
    disk.free = 0;
    9f30:	00019797          	auipc	a5,0x19
    9f34:	0e078223          	sb	zero,228(a5) # 23014 <disk+0x14>
  }

  b->disk = 1;

  unsigned int offset = b->blockno * BSIZE;
    9f38:	00c4a703          	lw	a4,12(s1)
  b->disk = 1;
    9f3c:	00100793          	li	a5,1
    9f40:	00f4a223          	sw	a5,4(s1)

  // printf("BSIZE : %p\n", BSIZE);
  // printf("offset: %p\n", offset);

  *EDISK_WEN = write ? 1 : 0;
    9f44:	012036b3          	snez	a3,s2
    9f48:	f80007b7          	lui	a5,0xf8000
  unsigned int offset = b->blockno * BSIZE;
    9f4c:	00a71713          	sll	a4,a4,0xa
  *EDISK_WEN = write ? 1 : 0;
    9f50:	00d7a423          	sw	a3,8(a5) # f8000008 <end+0xf7fdbff4>
    9f54:	40970733          	sub	a4,a4,s1
    9f58:	03848793          	add	a5,s1,56
    9f5c:	43848593          	add	a1,s1,1080
  for (int i = 0; i < BSIZE / 4; i++) {
    int addr = offset + i * 4;
    9f60:	fc870713          	add	a4,a4,-56
    *EDISK_ADDR = addr;
    9f64:	f80006b7          	lui	a3,0xf8000
    9f68:	06091463          	bnez	s2,9fd0 <virtio_disk_rw+0xfc>
    int addr = offset + i * 4;
    9f6c:	00f70633          	add	a2,a4,a5
    *EDISK_ADDR = addr;
    9f70:	00c6a023          	sw	a2,0(a3) # f8000000 <end+0xf7fdbfec>
    if (write) {
      *EDISK_DATA = ((unsigned int*)b->data)[i];
      // printf("disk_rw(%d): %p <= %p... %d\n", write, addr, ((unsigned int*)b->data)[i], i);
    } else {
      ((unsigned int*)b->data)[i] = *EDISK_DATA;
    9f74:	0106a603          	lw	a2,16(a3)
  for (int i = 0; i < BSIZE / 4; i++) {
    9f78:	00478793          	add	a5,a5,4
      ((unsigned int*)b->data)[i] = *EDISK_DATA;
    9f7c:	fec7ae23          	sw	a2,-4(a5)
  for (int i = 0; i < BSIZE / 4; i++) {
    9f80:	feb796e3          	bne	a5,a1,9f6c <virtio_disk_rw+0x98>
      // printf("disk_rw(%d): %p => %p... %d\n", write, addr, ((unsigned int*)b->data)[i], i);
    }
  }

  b->disk = 0;
    9f84:	0004a223          	sw	zero,4(s1)
  wakeup(&disk.free);
    9f88:	00019517          	auipc	a0,0x19
    9f8c:	08c50513          	add	a0,a0,140 # 23014 <disk+0x14>
  disk.free = 1;
    9f90:	00100793          	li	a5,1
    9f94:	00f98a23          	sb	a5,20(s3)
  wakeup(&disk.free);
    9f98:	ffffa097          	auipc	ra,0xffffa
    9f9c:	1c0080e7          	jalr	448(ra) # 4158 <wakeup>
  free_desc(idx);

  release(&disk.vdisk_lock);
}
    9fa0:	01812403          	lw	s0,24(sp)
    9fa4:	01c12083          	lw	ra,28(sp)
    9fa8:	01412483          	lw	s1,20(sp)
    9fac:	01012903          	lw	s2,16(sp)
    9fb0:	00c12983          	lw	s3,12(sp)
    9fb4:	00812a03          	lw	s4,8(sp)
    9fb8:	00412a83          	lw	s5,4(sp)
  release(&disk.vdisk_lock);
    9fbc:	00019517          	auipc	a0,0x19
    9fc0:	04c50513          	add	a0,a0,76 # 23008 <disk+0x8>
}
    9fc4:	02010113          	add	sp,sp,32
  release(&disk.vdisk_lock);
    9fc8:	ffff7317          	auipc	t1,0xffff7
    9fcc:	33430067          	jr	820(t1) # 12fc <release>
    int addr = offset + i * 4;
    9fd0:	00f70633          	add	a2,a4,a5
    *EDISK_ADDR = addr;
    9fd4:	00c6a023          	sw	a2,0(a3)
      *EDISK_DATA = ((unsigned int*)b->data)[i];
    9fd8:	0007a603          	lw	a2,0(a5)
  for (int i = 0; i < BSIZE / 4; i++) {
    9fdc:	00478793          	add	a5,a5,4
      *EDISK_DATA = ((unsigned int*)b->data)[i];
    9fe0:	00c6a823          	sw	a2,16(a3)
  for (int i = 0; i < BSIZE / 4; i++) {
    9fe4:	fab780e3          	beq	a5,a1,9f84 <virtio_disk_rw+0xb0>
    int addr = offset + i * 4;
    9fe8:	00f70633          	add	a2,a4,a5
    *EDISK_ADDR = addr;
    9fec:	00c6a023          	sw	a2,0(a3)
      *EDISK_DATA = ((unsigned int*)b->data)[i];
    9ff0:	0007a603          	lw	a2,0(a5)
  for (int i = 0; i < BSIZE / 4; i++) {
    9ff4:	00478793          	add	a5,a5,4
      *EDISK_DATA = ((unsigned int*)b->data)[i];
    9ff8:	00c6a823          	sw	a2,16(a3)
  for (int i = 0; i < BSIZE / 4; i++) {
    9ffc:	fcb79ae3          	bne	a5,a1,9fd0 <virtio_disk_rw+0xfc>
    a000:	f85ff06f          	j	9f84 <virtio_disk_rw+0xb0>
    sleep(&disk.free, &disk.vdisk_lock);
    a004:	000a8593          	mv	a1,s5
    a008:	000a0513          	mv	a0,s4
    a00c:	ffffa097          	auipc	ra,0xffffa
    a010:	060080e7          	jalr	96(ra) # 406c <sleep>
  if (disk.free) {
    a014:	0149c783          	lbu	a5,20(s3)
    a018:	f0079ce3          	bnez	a5,9f30 <virtio_disk_rw+0x5c>
    a01c:	fe9ff06f          	j	a004 <virtio_disk_rw+0x130>

0000a020 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    a020:	ff010113          	add	sp,sp,-16
    a024:	00812423          	sw	s0,8(sp)
    a028:	00112623          	sw	ra,12(sp)
    a02c:	01010413          	add	s0,sp,16
  panic("virtio_disk_intr");
    a030:	00002517          	auipc	a0,0x2
    a034:	83850513          	add	a0,a0,-1992 # b868 <main+0x738>
    a038:	ffff6097          	auipc	ra,0xffff6
    a03c:	69c080e7          	jalr	1692(ra) # 6d4 <panic>
	...

0000b000 <trampoline>:
    b000:	14051573          	csrrw	a0,sscratch,a0
    b004:	00152a23          	sw	ra,20(a0)
    b008:	00252c23          	sw	sp,24(a0)
    b00c:	00352e23          	sw	gp,28(a0)
    b010:	02452023          	sw	tp,32(a0)
    b014:	02552223          	sw	t0,36(a0)
    b018:	02652423          	sw	t1,40(a0)
    b01c:	02752623          	sw	t2,44(a0)
    b020:	02852823          	sw	s0,48(a0)
    b024:	02952a23          	sw	s1,52(a0)
    b028:	02b52e23          	sw	a1,60(a0)
    b02c:	04c52023          	sw	a2,64(a0)
    b030:	04d52223          	sw	a3,68(a0)
    b034:	04e52423          	sw	a4,72(a0)
    b038:	04f52623          	sw	a5,76(a0)
    b03c:	05052823          	sw	a6,80(a0)
    b040:	05152a23          	sw	a7,84(a0)
    b044:	05252c23          	sw	s2,88(a0)
    b048:	05352e23          	sw	s3,92(a0)
    b04c:	07452023          	sw	s4,96(a0)
    b050:	07552223          	sw	s5,100(a0)
    b054:	07652423          	sw	s6,104(a0)
    b058:	07752623          	sw	s7,108(a0)
    b05c:	07852823          	sw	s8,112(a0)
    b060:	07952a23          	sw	s9,116(a0)
    b064:	07a52c23          	sw	s10,120(a0)
    b068:	07b52e23          	sw	s11,124(a0)
    b06c:	09c52023          	sw	t3,128(a0)
    b070:	09d52223          	sw	t4,132(a0)
    b074:	09e52423          	sw	t5,136(a0)
    b078:	09f52623          	sw	t6,140(a0)
    b07c:	140022f3          	csrr	t0,sscratch
    b080:	02552c23          	sw	t0,56(a0)
    b084:	00452103          	lw	sp,4(a0)
    b088:	01052203          	lw	tp,16(a0)
    b08c:	00852283          	lw	t0,8(a0)
    b090:	00052303          	lw	t1,0(a0)
    b094:	18031073          	csrw	satp,t1
    b098:	12000073          	sfence.vma
    b09c:	00028067          	jr	t0

0000b0a0 <userret>:
    b0a0:	18059073          	csrw	satp,a1
    b0a4:	12000073          	sfence.vma
    b0a8:	03852283          	lw	t0,56(a0)
    b0ac:	14029073          	csrw	sscratch,t0
    b0b0:	01452083          	lw	ra,20(a0)
    b0b4:	01852103          	lw	sp,24(a0)
    b0b8:	01c52183          	lw	gp,28(a0)
    b0bc:	02052203          	lw	tp,32(a0)
    b0c0:	02452283          	lw	t0,36(a0)
    b0c4:	02852303          	lw	t1,40(a0)
    b0c8:	02c52383          	lw	t2,44(a0)
    b0cc:	03052403          	lw	s0,48(a0)
    b0d0:	03452483          	lw	s1,52(a0)
    b0d4:	03c52583          	lw	a1,60(a0)
    b0d8:	04052603          	lw	a2,64(a0)
    b0dc:	04452683          	lw	a3,68(a0)
    b0e0:	04852703          	lw	a4,72(a0)
    b0e4:	04c52783          	lw	a5,76(a0)
    b0e8:	05052803          	lw	a6,80(a0)
    b0ec:	05452883          	lw	a7,84(a0)
    b0f0:	05852903          	lw	s2,88(a0)
    b0f4:	05c52983          	lw	s3,92(a0)
    b0f8:	06052a03          	lw	s4,96(a0)
    b0fc:	06452a83          	lw	s5,100(a0)
    b100:	06852b03          	lw	s6,104(a0)
    b104:	06c52b83          	lw	s7,108(a0)
    b108:	07052c03          	lw	s8,112(a0)
    b10c:	07452c83          	lw	s9,116(a0)
    b110:	07852d03          	lw	s10,120(a0)
    b114:	07c52d83          	lw	s11,124(a0)
    b118:	08052e03          	lw	t3,128(a0)
    b11c:	08452e83          	lw	t4,132(a0)
    b120:	08852f03          	lw	t5,136(a0)
    b124:	08c52f83          	lw	t6,140(a0)
    b128:	14051573          	csrrw	a0,sscratch,a0
    b12c:	10200073          	sret

Disassembly of section .text.startup:

0000b130 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    b130:	ff010113          	add	sp,sp,-16
    b134:	00812423          	sw	s0,8(sp)
    b138:	00912223          	sw	s1,4(sp)
    b13c:	00112623          	sw	ra,12(sp)
    b140:	01010413          	add	s0,sp,16
  if(cpuid() == 0){
    b144:	ffff8097          	auipc	ra,0xffff8
    b148:	290080e7          	jalr	656(ra) # 33d4 <cpuid>
    b14c:	00019497          	auipc	s1,0x19
    b150:	eb848493          	add	s1,s1,-328 # 24004 <started>
    b154:	04050663          	beqz	a0,b1a0 <main+0x70>
    userinit();      // first user process
    // printf("k");
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    b158:	0004a783          	lw	a5,0(s1)
    b15c:	fe078ee3          	beqz	a5,b158 <main+0x28>
      ;
    __sync_synchronize();
    b160:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    b164:	ffff8097          	auipc	ra,0xffff8
    b168:	270080e7          	jalr	624(ra) # 33d4 <cpuid>
    b16c:	00050593          	mv	a1,a0
    b170:	00000517          	auipc	a0,0x0
    b174:	15850513          	add	a0,a0,344 # b2c8 <main+0x198>
    b178:	ffff5097          	auipc	ra,0xffff5
    b17c:	5b8080e7          	jalr	1464(ra) # 730 <printf>
    kvminithart();    // turn on paging
    b180:	ffff7097          	auipc	ra,0xffff7
    b184:	0c4080e7          	jalr	196(ra) # 2244 <kvminithart>
    trapinithart();   // install kernel trap vector
    b188:	ffff9097          	auipc	ra,0xffff9
    b18c:	6d8080e7          	jalr	1752(ra) # 4860 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    b190:	fffff097          	auipc	ra,0xfffff
    b194:	c80080e7          	jalr	-896(ra) # 9e10 <plicinithart>
  }

  scheduler();        
    b198:	ffff9097          	auipc	ra,0xffff9
    b19c:	83c080e7          	jalr	-1988(ra) # 39d4 <scheduler>
    consoleinit();
    b1a0:	ffff5097          	auipc	ra,0xffff5
    b1a4:	4d4080e7          	jalr	1236(ra) # 674 <consoleinit>
    printfinit();
    b1a8:	ffff6097          	auipc	ra,0xffff6
    b1ac:	b78080e7          	jalr	-1160(ra) # d20 <printfinit>
    printf("\n");
    b1b0:	00000517          	auipc	a0,0x0
    b1b4:	12850513          	add	a0,a0,296 # b2d8 <main+0x1a8>
    b1b8:	ffff5097          	auipc	ra,0xffff5
    b1bc:	578080e7          	jalr	1400(ra) # 730 <printf>
    printf("xv6 kernel is booting\n");
    b1c0:	00000517          	auipc	a0,0x0
    b1c4:	0f050513          	add	a0,a0,240 # b2b0 <main+0x180>
    b1c8:	ffff5097          	auipc	ra,0xffff5
    b1cc:	568080e7          	jalr	1384(ra) # 730 <printf>
    printf("\n");
    b1d0:	00000517          	auipc	a0,0x0
    b1d4:	10850513          	add	a0,a0,264 # b2d8 <main+0x1a8>
    b1d8:	ffff5097          	auipc	ra,0xffff5
    b1dc:	558080e7          	jalr	1368(ra) # 730 <printf>
    kinit();         // physical page allocator
    b1e0:	ffff6097          	auipc	ra,0xffff6
    b1e4:	c64080e7          	jalr	-924(ra) # e44 <kinit>
    kvminit();       // create kernel page table
    b1e8:	ffff7097          	auipc	ra,0xffff7
    b1ec:	358080e7          	jalr	856(ra) # 2540 <kvminit>
    kvminithart();   // turn on paging
    b1f0:	ffff7097          	auipc	ra,0xffff7
    b1f4:	054080e7          	jalr	84(ra) # 2244 <kvminithart>
    procinit();      // process table
    b1f8:	ffff8097          	auipc	ra,0xffff8
    b1fc:	0d8080e7          	jalr	216(ra) # 32d0 <procinit>
    trapinit();      // trap vectors
    b200:	ffff9097          	auipc	ra,0xffff9
    b204:	634080e7          	jalr	1588(ra) # 4834 <trapinit>
    trapinithart();  // install kernel trap vector
    b208:	ffff9097          	auipc	ra,0xffff9
    b20c:	658080e7          	jalr	1624(ra) # 4860 <trapinithart>
    binit();         // buffer cache
    b210:	ffffa097          	auipc	ra,0xffffa
    b214:	1e0080e7          	jalr	480(ra) # 53f0 <binit>
    iinit();         // inode cache
    b218:	ffffb097          	auipc	ra,0xffffb
    b21c:	9bc080e7          	jalr	-1604(ra) # 5bd4 <iinit>
    fileinit();      // file table
    b220:	ffffc097          	auipc	ra,0xffffc
    b224:	7e8080e7          	jalr	2024(ra) # 7a08 <fileinit>
    virtio_disk_init(); // emulated hard disk
    b228:	fffff097          	auipc	ra,0xfffff
    b22c:	c68080e7          	jalr	-920(ra) # 9e90 <virtio_disk_init>
    userinit();      // first user process
    b230:	ffff8097          	auipc	ra,0xffff8
    b234:	3c0080e7          	jalr	960(ra) # 35f0 <userinit>
    __sync_synchronize();
    b238:	0ff0000f          	fence
    started = 1;
    b23c:	00100793          	li	a5,1
    b240:	00f4a023          	sw	a5,0(s1)
    b244:	f55ff06f          	j	b198 <main+0x68>
