
kernel/kernel:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <_entry>:
       0:	0000a117          	auipc	sp,0xa
       4:	40010113          	add	sp,sp,1024 # a400 <stack0>
       8:	00001537          	lui	a0,0x1
       c:	f14025f3          	csrr	a1,mhartid
      10:	00158593          	add	a1,a1,1
      14:	02b50533          	mul	a0,a0,a1
      18:	00a10133          	add	sp,sp,a0
      1c:	098000ef          	jal	b4 <start>

00000020 <junk>:
      20:	0000006f          	j	20 <junk>

00000024 <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
      24:	ff010113          	add	sp,sp,-16
      28:	00812623          	sw	s0,12(sp)
      2c:	01010413          	add	s0,sp,16
// which hart (core) is this?
static inline uint32
r_mhartid()
{
  uint32 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
      30:	f1402673          	csrr	a2,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  uint32 interval = 100000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
      34:	00160793          	add	a5,a2,1
      38:	00379793          	sll	a5,a5,0x3
      3c:	f00006b7          	lui	a3,0xf0000
      40:	00d787b3          	add	a5,a5,a3
      44:	0006a703          	lw	a4,0(a3) # f0000000 <end+0xeffdefec>
      48:	0046a503          	lw	a0,4(a3)
      4c:	000186b7          	lui	a3,0x18
      50:	6a068693          	add	a3,a3,1696 # 186a0 <bcache+0x2fb0>
      54:	00d705b3          	add	a1,a4,a3
      58:	00e5b733          	sltu	a4,a1,a4
      5c:	00a70733          	add	a4,a4,a0
      60:	00b7a023          	sw	a1,0(a5)
      64:	00e7a223          	sw	a4,4(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint32 *scratch = &mscratch0[32 * id];
      68:	00761613          	sll	a2,a2,0x7
      6c:	0000a717          	auipc	a4,0xa
      70:	f9470713          	add	a4,a4,-108 # a000 <mscratch0>
      74:	00c70733          	add	a4,a4,a2
  scratch[4] = CLINT_MTIMECMP(id);
      78:	00f72823          	sw	a5,16(a4)
  scratch[5] = interval;
      7c:	00d72a23          	sw	a3,20(a4)
}

static inline void 
w_mscratch(uint32 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
      80:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
      84:	00008797          	auipc	a5,0x8
      88:	80c78793          	add	a5,a5,-2036 # 7890 <timervec>
      8c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
      90:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint32)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
      94:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
      98:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
      9c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  #define MIE_SEIE (1 << 9)
  w_mie(r_mie() | MIE_MTIE | MIE_SEIE);
      a0:	2807e793          	or	a5,a5,640
  asm volatile("csrw mie, %0" : : "r" (x));
      a4:	30479073          	csrw	mie,a5
}
      a8:	00c12403          	lw	s0,12(sp)
      ac:	01010113          	add	sp,sp,16
      b0:	00008067          	ret

000000b4 <start>:
{
      b4:	ff010113          	add	sp,sp,-16
      b8:	00112623          	sw	ra,12(sp)
      bc:	00812423          	sw	s0,8(sp)
      c0:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
      c4:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
      c8:	ffffe737          	lui	a4,0xffffe
      cc:	7ff70713          	add	a4,a4,2047 # ffffe7ff <end+0xfffdd7eb>
      d0:	00e7f7b3          	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
      d4:	00001737          	lui	a4,0x1
      d8:	80070713          	add	a4,a4,-2048 # 800 <printf+0x118>
      dc:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
      e0:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
      e4:	00001797          	auipc	a5,0x1
      e8:	fe078793          	add	a5,a5,-32 # 10c4 <main>
      ec:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
      f0:	00000793          	li	a5,0
      f4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
      f8:	000107b7          	lui	a5,0x10
      fc:	fff78793          	add	a5,a5,-1 # ffff <stack0+0x5bff>
     100:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
     104:	30379073          	csrw	mideleg,a5
  timerinit();
     108:	00000097          	auipc	ra,0x0
     10c:	f1c080e7          	jalr	-228(ra) # 24 <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
     110:	f14027f3          	csrr	a5,mhartid
}

static inline void 
w_tp(uint32 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
     114:	00078213          	mv	tp,a5
  asm volatile("mret");
     118:	30200073          	mret
}
     11c:	00c12083          	lw	ra,12(sp)
     120:	00812403          	lw	s0,8(sp)
     124:	01010113          	add	sp,sp,16
     128:	00008067          	ret

0000012c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint32 dst, int n)
{
     12c:	fc010113          	add	sp,sp,-64
     130:	02112e23          	sw	ra,60(sp)
     134:	02812c23          	sw	s0,56(sp)
     138:	02912a23          	sw	s1,52(sp)
     13c:	03212823          	sw	s2,48(sp)
     140:	03312623          	sw	s3,44(sp)
     144:	03412423          	sw	s4,40(sp)
     148:	03512223          	sw	s5,36(sp)
     14c:	03612023          	sw	s6,32(sp)
     150:	01712e23          	sw	s7,28(sp)
     154:	04010413          	add	s0,sp,64
     158:	00050b13          	mv	s6,a0
     15c:	00058a93          	mv	s5,a1
     160:	00060993          	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
     164:	00060a13          	mv	s4,a2
  acquire(&cons.lock);
     168:	00012517          	auipc	a0,0x12
     16c:	29850513          	add	a0,a0,664 # 12400 <cons>
     170:	00001097          	auipc	ra,0x1
     174:	c34080e7          	jalr	-972(ra) # da4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
     178:	00012497          	auipc	s1,0x12
     17c:	28848493          	add	s1,s1,648 # 12400 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
     180:	00012917          	auipc	s2,0x12
     184:	30c90913          	add	s2,s2,780 # 1248c <cons+0x8c>
  while(n > 0){
     188:	09305c63          	blez	s3,220 <consoleread+0xf4>
    while(cons.r == cons.w){
     18c:	08c4a783          	lw	a5,140(s1)
     190:	0904a703          	lw	a4,144(s1)
     194:	02e79863          	bne	a5,a4,1c4 <consoleread+0x98>
      if(myproc()->killed){
     198:	00002097          	auipc	ra,0x2
     19c:	f38080e7          	jalr	-200(ra) # 20d0 <myproc>
     1a0:	01852783          	lw	a5,24(a0)
     1a4:	08079a63          	bnez	a5,238 <consoleread+0x10c>
      sleep(&cons.r, &cons.lock);
     1a8:	00048593          	mv	a1,s1
     1ac:	00090513          	mv	a0,s2
     1b0:	00003097          	auipc	ra,0x3
     1b4:	964080e7          	jalr	-1692(ra) # 2b14 <sleep>
    while(cons.r == cons.w){
     1b8:	08c4a783          	lw	a5,140(s1)
     1bc:	0904a703          	lw	a4,144(s1)
     1c0:	fce78ce3          	beq	a5,a4,198 <consoleread+0x6c>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];
     1c4:	00012717          	auipc	a4,0x12
     1c8:	23c70713          	add	a4,a4,572 # 12400 <cons>
     1cc:	00178693          	add	a3,a5,1
     1d0:	08d72623          	sw	a3,140(a4)
     1d4:	07f7f693          	and	a3,a5,127
     1d8:	00d70733          	add	a4,a4,a3
     1dc:	00c74703          	lbu	a4,12(a4)
     1e0:	00070b93          	mv	s7,a4

    if(c == C('D')){  // end-of-file
     1e4:	00400693          	li	a3,4
     1e8:	08d70863          	beq	a4,a3,278 <consoleread+0x14c>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
     1ec:	fce407a3          	sb	a4,-49(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
     1f0:	015a05b3          	add	a1,s4,s5
     1f4:	00100693          	li	a3,1
     1f8:	fcf40613          	add	a2,s0,-49
     1fc:	413585b3          	sub	a1,a1,s3
     200:	000b0513          	mv	a0,s6
     204:	00003097          	auipc	ra,0x3
     208:	c74080e7          	jalr	-908(ra) # 2e78 <either_copyout>
     20c:	fff00793          	li	a5,-1
     210:	00f50863          	beq	a0,a5,220 <consoleread+0xf4>
      break;

    dst++;
    --n;
     214:	fff98993          	add	s3,s3,-1

    if(c == '\n'){
     218:	00a00793          	li	a5,10
     21c:	f6fb96e3          	bne	s7,a5,188 <consoleread+0x5c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
     220:	00012517          	auipc	a0,0x12
     224:	1e050513          	add	a0,a0,480 # 12400 <cons>
     228:	00001097          	auipc	ra,0x1
     22c:	bf0080e7          	jalr	-1040(ra) # e18 <release>

  return target - n;
     230:	413a0533          	sub	a0,s4,s3
     234:	0180006f          	j	24c <consoleread+0x120>
        release(&cons.lock);
     238:	00012517          	auipc	a0,0x12
     23c:	1c850513          	add	a0,a0,456 # 12400 <cons>
     240:	00001097          	auipc	ra,0x1
     244:	bd8080e7          	jalr	-1064(ra) # e18 <release>
        return -1;
     248:	fff00513          	li	a0,-1
}
     24c:	03c12083          	lw	ra,60(sp)
     250:	03812403          	lw	s0,56(sp)
     254:	03412483          	lw	s1,52(sp)
     258:	03012903          	lw	s2,48(sp)
     25c:	02c12983          	lw	s3,44(sp)
     260:	02812a03          	lw	s4,40(sp)
     264:	02412a83          	lw	s5,36(sp)
     268:	02012b03          	lw	s6,32(sp)
     26c:	01c12b83          	lw	s7,28(sp)
     270:	04010113          	add	sp,sp,64
     274:	00008067          	ret
      if(n < target){
     278:	fb49f4e3          	bgeu	s3,s4,220 <consoleread+0xf4>
        cons.r--;
     27c:	00012717          	auipc	a4,0x12
     280:	20f72823          	sw	a5,528(a4) # 1248c <cons+0x8c>
     284:	f9dff06f          	j	220 <consoleread+0xf4>

00000288 <consputc>:
  if(panicked){
     288:	00021797          	auipc	a5,0x21
     28c:	d787a783          	lw	a5,-648(a5) # 21000 <panicked>
     290:	00078463          	beqz	a5,298 <consputc+0x10>
    for(;;)
     294:	0000006f          	j	294 <consputc+0xc>
{
     298:	ff010113          	add	sp,sp,-16
     29c:	00112623          	sw	ra,12(sp)
     2a0:	00812423          	sw	s0,8(sp)
     2a4:	01010413          	add	s0,sp,16
  if(c == BACKSPACE){
     2a8:	10000793          	li	a5,256
     2ac:	00f50e63          	beq	a0,a5,2c8 <consputc+0x40>
    uartputc(c);
     2b0:	00000097          	auipc	ra,0x0
     2b4:	6f8080e7          	jalr	1784(ra) # 9a8 <uartputc>
}
     2b8:	00c12083          	lw	ra,12(sp)
     2bc:	00812403          	lw	s0,8(sp)
     2c0:	01010113          	add	sp,sp,16
     2c4:	00008067          	ret
    uartputc('\b'); uartputc(' '); uartputc('\b');
     2c8:	00800513          	li	a0,8
     2cc:	00000097          	auipc	ra,0x0
     2d0:	6dc080e7          	jalr	1756(ra) # 9a8 <uartputc>
     2d4:	02000513          	li	a0,32
     2d8:	00000097          	auipc	ra,0x0
     2dc:	6d0080e7          	jalr	1744(ra) # 9a8 <uartputc>
     2e0:	00800513          	li	a0,8
     2e4:	00000097          	auipc	ra,0x0
     2e8:	6c4080e7          	jalr	1732(ra) # 9a8 <uartputc>
     2ec:	fcdff06f          	j	2b8 <consputc+0x30>

000002f0 <consolewrite>:
{
     2f0:	fd010113          	add	sp,sp,-48
     2f4:	02112623          	sw	ra,44(sp)
     2f8:	02812423          	sw	s0,40(sp)
     2fc:	02912223          	sw	s1,36(sp)
     300:	03212023          	sw	s2,32(sp)
     304:	01312e23          	sw	s3,28(sp)
     308:	01412c23          	sw	s4,24(sp)
     30c:	01512a23          	sw	s5,20(sp)
     310:	03010413          	add	s0,sp,48
     314:	00050913          	mv	s2,a0
     318:	00058493          	mv	s1,a1
     31c:	00060a93          	mv	s5,a2
  acquire(&cons.lock);
     320:	00012517          	auipc	a0,0x12
     324:	0e050513          	add	a0,a0,224 # 12400 <cons>
     328:	00001097          	auipc	ra,0x1
     32c:	a7c080e7          	jalr	-1412(ra) # da4 <acquire>
  for(i = 0; i < n; i++){
     330:	03505e63          	blez	s5,36c <consolewrite+0x7c>
     334:	009a8a33          	add	s4,s5,s1
    if(either_copyin(&c, user_src, src+i, 1) == -1)
     338:	fff00993          	li	s3,-1
     33c:	00100693          	li	a3,1
     340:	00048613          	mv	a2,s1
     344:	00090593          	mv	a1,s2
     348:	fdf40513          	add	a0,s0,-33
     34c:	00003097          	auipc	ra,0x3
     350:	bbc080e7          	jalr	-1092(ra) # 2f08 <either_copyin>
     354:	01350c63          	beq	a0,s3,36c <consolewrite+0x7c>
    consputc(c);
     358:	fdf44503          	lbu	a0,-33(s0)
     35c:	00000097          	auipc	ra,0x0
     360:	f2c080e7          	jalr	-212(ra) # 288 <consputc>
  for(i = 0; i < n; i++){
     364:	00148493          	add	s1,s1,1
     368:	fd449ae3          	bne	s1,s4,33c <consolewrite+0x4c>
  release(&cons.lock);
     36c:	00012517          	auipc	a0,0x12
     370:	09450513          	add	a0,a0,148 # 12400 <cons>
     374:	00001097          	auipc	ra,0x1
     378:	aa4080e7          	jalr	-1372(ra) # e18 <release>
}
     37c:	000a8513          	mv	a0,s5
     380:	02c12083          	lw	ra,44(sp)
     384:	02812403          	lw	s0,40(sp)
     388:	02412483          	lw	s1,36(sp)
     38c:	02012903          	lw	s2,32(sp)
     390:	01c12983          	lw	s3,28(sp)
     394:	01812a03          	lw	s4,24(sp)
     398:	01412a83          	lw	s5,20(sp)
     39c:	03010113          	add	sp,sp,48
     3a0:	00008067          	ret

000003a4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
     3a4:	ff010113          	add	sp,sp,-16
     3a8:	00112623          	sw	ra,12(sp)
     3ac:	00812423          	sw	s0,8(sp)
     3b0:	00912223          	sw	s1,4(sp)
     3b4:	01212023          	sw	s2,0(sp)
     3b8:	01010413          	add	s0,sp,16
     3bc:	00050493          	mv	s1,a0
  acquire(&cons.lock);
     3c0:	00012517          	auipc	a0,0x12
     3c4:	04050513          	add	a0,a0,64 # 12400 <cons>
     3c8:	00001097          	auipc	ra,0x1
     3cc:	9dc080e7          	jalr	-1572(ra) # da4 <acquire>

  switch(c){
     3d0:	01500793          	li	a5,21
     3d4:	0cf48463          	beq	s1,a5,49c <consoleintr+0xf8>
     3d8:	0497c263          	blt	a5,s1,41c <consoleintr+0x78>
     3dc:	00800793          	li	a5,8
     3e0:	10f48863          	beq	s1,a5,4f0 <consoleintr+0x14c>
     3e4:	01000793          	li	a5,16
     3e8:	12f49c63          	bne	s1,a5,520 <consoleintr+0x17c>
  case C('P'):  // Print process list.
    procdump();
     3ec:	00003097          	auipc	ra,0x3
     3f0:	bac080e7          	jalr	-1108(ra) # 2f98 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
     3f4:	00012517          	auipc	a0,0x12
     3f8:	00c50513          	add	a0,a0,12 # 12400 <cons>
     3fc:	00001097          	auipc	ra,0x1
     400:	a1c080e7          	jalr	-1508(ra) # e18 <release>
}
     404:	00c12083          	lw	ra,12(sp)
     408:	00812403          	lw	s0,8(sp)
     40c:	00412483          	lw	s1,4(sp)
     410:	00012903          	lw	s2,0(sp)
     414:	01010113          	add	sp,sp,16
     418:	00008067          	ret
  switch(c){
     41c:	07f00793          	li	a5,127
     420:	0cf48863          	beq	s1,a5,4f0 <consoleintr+0x14c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
     424:	00012717          	auipc	a4,0x12
     428:	fdc70713          	add	a4,a4,-36 # 12400 <cons>
     42c:	09472783          	lw	a5,148(a4)
     430:	08c72703          	lw	a4,140(a4)
     434:	40e787b3          	sub	a5,a5,a4
     438:	07f00713          	li	a4,127
     43c:	faf76ce3          	bltu	a4,a5,3f4 <consoleintr+0x50>
      c = (c == '\r') ? '\n' : c;
     440:	00d00793          	li	a5,13
     444:	0ef48263          	beq	s1,a5,528 <consoleintr+0x184>
      consputc(c);
     448:	00048513          	mv	a0,s1
     44c:	00000097          	auipc	ra,0x0
     450:	e3c080e7          	jalr	-452(ra) # 288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
     454:	00012797          	auipc	a5,0x12
     458:	fac78793          	add	a5,a5,-84 # 12400 <cons>
     45c:	0947a703          	lw	a4,148(a5)
     460:	00170693          	add	a3,a4,1
     464:	08d7aa23          	sw	a3,148(a5)
     468:	07f77713          	and	a4,a4,127
     46c:	00e787b3          	add	a5,a5,a4
     470:	00978623          	sb	s1,12(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
     474:	00a00793          	li	a5,10
     478:	0ef48063          	beq	s1,a5,558 <consoleintr+0x1b4>
     47c:	00400793          	li	a5,4
     480:	0cf48c63          	beq	s1,a5,558 <consoleintr+0x1b4>
     484:	00012797          	auipc	a5,0x12
     488:	0087a783          	lw	a5,8(a5) # 1248c <cons+0x8c>
     48c:	08078793          	add	a5,a5,128
     490:	f6f692e3          	bne	a3,a5,3f4 <consoleintr+0x50>
      cons.buf[cons.e++ % INPUT_BUF] = c;
     494:	00078693          	mv	a3,a5
     498:	0c00006f          	j	558 <consoleintr+0x1b4>
    while(cons.e != cons.w &&
     49c:	00012717          	auipc	a4,0x12
     4a0:	f6470713          	add	a4,a4,-156 # 12400 <cons>
     4a4:	09472783          	lw	a5,148(a4)
     4a8:	09072703          	lw	a4,144(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
     4ac:	00012497          	auipc	s1,0x12
     4b0:	f5448493          	add	s1,s1,-172 # 12400 <cons>
    while(cons.e != cons.w &&
     4b4:	00a00913          	li	s2,10
     4b8:	f2e78ee3          	beq	a5,a4,3f4 <consoleintr+0x50>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
     4bc:	fff78793          	add	a5,a5,-1
     4c0:	07f7f713          	and	a4,a5,127
     4c4:	00e48733          	add	a4,s1,a4
    while(cons.e != cons.w &&
     4c8:	00c74703          	lbu	a4,12(a4)
     4cc:	f32704e3          	beq	a4,s2,3f4 <consoleintr+0x50>
      cons.e--;
     4d0:	08f4aa23          	sw	a5,148(s1)
      consputc(BACKSPACE);
     4d4:	10000513          	li	a0,256
     4d8:	00000097          	auipc	ra,0x0
     4dc:	db0080e7          	jalr	-592(ra) # 288 <consputc>
    while(cons.e != cons.w &&
     4e0:	0944a783          	lw	a5,148(s1)
     4e4:	0904a703          	lw	a4,144(s1)
     4e8:	fce79ae3          	bne	a5,a4,4bc <consoleintr+0x118>
     4ec:	f09ff06f          	j	3f4 <consoleintr+0x50>
    if(cons.e != cons.w){
     4f0:	00012717          	auipc	a4,0x12
     4f4:	f1070713          	add	a4,a4,-240 # 12400 <cons>
     4f8:	09472783          	lw	a5,148(a4)
     4fc:	09072703          	lw	a4,144(a4)
     500:	eee78ae3          	beq	a5,a4,3f4 <consoleintr+0x50>
      cons.e--;
     504:	fff78793          	add	a5,a5,-1
     508:	00012717          	auipc	a4,0x12
     50c:	f8f72623          	sw	a5,-116(a4) # 12494 <cons+0x94>
      consputc(BACKSPACE);
     510:	10000513          	li	a0,256
     514:	00000097          	auipc	ra,0x0
     518:	d74080e7          	jalr	-652(ra) # 288 <consputc>
     51c:	ed9ff06f          	j	3f4 <consoleintr+0x50>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
     520:	ec048ae3          	beqz	s1,3f4 <consoleintr+0x50>
     524:	f01ff06f          	j	424 <consoleintr+0x80>
      consputc(c);
     528:	00a00513          	li	a0,10
     52c:	00000097          	auipc	ra,0x0
     530:	d5c080e7          	jalr	-676(ra) # 288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
     534:	00012797          	auipc	a5,0x12
     538:	ecc78793          	add	a5,a5,-308 # 12400 <cons>
     53c:	0947a703          	lw	a4,148(a5)
     540:	00170693          	add	a3,a4,1
     544:	08d7aa23          	sw	a3,148(a5)
     548:	07f77713          	and	a4,a4,127
     54c:	00e787b3          	add	a5,a5,a4
     550:	00a00713          	li	a4,10
     554:	00e78623          	sb	a4,12(a5)
        cons.w = cons.e;
     558:	00012797          	auipc	a5,0x12
     55c:	f2d7ac23          	sw	a3,-200(a5) # 12490 <cons+0x90>
        wakeup(&cons.r);
     560:	00012517          	auipc	a0,0x12
     564:	f2c50513          	add	a0,a0,-212 # 1248c <cons+0x8c>
     568:	00002097          	auipc	ra,0x2
     56c:	7c8080e7          	jalr	1992(ra) # 2d30 <wakeup>
     570:	e85ff06f          	j	3f4 <consoleintr+0x50>

00000574 <consoleinit>:

void
consoleinit(void)
{
     574:	ff010113          	add	sp,sp,-16
     578:	00112623          	sw	ra,12(sp)
     57c:	00812423          	sw	s0,8(sp)
     580:	01010413          	add	s0,sp,16
  initlock(&cons.lock, "cons");
     584:	00008597          	auipc	a1,0x8
     588:	bac58593          	add	a1,a1,-1108 # 8130 <userret+0x90>
     58c:	00012517          	auipc	a0,0x12
     590:	e7450513          	add	a0,a0,-396 # 12400 <cons>
     594:	00000097          	auipc	ra,0x0
     598:	68c080e7          	jalr	1676(ra) # c20 <initlock>

  uartinit();
     59c:	00000097          	auipc	ra,0x0
     5a0:	3f4080e7          	jalr	1012(ra) # 990 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
     5a4:	0001f797          	auipc	a5,0x1f
     5a8:	93878793          	add	a5,a5,-1736 # 1eedc <devsw>
     5ac:	00000717          	auipc	a4,0x0
     5b0:	b8070713          	add	a4,a4,-1152 # 12c <consoleread>
     5b4:	00e7a423          	sw	a4,8(a5)
  devsw[CONSOLE].write = consolewrite;
     5b8:	00000717          	auipc	a4,0x0
     5bc:	d3870713          	add	a4,a4,-712 # 2f0 <consolewrite>
     5c0:	00e7a623          	sw	a4,12(a5)
}
     5c4:	00c12083          	lw	ra,12(sp)
     5c8:	00812403          	lw	s0,8(sp)
     5cc:	01010113          	add	sp,sp,16
     5d0:	00008067          	ret

000005d4 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
     5d4:	fe010113          	add	sp,sp,-32
     5d8:	00112e23          	sw	ra,28(sp)
     5dc:	00812c23          	sw	s0,24(sp)
     5e0:	00912a23          	sw	s1,20(sp)
     5e4:	01212823          	sw	s2,16(sp)
     5e8:	02010413          	add	s0,sp,32
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
     5ec:	00060463          	beqz	a2,5f4 <printint+0x20>
     5f0:	08054863          	bltz	a0,680 <printint+0xac>
    x = -xx;
  else
    x = xx;
     5f4:	00000893          	li	a7,0

  i = 0;
     5f8:	00000793          	li	a5,0
  do {
    buf[i++] = digits[x % base];
     5fc:	00008617          	auipc	a2,0x8
     600:	16860613          	add	a2,a2,360 # 8764 <digits>
     604:	00078813          	mv	a6,a5
     608:	00178793          	add	a5,a5,1
     60c:	fe040713          	add	a4,s0,-32
     610:	00f706b3          	add	a3,a4,a5
     614:	02b57733          	remu	a4,a0,a1
     618:	00e60733          	add	a4,a2,a4
     61c:	00074703          	lbu	a4,0(a4)
     620:	fee68fa3          	sb	a4,-1(a3)
  } while((x /= base) != 0);
     624:	00050713          	mv	a4,a0
     628:	02b55533          	divu	a0,a0,a1
     62c:	fcb77ce3          	bgeu	a4,a1,604 <printint+0x30>

  if(sign)
     630:	00088c63          	beqz	a7,648 <printint+0x74>
    buf[i++] = '-';
     634:	ff078793          	add	a5,a5,-16
     638:	008787b3          	add	a5,a5,s0
     63c:	02d00713          	li	a4,45
     640:	fee78823          	sb	a4,-16(a5)
     644:	00280793          	add	a5,a6,2

  while(--i >= 0)
     648:	02f05063          	blez	a5,668 <printint+0x94>
     64c:	fe040913          	add	s2,s0,-32
     650:	00f904b3          	add	s1,s2,a5
    consputc(buf[i]);
     654:	fff4c503          	lbu	a0,-1(s1)
     658:	00000097          	auipc	ra,0x0
     65c:	c30080e7          	jalr	-976(ra) # 288 <consputc>
  while(--i >= 0)
     660:	fff48493          	add	s1,s1,-1
     664:	ff2498e3          	bne	s1,s2,654 <printint+0x80>
}
     668:	01c12083          	lw	ra,28(sp)
     66c:	01812403          	lw	s0,24(sp)
     670:	01412483          	lw	s1,20(sp)
     674:	01012903          	lw	s2,16(sp)
     678:	02010113          	add	sp,sp,32
     67c:	00008067          	ret
    x = -xx;
     680:	40a00533          	neg	a0,a0
  if(sign && (sign = xx < 0))
     684:	00100893          	li	a7,1
    x = -xx;
     688:	f71ff06f          	j	5f8 <printint+0x24>

0000068c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
     68c:	ff010113          	add	sp,sp,-16
     690:	00112623          	sw	ra,12(sp)
     694:	00812423          	sw	s0,8(sp)
     698:	00912223          	sw	s1,4(sp)
     69c:	01010413          	add	s0,sp,16
     6a0:	00050493          	mv	s1,a0
  pr.locking = 0;
     6a4:	00012797          	auipc	a5,0x12
     6a8:	e007a023          	sw	zero,-512(a5) # 124a4 <pr+0xc>
  printf("panic: ");
     6ac:	00008517          	auipc	a0,0x8
     6b0:	a8c50513          	add	a0,a0,-1396 # 8138 <userret+0x98>
     6b4:	00000097          	auipc	ra,0x0
     6b8:	034080e7          	jalr	52(ra) # 6e8 <printf>
  printf(s);
     6bc:	00048513          	mv	a0,s1
     6c0:	00000097          	auipc	ra,0x0
     6c4:	028080e7          	jalr	40(ra) # 6e8 <printf>
  printf("\n");
     6c8:	00008517          	auipc	a0,0x8
     6cc:	af850513          	add	a0,a0,-1288 # 81c0 <userret+0x120>
     6d0:	00000097          	auipc	ra,0x0
     6d4:	018080e7          	jalr	24(ra) # 6e8 <printf>
  panicked = 1; // freeze other CPUs
     6d8:	00100793          	li	a5,1
     6dc:	00021717          	auipc	a4,0x21
     6e0:	92f72223          	sw	a5,-1756(a4) # 21000 <panicked>
  for(;;)
     6e4:	0000006f          	j	6e4 <panic+0x58>

000006e8 <printf>:
{
     6e8:	fa010113          	add	sp,sp,-96
     6ec:	02112e23          	sw	ra,60(sp)
     6f0:	02812c23          	sw	s0,56(sp)
     6f4:	02912a23          	sw	s1,52(sp)
     6f8:	03212823          	sw	s2,48(sp)
     6fc:	03312623          	sw	s3,44(sp)
     700:	03412423          	sw	s4,40(sp)
     704:	03512223          	sw	s5,36(sp)
     708:	03612023          	sw	s6,32(sp)
     70c:	01712e23          	sw	s7,28(sp)
     710:	01812c23          	sw	s8,24(sp)
     714:	01912a23          	sw	s9,20(sp)
     718:	01a12823          	sw	s10,16(sp)
     71c:	04010413          	add	s0,sp,64
     720:	00050993          	mv	s3,a0
     724:	00b42223          	sw	a1,4(s0)
     728:	00c42423          	sw	a2,8(s0)
     72c:	00d42623          	sw	a3,12(s0)
     730:	00e42823          	sw	a4,16(s0)
     734:	00f42a23          	sw	a5,20(s0)
     738:	01042c23          	sw	a6,24(s0)
     73c:	01142e23          	sw	a7,28(s0)
  locking = pr.locking;
     740:	00012c97          	auipc	s9,0x12
     744:	d64cac83          	lw	s9,-668(s9) # 124a4 <pr+0xc>
  if(locking)
     748:	020c9c63          	bnez	s9,780 <printf+0x98>
  if (fmt == 0)
     74c:	04098463          	beqz	s3,794 <printf+0xac>
  va_start(ap, fmt);
     750:	00440793          	add	a5,s0,4
     754:	fcf42623          	sw	a5,-52(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
     758:	0009c503          	lbu	a0,0(s3)
     75c:	18050c63          	beqz	a0,8f4 <printf+0x20c>
     760:	00000913          	li	s2,0
    if(c != '%'){
     764:	02500a13          	li	s4,37
    switch(c){
     768:	07000a93          	li	s5,112
    consputc(digits[x >> (sizeof(uint32) * 8 - 4)]);
     76c:	00008b17          	auipc	s6,0x8
     770:	ff8b0b13          	add	s6,s6,-8 # 8764 <digits>
    switch(c){
     774:	07300c13          	li	s8,115
     778:	06400b93          	li	s7,100
     77c:	0400006f          	j	7bc <printf+0xd4>
    acquire(&pr.lock);
     780:	00012517          	auipc	a0,0x12
     784:	d1850513          	add	a0,a0,-744 # 12498 <pr>
     788:	00000097          	auipc	ra,0x0
     78c:	61c080e7          	jalr	1564(ra) # da4 <acquire>
     790:	fbdff06f          	j	74c <printf+0x64>
    panic("null fmt");
     794:	00008517          	auipc	a0,0x8
     798:	9b450513          	add	a0,a0,-1612 # 8148 <userret+0xa8>
     79c:	00000097          	auipc	ra,0x0
     7a0:	ef0080e7          	jalr	-272(ra) # 68c <panic>
      consputc(c);
     7a4:	00000097          	auipc	ra,0x0
     7a8:	ae4080e7          	jalr	-1308(ra) # 288 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
     7ac:	00190913          	add	s2,s2,1
     7b0:	012987b3          	add	a5,s3,s2
     7b4:	0007c503          	lbu	a0,0(a5)
     7b8:	12050e63          	beqz	a0,8f4 <printf+0x20c>
    if(c != '%'){
     7bc:	ff4514e3          	bne	a0,s4,7a4 <printf+0xbc>
    c = fmt[++i] & 0xff;
     7c0:	00190913          	add	s2,s2,1
     7c4:	012987b3          	add	a5,s3,s2
     7c8:	0007c483          	lbu	s1,0(a5)
    if(c == 0)
     7cc:	12048463          	beqz	s1,8f4 <printf+0x20c>
    switch(c){
     7d0:	07548263          	beq	s1,s5,834 <printf+0x14c>
     7d4:	029afa63          	bgeu	s5,s1,808 <printf+0x120>
     7d8:	0b848663          	beq	s1,s8,884 <printf+0x19c>
     7dc:	07800793          	li	a5,120
     7e0:	0ef49c63          	bne	s1,a5,8d8 <printf+0x1f0>
      printint(va_arg(ap, int), 16, 1);
     7e4:	fcc42783          	lw	a5,-52(s0)
     7e8:	00478713          	add	a4,a5,4
     7ec:	fce42623          	sw	a4,-52(s0)
     7f0:	00100613          	li	a2,1
     7f4:	01000593          	li	a1,16
     7f8:	0007a503          	lw	a0,0(a5)
     7fc:	00000097          	auipc	ra,0x0
     800:	dd8080e7          	jalr	-552(ra) # 5d4 <printint>
      break;
     804:	fa9ff06f          	j	7ac <printf+0xc4>
    switch(c){
     808:	0d448063          	beq	s1,s4,8c8 <printf+0x1e0>
     80c:	0d749663          	bne	s1,s7,8d8 <printf+0x1f0>
      printint(va_arg(ap, int), 10, 1);
     810:	fcc42783          	lw	a5,-52(s0)
     814:	00478713          	add	a4,a5,4
     818:	fce42623          	sw	a4,-52(s0)
     81c:	00100613          	li	a2,1
     820:	00a00593          	li	a1,10
     824:	0007a503          	lw	a0,0(a5)
     828:	00000097          	auipc	ra,0x0
     82c:	dac080e7          	jalr	-596(ra) # 5d4 <printint>
      break;
     830:	f7dff06f          	j	7ac <printf+0xc4>
      printptr(va_arg(ap, uint32));
     834:	fcc42783          	lw	a5,-52(s0)
     838:	00478713          	add	a4,a5,4
     83c:	fce42623          	sw	a4,-52(s0)
     840:	0007ad03          	lw	s10,0(a5)
  consputc('0');
     844:	03000513          	li	a0,48
     848:	00000097          	auipc	ra,0x0
     84c:	a40080e7          	jalr	-1472(ra) # 288 <consputc>
  consputc('x');
     850:	07800513          	li	a0,120
     854:	00000097          	auipc	ra,0x0
     858:	a34080e7          	jalr	-1484(ra) # 288 <consputc>
     85c:	00800493          	li	s1,8
    consputc(digits[x >> (sizeof(uint32) * 8 - 4)]);
     860:	01cd5793          	srl	a5,s10,0x1c
     864:	00fb07b3          	add	a5,s6,a5
     868:	0007c503          	lbu	a0,0(a5)
     86c:	00000097          	auipc	ra,0x0
     870:	a1c080e7          	jalr	-1508(ra) # 288 <consputc>
  for (i = 0; i < (sizeof(uint32) * 2); i++, x <<= 4)
     874:	004d1d13          	sll	s10,s10,0x4
     878:	fff48493          	add	s1,s1,-1
     87c:	fe0492e3          	bnez	s1,860 <printf+0x178>
     880:	f2dff06f          	j	7ac <printf+0xc4>
      if((s = va_arg(ap, char*)) == 0)
     884:	fcc42783          	lw	a5,-52(s0)
     888:	00478713          	add	a4,a5,4
     88c:	fce42623          	sw	a4,-52(s0)
     890:	0007a483          	lw	s1,0(a5)
     894:	02048263          	beqz	s1,8b8 <printf+0x1d0>
      for(; *s; s++)
     898:	0004c503          	lbu	a0,0(s1)
     89c:	f00508e3          	beqz	a0,7ac <printf+0xc4>
        consputc(*s);
     8a0:	00000097          	auipc	ra,0x0
     8a4:	9e8080e7          	jalr	-1560(ra) # 288 <consputc>
      for(; *s; s++)
     8a8:	00148493          	add	s1,s1,1
     8ac:	0004c503          	lbu	a0,0(s1)
     8b0:	fe0518e3          	bnez	a0,8a0 <printf+0x1b8>
     8b4:	ef9ff06f          	j	7ac <printf+0xc4>
        s = "(null)";
     8b8:	00008497          	auipc	s1,0x8
     8bc:	88848493          	add	s1,s1,-1912 # 8140 <userret+0xa0>
      for(; *s; s++)
     8c0:	02800513          	li	a0,40
     8c4:	fddff06f          	j	8a0 <printf+0x1b8>
      consputc('%');
     8c8:	000a0513          	mv	a0,s4
     8cc:	00000097          	auipc	ra,0x0
     8d0:	9bc080e7          	jalr	-1604(ra) # 288 <consputc>
      break;
     8d4:	ed9ff06f          	j	7ac <printf+0xc4>
      consputc('%');
     8d8:	000a0513          	mv	a0,s4
     8dc:	00000097          	auipc	ra,0x0
     8e0:	9ac080e7          	jalr	-1620(ra) # 288 <consputc>
      consputc(c);
     8e4:	00048513          	mv	a0,s1
     8e8:	00000097          	auipc	ra,0x0
     8ec:	9a0080e7          	jalr	-1632(ra) # 288 <consputc>
      break;
     8f0:	ebdff06f          	j	7ac <printf+0xc4>
  if(locking)
     8f4:	020c9e63          	bnez	s9,930 <printf+0x248>
}
     8f8:	03c12083          	lw	ra,60(sp)
     8fc:	03812403          	lw	s0,56(sp)
     900:	03412483          	lw	s1,52(sp)
     904:	03012903          	lw	s2,48(sp)
     908:	02c12983          	lw	s3,44(sp)
     90c:	02812a03          	lw	s4,40(sp)
     910:	02412a83          	lw	s5,36(sp)
     914:	02012b03          	lw	s6,32(sp)
     918:	01c12b83          	lw	s7,28(sp)
     91c:	01812c03          	lw	s8,24(sp)
     920:	01412c83          	lw	s9,20(sp)
     924:	01012d03          	lw	s10,16(sp)
     928:	06010113          	add	sp,sp,96
     92c:	00008067          	ret
    release(&pr.lock);
     930:	00012517          	auipc	a0,0x12
     934:	b6850513          	add	a0,a0,-1176 # 12498 <pr>
     938:	00000097          	auipc	ra,0x0
     93c:	4e0080e7          	jalr	1248(ra) # e18 <release>
}
     940:	fb9ff06f          	j	8f8 <printf+0x210>

00000944 <printfinit>:
    ;
}

void
printfinit(void)
{
     944:	ff010113          	add	sp,sp,-16
     948:	00112623          	sw	ra,12(sp)
     94c:	00812423          	sw	s0,8(sp)
     950:	00912223          	sw	s1,4(sp)
     954:	01010413          	add	s0,sp,16
  initlock(&pr.lock, "pr");
     958:	00012497          	auipc	s1,0x12
     95c:	b4048493          	add	s1,s1,-1216 # 12498 <pr>
     960:	00007597          	auipc	a1,0x7
     964:	7f458593          	add	a1,a1,2036 # 8154 <userret+0xb4>
     968:	00048513          	mv	a0,s1
     96c:	00000097          	auipc	ra,0x0
     970:	2b4080e7          	jalr	692(ra) # c20 <initlock>
  pr.locking = 1;
     974:	00100793          	li	a5,1
     978:	00f4a623          	sw	a5,12(s1)
}
     97c:	00c12083          	lw	ra,12(sp)
     980:	00812403          	lw	s0,8(sp)
     984:	00412483          	lw	s1,4(sp)
     988:	01010113          	add	sp,sp,16
     98c:	00008067          	ret

00000990 <uartinit>:
#include "proc.h"
#include "defs.h"

void
uartinit(void)
{
     990:	ff010113          	add	sp,sp,-16
     994:	00812623          	sw	s0,12(sp)
     998:	01010413          	add	s0,sp,16
}
     99c:	00c12403          	lw	s0,12(sp)
     9a0:	01010113          	add	sp,sp,16
     9a4:	00008067          	ret

000009a8 <uartputc>:

// write one output character to the UART.
void
uartputc(int c)
{
     9a8:	ff010113          	add	sp,sp,-16
     9ac:	00812623          	sw	s0,12(sp)
     9b0:	01010413          	add	s0,sp,16
  volatile unsigned int *addr = (unsigned int*)0xff000000;
  *addr = c;
     9b4:	ff0007b7          	lui	a5,0xff000
     9b8:	00a7a023          	sw	a0,0(a5) # ff000000 <end+0xfefdefec>
}
     9bc:	00c12403          	lw	s0,12(sp)
     9c0:	01010113          	add	sp,sp,16
     9c4:	00008067          	ret

000009c8 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
     9c8:	ff010113          	add	sp,sp,-16
     9cc:	00812623          	sw	s0,12(sp)
     9d0:	01010413          	add	s0,sp,16
  volatile unsigned int *en     = (unsigned int*)0xff000010;
  volatile unsigned int *rdata  = (unsigned int*)0xff000018;
  if(*en & 0x01){
     9d4:	ff0007b7          	lui	a5,0xff000
     9d8:	0107a783          	lw	a5,16(a5) # ff000010 <end+0xfefdeffc>
     9dc:	0017f793          	and	a5,a5,1
     9e0:	00078c63          	beqz	a5,9f8 <uartgetc+0x30>
    // input data is ready.
    return *rdata;
     9e4:	ff0007b7          	lui	a5,0xff000
     9e8:	0187a503          	lw	a0,24(a5) # ff000018 <end+0xfefdf004>
  } else {
    return -1;
  }
}
     9ec:	00c12403          	lw	s0,12(sp)
     9f0:	01010113          	add	sp,sp,16
     9f4:	00008067          	ret
    return -1;
     9f8:	fff00513          	li	a0,-1
     9fc:	ff1ff06f          	j	9ec <uartgetc+0x24>

00000a00 <uartintr>:

// trap.c calls here when the uart interrupts.
void
uartintr(void)
{
     a00:	ff010113          	add	sp,sp,-16
     a04:	00112623          	sw	ra,12(sp)
     a08:	00812423          	sw	s0,8(sp)
     a0c:	00912223          	sw	s1,4(sp)
     a10:	01010413          	add	s0,sp,16
  while(1){
    int c = uartgetc();
    if(c == -1)
     a14:	fff00493          	li	s1,-1
     a18:	00c0006f          	j	a24 <uartintr+0x24>
      break;
    consoleintr(c);
     a1c:	00000097          	auipc	ra,0x0
     a20:	988080e7          	jalr	-1656(ra) # 3a4 <consoleintr>
    int c = uartgetc();
     a24:	00000097          	auipc	ra,0x0
     a28:	fa4080e7          	jalr	-92(ra) # 9c8 <uartgetc>
    if(c == -1)
     a2c:	fe9518e3          	bne	a0,s1,a1c <uartintr+0x1c>
  }
}
     a30:	00c12083          	lw	ra,12(sp)
     a34:	00812403          	lw	s0,8(sp)
     a38:	00412483          	lw	s1,4(sp)
     a3c:	01010113          	add	sp,sp,16
     a40:	00008067          	ret

00000a44 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
     a44:	ff010113          	add	sp,sp,-16
     a48:	00112623          	sw	ra,12(sp)
     a4c:	00812423          	sw	s0,8(sp)
     a50:	00912223          	sw	s1,4(sp)
     a54:	01212023          	sw	s2,0(sp)
     a58:	01010413          	add	s0,sp,16
  struct run *r;

  if(((uint32)pa % PGSIZE) != 0 || (char*)pa < end || (uint32)pa >= PHYSTOP)
     a5c:	01451793          	sll	a5,a0,0x14
     a60:	06079063          	bnez	a5,ac0 <kfree+0x7c>
     a64:	00050493          	mv	s1,a0
     a68:	00020797          	auipc	a5,0x20
     a6c:	5ac78793          	add	a5,a5,1452 # 21014 <end>
     a70:	04f56863          	bltu	a0,a5,ac0 <kfree+0x7c>
     a74:	020007b7          	lui	a5,0x2000
     a78:	04f57463          	bgeu	a0,a5,ac0 <kfree+0x7c>
  // TODO 遅すぎ
  // memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
     a7c:	00012917          	auipc	s2,0x12
     a80:	a2c90913          	add	s2,s2,-1492 # 124a8 <kmem>
     a84:	00090513          	mv	a0,s2
     a88:	00000097          	auipc	ra,0x0
     a8c:	31c080e7          	jalr	796(ra) # da4 <acquire>
  r->next = kmem.freelist;
     a90:	00c92783          	lw	a5,12(s2)
     a94:	00f4a023          	sw	a5,0(s1)
  kmem.freelist = r;
     a98:	00992623          	sw	s1,12(s2)
  release(&kmem.lock);
     a9c:	00090513          	mv	a0,s2
     aa0:	00000097          	auipc	ra,0x0
     aa4:	378080e7          	jalr	888(ra) # e18 <release>
}
     aa8:	00c12083          	lw	ra,12(sp)
     aac:	00812403          	lw	s0,8(sp)
     ab0:	00412483          	lw	s1,4(sp)
     ab4:	00012903          	lw	s2,0(sp)
     ab8:	01010113          	add	sp,sp,16
     abc:	00008067          	ret
    panic("kfree");
     ac0:	00007517          	auipc	a0,0x7
     ac4:	69850513          	add	a0,a0,1688 # 8158 <userret+0xb8>
     ac8:	00000097          	auipc	ra,0x0
     acc:	bc4080e7          	jalr	-1084(ra) # 68c <panic>

00000ad0 <freerange>:
{
     ad0:	fe010113          	add	sp,sp,-32
     ad4:	00112e23          	sw	ra,28(sp)
     ad8:	00812c23          	sw	s0,24(sp)
     adc:	00912a23          	sw	s1,20(sp)
     ae0:	01212823          	sw	s2,16(sp)
     ae4:	01312623          	sw	s3,12(sp)
     ae8:	01412423          	sw	s4,8(sp)
     aec:	02010413          	add	s0,sp,32
  p = (char*)PGROUNDUP((uint32)pa_start);
     af0:	000017b7          	lui	a5,0x1
     af4:	fff78713          	add	a4,a5,-1 # fff <strncpy+0x1b>
     af8:	00e504b3          	add	s1,a0,a4
     afc:	fffff737          	lui	a4,0xfffff
     b00:	00e4f4b3          	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     b04:	00f484b3          	add	s1,s1,a5
     b08:	0295e263          	bltu	a1,s1,b2c <freerange+0x5c>
     b0c:	00058913          	mv	s2,a1
    kfree(p);
     b10:	fffffa37          	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     b14:	000019b7          	lui	s3,0x1
    kfree(p);
     b18:	01448533          	add	a0,s1,s4
     b1c:	00000097          	auipc	ra,0x0
     b20:	f28080e7          	jalr	-216(ra) # a44 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
     b24:	013484b3          	add	s1,s1,s3
     b28:	fe9978e3          	bgeu	s2,s1,b18 <freerange+0x48>
}
     b2c:	01c12083          	lw	ra,28(sp)
     b30:	01812403          	lw	s0,24(sp)
     b34:	01412483          	lw	s1,20(sp)
     b38:	01012903          	lw	s2,16(sp)
     b3c:	00c12983          	lw	s3,12(sp)
     b40:	00812a03          	lw	s4,8(sp)
     b44:	02010113          	add	sp,sp,32
     b48:	00008067          	ret

00000b4c <kinit>:
{
     b4c:	ff010113          	add	sp,sp,-16
     b50:	00112623          	sw	ra,12(sp)
     b54:	00812423          	sw	s0,8(sp)
     b58:	01010413          	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
     b5c:	00007597          	auipc	a1,0x7
     b60:	60458593          	add	a1,a1,1540 # 8160 <userret+0xc0>
     b64:	00012517          	auipc	a0,0x12
     b68:	94450513          	add	a0,a0,-1724 # 124a8 <kmem>
     b6c:	00000097          	auipc	ra,0x0
     b70:	0b4080e7          	jalr	180(ra) # c20 <initlock>
  freerange(end, (void*)PHYSTOP);
     b74:	020005b7          	lui	a1,0x2000
     b78:	00020517          	auipc	a0,0x20
     b7c:	49c50513          	add	a0,a0,1180 # 21014 <end>
     b80:	00000097          	auipc	ra,0x0
     b84:	f50080e7          	jalr	-176(ra) # ad0 <freerange>
}
     b88:	00c12083          	lw	ra,12(sp)
     b8c:	00812403          	lw	s0,8(sp)
     b90:	01010113          	add	sp,sp,16
     b94:	00008067          	ret

00000b98 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
     b98:	ff010113          	add	sp,sp,-16
     b9c:	00112623          	sw	ra,12(sp)
     ba0:	00812423          	sw	s0,8(sp)
     ba4:	00912223          	sw	s1,4(sp)
     ba8:	01010413          	add	s0,sp,16
  struct run *r;

  acquire(&kmem.lock);
     bac:	00012497          	auipc	s1,0x12
     bb0:	8fc48493          	add	s1,s1,-1796 # 124a8 <kmem>
     bb4:	00048513          	mv	a0,s1
     bb8:	00000097          	auipc	ra,0x0
     bbc:	1ec080e7          	jalr	492(ra) # da4 <acquire>
  r = kmem.freelist;
     bc0:	00c4a483          	lw	s1,12(s1)
  if(r)
     bc4:	04048463          	beqz	s1,c0c <kalloc+0x74>
    kmem.freelist = r->next;
     bc8:	0004a783          	lw	a5,0(s1)
     bcc:	00012517          	auipc	a0,0x12
     bd0:	8dc50513          	add	a0,a0,-1828 # 124a8 <kmem>
     bd4:	00f52623          	sw	a5,12(a0)
  release(&kmem.lock);
     bd8:	00000097          	auipc	ra,0x0
     bdc:	240080e7          	jalr	576(ra) # e18 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
     be0:	00001637          	lui	a2,0x1
     be4:	00500593          	li	a1,5
     be8:	00048513          	mv	a0,s1
     bec:	00000097          	auipc	ra,0x0
     bf0:	28c080e7          	jalr	652(ra) # e78 <memset>
  return (void*)r;
}
     bf4:	00048513          	mv	a0,s1
     bf8:	00c12083          	lw	ra,12(sp)
     bfc:	00812403          	lw	s0,8(sp)
     c00:	00412483          	lw	s1,4(sp)
     c04:	01010113          	add	sp,sp,16
     c08:	00008067          	ret
  release(&kmem.lock);
     c0c:	00012517          	auipc	a0,0x12
     c10:	89c50513          	add	a0,a0,-1892 # 124a8 <kmem>
     c14:	00000097          	auipc	ra,0x0
     c18:	204080e7          	jalr	516(ra) # e18 <release>
  if(r)
     c1c:	fd9ff06f          	j	bf4 <kalloc+0x5c>

00000c20 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
     c20:	ff010113          	add	sp,sp,-16
     c24:	00812623          	sw	s0,12(sp)
     c28:	01010413          	add	s0,sp,16
  lk->name = name;
     c2c:	00b52223          	sw	a1,4(a0)
  lk->locked = 0;
     c30:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
     c34:	00052423          	sw	zero,8(a0)
}
     c38:	00c12403          	lw	s0,12(sp)
     c3c:	01010113          	add	sp,sp,16
     c40:	00008067          	ret

00000c44 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
     c44:	ff010113          	add	sp,sp,-16
     c48:	00112623          	sw	ra,12(sp)
     c4c:	00812423          	sw	s0,8(sp)
     c50:	00912223          	sw	s1,4(sp)
     c54:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
     c58:	100024f3          	csrr	s1,sstatus
     c5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
     c60:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
     c64:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
     c68:	00001097          	auipc	ra,0x1
     c6c:	434080e7          	jalr	1076(ra) # 209c <mycpu>
     c70:	03c52783          	lw	a5,60(a0)
     c74:	02078663          	beqz	a5,ca0 <push_off+0x5c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
     c78:	00001097          	auipc	ra,0x1
     c7c:	424080e7          	jalr	1060(ra) # 209c <mycpu>
     c80:	03c52783          	lw	a5,60(a0)
     c84:	00178793          	add	a5,a5,1
     c88:	02f52e23          	sw	a5,60(a0)
}
     c8c:	00c12083          	lw	ra,12(sp)
     c90:	00812403          	lw	s0,8(sp)
     c94:	00412483          	lw	s1,4(sp)
     c98:	01010113          	add	sp,sp,16
     c9c:	00008067          	ret
    mycpu()->intena = old;
     ca0:	00001097          	auipc	ra,0x1
     ca4:	3fc080e7          	jalr	1020(ra) # 209c <mycpu>
  return (x & SSTATUS_SIE) != 0;
     ca8:	0014d493          	srl	s1,s1,0x1
     cac:	0014f493          	and	s1,s1,1
     cb0:	04952023          	sw	s1,64(a0)
     cb4:	fc5ff06f          	j	c78 <push_off+0x34>

00000cb8 <pop_off>:

void
pop_off(void)
{
     cb8:	ff010113          	add	sp,sp,-16
     cbc:	00112623          	sw	ra,12(sp)
     cc0:	00812423          	sw	s0,8(sp)
     cc4:	01010413          	add	s0,sp,16
  struct cpu *c = mycpu();
     cc8:	00001097          	auipc	ra,0x1
     ccc:	3d4080e7          	jalr	980(ra) # 209c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
     cd0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
     cd4:	0027f793          	and	a5,a5,2
  if(intr_get())
     cd8:	04079463          	bnez	a5,d20 <pop_off+0x68>
    panic("pop_off - interruptible");
  c->noff -= 1;
     cdc:	03c52783          	lw	a5,60(a0)
     ce0:	fff78793          	add	a5,a5,-1
     ce4:	02f52e23          	sw	a5,60(a0)
  if(c->noff < 0)
     ce8:	0407c463          	bltz	a5,d30 <pop_off+0x78>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
     cec:	02079263          	bnez	a5,d10 <pop_off+0x58>
     cf0:	04052783          	lw	a5,64(a0)
     cf4:	00078e63          	beqz	a5,d10 <pop_off+0x58>
  asm volatile("csrr %0, sie" : "=r" (x) );
     cf8:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
     cfc:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
     d00:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
     d04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
     d08:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
     d0c:	10079073          	csrw	sstatus,a5
    intr_on();
}
     d10:	00c12083          	lw	ra,12(sp)
     d14:	00812403          	lw	s0,8(sp)
     d18:	01010113          	add	sp,sp,16
     d1c:	00008067          	ret
    panic("pop_off - interruptible");
     d20:	00007517          	auipc	a0,0x7
     d24:	44850513          	add	a0,a0,1096 # 8168 <userret+0xc8>
     d28:	00000097          	auipc	ra,0x0
     d2c:	964080e7          	jalr	-1692(ra) # 68c <panic>
    panic("pop_off");
     d30:	00007517          	auipc	a0,0x7
     d34:	45050513          	add	a0,a0,1104 # 8180 <userret+0xe0>
     d38:	00000097          	auipc	ra,0x0
     d3c:	954080e7          	jalr	-1708(ra) # 68c <panic>

00000d40 <holding>:
{
     d40:	ff010113          	add	sp,sp,-16
     d44:	00112623          	sw	ra,12(sp)
     d48:	00812423          	sw	s0,8(sp)
     d4c:	00912223          	sw	s1,4(sp)
     d50:	01010413          	add	s0,sp,16
     d54:	00050493          	mv	s1,a0
  push_off();
     d58:	00000097          	auipc	ra,0x0
     d5c:	eec080e7          	jalr	-276(ra) # c44 <push_off>
  r = (lk->locked && lk->cpu == mycpu());
     d60:	0004a783          	lw	a5,0(s1)
     d64:	02079463          	bnez	a5,d8c <holding+0x4c>
     d68:	00000493          	li	s1,0
  pop_off();
     d6c:	00000097          	auipc	ra,0x0
     d70:	f4c080e7          	jalr	-180(ra) # cb8 <pop_off>
}
     d74:	00048513          	mv	a0,s1
     d78:	00c12083          	lw	ra,12(sp)
     d7c:	00812403          	lw	s0,8(sp)
     d80:	00412483          	lw	s1,4(sp)
     d84:	01010113          	add	sp,sp,16
     d88:	00008067          	ret
  r = (lk->locked && lk->cpu == mycpu());
     d8c:	0084a483          	lw	s1,8(s1)
     d90:	00001097          	auipc	ra,0x1
     d94:	30c080e7          	jalr	780(ra) # 209c <mycpu>
     d98:	40a484b3          	sub	s1,s1,a0
     d9c:	0014b493          	seqz	s1,s1
     da0:	fcdff06f          	j	d6c <holding+0x2c>

00000da4 <acquire>:
{
     da4:	ff010113          	add	sp,sp,-16
     da8:	00112623          	sw	ra,12(sp)
     dac:	00812423          	sw	s0,8(sp)
     db0:	00912223          	sw	s1,4(sp)
     db4:	01010413          	add	s0,sp,16
     db8:	00050493          	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
     dbc:	00000097          	auipc	ra,0x0
     dc0:	e88080e7          	jalr	-376(ra) # c44 <push_off>
  if(holding(lk))
     dc4:	00048513          	mv	a0,s1
     dc8:	00000097          	auipc	ra,0x0
     dcc:	f78080e7          	jalr	-136(ra) # d40 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
     dd0:	00100713          	li	a4,1
  if(holding(lk))
     dd4:	02051a63          	bnez	a0,e08 <acquire+0x64>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
     dd8:	00070793          	mv	a5,a4
     ddc:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
     de0:	fe079ce3          	bnez	a5,dd8 <acquire+0x34>
  __sync_synchronize();
     de4:	0ff0000f          	fence
  lk->cpu = mycpu();
     de8:	00001097          	auipc	ra,0x1
     dec:	2b4080e7          	jalr	692(ra) # 209c <mycpu>
     df0:	00a4a423          	sw	a0,8(s1)
}
     df4:	00c12083          	lw	ra,12(sp)
     df8:	00812403          	lw	s0,8(sp)
     dfc:	00412483          	lw	s1,4(sp)
     e00:	01010113          	add	sp,sp,16
     e04:	00008067          	ret
    panic("acquire");
     e08:	00007517          	auipc	a0,0x7
     e0c:	38050513          	add	a0,a0,896 # 8188 <userret+0xe8>
     e10:	00000097          	auipc	ra,0x0
     e14:	87c080e7          	jalr	-1924(ra) # 68c <panic>

00000e18 <release>:
{
     e18:	ff010113          	add	sp,sp,-16
     e1c:	00112623          	sw	ra,12(sp)
     e20:	00812423          	sw	s0,8(sp)
     e24:	00912223          	sw	s1,4(sp)
     e28:	01010413          	add	s0,sp,16
     e2c:	00050493          	mv	s1,a0
  if(!holding(lk))
     e30:	00000097          	auipc	ra,0x0
     e34:	f10080e7          	jalr	-240(ra) # d40 <holding>
     e38:	02050863          	beqz	a0,e68 <release+0x50>
  lk->cpu = 0;
     e3c:	0004a423          	sw	zero,8(s1)
  __sync_synchronize();
     e40:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
     e44:	0f50000f          	fence	iorw,ow
     e48:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
     e4c:	00000097          	auipc	ra,0x0
     e50:	e6c080e7          	jalr	-404(ra) # cb8 <pop_off>
}
     e54:	00c12083          	lw	ra,12(sp)
     e58:	00812403          	lw	s0,8(sp)
     e5c:	00412483          	lw	s1,4(sp)
     e60:	01010113          	add	sp,sp,16
     e64:	00008067          	ret
    panic("release");
     e68:	00007517          	auipc	a0,0x7
     e6c:	32850513          	add	a0,a0,808 # 8190 <userret+0xf0>
     e70:	00000097          	auipc	ra,0x0
     e74:	81c080e7          	jalr	-2020(ra) # 68c <panic>

00000e78 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
     e78:	ff010113          	add	sp,sp,-16
     e7c:	00812623          	sw	s0,12(sp)
     e80:	01010413          	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     e84:	00060c63          	beqz	a2,e9c <memset+0x24>
     e88:	00050793          	mv	a5,a0
     e8c:	00a60633          	add	a2,a2,a0
    cdst[i] = c;
     e90:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     e94:	00178793          	add	a5,a5,1
     e98:	fec79ce3          	bne	a5,a2,e90 <memset+0x18>
  }
  return dst;
}
     e9c:	00c12403          	lw	s0,12(sp)
     ea0:	01010113          	add	sp,sp,16
     ea4:	00008067          	ret

00000ea8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
     ea8:	ff010113          	add	sp,sp,-16
     eac:	00812623          	sw	s0,12(sp)
     eb0:	01010413          	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
     eb4:	02060c63          	beqz	a2,eec <memcmp+0x44>
     eb8:	00c50633          	add	a2,a0,a2
    if(*s1 != *s2)
     ebc:	00054783          	lbu	a5,0(a0)
     ec0:	0005c703          	lbu	a4,0(a1) # 2000000 <end+0x1fdefec>
     ec4:	00e79c63          	bne	a5,a4,edc <memcmp+0x34>
      return *s1 - *s2;
    s1++, s2++;
     ec8:	00150513          	add	a0,a0,1
     ecc:	00158593          	add	a1,a1,1
  while(n-- > 0){
     ed0:	fea616e3          	bne	a2,a0,ebc <memcmp+0x14>
  }

  return 0;
     ed4:	00000513          	li	a0,0
     ed8:	0080006f          	j	ee0 <memcmp+0x38>
      return *s1 - *s2;
     edc:	40e78533          	sub	a0,a5,a4
}
     ee0:	00c12403          	lw	s0,12(sp)
     ee4:	01010113          	add	sp,sp,16
     ee8:	00008067          	ret
  return 0;
     eec:	00000513          	li	a0,0
     ef0:	ff1ff06f          	j	ee0 <memcmp+0x38>

00000ef4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
     ef4:	ff010113          	add	sp,sp,-16
     ef8:	00812623          	sw	s0,12(sp)
     efc:	01010413          	add	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
     f00:	02a5e863          	bltu	a1,a0,f30 <memmove+0x3c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
     f04:	00c586b3          	add	a3,a1,a2
     f08:	00050793          	mv	a5,a0
     f0c:	00060c63          	beqz	a2,f24 <memmove+0x30>
      *d++ = *s++;
     f10:	00158593          	add	a1,a1,1
     f14:	00178793          	add	a5,a5,1
     f18:	fff5c703          	lbu	a4,-1(a1)
     f1c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
     f20:	fed598e3          	bne	a1,a3,f10 <memmove+0x1c>

  return dst;
}
     f24:	00c12403          	lw	s0,12(sp)
     f28:	01010113          	add	sp,sp,16
     f2c:	00008067          	ret
  if(s < d && s + n > d){
     f30:	00c587b3          	add	a5,a1,a2
     f34:	fcf578e3          	bgeu	a0,a5,f04 <memmove+0x10>
    d += n;
     f38:	00c50733          	add	a4,a0,a2
    while(n-- > 0)
     f3c:	fe0604e3          	beqz	a2,f24 <memmove+0x30>
      *--d = *--s;
     f40:	fff78793          	add	a5,a5,-1
     f44:	fff70713          	add	a4,a4,-1 # ffffefff <end+0xfffddfeb>
     f48:	0007c683          	lbu	a3,0(a5)
     f4c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     f50:	fef598e3          	bne	a1,a5,f40 <memmove+0x4c>
     f54:	fd1ff06f          	j	f24 <memmove+0x30>

00000f58 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
     f58:	ff010113          	add	sp,sp,-16
     f5c:	00112623          	sw	ra,12(sp)
     f60:	00812423          	sw	s0,8(sp)
     f64:	01010413          	add	s0,sp,16
  return memmove(dst, src, n);
     f68:	00000097          	auipc	ra,0x0
     f6c:	f8c080e7          	jalr	-116(ra) # ef4 <memmove>
}
     f70:	00c12083          	lw	ra,12(sp)
     f74:	00812403          	lw	s0,8(sp)
     f78:	01010113          	add	sp,sp,16
     f7c:	00008067          	ret

00000f80 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
     f80:	ff010113          	add	sp,sp,-16
     f84:	00812623          	sw	s0,12(sp)
     f88:	01010413          	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
     f8c:	02060663          	beqz	a2,fb8 <strncmp+0x38>
     f90:	00054783          	lbu	a5,0(a0)
     f94:	02078663          	beqz	a5,fc0 <strncmp+0x40>
     f98:	0005c703          	lbu	a4,0(a1)
     f9c:	02f71263          	bne	a4,a5,fc0 <strncmp+0x40>
    n--, p++, q++;
     fa0:	fff60613          	add	a2,a2,-1 # fff <strncpy+0x1b>
     fa4:	00150513          	add	a0,a0,1
     fa8:	00158593          	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
     fac:	fe0612e3          	bnez	a2,f90 <strncmp+0x10>
  if(n == 0)
    return 0;
     fb0:	00000513          	li	a0,0
     fb4:	01c0006f          	j	fd0 <strncmp+0x50>
     fb8:	00000513          	li	a0,0
     fbc:	0140006f          	j	fd0 <strncmp+0x50>
  if(n == 0)
     fc0:	00060e63          	beqz	a2,fdc <strncmp+0x5c>
  return (uchar)*p - (uchar)*q;
     fc4:	00054503          	lbu	a0,0(a0)
     fc8:	0005c783          	lbu	a5,0(a1)
     fcc:	40f50533          	sub	a0,a0,a5
}
     fd0:	00c12403          	lw	s0,12(sp)
     fd4:	01010113          	add	sp,sp,16
     fd8:	00008067          	ret
    return 0;
     fdc:	00000513          	li	a0,0
     fe0:	ff1ff06f          	j	fd0 <strncmp+0x50>

00000fe4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
     fe4:	ff010113          	add	sp,sp,-16
     fe8:	00812623          	sw	s0,12(sp)
     fec:	01010413          	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
     ff0:	00050793          	mv	a5,a0
     ff4:	00060693          	mv	a3,a2
     ff8:	fff60613          	add	a2,a2,-1
     ffc:	00d05c63          	blez	a3,1014 <strncpy+0x30>
    1000:	00158593          	add	a1,a1,1
    1004:	00178793          	add	a5,a5,1
    1008:	fff5c703          	lbu	a4,-1(a1)
    100c:	fee78fa3          	sb	a4,-1(a5)
    1010:	fe0712e3          	bnez	a4,ff4 <strncpy+0x10>
    ;
  while(n-- > 0)
    1014:	00078713          	mv	a4,a5
    1018:	00d787b3          	add	a5,a5,a3
    101c:	fff78793          	add	a5,a5,-1
    1020:	00c05a63          	blez	a2,1034 <strncpy+0x50>
    *s++ = 0;
    1024:	00170713          	add	a4,a4,1
    1028:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    102c:	40e786b3          	sub	a3,a5,a4
    1030:	fed04ae3          	bgtz	a3,1024 <strncpy+0x40>
  return os;
}
    1034:	00c12403          	lw	s0,12(sp)
    1038:	01010113          	add	sp,sp,16
    103c:	00008067          	ret

00001040 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    1040:	ff010113          	add	sp,sp,-16
    1044:	00812623          	sw	s0,12(sp)
    1048:	01010413          	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    104c:	02c05663          	blez	a2,1078 <safestrcpy+0x38>
    1050:	fff60613          	add	a2,a2,-1
    1054:	00c586b3          	add	a3,a1,a2
    1058:	00050793          	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    105c:	00d58c63          	beq	a1,a3,1074 <safestrcpy+0x34>
    1060:	00158593          	add	a1,a1,1
    1064:	00178793          	add	a5,a5,1
    1068:	fff5c703          	lbu	a4,-1(a1)
    106c:	fee78fa3          	sb	a4,-1(a5)
    1070:	fe0716e3          	bnez	a4,105c <safestrcpy+0x1c>
    ;
  *s = 0;
    1074:	00078023          	sb	zero,0(a5)
  return os;
}
    1078:	00c12403          	lw	s0,12(sp)
    107c:	01010113          	add	sp,sp,16
    1080:	00008067          	ret

00001084 <strlen>:

int
strlen(const char *s)
{
    1084:	ff010113          	add	sp,sp,-16
    1088:	00812623          	sw	s0,12(sp)
    108c:	01010413          	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    1090:	00054783          	lbu	a5,0(a0)
    1094:	02078463          	beqz	a5,10bc <strlen+0x38>
    1098:	00050713          	mv	a4,a0
    109c:	00000513          	li	a0,0
    10a0:	00150513          	add	a0,a0,1
    10a4:	00a707b3          	add	a5,a4,a0
    10a8:	0007c783          	lbu	a5,0(a5)
    10ac:	fe079ae3          	bnez	a5,10a0 <strlen+0x1c>
    ;
  return n;
}
    10b0:	00c12403          	lw	s0,12(sp)
    10b4:	01010113          	add	sp,sp,16
    10b8:	00008067          	ret
  for(n = 0; s[n]; n++)
    10bc:	00000513          	li	a0,0
  return n;
    10c0:	ff1ff06f          	j	10b0 <strlen+0x2c>

000010c4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    10c4:	ff010113          	add	sp,sp,-16
    10c8:	00112623          	sw	ra,12(sp)
    10cc:	00812423          	sw	s0,8(sp)
    10d0:	01010413          	add	s0,sp,16
  if(cpuid() == 0){
    10d4:	00001097          	auipc	ra,0x1
    10d8:	fac080e7          	jalr	-84(ra) # 2080 <cpuid>
    userinit();      // first user process
    // printf("k");
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    10dc:	00020717          	auipc	a4,0x20
    10e0:	f2870713          	add	a4,a4,-216 # 21004 <started>
  if(cpuid() == 0){
    10e4:	04050663          	beqz	a0,1130 <main+0x6c>
    while(started == 0)
    10e8:	00072783          	lw	a5,0(a4)
    10ec:	fe078ee3          	beqz	a5,10e8 <main+0x24>
      ;
    __sync_synchronize();
    10f0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    10f4:	00001097          	auipc	ra,0x1
    10f8:	f8c080e7          	jalr	-116(ra) # 2080 <cpuid>
    10fc:	00050593          	mv	a1,a0
    1100:	00007517          	auipc	a0,0x7
    1104:	0b050513          	add	a0,a0,176 # 81b0 <userret+0x110>
    1108:	fffff097          	auipc	ra,0xfffff
    110c:	5e0080e7          	jalr	1504(ra) # 6e8 <printf>
    kvminithart();    // turn on paging
    1110:	00000097          	auipc	ra,0x0
    1114:	23c080e7          	jalr	572(ra) # 134c <kvminithart>
    trapinithart();   // install kernel trap vector
    1118:	00002097          	auipc	ra,0x2
    111c:	01c080e7          	jalr	28(ra) # 3134 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    1120:	00006097          	auipc	ra,0x6
    1124:	7f0080e7          	jalr	2032(ra) # 7910 <plicinithart>
  }

  scheduler();        
    1128:	00001097          	auipc	ra,0x1
    112c:	654080e7          	jalr	1620(ra) # 277c <scheduler>
    consoleinit();
    1130:	fffff097          	auipc	ra,0xfffff
    1134:	444080e7          	jalr	1092(ra) # 574 <consoleinit>
    printfinit();
    1138:	00000097          	auipc	ra,0x0
    113c:	80c080e7          	jalr	-2036(ra) # 944 <printfinit>
    printf("\n");
    1140:	00007517          	auipc	a0,0x7
    1144:	08050513          	add	a0,a0,128 # 81c0 <userret+0x120>
    1148:	fffff097          	auipc	ra,0xfffff
    114c:	5a0080e7          	jalr	1440(ra) # 6e8 <printf>
    printf("xv6 kernel is booting\n");
    1150:	00007517          	auipc	a0,0x7
    1154:	04850513          	add	a0,a0,72 # 8198 <userret+0xf8>
    1158:	fffff097          	auipc	ra,0xfffff
    115c:	590080e7          	jalr	1424(ra) # 6e8 <printf>
    printf("\n");
    1160:	00007517          	auipc	a0,0x7
    1164:	06050513          	add	a0,a0,96 # 81c0 <userret+0x120>
    1168:	fffff097          	auipc	ra,0xfffff
    116c:	580080e7          	jalr	1408(ra) # 6e8 <printf>
    kinit();         // physical page allocator
    1170:	00000097          	auipc	ra,0x0
    1174:	9dc080e7          	jalr	-1572(ra) # b4c <kinit>
    kvminit();       // create kernel page table
    1178:	00000097          	auipc	ra,0x0
    117c:	428080e7          	jalr	1064(ra) # 15a0 <kvminit>
    kvminithart();   // turn on paging
    1180:	00000097          	auipc	ra,0x0
    1184:	1cc080e7          	jalr	460(ra) # 134c <kvminithart>
    procinit();      // process table
    1188:	00001097          	auipc	ra,0x1
    118c:	df0080e7          	jalr	-528(ra) # 1f78 <procinit>
    trapinit();      // trap vectors
    1190:	00002097          	auipc	ra,0x2
    1194:	f6c080e7          	jalr	-148(ra) # 30fc <trapinit>
    trapinithart();  // install kernel trap vector
    1198:	00002097          	auipc	ra,0x2
    119c:	f9c080e7          	jalr	-100(ra) # 3134 <trapinithart>
    binit();         // buffer cache
    11a0:	00003097          	auipc	ra,0x3
    11a4:	990080e7          	jalr	-1648(ra) # 3b30 <binit>
    iinit();         // inode cache
    11a8:	00003097          	auipc	ra,0x3
    11ac:	23c080e7          	jalr	572(ra) # 43e4 <iinit>
    fileinit();      // file table
    11b0:	00004097          	auipc	ra,0x4
    11b4:	75c080e7          	jalr	1884(ra) # 590c <fileinit>
    virtio_disk_init(); // emulated hard disk
    11b8:	00006097          	auipc	ra,0x6
    11bc:	7d8080e7          	jalr	2008(ra) # 7990 <virtio_disk_init>
    userinit();      // first user process
    11c0:	00001097          	auipc	ra,0x1
    11c4:	288080e7          	jalr	648(ra) # 2448 <userinit>
    __sync_synchronize();
    11c8:	0ff0000f          	fence
    started = 1;
    11cc:	00100793          	li	a5,1
    11d0:	00020717          	auipc	a4,0x20
    11d4:	e2f72a23          	sw	a5,-460(a4) # 21004 <started>
    11d8:	f51ff06f          	j	1128 <main+0x64>

000011dc <walk>:
//    0.. 7 -- flags: Valid/Read/Write/Execute/User/Global/Accessed/Dirty
// 

static pte_t *
walk(pagetable_t pagetable, uint32 va, int alloc)
{
    11dc:	fe010113          	add	sp,sp,-32
    11e0:	00112e23          	sw	ra,28(sp)
    11e4:	00812c23          	sw	s0,24(sp)
    11e8:	00912a23          	sw	s1,20(sp)
    11ec:	01212823          	sw	s2,16(sp)
    11f0:	01312623          	sw	s3,12(sp)
    11f4:	02010413          	add	s0,sp,32
  if(va >= MAXVA)
    11f8:	fff00793          	li	a5,-1
    11fc:	04f58c63          	beq	a1,a5,1254 <walk+0x78>
    1200:	00058493          	mv	s1,a1
    panic("walk");

  for(int level = 1; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    1204:	0165d793          	srl	a5,a1,0x16
    1208:	00279793          	sll	a5,a5,0x2
    120c:	00f509b3          	add	s3,a0,a5
    if(*pte & PTE_V) {
    1210:	0009a903          	lw	s2,0(s3) # 1000 <strncpy+0x1c>
    1214:	00197793          	and	a5,s2,1
    1218:	04078663          	beqz	a5,1264 <walk+0x88>
      pagetable = (pagetable_t)PTE2PA(*pte);
    121c:	00a95913          	srl	s2,s2,0xa
    1220:	00c91913          	sll	s2,s2,0xc
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
    1224:	00c4d493          	srl	s1,s1,0xc
    1228:	3ff4f493          	and	s1,s1,1023
    122c:	00249493          	sll	s1,s1,0x2
    1230:	00990933          	add	s2,s2,s1
}
    1234:	00090513          	mv	a0,s2
    1238:	01c12083          	lw	ra,28(sp)
    123c:	01812403          	lw	s0,24(sp)
    1240:	01412483          	lw	s1,20(sp)
    1244:	01012903          	lw	s2,16(sp)
    1248:	00c12983          	lw	s3,12(sp)
    124c:	02010113          	add	sp,sp,32
    1250:	00008067          	ret
    panic("walk");
    1254:	00007517          	auipc	a0,0x7
    1258:	f7050513          	add	a0,a0,-144 # 81c4 <userret+0x124>
    125c:	fffff097          	auipc	ra,0xfffff
    1260:	430080e7          	jalr	1072(ra) # 68c <panic>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    1264:	02060c63          	beqz	a2,129c <walk+0xc0>
    1268:	00000097          	auipc	ra,0x0
    126c:	930080e7          	jalr	-1744(ra) # b98 <kalloc>
    1270:	00050913          	mv	s2,a0
    1274:	fc0500e3          	beqz	a0,1234 <walk+0x58>
      memset(pagetable, 0, PGSIZE);
    1278:	00001637          	lui	a2,0x1
    127c:	00000593          	li	a1,0
    1280:	00000097          	auipc	ra,0x0
    1284:	bf8080e7          	jalr	-1032(ra) # e78 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    1288:	00c95793          	srl	a5,s2,0xc
    128c:	00a79793          	sll	a5,a5,0xa
    1290:	0017e793          	or	a5,a5,1
    1294:	00f9a023          	sw	a5,0(s3)
    1298:	f8dff06f          	j	1224 <walk+0x48>
        return 0;
    129c:	00000913          	li	s2,0
    12a0:	f95ff06f          	j	1234 <walk+0x58>

000012a4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    12a4:	fe010113          	add	sp,sp,-32
    12a8:	00112e23          	sw	ra,28(sp)
    12ac:	00812c23          	sw	s0,24(sp)
    12b0:	00912a23          	sw	s1,20(sp)
    12b4:	01212823          	sw	s2,16(sp)
    12b8:	01312623          	sw	s3,12(sp)
    12bc:	01412423          	sw	s4,8(sp)
    12c0:	02010413          	add	s0,sp,32
    12c4:	00050a13          	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    12c8:	00050493          	mv	s1,a0
    12cc:	00001937          	lui	s2,0x1
    12d0:	80090913          	add	s2,s2,-2048 # 800 <printf+0x118>
    12d4:	01250933          	add	s2,a0,s2
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    12d8:	00100993          	li	s3,1
    12dc:	0200006f          	j	12fc <freewalk+0x58>
      // this PTE points to a lower-level page table.
      uint32 child = PTE2PA(pte);
    12e0:	00a7d793          	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    12e4:	00c79513          	sll	a0,a5,0xc
    12e8:	00000097          	auipc	ra,0x0
    12ec:	fbc080e7          	jalr	-68(ra) # 12a4 <freewalk>
      pagetable[i] = 0;
    12f0:	0004a023          	sw	zero,0(s1)
  for(int i = 0; i < 512; i++){
    12f4:	00448493          	add	s1,s1,4
    12f8:	03248463          	beq	s1,s2,1320 <freewalk+0x7c>
    pte_t pte = pagetable[i];
    12fc:	0004a783          	lw	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    1300:	00f7f713          	and	a4,a5,15
    1304:	fd370ee3          	beq	a4,s3,12e0 <freewalk+0x3c>
    } else if(pte & PTE_V){
    1308:	0017f793          	and	a5,a5,1
    130c:	fe0784e3          	beqz	a5,12f4 <freewalk+0x50>
      panic("freewalk: leaf");
    1310:	00007517          	auipc	a0,0x7
    1314:	ebc50513          	add	a0,a0,-324 # 81cc <userret+0x12c>
    1318:	fffff097          	auipc	ra,0xfffff
    131c:	374080e7          	jalr	884(ra) # 68c <panic>
    }
  }
  kfree((void*)pagetable);
    1320:	000a0513          	mv	a0,s4
    1324:	fffff097          	auipc	ra,0xfffff
    1328:	720080e7          	jalr	1824(ra) # a44 <kfree>
}
    132c:	01c12083          	lw	ra,28(sp)
    1330:	01812403          	lw	s0,24(sp)
    1334:	01412483          	lw	s1,20(sp)
    1338:	01012903          	lw	s2,16(sp)
    133c:	00c12983          	lw	s3,12(sp)
    1340:	00812a03          	lw	s4,8(sp)
    1344:	02010113          	add	sp,sp,32
    1348:	00008067          	ret

0000134c <kvminithart>:
{
    134c:	ff010113          	add	sp,sp,-16
    1350:	00812623          	sw	s0,12(sp)
    1354:	01010413          	add	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    1358:	00020797          	auipc	a5,0x20
    135c:	cb07a783          	lw	a5,-848(a5) # 21008 <kernel_pagetable>
    1360:	00c7d793          	srl	a5,a5,0xc
    1364:	80000737          	lui	a4,0x80000
    1368:	00e7e7b3          	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    136c:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    1370:	12000073          	sfence.vma
}
    1374:	00c12403          	lw	s0,12(sp)
    1378:	01010113          	add	sp,sp,16
    137c:	00008067          	ret

00001380 <walkaddr>:
  if(va >= MAXVA)
    1380:	fff00793          	li	a5,-1
    1384:	04f58a63          	beq	a1,a5,13d8 <walkaddr+0x58>
{
    1388:	ff010113          	add	sp,sp,-16
    138c:	00112623          	sw	ra,12(sp)
    1390:	00812423          	sw	s0,8(sp)
    1394:	01010413          	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    1398:	00000613          	li	a2,0
    139c:	00000097          	auipc	ra,0x0
    13a0:	e40080e7          	jalr	-448(ra) # 11dc <walk>
  if(pte == 0)
    13a4:	02050e63          	beqz	a0,13e0 <walkaddr+0x60>
  if((*pte & PTE_V) == 0)
    13a8:	00052783          	lw	a5,0(a0)
  if((*pte & PTE_U) == 0)
    13ac:	0117f693          	and	a3,a5,17
    13b0:	01100713          	li	a4,17
    return 0;
    13b4:	00000513          	li	a0,0
  if((*pte & PTE_U) == 0)
    13b8:	00e68a63          	beq	a3,a4,13cc <walkaddr+0x4c>
}
    13bc:	00c12083          	lw	ra,12(sp)
    13c0:	00812403          	lw	s0,8(sp)
    13c4:	01010113          	add	sp,sp,16
    13c8:	00008067          	ret
  pa = PTE2PA(*pte);
    13cc:	00a7d793          	srl	a5,a5,0xa
    13d0:	00c79513          	sll	a0,a5,0xc
  return pa;
    13d4:	fe9ff06f          	j	13bc <walkaddr+0x3c>
    return 0;
    13d8:	00000513          	li	a0,0
}
    13dc:	00008067          	ret
    return 0;
    13e0:	00000513          	li	a0,0
    13e4:	fd9ff06f          	j	13bc <walkaddr+0x3c>

000013e8 <kvmpa>:
{
    13e8:	ff010113          	add	sp,sp,-16
    13ec:	00112623          	sw	ra,12(sp)
    13f0:	00812423          	sw	s0,8(sp)
    13f4:	00912223          	sw	s1,4(sp)
    13f8:	01010413          	add	s0,sp,16
    13fc:	00050593          	mv	a1,a0
  uint32 off = va % PGSIZE;
    1400:	01451513          	sll	a0,a0,0x14
    1404:	01455493          	srl	s1,a0,0x14
  pte = walk(kernel_pagetable, va, 0);
    1408:	00000613          	li	a2,0
    140c:	00020517          	auipc	a0,0x20
    1410:	bfc52503          	lw	a0,-1028(a0) # 21008 <kernel_pagetable>
    1414:	00000097          	auipc	ra,0x0
    1418:	dc8080e7          	jalr	-568(ra) # 11dc <walk>
  if(pte == 0)
    141c:	02050863          	beqz	a0,144c <kvmpa+0x64>
  if((*pte & PTE_V) == 0)
    1420:	00052503          	lw	a0,0(a0)
    1424:	00157793          	and	a5,a0,1
    1428:	02078a63          	beqz	a5,145c <kvmpa+0x74>
  pa = PTE2PA(*pte);
    142c:	00a55513          	srl	a0,a0,0xa
    1430:	00c51513          	sll	a0,a0,0xc
}
    1434:	00950533          	add	a0,a0,s1
    1438:	00c12083          	lw	ra,12(sp)
    143c:	00812403          	lw	s0,8(sp)
    1440:	00412483          	lw	s1,4(sp)
    1444:	01010113          	add	sp,sp,16
    1448:	00008067          	ret
    panic("kvmpa");
    144c:	00007517          	auipc	a0,0x7
    1450:	d9050513          	add	a0,a0,-624 # 81dc <userret+0x13c>
    1454:	fffff097          	auipc	ra,0xfffff
    1458:	238080e7          	jalr	568(ra) # 68c <panic>
    panic("kvmpa");
    145c:	00007517          	auipc	a0,0x7
    1460:	d8050513          	add	a0,a0,-640 # 81dc <userret+0x13c>
    1464:	fffff097          	auipc	ra,0xfffff
    1468:	228080e7          	jalr	552(ra) # 68c <panic>

0000146c <mappages>:
{
    146c:	fd010113          	add	sp,sp,-48
    1470:	02112623          	sw	ra,44(sp)
    1474:	02812423          	sw	s0,40(sp)
    1478:	02912223          	sw	s1,36(sp)
    147c:	03212023          	sw	s2,32(sp)
    1480:	01312e23          	sw	s3,28(sp)
    1484:	01412c23          	sw	s4,24(sp)
    1488:	01512a23          	sw	s5,20(sp)
    148c:	01612823          	sw	s6,16(sp)
    1490:	01712623          	sw	s7,12(sp)
    1494:	03010413          	add	s0,sp,48
    1498:	00050a93          	mv	s5,a0
    149c:	00070b13          	mv	s6,a4
  a = PGROUNDDOWN(va);
    14a0:	fffff737          	lui	a4,0xfffff
    14a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    14a8:	fff60993          	add	s3,a2,-1 # fff <strncpy+0x1b>
    14ac:	00b989b3          	add	s3,s3,a1
    14b0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    14b4:	00078913          	mv	s2,a5
    14b8:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    14bc:	00001bb7          	lui	s7,0x1
    14c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    14c4:	00100613          	li	a2,1
    14c8:	00090593          	mv	a1,s2
    14cc:	000a8513          	mv	a0,s5
    14d0:	00000097          	auipc	ra,0x0
    14d4:	d0c080e7          	jalr	-756(ra) # 11dc <walk>
    14d8:	04050063          	beqz	a0,1518 <mappages+0xac>
    if(*pte & PTE_V)
    14dc:	00052783          	lw	a5,0(a0)
    14e0:	0017f793          	and	a5,a5,1
    14e4:	02079263          	bnez	a5,1508 <mappages+0x9c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    14e8:	00c4d493          	srl	s1,s1,0xc
    14ec:	00a49493          	sll	s1,s1,0xa
    14f0:	0164e4b3          	or	s1,s1,s6
    14f4:	0014e493          	or	s1,s1,1
    14f8:	00952023          	sw	s1,0(a0)
    if(a == last)
    14fc:	05390663          	beq	s2,s3,1548 <mappages+0xdc>
    a += PGSIZE;
    1500:	01790933          	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    1504:	fbdff06f          	j	14c0 <mappages+0x54>
      panic("remap");
    1508:	00007517          	auipc	a0,0x7
    150c:	cdc50513          	add	a0,a0,-804 # 81e4 <userret+0x144>
    1510:	fffff097          	auipc	ra,0xfffff
    1514:	17c080e7          	jalr	380(ra) # 68c <panic>
      return -1;
    1518:	fff00513          	li	a0,-1
}
    151c:	02c12083          	lw	ra,44(sp)
    1520:	02812403          	lw	s0,40(sp)
    1524:	02412483          	lw	s1,36(sp)
    1528:	02012903          	lw	s2,32(sp)
    152c:	01c12983          	lw	s3,28(sp)
    1530:	01812a03          	lw	s4,24(sp)
    1534:	01412a83          	lw	s5,20(sp)
    1538:	01012b03          	lw	s6,16(sp)
    153c:	00c12b83          	lw	s7,12(sp)
    1540:	03010113          	add	sp,sp,48
    1544:	00008067          	ret
  return 0;
    1548:	00000513          	li	a0,0
    154c:	fd1ff06f          	j	151c <mappages+0xb0>

00001550 <kvmmap>:
{
    1550:	ff010113          	add	sp,sp,-16
    1554:	00112623          	sw	ra,12(sp)
    1558:	00812423          	sw	s0,8(sp)
    155c:	01010413          	add	s0,sp,16
    1560:	00068713          	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    1564:	00058693          	mv	a3,a1
    1568:	00050593          	mv	a1,a0
    156c:	00020517          	auipc	a0,0x20
    1570:	a9c52503          	lw	a0,-1380(a0) # 21008 <kernel_pagetable>
    1574:	00000097          	auipc	ra,0x0
    1578:	ef8080e7          	jalr	-264(ra) # 146c <mappages>
    157c:	00051a63          	bnez	a0,1590 <kvmmap+0x40>
}
    1580:	00c12083          	lw	ra,12(sp)
    1584:	00812403          	lw	s0,8(sp)
    1588:	01010113          	add	sp,sp,16
    158c:	00008067          	ret
    panic("kvmmap");
    1590:	00007517          	auipc	a0,0x7
    1594:	c5c50513          	add	a0,a0,-932 # 81ec <userret+0x14c>
    1598:	fffff097          	auipc	ra,0xfffff
    159c:	0f4080e7          	jalr	244(ra) # 68c <panic>

000015a0 <kvminit>:
{
    15a0:	ff010113          	add	sp,sp,-16
    15a4:	00112623          	sw	ra,12(sp)
    15a8:	00812423          	sw	s0,8(sp)
    15ac:	00912223          	sw	s1,4(sp)
    15b0:	01010413          	add	s0,sp,16
  kernel_pagetable = (pagetable_t) kalloc();
    15b4:	fffff097          	auipc	ra,0xfffff
    15b8:	5e4080e7          	jalr	1508(ra) # b98 <kalloc>
    15bc:	00020797          	auipc	a5,0x20
    15c0:	a4a7a623          	sw	a0,-1460(a5) # 21008 <kernel_pagetable>
  if (kernel_pagetable == 0) { 
    15c4:	0c050863          	beqz	a0,1694 <kvminit+0xf4>
  memset(kernel_pagetable, 0, PGSIZE);
    15c8:	00001637          	lui	a2,0x1
    15cc:	00000593          	li	a1,0
    15d0:	00020517          	auipc	a0,0x20
    15d4:	a3852503          	lw	a0,-1480(a0) # 21008 <kernel_pagetable>
    15d8:	00000097          	auipc	ra,0x0
    15dc:	8a0080e7          	jalr	-1888(ra) # e78 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    15e0:	00600693          	li	a3,6
    15e4:	00001637          	lui	a2,0x1
    15e8:	ff0005b7          	lui	a1,0xff000
    15ec:	ff000537          	lui	a0,0xff000
    15f0:	00000097          	auipc	ra,0x0
    15f4:	f60080e7          	jalr	-160(ra) # 1550 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    15f8:	00600693          	li	a3,6
    15fc:	00001637          	lui	a2,0x1
    1600:	f80005b7          	lui	a1,0xf8000
    1604:	f8000537          	lui	a0,0xf8000
    1608:	00000097          	auipc	ra,0x0
    160c:	f48080e7          	jalr	-184(ra) # 1550 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    1610:	00600693          	li	a3,6
    1614:	00010637          	lui	a2,0x10
    1618:	f00005b7          	lui	a1,0xf0000
    161c:	f0000537          	lui	a0,0xf0000
    1620:	00000097          	auipc	ra,0x0
    1624:	f30080e7          	jalr	-208(ra) # 1550 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint32)etext-KERNBASE, PTE_R | PTE_X);
    1628:	00008497          	auipc	s1,0x8
    162c:	9d848493          	add	s1,s1,-1576 # 9000 <initcode>
    1630:	00a00693          	li	a3,10
    1634:	00048613          	mv	a2,s1
    1638:	00000593          	li	a1,0
    163c:	00000513          	li	a0,0
    1640:	00000097          	auipc	ra,0x0
    1644:	f10080e7          	jalr	-240(ra) # 1550 <kvmmap>
  kvmmap((uint32)etext, (uint32)etext, PHYSTOP-(uint32)etext, PTE_R | PTE_W);
    1648:	00600693          	li	a3,6
    164c:	02000637          	lui	a2,0x2000
    1650:	40960633          	sub	a2,a2,s1
    1654:	00048593          	mv	a1,s1
    1658:	00048513          	mv	a0,s1
    165c:	00000097          	auipc	ra,0x0
    1660:	ef4080e7          	jalr	-268(ra) # 1550 <kvmmap>
  kvmmap(TRAMPOLINE, (uint32)trampoline, PGSIZE, PTE_R | PTE_X);
    1664:	00a00693          	li	a3,10
    1668:	00001637          	lui	a2,0x1
    166c:	00007597          	auipc	a1,0x7
    1670:	99458593          	add	a1,a1,-1644 # 8000 <trampoline>
    1674:	fffff537          	lui	a0,0xfffff
    1678:	00000097          	auipc	ra,0x0
    167c:	ed8080e7          	jalr	-296(ra) # 1550 <kvmmap>
}
    1680:	00c12083          	lw	ra,12(sp)
    1684:	00812403          	lw	s0,8(sp)
    1688:	00412483          	lw	s1,4(sp)
    168c:	01010113          	add	sp,sp,16
    1690:	00008067          	ret
    printf("kalloc failed\n");
    1694:	00007517          	auipc	a0,0x7
    1698:	b6050513          	add	a0,a0,-1184 # 81f4 <userret+0x154>
    169c:	fffff097          	auipc	ra,0xfffff
    16a0:	04c080e7          	jalr	76(ra) # 6e8 <printf>
    16a4:	f25ff06f          	j	15c8 <kvminit+0x28>

000016a8 <uvmunmap>:
{
    16a8:	fd010113          	add	sp,sp,-48
    16ac:	02112623          	sw	ra,44(sp)
    16b0:	02812423          	sw	s0,40(sp)
    16b4:	02912223          	sw	s1,36(sp)
    16b8:	03212023          	sw	s2,32(sp)
    16bc:	01312e23          	sw	s3,28(sp)
    16c0:	01412c23          	sw	s4,24(sp)
    16c4:	01512a23          	sw	s5,20(sp)
    16c8:	01612823          	sw	s6,16(sp)
    16cc:	01712623          	sw	s7,12(sp)
    16d0:	03010413          	add	s0,sp,48
    16d4:	00050a13          	mv	s4,a0
    16d8:	00068a93          	mv	s5,a3
  a = PGROUNDDOWN(va);
    16dc:	fffff7b7          	lui	a5,0xfffff
    16e0:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    16e4:	fff60993          	add	s3,a2,-1 # fff <strncpy+0x1b>
    16e8:	00b989b3          	add	s3,s3,a1
    16ec:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    16f0:	00100b13          	li	s6,1
    a += PGSIZE;
    16f4:	00001bb7          	lui	s7,0x1
    16f8:	0540006f          	j	174c <uvmunmap+0xa4>
      panic("uvmunmap: walk");
    16fc:	00007517          	auipc	a0,0x7
    1700:	b0850513          	add	a0,a0,-1272 # 8204 <userret+0x164>
    1704:	fffff097          	auipc	ra,0xfffff
    1708:	f88080e7          	jalr	-120(ra) # 68c <panic>
      printf("va=%p pte=%p\n", a, *pte);
    170c:	00090593          	mv	a1,s2
    1710:	00007517          	auipc	a0,0x7
    1714:	b0450513          	add	a0,a0,-1276 # 8214 <userret+0x174>
    1718:	fffff097          	auipc	ra,0xfffff
    171c:	fd0080e7          	jalr	-48(ra) # 6e8 <printf>
      panic("uvmunmap: not mapped");
    1720:	00007517          	auipc	a0,0x7
    1724:	b0450513          	add	a0,a0,-1276 # 8224 <userret+0x184>
    1728:	fffff097          	auipc	ra,0xfffff
    172c:	f64080e7          	jalr	-156(ra) # 68c <panic>
      panic("uvmunmap: not a leaf");
    1730:	00007517          	auipc	a0,0x7
    1734:	b0c50513          	add	a0,a0,-1268 # 823c <userret+0x19c>
    1738:	fffff097          	auipc	ra,0xfffff
    173c:	f54080e7          	jalr	-172(ra) # 68c <panic>
    *pte = 0;
    1740:	0004a023          	sw	zero,0(s1)
    if(a == last)
    1744:	05390863          	beq	s2,s3,1794 <uvmunmap+0xec>
    a += PGSIZE;
    1748:	01790933          	add	s2,s2,s7
    if((pte = walk(pagetable, a, 0)) == 0)
    174c:	00000613          	li	a2,0
    1750:	00090593          	mv	a1,s2
    1754:	000a0513          	mv	a0,s4
    1758:	00000097          	auipc	ra,0x0
    175c:	a84080e7          	jalr	-1404(ra) # 11dc <walk>
    1760:	00050493          	mv	s1,a0
    1764:	f8050ce3          	beqz	a0,16fc <uvmunmap+0x54>
    if((*pte & PTE_V) == 0){
    1768:	00052603          	lw	a2,0(a0)
    176c:	00167793          	and	a5,a2,1
    1770:	f8078ee3          	beqz	a5,170c <uvmunmap+0x64>
    if(PTE_FLAGS(*pte) == PTE_V)
    1774:	3ff67793          	and	a5,a2,1023
    1778:	fb678ce3          	beq	a5,s6,1730 <uvmunmap+0x88>
    if(do_free){
    177c:	fc0a82e3          	beqz	s5,1740 <uvmunmap+0x98>
      pa = PTE2PA(*pte);
    1780:	00a65613          	srl	a2,a2,0xa
      kfree((void*)pa);
    1784:	00c61513          	sll	a0,a2,0xc
    1788:	fffff097          	auipc	ra,0xfffff
    178c:	2bc080e7          	jalr	700(ra) # a44 <kfree>
    1790:	fb1ff06f          	j	1740 <uvmunmap+0x98>
}
    1794:	02c12083          	lw	ra,44(sp)
    1798:	02812403          	lw	s0,40(sp)
    179c:	02412483          	lw	s1,36(sp)
    17a0:	02012903          	lw	s2,32(sp)
    17a4:	01c12983          	lw	s3,28(sp)
    17a8:	01812a03          	lw	s4,24(sp)
    17ac:	01412a83          	lw	s5,20(sp)
    17b0:	01012b03          	lw	s6,16(sp)
    17b4:	00c12b83          	lw	s7,12(sp)
    17b8:	03010113          	add	sp,sp,48
    17bc:	00008067          	ret

000017c0 <uvmcreate>:
{
    17c0:	ff010113          	add	sp,sp,-16
    17c4:	00112623          	sw	ra,12(sp)
    17c8:	00812423          	sw	s0,8(sp)
    17cc:	00912223          	sw	s1,4(sp)
    17d0:	01010413          	add	s0,sp,16
  pagetable = (pagetable_t) kalloc();
    17d4:	fffff097          	auipc	ra,0xfffff
    17d8:	3c4080e7          	jalr	964(ra) # b98 <kalloc>
  if(pagetable == 0)
    17dc:	02050863          	beqz	a0,180c <uvmcreate+0x4c>
    17e0:	00050493          	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    17e4:	00001637          	lui	a2,0x1
    17e8:	00000593          	li	a1,0
    17ec:	fffff097          	auipc	ra,0xfffff
    17f0:	68c080e7          	jalr	1676(ra) # e78 <memset>
}
    17f4:	00048513          	mv	a0,s1
    17f8:	00c12083          	lw	ra,12(sp)
    17fc:	00812403          	lw	s0,8(sp)
    1800:	00412483          	lw	s1,4(sp)
    1804:	01010113          	add	sp,sp,16
    1808:	00008067          	ret
    panic("uvmcreate: out of memory");
    180c:	00007517          	auipc	a0,0x7
    1810:	a4850513          	add	a0,a0,-1464 # 8254 <userret+0x1b4>
    1814:	fffff097          	auipc	ra,0xfffff
    1818:	e78080e7          	jalr	-392(ra) # 68c <panic>

0000181c <uvminit>:
{
    181c:	fe010113          	add	sp,sp,-32
    1820:	00112e23          	sw	ra,28(sp)
    1824:	00812c23          	sw	s0,24(sp)
    1828:	00912a23          	sw	s1,20(sp)
    182c:	01212823          	sw	s2,16(sp)
    1830:	01312623          	sw	s3,12(sp)
    1834:	01412423          	sw	s4,8(sp)
    1838:	02010413          	add	s0,sp,32
  if(sz >= PGSIZE)
    183c:	000017b7          	lui	a5,0x1
    1840:	06f67e63          	bgeu	a2,a5,18bc <uvminit+0xa0>
    1844:	00050a13          	mv	s4,a0
    1848:	00058993          	mv	s3,a1
    184c:	00060493          	mv	s1,a2
  mem = kalloc();
    1850:	fffff097          	auipc	ra,0xfffff
    1854:	348080e7          	jalr	840(ra) # b98 <kalloc>
    1858:	00050913          	mv	s2,a0
  memset(mem, 0, PGSIZE);
    185c:	00001637          	lui	a2,0x1
    1860:	00000593          	li	a1,0
    1864:	fffff097          	auipc	ra,0xfffff
    1868:	614080e7          	jalr	1556(ra) # e78 <memset>
  mappages(pagetable, 0, PGSIZE, (uint32)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    186c:	01e00713          	li	a4,30
    1870:	00090693          	mv	a3,s2
    1874:	00001637          	lui	a2,0x1
    1878:	00000593          	li	a1,0
    187c:	000a0513          	mv	a0,s4
    1880:	00000097          	auipc	ra,0x0
    1884:	bec080e7          	jalr	-1044(ra) # 146c <mappages>
  memmove(mem, src, sz);
    1888:	00048613          	mv	a2,s1
    188c:	00098593          	mv	a1,s3
    1890:	00090513          	mv	a0,s2
    1894:	fffff097          	auipc	ra,0xfffff
    1898:	660080e7          	jalr	1632(ra) # ef4 <memmove>
}
    189c:	01c12083          	lw	ra,28(sp)
    18a0:	01812403          	lw	s0,24(sp)
    18a4:	01412483          	lw	s1,20(sp)
    18a8:	01012903          	lw	s2,16(sp)
    18ac:	00c12983          	lw	s3,12(sp)
    18b0:	00812a03          	lw	s4,8(sp)
    18b4:	02010113          	add	sp,sp,32
    18b8:	00008067          	ret
    panic("inituvm: more than a page");
    18bc:	00007517          	auipc	a0,0x7
    18c0:	9b450513          	add	a0,a0,-1612 # 8270 <userret+0x1d0>
    18c4:	fffff097          	auipc	ra,0xfffff
    18c8:	dc8080e7          	jalr	-568(ra) # 68c <panic>

000018cc <uvmdealloc>:
{
    18cc:	ff010113          	add	sp,sp,-16
    18d0:	00112623          	sw	ra,12(sp)
    18d4:	00812423          	sw	s0,8(sp)
    18d8:	00912223          	sw	s1,4(sp)
    18dc:	01010413          	add	s0,sp,16
    return oldsz;
    18e0:	00058493          	mv	s1,a1
  if(newsz >= oldsz)
    18e4:	02b67463          	bgeu	a2,a1,190c <uvmdealloc+0x40>
    18e8:	00060493          	mv	s1,a2
  uint32 newup = PGROUNDUP(newsz);
    18ec:	000017b7          	lui	a5,0x1
    18f0:	fff78793          	add	a5,a5,-1 # fff <strncpy+0x1b>
    18f4:	00f60733          	add	a4,a2,a5
    18f8:	fffff6b7          	lui	a3,0xfffff
    18fc:	00d77733          	and	a4,a4,a3
  if(newup < PGROUNDUP(oldsz))
    1900:	00f587b3          	add	a5,a1,a5
    1904:	00d7f7b3          	and	a5,a5,a3
    1908:	00f76e63          	bltu	a4,a5,1924 <uvmdealloc+0x58>
}
    190c:	00048513          	mv	a0,s1
    1910:	00c12083          	lw	ra,12(sp)
    1914:	00812403          	lw	s0,8(sp)
    1918:	00412483          	lw	s1,4(sp)
    191c:	01010113          	add	sp,sp,16
    1920:	00008067          	ret
    uvmunmap(pagetable, newup, oldsz - newup, 1);
    1924:	00100693          	li	a3,1
    1928:	40e58633          	sub	a2,a1,a4
    192c:	00070593          	mv	a1,a4
    1930:	00000097          	auipc	ra,0x0
    1934:	d78080e7          	jalr	-648(ra) # 16a8 <uvmunmap>
    1938:	fd5ff06f          	j	190c <uvmdealloc+0x40>

0000193c <uvmalloc>:
  if(newsz < oldsz)
    193c:	10b66263          	bltu	a2,a1,1a40 <uvmalloc+0x104>
{
    1940:	fe010113          	add	sp,sp,-32
    1944:	00112e23          	sw	ra,28(sp)
    1948:	00812c23          	sw	s0,24(sp)
    194c:	00912a23          	sw	s1,20(sp)
    1950:	01212823          	sw	s2,16(sp)
    1954:	01312623          	sw	s3,12(sp)
    1958:	01412423          	sw	s4,8(sp)
    195c:	01512223          	sw	s5,4(sp)
    1960:	02010413          	add	s0,sp,32
    1964:	00050a93          	mv	s5,a0
    1968:	00060a13          	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    196c:	000017b7          	lui	a5,0x1
    1970:	fff78793          	add	a5,a5,-1 # fff <strncpy+0x1b>
    1974:	00f585b3          	add	a1,a1,a5
    1978:	fffff7b7          	lui	a5,0xfffff
    197c:	00f5f9b3          	and	s3,a1,a5
  for(; a < newsz; a += PGSIZE){
    1980:	0cc9f463          	bgeu	s3,a2,1a48 <uvmalloc+0x10c>
  a = oldsz;
    1984:	00098913          	mv	s2,s3
    mem = kalloc();
    1988:	fffff097          	auipc	ra,0xfffff
    198c:	210080e7          	jalr	528(ra) # b98 <kalloc>
    1990:	00050493          	mv	s1,a0
    if(mem == 0){
    1994:	04050463          	beqz	a0,19dc <uvmalloc+0xa0>
    memset(mem, 0, PGSIZE);
    1998:	00001637          	lui	a2,0x1
    199c:	00000593          	li	a1,0
    19a0:	fffff097          	auipc	ra,0xfffff
    19a4:	4d8080e7          	jalr	1240(ra) # e78 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint32)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    19a8:	01e00713          	li	a4,30
    19ac:	00048693          	mv	a3,s1
    19b0:	00001637          	lui	a2,0x1
    19b4:	00090593          	mv	a1,s2
    19b8:	000a8513          	mv	a0,s5
    19bc:	00000097          	auipc	ra,0x0
    19c0:	ab0080e7          	jalr	-1360(ra) # 146c <mappages>
    19c4:	04051a63          	bnez	a0,1a18 <uvmalloc+0xdc>
  for(; a < newsz; a += PGSIZE){
    19c8:	000017b7          	lui	a5,0x1
    19cc:	00f90933          	add	s2,s2,a5
    19d0:	fb496ce3          	bltu	s2,s4,1988 <uvmalloc+0x4c>
  return newsz;
    19d4:	000a0513          	mv	a0,s4
    19d8:	01c0006f          	j	19f4 <uvmalloc+0xb8>
      uvmdealloc(pagetable, a, oldsz);
    19dc:	00098613          	mv	a2,s3
    19e0:	00090593          	mv	a1,s2
    19e4:	000a8513          	mv	a0,s5
    19e8:	00000097          	auipc	ra,0x0
    19ec:	ee4080e7          	jalr	-284(ra) # 18cc <uvmdealloc>
      return 0;
    19f0:	00000513          	li	a0,0
}
    19f4:	01c12083          	lw	ra,28(sp)
    19f8:	01812403          	lw	s0,24(sp)
    19fc:	01412483          	lw	s1,20(sp)
    1a00:	01012903          	lw	s2,16(sp)
    1a04:	00c12983          	lw	s3,12(sp)
    1a08:	00812a03          	lw	s4,8(sp)
    1a0c:	00412a83          	lw	s5,4(sp)
    1a10:	02010113          	add	sp,sp,32
    1a14:	00008067          	ret
      kfree(mem);
    1a18:	00048513          	mv	a0,s1
    1a1c:	fffff097          	auipc	ra,0xfffff
    1a20:	028080e7          	jalr	40(ra) # a44 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    1a24:	00098613          	mv	a2,s3
    1a28:	00090593          	mv	a1,s2
    1a2c:	000a8513          	mv	a0,s5
    1a30:	00000097          	auipc	ra,0x0
    1a34:	e9c080e7          	jalr	-356(ra) # 18cc <uvmdealloc>
      return 0;
    1a38:	00000513          	li	a0,0
    1a3c:	fb9ff06f          	j	19f4 <uvmalloc+0xb8>
    return oldsz;
    1a40:	00058513          	mv	a0,a1
}
    1a44:	00008067          	ret
  return newsz;
    1a48:	00060513          	mv	a0,a2
    1a4c:	fa9ff06f          	j	19f4 <uvmalloc+0xb8>

00001a50 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint32 sz)
{
    1a50:	ff010113          	add	sp,sp,-16
    1a54:	00112623          	sw	ra,12(sp)
    1a58:	00812423          	sw	s0,8(sp)
    1a5c:	00912223          	sw	s1,4(sp)
    1a60:	01010413          	add	s0,sp,16
    1a64:	00050493          	mv	s1,a0
    1a68:	00058613          	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    1a6c:	00100693          	li	a3,1
    1a70:	00000593          	li	a1,0
    1a74:	00000097          	auipc	ra,0x0
    1a78:	c34080e7          	jalr	-972(ra) # 16a8 <uvmunmap>
  freewalk(pagetable);
    1a7c:	00048513          	mv	a0,s1
    1a80:	00000097          	auipc	ra,0x0
    1a84:	824080e7          	jalr	-2012(ra) # 12a4 <freewalk>
}
    1a88:	00c12083          	lw	ra,12(sp)
    1a8c:	00812403          	lw	s0,8(sp)
    1a90:	00412483          	lw	s1,4(sp)
    1a94:	01010113          	add	sp,sp,16
    1a98:	00008067          	ret

00001a9c <uvmcopy>:
  pte_t *pte;
  uint32 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    1a9c:	12060a63          	beqz	a2,1bd0 <uvmcopy+0x134>
{
    1aa0:	fd010113          	add	sp,sp,-48
    1aa4:	02112623          	sw	ra,44(sp)
    1aa8:	02812423          	sw	s0,40(sp)
    1aac:	02912223          	sw	s1,36(sp)
    1ab0:	03212023          	sw	s2,32(sp)
    1ab4:	01312e23          	sw	s3,28(sp)
    1ab8:	01412c23          	sw	s4,24(sp)
    1abc:	01512a23          	sw	s5,20(sp)
    1ac0:	01612823          	sw	s6,16(sp)
    1ac4:	01712623          	sw	s7,12(sp)
    1ac8:	03010413          	add	s0,sp,48
    1acc:	00050b13          	mv	s6,a0
    1ad0:	00058a93          	mv	s5,a1
    1ad4:	00060a13          	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    1ad8:	00000993          	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    1adc:	00000613          	li	a2,0
    1ae0:	00098593          	mv	a1,s3
    1ae4:	000b0513          	mv	a0,s6
    1ae8:	fffff097          	auipc	ra,0xfffff
    1aec:	6f4080e7          	jalr	1780(ra) # 11dc <walk>
    1af0:	06050663          	beqz	a0,1b5c <uvmcopy+0xc0>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    1af4:	00052703          	lw	a4,0(a0)
    1af8:	00177793          	and	a5,a4,1
    1afc:	06078863          	beqz	a5,1b6c <uvmcopy+0xd0>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    1b00:	00a75593          	srl	a1,a4,0xa
    1b04:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    1b08:	3ff77493          	and	s1,a4,1023
    if((mem = kalloc()) == 0)
    1b0c:	fffff097          	auipc	ra,0xfffff
    1b10:	08c080e7          	jalr	140(ra) # b98 <kalloc>
    1b14:	00050913          	mv	s2,a0
    1b18:	06050863          	beqz	a0,1b88 <uvmcopy+0xec>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    1b1c:	00001637          	lui	a2,0x1
    1b20:	000b8593          	mv	a1,s7
    1b24:	fffff097          	auipc	ra,0xfffff
    1b28:	3d0080e7          	jalr	976(ra) # ef4 <memmove>
    if(mappages(new, i, PGSIZE, (uint32)mem, flags) != 0){
    1b2c:	00048713          	mv	a4,s1
    1b30:	00090693          	mv	a3,s2
    1b34:	00001637          	lui	a2,0x1
    1b38:	00098593          	mv	a1,s3
    1b3c:	000a8513          	mv	a0,s5
    1b40:	00000097          	auipc	ra,0x0
    1b44:	92c080e7          	jalr	-1748(ra) # 146c <mappages>
    1b48:	02051a63          	bnez	a0,1b7c <uvmcopy+0xe0>
  for(i = 0; i < sz; i += PGSIZE){
    1b4c:	000017b7          	lui	a5,0x1
    1b50:	00f989b3          	add	s3,s3,a5
    1b54:	f949e4e3          	bltu	s3,s4,1adc <uvmcopy+0x40>
    1b58:	04c0006f          	j	1ba4 <uvmcopy+0x108>
      panic("uvmcopy: pte should exist");
    1b5c:	00006517          	auipc	a0,0x6
    1b60:	73050513          	add	a0,a0,1840 # 828c <userret+0x1ec>
    1b64:	fffff097          	auipc	ra,0xfffff
    1b68:	b28080e7          	jalr	-1240(ra) # 68c <panic>
      panic("uvmcopy: page not present");
    1b6c:	00006517          	auipc	a0,0x6
    1b70:	73c50513          	add	a0,a0,1852 # 82a8 <userret+0x208>
    1b74:	fffff097          	auipc	ra,0xfffff
    1b78:	b18080e7          	jalr	-1256(ra) # 68c <panic>
      kfree(mem);
    1b7c:	00090513          	mv	a0,s2
    1b80:	fffff097          	auipc	ra,0xfffff
    1b84:	ec4080e7          	jalr	-316(ra) # a44 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    1b88:	00100693          	li	a3,1
    1b8c:	00098613          	mv	a2,s3
    1b90:	00000593          	li	a1,0
    1b94:	000a8513          	mv	a0,s5
    1b98:	00000097          	auipc	ra,0x0
    1b9c:	b10080e7          	jalr	-1264(ra) # 16a8 <uvmunmap>
  return -1;
    1ba0:	fff00513          	li	a0,-1
}
    1ba4:	02c12083          	lw	ra,44(sp)
    1ba8:	02812403          	lw	s0,40(sp)
    1bac:	02412483          	lw	s1,36(sp)
    1bb0:	02012903          	lw	s2,32(sp)
    1bb4:	01c12983          	lw	s3,28(sp)
    1bb8:	01812a03          	lw	s4,24(sp)
    1bbc:	01412a83          	lw	s5,20(sp)
    1bc0:	01012b03          	lw	s6,16(sp)
    1bc4:	00c12b83          	lw	s7,12(sp)
    1bc8:	03010113          	add	sp,sp,48
    1bcc:	00008067          	ret
  return 0;
    1bd0:	00000513          	li	a0,0
}
    1bd4:	00008067          	ret

00001bd8 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint32 va)
{
    1bd8:	ff010113          	add	sp,sp,-16
    1bdc:	00112623          	sw	ra,12(sp)
    1be0:	00812423          	sw	s0,8(sp)
    1be4:	01010413          	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    1be8:	00000613          	li	a2,0
    1bec:	fffff097          	auipc	ra,0xfffff
    1bf0:	5f0080e7          	jalr	1520(ra) # 11dc <walk>
  if(pte == 0)
    1bf4:	02050063          	beqz	a0,1c14 <uvmclear+0x3c>
    panic("uvmclear");
  *pte &= ~PTE_U;
    1bf8:	00052783          	lw	a5,0(a0)
    1bfc:	fef7f793          	and	a5,a5,-17
    1c00:	00f52023          	sw	a5,0(a0)
}
    1c04:	00c12083          	lw	ra,12(sp)
    1c08:	00812403          	lw	s0,8(sp)
    1c0c:	01010113          	add	sp,sp,16
    1c10:	00008067          	ret
    panic("uvmclear");
    1c14:	00006517          	auipc	a0,0x6
    1c18:	6b050513          	add	a0,a0,1712 # 82c4 <userret+0x224>
    1c1c:	fffff097          	auipc	ra,0xfffff
    1c20:	a70080e7          	jalr	-1424(ra) # 68c <panic>

00001c24 <copyout>:
int
copyout(pagetable_t pagetable, uint32 dstva, char *src, uint32 len)
{
  uint32 n, va0, pa0;

  while(len > 0){
    1c24:	0a068663          	beqz	a3,1cd0 <copyout+0xac>
{
    1c28:	fd010113          	add	sp,sp,-48
    1c2c:	02112623          	sw	ra,44(sp)
    1c30:	02812423          	sw	s0,40(sp)
    1c34:	02912223          	sw	s1,36(sp)
    1c38:	03212023          	sw	s2,32(sp)
    1c3c:	01312e23          	sw	s3,28(sp)
    1c40:	01412c23          	sw	s4,24(sp)
    1c44:	01512a23          	sw	s5,20(sp)
    1c48:	01612823          	sw	s6,16(sp)
    1c4c:	01712623          	sw	s7,12(sp)
    1c50:	01812423          	sw	s8,8(sp)
    1c54:	03010413          	add	s0,sp,48
    1c58:	00050b13          	mv	s6,a0
    1c5c:	00058c13          	mv	s8,a1
    1c60:	00060a13          	mv	s4,a2
    1c64:	00068993          	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    1c68:	fffffbb7          	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    1c6c:	00001ab7          	lui	s5,0x1
    1c70:	02c0006f          	j	1c9c <copyout+0x78>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    1c74:	01850533          	add	a0,a0,s8
    1c78:	00048613          	mv	a2,s1
    1c7c:	000a0593          	mv	a1,s4
    1c80:	41250533          	sub	a0,a0,s2
    1c84:	fffff097          	auipc	ra,0xfffff
    1c88:	270080e7          	jalr	624(ra) # ef4 <memmove>

    len -= n;
    1c8c:	409989b3          	sub	s3,s3,s1
    src += n;
    1c90:	009a0a33          	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    1c94:	01590c33          	add	s8,s2,s5
  while(len > 0){
    1c98:	02098863          	beqz	s3,1cc8 <copyout+0xa4>
    va0 = PGROUNDDOWN(dstva);
    1c9c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    1ca0:	00090593          	mv	a1,s2
    1ca4:	000b0513          	mv	a0,s6
    1ca8:	fffff097          	auipc	ra,0xfffff
    1cac:	6d8080e7          	jalr	1752(ra) # 1380 <walkaddr>
    if(pa0 == 0)
    1cb0:	02050463          	beqz	a0,1cd8 <copyout+0xb4>
    n = PGSIZE - (dstva - va0);
    1cb4:	418904b3          	sub	s1,s2,s8
    1cb8:	015484b3          	add	s1,s1,s5
    1cbc:	fa99fce3          	bgeu	s3,s1,1c74 <copyout+0x50>
    1cc0:	00098493          	mv	s1,s3
    1cc4:	fb1ff06f          	j	1c74 <copyout+0x50>
  }
  return 0;
    1cc8:	00000513          	li	a0,0
    1ccc:	0100006f          	j	1cdc <copyout+0xb8>
    1cd0:	00000513          	li	a0,0
}
    1cd4:	00008067          	ret
      return -1;
    1cd8:	fff00513          	li	a0,-1
}
    1cdc:	02c12083          	lw	ra,44(sp)
    1ce0:	02812403          	lw	s0,40(sp)
    1ce4:	02412483          	lw	s1,36(sp)
    1ce8:	02012903          	lw	s2,32(sp)
    1cec:	01c12983          	lw	s3,28(sp)
    1cf0:	01812a03          	lw	s4,24(sp)
    1cf4:	01412a83          	lw	s5,20(sp)
    1cf8:	01012b03          	lw	s6,16(sp)
    1cfc:	00c12b83          	lw	s7,12(sp)
    1d00:	00812c03          	lw	s8,8(sp)
    1d04:	03010113          	add	sp,sp,48
    1d08:	00008067          	ret

00001d0c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint32 srcva, uint32 len)
{
  uint32 n, va0, pa0;

  while(len > 0){
    1d0c:	0a068663          	beqz	a3,1db8 <copyin+0xac>
{
    1d10:	fd010113          	add	sp,sp,-48
    1d14:	02112623          	sw	ra,44(sp)
    1d18:	02812423          	sw	s0,40(sp)
    1d1c:	02912223          	sw	s1,36(sp)
    1d20:	03212023          	sw	s2,32(sp)
    1d24:	01312e23          	sw	s3,28(sp)
    1d28:	01412c23          	sw	s4,24(sp)
    1d2c:	01512a23          	sw	s5,20(sp)
    1d30:	01612823          	sw	s6,16(sp)
    1d34:	01712623          	sw	s7,12(sp)
    1d38:	01812423          	sw	s8,8(sp)
    1d3c:	03010413          	add	s0,sp,48
    1d40:	00050b13          	mv	s6,a0
    1d44:	00058a13          	mv	s4,a1
    1d48:	00060c13          	mv	s8,a2
    1d4c:	00068993          	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    1d50:	fffffbb7          	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    1d54:	00001ab7          	lui	s5,0x1
    1d58:	02c0006f          	j	1d84 <copyin+0x78>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    1d5c:	018505b3          	add	a1,a0,s8
    1d60:	00048613          	mv	a2,s1
    1d64:	412585b3          	sub	a1,a1,s2
    1d68:	000a0513          	mv	a0,s4
    1d6c:	fffff097          	auipc	ra,0xfffff
    1d70:	188080e7          	jalr	392(ra) # ef4 <memmove>

    len -= n;
    1d74:	409989b3          	sub	s3,s3,s1
    dst += n;
    1d78:	009a0a33          	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    1d7c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    1d80:	02098863          	beqz	s3,1db0 <copyin+0xa4>
    va0 = PGROUNDDOWN(srcva);
    1d84:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    1d88:	00090593          	mv	a1,s2
    1d8c:	000b0513          	mv	a0,s6
    1d90:	fffff097          	auipc	ra,0xfffff
    1d94:	5f0080e7          	jalr	1520(ra) # 1380 <walkaddr>
    if(pa0 == 0)
    1d98:	02050463          	beqz	a0,1dc0 <copyin+0xb4>
    n = PGSIZE - (srcva - va0);
    1d9c:	418904b3          	sub	s1,s2,s8
    1da0:	015484b3          	add	s1,s1,s5
    1da4:	fa99fce3          	bgeu	s3,s1,1d5c <copyin+0x50>
    1da8:	00098493          	mv	s1,s3
    1dac:	fb1ff06f          	j	1d5c <copyin+0x50>
  }
  return 0;
    1db0:	00000513          	li	a0,0
    1db4:	0100006f          	j	1dc4 <copyin+0xb8>
    1db8:	00000513          	li	a0,0
}
    1dbc:	00008067          	ret
      return -1;
    1dc0:	fff00513          	li	a0,-1
}
    1dc4:	02c12083          	lw	ra,44(sp)
    1dc8:	02812403          	lw	s0,40(sp)
    1dcc:	02412483          	lw	s1,36(sp)
    1dd0:	02012903          	lw	s2,32(sp)
    1dd4:	01c12983          	lw	s3,28(sp)
    1dd8:	01812a03          	lw	s4,24(sp)
    1ddc:	01412a83          	lw	s5,20(sp)
    1de0:	01012b03          	lw	s6,16(sp)
    1de4:	00c12b83          	lw	s7,12(sp)
    1de8:	00812c03          	lw	s8,8(sp)
    1dec:	03010113          	add	sp,sp,48
    1df0:	00008067          	ret

00001df4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint32 srcva, uint32 max)
{
  uint32 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    1df4:	10068863          	beqz	a3,1f04 <copyinstr+0x110>
{
    1df8:	fd010113          	add	sp,sp,-48
    1dfc:	02112623          	sw	ra,44(sp)
    1e00:	02812423          	sw	s0,40(sp)
    1e04:	02912223          	sw	s1,36(sp)
    1e08:	03212023          	sw	s2,32(sp)
    1e0c:	01312e23          	sw	s3,28(sp)
    1e10:	01412c23          	sw	s4,24(sp)
    1e14:	01512a23          	sw	s5,20(sp)
    1e18:	01612823          	sw	s6,16(sp)
    1e1c:	01712623          	sw	s7,12(sp)
    1e20:	03010413          	add	s0,sp,48
    1e24:	00050a13          	mv	s4,a0
    1e28:	00058b13          	mv	s6,a1
    1e2c:	00060b93          	mv	s7,a2
    1e30:	00068493          	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    1e34:	fffffab7          	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    1e38:	000019b7          	lui	s3,0x1
    1e3c:	0440006f          	j	1e80 <copyinstr+0x8c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    1e40:	00078023          	sb	zero,0(a5) # 1000 <strncpy+0x1c>
    1e44:	00100793          	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    1e48:	fff78513          	add	a0,a5,-1
    return 0;
  } else {
    return -1;
  }
}
    1e4c:	02c12083          	lw	ra,44(sp)
    1e50:	02812403          	lw	s0,40(sp)
    1e54:	02412483          	lw	s1,36(sp)
    1e58:	02012903          	lw	s2,32(sp)
    1e5c:	01c12983          	lw	s3,28(sp)
    1e60:	01812a03          	lw	s4,24(sp)
    1e64:	01412a83          	lw	s5,20(sp)
    1e68:	01012b03          	lw	s6,16(sp)
    1e6c:	00c12b83          	lw	s7,12(sp)
    1e70:	03010113          	add	sp,sp,48
    1e74:	00008067          	ret
    srcva = va0 + PGSIZE;
    1e78:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    1e7c:	06048c63          	beqz	s1,1ef4 <copyinstr+0x100>
    va0 = PGROUNDDOWN(srcva);
    1e80:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    1e84:	00090593          	mv	a1,s2
    1e88:	000a0513          	mv	a0,s4
    1e8c:	fffff097          	auipc	ra,0xfffff
    1e90:	4f4080e7          	jalr	1268(ra) # 1380 <walkaddr>
    if(pa0 == 0)
    1e94:	06050463          	beqz	a0,1efc <copyinstr+0x108>
    n = PGSIZE - (srcva - va0);
    1e98:	417906b3          	sub	a3,s2,s7
    1e9c:	013686b3          	add	a3,a3,s3
    1ea0:	00d4f463          	bgeu	s1,a3,1ea8 <copyinstr+0xb4>
    1ea4:	00048693          	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    1ea8:	01750533          	add	a0,a0,s7
    1eac:	41250533          	sub	a0,a0,s2
    while(n > 0){
    1eb0:	fc0684e3          	beqz	a3,1e78 <copyinstr+0x84>
    1eb4:	000b0793          	mv	a5,s6
    1eb8:	000b0813          	mv	a6,s6
      if(*p == '\0'){
    1ebc:	41650633          	sub	a2,a0,s6
    while(n > 0){
    1ec0:	00db06b3          	add	a3,s6,a3
    1ec4:	00078593          	mv	a1,a5
      if(*p == '\0'){
    1ec8:	00f60733          	add	a4,a2,a5
    1ecc:	00074703          	lbu	a4,0(a4) # fffff000 <end+0xfffddfec>
    1ed0:	f60708e3          	beqz	a4,1e40 <copyinstr+0x4c>
        *dst = *p;
    1ed4:	00e78023          	sb	a4,0(a5)
      dst++;
    1ed8:	00178793          	add	a5,a5,1
    while(n > 0){
    1edc:	fed794e3          	bne	a5,a3,1ec4 <copyinstr+0xd0>
    1ee0:	fff48493          	add	s1,s1,-1
    1ee4:	010484b3          	add	s1,s1,a6
      --max;
    1ee8:	40b484b3          	sub	s1,s1,a1
      dst++;
    1eec:	00078b13          	mv	s6,a5
    1ef0:	f89ff06f          	j	1e78 <copyinstr+0x84>
    1ef4:	00000793          	li	a5,0
    1ef8:	f51ff06f          	j	1e48 <copyinstr+0x54>
      return -1;
    1efc:	fff00513          	li	a0,-1
    1f00:	f4dff06f          	j	1e4c <copyinstr+0x58>
  int got_null = 0;
    1f04:	00000793          	li	a5,0
  if(got_null){
    1f08:	fff78513          	add	a0,a5,-1
}
    1f0c:	00008067          	ret

00001f10 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    1f10:	ff010113          	add	sp,sp,-16
    1f14:	00112623          	sw	ra,12(sp)
    1f18:	00812423          	sw	s0,8(sp)
    1f1c:	00912223          	sw	s1,4(sp)
    1f20:	01010413          	add	s0,sp,16
    1f24:	00050493          	mv	s1,a0
  if(!holding(&p->lock))
    1f28:	fffff097          	auipc	ra,0xfffff
    1f2c:	e18080e7          	jalr	-488(ra) # d40 <holding>
    1f30:	02050063          	beqz	a0,1f50 <wakeup1+0x40>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    1f34:	0144a783          	lw	a5,20(s1)
    1f38:	02978463          	beq	a5,s1,1f60 <wakeup1+0x50>
    p->state = RUNNABLE;
  }
}
    1f3c:	00c12083          	lw	ra,12(sp)
    1f40:	00812403          	lw	s0,8(sp)
    1f44:	00412483          	lw	s1,4(sp)
    1f48:	01010113          	add	sp,sp,16
    1f4c:	00008067          	ret
    panic("wakeup1");
    1f50:	00006517          	auipc	a0,0x6
    1f54:	38050513          	add	a0,a0,896 # 82d0 <userret+0x230>
    1f58:	ffffe097          	auipc	ra,0xffffe
    1f5c:	734080e7          	jalr	1844(ra) # 68c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    1f60:	00c4a703          	lw	a4,12(s1)
    1f64:	00100793          	li	a5,1
    1f68:	fcf71ae3          	bne	a4,a5,1f3c <wakeup1+0x2c>
    p->state = RUNNABLE;
    1f6c:	00200793          	li	a5,2
    1f70:	00f4a623          	sw	a5,12(s1)
}
    1f74:	fc9ff06f          	j	1f3c <wakeup1+0x2c>

00001f78 <procinit>:
{
    1f78:	fd010113          	add	sp,sp,-48
    1f7c:	02112623          	sw	ra,44(sp)
    1f80:	02812423          	sw	s0,40(sp)
    1f84:	02912223          	sw	s1,36(sp)
    1f88:	03212023          	sw	s2,32(sp)
    1f8c:	01312e23          	sw	s3,28(sp)
    1f90:	01412c23          	sw	s4,24(sp)
    1f94:	01512a23          	sw	s5,20(sp)
    1f98:	01612823          	sw	s6,16(sp)
    1f9c:	01712623          	sw	s7,12(sp)
    1fa0:	03010413          	add	s0,sp,48
  initlock(&pid_lock, "nextpid");
    1fa4:	00006597          	auipc	a1,0x6
    1fa8:	33458593          	add	a1,a1,820 # 82d8 <userret+0x238>
    1fac:	00010517          	auipc	a0,0x10
    1fb0:	50c50513          	add	a0,a0,1292 # 124b8 <pid_lock>
    1fb4:	fffff097          	auipc	ra,0xfffff
    1fb8:	c6c080e7          	jalr	-916(ra) # c20 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    1fbc:	00010917          	auipc	s2,0x10
    1fc0:	72890913          	add	s2,s2,1832 # 126e4 <proc>
      initlock(&p->lock, "proc");
    1fc4:	00006b97          	auipc	s7,0x6
    1fc8:	31cb8b93          	add	s7,s7,796 # 82e0 <userret+0x240>
      uint32 va = KSTACK((int) (p - proc));
    1fcc:	00090b13          	mv	s6,s2
    1fd0:	aaaab9b7          	lui	s3,0xaaaab
    1fd4:	aab98993          	add	s3,s3,-1365 # aaaaaaab <end+0xaaa89a97>
    1fd8:	fffffab7          	lui	s5,0xfffff
  for(p = proc; p < &proc[NPROC]; p++) {
    1fdc:	00013a17          	auipc	s4,0x13
    1fe0:	708a0a13          	add	s4,s4,1800 # 156e4 <tickslock>
      initlock(&p->lock, "proc");
    1fe4:	000b8593          	mv	a1,s7
    1fe8:	00090513          	mv	a0,s2
    1fec:	fffff097          	auipc	ra,0xfffff
    1ff0:	c34080e7          	jalr	-972(ra) # c20 <initlock>
      char *pa = kalloc();
    1ff4:	fffff097          	auipc	ra,0xfffff
    1ff8:	ba4080e7          	jalr	-1116(ra) # b98 <kalloc>
    1ffc:	00050593          	mv	a1,a0
      if(pa == 0)
    2000:	06050863          	beqz	a0,2070 <procinit+0xf8>
      uint32 va = KSTACK((int) (p - proc));
    2004:	416904b3          	sub	s1,s2,s6
    2008:	4064d493          	sra	s1,s1,0x6
    200c:	033484b3          	mul	s1,s1,s3
    2010:	00148493          	add	s1,s1,1
    2014:	00d49493          	sll	s1,s1,0xd
    2018:	409a84b3          	sub	s1,s5,s1
      kvmmap(va, (uint32)pa, PGSIZE, PTE_R | PTE_W);
    201c:	00600693          	li	a3,6
    2020:	00001637          	lui	a2,0x1
    2024:	00048513          	mv	a0,s1
    2028:	fffff097          	auipc	ra,0xfffff
    202c:	528080e7          	jalr	1320(ra) # 1550 <kvmmap>
      p->kstack = va;
    2030:	02992223          	sw	s1,36(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    2034:	0c090913          	add	s2,s2,192
    2038:	fb4916e3          	bne	s2,s4,1fe4 <procinit+0x6c>
  kvminithart();
    203c:	fffff097          	auipc	ra,0xfffff
    2040:	310080e7          	jalr	784(ra) # 134c <kvminithart>
}
    2044:	02c12083          	lw	ra,44(sp)
    2048:	02812403          	lw	s0,40(sp)
    204c:	02412483          	lw	s1,36(sp)
    2050:	02012903          	lw	s2,32(sp)
    2054:	01c12983          	lw	s3,28(sp)
    2058:	01812a03          	lw	s4,24(sp)
    205c:	01412a83          	lw	s5,20(sp)
    2060:	01012b03          	lw	s6,16(sp)
    2064:	00c12b83          	lw	s7,12(sp)
    2068:	03010113          	add	sp,sp,48
    206c:	00008067          	ret
        panic("kalloc");
    2070:	00006517          	auipc	a0,0x6
    2074:	27850513          	add	a0,a0,632 # 82e8 <userret+0x248>
    2078:	ffffe097          	auipc	ra,0xffffe
    207c:	614080e7          	jalr	1556(ra) # 68c <panic>

00002080 <cpuid>:
{
    2080:	ff010113          	add	sp,sp,-16
    2084:	00812623          	sw	s0,12(sp)
    2088:	01010413          	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    208c:	00020513          	mv	a0,tp
}
    2090:	00c12403          	lw	s0,12(sp)
    2094:	01010113          	add	sp,sp,16
    2098:	00008067          	ret

0000209c <mycpu>:
mycpu(void) {
    209c:	ff010113          	add	sp,sp,-16
    20a0:	00812623          	sw	s0,12(sp)
    20a4:	01010413          	add	s0,sp,16
    20a8:	00020713          	mv	a4,tp
  struct cpu *c = &cpus[id];
    20ac:	00471793          	sll	a5,a4,0x4
    20b0:	00e787b3          	add	a5,a5,a4
    20b4:	00279793          	sll	a5,a5,0x2
}
    20b8:	00010517          	auipc	a0,0x10
    20bc:	40c50513          	add	a0,a0,1036 # 124c4 <cpus>
    20c0:	00f50533          	add	a0,a0,a5
    20c4:	00c12403          	lw	s0,12(sp)
    20c8:	01010113          	add	sp,sp,16
    20cc:	00008067          	ret

000020d0 <myproc>:
myproc(void) {
    20d0:	ff010113          	add	sp,sp,-16
    20d4:	00112623          	sw	ra,12(sp)
    20d8:	00812423          	sw	s0,8(sp)
    20dc:	00912223          	sw	s1,4(sp)
    20e0:	01010413          	add	s0,sp,16
  push_off();
    20e4:	fffff097          	auipc	ra,0xfffff
    20e8:	b60080e7          	jalr	-1184(ra) # c44 <push_off>
    20ec:	00020713          	mv	a4,tp
  struct proc *p = c->proc;
    20f0:	00471793          	sll	a5,a4,0x4
    20f4:	00e787b3          	add	a5,a5,a4
    20f8:	00279793          	sll	a5,a5,0x2
    20fc:	00010717          	auipc	a4,0x10
    2100:	3bc70713          	add	a4,a4,956 # 124b8 <pid_lock>
    2104:	00f707b3          	add	a5,a4,a5
    2108:	00c7a483          	lw	s1,12(a5)
  pop_off();
    210c:	fffff097          	auipc	ra,0xfffff
    2110:	bac080e7          	jalr	-1108(ra) # cb8 <pop_off>
}
    2114:	00048513          	mv	a0,s1
    2118:	00c12083          	lw	ra,12(sp)
    211c:	00812403          	lw	s0,8(sp)
    2120:	00412483          	lw	s1,4(sp)
    2124:	01010113          	add	sp,sp,16
    2128:	00008067          	ret

0000212c <forkret>:
{
    212c:	ff010113          	add	sp,sp,-16
    2130:	00112623          	sw	ra,12(sp)
    2134:	00812423          	sw	s0,8(sp)
    2138:	01010413          	add	s0,sp,16
  release(&myproc()->lock);
    213c:	00000097          	auipc	ra,0x0
    2140:	f94080e7          	jalr	-108(ra) # 20d0 <myproc>
    2144:	fffff097          	auipc	ra,0xfffff
    2148:	cd4080e7          	jalr	-812(ra) # e18 <release>
  if (first) {
    214c:	00007797          	auipc	a5,0x7
    2150:	eec7a783          	lw	a5,-276(a5) # 9038 <first.1>
    2154:	00079e63          	bnez	a5,2170 <forkret+0x44>
  usertrapret();
    2158:	00001097          	auipc	ra,0x1
    215c:	000080e7          	jalr	ra # 3158 <usertrapret>
}
    2160:	00c12083          	lw	ra,12(sp)
    2164:	00812403          	lw	s0,8(sp)
    2168:	01010113          	add	sp,sp,16
    216c:	00008067          	ret
    first = 0;
    2170:	00007797          	auipc	a5,0x7
    2174:	ec07a423          	sw	zero,-312(a5) # 9038 <first.1>
    fsinit(ROOTDEV);
    2178:	00100513          	li	a0,1
    217c:	00002097          	auipc	ra,0x2
    2180:	1c0080e7          	jalr	448(ra) # 433c <fsinit>
    2184:	fd5ff06f          	j	2158 <forkret+0x2c>

00002188 <allocpid>:
allocpid() {
    2188:	ff010113          	add	sp,sp,-16
    218c:	00112623          	sw	ra,12(sp)
    2190:	00812423          	sw	s0,8(sp)
    2194:	00912223          	sw	s1,4(sp)
    2198:	01212023          	sw	s2,0(sp)
    219c:	01010413          	add	s0,sp,16
  acquire(&pid_lock);
    21a0:	00010917          	auipc	s2,0x10
    21a4:	31890913          	add	s2,s2,792 # 124b8 <pid_lock>
    21a8:	00090513          	mv	a0,s2
    21ac:	fffff097          	auipc	ra,0xfffff
    21b0:	bf8080e7          	jalr	-1032(ra) # da4 <acquire>
  pid = nextpid;
    21b4:	00007797          	auipc	a5,0x7
    21b8:	e8878793          	add	a5,a5,-376 # 903c <nextpid>
    21bc:	0007a483          	lw	s1,0(a5)
  nextpid = nextpid + 1;
    21c0:	00148713          	add	a4,s1,1
    21c4:	00e7a023          	sw	a4,0(a5)
  release(&pid_lock);
    21c8:	00090513          	mv	a0,s2
    21cc:	fffff097          	auipc	ra,0xfffff
    21d0:	c4c080e7          	jalr	-948(ra) # e18 <release>
}
    21d4:	00048513          	mv	a0,s1
    21d8:	00c12083          	lw	ra,12(sp)
    21dc:	00812403          	lw	s0,8(sp)
    21e0:	00412483          	lw	s1,4(sp)
    21e4:	00012903          	lw	s2,0(sp)
    21e8:	01010113          	add	sp,sp,16
    21ec:	00008067          	ret

000021f0 <proc_pagetable>:
{
    21f0:	ff010113          	add	sp,sp,-16
    21f4:	00112623          	sw	ra,12(sp)
    21f8:	00812423          	sw	s0,8(sp)
    21fc:	00912223          	sw	s1,4(sp)
    2200:	01212023          	sw	s2,0(sp)
    2204:	01010413          	add	s0,sp,16
    2208:	00050913          	mv	s2,a0
  pagetable = uvmcreate();
    220c:	fffff097          	auipc	ra,0xfffff
    2210:	5b4080e7          	jalr	1460(ra) # 17c0 <uvmcreate>
    2214:	00050493          	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    2218:	00a00713          	li	a4,10
    221c:	00006697          	auipc	a3,0x6
    2220:	de468693          	add	a3,a3,-540 # 8000 <trampoline>
    2224:	00001637          	lui	a2,0x1
    2228:	fffff5b7          	lui	a1,0xfffff
    222c:	fffff097          	auipc	ra,0xfffff
    2230:	240080e7          	jalr	576(ra) # 146c <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    2234:	00600713          	li	a4,6
    2238:	03092683          	lw	a3,48(s2)
    223c:	00001637          	lui	a2,0x1
    2240:	ffffe5b7          	lui	a1,0xffffe
    2244:	00048513          	mv	a0,s1
    2248:	fffff097          	auipc	ra,0xfffff
    224c:	224080e7          	jalr	548(ra) # 146c <mappages>
}
    2250:	00048513          	mv	a0,s1
    2254:	00c12083          	lw	ra,12(sp)
    2258:	00812403          	lw	s0,8(sp)
    225c:	00412483          	lw	s1,4(sp)
    2260:	00012903          	lw	s2,0(sp)
    2264:	01010113          	add	sp,sp,16
    2268:	00008067          	ret

0000226c <allocproc>:
{
    226c:	ff010113          	add	sp,sp,-16
    2270:	00112623          	sw	ra,12(sp)
    2274:	00812423          	sw	s0,8(sp)
    2278:	00912223          	sw	s1,4(sp)
    227c:	01212023          	sw	s2,0(sp)
    2280:	01010413          	add	s0,sp,16
  for(p = proc; p < &proc[NPROC]; p++) {
    2284:	00010497          	auipc	s1,0x10
    2288:	46048493          	add	s1,s1,1120 # 126e4 <proc>
    228c:	00013917          	auipc	s2,0x13
    2290:	45890913          	add	s2,s2,1112 # 156e4 <tickslock>
    acquire(&p->lock);
    2294:	00048513          	mv	a0,s1
    2298:	fffff097          	auipc	ra,0xfffff
    229c:	b0c080e7          	jalr	-1268(ra) # da4 <acquire>
    if(p->state == UNUSED) {
    22a0:	00c4a783          	lw	a5,12(s1)
    22a4:	02078063          	beqz	a5,22c4 <allocproc+0x58>
      release(&p->lock);
    22a8:	00048513          	mv	a0,s1
    22ac:	fffff097          	auipc	ra,0xfffff
    22b0:	b6c080e7          	jalr	-1172(ra) # e18 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    22b4:	0c048493          	add	s1,s1,192
    22b8:	fd249ee3          	bne	s1,s2,2294 <allocproc+0x28>
  return 0;
    22bc:	00000493          	li	s1,0
    22c0:	0640006f          	j	2324 <allocproc+0xb8>
  p->pid = allocpid();
    22c4:	00000097          	auipc	ra,0x0
    22c8:	ec4080e7          	jalr	-316(ra) # 2188 <allocpid>
    22cc:	02a4a023          	sw	a0,32(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    22d0:	fffff097          	auipc	ra,0xfffff
    22d4:	8c8080e7          	jalr	-1848(ra) # b98 <kalloc>
    22d8:	00050913          	mv	s2,a0
    22dc:	02a4a823          	sw	a0,48(s1)
    22e0:	06050063          	beqz	a0,2340 <allocproc+0xd4>
  p->pagetable = proc_pagetable(p);
    22e4:	00048513          	mv	a0,s1
    22e8:	00000097          	auipc	ra,0x0
    22ec:	f08080e7          	jalr	-248(ra) # 21f0 <proc_pagetable>
    22f0:	02a4a623          	sw	a0,44(s1)
  memset(&p->context, 0, sizeof p->context);
    22f4:	03800613          	li	a2,56
    22f8:	00000593          	li	a1,0
    22fc:	03448513          	add	a0,s1,52
    2300:	fffff097          	auipc	ra,0xfffff
    2304:	b78080e7          	jalr	-1160(ra) # e78 <memset>
  p->context.ra = (uint32)forkret;
    2308:	00000797          	auipc	a5,0x0
    230c:	e2478793          	add	a5,a5,-476 # 212c <forkret>
    2310:	02f4aa23          	sw	a5,52(s1)
  p->context.sp = p->kstack + PGSIZE;
    2314:	0244a783          	lw	a5,36(s1)
    2318:	00001737          	lui	a4,0x1
    231c:	00e787b3          	add	a5,a5,a4
    2320:	02f4ac23          	sw	a5,56(s1)
}
    2324:	00048513          	mv	a0,s1
    2328:	00c12083          	lw	ra,12(sp)
    232c:	00812403          	lw	s0,8(sp)
    2330:	00412483          	lw	s1,4(sp)
    2334:	00012903          	lw	s2,0(sp)
    2338:	01010113          	add	sp,sp,16
    233c:	00008067          	ret
    release(&p->lock);
    2340:	00048513          	mv	a0,s1
    2344:	fffff097          	auipc	ra,0xfffff
    2348:	ad4080e7          	jalr	-1324(ra) # e18 <release>
    return 0;
    234c:	00090493          	mv	s1,s2
    2350:	fd5ff06f          	j	2324 <allocproc+0xb8>

00002354 <proc_freepagetable>:
{
    2354:	ff010113          	add	sp,sp,-16
    2358:	00112623          	sw	ra,12(sp)
    235c:	00812423          	sw	s0,8(sp)
    2360:	00912223          	sw	s1,4(sp)
    2364:	01212023          	sw	s2,0(sp)
    2368:	01010413          	add	s0,sp,16
    236c:	00050493          	mv	s1,a0
    2370:	00058913          	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    2374:	00000693          	li	a3,0
    2378:	00001637          	lui	a2,0x1
    237c:	fffff5b7          	lui	a1,0xfffff
    2380:	fffff097          	auipc	ra,0xfffff
    2384:	328080e7          	jalr	808(ra) # 16a8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    2388:	00000693          	li	a3,0
    238c:	00001637          	lui	a2,0x1
    2390:	ffffe5b7          	lui	a1,0xffffe
    2394:	00048513          	mv	a0,s1
    2398:	fffff097          	auipc	ra,0xfffff
    239c:	310080e7          	jalr	784(ra) # 16a8 <uvmunmap>
  if(sz > 0)
    23a0:	00091e63          	bnez	s2,23bc <proc_freepagetable+0x68>
}
    23a4:	00c12083          	lw	ra,12(sp)
    23a8:	00812403          	lw	s0,8(sp)
    23ac:	00412483          	lw	s1,4(sp)
    23b0:	00012903          	lw	s2,0(sp)
    23b4:	01010113          	add	sp,sp,16
    23b8:	00008067          	ret
    uvmfree(pagetable, sz);
    23bc:	00090593          	mv	a1,s2
    23c0:	00048513          	mv	a0,s1
    23c4:	fffff097          	auipc	ra,0xfffff
    23c8:	68c080e7          	jalr	1676(ra) # 1a50 <uvmfree>
}
    23cc:	fd9ff06f          	j	23a4 <proc_freepagetable+0x50>

000023d0 <freeproc>:
{
    23d0:	ff010113          	add	sp,sp,-16
    23d4:	00112623          	sw	ra,12(sp)
    23d8:	00812423          	sw	s0,8(sp)
    23dc:	00912223          	sw	s1,4(sp)
    23e0:	01010413          	add	s0,sp,16
    23e4:	00050493          	mv	s1,a0
  if(p->tf)
    23e8:	03052503          	lw	a0,48(a0)
    23ec:	00050663          	beqz	a0,23f8 <freeproc+0x28>
    kfree((void*)p->tf);
    23f0:	ffffe097          	auipc	ra,0xffffe
    23f4:	654080e7          	jalr	1620(ra) # a44 <kfree>
  p->tf = 0;
    23f8:	0204a823          	sw	zero,48(s1)
  if(p->pagetable)
    23fc:	02c4a503          	lw	a0,44(s1)
    2400:	00050863          	beqz	a0,2410 <freeproc+0x40>
    proc_freepagetable(p->pagetable, p->sz);
    2404:	0284a583          	lw	a1,40(s1)
    2408:	00000097          	auipc	ra,0x0
    240c:	f4c080e7          	jalr	-180(ra) # 2354 <proc_freepagetable>
  p->pagetable = 0;
    2410:	0204a623          	sw	zero,44(s1)
  p->sz = 0;
    2414:	0204a423          	sw	zero,40(s1)
  p->pid = 0;
    2418:	0204a023          	sw	zero,32(s1)
  p->parent = 0;
    241c:	0004a823          	sw	zero,16(s1)
  p->name[0] = 0;
    2420:	0a048823          	sb	zero,176(s1)
  p->chan = 0;
    2424:	0004aa23          	sw	zero,20(s1)
  p->killed = 0;
    2428:	0004ac23          	sw	zero,24(s1)
  p->xstate = 0;
    242c:	0004ae23          	sw	zero,28(s1)
  p->state = UNUSED;
    2430:	0004a623          	sw	zero,12(s1)
}
    2434:	00c12083          	lw	ra,12(sp)
    2438:	00812403          	lw	s0,8(sp)
    243c:	00412483          	lw	s1,4(sp)
    2440:	01010113          	add	sp,sp,16
    2444:	00008067          	ret

00002448 <userinit>:
{
    2448:	ff010113          	add	sp,sp,-16
    244c:	00112623          	sw	ra,12(sp)
    2450:	00812423          	sw	s0,8(sp)
    2454:	00912223          	sw	s1,4(sp)
    2458:	01010413          	add	s0,sp,16
  p = allocproc();
    245c:	00000097          	auipc	ra,0x0
    2460:	e10080e7          	jalr	-496(ra) # 226c <allocproc>
    2464:	00050493          	mv	s1,a0
  initproc = p;
    2468:	0001f797          	auipc	a5,0x1f
    246c:	baa7a223          	sw	a0,-1116(a5) # 2100c <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    2470:	03800613          	li	a2,56
    2474:	00007597          	auipc	a1,0x7
    2478:	b8c58593          	add	a1,a1,-1140 # 9000 <initcode>
    247c:	02c52503          	lw	a0,44(a0)
    2480:	fffff097          	auipc	ra,0xfffff
    2484:	39c080e7          	jalr	924(ra) # 181c <uvminit>
  p->sz = PGSIZE;
    2488:	000017b7          	lui	a5,0x1
    248c:	02f4a423          	sw	a5,40(s1)
  p->tf->epc = 0;      // user program counter
    2490:	0304a703          	lw	a4,48(s1)
    2494:	00072623          	sw	zero,12(a4) # 100c <strncpy+0x28>
  p->tf->sp = PGSIZE;  // user stack pointer
    2498:	0304a703          	lw	a4,48(s1)
    249c:	00f72c23          	sw	a5,24(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    24a0:	01000613          	li	a2,16
    24a4:	00006597          	auipc	a1,0x6
    24a8:	e4c58593          	add	a1,a1,-436 # 82f0 <userret+0x250>
    24ac:	0b048513          	add	a0,s1,176
    24b0:	fffff097          	auipc	ra,0xfffff
    24b4:	b90080e7          	jalr	-1136(ra) # 1040 <safestrcpy>
  p->cwd = namei("/");
    24b8:	00006517          	auipc	a0,0x6
    24bc:	e4450513          	add	a0,a0,-444 # 82fc <userret+0x25c>
    24c0:	00003097          	auipc	ra,0x3
    24c4:	c40080e7          	jalr	-960(ra) # 5100 <namei>
    24c8:	0aa4a623          	sw	a0,172(s1)
  p->state = RUNNABLE;
    24cc:	00200793          	li	a5,2
    24d0:	00f4a623          	sw	a5,12(s1)
  release(&p->lock);
    24d4:	00048513          	mv	a0,s1
    24d8:	fffff097          	auipc	ra,0xfffff
    24dc:	940080e7          	jalr	-1728(ra) # e18 <release>
}
    24e0:	00c12083          	lw	ra,12(sp)
    24e4:	00812403          	lw	s0,8(sp)
    24e8:	00412483          	lw	s1,4(sp)
    24ec:	01010113          	add	sp,sp,16
    24f0:	00008067          	ret

000024f4 <growproc>:
{
    24f4:	ff010113          	add	sp,sp,-16
    24f8:	00112623          	sw	ra,12(sp)
    24fc:	00812423          	sw	s0,8(sp)
    2500:	00912223          	sw	s1,4(sp)
    2504:	01212023          	sw	s2,0(sp)
    2508:	01010413          	add	s0,sp,16
    250c:	00050913          	mv	s2,a0
  struct proc *p = myproc();
    2510:	00000097          	auipc	ra,0x0
    2514:	bc0080e7          	jalr	-1088(ra) # 20d0 <myproc>
    2518:	00050493          	mv	s1,a0
  sz = p->sz;
    251c:	02852583          	lw	a1,40(a0)
  if(n > 0){
    2520:	03204463          	bgtz	s2,2548 <growproc+0x54>
  } else if(n < 0){
    2524:	04094263          	bltz	s2,2568 <growproc+0x74>
  p->sz = sz;
    2528:	02b4a423          	sw	a1,40(s1)
  return 0;
    252c:	00000513          	li	a0,0
}
    2530:	00c12083          	lw	ra,12(sp)
    2534:	00812403          	lw	s0,8(sp)
    2538:	00412483          	lw	s1,4(sp)
    253c:	00012903          	lw	s2,0(sp)
    2540:	01010113          	add	sp,sp,16
    2544:	00008067          	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    2548:	00b90633          	add	a2,s2,a1
    254c:	02c52503          	lw	a0,44(a0)
    2550:	fffff097          	auipc	ra,0xfffff
    2554:	3ec080e7          	jalr	1004(ra) # 193c <uvmalloc>
    2558:	00050593          	mv	a1,a0
    255c:	fc0516e3          	bnez	a0,2528 <growproc+0x34>
      return -1;
    2560:	fff00513          	li	a0,-1
    2564:	fcdff06f          	j	2530 <growproc+0x3c>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    2568:	00b90633          	add	a2,s2,a1
    256c:	02c52503          	lw	a0,44(a0)
    2570:	fffff097          	auipc	ra,0xfffff
    2574:	35c080e7          	jalr	860(ra) # 18cc <uvmdealloc>
    2578:	00050593          	mv	a1,a0
    257c:	fadff06f          	j	2528 <growproc+0x34>

00002580 <fork>:
{
    2580:	fe010113          	add	sp,sp,-32
    2584:	00112e23          	sw	ra,28(sp)
    2588:	00812c23          	sw	s0,24(sp)
    258c:	00912a23          	sw	s1,20(sp)
    2590:	01212823          	sw	s2,16(sp)
    2594:	01312623          	sw	s3,12(sp)
    2598:	01412423          	sw	s4,8(sp)
    259c:	01512223          	sw	s5,4(sp)
    25a0:	02010413          	add	s0,sp,32
  struct proc *p = myproc();
    25a4:	00000097          	auipc	ra,0x0
    25a8:	b2c080e7          	jalr	-1236(ra) # 20d0 <myproc>
    25ac:	00050a93          	mv	s5,a0
  if((np = allocproc()) == 0){
    25b0:	00000097          	auipc	ra,0x0
    25b4:	cbc080e7          	jalr	-836(ra) # 226c <allocproc>
    25b8:	12050463          	beqz	a0,26e0 <fork+0x160>
    25bc:	00050a13          	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    25c0:	028aa603          	lw	a2,40(s5) # fffff028 <end+0xfffde014>
    25c4:	02c52583          	lw	a1,44(a0)
    25c8:	02caa503          	lw	a0,44(s5)
    25cc:	fffff097          	auipc	ra,0xfffff
    25d0:	4d0080e7          	jalr	1232(ra) # 1a9c <uvmcopy>
    25d4:	06054263          	bltz	a0,2638 <fork+0xb8>
  np->sz = p->sz;
    25d8:	028aa783          	lw	a5,40(s5)
    25dc:	02fa2423          	sw	a5,40(s4)
  np->parent = p;
    25e0:	015a2823          	sw	s5,16(s4)
  *(np->tf) = *(p->tf);
    25e4:	030aa683          	lw	a3,48(s5)
    25e8:	00068793          	mv	a5,a3
    25ec:	030a2703          	lw	a4,48(s4)
    25f0:	09068693          	add	a3,a3,144
    25f4:	0007a803          	lw	a6,0(a5) # 1000 <strncpy+0x1c>
    25f8:	0047a503          	lw	a0,4(a5)
    25fc:	0087a583          	lw	a1,8(a5)
    2600:	00c7a603          	lw	a2,12(a5)
    2604:	01072023          	sw	a6,0(a4)
    2608:	00a72223          	sw	a0,4(a4)
    260c:	00b72423          	sw	a1,8(a4)
    2610:	00c72623          	sw	a2,12(a4)
    2614:	01078793          	add	a5,a5,16
    2618:	01070713          	add	a4,a4,16
    261c:	fcd79ce3          	bne	a5,a3,25f4 <fork+0x74>
  np->tf->a0 = 0;
    2620:	030a2783          	lw	a5,48(s4)
    2624:	0207ac23          	sw	zero,56(a5)
  for(i = 0; i < NOFILE; i++)
    2628:	06ca8493          	add	s1,s5,108
    262c:	06ca0913          	add	s2,s4,108
    2630:	0aca8993          	add	s3,s5,172
    2634:	0300006f          	j	2664 <fork+0xe4>
    freeproc(np);
    2638:	000a0513          	mv	a0,s4
    263c:	00000097          	auipc	ra,0x0
    2640:	d94080e7          	jalr	-620(ra) # 23d0 <freeproc>
    release(&np->lock);
    2644:	000a0513          	mv	a0,s4
    2648:	ffffe097          	auipc	ra,0xffffe
    264c:	7d0080e7          	jalr	2000(ra) # e18 <release>
    return -1;
    2650:	fff00493          	li	s1,-1
    2654:	0640006f          	j	26b8 <fork+0x138>
  for(i = 0; i < NOFILE; i++)
    2658:	00448493          	add	s1,s1,4
    265c:	00490913          	add	s2,s2,4
    2660:	01348e63          	beq	s1,s3,267c <fork+0xfc>
    if(p->ofile[i])
    2664:	0004a503          	lw	a0,0(s1)
    2668:	fe0508e3          	beqz	a0,2658 <fork+0xd8>
      np->ofile[i] = filedup(p->ofile[i]);
    266c:	00003097          	auipc	ra,0x3
    2670:	364080e7          	jalr	868(ra) # 59d0 <filedup>
    2674:	00a92023          	sw	a0,0(s2)
    2678:	fe1ff06f          	j	2658 <fork+0xd8>
  np->cwd = idup(p->cwd);
    267c:	0acaa503          	lw	a0,172(s5)
    2680:	00002097          	auipc	ra,0x2
    2684:	fb0080e7          	jalr	-80(ra) # 4630 <idup>
    2688:	0aaa2623          	sw	a0,172(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    268c:	01000613          	li	a2,16
    2690:	0b0a8593          	add	a1,s5,176
    2694:	0b0a0513          	add	a0,s4,176
    2698:	fffff097          	auipc	ra,0xfffff
    269c:	9a8080e7          	jalr	-1624(ra) # 1040 <safestrcpy>
  pid = np->pid;
    26a0:	020a2483          	lw	s1,32(s4)
  np->state = RUNNABLE;
    26a4:	00200793          	li	a5,2
    26a8:	00fa2623          	sw	a5,12(s4)
  release(&np->lock);
    26ac:	000a0513          	mv	a0,s4
    26b0:	ffffe097          	auipc	ra,0xffffe
    26b4:	768080e7          	jalr	1896(ra) # e18 <release>
}
    26b8:	00048513          	mv	a0,s1
    26bc:	01c12083          	lw	ra,28(sp)
    26c0:	01812403          	lw	s0,24(sp)
    26c4:	01412483          	lw	s1,20(sp)
    26c8:	01012903          	lw	s2,16(sp)
    26cc:	00c12983          	lw	s3,12(sp)
    26d0:	00812a03          	lw	s4,8(sp)
    26d4:	00412a83          	lw	s5,4(sp)
    26d8:	02010113          	add	sp,sp,32
    26dc:	00008067          	ret
    return -1;
    26e0:	fff00493          	li	s1,-1
    26e4:	fd5ff06f          	j	26b8 <fork+0x138>

000026e8 <reparent>:
{
    26e8:	fe010113          	add	sp,sp,-32
    26ec:	00112e23          	sw	ra,28(sp)
    26f0:	00812c23          	sw	s0,24(sp)
    26f4:	00912a23          	sw	s1,20(sp)
    26f8:	01212823          	sw	s2,16(sp)
    26fc:	01312623          	sw	s3,12(sp)
    2700:	01412423          	sw	s4,8(sp)
    2704:	02010413          	add	s0,sp,32
    2708:	00050913          	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    270c:	00010497          	auipc	s1,0x10
    2710:	fd848493          	add	s1,s1,-40 # 126e4 <proc>
      pp->parent = initproc;
    2714:	0001fa17          	auipc	s4,0x1f
    2718:	8f8a0a13          	add	s4,s4,-1800 # 2100c <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    271c:	00013997          	auipc	s3,0x13
    2720:	fc898993          	add	s3,s3,-56 # 156e4 <tickslock>
    2724:	00c0006f          	j	2730 <reparent+0x48>
    2728:	0c048493          	add	s1,s1,192
    272c:	03348863          	beq	s1,s3,275c <reparent+0x74>
    if(pp->parent == p){
    2730:	0104a783          	lw	a5,16(s1)
    2734:	ff279ae3          	bne	a5,s2,2728 <reparent+0x40>
      acquire(&pp->lock);
    2738:	00048513          	mv	a0,s1
    273c:	ffffe097          	auipc	ra,0xffffe
    2740:	668080e7          	jalr	1640(ra) # da4 <acquire>
      pp->parent = initproc;
    2744:	000a2783          	lw	a5,0(s4)
    2748:	00f4a823          	sw	a5,16(s1)
      release(&pp->lock);
    274c:	00048513          	mv	a0,s1
    2750:	ffffe097          	auipc	ra,0xffffe
    2754:	6c8080e7          	jalr	1736(ra) # e18 <release>
    2758:	fd1ff06f          	j	2728 <reparent+0x40>
}
    275c:	01c12083          	lw	ra,28(sp)
    2760:	01812403          	lw	s0,24(sp)
    2764:	01412483          	lw	s1,20(sp)
    2768:	01012903          	lw	s2,16(sp)
    276c:	00c12983          	lw	s3,12(sp)
    2770:	00812a03          	lw	s4,8(sp)
    2774:	02010113          	add	sp,sp,32
    2778:	00008067          	ret

0000277c <scheduler>:
{
    277c:	fe010113          	add	sp,sp,-32
    2780:	00112e23          	sw	ra,28(sp)
    2784:	00812c23          	sw	s0,24(sp)
    2788:	00912a23          	sw	s1,20(sp)
    278c:	01212823          	sw	s2,16(sp)
    2790:	01312623          	sw	s3,12(sp)
    2794:	01412423          	sw	s4,8(sp)
    2798:	01512223          	sw	s5,4(sp)
    279c:	01612023          	sw	s6,0(sp)
    27a0:	02010413          	add	s0,sp,32
    27a4:	00020713          	mv	a4,tp
  c->proc = 0;
    27a8:	00471793          	sll	a5,a4,0x4
    27ac:	00e78633          	add	a2,a5,a4
    27b0:	00261613          	sll	a2,a2,0x2
    27b4:	00010697          	auipc	a3,0x10
    27b8:	d0468693          	add	a3,a3,-764 # 124b8 <pid_lock>
    27bc:	00c686b3          	add	a3,a3,a2
    27c0:	0006a623          	sw	zero,12(a3)
        swtch(&c->scheduler, &p->context);
    27c4:	00010797          	auipc	a5,0x10
    27c8:	d0478793          	add	a5,a5,-764 # 124c8 <cpus+0x4>
    27cc:	00f60b33          	add	s6,a2,a5
      if(p->state == RUNNABLE) {
    27d0:	00200993          	li	s3,2
        c->proc = p;
    27d4:	00068a13          	mv	s4,a3
    for(p = proc; p < &proc[NPROC]; p++) {
    27d8:	00013917          	auipc	s2,0x13
    27dc:	f0c90913          	add	s2,s2,-244 # 156e4 <tickslock>
  asm volatile("csrr %0, sie" : "=r" (x) );
    27e0:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    27e4:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    27e8:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    27ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    27f0:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    27f4:	10079073          	csrw	sstatus,a5
    27f8:	00010497          	auipc	s1,0x10
    27fc:	eec48493          	add	s1,s1,-276 # 126e4 <proc>
        p->state = RUNNING;
    2800:	00300a93          	li	s5,3
    2804:	0180006f          	j	281c <scheduler+0xa0>
      release(&p->lock);
    2808:	00048513          	mv	a0,s1
    280c:	ffffe097          	auipc	ra,0xffffe
    2810:	60c080e7          	jalr	1548(ra) # e18 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    2814:	0c048493          	add	s1,s1,192
    2818:	fd2484e3          	beq	s1,s2,27e0 <scheduler+0x64>
      acquire(&p->lock);
    281c:	00048513          	mv	a0,s1
    2820:	ffffe097          	auipc	ra,0xffffe
    2824:	584080e7          	jalr	1412(ra) # da4 <acquire>
      if(p->state == RUNNABLE) {
    2828:	00c4a783          	lw	a5,12(s1)
    282c:	fd379ee3          	bne	a5,s3,2808 <scheduler+0x8c>
        p->state = RUNNING;
    2830:	0154a623          	sw	s5,12(s1)
        c->proc = p;
    2834:	009a2623          	sw	s1,12(s4)
        swtch(&c->scheduler, &p->context);
    2838:	03448593          	add	a1,s1,52
    283c:	000b0513          	mv	a0,s6
    2840:	00001097          	auipc	ra,0x1
    2844:	848080e7          	jalr	-1976(ra) # 3088 <swtch>
        c->proc = 0;
    2848:	000a2623          	sw	zero,12(s4)
    284c:	fbdff06f          	j	2808 <scheduler+0x8c>

00002850 <sched>:
{
    2850:	fe010113          	add	sp,sp,-32
    2854:	00112e23          	sw	ra,28(sp)
    2858:	00812c23          	sw	s0,24(sp)
    285c:	00912a23          	sw	s1,20(sp)
    2860:	01212823          	sw	s2,16(sp)
    2864:	01312623          	sw	s3,12(sp)
    2868:	02010413          	add	s0,sp,32
  struct proc *p = myproc();
    286c:	00000097          	auipc	ra,0x0
    2870:	864080e7          	jalr	-1948(ra) # 20d0 <myproc>
    2874:	00050493          	mv	s1,a0
  if(!holding(&p->lock))
    2878:	ffffe097          	auipc	ra,0xffffe
    287c:	4c8080e7          	jalr	1224(ra) # d40 <holding>
    2880:	0c050063          	beqz	a0,2940 <sched+0xf0>
  asm volatile("mv %0, tp" : "=r" (x) );
    2884:	00020713          	mv	a4,tp
  if(mycpu()->noff != 1)
    2888:	00471793          	sll	a5,a4,0x4
    288c:	00e787b3          	add	a5,a5,a4
    2890:	00279793          	sll	a5,a5,0x2
    2894:	00010717          	auipc	a4,0x10
    2898:	c2470713          	add	a4,a4,-988 # 124b8 <pid_lock>
    289c:	00f707b3          	add	a5,a4,a5
    28a0:	0487a703          	lw	a4,72(a5)
    28a4:	00100793          	li	a5,1
    28a8:	0af71463          	bne	a4,a5,2950 <sched+0x100>
  if(p->state == RUNNING)
    28ac:	00c4a703          	lw	a4,12(s1)
    28b0:	00300793          	li	a5,3
    28b4:	0af70663          	beq	a4,a5,2960 <sched+0x110>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    28b8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    28bc:	0027f793          	and	a5,a5,2
  if(intr_get())
    28c0:	0a079863          	bnez	a5,2970 <sched+0x120>
  asm volatile("mv %0, tp" : "=r" (x) );
    28c4:	00020713          	mv	a4,tp
  intena = mycpu()->intena;
    28c8:	00010917          	auipc	s2,0x10
    28cc:	bf090913          	add	s2,s2,-1040 # 124b8 <pid_lock>
    28d0:	00471793          	sll	a5,a4,0x4
    28d4:	00e787b3          	add	a5,a5,a4
    28d8:	00279793          	sll	a5,a5,0x2
    28dc:	00f907b3          	add	a5,s2,a5
    28e0:	04c7a983          	lw	s3,76(a5)
    28e4:	00020713          	mv	a4,tp
  swtch(&p->context, &mycpu()->scheduler);
    28e8:	00471793          	sll	a5,a4,0x4
    28ec:	00e787b3          	add	a5,a5,a4
    28f0:	00279793          	sll	a5,a5,0x2
    28f4:	00010597          	auipc	a1,0x10
    28f8:	bd458593          	add	a1,a1,-1068 # 124c8 <cpus+0x4>
    28fc:	00b785b3          	add	a1,a5,a1
    2900:	03448513          	add	a0,s1,52
    2904:	00000097          	auipc	ra,0x0
    2908:	784080e7          	jalr	1924(ra) # 3088 <swtch>
    290c:	00020713          	mv	a4,tp
  mycpu()->intena = intena;
    2910:	00471793          	sll	a5,a4,0x4
    2914:	00e787b3          	add	a5,a5,a4
    2918:	00279793          	sll	a5,a5,0x2
    291c:	00f90933          	add	s2,s2,a5
    2920:	05392623          	sw	s3,76(s2)
}
    2924:	01c12083          	lw	ra,28(sp)
    2928:	01812403          	lw	s0,24(sp)
    292c:	01412483          	lw	s1,20(sp)
    2930:	01012903          	lw	s2,16(sp)
    2934:	00c12983          	lw	s3,12(sp)
    2938:	02010113          	add	sp,sp,32
    293c:	00008067          	ret
    panic("sched p->lock");
    2940:	00006517          	auipc	a0,0x6
    2944:	9c050513          	add	a0,a0,-1600 # 8300 <userret+0x260>
    2948:	ffffe097          	auipc	ra,0xffffe
    294c:	d44080e7          	jalr	-700(ra) # 68c <panic>
    panic("sched locks");
    2950:	00006517          	auipc	a0,0x6
    2954:	9c050513          	add	a0,a0,-1600 # 8310 <userret+0x270>
    2958:	ffffe097          	auipc	ra,0xffffe
    295c:	d34080e7          	jalr	-716(ra) # 68c <panic>
    panic("sched running");
    2960:	00006517          	auipc	a0,0x6
    2964:	9bc50513          	add	a0,a0,-1604 # 831c <userret+0x27c>
    2968:	ffffe097          	auipc	ra,0xffffe
    296c:	d24080e7          	jalr	-732(ra) # 68c <panic>
    panic("sched interruptible");
    2970:	00006517          	auipc	a0,0x6
    2974:	9bc50513          	add	a0,a0,-1604 # 832c <userret+0x28c>
    2978:	ffffe097          	auipc	ra,0xffffe
    297c:	d14080e7          	jalr	-748(ra) # 68c <panic>

00002980 <exit>:
{
    2980:	fe010113          	add	sp,sp,-32
    2984:	00112e23          	sw	ra,28(sp)
    2988:	00812c23          	sw	s0,24(sp)
    298c:	00912a23          	sw	s1,20(sp)
    2990:	01212823          	sw	s2,16(sp)
    2994:	01312623          	sw	s3,12(sp)
    2998:	01412423          	sw	s4,8(sp)
    299c:	02010413          	add	s0,sp,32
    29a0:	00050a13          	mv	s4,a0
  struct proc *p = myproc();
    29a4:	fffff097          	auipc	ra,0xfffff
    29a8:	72c080e7          	jalr	1836(ra) # 20d0 <myproc>
    29ac:	00050993          	mv	s3,a0
  if(p == initproc)
    29b0:	0001e797          	auipc	a5,0x1e
    29b4:	65c7a783          	lw	a5,1628(a5) # 2100c <initproc>
    29b8:	06c50493          	add	s1,a0,108
    29bc:	0ac50913          	add	s2,a0,172
    29c0:	02a79463          	bne	a5,a0,29e8 <exit+0x68>
    panic("init exiting");
    29c4:	00006517          	auipc	a0,0x6
    29c8:	97c50513          	add	a0,a0,-1668 # 8340 <userret+0x2a0>
    29cc:	ffffe097          	auipc	ra,0xffffe
    29d0:	cc0080e7          	jalr	-832(ra) # 68c <panic>
      fileclose(f);
    29d4:	00003097          	auipc	ra,0x3
    29d8:	06c080e7          	jalr	108(ra) # 5a40 <fileclose>
      p->ofile[fd] = 0;
    29dc:	0004a023          	sw	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    29e0:	00448493          	add	s1,s1,4
    29e4:	01248863          	beq	s1,s2,29f4 <exit+0x74>
    if(p->ofile[fd]){
    29e8:	0004a503          	lw	a0,0(s1)
    29ec:	fe0514e3          	bnez	a0,29d4 <exit+0x54>
    29f0:	ff1ff06f          	j	29e0 <exit+0x60>
  begin_op();
    29f4:	00003097          	auipc	ra,0x3
    29f8:	9c4080e7          	jalr	-1596(ra) # 53b8 <begin_op>
  iput(p->cwd);
    29fc:	0ac9a503          	lw	a0,172(s3)
    2a00:	00002097          	auipc	ra,0x2
    2a04:	e00080e7          	jalr	-512(ra) # 4800 <iput>
  end_op();
    2a08:	00003097          	auipc	ra,0x3
    2a0c:	a60080e7          	jalr	-1440(ra) # 5468 <end_op>
  p->cwd = 0;
    2a10:	0a09a623          	sw	zero,172(s3)
  acquire(&initproc->lock);
    2a14:	0001e497          	auipc	s1,0x1e
    2a18:	5f848493          	add	s1,s1,1528 # 2100c <initproc>
    2a1c:	0004a503          	lw	a0,0(s1)
    2a20:	ffffe097          	auipc	ra,0xffffe
    2a24:	384080e7          	jalr	900(ra) # da4 <acquire>
  wakeup1(initproc);
    2a28:	0004a503          	lw	a0,0(s1)
    2a2c:	fffff097          	auipc	ra,0xfffff
    2a30:	4e4080e7          	jalr	1252(ra) # 1f10 <wakeup1>
  release(&initproc->lock);
    2a34:	0004a503          	lw	a0,0(s1)
    2a38:	ffffe097          	auipc	ra,0xffffe
    2a3c:	3e0080e7          	jalr	992(ra) # e18 <release>
  acquire(&p->lock);
    2a40:	00098513          	mv	a0,s3
    2a44:	ffffe097          	auipc	ra,0xffffe
    2a48:	360080e7          	jalr	864(ra) # da4 <acquire>
  struct proc *original_parent = p->parent;
    2a4c:	0109a483          	lw	s1,16(s3)
  release(&p->lock);
    2a50:	00098513          	mv	a0,s3
    2a54:	ffffe097          	auipc	ra,0xffffe
    2a58:	3c4080e7          	jalr	964(ra) # e18 <release>
  acquire(&original_parent->lock);
    2a5c:	00048513          	mv	a0,s1
    2a60:	ffffe097          	auipc	ra,0xffffe
    2a64:	344080e7          	jalr	836(ra) # da4 <acquire>
  acquire(&p->lock);
    2a68:	00098513          	mv	a0,s3
    2a6c:	ffffe097          	auipc	ra,0xffffe
    2a70:	338080e7          	jalr	824(ra) # da4 <acquire>
  reparent(p);
    2a74:	00098513          	mv	a0,s3
    2a78:	00000097          	auipc	ra,0x0
    2a7c:	c70080e7          	jalr	-912(ra) # 26e8 <reparent>
  wakeup1(original_parent);
    2a80:	00048513          	mv	a0,s1
    2a84:	fffff097          	auipc	ra,0xfffff
    2a88:	48c080e7          	jalr	1164(ra) # 1f10 <wakeup1>
  p->xstate = status;
    2a8c:	0149ae23          	sw	s4,28(s3)
  p->state = ZOMBIE;
    2a90:	00400793          	li	a5,4
    2a94:	00f9a623          	sw	a5,12(s3)
  release(&original_parent->lock);
    2a98:	00048513          	mv	a0,s1
    2a9c:	ffffe097          	auipc	ra,0xffffe
    2aa0:	37c080e7          	jalr	892(ra) # e18 <release>
  sched();
    2aa4:	00000097          	auipc	ra,0x0
    2aa8:	dac080e7          	jalr	-596(ra) # 2850 <sched>
  panic("zombie exit");
    2aac:	00006517          	auipc	a0,0x6
    2ab0:	8a450513          	add	a0,a0,-1884 # 8350 <userret+0x2b0>
    2ab4:	ffffe097          	auipc	ra,0xffffe
    2ab8:	bd8080e7          	jalr	-1064(ra) # 68c <panic>

00002abc <yield>:
{
    2abc:	ff010113          	add	sp,sp,-16
    2ac0:	00112623          	sw	ra,12(sp)
    2ac4:	00812423          	sw	s0,8(sp)
    2ac8:	00912223          	sw	s1,4(sp)
    2acc:	01010413          	add	s0,sp,16
  struct proc *p = myproc();
    2ad0:	fffff097          	auipc	ra,0xfffff
    2ad4:	600080e7          	jalr	1536(ra) # 20d0 <myproc>
    2ad8:	00050493          	mv	s1,a0
  acquire(&p->lock);
    2adc:	ffffe097          	auipc	ra,0xffffe
    2ae0:	2c8080e7          	jalr	712(ra) # da4 <acquire>
  p->state = RUNNABLE;
    2ae4:	00200793          	li	a5,2
    2ae8:	00f4a623          	sw	a5,12(s1)
  sched();
    2aec:	00000097          	auipc	ra,0x0
    2af0:	d64080e7          	jalr	-668(ra) # 2850 <sched>
  release(&p->lock);
    2af4:	00048513          	mv	a0,s1
    2af8:	ffffe097          	auipc	ra,0xffffe
    2afc:	320080e7          	jalr	800(ra) # e18 <release>
}
    2b00:	00c12083          	lw	ra,12(sp)
    2b04:	00812403          	lw	s0,8(sp)
    2b08:	00412483          	lw	s1,4(sp)
    2b0c:	01010113          	add	sp,sp,16
    2b10:	00008067          	ret

00002b14 <sleep>:
{
    2b14:	fe010113          	add	sp,sp,-32
    2b18:	00112e23          	sw	ra,28(sp)
    2b1c:	00812c23          	sw	s0,24(sp)
    2b20:	00912a23          	sw	s1,20(sp)
    2b24:	01212823          	sw	s2,16(sp)
    2b28:	01312623          	sw	s3,12(sp)
    2b2c:	02010413          	add	s0,sp,32
    2b30:	00050993          	mv	s3,a0
    2b34:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    2b38:	fffff097          	auipc	ra,0xfffff
    2b3c:	598080e7          	jalr	1432(ra) # 20d0 <myproc>
    2b40:	00050493          	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    2b44:	07250263          	beq	a0,s2,2ba8 <sleep+0x94>
    acquire(&p->lock);  //DOC: sleeplock1
    2b48:	ffffe097          	auipc	ra,0xffffe
    2b4c:	25c080e7          	jalr	604(ra) # da4 <acquire>
    release(lk);
    2b50:	00090513          	mv	a0,s2
    2b54:	ffffe097          	auipc	ra,0xffffe
    2b58:	2c4080e7          	jalr	708(ra) # e18 <release>
  p->chan = chan;
    2b5c:	0134aa23          	sw	s3,20(s1)
  p->state = SLEEPING;
    2b60:	00100793          	li	a5,1
    2b64:	00f4a623          	sw	a5,12(s1)
  sched();
    2b68:	00000097          	auipc	ra,0x0
    2b6c:	ce8080e7          	jalr	-792(ra) # 2850 <sched>
  p->chan = 0;
    2b70:	0004aa23          	sw	zero,20(s1)
    release(&p->lock);
    2b74:	00048513          	mv	a0,s1
    2b78:	ffffe097          	auipc	ra,0xffffe
    2b7c:	2a0080e7          	jalr	672(ra) # e18 <release>
    acquire(lk);
    2b80:	00090513          	mv	a0,s2
    2b84:	ffffe097          	auipc	ra,0xffffe
    2b88:	220080e7          	jalr	544(ra) # da4 <acquire>
}
    2b8c:	01c12083          	lw	ra,28(sp)
    2b90:	01812403          	lw	s0,24(sp)
    2b94:	01412483          	lw	s1,20(sp)
    2b98:	01012903          	lw	s2,16(sp)
    2b9c:	00c12983          	lw	s3,12(sp)
    2ba0:	02010113          	add	sp,sp,32
    2ba4:	00008067          	ret
  p->chan = chan;
    2ba8:	01352a23          	sw	s3,20(a0)
  p->state = SLEEPING;
    2bac:	00100793          	li	a5,1
    2bb0:	00f52623          	sw	a5,12(a0)
  sched();
    2bb4:	00000097          	auipc	ra,0x0
    2bb8:	c9c080e7          	jalr	-868(ra) # 2850 <sched>
  p->chan = 0;
    2bbc:	0004aa23          	sw	zero,20(s1)
  if(lk != &p->lock){
    2bc0:	fcdff06f          	j	2b8c <sleep+0x78>

00002bc4 <wait>:
{
    2bc4:	fd010113          	add	sp,sp,-48
    2bc8:	02112623          	sw	ra,44(sp)
    2bcc:	02812423          	sw	s0,40(sp)
    2bd0:	02912223          	sw	s1,36(sp)
    2bd4:	03212023          	sw	s2,32(sp)
    2bd8:	01312e23          	sw	s3,28(sp)
    2bdc:	01412c23          	sw	s4,24(sp)
    2be0:	01512a23          	sw	s5,20(sp)
    2be4:	01612823          	sw	s6,16(sp)
    2be8:	01712623          	sw	s7,12(sp)
    2bec:	03010413          	add	s0,sp,48
    2bf0:	00050b13          	mv	s6,a0
  struct proc *p = myproc();
    2bf4:	fffff097          	auipc	ra,0xfffff
    2bf8:	4dc080e7          	jalr	1244(ra) # 20d0 <myproc>
    2bfc:	00050913          	mv	s2,a0
  acquire(&p->lock);
    2c00:	ffffe097          	auipc	ra,0xffffe
    2c04:	1a4080e7          	jalr	420(ra) # da4 <acquire>
    havekids = 0;
    2c08:	00000b93          	li	s7,0
        if(np->state == ZOMBIE){
    2c0c:	00400a13          	li	s4,4
        havekids = 1;
    2c10:	00100a93          	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    2c14:	00013997          	auipc	s3,0x13
    2c18:	ad098993          	add	s3,s3,-1328 # 156e4 <tickslock>
    2c1c:	0f00006f          	j	2d0c <wait+0x148>
          pid = np->pid;
    2c20:	0204a983          	lw	s3,32(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    2c24:	020b0063          	beqz	s6,2c44 <wait+0x80>
    2c28:	00400693          	li	a3,4
    2c2c:	01c48613          	add	a2,s1,28
    2c30:	000b0593          	mv	a1,s6
    2c34:	02c92503          	lw	a0,44(s2)
    2c38:	fffff097          	auipc	ra,0xfffff
    2c3c:	fec080e7          	jalr	-20(ra) # 1c24 <copyout>
    2c40:	04054c63          	bltz	a0,2c98 <wait+0xd4>
          freeproc(np);
    2c44:	00048513          	mv	a0,s1
    2c48:	fffff097          	auipc	ra,0xfffff
    2c4c:	788080e7          	jalr	1928(ra) # 23d0 <freeproc>
          release(&np->lock);
    2c50:	00048513          	mv	a0,s1
    2c54:	ffffe097          	auipc	ra,0xffffe
    2c58:	1c4080e7          	jalr	452(ra) # e18 <release>
          release(&p->lock);
    2c5c:	00090513          	mv	a0,s2
    2c60:	ffffe097          	auipc	ra,0xffffe
    2c64:	1b8080e7          	jalr	440(ra) # e18 <release>
}
    2c68:	00098513          	mv	a0,s3
    2c6c:	02c12083          	lw	ra,44(sp)
    2c70:	02812403          	lw	s0,40(sp)
    2c74:	02412483          	lw	s1,36(sp)
    2c78:	02012903          	lw	s2,32(sp)
    2c7c:	01c12983          	lw	s3,28(sp)
    2c80:	01812a03          	lw	s4,24(sp)
    2c84:	01412a83          	lw	s5,20(sp)
    2c88:	01012b03          	lw	s6,16(sp)
    2c8c:	00c12b83          	lw	s7,12(sp)
    2c90:	03010113          	add	sp,sp,48
    2c94:	00008067          	ret
            release(&np->lock);
    2c98:	00048513          	mv	a0,s1
    2c9c:	ffffe097          	auipc	ra,0xffffe
    2ca0:	17c080e7          	jalr	380(ra) # e18 <release>
            release(&p->lock);
    2ca4:	00090513          	mv	a0,s2
    2ca8:	ffffe097          	auipc	ra,0xffffe
    2cac:	170080e7          	jalr	368(ra) # e18 <release>
            return -1;
    2cb0:	fff00993          	li	s3,-1
    2cb4:	fb5ff06f          	j	2c68 <wait+0xa4>
    for(np = proc; np < &proc[NPROC]; np++){
    2cb8:	0c048493          	add	s1,s1,192
    2cbc:	03348a63          	beq	s1,s3,2cf0 <wait+0x12c>
      if(np->parent == p){
    2cc0:	0104a783          	lw	a5,16(s1)
    2cc4:	ff279ae3          	bne	a5,s2,2cb8 <wait+0xf4>
        acquire(&np->lock);
    2cc8:	00048513          	mv	a0,s1
    2ccc:	ffffe097          	auipc	ra,0xffffe
    2cd0:	0d8080e7          	jalr	216(ra) # da4 <acquire>
        if(np->state == ZOMBIE){
    2cd4:	00c4a783          	lw	a5,12(s1)
    2cd8:	f54784e3          	beq	a5,s4,2c20 <wait+0x5c>
        release(&np->lock);
    2cdc:	00048513          	mv	a0,s1
    2ce0:	ffffe097          	auipc	ra,0xffffe
    2ce4:	138080e7          	jalr	312(ra) # e18 <release>
        havekids = 1;
    2ce8:	000a8713          	mv	a4,s5
    2cec:	fcdff06f          	j	2cb8 <wait+0xf4>
    if(!havekids || p->killed){
    2cf0:	02070663          	beqz	a4,2d1c <wait+0x158>
    2cf4:	01892783          	lw	a5,24(s2)
    2cf8:	02079263          	bnez	a5,2d1c <wait+0x158>
    sleep(p, &p->lock);  //DOC: wait-sleep
    2cfc:	00090593          	mv	a1,s2
    2d00:	00090513          	mv	a0,s2
    2d04:	00000097          	auipc	ra,0x0
    2d08:	e10080e7          	jalr	-496(ra) # 2b14 <sleep>
    havekids = 0;
    2d0c:	000b8713          	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    2d10:	00010497          	auipc	s1,0x10
    2d14:	9d448493          	add	s1,s1,-1580 # 126e4 <proc>
    2d18:	fa9ff06f          	j	2cc0 <wait+0xfc>
      release(&p->lock);
    2d1c:	00090513          	mv	a0,s2
    2d20:	ffffe097          	auipc	ra,0xffffe
    2d24:	0f8080e7          	jalr	248(ra) # e18 <release>
      return -1;
    2d28:	fff00993          	li	s3,-1
    2d2c:	f3dff06f          	j	2c68 <wait+0xa4>

00002d30 <wakeup>:
{
    2d30:	fe010113          	add	sp,sp,-32
    2d34:	00112e23          	sw	ra,28(sp)
    2d38:	00812c23          	sw	s0,24(sp)
    2d3c:	00912a23          	sw	s1,20(sp)
    2d40:	01212823          	sw	s2,16(sp)
    2d44:	01312623          	sw	s3,12(sp)
    2d48:	01412423          	sw	s4,8(sp)
    2d4c:	01512223          	sw	s5,4(sp)
    2d50:	02010413          	add	s0,sp,32
    2d54:	00050a13          	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    2d58:	00010497          	auipc	s1,0x10
    2d5c:	98c48493          	add	s1,s1,-1652 # 126e4 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    2d60:	00100993          	li	s3,1
      p->state = RUNNABLE;
    2d64:	00200a93          	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    2d68:	00013917          	auipc	s2,0x13
    2d6c:	97c90913          	add	s2,s2,-1668 # 156e4 <tickslock>
    2d70:	0180006f          	j	2d88 <wakeup+0x58>
    release(&p->lock);
    2d74:	00048513          	mv	a0,s1
    2d78:	ffffe097          	auipc	ra,0xffffe
    2d7c:	0a0080e7          	jalr	160(ra) # e18 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    2d80:	0c048493          	add	s1,s1,192
    2d84:	03248463          	beq	s1,s2,2dac <wakeup+0x7c>
    acquire(&p->lock);
    2d88:	00048513          	mv	a0,s1
    2d8c:	ffffe097          	auipc	ra,0xffffe
    2d90:	018080e7          	jalr	24(ra) # da4 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    2d94:	00c4a783          	lw	a5,12(s1)
    2d98:	fd379ee3          	bne	a5,s3,2d74 <wakeup+0x44>
    2d9c:	0144a783          	lw	a5,20(s1)
    2da0:	fd479ae3          	bne	a5,s4,2d74 <wakeup+0x44>
      p->state = RUNNABLE;
    2da4:	0154a623          	sw	s5,12(s1)
    2da8:	fcdff06f          	j	2d74 <wakeup+0x44>
}
    2dac:	01c12083          	lw	ra,28(sp)
    2db0:	01812403          	lw	s0,24(sp)
    2db4:	01412483          	lw	s1,20(sp)
    2db8:	01012903          	lw	s2,16(sp)
    2dbc:	00c12983          	lw	s3,12(sp)
    2dc0:	00812a03          	lw	s4,8(sp)
    2dc4:	00412a83          	lw	s5,4(sp)
    2dc8:	02010113          	add	sp,sp,32
    2dcc:	00008067          	ret

00002dd0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    2dd0:	fe010113          	add	sp,sp,-32
    2dd4:	00112e23          	sw	ra,28(sp)
    2dd8:	00812c23          	sw	s0,24(sp)
    2ddc:	00912a23          	sw	s1,20(sp)
    2de0:	01212823          	sw	s2,16(sp)
    2de4:	01312623          	sw	s3,12(sp)
    2de8:	02010413          	add	s0,sp,32
    2dec:	00050913          	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    2df0:	00010497          	auipc	s1,0x10
    2df4:	8f448493          	add	s1,s1,-1804 # 126e4 <proc>
    2df8:	00013997          	auipc	s3,0x13
    2dfc:	8ec98993          	add	s3,s3,-1812 # 156e4 <tickslock>
    acquire(&p->lock);
    2e00:	00048513          	mv	a0,s1
    2e04:	ffffe097          	auipc	ra,0xffffe
    2e08:	fa0080e7          	jalr	-96(ra) # da4 <acquire>
    if(p->pid == pid){
    2e0c:	0204a783          	lw	a5,32(s1)
    2e10:	03278063          	beq	a5,s2,2e30 <kill+0x60>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    2e14:	00048513          	mv	a0,s1
    2e18:	ffffe097          	auipc	ra,0xffffe
    2e1c:	000080e7          	jalr	ra # e18 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    2e20:	0c048493          	add	s1,s1,192
    2e24:	fd349ee3          	bne	s1,s3,2e00 <kill+0x30>
  }
  return -1;
    2e28:	fff00513          	li	a0,-1
    2e2c:	0240006f          	j	2e50 <kill+0x80>
      p->killed = 1;
    2e30:	00100793          	li	a5,1
    2e34:	00f4ac23          	sw	a5,24(s1)
      if(p->state == SLEEPING){
    2e38:	00c4a703          	lw	a4,12(s1)
    2e3c:	02f70863          	beq	a4,a5,2e6c <kill+0x9c>
      release(&p->lock);
    2e40:	00048513          	mv	a0,s1
    2e44:	ffffe097          	auipc	ra,0xffffe
    2e48:	fd4080e7          	jalr	-44(ra) # e18 <release>
      return 0;
    2e4c:	00000513          	li	a0,0
}
    2e50:	01c12083          	lw	ra,28(sp)
    2e54:	01812403          	lw	s0,24(sp)
    2e58:	01412483          	lw	s1,20(sp)
    2e5c:	01012903          	lw	s2,16(sp)
    2e60:	00c12983          	lw	s3,12(sp)
    2e64:	02010113          	add	sp,sp,32
    2e68:	00008067          	ret
        p->state = RUNNABLE;
    2e6c:	00200793          	li	a5,2
    2e70:	00f4a623          	sw	a5,12(s1)
    2e74:	fcdff06f          	j	2e40 <kill+0x70>

00002e78 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint32 dst, void *src, uint32 len)
{
    2e78:	fe010113          	add	sp,sp,-32
    2e7c:	00112e23          	sw	ra,28(sp)
    2e80:	00812c23          	sw	s0,24(sp)
    2e84:	00912a23          	sw	s1,20(sp)
    2e88:	01212823          	sw	s2,16(sp)
    2e8c:	01312623          	sw	s3,12(sp)
    2e90:	01412423          	sw	s4,8(sp)
    2e94:	02010413          	add	s0,sp,32
    2e98:	00050493          	mv	s1,a0
    2e9c:	00058913          	mv	s2,a1
    2ea0:	00060993          	mv	s3,a2
    2ea4:	00068a13          	mv	s4,a3
  struct proc *p = myproc();
    2ea8:	fffff097          	auipc	ra,0xfffff
    2eac:	228080e7          	jalr	552(ra) # 20d0 <myproc>
  if(user_dst){
    2eb0:	02048e63          	beqz	s1,2eec <either_copyout+0x74>
    return copyout(p->pagetable, dst, src, len);
    2eb4:	000a0693          	mv	a3,s4
    2eb8:	00098613          	mv	a2,s3
    2ebc:	00090593          	mv	a1,s2
    2ec0:	02c52503          	lw	a0,44(a0)
    2ec4:	fffff097          	auipc	ra,0xfffff
    2ec8:	d60080e7          	jalr	-672(ra) # 1c24 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    2ecc:	01c12083          	lw	ra,28(sp)
    2ed0:	01812403          	lw	s0,24(sp)
    2ed4:	01412483          	lw	s1,20(sp)
    2ed8:	01012903          	lw	s2,16(sp)
    2edc:	00c12983          	lw	s3,12(sp)
    2ee0:	00812a03          	lw	s4,8(sp)
    2ee4:	02010113          	add	sp,sp,32
    2ee8:	00008067          	ret
    memmove((char *)dst, src, len);
    2eec:	000a0613          	mv	a2,s4
    2ef0:	00098593          	mv	a1,s3
    2ef4:	00090513          	mv	a0,s2
    2ef8:	ffffe097          	auipc	ra,0xffffe
    2efc:	ffc080e7          	jalr	-4(ra) # ef4 <memmove>
    return 0;
    2f00:	00048513          	mv	a0,s1
    2f04:	fc9ff06f          	j	2ecc <either_copyout+0x54>

00002f08 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint32 src, uint32 len)
{
    2f08:	fe010113          	add	sp,sp,-32
    2f0c:	00112e23          	sw	ra,28(sp)
    2f10:	00812c23          	sw	s0,24(sp)
    2f14:	00912a23          	sw	s1,20(sp)
    2f18:	01212823          	sw	s2,16(sp)
    2f1c:	01312623          	sw	s3,12(sp)
    2f20:	01412423          	sw	s4,8(sp)
    2f24:	02010413          	add	s0,sp,32
    2f28:	00050913          	mv	s2,a0
    2f2c:	00058493          	mv	s1,a1
    2f30:	00060993          	mv	s3,a2
    2f34:	00068a13          	mv	s4,a3
  struct proc *p = myproc();
    2f38:	fffff097          	auipc	ra,0xfffff
    2f3c:	198080e7          	jalr	408(ra) # 20d0 <myproc>
  if(user_src){
    2f40:	02048e63          	beqz	s1,2f7c <either_copyin+0x74>
    return copyin(p->pagetable, dst, src, len);
    2f44:	000a0693          	mv	a3,s4
    2f48:	00098613          	mv	a2,s3
    2f4c:	00090593          	mv	a1,s2
    2f50:	02c52503          	lw	a0,44(a0)
    2f54:	fffff097          	auipc	ra,0xfffff
    2f58:	db8080e7          	jalr	-584(ra) # 1d0c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    2f5c:	01c12083          	lw	ra,28(sp)
    2f60:	01812403          	lw	s0,24(sp)
    2f64:	01412483          	lw	s1,20(sp)
    2f68:	01012903          	lw	s2,16(sp)
    2f6c:	00c12983          	lw	s3,12(sp)
    2f70:	00812a03          	lw	s4,8(sp)
    2f74:	02010113          	add	sp,sp,32
    2f78:	00008067          	ret
    memmove(dst, (char*)src, len);
    2f7c:	000a0613          	mv	a2,s4
    2f80:	00098593          	mv	a1,s3
    2f84:	00090513          	mv	a0,s2
    2f88:	ffffe097          	auipc	ra,0xffffe
    2f8c:	f6c080e7          	jalr	-148(ra) # ef4 <memmove>
    return 0;
    2f90:	00048513          	mv	a0,s1
    2f94:	fc9ff06f          	j	2f5c <either_copyin+0x54>

00002f98 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    2f98:	fd010113          	add	sp,sp,-48
    2f9c:	02112623          	sw	ra,44(sp)
    2fa0:	02812423          	sw	s0,40(sp)
    2fa4:	02912223          	sw	s1,36(sp)
    2fa8:	03212023          	sw	s2,32(sp)
    2fac:	01312e23          	sw	s3,28(sp)
    2fb0:	01412c23          	sw	s4,24(sp)
    2fb4:	01512a23          	sw	s5,20(sp)
    2fb8:	01612823          	sw	s6,16(sp)
    2fbc:	01712623          	sw	s7,12(sp)
    2fc0:	03010413          	add	s0,sp,48
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    2fc4:	00005517          	auipc	a0,0x5
    2fc8:	1fc50513          	add	a0,a0,508 # 81c0 <userret+0x120>
    2fcc:	ffffd097          	auipc	ra,0xffffd
    2fd0:	71c080e7          	jalr	1820(ra) # 6e8 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    2fd4:	0000f497          	auipc	s1,0xf
    2fd8:	7c048493          	add	s1,s1,1984 # 12794 <proc+0xb0>
    2fdc:	00012917          	auipc	s2,0x12
    2fe0:	7b890913          	add	s2,s2,1976 # 15794 <bcache+0xa4>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    2fe4:	00400b13          	li	s6,4
      state = states[p->state];
    else
      state = "???";
    2fe8:	00005997          	auipc	s3,0x5
    2fec:	37498993          	add	s3,s3,884 # 835c <userret+0x2bc>
    printf("%d %s %s", p->pid, state, p->name);
    2ff0:	00005a97          	auipc	s5,0x5
    2ff4:	370a8a93          	add	s5,s5,880 # 8360 <userret+0x2c0>
    printf("\n");
    2ff8:	00005a17          	auipc	s4,0x5
    2ffc:	1c8a0a13          	add	s4,s4,456 # 81c0 <userret+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    3000:	00005b97          	auipc	s7,0x5
    3004:	778b8b93          	add	s7,s7,1912 # 8778 <states.0>
    3008:	0280006f          	j	3030 <procdump+0x98>
    printf("%d %s %s", p->pid, state, p->name);
    300c:	f706a583          	lw	a1,-144(a3)
    3010:	000a8513          	mv	a0,s5
    3014:	ffffd097          	auipc	ra,0xffffd
    3018:	6d4080e7          	jalr	1748(ra) # 6e8 <printf>
    printf("\n");
    301c:	000a0513          	mv	a0,s4
    3020:	ffffd097          	auipc	ra,0xffffd
    3024:	6c8080e7          	jalr	1736(ra) # 6e8 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    3028:	0c048493          	add	s1,s1,192
    302c:	03248863          	beq	s1,s2,305c <procdump+0xc4>
    if(p->state == UNUSED)
    3030:	00048693          	mv	a3,s1
    3034:	f5c4a783          	lw	a5,-164(s1)
    3038:	fe0788e3          	beqz	a5,3028 <procdump+0x90>
      state = "???";
    303c:	00098613          	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    3040:	fcfb66e3          	bltu	s6,a5,300c <procdump+0x74>
    3044:	00279793          	sll	a5,a5,0x2
    3048:	00fb87b3          	add	a5,s7,a5
    304c:	0007a603          	lw	a2,0(a5)
    3050:	fa061ee3          	bnez	a2,300c <procdump+0x74>
      state = "???";
    3054:	00098613          	mv	a2,s3
    3058:	fb5ff06f          	j	300c <procdump+0x74>
  }
}
    305c:	02c12083          	lw	ra,44(sp)
    3060:	02812403          	lw	s0,40(sp)
    3064:	02412483          	lw	s1,36(sp)
    3068:	02012903          	lw	s2,32(sp)
    306c:	01c12983          	lw	s3,28(sp)
    3070:	01812a03          	lw	s4,24(sp)
    3074:	01412a83          	lw	s5,20(sp)
    3078:	01012b03          	lw	s6,16(sp)
    307c:	00c12b83          	lw	s7,12(sp)
    3080:	03010113          	add	sp,sp,48
    3084:	00008067          	ret

00003088 <swtch>:
    3088:	00152023          	sw	ra,0(a0)
    308c:	00252223          	sw	sp,4(a0)
    3090:	00852423          	sw	s0,8(a0)
    3094:	00952623          	sw	s1,12(a0)
    3098:	01252823          	sw	s2,16(a0)
    309c:	01352a23          	sw	s3,20(a0)
    30a0:	01452c23          	sw	s4,24(a0)
    30a4:	01552e23          	sw	s5,28(a0)
    30a8:	03652023          	sw	s6,32(a0)
    30ac:	03752223          	sw	s7,36(a0)
    30b0:	03852423          	sw	s8,40(a0)
    30b4:	03952623          	sw	s9,44(a0)
    30b8:	03a52823          	sw	s10,48(a0)
    30bc:	03b52a23          	sw	s11,52(a0)
    30c0:	0005a083          	lw	ra,0(a1)
    30c4:	0045a103          	lw	sp,4(a1)
    30c8:	0085a403          	lw	s0,8(a1)
    30cc:	00c5a483          	lw	s1,12(a1)
    30d0:	0105a903          	lw	s2,16(a1)
    30d4:	0145a983          	lw	s3,20(a1)
    30d8:	0185aa03          	lw	s4,24(a1)
    30dc:	01c5aa83          	lw	s5,28(a1)
    30e0:	0205ab03          	lw	s6,32(a1)
    30e4:	0245ab83          	lw	s7,36(a1)
    30e8:	0285ac03          	lw	s8,40(a1)
    30ec:	02c5ac83          	lw	s9,44(a1)
    30f0:	0305ad03          	lw	s10,48(a1)
    30f4:	0345ad83          	lw	s11,52(a1)
    30f8:	00008067          	ret

000030fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    30fc:	ff010113          	add	sp,sp,-16
    3100:	00112623          	sw	ra,12(sp)
    3104:	00812423          	sw	s0,8(sp)
    3108:	01010413          	add	s0,sp,16
  initlock(&tickslock, "time");
    310c:	00005597          	auipc	a1,0x5
    3110:	28858593          	add	a1,a1,648 # 8394 <userret+0x2f4>
    3114:	00012517          	auipc	a0,0x12
    3118:	5d050513          	add	a0,a0,1488 # 156e4 <tickslock>
    311c:	ffffe097          	auipc	ra,0xffffe
    3120:	b04080e7          	jalr	-1276(ra) # c20 <initlock>
}
    3124:	00c12083          	lw	ra,12(sp)
    3128:	00812403          	lw	s0,8(sp)
    312c:	01010113          	add	sp,sp,16
    3130:	00008067          	ret

00003134 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    3134:	ff010113          	add	sp,sp,-16
    3138:	00812623          	sw	s0,12(sp)
    313c:	01010413          	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    3140:	00004797          	auipc	a5,0x4
    3144:	64078793          	add	a5,a5,1600 # 7780 <kernelvec>
    3148:	10579073          	csrw	stvec,a5
  w_stvec((uint32)kernelvec);
}
    314c:	00c12403          	lw	s0,12(sp)
    3150:	01010113          	add	sp,sp,16
    3154:	00008067          	ret

00003158 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    3158:	ff010113          	add	sp,sp,-16
    315c:	00112623          	sw	ra,12(sp)
    3160:	00812423          	sw	s0,8(sp)
    3164:	01010413          	add	s0,sp,16
  struct proc *p = myproc();
    3168:	fffff097          	auipc	ra,0xfffff
    316c:	f68080e7          	jalr	-152(ra) # 20d0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3170:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    3174:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    3178:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    317c:	00005617          	auipc	a2,0x5
    3180:	e8460613          	add	a2,a2,-380 # 8000 <trampoline>
    3184:	00005797          	auipc	a5,0x5
    3188:	e7c78793          	add	a5,a5,-388 # 8000 <trampoline>
    318c:	40c787b3          	sub	a5,a5,a2
    3190:	fffff737          	lui	a4,0xfffff
    3194:	00e787b3          	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    3198:	10579073          	csrw	stvec,a5

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    319c:	03052783          	lw	a5,48(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    31a0:	18002773          	csrr	a4,satp
    31a4:	00e7a023          	sw	a4,0(a5)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    31a8:	03052703          	lw	a4,48(a0)
    31ac:	000016b7          	lui	a3,0x1
    31b0:	02452783          	lw	a5,36(a0)
    31b4:	00d787b3          	add	a5,a5,a3
    31b8:	00f72223          	sw	a5,4(a4) # fffff004 <end+0xfffddff0>
  p->tf->kernel_trap = (uint32)usertrap;
    31bc:	03052783          	lw	a5,48(a0)
    31c0:	00000717          	auipc	a4,0x0
    31c4:	15870713          	add	a4,a4,344 # 3318 <usertrap>
    31c8:	00e7a423          	sw	a4,8(a5)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    31cc:	03052783          	lw	a5,48(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    31d0:	00020713          	mv	a4,tp
    31d4:	00e7a823          	sw	a4,16(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    31d8:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    31dc:	eff7f793          	and	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    31e0:	0207e793          	or	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    31e4:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    31e8:	03052783          	lw	a5,48(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    31ec:	00c7a783          	lw	a5,12(a5)
    31f0:	14179073          	csrw	sepc,a5

  // tell trampoline.S the user page table to switch to.
  uint32 satp = MAKE_SATP(p->pagetable);
    31f4:	02c52703          	lw	a4,44(a0)
    31f8:	00c75713          	srl	a4,a4,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint32 fn = TRAMPOLINE + (userret - trampoline);
    31fc:	00005797          	auipc	a5,0x5
    3200:	ea478793          	add	a5,a5,-348 # 80a0 <userret>
    3204:	40c787b3          	sub	a5,a5,a2
    3208:	40d787b3          	sub	a5,a5,a3
  ((void (*)(uint32,uint32))fn)(TRAPFRAME, satp);
    320c:	800005b7          	lui	a1,0x80000
    3210:	00b765b3          	or	a1,a4,a1
    3214:	ffffe537          	lui	a0,0xffffe
    3218:	000780e7          	jalr	a5
}
    321c:	00c12083          	lw	ra,12(sp)
    3220:	00812403          	lw	s0,8(sp)
    3224:	01010113          	add	sp,sp,16
    3228:	00008067          	ret

0000322c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    322c:	ff010113          	add	sp,sp,-16
    3230:	00112623          	sw	ra,12(sp)
    3234:	00812423          	sw	s0,8(sp)
    3238:	00912223          	sw	s1,4(sp)
    323c:	01010413          	add	s0,sp,16
  acquire(&tickslock);
    3240:	00012497          	auipc	s1,0x12
    3244:	4a448493          	add	s1,s1,1188 # 156e4 <tickslock>
    3248:	00048513          	mv	a0,s1
    324c:	ffffe097          	auipc	ra,0xffffe
    3250:	b58080e7          	jalr	-1192(ra) # da4 <acquire>
  ticks++;
    3254:	0001e517          	auipc	a0,0x1e
    3258:	dbc50513          	add	a0,a0,-580 # 21010 <ticks>
    325c:	00052783          	lw	a5,0(a0)
    3260:	00178793          	add	a5,a5,1
    3264:	00f52023          	sw	a5,0(a0)
  wakeup(&ticks);
    3268:	00000097          	auipc	ra,0x0
    326c:	ac8080e7          	jalr	-1336(ra) # 2d30 <wakeup>
  release(&tickslock);
    3270:	00048513          	mv	a0,s1
    3274:	ffffe097          	auipc	ra,0xffffe
    3278:	ba4080e7          	jalr	-1116(ra) # e18 <release>
}
    327c:	00c12083          	lw	ra,12(sp)
    3280:	00812403          	lw	s0,8(sp)
    3284:	00412483          	lw	s1,4(sp)
    3288:	01010113          	add	sp,sp,16
    328c:	00008067          	ret

00003290 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    3290:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    3294:	00000513          	li	a0,0
  if((scause & 0x80000000L) &&
    3298:	0607de63          	bgez	a5,3314 <devintr+0x84>
{
    329c:	ff010113          	add	sp,sp,-16
    32a0:	00112623          	sw	ra,12(sp)
    32a4:	00812423          	sw	s0,8(sp)
    32a8:	01010413          	add	s0,sp,16
     (scause & 0xff) == 9){
    32ac:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x80000000L) &&
    32b0:	00900693          	li	a3,9
    32b4:	02d70263          	beq	a4,a3,32d8 <devintr+0x48>
  } else if(scause == 0x80000001L){
    32b8:	80000737          	lui	a4,0x80000
    32bc:	00170713          	add	a4,a4,1 # 80000001 <end+0x7ffdefed>
    return 0;
    32c0:	00000513          	li	a0,0
  } else if(scause == 0x80000001L){
    32c4:	02e78263          	beq	a5,a4,32e8 <devintr+0x58>
  }
}
    32c8:	00c12083          	lw	ra,12(sp)
    32cc:	00812403          	lw	s0,8(sp)
    32d0:	01010113          	add	sp,sp,16
    32d4:	00008067          	ret
      uartintr();
    32d8:	ffffd097          	auipc	ra,0xffffd
    32dc:	728080e7          	jalr	1832(ra) # a00 <uartintr>
    return 1;
    32e0:	00100513          	li	a0,1
    32e4:	fe5ff06f          	j	32c8 <devintr+0x38>
    if(cpuid() == 0){
    32e8:	fffff097          	auipc	ra,0xfffff
    32ec:	d98080e7          	jalr	-616(ra) # 2080 <cpuid>
    32f0:	00050c63          	beqz	a0,3308 <devintr+0x78>
  asm volatile("csrr %0, sip" : "=r" (x) );
    32f4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    32f8:	ffd7f793          	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    32fc:	14479073          	csrw	sip,a5
    return 2;
    3300:	00200513          	li	a0,2
    3304:	fc5ff06f          	j	32c8 <devintr+0x38>
      clockintr();
    3308:	00000097          	auipc	ra,0x0
    330c:	f24080e7          	jalr	-220(ra) # 322c <clockintr>
    3310:	fe5ff06f          	j	32f4 <devintr+0x64>
}
    3314:	00008067          	ret

00003318 <usertrap>:
{
    3318:	ff010113          	add	sp,sp,-16
    331c:	00112623          	sw	ra,12(sp)
    3320:	00812423          	sw	s0,8(sp)
    3324:	00912223          	sw	s1,4(sp)
    3328:	01212023          	sw	s2,0(sp)
    332c:	01010413          	add	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3330:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    3334:	1007f793          	and	a5,a5,256
    3338:	08079a63          	bnez	a5,33cc <usertrap+0xb4>
  asm volatile("csrw stvec, %0" : : "r" (x));
    333c:	00004797          	auipc	a5,0x4
    3340:	44478793          	add	a5,a5,1092 # 7780 <kernelvec>
    3344:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    3348:	fffff097          	auipc	ra,0xfffff
    334c:	d88080e7          	jalr	-632(ra) # 20d0 <myproc>
    3350:	00050493          	mv	s1,a0
  p->tf->epc = r_sepc();
    3354:	03052783          	lw	a5,48(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    3358:	14102773          	csrr	a4,sepc
    335c:	00e7a623          	sw	a4,12(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    3360:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    3364:	00800793          	li	a5,8
    3368:	08f71263          	bne	a4,a5,33ec <usertrap+0xd4>
    if(p->killed)
    336c:	01852783          	lw	a5,24(a0)
    3370:	06079663          	bnez	a5,33dc <usertrap+0xc4>
    p->tf->epc += 4;
    3374:	0304a703          	lw	a4,48(s1)
    3378:	00c72783          	lw	a5,12(a4)
    337c:	00478793          	add	a5,a5,4
    3380:	00f72623          	sw	a5,12(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    3384:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    3388:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    338c:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3390:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    3394:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    3398:	10079073          	csrw	sstatus,a5
    syscall();
    339c:	00000097          	auipc	ra,0x0
    33a0:	430080e7          	jalr	1072(ra) # 37cc <syscall>
  if(p->killed)
    33a4:	0184a783          	lw	a5,24(s1)
    33a8:	0a079c63          	bnez	a5,3460 <usertrap+0x148>
  usertrapret();
    33ac:	00000097          	auipc	ra,0x0
    33b0:	dac080e7          	jalr	-596(ra) # 3158 <usertrapret>
}
    33b4:	00c12083          	lw	ra,12(sp)
    33b8:	00812403          	lw	s0,8(sp)
    33bc:	00412483          	lw	s1,4(sp)
    33c0:	00012903          	lw	s2,0(sp)
    33c4:	01010113          	add	sp,sp,16
    33c8:	00008067          	ret
    panic("usertrap: not from user mode");
    33cc:	00005517          	auipc	a0,0x5
    33d0:	fd050513          	add	a0,a0,-48 # 839c <userret+0x2fc>
    33d4:	ffffd097          	auipc	ra,0xffffd
    33d8:	2b8080e7          	jalr	696(ra) # 68c <panic>
      exit(-1);
    33dc:	fff00513          	li	a0,-1
    33e0:	fffff097          	auipc	ra,0xfffff
    33e4:	5a0080e7          	jalr	1440(ra) # 2980 <exit>
    33e8:	f8dff06f          	j	3374 <usertrap+0x5c>
  } else if((which_dev = devintr()) != 0){
    33ec:	00000097          	auipc	ra,0x0
    33f0:	ea4080e7          	jalr	-348(ra) # 3290 <devintr>
    33f4:	00050913          	mv	s2,a0
    33f8:	00050863          	beqz	a0,3408 <usertrap+0xf0>
  if(p->killed)
    33fc:	0184a783          	lw	a5,24(s1)
    3400:	04078663          	beqz	a5,344c <usertrap+0x134>
    3404:	03c0006f          	j	3440 <usertrap+0x128>
  asm volatile("csrr %0, scause" : "=r" (x) );
    3408:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    340c:	0204a603          	lw	a2,32(s1)
    3410:	00005517          	auipc	a0,0x5
    3414:	fac50513          	add	a0,a0,-84 # 83bc <userret+0x31c>
    3418:	ffffd097          	auipc	ra,0xffffd
    341c:	2d0080e7          	jalr	720(ra) # 6e8 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    3420:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    3424:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    3428:	00005517          	auipc	a0,0x5
    342c:	fc050513          	add	a0,a0,-64 # 83e8 <userret+0x348>
    3430:	ffffd097          	auipc	ra,0xffffd
    3434:	2b8080e7          	jalr	696(ra) # 6e8 <printf>
    p->killed = 1;
    3438:	00100793          	li	a5,1
    343c:	00f4ac23          	sw	a5,24(s1)
    exit(-1);
    3440:	fff00513          	li	a0,-1
    3444:	fffff097          	auipc	ra,0xfffff
    3448:	53c080e7          	jalr	1340(ra) # 2980 <exit>
  if(which_dev == 2)
    344c:	00200793          	li	a5,2
    3450:	f4f91ee3          	bne	s2,a5,33ac <usertrap+0x94>
    yield();
    3454:	fffff097          	auipc	ra,0xfffff
    3458:	668080e7          	jalr	1640(ra) # 2abc <yield>
    345c:	f51ff06f          	j	33ac <usertrap+0x94>
  int which_dev = 0;
    3460:	00000913          	li	s2,0
    3464:	fddff06f          	j	3440 <usertrap+0x128>

00003468 <kerneltrap>:
{
    3468:	fe010113          	add	sp,sp,-32
    346c:	00112e23          	sw	ra,28(sp)
    3470:	00812c23          	sw	s0,24(sp)
    3474:	00912a23          	sw	s1,20(sp)
    3478:	01212823          	sw	s2,16(sp)
    347c:	01312623          	sw	s3,12(sp)
    3480:	02010413          	add	s0,sp,32
  asm volatile("csrr %0, sepc" : "=r" (x) );
    3484:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3488:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    348c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    3490:	1004f793          	and	a5,s1,256
    3494:	04078463          	beqz	a5,34dc <kerneltrap+0x74>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    3498:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    349c:	0027f793          	and	a5,a5,2
  if(intr_get() != 0)
    34a0:	04079663          	bnez	a5,34ec <kerneltrap+0x84>
  if((which_dev = devintr()) == 0){
    34a4:	00000097          	auipc	ra,0x0
    34a8:	dec080e7          	jalr	-532(ra) # 3290 <devintr>
    34ac:	04050863          	beqz	a0,34fc <kerneltrap+0x94>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    34b0:	00200793          	li	a5,2
    34b4:	08f50263          	beq	a0,a5,3538 <kerneltrap+0xd0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    34b8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    34bc:	10049073          	csrw	sstatus,s1
}
    34c0:	01c12083          	lw	ra,28(sp)
    34c4:	01812403          	lw	s0,24(sp)
    34c8:	01412483          	lw	s1,20(sp)
    34cc:	01012903          	lw	s2,16(sp)
    34d0:	00c12983          	lw	s3,12(sp)
    34d4:	02010113          	add	sp,sp,32
    34d8:	00008067          	ret
    panic("kerneltrap: not from supervisor mode");
    34dc:	00005517          	auipc	a0,0x5
    34e0:	f2c50513          	add	a0,a0,-212 # 8408 <userret+0x368>
    34e4:	ffffd097          	auipc	ra,0xffffd
    34e8:	1a8080e7          	jalr	424(ra) # 68c <panic>
    panic("kerneltrap: interrupts enabled");
    34ec:	00005517          	auipc	a0,0x5
    34f0:	f4450513          	add	a0,a0,-188 # 8430 <userret+0x390>
    34f4:	ffffd097          	auipc	ra,0xffffd
    34f8:	198080e7          	jalr	408(ra) # 68c <panic>
    printf("scause %p\n", scause);
    34fc:	00098593          	mv	a1,s3
    3500:	00005517          	auipc	a0,0x5
    3504:	f5050513          	add	a0,a0,-176 # 8450 <userret+0x3b0>
    3508:	ffffd097          	auipc	ra,0xffffd
    350c:	1e0080e7          	jalr	480(ra) # 6e8 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    3510:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    3514:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    3518:	00005517          	auipc	a0,0x5
    351c:	edc50513          	add	a0,a0,-292 # 83f4 <userret+0x354>
    3520:	ffffd097          	auipc	ra,0xffffd
    3524:	1c8080e7          	jalr	456(ra) # 6e8 <printf>
    panic("kerneltrap");
    3528:	00005517          	auipc	a0,0x5
    352c:	f3450513          	add	a0,a0,-204 # 845c <userret+0x3bc>
    3530:	ffffd097          	auipc	ra,0xffffd
    3534:	15c080e7          	jalr	348(ra) # 68c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    3538:	fffff097          	auipc	ra,0xfffff
    353c:	b98080e7          	jalr	-1128(ra) # 20d0 <myproc>
    3540:	f6050ce3          	beqz	a0,34b8 <kerneltrap+0x50>
    3544:	fffff097          	auipc	ra,0xfffff
    3548:	b8c080e7          	jalr	-1140(ra) # 20d0 <myproc>
    354c:	00c52703          	lw	a4,12(a0)
    3550:	00300793          	li	a5,3
    3554:	f6f712e3          	bne	a4,a5,34b8 <kerneltrap+0x50>
    yield();
    3558:	fffff097          	auipc	ra,0xfffff
    355c:	564080e7          	jalr	1380(ra) # 2abc <yield>
    3560:	f59ff06f          	j	34b8 <kerneltrap+0x50>

00003564 <argraw>:
  return strlen(buf);
}

static uint32
argraw(int n)
{
    3564:	ff010113          	add	sp,sp,-16
    3568:	00112623          	sw	ra,12(sp)
    356c:	00812423          	sw	s0,8(sp)
    3570:	00912223          	sw	s1,4(sp)
    3574:	01010413          	add	s0,sp,16
    3578:	00050493          	mv	s1,a0
  struct proc *p = myproc();
    357c:	fffff097          	auipc	ra,0xfffff
    3580:	b54080e7          	jalr	-1196(ra) # 20d0 <myproc>
  switch (n) {
    3584:	00500793          	li	a5,5
    3588:	0697ec63          	bltu	a5,s1,3600 <argraw+0x9c>
    358c:	00249493          	sll	s1,s1,0x2
    3590:	00005717          	auipc	a4,0x5
    3594:	1fc70713          	add	a4,a4,508 # 878c <states.0+0x14>
    3598:	00e484b3          	add	s1,s1,a4
    359c:	0004a783          	lw	a5,0(s1)
    35a0:	00e787b3          	add	a5,a5,a4
    35a4:	00078067          	jr	a5
  case 0:
    return p->tf->a0;
    35a8:	03052783          	lw	a5,48(a0)
    35ac:	0387a503          	lw	a0,56(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    35b0:	00c12083          	lw	ra,12(sp)
    35b4:	00812403          	lw	s0,8(sp)
    35b8:	00412483          	lw	s1,4(sp)
    35bc:	01010113          	add	sp,sp,16
    35c0:	00008067          	ret
    return p->tf->a1;
    35c4:	03052783          	lw	a5,48(a0)
    35c8:	03c7a503          	lw	a0,60(a5)
    35cc:	fe5ff06f          	j	35b0 <argraw+0x4c>
    return p->tf->a2;
    35d0:	03052783          	lw	a5,48(a0)
    35d4:	0407a503          	lw	a0,64(a5)
    35d8:	fd9ff06f          	j	35b0 <argraw+0x4c>
    return p->tf->a3;
    35dc:	03052783          	lw	a5,48(a0)
    35e0:	0447a503          	lw	a0,68(a5)
    35e4:	fcdff06f          	j	35b0 <argraw+0x4c>
    return p->tf->a4;
    35e8:	03052783          	lw	a5,48(a0)
    35ec:	0487a503          	lw	a0,72(a5)
    35f0:	fc1ff06f          	j	35b0 <argraw+0x4c>
    return p->tf->a5;
    35f4:	03052783          	lw	a5,48(a0)
    35f8:	04c7a503          	lw	a0,76(a5)
    35fc:	fb5ff06f          	j	35b0 <argraw+0x4c>
  panic("argraw");
    3600:	00005517          	auipc	a0,0x5
    3604:	e6850513          	add	a0,a0,-408 # 8468 <userret+0x3c8>
    3608:	ffffd097          	auipc	ra,0xffffd
    360c:	084080e7          	jalr	132(ra) # 68c <panic>

00003610 <fetchaddr>:
{
    3610:	ff010113          	add	sp,sp,-16
    3614:	00112623          	sw	ra,12(sp)
    3618:	00812423          	sw	s0,8(sp)
    361c:	00912223          	sw	s1,4(sp)
    3620:	01212023          	sw	s2,0(sp)
    3624:	01010413          	add	s0,sp,16
    3628:	00050493          	mv	s1,a0
    362c:	00058913          	mv	s2,a1
  struct proc *p = myproc();
    3630:	fffff097          	auipc	ra,0xfffff
    3634:	aa0080e7          	jalr	-1376(ra) # 20d0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint32) > p->sz)
    3638:	02852783          	lw	a5,40(a0)
    363c:	04f4f263          	bgeu	s1,a5,3680 <fetchaddr+0x70>
    3640:	00448713          	add	a4,s1,4
    3644:	04e7e263          	bltu	a5,a4,3688 <fetchaddr+0x78>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    3648:	00400693          	li	a3,4
    364c:	00048613          	mv	a2,s1
    3650:	00090593          	mv	a1,s2
    3654:	02c52503          	lw	a0,44(a0)
    3658:	ffffe097          	auipc	ra,0xffffe
    365c:	6b4080e7          	jalr	1716(ra) # 1d0c <copyin>
    3660:	00a03533          	snez	a0,a0
    3664:	40a00533          	neg	a0,a0
}
    3668:	00c12083          	lw	ra,12(sp)
    366c:	00812403          	lw	s0,8(sp)
    3670:	00412483          	lw	s1,4(sp)
    3674:	00012903          	lw	s2,0(sp)
    3678:	01010113          	add	sp,sp,16
    367c:	00008067          	ret
    return -1;
    3680:	fff00513          	li	a0,-1
    3684:	fe5ff06f          	j	3668 <fetchaddr+0x58>
    3688:	fff00513          	li	a0,-1
    368c:	fddff06f          	j	3668 <fetchaddr+0x58>

00003690 <fetchstr>:
{
    3690:	fe010113          	add	sp,sp,-32
    3694:	00112e23          	sw	ra,28(sp)
    3698:	00812c23          	sw	s0,24(sp)
    369c:	00912a23          	sw	s1,20(sp)
    36a0:	01212823          	sw	s2,16(sp)
    36a4:	01312623          	sw	s3,12(sp)
    36a8:	02010413          	add	s0,sp,32
    36ac:	00050913          	mv	s2,a0
    36b0:	00058493          	mv	s1,a1
    36b4:	00060993          	mv	s3,a2
  struct proc *p = myproc();
    36b8:	fffff097          	auipc	ra,0xfffff
    36bc:	a18080e7          	jalr	-1512(ra) # 20d0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    36c0:	00098693          	mv	a3,s3
    36c4:	00090613          	mv	a2,s2
    36c8:	00048593          	mv	a1,s1
    36cc:	02c52503          	lw	a0,44(a0)
    36d0:	ffffe097          	auipc	ra,0xffffe
    36d4:	724080e7          	jalr	1828(ra) # 1df4 <copyinstr>
  if(err < 0)
    36d8:	00054863          	bltz	a0,36e8 <fetchstr+0x58>
  return strlen(buf);
    36dc:	00048513          	mv	a0,s1
    36e0:	ffffe097          	auipc	ra,0xffffe
    36e4:	9a4080e7          	jalr	-1628(ra) # 1084 <strlen>
}
    36e8:	01c12083          	lw	ra,28(sp)
    36ec:	01812403          	lw	s0,24(sp)
    36f0:	01412483          	lw	s1,20(sp)
    36f4:	01012903          	lw	s2,16(sp)
    36f8:	00c12983          	lw	s3,12(sp)
    36fc:	02010113          	add	sp,sp,32
    3700:	00008067          	ret

00003704 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    3704:	ff010113          	add	sp,sp,-16
    3708:	00112623          	sw	ra,12(sp)
    370c:	00812423          	sw	s0,8(sp)
    3710:	00912223          	sw	s1,4(sp)
    3714:	01010413          	add	s0,sp,16
    3718:	00058493          	mv	s1,a1
  *ip = argraw(n);
    371c:	00000097          	auipc	ra,0x0
    3720:	e48080e7          	jalr	-440(ra) # 3564 <argraw>
    3724:	00a4a023          	sw	a0,0(s1)
  return 0;
}
    3728:	00000513          	li	a0,0
    372c:	00c12083          	lw	ra,12(sp)
    3730:	00812403          	lw	s0,8(sp)
    3734:	00412483          	lw	s1,4(sp)
    3738:	01010113          	add	sp,sp,16
    373c:	00008067          	ret

00003740 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint32 *ip)
{
    3740:	ff010113          	add	sp,sp,-16
    3744:	00112623          	sw	ra,12(sp)
    3748:	00812423          	sw	s0,8(sp)
    374c:	00912223          	sw	s1,4(sp)
    3750:	01010413          	add	s0,sp,16
    3754:	00058493          	mv	s1,a1
  *ip = argraw(n);
    3758:	00000097          	auipc	ra,0x0
    375c:	e0c080e7          	jalr	-500(ra) # 3564 <argraw>
    3760:	00a4a023          	sw	a0,0(s1)
  return 0;
}
    3764:	00000513          	li	a0,0
    3768:	00c12083          	lw	ra,12(sp)
    376c:	00812403          	lw	s0,8(sp)
    3770:	00412483          	lw	s1,4(sp)
    3774:	01010113          	add	sp,sp,16
    3778:	00008067          	ret

0000377c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    377c:	ff010113          	add	sp,sp,-16
    3780:	00112623          	sw	ra,12(sp)
    3784:	00812423          	sw	s0,8(sp)
    3788:	00912223          	sw	s1,4(sp)
    378c:	01212023          	sw	s2,0(sp)
    3790:	01010413          	add	s0,sp,16
    3794:	00058493          	mv	s1,a1
    3798:	00060913          	mv	s2,a2
  *ip = argraw(n);
    379c:	00000097          	auipc	ra,0x0
    37a0:	dc8080e7          	jalr	-568(ra) # 3564 <argraw>
  uint32 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    37a4:	00090613          	mv	a2,s2
    37a8:	00048593          	mv	a1,s1
    37ac:	00000097          	auipc	ra,0x0
    37b0:	ee4080e7          	jalr	-284(ra) # 3690 <fetchstr>
}
    37b4:	00c12083          	lw	ra,12(sp)
    37b8:	00812403          	lw	s0,8(sp)
    37bc:	00412483          	lw	s1,4(sp)
    37c0:	00012903          	lw	s2,0(sp)
    37c4:	01010113          	add	sp,sp,16
    37c8:	00008067          	ret

000037cc <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    37cc:	ff010113          	add	sp,sp,-16
    37d0:	00112623          	sw	ra,12(sp)
    37d4:	00812423          	sw	s0,8(sp)
    37d8:	00912223          	sw	s1,4(sp)
    37dc:	01212023          	sw	s2,0(sp)
    37e0:	01010413          	add	s0,sp,16
  int num;
  struct proc *p = myproc();
    37e4:	fffff097          	auipc	ra,0xfffff
    37e8:	8ec080e7          	jalr	-1812(ra) # 20d0 <myproc>
    37ec:	00050493          	mv	s1,a0

  num = p->tf->a7;
    37f0:	03052903          	lw	s2,48(a0)
    37f4:	05492683          	lw	a3,84(s2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    37f8:	fff68713          	add	a4,a3,-1 # fff <strncpy+0x1b>
    37fc:	01400793          	li	a5,20
    3800:	02e7e463          	bltu	a5,a4,3828 <syscall+0x5c>
    3804:	00269713          	sll	a4,a3,0x2
    3808:	00005797          	auipc	a5,0x5
    380c:	f9c78793          	add	a5,a5,-100 # 87a4 <syscalls>
    3810:	00e787b3          	add	a5,a5,a4
    3814:	0007a783          	lw	a5,0(a5)
    3818:	00078863          	beqz	a5,3828 <syscall+0x5c>
    // printf("syscall %p!\n", num);
    p->tf->a0 = syscalls[num]();
    381c:	000780e7          	jalr	a5
    3820:	02a92c23          	sw	a0,56(s2)
    3824:	0280006f          	j	384c <syscall+0x80>
    // printf("result: %p\n", p->tf->a0);
  } else {
    printf("%d %s: unknown sys call %d\n",
    3828:	0b048613          	add	a2,s1,176
    382c:	0204a583          	lw	a1,32(s1)
    3830:	00005517          	auipc	a0,0x5
    3834:	c4050513          	add	a0,a0,-960 # 8470 <userret+0x3d0>
    3838:	ffffd097          	auipc	ra,0xffffd
    383c:	eb0080e7          	jalr	-336(ra) # 6e8 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    3840:	0304a783          	lw	a5,48(s1)
    3844:	fff00713          	li	a4,-1
    3848:	02e7ac23          	sw	a4,56(a5)
  }
}
    384c:	00c12083          	lw	ra,12(sp)
    3850:	00812403          	lw	s0,8(sp)
    3854:	00412483          	lw	s1,4(sp)
    3858:	00012903          	lw	s2,0(sp)
    385c:	01010113          	add	sp,sp,16
    3860:	00008067          	ret

00003864 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint32
sys_exit(void)
{
    3864:	fe010113          	add	sp,sp,-32
    3868:	00112e23          	sw	ra,28(sp)
    386c:	00812c23          	sw	s0,24(sp)
    3870:	02010413          	add	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    3874:	fec40593          	add	a1,s0,-20
    3878:	00000513          	li	a0,0
    387c:	00000097          	auipc	ra,0x0
    3880:	e88080e7          	jalr	-376(ra) # 3704 <argint>
    return -1;
    3884:	fff00793          	li	a5,-1
  if(argint(0, &n) < 0)
    3888:	00054a63          	bltz	a0,389c <sys_exit+0x38>
  exit(n);
    388c:	fec42503          	lw	a0,-20(s0)
    3890:	fffff097          	auipc	ra,0xfffff
    3894:	0f0080e7          	jalr	240(ra) # 2980 <exit>
  return 0;  // not reached
    3898:	00000793          	li	a5,0
}
    389c:	00078513          	mv	a0,a5
    38a0:	01c12083          	lw	ra,28(sp)
    38a4:	01812403          	lw	s0,24(sp)
    38a8:	02010113          	add	sp,sp,32
    38ac:	00008067          	ret

000038b0 <sys_getpid>:

uint32
sys_getpid(void)
{
    38b0:	ff010113          	add	sp,sp,-16
    38b4:	00112623          	sw	ra,12(sp)
    38b8:	00812423          	sw	s0,8(sp)
    38bc:	01010413          	add	s0,sp,16
  return myproc()->pid;
    38c0:	fffff097          	auipc	ra,0xfffff
    38c4:	810080e7          	jalr	-2032(ra) # 20d0 <myproc>
}
    38c8:	02052503          	lw	a0,32(a0)
    38cc:	00c12083          	lw	ra,12(sp)
    38d0:	00812403          	lw	s0,8(sp)
    38d4:	01010113          	add	sp,sp,16
    38d8:	00008067          	ret

000038dc <sys_fork>:

uint32
sys_fork(void)
{
    38dc:	ff010113          	add	sp,sp,-16
    38e0:	00112623          	sw	ra,12(sp)
    38e4:	00812423          	sw	s0,8(sp)
    38e8:	01010413          	add	s0,sp,16
  return fork();
    38ec:	fffff097          	auipc	ra,0xfffff
    38f0:	c94080e7          	jalr	-876(ra) # 2580 <fork>
}
    38f4:	00c12083          	lw	ra,12(sp)
    38f8:	00812403          	lw	s0,8(sp)
    38fc:	01010113          	add	sp,sp,16
    3900:	00008067          	ret

00003904 <sys_wait>:

uint32
sys_wait(void)
{
    3904:	fe010113          	add	sp,sp,-32
    3908:	00112e23          	sw	ra,28(sp)
    390c:	00812c23          	sw	s0,24(sp)
    3910:	02010413          	add	s0,sp,32
  uint32 p;
  if(argaddr(0, &p) < 0)
    3914:	fec40593          	add	a1,s0,-20
    3918:	00000513          	li	a0,0
    391c:	00000097          	auipc	ra,0x0
    3920:	e24080e7          	jalr	-476(ra) # 3740 <argaddr>
    3924:	00050793          	mv	a5,a0
    return -1;
    3928:	fff00513          	li	a0,-1
  if(argaddr(0, &p) < 0)
    392c:	0007c863          	bltz	a5,393c <sys_wait+0x38>
  return wait(p);
    3930:	fec42503          	lw	a0,-20(s0)
    3934:	fffff097          	auipc	ra,0xfffff
    3938:	290080e7          	jalr	656(ra) # 2bc4 <wait>
}
    393c:	01c12083          	lw	ra,28(sp)
    3940:	01812403          	lw	s0,24(sp)
    3944:	02010113          	add	sp,sp,32
    3948:	00008067          	ret

0000394c <sys_sbrk>:

uint32
sys_sbrk(void)
{
    394c:	fe010113          	add	sp,sp,-32
    3950:	00112e23          	sw	ra,28(sp)
    3954:	00812c23          	sw	s0,24(sp)
    3958:	00912a23          	sw	s1,20(sp)
    395c:	02010413          	add	s0,sp,32
  int addr;
  int n;

  if(argint(0, &n) < 0)
    3960:	fec40593          	add	a1,s0,-20
    3964:	00000513          	li	a0,0
    3968:	00000097          	auipc	ra,0x0
    396c:	d9c080e7          	jalr	-612(ra) # 3704 <argint>
    return -1;
    3970:	fff00493          	li	s1,-1
  if(argint(0, &n) < 0)
    3974:	02054063          	bltz	a0,3994 <sys_sbrk+0x48>
  addr = myproc()->sz;
    3978:	ffffe097          	auipc	ra,0xffffe
    397c:	758080e7          	jalr	1880(ra) # 20d0 <myproc>
    3980:	02852483          	lw	s1,40(a0)
  if(growproc(n) < 0)
    3984:	fec42503          	lw	a0,-20(s0)
    3988:	fffff097          	auipc	ra,0xfffff
    398c:	b6c080e7          	jalr	-1172(ra) # 24f4 <growproc>
    3990:	00054e63          	bltz	a0,39ac <sys_sbrk+0x60>
    return -1;
  return addr;
}
    3994:	00048513          	mv	a0,s1
    3998:	01c12083          	lw	ra,28(sp)
    399c:	01812403          	lw	s0,24(sp)
    39a0:	01412483          	lw	s1,20(sp)
    39a4:	02010113          	add	sp,sp,32
    39a8:	00008067          	ret
    return -1;
    39ac:	fff00493          	li	s1,-1
    39b0:	fe5ff06f          	j	3994 <sys_sbrk+0x48>

000039b4 <sys_sleep>:

uint32
sys_sleep(void)
{
    39b4:	fd010113          	add	sp,sp,-48
    39b8:	02112623          	sw	ra,44(sp)
    39bc:	02812423          	sw	s0,40(sp)
    39c0:	02912223          	sw	s1,36(sp)
    39c4:	03212023          	sw	s2,32(sp)
    39c8:	01312e23          	sw	s3,28(sp)
    39cc:	03010413          	add	s0,sp,48
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    39d0:	fdc40593          	add	a1,s0,-36
    39d4:	00000513          	li	a0,0
    39d8:	00000097          	auipc	ra,0x0
    39dc:	d2c080e7          	jalr	-724(ra) # 3704 <argint>
    return -1;
    39e0:	fff00793          	li	a5,-1
  if(argint(0, &n) < 0)
    39e4:	06054c63          	bltz	a0,3a5c <sys_sleep+0xa8>
  acquire(&tickslock);
    39e8:	00012517          	auipc	a0,0x12
    39ec:	cfc50513          	add	a0,a0,-772 # 156e4 <tickslock>
    39f0:	ffffd097          	auipc	ra,0xffffd
    39f4:	3b4080e7          	jalr	948(ra) # da4 <acquire>
  ticks0 = ticks;
    39f8:	0001d917          	auipc	s2,0x1d
    39fc:	61892903          	lw	s2,1560(s2) # 21010 <ticks>
  while(ticks - ticks0 < n){
    3a00:	fdc42783          	lw	a5,-36(s0)
    3a04:	04078263          	beqz	a5,3a48 <sys_sleep+0x94>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    3a08:	00012997          	auipc	s3,0x12
    3a0c:	cdc98993          	add	s3,s3,-804 # 156e4 <tickslock>
    3a10:	0001d497          	auipc	s1,0x1d
    3a14:	60048493          	add	s1,s1,1536 # 21010 <ticks>
    if(myproc()->killed){
    3a18:	ffffe097          	auipc	ra,0xffffe
    3a1c:	6b8080e7          	jalr	1720(ra) # 20d0 <myproc>
    3a20:	01852783          	lw	a5,24(a0)
    3a24:	04079c63          	bnez	a5,3a7c <sys_sleep+0xc8>
    sleep(&ticks, &tickslock);
    3a28:	00098593          	mv	a1,s3
    3a2c:	00048513          	mv	a0,s1
    3a30:	fffff097          	auipc	ra,0xfffff
    3a34:	0e4080e7          	jalr	228(ra) # 2b14 <sleep>
  while(ticks - ticks0 < n){
    3a38:	0004a783          	lw	a5,0(s1)
    3a3c:	412787b3          	sub	a5,a5,s2
    3a40:	fdc42703          	lw	a4,-36(s0)
    3a44:	fce7eae3          	bltu	a5,a4,3a18 <sys_sleep+0x64>
  }
  release(&tickslock);
    3a48:	00012517          	auipc	a0,0x12
    3a4c:	c9c50513          	add	a0,a0,-868 # 156e4 <tickslock>
    3a50:	ffffd097          	auipc	ra,0xffffd
    3a54:	3c8080e7          	jalr	968(ra) # e18 <release>
  return 0;
    3a58:	00000793          	li	a5,0
}
    3a5c:	00078513          	mv	a0,a5
    3a60:	02c12083          	lw	ra,44(sp)
    3a64:	02812403          	lw	s0,40(sp)
    3a68:	02412483          	lw	s1,36(sp)
    3a6c:	02012903          	lw	s2,32(sp)
    3a70:	01c12983          	lw	s3,28(sp)
    3a74:	03010113          	add	sp,sp,48
    3a78:	00008067          	ret
      release(&tickslock);
    3a7c:	00012517          	auipc	a0,0x12
    3a80:	c6850513          	add	a0,a0,-920 # 156e4 <tickslock>
    3a84:	ffffd097          	auipc	ra,0xffffd
    3a88:	394080e7          	jalr	916(ra) # e18 <release>
      return -1;
    3a8c:	fff00793          	li	a5,-1
    3a90:	fcdff06f          	j	3a5c <sys_sleep+0xa8>

00003a94 <sys_kill>:

uint32
sys_kill(void)
{
    3a94:	fe010113          	add	sp,sp,-32
    3a98:	00112e23          	sw	ra,28(sp)
    3a9c:	00812c23          	sw	s0,24(sp)
    3aa0:	02010413          	add	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    3aa4:	fec40593          	add	a1,s0,-20
    3aa8:	00000513          	li	a0,0
    3aac:	00000097          	auipc	ra,0x0
    3ab0:	c58080e7          	jalr	-936(ra) # 3704 <argint>
    3ab4:	00050793          	mv	a5,a0
    return -1;
    3ab8:	fff00513          	li	a0,-1
  if(argint(0, &pid) < 0)
    3abc:	0007c863          	bltz	a5,3acc <sys_kill+0x38>
  return kill(pid);
    3ac0:	fec42503          	lw	a0,-20(s0)
    3ac4:	fffff097          	auipc	ra,0xfffff
    3ac8:	30c080e7          	jalr	780(ra) # 2dd0 <kill>
}
    3acc:	01c12083          	lw	ra,28(sp)
    3ad0:	01812403          	lw	s0,24(sp)
    3ad4:	02010113          	add	sp,sp,32
    3ad8:	00008067          	ret

00003adc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint32
sys_uptime(void)
{
    3adc:	ff010113          	add	sp,sp,-16
    3ae0:	00112623          	sw	ra,12(sp)
    3ae4:	00812423          	sw	s0,8(sp)
    3ae8:	00912223          	sw	s1,4(sp)
    3aec:	01010413          	add	s0,sp,16
  uint xticks;

  acquire(&tickslock);
    3af0:	00012517          	auipc	a0,0x12
    3af4:	bf450513          	add	a0,a0,-1036 # 156e4 <tickslock>
    3af8:	ffffd097          	auipc	ra,0xffffd
    3afc:	2ac080e7          	jalr	684(ra) # da4 <acquire>
  xticks = ticks;
    3b00:	0001d497          	auipc	s1,0x1d
    3b04:	5104a483          	lw	s1,1296(s1) # 21010 <ticks>
  release(&tickslock);
    3b08:	00012517          	auipc	a0,0x12
    3b0c:	bdc50513          	add	a0,a0,-1060 # 156e4 <tickslock>
    3b10:	ffffd097          	auipc	ra,0xffffd
    3b14:	308080e7          	jalr	776(ra) # e18 <release>
  return xticks;
}
    3b18:	00048513          	mv	a0,s1
    3b1c:	00c12083          	lw	ra,12(sp)
    3b20:	00812403          	lw	s0,8(sp)
    3b24:	00412483          	lw	s1,4(sp)
    3b28:	01010113          	add	sp,sp,16
    3b2c:	00008067          	ret

00003b30 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    3b30:	fe010113          	add	sp,sp,-32
    3b34:	00112e23          	sw	ra,28(sp)
    3b38:	00812c23          	sw	s0,24(sp)
    3b3c:	00912a23          	sw	s1,20(sp)
    3b40:	01212823          	sw	s2,16(sp)
    3b44:	01312623          	sw	s3,12(sp)
    3b48:	01412423          	sw	s4,8(sp)
    3b4c:	02010413          	add	s0,sp,32
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    3b50:	00005597          	auipc	a1,0x5
    3b54:	93c58593          	add	a1,a1,-1732 # 848c <userret+0x3ec>
    3b58:	00012517          	auipc	a0,0x12
    3b5c:	b9850513          	add	a0,a0,-1128 # 156f0 <bcache>
    3b60:	ffffd097          	auipc	ra,0xffffd
    3b64:	0c0080e7          	jalr	192(ra) # c20 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    3b68:	0001a797          	auipc	a5,0x1a
    3b6c:	b8878793          	add	a5,a5,-1144 # 1d6f0 <bcache+0x8000>
    3b70:	0001a717          	auipc	a4,0x1a
    3b74:	a1c70713          	add	a4,a4,-1508 # 1d58c <bcache+0x7e9c>
    3b78:	ece7a423          	sw	a4,-312(a5)
  bcache.head.next = &bcache.head;
    3b7c:	ece7a623          	sw	a4,-308(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    3b80:	00012497          	auipc	s1,0x12
    3b84:	b7c48493          	add	s1,s1,-1156 # 156fc <bcache+0xc>
    b->next = bcache.head.next;
    3b88:	00078913          	mv	s2,a5
    b->prev = &bcache.head;
    3b8c:	00070993          	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    3b90:	00005a17          	auipc	s4,0x5
    3b94:	904a0a13          	add	s4,s4,-1788 # 8494 <userret+0x3f4>
    b->next = bcache.head.next;
    3b98:	ecc92783          	lw	a5,-308(s2)
    3b9c:	02f4a823          	sw	a5,48(s1)
    b->prev = &bcache.head;
    3ba0:	0334a623          	sw	s3,44(s1)
    initsleeplock(&b->lock, "buffer");
    3ba4:	000a0593          	mv	a1,s4
    3ba8:	01048513          	add	a0,s1,16
    3bac:	00002097          	auipc	ra,0x2
    3bb0:	b98080e7          	jalr	-1128(ra) # 5744 <initsleeplock>
    bcache.head.next->prev = b;
    3bb4:	ecc92783          	lw	a5,-308(s2)
    3bb8:	0297a623          	sw	s1,44(a5)
    bcache.head.next = b;
    3bbc:	ec992623          	sw	s1,-308(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    3bc0:	43848493          	add	s1,s1,1080
    3bc4:	fd349ae3          	bne	s1,s3,3b98 <binit+0x68>
  }
}
    3bc8:	01c12083          	lw	ra,28(sp)
    3bcc:	01812403          	lw	s0,24(sp)
    3bd0:	01412483          	lw	s1,20(sp)
    3bd4:	01012903          	lw	s2,16(sp)
    3bd8:	00c12983          	lw	s3,12(sp)
    3bdc:	00812a03          	lw	s4,8(sp)
    3be0:	02010113          	add	sp,sp,32
    3be4:	00008067          	ret

00003be8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    3be8:	fe010113          	add	sp,sp,-32
    3bec:	00112e23          	sw	ra,28(sp)
    3bf0:	00812c23          	sw	s0,24(sp)
    3bf4:	00912a23          	sw	s1,20(sp)
    3bf8:	01212823          	sw	s2,16(sp)
    3bfc:	01312623          	sw	s3,12(sp)
    3c00:	02010413          	add	s0,sp,32
    3c04:	00050913          	mv	s2,a0
    3c08:	00058993          	mv	s3,a1
  acquire(&bcache.lock);
    3c0c:	00012517          	auipc	a0,0x12
    3c10:	ae450513          	add	a0,a0,-1308 # 156f0 <bcache>
    3c14:	ffffd097          	auipc	ra,0xffffd
    3c18:	190080e7          	jalr	400(ra) # da4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    3c1c:	0001a497          	auipc	s1,0x1a
    3c20:	9a04a483          	lw	s1,-1632(s1) # 1d5bc <bcache+0x7ecc>
    3c24:	0001a797          	auipc	a5,0x1a
    3c28:	96878793          	add	a5,a5,-1688 # 1d58c <bcache+0x7e9c>
    3c2c:	04f48863          	beq	s1,a5,3c7c <bread+0x94>
    3c30:	00078713          	mv	a4,a5
    3c34:	00c0006f          	j	3c40 <bread+0x58>
    3c38:	0304a483          	lw	s1,48(s1)
    3c3c:	04e48063          	beq	s1,a4,3c7c <bread+0x94>
    if(b->dev == dev && b->blockno == blockno){
    3c40:	0084a783          	lw	a5,8(s1)
    3c44:	fef91ae3          	bne	s2,a5,3c38 <bread+0x50>
    3c48:	00c4a783          	lw	a5,12(s1)
    3c4c:	fef996e3          	bne	s3,a5,3c38 <bread+0x50>
      b->refcnt++;
    3c50:	0284a783          	lw	a5,40(s1)
    3c54:	00178793          	add	a5,a5,1
    3c58:	02f4a423          	sw	a5,40(s1)
      release(&bcache.lock);
    3c5c:	00012517          	auipc	a0,0x12
    3c60:	a9450513          	add	a0,a0,-1388 # 156f0 <bcache>
    3c64:	ffffd097          	auipc	ra,0xffffd
    3c68:	1b4080e7          	jalr	436(ra) # e18 <release>
      acquiresleep(&b->lock);
    3c6c:	01048513          	add	a0,s1,16
    3c70:	00002097          	auipc	ra,0x2
    3c74:	b2c080e7          	jalr	-1236(ra) # 579c <acquiresleep>
      return b;
    3c78:	06c0006f          	j	3ce4 <bread+0xfc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    3c7c:	0001a497          	auipc	s1,0x1a
    3c80:	93c4a483          	lw	s1,-1732(s1) # 1d5b8 <bcache+0x7ec8>
    3c84:	0001a797          	auipc	a5,0x1a
    3c88:	90878793          	add	a5,a5,-1784 # 1d58c <bcache+0x7e9c>
    3c8c:	00f48c63          	beq	s1,a5,3ca4 <bread+0xbc>
    3c90:	00078713          	mv	a4,a5
    if(b->refcnt == 0) {
    3c94:	0284a783          	lw	a5,40(s1)
    3c98:	00078e63          	beqz	a5,3cb4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    3c9c:	02c4a483          	lw	s1,44(s1)
    3ca0:	fee49ae3          	bne	s1,a4,3c94 <bread+0xac>
  panic("bget: no buffers");
    3ca4:	00004517          	auipc	a0,0x4
    3ca8:	7f850513          	add	a0,a0,2040 # 849c <userret+0x3fc>
    3cac:	ffffd097          	auipc	ra,0xffffd
    3cb0:	9e0080e7          	jalr	-1568(ra) # 68c <panic>
      b->dev = dev;
    3cb4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    3cb8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    3cbc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    3cc0:	00100793          	li	a5,1
    3cc4:	02f4a423          	sw	a5,40(s1)
      release(&bcache.lock);
    3cc8:	00012517          	auipc	a0,0x12
    3ccc:	a2850513          	add	a0,a0,-1496 # 156f0 <bcache>
    3cd0:	ffffd097          	auipc	ra,0xffffd
    3cd4:	148080e7          	jalr	328(ra) # e18 <release>
      acquiresleep(&b->lock);
    3cd8:	01048513          	add	a0,s1,16
    3cdc:	00002097          	auipc	ra,0x2
    3ce0:	ac0080e7          	jalr	-1344(ra) # 579c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    3ce4:	0004a783          	lw	a5,0(s1)
    3ce8:	02078263          	beqz	a5,3d0c <bread+0x124>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    3cec:	00048513          	mv	a0,s1
    3cf0:	01c12083          	lw	ra,28(sp)
    3cf4:	01812403          	lw	s0,24(sp)
    3cf8:	01412483          	lw	s1,20(sp)
    3cfc:	01012903          	lw	s2,16(sp)
    3d00:	00c12983          	lw	s3,12(sp)
    3d04:	02010113          	add	sp,sp,32
    3d08:	00008067          	ret
    virtio_disk_rw(b, 0);
    3d0c:	00000593          	li	a1,0
    3d10:	00048513          	mv	a0,s1
    3d14:	00004097          	auipc	ra,0x4
    3d18:	cc0080e7          	jalr	-832(ra) # 79d4 <virtio_disk_rw>
    b->valid = 1;
    3d1c:	00100793          	li	a5,1
    3d20:	00f4a023          	sw	a5,0(s1)
  return b;
    3d24:	fc9ff06f          	j	3cec <bread+0x104>

00003d28 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    3d28:	ff010113          	add	sp,sp,-16
    3d2c:	00112623          	sw	ra,12(sp)
    3d30:	00812423          	sw	s0,8(sp)
    3d34:	00912223          	sw	s1,4(sp)
    3d38:	01010413          	add	s0,sp,16
    3d3c:	00050493          	mv	s1,a0
  if(!holdingsleep(&b->lock))
    3d40:	01050513          	add	a0,a0,16
    3d44:	00002097          	auipc	ra,0x2
    3d48:	b44080e7          	jalr	-1212(ra) # 5888 <holdingsleep>
    3d4c:	02050463          	beqz	a0,3d74 <bwrite+0x4c>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    3d50:	00100593          	li	a1,1
    3d54:	00048513          	mv	a0,s1
    3d58:	00004097          	auipc	ra,0x4
    3d5c:	c7c080e7          	jalr	-900(ra) # 79d4 <virtio_disk_rw>
}
    3d60:	00c12083          	lw	ra,12(sp)
    3d64:	00812403          	lw	s0,8(sp)
    3d68:	00412483          	lw	s1,4(sp)
    3d6c:	01010113          	add	sp,sp,16
    3d70:	00008067          	ret
    panic("bwrite");
    3d74:	00004517          	auipc	a0,0x4
    3d78:	73c50513          	add	a0,a0,1852 # 84b0 <userret+0x410>
    3d7c:	ffffd097          	auipc	ra,0xffffd
    3d80:	910080e7          	jalr	-1776(ra) # 68c <panic>

00003d84 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    3d84:	ff010113          	add	sp,sp,-16
    3d88:	00112623          	sw	ra,12(sp)
    3d8c:	00812423          	sw	s0,8(sp)
    3d90:	00912223          	sw	s1,4(sp)
    3d94:	01212023          	sw	s2,0(sp)
    3d98:	01010413          	add	s0,sp,16
    3d9c:	00050493          	mv	s1,a0
  if(!holdingsleep(&b->lock))
    3da0:	01050913          	add	s2,a0,16
    3da4:	00090513          	mv	a0,s2
    3da8:	00002097          	auipc	ra,0x2
    3dac:	ae0080e7          	jalr	-1312(ra) # 5888 <holdingsleep>
    3db0:	08050a63          	beqz	a0,3e44 <brelse+0xc0>
    panic("brelse");

  releasesleep(&b->lock);
    3db4:	00090513          	mv	a0,s2
    3db8:	00002097          	auipc	ra,0x2
    3dbc:	a6c080e7          	jalr	-1428(ra) # 5824 <releasesleep>

  acquire(&bcache.lock);
    3dc0:	00012517          	auipc	a0,0x12
    3dc4:	93050513          	add	a0,a0,-1744 # 156f0 <bcache>
    3dc8:	ffffd097          	auipc	ra,0xffffd
    3dcc:	fdc080e7          	jalr	-36(ra) # da4 <acquire>
  b->refcnt--;
    3dd0:	0284a783          	lw	a5,40(s1)
    3dd4:	fff78793          	add	a5,a5,-1
    3dd8:	02f4a423          	sw	a5,40(s1)
  if (b->refcnt == 0) {
    3ddc:	04079063          	bnez	a5,3e1c <brelse+0x98>
    // no one is waiting for it.
    b->next->prev = b->prev;
    3de0:	0304a703          	lw	a4,48(s1)
    3de4:	02c4a783          	lw	a5,44(s1)
    3de8:	02f72623          	sw	a5,44(a4)
    b->prev->next = b->next;
    3dec:	0304a703          	lw	a4,48(s1)
    3df0:	02e7a823          	sw	a4,48(a5)
    b->next = bcache.head.next;
    3df4:	0001a797          	auipc	a5,0x1a
    3df8:	8fc78793          	add	a5,a5,-1796 # 1d6f0 <bcache+0x8000>
    3dfc:	ecc7a703          	lw	a4,-308(a5)
    3e00:	02e4a823          	sw	a4,48(s1)
    b->prev = &bcache.head;
    3e04:	00019717          	auipc	a4,0x19
    3e08:	78870713          	add	a4,a4,1928 # 1d58c <bcache+0x7e9c>
    3e0c:	02e4a623          	sw	a4,44(s1)
    bcache.head.next->prev = b;
    3e10:	ecc7a703          	lw	a4,-308(a5)
    3e14:	02972623          	sw	s1,44(a4)
    bcache.head.next = b;
    3e18:	ec97a623          	sw	s1,-308(a5)
  }
  
  release(&bcache.lock);
    3e1c:	00012517          	auipc	a0,0x12
    3e20:	8d450513          	add	a0,a0,-1836 # 156f0 <bcache>
    3e24:	ffffd097          	auipc	ra,0xffffd
    3e28:	ff4080e7          	jalr	-12(ra) # e18 <release>
}
    3e2c:	00c12083          	lw	ra,12(sp)
    3e30:	00812403          	lw	s0,8(sp)
    3e34:	00412483          	lw	s1,4(sp)
    3e38:	00012903          	lw	s2,0(sp)
    3e3c:	01010113          	add	sp,sp,16
    3e40:	00008067          	ret
    panic("brelse");
    3e44:	00004517          	auipc	a0,0x4
    3e48:	67450513          	add	a0,a0,1652 # 84b8 <userret+0x418>
    3e4c:	ffffd097          	auipc	ra,0xffffd
    3e50:	840080e7          	jalr	-1984(ra) # 68c <panic>

00003e54 <bpin>:

void
bpin(struct buf *b) {
    3e54:	ff010113          	add	sp,sp,-16
    3e58:	00112623          	sw	ra,12(sp)
    3e5c:	00812423          	sw	s0,8(sp)
    3e60:	00912223          	sw	s1,4(sp)
    3e64:	01010413          	add	s0,sp,16
    3e68:	00050493          	mv	s1,a0
  acquire(&bcache.lock);
    3e6c:	00012517          	auipc	a0,0x12
    3e70:	88450513          	add	a0,a0,-1916 # 156f0 <bcache>
    3e74:	ffffd097          	auipc	ra,0xffffd
    3e78:	f30080e7          	jalr	-208(ra) # da4 <acquire>
  b->refcnt++;
    3e7c:	0284a783          	lw	a5,40(s1)
    3e80:	00178793          	add	a5,a5,1
    3e84:	02f4a423          	sw	a5,40(s1)
  release(&bcache.lock);
    3e88:	00012517          	auipc	a0,0x12
    3e8c:	86850513          	add	a0,a0,-1944 # 156f0 <bcache>
    3e90:	ffffd097          	auipc	ra,0xffffd
    3e94:	f88080e7          	jalr	-120(ra) # e18 <release>
}
    3e98:	00c12083          	lw	ra,12(sp)
    3e9c:	00812403          	lw	s0,8(sp)
    3ea0:	00412483          	lw	s1,4(sp)
    3ea4:	01010113          	add	sp,sp,16
    3ea8:	00008067          	ret

00003eac <bunpin>:

void
bunpin(struct buf *b) {
    3eac:	ff010113          	add	sp,sp,-16
    3eb0:	00112623          	sw	ra,12(sp)
    3eb4:	00812423          	sw	s0,8(sp)
    3eb8:	00912223          	sw	s1,4(sp)
    3ebc:	01010413          	add	s0,sp,16
    3ec0:	00050493          	mv	s1,a0
  acquire(&bcache.lock);
    3ec4:	00012517          	auipc	a0,0x12
    3ec8:	82c50513          	add	a0,a0,-2004 # 156f0 <bcache>
    3ecc:	ffffd097          	auipc	ra,0xffffd
    3ed0:	ed8080e7          	jalr	-296(ra) # da4 <acquire>
  b->refcnt--;
    3ed4:	0284a783          	lw	a5,40(s1)
    3ed8:	fff78793          	add	a5,a5,-1
    3edc:	02f4a423          	sw	a5,40(s1)
  release(&bcache.lock);
    3ee0:	00012517          	auipc	a0,0x12
    3ee4:	81050513          	add	a0,a0,-2032 # 156f0 <bcache>
    3ee8:	ffffd097          	auipc	ra,0xffffd
    3eec:	f30080e7          	jalr	-208(ra) # e18 <release>
}
    3ef0:	00c12083          	lw	ra,12(sp)
    3ef4:	00812403          	lw	s0,8(sp)
    3ef8:	00412483          	lw	s1,4(sp)
    3efc:	01010113          	add	sp,sp,16
    3f00:	00008067          	ret

00003f04 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    3f04:	ff010113          	add	sp,sp,-16
    3f08:	00112623          	sw	ra,12(sp)
    3f0c:	00812423          	sw	s0,8(sp)
    3f10:	00912223          	sw	s1,4(sp)
    3f14:	01212023          	sw	s2,0(sp)
    3f18:	01010413          	add	s0,sp,16
    3f1c:	00058493          	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    3f20:	00d5d593          	srl	a1,a1,0xd
    3f24:	0001a797          	auipc	a5,0x1a
    3f28:	abc7a783          	lw	a5,-1348(a5) # 1d9e0 <sb+0x1c>
    3f2c:	00f585b3          	add	a1,a1,a5
    3f30:	00000097          	auipc	ra,0x0
    3f34:	cb8080e7          	jalr	-840(ra) # 3be8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    3f38:	0074f713          	and	a4,s1,7
    3f3c:	00100793          	li	a5,1
    3f40:	00e797b3          	sll	a5,a5,a4
  bi = b % BPB;
    3f44:	01349493          	sll	s1,s1,0x13
  if((bp->data[bi/8] & m) == 0)
    3f48:	0164d493          	srl	s1,s1,0x16
    3f4c:	00950733          	add	a4,a0,s1
    3f50:	03874703          	lbu	a4,56(a4)
    3f54:	00f776b3          	and	a3,a4,a5
    3f58:	04068263          	beqz	a3,3f9c <bfree+0x98>
    3f5c:	00050913          	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    3f60:	009504b3          	add	s1,a0,s1
    3f64:	fff7c793          	not	a5,a5
    3f68:	00f77733          	and	a4,a4,a5
    3f6c:	02e48c23          	sb	a4,56(s1)
  log_write(bp);
    3f70:	00001097          	auipc	ra,0x1
    3f74:	6a0080e7          	jalr	1696(ra) # 5610 <log_write>
  brelse(bp);
    3f78:	00090513          	mv	a0,s2
    3f7c:	00000097          	auipc	ra,0x0
    3f80:	e08080e7          	jalr	-504(ra) # 3d84 <brelse>
}
    3f84:	00c12083          	lw	ra,12(sp)
    3f88:	00812403          	lw	s0,8(sp)
    3f8c:	00412483          	lw	s1,4(sp)
    3f90:	00012903          	lw	s2,0(sp)
    3f94:	01010113          	add	sp,sp,16
    3f98:	00008067          	ret
    panic("freeing free block");
    3f9c:	00004517          	auipc	a0,0x4
    3fa0:	52450513          	add	a0,a0,1316 # 84c0 <userret+0x420>
    3fa4:	ffffc097          	auipc	ra,0xffffc
    3fa8:	6e8080e7          	jalr	1768(ra) # 68c <panic>

00003fac <balloc>:
{
    3fac:	fd010113          	add	sp,sp,-48
    3fb0:	02112623          	sw	ra,44(sp)
    3fb4:	02812423          	sw	s0,40(sp)
    3fb8:	02912223          	sw	s1,36(sp)
    3fbc:	03212023          	sw	s2,32(sp)
    3fc0:	01312e23          	sw	s3,28(sp)
    3fc4:	01412c23          	sw	s4,24(sp)
    3fc8:	01512a23          	sw	s5,20(sp)
    3fcc:	01612823          	sw	s6,16(sp)
    3fd0:	01712623          	sw	s7,12(sp)
    3fd4:	01812423          	sw	s8,8(sp)
    3fd8:	03010413          	add	s0,sp,48
  for(b = 0; b < sb.size; b += BPB){
    3fdc:	0001a797          	auipc	a5,0x1a
    3fe0:	9ec7a783          	lw	a5,-1556(a5) # 1d9c8 <sb+0x4>
    3fe4:	0a078663          	beqz	a5,4090 <balloc+0xe4>
    3fe8:	00050b93          	mv	s7,a0
    3fec:	00000a93          	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    3ff0:	000029b7          	lui	s3,0x2
    3ff4:	fff98c13          	add	s8,s3,-1 # 1fff <procinit+0x87>
    3ff8:	0001ab17          	auipc	s6,0x1a
    3ffc:	9ccb0b13          	add	s6,s6,-1588 # 1d9c4 <sb>
      m = 1 << (bi % 8);
    4000:	00100a13          	li	s4,1
    4004:	01c0006f          	j	4020 <balloc+0x74>
    brelse(bp);
    4008:	00090513          	mv	a0,s2
    400c:	00000097          	auipc	ra,0x0
    4010:	d78080e7          	jalr	-648(ra) # 3d84 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    4014:	013a8ab3          	add	s5,s5,s3
    4018:	004b2783          	lw	a5,4(s6)
    401c:	06fafa63          	bgeu	s5,a5,4090 <balloc+0xe4>
    bp = bread(dev, BBLOCK(b, sb));
    4020:	41fad793          	sra	a5,s5,0x1f
    4024:	0187f7b3          	and	a5,a5,s8
    4028:	015787b3          	add	a5,a5,s5
    402c:	40d7d793          	sra	a5,a5,0xd
    4030:	01cb2583          	lw	a1,28(s6)
    4034:	00b785b3          	add	a1,a5,a1
    4038:	000b8513          	mv	a0,s7
    403c:	00000097          	auipc	ra,0x0
    4040:	bac080e7          	jalr	-1108(ra) # 3be8 <bread>
    4044:	00050913          	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    4048:	004b2503          	lw	a0,4(s6)
    404c:	000a8493          	mv	s1,s5
    4050:	00000713          	li	a4,0
    4054:	faa4fae3          	bgeu	s1,a0,4008 <balloc+0x5c>
      m = 1 << (bi % 8);
    4058:	00777693          	and	a3,a4,7
    405c:	00da16b3          	sll	a3,s4,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    4060:	41f75793          	sra	a5,a4,0x1f
    4064:	0077f793          	and	a5,a5,7
    4068:	00e787b3          	add	a5,a5,a4
    406c:	4037d793          	sra	a5,a5,0x3
    4070:	00f90633          	add	a2,s2,a5
    4074:	03864603          	lbu	a2,56(a2)
    4078:	00d675b3          	and	a1,a2,a3
    407c:	02058263          	beqz	a1,40a0 <balloc+0xf4>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    4080:	00170713          	add	a4,a4,1
    4084:	00148493          	add	s1,s1,1
    4088:	fd3716e3          	bne	a4,s3,4054 <balloc+0xa8>
    408c:	f7dff06f          	j	4008 <balloc+0x5c>
  panic("balloc: out of blocks");
    4090:	00004517          	auipc	a0,0x4
    4094:	44450513          	add	a0,a0,1092 # 84d4 <userret+0x434>
    4098:	ffffc097          	auipc	ra,0xffffc
    409c:	5f4080e7          	jalr	1524(ra) # 68c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    40a0:	00f907b3          	add	a5,s2,a5
    40a4:	00d66633          	or	a2,a2,a3
    40a8:	02c78c23          	sb	a2,56(a5)
        log_write(bp);
    40ac:	00090513          	mv	a0,s2
    40b0:	00001097          	auipc	ra,0x1
    40b4:	560080e7          	jalr	1376(ra) # 5610 <log_write>
        brelse(bp);
    40b8:	00090513          	mv	a0,s2
    40bc:	00000097          	auipc	ra,0x0
    40c0:	cc8080e7          	jalr	-824(ra) # 3d84 <brelse>
  bp = bread(dev, bno);
    40c4:	00048593          	mv	a1,s1
    40c8:	000b8513          	mv	a0,s7
    40cc:	00000097          	auipc	ra,0x0
    40d0:	b1c080e7          	jalr	-1252(ra) # 3be8 <bread>
    40d4:	00050913          	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    40d8:	40000613          	li	a2,1024
    40dc:	00000593          	li	a1,0
    40e0:	03850513          	add	a0,a0,56
    40e4:	ffffd097          	auipc	ra,0xffffd
    40e8:	d94080e7          	jalr	-620(ra) # e78 <memset>
  log_write(bp);
    40ec:	00090513          	mv	a0,s2
    40f0:	00001097          	auipc	ra,0x1
    40f4:	520080e7          	jalr	1312(ra) # 5610 <log_write>
  brelse(bp);
    40f8:	00090513          	mv	a0,s2
    40fc:	00000097          	auipc	ra,0x0
    4100:	c88080e7          	jalr	-888(ra) # 3d84 <brelse>
}
    4104:	00048513          	mv	a0,s1
    4108:	02c12083          	lw	ra,44(sp)
    410c:	02812403          	lw	s0,40(sp)
    4110:	02412483          	lw	s1,36(sp)
    4114:	02012903          	lw	s2,32(sp)
    4118:	01c12983          	lw	s3,28(sp)
    411c:	01812a03          	lw	s4,24(sp)
    4120:	01412a83          	lw	s5,20(sp)
    4124:	01012b03          	lw	s6,16(sp)
    4128:	00c12b83          	lw	s7,12(sp)
    412c:	00812c03          	lw	s8,8(sp)
    4130:	03010113          	add	sp,sp,48
    4134:	00008067          	ret

00004138 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    4138:	fe010113          	add	sp,sp,-32
    413c:	00112e23          	sw	ra,28(sp)
    4140:	00812c23          	sw	s0,24(sp)
    4144:	00912a23          	sw	s1,20(sp)
    4148:	01212823          	sw	s2,16(sp)
    414c:	01312623          	sw	s3,12(sp)
    4150:	01412423          	sw	s4,8(sp)
    4154:	02010413          	add	s0,sp,32
    4158:	00050913          	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    415c:	00b00793          	li	a5,11
    4160:	06b7f663          	bgeu	a5,a1,41cc <bmap+0x94>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    4164:	ff458493          	add	s1,a1,-12

  if(bn < NINDIRECT){
    4168:	0ff00793          	li	a5,255
    416c:	0c97e263          	bltu	a5,s1,4230 <bmap+0xf8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    4170:	06452583          	lw	a1,100(a0)
    4174:	08058063          	beqz	a1,41f4 <bmap+0xbc>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    4178:	00092503          	lw	a0,0(s2)
    417c:	00000097          	auipc	ra,0x0
    4180:	a6c080e7          	jalr	-1428(ra) # 3be8 <bread>
    4184:	00050a13          	mv	s4,a0
    a = (uint*)bp->data;
    4188:	03850793          	add	a5,a0,56
    if((addr = a[bn]) == 0){
    418c:	00249593          	sll	a1,s1,0x2
    4190:	00b784b3          	add	s1,a5,a1
    4194:	0004a983          	lw	s3,0(s1)
    4198:	06098a63          	beqz	s3,420c <bmap+0xd4>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    419c:	000a0513          	mv	a0,s4
    41a0:	00000097          	auipc	ra,0x0
    41a4:	be4080e7          	jalr	-1052(ra) # 3d84 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    41a8:	00098513          	mv	a0,s3
    41ac:	01c12083          	lw	ra,28(sp)
    41b0:	01812403          	lw	s0,24(sp)
    41b4:	01412483          	lw	s1,20(sp)
    41b8:	01012903          	lw	s2,16(sp)
    41bc:	00c12983          	lw	s3,12(sp)
    41c0:	00812a03          	lw	s4,8(sp)
    41c4:	02010113          	add	sp,sp,32
    41c8:	00008067          	ret
    if((addr = ip->addrs[bn]) == 0)
    41cc:	00259593          	sll	a1,a1,0x2
    41d0:	00b504b3          	add	s1,a0,a1
    41d4:	0344a983          	lw	s3,52(s1)
    41d8:	fc0998e3          	bnez	s3,41a8 <bmap+0x70>
      ip->addrs[bn] = addr = balloc(ip->dev);
    41dc:	00052503          	lw	a0,0(a0)
    41e0:	00000097          	auipc	ra,0x0
    41e4:	dcc080e7          	jalr	-564(ra) # 3fac <balloc>
    41e8:	00050993          	mv	s3,a0
    41ec:	02a4aa23          	sw	a0,52(s1)
    41f0:	fb9ff06f          	j	41a8 <bmap+0x70>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    41f4:	00052503          	lw	a0,0(a0)
    41f8:	00000097          	auipc	ra,0x0
    41fc:	db4080e7          	jalr	-588(ra) # 3fac <balloc>
    4200:	00050593          	mv	a1,a0
    4204:	06a92223          	sw	a0,100(s2)
    4208:	f71ff06f          	j	4178 <bmap+0x40>
      a[bn] = addr = balloc(ip->dev);
    420c:	00092503          	lw	a0,0(s2)
    4210:	00000097          	auipc	ra,0x0
    4214:	d9c080e7          	jalr	-612(ra) # 3fac <balloc>
    4218:	00050993          	mv	s3,a0
    421c:	00a4a023          	sw	a0,0(s1)
      log_write(bp);
    4220:	000a0513          	mv	a0,s4
    4224:	00001097          	auipc	ra,0x1
    4228:	3ec080e7          	jalr	1004(ra) # 5610 <log_write>
    422c:	f71ff06f          	j	419c <bmap+0x64>
  panic("bmap: out of range");
    4230:	00004517          	auipc	a0,0x4
    4234:	2bc50513          	add	a0,a0,700 # 84ec <userret+0x44c>
    4238:	ffffc097          	auipc	ra,0xffffc
    423c:	454080e7          	jalr	1108(ra) # 68c <panic>

00004240 <iget>:
{
    4240:	fe010113          	add	sp,sp,-32
    4244:	00112e23          	sw	ra,28(sp)
    4248:	00812c23          	sw	s0,24(sp)
    424c:	00912a23          	sw	s1,20(sp)
    4250:	01212823          	sw	s2,16(sp)
    4254:	01312623          	sw	s3,12(sp)
    4258:	01412423          	sw	s4,8(sp)
    425c:	02010413          	add	s0,sp,32
    4260:	00050993          	mv	s3,a0
    4264:	00058a13          	mv	s4,a1
  acquire(&icache.lock);
    4268:	00019517          	auipc	a0,0x19
    426c:	77c50513          	add	a0,a0,1916 # 1d9e4 <icache>
    4270:	ffffd097          	auipc	ra,0xffffd
    4274:	b34080e7          	jalr	-1228(ra) # da4 <acquire>
  empty = 0;
    4278:	00000913          	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    427c:	00019497          	auipc	s1,0x19
    4280:	77448493          	add	s1,s1,1908 # 1d9f0 <icache+0xc>
    4284:	0001b697          	auipc	a3,0x1b
    4288:	bbc68693          	add	a3,a3,-1092 # 1ee40 <log>
    428c:	0100006f          	j	429c <iget+0x5c>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    4290:	04090263          	beqz	s2,42d4 <iget+0x94>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    4294:	06848493          	add	s1,s1,104
    4298:	04d48463          	beq	s1,a3,42e0 <iget+0xa0>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    429c:	0084a783          	lw	a5,8(s1)
    42a0:	fef058e3          	blez	a5,4290 <iget+0x50>
    42a4:	0004a703          	lw	a4,0(s1)
    42a8:	ff3714e3          	bne	a4,s3,4290 <iget+0x50>
    42ac:	0044a703          	lw	a4,4(s1)
    42b0:	ff4710e3          	bne	a4,s4,4290 <iget+0x50>
      ip->ref++;
    42b4:	00178793          	add	a5,a5,1
    42b8:	00f4a423          	sw	a5,8(s1)
      release(&icache.lock);
    42bc:	00019517          	auipc	a0,0x19
    42c0:	72850513          	add	a0,a0,1832 # 1d9e4 <icache>
    42c4:	ffffd097          	auipc	ra,0xffffd
    42c8:	b54080e7          	jalr	-1196(ra) # e18 <release>
      return ip;
    42cc:	00048913          	mv	s2,s1
    42d0:	0380006f          	j	4308 <iget+0xc8>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    42d4:	fc0790e3          	bnez	a5,4294 <iget+0x54>
    42d8:	00048913          	mv	s2,s1
    42dc:	fb9ff06f          	j	4294 <iget+0x54>
  if(empty == 0)
    42e0:	04090663          	beqz	s2,432c <iget+0xec>
  ip->dev = dev;
    42e4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    42e8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    42ec:	00100793          	li	a5,1
    42f0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    42f4:	02092223          	sw	zero,36(s2)
  release(&icache.lock);
    42f8:	00019517          	auipc	a0,0x19
    42fc:	6ec50513          	add	a0,a0,1772 # 1d9e4 <icache>
    4300:	ffffd097          	auipc	ra,0xffffd
    4304:	b18080e7          	jalr	-1256(ra) # e18 <release>
}
    4308:	00090513          	mv	a0,s2
    430c:	01c12083          	lw	ra,28(sp)
    4310:	01812403          	lw	s0,24(sp)
    4314:	01412483          	lw	s1,20(sp)
    4318:	01012903          	lw	s2,16(sp)
    431c:	00c12983          	lw	s3,12(sp)
    4320:	00812a03          	lw	s4,8(sp)
    4324:	02010113          	add	sp,sp,32
    4328:	00008067          	ret
    panic("iget: no inodes");
    432c:	00004517          	auipc	a0,0x4
    4330:	1d450513          	add	a0,a0,468 # 8500 <userret+0x460>
    4334:	ffffc097          	auipc	ra,0xffffc
    4338:	358080e7          	jalr	856(ra) # 68c <panic>

0000433c <fsinit>:
fsinit(int dev) {
    433c:	fe010113          	add	sp,sp,-32
    4340:	00112e23          	sw	ra,28(sp)
    4344:	00812c23          	sw	s0,24(sp)
    4348:	00912a23          	sw	s1,20(sp)
    434c:	01212823          	sw	s2,16(sp)
    4350:	01312623          	sw	s3,12(sp)
    4354:	02010413          	add	s0,sp,32
    4358:	00050913          	mv	s2,a0
  bp = bread(dev, 1);
    435c:	00100593          	li	a1,1
    4360:	00000097          	auipc	ra,0x0
    4364:	888080e7          	jalr	-1912(ra) # 3be8 <bread>
    4368:	00050493          	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    436c:	00019997          	auipc	s3,0x19
    4370:	65898993          	add	s3,s3,1624 # 1d9c4 <sb>
    4374:	02000613          	li	a2,32
    4378:	03850593          	add	a1,a0,56
    437c:	00098513          	mv	a0,s3
    4380:	ffffd097          	auipc	ra,0xffffd
    4384:	b74080e7          	jalr	-1164(ra) # ef4 <memmove>
  brelse(bp);
    4388:	00048513          	mv	a0,s1
    438c:	00000097          	auipc	ra,0x0
    4390:	9f8080e7          	jalr	-1544(ra) # 3d84 <brelse>
  if(sb.magic != FSMAGIC)
    4394:	0009a703          	lw	a4,0(s3)
    4398:	102037b7          	lui	a5,0x10203
    439c:	04078793          	add	a5,a5,64 # 10203040 <end+0x101e202c>
    43a0:	02f71a63          	bne	a4,a5,43d4 <fsinit+0x98>
  initlog(dev, &sb);
    43a4:	00019597          	auipc	a1,0x19
    43a8:	62058593          	add	a1,a1,1568 # 1d9c4 <sb>
    43ac:	00090513          	mv	a0,s2
    43b0:	00001097          	auipc	ra,0x1
    43b4:	f38080e7          	jalr	-200(ra) # 52e8 <initlog>
}
    43b8:	01c12083          	lw	ra,28(sp)
    43bc:	01812403          	lw	s0,24(sp)
    43c0:	01412483          	lw	s1,20(sp)
    43c4:	01012903          	lw	s2,16(sp)
    43c8:	00c12983          	lw	s3,12(sp)
    43cc:	02010113          	add	sp,sp,32
    43d0:	00008067          	ret
    panic("invalid file system");
    43d4:	00004517          	auipc	a0,0x4
    43d8:	13c50513          	add	a0,a0,316 # 8510 <userret+0x470>
    43dc:	ffffc097          	auipc	ra,0xffffc
    43e0:	2b0080e7          	jalr	688(ra) # 68c <panic>

000043e4 <iinit>:
{
    43e4:	fe010113          	add	sp,sp,-32
    43e8:	00112e23          	sw	ra,28(sp)
    43ec:	00812c23          	sw	s0,24(sp)
    43f0:	00912a23          	sw	s1,20(sp)
    43f4:	01212823          	sw	s2,16(sp)
    43f8:	01312623          	sw	s3,12(sp)
    43fc:	02010413          	add	s0,sp,32
  initlock(&icache.lock, "icache");
    4400:	00004597          	auipc	a1,0x4
    4404:	12458593          	add	a1,a1,292 # 8524 <userret+0x484>
    4408:	00019517          	auipc	a0,0x19
    440c:	5dc50513          	add	a0,a0,1500 # 1d9e4 <icache>
    4410:	ffffd097          	auipc	ra,0xffffd
    4414:	810080e7          	jalr	-2032(ra) # c20 <initlock>
  for(i = 0; i < NINODE; i++) {
    4418:	00019497          	auipc	s1,0x19
    441c:	5e448493          	add	s1,s1,1508 # 1d9fc <icache+0x18>
    4420:	0001b997          	auipc	s3,0x1b
    4424:	a2c98993          	add	s3,s3,-1492 # 1ee4c <log+0xc>
    initsleeplock(&icache.inode[i].lock, "inode");
    4428:	00004917          	auipc	s2,0x4
    442c:	10490913          	add	s2,s2,260 # 852c <userret+0x48c>
    4430:	00090593          	mv	a1,s2
    4434:	00048513          	mv	a0,s1
    4438:	00001097          	auipc	ra,0x1
    443c:	30c080e7          	jalr	780(ra) # 5744 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    4440:	06848493          	add	s1,s1,104
    4444:	ff3496e3          	bne	s1,s3,4430 <iinit+0x4c>
}
    4448:	01c12083          	lw	ra,28(sp)
    444c:	01812403          	lw	s0,24(sp)
    4450:	01412483          	lw	s1,20(sp)
    4454:	01012903          	lw	s2,16(sp)
    4458:	00c12983          	lw	s3,12(sp)
    445c:	02010113          	add	sp,sp,32
    4460:	00008067          	ret

00004464 <ialloc>:
{
    4464:	fe010113          	add	sp,sp,-32
    4468:	00112e23          	sw	ra,28(sp)
    446c:	00812c23          	sw	s0,24(sp)
    4470:	00912a23          	sw	s1,20(sp)
    4474:	01212823          	sw	s2,16(sp)
    4478:	01312623          	sw	s3,12(sp)
    447c:	01412423          	sw	s4,8(sp)
    4480:	01512223          	sw	s5,4(sp)
    4484:	01612023          	sw	s6,0(sp)
    4488:	02010413          	add	s0,sp,32
  for(inum = 1; inum < sb.ninodes; inum++){
    448c:	00019717          	auipc	a4,0x19
    4490:	54472703          	lw	a4,1348(a4) # 1d9d0 <sb+0xc>
    4494:	00100793          	li	a5,1
    4498:	06e7f063          	bgeu	a5,a4,44f8 <ialloc+0x94>
    449c:	00050a93          	mv	s5,a0
    44a0:	00058b13          	mv	s6,a1
    44a4:	00100913          	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    44a8:	00019a17          	auipc	s4,0x19
    44ac:	51ca0a13          	add	s4,s4,1308 # 1d9c4 <sb>
    44b0:	00495593          	srl	a1,s2,0x4
    44b4:	018a2783          	lw	a5,24(s4)
    44b8:	00f585b3          	add	a1,a1,a5
    44bc:	000a8513          	mv	a0,s5
    44c0:	fffff097          	auipc	ra,0xfffff
    44c4:	728080e7          	jalr	1832(ra) # 3be8 <bread>
    44c8:	00050493          	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    44cc:	03850993          	add	s3,a0,56
    44d0:	00f97793          	and	a5,s2,15
    44d4:	00679793          	sll	a5,a5,0x6
    44d8:	00f989b3          	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    44dc:	00099783          	lh	a5,0(s3)
    44e0:	02078463          	beqz	a5,4508 <ialloc+0xa4>
    brelse(bp);
    44e4:	00000097          	auipc	ra,0x0
    44e8:	8a0080e7          	jalr	-1888(ra) # 3d84 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    44ec:	00190913          	add	s2,s2,1
    44f0:	00ca2783          	lw	a5,12(s4)
    44f4:	faf96ee3          	bltu	s2,a5,44b0 <ialloc+0x4c>
  panic("ialloc: no inodes");
    44f8:	00004517          	auipc	a0,0x4
    44fc:	03c50513          	add	a0,a0,60 # 8534 <userret+0x494>
    4500:	ffffc097          	auipc	ra,0xffffc
    4504:	18c080e7          	jalr	396(ra) # 68c <panic>
      memset(dip, 0, sizeof(*dip));
    4508:	04000613          	li	a2,64
    450c:	00000593          	li	a1,0
    4510:	00098513          	mv	a0,s3
    4514:	ffffd097          	auipc	ra,0xffffd
    4518:	964080e7          	jalr	-1692(ra) # e78 <memset>
      dip->type = type;
    451c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    4520:	00048513          	mv	a0,s1
    4524:	00001097          	auipc	ra,0x1
    4528:	0ec080e7          	jalr	236(ra) # 5610 <log_write>
      brelse(bp);
    452c:	00048513          	mv	a0,s1
    4530:	00000097          	auipc	ra,0x0
    4534:	854080e7          	jalr	-1964(ra) # 3d84 <brelse>
      return iget(dev, inum);
    4538:	00090593          	mv	a1,s2
    453c:	000a8513          	mv	a0,s5
    4540:	00000097          	auipc	ra,0x0
    4544:	d00080e7          	jalr	-768(ra) # 4240 <iget>
}
    4548:	01c12083          	lw	ra,28(sp)
    454c:	01812403          	lw	s0,24(sp)
    4550:	01412483          	lw	s1,20(sp)
    4554:	01012903          	lw	s2,16(sp)
    4558:	00c12983          	lw	s3,12(sp)
    455c:	00812a03          	lw	s4,8(sp)
    4560:	00412a83          	lw	s5,4(sp)
    4564:	00012b03          	lw	s6,0(sp)
    4568:	02010113          	add	sp,sp,32
    456c:	00008067          	ret

00004570 <iupdate>:
{
    4570:	ff010113          	add	sp,sp,-16
    4574:	00112623          	sw	ra,12(sp)
    4578:	00812423          	sw	s0,8(sp)
    457c:	00912223          	sw	s1,4(sp)
    4580:	01212023          	sw	s2,0(sp)
    4584:	01010413          	add	s0,sp,16
    4588:	00050493          	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    458c:	00452783          	lw	a5,4(a0)
    4590:	0047d793          	srl	a5,a5,0x4
    4594:	00019597          	auipc	a1,0x19
    4598:	4485a583          	lw	a1,1096(a1) # 1d9dc <sb+0x18>
    459c:	00b785b3          	add	a1,a5,a1
    45a0:	00052503          	lw	a0,0(a0)
    45a4:	fffff097          	auipc	ra,0xfffff
    45a8:	644080e7          	jalr	1604(ra) # 3be8 <bread>
    45ac:	00050913          	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    45b0:	03850793          	add	a5,a0,56
    45b4:	0044a703          	lw	a4,4(s1)
    45b8:	00f77713          	and	a4,a4,15
    45bc:	00671713          	sll	a4,a4,0x6
    45c0:	00e787b3          	add	a5,a5,a4
  dip->type = ip->type;
    45c4:	02849703          	lh	a4,40(s1)
    45c8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    45cc:	02a49703          	lh	a4,42(s1)
    45d0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    45d4:	02c49703          	lh	a4,44(s1)
    45d8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    45dc:	02e49703          	lh	a4,46(s1)
    45e0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    45e4:	0304a703          	lw	a4,48(s1)
    45e8:	00e7a423          	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    45ec:	03400613          	li	a2,52
    45f0:	03448593          	add	a1,s1,52
    45f4:	00c78513          	add	a0,a5,12
    45f8:	ffffd097          	auipc	ra,0xffffd
    45fc:	8fc080e7          	jalr	-1796(ra) # ef4 <memmove>
  log_write(bp);
    4600:	00090513          	mv	a0,s2
    4604:	00001097          	auipc	ra,0x1
    4608:	00c080e7          	jalr	12(ra) # 5610 <log_write>
  brelse(bp);
    460c:	00090513          	mv	a0,s2
    4610:	fffff097          	auipc	ra,0xfffff
    4614:	774080e7          	jalr	1908(ra) # 3d84 <brelse>
}
    4618:	00c12083          	lw	ra,12(sp)
    461c:	00812403          	lw	s0,8(sp)
    4620:	00412483          	lw	s1,4(sp)
    4624:	00012903          	lw	s2,0(sp)
    4628:	01010113          	add	sp,sp,16
    462c:	00008067          	ret

00004630 <idup>:
{
    4630:	ff010113          	add	sp,sp,-16
    4634:	00112623          	sw	ra,12(sp)
    4638:	00812423          	sw	s0,8(sp)
    463c:	00912223          	sw	s1,4(sp)
    4640:	01010413          	add	s0,sp,16
    4644:	00050493          	mv	s1,a0
  acquire(&icache.lock);
    4648:	00019517          	auipc	a0,0x19
    464c:	39c50513          	add	a0,a0,924 # 1d9e4 <icache>
    4650:	ffffc097          	auipc	ra,0xffffc
    4654:	754080e7          	jalr	1876(ra) # da4 <acquire>
  ip->ref++;
    4658:	0084a783          	lw	a5,8(s1)
    465c:	00178793          	add	a5,a5,1
    4660:	00f4a423          	sw	a5,8(s1)
  release(&icache.lock);
    4664:	00019517          	auipc	a0,0x19
    4668:	38050513          	add	a0,a0,896 # 1d9e4 <icache>
    466c:	ffffc097          	auipc	ra,0xffffc
    4670:	7ac080e7          	jalr	1964(ra) # e18 <release>
}
    4674:	00048513          	mv	a0,s1
    4678:	00c12083          	lw	ra,12(sp)
    467c:	00812403          	lw	s0,8(sp)
    4680:	00412483          	lw	s1,4(sp)
    4684:	01010113          	add	sp,sp,16
    4688:	00008067          	ret

0000468c <ilock>:
{
    468c:	ff010113          	add	sp,sp,-16
    4690:	00112623          	sw	ra,12(sp)
    4694:	00812423          	sw	s0,8(sp)
    4698:	00912223          	sw	s1,4(sp)
    469c:	01212023          	sw	s2,0(sp)
    46a0:	01010413          	add	s0,sp,16
  if(ip == 0 || ip->ref < 1)
    46a4:	02050e63          	beqz	a0,46e0 <ilock+0x54>
    46a8:	00050493          	mv	s1,a0
    46ac:	00852783          	lw	a5,8(a0)
    46b0:	02f05863          	blez	a5,46e0 <ilock+0x54>
  acquiresleep(&ip->lock);
    46b4:	00c50513          	add	a0,a0,12
    46b8:	00001097          	auipc	ra,0x1
    46bc:	0e4080e7          	jalr	228(ra) # 579c <acquiresleep>
  if(ip->valid == 0){
    46c0:	0244a783          	lw	a5,36(s1)
    46c4:	02078663          	beqz	a5,46f0 <ilock+0x64>
}
    46c8:	00c12083          	lw	ra,12(sp)
    46cc:	00812403          	lw	s0,8(sp)
    46d0:	00412483          	lw	s1,4(sp)
    46d4:	00012903          	lw	s2,0(sp)
    46d8:	01010113          	add	sp,sp,16
    46dc:	00008067          	ret
    panic("ilock");
    46e0:	00004517          	auipc	a0,0x4
    46e4:	e6850513          	add	a0,a0,-408 # 8548 <userret+0x4a8>
    46e8:	ffffc097          	auipc	ra,0xffffc
    46ec:	fa4080e7          	jalr	-92(ra) # 68c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    46f0:	0044a783          	lw	a5,4(s1)
    46f4:	0047d793          	srl	a5,a5,0x4
    46f8:	00019597          	auipc	a1,0x19
    46fc:	2e45a583          	lw	a1,740(a1) # 1d9dc <sb+0x18>
    4700:	00b785b3          	add	a1,a5,a1
    4704:	0004a503          	lw	a0,0(s1)
    4708:	fffff097          	auipc	ra,0xfffff
    470c:	4e0080e7          	jalr	1248(ra) # 3be8 <bread>
    4710:	00050913          	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    4714:	03850593          	add	a1,a0,56
    4718:	0044a783          	lw	a5,4(s1)
    471c:	00f7f793          	and	a5,a5,15
    4720:	00679793          	sll	a5,a5,0x6
    4724:	00f585b3          	add	a1,a1,a5
    ip->type = dip->type;
    4728:	00059783          	lh	a5,0(a1)
    472c:	02f49423          	sh	a5,40(s1)
    ip->major = dip->major;
    4730:	00259783          	lh	a5,2(a1)
    4734:	02f49523          	sh	a5,42(s1)
    ip->minor = dip->minor;
    4738:	00459783          	lh	a5,4(a1)
    473c:	02f49623          	sh	a5,44(s1)
    ip->nlink = dip->nlink;
    4740:	00659783          	lh	a5,6(a1)
    4744:	02f49723          	sh	a5,46(s1)
    ip->size = dip->size;
    4748:	0085a783          	lw	a5,8(a1)
    474c:	02f4a823          	sw	a5,48(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    4750:	03400613          	li	a2,52
    4754:	00c58593          	add	a1,a1,12
    4758:	03448513          	add	a0,s1,52
    475c:	ffffc097          	auipc	ra,0xffffc
    4760:	798080e7          	jalr	1944(ra) # ef4 <memmove>
    brelse(bp);
    4764:	00090513          	mv	a0,s2
    4768:	fffff097          	auipc	ra,0xfffff
    476c:	61c080e7          	jalr	1564(ra) # 3d84 <brelse>
    ip->valid = 1;
    4770:	00100793          	li	a5,1
    4774:	02f4a223          	sw	a5,36(s1)
    if(ip->type == 0)
    4778:	02849783          	lh	a5,40(s1)
    477c:	f40796e3          	bnez	a5,46c8 <ilock+0x3c>
      panic("ilock: no type");
    4780:	00004517          	auipc	a0,0x4
    4784:	dd050513          	add	a0,a0,-560 # 8550 <userret+0x4b0>
    4788:	ffffc097          	auipc	ra,0xffffc
    478c:	f04080e7          	jalr	-252(ra) # 68c <panic>

00004790 <iunlock>:
{
    4790:	ff010113          	add	sp,sp,-16
    4794:	00112623          	sw	ra,12(sp)
    4798:	00812423          	sw	s0,8(sp)
    479c:	00912223          	sw	s1,4(sp)
    47a0:	01212023          	sw	s2,0(sp)
    47a4:	01010413          	add	s0,sp,16
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    47a8:	04050463          	beqz	a0,47f0 <iunlock+0x60>
    47ac:	00050493          	mv	s1,a0
    47b0:	00c50913          	add	s2,a0,12
    47b4:	00090513          	mv	a0,s2
    47b8:	00001097          	auipc	ra,0x1
    47bc:	0d0080e7          	jalr	208(ra) # 5888 <holdingsleep>
    47c0:	02050863          	beqz	a0,47f0 <iunlock+0x60>
    47c4:	0084a783          	lw	a5,8(s1)
    47c8:	02f05463          	blez	a5,47f0 <iunlock+0x60>
  releasesleep(&ip->lock);
    47cc:	00090513          	mv	a0,s2
    47d0:	00001097          	auipc	ra,0x1
    47d4:	054080e7          	jalr	84(ra) # 5824 <releasesleep>
}
    47d8:	00c12083          	lw	ra,12(sp)
    47dc:	00812403          	lw	s0,8(sp)
    47e0:	00412483          	lw	s1,4(sp)
    47e4:	00012903          	lw	s2,0(sp)
    47e8:	01010113          	add	sp,sp,16
    47ec:	00008067          	ret
    panic("iunlock");
    47f0:	00004517          	auipc	a0,0x4
    47f4:	d7050513          	add	a0,a0,-656 # 8560 <userret+0x4c0>
    47f8:	ffffc097          	auipc	ra,0xffffc
    47fc:	e94080e7          	jalr	-364(ra) # 68c <panic>

00004800 <iput>:
{
    4800:	fe010113          	add	sp,sp,-32
    4804:	00112e23          	sw	ra,28(sp)
    4808:	00812c23          	sw	s0,24(sp)
    480c:	00912a23          	sw	s1,20(sp)
    4810:	01212823          	sw	s2,16(sp)
    4814:	01312623          	sw	s3,12(sp)
    4818:	01412423          	sw	s4,8(sp)
    481c:	01512223          	sw	s5,4(sp)
    4820:	02010413          	add	s0,sp,32
    4824:	00050493          	mv	s1,a0
  acquire(&icache.lock);
    4828:	00019517          	auipc	a0,0x19
    482c:	1bc50513          	add	a0,a0,444 # 1d9e4 <icache>
    4830:	ffffc097          	auipc	ra,0xffffc
    4834:	574080e7          	jalr	1396(ra) # da4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    4838:	0084a703          	lw	a4,8(s1)
    483c:	00100793          	li	a5,1
    4840:	04f70263          	beq	a4,a5,4884 <iput+0x84>
  ip->ref--;
    4844:	0084a783          	lw	a5,8(s1)
    4848:	fff78793          	add	a5,a5,-1
    484c:	00f4a423          	sw	a5,8(s1)
  release(&icache.lock);
    4850:	00019517          	auipc	a0,0x19
    4854:	19450513          	add	a0,a0,404 # 1d9e4 <icache>
    4858:	ffffc097          	auipc	ra,0xffffc
    485c:	5c0080e7          	jalr	1472(ra) # e18 <release>
}
    4860:	01c12083          	lw	ra,28(sp)
    4864:	01812403          	lw	s0,24(sp)
    4868:	01412483          	lw	s1,20(sp)
    486c:	01012903          	lw	s2,16(sp)
    4870:	00c12983          	lw	s3,12(sp)
    4874:	00812a03          	lw	s4,8(sp)
    4878:	00412a83          	lw	s5,4(sp)
    487c:	02010113          	add	sp,sp,32
    4880:	00008067          	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    4884:	0244a783          	lw	a5,36(s1)
    4888:	fa078ee3          	beqz	a5,4844 <iput+0x44>
    488c:	02e49783          	lh	a5,46(s1)
    4890:	fa079ae3          	bnez	a5,4844 <iput+0x44>
    acquiresleep(&ip->lock);
    4894:	00c48a13          	add	s4,s1,12
    4898:	000a0513          	mv	a0,s4
    489c:	00001097          	auipc	ra,0x1
    48a0:	f00080e7          	jalr	-256(ra) # 579c <acquiresleep>
    release(&icache.lock);
    48a4:	00019517          	auipc	a0,0x19
    48a8:	14050513          	add	a0,a0,320 # 1d9e4 <icache>
    48ac:	ffffc097          	auipc	ra,0xffffc
    48b0:	56c080e7          	jalr	1388(ra) # e18 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    48b4:	03448913          	add	s2,s1,52
    48b8:	06448993          	add	s3,s1,100
    48bc:	00c0006f          	j	48c8 <iput+0xc8>
    48c0:	00490913          	add	s2,s2,4
    48c4:	03390063          	beq	s2,s3,48e4 <iput+0xe4>
    if(ip->addrs[i]){
    48c8:	00092583          	lw	a1,0(s2)
    48cc:	fe058ae3          	beqz	a1,48c0 <iput+0xc0>
      bfree(ip->dev, ip->addrs[i]);
    48d0:	0004a503          	lw	a0,0(s1)
    48d4:	fffff097          	auipc	ra,0xfffff
    48d8:	630080e7          	jalr	1584(ra) # 3f04 <bfree>
      ip->addrs[i] = 0;
    48dc:	00092023          	sw	zero,0(s2)
    48e0:	fe1ff06f          	j	48c0 <iput+0xc0>
    }
  }

  if(ip->addrs[NDIRECT]){
    48e4:	0644a583          	lw	a1,100(s1)
    48e8:	04059463          	bnez	a1,4930 <iput+0x130>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    48ec:	0204a823          	sw	zero,48(s1)
  iupdate(ip);
    48f0:	00048513          	mv	a0,s1
    48f4:	00000097          	auipc	ra,0x0
    48f8:	c7c080e7          	jalr	-900(ra) # 4570 <iupdate>
    ip->type = 0;
    48fc:	02049423          	sh	zero,40(s1)
    iupdate(ip);
    4900:	00048513          	mv	a0,s1
    4904:	00000097          	auipc	ra,0x0
    4908:	c6c080e7          	jalr	-916(ra) # 4570 <iupdate>
    ip->valid = 0;
    490c:	0204a223          	sw	zero,36(s1)
    releasesleep(&ip->lock);
    4910:	000a0513          	mv	a0,s4
    4914:	00001097          	auipc	ra,0x1
    4918:	f10080e7          	jalr	-240(ra) # 5824 <releasesleep>
    acquire(&icache.lock);
    491c:	00019517          	auipc	a0,0x19
    4920:	0c850513          	add	a0,a0,200 # 1d9e4 <icache>
    4924:	ffffc097          	auipc	ra,0xffffc
    4928:	480080e7          	jalr	1152(ra) # da4 <acquire>
    492c:	f19ff06f          	j	4844 <iput+0x44>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    4930:	0004a503          	lw	a0,0(s1)
    4934:	fffff097          	auipc	ra,0xfffff
    4938:	2b4080e7          	jalr	692(ra) # 3be8 <bread>
    493c:	00050a93          	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    4940:	03850913          	add	s2,a0,56
    4944:	43850993          	add	s3,a0,1080
    4948:	00c0006f          	j	4954 <iput+0x154>
    494c:	00490913          	add	s2,s2,4
    4950:	01390e63          	beq	s2,s3,496c <iput+0x16c>
      if(a[j])
    4954:	00092583          	lw	a1,0(s2)
    4958:	fe058ae3          	beqz	a1,494c <iput+0x14c>
        bfree(ip->dev, a[j]);
    495c:	0004a503          	lw	a0,0(s1)
    4960:	fffff097          	auipc	ra,0xfffff
    4964:	5a4080e7          	jalr	1444(ra) # 3f04 <bfree>
    4968:	fe5ff06f          	j	494c <iput+0x14c>
    brelse(bp);
    496c:	000a8513          	mv	a0,s5
    4970:	fffff097          	auipc	ra,0xfffff
    4974:	414080e7          	jalr	1044(ra) # 3d84 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    4978:	0644a583          	lw	a1,100(s1)
    497c:	0004a503          	lw	a0,0(s1)
    4980:	fffff097          	auipc	ra,0xfffff
    4984:	584080e7          	jalr	1412(ra) # 3f04 <bfree>
    ip->addrs[NDIRECT] = 0;
    4988:	0604a223          	sw	zero,100(s1)
    498c:	f61ff06f          	j	48ec <iput+0xec>

00004990 <iunlockput>:
{
    4990:	ff010113          	add	sp,sp,-16
    4994:	00112623          	sw	ra,12(sp)
    4998:	00812423          	sw	s0,8(sp)
    499c:	00912223          	sw	s1,4(sp)
    49a0:	01010413          	add	s0,sp,16
    49a4:	00050493          	mv	s1,a0
  iunlock(ip);
    49a8:	00000097          	auipc	ra,0x0
    49ac:	de8080e7          	jalr	-536(ra) # 4790 <iunlock>
  iput(ip);
    49b0:	00048513          	mv	a0,s1
    49b4:	00000097          	auipc	ra,0x0
    49b8:	e4c080e7          	jalr	-436(ra) # 4800 <iput>
}
    49bc:	00c12083          	lw	ra,12(sp)
    49c0:	00812403          	lw	s0,8(sp)
    49c4:	00412483          	lw	s1,4(sp)
    49c8:	01010113          	add	sp,sp,16
    49cc:	00008067          	ret

000049d0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    49d0:	ff010113          	add	sp,sp,-16
    49d4:	00812623          	sw	s0,12(sp)
    49d8:	01010413          	add	s0,sp,16
  st->dev = ip->dev;
    49dc:	00052783          	lw	a5,0(a0)
    49e0:	00f5a023          	sw	a5,0(a1)
  st->ino = ip->inum;
    49e4:	00452783          	lw	a5,4(a0)
    49e8:	00f5a223          	sw	a5,4(a1)
  st->type = ip->type;
    49ec:	02851783          	lh	a5,40(a0)
    49f0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    49f4:	02e51783          	lh	a5,46(a0)
    49f8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    49fc:	03052783          	lw	a5,48(a0)
    4a00:	00f5a823          	sw	a5,16(a1)
    4a04:	0005aa23          	sw	zero,20(a1)
}
    4a08:	00c12403          	lw	s0,12(sp)
    4a0c:	01010113          	add	sp,sp,16
    4a10:	00008067          	ret

00004a14 <readi>:
readi(struct inode *ip, int user_dst, uint32 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    4a14:	03052783          	lw	a5,48(a0)
    4a18:	12d7ec63          	bltu	a5,a3,4b50 <readi+0x13c>
{
    4a1c:	fd010113          	add	sp,sp,-48
    4a20:	02112623          	sw	ra,44(sp)
    4a24:	02812423          	sw	s0,40(sp)
    4a28:	02912223          	sw	s1,36(sp)
    4a2c:	03212023          	sw	s2,32(sp)
    4a30:	01312e23          	sw	s3,28(sp)
    4a34:	01412c23          	sw	s4,24(sp)
    4a38:	01512a23          	sw	s5,20(sp)
    4a3c:	01612823          	sw	s6,16(sp)
    4a40:	01712623          	sw	s7,12(sp)
    4a44:	01812423          	sw	s8,8(sp)
    4a48:	01912223          	sw	s9,4(sp)
    4a4c:	01a12023          	sw	s10,0(sp)
    4a50:	03010413          	add	s0,sp,48
    4a54:	00050b93          	mv	s7,a0
    4a58:	00058c13          	mv	s8,a1
    4a5c:	00060a93          	mv	s5,a2
    4a60:	00068993          	mv	s3,a3
    4a64:	00070b13          	mv	s6,a4
  if(off > ip->size || off + n < off)
    4a68:	00e68733          	add	a4,a3,a4
    4a6c:	0ed76663          	bltu	a4,a3,4b58 <readi+0x144>
    return -1;
  if(off + n > ip->size)
    4a70:	00e7f463          	bgeu	a5,a4,4a78 <readi+0x64>
    n = ip->size - off;
    4a74:	40d78b33          	sub	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    4a78:	080b0e63          	beqz	s6,4b14 <readi+0x100>
    4a7c:	00000a13          	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    4a80:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    4a84:	fff00c93          	li	s9,-1
    4a88:	0400006f          	j	4ac8 <readi+0xb4>
    4a8c:	03890613          	add	a2,s2,56
    4a90:	00048693          	mv	a3,s1
    4a94:	00f60633          	add	a2,a2,a5
    4a98:	000a8593          	mv	a1,s5
    4a9c:	000c0513          	mv	a0,s8
    4aa0:	ffffe097          	auipc	ra,0xffffe
    4aa4:	3d8080e7          	jalr	984(ra) # 2e78 <either_copyout>
    4aa8:	07950063          	beq	a0,s9,4b08 <readi+0xf4>
      brelse(bp);
      break;
    }
    brelse(bp);
    4aac:	00090513          	mv	a0,s2
    4ab0:	fffff097          	auipc	ra,0xfffff
    4ab4:	2d4080e7          	jalr	724(ra) # 3d84 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    4ab8:	009a0a33          	add	s4,s4,s1
    4abc:	009989b3          	add	s3,s3,s1
    4ac0:	009a8ab3          	add	s5,s5,s1
    4ac4:	056a7863          	bgeu	s4,s6,4b14 <readi+0x100>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    4ac8:	000ba483          	lw	s1,0(s7)
    4acc:	00a9d593          	srl	a1,s3,0xa
    4ad0:	000b8513          	mv	a0,s7
    4ad4:	fffff097          	auipc	ra,0xfffff
    4ad8:	664080e7          	jalr	1636(ra) # 4138 <bmap>
    4adc:	00050593          	mv	a1,a0
    4ae0:	00048513          	mv	a0,s1
    4ae4:	fffff097          	auipc	ra,0xfffff
    4ae8:	104080e7          	jalr	260(ra) # 3be8 <bread>
    4aec:	00050913          	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    4af0:	3ff9f793          	and	a5,s3,1023
    4af4:	414b0733          	sub	a4,s6,s4
    4af8:	40fd04b3          	sub	s1,s10,a5
    4afc:	f89778e3          	bgeu	a4,s1,4a8c <readi+0x78>
    4b00:	00070493          	mv	s1,a4
    4b04:	f89ff06f          	j	4a8c <readi+0x78>
      brelse(bp);
    4b08:	00090513          	mv	a0,s2
    4b0c:	fffff097          	auipc	ra,0xfffff
    4b10:	278080e7          	jalr	632(ra) # 3d84 <brelse>
  }
  return n;
    4b14:	000b0513          	mv	a0,s6
}
    4b18:	02c12083          	lw	ra,44(sp)
    4b1c:	02812403          	lw	s0,40(sp)
    4b20:	02412483          	lw	s1,36(sp)
    4b24:	02012903          	lw	s2,32(sp)
    4b28:	01c12983          	lw	s3,28(sp)
    4b2c:	01812a03          	lw	s4,24(sp)
    4b30:	01412a83          	lw	s5,20(sp)
    4b34:	01012b03          	lw	s6,16(sp)
    4b38:	00c12b83          	lw	s7,12(sp)
    4b3c:	00812c03          	lw	s8,8(sp)
    4b40:	00412c83          	lw	s9,4(sp)
    4b44:	00012d03          	lw	s10,0(sp)
    4b48:	03010113          	add	sp,sp,48
    4b4c:	00008067          	ret
    return -1;
    4b50:	fff00513          	li	a0,-1
}
    4b54:	00008067          	ret
    return -1;
    4b58:	fff00513          	li	a0,-1
    4b5c:	fbdff06f          	j	4b18 <readi+0x104>

00004b60 <writei>:
writei(struct inode *ip, int user_src, uint32 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    4b60:	03052783          	lw	a5,48(a0)
    4b64:	14d7ee63          	bltu	a5,a3,4cc0 <writei+0x160>
{
    4b68:	fd010113          	add	sp,sp,-48
    4b6c:	02112623          	sw	ra,44(sp)
    4b70:	02812423          	sw	s0,40(sp)
    4b74:	02912223          	sw	s1,36(sp)
    4b78:	03212023          	sw	s2,32(sp)
    4b7c:	01312e23          	sw	s3,28(sp)
    4b80:	01412c23          	sw	s4,24(sp)
    4b84:	01512a23          	sw	s5,20(sp)
    4b88:	01612823          	sw	s6,16(sp)
    4b8c:	01712623          	sw	s7,12(sp)
    4b90:	01812423          	sw	s8,8(sp)
    4b94:	01912223          	sw	s9,4(sp)
    4b98:	01a12023          	sw	s10,0(sp)
    4b9c:	03010413          	add	s0,sp,48
    4ba0:	00050b93          	mv	s7,a0
    4ba4:	00058c13          	mv	s8,a1
    4ba8:	00060a93          	mv	s5,a2
    4bac:	00068993          	mv	s3,a3
    4bb0:	00070b13          	mv	s6,a4
  if(off > ip->size || off + n < off)
    4bb4:	00e687b3          	add	a5,a3,a4
    4bb8:	10d7e863          	bltu	a5,a3,4cc8 <writei+0x168>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    4bbc:	00043737          	lui	a4,0x43
    4bc0:	10f76863          	bltu	a4,a5,4cd0 <writei+0x170>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    4bc4:	0c0b0063          	beqz	s6,4c84 <writei+0x124>
    4bc8:	00000a13          	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    4bcc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    4bd0:	fff00c93          	li	s9,-1
    4bd4:	04c0006f          	j	4c20 <writei+0xc0>
    4bd8:	03890793          	add	a5,s2,56
    4bdc:	00048693          	mv	a3,s1
    4be0:	000a8613          	mv	a2,s5
    4be4:	000c0593          	mv	a1,s8
    4be8:	00a78533          	add	a0,a5,a0
    4bec:	ffffe097          	auipc	ra,0xffffe
    4bf0:	31c080e7          	jalr	796(ra) # 2f08 <either_copyin>
    4bf4:	07950663          	beq	a0,s9,4c60 <writei+0x100>
      brelse(bp);
      break;
    }
    log_write(bp);
    4bf8:	00090513          	mv	a0,s2
    4bfc:	00001097          	auipc	ra,0x1
    4c00:	a14080e7          	jalr	-1516(ra) # 5610 <log_write>
    brelse(bp);
    4c04:	00090513          	mv	a0,s2
    4c08:	fffff097          	auipc	ra,0xfffff
    4c0c:	17c080e7          	jalr	380(ra) # 3d84 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    4c10:	009a0a33          	add	s4,s4,s1
    4c14:	009989b3          	add	s3,s3,s1
    4c18:	009a8ab3          	add	s5,s5,s1
    4c1c:	056a7863          	bgeu	s4,s6,4c6c <writei+0x10c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    4c20:	000ba483          	lw	s1,0(s7)
    4c24:	00a9d593          	srl	a1,s3,0xa
    4c28:	000b8513          	mv	a0,s7
    4c2c:	fffff097          	auipc	ra,0xfffff
    4c30:	50c080e7          	jalr	1292(ra) # 4138 <bmap>
    4c34:	00050593          	mv	a1,a0
    4c38:	00048513          	mv	a0,s1
    4c3c:	fffff097          	auipc	ra,0xfffff
    4c40:	fac080e7          	jalr	-84(ra) # 3be8 <bread>
    4c44:	00050913          	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    4c48:	3ff9f513          	and	a0,s3,1023
    4c4c:	414b07b3          	sub	a5,s6,s4
    4c50:	40ad04b3          	sub	s1,s10,a0
    4c54:	f897f2e3          	bgeu	a5,s1,4bd8 <writei+0x78>
    4c58:	00078493          	mv	s1,a5
    4c5c:	f7dff06f          	j	4bd8 <writei+0x78>
      brelse(bp);
    4c60:	00090513          	mv	a0,s2
    4c64:	fffff097          	auipc	ra,0xfffff
    4c68:	120080e7          	jalr	288(ra) # 3d84 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    4c6c:	030ba783          	lw	a5,48(s7)
    4c70:	0137f463          	bgeu	a5,s3,4c78 <writei+0x118>
      ip->size = off;
    4c74:	033ba823          	sw	s3,48(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    4c78:	000b8513          	mv	a0,s7
    4c7c:	00000097          	auipc	ra,0x0
    4c80:	8f4080e7          	jalr	-1804(ra) # 4570 <iupdate>
  }

  return n;
    4c84:	000b0513          	mv	a0,s6
}
    4c88:	02c12083          	lw	ra,44(sp)
    4c8c:	02812403          	lw	s0,40(sp)
    4c90:	02412483          	lw	s1,36(sp)
    4c94:	02012903          	lw	s2,32(sp)
    4c98:	01c12983          	lw	s3,28(sp)
    4c9c:	01812a03          	lw	s4,24(sp)
    4ca0:	01412a83          	lw	s5,20(sp)
    4ca4:	01012b03          	lw	s6,16(sp)
    4ca8:	00c12b83          	lw	s7,12(sp)
    4cac:	00812c03          	lw	s8,8(sp)
    4cb0:	00412c83          	lw	s9,4(sp)
    4cb4:	00012d03          	lw	s10,0(sp)
    4cb8:	03010113          	add	sp,sp,48
    4cbc:	00008067          	ret
    return -1;
    4cc0:	fff00513          	li	a0,-1
}
    4cc4:	00008067          	ret
    return -1;
    4cc8:	fff00513          	li	a0,-1
    4ccc:	fbdff06f          	j	4c88 <writei+0x128>
    return -1;
    4cd0:	fff00513          	li	a0,-1
    4cd4:	fb5ff06f          	j	4c88 <writei+0x128>

00004cd8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    4cd8:	ff010113          	add	sp,sp,-16
    4cdc:	00112623          	sw	ra,12(sp)
    4ce0:	00812423          	sw	s0,8(sp)
    4ce4:	01010413          	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    4ce8:	00e00613          	li	a2,14
    4cec:	ffffc097          	auipc	ra,0xffffc
    4cf0:	294080e7          	jalr	660(ra) # f80 <strncmp>
}
    4cf4:	00c12083          	lw	ra,12(sp)
    4cf8:	00812403          	lw	s0,8(sp)
    4cfc:	01010113          	add	sp,sp,16
    4d00:	00008067          	ret

00004d04 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    4d04:	fd010113          	add	sp,sp,-48
    4d08:	02112623          	sw	ra,44(sp)
    4d0c:	02812423          	sw	s0,40(sp)
    4d10:	02912223          	sw	s1,36(sp)
    4d14:	03212023          	sw	s2,32(sp)
    4d18:	01312e23          	sw	s3,28(sp)
    4d1c:	01412c23          	sw	s4,24(sp)
    4d20:	03010413          	add	s0,sp,48
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    4d24:	02851703          	lh	a4,40(a0)
    4d28:	00100793          	li	a5,1
    4d2c:	02f71263          	bne	a4,a5,4d50 <dirlookup+0x4c>
    4d30:	00050913          	mv	s2,a0
    4d34:	00058993          	mv	s3,a1
    4d38:	00060a13          	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    4d3c:	03052783          	lw	a5,48(a0)
    4d40:	00000493          	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    4d44:	00000513          	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    4d48:	02079a63          	bnez	a5,4d7c <dirlookup+0x78>
    4d4c:	0900006f          	j	4ddc <dirlookup+0xd8>
    panic("dirlookup not DIR");
    4d50:	00004517          	auipc	a0,0x4
    4d54:	81850513          	add	a0,a0,-2024 # 8568 <userret+0x4c8>
    4d58:	ffffc097          	auipc	ra,0xffffc
    4d5c:	934080e7          	jalr	-1740(ra) # 68c <panic>
      panic("dirlookup read");
    4d60:	00004517          	auipc	a0,0x4
    4d64:	81c50513          	add	a0,a0,-2020 # 857c <userret+0x4dc>
    4d68:	ffffc097          	auipc	ra,0xffffc
    4d6c:	924080e7          	jalr	-1756(ra) # 68c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    4d70:	01048493          	add	s1,s1,16
    4d74:	03092783          	lw	a5,48(s2)
    4d78:	06f4f063          	bgeu	s1,a5,4dd8 <dirlookup+0xd4>
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    4d7c:	01000713          	li	a4,16
    4d80:	00048693          	mv	a3,s1
    4d84:	fd040613          	add	a2,s0,-48
    4d88:	00000593          	li	a1,0
    4d8c:	00090513          	mv	a0,s2
    4d90:	00000097          	auipc	ra,0x0
    4d94:	c84080e7          	jalr	-892(ra) # 4a14 <readi>
    4d98:	01000793          	li	a5,16
    4d9c:	fcf512e3          	bne	a0,a5,4d60 <dirlookup+0x5c>
    if(de.inum == 0)
    4da0:	fd045783          	lhu	a5,-48(s0)
    4da4:	fc0786e3          	beqz	a5,4d70 <dirlookup+0x6c>
    if(namecmp(name, de.name) == 0){
    4da8:	fd240593          	add	a1,s0,-46
    4dac:	00098513          	mv	a0,s3
    4db0:	00000097          	auipc	ra,0x0
    4db4:	f28080e7          	jalr	-216(ra) # 4cd8 <namecmp>
    4db8:	fa051ce3          	bnez	a0,4d70 <dirlookup+0x6c>
      if(poff)
    4dbc:	000a0463          	beqz	s4,4dc4 <dirlookup+0xc0>
        *poff = off;
    4dc0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    4dc4:	fd045583          	lhu	a1,-48(s0)
    4dc8:	00092503          	lw	a0,0(s2)
    4dcc:	fffff097          	auipc	ra,0xfffff
    4dd0:	474080e7          	jalr	1140(ra) # 4240 <iget>
    4dd4:	0080006f          	j	4ddc <dirlookup+0xd8>
  return 0;
    4dd8:	00000513          	li	a0,0
}
    4ddc:	02c12083          	lw	ra,44(sp)
    4de0:	02812403          	lw	s0,40(sp)
    4de4:	02412483          	lw	s1,36(sp)
    4de8:	02012903          	lw	s2,32(sp)
    4dec:	01c12983          	lw	s3,28(sp)
    4df0:	01812a03          	lw	s4,24(sp)
    4df4:	03010113          	add	sp,sp,48
    4df8:	00008067          	ret

00004dfc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    4dfc:	fd010113          	add	sp,sp,-48
    4e00:	02112623          	sw	ra,44(sp)
    4e04:	02812423          	sw	s0,40(sp)
    4e08:	02912223          	sw	s1,36(sp)
    4e0c:	03212023          	sw	s2,32(sp)
    4e10:	01312e23          	sw	s3,28(sp)
    4e14:	01412c23          	sw	s4,24(sp)
    4e18:	01512a23          	sw	s5,20(sp)
    4e1c:	01612823          	sw	s6,16(sp)
    4e20:	01712623          	sw	s7,12(sp)
    4e24:	01812423          	sw	s8,8(sp)
    4e28:	01912223          	sw	s9,4(sp)
    4e2c:	03010413          	add	s0,sp,48
    4e30:	00050493          	mv	s1,a0
    4e34:	00058b13          	mv	s6,a1
    4e38:	00060a93          	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    4e3c:	00054703          	lbu	a4,0(a0)
    4e40:	02f00793          	li	a5,47
    4e44:	02f70663          	beq	a4,a5,4e70 <namex+0x74>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    4e48:	ffffd097          	auipc	ra,0xffffd
    4e4c:	288080e7          	jalr	648(ra) # 20d0 <myproc>
    4e50:	0ac52503          	lw	a0,172(a0)
    4e54:	fffff097          	auipc	ra,0xfffff
    4e58:	7dc080e7          	jalr	2012(ra) # 4630 <idup>
    4e5c:	00050a13          	mv	s4,a0
  while(*path == '/')
    4e60:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    4e64:	00d00c13          	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    4e68:	00100b93          	li	s7,1
    4e6c:	1080006f          	j	4f74 <namex+0x178>
    ip = iget(ROOTDEV, ROOTINO);
    4e70:	00100593          	li	a1,1
    4e74:	00100513          	li	a0,1
    4e78:	fffff097          	auipc	ra,0xfffff
    4e7c:	3c8080e7          	jalr	968(ra) # 4240 <iget>
    4e80:	00050a13          	mv	s4,a0
    4e84:	fddff06f          	j	4e60 <namex+0x64>
      iunlockput(ip);
    4e88:	000a0513          	mv	a0,s4
    4e8c:	00000097          	auipc	ra,0x0
    4e90:	b04080e7          	jalr	-1276(ra) # 4990 <iunlockput>
      return 0;
    4e94:	00000a13          	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    4e98:	000a0513          	mv	a0,s4
    4e9c:	02c12083          	lw	ra,44(sp)
    4ea0:	02812403          	lw	s0,40(sp)
    4ea4:	02412483          	lw	s1,36(sp)
    4ea8:	02012903          	lw	s2,32(sp)
    4eac:	01c12983          	lw	s3,28(sp)
    4eb0:	01812a03          	lw	s4,24(sp)
    4eb4:	01412a83          	lw	s5,20(sp)
    4eb8:	01012b03          	lw	s6,16(sp)
    4ebc:	00c12b83          	lw	s7,12(sp)
    4ec0:	00812c03          	lw	s8,8(sp)
    4ec4:	00412c83          	lw	s9,4(sp)
    4ec8:	03010113          	add	sp,sp,48
    4ecc:	00008067          	ret
      iunlock(ip);
    4ed0:	000a0513          	mv	a0,s4
    4ed4:	00000097          	auipc	ra,0x0
    4ed8:	8bc080e7          	jalr	-1860(ra) # 4790 <iunlock>
      return ip;
    4edc:	fbdff06f          	j	4e98 <namex+0x9c>
      iunlockput(ip);
    4ee0:	000a0513          	mv	a0,s4
    4ee4:	00000097          	auipc	ra,0x0
    4ee8:	aac080e7          	jalr	-1364(ra) # 4990 <iunlockput>
      return 0;
    4eec:	00098a13          	mv	s4,s3
    4ef0:	fa9ff06f          	j	4e98 <namex+0x9c>
  len = path - s;
    4ef4:	40998cb3          	sub	s9,s3,s1
  if(len >= DIRSIZ)
    4ef8:	0b9c5c63          	bge	s8,s9,4fb0 <namex+0x1b4>
    memmove(name, s, DIRSIZ);
    4efc:	00e00613          	li	a2,14
    4f00:	00048593          	mv	a1,s1
    4f04:	000a8513          	mv	a0,s5
    4f08:	ffffc097          	auipc	ra,0xffffc
    4f0c:	fec080e7          	jalr	-20(ra) # ef4 <memmove>
    4f10:	00098493          	mv	s1,s3
  while(*path == '/')
    4f14:	0004c783          	lbu	a5,0(s1)
    4f18:	01279863          	bne	a5,s2,4f28 <namex+0x12c>
    path++;
    4f1c:	00148493          	add	s1,s1,1
  while(*path == '/')
    4f20:	0004c783          	lbu	a5,0(s1)
    4f24:	ff278ce3          	beq	a5,s2,4f1c <namex+0x120>
    ilock(ip);
    4f28:	000a0513          	mv	a0,s4
    4f2c:	fffff097          	auipc	ra,0xfffff
    4f30:	760080e7          	jalr	1888(ra) # 468c <ilock>
    if(ip->type != T_DIR){
    4f34:	028a1783          	lh	a5,40(s4)
    4f38:	f57798e3          	bne	a5,s7,4e88 <namex+0x8c>
    if(nameiparent && *path == '\0'){
    4f3c:	000b0663          	beqz	s6,4f48 <namex+0x14c>
    4f40:	0004c783          	lbu	a5,0(s1)
    4f44:	f80786e3          	beqz	a5,4ed0 <namex+0xd4>
    if((next = dirlookup(ip, name, 0)) == 0){
    4f48:	00000613          	li	a2,0
    4f4c:	000a8593          	mv	a1,s5
    4f50:	000a0513          	mv	a0,s4
    4f54:	00000097          	auipc	ra,0x0
    4f58:	db0080e7          	jalr	-592(ra) # 4d04 <dirlookup>
    4f5c:	00050993          	mv	s3,a0
    4f60:	f80500e3          	beqz	a0,4ee0 <namex+0xe4>
    iunlockput(ip);
    4f64:	000a0513          	mv	a0,s4
    4f68:	00000097          	auipc	ra,0x0
    4f6c:	a28080e7          	jalr	-1496(ra) # 4990 <iunlockput>
    ip = next;
    4f70:	00098a13          	mv	s4,s3
  while(*path == '/')
    4f74:	0004c783          	lbu	a5,0(s1)
    4f78:	01279863          	bne	a5,s2,4f88 <namex+0x18c>
    path++;
    4f7c:	00148493          	add	s1,s1,1
  while(*path == '/')
    4f80:	0004c783          	lbu	a5,0(s1)
    4f84:	ff278ce3          	beq	a5,s2,4f7c <namex+0x180>
  if(*path == 0)
    4f88:	04078663          	beqz	a5,4fd4 <namex+0x1d8>
  while(*path != '/' && *path != 0)
    4f8c:	0004c783          	lbu	a5,0(s1)
    4f90:	00048993          	mv	s3,s1
  len = path - s;
    4f94:	00000c93          	li	s9,0
  while(*path != '/' && *path != 0)
    4f98:	01278c63          	beq	a5,s2,4fb0 <namex+0x1b4>
    4f9c:	f4078ce3          	beqz	a5,4ef4 <namex+0xf8>
    path++;
    4fa0:	00198993          	add	s3,s3,1
  while(*path != '/' && *path != 0)
    4fa4:	0009c783          	lbu	a5,0(s3)
    4fa8:	ff279ae3          	bne	a5,s2,4f9c <namex+0x1a0>
    4fac:	f49ff06f          	j	4ef4 <namex+0xf8>
    memmove(name, s, len);
    4fb0:	000c8613          	mv	a2,s9
    4fb4:	00048593          	mv	a1,s1
    4fb8:	000a8513          	mv	a0,s5
    4fbc:	ffffc097          	auipc	ra,0xffffc
    4fc0:	f38080e7          	jalr	-200(ra) # ef4 <memmove>
    name[len] = 0;
    4fc4:	019a8cb3          	add	s9,s5,s9
    4fc8:	000c8023          	sb	zero,0(s9)
    4fcc:	00098493          	mv	s1,s3
    4fd0:	f45ff06f          	j	4f14 <namex+0x118>
  if(nameiparent){
    4fd4:	ec0b02e3          	beqz	s6,4e98 <namex+0x9c>
    iput(ip);
    4fd8:	000a0513          	mv	a0,s4
    4fdc:	00000097          	auipc	ra,0x0
    4fe0:	824080e7          	jalr	-2012(ra) # 4800 <iput>
    return 0;
    4fe4:	00000a13          	li	s4,0
    4fe8:	eb1ff06f          	j	4e98 <namex+0x9c>

00004fec <dirlink>:
{
    4fec:	fd010113          	add	sp,sp,-48
    4ff0:	02112623          	sw	ra,44(sp)
    4ff4:	02812423          	sw	s0,40(sp)
    4ff8:	02912223          	sw	s1,36(sp)
    4ffc:	03212023          	sw	s2,32(sp)
    5000:	01312e23          	sw	s3,28(sp)
    5004:	01412c23          	sw	s4,24(sp)
    5008:	03010413          	add	s0,sp,48
    500c:	00050913          	mv	s2,a0
    5010:	00058a13          	mv	s4,a1
    5014:	00060993          	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    5018:	00000613          	li	a2,0
    501c:	00000097          	auipc	ra,0x0
    5020:	ce8080e7          	jalr	-792(ra) # 4d04 <dirlookup>
    5024:	0a051663          	bnez	a0,50d0 <dirlink+0xe4>
  for(off = 0; off < dp->size; off += sizeof(de)){
    5028:	03092483          	lw	s1,48(s2)
    502c:	04048063          	beqz	s1,506c <dirlink+0x80>
    5030:	00000493          	li	s1,0
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    5034:	01000713          	li	a4,16
    5038:	00048693          	mv	a3,s1
    503c:	fd040613          	add	a2,s0,-48
    5040:	00000593          	li	a1,0
    5044:	00090513          	mv	a0,s2
    5048:	00000097          	auipc	ra,0x0
    504c:	9cc080e7          	jalr	-1588(ra) # 4a14 <readi>
    5050:	01000793          	li	a5,16
    5054:	08f51663          	bne	a0,a5,50e0 <dirlink+0xf4>
    if(de.inum == 0)
    5058:	fd045783          	lhu	a5,-48(s0)
    505c:	00078863          	beqz	a5,506c <dirlink+0x80>
  for(off = 0; off < dp->size; off += sizeof(de)){
    5060:	01048493          	add	s1,s1,16
    5064:	03092783          	lw	a5,48(s2)
    5068:	fcf4e6e3          	bltu	s1,a5,5034 <dirlink+0x48>
  strncpy(de.name, name, DIRSIZ);
    506c:	00e00613          	li	a2,14
    5070:	000a0593          	mv	a1,s4
    5074:	fd240513          	add	a0,s0,-46
    5078:	ffffc097          	auipc	ra,0xffffc
    507c:	f6c080e7          	jalr	-148(ra) # fe4 <strncpy>
  de.inum = inum;
    5080:	fd341823          	sh	s3,-48(s0)
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    5084:	01000713          	li	a4,16
    5088:	00048693          	mv	a3,s1
    508c:	fd040613          	add	a2,s0,-48
    5090:	00000593          	li	a1,0
    5094:	00090513          	mv	a0,s2
    5098:	00000097          	auipc	ra,0x0
    509c:	ac8080e7          	jalr	-1336(ra) # 4b60 <writei>
    50a0:	00050713          	mv	a4,a0
    50a4:	01000793          	li	a5,16
  return 0;
    50a8:	00000513          	li	a0,0
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    50ac:	04f71263          	bne	a4,a5,50f0 <dirlink+0x104>
}
    50b0:	02c12083          	lw	ra,44(sp)
    50b4:	02812403          	lw	s0,40(sp)
    50b8:	02412483          	lw	s1,36(sp)
    50bc:	02012903          	lw	s2,32(sp)
    50c0:	01c12983          	lw	s3,28(sp)
    50c4:	01812a03          	lw	s4,24(sp)
    50c8:	03010113          	add	sp,sp,48
    50cc:	00008067          	ret
    iput(ip);
    50d0:	fffff097          	auipc	ra,0xfffff
    50d4:	730080e7          	jalr	1840(ra) # 4800 <iput>
    return -1;
    50d8:	fff00513          	li	a0,-1
    50dc:	fd5ff06f          	j	50b0 <dirlink+0xc4>
      panic("dirlink read");
    50e0:	00003517          	auipc	a0,0x3
    50e4:	4ac50513          	add	a0,a0,1196 # 858c <userret+0x4ec>
    50e8:	ffffb097          	auipc	ra,0xffffb
    50ec:	5a4080e7          	jalr	1444(ra) # 68c <panic>
    panic("dirlink");
    50f0:	00003517          	auipc	a0,0x3
    50f4:	5bc50513          	add	a0,a0,1468 # 86ac <userret+0x60c>
    50f8:	ffffb097          	auipc	ra,0xffffb
    50fc:	594080e7          	jalr	1428(ra) # 68c <panic>

00005100 <namei>:

struct inode*
namei(char *path)
{
    5100:	fe010113          	add	sp,sp,-32
    5104:	00112e23          	sw	ra,28(sp)
    5108:	00812c23          	sw	s0,24(sp)
    510c:	02010413          	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    5110:	fe040613          	add	a2,s0,-32
    5114:	00000593          	li	a1,0
    5118:	00000097          	auipc	ra,0x0
    511c:	ce4080e7          	jalr	-796(ra) # 4dfc <namex>
}
    5120:	01c12083          	lw	ra,28(sp)
    5124:	01812403          	lw	s0,24(sp)
    5128:	02010113          	add	sp,sp,32
    512c:	00008067          	ret

00005130 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    5130:	ff010113          	add	sp,sp,-16
    5134:	00112623          	sw	ra,12(sp)
    5138:	00812423          	sw	s0,8(sp)
    513c:	01010413          	add	s0,sp,16
    5140:	00058613          	mv	a2,a1
  return namex(path, 1, name);
    5144:	00100593          	li	a1,1
    5148:	00000097          	auipc	ra,0x0
    514c:	cb4080e7          	jalr	-844(ra) # 4dfc <namex>
}
    5150:	00c12083          	lw	ra,12(sp)
    5154:	00812403          	lw	s0,8(sp)
    5158:	01010113          	add	sp,sp,16
    515c:	00008067          	ret

00005160 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    5160:	ff010113          	add	sp,sp,-16
    5164:	00112623          	sw	ra,12(sp)
    5168:	00812423          	sw	s0,8(sp)
    516c:	00912223          	sw	s1,4(sp)
    5170:	01212023          	sw	s2,0(sp)
    5174:	01010413          	add	s0,sp,16
  struct buf *buf = bread(log.dev, log.start);
    5178:	0001a917          	auipc	s2,0x1a
    517c:	cc890913          	add	s2,s2,-824 # 1ee40 <log>
    5180:	00c92583          	lw	a1,12(s2)
    5184:	01c92503          	lw	a0,28(s2)
    5188:	fffff097          	auipc	ra,0xfffff
    518c:	a60080e7          	jalr	-1440(ra) # 3be8 <bread>
    5190:	00050493          	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    5194:	02092603          	lw	a2,32(s2)
    5198:	02c52c23          	sw	a2,56(a0)
  for (i = 0; i < log.lh.n; i++) {
    519c:	02c05663          	blez	a2,51c8 <write_head+0x68>
    51a0:	0001a717          	auipc	a4,0x1a
    51a4:	cc470713          	add	a4,a4,-828 # 1ee64 <log+0x24>
    51a8:	00050793          	mv	a5,a0
    51ac:	00261613          	sll	a2,a2,0x2
    51b0:	00a60633          	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    51b4:	00072683          	lw	a3,0(a4)
    51b8:	02d7ae23          	sw	a3,60(a5)
  for (i = 0; i < log.lh.n; i++) {
    51bc:	00470713          	add	a4,a4,4
    51c0:	00478793          	add	a5,a5,4
    51c4:	fec798e3          	bne	a5,a2,51b4 <write_head+0x54>
  }
  bwrite(buf);
    51c8:	00048513          	mv	a0,s1
    51cc:	fffff097          	auipc	ra,0xfffff
    51d0:	b5c080e7          	jalr	-1188(ra) # 3d28 <bwrite>
  brelse(buf);
    51d4:	00048513          	mv	a0,s1
    51d8:	fffff097          	auipc	ra,0xfffff
    51dc:	bac080e7          	jalr	-1108(ra) # 3d84 <brelse>
}
    51e0:	00c12083          	lw	ra,12(sp)
    51e4:	00812403          	lw	s0,8(sp)
    51e8:	00412483          	lw	s1,4(sp)
    51ec:	00012903          	lw	s2,0(sp)
    51f0:	01010113          	add	sp,sp,16
    51f4:	00008067          	ret

000051f8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    51f8:	0001a797          	auipc	a5,0x1a
    51fc:	c687a783          	lw	a5,-920(a5) # 1ee60 <log+0x20>
    5200:	0ef05263          	blez	a5,52e4 <install_trans+0xec>
{
    5204:	fe010113          	add	sp,sp,-32
    5208:	00112e23          	sw	ra,28(sp)
    520c:	00812c23          	sw	s0,24(sp)
    5210:	00912a23          	sw	s1,20(sp)
    5214:	01212823          	sw	s2,16(sp)
    5218:	01312623          	sw	s3,12(sp)
    521c:	01412423          	sw	s4,8(sp)
    5220:	01512223          	sw	s5,4(sp)
    5224:	02010413          	add	s0,sp,32
    5228:	0001aa97          	auipc	s5,0x1a
    522c:	c3ca8a93          	add	s5,s5,-964 # 1ee64 <log+0x24>
  for (tail = 0; tail < log.lh.n; tail++) {
    5230:	00000a13          	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    5234:	0001a997          	auipc	s3,0x1a
    5238:	c0c98993          	add	s3,s3,-1012 # 1ee40 <log>
    523c:	00c9a583          	lw	a1,12(s3)
    5240:	00ba05b3          	add	a1,s4,a1
    5244:	00158593          	add	a1,a1,1
    5248:	01c9a503          	lw	a0,28(s3)
    524c:	fffff097          	auipc	ra,0xfffff
    5250:	99c080e7          	jalr	-1636(ra) # 3be8 <bread>
    5254:	00050913          	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    5258:	000aa583          	lw	a1,0(s5)
    525c:	01c9a503          	lw	a0,28(s3)
    5260:	fffff097          	auipc	ra,0xfffff
    5264:	988080e7          	jalr	-1656(ra) # 3be8 <bread>
    5268:	00050493          	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    526c:	40000613          	li	a2,1024
    5270:	03890593          	add	a1,s2,56
    5274:	03850513          	add	a0,a0,56
    5278:	ffffc097          	auipc	ra,0xffffc
    527c:	c7c080e7          	jalr	-900(ra) # ef4 <memmove>
    bwrite(dbuf);  // write dst to disk
    5280:	00048513          	mv	a0,s1
    5284:	fffff097          	auipc	ra,0xfffff
    5288:	aa4080e7          	jalr	-1372(ra) # 3d28 <bwrite>
    bunpin(dbuf);
    528c:	00048513          	mv	a0,s1
    5290:	fffff097          	auipc	ra,0xfffff
    5294:	c1c080e7          	jalr	-996(ra) # 3eac <bunpin>
    brelse(lbuf);
    5298:	00090513          	mv	a0,s2
    529c:	fffff097          	auipc	ra,0xfffff
    52a0:	ae8080e7          	jalr	-1304(ra) # 3d84 <brelse>
    brelse(dbuf);
    52a4:	00048513          	mv	a0,s1
    52a8:	fffff097          	auipc	ra,0xfffff
    52ac:	adc080e7          	jalr	-1316(ra) # 3d84 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    52b0:	001a0a13          	add	s4,s4,1
    52b4:	004a8a93          	add	s5,s5,4
    52b8:	0209a783          	lw	a5,32(s3)
    52bc:	f8fa40e3          	blt	s4,a5,523c <install_trans+0x44>
}
    52c0:	01c12083          	lw	ra,28(sp)
    52c4:	01812403          	lw	s0,24(sp)
    52c8:	01412483          	lw	s1,20(sp)
    52cc:	01012903          	lw	s2,16(sp)
    52d0:	00c12983          	lw	s3,12(sp)
    52d4:	00812a03          	lw	s4,8(sp)
    52d8:	00412a83          	lw	s5,4(sp)
    52dc:	02010113          	add	sp,sp,32
    52e0:	00008067          	ret
    52e4:	00008067          	ret

000052e8 <initlog>:
{
    52e8:	fe010113          	add	sp,sp,-32
    52ec:	00112e23          	sw	ra,28(sp)
    52f0:	00812c23          	sw	s0,24(sp)
    52f4:	00912a23          	sw	s1,20(sp)
    52f8:	01212823          	sw	s2,16(sp)
    52fc:	01312623          	sw	s3,12(sp)
    5300:	02010413          	add	s0,sp,32
    5304:	00050913          	mv	s2,a0
    5308:	00058993          	mv	s3,a1
  initlock(&log.lock, "log");
    530c:	0001a497          	auipc	s1,0x1a
    5310:	b3448493          	add	s1,s1,-1228 # 1ee40 <log>
    5314:	00003597          	auipc	a1,0x3
    5318:	28858593          	add	a1,a1,648 # 859c <userret+0x4fc>
    531c:	00048513          	mv	a0,s1
    5320:	ffffc097          	auipc	ra,0xffffc
    5324:	900080e7          	jalr	-1792(ra) # c20 <initlock>
  log.start = sb->logstart;
    5328:	0149a583          	lw	a1,20(s3)
    532c:	00b4a623          	sw	a1,12(s1)
  log.size = sb->nlog;
    5330:	0109a783          	lw	a5,16(s3)
    5334:	00f4a823          	sw	a5,16(s1)
  log.dev = dev;
    5338:	0124ae23          	sw	s2,28(s1)
  struct buf *buf = bread(log.dev, log.start);
    533c:	00090513          	mv	a0,s2
    5340:	fffff097          	auipc	ra,0xfffff
    5344:	8a8080e7          	jalr	-1880(ra) # 3be8 <bread>
  log.lh.n = lh->n;
    5348:	03852603          	lw	a2,56(a0)
    534c:	02c4a023          	sw	a2,32(s1)
  for (i = 0; i < log.lh.n; i++) {
    5350:	02c05663          	blez	a2,537c <initlog+0x94>
    5354:	00050793          	mv	a5,a0
    5358:	0001a717          	auipc	a4,0x1a
    535c:	b0c70713          	add	a4,a4,-1268 # 1ee64 <log+0x24>
    5360:	00261613          	sll	a2,a2,0x2
    5364:	00a60633          	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    5368:	03c7a683          	lw	a3,60(a5)
    536c:	00d72023          	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    5370:	00478793          	add	a5,a5,4
    5374:	00470713          	add	a4,a4,4
    5378:	fec798e3          	bne	a5,a2,5368 <initlog+0x80>
  brelse(buf);
    537c:	fffff097          	auipc	ra,0xfffff
    5380:	a08080e7          	jalr	-1528(ra) # 3d84 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    5384:	00000097          	auipc	ra,0x0
    5388:	e74080e7          	jalr	-396(ra) # 51f8 <install_trans>
  log.lh.n = 0;
    538c:	0001a797          	auipc	a5,0x1a
    5390:	ac07aa23          	sw	zero,-1324(a5) # 1ee60 <log+0x20>
  write_head(); // clear the log
    5394:	00000097          	auipc	ra,0x0
    5398:	dcc080e7          	jalr	-564(ra) # 5160 <write_head>
}
    539c:	01c12083          	lw	ra,28(sp)
    53a0:	01812403          	lw	s0,24(sp)
    53a4:	01412483          	lw	s1,20(sp)
    53a8:	01012903          	lw	s2,16(sp)
    53ac:	00c12983          	lw	s3,12(sp)
    53b0:	02010113          	add	sp,sp,32
    53b4:	00008067          	ret

000053b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    53b8:	ff010113          	add	sp,sp,-16
    53bc:	00112623          	sw	ra,12(sp)
    53c0:	00812423          	sw	s0,8(sp)
    53c4:	00912223          	sw	s1,4(sp)
    53c8:	01212023          	sw	s2,0(sp)
    53cc:	01010413          	add	s0,sp,16
  acquire(&log.lock);
    53d0:	0001a517          	auipc	a0,0x1a
    53d4:	a7050513          	add	a0,a0,-1424 # 1ee40 <log>
    53d8:	ffffc097          	auipc	ra,0xffffc
    53dc:	9cc080e7          	jalr	-1588(ra) # da4 <acquire>
  while(1){
    if(log.committing){
    53e0:	0001a497          	auipc	s1,0x1a
    53e4:	a6048493          	add	s1,s1,-1440 # 1ee40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    53e8:	01e00913          	li	s2,30
    53ec:	0140006f          	j	5400 <begin_op+0x48>
      sleep(&log, &log.lock);
    53f0:	00048593          	mv	a1,s1
    53f4:	00048513          	mv	a0,s1
    53f8:	ffffd097          	auipc	ra,0xffffd
    53fc:	71c080e7          	jalr	1820(ra) # 2b14 <sleep>
    if(log.committing){
    5400:	0184a783          	lw	a5,24(s1)
    5404:	fe0796e3          	bnez	a5,53f0 <begin_op+0x38>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    5408:	0144a703          	lw	a4,20(s1)
    540c:	00170713          	add	a4,a4,1
    5410:	00271793          	sll	a5,a4,0x2
    5414:	00e787b3          	add	a5,a5,a4
    5418:	00179793          	sll	a5,a5,0x1
    541c:	0204a683          	lw	a3,32(s1)
    5420:	00d787b3          	add	a5,a5,a3
    5424:	00f95c63          	bge	s2,a5,543c <begin_op+0x84>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    5428:	00048593          	mv	a1,s1
    542c:	00048513          	mv	a0,s1
    5430:	ffffd097          	auipc	ra,0xffffd
    5434:	6e4080e7          	jalr	1764(ra) # 2b14 <sleep>
    5438:	fc9ff06f          	j	5400 <begin_op+0x48>
    } else {
      log.outstanding += 1;
    543c:	0001a517          	auipc	a0,0x1a
    5440:	a0450513          	add	a0,a0,-1532 # 1ee40 <log>
    5444:	00e52a23          	sw	a4,20(a0)
      release(&log.lock);
    5448:	ffffc097          	auipc	ra,0xffffc
    544c:	9d0080e7          	jalr	-1584(ra) # e18 <release>
      break;
    }
  }
}
    5450:	00c12083          	lw	ra,12(sp)
    5454:	00812403          	lw	s0,8(sp)
    5458:	00412483          	lw	s1,4(sp)
    545c:	00012903          	lw	s2,0(sp)
    5460:	01010113          	add	sp,sp,16
    5464:	00008067          	ret

00005468 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    5468:	fe010113          	add	sp,sp,-32
    546c:	00112e23          	sw	ra,28(sp)
    5470:	00812c23          	sw	s0,24(sp)
    5474:	00912a23          	sw	s1,20(sp)
    5478:	01212823          	sw	s2,16(sp)
    547c:	01312623          	sw	s3,12(sp)
    5480:	01412423          	sw	s4,8(sp)
    5484:	01512223          	sw	s5,4(sp)
    5488:	02010413          	add	s0,sp,32
  int do_commit = 0;

  acquire(&log.lock);
    548c:	0001a917          	auipc	s2,0x1a
    5490:	9b490913          	add	s2,s2,-1612 # 1ee40 <log>
    5494:	00090513          	mv	a0,s2
    5498:	ffffc097          	auipc	ra,0xffffc
    549c:	90c080e7          	jalr	-1780(ra) # da4 <acquire>
  log.outstanding -= 1;
    54a0:	01492483          	lw	s1,20(s2)
    54a4:	fff48493          	add	s1,s1,-1
    54a8:	00992a23          	sw	s1,20(s2)
  if(log.committing)
    54ac:	01892783          	lw	a5,24(s2)
    54b0:	06079063          	bnez	a5,5510 <end_op+0xa8>
    panic("log.committing");
  if(log.outstanding == 0){
    54b4:	06049663          	bnez	s1,5520 <end_op+0xb8>
    do_commit = 1;
    log.committing = 1;
    54b8:	0001a917          	auipc	s2,0x1a
    54bc:	98890913          	add	s2,s2,-1656 # 1ee40 <log>
    54c0:	00100793          	li	a5,1
    54c4:	00f92c23          	sw	a5,24(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    54c8:	00090513          	mv	a0,s2
    54cc:	ffffc097          	auipc	ra,0xffffc
    54d0:	94c080e7          	jalr	-1716(ra) # e18 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    54d4:	02092783          	lw	a5,32(s2)
    54d8:	08f04663          	bgtz	a5,5564 <end_op+0xfc>
    acquire(&log.lock);
    54dc:	0001a497          	auipc	s1,0x1a
    54e0:	96448493          	add	s1,s1,-1692 # 1ee40 <log>
    54e4:	00048513          	mv	a0,s1
    54e8:	ffffc097          	auipc	ra,0xffffc
    54ec:	8bc080e7          	jalr	-1860(ra) # da4 <acquire>
    log.committing = 0;
    54f0:	0004ac23          	sw	zero,24(s1)
    wakeup(&log);
    54f4:	00048513          	mv	a0,s1
    54f8:	ffffe097          	auipc	ra,0xffffe
    54fc:	838080e7          	jalr	-1992(ra) # 2d30 <wakeup>
    release(&log.lock);
    5500:	00048513          	mv	a0,s1
    5504:	ffffc097          	auipc	ra,0xffffc
    5508:	914080e7          	jalr	-1772(ra) # e18 <release>
}
    550c:	0340006f          	j	5540 <end_op+0xd8>
    panic("log.committing");
    5510:	00003517          	auipc	a0,0x3
    5514:	09050513          	add	a0,a0,144 # 85a0 <userret+0x500>
    5518:	ffffb097          	auipc	ra,0xffffb
    551c:	174080e7          	jalr	372(ra) # 68c <panic>
    wakeup(&log);
    5520:	0001a497          	auipc	s1,0x1a
    5524:	92048493          	add	s1,s1,-1760 # 1ee40 <log>
    5528:	00048513          	mv	a0,s1
    552c:	ffffe097          	auipc	ra,0xffffe
    5530:	804080e7          	jalr	-2044(ra) # 2d30 <wakeup>
  release(&log.lock);
    5534:	00048513          	mv	a0,s1
    5538:	ffffc097          	auipc	ra,0xffffc
    553c:	8e0080e7          	jalr	-1824(ra) # e18 <release>
}
    5540:	01c12083          	lw	ra,28(sp)
    5544:	01812403          	lw	s0,24(sp)
    5548:	01412483          	lw	s1,20(sp)
    554c:	01012903          	lw	s2,16(sp)
    5550:	00c12983          	lw	s3,12(sp)
    5554:	00812a03          	lw	s4,8(sp)
    5558:	00412a83          	lw	s5,4(sp)
    555c:	02010113          	add	sp,sp,32
    5560:	00008067          	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    5564:	0001aa97          	auipc	s5,0x1a
    5568:	900a8a93          	add	s5,s5,-1792 # 1ee64 <log+0x24>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    556c:	0001aa17          	auipc	s4,0x1a
    5570:	8d4a0a13          	add	s4,s4,-1836 # 1ee40 <log>
    5574:	00ca2583          	lw	a1,12(s4)
    5578:	00b485b3          	add	a1,s1,a1
    557c:	00158593          	add	a1,a1,1
    5580:	01ca2503          	lw	a0,28(s4)
    5584:	ffffe097          	auipc	ra,0xffffe
    5588:	664080e7          	jalr	1636(ra) # 3be8 <bread>
    558c:	00050913          	mv	s2,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    5590:	000aa583          	lw	a1,0(s5)
    5594:	01ca2503          	lw	a0,28(s4)
    5598:	ffffe097          	auipc	ra,0xffffe
    559c:	650080e7          	jalr	1616(ra) # 3be8 <bread>
    55a0:	00050993          	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    55a4:	40000613          	li	a2,1024
    55a8:	03850593          	add	a1,a0,56
    55ac:	03890513          	add	a0,s2,56
    55b0:	ffffc097          	auipc	ra,0xffffc
    55b4:	944080e7          	jalr	-1724(ra) # ef4 <memmove>
    bwrite(to);  // write the log
    55b8:	00090513          	mv	a0,s2
    55bc:	ffffe097          	auipc	ra,0xffffe
    55c0:	76c080e7          	jalr	1900(ra) # 3d28 <bwrite>
    brelse(from);
    55c4:	00098513          	mv	a0,s3
    55c8:	ffffe097          	auipc	ra,0xffffe
    55cc:	7bc080e7          	jalr	1980(ra) # 3d84 <brelse>
    brelse(to);
    55d0:	00090513          	mv	a0,s2
    55d4:	ffffe097          	auipc	ra,0xffffe
    55d8:	7b0080e7          	jalr	1968(ra) # 3d84 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    55dc:	00148493          	add	s1,s1,1
    55e0:	004a8a93          	add	s5,s5,4
    55e4:	020a2783          	lw	a5,32(s4)
    55e8:	f8f4c6e3          	blt	s1,a5,5574 <end_op+0x10c>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    55ec:	00000097          	auipc	ra,0x0
    55f0:	b74080e7          	jalr	-1164(ra) # 5160 <write_head>
    install_trans(); // Now install writes to home locations
    55f4:	00000097          	auipc	ra,0x0
    55f8:	c04080e7          	jalr	-1020(ra) # 51f8 <install_trans>
    log.lh.n = 0;
    55fc:	0001a797          	auipc	a5,0x1a
    5600:	8607a223          	sw	zero,-1948(a5) # 1ee60 <log+0x20>
    write_head();    // Erase the transaction from the log
    5604:	00000097          	auipc	ra,0x0
    5608:	b5c080e7          	jalr	-1188(ra) # 5160 <write_head>
    560c:	ed1ff06f          	j	54dc <end_op+0x74>

00005610 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    5610:	ff010113          	add	sp,sp,-16
    5614:	00112623          	sw	ra,12(sp)
    5618:	00812423          	sw	s0,8(sp)
    561c:	00912223          	sw	s1,4(sp)
    5620:	01212023          	sw	s2,0(sp)
    5624:	01010413          	add	s0,sp,16
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    5628:	0001a717          	auipc	a4,0x1a
    562c:	83872703          	lw	a4,-1992(a4) # 1ee60 <log+0x20>
    5630:	01d00793          	li	a5,29
    5634:	0ae7c263          	blt	a5,a4,56d8 <log_write+0xc8>
    5638:	00050493          	mv	s1,a0
    563c:	0001a797          	auipc	a5,0x1a
    5640:	8147a783          	lw	a5,-2028(a5) # 1ee50 <log+0x10>
    5644:	fff78793          	add	a5,a5,-1
    5648:	08f75863          	bge	a4,a5,56d8 <log_write+0xc8>
    panic("too big a transaction");
  if (log.outstanding < 1)
    564c:	0001a797          	auipc	a5,0x1a
    5650:	8087a783          	lw	a5,-2040(a5) # 1ee54 <log+0x14>
    5654:	08f05a63          	blez	a5,56e8 <log_write+0xd8>
    panic("log_write outside of trans");

  acquire(&log.lock);
    5658:	00019917          	auipc	s2,0x19
    565c:	7e890913          	add	s2,s2,2024 # 1ee40 <log>
    5660:	00090513          	mv	a0,s2
    5664:	ffffb097          	auipc	ra,0xffffb
    5668:	740080e7          	jalr	1856(ra) # da4 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    566c:	02092603          	lw	a2,32(s2)
    5670:	08c05463          	blez	a2,56f8 <log_write+0xe8>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    5674:	00c4a583          	lw	a1,12(s1)
    5678:	00019717          	auipc	a4,0x19
    567c:	7ec70713          	add	a4,a4,2028 # 1ee64 <log+0x24>
  for (i = 0; i < log.lh.n; i++) {
    5680:	00000793          	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    5684:	00072683          	lw	a3,0(a4)
    5688:	06b68a63          	beq	a3,a1,56fc <log_write+0xec>
  for (i = 0; i < log.lh.n; i++) {
    568c:	00178793          	add	a5,a5,1
    5690:	00470713          	add	a4,a4,4
    5694:	fec798e3          	bne	a5,a2,5684 <log_write+0x74>
      break;
  }
  log.lh.block[i] = b->blockno;
    5698:	00860613          	add	a2,a2,8
    569c:	00261613          	sll	a2,a2,0x2
    56a0:	00019797          	auipc	a5,0x19
    56a4:	7a078793          	add	a5,a5,1952 # 1ee40 <log>
    56a8:	00c787b3          	add	a5,a5,a2
    56ac:	00c4a703          	lw	a4,12(s1)
    56b0:	00e7a223          	sw	a4,4(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    56b4:	00048513          	mv	a0,s1
    56b8:	ffffe097          	auipc	ra,0xffffe
    56bc:	79c080e7          	jalr	1948(ra) # 3e54 <bpin>
    log.lh.n++;
    56c0:	00019717          	auipc	a4,0x19
    56c4:	78070713          	add	a4,a4,1920 # 1ee40 <log>
    56c8:	02072783          	lw	a5,32(a4)
    56cc:	00178793          	add	a5,a5,1
    56d0:	02f72023          	sw	a5,32(a4)
    56d4:	0480006f          	j	571c <log_write+0x10c>
    panic("too big a transaction");
    56d8:	00003517          	auipc	a0,0x3
    56dc:	ed850513          	add	a0,a0,-296 # 85b0 <userret+0x510>
    56e0:	ffffb097          	auipc	ra,0xffffb
    56e4:	fac080e7          	jalr	-84(ra) # 68c <panic>
    panic("log_write outside of trans");
    56e8:	00003517          	auipc	a0,0x3
    56ec:	ee050513          	add	a0,a0,-288 # 85c8 <userret+0x528>
    56f0:	ffffb097          	auipc	ra,0xffffb
    56f4:	f9c080e7          	jalr	-100(ra) # 68c <panic>
  for (i = 0; i < log.lh.n; i++) {
    56f8:	00000793          	li	a5,0
  log.lh.block[i] = b->blockno;
    56fc:	00878693          	add	a3,a5,8
    5700:	00269693          	sll	a3,a3,0x2
    5704:	00019717          	auipc	a4,0x19
    5708:	73c70713          	add	a4,a4,1852 # 1ee40 <log>
    570c:	00d70733          	add	a4,a4,a3
    5710:	00c4a683          	lw	a3,12(s1)
    5714:	00d72223          	sw	a3,4(a4)
  if (i == log.lh.n) {  // Add new block to log?
    5718:	f8f60ee3          	beq	a2,a5,56b4 <log_write+0xa4>
  }
  release(&log.lock);
    571c:	00019517          	auipc	a0,0x19
    5720:	72450513          	add	a0,a0,1828 # 1ee40 <log>
    5724:	ffffb097          	auipc	ra,0xffffb
    5728:	6f4080e7          	jalr	1780(ra) # e18 <release>
}
    572c:	00c12083          	lw	ra,12(sp)
    5730:	00812403          	lw	s0,8(sp)
    5734:	00412483          	lw	s1,4(sp)
    5738:	00012903          	lw	s2,0(sp)
    573c:	01010113          	add	sp,sp,16
    5740:	00008067          	ret

00005744 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    5744:	ff010113          	add	sp,sp,-16
    5748:	00112623          	sw	ra,12(sp)
    574c:	00812423          	sw	s0,8(sp)
    5750:	00912223          	sw	s1,4(sp)
    5754:	01212023          	sw	s2,0(sp)
    5758:	01010413          	add	s0,sp,16
    575c:	00050493          	mv	s1,a0
    5760:	00058913          	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    5764:	00003597          	auipc	a1,0x3
    5768:	e8058593          	add	a1,a1,-384 # 85e4 <userret+0x544>
    576c:	00450513          	add	a0,a0,4
    5770:	ffffb097          	auipc	ra,0xffffb
    5774:	4b0080e7          	jalr	1200(ra) # c20 <initlock>
  lk->name = name;
    5778:	0124a823          	sw	s2,16(s1)
  lk->locked = 0;
    577c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    5780:	0004aa23          	sw	zero,20(s1)
}
    5784:	00c12083          	lw	ra,12(sp)
    5788:	00812403          	lw	s0,8(sp)
    578c:	00412483          	lw	s1,4(sp)
    5790:	00012903          	lw	s2,0(sp)
    5794:	01010113          	add	sp,sp,16
    5798:	00008067          	ret

0000579c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    579c:	ff010113          	add	sp,sp,-16
    57a0:	00112623          	sw	ra,12(sp)
    57a4:	00812423          	sw	s0,8(sp)
    57a8:	00912223          	sw	s1,4(sp)
    57ac:	01212023          	sw	s2,0(sp)
    57b0:	01010413          	add	s0,sp,16
    57b4:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    57b8:	00450913          	add	s2,a0,4
    57bc:	00090513          	mv	a0,s2
    57c0:	ffffb097          	auipc	ra,0xffffb
    57c4:	5e4080e7          	jalr	1508(ra) # da4 <acquire>
  while (lk->locked) {
    57c8:	0004a783          	lw	a5,0(s1)
    57cc:	00078e63          	beqz	a5,57e8 <acquiresleep+0x4c>
    sleep(lk, &lk->lk);
    57d0:	00090593          	mv	a1,s2
    57d4:	00048513          	mv	a0,s1
    57d8:	ffffd097          	auipc	ra,0xffffd
    57dc:	33c080e7          	jalr	828(ra) # 2b14 <sleep>
  while (lk->locked) {
    57e0:	0004a783          	lw	a5,0(s1)
    57e4:	fe0796e3          	bnez	a5,57d0 <acquiresleep+0x34>
  }
  lk->locked = 1;
    57e8:	00100793          	li	a5,1
    57ec:	00f4a023          	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    57f0:	ffffd097          	auipc	ra,0xffffd
    57f4:	8e0080e7          	jalr	-1824(ra) # 20d0 <myproc>
    57f8:	02052783          	lw	a5,32(a0)
    57fc:	00f4aa23          	sw	a5,20(s1)
  release(&lk->lk);
    5800:	00090513          	mv	a0,s2
    5804:	ffffb097          	auipc	ra,0xffffb
    5808:	614080e7          	jalr	1556(ra) # e18 <release>
}
    580c:	00c12083          	lw	ra,12(sp)
    5810:	00812403          	lw	s0,8(sp)
    5814:	00412483          	lw	s1,4(sp)
    5818:	00012903          	lw	s2,0(sp)
    581c:	01010113          	add	sp,sp,16
    5820:	00008067          	ret

00005824 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    5824:	ff010113          	add	sp,sp,-16
    5828:	00112623          	sw	ra,12(sp)
    582c:	00812423          	sw	s0,8(sp)
    5830:	00912223          	sw	s1,4(sp)
    5834:	01212023          	sw	s2,0(sp)
    5838:	01010413          	add	s0,sp,16
    583c:	00050493          	mv	s1,a0
  acquire(&lk->lk);
    5840:	00450913          	add	s2,a0,4
    5844:	00090513          	mv	a0,s2
    5848:	ffffb097          	auipc	ra,0xffffb
    584c:	55c080e7          	jalr	1372(ra) # da4 <acquire>
  lk->locked = 0;
    5850:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    5854:	0004aa23          	sw	zero,20(s1)
  wakeup(lk);
    5858:	00048513          	mv	a0,s1
    585c:	ffffd097          	auipc	ra,0xffffd
    5860:	4d4080e7          	jalr	1236(ra) # 2d30 <wakeup>
  release(&lk->lk);
    5864:	00090513          	mv	a0,s2
    5868:	ffffb097          	auipc	ra,0xffffb
    586c:	5b0080e7          	jalr	1456(ra) # e18 <release>
}
    5870:	00c12083          	lw	ra,12(sp)
    5874:	00812403          	lw	s0,8(sp)
    5878:	00412483          	lw	s1,4(sp)
    587c:	00012903          	lw	s2,0(sp)
    5880:	01010113          	add	sp,sp,16
    5884:	00008067          	ret

00005888 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    5888:	fe010113          	add	sp,sp,-32
    588c:	00112e23          	sw	ra,28(sp)
    5890:	00812c23          	sw	s0,24(sp)
    5894:	00912a23          	sw	s1,20(sp)
    5898:	01212823          	sw	s2,16(sp)
    589c:	01312623          	sw	s3,12(sp)
    58a0:	02010413          	add	s0,sp,32
    58a4:	00050493          	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    58a8:	00450913          	add	s2,a0,4
    58ac:	00090513          	mv	a0,s2
    58b0:	ffffb097          	auipc	ra,0xffffb
    58b4:	4f4080e7          	jalr	1268(ra) # da4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    58b8:	0004a783          	lw	a5,0(s1)
    58bc:	02079a63          	bnez	a5,58f0 <holdingsleep+0x68>
    58c0:	00000493          	li	s1,0
  release(&lk->lk);
    58c4:	00090513          	mv	a0,s2
    58c8:	ffffb097          	auipc	ra,0xffffb
    58cc:	550080e7          	jalr	1360(ra) # e18 <release>
  return r;
}
    58d0:	00048513          	mv	a0,s1
    58d4:	01c12083          	lw	ra,28(sp)
    58d8:	01812403          	lw	s0,24(sp)
    58dc:	01412483          	lw	s1,20(sp)
    58e0:	01012903          	lw	s2,16(sp)
    58e4:	00c12983          	lw	s3,12(sp)
    58e8:	02010113          	add	sp,sp,32
    58ec:	00008067          	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    58f0:	0144a983          	lw	s3,20(s1)
    58f4:	ffffc097          	auipc	ra,0xffffc
    58f8:	7dc080e7          	jalr	2012(ra) # 20d0 <myproc>
    58fc:	02052483          	lw	s1,32(a0)
    5900:	413484b3          	sub	s1,s1,s3
    5904:	0014b493          	seqz	s1,s1
    5908:	fbdff06f          	j	58c4 <holdingsleep+0x3c>

0000590c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    590c:	ff010113          	add	sp,sp,-16
    5910:	00112623          	sw	ra,12(sp)
    5914:	00812423          	sw	s0,8(sp)
    5918:	01010413          	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    591c:	00003597          	auipc	a1,0x3
    5920:	cd458593          	add	a1,a1,-812 # 85f0 <userret+0x550>
    5924:	00019517          	auipc	a0,0x19
    5928:	60850513          	add	a0,a0,1544 # 1ef2c <ftable>
    592c:	ffffb097          	auipc	ra,0xffffb
    5930:	2f4080e7          	jalr	756(ra) # c20 <initlock>
}
    5934:	00c12083          	lw	ra,12(sp)
    5938:	00812403          	lw	s0,8(sp)
    593c:	01010113          	add	sp,sp,16
    5940:	00008067          	ret

00005944 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    5944:	ff010113          	add	sp,sp,-16
    5948:	00112623          	sw	ra,12(sp)
    594c:	00812423          	sw	s0,8(sp)
    5950:	00912223          	sw	s1,4(sp)
    5954:	01010413          	add	s0,sp,16
  struct file *f;

  acquire(&ftable.lock);
    5958:	00019517          	auipc	a0,0x19
    595c:	5d450513          	add	a0,a0,1492 # 1ef2c <ftable>
    5960:	ffffb097          	auipc	ra,0xffffb
    5964:	444080e7          	jalr	1092(ra) # da4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    5968:	00019497          	auipc	s1,0x19
    596c:	5d048493          	add	s1,s1,1488 # 1ef38 <ftable+0xc>
    5970:	0001a717          	auipc	a4,0x1a
    5974:	0b870713          	add	a4,a4,184 # 1fa28 <ftable+0xafc>
    if(f->ref == 0){
    5978:	0044a783          	lw	a5,4(s1)
    597c:	02078263          	beqz	a5,59a0 <filealloc+0x5c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    5980:	01c48493          	add	s1,s1,28
    5984:	fee49ae3          	bne	s1,a4,5978 <filealloc+0x34>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    5988:	00019517          	auipc	a0,0x19
    598c:	5a450513          	add	a0,a0,1444 # 1ef2c <ftable>
    5990:	ffffb097          	auipc	ra,0xffffb
    5994:	488080e7          	jalr	1160(ra) # e18 <release>
  return 0;
    5998:	00000493          	li	s1,0
    599c:	01c0006f          	j	59b8 <filealloc+0x74>
      f->ref = 1;
    59a0:	00100793          	li	a5,1
    59a4:	00f4a223          	sw	a5,4(s1)
      release(&ftable.lock);
    59a8:	00019517          	auipc	a0,0x19
    59ac:	58450513          	add	a0,a0,1412 # 1ef2c <ftable>
    59b0:	ffffb097          	auipc	ra,0xffffb
    59b4:	468080e7          	jalr	1128(ra) # e18 <release>
}
    59b8:	00048513          	mv	a0,s1
    59bc:	00c12083          	lw	ra,12(sp)
    59c0:	00812403          	lw	s0,8(sp)
    59c4:	00412483          	lw	s1,4(sp)
    59c8:	01010113          	add	sp,sp,16
    59cc:	00008067          	ret

000059d0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    59d0:	ff010113          	add	sp,sp,-16
    59d4:	00112623          	sw	ra,12(sp)
    59d8:	00812423          	sw	s0,8(sp)
    59dc:	00912223          	sw	s1,4(sp)
    59e0:	01010413          	add	s0,sp,16
    59e4:	00050493          	mv	s1,a0
  acquire(&ftable.lock);
    59e8:	00019517          	auipc	a0,0x19
    59ec:	54450513          	add	a0,a0,1348 # 1ef2c <ftable>
    59f0:	ffffb097          	auipc	ra,0xffffb
    59f4:	3b4080e7          	jalr	948(ra) # da4 <acquire>
  if(f->ref < 1)
    59f8:	0044a783          	lw	a5,4(s1)
    59fc:	02f05a63          	blez	a5,5a30 <filedup+0x60>
    panic("filedup");
  f->ref++;
    5a00:	00178793          	add	a5,a5,1
    5a04:	00f4a223          	sw	a5,4(s1)
  release(&ftable.lock);
    5a08:	00019517          	auipc	a0,0x19
    5a0c:	52450513          	add	a0,a0,1316 # 1ef2c <ftable>
    5a10:	ffffb097          	auipc	ra,0xffffb
    5a14:	408080e7          	jalr	1032(ra) # e18 <release>
  return f;
}
    5a18:	00048513          	mv	a0,s1
    5a1c:	00c12083          	lw	ra,12(sp)
    5a20:	00812403          	lw	s0,8(sp)
    5a24:	00412483          	lw	s1,4(sp)
    5a28:	01010113          	add	sp,sp,16
    5a2c:	00008067          	ret
    panic("filedup");
    5a30:	00003517          	auipc	a0,0x3
    5a34:	bc850513          	add	a0,a0,-1080 # 85f8 <userret+0x558>
    5a38:	ffffb097          	auipc	ra,0xffffb
    5a3c:	c54080e7          	jalr	-940(ra) # 68c <panic>

00005a40 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    5a40:	fe010113          	add	sp,sp,-32
    5a44:	00112e23          	sw	ra,28(sp)
    5a48:	00812c23          	sw	s0,24(sp)
    5a4c:	00912a23          	sw	s1,20(sp)
    5a50:	01212823          	sw	s2,16(sp)
    5a54:	01312623          	sw	s3,12(sp)
    5a58:	01412423          	sw	s4,8(sp)
    5a5c:	01512223          	sw	s5,4(sp)
    5a60:	02010413          	add	s0,sp,32
    5a64:	00050493          	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    5a68:	00019517          	auipc	a0,0x19
    5a6c:	4c450513          	add	a0,a0,1220 # 1ef2c <ftable>
    5a70:	ffffb097          	auipc	ra,0xffffb
    5a74:	334080e7          	jalr	820(ra) # da4 <acquire>
  if(f->ref < 1)
    5a78:	0044a783          	lw	a5,4(s1)
    5a7c:	06f05663          	blez	a5,5ae8 <fileclose+0xa8>
    panic("fileclose");
  if(--f->ref > 0){
    5a80:	fff78793          	add	a5,a5,-1
    5a84:	00f4a223          	sw	a5,4(s1)
    5a88:	06f04863          	bgtz	a5,5af8 <fileclose+0xb8>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    5a8c:	0004a903          	lw	s2,0(s1)
    5a90:	0094ca83          	lbu	s5,9(s1)
    5a94:	00c4aa03          	lw	s4,12(s1)
    5a98:	0104a983          	lw	s3,16(s1)
  f->ref = 0;
    5a9c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    5aa0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    5aa4:	00019517          	auipc	a0,0x19
    5aa8:	48850513          	add	a0,a0,1160 # 1ef2c <ftable>
    5aac:	ffffb097          	auipc	ra,0xffffb
    5ab0:	36c080e7          	jalr	876(ra) # e18 <release>

  if(ff.type == FD_PIPE){
    5ab4:	00100793          	li	a5,1
    5ab8:	06f90a63          	beq	s2,a5,5b2c <fileclose+0xec>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    5abc:	ffe90913          	add	s2,s2,-2
    5ac0:	00100793          	li	a5,1
    5ac4:	0527e263          	bltu	a5,s2,5b08 <fileclose+0xc8>
    begin_op();
    5ac8:	00000097          	auipc	ra,0x0
    5acc:	8f0080e7          	jalr	-1808(ra) # 53b8 <begin_op>
    iput(ff.ip);
    5ad0:	00098513          	mv	a0,s3
    5ad4:	fffff097          	auipc	ra,0xfffff
    5ad8:	d2c080e7          	jalr	-724(ra) # 4800 <iput>
    end_op();
    5adc:	00000097          	auipc	ra,0x0
    5ae0:	98c080e7          	jalr	-1652(ra) # 5468 <end_op>
    5ae4:	0240006f          	j	5b08 <fileclose+0xc8>
    panic("fileclose");
    5ae8:	00003517          	auipc	a0,0x3
    5aec:	b1850513          	add	a0,a0,-1256 # 8600 <userret+0x560>
    5af0:	ffffb097          	auipc	ra,0xffffb
    5af4:	b9c080e7          	jalr	-1124(ra) # 68c <panic>
    release(&ftable.lock);
    5af8:	00019517          	auipc	a0,0x19
    5afc:	43450513          	add	a0,a0,1076 # 1ef2c <ftable>
    5b00:	ffffb097          	auipc	ra,0xffffb
    5b04:	318080e7          	jalr	792(ra) # e18 <release>
  }
}
    5b08:	01c12083          	lw	ra,28(sp)
    5b0c:	01812403          	lw	s0,24(sp)
    5b10:	01412483          	lw	s1,20(sp)
    5b14:	01012903          	lw	s2,16(sp)
    5b18:	00c12983          	lw	s3,12(sp)
    5b1c:	00812a03          	lw	s4,8(sp)
    5b20:	00412a83          	lw	s5,4(sp)
    5b24:	02010113          	add	sp,sp,32
    5b28:	00008067          	ret
    pipeclose(ff.pipe, ff.writable);
    5b2c:	000a8593          	mv	a1,s5
    5b30:	000a0513          	mv	a0,s4
    5b34:	00000097          	auipc	ra,0x0
    5b38:	4cc080e7          	jalr	1228(ra) # 6000 <pipeclose>
    5b3c:	fcdff06f          	j	5b08 <fileclose+0xc8>

00005b40 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint32 addr)
{
    5b40:	fc010113          	add	sp,sp,-64
    5b44:	02112e23          	sw	ra,60(sp)
    5b48:	02812c23          	sw	s0,56(sp)
    5b4c:	02912a23          	sw	s1,52(sp)
    5b50:	03212823          	sw	s2,48(sp)
    5b54:	03312623          	sw	s3,44(sp)
    5b58:	04010413          	add	s0,sp,64
    5b5c:	00050493          	mv	s1,a0
    5b60:	00058993          	mv	s3,a1
  struct proc *p = myproc();
    5b64:	ffffc097          	auipc	ra,0xffffc
    5b68:	56c080e7          	jalr	1388(ra) # 20d0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    5b6c:	0004a783          	lw	a5,0(s1)
    5b70:	ffe78793          	add	a5,a5,-2
    5b74:	00100713          	li	a4,1
    5b78:	06f76463          	bltu	a4,a5,5be0 <filestat+0xa0>
    5b7c:	00050913          	mv	s2,a0
    ilock(f->ip);
    5b80:	0104a503          	lw	a0,16(s1)
    5b84:	fffff097          	auipc	ra,0xfffff
    5b88:	b08080e7          	jalr	-1272(ra) # 468c <ilock>
    stati(f->ip, &st);
    5b8c:	fc840593          	add	a1,s0,-56
    5b90:	0104a503          	lw	a0,16(s1)
    5b94:	fffff097          	auipc	ra,0xfffff
    5b98:	e3c080e7          	jalr	-452(ra) # 49d0 <stati>
    iunlock(f->ip);
    5b9c:	0104a503          	lw	a0,16(s1)
    5ba0:	fffff097          	auipc	ra,0xfffff
    5ba4:	bf0080e7          	jalr	-1040(ra) # 4790 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    5ba8:	01800693          	li	a3,24
    5bac:	fc840613          	add	a2,s0,-56
    5bb0:	00098593          	mv	a1,s3
    5bb4:	02c92503          	lw	a0,44(s2)
    5bb8:	ffffc097          	auipc	ra,0xffffc
    5bbc:	06c080e7          	jalr	108(ra) # 1c24 <copyout>
    5bc0:	41f55513          	sra	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    5bc4:	03c12083          	lw	ra,60(sp)
    5bc8:	03812403          	lw	s0,56(sp)
    5bcc:	03412483          	lw	s1,52(sp)
    5bd0:	03012903          	lw	s2,48(sp)
    5bd4:	02c12983          	lw	s3,44(sp)
    5bd8:	04010113          	add	sp,sp,64
    5bdc:	00008067          	ret
  return -1;
    5be0:	fff00513          	li	a0,-1
    5be4:	fe1ff06f          	j	5bc4 <filestat+0x84>

00005be8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint32 addr, int n)
{
    5be8:	fe010113          	add	sp,sp,-32
    5bec:	00112e23          	sw	ra,28(sp)
    5bf0:	00812c23          	sw	s0,24(sp)
    5bf4:	00912a23          	sw	s1,20(sp)
    5bf8:	01212823          	sw	s2,16(sp)
    5bfc:	01312623          	sw	s3,12(sp)
    5c00:	02010413          	add	s0,sp,32
  int r = 0;

  if(f->readable == 0)
    5c04:	00854783          	lbu	a5,8(a0)
    5c08:	0e078a63          	beqz	a5,5cfc <fileread+0x114>
    5c0c:	00050493          	mv	s1,a0
    5c10:	00058993          	mv	s3,a1
    5c14:	00060913          	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    5c18:	00052783          	lw	a5,0(a0)
    5c1c:	00100713          	li	a4,1
    5c20:	06e78e63          	beq	a5,a4,5c9c <fileread+0xb4>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    5c24:	00300713          	li	a4,3
    5c28:	08e78463          	beq	a5,a4,5cb0 <fileread+0xc8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    5c2c:	00200713          	li	a4,2
    5c30:	0ae79e63          	bne	a5,a4,5cec <fileread+0x104>
    ilock(f->ip);
    5c34:	01052503          	lw	a0,16(a0)
    5c38:	fffff097          	auipc	ra,0xfffff
    5c3c:	a54080e7          	jalr	-1452(ra) # 468c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    5c40:	00090713          	mv	a4,s2
    5c44:	0144a683          	lw	a3,20(s1)
    5c48:	00098613          	mv	a2,s3
    5c4c:	00100593          	li	a1,1
    5c50:	0104a503          	lw	a0,16(s1)
    5c54:	fffff097          	auipc	ra,0xfffff
    5c58:	dc0080e7          	jalr	-576(ra) # 4a14 <readi>
    5c5c:	00050913          	mv	s2,a0
    5c60:	00a05863          	blez	a0,5c70 <fileread+0x88>
      f->off += r;
    5c64:	0144a783          	lw	a5,20(s1)
    5c68:	00a787b3          	add	a5,a5,a0
    5c6c:	00f4aa23          	sw	a5,20(s1)
    iunlock(f->ip);
    5c70:	0104a503          	lw	a0,16(s1)
    5c74:	fffff097          	auipc	ra,0xfffff
    5c78:	b1c080e7          	jalr	-1252(ra) # 4790 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    5c7c:	00090513          	mv	a0,s2
    5c80:	01c12083          	lw	ra,28(sp)
    5c84:	01812403          	lw	s0,24(sp)
    5c88:	01412483          	lw	s1,20(sp)
    5c8c:	01012903          	lw	s2,16(sp)
    5c90:	00c12983          	lw	s3,12(sp)
    5c94:	02010113          	add	sp,sp,32
    5c98:	00008067          	ret
    r = piperead(f->pipe, addr, n);
    5c9c:	00c52503          	lw	a0,12(a0)
    5ca0:	00000097          	auipc	ra,0x0
    5ca4:	554080e7          	jalr	1364(ra) # 61f4 <piperead>
    5ca8:	00050913          	mv	s2,a0
    5cac:	fd1ff06f          	j	5c7c <fileread+0x94>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    5cb0:	01851783          	lh	a5,24(a0)
    5cb4:	01079693          	sll	a3,a5,0x10
    5cb8:	0106d693          	srl	a3,a3,0x10
    5cbc:	00900713          	li	a4,9
    5cc0:	04d76263          	bltu	a4,a3,5d04 <fileread+0x11c>
    5cc4:	00379793          	sll	a5,a5,0x3
    5cc8:	00019717          	auipc	a4,0x19
    5ccc:	21470713          	add	a4,a4,532 # 1eedc <devsw>
    5cd0:	00f707b3          	add	a5,a4,a5
    5cd4:	0007a783          	lw	a5,0(a5)
    5cd8:	02078a63          	beqz	a5,5d0c <fileread+0x124>
    r = devsw[f->major].read(1, addr, n);
    5cdc:	00100513          	li	a0,1
    5ce0:	000780e7          	jalr	a5
    5ce4:	00050913          	mv	s2,a0
    5ce8:	f95ff06f          	j	5c7c <fileread+0x94>
    panic("fileread");
    5cec:	00003517          	auipc	a0,0x3
    5cf0:	92050513          	add	a0,a0,-1760 # 860c <userret+0x56c>
    5cf4:	ffffb097          	auipc	ra,0xffffb
    5cf8:	998080e7          	jalr	-1640(ra) # 68c <panic>
    return -1;
    5cfc:	fff00913          	li	s2,-1
    5d00:	f7dff06f          	j	5c7c <fileread+0x94>
      return -1;
    5d04:	fff00913          	li	s2,-1
    5d08:	f75ff06f          	j	5c7c <fileread+0x94>
    5d0c:	fff00913          	li	s2,-1
    5d10:	f6dff06f          	j	5c7c <fileread+0x94>

00005d14 <filewrite>:
int
filewrite(struct file *f, uint32 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    5d14:	00954783          	lbu	a5,9(a0)
    5d18:	18078e63          	beqz	a5,5eb4 <filewrite+0x1a0>
{
    5d1c:	fd010113          	add	sp,sp,-48
    5d20:	02112623          	sw	ra,44(sp)
    5d24:	02812423          	sw	s0,40(sp)
    5d28:	02912223          	sw	s1,36(sp)
    5d2c:	03212023          	sw	s2,32(sp)
    5d30:	01312e23          	sw	s3,28(sp)
    5d34:	01412c23          	sw	s4,24(sp)
    5d38:	01512a23          	sw	s5,20(sp)
    5d3c:	01612823          	sw	s6,16(sp)
    5d40:	01712623          	sw	s7,12(sp)
    5d44:	03010413          	add	s0,sp,48
    5d48:	00050913          	mv	s2,a0
    5d4c:	00058b93          	mv	s7,a1
    5d50:	00060a93          	mv	s5,a2
    return -1;

  if(f->type == FD_PIPE){
    5d54:	00052783          	lw	a5,0(a0)
    5d58:	00100713          	li	a4,1
    5d5c:	02e78463          	beq	a5,a4,5d84 <filewrite+0x70>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    5d60:	00300713          	li	a4,3
    5d64:	02e78863          	beq	a5,a4,5d94 <filewrite+0x80>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    5d68:	00200713          	li	a4,2
    5d6c:	12e79c63          	bne	a5,a4,5ea4 <filewrite+0x190>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    5d70:	12c05663          	blez	a2,5e9c <filewrite+0x188>
    int i = 0;
    5d74:	00000993          	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    5d78:	00001b37          	lui	s6,0x1
    5d7c:	c00b0b13          	add	s6,s6,-1024 # c00 <kalloc+0x68>
    5d80:	0b00006f          	j	5e30 <filewrite+0x11c>
    ret = pipewrite(f->pipe, addr, n);
    5d84:	00c52503          	lw	a0,12(a0)
    5d88:	00000097          	auipc	ra,0x0
    5d8c:	318080e7          	jalr	792(ra) # 60a0 <pipewrite>
    5d90:	0d00006f          	j	5e60 <filewrite+0x14c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    5d94:	01851783          	lh	a5,24(a0)
    5d98:	01079693          	sll	a3,a5,0x10
    5d9c:	0106d693          	srl	a3,a3,0x10
    5da0:	00900713          	li	a4,9
    5da4:	10d76c63          	bltu	a4,a3,5ebc <filewrite+0x1a8>
    5da8:	00379793          	sll	a5,a5,0x3
    5dac:	00019717          	auipc	a4,0x19
    5db0:	13070713          	add	a4,a4,304 # 1eedc <devsw>
    5db4:	00f707b3          	add	a5,a4,a5
    5db8:	0047a783          	lw	a5,4(a5)
    5dbc:	10078463          	beqz	a5,5ec4 <filewrite+0x1b0>
    ret = devsw[f->major].write(1, addr, n);
    5dc0:	00100513          	li	a0,1
    5dc4:	000780e7          	jalr	a5
    5dc8:	0980006f          	j	5e60 <filewrite+0x14c>
        n1 = max;

      begin_op();
    5dcc:	fffff097          	auipc	ra,0xfffff
    5dd0:	5ec080e7          	jalr	1516(ra) # 53b8 <begin_op>
      ilock(f->ip);
    5dd4:	01092503          	lw	a0,16(s2)
    5dd8:	fffff097          	auipc	ra,0xfffff
    5ddc:	8b4080e7          	jalr	-1868(ra) # 468c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    5de0:	000a0713          	mv	a4,s4
    5de4:	01492683          	lw	a3,20(s2)
    5de8:	01798633          	add	a2,s3,s7
    5dec:	00100593          	li	a1,1
    5df0:	01092503          	lw	a0,16(s2)
    5df4:	fffff097          	auipc	ra,0xfffff
    5df8:	d6c080e7          	jalr	-660(ra) # 4b60 <writei>
    5dfc:	00050493          	mv	s1,a0
    5e00:	04a05063          	blez	a0,5e40 <filewrite+0x12c>
        f->off += r;
    5e04:	01492783          	lw	a5,20(s2)
    5e08:	00a787b3          	add	a5,a5,a0
    5e0c:	00f92a23          	sw	a5,20(s2)
      iunlock(f->ip);
    5e10:	01092503          	lw	a0,16(s2)
    5e14:	fffff097          	auipc	ra,0xfffff
    5e18:	97c080e7          	jalr	-1668(ra) # 4790 <iunlock>
      end_op();
    5e1c:	fffff097          	auipc	ra,0xfffff
    5e20:	64c080e7          	jalr	1612(ra) # 5468 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    5e24:	069a1463          	bne	s4,s1,5e8c <filewrite+0x178>
        panic("short filewrite");
      i += r;
    5e28:	009989b3          	add	s3,s3,s1
    while(i < n){
    5e2c:	0359d663          	bge	s3,s5,5e58 <filewrite+0x144>
      int n1 = n - i;
    5e30:	413a8a33          	sub	s4,s5,s3
      if(n1 > max)
    5e34:	f94b5ce3          	bge	s6,s4,5dcc <filewrite+0xb8>
    5e38:	000b0a13          	mv	s4,s6
    5e3c:	f91ff06f          	j	5dcc <filewrite+0xb8>
      iunlock(f->ip);
    5e40:	01092503          	lw	a0,16(s2)
    5e44:	fffff097          	auipc	ra,0xfffff
    5e48:	94c080e7          	jalr	-1716(ra) # 4790 <iunlock>
      end_op();
    5e4c:	fffff097          	auipc	ra,0xfffff
    5e50:	61c080e7          	jalr	1564(ra) # 5468 <end_op>
      if(r < 0)
    5e54:	fc04d8e3          	bgez	s1,5e24 <filewrite+0x110>
    }
    ret = (i == n ? n : -1);
    5e58:	073a9a63          	bne	s5,s3,5ecc <filewrite+0x1b8>
    5e5c:	000a8513          	mv	a0,s5
  } else {
    panic("filewrite");
  }

  return ret;
}
    5e60:	02c12083          	lw	ra,44(sp)
    5e64:	02812403          	lw	s0,40(sp)
    5e68:	02412483          	lw	s1,36(sp)
    5e6c:	02012903          	lw	s2,32(sp)
    5e70:	01c12983          	lw	s3,28(sp)
    5e74:	01812a03          	lw	s4,24(sp)
    5e78:	01412a83          	lw	s5,20(sp)
    5e7c:	01012b03          	lw	s6,16(sp)
    5e80:	00c12b83          	lw	s7,12(sp)
    5e84:	03010113          	add	sp,sp,48
    5e88:	00008067          	ret
        panic("short filewrite");
    5e8c:	00002517          	auipc	a0,0x2
    5e90:	78c50513          	add	a0,a0,1932 # 8618 <userret+0x578>
    5e94:	ffffa097          	auipc	ra,0xffffa
    5e98:	7f8080e7          	jalr	2040(ra) # 68c <panic>
    int i = 0;
    5e9c:	00000993          	li	s3,0
    5ea0:	fb9ff06f          	j	5e58 <filewrite+0x144>
    panic("filewrite");
    5ea4:	00002517          	auipc	a0,0x2
    5ea8:	78450513          	add	a0,a0,1924 # 8628 <userret+0x588>
    5eac:	ffffa097          	auipc	ra,0xffffa
    5eb0:	7e0080e7          	jalr	2016(ra) # 68c <panic>
    return -1;
    5eb4:	fff00513          	li	a0,-1
}
    5eb8:	00008067          	ret
      return -1;
    5ebc:	fff00513          	li	a0,-1
    5ec0:	fa1ff06f          	j	5e60 <filewrite+0x14c>
    5ec4:	fff00513          	li	a0,-1
    5ec8:	f99ff06f          	j	5e60 <filewrite+0x14c>
    ret = (i == n ? n : -1);
    5ecc:	fff00513          	li	a0,-1
    5ed0:	f91ff06f          	j	5e60 <filewrite+0x14c>

00005ed4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    5ed4:	fe010113          	add	sp,sp,-32
    5ed8:	00112e23          	sw	ra,28(sp)
    5edc:	00812c23          	sw	s0,24(sp)
    5ee0:	00912a23          	sw	s1,20(sp)
    5ee4:	01212823          	sw	s2,16(sp)
    5ee8:	01312623          	sw	s3,12(sp)
    5eec:	01412423          	sw	s4,8(sp)
    5ef0:	02010413          	add	s0,sp,32
    5ef4:	00050493          	mv	s1,a0
    5ef8:	00058a13          	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    5efc:	0005a023          	sw	zero,0(a1)
    5f00:	00052023          	sw	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    5f04:	00000097          	auipc	ra,0x0
    5f08:	a40080e7          	jalr	-1472(ra) # 5944 <filealloc>
    5f0c:	00a4a023          	sw	a0,0(s1)
    5f10:	0a050663          	beqz	a0,5fbc <pipealloc+0xe8>
    5f14:	00000097          	auipc	ra,0x0
    5f18:	a30080e7          	jalr	-1488(ra) # 5944 <filealloc>
    5f1c:	00aa2023          	sw	a0,0(s4)
    5f20:	08050663          	beqz	a0,5fac <pipealloc+0xd8>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    5f24:	ffffb097          	auipc	ra,0xffffb
    5f28:	c74080e7          	jalr	-908(ra) # b98 <kalloc>
    5f2c:	00050913          	mv	s2,a0
    5f30:	06050863          	beqz	a0,5fa0 <pipealloc+0xcc>
    goto bad;
  pi->readopen = 1;
    5f34:	00100993          	li	s3,1
    5f38:	21352a23          	sw	s3,532(a0)
  pi->writeopen = 1;
    5f3c:	21352c23          	sw	s3,536(a0)
  pi->nwrite = 0;
    5f40:	20052823          	sw	zero,528(a0)
  pi->nread = 0;
    5f44:	20052623          	sw	zero,524(a0)
  initlock(&pi->lock, "pipe");
    5f48:	00002597          	auipc	a1,0x2
    5f4c:	6ec58593          	add	a1,a1,1772 # 8634 <userret+0x594>
    5f50:	ffffb097          	auipc	ra,0xffffb
    5f54:	cd0080e7          	jalr	-816(ra) # c20 <initlock>
  (*f0)->type = FD_PIPE;
    5f58:	0004a783          	lw	a5,0(s1)
    5f5c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    5f60:	0004a783          	lw	a5,0(s1)
    5f64:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    5f68:	0004a783          	lw	a5,0(s1)
    5f6c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    5f70:	0004a783          	lw	a5,0(s1)
    5f74:	0127a623          	sw	s2,12(a5)
  (*f1)->type = FD_PIPE;
    5f78:	000a2783          	lw	a5,0(s4)
    5f7c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    5f80:	000a2783          	lw	a5,0(s4)
    5f84:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    5f88:	000a2783          	lw	a5,0(s4)
    5f8c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    5f90:	000a2783          	lw	a5,0(s4)
    5f94:	0127a623          	sw	s2,12(a5)
  return 0;
    5f98:	00000513          	li	a0,0
    5f9c:	03c0006f          	j	5fd8 <pipealloc+0x104>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    5fa0:	0004a503          	lw	a0,0(s1)
    5fa4:	00051863          	bnez	a0,5fb4 <pipealloc+0xe0>
    5fa8:	0140006f          	j	5fbc <pipealloc+0xe8>
    5fac:	0004a503          	lw	a0,0(s1)
    5fb0:	04050463          	beqz	a0,5ff8 <pipealloc+0x124>
    fileclose(*f0);
    5fb4:	00000097          	auipc	ra,0x0
    5fb8:	a8c080e7          	jalr	-1396(ra) # 5a40 <fileclose>
  if(*f1)
    5fbc:	000a2783          	lw	a5,0(s4)
    fileclose(*f1);
  return -1;
    5fc0:	fff00513          	li	a0,-1
  if(*f1)
    5fc4:	00078a63          	beqz	a5,5fd8 <pipealloc+0x104>
    fileclose(*f1);
    5fc8:	00078513          	mv	a0,a5
    5fcc:	00000097          	auipc	ra,0x0
    5fd0:	a74080e7          	jalr	-1420(ra) # 5a40 <fileclose>
  return -1;
    5fd4:	fff00513          	li	a0,-1
}
    5fd8:	01c12083          	lw	ra,28(sp)
    5fdc:	01812403          	lw	s0,24(sp)
    5fe0:	01412483          	lw	s1,20(sp)
    5fe4:	01012903          	lw	s2,16(sp)
    5fe8:	00c12983          	lw	s3,12(sp)
    5fec:	00812a03          	lw	s4,8(sp)
    5ff0:	02010113          	add	sp,sp,32
    5ff4:	00008067          	ret
  return -1;
    5ff8:	fff00513          	li	a0,-1
    5ffc:	fddff06f          	j	5fd8 <pipealloc+0x104>

00006000 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    6000:	ff010113          	add	sp,sp,-16
    6004:	00112623          	sw	ra,12(sp)
    6008:	00812423          	sw	s0,8(sp)
    600c:	00912223          	sw	s1,4(sp)
    6010:	01212023          	sw	s2,0(sp)
    6014:	01010413          	add	s0,sp,16
    6018:	00050493          	mv	s1,a0
    601c:	00058913          	mv	s2,a1
  acquire(&pi->lock);
    6020:	ffffb097          	auipc	ra,0xffffb
    6024:	d84080e7          	jalr	-636(ra) # da4 <acquire>
  if(writable){
    6028:	04090463          	beqz	s2,6070 <pipeclose+0x70>
    pi->writeopen = 0;
    602c:	2004ac23          	sw	zero,536(s1)
    wakeup(&pi->nread);
    6030:	20c48513          	add	a0,s1,524
    6034:	ffffd097          	auipc	ra,0xffffd
    6038:	cfc080e7          	jalr	-772(ra) # 2d30 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    603c:	2144a783          	lw	a5,532(s1)
    6040:	00079663          	bnez	a5,604c <pipeclose+0x4c>
    6044:	2184a783          	lw	a5,536(s1)
    6048:	02078e63          	beqz	a5,6084 <pipeclose+0x84>
    release(&pi->lock);
    kfree((char*)pi);
  } else
    release(&pi->lock);
    604c:	00048513          	mv	a0,s1
    6050:	ffffb097          	auipc	ra,0xffffb
    6054:	dc8080e7          	jalr	-568(ra) # e18 <release>
}
    6058:	00c12083          	lw	ra,12(sp)
    605c:	00812403          	lw	s0,8(sp)
    6060:	00412483          	lw	s1,4(sp)
    6064:	00012903          	lw	s2,0(sp)
    6068:	01010113          	add	sp,sp,16
    606c:	00008067          	ret
    pi->readopen = 0;
    6070:	2004aa23          	sw	zero,532(s1)
    wakeup(&pi->nwrite);
    6074:	21048513          	add	a0,s1,528
    6078:	ffffd097          	auipc	ra,0xffffd
    607c:	cb8080e7          	jalr	-840(ra) # 2d30 <wakeup>
    6080:	fbdff06f          	j	603c <pipeclose+0x3c>
    release(&pi->lock);
    6084:	00048513          	mv	a0,s1
    6088:	ffffb097          	auipc	ra,0xffffb
    608c:	d90080e7          	jalr	-624(ra) # e18 <release>
    kfree((char*)pi);
    6090:	00048513          	mv	a0,s1
    6094:	ffffb097          	auipc	ra,0xffffb
    6098:	9b0080e7          	jalr	-1616(ra) # a44 <kfree>
    609c:	fbdff06f          	j	6058 <pipeclose+0x58>

000060a0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint32 addr, int n)
{
    60a0:	fc010113          	add	sp,sp,-64
    60a4:	02112e23          	sw	ra,60(sp)
    60a8:	02812c23          	sw	s0,56(sp)
    60ac:	02912a23          	sw	s1,52(sp)
    60b0:	03212823          	sw	s2,48(sp)
    60b4:	03312623          	sw	s3,44(sp)
    60b8:	03412423          	sw	s4,40(sp)
    60bc:	03512223          	sw	s5,36(sp)
    60c0:	03612023          	sw	s6,32(sp)
    60c4:	01712e23          	sw	s7,28(sp)
    60c8:	04010413          	add	s0,sp,64
    60cc:	00050493          	mv	s1,a0
    60d0:	00058a93          	mv	s5,a1
    60d4:	00060a13          	mv	s4,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    60d8:	ffffc097          	auipc	ra,0xffffc
    60dc:	ff8080e7          	jalr	-8(ra) # 20d0 <myproc>
    60e0:	00050b13          	mv	s6,a0

  acquire(&pi->lock);
    60e4:	00048513          	mv	a0,s1
    60e8:	ffffb097          	auipc	ra,0xffffb
    60ec:	cbc080e7          	jalr	-836(ra) # da4 <acquire>
  for(i = 0; i < n; i++){
    60f0:	0b405463          	blez	s4,6198 <pipewrite+0xf8>
    60f4:	015a0bb3          	add	s7,s4,s5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    60f8:	20c48993          	add	s3,s1,524
      sleep(&pi->nwrite, &pi->lock);
    60fc:	21048913          	add	s2,s1,528
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    6100:	20c4a783          	lw	a5,524(s1)
    6104:	20078793          	add	a5,a5,512
    6108:	2104a703          	lw	a4,528(s1)
    610c:	04f71463          	bne	a4,a5,6154 <pipewrite+0xb4>
      if(pi->readopen == 0 || myproc()->killed){
    6110:	2144a783          	lw	a5,532(s1)
    6114:	0a078263          	beqz	a5,61b8 <pipewrite+0x118>
    6118:	ffffc097          	auipc	ra,0xffffc
    611c:	fb8080e7          	jalr	-72(ra) # 20d0 <myproc>
    6120:	01852783          	lw	a5,24(a0)
    6124:	08079a63          	bnez	a5,61b8 <pipewrite+0x118>
      wakeup(&pi->nread);
    6128:	00098513          	mv	a0,s3
    612c:	ffffd097          	auipc	ra,0xffffd
    6130:	c04080e7          	jalr	-1020(ra) # 2d30 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    6134:	00048593          	mv	a1,s1
    6138:	00090513          	mv	a0,s2
    613c:	ffffd097          	auipc	ra,0xffffd
    6140:	9d8080e7          	jalr	-1576(ra) # 2b14 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    6144:	20c4a783          	lw	a5,524(s1)
    6148:	20078793          	add	a5,a5,512
    614c:	2104a703          	lw	a4,528(s1)
    6150:	fcf700e3          	beq	a4,a5,6110 <pipewrite+0x70>
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    6154:	00100693          	li	a3,1
    6158:	000a8613          	mv	a2,s5
    615c:	fcf40593          	add	a1,s0,-49
    6160:	02cb2503          	lw	a0,44(s6)
    6164:	ffffc097          	auipc	ra,0xffffc
    6168:	ba8080e7          	jalr	-1112(ra) # 1d0c <copyin>
    616c:	fff00793          	li	a5,-1
    6170:	02f50463          	beq	a0,a5,6198 <pipewrite+0xf8>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    6174:	2104a783          	lw	a5,528(s1)
    6178:	00178713          	add	a4,a5,1
    617c:	20e4a823          	sw	a4,528(s1)
    6180:	1ff7f793          	and	a5,a5,511
    6184:	00f487b3          	add	a5,s1,a5
    6188:	fcf44703          	lbu	a4,-49(s0)
    618c:	00e78623          	sb	a4,12(a5)
  for(i = 0; i < n; i++){
    6190:	001a8a93          	add	s5,s5,1
    6194:	f75b96e3          	bne	s7,s5,6100 <pipewrite+0x60>
  }
  wakeup(&pi->nread);
    6198:	20c48513          	add	a0,s1,524
    619c:	ffffd097          	auipc	ra,0xffffd
    61a0:	b94080e7          	jalr	-1132(ra) # 2d30 <wakeup>
  release(&pi->lock);
    61a4:	00048513          	mv	a0,s1
    61a8:	ffffb097          	auipc	ra,0xffffb
    61ac:	c70080e7          	jalr	-912(ra) # e18 <release>
  return n;
    61b0:	000a0513          	mv	a0,s4
    61b4:	0140006f          	j	61c8 <pipewrite+0x128>
        release(&pi->lock);
    61b8:	00048513          	mv	a0,s1
    61bc:	ffffb097          	auipc	ra,0xffffb
    61c0:	c5c080e7          	jalr	-932(ra) # e18 <release>
        return -1;
    61c4:	fff00513          	li	a0,-1
}
    61c8:	03c12083          	lw	ra,60(sp)
    61cc:	03812403          	lw	s0,56(sp)
    61d0:	03412483          	lw	s1,52(sp)
    61d4:	03012903          	lw	s2,48(sp)
    61d8:	02c12983          	lw	s3,44(sp)
    61dc:	02812a03          	lw	s4,40(sp)
    61e0:	02412a83          	lw	s5,36(sp)
    61e4:	02012b03          	lw	s6,32(sp)
    61e8:	01c12b83          	lw	s7,28(sp)
    61ec:	04010113          	add	sp,sp,64
    61f0:	00008067          	ret

000061f4 <piperead>:

int
piperead(struct pipe *pi, uint32 addr, int n)
{
    61f4:	fd010113          	add	sp,sp,-48
    61f8:	02112623          	sw	ra,44(sp)
    61fc:	02812423          	sw	s0,40(sp)
    6200:	02912223          	sw	s1,36(sp)
    6204:	03212023          	sw	s2,32(sp)
    6208:	01312e23          	sw	s3,28(sp)
    620c:	01412c23          	sw	s4,24(sp)
    6210:	01512a23          	sw	s5,20(sp)
    6214:	01612823          	sw	s6,16(sp)
    6218:	03010413          	add	s0,sp,48
    621c:	00050493          	mv	s1,a0
    6220:	00058a93          	mv	s5,a1
    6224:	00060993          	mv	s3,a2
  int i;
  struct proc *pr = myproc();
    6228:	ffffc097          	auipc	ra,0xffffc
    622c:	ea8080e7          	jalr	-344(ra) # 20d0 <myproc>
    6230:	00050a13          	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    6234:	00048513          	mv	a0,s1
    6238:	ffffb097          	auipc	ra,0xffffb
    623c:	b6c080e7          	jalr	-1172(ra) # da4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    6240:	20c4a703          	lw	a4,524(s1)
    6244:	2104a783          	lw	a5,528(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    6248:	20c48913          	add	s2,s1,524
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    624c:	02f71c63          	bne	a4,a5,6284 <piperead+0x90>
    6250:	2184a783          	lw	a5,536(s1)
    6254:	02078863          	beqz	a5,6284 <piperead+0x90>
    if(myproc()->killed){
    6258:	ffffc097          	auipc	ra,0xffffc
    625c:	e78080e7          	jalr	-392(ra) # 20d0 <myproc>
    6260:	01852783          	lw	a5,24(a0)
    6264:	0a079e63          	bnez	a5,6320 <piperead+0x12c>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    6268:	00048593          	mv	a1,s1
    626c:	00090513          	mv	a0,s2
    6270:	ffffd097          	auipc	ra,0xffffd
    6274:	8a4080e7          	jalr	-1884(ra) # 2b14 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    6278:	20c4a703          	lw	a4,524(s1)
    627c:	2104a783          	lw	a5,528(s1)
    6280:	fcf708e3          	beq	a4,a5,6250 <piperead+0x5c>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    6284:	00000913          	li	s2,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    6288:	fff00b13          	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    628c:	05305863          	blez	s3,62dc <piperead+0xe8>
    if(pi->nread == pi->nwrite)
    6290:	20c4a783          	lw	a5,524(s1)
    6294:	2104a703          	lw	a4,528(s1)
    6298:	04e78263          	beq	a5,a4,62dc <piperead+0xe8>
    ch = pi->data[pi->nread++ % PIPESIZE];
    629c:	00178713          	add	a4,a5,1
    62a0:	20e4a623          	sw	a4,524(s1)
    62a4:	1ff7f793          	and	a5,a5,511
    62a8:	00f487b3          	add	a5,s1,a5
    62ac:	00c7c783          	lbu	a5,12(a5)
    62b0:	fcf40fa3          	sb	a5,-33(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    62b4:	00100693          	li	a3,1
    62b8:	fdf40613          	add	a2,s0,-33
    62bc:	015905b3          	add	a1,s2,s5
    62c0:	02ca2503          	lw	a0,44(s4)
    62c4:	ffffc097          	auipc	ra,0xffffc
    62c8:	960080e7          	jalr	-1696(ra) # 1c24 <copyout>
    62cc:	01650863          	beq	a0,s6,62dc <piperead+0xe8>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    62d0:	00190913          	add	s2,s2,1
    62d4:	fb299ee3          	bne	s3,s2,6290 <piperead+0x9c>
    62d8:	00098913          	mv	s2,s3
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    62dc:	21048513          	add	a0,s1,528
    62e0:	ffffd097          	auipc	ra,0xffffd
    62e4:	a50080e7          	jalr	-1456(ra) # 2d30 <wakeup>
  release(&pi->lock);
    62e8:	00048513          	mv	a0,s1
    62ec:	ffffb097          	auipc	ra,0xffffb
    62f0:	b2c080e7          	jalr	-1236(ra) # e18 <release>
  return i;
}
    62f4:	00090513          	mv	a0,s2
    62f8:	02c12083          	lw	ra,44(sp)
    62fc:	02812403          	lw	s0,40(sp)
    6300:	02412483          	lw	s1,36(sp)
    6304:	02012903          	lw	s2,32(sp)
    6308:	01c12983          	lw	s3,28(sp)
    630c:	01812a03          	lw	s4,24(sp)
    6310:	01412a83          	lw	s5,20(sp)
    6314:	01012b03          	lw	s6,16(sp)
    6318:	03010113          	add	sp,sp,48
    631c:	00008067          	ret
      release(&pi->lock);
    6320:	00048513          	mv	a0,s1
    6324:	ffffb097          	auipc	ra,0xffffb
    6328:	af4080e7          	jalr	-1292(ra) # e18 <release>
      return -1;
    632c:	fff00913          	li	s2,-1
    6330:	fc5ff06f          	j	62f4 <piperead+0x100>

00006334 <exec>:

static int loadseg(pde_t *pgdir, uint32 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    6334:	ed010113          	add	sp,sp,-304
    6338:	12112623          	sw	ra,300(sp)
    633c:	12812423          	sw	s0,296(sp)
    6340:	12912223          	sw	s1,292(sp)
    6344:	13212023          	sw	s2,288(sp)
    6348:	11312e23          	sw	s3,284(sp)
    634c:	11412c23          	sw	s4,280(sp)
    6350:	11512a23          	sw	s5,276(sp)
    6354:	11612823          	sw	s6,272(sp)
    6358:	11712623          	sw	s7,268(sp)
    635c:	11812423          	sw	s8,264(sp)
    6360:	11912223          	sw	s9,260(sp)
    6364:	11a12023          	sw	s10,256(sp)
    6368:	0fb12e23          	sw	s11,252(sp)
    636c:	13010413          	add	s0,sp,304
    6370:	00050913          	mv	s2,a0
    6374:	eca42a23          	sw	a0,-300(s0)
    6378:	ecb42c23          	sw	a1,-296(s0)
  uint32 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    637c:	ffffc097          	auipc	ra,0xffffc
    6380:	d54080e7          	jalr	-684(ra) # 20d0 <myproc>
    6384:	00050493          	mv	s1,a0

  begin_op();
    6388:	fffff097          	auipc	ra,0xfffff
    638c:	030080e7          	jalr	48(ra) # 53b8 <begin_op>

  if((ip = namei(path)) == 0){
    6390:	00090513          	mv	a0,s2
    6394:	fffff097          	auipc	ra,0xfffff
    6398:	d6c080e7          	jalr	-660(ra) # 5100 <namei>
    639c:	08050c63          	beqz	a0,6434 <exec+0x100>
    63a0:	00050a93          	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    63a4:	ffffe097          	auipc	ra,0xffffe
    63a8:	2e8080e7          	jalr	744(ra) # 468c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint32)&elf, 0, sizeof(elf)) != sizeof(elf))
    63ac:	03400713          	li	a4,52
    63b0:	00000693          	li	a3,0
    63b4:	f0840613          	add	a2,s0,-248
    63b8:	00000593          	li	a1,0
    63bc:	000a8513          	mv	a0,s5
    63c0:	ffffe097          	auipc	ra,0xffffe
    63c4:	654080e7          	jalr	1620(ra) # 4a14 <readi>
    63c8:	03400793          	li	a5,52
    63cc:	00f51a63          	bne	a0,a5,63e0 <exec+0xac>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    63d0:	f0842703          	lw	a4,-248(s0)
    63d4:	464c47b7          	lui	a5,0x464c4
    63d8:	57f78793          	add	a5,a5,1407 # 464c457f <end+0x464a356b>
    63dc:	06f70463          	beq	a4,a5,6444 <exec+0x110>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    63e0:	000a8513          	mv	a0,s5
    63e4:	ffffe097          	auipc	ra,0xffffe
    63e8:	5ac080e7          	jalr	1452(ra) # 4990 <iunlockput>
    end_op();
    63ec:	fffff097          	auipc	ra,0xfffff
    63f0:	07c080e7          	jalr	124(ra) # 5468 <end_op>
  }
  return -1;
    63f4:	fff00513          	li	a0,-1
}
    63f8:	12c12083          	lw	ra,300(sp)
    63fc:	12812403          	lw	s0,296(sp)
    6400:	12412483          	lw	s1,292(sp)
    6404:	12012903          	lw	s2,288(sp)
    6408:	11c12983          	lw	s3,284(sp)
    640c:	11812a03          	lw	s4,280(sp)
    6410:	11412a83          	lw	s5,276(sp)
    6414:	11012b03          	lw	s6,272(sp)
    6418:	10c12b83          	lw	s7,268(sp)
    641c:	10812c03          	lw	s8,264(sp)
    6420:	10412c83          	lw	s9,260(sp)
    6424:	10012d03          	lw	s10,256(sp)
    6428:	0fc12d83          	lw	s11,252(sp)
    642c:	13010113          	add	sp,sp,304
    6430:	00008067          	ret
    end_op();
    6434:	fffff097          	auipc	ra,0xfffff
    6438:	034080e7          	jalr	52(ra) # 5468 <end_op>
    return -1;
    643c:	fff00513          	li	a0,-1
    6440:	fb9ff06f          	j	63f8 <exec+0xc4>
  if((pagetable = proc_pagetable(p)) == 0)
    6444:	00048513          	mv	a0,s1
    6448:	ffffc097          	auipc	ra,0xffffc
    644c:	da8080e7          	jalr	-600(ra) # 21f0 <proc_pagetable>
    6450:	00050b13          	mv	s6,a0
    6454:	f80506e3          	beqz	a0,63e0 <exec+0xac>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    6458:	f2442683          	lw	a3,-220(s0)
    645c:	f3445783          	lhu	a5,-204(s0)
    6460:	12078463          	beqz	a5,6588 <exec+0x254>
  uint32 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    6464:	00000493          	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    6468:	00000c93          	li	s9,0
    if(ph.type != ELF_PROG_LOAD)
    646c:	00100d13          	li	s10,1
    if(ph.vaddr % PGSIZE != 0)
    6470:	000019b7          	lui	s3,0x1
    6474:	fff98793          	add	a5,s3,-1 # fff <strncpy+0x1b>
    6478:	ecf42823          	sw	a5,-304(s0)
    647c:	0840006f          	j	6500 <exec+0x1cc>
{
  uint i, n;
  uint32 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");
    6480:	00002517          	auipc	a0,0x2
    6484:	1bc50513          	add	a0,a0,444 # 863c <userret+0x59c>
    6488:	ffffa097          	auipc	ra,0xffffa
    648c:	204080e7          	jalr	516(ra) # 68c <panic>

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    6490:	00002517          	auipc	a0,0x2
    6494:	1d050513          	add	a0,a0,464 # 8660 <userret+0x5c0>
    6498:	ffffa097          	auipc	ra,0xffffa
    649c:	1f4080e7          	jalr	500(ra) # 68c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint32)pa, offset+i, n) != n)
    64a0:	00090713          	mv	a4,s2
    64a4:	009c06b3          	add	a3,s8,s1
    64a8:	00000593          	li	a1,0
    64ac:	000a8513          	mv	a0,s5
    64b0:	ffffe097          	auipc	ra,0xffffe
    64b4:	564080e7          	jalr	1380(ra) # 4a14 <readi>
    64b8:	2aa91863          	bne	s2,a0,6768 <exec+0x434>
  for(i = 0; i < sz; i += PGSIZE){
    64bc:	013484b3          	add	s1,s1,s3
    64c0:	0344f663          	bgeu	s1,s4,64ec <exec+0x1b8>
    pa = walkaddr(pagetable, va + i);
    64c4:	009b85b3          	add	a1,s7,s1
    64c8:	000b0513          	mv	a0,s6
    64cc:	ffffb097          	auipc	ra,0xffffb
    64d0:	eb4080e7          	jalr	-332(ra) # 1380 <walkaddr>
    64d4:	00050613          	mv	a2,a0
    if(pa == 0)
    64d8:	fa050ce3          	beqz	a0,6490 <exec+0x15c>
    if(sz - i < PGSIZE)
    64dc:	409a0933          	sub	s2,s4,s1
    64e0:	fd29f0e3          	bgeu	s3,s2,64a0 <exec+0x16c>
    64e4:	00098913          	mv	s2,s3
    64e8:	fb9ff06f          	j	64a0 <exec+0x16c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    64ec:	edc42483          	lw	s1,-292(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    64f0:	001c8c93          	add	s9,s9,1
    64f4:	020d8693          	add	a3,s11,32
    64f8:	f3445783          	lhu	a5,-204(s0)
    64fc:	08fcd863          	bge	s9,a5,658c <exec+0x258>
    if(readi(ip, 0, (uint32)&ph, off, sizeof(ph)) != sizeof(ph))
    6500:	00068d93          	mv	s11,a3
    6504:	02000713          	li	a4,32
    6508:	ee840613          	add	a2,s0,-280
    650c:	00000593          	li	a1,0
    6510:	000a8513          	mv	a0,s5
    6514:	ffffe097          	auipc	ra,0xffffe
    6518:	500080e7          	jalr	1280(ra) # 4a14 <readi>
    651c:	02000793          	li	a5,32
    6520:	24f51263          	bne	a0,a5,6764 <exec+0x430>
    if(ph.type != ELF_PROG_LOAD)
    6524:	ee842783          	lw	a5,-280(s0)
    6528:	fda794e3          	bne	a5,s10,64f0 <exec+0x1bc>
    if(ph.memsz < ph.filesz)
    652c:	efc42603          	lw	a2,-260(s0)
    6530:	ef842783          	lw	a5,-264(s0)
    6534:	24f66863          	bltu	a2,a5,6784 <exec+0x450>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    6538:	ef042783          	lw	a5,-272(s0)
    653c:	00f60633          	add	a2,a2,a5
    6540:	24f66663          	bltu	a2,a5,678c <exec+0x458>
    if(ph.vaddr % PGSIZE != 0)
    6544:	ed042903          	lw	s2,-304(s0)
    6548:	0127f7b3          	and	a5,a5,s2
    654c:	24079463          	bnez	a5,6794 <exec+0x460>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    6550:	00048593          	mv	a1,s1
    6554:	000b0513          	mv	a0,s6
    6558:	ffffb097          	auipc	ra,0xffffb
    655c:	3e4080e7          	jalr	996(ra) # 193c <uvmalloc>
    6560:	eca42e23          	sw	a0,-292(s0)
    6564:	22050c63          	beqz	a0,679c <exec+0x468>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    6568:	ef042b83          	lw	s7,-272(s0)
    656c:	eec42c03          	lw	s8,-276(s0)
    6570:	ef842a03          	lw	s4,-264(s0)
  if((va % PGSIZE) != 0)
    6574:	012bf4b3          	and	s1,s7,s2
    6578:	f00494e3          	bnez	s1,6480 <exec+0x14c>
  for(i = 0; i < sz; i += PGSIZE){
    657c:	f40a14e3          	bnez	s4,64c4 <exec+0x190>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    6580:	00050493          	mv	s1,a0
    6584:	f6dff06f          	j	64f0 <exec+0x1bc>
  uint32 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    6588:	00000493          	li	s1,0
  iunlockput(ip);
    658c:	000a8513          	mv	a0,s5
    6590:	ffffe097          	auipc	ra,0xffffe
    6594:	400080e7          	jalr	1024(ra) # 4990 <iunlockput>
  end_op();
    6598:	fffff097          	auipc	ra,0xfffff
    659c:	ed0080e7          	jalr	-304(ra) # 5468 <end_op>
  p = myproc();
    65a0:	ffffc097          	auipc	ra,0xffffc
    65a4:	b30080e7          	jalr	-1232(ra) # 20d0 <myproc>
    65a8:	00050a93          	mv	s5,a0
  uint32 oldsz = p->sz;
    65ac:	02852c83          	lw	s9,40(a0)
  sz = PGROUNDUP(sz);
    65b0:	000019b7          	lui	s3,0x1
    65b4:	fff98993          	add	s3,s3,-1 # fff <strncpy+0x1b>
    65b8:	013489b3          	add	s3,s1,s3
    65bc:	fffff7b7          	lui	a5,0xfffff
    65c0:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    65c4:	00002637          	lui	a2,0x2
    65c8:	00c98633          	add	a2,s3,a2
    65cc:	00098593          	mv	a1,s3
    65d0:	000b0513          	mv	a0,s6
    65d4:	ffffb097          	auipc	ra,0xffffb
    65d8:	368080e7          	jalr	872(ra) # 193c <uvmalloc>
    65dc:	00050913          	mv	s2,a0
    65e0:	eca42e23          	sw	a0,-292(s0)
    65e4:	00051863          	bnez	a0,65f4 <exec+0x2c0>
  if(pagetable)
    65e8:	ed342e23          	sw	s3,-292(s0)
    65ec:	00000a93          	li	s5,0
    65f0:	1780006f          	j	6768 <exec+0x434>
  uvmclear(pagetable, sz-2*PGSIZE);
    65f4:	ffffe5b7          	lui	a1,0xffffe
    65f8:	00b505b3          	add	a1,a0,a1
    65fc:	000b0513          	mv	a0,s6
    6600:	ffffb097          	auipc	ra,0xffffb
    6604:	5d8080e7          	jalr	1496(ra) # 1bd8 <uvmclear>
  stackbase = sp - PGSIZE;
    6608:	fffffbb7          	lui	s7,0xfffff
    660c:	01790bb3          	add	s7,s2,s7
  for(argc = 0; argv[argc]; argc++) {
    6610:	ed842783          	lw	a5,-296(s0)
    6614:	0007a503          	lw	a0,0(a5) # fffff000 <end+0xfffddfec>
    6618:	08050063          	beqz	a0,6698 <exec+0x364>
    661c:	f3c40993          	add	s3,s0,-196
    6620:	fbc40c13          	add	s8,s0,-68
    6624:	00000493          	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    6628:	ffffb097          	auipc	ra,0xffffb
    662c:	a5c080e7          	jalr	-1444(ra) # 1084 <strlen>
    6630:	00150793          	add	a5,a0,1
    6634:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    6638:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    663c:	17796463          	bltu	s2,s7,67a4 <exec+0x470>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    6640:	ed842d03          	lw	s10,-296(s0)
    6644:	000d2a03          	lw	s4,0(s10)
    6648:	000a0513          	mv	a0,s4
    664c:	ffffb097          	auipc	ra,0xffffb
    6650:	a38080e7          	jalr	-1480(ra) # 1084 <strlen>
    6654:	00150693          	add	a3,a0,1
    6658:	000a0613          	mv	a2,s4
    665c:	00090593          	mv	a1,s2
    6660:	000b0513          	mv	a0,s6
    6664:	ffffb097          	auipc	ra,0xffffb
    6668:	5c0080e7          	jalr	1472(ra) # 1c24 <copyout>
    666c:	14054063          	bltz	a0,67ac <exec+0x478>
    ustack[argc] = sp;
    6670:	0129a023          	sw	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    6674:	00148493          	add	s1,s1,1
    6678:	004d0793          	add	a5,s10,4
    667c:	ecf42c23          	sw	a5,-296(s0)
    6680:	004d2503          	lw	a0,4(s10)
    6684:	00050e63          	beqz	a0,66a0 <exec+0x36c>
    if(argc >= MAXARG)
    6688:	00498993          	add	s3,s3,4
    668c:	f9899ee3          	bne	s3,s8,6628 <exec+0x2f4>
  ip = 0;
    6690:	00000a93          	li	s5,0
    6694:	0d40006f          	j	6768 <exec+0x434>
  sp = sz;
    6698:	edc42903          	lw	s2,-292(s0)
  for(argc = 0; argv[argc]; argc++) {
    669c:	00000493          	li	s1,0
  ustack[argc] = 0;
    66a0:	00249793          	sll	a5,s1,0x2
    66a4:	fc078793          	add	a5,a5,-64
    66a8:	008787b3          	add	a5,a5,s0
    66ac:	f607ae23          	sw	zero,-132(a5)
  sp -= (argc+1) * sizeof(uint32);
    66b0:	00148693          	add	a3,s1,1
    66b4:	00269693          	sll	a3,a3,0x2
    66b8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    66bc:	ff097913          	and	s2,s2,-16
  sz = sz1;
    66c0:	edc42983          	lw	s3,-292(s0)
  if(sp < stackbase)
    66c4:	f37962e3          	bltu	s2,s7,65e8 <exec+0x2b4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint32)) < 0)
    66c8:	f3c40613          	add	a2,s0,-196
    66cc:	00090593          	mv	a1,s2
    66d0:	000b0513          	mv	a0,s6
    66d4:	ffffb097          	auipc	ra,0xffffb
    66d8:	550080e7          	jalr	1360(ra) # 1c24 <copyout>
    66dc:	0c054c63          	bltz	a0,67b4 <exec+0x480>
  p->tf->a1 = sp;
    66e0:	030aa783          	lw	a5,48(s5)
    66e4:	0327ae23          	sw	s2,60(a5)
  for(last=s=path; *s; s++)
    66e8:	ed442783          	lw	a5,-300(s0)
    66ec:	0007c703          	lbu	a4,0(a5)
    66f0:	02070463          	beqz	a4,6718 <exec+0x3e4>
    66f4:	00178793          	add	a5,a5,1
    if(*s == '/')
    66f8:	02f00693          	li	a3,47
    66fc:	0140006f          	j	6710 <exec+0x3dc>
      last = s+1;
    6700:	ecf42a23          	sw	a5,-300(s0)
  for(last=s=path; *s; s++)
    6704:	00178793          	add	a5,a5,1
    6708:	fff7c703          	lbu	a4,-1(a5)
    670c:	00070663          	beqz	a4,6718 <exec+0x3e4>
    if(*s == '/')
    6710:	fed71ae3          	bne	a4,a3,6704 <exec+0x3d0>
    6714:	fedff06f          	j	6700 <exec+0x3cc>
  safestrcpy(p->name, last, sizeof(p->name));
    6718:	01000613          	li	a2,16
    671c:	ed442583          	lw	a1,-300(s0)
    6720:	0b0a8513          	add	a0,s5,176
    6724:	ffffb097          	auipc	ra,0xffffb
    6728:	91c080e7          	jalr	-1764(ra) # 1040 <safestrcpy>
  oldpagetable = p->pagetable;
    672c:	02caa503          	lw	a0,44(s5)
  p->pagetable = pagetable;
    6730:	036aa623          	sw	s6,44(s5)
  p->sz = sz;
    6734:	edc42783          	lw	a5,-292(s0)
    6738:	02faa423          	sw	a5,40(s5)
  p->tf->epc = elf.entry;  // initial program counter = main
    673c:	030aa783          	lw	a5,48(s5)
    6740:	f2042703          	lw	a4,-224(s0)
    6744:	00e7a623          	sw	a4,12(a5)
  p->tf->sp = sp; // initial stack pointer
    6748:	030aa783          	lw	a5,48(s5)
    674c:	0127ac23          	sw	s2,24(a5)
  proc_freepagetable(oldpagetable, oldsz);
    6750:	000c8593          	mv	a1,s9
    6754:	ffffc097          	auipc	ra,0xffffc
    6758:	c00080e7          	jalr	-1024(ra) # 2354 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    675c:	00048513          	mv	a0,s1
    6760:	c99ff06f          	j	63f8 <exec+0xc4>
    6764:	ec942e23          	sw	s1,-292(s0)
    proc_freepagetable(pagetable, sz);
    6768:	edc42583          	lw	a1,-292(s0)
    676c:	000b0513          	mv	a0,s6
    6770:	ffffc097          	auipc	ra,0xffffc
    6774:	be4080e7          	jalr	-1052(ra) # 2354 <proc_freepagetable>
  return -1;
    6778:	fff00513          	li	a0,-1
  if(ip){
    677c:	c60a8ee3          	beqz	s5,63f8 <exec+0xc4>
    6780:	c61ff06f          	j	63e0 <exec+0xac>
    6784:	ec942e23          	sw	s1,-292(s0)
    6788:	fe1ff06f          	j	6768 <exec+0x434>
    678c:	ec942e23          	sw	s1,-292(s0)
    6790:	fd9ff06f          	j	6768 <exec+0x434>
    6794:	ec942e23          	sw	s1,-292(s0)
    6798:	fd1ff06f          	j	6768 <exec+0x434>
    679c:	ec942e23          	sw	s1,-292(s0)
    67a0:	fc9ff06f          	j	6768 <exec+0x434>
  ip = 0;
    67a4:	00000a93          	li	s5,0
    67a8:	fc1ff06f          	j	6768 <exec+0x434>
    67ac:	00000a93          	li	s5,0
  if(pagetable)
    67b0:	fb9ff06f          	j	6768 <exec+0x434>
  sz = sz1;
    67b4:	edc42983          	lw	s3,-292(s0)
    67b8:	e31ff06f          	j	65e8 <exec+0x2b4>

000067bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    67bc:	fe010113          	add	sp,sp,-32
    67c0:	00112e23          	sw	ra,28(sp)
    67c4:	00812c23          	sw	s0,24(sp)
    67c8:	00912a23          	sw	s1,20(sp)
    67cc:	01212823          	sw	s2,16(sp)
    67d0:	02010413          	add	s0,sp,32
    67d4:	00058913          	mv	s2,a1
    67d8:	00060493          	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    67dc:	fec40593          	add	a1,s0,-20
    67e0:	ffffd097          	auipc	ra,0xffffd
    67e4:	f24080e7          	jalr	-220(ra) # 3704 <argint>
    67e8:	04054e63          	bltz	a0,6844 <argfd+0x88>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    67ec:	fec42703          	lw	a4,-20(s0)
    67f0:	00f00793          	li	a5,15
    67f4:	04e7ec63          	bltu	a5,a4,684c <argfd+0x90>
    67f8:	ffffc097          	auipc	ra,0xffffc
    67fc:	8d8080e7          	jalr	-1832(ra) # 20d0 <myproc>
    6800:	fec42703          	lw	a4,-20(s0)
    6804:	01870793          	add	a5,a4,24
    6808:	00279793          	sll	a5,a5,0x2
    680c:	00f50533          	add	a0,a0,a5
    6810:	00c52783          	lw	a5,12(a0)
    6814:	04078063          	beqz	a5,6854 <argfd+0x98>
    return -1;
  if(pfd)
    6818:	00090463          	beqz	s2,6820 <argfd+0x64>
    *pfd = fd;
    681c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    6820:	00000513          	li	a0,0
  if(pf)
    6824:	00048463          	beqz	s1,682c <argfd+0x70>
    *pf = f;
    6828:	00f4a023          	sw	a5,0(s1)
}
    682c:	01c12083          	lw	ra,28(sp)
    6830:	01812403          	lw	s0,24(sp)
    6834:	01412483          	lw	s1,20(sp)
    6838:	01012903          	lw	s2,16(sp)
    683c:	02010113          	add	sp,sp,32
    6840:	00008067          	ret
    return -1;
    6844:	fff00513          	li	a0,-1
    6848:	fe5ff06f          	j	682c <argfd+0x70>
    return -1;
    684c:	fff00513          	li	a0,-1
    6850:	fddff06f          	j	682c <argfd+0x70>
    6854:	fff00513          	li	a0,-1
    6858:	fd5ff06f          	j	682c <argfd+0x70>

0000685c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    685c:	ff010113          	add	sp,sp,-16
    6860:	00112623          	sw	ra,12(sp)
    6864:	00812423          	sw	s0,8(sp)
    6868:	00912223          	sw	s1,4(sp)
    686c:	01010413          	add	s0,sp,16
    6870:	00050493          	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    6874:	ffffc097          	auipc	ra,0xffffc
    6878:	85c080e7          	jalr	-1956(ra) # 20d0 <myproc>
    687c:	00050613          	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    6880:	06c50793          	add	a5,a0,108
    6884:	00000513          	li	a0,0
    6888:	01000693          	li	a3,16
    if(p->ofile[fd] == 0){
    688c:	0007a703          	lw	a4,0(a5)
    6890:	02070463          	beqz	a4,68b8 <fdalloc+0x5c>
  for(fd = 0; fd < NOFILE; fd++){
    6894:	00150513          	add	a0,a0,1
    6898:	00478793          	add	a5,a5,4
    689c:	fed518e3          	bne	a0,a3,688c <fdalloc+0x30>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    68a0:	fff00513          	li	a0,-1
}
    68a4:	00c12083          	lw	ra,12(sp)
    68a8:	00812403          	lw	s0,8(sp)
    68ac:	00412483          	lw	s1,4(sp)
    68b0:	01010113          	add	sp,sp,16
    68b4:	00008067          	ret
      p->ofile[fd] = f;
    68b8:	01850793          	add	a5,a0,24
    68bc:	00279793          	sll	a5,a5,0x2
    68c0:	00f60633          	add	a2,a2,a5
    68c4:	00962623          	sw	s1,12(a2) # 200c <procinit+0x94>
      return fd;
    68c8:	fddff06f          	j	68a4 <fdalloc+0x48>

000068cc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    68cc:	fd010113          	add	sp,sp,-48
    68d0:	02112623          	sw	ra,44(sp)
    68d4:	02812423          	sw	s0,40(sp)
    68d8:	02912223          	sw	s1,36(sp)
    68dc:	03212023          	sw	s2,32(sp)
    68e0:	01312e23          	sw	s3,28(sp)
    68e4:	01412c23          	sw	s4,24(sp)
    68e8:	01512a23          	sw	s5,20(sp)
    68ec:	03010413          	add	s0,sp,48
    68f0:	00058a93          	mv	s5,a1
    68f4:	00060a13          	mv	s4,a2
    68f8:	00068993          	mv	s3,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    68fc:	fd040593          	add	a1,s0,-48
    6900:	fffff097          	auipc	ra,0xfffff
    6904:	830080e7          	jalr	-2000(ra) # 5130 <nameiparent>
    6908:	00050913          	mv	s2,a0
    690c:	18050263          	beqz	a0,6a90 <create+0x1c4>
    return 0;

  ilock(dp);
    6910:	ffffe097          	auipc	ra,0xffffe
    6914:	d7c080e7          	jalr	-644(ra) # 468c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    6918:	00000613          	li	a2,0
    691c:	fd040593          	add	a1,s0,-48
    6920:	00090513          	mv	a0,s2
    6924:	ffffe097          	auipc	ra,0xffffe
    6928:	3e0080e7          	jalr	992(ra) # 4d04 <dirlookup>
    692c:	00050493          	mv	s1,a0
    6930:	06050c63          	beqz	a0,69a8 <create+0xdc>
    iunlockput(dp);
    6934:	00090513          	mv	a0,s2
    6938:	ffffe097          	auipc	ra,0xffffe
    693c:	058080e7          	jalr	88(ra) # 4990 <iunlockput>
    ilock(ip);
    6940:	00048513          	mv	a0,s1
    6944:	ffffe097          	auipc	ra,0xffffe
    6948:	d48080e7          	jalr	-696(ra) # 468c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    694c:	00200793          	li	a5,2
    6950:	04fa9263          	bne	s5,a5,6994 <create+0xc8>
    6954:	0284d783          	lhu	a5,40(s1)
    6958:	ffe78793          	add	a5,a5,-2
    695c:	01079793          	sll	a5,a5,0x10
    6960:	0107d793          	srl	a5,a5,0x10
    6964:	00100713          	li	a4,1
    6968:	02f76663          	bltu	a4,a5,6994 <create+0xc8>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    696c:	00048513          	mv	a0,s1
    6970:	02c12083          	lw	ra,44(sp)
    6974:	02812403          	lw	s0,40(sp)
    6978:	02412483          	lw	s1,36(sp)
    697c:	02012903          	lw	s2,32(sp)
    6980:	01c12983          	lw	s3,28(sp)
    6984:	01812a03          	lw	s4,24(sp)
    6988:	01412a83          	lw	s5,20(sp)
    698c:	03010113          	add	sp,sp,48
    6990:	00008067          	ret
    iunlockput(ip);
    6994:	00048513          	mv	a0,s1
    6998:	ffffe097          	auipc	ra,0xffffe
    699c:	ff8080e7          	jalr	-8(ra) # 4990 <iunlockput>
    return 0;
    69a0:	00000493          	li	s1,0
    69a4:	fc9ff06f          	j	696c <create+0xa0>
  if((ip = ialloc(dp->dev, type)) == 0)
    69a8:	000a8593          	mv	a1,s5
    69ac:	00092503          	lw	a0,0(s2)
    69b0:	ffffe097          	auipc	ra,0xffffe
    69b4:	ab4080e7          	jalr	-1356(ra) # 4464 <ialloc>
    69b8:	00050493          	mv	s1,a0
    69bc:	04050a63          	beqz	a0,6a10 <create+0x144>
  ilock(ip);
    69c0:	ffffe097          	auipc	ra,0xffffe
    69c4:	ccc080e7          	jalr	-820(ra) # 468c <ilock>
  ip->major = major;
    69c8:	03449523          	sh	s4,42(s1)
  ip->minor = minor;
    69cc:	03349623          	sh	s3,44(s1)
  ip->nlink = 1;
    69d0:	00100993          	li	s3,1
    69d4:	03349723          	sh	s3,46(s1)
  iupdate(ip);
    69d8:	00048513          	mv	a0,s1
    69dc:	ffffe097          	auipc	ra,0xffffe
    69e0:	b94080e7          	jalr	-1132(ra) # 4570 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    69e4:	033a8e63          	beq	s5,s3,6a20 <create+0x154>
  if(dirlink(dp, name, ip->inum) < 0)
    69e8:	0044a603          	lw	a2,4(s1)
    69ec:	fd040593          	add	a1,s0,-48
    69f0:	00090513          	mv	a0,s2
    69f4:	ffffe097          	auipc	ra,0xffffe
    69f8:	5f8080e7          	jalr	1528(ra) # 4fec <dirlink>
    69fc:	08054263          	bltz	a0,6a80 <create+0x1b4>
  iunlockput(dp);
    6a00:	00090513          	mv	a0,s2
    6a04:	ffffe097          	auipc	ra,0xffffe
    6a08:	f8c080e7          	jalr	-116(ra) # 4990 <iunlockput>
  return ip;
    6a0c:	f61ff06f          	j	696c <create+0xa0>
    panic("create: ialloc");
    6a10:	00002517          	auipc	a0,0x2
    6a14:	c7050513          	add	a0,a0,-912 # 8680 <userret+0x5e0>
    6a18:	ffffa097          	auipc	ra,0xffffa
    6a1c:	c74080e7          	jalr	-908(ra) # 68c <panic>
    dp->nlink++;  // for ".."
    6a20:	02e95783          	lhu	a5,46(s2)
    6a24:	00178793          	add	a5,a5,1
    6a28:	02f91723          	sh	a5,46(s2)
    iupdate(dp);
    6a2c:	00090513          	mv	a0,s2
    6a30:	ffffe097          	auipc	ra,0xffffe
    6a34:	b40080e7          	jalr	-1216(ra) # 4570 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    6a38:	0044a603          	lw	a2,4(s1)
    6a3c:	00002597          	auipc	a1,0x2
    6a40:	c5458593          	add	a1,a1,-940 # 8690 <userret+0x5f0>
    6a44:	00048513          	mv	a0,s1
    6a48:	ffffe097          	auipc	ra,0xffffe
    6a4c:	5a4080e7          	jalr	1444(ra) # 4fec <dirlink>
    6a50:	02054063          	bltz	a0,6a70 <create+0x1a4>
    6a54:	00492603          	lw	a2,4(s2)
    6a58:	00002597          	auipc	a1,0x2
    6a5c:	c3c58593          	add	a1,a1,-964 # 8694 <userret+0x5f4>
    6a60:	00048513          	mv	a0,s1
    6a64:	ffffe097          	auipc	ra,0xffffe
    6a68:	588080e7          	jalr	1416(ra) # 4fec <dirlink>
    6a6c:	f6055ee3          	bgez	a0,69e8 <create+0x11c>
      panic("create dots");
    6a70:	00002517          	auipc	a0,0x2
    6a74:	c2850513          	add	a0,a0,-984 # 8698 <userret+0x5f8>
    6a78:	ffffa097          	auipc	ra,0xffffa
    6a7c:	c14080e7          	jalr	-1004(ra) # 68c <panic>
    panic("create: dirlink");
    6a80:	00002517          	auipc	a0,0x2
    6a84:	c2450513          	add	a0,a0,-988 # 86a4 <userret+0x604>
    6a88:	ffffa097          	auipc	ra,0xffffa
    6a8c:	c04080e7          	jalr	-1020(ra) # 68c <panic>
    return 0;
    6a90:	00050493          	mv	s1,a0
    6a94:	ed9ff06f          	j	696c <create+0xa0>

00006a98 <sys_dup>:
{
    6a98:	fe010113          	add	sp,sp,-32
    6a9c:	00112e23          	sw	ra,28(sp)
    6aa0:	00812c23          	sw	s0,24(sp)
    6aa4:	00912a23          	sw	s1,20(sp)
    6aa8:	01212823          	sw	s2,16(sp)
    6aac:	02010413          	add	s0,sp,32
  if(argfd(0, 0, &f) < 0)
    6ab0:	fec40613          	add	a2,s0,-20
    6ab4:	00000593          	li	a1,0
    6ab8:	00000513          	li	a0,0
    6abc:	00000097          	auipc	ra,0x0
    6ac0:	d00080e7          	jalr	-768(ra) # 67bc <argfd>
    return -1;
    6ac4:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    6ac8:	02054863          	bltz	a0,6af8 <sys_dup+0x60>
  if((fd=fdalloc(f)) < 0)
    6acc:	fec42903          	lw	s2,-20(s0)
    6ad0:	00090513          	mv	a0,s2
    6ad4:	00000097          	auipc	ra,0x0
    6ad8:	d88080e7          	jalr	-632(ra) # 685c <fdalloc>
    6adc:	00050493          	mv	s1,a0
    return -1;
    6ae0:	fff00793          	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    6ae4:	00054a63          	bltz	a0,6af8 <sys_dup+0x60>
  filedup(f);
    6ae8:	00090513          	mv	a0,s2
    6aec:	fffff097          	auipc	ra,0xfffff
    6af0:	ee4080e7          	jalr	-284(ra) # 59d0 <filedup>
  return fd;
    6af4:	00048793          	mv	a5,s1
}
    6af8:	00078513          	mv	a0,a5
    6afc:	01c12083          	lw	ra,28(sp)
    6b00:	01812403          	lw	s0,24(sp)
    6b04:	01412483          	lw	s1,20(sp)
    6b08:	01012903          	lw	s2,16(sp)
    6b0c:	02010113          	add	sp,sp,32
    6b10:	00008067          	ret

00006b14 <sys_read>:
{
    6b14:	fe010113          	add	sp,sp,-32
    6b18:	00112e23          	sw	ra,28(sp)
    6b1c:	00812c23          	sw	s0,24(sp)
    6b20:	02010413          	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6b24:	fec40613          	add	a2,s0,-20
    6b28:	00000593          	li	a1,0
    6b2c:	00000513          	li	a0,0
    6b30:	00000097          	auipc	ra,0x0
    6b34:	c8c080e7          	jalr	-884(ra) # 67bc <argfd>
    return -1;
    6b38:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6b3c:	04054663          	bltz	a0,6b88 <sys_read+0x74>
    6b40:	fe840593          	add	a1,s0,-24
    6b44:	00200513          	li	a0,2
    6b48:	ffffd097          	auipc	ra,0xffffd
    6b4c:	bbc080e7          	jalr	-1092(ra) # 3704 <argint>
    return -1;
    6b50:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6b54:	02054a63          	bltz	a0,6b88 <sys_read+0x74>
    6b58:	fe440593          	add	a1,s0,-28
    6b5c:	00100513          	li	a0,1
    6b60:	ffffd097          	auipc	ra,0xffffd
    6b64:	be0080e7          	jalr	-1056(ra) # 3740 <argaddr>
    return -1;
    6b68:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6b6c:	00054e63          	bltz	a0,6b88 <sys_read+0x74>
  return fileread(f, p, n);
    6b70:	fe842603          	lw	a2,-24(s0)
    6b74:	fe442583          	lw	a1,-28(s0)
    6b78:	fec42503          	lw	a0,-20(s0)
    6b7c:	fffff097          	auipc	ra,0xfffff
    6b80:	06c080e7          	jalr	108(ra) # 5be8 <fileread>
    6b84:	00050793          	mv	a5,a0
}
    6b88:	00078513          	mv	a0,a5
    6b8c:	01c12083          	lw	ra,28(sp)
    6b90:	01812403          	lw	s0,24(sp)
    6b94:	02010113          	add	sp,sp,32
    6b98:	00008067          	ret

00006b9c <sys_write>:
{
    6b9c:	fe010113          	add	sp,sp,-32
    6ba0:	00112e23          	sw	ra,28(sp)
    6ba4:	00812c23          	sw	s0,24(sp)
    6ba8:	02010413          	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6bac:	fec40613          	add	a2,s0,-20
    6bb0:	00000593          	li	a1,0
    6bb4:	00000513          	li	a0,0
    6bb8:	00000097          	auipc	ra,0x0
    6bbc:	c04080e7          	jalr	-1020(ra) # 67bc <argfd>
    return -1;
    6bc0:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6bc4:	04054663          	bltz	a0,6c10 <sys_write+0x74>
    6bc8:	fe840593          	add	a1,s0,-24
    6bcc:	00200513          	li	a0,2
    6bd0:	ffffd097          	auipc	ra,0xffffd
    6bd4:	b34080e7          	jalr	-1228(ra) # 3704 <argint>
    return -1;
    6bd8:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6bdc:	02054a63          	bltz	a0,6c10 <sys_write+0x74>
    6be0:	fe440593          	add	a1,s0,-28
    6be4:	00100513          	li	a0,1
    6be8:	ffffd097          	auipc	ra,0xffffd
    6bec:	b58080e7          	jalr	-1192(ra) # 3740 <argaddr>
    return -1;
    6bf0:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    6bf4:	00054e63          	bltz	a0,6c10 <sys_write+0x74>
  return filewrite(f, p, n);
    6bf8:	fe842603          	lw	a2,-24(s0)
    6bfc:	fe442583          	lw	a1,-28(s0)
    6c00:	fec42503          	lw	a0,-20(s0)
    6c04:	fffff097          	auipc	ra,0xfffff
    6c08:	110080e7          	jalr	272(ra) # 5d14 <filewrite>
    6c0c:	00050793          	mv	a5,a0
}
    6c10:	00078513          	mv	a0,a5
    6c14:	01c12083          	lw	ra,28(sp)
    6c18:	01812403          	lw	s0,24(sp)
    6c1c:	02010113          	add	sp,sp,32
    6c20:	00008067          	ret

00006c24 <sys_close>:
{
    6c24:	fe010113          	add	sp,sp,-32
    6c28:	00112e23          	sw	ra,28(sp)
    6c2c:	00812c23          	sw	s0,24(sp)
    6c30:	02010413          	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    6c34:	fe840613          	add	a2,s0,-24
    6c38:	fec40593          	add	a1,s0,-20
    6c3c:	00000513          	li	a0,0
    6c40:	00000097          	auipc	ra,0x0
    6c44:	b7c080e7          	jalr	-1156(ra) # 67bc <argfd>
    return -1;
    6c48:	fff00793          	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    6c4c:	02054863          	bltz	a0,6c7c <sys_close+0x58>
  myproc()->ofile[fd] = 0;
    6c50:	ffffb097          	auipc	ra,0xffffb
    6c54:	480080e7          	jalr	1152(ra) # 20d0 <myproc>
    6c58:	fec42783          	lw	a5,-20(s0)
    6c5c:	01878793          	add	a5,a5,24
    6c60:	00279793          	sll	a5,a5,0x2
    6c64:	00f50533          	add	a0,a0,a5
    6c68:	00052623          	sw	zero,12(a0)
  fileclose(f);
    6c6c:	fe842503          	lw	a0,-24(s0)
    6c70:	fffff097          	auipc	ra,0xfffff
    6c74:	dd0080e7          	jalr	-560(ra) # 5a40 <fileclose>
  return 0;
    6c78:	00000793          	li	a5,0
}
    6c7c:	00078513          	mv	a0,a5
    6c80:	01c12083          	lw	ra,28(sp)
    6c84:	01812403          	lw	s0,24(sp)
    6c88:	02010113          	add	sp,sp,32
    6c8c:	00008067          	ret

00006c90 <sys_fstat>:
{
    6c90:	fe010113          	add	sp,sp,-32
    6c94:	00112e23          	sw	ra,28(sp)
    6c98:	00812c23          	sw	s0,24(sp)
    6c9c:	02010413          	add	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    6ca0:	fec40613          	add	a2,s0,-20
    6ca4:	00000593          	li	a1,0
    6ca8:	00000513          	li	a0,0
    6cac:	00000097          	auipc	ra,0x0
    6cb0:	b10080e7          	jalr	-1264(ra) # 67bc <argfd>
    return -1;
    6cb4:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    6cb8:	02054863          	bltz	a0,6ce8 <sys_fstat+0x58>
    6cbc:	fe840593          	add	a1,s0,-24
    6cc0:	00100513          	li	a0,1
    6cc4:	ffffd097          	auipc	ra,0xffffd
    6cc8:	a7c080e7          	jalr	-1412(ra) # 3740 <argaddr>
    return -1;
    6ccc:	fff00793          	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    6cd0:	00054c63          	bltz	a0,6ce8 <sys_fstat+0x58>
  return filestat(f, st);
    6cd4:	fe842583          	lw	a1,-24(s0)
    6cd8:	fec42503          	lw	a0,-20(s0)
    6cdc:	fffff097          	auipc	ra,0xfffff
    6ce0:	e64080e7          	jalr	-412(ra) # 5b40 <filestat>
    6ce4:	00050793          	mv	a5,a0
}
    6ce8:	00078513          	mv	a0,a5
    6cec:	01c12083          	lw	ra,28(sp)
    6cf0:	01812403          	lw	s0,24(sp)
    6cf4:	02010113          	add	sp,sp,32
    6cf8:	00008067          	ret

00006cfc <sys_link>:
{
    6cfc:	ee010113          	add	sp,sp,-288
    6d00:	10112e23          	sw	ra,284(sp)
    6d04:	10812c23          	sw	s0,280(sp)
    6d08:	10912a23          	sw	s1,276(sp)
    6d0c:	11212823          	sw	s2,272(sp)
    6d10:	12010413          	add	s0,sp,288
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    6d14:	08000613          	li	a2,128
    6d18:	ee040593          	add	a1,s0,-288
    6d1c:	00000513          	li	a0,0
    6d20:	ffffd097          	auipc	ra,0xffffd
    6d24:	a5c080e7          	jalr	-1444(ra) # 377c <argstr>
    return -1;
    6d28:	fff00793          	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    6d2c:	14054a63          	bltz	a0,6e80 <sys_link+0x184>
    6d30:	08000613          	li	a2,128
    6d34:	f6040593          	add	a1,s0,-160
    6d38:	00100513          	li	a0,1
    6d3c:	ffffd097          	auipc	ra,0xffffd
    6d40:	a40080e7          	jalr	-1472(ra) # 377c <argstr>
    return -1;
    6d44:	fff00793          	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    6d48:	12054c63          	bltz	a0,6e80 <sys_link+0x184>
  begin_op();
    6d4c:	ffffe097          	auipc	ra,0xffffe
    6d50:	66c080e7          	jalr	1644(ra) # 53b8 <begin_op>
  if((ip = namei(old)) == 0){
    6d54:	ee040513          	add	a0,s0,-288
    6d58:	ffffe097          	auipc	ra,0xffffe
    6d5c:	3a8080e7          	jalr	936(ra) # 5100 <namei>
    6d60:	00050493          	mv	s1,a0
    6d64:	0a050463          	beqz	a0,6e0c <sys_link+0x110>
  ilock(ip);
    6d68:	ffffe097          	auipc	ra,0xffffe
    6d6c:	924080e7          	jalr	-1756(ra) # 468c <ilock>
  if(ip->type == T_DIR){
    6d70:	02849703          	lh	a4,40(s1)
    6d74:	00100793          	li	a5,1
    6d78:	0af70263          	beq	a4,a5,6e1c <sys_link+0x120>
  ip->nlink++;
    6d7c:	02e4d783          	lhu	a5,46(s1)
    6d80:	00178793          	add	a5,a5,1
    6d84:	02f49723          	sh	a5,46(s1)
  iupdate(ip);
    6d88:	00048513          	mv	a0,s1
    6d8c:	ffffd097          	auipc	ra,0xffffd
    6d90:	7e4080e7          	jalr	2020(ra) # 4570 <iupdate>
  iunlock(ip);
    6d94:	00048513          	mv	a0,s1
    6d98:	ffffe097          	auipc	ra,0xffffe
    6d9c:	9f8080e7          	jalr	-1544(ra) # 4790 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    6da0:	fe040593          	add	a1,s0,-32
    6da4:	f6040513          	add	a0,s0,-160
    6da8:	ffffe097          	auipc	ra,0xffffe
    6dac:	388080e7          	jalr	904(ra) # 5130 <nameiparent>
    6db0:	00050913          	mv	s2,a0
    6db4:	08050863          	beqz	a0,6e44 <sys_link+0x148>
  ilock(dp);
    6db8:	ffffe097          	auipc	ra,0xffffe
    6dbc:	8d4080e7          	jalr	-1836(ra) # 468c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    6dc0:	00092703          	lw	a4,0(s2)
    6dc4:	0004a783          	lw	a5,0(s1)
    6dc8:	06f71863          	bne	a4,a5,6e38 <sys_link+0x13c>
    6dcc:	0044a603          	lw	a2,4(s1)
    6dd0:	fe040593          	add	a1,s0,-32
    6dd4:	00090513          	mv	a0,s2
    6dd8:	ffffe097          	auipc	ra,0xffffe
    6ddc:	214080e7          	jalr	532(ra) # 4fec <dirlink>
    6de0:	04054c63          	bltz	a0,6e38 <sys_link+0x13c>
  iunlockput(dp);
    6de4:	00090513          	mv	a0,s2
    6de8:	ffffe097          	auipc	ra,0xffffe
    6dec:	ba8080e7          	jalr	-1112(ra) # 4990 <iunlockput>
  iput(ip);
    6df0:	00048513          	mv	a0,s1
    6df4:	ffffe097          	auipc	ra,0xffffe
    6df8:	a0c080e7          	jalr	-1524(ra) # 4800 <iput>
  end_op();
    6dfc:	ffffe097          	auipc	ra,0xffffe
    6e00:	66c080e7          	jalr	1644(ra) # 5468 <end_op>
  return 0;
    6e04:	00000793          	li	a5,0
    6e08:	0780006f          	j	6e80 <sys_link+0x184>
    end_op();
    6e0c:	ffffe097          	auipc	ra,0xffffe
    6e10:	65c080e7          	jalr	1628(ra) # 5468 <end_op>
    return -1;
    6e14:	fff00793          	li	a5,-1
    6e18:	0680006f          	j	6e80 <sys_link+0x184>
    iunlockput(ip);
    6e1c:	00048513          	mv	a0,s1
    6e20:	ffffe097          	auipc	ra,0xffffe
    6e24:	b70080e7          	jalr	-1168(ra) # 4990 <iunlockput>
    end_op();
    6e28:	ffffe097          	auipc	ra,0xffffe
    6e2c:	640080e7          	jalr	1600(ra) # 5468 <end_op>
    return -1;
    6e30:	fff00793          	li	a5,-1
    6e34:	04c0006f          	j	6e80 <sys_link+0x184>
    iunlockput(dp);
    6e38:	00090513          	mv	a0,s2
    6e3c:	ffffe097          	auipc	ra,0xffffe
    6e40:	b54080e7          	jalr	-1196(ra) # 4990 <iunlockput>
  ilock(ip);
    6e44:	00048513          	mv	a0,s1
    6e48:	ffffe097          	auipc	ra,0xffffe
    6e4c:	844080e7          	jalr	-1980(ra) # 468c <ilock>
  ip->nlink--;
    6e50:	02e4d783          	lhu	a5,46(s1)
    6e54:	fff78793          	add	a5,a5,-1
    6e58:	02f49723          	sh	a5,46(s1)
  iupdate(ip);
    6e5c:	00048513          	mv	a0,s1
    6e60:	ffffd097          	auipc	ra,0xffffd
    6e64:	710080e7          	jalr	1808(ra) # 4570 <iupdate>
  iunlockput(ip);
    6e68:	00048513          	mv	a0,s1
    6e6c:	ffffe097          	auipc	ra,0xffffe
    6e70:	b24080e7          	jalr	-1244(ra) # 4990 <iunlockput>
  end_op();
    6e74:	ffffe097          	auipc	ra,0xffffe
    6e78:	5f4080e7          	jalr	1524(ra) # 5468 <end_op>
  return -1;
    6e7c:	fff00793          	li	a5,-1
}
    6e80:	00078513          	mv	a0,a5
    6e84:	11c12083          	lw	ra,284(sp)
    6e88:	11812403          	lw	s0,280(sp)
    6e8c:	11412483          	lw	s1,276(sp)
    6e90:	11012903          	lw	s2,272(sp)
    6e94:	12010113          	add	sp,sp,288
    6e98:	00008067          	ret

00006e9c <sys_unlink>:
{
    6e9c:	f2010113          	add	sp,sp,-224
    6ea0:	0c112e23          	sw	ra,220(sp)
    6ea4:	0c812c23          	sw	s0,216(sp)
    6ea8:	0c912a23          	sw	s1,212(sp)
    6eac:	0d212823          	sw	s2,208(sp)
    6eb0:	0d312623          	sw	s3,204(sp)
    6eb4:	0e010413          	add	s0,sp,224
  if(argstr(0, path, MAXPATH) < 0)
    6eb8:	08000613          	li	a2,128
    6ebc:	f4040593          	add	a1,s0,-192
    6ec0:	00000513          	li	a0,0
    6ec4:	ffffd097          	auipc	ra,0xffffd
    6ec8:	8b8080e7          	jalr	-1864(ra) # 377c <argstr>
    6ecc:	1c054063          	bltz	a0,708c <sys_unlink+0x1f0>
  begin_op();
    6ed0:	ffffe097          	auipc	ra,0xffffe
    6ed4:	4e8080e7          	jalr	1256(ra) # 53b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    6ed8:	fc040593          	add	a1,s0,-64
    6edc:	f4040513          	add	a0,s0,-192
    6ee0:	ffffe097          	auipc	ra,0xffffe
    6ee4:	250080e7          	jalr	592(ra) # 5130 <nameiparent>
    6ee8:	00050493          	mv	s1,a0
    6eec:	0e050c63          	beqz	a0,6fe4 <sys_unlink+0x148>
  ilock(dp);
    6ef0:	ffffd097          	auipc	ra,0xffffd
    6ef4:	79c080e7          	jalr	1948(ra) # 468c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    6ef8:	00001597          	auipc	a1,0x1
    6efc:	79858593          	add	a1,a1,1944 # 8690 <userret+0x5f0>
    6f00:	fc040513          	add	a0,s0,-64
    6f04:	ffffe097          	auipc	ra,0xffffe
    6f08:	dd4080e7          	jalr	-556(ra) # 4cd8 <namecmp>
    6f0c:	18050a63          	beqz	a0,70a0 <sys_unlink+0x204>
    6f10:	00001597          	auipc	a1,0x1
    6f14:	78458593          	add	a1,a1,1924 # 8694 <userret+0x5f4>
    6f18:	fc040513          	add	a0,s0,-64
    6f1c:	ffffe097          	auipc	ra,0xffffe
    6f20:	dbc080e7          	jalr	-580(ra) # 4cd8 <namecmp>
    6f24:	16050e63          	beqz	a0,70a0 <sys_unlink+0x204>
  if((ip = dirlookup(dp, name, &off)) == 0)
    6f28:	f3c40613          	add	a2,s0,-196
    6f2c:	fc040593          	add	a1,s0,-64
    6f30:	00048513          	mv	a0,s1
    6f34:	ffffe097          	auipc	ra,0xffffe
    6f38:	dd0080e7          	jalr	-560(ra) # 4d04 <dirlookup>
    6f3c:	00050913          	mv	s2,a0
    6f40:	16050063          	beqz	a0,70a0 <sys_unlink+0x204>
  ilock(ip);
    6f44:	ffffd097          	auipc	ra,0xffffd
    6f48:	748080e7          	jalr	1864(ra) # 468c <ilock>
  if(ip->nlink < 1)
    6f4c:	02e91783          	lh	a5,46(s2)
    6f50:	0af05263          	blez	a5,6ff4 <sys_unlink+0x158>
  if(ip->type == T_DIR && !isdirempty(ip)){
    6f54:	02891703          	lh	a4,40(s2)
    6f58:	00100793          	li	a5,1
    6f5c:	0af70463          	beq	a4,a5,7004 <sys_unlink+0x168>
  memset(&de, 0, sizeof(de));
    6f60:	01000613          	li	a2,16
    6f64:	00000593          	li	a1,0
    6f68:	fd040513          	add	a0,s0,-48
    6f6c:	ffffa097          	auipc	ra,0xffffa
    6f70:	f0c080e7          	jalr	-244(ra) # e78 <memset>
  if(writei(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    6f74:	01000713          	li	a4,16
    6f78:	f3c42683          	lw	a3,-196(s0)
    6f7c:	fd040613          	add	a2,s0,-48
    6f80:	00000593          	li	a1,0
    6f84:	00048513          	mv	a0,s1
    6f88:	ffffe097          	auipc	ra,0xffffe
    6f8c:	bd8080e7          	jalr	-1064(ra) # 4b60 <writei>
    6f90:	01000793          	li	a5,16
    6f94:	0cf51663          	bne	a0,a5,7060 <sys_unlink+0x1c4>
  if(ip->type == T_DIR){
    6f98:	02891703          	lh	a4,40(s2)
    6f9c:	00100793          	li	a5,1
    6fa0:	0cf70863          	beq	a4,a5,7070 <sys_unlink+0x1d4>
  iunlockput(dp);
    6fa4:	00048513          	mv	a0,s1
    6fa8:	ffffe097          	auipc	ra,0xffffe
    6fac:	9e8080e7          	jalr	-1560(ra) # 4990 <iunlockput>
  ip->nlink--;
    6fb0:	02e95783          	lhu	a5,46(s2)
    6fb4:	fff78793          	add	a5,a5,-1
    6fb8:	02f91723          	sh	a5,46(s2)
  iupdate(ip);
    6fbc:	00090513          	mv	a0,s2
    6fc0:	ffffd097          	auipc	ra,0xffffd
    6fc4:	5b0080e7          	jalr	1456(ra) # 4570 <iupdate>
  iunlockput(ip);
    6fc8:	00090513          	mv	a0,s2
    6fcc:	ffffe097          	auipc	ra,0xffffe
    6fd0:	9c4080e7          	jalr	-1596(ra) # 4990 <iunlockput>
  end_op();
    6fd4:	ffffe097          	auipc	ra,0xffffe
    6fd8:	494080e7          	jalr	1172(ra) # 5468 <end_op>
  return 0;
    6fdc:	00000513          	li	a0,0
    6fe0:	0d80006f          	j	70b8 <sys_unlink+0x21c>
    end_op();
    6fe4:	ffffe097          	auipc	ra,0xffffe
    6fe8:	484080e7          	jalr	1156(ra) # 5468 <end_op>
    return -1;
    6fec:	fff00513          	li	a0,-1
    6ff0:	0c80006f          	j	70b8 <sys_unlink+0x21c>
    panic("unlink: nlink < 1");
    6ff4:	00001517          	auipc	a0,0x1
    6ff8:	6c050513          	add	a0,a0,1728 # 86b4 <userret+0x614>
    6ffc:	ffff9097          	auipc	ra,0xffff9
    7000:	690080e7          	jalr	1680(ra) # 68c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    7004:	03092703          	lw	a4,48(s2)
    7008:	02000793          	li	a5,32
    700c:	f4e7fae3          	bgeu	a5,a4,6f60 <sys_unlink+0xc4>
    7010:	02000993          	li	s3,32
    if(readi(dp, 0, (uint32)&de, off, sizeof(de)) != sizeof(de))
    7014:	01000713          	li	a4,16
    7018:	00098693          	mv	a3,s3
    701c:	f2c40613          	add	a2,s0,-212
    7020:	00000593          	li	a1,0
    7024:	00090513          	mv	a0,s2
    7028:	ffffe097          	auipc	ra,0xffffe
    702c:	9ec080e7          	jalr	-1556(ra) # 4a14 <readi>
    7030:	01000793          	li	a5,16
    7034:	00f51e63          	bne	a0,a5,7050 <sys_unlink+0x1b4>
    if(de.inum != 0)
    7038:	f2c45783          	lhu	a5,-212(s0)
    703c:	04079c63          	bnez	a5,7094 <sys_unlink+0x1f8>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    7040:	01098993          	add	s3,s3,16
    7044:	03092783          	lw	a5,48(s2)
    7048:	fcf9e6e3          	bltu	s3,a5,7014 <sys_unlink+0x178>
    704c:	f15ff06f          	j	6f60 <sys_unlink+0xc4>
      panic("isdirempty: readi");
    7050:	00001517          	auipc	a0,0x1
    7054:	67850513          	add	a0,a0,1656 # 86c8 <userret+0x628>
    7058:	ffff9097          	auipc	ra,0xffff9
    705c:	634080e7          	jalr	1588(ra) # 68c <panic>
    panic("unlink: writei");
    7060:	00001517          	auipc	a0,0x1
    7064:	67c50513          	add	a0,a0,1660 # 86dc <userret+0x63c>
    7068:	ffff9097          	auipc	ra,0xffff9
    706c:	624080e7          	jalr	1572(ra) # 68c <panic>
    dp->nlink--;
    7070:	02e4d783          	lhu	a5,46(s1)
    7074:	fff78793          	add	a5,a5,-1
    7078:	02f49723          	sh	a5,46(s1)
    iupdate(dp);
    707c:	00048513          	mv	a0,s1
    7080:	ffffd097          	auipc	ra,0xffffd
    7084:	4f0080e7          	jalr	1264(ra) # 4570 <iupdate>
    7088:	f1dff06f          	j	6fa4 <sys_unlink+0x108>
    return -1;
    708c:	fff00513          	li	a0,-1
    7090:	0280006f          	j	70b8 <sys_unlink+0x21c>
    iunlockput(ip);
    7094:	00090513          	mv	a0,s2
    7098:	ffffe097          	auipc	ra,0xffffe
    709c:	8f8080e7          	jalr	-1800(ra) # 4990 <iunlockput>
  iunlockput(dp);
    70a0:	00048513          	mv	a0,s1
    70a4:	ffffe097          	auipc	ra,0xffffe
    70a8:	8ec080e7          	jalr	-1812(ra) # 4990 <iunlockput>
  end_op();
    70ac:	ffffe097          	auipc	ra,0xffffe
    70b0:	3bc080e7          	jalr	956(ra) # 5468 <end_op>
  return -1;
    70b4:	fff00513          	li	a0,-1
}
    70b8:	0dc12083          	lw	ra,220(sp)
    70bc:	0d812403          	lw	s0,216(sp)
    70c0:	0d412483          	lw	s1,212(sp)
    70c4:	0d012903          	lw	s2,208(sp)
    70c8:	0cc12983          	lw	s3,204(sp)
    70cc:	0e010113          	add	sp,sp,224
    70d0:	00008067          	ret

000070d4 <sys_open>:

uint32
sys_open(void)
{
    70d4:	f5010113          	add	sp,sp,-176
    70d8:	0a112623          	sw	ra,172(sp)
    70dc:	0a812423          	sw	s0,168(sp)
    70e0:	0a912223          	sw	s1,164(sp)
    70e4:	0b212023          	sw	s2,160(sp)
    70e8:	09312e23          	sw	s3,156(sp)
    70ec:	0b010413          	add	s0,sp,176
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    70f0:	08000613          	li	a2,128
    70f4:	f6040593          	add	a1,s0,-160
    70f8:	00000513          	li	a0,0
    70fc:	ffffc097          	auipc	ra,0xffffc
    7100:	680080e7          	jalr	1664(ra) # 377c <argstr>
    return -1;
    7104:	fff00493          	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    7108:	0c054863          	bltz	a0,71d8 <sys_open+0x104>
    710c:	f5c40593          	add	a1,s0,-164
    7110:	00100513          	li	a0,1
    7114:	ffffc097          	auipc	ra,0xffffc
    7118:	5f0080e7          	jalr	1520(ra) # 3704 <argint>
    711c:	0a054e63          	bltz	a0,71d8 <sys_open+0x104>

  begin_op();
    7120:	ffffe097          	auipc	ra,0xffffe
    7124:	298080e7          	jalr	664(ra) # 53b8 <begin_op>

  if(omode & O_CREATE){
    7128:	f5c42783          	lw	a5,-164(s0)
    712c:	2007f793          	and	a5,a5,512
    7130:	0c078a63          	beqz	a5,7204 <sys_open+0x130>
    ip = create(path, T_FILE, 0, 0);
    7134:	00000693          	li	a3,0
    7138:	00000613          	li	a2,0
    713c:	00200593          	li	a1,2
    7140:	f6040513          	add	a0,s0,-160
    7144:	fffff097          	auipc	ra,0xfffff
    7148:	788080e7          	jalr	1928(ra) # 68cc <create>
    714c:	00050913          	mv	s2,a0
    if(ip == 0){
    7150:	0a050463          	beqz	a0,71f8 <sys_open+0x124>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    7154:	02891703          	lh	a4,40(s2)
    7158:	00300793          	li	a5,3
    715c:	00f71863          	bne	a4,a5,716c <sys_open+0x98>
    7160:	02a95703          	lhu	a4,42(s2)
    7164:	00900793          	li	a5,9
    7168:	0ee7ec63          	bltu	a5,a4,7260 <sys_open+0x18c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    716c:	ffffe097          	auipc	ra,0xffffe
    7170:	7d8080e7          	jalr	2008(ra) # 5944 <filealloc>
    7174:	00050993          	mv	s3,a0
    7178:	10050863          	beqz	a0,7288 <sys_open+0x1b4>
    717c:	fffff097          	auipc	ra,0xfffff
    7180:	6e0080e7          	jalr	1760(ra) # 685c <fdalloc>
    7184:	00050493          	mv	s1,a0
    7188:	0e054a63          	bltz	a0,727c <sys_open+0x1a8>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    718c:	02891703          	lh	a4,40(s2)
    7190:	00300793          	li	a5,3
    7194:	10f70863          	beq	a4,a5,72a4 <sys_open+0x1d0>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    7198:	00200793          	li	a5,2
    719c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    71a0:	0009aa23          	sw	zero,20(s3)
  }
  f->ip = ip;
    71a4:	0129a823          	sw	s2,16(s3)
  f->readable = !(omode & O_WRONLY);
    71a8:	f5c42783          	lw	a5,-164(s0)
    71ac:	0017c713          	xor	a4,a5,1
    71b0:	00177713          	and	a4,a4,1
    71b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    71b8:	0037f793          	and	a5,a5,3
    71bc:	00f037b3          	snez	a5,a5
    71c0:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    71c4:	00090513          	mv	a0,s2
    71c8:	ffffd097          	auipc	ra,0xffffd
    71cc:	5c8080e7          	jalr	1480(ra) # 4790 <iunlock>
  end_op();
    71d0:	ffffe097          	auipc	ra,0xffffe
    71d4:	298080e7          	jalr	664(ra) # 5468 <end_op>

  return fd;
}
    71d8:	00048513          	mv	a0,s1
    71dc:	0ac12083          	lw	ra,172(sp)
    71e0:	0a812403          	lw	s0,168(sp)
    71e4:	0a412483          	lw	s1,164(sp)
    71e8:	0a012903          	lw	s2,160(sp)
    71ec:	09c12983          	lw	s3,156(sp)
    71f0:	0b010113          	add	sp,sp,176
    71f4:	00008067          	ret
      end_op();
    71f8:	ffffe097          	auipc	ra,0xffffe
    71fc:	270080e7          	jalr	624(ra) # 5468 <end_op>
      return -1;
    7200:	fd9ff06f          	j	71d8 <sys_open+0x104>
    if((ip = namei(path)) == 0){
    7204:	f6040513          	add	a0,s0,-160
    7208:	ffffe097          	auipc	ra,0xffffe
    720c:	ef8080e7          	jalr	-264(ra) # 5100 <namei>
    7210:	00050913          	mv	s2,a0
    7214:	02050e63          	beqz	a0,7250 <sys_open+0x17c>
    ilock(ip);
    7218:	ffffd097          	auipc	ra,0xffffd
    721c:	474080e7          	jalr	1140(ra) # 468c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    7220:	02891703          	lh	a4,40(s2)
    7224:	00100793          	li	a5,1
    7228:	f2f716e3          	bne	a4,a5,7154 <sys_open+0x80>
    722c:	f5c42783          	lw	a5,-164(s0)
    7230:	f2078ee3          	beqz	a5,716c <sys_open+0x98>
      iunlockput(ip);
    7234:	00090513          	mv	a0,s2
    7238:	ffffd097          	auipc	ra,0xffffd
    723c:	758080e7          	jalr	1880(ra) # 4990 <iunlockput>
      end_op();
    7240:	ffffe097          	auipc	ra,0xffffe
    7244:	228080e7          	jalr	552(ra) # 5468 <end_op>
      return -1;
    7248:	fff00493          	li	s1,-1
    724c:	f8dff06f          	j	71d8 <sys_open+0x104>
      end_op();
    7250:	ffffe097          	auipc	ra,0xffffe
    7254:	218080e7          	jalr	536(ra) # 5468 <end_op>
      return -1;
    7258:	fff00493          	li	s1,-1
    725c:	f7dff06f          	j	71d8 <sys_open+0x104>
    iunlockput(ip);
    7260:	00090513          	mv	a0,s2
    7264:	ffffd097          	auipc	ra,0xffffd
    7268:	72c080e7          	jalr	1836(ra) # 4990 <iunlockput>
    end_op();
    726c:	ffffe097          	auipc	ra,0xffffe
    7270:	1fc080e7          	jalr	508(ra) # 5468 <end_op>
    return -1;
    7274:	fff00493          	li	s1,-1
    7278:	f61ff06f          	j	71d8 <sys_open+0x104>
      fileclose(f);
    727c:	00098513          	mv	a0,s3
    7280:	ffffe097          	auipc	ra,0xffffe
    7284:	7c0080e7          	jalr	1984(ra) # 5a40 <fileclose>
    iunlockput(ip);
    7288:	00090513          	mv	a0,s2
    728c:	ffffd097          	auipc	ra,0xffffd
    7290:	704080e7          	jalr	1796(ra) # 4990 <iunlockput>
    end_op();
    7294:	ffffe097          	auipc	ra,0xffffe
    7298:	1d4080e7          	jalr	468(ra) # 5468 <end_op>
    return -1;
    729c:	fff00493          	li	s1,-1
    72a0:	f39ff06f          	j	71d8 <sys_open+0x104>
    f->type = FD_DEVICE;
    72a4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    72a8:	02a91783          	lh	a5,42(s2)
    72ac:	00f99c23          	sh	a5,24(s3)
    72b0:	ef5ff06f          	j	71a4 <sys_open+0xd0>

000072b4 <sys_mkdir>:

uint32
sys_mkdir(void)
{
    72b4:	f7010113          	add	sp,sp,-144
    72b8:	08112623          	sw	ra,140(sp)
    72bc:	08812423          	sw	s0,136(sp)
    72c0:	09010413          	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    72c4:	ffffe097          	auipc	ra,0xffffe
    72c8:	0f4080e7          	jalr	244(ra) # 53b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    72cc:	08000613          	li	a2,128
    72d0:	f7040593          	add	a1,s0,-144
    72d4:	00000513          	li	a0,0
    72d8:	ffffc097          	auipc	ra,0xffffc
    72dc:	4a4080e7          	jalr	1188(ra) # 377c <argstr>
    72e0:	04054263          	bltz	a0,7324 <sys_mkdir+0x70>
    72e4:	00000693          	li	a3,0
    72e8:	00000613          	li	a2,0
    72ec:	00100593          	li	a1,1
    72f0:	f7040513          	add	a0,s0,-144
    72f4:	fffff097          	auipc	ra,0xfffff
    72f8:	5d8080e7          	jalr	1496(ra) # 68cc <create>
    72fc:	02050463          	beqz	a0,7324 <sys_mkdir+0x70>
    end_op();
    return -1;
  }
  iunlockput(ip);
    7300:	ffffd097          	auipc	ra,0xffffd
    7304:	690080e7          	jalr	1680(ra) # 4990 <iunlockput>
  end_op();
    7308:	ffffe097          	auipc	ra,0xffffe
    730c:	160080e7          	jalr	352(ra) # 5468 <end_op>
  return 0;
    7310:	00000513          	li	a0,0
}
    7314:	08c12083          	lw	ra,140(sp)
    7318:	08812403          	lw	s0,136(sp)
    731c:	09010113          	add	sp,sp,144
    7320:	00008067          	ret
    end_op();
    7324:	ffffe097          	auipc	ra,0xffffe
    7328:	144080e7          	jalr	324(ra) # 5468 <end_op>
    return -1;
    732c:	fff00513          	li	a0,-1
    7330:	fe5ff06f          	j	7314 <sys_mkdir+0x60>

00007334 <sys_mknod>:

uint32
sys_mknod(void)
{
    7334:	f6010113          	add	sp,sp,-160
    7338:	08112e23          	sw	ra,156(sp)
    733c:	08812c23          	sw	s0,152(sp)
    7340:	0a010413          	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    7344:	ffffe097          	auipc	ra,0xffffe
    7348:	074080e7          	jalr	116(ra) # 53b8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    734c:	08000613          	li	a2,128
    7350:	f7040593          	add	a1,s0,-144
    7354:	00000513          	li	a0,0
    7358:	ffffc097          	auipc	ra,0xffffc
    735c:	424080e7          	jalr	1060(ra) # 377c <argstr>
    7360:	06054063          	bltz	a0,73c0 <sys_mknod+0x8c>
     argint(1, &major) < 0 ||
    7364:	f6c40593          	add	a1,s0,-148
    7368:	00100513          	li	a0,1
    736c:	ffffc097          	auipc	ra,0xffffc
    7370:	398080e7          	jalr	920(ra) # 3704 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    7374:	04054663          	bltz	a0,73c0 <sys_mknod+0x8c>
     argint(2, &minor) < 0 ||
    7378:	f6840593          	add	a1,s0,-152
    737c:	00200513          	li	a0,2
    7380:	ffffc097          	auipc	ra,0xffffc
    7384:	384080e7          	jalr	900(ra) # 3704 <argint>
     argint(1, &major) < 0 ||
    7388:	02054c63          	bltz	a0,73c0 <sys_mknod+0x8c>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    738c:	f6841683          	lh	a3,-152(s0)
    7390:	f6c41603          	lh	a2,-148(s0)
    7394:	00300593          	li	a1,3
    7398:	f7040513          	add	a0,s0,-144
    739c:	fffff097          	auipc	ra,0xfffff
    73a0:	530080e7          	jalr	1328(ra) # 68cc <create>
     argint(2, &minor) < 0 ||
    73a4:	00050e63          	beqz	a0,73c0 <sys_mknod+0x8c>
    end_op();
    return -1;
  }
  iunlockput(ip);
    73a8:	ffffd097          	auipc	ra,0xffffd
    73ac:	5e8080e7          	jalr	1512(ra) # 4990 <iunlockput>
  end_op();
    73b0:	ffffe097          	auipc	ra,0xffffe
    73b4:	0b8080e7          	jalr	184(ra) # 5468 <end_op>
  return 0;
    73b8:	00000513          	li	a0,0
    73bc:	0100006f          	j	73cc <sys_mknod+0x98>
    end_op();
    73c0:	ffffe097          	auipc	ra,0xffffe
    73c4:	0a8080e7          	jalr	168(ra) # 5468 <end_op>
    return -1;
    73c8:	fff00513          	li	a0,-1
}
    73cc:	09c12083          	lw	ra,156(sp)
    73d0:	09812403          	lw	s0,152(sp)
    73d4:	0a010113          	add	sp,sp,160
    73d8:	00008067          	ret

000073dc <sys_chdir>:

uint32
sys_chdir(void)
{
    73dc:	f7010113          	add	sp,sp,-144
    73e0:	08112623          	sw	ra,140(sp)
    73e4:	08812423          	sw	s0,136(sp)
    73e8:	08912223          	sw	s1,132(sp)
    73ec:	09212023          	sw	s2,128(sp)
    73f0:	09010413          	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    73f4:	ffffb097          	auipc	ra,0xffffb
    73f8:	cdc080e7          	jalr	-804(ra) # 20d0 <myproc>
    73fc:	00050913          	mv	s2,a0
  
  begin_op();
    7400:	ffffe097          	auipc	ra,0xffffe
    7404:	fb8080e7          	jalr	-72(ra) # 53b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    7408:	08000613          	li	a2,128
    740c:	f7040593          	add	a1,s0,-144
    7410:	00000513          	li	a0,0
    7414:	ffffc097          	auipc	ra,0xffffc
    7418:	368080e7          	jalr	872(ra) # 377c <argstr>
    741c:	06054663          	bltz	a0,7488 <sys_chdir+0xac>
    7420:	f7040513          	add	a0,s0,-144
    7424:	ffffe097          	auipc	ra,0xffffe
    7428:	cdc080e7          	jalr	-804(ra) # 5100 <namei>
    742c:	00050493          	mv	s1,a0
    7430:	04050c63          	beqz	a0,7488 <sys_chdir+0xac>
    end_op();
    return -1;
  }
  ilock(ip);
    7434:	ffffd097          	auipc	ra,0xffffd
    7438:	258080e7          	jalr	600(ra) # 468c <ilock>
  if(ip->type != T_DIR){
    743c:	02849703          	lh	a4,40(s1)
    7440:	00100793          	li	a5,1
    7444:	04f71a63          	bne	a4,a5,7498 <sys_chdir+0xbc>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    7448:	00048513          	mv	a0,s1
    744c:	ffffd097          	auipc	ra,0xffffd
    7450:	344080e7          	jalr	836(ra) # 4790 <iunlock>
  iput(p->cwd);
    7454:	0ac92503          	lw	a0,172(s2)
    7458:	ffffd097          	auipc	ra,0xffffd
    745c:	3a8080e7          	jalr	936(ra) # 4800 <iput>
  end_op();
    7460:	ffffe097          	auipc	ra,0xffffe
    7464:	008080e7          	jalr	8(ra) # 5468 <end_op>
  p->cwd = ip;
    7468:	0a992623          	sw	s1,172(s2)
  return 0;
    746c:	00000513          	li	a0,0
}
    7470:	08c12083          	lw	ra,140(sp)
    7474:	08812403          	lw	s0,136(sp)
    7478:	08412483          	lw	s1,132(sp)
    747c:	08012903          	lw	s2,128(sp)
    7480:	09010113          	add	sp,sp,144
    7484:	00008067          	ret
    end_op();
    7488:	ffffe097          	auipc	ra,0xffffe
    748c:	fe0080e7          	jalr	-32(ra) # 5468 <end_op>
    return -1;
    7490:	fff00513          	li	a0,-1
    7494:	fddff06f          	j	7470 <sys_chdir+0x94>
    iunlockput(ip);
    7498:	00048513          	mv	a0,s1
    749c:	ffffd097          	auipc	ra,0xffffd
    74a0:	4f4080e7          	jalr	1268(ra) # 4990 <iunlockput>
    end_op();
    74a4:	ffffe097          	auipc	ra,0xffffe
    74a8:	fc4080e7          	jalr	-60(ra) # 5468 <end_op>
    return -1;
    74ac:	fff00513          	li	a0,-1
    74b0:	fc1ff06f          	j	7470 <sys_chdir+0x94>

000074b4 <sys_exec>:

uint32
sys_exec(void)
{
    74b4:	ed010113          	add	sp,sp,-304
    74b8:	12112623          	sw	ra,300(sp)
    74bc:	12812423          	sw	s0,296(sp)
    74c0:	12912223          	sw	s1,292(sp)
    74c4:	13212023          	sw	s2,288(sp)
    74c8:	11312e23          	sw	s3,284(sp)
    74cc:	11412c23          	sw	s4,280(sp)
    74d0:	13010413          	add	s0,sp,304
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint32 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    74d4:	08000613          	li	a2,128
    74d8:	f6040593          	add	a1,s0,-160
    74dc:	00000513          	li	a0,0
    74e0:	ffffc097          	auipc	ra,0xffffc
    74e4:	29c080e7          	jalr	668(ra) # 377c <argstr>
    74e8:	10054c63          	bltz	a0,7600 <sys_exec+0x14c>
    74ec:	edc40593          	add	a1,s0,-292
    74f0:	00100513          	li	a0,1
    74f4:	ffffc097          	auipc	ra,0xffffc
    74f8:	24c080e7          	jalr	588(ra) # 3740 <argaddr>
    74fc:	12054463          	bltz	a0,7624 <sys_exec+0x170>
    return -1;
  }
  // printf("exec %s!\n", path);
  memset(argv, 0, sizeof(argv));
    7500:	08000613          	li	a2,128
    7504:	00000593          	li	a1,0
    7508:	ee040513          	add	a0,s0,-288
    750c:	ffffa097          	auipc	ra,0xffffa
    7510:	96c080e7          	jalr	-1684(ra) # e78 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    7514:	ee040493          	add	s1,s0,-288
  memset(argv, 0, sizeof(argv));
    7518:	00048993          	mv	s3,s1
  for(i=0;; i++){
    751c:	00000913          	li	s2,0
    if(i >= NELEM(argv)){
    7520:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint32)*i, (uint32*)&uarg) < 0){
    7524:	00291513          	sll	a0,s2,0x2
    7528:	ed840593          	add	a1,s0,-296
    752c:	edc42783          	lw	a5,-292(s0)
    7530:	00f50533          	add	a0,a0,a5
    7534:	ffffc097          	auipc	ra,0xffffc
    7538:	0dc080e7          	jalr	220(ra) # 3610 <fetchaddr>
    753c:	04054063          	bltz	a0,757c <sys_exec+0xc8>
      goto bad;
    }
    if(uarg == 0){
    7540:	ed842783          	lw	a5,-296(s0)
    7544:	04078e63          	beqz	a5,75a0 <sys_exec+0xec>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    7548:	ffff9097          	auipc	ra,0xffff9
    754c:	650080e7          	jalr	1616(ra) # b98 <kalloc>
    7550:	00050593          	mv	a1,a0
    7554:	00a9a023          	sw	a0,0(s3)
    if(argv[i] == 0)
    7558:	08050863          	beqz	a0,75e8 <sys_exec+0x134>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    755c:	00001637          	lui	a2,0x1
    7560:	ed842503          	lw	a0,-296(s0)
    7564:	ffffc097          	auipc	ra,0xffffc
    7568:	12c080e7          	jalr	300(ra) # 3690 <fetchstr>
    756c:	00054863          	bltz	a0,757c <sys_exec+0xc8>
  for(i=0;; i++){
    7570:	00190913          	add	s2,s2,1
    if(i >= NELEM(argv)){
    7574:	00498993          	add	s3,s3,4
    7578:	fb4916e3          	bne	s2,s4,7524 <sys_exec+0x70>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    757c:	f6040913          	add	s2,s0,-160
    7580:	0004a503          	lw	a0,0(s1)
    7584:	06050a63          	beqz	a0,75f8 <sys_exec+0x144>
    kfree(argv[i]);
    7588:	ffff9097          	auipc	ra,0xffff9
    758c:	4bc080e7          	jalr	1212(ra) # a44 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    7590:	00448493          	add	s1,s1,4
    7594:	ff2496e3          	bne	s1,s2,7580 <sys_exec+0xcc>
  return -1;
    7598:	fff00513          	li	a0,-1
    759c:	0680006f          	j	7604 <sys_exec+0x150>
      argv[i] = 0;
    75a0:	00291913          	sll	s2,s2,0x2
    75a4:	fe090793          	add	a5,s2,-32
    75a8:	00878933          	add	s2,a5,s0
    75ac:	f0092023          	sw	zero,-256(s2)
  int ret = exec(path, argv);
    75b0:	ee040593          	add	a1,s0,-288
    75b4:	f6040513          	add	a0,s0,-160
    75b8:	fffff097          	auipc	ra,0xfffff
    75bc:	d7c080e7          	jalr	-644(ra) # 6334 <exec>
    75c0:	00050913          	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    75c4:	f6040993          	add	s3,s0,-160
    75c8:	0004a503          	lw	a0,0(s1)
    75cc:	00050a63          	beqz	a0,75e0 <sys_exec+0x12c>
    kfree(argv[i]);
    75d0:	ffff9097          	auipc	ra,0xffff9
    75d4:	474080e7          	jalr	1140(ra) # a44 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    75d8:	00448493          	add	s1,s1,4
    75dc:	ff3496e3          	bne	s1,s3,75c8 <sys_exec+0x114>
  return ret;
    75e0:	00090513          	mv	a0,s2
    75e4:	0200006f          	j	7604 <sys_exec+0x150>
      panic("sys_exec kalloc");
    75e8:	00001517          	auipc	a0,0x1
    75ec:	10450513          	add	a0,a0,260 # 86ec <userret+0x64c>
    75f0:	ffff9097          	auipc	ra,0xffff9
    75f4:	09c080e7          	jalr	156(ra) # 68c <panic>
  return -1;
    75f8:	fff00513          	li	a0,-1
    75fc:	0080006f          	j	7604 <sys_exec+0x150>
    return -1;
    7600:	fff00513          	li	a0,-1
}
    7604:	12c12083          	lw	ra,300(sp)
    7608:	12812403          	lw	s0,296(sp)
    760c:	12412483          	lw	s1,292(sp)
    7610:	12012903          	lw	s2,288(sp)
    7614:	11c12983          	lw	s3,284(sp)
    7618:	11812a03          	lw	s4,280(sp)
    761c:	13010113          	add	sp,sp,304
    7620:	00008067          	ret
    return -1;
    7624:	fff00513          	li	a0,-1
    7628:	fddff06f          	j	7604 <sys_exec+0x150>

0000762c <sys_pipe>:

uint32
sys_pipe(void)
{
    762c:	fd010113          	add	sp,sp,-48
    7630:	02112623          	sw	ra,44(sp)
    7634:	02812423          	sw	s0,40(sp)
    7638:	02912223          	sw	s1,36(sp)
    763c:	03010413          	add	s0,sp,48
  uint32 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    7640:	ffffb097          	auipc	ra,0xffffb
    7644:	a90080e7          	jalr	-1392(ra) # 20d0 <myproc>
    7648:	00050493          	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    764c:	fec40593          	add	a1,s0,-20
    7650:	00000513          	li	a0,0
    7654:	ffffc097          	auipc	ra,0xffffc
    7658:	0ec080e7          	jalr	236(ra) # 3740 <argaddr>
    return -1;
    765c:	fff00793          	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    7660:	10054263          	bltz	a0,7764 <sys_pipe+0x138>
  if(pipealloc(&rf, &wf) < 0)
    7664:	fe440593          	add	a1,s0,-28
    7668:	fe840513          	add	a0,s0,-24
    766c:	fffff097          	auipc	ra,0xfffff
    7670:	868080e7          	jalr	-1944(ra) # 5ed4 <pipealloc>
    return -1;
    7674:	fff00793          	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    7678:	0e054663          	bltz	a0,7764 <sys_pipe+0x138>
  fd0 = -1;
    767c:	fef42023          	sw	a5,-32(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    7680:	fe842503          	lw	a0,-24(s0)
    7684:	fffff097          	auipc	ra,0xfffff
    7688:	1d8080e7          	jalr	472(ra) # 685c <fdalloc>
    768c:	fea42023          	sw	a0,-32(s0)
    7690:	0a054c63          	bltz	a0,7748 <sys_pipe+0x11c>
    7694:	fe442503          	lw	a0,-28(s0)
    7698:	fffff097          	auipc	ra,0xfffff
    769c:	1c4080e7          	jalr	452(ra) # 685c <fdalloc>
    76a0:	fca42e23          	sw	a0,-36(s0)
    76a4:	08054663          	bltz	a0,7730 <sys_pipe+0x104>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    76a8:	00400693          	li	a3,4
    76ac:	fe040613          	add	a2,s0,-32
    76b0:	fec42583          	lw	a1,-20(s0)
    76b4:	02c4a503          	lw	a0,44(s1)
    76b8:	ffffa097          	auipc	ra,0xffffa
    76bc:	56c080e7          	jalr	1388(ra) # 1c24 <copyout>
    76c0:	02054463          	bltz	a0,76e8 <sys_pipe+0xbc>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    76c4:	00400693          	li	a3,4
    76c8:	fdc40613          	add	a2,s0,-36
    76cc:	fec42583          	lw	a1,-20(s0)
    76d0:	00458593          	add	a1,a1,4
    76d4:	02c4a503          	lw	a0,44(s1)
    76d8:	ffffa097          	auipc	ra,0xffffa
    76dc:	54c080e7          	jalr	1356(ra) # 1c24 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    76e0:	00000793          	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    76e4:	08055063          	bgez	a0,7764 <sys_pipe+0x138>
    p->ofile[fd0] = 0;
    76e8:	fe042783          	lw	a5,-32(s0)
    76ec:	01878793          	add	a5,a5,24
    76f0:	00279793          	sll	a5,a5,0x2
    76f4:	00f487b3          	add	a5,s1,a5
    76f8:	0007a623          	sw	zero,12(a5)
    p->ofile[fd1] = 0;
    76fc:	fdc42783          	lw	a5,-36(s0)
    7700:	01878793          	add	a5,a5,24
    7704:	00279793          	sll	a5,a5,0x2
    7708:	00f48533          	add	a0,s1,a5
    770c:	00052623          	sw	zero,12(a0)
    fileclose(rf);
    7710:	fe842503          	lw	a0,-24(s0)
    7714:	ffffe097          	auipc	ra,0xffffe
    7718:	32c080e7          	jalr	812(ra) # 5a40 <fileclose>
    fileclose(wf);
    771c:	fe442503          	lw	a0,-28(s0)
    7720:	ffffe097          	auipc	ra,0xffffe
    7724:	320080e7          	jalr	800(ra) # 5a40 <fileclose>
    return -1;
    7728:	fff00793          	li	a5,-1
    772c:	0380006f          	j	7764 <sys_pipe+0x138>
    if(fd0 >= 0)
    7730:	fe042783          	lw	a5,-32(s0)
    7734:	0007ca63          	bltz	a5,7748 <sys_pipe+0x11c>
      p->ofile[fd0] = 0;
    7738:	01878793          	add	a5,a5,24
    773c:	00279793          	sll	a5,a5,0x2
    7740:	00f487b3          	add	a5,s1,a5
    7744:	0007a623          	sw	zero,12(a5)
    fileclose(rf);
    7748:	fe842503          	lw	a0,-24(s0)
    774c:	ffffe097          	auipc	ra,0xffffe
    7750:	2f4080e7          	jalr	756(ra) # 5a40 <fileclose>
    fileclose(wf);
    7754:	fe442503          	lw	a0,-28(s0)
    7758:	ffffe097          	auipc	ra,0xffffe
    775c:	2e8080e7          	jalr	744(ra) # 5a40 <fileclose>
    return -1;
    7760:	fff00793          	li	a5,-1
}
    7764:	00078513          	mv	a0,a5
    7768:	02c12083          	lw	ra,44(sp)
    776c:	02812403          	lw	s0,40(sp)
    7770:	02412483          	lw	s1,36(sp)
    7774:	03010113          	add	sp,sp,48
    7778:	00008067          	ret
    777c:	0000                	.2byte	0x0
	...

00007780 <kernelvec>:
    7780:	f8010113          	add	sp,sp,-128
    7784:	00112023          	sw	ra,0(sp)
    7788:	00212223          	sw	sp,4(sp)
    778c:	00312423          	sw	gp,8(sp)
    7790:	00412623          	sw	tp,12(sp)
    7794:	00512823          	sw	t0,16(sp)
    7798:	00612a23          	sw	t1,20(sp)
    779c:	00712c23          	sw	t2,24(sp)
    77a0:	00812e23          	sw	s0,28(sp)
    77a4:	02912023          	sw	s1,32(sp)
    77a8:	02a12223          	sw	a0,36(sp)
    77ac:	02b12423          	sw	a1,40(sp)
    77b0:	02c12623          	sw	a2,44(sp)
    77b4:	02d12823          	sw	a3,48(sp)
    77b8:	02e12a23          	sw	a4,52(sp)
    77bc:	02f12c23          	sw	a5,56(sp)
    77c0:	03012e23          	sw	a6,60(sp)
    77c4:	05112023          	sw	a7,64(sp)
    77c8:	05212223          	sw	s2,68(sp)
    77cc:	05312423          	sw	s3,72(sp)
    77d0:	05412623          	sw	s4,76(sp)
    77d4:	05512823          	sw	s5,80(sp)
    77d8:	05612a23          	sw	s6,84(sp)
    77dc:	05712c23          	sw	s7,88(sp)
    77e0:	05812e23          	sw	s8,92(sp)
    77e4:	07912023          	sw	s9,96(sp)
    77e8:	07a12223          	sw	s10,100(sp)
    77ec:	07b12423          	sw	s11,104(sp)
    77f0:	07c12623          	sw	t3,108(sp)
    77f4:	07d12823          	sw	t4,112(sp)
    77f8:	07e12a23          	sw	t5,116(sp)
    77fc:	07f12c23          	sw	t6,120(sp)
    7800:	c69fb0ef          	jal	3468 <kerneltrap>
    7804:	00012083          	lw	ra,0(sp)
    7808:	00412103          	lw	sp,4(sp)
    780c:	00812183          	lw	gp,8(sp)
    7810:	01012283          	lw	t0,16(sp)
    7814:	01412303          	lw	t1,20(sp)
    7818:	01812383          	lw	t2,24(sp)
    781c:	01c12403          	lw	s0,28(sp)
    7820:	02012483          	lw	s1,32(sp)
    7824:	02412503          	lw	a0,36(sp)
    7828:	02812583          	lw	a1,40(sp)
    782c:	02c12603          	lw	a2,44(sp)
    7830:	03012683          	lw	a3,48(sp)
    7834:	03412703          	lw	a4,52(sp)
    7838:	03812783          	lw	a5,56(sp)
    783c:	03c12803          	lw	a6,60(sp)
    7840:	04012883          	lw	a7,64(sp)
    7844:	04412903          	lw	s2,68(sp)
    7848:	04812983          	lw	s3,72(sp)
    784c:	04c12a03          	lw	s4,76(sp)
    7850:	05012a83          	lw	s5,80(sp)
    7854:	05412b03          	lw	s6,84(sp)
    7858:	05812b83          	lw	s7,88(sp)
    785c:	05c12c03          	lw	s8,92(sp)
    7860:	06012c83          	lw	s9,96(sp)
    7864:	06412d03          	lw	s10,100(sp)
    7868:	06812d83          	lw	s11,104(sp)
    786c:	06c12e03          	lw	t3,108(sp)
    7870:	07012e83          	lw	t4,112(sp)
    7874:	07412f03          	lw	t5,116(sp)
    7878:	07812f83          	lw	t6,120(sp)
    787c:	08010113          	add	sp,sp,128
    7880:	10200073          	sret
    7884:	00000013          	nop
    7888:	00000013          	nop
    788c:	00000013          	nop

00007890 <timervec>:
    7890:	34051573          	csrrw	a0,mscratch,a0
    7894:	00b52023          	sw	a1,0(a0)
    7898:	00c52223          	sw	a2,4(a0)
    789c:	00d52423          	sw	a3,8(a0)
    78a0:	00e52623          	sw	a4,12(a0)
    78a4:	01052583          	lw	a1,16(a0)
    78a8:	01452603          	lw	a2,20(a0)
    78ac:	0005a683          	lw	a3,0(a1)
    78b0:	0045a703          	lw	a4,4(a1)
    78b4:	00c686b3          	add	a3,a3,a2
    78b8:	00c6b633          	sltu	a2,a3,a2
    78bc:	00c70733          	add	a4,a4,a2
    78c0:	fff00613          	li	a2,-1
    78c4:	00c5a023          	sw	a2,0(a1)
    78c8:	00e5a223          	sw	a4,4(a1)
    78cc:	00d5a023          	sw	a3,0(a1)
    78d0:	00200593          	li	a1,2
    78d4:	14459073          	csrw	sip,a1
    78d8:	00c52703          	lw	a4,12(a0)
    78dc:	00852683          	lw	a3,8(a0)
    78e0:	00452603          	lw	a2,4(a0)
    78e4:	00052583          	lw	a1,0(a0)
    78e8:	34051573          	csrrw	a0,mscratch,a0
    78ec:	30200073          	mret

000078f0 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    78f0:	ff010113          	add	sp,sp,-16
    78f4:	00112623          	sw	ra,12(sp)
    78f8:	00812423          	sw	s0,8(sp)
    78fc:	01010413          	add	s0,sp,16
  panic("plicinit");
    7900:	00001517          	auipc	a0,0x1
    7904:	dfc50513          	add	a0,a0,-516 # 86fc <userret+0x65c>
    7908:	ffff9097          	auipc	ra,0xffff9
    790c:	d84080e7          	jalr	-636(ra) # 68c <panic>

00007910 <plicinithart>:
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
}

void
plicinithart(void)
{
    7910:	ff010113          	add	sp,sp,-16
    7914:	00112623          	sw	ra,12(sp)
    7918:	00812423          	sw	s0,8(sp)
    791c:	01010413          	add	s0,sp,16
  panic("plicinithart");
    7920:	00001517          	auipc	a0,0x1
    7924:	de850513          	add	a0,a0,-536 # 8708 <userret+0x668>
    7928:	ffff9097          	auipc	ra,0xffff9
    792c:	d64080e7          	jalr	-668(ra) # 68c <panic>

00007930 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint32
plic_pending(void)
{
    7930:	ff010113          	add	sp,sp,-16
    7934:	00112623          	sw	ra,12(sp)
    7938:	00812423          	sw	s0,8(sp)
    793c:	01010413          	add	s0,sp,16
  panic("plic_pending");
    7940:	00001517          	auipc	a0,0x1
    7944:	dd850513          	add	a0,a0,-552 # 8718 <userret+0x678>
    7948:	ffff9097          	auipc	ra,0xffff9
    794c:	d44080e7          	jalr	-700(ra) # 68c <panic>

00007950 <plic_claim>:
}

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    7950:	ff010113          	add	sp,sp,-16
    7954:	00112623          	sw	ra,12(sp)
    7958:	00812423          	sw	s0,8(sp)
    795c:	01010413          	add	s0,sp,16
  panic("plic_claim");
    7960:	00001517          	auipc	a0,0x1
    7964:	dc850513          	add	a0,a0,-568 # 8728 <userret+0x688>
    7968:	ffff9097          	auipc	ra,0xffff9
    796c:	d24080e7          	jalr	-732(ra) # 68c <panic>

00007970 <plic_complete>:
}

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    7970:	ff010113          	add	sp,sp,-16
    7974:	00112623          	sw	ra,12(sp)
    7978:	00812423          	sw	s0,8(sp)
    797c:	01010413          	add	s0,sp,16
  panic("plic_complete");
    7980:	00001517          	auipc	a0,0x1
    7984:	db450513          	add	a0,a0,-588 # 8734 <userret+0x694>
    7988:	ffff9097          	auipc	ra,0xffff9
    798c:	d04080e7          	jalr	-764(ra) # 68c <panic>

00007990 <virtio_disk_init>:
}  __attribute__ ((aligned (PGSIZE)))  disk;
  

void
virtio_disk_init(void)
{
    7990:	ff010113          	add	sp,sp,-16
    7994:	00112623          	sw	ra,12(sp)
    7998:	00812423          	sw	s0,8(sp)
    799c:	01010413          	add	s0,sp,16
  initlock(&disk.vdisk_lock, "virtio_disk");
    79a0:	00001597          	auipc	a1,0x1
    79a4:	da458593          	add	a1,a1,-604 # 8744 <userret+0x6a4>
    79a8:	00018517          	auipc	a0,0x18
    79ac:	66050513          	add	a0,a0,1632 # 20008 <disk+0x8>
    79b0:	ffff9097          	auipc	ra,0xffff9
    79b4:	270080e7          	jalr	624(ra) # c20 <initlock>
  disk.free = 1;
    79b8:	00100793          	li	a5,1
    79bc:	00018717          	auipc	a4,0x18
    79c0:	64f70c23          	sb	a5,1624(a4) # 20014 <disk+0x14>
}
    79c4:	00c12083          	lw	ra,12(sp)
    79c8:	00812403          	lw	s0,8(sp)
    79cc:	01010113          	add	sp,sp,16
    79d0:	00008067          	ret

000079d4 <virtio_disk_rw>:
#define EDISK_WEN   ((volatile unsigned int*)0xf8000008)
#define EDISK_DATA  ((volatile unsigned int*)0xf8000010)

void
virtio_disk_rw(struct buf *b, int write)
{
    79d4:	fe010113          	add	sp,sp,-32
    79d8:	00112e23          	sw	ra,28(sp)
    79dc:	00812c23          	sw	s0,24(sp)
    79e0:	00912a23          	sw	s1,20(sp)
    79e4:	01212823          	sw	s2,16(sp)
    79e8:	01312623          	sw	s3,12(sp)
    79ec:	01412423          	sw	s4,8(sp)
    79f0:	01512223          	sw	s5,4(sp)
    79f4:	02010413          	add	s0,sp,32
    79f8:	00050913          	mv	s2,a0
    79fc:	00058493          	mv	s1,a1
  // printf("virtio_disk_rw\n");
  acquire(&disk.vdisk_lock);
    7a00:	00018517          	auipc	a0,0x18
    7a04:	60850513          	add	a0,a0,1544 # 20008 <disk+0x8>
    7a08:	ffff9097          	auipc	ra,0xffff9
    7a0c:	39c080e7          	jalr	924(ra) # da4 <acquire>
  if (disk.free) {
    7a10:	00018997          	auipc	s3,0x18
    7a14:	5f098993          	add	s3,s3,1520 # 20000 <disk>
  while (1) {
    if ((idx = alloc_desc()) >= 0) {
      break;
    }
    // 奪えなかったらfreeで寝る
    sleep(&disk.free, &disk.vdisk_lock);
    7a18:	00018a97          	auipc	s5,0x18
    7a1c:	5f0a8a93          	add	s5,s5,1520 # 20008 <disk+0x8>
    7a20:	00018a17          	auipc	s4,0x18
    7a24:	5f4a0a13          	add	s4,s4,1524 # 20014 <disk+0x14>
    7a28:	0900006f          	j	7ab8 <virtio_disk_rw+0xe4>
    *EDISK_ADDR = addr;
    if (write) {
      *EDISK_DATA = ((unsigned int*)b->data)[i];
      // printf("disk_rw(%d): %p <= %p... %d\n", write, addr, ((unsigned int*)b->data)[i], i);
    } else {
      ((unsigned int*)b->data)[i] = *EDISK_DATA;
    7a2c:	01072683          	lw	a3,16(a4)
    7a30:	00d7a023          	sw	a3,0(a5)
  for (int i = 0; i < BSIZE / 4; i++) {
    7a34:	00478793          	add	a5,a5,4
    7a38:	00b78e63          	beq	a5,a1,7a54 <virtio_disk_rw+0x80>
    int addr = offset + i * 4;
    7a3c:	00f606b3          	add	a3,a2,a5
    *EDISK_ADDR = addr;
    7a40:	00d72023          	sw	a3,0(a4)
    if (write) {
    7a44:	fe0484e3          	beqz	s1,7a2c <virtio_disk_rw+0x58>
      *EDISK_DATA = ((unsigned int*)b->data)[i];
    7a48:	0007a683          	lw	a3,0(a5)
    7a4c:	00d72823          	sw	a3,16(a4)
    7a50:	fe5ff06f          	j	7a34 <virtio_disk_rw+0x60>
      // printf("disk_rw(%d): %p => %p... %d\n", write, addr, ((unsigned int*)b->data)[i], i);
    }
  }

  b->disk = 0;
    7a54:	00092223          	sw	zero,4(s2)
  disk.free = 1;
    7a58:	00100793          	li	a5,1
    7a5c:	00018717          	auipc	a4,0x18
    7a60:	5af70c23          	sb	a5,1464(a4) # 20014 <disk+0x14>
  wakeup(&disk.free);
    7a64:	00018517          	auipc	a0,0x18
    7a68:	5b050513          	add	a0,a0,1456 # 20014 <disk+0x14>
    7a6c:	ffffb097          	auipc	ra,0xffffb
    7a70:	2c4080e7          	jalr	708(ra) # 2d30 <wakeup>
  free_desc(idx);

  release(&disk.vdisk_lock);
    7a74:	00018517          	auipc	a0,0x18
    7a78:	59450513          	add	a0,a0,1428 # 20008 <disk+0x8>
    7a7c:	ffff9097          	auipc	ra,0xffff9
    7a80:	39c080e7          	jalr	924(ra) # e18 <release>
}
    7a84:	01c12083          	lw	ra,28(sp)
    7a88:	01812403          	lw	s0,24(sp)
    7a8c:	01412483          	lw	s1,20(sp)
    7a90:	01012903          	lw	s2,16(sp)
    7a94:	00c12983          	lw	s3,12(sp)
    7a98:	00812a03          	lw	s4,8(sp)
    7a9c:	00412a83          	lw	s5,4(sp)
    7aa0:	02010113          	add	sp,sp,32
    7aa4:	00008067          	ret
    sleep(&disk.free, &disk.vdisk_lock);
    7aa8:	000a8593          	mv	a1,s5
    7aac:	000a0513          	mv	a0,s4
    7ab0:	ffffb097          	auipc	ra,0xffffb
    7ab4:	064080e7          	jalr	100(ra) # 2b14 <sleep>
  if (disk.free) {
    7ab8:	0149c783          	lbu	a5,20(s3)
    7abc:	fe0786e3          	beqz	a5,7aa8 <virtio_disk_rw+0xd4>
    disk.free = 0;
    7ac0:	00018797          	auipc	a5,0x18
    7ac4:	54078a23          	sb	zero,1364(a5) # 20014 <disk+0x14>
  b->disk = 1;
    7ac8:	00100793          	li	a5,1
    7acc:	00f92223          	sw	a5,4(s2)
  unsigned int offset = b->blockno * BSIZE;
    7ad0:	00c92603          	lw	a2,12(s2)
    7ad4:	00a61613          	sll	a2,a2,0xa
  *EDISK_WEN = write ? 1 : 0;
    7ad8:	009037b3          	snez	a5,s1
    7adc:	f8000737          	lui	a4,0xf8000
    7ae0:	00f72423          	sw	a5,8(a4) # f8000008 <end+0xf7fdeff4>
  for (int i = 0; i < BSIZE / 4; i++) {
    7ae4:	03890793          	add	a5,s2,56
    7ae8:	43890593          	add	a1,s2,1080
    int addr = offset + i * 4;
    7aec:	41260633          	sub	a2,a2,s2
    7af0:	fc860613          	add	a2,a2,-56 # fc8 <strncmp+0x48>
    7af4:	f49ff06f          	j	7a3c <virtio_disk_rw+0x68>

00007af8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    7af8:	ff010113          	add	sp,sp,-16
    7afc:	00112623          	sw	ra,12(sp)
    7b00:	00812423          	sw	s0,8(sp)
    7b04:	01010413          	add	s0,sp,16
  panic("virtio_disk_intr");
    7b08:	00001517          	auipc	a0,0x1
    7b0c:	c4850513          	add	a0,a0,-952 # 8750 <userret+0x6b0>
    7b10:	ffff9097          	auipc	ra,0xffff9
    7b14:	b7c080e7          	jalr	-1156(ra) # 68c <panic>
	...

00008000 <trampoline>:
    8000:	14051573          	csrrw	a0,sscratch,a0
    8004:	00152a23          	sw	ra,20(a0)
    8008:	00252c23          	sw	sp,24(a0)
    800c:	00352e23          	sw	gp,28(a0)
    8010:	02452023          	sw	tp,32(a0)
    8014:	02552223          	sw	t0,36(a0)
    8018:	02652423          	sw	t1,40(a0)
    801c:	02752623          	sw	t2,44(a0)
    8020:	02852823          	sw	s0,48(a0)
    8024:	02952a23          	sw	s1,52(a0)
    8028:	02b52e23          	sw	a1,60(a0)
    802c:	04c52023          	sw	a2,64(a0)
    8030:	04d52223          	sw	a3,68(a0)
    8034:	04e52423          	sw	a4,72(a0)
    8038:	04f52623          	sw	a5,76(a0)
    803c:	05052823          	sw	a6,80(a0)
    8040:	05152a23          	sw	a7,84(a0)
    8044:	05252c23          	sw	s2,88(a0)
    8048:	05352e23          	sw	s3,92(a0)
    804c:	07452023          	sw	s4,96(a0)
    8050:	07552223          	sw	s5,100(a0)
    8054:	07652423          	sw	s6,104(a0)
    8058:	07752623          	sw	s7,108(a0)
    805c:	07852823          	sw	s8,112(a0)
    8060:	07952a23          	sw	s9,116(a0)
    8064:	07a52c23          	sw	s10,120(a0)
    8068:	07b52e23          	sw	s11,124(a0)
    806c:	09c52023          	sw	t3,128(a0)
    8070:	09d52223          	sw	t4,132(a0)
    8074:	09e52423          	sw	t5,136(a0)
    8078:	09f52623          	sw	t6,140(a0)
    807c:	140022f3          	csrr	t0,sscratch
    8080:	02552c23          	sw	t0,56(a0)
    8084:	00452103          	lw	sp,4(a0)
    8088:	01052203          	lw	tp,16(a0)
    808c:	00852283          	lw	t0,8(a0)
    8090:	00052303          	lw	t1,0(a0)
    8094:	18031073          	csrw	satp,t1
    8098:	12000073          	sfence.vma
    809c:	00028067          	jr	t0

000080a0 <userret>:
    80a0:	18059073          	csrw	satp,a1
    80a4:	12000073          	sfence.vma
    80a8:	03852283          	lw	t0,56(a0)
    80ac:	14029073          	csrw	sscratch,t0
    80b0:	01452083          	lw	ra,20(a0)
    80b4:	01852103          	lw	sp,24(a0)
    80b8:	01c52183          	lw	gp,28(a0)
    80bc:	02052203          	lw	tp,32(a0)
    80c0:	02452283          	lw	t0,36(a0)
    80c4:	02852303          	lw	t1,40(a0)
    80c8:	02c52383          	lw	t2,44(a0)
    80cc:	03052403          	lw	s0,48(a0)
    80d0:	03452483          	lw	s1,52(a0)
    80d4:	03c52583          	lw	a1,60(a0)
    80d8:	04052603          	lw	a2,64(a0)
    80dc:	04452683          	lw	a3,68(a0)
    80e0:	04852703          	lw	a4,72(a0)
    80e4:	04c52783          	lw	a5,76(a0)
    80e8:	05052803          	lw	a6,80(a0)
    80ec:	05452883          	lw	a7,84(a0)
    80f0:	05852903          	lw	s2,88(a0)
    80f4:	05c52983          	lw	s3,92(a0)
    80f8:	06052a03          	lw	s4,96(a0)
    80fc:	06452a83          	lw	s5,100(a0)
    8100:	06852b03          	lw	s6,104(a0)
    8104:	06c52b83          	lw	s7,108(a0)
    8108:	07052c03          	lw	s8,112(a0)
    810c:	07452c83          	lw	s9,116(a0)
    8110:	07852d03          	lw	s10,120(a0)
    8114:	07c52d83          	lw	s11,124(a0)
    8118:	08052e03          	lw	t3,128(a0)
    811c:	08452e83          	lw	t4,132(a0)
    8120:	08852f03          	lw	t5,136(a0)
    8124:	08c52f83          	lw	t6,140(a0)
    8128:	14051573          	csrrw	a0,sscratch,a0
    812c:	10200073          	sret
