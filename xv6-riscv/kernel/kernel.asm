
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	addi	sp,sp,-1472 # 80008a40 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8b070713          	addi	a4,a4,-1872 # 80008900 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	ade78793          	addi	a5,a5,-1314 # 80005b40 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca8f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	372080e7          	jalr	882(ra) # 8000249c <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8bc50513          	addi	a0,a0,-1860 # 80010a40 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	8ac48493          	addi	s1,s1,-1876 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	93c90913          	addi	s2,s2,-1732 # 80010ad8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00001097          	auipc	ra,0x1
    800001b8:	7e2080e7          	jalr	2018(ra) # 80001996 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	12a080e7          	jalr	298(ra) # 800022e6 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	e74080e7          	jalr	-396(ra) # 8000203e <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	86270713          	addi	a4,a4,-1950 # 80010a40 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	236080e7          	jalr	566(ra) # 80002446 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	81850513          	addi	a0,a0,-2024 # 80010a40 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	80250513          	addi	a0,a0,-2046 # 80010a40 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	86f72523          	sw	a5,-1942(a4) # 80010ad8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	77850513          	addi	a0,a0,1912 # 80010a40 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	204080e7          	jalr	516(ra) # 800024f2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	74a50513          	addi	a0,a0,1866 # 80010a40 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	72670713          	addi	a4,a4,1830 # 80010a40 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	6fc78793          	addi	a5,a5,1788 # 80010a40 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7667a783          	lw	a5,1894(a5) # 80010ad8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6ba70713          	addi	a4,a4,1722 # 80010a40 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	6aa48493          	addi	s1,s1,1706 # 80010a40 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	66e70713          	addi	a4,a4,1646 # 80010a40 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6ef72c23          	sw	a5,1784(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	63278793          	addi	a5,a5,1586 # 80010a40 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	6ac7a523          	sw	a2,1706(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	69e50513          	addi	a0,a0,1694 # 80010ad8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	c60080e7          	jalr	-928(ra) # 800020a2 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5e450513          	addi	a0,a0,1508 # 80010a40 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00020797          	auipc	a5,0x20
    80000478:	76478793          	addi	a5,a5,1892 # 80020bd8 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5a07ac23          	sw	zero,1464(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b7e50513          	addi	a0,a0,-1154 # 800080e8 <digits+0xa8>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	34f72223          	sw	a5,836(a4) # 800088c0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	548dad83          	lw	s11,1352(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	addi	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	4f250513          	addi	a0,a0,1266 # 80010ae8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srli	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	slli	s2,s2,0x4
    800006d4:	34fd                	addiw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	addi	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	addi	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	addi	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	addi	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	39450513          	addi	a0,a0,916 # 80010ae8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	37848493          	addi	s1,s1,888 # 80010ae8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	addi	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	addi	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	addi	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	addi	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	33850513          	addi	a0,a0,824 # 80010b08 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	addi	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0c47a783          	lw	a5,196(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	andi	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	addi	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0947b783          	ld	a5,148(a5) # 800088c8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	09473703          	ld	a4,148(a4) # 800088d0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	addi	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	2aaa0a13          	addi	s4,s4,682 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	06248493          	addi	s1,s1,98 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	06298993          	addi	s3,s3,98 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	andi	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	andi	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	addi	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	812080e7          	jalr	-2030(ra) # 800020a2 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	addi	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	addi	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	addi	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	23c50513          	addi	a0,a0,572 # 80010b08 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fe47a783          	lw	a5,-28(a5) # 800088c0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fea73703          	ld	a4,-22(a4) # 800088d0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fda7b783          	ld	a5,-38(a5) # 800088c8 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	20e98993          	addi	s3,s3,526 # 80010b08 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fc648493          	addi	s1,s1,-58 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fc690913          	addi	s2,s2,-58 # 800088d0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	724080e7          	jalr	1828(ra) # 8000203e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1d848493          	addi	s1,s1,472 # 80010b08 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f8e7b623          	sd	a4,-116(a5) # 800088d0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	addi	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	andi	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	15248493          	addi	s1,s1,338 # 80010b08 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	37878793          	addi	a5,a5,888 # 80021d70 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	12890913          	addi	s2,s2,296 # 80010b40 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	addi	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	08a50513          	addi	a0,a0,138 # 80010b40 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	2a650513          	addi	a0,a0,678 # 80021d70 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	05448493          	addi	s1,s1,84 # 80010b40 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	03c50513          	addi	a0,a0,60 # 80010b40 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	01050513          	addi	a0,a0,16 # 80010b40 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	addi	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	e0e080e7          	jalr	-498(ra) # 8000197a <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	ddc080e7          	jalr	-548(ra) # 8000197a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	dd0080e7          	jalr	-560(ra) # 8000197a <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	db8080e7          	jalr	-584(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srli	s1,s1,0x1
    80000bcc:	8885                	andi	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	d78080e7          	jalr	-648(ra) # 8000197a <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	addi	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d4c080e7          	jalr	-692(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addiw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	addi	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	addi	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	addi	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	addi	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	slli	a2,a2,0x20
    80000cda:	9201                	srli	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	addi	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	addi	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	slli	a3,a3,0x20
    80000cfe:	9281                	srli	a3,a3,0x20
    80000d00:	0685                	addi	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	addi	a0,a0,1
    80000d12:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	slli	a2,a2,0x20
    80000d38:	9201                	srli	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	addi	a1,a1,1
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd291>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	slli	a3,a2,0x20
    80000d5a:	9281                	srli	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addiw	a5,a2,-1
    80000d6a:	1782                	slli	a5,a5,0x20
    80000d6c:	9381                	srli	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	addi	a4,a4,-1
    80000d76:	16fd                	addi	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addiw	a2,a2,-1
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addiw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	addi	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	addi	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addiw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	addi	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	a5670713          	addi	a4,a4,-1450 # 800088d8 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	23850513          	addi	a0,a0,568 # 800080d8 <digits+0x98>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0c8080e7          	jalr	200(ra) # 80000f78 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	77c080e7          	jalr	1916(ra) # 80002634 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	cc0080e7          	jalr	-832(ra) # 80005b80 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fc4080e7          	jalr	-60(ra) # 80001e8c <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	20850513          	addi	a0,a0,520 # 800080e8 <digits+0xa8>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f00:	00000097          	auipc	ra,0x0
    80000f04:	ba6080e7          	jalr	-1114(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f08:	00000097          	auipc	ra,0x0
    80000f0c:	326080e7          	jalr	806(ra) # 8000122e <kvminit>
    kvminithart();   // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	068080e7          	jalr	104(ra) # 80000f78 <kvminithart>
    procinit();      // process table
    80000f18:	00001097          	auipc	ra,0x1
    80000f1c:	99e080e7          	jalr	-1634(ra) # 800018b6 <procinit>
    trapinit();      // trap vectors
    80000f20:	00001097          	auipc	ra,0x1
    80000f24:	6ec080e7          	jalr	1772(ra) # 8000260c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	70c080e7          	jalr	1804(ra) # 80002634 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f30:	00005097          	auipc	ra,0x5
    80000f34:	c3a080e7          	jalr	-966(ra) # 80005b6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f38:	00005097          	auipc	ra,0x5
    80000f3c:	c48080e7          	jalr	-952(ra) # 80005b80 <plicinithart>
    binit();         // buffer cache
    80000f40:	00002097          	auipc	ra,0x2
    80000f44:	e42080e7          	jalr	-446(ra) # 80002d82 <binit>
    iinit();         // inode table
    80000f48:	00002097          	auipc	ra,0x2
    80000f4c:	4e0080e7          	jalr	1248(ra) # 80003428 <iinit>
    fileinit();      // file table
    80000f50:	00003097          	auipc	ra,0x3
    80000f54:	456080e7          	jalr	1110(ra) # 800043a6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f58:	00005097          	auipc	ra,0x5
    80000f5c:	d30080e7          	jalr	-720(ra) # 80005c88 <virtio_disk_init>
    userinit();      // first user process
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	d0e080e7          	jalr	-754(ra) # 80001c6e <userinit>
    __sync_synchronize();
    80000f68:	0ff0000f          	fence
    started = 1;
    80000f6c:	4785                	li	a5,1
    80000f6e:	00008717          	auipc	a4,0x8
    80000f72:	96f72523          	sw	a5,-1686(a4) # 800088d8 <started>
    80000f76:	bf89                	j	80000ec8 <main+0x56>

0000000080000f78 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f78:	1141                	addi	sp,sp,-16
    80000f7a:	e422                	sd	s0,8(sp)
    80000f7c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f7e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f82:	00008797          	auipc	a5,0x8
    80000f86:	95e7b783          	ld	a5,-1698(a5) # 800088e0 <kernel_pagetable>
    80000f8a:	83b1                	srli	a5,a5,0xc
    80000f8c:	577d                	li	a4,-1
    80000f8e:	177e                	slli	a4,a4,0x3f
    80000f90:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f92:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f96:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f9a:	6422                	ld	s0,8(sp)
    80000f9c:	0141                	addi	sp,sp,16
    80000f9e:	8082                	ret

0000000080000fa0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa0:	7139                	addi	sp,sp,-64
    80000fa2:	fc06                	sd	ra,56(sp)
    80000fa4:	f822                	sd	s0,48(sp)
    80000fa6:	f426                	sd	s1,40(sp)
    80000fa8:	f04a                	sd	s2,32(sp)
    80000faa:	ec4e                	sd	s3,24(sp)
    80000fac:	e852                	sd	s4,16(sp)
    80000fae:	e456                	sd	s5,8(sp)
    80000fb0:	e05a                	sd	s6,0(sp)
    80000fb2:	0080                	addi	s0,sp,64
    80000fb4:	84aa                	mv	s1,a0
    80000fb6:	89ae                	mv	s3,a1
    80000fb8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fba:	57fd                	li	a5,-1
    80000fbc:	83e9                	srli	a5,a5,0x1a
    80000fbe:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc2:	04b7f263          	bgeu	a5,a1,80001006 <walk+0x66>
    panic("walk");
    80000fc6:	00007517          	auipc	a0,0x7
    80000fca:	12a50513          	addi	a0,a0,298 # 800080f0 <digits+0xb0>
    80000fce:	fffff097          	auipc	ra,0xfffff
    80000fd2:	56e080e7          	jalr	1390(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fd6:	060a8663          	beqz	s5,80001042 <walk+0xa2>
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	b08080e7          	jalr	-1272(ra) # 80000ae2 <kalloc>
    80000fe2:	84aa                	mv	s1,a0
    80000fe4:	c529                	beqz	a0,8000102e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fe6:	6605                	lui	a2,0x1
    80000fe8:	4581                	li	a1,0
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	ce4080e7          	jalr	-796(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff2:	00c4d793          	srli	a5,s1,0xc
    80000ff6:	07aa                	slli	a5,a5,0xa
    80000ff8:	0017e793          	ori	a5,a5,1
    80000ffc:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001000:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd287>
    80001002:	036a0063          	beq	s4,s6,80001022 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001006:	0149d933          	srl	s2,s3,s4
    8000100a:	1ff97913          	andi	s2,s2,511
    8000100e:	090e                	slli	s2,s2,0x3
    80001010:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001012:	00093483          	ld	s1,0(s2)
    80001016:	0014f793          	andi	a5,s1,1
    8000101a:	dfd5                	beqz	a5,80000fd6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000101c:	80a9                	srli	s1,s1,0xa
    8000101e:	04b2                	slli	s1,s1,0xc
    80001020:	b7c5                	j	80001000 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001022:	00c9d513          	srli	a0,s3,0xc
    80001026:	1ff57513          	andi	a0,a0,511
    8000102a:	050e                	slli	a0,a0,0x3
    8000102c:	9526                	add	a0,a0,s1
}
    8000102e:	70e2                	ld	ra,56(sp)
    80001030:	7442                	ld	s0,48(sp)
    80001032:	74a2                	ld	s1,40(sp)
    80001034:	7902                	ld	s2,32(sp)
    80001036:	69e2                	ld	s3,24(sp)
    80001038:	6a42                	ld	s4,16(sp)
    8000103a:	6aa2                	ld	s5,8(sp)
    8000103c:	6b02                	ld	s6,0(sp)
    8000103e:	6121                	addi	sp,sp,64
    80001040:	8082                	ret
        return 0;
    80001042:	4501                	li	a0,0
    80001044:	b7ed                	j	8000102e <walk+0x8e>

0000000080001046 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001046:	57fd                	li	a5,-1
    80001048:	83e9                	srli	a5,a5,0x1a
    8000104a:	00b7f463          	bgeu	a5,a1,80001052 <walkaddr+0xc>
    return 0;
    8000104e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001050:	8082                	ret
{
    80001052:	1141                	addi	sp,sp,-16
    80001054:	e406                	sd	ra,8(sp)
    80001056:	e022                	sd	s0,0(sp)
    80001058:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000105a:	4601                	li	a2,0
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	f44080e7          	jalr	-188(ra) # 80000fa0 <walk>
  if(pte == 0)
    80001064:	c105                	beqz	a0,80001084 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001066:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001068:	0117f693          	andi	a3,a5,17
    8000106c:	4745                	li	a4,17
    return 0;
    8000106e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001070:	00e68663          	beq	a3,a4,8000107c <walkaddr+0x36>
}
    80001074:	60a2                	ld	ra,8(sp)
    80001076:	6402                	ld	s0,0(sp)
    80001078:	0141                	addi	sp,sp,16
    8000107a:	8082                	ret
  pa = PTE2PA(*pte);
    8000107c:	83a9                	srli	a5,a5,0xa
    8000107e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001082:	bfcd                	j	80001074 <walkaddr+0x2e>
    return 0;
    80001084:	4501                	li	a0,0
    80001086:	b7fd                	j	80001074 <walkaddr+0x2e>

0000000080001088 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001088:	715d                	addi	sp,sp,-80
    8000108a:	e486                	sd	ra,72(sp)
    8000108c:	e0a2                	sd	s0,64(sp)
    8000108e:	fc26                	sd	s1,56(sp)
    80001090:	f84a                	sd	s2,48(sp)
    80001092:	f44e                	sd	s3,40(sp)
    80001094:	f052                	sd	s4,32(sp)
    80001096:	ec56                	sd	s5,24(sp)
    80001098:	e85a                	sd	s6,16(sp)
    8000109a:	e45e                	sd	s7,8(sp)
    8000109c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000109e:	c639                	beqz	a2,800010ec <mappages+0x64>
    800010a0:	8aaa                	mv	s5,a0
    800010a2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010a4:	777d                	lui	a4,0xfffff
    800010a6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010aa:	fff58993          	addi	s3,a1,-1
    800010ae:	99b2                	add	s3,s3,a2
    800010b0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b4:	893e                	mv	s2,a5
    800010b6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ba:	6b85                	lui	s7,0x1
    800010bc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c0:	4605                	li	a2,1
    800010c2:	85ca                	mv	a1,s2
    800010c4:	8556                	mv	a0,s5
    800010c6:	00000097          	auipc	ra,0x0
    800010ca:	eda080e7          	jalr	-294(ra) # 80000fa0 <walk>
    800010ce:	cd1d                	beqz	a0,8000110c <mappages+0x84>
    if(*pte & PTE_V)
    800010d0:	611c                	ld	a5,0(a0)
    800010d2:	8b85                	andi	a5,a5,1
    800010d4:	e785                	bnez	a5,800010fc <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010d6:	80b1                	srli	s1,s1,0xc
    800010d8:	04aa                	slli	s1,s1,0xa
    800010da:	0164e4b3          	or	s1,s1,s6
    800010de:	0014e493          	ori	s1,s1,1
    800010e2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e4:	05390063          	beq	s2,s3,80001124 <mappages+0x9c>
    a += PGSIZE;
    800010e8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ea:	bfc9                	j	800010bc <mappages+0x34>
    panic("mappages: size");
    800010ec:	00007517          	auipc	a0,0x7
    800010f0:	00c50513          	addi	a0,a0,12 # 800080f8 <digits+0xb8>
    800010f4:	fffff097          	auipc	ra,0xfffff
    800010f8:	448080e7          	jalr	1096(ra) # 8000053c <panic>
      panic("mappages: remap");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	00c50513          	addi	a0,a0,12 # 80008108 <digits+0xc8>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      return -1;
    8000110c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000110e:	60a6                	ld	ra,72(sp)
    80001110:	6406                	ld	s0,64(sp)
    80001112:	74e2                	ld	s1,56(sp)
    80001114:	7942                	ld	s2,48(sp)
    80001116:	79a2                	ld	s3,40(sp)
    80001118:	7a02                	ld	s4,32(sp)
    8000111a:	6ae2                	ld	s5,24(sp)
    8000111c:	6b42                	ld	s6,16(sp)
    8000111e:	6ba2                	ld	s7,8(sp)
    80001120:	6161                	addi	sp,sp,80
    80001122:	8082                	ret
  return 0;
    80001124:	4501                	li	a0,0
    80001126:	b7e5                	j	8000110e <mappages+0x86>

0000000080001128 <kvmmap>:
{
    80001128:	1141                	addi	sp,sp,-16
    8000112a:	e406                	sd	ra,8(sp)
    8000112c:	e022                	sd	s0,0(sp)
    8000112e:	0800                	addi	s0,sp,16
    80001130:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001132:	86b2                	mv	a3,a2
    80001134:	863e                	mv	a2,a5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	f52080e7          	jalr	-174(ra) # 80001088 <mappages>
    8000113e:	e509                	bnez	a0,80001148 <kvmmap+0x20>
}
    80001140:	60a2                	ld	ra,8(sp)
    80001142:	6402                	ld	s0,0(sp)
    80001144:	0141                	addi	sp,sp,16
    80001146:	8082                	ret
    panic("kvmmap");
    80001148:	00007517          	auipc	a0,0x7
    8000114c:	fd050513          	addi	a0,a0,-48 # 80008118 <digits+0xd8>
    80001150:	fffff097          	auipc	ra,0xfffff
    80001154:	3ec080e7          	jalr	1004(ra) # 8000053c <panic>

0000000080001158 <kvmmake>:
{
    80001158:	1101                	addi	sp,sp,-32
    8000115a:	ec06                	sd	ra,24(sp)
    8000115c:	e822                	sd	s0,16(sp)
    8000115e:	e426                	sd	s1,8(sp)
    80001160:	e04a                	sd	s2,0(sp)
    80001162:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001164:	00000097          	auipc	ra,0x0
    80001168:	97e080e7          	jalr	-1666(ra) # 80000ae2 <kalloc>
    8000116c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000116e:	6605                	lui	a2,0x1
    80001170:	4581                	li	a1,0
    80001172:	00000097          	auipc	ra,0x0
    80001176:	b5c080e7          	jalr	-1188(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000117a:	4719                	li	a4,6
    8000117c:	6685                	lui	a3,0x1
    8000117e:	10000637          	lui	a2,0x10000
    80001182:	100005b7          	lui	a1,0x10000
    80001186:	8526                	mv	a0,s1
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	fa0080e7          	jalr	-96(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10001637          	lui	a2,0x10001
    80001198:	100015b7          	lui	a1,0x10001
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	f8a080e7          	jalr	-118(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	004006b7          	lui	a3,0x400
    800011ac:	0c000637          	lui	a2,0xc000
    800011b0:	0c0005b7          	lui	a1,0xc000
    800011b4:	8526                	mv	a0,s1
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	f72080e7          	jalr	-142(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011be:	00007917          	auipc	s2,0x7
    800011c2:	e4290913          	addi	s2,s2,-446 # 80008000 <etext>
    800011c6:	4729                	li	a4,10
    800011c8:	80007697          	auipc	a3,0x80007
    800011cc:	e3868693          	addi	a3,a3,-456 # 8000 <_entry-0x7fff8000>
    800011d0:	4605                	li	a2,1
    800011d2:	067e                	slli	a2,a2,0x1f
    800011d4:	85b2                	mv	a1,a2
    800011d6:	8526                	mv	a0,s1
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	f50080e7          	jalr	-176(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011e0:	4719                	li	a4,6
    800011e2:	46c5                	li	a3,17
    800011e4:	06ee                	slli	a3,a3,0x1b
    800011e6:	412686b3          	sub	a3,a3,s2
    800011ea:	864a                	mv	a2,s2
    800011ec:	85ca                	mv	a1,s2
    800011ee:	8526                	mv	a0,s1
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f38080e7          	jalr	-200(ra) # 80001128 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011f8:	4729                	li	a4,10
    800011fa:	6685                	lui	a3,0x1
    800011fc:	00006617          	auipc	a2,0x6
    80001200:	e0460613          	addi	a2,a2,-508 # 80007000 <_trampoline>
    80001204:	040005b7          	lui	a1,0x4000
    80001208:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000120a:	05b2                	slli	a1,a1,0xc
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f1a080e7          	jalr	-230(ra) # 80001128 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	608080e7          	jalr	1544(ra) # 80001820 <proc_mapstacks>
}
    80001220:	8526                	mv	a0,s1
    80001222:	60e2                	ld	ra,24(sp)
    80001224:	6442                	ld	s0,16(sp)
    80001226:	64a2                	ld	s1,8(sp)
    80001228:	6902                	ld	s2,0(sp)
    8000122a:	6105                	addi	sp,sp,32
    8000122c:	8082                	ret

000000008000122e <kvminit>:
{
    8000122e:	1141                	addi	sp,sp,-16
    80001230:	e406                	sd	ra,8(sp)
    80001232:	e022                	sd	s0,0(sp)
    80001234:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f22080e7          	jalr	-222(ra) # 80001158 <kvmmake>
    8000123e:	00007797          	auipc	a5,0x7
    80001242:	6aa7b123          	sd	a0,1698(a5) # 800088e0 <kernel_pagetable>
}
    80001246:	60a2                	ld	ra,8(sp)
    80001248:	6402                	ld	s0,0(sp)
    8000124a:	0141                	addi	sp,sp,16
    8000124c:	8082                	ret

000000008000124e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000124e:	715d                	addi	sp,sp,-80
    80001250:	e486                	sd	ra,72(sp)
    80001252:	e0a2                	sd	s0,64(sp)
    80001254:	fc26                	sd	s1,56(sp)
    80001256:	f84a                	sd	s2,48(sp)
    80001258:	f44e                	sd	s3,40(sp)
    8000125a:	f052                	sd	s4,32(sp)
    8000125c:	ec56                	sd	s5,24(sp)
    8000125e:	e85a                	sd	s6,16(sp)
    80001260:	e45e                	sd	s7,8(sp)
    80001262:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001264:	03459793          	slli	a5,a1,0x34
    80001268:	e795                	bnez	a5,80001294 <uvmunmap+0x46>
    8000126a:	8a2a                	mv	s4,a0
    8000126c:	892e                	mv	s2,a1
    8000126e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001270:	0632                	slli	a2,a2,0xc
    80001272:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001276:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001278:	6b05                	lui	s6,0x1
    8000127a:	0735e263          	bltu	a1,s3,800012de <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000127e:	60a6                	ld	ra,72(sp)
    80001280:	6406                	ld	s0,64(sp)
    80001282:	74e2                	ld	s1,56(sp)
    80001284:	7942                	ld	s2,48(sp)
    80001286:	79a2                	ld	s3,40(sp)
    80001288:	7a02                	ld	s4,32(sp)
    8000128a:	6ae2                	ld	s5,24(sp)
    8000128c:	6b42                	ld	s6,16(sp)
    8000128e:	6ba2                	ld	s7,8(sp)
    80001290:	6161                	addi	sp,sp,80
    80001292:	8082                	ret
    panic("uvmunmap: not aligned");
    80001294:	00007517          	auipc	a0,0x7
    80001298:	e8c50513          	addi	a0,a0,-372 # 80008120 <digits+0xe0>
    8000129c:	fffff097          	auipc	ra,0xfffff
    800012a0:	2a0080e7          	jalr	672(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e9450513          	addi	a0,a0,-364 # 80008138 <digits+0xf8>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e9450513          	addi	a0,a0,-364 # 80008148 <digits+0x108>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e9c50513          	addi	a0,a0,-356 # 80008160 <digits+0x120>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
    *pte = 0;
    800012d4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	995a                	add	s2,s2,s6
    800012da:	fb3972e3          	bgeu	s2,s3,8000127e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012de:	4601                	li	a2,0
    800012e0:	85ca                	mv	a1,s2
    800012e2:	8552                	mv	a0,s4
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	cbc080e7          	jalr	-836(ra) # 80000fa0 <walk>
    800012ec:	84aa                	mv	s1,a0
    800012ee:	d95d                	beqz	a0,800012a4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012f0:	6108                	ld	a0,0(a0)
    800012f2:	00157793          	andi	a5,a0,1
    800012f6:	dfdd                	beqz	a5,800012b4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f8:	3ff57793          	andi	a5,a0,1023
    800012fc:	fd7784e3          	beq	a5,s7,800012c4 <uvmunmap+0x76>
    if(do_free){
    80001300:	fc0a8ae3          	beqz	s5,800012d4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6dc080e7          	jalr	1756(ra) # 800009e4 <kfree>
    80001310:	b7d1                	j	800012d4 <uvmunmap+0x86>

0000000080001312 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001312:	1101                	addi	sp,sp,-32
    80001314:	ec06                	sd	ra,24(sp)
    80001316:	e822                	sd	s0,16(sp)
    80001318:	e426                	sd	s1,8(sp)
    8000131a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	7c6080e7          	jalr	1990(ra) # 80000ae2 <kalloc>
    80001324:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001326:	c519                	beqz	a0,80001334 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001328:	6605                	lui	a2,0x1
    8000132a:	4581                	li	a1,0
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	9a2080e7          	jalr	-1630(ra) # 80000cce <memset>
  return pagetable;
}
    80001334:	8526                	mv	a0,s1
    80001336:	60e2                	ld	ra,24(sp)
    80001338:	6442                	ld	s0,16(sp)
    8000133a:	64a2                	ld	s1,8(sp)
    8000133c:	6105                	addi	sp,sp,32
    8000133e:	8082                	ret

0000000080001340 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001340:	7179                	addi	sp,sp,-48
    80001342:	f406                	sd	ra,40(sp)
    80001344:	f022                	sd	s0,32(sp)
    80001346:	ec26                	sd	s1,24(sp)
    80001348:	e84a                	sd	s2,16(sp)
    8000134a:	e44e                	sd	s3,8(sp)
    8000134c:	e052                	sd	s4,0(sp)
    8000134e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001350:	6785                	lui	a5,0x1
    80001352:	04f67863          	bgeu	a2,a5,800013a2 <uvmfirst+0x62>
    80001356:	8a2a                	mv	s4,a0
    80001358:	89ae                	mv	s3,a1
    8000135a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	786080e7          	jalr	1926(ra) # 80000ae2 <kalloc>
    80001364:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001366:	6605                	lui	a2,0x1
    80001368:	4581                	li	a1,0
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	964080e7          	jalr	-1692(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001372:	4779                	li	a4,30
    80001374:	86ca                	mv	a3,s2
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	8552                	mv	a0,s4
    8000137c:	00000097          	auipc	ra,0x0
    80001380:	d0c080e7          	jalr	-756(ra) # 80001088 <mappages>
  memmove(mem, src, sz);
    80001384:	8626                	mv	a2,s1
    80001386:	85ce                	mv	a1,s3
    80001388:	854a                	mv	a0,s2
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	9a0080e7          	jalr	-1632(ra) # 80000d2a <memmove>
}
    80001392:	70a2                	ld	ra,40(sp)
    80001394:	7402                	ld	s0,32(sp)
    80001396:	64e2                	ld	s1,24(sp)
    80001398:	6942                	ld	s2,16(sp)
    8000139a:	69a2                	ld	s3,8(sp)
    8000139c:	6a02                	ld	s4,0(sp)
    8000139e:	6145                	addi	sp,sp,48
    800013a0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013a2:	00007517          	auipc	a0,0x7
    800013a6:	dd650513          	addi	a0,a0,-554 # 80008178 <digits+0x138>
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	192080e7          	jalr	402(ra) # 8000053c <panic>

00000000800013b2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b2:	1101                	addi	sp,sp,-32
    800013b4:	ec06                	sd	ra,24(sp)
    800013b6:	e822                	sd	s0,16(sp)
    800013b8:	e426                	sd	s1,8(sp)
    800013ba:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013bc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013be:	00b67d63          	bgeu	a2,a1,800013d8 <uvmdealloc+0x26>
    800013c2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c4:	6785                	lui	a5,0x1
    800013c6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013c8:	00f60733          	add	a4,a2,a5
    800013cc:	76fd                	lui	a3,0xfffff
    800013ce:	8f75                	and	a4,a4,a3
    800013d0:	97ae                	add	a5,a5,a1
    800013d2:	8ff5                	and	a5,a5,a3
    800013d4:	00f76863          	bltu	a4,a5,800013e4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d8:	8526                	mv	a0,s1
    800013da:	60e2                	ld	ra,24(sp)
    800013dc:	6442                	ld	s0,16(sp)
    800013de:	64a2                	ld	s1,8(sp)
    800013e0:	6105                	addi	sp,sp,32
    800013e2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e4:	8f99                	sub	a5,a5,a4
    800013e6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e8:	4685                	li	a3,1
    800013ea:	0007861b          	sext.w	a2,a5
    800013ee:	85ba                	mv	a1,a4
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	e5e080e7          	jalr	-418(ra) # 8000124e <uvmunmap>
    800013f8:	b7c5                	j	800013d8 <uvmdealloc+0x26>

00000000800013fa <uvmalloc>:
  if(newsz < oldsz)
    800013fa:	0ab66563          	bltu	a2,a1,800014a4 <uvmalloc+0xaa>
{
    800013fe:	7139                	addi	sp,sp,-64
    80001400:	fc06                	sd	ra,56(sp)
    80001402:	f822                	sd	s0,48(sp)
    80001404:	f426                	sd	s1,40(sp)
    80001406:	f04a                	sd	s2,32(sp)
    80001408:	ec4e                	sd	s3,24(sp)
    8000140a:	e852                	sd	s4,16(sp)
    8000140c:	e456                	sd	s5,8(sp)
    8000140e:	e05a                	sd	s6,0(sp)
    80001410:	0080                	addi	s0,sp,64
    80001412:	8aaa                	mv	s5,a0
    80001414:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001416:	6785                	lui	a5,0x1
    80001418:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000141a:	95be                	add	a1,a1,a5
    8000141c:	77fd                	lui	a5,0xfffff
    8000141e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001422:	08c9f363          	bgeu	s3,a2,800014a8 <uvmalloc+0xae>
    80001426:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001428:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000142c:	fffff097          	auipc	ra,0xfffff
    80001430:	6b6080e7          	jalr	1718(ra) # 80000ae2 <kalloc>
    80001434:	84aa                	mv	s1,a0
    if(mem == 0){
    80001436:	c51d                	beqz	a0,80001464 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	892080e7          	jalr	-1902(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001444:	875a                	mv	a4,s6
    80001446:	86a6                	mv	a3,s1
    80001448:	6605                	lui	a2,0x1
    8000144a:	85ca                	mv	a1,s2
    8000144c:	8556                	mv	a0,s5
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	c3a080e7          	jalr	-966(ra) # 80001088 <mappages>
    80001456:	e90d                	bnez	a0,80001488 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001458:	6785                	lui	a5,0x1
    8000145a:	993e                	add	s2,s2,a5
    8000145c:	fd4968e3          	bltu	s2,s4,8000142c <uvmalloc+0x32>
  return newsz;
    80001460:	8552                	mv	a0,s4
    80001462:	a809                	j	80001474 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001464:	864e                	mv	a2,s3
    80001466:	85ca                	mv	a1,s2
    80001468:	8556                	mv	a0,s5
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	f48080e7          	jalr	-184(ra) # 800013b2 <uvmdealloc>
      return 0;
    80001472:	4501                	li	a0,0
}
    80001474:	70e2                	ld	ra,56(sp)
    80001476:	7442                	ld	s0,48(sp)
    80001478:	74a2                	ld	s1,40(sp)
    8000147a:	7902                	ld	s2,32(sp)
    8000147c:	69e2                	ld	s3,24(sp)
    8000147e:	6a42                	ld	s4,16(sp)
    80001480:	6aa2                	ld	s5,8(sp)
    80001482:	6b02                	ld	s6,0(sp)
    80001484:	6121                	addi	sp,sp,64
    80001486:	8082                	ret
      kfree(mem);
    80001488:	8526                	mv	a0,s1
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	55a080e7          	jalr	1370(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001492:	864e                	mv	a2,s3
    80001494:	85ca                	mv	a1,s2
    80001496:	8556                	mv	a0,s5
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	f1a080e7          	jalr	-230(ra) # 800013b2 <uvmdealloc>
      return 0;
    800014a0:	4501                	li	a0,0
    800014a2:	bfc9                	j	80001474 <uvmalloc+0x7a>
    return oldsz;
    800014a4:	852e                	mv	a0,a1
}
    800014a6:	8082                	ret
  return newsz;
    800014a8:	8532                	mv	a0,a2
    800014aa:	b7e9                	j	80001474 <uvmalloc+0x7a>

00000000800014ac <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ac:	7179                	addi	sp,sp,-48
    800014ae:	f406                	sd	ra,40(sp)
    800014b0:	f022                	sd	s0,32(sp)
    800014b2:	ec26                	sd	s1,24(sp)
    800014b4:	e84a                	sd	s2,16(sp)
    800014b6:	e44e                	sd	s3,8(sp)
    800014b8:	e052                	sd	s4,0(sp)
    800014ba:	1800                	addi	s0,sp,48
    800014bc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014be:	84aa                	mv	s1,a0
    800014c0:	6905                	lui	s2,0x1
    800014c2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c4:	4985                	li	s3,1
    800014c6:	a829                	j	800014e0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014c8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014ca:	00c79513          	slli	a0,a5,0xc
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	fde080e7          	jalr	-34(ra) # 800014ac <freewalk>
      pagetable[i] = 0;
    800014d6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014da:	04a1                	addi	s1,s1,8
    800014dc:	03248163          	beq	s1,s2,800014fe <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014e0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e2:	00f7f713          	andi	a4,a5,15
    800014e6:	ff3701e3          	beq	a4,s3,800014c8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ea:	8b85                	andi	a5,a5,1
    800014ec:	d7fd                	beqz	a5,800014da <freewalk+0x2e>
      panic("freewalk: leaf");
    800014ee:	00007517          	auipc	a0,0x7
    800014f2:	caa50513          	addi	a0,a0,-854 # 80008198 <digits+0x158>
    800014f6:	fffff097          	auipc	ra,0xfffff
    800014fa:	046080e7          	jalr	70(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800014fe:	8552                	mv	a0,s4
    80001500:	fffff097          	auipc	ra,0xfffff
    80001504:	4e4080e7          	jalr	1252(ra) # 800009e4 <kfree>
}
    80001508:	70a2                	ld	ra,40(sp)
    8000150a:	7402                	ld	s0,32(sp)
    8000150c:	64e2                	ld	s1,24(sp)
    8000150e:	6942                	ld	s2,16(sp)
    80001510:	69a2                	ld	s3,8(sp)
    80001512:	6a02                	ld	s4,0(sp)
    80001514:	6145                	addi	sp,sp,48
    80001516:	8082                	ret

0000000080001518 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001518:	1101                	addi	sp,sp,-32
    8000151a:	ec06                	sd	ra,24(sp)
    8000151c:	e822                	sd	s0,16(sp)
    8000151e:	e426                	sd	s1,8(sp)
    80001520:	1000                	addi	s0,sp,32
    80001522:	84aa                	mv	s1,a0
  if(sz > 0)
    80001524:	e999                	bnez	a1,8000153a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001526:	8526                	mv	a0,s1
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f84080e7          	jalr	-124(ra) # 800014ac <freewalk>
}
    80001530:	60e2                	ld	ra,24(sp)
    80001532:	6442                	ld	s0,16(sp)
    80001534:	64a2                	ld	s1,8(sp)
    80001536:	6105                	addi	sp,sp,32
    80001538:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153a:	6785                	lui	a5,0x1
    8000153c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000153e:	95be                	add	a1,a1,a5
    80001540:	4685                	li	a3,1
    80001542:	00c5d613          	srli	a2,a1,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d06080e7          	jalr	-762(ra) # 8000124e <uvmunmap>
    80001550:	bfd9                	j	80001526 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a28080e7          	jalr	-1496(ra) # 80000fa0 <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	54c080e7          	jalr	1356(ra) # 80000ae2 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	784080e7          	jalr	1924(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	ad0080e7          	jalr	-1328(ra) # 80001088 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bdc50513          	addi	a0,a0,-1060 # 800081a8 <digits+0x168>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f68080e7          	jalr	-152(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bec50513          	addi	a0,a0,-1044 # 800081c8 <digits+0x188>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3f6080e7          	jalr	1014(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c4e080e7          	jalr	-946(ra) # 8000124e <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	972080e7          	jalr	-1678(ra) # 80000fa0 <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	ba250513          	addi	a0,a0,-1118 # 800081e8 <digits+0x1a8>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	eee080e7          	jalr	-274(ra) # 8000053c <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	6a0080e7          	jalr	1696(ra) # 80000d2a <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	99e080e7          	jalr	-1634(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	caa5                	beqz	a3,80001752 <copyin+0x70>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a01d                	j	8000172e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	018505b3          	add	a1,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	412585b3          	sub	a1,a1,s2
    80001716:	8552                	mv	a0,s4
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	612080e7          	jalr	1554(ra) # 80000d2a <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001724:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	910080e7          	jalr	-1776(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f2e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	bf7d                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyin+0x76>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001770:	c2dd                	beqz	a3,80001816 <copyinstr+0xa6>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8a2a                	mv	s4,a0
    8000178a:	8b2e                	mv	s6,a1
    8000178c:	8bb2                	mv	s7,a2
    8000178e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6985                	lui	s3,0x1
    80001794:	a02d                	j	800017be <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001796:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179c:	37fd                	addiw	a5,a5,-1
    8000179e:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017b8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017bc:	c8a9                	beqz	s1,8000180e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017be:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c2:	85ca                	mv	a1,s2
    800017c4:	8552                	mv	a0,s4
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	880080e7          	jalr	-1920(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    800017ce:	c131                	beqz	a0,80001812 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017d0:	417906b3          	sub	a3,s2,s7
    800017d4:	96ce                	add	a3,a3,s3
    800017d6:	00d4f363          	bgeu	s1,a3,800017dc <copyinstr+0x6c>
    800017da:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017dc:	955e                	add	a0,a0,s7
    800017de:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e2:	daf9                	beqz	a3,800017b8 <copyinstr+0x48>
    800017e4:	87da                	mv	a5,s6
    800017e6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017e8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017ec:	96da                	add	a3,a3,s6
    800017ee:	85be                	mv	a1,a5
      if(*p == '\0'){
    800017f0:	00f60733          	add	a4,a2,a5
    800017f4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd290>
    800017f8:	df59                	beqz	a4,80001796 <copyinstr+0x26>
        *dst = *p;
    800017fa:	00e78023          	sb	a4,0(a5)
      dst++;
    800017fe:	0785                	addi	a5,a5,1
    while(n > 0){
    80001800:	fed797e3          	bne	a5,a3,800017ee <copyinstr+0x7e>
    80001804:	14fd                	addi	s1,s1,-1
    80001806:	94c2                	add	s1,s1,a6
      --max;
    80001808:	8c8d                	sub	s1,s1,a1
      dst++;
    8000180a:	8b3e                	mv	s6,a5
    8000180c:	b775                	j	800017b8 <copyinstr+0x48>
    8000180e:	4781                	li	a5,0
    80001810:	b771                	j	8000179c <copyinstr+0x2c>
      return -1;
    80001812:	557d                	li	a0,-1
    80001814:	b779                	j	800017a2 <copyinstr+0x32>
  int got_null = 0;
    80001816:	4781                	li	a5,0
  if(got_null){
    80001818:	37fd                	addiw	a5,a5,-1
    8000181a:	0007851b          	sext.w	a0,a5
}
    8000181e:	8082                	ret

0000000080001820 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001820:	7139                	addi	sp,sp,-64
    80001822:	fc06                	sd	ra,56(sp)
    80001824:	f822                	sd	s0,48(sp)
    80001826:	f426                	sd	s1,40(sp)
    80001828:	f04a                	sd	s2,32(sp)
    8000182a:	ec4e                	sd	s3,24(sp)
    8000182c:	e852                	sd	s4,16(sp)
    8000182e:	e456                	sd	s5,8(sp)
    80001830:	e05a                	sd	s6,0(sp)
    80001832:	0080                	addi	s0,sp,64
    80001834:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001836:	0000f497          	auipc	s1,0xf
    8000183a:	75a48493          	addi	s1,s1,1882 # 80010f90 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000183e:	8b26                	mv	s6,s1
    80001840:	00006a97          	auipc	s5,0x6
    80001844:	7c0a8a93          	addi	s5,s5,1984 # 80008000 <etext>
    80001848:	04000937          	lui	s2,0x4000
    8000184c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000184e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001850:	00015a17          	auipc	s4,0x15
    80001854:	140a0a13          	addi	s4,s4,320 # 80016990 <tickslock>
    char *pa = kalloc();
    80001858:	fffff097          	auipc	ra,0xfffff
    8000185c:	28a080e7          	jalr	650(ra) # 80000ae2 <kalloc>
    80001860:	862a                	mv	a2,a0
    if(pa == 0)
    80001862:	c131                	beqz	a0,800018a6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001864:	416485b3          	sub	a1,s1,s6
    80001868:	858d                	srai	a1,a1,0x3
    8000186a:	000ab783          	ld	a5,0(s5)
    8000186e:	02f585b3          	mul	a1,a1,a5
    80001872:	2585                	addiw	a1,a1,1
    80001874:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001878:	4719                	li	a4,6
    8000187a:	6685                	lui	a3,0x1
    8000187c:	40b905b3          	sub	a1,s2,a1
    80001880:	854e                	mv	a0,s3
    80001882:	00000097          	auipc	ra,0x0
    80001886:	8a6080e7          	jalr	-1882(ra) # 80001128 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188a:	16848493          	addi	s1,s1,360
    8000188e:	fd4495e3          	bne	s1,s4,80001858 <proc_mapstacks+0x38>
  }
}
    80001892:	70e2                	ld	ra,56(sp)
    80001894:	7442                	ld	s0,48(sp)
    80001896:	74a2                	ld	s1,40(sp)
    80001898:	7902                	ld	s2,32(sp)
    8000189a:	69e2                	ld	s3,24(sp)
    8000189c:	6a42                	ld	s4,16(sp)
    8000189e:	6aa2                	ld	s5,8(sp)
    800018a0:	6b02                	ld	s6,0(sp)
    800018a2:	6121                	addi	sp,sp,64
    800018a4:	8082                	ret
      panic("kalloc");
    800018a6:	00007517          	auipc	a0,0x7
    800018aa:	95250513          	addi	a0,a0,-1710 # 800081f8 <digits+0x1b8>
    800018ae:	fffff097          	auipc	ra,0xfffff
    800018b2:	c8e080e7          	jalr	-882(ra) # 8000053c <panic>

00000000800018b6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018b6:	7139                	addi	sp,sp,-64
    800018b8:	fc06                	sd	ra,56(sp)
    800018ba:	f822                	sd	s0,48(sp)
    800018bc:	f426                	sd	s1,40(sp)
    800018be:	f04a                	sd	s2,32(sp)
    800018c0:	ec4e                	sd	s3,24(sp)
    800018c2:	e852                	sd	s4,16(sp)
    800018c4:	e456                	sd	s5,8(sp)
    800018c6:	e05a                	sd	s6,0(sp)
    800018c8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ca:	00007597          	auipc	a1,0x7
    800018ce:	93658593          	addi	a1,a1,-1738 # 80008200 <digits+0x1c0>
    800018d2:	0000f517          	auipc	a0,0xf
    800018d6:	28e50513          	addi	a0,a0,654 # 80010b60 <pid_lock>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	268080e7          	jalr	616(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e2:	00007597          	auipc	a1,0x7
    800018e6:	92658593          	addi	a1,a1,-1754 # 80008208 <digits+0x1c8>
    800018ea:	0000f517          	auipc	a0,0xf
    800018ee:	28e50513          	addi	a0,a0,654 # 80010b78 <wait_lock>
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	250080e7          	jalr	592(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fa:	0000f497          	auipc	s1,0xf
    800018fe:	69648493          	addi	s1,s1,1686 # 80010f90 <proc>
      initlock(&p->lock, "proc");
    80001902:	00007b17          	auipc	s6,0x7
    80001906:	916b0b13          	addi	s6,s6,-1770 # 80008218 <digits+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000190a:	8aa6                	mv	s5,s1
    8000190c:	00006a17          	auipc	s4,0x6
    80001910:	6f4a0a13          	addi	s4,s4,1780 # 80008000 <etext>
    80001914:	04000937          	lui	s2,0x4000
    80001918:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000191a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191c:	00015997          	auipc	s3,0x15
    80001920:	07498993          	addi	s3,s3,116 # 80016990 <tickslock>
      initlock(&p->lock, "proc");
    80001924:	85da                	mv	a1,s6
    80001926:	8526                	mv	a0,s1
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	21a080e7          	jalr	538(ra) # 80000b42 <initlock>
      p->state = UNUSED;
    80001930:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	878d                	srai	a5,a5,0x3
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	16848493          	addi	s1,s1,360
    80001952:	fd3499e3          	bne	s1,s3,80001924 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	0000f517          	auipc	a0,0xf
    8000198a:	20a50513          	addi	a0,a0,522 # 80010b90 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e6080e7          	jalr	486(ra) # 80000b86 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	0000f717          	auipc	a4,0xf
    800019b2:	1b270713          	addi	a4,a4,434 # 80010b60 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26c080e7          	jalr	620(ra) # 80000c26 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a8080e7          	jalr	680(ra) # 80000c86 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	e8a7a783          	lw	a5,-374(a5) # 80008870 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	c5c080e7          	jalr	-932(ra) # 8000264c <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e607a823          	sw	zero,-400(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	99e080e7          	jalr	-1634(ra) # 800033a8 <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
{
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	0000f917          	auipc	s2,0xf
    80001a24:	14090913          	addi	s2,s2,320 # 80010b60 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a8080e7          	jalr	424(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e4278793          	addi	a5,a5,-446 # 80008874 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	242080e7          	jalr	578(ra) # 80000c86 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8aa080e7          	jalr	-1878(ra) # 80001312 <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	600080e7          	jalr	1536(ra) # 80001088 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	05893683          	ld	a3,88(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5e2080e7          	jalr	1506(ra) # 80001088 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a54080e7          	jalr	-1452(ra) # 80001518 <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	770080e7          	jalr	1904(ra) # 8000124e <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a2e080e7          	jalr	-1490(ra) # 80001518 <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	73c080e7          	jalr	1852(ra) # 8000124e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	726080e7          	jalr	1830(ra) # 8000124e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e4080e7          	jalr	-1564(ra) # 80001518 <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	6d28                	ld	a0,88(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8c080e7          	jalr	-372(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b60:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b64:	68a8                	ld	a0,80(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	64ac                	ld	a1,72(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b76:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b82:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b92:	0004ac23          	sw	zero,24(s1)
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <allocproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	0000f497          	auipc	s1,0xf
    80001bb0:	3e448493          	addi	s1,s1,996 # 80010f90 <proc>
    80001bb4:	00015917          	auipc	s2,0x15
    80001bb8:	ddc90913          	addi	s2,s2,-548 # 80016990 <tickslock>
    acquire(&p->lock);
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	014080e7          	jalr	20(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80001bc6:	4c9c                	lw	a5,24(s1)
    80001bc8:	cf81                	beqz	a5,80001be0 <allocproc+0x40>
      release(&p->lock);
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	0ba080e7          	jalr	186(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	16848493          	addi	s1,s1,360
    80001bd8:	ff2492e3          	bne	s1,s2,80001bbc <allocproc+0x1c>
  return 0;
    80001bdc:	4481                	li	s1,0
    80001bde:	a889                	j	80001c30 <allocproc+0x90>
  p->pid = allocpid();
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	e34080e7          	jalr	-460(ra) # 80001a14 <allocpid>
    80001be8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bea:	4785                	li	a5,1
    80001bec:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ef4080e7          	jalr	-268(ra) # 80000ae2 <kalloc>
    80001bf6:	892a                	mv	s2,a0
    80001bf8:	eca8                	sd	a0,88(s1)
    80001bfa:	c131                	beqz	a0,80001c3e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e5c080e7          	jalr	-420(ra) # 80001a5a <proc_pagetable>
    80001c06:	892a                	mv	s2,a0
    80001c08:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c0a:	c531                	beqz	a0,80001c56 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0c:	07000613          	li	a2,112
    80001c10:	4581                	li	a1,0
    80001c12:	06048513          	addi	a0,s1,96
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	0b8080e7          	jalr	184(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c1e:	00000797          	auipc	a5,0x0
    80001c22:	db078793          	addi	a5,a5,-592 # 800019ce <forkret>
    80001c26:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c28:	60bc                	ld	a5,64(s1)
    80001c2a:	6705                	lui	a4,0x1
    80001c2c:	97ba                	add	a5,a5,a4
    80001c2e:	f4bc                	sd	a5,104(s1)
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    freeproc(p);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	f08080e7          	jalr	-248(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	03c080e7          	jalr	60(ra) # 80000c86 <release>
    return 0;
    80001c52:	84ca                	mv	s1,s2
    80001c54:	bff1                	j	80001c30 <allocproc+0x90>
    freeproc(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	ef0080e7          	jalr	-272(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	024080e7          	jalr	36(ra) # 80000c86 <release>
    return 0;
    80001c6a:	84ca                	mv	s1,s2
    80001c6c:	b7d1                	j	80001c30 <allocproc+0x90>

0000000080001c6e <userinit>:
{
    80001c6e:	1101                	addi	sp,sp,-32
    80001c70:	ec06                	sd	ra,24(sp)
    80001c72:	e822                	sd	s0,16(sp)
    80001c74:	e426                	sd	s1,8(sp)
    80001c76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f28080e7          	jalr	-216(ra) # 80001ba0 <allocproc>
    80001c80:	84aa                	mv	s1,a0
  initproc = p;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	c6a7b323          	sd	a0,-922(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001c8a:	03400613          	li	a2,52
    80001c8e:	00007597          	auipc	a1,0x7
    80001c92:	bf258593          	addi	a1,a1,-1038 # 80008880 <initcode>
    80001c96:	6928                	ld	a0,80(a0)
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6a8080e7          	jalr	1704(ra) # 80001340 <uvmfirst>
  p->sz = PGSIZE;
    80001ca0:	6785                	lui	a5,0x1
    80001ca2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca4:	6cb8                	ld	a4,88(s1)
    80001ca6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001caa:	6cb8                	ld	a4,88(s1)
    80001cac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cae:	4641                	li	a2,16
    80001cb0:	00006597          	auipc	a1,0x6
    80001cb4:	57058593          	addi	a1,a1,1392 # 80008220 <digits+0x1e0>
    80001cb8:	15848513          	addi	a0,s1,344
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	15a080e7          	jalr	346(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	56c50513          	addi	a0,a0,1388 # 80008230 <digits+0x1f0>
    80001ccc:	00002097          	auipc	ra,0x2
    80001cd0:	0fa080e7          	jalr	250(ra) # 80003dc6 <namei>
    80001cd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd8:	478d                	li	a5,3
    80001cda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fa8080e7          	jalr	-88(ra) # 80000c86 <release>
}
    80001ce6:	60e2                	ld	ra,24(sp)
    80001ce8:	6442                	ld	s0,16(sp)
    80001cea:	64a2                	ld	s1,8(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <growproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	e04a                	sd	s2,0(sp)
    80001cfa:	1000                	addi	s0,sp,32
    80001cfc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001cfe:	00000097          	auipc	ra,0x0
    80001d02:	c98080e7          	jalr	-872(ra) # 80001996 <myproc>
    80001d06:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d08:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d0a:	01204c63          	bgtz	s2,80001d22 <growproc+0x32>
  } else if(n < 0){
    80001d0e:	02094663          	bltz	s2,80001d3a <growproc+0x4a>
  p->sz = sz;
    80001d12:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d14:	4501                	li	a0,0
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6902                	ld	s2,0(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d22:	4691                	li	a3,4
    80001d24:	00b90633          	add	a2,s2,a1
    80001d28:	6928                	ld	a0,80(a0)
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	6d0080e7          	jalr	1744(ra) # 800013fa <uvmalloc>
    80001d32:	85aa                	mv	a1,a0
    80001d34:	fd79                	bnez	a0,80001d12 <growproc+0x22>
      return -1;
    80001d36:	557d                	li	a0,-1
    80001d38:	bff9                	j	80001d16 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	672080e7          	jalr	1650(ra) # 800013b2 <uvmdealloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	b7e1                	j	80001d12 <growproc+0x22>

0000000080001d4c <fork>:
{
    80001d4c:	7139                	addi	sp,sp,-64
    80001d4e:	fc06                	sd	ra,56(sp)
    80001d50:	f822                	sd	s0,48(sp)
    80001d52:	f426                	sd	s1,40(sp)
    80001d54:	f04a                	sd	s2,32(sp)
    80001d56:	ec4e                	sd	s3,24(sp)
    80001d58:	e852                	sd	s4,16(sp)
    80001d5a:	e456                	sd	s5,8(sp)
    80001d5c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	c38080e7          	jalr	-968(ra) # 80001996 <myproc>
    80001d66:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e38080e7          	jalr	-456(ra) # 80001ba0 <allocproc>
    80001d70:	10050c63          	beqz	a0,80001e88 <fork+0x13c>
    80001d74:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d76:	048ab603          	ld	a2,72(s5)
    80001d7a:	692c                	ld	a1,80(a0)
    80001d7c:	050ab503          	ld	a0,80(s5)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	7d2080e7          	jalr	2002(ra) # 80001552 <uvmcopy>
    80001d88:	04054863          	bltz	a0,80001dd8 <fork+0x8c>
  np->sz = p->sz;
    80001d8c:	048ab783          	ld	a5,72(s5)
    80001d90:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001d94:	058ab683          	ld	a3,88(s5)
    80001d98:	87b6                	mv	a5,a3
    80001d9a:	058a3703          	ld	a4,88(s4)
    80001d9e:	12068693          	addi	a3,a3,288
    80001da2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001da6:	6788                	ld	a0,8(a5)
    80001da8:	6b8c                	ld	a1,16(a5)
    80001daa:	6f90                	ld	a2,24(a5)
    80001dac:	01073023          	sd	a6,0(a4)
    80001db0:	e708                	sd	a0,8(a4)
    80001db2:	eb0c                	sd	a1,16(a4)
    80001db4:	ef10                	sd	a2,24(a4)
    80001db6:	02078793          	addi	a5,a5,32
    80001dba:	02070713          	addi	a4,a4,32
    80001dbe:	fed792e3          	bne	a5,a3,80001da2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dc2:	058a3783          	ld	a5,88(s4)
    80001dc6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dca:	0d0a8493          	addi	s1,s5,208
    80001dce:	0d0a0913          	addi	s2,s4,208
    80001dd2:	150a8993          	addi	s3,s5,336
    80001dd6:	a00d                	j	80001df8 <fork+0xac>
    freeproc(np);
    80001dd8:	8552                	mv	a0,s4
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	d6e080e7          	jalr	-658(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001de2:	8552                	mv	a0,s4
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	ea2080e7          	jalr	-350(ra) # 80000c86 <release>
    return -1;
    80001dec:	597d                	li	s2,-1
    80001dee:	a059                	j	80001e74 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001df0:	04a1                	addi	s1,s1,8
    80001df2:	0921                	addi	s2,s2,8
    80001df4:	01348b63          	beq	s1,s3,80001e0a <fork+0xbe>
    if(p->ofile[i])
    80001df8:	6088                	ld	a0,0(s1)
    80001dfa:	d97d                	beqz	a0,80001df0 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001dfc:	00002097          	auipc	ra,0x2
    80001e00:	63c080e7          	jalr	1596(ra) # 80004438 <filedup>
    80001e04:	00a93023          	sd	a0,0(s2)
    80001e08:	b7e5                	j	80001df0 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e0a:	150ab503          	ld	a0,336(s5)
    80001e0e:	00001097          	auipc	ra,0x1
    80001e12:	7d4080e7          	jalr	2004(ra) # 800035e2 <idup>
    80001e16:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e1a:	4641                	li	a2,16
    80001e1c:	158a8593          	addi	a1,s5,344
    80001e20:	158a0513          	addi	a0,s4,344
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	ff2080e7          	jalr	-14(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e2c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e30:	8552                	mv	a0,s4
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e54080e7          	jalr	-428(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e3a:	0000f497          	auipc	s1,0xf
    80001e3e:	d3e48493          	addi	s1,s1,-706 # 80010b78 <wait_lock>
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	d8e080e7          	jalr	-626(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e4c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e34080e7          	jalr	-460(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	d76080e7          	jalr	-650(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001e64:	478d                	li	a5,3
    80001e66:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e1a080e7          	jalr	-486(ra) # 80000c86 <release>
}
    80001e74:	854a                	mv	a0,s2
    80001e76:	70e2                	ld	ra,56(sp)
    80001e78:	7442                	ld	s0,48(sp)
    80001e7a:	74a2                	ld	s1,40(sp)
    80001e7c:	7902                	ld	s2,32(sp)
    80001e7e:	69e2                	ld	s3,24(sp)
    80001e80:	6a42                	ld	s4,16(sp)
    80001e82:	6aa2                	ld	s5,8(sp)
    80001e84:	6121                	addi	sp,sp,64
    80001e86:	8082                	ret
    return -1;
    80001e88:	597d                	li	s2,-1
    80001e8a:	b7ed                	j	80001e74 <fork+0x128>

0000000080001e8c <scheduler>:
{
    80001e8c:	7139                	addi	sp,sp,-64
    80001e8e:	fc06                	sd	ra,56(sp)
    80001e90:	f822                	sd	s0,48(sp)
    80001e92:	f426                	sd	s1,40(sp)
    80001e94:	f04a                	sd	s2,32(sp)
    80001e96:	ec4e                	sd	s3,24(sp)
    80001e98:	e852                	sd	s4,16(sp)
    80001e9a:	e456                	sd	s5,8(sp)
    80001e9c:	e05a                	sd	s6,0(sp)
    80001e9e:	0080                	addi	s0,sp,64
    80001ea0:	8792                	mv	a5,tp
  int id = r_tp();
    80001ea2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ea4:	00779a93          	slli	s5,a5,0x7
    80001ea8:	0000f717          	auipc	a4,0xf
    80001eac:	cb870713          	addi	a4,a4,-840 # 80010b60 <pid_lock>
    80001eb0:	9756                	add	a4,a4,s5
    80001eb2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eb6:	0000f717          	auipc	a4,0xf
    80001eba:	ce270713          	addi	a4,a4,-798 # 80010b98 <cpus+0x8>
    80001ebe:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ec0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ec2:	4b11                	li	s6,4
        c->proc = p;
    80001ec4:	079e                	slli	a5,a5,0x7
    80001ec6:	0000fa17          	auipc	s4,0xf
    80001eca:	c9aa0a13          	addi	s4,s4,-870 # 80010b60 <pid_lock>
    80001ece:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ed0:	00015917          	auipc	s2,0x15
    80001ed4:	ac090913          	addi	s2,s2,-1344 # 80016990 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ed8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001edc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ee0:	10079073          	csrw	sstatus,a5
    80001ee4:	0000f497          	auipc	s1,0xf
    80001ee8:	0ac48493          	addi	s1,s1,172 # 80010f90 <proc>
    80001eec:	a811                	j	80001f00 <scheduler+0x74>
      release(&p->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	d96080e7          	jalr	-618(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef8:	16848493          	addi	s1,s1,360
    80001efc:	fd248ee3          	beq	s1,s2,80001ed8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	cd0080e7          	jalr	-816(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80001f0a:	4c9c                	lw	a5,24(s1)
    80001f0c:	ff3791e3          	bne	a5,s3,80001eee <scheduler+0x62>
        p->state = RUNNING;
    80001f10:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f14:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f18:	06048593          	addi	a1,s1,96
    80001f1c:	8556                	mv	a0,s5
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	684080e7          	jalr	1668(ra) # 800025a2 <swtch>
        c->proc = 0;
    80001f26:	020a3823          	sd	zero,48(s4)
    80001f2a:	b7d1                	j	80001eee <scheduler+0x62>

0000000080001f2c <sched>:
{
    80001f2c:	7179                	addi	sp,sp,-48
    80001f2e:	f406                	sd	ra,40(sp)
    80001f30:	f022                	sd	s0,32(sp)
    80001f32:	ec26                	sd	s1,24(sp)
    80001f34:	e84a                	sd	s2,16(sp)
    80001f36:	e44e                	sd	s3,8(sp)
    80001f38:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	a5c080e7          	jalr	-1444(ra) # 80001996 <myproc>
    80001f42:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	c14080e7          	jalr	-1004(ra) # 80000b58 <holding>
    80001f4c:	c93d                	beqz	a0,80001fc2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f4e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f50:	2781                	sext.w	a5,a5
    80001f52:	079e                	slli	a5,a5,0x7
    80001f54:	0000f717          	auipc	a4,0xf
    80001f58:	c0c70713          	addi	a4,a4,-1012 # 80010b60 <pid_lock>
    80001f5c:	97ba                	add	a5,a5,a4
    80001f5e:	0a87a703          	lw	a4,168(a5)
    80001f62:	4785                	li	a5,1
    80001f64:	06f71763          	bne	a4,a5,80001fd2 <sched+0xa6>
  if(p->state == RUNNING)
    80001f68:	4c98                	lw	a4,24(s1)
    80001f6a:	4791                	li	a5,4
    80001f6c:	06f70b63          	beq	a4,a5,80001fe2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f70:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f74:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f76:	efb5                	bnez	a5,80001ff2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f78:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f7a:	0000f917          	auipc	s2,0xf
    80001f7e:	be690913          	addi	s2,s2,-1050 # 80010b60 <pid_lock>
    80001f82:	2781                	sext.w	a5,a5
    80001f84:	079e                	slli	a5,a5,0x7
    80001f86:	97ca                	add	a5,a5,s2
    80001f88:	0ac7a983          	lw	s3,172(a5)
    80001f8c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	079e                	slli	a5,a5,0x7
    80001f92:	0000f597          	auipc	a1,0xf
    80001f96:	c0658593          	addi	a1,a1,-1018 # 80010b98 <cpus+0x8>
    80001f9a:	95be                	add	a1,a1,a5
    80001f9c:	06048513          	addi	a0,s1,96
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	602080e7          	jalr	1538(ra) # 800025a2 <swtch>
    80001fa8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001faa:	2781                	sext.w	a5,a5
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	993e                	add	s2,s2,a5
    80001fb0:	0b392623          	sw	s3,172(s2)
}
    80001fb4:	70a2                	ld	ra,40(sp)
    80001fb6:	7402                	ld	s0,32(sp)
    80001fb8:	64e2                	ld	s1,24(sp)
    80001fba:	6942                	ld	s2,16(sp)
    80001fbc:	69a2                	ld	s3,8(sp)
    80001fbe:	6145                	addi	sp,sp,48
    80001fc0:	8082                	ret
    panic("sched p->lock");
    80001fc2:	00006517          	auipc	a0,0x6
    80001fc6:	27650513          	addi	a0,a0,630 # 80008238 <digits+0x1f8>
    80001fca:	ffffe097          	auipc	ra,0xffffe
    80001fce:	572080e7          	jalr	1394(ra) # 8000053c <panic>
    panic("sched locks");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	27650513          	addi	a0,a0,630 # 80008248 <digits+0x208>
    80001fda:	ffffe097          	auipc	ra,0xffffe
    80001fde:	562080e7          	jalr	1378(ra) # 8000053c <panic>
    panic("sched running");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	27650513          	addi	a0,a0,630 # 80008258 <digits+0x218>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	552080e7          	jalr	1362(ra) # 8000053c <panic>
    panic("sched interruptible");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	27650513          	addi	a0,a0,630 # 80008268 <digits+0x228>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	542080e7          	jalr	1346(ra) # 8000053c <panic>

0000000080002002 <yield>:
{
    80002002:	1101                	addi	sp,sp,-32
    80002004:	ec06                	sd	ra,24(sp)
    80002006:	e822                	sd	s0,16(sp)
    80002008:	e426                	sd	s1,8(sp)
    8000200a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	98a080e7          	jalr	-1654(ra) # 80001996 <myproc>
    80002014:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	bbc080e7          	jalr	-1092(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    8000201e:	478d                	li	a5,3
    80002020:	cc9c                	sw	a5,24(s1)
  sched();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	f0a080e7          	jalr	-246(ra) # 80001f2c <sched>
  release(&p->lock);
    8000202a:	8526                	mv	a0,s1
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c5a080e7          	jalr	-934(ra) # 80000c86 <release>
}
    80002034:	60e2                	ld	ra,24(sp)
    80002036:	6442                	ld	s0,16(sp)
    80002038:	64a2                	ld	s1,8(sp)
    8000203a:	6105                	addi	sp,sp,32
    8000203c:	8082                	ret

000000008000203e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000203e:	7179                	addi	sp,sp,-48
    80002040:	f406                	sd	ra,40(sp)
    80002042:	f022                	sd	s0,32(sp)
    80002044:	ec26                	sd	s1,24(sp)
    80002046:	e84a                	sd	s2,16(sp)
    80002048:	e44e                	sd	s3,8(sp)
    8000204a:	1800                	addi	s0,sp,48
    8000204c:	89aa                	mv	s3,a0
    8000204e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	946080e7          	jalr	-1722(ra) # 80001996 <myproc>
    80002058:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	b78080e7          	jalr	-1160(ra) # 80000bd2 <acquire>
  release(lk);
    80002062:	854a                	mv	a0,s2
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c22080e7          	jalr	-990(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    8000206c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002070:	4789                	li	a5,2
    80002072:	cc9c                	sw	a5,24(s1)

  sched();
    80002074:	00000097          	auipc	ra,0x0
    80002078:	eb8080e7          	jalr	-328(ra) # 80001f2c <sched>

  // Tidy up.
  p->chan = 0;
    8000207c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c04080e7          	jalr	-1020(ra) # 80000c86 <release>
  acquire(lk);
    8000208a:	854a                	mv	a0,s2
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b46080e7          	jalr	-1210(ra) # 80000bd2 <acquire>
}
    80002094:	70a2                	ld	ra,40(sp)
    80002096:	7402                	ld	s0,32(sp)
    80002098:	64e2                	ld	s1,24(sp)
    8000209a:	6942                	ld	s2,16(sp)
    8000209c:	69a2                	ld	s3,8(sp)
    8000209e:	6145                	addi	sp,sp,48
    800020a0:	8082                	ret

00000000800020a2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020a2:	7139                	addi	sp,sp,-64
    800020a4:	fc06                	sd	ra,56(sp)
    800020a6:	f822                	sd	s0,48(sp)
    800020a8:	f426                	sd	s1,40(sp)
    800020aa:	f04a                	sd	s2,32(sp)
    800020ac:	ec4e                	sd	s3,24(sp)
    800020ae:	e852                	sd	s4,16(sp)
    800020b0:	e456                	sd	s5,8(sp)
    800020b2:	0080                	addi	s0,sp,64
    800020b4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020b6:	0000f497          	auipc	s1,0xf
    800020ba:	eda48493          	addi	s1,s1,-294 # 80010f90 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020be:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020c0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020c2:	00015917          	auipc	s2,0x15
    800020c6:	8ce90913          	addi	s2,s2,-1842 # 80016990 <tickslock>
    800020ca:	a811                	j	800020de <wakeup+0x3c>
      }
      release(&p->lock);
    800020cc:	8526                	mv	a0,s1
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	bb8080e7          	jalr	-1096(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d6:	16848493          	addi	s1,s1,360
    800020da:	03248663          	beq	s1,s2,80002106 <wakeup+0x64>
    if(p != myproc()){
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	8b8080e7          	jalr	-1864(ra) # 80001996 <myproc>
    800020e6:	fea488e3          	beq	s1,a0,800020d6 <wakeup+0x34>
      acquire(&p->lock);
    800020ea:	8526                	mv	a0,s1
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	ae6080e7          	jalr	-1306(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800020f4:	4c9c                	lw	a5,24(s1)
    800020f6:	fd379be3          	bne	a5,s3,800020cc <wakeup+0x2a>
    800020fa:	709c                	ld	a5,32(s1)
    800020fc:	fd4798e3          	bne	a5,s4,800020cc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002100:	0154ac23          	sw	s5,24(s1)
    80002104:	b7e1                	j	800020cc <wakeup+0x2a>
    }
  }
}
    80002106:	70e2                	ld	ra,56(sp)
    80002108:	7442                	ld	s0,48(sp)
    8000210a:	74a2                	ld	s1,40(sp)
    8000210c:	7902                	ld	s2,32(sp)
    8000210e:	69e2                	ld	s3,24(sp)
    80002110:	6a42                	ld	s4,16(sp)
    80002112:	6aa2                	ld	s5,8(sp)
    80002114:	6121                	addi	sp,sp,64
    80002116:	8082                	ret

0000000080002118 <reparent>:
{
    80002118:	7179                	addi	sp,sp,-48
    8000211a:	f406                	sd	ra,40(sp)
    8000211c:	f022                	sd	s0,32(sp)
    8000211e:	ec26                	sd	s1,24(sp)
    80002120:	e84a                	sd	s2,16(sp)
    80002122:	e44e                	sd	s3,8(sp)
    80002124:	e052                	sd	s4,0(sp)
    80002126:	1800                	addi	s0,sp,48
    80002128:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000212a:	0000f497          	auipc	s1,0xf
    8000212e:	e6648493          	addi	s1,s1,-410 # 80010f90 <proc>
      pp->parent = initproc;
    80002132:	00006a17          	auipc	s4,0x6
    80002136:	7b6a0a13          	addi	s4,s4,1974 # 800088e8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000213a:	00015997          	auipc	s3,0x15
    8000213e:	85698993          	addi	s3,s3,-1962 # 80016990 <tickslock>
    80002142:	a029                	j	8000214c <reparent+0x34>
    80002144:	16848493          	addi	s1,s1,360
    80002148:	01348d63          	beq	s1,s3,80002162 <reparent+0x4a>
    if(pp->parent == p){
    8000214c:	7c9c                	ld	a5,56(s1)
    8000214e:	ff279be3          	bne	a5,s2,80002144 <reparent+0x2c>
      pp->parent = initproc;
    80002152:	000a3503          	ld	a0,0(s4)
    80002156:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	f4a080e7          	jalr	-182(ra) # 800020a2 <wakeup>
    80002160:	b7d5                	j	80002144 <reparent+0x2c>
}
    80002162:	70a2                	ld	ra,40(sp)
    80002164:	7402                	ld	s0,32(sp)
    80002166:	64e2                	ld	s1,24(sp)
    80002168:	6942                	ld	s2,16(sp)
    8000216a:	69a2                	ld	s3,8(sp)
    8000216c:	6a02                	ld	s4,0(sp)
    8000216e:	6145                	addi	sp,sp,48
    80002170:	8082                	ret

0000000080002172 <exit>:
{
    80002172:	7179                	addi	sp,sp,-48
    80002174:	f406                	sd	ra,40(sp)
    80002176:	f022                	sd	s0,32(sp)
    80002178:	ec26                	sd	s1,24(sp)
    8000217a:	e84a                	sd	s2,16(sp)
    8000217c:	e44e                	sd	s3,8(sp)
    8000217e:	e052                	sd	s4,0(sp)
    80002180:	1800                	addi	s0,sp,48
    80002182:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	812080e7          	jalr	-2030(ra) # 80001996 <myproc>
    8000218c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000218e:	00006797          	auipc	a5,0x6
    80002192:	75a7b783          	ld	a5,1882(a5) # 800088e8 <initproc>
    80002196:	0d050493          	addi	s1,a0,208
    8000219a:	15050913          	addi	s2,a0,336
    8000219e:	02a79363          	bne	a5,a0,800021c4 <exit+0x52>
    panic("init exiting");
    800021a2:	00006517          	auipc	a0,0x6
    800021a6:	0de50513          	addi	a0,a0,222 # 80008280 <digits+0x240>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	392080e7          	jalr	914(ra) # 8000053c <panic>
      fileclose(f);
    800021b2:	00002097          	auipc	ra,0x2
    800021b6:	2d8080e7          	jalr	728(ra) # 8000448a <fileclose>
      p->ofile[fd] = 0;
    800021ba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021be:	04a1                	addi	s1,s1,8
    800021c0:	01248563          	beq	s1,s2,800021ca <exit+0x58>
    if(p->ofile[fd]){
    800021c4:	6088                	ld	a0,0(s1)
    800021c6:	f575                	bnez	a0,800021b2 <exit+0x40>
    800021c8:	bfdd                	j	800021be <exit+0x4c>
  begin_op();
    800021ca:	00002097          	auipc	ra,0x2
    800021ce:	dfc080e7          	jalr	-516(ra) # 80003fc6 <begin_op>
  iput(p->cwd);
    800021d2:	1509b503          	ld	a0,336(s3)
    800021d6:	00001097          	auipc	ra,0x1
    800021da:	604080e7          	jalr	1540(ra) # 800037da <iput>
  end_op();
    800021de:	00002097          	auipc	ra,0x2
    800021e2:	e62080e7          	jalr	-414(ra) # 80004040 <end_op>
  p->cwd = 0;
    800021e6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800021ea:	0000f497          	auipc	s1,0xf
    800021ee:	98e48493          	addi	s1,s1,-1650 # 80010b78 <wait_lock>
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	9de080e7          	jalr	-1570(ra) # 80000bd2 <acquire>
  reparent(p);
    800021fc:	854e                	mv	a0,s3
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	f1a080e7          	jalr	-230(ra) # 80002118 <reparent>
  wakeup(p->parent);
    80002206:	0389b503          	ld	a0,56(s3)
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	e98080e7          	jalr	-360(ra) # 800020a2 <wakeup>
  acquire(&p->lock);
    80002212:	854e                	mv	a0,s3
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	9be080e7          	jalr	-1602(ra) # 80000bd2 <acquire>
  p->xstate = status;
    8000221c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002220:	4795                	li	a5,5
    80002222:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a5e080e7          	jalr	-1442(ra) # 80000c86 <release>
  sched();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	cfc080e7          	jalr	-772(ra) # 80001f2c <sched>
  panic("zombie exit");
    80002238:	00006517          	auipc	a0,0x6
    8000223c:	05850513          	addi	a0,a0,88 # 80008290 <digits+0x250>
    80002240:	ffffe097          	auipc	ra,0xffffe
    80002244:	2fc080e7          	jalr	764(ra) # 8000053c <panic>

0000000080002248 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002248:	7179                	addi	sp,sp,-48
    8000224a:	f406                	sd	ra,40(sp)
    8000224c:	f022                	sd	s0,32(sp)
    8000224e:	ec26                	sd	s1,24(sp)
    80002250:	e84a                	sd	s2,16(sp)
    80002252:	e44e                	sd	s3,8(sp)
    80002254:	1800                	addi	s0,sp,48
    80002256:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002258:	0000f497          	auipc	s1,0xf
    8000225c:	d3848493          	addi	s1,s1,-712 # 80010f90 <proc>
    80002260:	00014997          	auipc	s3,0x14
    80002264:	73098993          	addi	s3,s3,1840 # 80016990 <tickslock>
    acquire(&p->lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	968080e7          	jalr	-1688(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    80002272:	589c                	lw	a5,48(s1)
    80002274:	01278d63          	beq	a5,s2,8000228e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	a0c080e7          	jalr	-1524(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002282:	16848493          	addi	s1,s1,360
    80002286:	ff3491e3          	bne	s1,s3,80002268 <kill+0x20>
  }
  return -1;
    8000228a:	557d                	li	a0,-1
    8000228c:	a829                	j	800022a6 <kill+0x5e>
      p->killed = 1;
    8000228e:	4785                	li	a5,1
    80002290:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002292:	4c98                	lw	a4,24(s1)
    80002294:	4789                	li	a5,2
    80002296:	00f70f63          	beq	a4,a5,800022b4 <kill+0x6c>
      release(&p->lock);
    8000229a:	8526                	mv	a0,s1
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	9ea080e7          	jalr	-1558(ra) # 80000c86 <release>
      return 0;
    800022a4:	4501                	li	a0,0
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6145                	addi	sp,sp,48
    800022b2:	8082                	ret
        p->state = RUNNABLE;
    800022b4:	478d                	li	a5,3
    800022b6:	cc9c                	sw	a5,24(s1)
    800022b8:	b7cd                	j	8000229a <kill+0x52>

00000000800022ba <setkilled>:

void
setkilled(struct proc *p)
{
    800022ba:	1101                	addi	sp,sp,-32
    800022bc:	ec06                	sd	ra,24(sp)
    800022be:	e822                	sd	s0,16(sp)
    800022c0:	e426                	sd	s1,8(sp)
    800022c2:	1000                	addi	s0,sp,32
    800022c4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	90c080e7          	jalr	-1780(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800022ce:	4785                	li	a5,1
    800022d0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9b2080e7          	jalr	-1614(ra) # 80000c86 <release>
}
    800022dc:	60e2                	ld	ra,24(sp)
    800022de:	6442                	ld	s0,16(sp)
    800022e0:	64a2                	ld	s1,8(sp)
    800022e2:	6105                	addi	sp,sp,32
    800022e4:	8082                	ret

00000000800022e6 <killed>:

int
killed(struct proc *p)
{
    800022e6:	1101                	addi	sp,sp,-32
    800022e8:	ec06                	sd	ra,24(sp)
    800022ea:	e822                	sd	s0,16(sp)
    800022ec:	e426                	sd	s1,8(sp)
    800022ee:	e04a                	sd	s2,0(sp)
    800022f0:	1000                	addi	s0,sp,32
    800022f2:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8de080e7          	jalr	-1826(ra) # 80000bd2 <acquire>
  k = p->killed;
    800022fc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	984080e7          	jalr	-1660(ra) # 80000c86 <release>
  return k;
}
    8000230a:	854a                	mv	a0,s2
    8000230c:	60e2                	ld	ra,24(sp)
    8000230e:	6442                	ld	s0,16(sp)
    80002310:	64a2                	ld	s1,8(sp)
    80002312:	6902                	ld	s2,0(sp)
    80002314:	6105                	addi	sp,sp,32
    80002316:	8082                	ret

0000000080002318 <wait>:
{
    80002318:	715d                	addi	sp,sp,-80
    8000231a:	e486                	sd	ra,72(sp)
    8000231c:	e0a2                	sd	s0,64(sp)
    8000231e:	fc26                	sd	s1,56(sp)
    80002320:	f84a                	sd	s2,48(sp)
    80002322:	f44e                	sd	s3,40(sp)
    80002324:	f052                	sd	s4,32(sp)
    80002326:	ec56                	sd	s5,24(sp)
    80002328:	e85a                	sd	s6,16(sp)
    8000232a:	e45e                	sd	s7,8(sp)
    8000232c:	e062                	sd	s8,0(sp)
    8000232e:	0880                	addi	s0,sp,80
    80002330:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	664080e7          	jalr	1636(ra) # 80001996 <myproc>
    8000233a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000233c:	0000f517          	auipc	a0,0xf
    80002340:	83c50513          	addi	a0,a0,-1988 # 80010b78 <wait_lock>
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	88e080e7          	jalr	-1906(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000234c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000234e:	4a15                	li	s4,5
        havekids = 1;
    80002350:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002352:	00014997          	auipc	s3,0x14
    80002356:	63e98993          	addi	s3,s3,1598 # 80016990 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000235a:	0000fc17          	auipc	s8,0xf
    8000235e:	81ec0c13          	addi	s8,s8,-2018 # 80010b78 <wait_lock>
    80002362:	a0d1                	j	80002426 <wait+0x10e>
          pid = pp->pid;
    80002364:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002368:	000b0e63          	beqz	s6,80002384 <wait+0x6c>
    8000236c:	4691                	li	a3,4
    8000236e:	02c48613          	addi	a2,s1,44
    80002372:	85da                	mv	a1,s6
    80002374:	05093503          	ld	a0,80(s2)
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	2de080e7          	jalr	734(ra) # 80001656 <copyout>
    80002380:	04054163          	bltz	a0,800023c2 <wait+0xaa>
          freeproc(pp);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	7c2080e7          	jalr	1986(ra) # 80001b48 <freeproc>
          release(&pp->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	8f6080e7          	jalr	-1802(ra) # 80000c86 <release>
          release(&wait_lock);
    80002398:	0000e517          	auipc	a0,0xe
    8000239c:	7e050513          	addi	a0,a0,2016 # 80010b78 <wait_lock>
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8e6080e7          	jalr	-1818(ra) # 80000c86 <release>
}
    800023a8:	854e                	mv	a0,s3
    800023aa:	60a6                	ld	ra,72(sp)
    800023ac:	6406                	ld	s0,64(sp)
    800023ae:	74e2                	ld	s1,56(sp)
    800023b0:	7942                	ld	s2,48(sp)
    800023b2:	79a2                	ld	s3,40(sp)
    800023b4:	7a02                	ld	s4,32(sp)
    800023b6:	6ae2                	ld	s5,24(sp)
    800023b8:	6b42                	ld	s6,16(sp)
    800023ba:	6ba2                	ld	s7,8(sp)
    800023bc:	6c02                	ld	s8,0(sp)
    800023be:	6161                	addi	sp,sp,80
    800023c0:	8082                	ret
            release(&pp->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8c2080e7          	jalr	-1854(ra) # 80000c86 <release>
            release(&wait_lock);
    800023cc:	0000e517          	auipc	a0,0xe
    800023d0:	7ac50513          	addi	a0,a0,1964 # 80010b78 <wait_lock>
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8b2080e7          	jalr	-1870(ra) # 80000c86 <release>
            return -1;
    800023dc:	59fd                	li	s3,-1
    800023de:	b7e9                	j	800023a8 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e0:	16848493          	addi	s1,s1,360
    800023e4:	03348463          	beq	s1,s3,8000240c <wait+0xf4>
      if(pp->parent == p){
    800023e8:	7c9c                	ld	a5,56(s1)
    800023ea:	ff279be3          	bne	a5,s2,800023e0 <wait+0xc8>
        acquire(&pp->lock);
    800023ee:	8526                	mv	a0,s1
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7e2080e7          	jalr	2018(ra) # 80000bd2 <acquire>
        if(pp->state == ZOMBIE){
    800023f8:	4c9c                	lw	a5,24(s1)
    800023fa:	f74785e3          	beq	a5,s4,80002364 <wait+0x4c>
        release(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	886080e7          	jalr	-1914(ra) # 80000c86 <release>
        havekids = 1;
    80002408:	8756                	mv	a4,s5
    8000240a:	bfd9                	j	800023e0 <wait+0xc8>
    if(!havekids || killed(p)){
    8000240c:	c31d                	beqz	a4,80002432 <wait+0x11a>
    8000240e:	854a                	mv	a0,s2
    80002410:	00000097          	auipc	ra,0x0
    80002414:	ed6080e7          	jalr	-298(ra) # 800022e6 <killed>
    80002418:	ed09                	bnez	a0,80002432 <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000241a:	85e2                	mv	a1,s8
    8000241c:	854a                	mv	a0,s2
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	c20080e7          	jalr	-992(ra) # 8000203e <sleep>
    havekids = 0;
    80002426:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002428:	0000f497          	auipc	s1,0xf
    8000242c:	b6848493          	addi	s1,s1,-1176 # 80010f90 <proc>
    80002430:	bf65                	j	800023e8 <wait+0xd0>
      release(&wait_lock);
    80002432:	0000e517          	auipc	a0,0xe
    80002436:	74650513          	addi	a0,a0,1862 # 80010b78 <wait_lock>
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	84c080e7          	jalr	-1972(ra) # 80000c86 <release>
      return -1;
    80002442:	59fd                	li	s3,-1
    80002444:	b795                	j	800023a8 <wait+0x90>

0000000080002446 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002446:	7179                	addi	sp,sp,-48
    80002448:	f406                	sd	ra,40(sp)
    8000244a:	f022                	sd	s0,32(sp)
    8000244c:	ec26                	sd	s1,24(sp)
    8000244e:	e84a                	sd	s2,16(sp)
    80002450:	e44e                	sd	s3,8(sp)
    80002452:	e052                	sd	s4,0(sp)
    80002454:	1800                	addi	s0,sp,48
    80002456:	84aa                	mv	s1,a0
    80002458:	892e                	mv	s2,a1
    8000245a:	89b2                	mv	s3,a2
    8000245c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	538080e7          	jalr	1336(ra) # 80001996 <myproc>
  if(user_dst){
    80002466:	c08d                	beqz	s1,80002488 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002468:	86d2                	mv	a3,s4
    8000246a:	864e                	mv	a2,s3
    8000246c:	85ca                	mv	a1,s2
    8000246e:	6928                	ld	a0,80(a0)
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	1e6080e7          	jalr	486(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6a02                	ld	s4,0(sp)
    80002484:	6145                	addi	sp,sp,48
    80002486:	8082                	ret
    memmove((char *)dst, src, len);
    80002488:	000a061b          	sext.w	a2,s4
    8000248c:	85ce                	mv	a1,s3
    8000248e:	854a                	mv	a0,s2
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	89a080e7          	jalr	-1894(ra) # 80000d2a <memmove>
    return 0;
    80002498:	8526                	mv	a0,s1
    8000249a:	bff9                	j	80002478 <either_copyout+0x32>

000000008000249c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000249c:	7179                	addi	sp,sp,-48
    8000249e:	f406                	sd	ra,40(sp)
    800024a0:	f022                	sd	s0,32(sp)
    800024a2:	ec26                	sd	s1,24(sp)
    800024a4:	e84a                	sd	s2,16(sp)
    800024a6:	e44e                	sd	s3,8(sp)
    800024a8:	e052                	sd	s4,0(sp)
    800024aa:	1800                	addi	s0,sp,48
    800024ac:	892a                	mv	s2,a0
    800024ae:	84ae                	mv	s1,a1
    800024b0:	89b2                	mv	s3,a2
    800024b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	4e2080e7          	jalr	1250(ra) # 80001996 <myproc>
  if(user_src){
    800024bc:	c08d                	beqz	s1,800024de <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024be:	86d2                	mv	a3,s4
    800024c0:	864e                	mv	a2,s3
    800024c2:	85ca                	mv	a1,s2
    800024c4:	6928                	ld	a0,80(a0)
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	21c080e7          	jalr	540(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ce:	70a2                	ld	ra,40(sp)
    800024d0:	7402                	ld	s0,32(sp)
    800024d2:	64e2                	ld	s1,24(sp)
    800024d4:	6942                	ld	s2,16(sp)
    800024d6:	69a2                	ld	s3,8(sp)
    800024d8:	6a02                	ld	s4,0(sp)
    800024da:	6145                	addi	sp,sp,48
    800024dc:	8082                	ret
    memmove(dst, (char*)src, len);
    800024de:	000a061b          	sext.w	a2,s4
    800024e2:	85ce                	mv	a1,s3
    800024e4:	854a                	mv	a0,s2
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	844080e7          	jalr	-1980(ra) # 80000d2a <memmove>
    return 0;
    800024ee:	8526                	mv	a0,s1
    800024f0:	bff9                	j	800024ce <either_copyin+0x32>

00000000800024f2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024f2:	715d                	addi	sp,sp,-80
    800024f4:	e486                	sd	ra,72(sp)
    800024f6:	e0a2                	sd	s0,64(sp)
    800024f8:	fc26                	sd	s1,56(sp)
    800024fa:	f84a                	sd	s2,48(sp)
    800024fc:	f44e                	sd	s3,40(sp)
    800024fe:	f052                	sd	s4,32(sp)
    80002500:	ec56                	sd	s5,24(sp)
    80002502:	e85a                	sd	s6,16(sp)
    80002504:	e45e                	sd	s7,8(sp)
    80002506:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002508:	00006517          	auipc	a0,0x6
    8000250c:	be050513          	addi	a0,a0,-1056 # 800080e8 <digits+0xa8>
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	076080e7          	jalr	118(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002518:	0000f497          	auipc	s1,0xf
    8000251c:	bd048493          	addi	s1,s1,-1072 # 800110e8 <proc+0x158>
    80002520:	00014917          	auipc	s2,0x14
    80002524:	5c890913          	addi	s2,s2,1480 # 80016ae8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002528:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000252a:	00006997          	auipc	s3,0x6
    8000252e:	d7698993          	addi	s3,s3,-650 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002532:	00006a97          	auipc	s5,0x6
    80002536:	d76a8a93          	addi	s5,s5,-650 # 800082a8 <digits+0x268>
    printf("\n");
    8000253a:	00006a17          	auipc	s4,0x6
    8000253e:	baea0a13          	addi	s4,s4,-1106 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002542:	00006b97          	auipc	s7,0x6
    80002546:	da6b8b93          	addi	s7,s7,-602 # 800082e8 <states.0>
    8000254a:	a00d                	j	8000256c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000254c:	ed86a583          	lw	a1,-296(a3)
    80002550:	8556                	mv	a0,s5
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	034080e7          	jalr	52(ra) # 80000586 <printf>
    printf("\n");
    8000255a:	8552                	mv	a0,s4
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	02a080e7          	jalr	42(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002564:	16848493          	addi	s1,s1,360
    80002568:	03248263          	beq	s1,s2,8000258c <procdump+0x9a>
    if(p->state == UNUSED)
    8000256c:	86a6                	mv	a3,s1
    8000256e:	ec04a783          	lw	a5,-320(s1)
    80002572:	dbed                	beqz	a5,80002564 <procdump+0x72>
      state = "???";
    80002574:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002576:	fcfb6be3          	bltu	s6,a5,8000254c <procdump+0x5a>
    8000257a:	02079713          	slli	a4,a5,0x20
    8000257e:	01d75793          	srli	a5,a4,0x1d
    80002582:	97de                	add	a5,a5,s7
    80002584:	6390                	ld	a2,0(a5)
    80002586:	f279                	bnez	a2,8000254c <procdump+0x5a>
      state = "???";
    80002588:	864e                	mv	a2,s3
    8000258a:	b7c9                	j	8000254c <procdump+0x5a>
  }
}
    8000258c:	60a6                	ld	ra,72(sp)
    8000258e:	6406                	ld	s0,64(sp)
    80002590:	74e2                	ld	s1,56(sp)
    80002592:	7942                	ld	s2,48(sp)
    80002594:	79a2                	ld	s3,40(sp)
    80002596:	7a02                	ld	s4,32(sp)
    80002598:	6ae2                	ld	s5,24(sp)
    8000259a:	6b42                	ld	s6,16(sp)
    8000259c:	6ba2                	ld	s7,8(sp)
    8000259e:	6161                	addi	sp,sp,80
    800025a0:	8082                	ret

00000000800025a2 <swtch>:
    800025a2:	00153023          	sd	ra,0(a0)
    800025a6:	00253423          	sd	sp,8(a0)
    800025aa:	e900                	sd	s0,16(a0)
    800025ac:	ed04                	sd	s1,24(a0)
    800025ae:	03253023          	sd	s2,32(a0)
    800025b2:	03353423          	sd	s3,40(a0)
    800025b6:	03453823          	sd	s4,48(a0)
    800025ba:	03553c23          	sd	s5,56(a0)
    800025be:	05653023          	sd	s6,64(a0)
    800025c2:	05753423          	sd	s7,72(a0)
    800025c6:	05853823          	sd	s8,80(a0)
    800025ca:	05953c23          	sd	s9,88(a0)
    800025ce:	07a53023          	sd	s10,96(a0)
    800025d2:	07b53423          	sd	s11,104(a0)
    800025d6:	0005b083          	ld	ra,0(a1)
    800025da:	0085b103          	ld	sp,8(a1)
    800025de:	6980                	ld	s0,16(a1)
    800025e0:	6d84                	ld	s1,24(a1)
    800025e2:	0205b903          	ld	s2,32(a1)
    800025e6:	0285b983          	ld	s3,40(a1)
    800025ea:	0305ba03          	ld	s4,48(a1)
    800025ee:	0385ba83          	ld	s5,56(a1)
    800025f2:	0405bb03          	ld	s6,64(a1)
    800025f6:	0485bb83          	ld	s7,72(a1)
    800025fa:	0505bc03          	ld	s8,80(a1)
    800025fe:	0585bc83          	ld	s9,88(a1)
    80002602:	0605bd03          	ld	s10,96(a1)
    80002606:	0685bd83          	ld	s11,104(a1)
    8000260a:	8082                	ret

000000008000260c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000260c:	1141                	addi	sp,sp,-16
    8000260e:	e406                	sd	ra,8(sp)
    80002610:	e022                	sd	s0,0(sp)
    80002612:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002614:	00006597          	auipc	a1,0x6
    80002618:	d0458593          	addi	a1,a1,-764 # 80008318 <states.0+0x30>
    8000261c:	00014517          	auipc	a0,0x14
    80002620:	37450513          	addi	a0,a0,884 # 80016990 <tickslock>
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	51e080e7          	jalr	1310(ra) # 80000b42 <initlock>
}
    8000262c:	60a2                	ld	ra,8(sp)
    8000262e:	6402                	ld	s0,0(sp)
    80002630:	0141                	addi	sp,sp,16
    80002632:	8082                	ret

0000000080002634 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002634:	1141                	addi	sp,sp,-16
    80002636:	e422                	sd	s0,8(sp)
    80002638:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000263a:	00003797          	auipc	a5,0x3
    8000263e:	47678793          	addi	a5,a5,1142 # 80005ab0 <kernelvec>
    80002642:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002646:	6422                	ld	s0,8(sp)
    80002648:	0141                	addi	sp,sp,16
    8000264a:	8082                	ret

000000008000264c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000264c:	1141                	addi	sp,sp,-16
    8000264e:	e406                	sd	ra,8(sp)
    80002650:	e022                	sd	s0,0(sp)
    80002652:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	342080e7          	jalr	834(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000265c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002660:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002662:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002666:	00005697          	auipc	a3,0x5
    8000266a:	99a68693          	addi	a3,a3,-1638 # 80007000 <_trampoline>
    8000266e:	00005717          	auipc	a4,0x5
    80002672:	99270713          	addi	a4,a4,-1646 # 80007000 <_trampoline>
    80002676:	8f15                	sub	a4,a4,a3
    80002678:	040007b7          	lui	a5,0x4000
    8000267c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000267e:	07b2                	slli	a5,a5,0xc
    80002680:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002682:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002686:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002688:	18002673          	csrr	a2,satp
    8000268c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000268e:	6d30                	ld	a2,88(a0)
    80002690:	6138                	ld	a4,64(a0)
    80002692:	6585                	lui	a1,0x1
    80002694:	972e                	add	a4,a4,a1
    80002696:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002698:	6d38                	ld	a4,88(a0)
    8000269a:	00000617          	auipc	a2,0x0
    8000269e:	13460613          	addi	a2,a2,308 # 800027ce <usertrap>
    800026a2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026a4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026a6:	8612                	mv	a2,tp
    800026a8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026aa:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ae:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026b2:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026ba:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026bc:	6f18                	ld	a4,24(a4)
    800026be:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026c2:	6928                	ld	a0,80(a0)
    800026c4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026c6:	00005717          	auipc	a4,0x5
    800026ca:	9d670713          	addi	a4,a4,-1578 # 8000709c <userret>
    800026ce:	8f15                	sub	a4,a4,a3
    800026d0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026d2:	577d                	li	a4,-1
    800026d4:	177e                	slli	a4,a4,0x3f
    800026d6:	8d59                	or	a0,a0,a4
    800026d8:	9782                	jalr	a5
}
    800026da:	60a2                	ld	ra,8(sp)
    800026dc:	6402                	ld	s0,0(sp)
    800026de:	0141                	addi	sp,sp,16
    800026e0:	8082                	ret

00000000800026e2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026e2:	1101                	addi	sp,sp,-32
    800026e4:	ec06                	sd	ra,24(sp)
    800026e6:	e822                	sd	s0,16(sp)
    800026e8:	e426                	sd	s1,8(sp)
    800026ea:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026ec:	00014497          	auipc	s1,0x14
    800026f0:	2a448493          	addi	s1,s1,676 # 80016990 <tickslock>
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	4dc080e7          	jalr	1244(ra) # 80000bd2 <acquire>
  ticks++;
    800026fe:	00006517          	auipc	a0,0x6
    80002702:	1f250513          	addi	a0,a0,498 # 800088f0 <ticks>
    80002706:	411c                	lw	a5,0(a0)
    80002708:	2785                	addiw	a5,a5,1
    8000270a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000270c:	00000097          	auipc	ra,0x0
    80002710:	996080e7          	jalr	-1642(ra) # 800020a2 <wakeup>
  release(&tickslock);
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	570080e7          	jalr	1392(ra) # 80000c86 <release>
}
    8000271e:	60e2                	ld	ra,24(sp)
    80002720:	6442                	ld	s0,16(sp)
    80002722:	64a2                	ld	s1,8(sp)
    80002724:	6105                	addi	sp,sp,32
    80002726:	8082                	ret

0000000080002728 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002728:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000272c:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    8000272e:	0807df63          	bgez	a5,800027cc <devintr+0xa4>
{
    80002732:	1101                	addi	sp,sp,-32
    80002734:	ec06                	sd	ra,24(sp)
    80002736:	e822                	sd	s0,16(sp)
    80002738:	e426                	sd	s1,8(sp)
    8000273a:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    8000273c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002740:	46a5                	li	a3,9
    80002742:	00d70d63          	beq	a4,a3,8000275c <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002746:	577d                	li	a4,-1
    80002748:	177e                	slli	a4,a4,0x3f
    8000274a:	0705                	addi	a4,a4,1
    return 0;
    8000274c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000274e:	04e78e63          	beq	a5,a4,800027aa <devintr+0x82>
  }
}
    80002752:	60e2                	ld	ra,24(sp)
    80002754:	6442                	ld	s0,16(sp)
    80002756:	64a2                	ld	s1,8(sp)
    80002758:	6105                	addi	sp,sp,32
    8000275a:	8082                	ret
    int irq = plic_claim();
    8000275c:	00003097          	auipc	ra,0x3
    80002760:	45c080e7          	jalr	1116(ra) # 80005bb8 <plic_claim>
    80002764:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002766:	47a9                	li	a5,10
    80002768:	02f50763          	beq	a0,a5,80002796 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    8000276c:	4785                	li	a5,1
    8000276e:	02f50963          	beq	a0,a5,800027a0 <devintr+0x78>
    return 1;
    80002772:	4505                	li	a0,1
    } else if(irq){
    80002774:	dcf9                	beqz	s1,80002752 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002776:	85a6                	mv	a1,s1
    80002778:	00006517          	auipc	a0,0x6
    8000277c:	ba850513          	addi	a0,a0,-1112 # 80008320 <states.0+0x38>
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	e06080e7          	jalr	-506(ra) # 80000586 <printf>
      plic_complete(irq);
    80002788:	8526                	mv	a0,s1
    8000278a:	00003097          	auipc	ra,0x3
    8000278e:	452080e7          	jalr	1106(ra) # 80005bdc <plic_complete>
    return 1;
    80002792:	4505                	li	a0,1
    80002794:	bf7d                	j	80002752 <devintr+0x2a>
      uartintr();
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	1fe080e7          	jalr	510(ra) # 80000994 <uartintr>
    if(irq)
    8000279e:	b7ed                	j	80002788 <devintr+0x60>
      virtio_disk_intr();
    800027a0:	00004097          	auipc	ra,0x4
    800027a4:	902080e7          	jalr	-1790(ra) # 800060a2 <virtio_disk_intr>
    if(irq)
    800027a8:	b7c5                	j	80002788 <devintr+0x60>
    if(cpuid() == 0){
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	1c0080e7          	jalr	448(ra) # 8000196a <cpuid>
    800027b2:	c901                	beqz	a0,800027c2 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027b4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027b8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ba:	14479073          	csrw	sip,a5
    return 2;
    800027be:	4509                	li	a0,2
    800027c0:	bf49                	j	80002752 <devintr+0x2a>
      clockintr();
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	f20080e7          	jalr	-224(ra) # 800026e2 <clockintr>
    800027ca:	b7ed                	j	800027b4 <devintr+0x8c>
}
    800027cc:	8082                	ret

00000000800027ce <usertrap>:
{
    800027ce:	1101                	addi	sp,sp,-32
    800027d0:	ec06                	sd	ra,24(sp)
    800027d2:	e822                	sd	s0,16(sp)
    800027d4:	e426                	sd	s1,8(sp)
    800027d6:	e04a                	sd	s2,0(sp)
    800027d8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027da:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027de:	1007f793          	andi	a5,a5,256
    800027e2:	e3b1                	bnez	a5,80002826 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027e4:	00003797          	auipc	a5,0x3
    800027e8:	2cc78793          	addi	a5,a5,716 # 80005ab0 <kernelvec>
    800027ec:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027f0:	fffff097          	auipc	ra,0xfffff
    800027f4:	1a6080e7          	jalr	422(ra) # 80001996 <myproc>
    800027f8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027fa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027fc:	14102773          	csrr	a4,sepc
    80002800:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002802:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002806:	47a1                	li	a5,8
    80002808:	02f70763          	beq	a4,a5,80002836 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	f1c080e7          	jalr	-228(ra) # 80002728 <devintr>
    80002814:	892a                	mv	s2,a0
    80002816:	c151                	beqz	a0,8000289a <usertrap+0xcc>
  if(killed(p))
    80002818:	8526                	mv	a0,s1
    8000281a:	00000097          	auipc	ra,0x0
    8000281e:	acc080e7          	jalr	-1332(ra) # 800022e6 <killed>
    80002822:	c929                	beqz	a0,80002874 <usertrap+0xa6>
    80002824:	a099                	j	8000286a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002826:	00006517          	auipc	a0,0x6
    8000282a:	b1a50513          	addi	a0,a0,-1254 # 80008340 <states.0+0x58>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	d0e080e7          	jalr	-754(ra) # 8000053c <panic>
    if(killed(p))
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	ab0080e7          	jalr	-1360(ra) # 800022e6 <killed>
    8000283e:	e921                	bnez	a0,8000288e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002840:	6cb8                	ld	a4,88(s1)
    80002842:	6f1c                	ld	a5,24(a4)
    80002844:	0791                	addi	a5,a5,4
    80002846:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002848:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000284c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002850:	10079073          	csrw	sstatus,a5
    syscall();
    80002854:	00000097          	auipc	ra,0x0
    80002858:	2d4080e7          	jalr	724(ra) # 80002b28 <syscall>
  if(killed(p))
    8000285c:	8526                	mv	a0,s1
    8000285e:	00000097          	auipc	ra,0x0
    80002862:	a88080e7          	jalr	-1400(ra) # 800022e6 <killed>
    80002866:	c911                	beqz	a0,8000287a <usertrap+0xac>
    80002868:	4901                	li	s2,0
    exit(-1);
    8000286a:	557d                	li	a0,-1
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	906080e7          	jalr	-1786(ra) # 80002172 <exit>
  if(which_dev == 2)
    80002874:	4789                	li	a5,2
    80002876:	04f90f63          	beq	s2,a5,800028d4 <usertrap+0x106>
  usertrapret();
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	dd2080e7          	jalr	-558(ra) # 8000264c <usertrapret>
}
    80002882:	60e2                	ld	ra,24(sp)
    80002884:	6442                	ld	s0,16(sp)
    80002886:	64a2                	ld	s1,8(sp)
    80002888:	6902                	ld	s2,0(sp)
    8000288a:	6105                	addi	sp,sp,32
    8000288c:	8082                	ret
      exit(-1);
    8000288e:	557d                	li	a0,-1
    80002890:	00000097          	auipc	ra,0x0
    80002894:	8e2080e7          	jalr	-1822(ra) # 80002172 <exit>
    80002898:	b765                	j	80002840 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000289e:	5890                	lw	a2,48(s1)
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	ac050513          	addi	a0,a0,-1344 # 80008360 <states.0+0x78>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	cde080e7          	jalr	-802(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028b4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028b8:	00006517          	auipc	a0,0x6
    800028bc:	ad850513          	addi	a0,a0,-1320 # 80008390 <states.0+0xa8>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	cc6080e7          	jalr	-826(ra) # 80000586 <printf>
    setkilled(p);
    800028c8:	8526                	mv	a0,s1
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	9f0080e7          	jalr	-1552(ra) # 800022ba <setkilled>
    800028d2:	b769                	j	8000285c <usertrap+0x8e>
    yield();
    800028d4:	fffff097          	auipc	ra,0xfffff
    800028d8:	72e080e7          	jalr	1838(ra) # 80002002 <yield>
    800028dc:	bf79                	j	8000287a <usertrap+0xac>

00000000800028de <kerneltrap>:
{
    800028de:	7179                	addi	sp,sp,-48
    800028e0:	f406                	sd	ra,40(sp)
    800028e2:	f022                	sd	s0,32(sp)
    800028e4:	ec26                	sd	s1,24(sp)
    800028e6:	e84a                	sd	s2,16(sp)
    800028e8:	e44e                	sd	s3,8(sp)
    800028ea:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028f8:	1004f793          	andi	a5,s1,256
    800028fc:	cb85                	beqz	a5,8000292c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002902:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002904:	ef85                	bnez	a5,8000293c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	e22080e7          	jalr	-478(ra) # 80002728 <devintr>
    8000290e:	cd1d                	beqz	a0,8000294c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002910:	4789                	li	a5,2
    80002912:	06f50a63          	beq	a0,a5,80002986 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002916:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291a:	10049073          	csrw	sstatus,s1
}
    8000291e:	70a2                	ld	ra,40(sp)
    80002920:	7402                	ld	s0,32(sp)
    80002922:	64e2                	ld	s1,24(sp)
    80002924:	6942                	ld	s2,16(sp)
    80002926:	69a2                	ld	s3,8(sp)
    80002928:	6145                	addi	sp,sp,48
    8000292a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	a8450513          	addi	a0,a0,-1404 # 800083b0 <states.0+0xc8>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c08080e7          	jalr	-1016(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a9c50513          	addi	a0,a0,-1380 # 800083d8 <states.0+0xf0>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	bf8080e7          	jalr	-1032(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    8000294c:	85ce                	mv	a1,s3
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	aaa50513          	addi	a0,a0,-1366 # 800083f8 <states.0+0x110>
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	c30080e7          	jalr	-976(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002962:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	aa250513          	addi	a0,a0,-1374 # 80008408 <states.0+0x120>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c18080e7          	jalr	-1000(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	aaa50513          	addi	a0,a0,-1366 # 80008420 <states.0+0x138>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	bbe080e7          	jalr	-1090(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	010080e7          	jalr	16(ra) # 80001996 <myproc>
    8000298e:	d541                	beqz	a0,80002916 <kerneltrap+0x38>
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	006080e7          	jalr	6(ra) # 80001996 <myproc>
    80002998:	4d18                	lw	a4,24(a0)
    8000299a:	4791                	li	a5,4
    8000299c:	f6f71de3          	bne	a4,a5,80002916 <kerneltrap+0x38>
    yield();
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	662080e7          	jalr	1634(ra) # 80002002 <yield>
    800029a8:	b7bd                	j	80002916 <kerneltrap+0x38>

00000000800029aa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029aa:	1101                	addi	sp,sp,-32
    800029ac:	ec06                	sd	ra,24(sp)
    800029ae:	e822                	sd	s0,16(sp)
    800029b0:	e426                	sd	s1,8(sp)
    800029b2:	1000                	addi	s0,sp,32
    800029b4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	fe0080e7          	jalr	-32(ra) # 80001996 <myproc>
  switch (n) {
    800029be:	4795                	li	a5,5
    800029c0:	0497e163          	bltu	a5,s1,80002a02 <argraw+0x58>
    800029c4:	048a                	slli	s1,s1,0x2
    800029c6:	00006717          	auipc	a4,0x6
    800029ca:	a9270713          	addi	a4,a4,-1390 # 80008458 <states.0+0x170>
    800029ce:	94ba                	add	s1,s1,a4
    800029d0:	409c                	lw	a5,0(s1)
    800029d2:	97ba                	add	a5,a5,a4
    800029d4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029d6:	6d3c                	ld	a5,88(a0)
    800029d8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029da:	60e2                	ld	ra,24(sp)
    800029dc:	6442                	ld	s0,16(sp)
    800029de:	64a2                	ld	s1,8(sp)
    800029e0:	6105                	addi	sp,sp,32
    800029e2:	8082                	ret
    return p->trapframe->a1;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	7fa8                	ld	a0,120(a5)
    800029e8:	bfcd                	j	800029da <argraw+0x30>
    return p->trapframe->a2;
    800029ea:	6d3c                	ld	a5,88(a0)
    800029ec:	63c8                	ld	a0,128(a5)
    800029ee:	b7f5                	j	800029da <argraw+0x30>
    return p->trapframe->a3;
    800029f0:	6d3c                	ld	a5,88(a0)
    800029f2:	67c8                	ld	a0,136(a5)
    800029f4:	b7dd                	j	800029da <argraw+0x30>
    return p->trapframe->a4;
    800029f6:	6d3c                	ld	a5,88(a0)
    800029f8:	6bc8                	ld	a0,144(a5)
    800029fa:	b7c5                	j	800029da <argraw+0x30>
    return p->trapframe->a5;
    800029fc:	6d3c                	ld	a5,88(a0)
    800029fe:	6fc8                	ld	a0,152(a5)
    80002a00:	bfe9                	j	800029da <argraw+0x30>
  panic("argraw");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	a2e50513          	addi	a0,a0,-1490 # 80008430 <states.0+0x148>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b32080e7          	jalr	-1230(ra) # 8000053c <panic>

0000000080002a12 <fetchaddr>:
{
    80002a12:	1101                	addi	sp,sp,-32
    80002a14:	ec06                	sd	ra,24(sp)
    80002a16:	e822                	sd	s0,16(sp)
    80002a18:	e426                	sd	s1,8(sp)
    80002a1a:	e04a                	sd	s2,0(sp)
    80002a1c:	1000                	addi	s0,sp,32
    80002a1e:	84aa                	mv	s1,a0
    80002a20:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	f74080e7          	jalr	-140(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a2a:	653c                	ld	a5,72(a0)
    80002a2c:	02f4f863          	bgeu	s1,a5,80002a5c <fetchaddr+0x4a>
    80002a30:	00848713          	addi	a4,s1,8
    80002a34:	02e7e663          	bltu	a5,a4,80002a60 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a38:	46a1                	li	a3,8
    80002a3a:	8626                	mv	a2,s1
    80002a3c:	85ca                	mv	a1,s2
    80002a3e:	6928                	ld	a0,80(a0)
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	ca2080e7          	jalr	-862(ra) # 800016e2 <copyin>
    80002a48:	00a03533          	snez	a0,a0
    80002a4c:	40a00533          	neg	a0,a0
}
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6902                	ld	s2,0(sp)
    80002a58:	6105                	addi	sp,sp,32
    80002a5a:	8082                	ret
    return -1;
    80002a5c:	557d                	li	a0,-1
    80002a5e:	bfcd                	j	80002a50 <fetchaddr+0x3e>
    80002a60:	557d                	li	a0,-1
    80002a62:	b7fd                	j	80002a50 <fetchaddr+0x3e>

0000000080002a64 <fetchstr>:
{
    80002a64:	7179                	addi	sp,sp,-48
    80002a66:	f406                	sd	ra,40(sp)
    80002a68:	f022                	sd	s0,32(sp)
    80002a6a:	ec26                	sd	s1,24(sp)
    80002a6c:	e84a                	sd	s2,16(sp)
    80002a6e:	e44e                	sd	s3,8(sp)
    80002a70:	1800                	addi	s0,sp,48
    80002a72:	892a                	mv	s2,a0
    80002a74:	84ae                	mv	s1,a1
    80002a76:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f1e080e7          	jalr	-226(ra) # 80001996 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a80:	86ce                	mv	a3,s3
    80002a82:	864a                	mv	a2,s2
    80002a84:	85a6                	mv	a1,s1
    80002a86:	6928                	ld	a0,80(a0)
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	ce8080e7          	jalr	-792(ra) # 80001770 <copyinstr>
    80002a90:	00054e63          	bltz	a0,80002aac <fetchstr+0x48>
  return strlen(buf);
    80002a94:	8526                	mv	a0,s1
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	3b2080e7          	jalr	946(ra) # 80000e48 <strlen>
}
    80002a9e:	70a2                	ld	ra,40(sp)
    80002aa0:	7402                	ld	s0,32(sp)
    80002aa2:	64e2                	ld	s1,24(sp)
    80002aa4:	6942                	ld	s2,16(sp)
    80002aa6:	69a2                	ld	s3,8(sp)
    80002aa8:	6145                	addi	sp,sp,48
    80002aaa:	8082                	ret
    return -1;
    80002aac:	557d                	li	a0,-1
    80002aae:	bfc5                	j	80002a9e <fetchstr+0x3a>

0000000080002ab0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ab0:	1101                	addi	sp,sp,-32
    80002ab2:	ec06                	sd	ra,24(sp)
    80002ab4:	e822                	sd	s0,16(sp)
    80002ab6:	e426                	sd	s1,8(sp)
    80002ab8:	1000                	addi	s0,sp,32
    80002aba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002abc:	00000097          	auipc	ra,0x0
    80002ac0:	eee080e7          	jalr	-274(ra) # 800029aa <argraw>
    80002ac4:	c088                	sw	a0,0(s1)
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret

0000000080002ad0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	1000                	addi	s0,sp,32
    80002ada:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	ece080e7          	jalr	-306(ra) # 800029aa <argraw>
    80002ae4:	e088                	sd	a0,0(s1)
}
    80002ae6:	60e2                	ld	ra,24(sp)
    80002ae8:	6442                	ld	s0,16(sp)
    80002aea:	64a2                	ld	s1,8(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret

0000000080002af0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002af0:	7179                	addi	sp,sp,-48
    80002af2:	f406                	sd	ra,40(sp)
    80002af4:	f022                	sd	s0,32(sp)
    80002af6:	ec26                	sd	s1,24(sp)
    80002af8:	e84a                	sd	s2,16(sp)
    80002afa:	1800                	addi	s0,sp,48
    80002afc:	84ae                	mv	s1,a1
    80002afe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b00:	fd840593          	addi	a1,s0,-40
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	fcc080e7          	jalr	-52(ra) # 80002ad0 <argaddr>
  return fetchstr(addr, buf, max);
    80002b0c:	864a                	mv	a2,s2
    80002b0e:	85a6                	mv	a1,s1
    80002b10:	fd843503          	ld	a0,-40(s0)
    80002b14:	00000097          	auipc	ra,0x0
    80002b18:	f50080e7          	jalr	-176(ra) # 80002a64 <fetchstr>
}
    80002b1c:	70a2                	ld	ra,40(sp)
    80002b1e:	7402                	ld	s0,32(sp)
    80002b20:	64e2                	ld	s1,24(sp)
    80002b22:	6942                	ld	s2,16(sp)
    80002b24:	6145                	addi	sp,sp,48
    80002b26:	8082                	ret

0000000080002b28 <syscall>:
[SYS_ps]      sys_ps,
};

void
syscall(void)
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	e62080e7          	jalr	-414(ra) # 80001996 <myproc>
    80002b3c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b3e:	05853903          	ld	s2,88(a0)
    80002b42:	0a893783          	ld	a5,168(s2)
    80002b46:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b4a:	37fd                	addiw	a5,a5,-1
    80002b4c:	4755                	li	a4,21
    80002b4e:	00f76f63          	bltu	a4,a5,80002b6c <syscall+0x44>
    80002b52:	00369713          	slli	a4,a3,0x3
    80002b56:	00006797          	auipc	a5,0x6
    80002b5a:	91a78793          	addi	a5,a5,-1766 # 80008470 <syscalls>
    80002b5e:	97ba                	add	a5,a5,a4
    80002b60:	639c                	ld	a5,0(a5)
    80002b62:	c789                	beqz	a5,80002b6c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b64:	9782                	jalr	a5
    80002b66:	06a93823          	sd	a0,112(s2)
    80002b6a:	a839                	j	80002b88 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b6c:	15848613          	addi	a2,s1,344
    80002b70:	588c                	lw	a1,48(s1)
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	8c650513          	addi	a0,a0,-1850 # 80008438 <states.0+0x150>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	a0c080e7          	jalr	-1524(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b82:	6cbc                	ld	a5,88(s1)
    80002b84:	577d                	li	a4,-1
    80002b86:	fbb8                	sd	a4,112(a5)
  }
}
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6902                	ld	s2,0(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret

0000000080002b94 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b94:	1101                	addi	sp,sp,-32
    80002b96:	ec06                	sd	ra,24(sp)
    80002b98:	e822                	sd	s0,16(sp)
    80002b9a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002b9c:	fec40593          	addi	a1,s0,-20
    80002ba0:	4501                	li	a0,0
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	f0e080e7          	jalr	-242(ra) # 80002ab0 <argint>
  exit(n);
    80002baa:	fec42503          	lw	a0,-20(s0)
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	5c4080e7          	jalr	1476(ra) # 80002172 <exit>
  return 0;  // not reached
}
    80002bb6:	4501                	li	a0,0
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	6105                	addi	sp,sp,32
    80002bbe:	8082                	ret

0000000080002bc0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bc0:	1141                	addi	sp,sp,-16
    80002bc2:	e406                	sd	ra,8(sp)
    80002bc4:	e022                	sd	s0,0(sp)
    80002bc6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	dce080e7          	jalr	-562(ra) # 80001996 <myproc>
}
    80002bd0:	5908                	lw	a0,48(a0)
    80002bd2:	60a2                	ld	ra,8(sp)
    80002bd4:	6402                	ld	s0,0(sp)
    80002bd6:	0141                	addi	sp,sp,16
    80002bd8:	8082                	ret

0000000080002bda <sys_fork>:

uint64
sys_fork(void)
{
    80002bda:	1141                	addi	sp,sp,-16
    80002bdc:	e406                	sd	ra,8(sp)
    80002bde:	e022                	sd	s0,0(sp)
    80002be0:	0800                	addi	s0,sp,16
  return fork();
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	16a080e7          	jalr	362(ra) # 80001d4c <fork>
}
    80002bea:	60a2                	ld	ra,8(sp)
    80002bec:	6402                	ld	s0,0(sp)
    80002bee:	0141                	addi	sp,sp,16
    80002bf0:	8082                	ret

0000000080002bf2 <sys_wait>:

uint64
sys_wait(void)
{
    80002bf2:	1101                	addi	sp,sp,-32
    80002bf4:	ec06                	sd	ra,24(sp)
    80002bf6:	e822                	sd	s0,16(sp)
    80002bf8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002bfa:	fe840593          	addi	a1,s0,-24
    80002bfe:	4501                	li	a0,0
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	ed0080e7          	jalr	-304(ra) # 80002ad0 <argaddr>
  return wait(p);
    80002c08:	fe843503          	ld	a0,-24(s0)
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	70c080e7          	jalr	1804(ra) # 80002318 <wait>
}
    80002c14:	60e2                	ld	ra,24(sp)
    80002c16:	6442                	ld	s0,16(sp)
    80002c18:	6105                	addi	sp,sp,32
    80002c1a:	8082                	ret

0000000080002c1c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c1c:	7179                	addi	sp,sp,-48
    80002c1e:	f406                	sd	ra,40(sp)
    80002c20:	f022                	sd	s0,32(sp)
    80002c22:	ec26                	sd	s1,24(sp)
    80002c24:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c26:	fdc40593          	addi	a1,s0,-36
    80002c2a:	4501                	li	a0,0
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	e84080e7          	jalr	-380(ra) # 80002ab0 <argint>
  addr = myproc()->sz;
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	d62080e7          	jalr	-670(ra) # 80001996 <myproc>
    80002c3c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c3e:	fdc42503          	lw	a0,-36(s0)
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	0ae080e7          	jalr	174(ra) # 80001cf0 <growproc>
    80002c4a:	00054863          	bltz	a0,80002c5a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c4e:	8526                	mv	a0,s1
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret
    return -1;
    80002c5a:	54fd                	li	s1,-1
    80002c5c:	bfcd                	j	80002c4e <sys_sbrk+0x32>

0000000080002c5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c5e:	7139                	addi	sp,sp,-64
    80002c60:	fc06                	sd	ra,56(sp)
    80002c62:	f822                	sd	s0,48(sp)
    80002c64:	f426                	sd	s1,40(sp)
    80002c66:	f04a                	sd	s2,32(sp)
    80002c68:	ec4e                	sd	s3,24(sp)
    80002c6a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002c6c:	fcc40593          	addi	a1,s0,-52
    80002c70:	4501                	li	a0,0
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	e3e080e7          	jalr	-450(ra) # 80002ab0 <argint>
  acquire(&tickslock);
    80002c7a:	00014517          	auipc	a0,0x14
    80002c7e:	d1650513          	addi	a0,a0,-746 # 80016990 <tickslock>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	f50080e7          	jalr	-176(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002c8a:	00006917          	auipc	s2,0x6
    80002c8e:	c6692903          	lw	s2,-922(s2) # 800088f0 <ticks>
  while(ticks - ticks0 < n){
    80002c92:	fcc42783          	lw	a5,-52(s0)
    80002c96:	cf9d                	beqz	a5,80002cd4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c98:	00014997          	auipc	s3,0x14
    80002c9c:	cf898993          	addi	s3,s3,-776 # 80016990 <tickslock>
    80002ca0:	00006497          	auipc	s1,0x6
    80002ca4:	c5048493          	addi	s1,s1,-944 # 800088f0 <ticks>
    if(killed(myproc())){
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	cee080e7          	jalr	-786(ra) # 80001996 <myproc>
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	636080e7          	jalr	1590(ra) # 800022e6 <killed>
    80002cb8:	ed15                	bnez	a0,80002cf4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cba:	85ce                	mv	a1,s3
    80002cbc:	8526                	mv	a0,s1
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	380080e7          	jalr	896(ra) # 8000203e <sleep>
  while(ticks - ticks0 < n){
    80002cc6:	409c                	lw	a5,0(s1)
    80002cc8:	412787bb          	subw	a5,a5,s2
    80002ccc:	fcc42703          	lw	a4,-52(s0)
    80002cd0:	fce7ece3          	bltu	a5,a4,80002ca8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002cd4:	00014517          	auipc	a0,0x14
    80002cd8:	cbc50513          	addi	a0,a0,-836 # 80016990 <tickslock>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	faa080e7          	jalr	-86(ra) # 80000c86 <release>
  return 0;
    80002ce4:	4501                	li	a0,0
}
    80002ce6:	70e2                	ld	ra,56(sp)
    80002ce8:	7442                	ld	s0,48(sp)
    80002cea:	74a2                	ld	s1,40(sp)
    80002cec:	7902                	ld	s2,32(sp)
    80002cee:	69e2                	ld	s3,24(sp)
    80002cf0:	6121                	addi	sp,sp,64
    80002cf2:	8082                	ret
      release(&tickslock);
    80002cf4:	00014517          	auipc	a0,0x14
    80002cf8:	c9c50513          	addi	a0,a0,-868 # 80016990 <tickslock>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	f8a080e7          	jalr	-118(ra) # 80000c86 <release>
      return -1;
    80002d04:	557d                	li	a0,-1
    80002d06:	b7c5                	j	80002ce6 <sys_sleep+0x88>

0000000080002d08 <sys_kill>:

uint64
sys_kill(void)
{
    80002d08:	1101                	addi	sp,sp,-32
    80002d0a:	ec06                	sd	ra,24(sp)
    80002d0c:	e822                	sd	s0,16(sp)
    80002d0e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d10:	fec40593          	addi	a1,s0,-20
    80002d14:	4501                	li	a0,0
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	d9a080e7          	jalr	-614(ra) # 80002ab0 <argint>
  return kill(pid);
    80002d1e:	fec42503          	lw	a0,-20(s0)
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	526080e7          	jalr	1318(ra) # 80002248 <kill>
}
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d3c:	00014517          	auipc	a0,0x14
    80002d40:	c5450513          	addi	a0,a0,-940 # 80016990 <tickslock>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	e8e080e7          	jalr	-370(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002d4c:	00006497          	auipc	s1,0x6
    80002d50:	ba44a483          	lw	s1,-1116(s1) # 800088f0 <ticks>
  release(&tickslock);
    80002d54:	00014517          	auipc	a0,0x14
    80002d58:	c3c50513          	addi	a0,a0,-964 # 80016990 <tickslock>
    80002d5c:	ffffe097          	auipc	ra,0xffffe
    80002d60:	f2a080e7          	jalr	-214(ra) # 80000c86 <release>
  return xticks;
}
    80002d64:	02049513          	slli	a0,s1,0x20
    80002d68:	9101                	srli	a0,a0,0x20
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	64a2                	ld	s1,8(sp)
    80002d70:	6105                	addi	sp,sp,32
    80002d72:	8082                	ret

0000000080002d74 <sys_ps>:

uint64
sys_ps(void)
{
    80002d74:	1141                	addi	sp,sp,-16
    80002d76:	e422                	sd	s0,8(sp)
    80002d78:	0800                	addi	s0,sp,16
  // EEE3535-01 Operating Systems
  // Assignment 1: Process and System Call
  return 0;
}
    80002d7a:	4501                	li	a0,0
    80002d7c:	6422                	ld	s0,8(sp)
    80002d7e:	0141                	addi	sp,sp,16
    80002d80:	8082                	ret

0000000080002d82 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d82:	7179                	addi	sp,sp,-48
    80002d84:	f406                	sd	ra,40(sp)
    80002d86:	f022                	sd	s0,32(sp)
    80002d88:	ec26                	sd	s1,24(sp)
    80002d8a:	e84a                	sd	s2,16(sp)
    80002d8c:	e44e                	sd	s3,8(sp)
    80002d8e:	e052                	sd	s4,0(sp)
    80002d90:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d92:	00005597          	auipc	a1,0x5
    80002d96:	79658593          	addi	a1,a1,1942 # 80008528 <syscalls+0xb8>
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	c0e50513          	addi	a0,a0,-1010 # 800169a8 <bcache>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	da0080e7          	jalr	-608(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002daa:	0001c797          	auipc	a5,0x1c
    80002dae:	bfe78793          	addi	a5,a5,-1026 # 8001e9a8 <bcache+0x8000>
    80002db2:	0001c717          	auipc	a4,0x1c
    80002db6:	e5e70713          	addi	a4,a4,-418 # 8001ec10 <bcache+0x8268>
    80002dba:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dbe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dc2:	00014497          	auipc	s1,0x14
    80002dc6:	bfe48493          	addi	s1,s1,-1026 # 800169c0 <bcache+0x18>
    b->next = bcache.head.next;
    80002dca:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dcc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dce:	00005a17          	auipc	s4,0x5
    80002dd2:	762a0a13          	addi	s4,s4,1890 # 80008530 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002dd6:	2b893783          	ld	a5,696(s2)
    80002dda:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ddc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002de0:	85d2                	mv	a1,s4
    80002de2:	01048513          	addi	a0,s1,16
    80002de6:	00001097          	auipc	ra,0x1
    80002dea:	496080e7          	jalr	1174(ra) # 8000427c <initsleeplock>
    bcache.head.next->prev = b;
    80002dee:	2b893783          	ld	a5,696(s2)
    80002df2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002df4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002df8:	45848493          	addi	s1,s1,1112
    80002dfc:	fd349de3          	bne	s1,s3,80002dd6 <binit+0x54>
  }
}
    80002e00:	70a2                	ld	ra,40(sp)
    80002e02:	7402                	ld	s0,32(sp)
    80002e04:	64e2                	ld	s1,24(sp)
    80002e06:	6942                	ld	s2,16(sp)
    80002e08:	69a2                	ld	s3,8(sp)
    80002e0a:	6a02                	ld	s4,0(sp)
    80002e0c:	6145                	addi	sp,sp,48
    80002e0e:	8082                	ret

0000000080002e10 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e10:	7179                	addi	sp,sp,-48
    80002e12:	f406                	sd	ra,40(sp)
    80002e14:	f022                	sd	s0,32(sp)
    80002e16:	ec26                	sd	s1,24(sp)
    80002e18:	e84a                	sd	s2,16(sp)
    80002e1a:	e44e                	sd	s3,8(sp)
    80002e1c:	1800                	addi	s0,sp,48
    80002e1e:	892a                	mv	s2,a0
    80002e20:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e22:	00014517          	auipc	a0,0x14
    80002e26:	b8650513          	addi	a0,a0,-1146 # 800169a8 <bcache>
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	da8080e7          	jalr	-600(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e32:	0001c497          	auipc	s1,0x1c
    80002e36:	e2e4b483          	ld	s1,-466(s1) # 8001ec60 <bcache+0x82b8>
    80002e3a:	0001c797          	auipc	a5,0x1c
    80002e3e:	dd678793          	addi	a5,a5,-554 # 8001ec10 <bcache+0x8268>
    80002e42:	02f48f63          	beq	s1,a5,80002e80 <bread+0x70>
    80002e46:	873e                	mv	a4,a5
    80002e48:	a021                	j	80002e50 <bread+0x40>
    80002e4a:	68a4                	ld	s1,80(s1)
    80002e4c:	02e48a63          	beq	s1,a4,80002e80 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e50:	449c                	lw	a5,8(s1)
    80002e52:	ff279ce3          	bne	a5,s2,80002e4a <bread+0x3a>
    80002e56:	44dc                	lw	a5,12(s1)
    80002e58:	ff3799e3          	bne	a5,s3,80002e4a <bread+0x3a>
      b->refcnt++;
    80002e5c:	40bc                	lw	a5,64(s1)
    80002e5e:	2785                	addiw	a5,a5,1
    80002e60:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e62:	00014517          	auipc	a0,0x14
    80002e66:	b4650513          	addi	a0,a0,-1210 # 800169a8 <bcache>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	e1c080e7          	jalr	-484(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002e72:	01048513          	addi	a0,s1,16
    80002e76:	00001097          	auipc	ra,0x1
    80002e7a:	440080e7          	jalr	1088(ra) # 800042b6 <acquiresleep>
      return b;
    80002e7e:	a8b9                	j	80002edc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e80:	0001c497          	auipc	s1,0x1c
    80002e84:	dd84b483          	ld	s1,-552(s1) # 8001ec58 <bcache+0x82b0>
    80002e88:	0001c797          	auipc	a5,0x1c
    80002e8c:	d8878793          	addi	a5,a5,-632 # 8001ec10 <bcache+0x8268>
    80002e90:	00f48863          	beq	s1,a5,80002ea0 <bread+0x90>
    80002e94:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e96:	40bc                	lw	a5,64(s1)
    80002e98:	cf81                	beqz	a5,80002eb0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e9a:	64a4                	ld	s1,72(s1)
    80002e9c:	fee49de3          	bne	s1,a4,80002e96 <bread+0x86>
  panic("bget: no buffers");
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	69850513          	addi	a0,a0,1688 # 80008538 <syscalls+0xc8>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	694080e7          	jalr	1684(ra) # 8000053c <panic>
      b->dev = dev;
    80002eb0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002eb4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002eb8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ebc:	4785                	li	a5,1
    80002ebe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec0:	00014517          	auipc	a0,0x14
    80002ec4:	ae850513          	addi	a0,a0,-1304 # 800169a8 <bcache>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	dbe080e7          	jalr	-578(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002ed0:	01048513          	addi	a0,s1,16
    80002ed4:	00001097          	auipc	ra,0x1
    80002ed8:	3e2080e7          	jalr	994(ra) # 800042b6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002edc:	409c                	lw	a5,0(s1)
    80002ede:	cb89                	beqz	a5,80002ef0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	70a2                	ld	ra,40(sp)
    80002ee4:	7402                	ld	s0,32(sp)
    80002ee6:	64e2                	ld	s1,24(sp)
    80002ee8:	6942                	ld	s2,16(sp)
    80002eea:	69a2                	ld	s3,8(sp)
    80002eec:	6145                	addi	sp,sp,48
    80002eee:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ef0:	4581                	li	a1,0
    80002ef2:	8526                	mv	a0,s1
    80002ef4:	00003097          	auipc	ra,0x3
    80002ef8:	f7e080e7          	jalr	-130(ra) # 80005e72 <virtio_disk_rw>
    b->valid = 1;
    80002efc:	4785                	li	a5,1
    80002efe:	c09c                	sw	a5,0(s1)
  return b;
    80002f00:	b7c5                	j	80002ee0 <bread+0xd0>

0000000080002f02 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	e426                	sd	s1,8(sp)
    80002f0a:	1000                	addi	s0,sp,32
    80002f0c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f0e:	0541                	addi	a0,a0,16
    80002f10:	00001097          	auipc	ra,0x1
    80002f14:	440080e7          	jalr	1088(ra) # 80004350 <holdingsleep>
    80002f18:	cd01                	beqz	a0,80002f30 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f1a:	4585                	li	a1,1
    80002f1c:	8526                	mv	a0,s1
    80002f1e:	00003097          	auipc	ra,0x3
    80002f22:	f54080e7          	jalr	-172(ra) # 80005e72 <virtio_disk_rw>
}
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	64a2                	ld	s1,8(sp)
    80002f2c:	6105                	addi	sp,sp,32
    80002f2e:	8082                	ret
    panic("bwrite");
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	62050513          	addi	a0,a0,1568 # 80008550 <syscalls+0xe0>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	604080e7          	jalr	1540(ra) # 8000053c <panic>

0000000080002f40 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f40:	1101                	addi	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	e426                	sd	s1,8(sp)
    80002f48:	e04a                	sd	s2,0(sp)
    80002f4a:	1000                	addi	s0,sp,32
    80002f4c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f4e:	01050913          	addi	s2,a0,16
    80002f52:	854a                	mv	a0,s2
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	3fc080e7          	jalr	1020(ra) # 80004350 <holdingsleep>
    80002f5c:	c925                	beqz	a0,80002fcc <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80002f5e:	854a                	mv	a0,s2
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	3ac080e7          	jalr	940(ra) # 8000430c <releasesleep>

  acquire(&bcache.lock);
    80002f68:	00014517          	auipc	a0,0x14
    80002f6c:	a4050513          	addi	a0,a0,-1472 # 800169a8 <bcache>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	c62080e7          	jalr	-926(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80002f78:	40bc                	lw	a5,64(s1)
    80002f7a:	37fd                	addiw	a5,a5,-1
    80002f7c:	0007871b          	sext.w	a4,a5
    80002f80:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f82:	e71d                	bnez	a4,80002fb0 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f84:	68b8                	ld	a4,80(s1)
    80002f86:	64bc                	ld	a5,72(s1)
    80002f88:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002f8a:	68b8                	ld	a4,80(s1)
    80002f8c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f8e:	0001c797          	auipc	a5,0x1c
    80002f92:	a1a78793          	addi	a5,a5,-1510 # 8001e9a8 <bcache+0x8000>
    80002f96:	2b87b703          	ld	a4,696(a5)
    80002f9a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f9c:	0001c717          	auipc	a4,0x1c
    80002fa0:	c7470713          	addi	a4,a4,-908 # 8001ec10 <bcache+0x8268>
    80002fa4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fa6:	2b87b703          	ld	a4,696(a5)
    80002faa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fb0:	00014517          	auipc	a0,0x14
    80002fb4:	9f850513          	addi	a0,a0,-1544 # 800169a8 <bcache>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	cce080e7          	jalr	-818(ra) # 80000c86 <release>
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6902                	ld	s2,0(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret
    panic("brelse");
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	58c50513          	addi	a0,a0,1420 # 80008558 <syscalls+0xe8>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	568080e7          	jalr	1384(ra) # 8000053c <panic>

0000000080002fdc <bpin>:

void
bpin(struct buf *b) {
    80002fdc:	1101                	addi	sp,sp,-32
    80002fde:	ec06                	sd	ra,24(sp)
    80002fe0:	e822                	sd	s0,16(sp)
    80002fe2:	e426                	sd	s1,8(sp)
    80002fe4:	1000                	addi	s0,sp,32
    80002fe6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	9c050513          	addi	a0,a0,-1600 # 800169a8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	be2080e7          	jalr	-1054(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80002ff8:	40bc                	lw	a5,64(s1)
    80002ffa:	2785                	addiw	a5,a5,1
    80002ffc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ffe:	00014517          	auipc	a0,0x14
    80003002:	9aa50513          	addi	a0,a0,-1622 # 800169a8 <bcache>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	c80080e7          	jalr	-896(ra) # 80000c86 <release>
}
    8000300e:	60e2                	ld	ra,24(sp)
    80003010:	6442                	ld	s0,16(sp)
    80003012:	64a2                	ld	s1,8(sp)
    80003014:	6105                	addi	sp,sp,32
    80003016:	8082                	ret

0000000080003018 <bunpin>:

void
bunpin(struct buf *b) {
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003024:	00014517          	auipc	a0,0x14
    80003028:	98450513          	addi	a0,a0,-1660 # 800169a8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	ba6080e7          	jalr	-1114(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003034:	40bc                	lw	a5,64(s1)
    80003036:	37fd                	addiw	a5,a5,-1
    80003038:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303a:	00014517          	auipc	a0,0x14
    8000303e:	96e50513          	addi	a0,a0,-1682 # 800169a8 <bcache>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c44080e7          	jalr	-956(ra) # 80000c86 <release>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003054:	1101                	addi	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	e04a                	sd	s2,0(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003062:	00d5d59b          	srliw	a1,a1,0xd
    80003066:	0001c797          	auipc	a5,0x1c
    8000306a:	01e7a783          	lw	a5,30(a5) # 8001f084 <sb+0x1c>
    8000306e:	9dbd                	addw	a1,a1,a5
    80003070:	00000097          	auipc	ra,0x0
    80003074:	da0080e7          	jalr	-608(ra) # 80002e10 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003078:	0074f713          	andi	a4,s1,7
    8000307c:	4785                	li	a5,1
    8000307e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003082:	14ce                	slli	s1,s1,0x33
    80003084:	90d9                	srli	s1,s1,0x36
    80003086:	00950733          	add	a4,a0,s1
    8000308a:	05874703          	lbu	a4,88(a4)
    8000308e:	00e7f6b3          	and	a3,a5,a4
    80003092:	c69d                	beqz	a3,800030c0 <bfree+0x6c>
    80003094:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003096:	94aa                	add	s1,s1,a0
    80003098:	fff7c793          	not	a5,a5
    8000309c:	8f7d                	and	a4,a4,a5
    8000309e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	0f6080e7          	jalr	246(ra) # 80004198 <log_write>
  brelse(bp);
    800030aa:	854a                	mv	a0,s2
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	e94080e7          	jalr	-364(ra) # 80002f40 <brelse>
}
    800030b4:	60e2                	ld	ra,24(sp)
    800030b6:	6442                	ld	s0,16(sp)
    800030b8:	64a2                	ld	s1,8(sp)
    800030ba:	6902                	ld	s2,0(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret
    panic("freeing free block");
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	4a050513          	addi	a0,a0,1184 # 80008560 <syscalls+0xf0>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	474080e7          	jalr	1140(ra) # 8000053c <panic>

00000000800030d0 <balloc>:
{
    800030d0:	711d                	addi	sp,sp,-96
    800030d2:	ec86                	sd	ra,88(sp)
    800030d4:	e8a2                	sd	s0,80(sp)
    800030d6:	e4a6                	sd	s1,72(sp)
    800030d8:	e0ca                	sd	s2,64(sp)
    800030da:	fc4e                	sd	s3,56(sp)
    800030dc:	f852                	sd	s4,48(sp)
    800030de:	f456                	sd	s5,40(sp)
    800030e0:	f05a                	sd	s6,32(sp)
    800030e2:	ec5e                	sd	s7,24(sp)
    800030e4:	e862                	sd	s8,16(sp)
    800030e6:	e466                	sd	s9,8(sp)
    800030e8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ea:	0001c797          	auipc	a5,0x1c
    800030ee:	f827a783          	lw	a5,-126(a5) # 8001f06c <sb+0x4>
    800030f2:	cff5                	beqz	a5,800031ee <balloc+0x11e>
    800030f4:	8baa                	mv	s7,a0
    800030f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030f8:	0001cb17          	auipc	s6,0x1c
    800030fc:	f70b0b13          	addi	s6,s6,-144 # 8001f068 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003100:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003102:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003104:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003106:	6c89                	lui	s9,0x2
    80003108:	a061                	j	80003190 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000310a:	97ca                	add	a5,a5,s2
    8000310c:	8e55                	or	a2,a2,a3
    8000310e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003112:	854a                	mv	a0,s2
    80003114:	00001097          	auipc	ra,0x1
    80003118:	084080e7          	jalr	132(ra) # 80004198 <log_write>
        brelse(bp);
    8000311c:	854a                	mv	a0,s2
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	e22080e7          	jalr	-478(ra) # 80002f40 <brelse>
  bp = bread(dev, bno);
    80003126:	85a6                	mv	a1,s1
    80003128:	855e                	mv	a0,s7
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	ce6080e7          	jalr	-794(ra) # 80002e10 <bread>
    80003132:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003134:	40000613          	li	a2,1024
    80003138:	4581                	li	a1,0
    8000313a:	05850513          	addi	a0,a0,88
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b90080e7          	jalr	-1136(ra) # 80000cce <memset>
  log_write(bp);
    80003146:	854a                	mv	a0,s2
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	050080e7          	jalr	80(ra) # 80004198 <log_write>
  brelse(bp);
    80003150:	854a                	mv	a0,s2
    80003152:	00000097          	auipc	ra,0x0
    80003156:	dee080e7          	jalr	-530(ra) # 80002f40 <brelse>
}
    8000315a:	8526                	mv	a0,s1
    8000315c:	60e6                	ld	ra,88(sp)
    8000315e:	6446                	ld	s0,80(sp)
    80003160:	64a6                	ld	s1,72(sp)
    80003162:	6906                	ld	s2,64(sp)
    80003164:	79e2                	ld	s3,56(sp)
    80003166:	7a42                	ld	s4,48(sp)
    80003168:	7aa2                	ld	s5,40(sp)
    8000316a:	7b02                	ld	s6,32(sp)
    8000316c:	6be2                	ld	s7,24(sp)
    8000316e:	6c42                	ld	s8,16(sp)
    80003170:	6ca2                	ld	s9,8(sp)
    80003172:	6125                	addi	sp,sp,96
    80003174:	8082                	ret
    brelse(bp);
    80003176:	854a                	mv	a0,s2
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	dc8080e7          	jalr	-568(ra) # 80002f40 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003180:	015c87bb          	addw	a5,s9,s5
    80003184:	00078a9b          	sext.w	s5,a5
    80003188:	004b2703          	lw	a4,4(s6)
    8000318c:	06eaf163          	bgeu	s5,a4,800031ee <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003190:	41fad79b          	sraiw	a5,s5,0x1f
    80003194:	0137d79b          	srliw	a5,a5,0x13
    80003198:	015787bb          	addw	a5,a5,s5
    8000319c:	40d7d79b          	sraiw	a5,a5,0xd
    800031a0:	01cb2583          	lw	a1,28(s6)
    800031a4:	9dbd                	addw	a1,a1,a5
    800031a6:	855e                	mv	a0,s7
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	c68080e7          	jalr	-920(ra) # 80002e10 <bread>
    800031b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b2:	004b2503          	lw	a0,4(s6)
    800031b6:	000a849b          	sext.w	s1,s5
    800031ba:	8762                	mv	a4,s8
    800031bc:	faa4fde3          	bgeu	s1,a0,80003176 <balloc+0xa6>
      m = 1 << (bi % 8);
    800031c0:	00777693          	andi	a3,a4,7
    800031c4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031c8:	41f7579b          	sraiw	a5,a4,0x1f
    800031cc:	01d7d79b          	srliw	a5,a5,0x1d
    800031d0:	9fb9                	addw	a5,a5,a4
    800031d2:	4037d79b          	sraiw	a5,a5,0x3
    800031d6:	00f90633          	add	a2,s2,a5
    800031da:	05864603          	lbu	a2,88(a2)
    800031de:	00c6f5b3          	and	a1,a3,a2
    800031e2:	d585                	beqz	a1,8000310a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e4:	2705                	addiw	a4,a4,1
    800031e6:	2485                	addiw	s1,s1,1
    800031e8:	fd471ae3          	bne	a4,s4,800031bc <balloc+0xec>
    800031ec:	b769                	j	80003176 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	38a50513          	addi	a0,a0,906 # 80008578 <syscalls+0x108>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	390080e7          	jalr	912(ra) # 80000586 <printf>
  return 0;
    800031fe:	4481                	li	s1,0
    80003200:	bfa9                	j	8000315a <balloc+0x8a>

0000000080003202 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003202:	7179                	addi	sp,sp,-48
    80003204:	f406                	sd	ra,40(sp)
    80003206:	f022                	sd	s0,32(sp)
    80003208:	ec26                	sd	s1,24(sp)
    8000320a:	e84a                	sd	s2,16(sp)
    8000320c:	e44e                	sd	s3,8(sp)
    8000320e:	e052                	sd	s4,0(sp)
    80003210:	1800                	addi	s0,sp,48
    80003212:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003214:	47ad                	li	a5,11
    80003216:	02b7e863          	bltu	a5,a1,80003246 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000321a:	02059793          	slli	a5,a1,0x20
    8000321e:	01e7d593          	srli	a1,a5,0x1e
    80003222:	00b504b3          	add	s1,a0,a1
    80003226:	0504a903          	lw	s2,80(s1)
    8000322a:	06091e63          	bnez	s2,800032a6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000322e:	4108                	lw	a0,0(a0)
    80003230:	00000097          	auipc	ra,0x0
    80003234:	ea0080e7          	jalr	-352(ra) # 800030d0 <balloc>
    80003238:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000323c:	06090563          	beqz	s2,800032a6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003240:	0524a823          	sw	s2,80(s1)
    80003244:	a08d                	j	800032a6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003246:	ff45849b          	addiw	s1,a1,-12
    8000324a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000324e:	0ff00793          	li	a5,255
    80003252:	08e7e563          	bltu	a5,a4,800032dc <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003256:	08052903          	lw	s2,128(a0)
    8000325a:	00091d63          	bnez	s2,80003274 <bmap+0x72>
      addr = balloc(ip->dev);
    8000325e:	4108                	lw	a0,0(a0)
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e70080e7          	jalr	-400(ra) # 800030d0 <balloc>
    80003268:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000326c:	02090d63          	beqz	s2,800032a6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003270:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003274:	85ca                	mv	a1,s2
    80003276:	0009a503          	lw	a0,0(s3)
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	b96080e7          	jalr	-1130(ra) # 80002e10 <bread>
    80003282:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003284:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003288:	02049713          	slli	a4,s1,0x20
    8000328c:	01e75593          	srli	a1,a4,0x1e
    80003290:	00b784b3          	add	s1,a5,a1
    80003294:	0004a903          	lw	s2,0(s1)
    80003298:	02090063          	beqz	s2,800032b8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000329c:	8552                	mv	a0,s4
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	ca2080e7          	jalr	-862(ra) # 80002f40 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032a6:	854a                	mv	a0,s2
    800032a8:	70a2                	ld	ra,40(sp)
    800032aa:	7402                	ld	s0,32(sp)
    800032ac:	64e2                	ld	s1,24(sp)
    800032ae:	6942                	ld	s2,16(sp)
    800032b0:	69a2                	ld	s3,8(sp)
    800032b2:	6a02                	ld	s4,0(sp)
    800032b4:	6145                	addi	sp,sp,48
    800032b6:	8082                	ret
      addr = balloc(ip->dev);
    800032b8:	0009a503          	lw	a0,0(s3)
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e14080e7          	jalr	-492(ra) # 800030d0 <balloc>
    800032c4:	0005091b          	sext.w	s2,a0
      if(addr){
    800032c8:	fc090ae3          	beqz	s2,8000329c <bmap+0x9a>
        a[bn] = addr;
    800032cc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032d0:	8552                	mv	a0,s4
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	ec6080e7          	jalr	-314(ra) # 80004198 <log_write>
    800032da:	b7c9                	j	8000329c <bmap+0x9a>
  panic("bmap: out of range");
    800032dc:	00005517          	auipc	a0,0x5
    800032e0:	2b450513          	addi	a0,a0,692 # 80008590 <syscalls+0x120>
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	258080e7          	jalr	600(ra) # 8000053c <panic>

00000000800032ec <iget>:
{
    800032ec:	7179                	addi	sp,sp,-48
    800032ee:	f406                	sd	ra,40(sp)
    800032f0:	f022                	sd	s0,32(sp)
    800032f2:	ec26                	sd	s1,24(sp)
    800032f4:	e84a                	sd	s2,16(sp)
    800032f6:	e44e                	sd	s3,8(sp)
    800032f8:	e052                	sd	s4,0(sp)
    800032fa:	1800                	addi	s0,sp,48
    800032fc:	89aa                	mv	s3,a0
    800032fe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003300:	0001c517          	auipc	a0,0x1c
    80003304:	d8850513          	addi	a0,a0,-632 # 8001f088 <itable>
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	8ca080e7          	jalr	-1846(ra) # 80000bd2 <acquire>
  empty = 0;
    80003310:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003312:	0001c497          	auipc	s1,0x1c
    80003316:	d8e48493          	addi	s1,s1,-626 # 8001f0a0 <itable+0x18>
    8000331a:	0001e697          	auipc	a3,0x1e
    8000331e:	81668693          	addi	a3,a3,-2026 # 80020b30 <log>
    80003322:	a039                	j	80003330 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003324:	02090b63          	beqz	s2,8000335a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003328:	08848493          	addi	s1,s1,136
    8000332c:	02d48a63          	beq	s1,a3,80003360 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003330:	449c                	lw	a5,8(s1)
    80003332:	fef059e3          	blez	a5,80003324 <iget+0x38>
    80003336:	4098                	lw	a4,0(s1)
    80003338:	ff3716e3          	bne	a4,s3,80003324 <iget+0x38>
    8000333c:	40d8                	lw	a4,4(s1)
    8000333e:	ff4713e3          	bne	a4,s4,80003324 <iget+0x38>
      ip->ref++;
    80003342:	2785                	addiw	a5,a5,1
    80003344:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003346:	0001c517          	auipc	a0,0x1c
    8000334a:	d4250513          	addi	a0,a0,-702 # 8001f088 <itable>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	938080e7          	jalr	-1736(ra) # 80000c86 <release>
      return ip;
    80003356:	8926                	mv	s2,s1
    80003358:	a03d                	j	80003386 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000335a:	f7f9                	bnez	a5,80003328 <iget+0x3c>
    8000335c:	8926                	mv	s2,s1
    8000335e:	b7e9                	j	80003328 <iget+0x3c>
  if(empty == 0)
    80003360:	02090c63          	beqz	s2,80003398 <iget+0xac>
  ip->dev = dev;
    80003364:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003368:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000336c:	4785                	li	a5,1
    8000336e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003372:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003376:	0001c517          	auipc	a0,0x1c
    8000337a:	d1250513          	addi	a0,a0,-750 # 8001f088 <itable>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	908080e7          	jalr	-1784(ra) # 80000c86 <release>
}
    80003386:	854a                	mv	a0,s2
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6a02                	ld	s4,0(sp)
    80003394:	6145                	addi	sp,sp,48
    80003396:	8082                	ret
    panic("iget: no inodes");
    80003398:	00005517          	auipc	a0,0x5
    8000339c:	21050513          	addi	a0,a0,528 # 800085a8 <syscalls+0x138>
    800033a0:	ffffd097          	auipc	ra,0xffffd
    800033a4:	19c080e7          	jalr	412(ra) # 8000053c <panic>

00000000800033a8 <fsinit>:
fsinit(int dev) {
    800033a8:	7179                	addi	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	1800                	addi	s0,sp,48
    800033b6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033b8:	4585                	li	a1,1
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	a56080e7          	jalr	-1450(ra) # 80002e10 <bread>
    800033c2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033c4:	0001c997          	auipc	s3,0x1c
    800033c8:	ca498993          	addi	s3,s3,-860 # 8001f068 <sb>
    800033cc:	02000613          	li	a2,32
    800033d0:	05850593          	addi	a1,a0,88
    800033d4:	854e                	mv	a0,s3
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	954080e7          	jalr	-1708(ra) # 80000d2a <memmove>
  brelse(bp);
    800033de:	8526                	mv	a0,s1
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	b60080e7          	jalr	-1184(ra) # 80002f40 <brelse>
  if(sb.magic != FSMAGIC)
    800033e8:	0009a703          	lw	a4,0(s3)
    800033ec:	102037b7          	lui	a5,0x10203
    800033f0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033f4:	02f71263          	bne	a4,a5,80003418 <fsinit+0x70>
  initlog(dev, &sb);
    800033f8:	0001c597          	auipc	a1,0x1c
    800033fc:	c7058593          	addi	a1,a1,-912 # 8001f068 <sb>
    80003400:	854a                	mv	a0,s2
    80003402:	00001097          	auipc	ra,0x1
    80003406:	b2c080e7          	jalr	-1236(ra) # 80003f2e <initlog>
}
    8000340a:	70a2                	ld	ra,40(sp)
    8000340c:	7402                	ld	s0,32(sp)
    8000340e:	64e2                	ld	s1,24(sp)
    80003410:	6942                	ld	s2,16(sp)
    80003412:	69a2                	ld	s3,8(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret
    panic("invalid file system");
    80003418:	00005517          	auipc	a0,0x5
    8000341c:	1a050513          	addi	a0,a0,416 # 800085b8 <syscalls+0x148>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	11c080e7          	jalr	284(ra) # 8000053c <panic>

0000000080003428 <iinit>:
{
    80003428:	7179                	addi	sp,sp,-48
    8000342a:	f406                	sd	ra,40(sp)
    8000342c:	f022                	sd	s0,32(sp)
    8000342e:	ec26                	sd	s1,24(sp)
    80003430:	e84a                	sd	s2,16(sp)
    80003432:	e44e                	sd	s3,8(sp)
    80003434:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003436:	00005597          	auipc	a1,0x5
    8000343a:	19a58593          	addi	a1,a1,410 # 800085d0 <syscalls+0x160>
    8000343e:	0001c517          	auipc	a0,0x1c
    80003442:	c4a50513          	addi	a0,a0,-950 # 8001f088 <itable>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	6fc080e7          	jalr	1788(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000344e:	0001c497          	auipc	s1,0x1c
    80003452:	c6248493          	addi	s1,s1,-926 # 8001f0b0 <itable+0x28>
    80003456:	0001d997          	auipc	s3,0x1d
    8000345a:	6ea98993          	addi	s3,s3,1770 # 80020b40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000345e:	00005917          	auipc	s2,0x5
    80003462:	17a90913          	addi	s2,s2,378 # 800085d8 <syscalls+0x168>
    80003466:	85ca                	mv	a1,s2
    80003468:	8526                	mv	a0,s1
    8000346a:	00001097          	auipc	ra,0x1
    8000346e:	e12080e7          	jalr	-494(ra) # 8000427c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003472:	08848493          	addi	s1,s1,136
    80003476:	ff3498e3          	bne	s1,s3,80003466 <iinit+0x3e>
}
    8000347a:	70a2                	ld	ra,40(sp)
    8000347c:	7402                	ld	s0,32(sp)
    8000347e:	64e2                	ld	s1,24(sp)
    80003480:	6942                	ld	s2,16(sp)
    80003482:	69a2                	ld	s3,8(sp)
    80003484:	6145                	addi	sp,sp,48
    80003486:	8082                	ret

0000000080003488 <ialloc>:
{
    80003488:	7139                	addi	sp,sp,-64
    8000348a:	fc06                	sd	ra,56(sp)
    8000348c:	f822                	sd	s0,48(sp)
    8000348e:	f426                	sd	s1,40(sp)
    80003490:	f04a                	sd	s2,32(sp)
    80003492:	ec4e                	sd	s3,24(sp)
    80003494:	e852                	sd	s4,16(sp)
    80003496:	e456                	sd	s5,8(sp)
    80003498:	e05a                	sd	s6,0(sp)
    8000349a:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000349c:	0001c717          	auipc	a4,0x1c
    800034a0:	bd872703          	lw	a4,-1064(a4) # 8001f074 <sb+0xc>
    800034a4:	4785                	li	a5,1
    800034a6:	04e7f863          	bgeu	a5,a4,800034f6 <ialloc+0x6e>
    800034aa:	8aaa                	mv	s5,a0
    800034ac:	8b2e                	mv	s6,a1
    800034ae:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034b0:	0001ca17          	auipc	s4,0x1c
    800034b4:	bb8a0a13          	addi	s4,s4,-1096 # 8001f068 <sb>
    800034b8:	00495593          	srli	a1,s2,0x4
    800034bc:	018a2783          	lw	a5,24(s4)
    800034c0:	9dbd                	addw	a1,a1,a5
    800034c2:	8556                	mv	a0,s5
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	94c080e7          	jalr	-1716(ra) # 80002e10 <bread>
    800034cc:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034ce:	05850993          	addi	s3,a0,88
    800034d2:	00f97793          	andi	a5,s2,15
    800034d6:	079a                	slli	a5,a5,0x6
    800034d8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034da:	00099783          	lh	a5,0(s3)
    800034de:	cf9d                	beqz	a5,8000351c <ialloc+0x94>
    brelse(bp);
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	a60080e7          	jalr	-1440(ra) # 80002f40 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034e8:	0905                	addi	s2,s2,1
    800034ea:	00ca2703          	lw	a4,12(s4)
    800034ee:	0009079b          	sext.w	a5,s2
    800034f2:	fce7e3e3          	bltu	a5,a4,800034b8 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800034f6:	00005517          	auipc	a0,0x5
    800034fa:	0ea50513          	addi	a0,a0,234 # 800085e0 <syscalls+0x170>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	088080e7          	jalr	136(ra) # 80000586 <printf>
  return 0;
    80003506:	4501                	li	a0,0
}
    80003508:	70e2                	ld	ra,56(sp)
    8000350a:	7442                	ld	s0,48(sp)
    8000350c:	74a2                	ld	s1,40(sp)
    8000350e:	7902                	ld	s2,32(sp)
    80003510:	69e2                	ld	s3,24(sp)
    80003512:	6a42                	ld	s4,16(sp)
    80003514:	6aa2                	ld	s5,8(sp)
    80003516:	6b02                	ld	s6,0(sp)
    80003518:	6121                	addi	sp,sp,64
    8000351a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000351c:	04000613          	li	a2,64
    80003520:	4581                	li	a1,0
    80003522:	854e                	mv	a0,s3
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	7aa080e7          	jalr	1962(ra) # 80000cce <memset>
      dip->type = type;
    8000352c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003530:	8526                	mv	a0,s1
    80003532:	00001097          	auipc	ra,0x1
    80003536:	c66080e7          	jalr	-922(ra) # 80004198 <log_write>
      brelse(bp);
    8000353a:	8526                	mv	a0,s1
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	a04080e7          	jalr	-1532(ra) # 80002f40 <brelse>
      return iget(dev, inum);
    80003544:	0009059b          	sext.w	a1,s2
    80003548:	8556                	mv	a0,s5
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	da2080e7          	jalr	-606(ra) # 800032ec <iget>
    80003552:	bf5d                	j	80003508 <ialloc+0x80>

0000000080003554 <iupdate>:
{
    80003554:	1101                	addi	sp,sp,-32
    80003556:	ec06                	sd	ra,24(sp)
    80003558:	e822                	sd	s0,16(sp)
    8000355a:	e426                	sd	s1,8(sp)
    8000355c:	e04a                	sd	s2,0(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003562:	415c                	lw	a5,4(a0)
    80003564:	0047d79b          	srliw	a5,a5,0x4
    80003568:	0001c597          	auipc	a1,0x1c
    8000356c:	b185a583          	lw	a1,-1256(a1) # 8001f080 <sb+0x18>
    80003570:	9dbd                	addw	a1,a1,a5
    80003572:	4108                	lw	a0,0(a0)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	89c080e7          	jalr	-1892(ra) # 80002e10 <bread>
    8000357c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000357e:	05850793          	addi	a5,a0,88
    80003582:	40d8                	lw	a4,4(s1)
    80003584:	8b3d                	andi	a4,a4,15
    80003586:	071a                	slli	a4,a4,0x6
    80003588:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000358a:	04449703          	lh	a4,68(s1)
    8000358e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003592:	04649703          	lh	a4,70(s1)
    80003596:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000359a:	04849703          	lh	a4,72(s1)
    8000359e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035a2:	04a49703          	lh	a4,74(s1)
    800035a6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035aa:	44f8                	lw	a4,76(s1)
    800035ac:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035ae:	03400613          	li	a2,52
    800035b2:	05048593          	addi	a1,s1,80
    800035b6:	00c78513          	addi	a0,a5,12
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	770080e7          	jalr	1904(ra) # 80000d2a <memmove>
  log_write(bp);
    800035c2:	854a                	mv	a0,s2
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	bd4080e7          	jalr	-1068(ra) # 80004198 <log_write>
  brelse(bp);
    800035cc:	854a                	mv	a0,s2
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	972080e7          	jalr	-1678(ra) # 80002f40 <brelse>
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6902                	ld	s2,0(sp)
    800035de:	6105                	addi	sp,sp,32
    800035e0:	8082                	ret

00000000800035e2 <idup>:
{
    800035e2:	1101                	addi	sp,sp,-32
    800035e4:	ec06                	sd	ra,24(sp)
    800035e6:	e822                	sd	s0,16(sp)
    800035e8:	e426                	sd	s1,8(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035ee:	0001c517          	auipc	a0,0x1c
    800035f2:	a9a50513          	addi	a0,a0,-1382 # 8001f088 <itable>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	5dc080e7          	jalr	1500(ra) # 80000bd2 <acquire>
  ip->ref++;
    800035fe:	449c                	lw	a5,8(s1)
    80003600:	2785                	addiw	a5,a5,1
    80003602:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003604:	0001c517          	auipc	a0,0x1c
    80003608:	a8450513          	addi	a0,a0,-1404 # 8001f088 <itable>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	67a080e7          	jalr	1658(ra) # 80000c86 <release>
}
    80003614:	8526                	mv	a0,s1
    80003616:	60e2                	ld	ra,24(sp)
    80003618:	6442                	ld	s0,16(sp)
    8000361a:	64a2                	ld	s1,8(sp)
    8000361c:	6105                	addi	sp,sp,32
    8000361e:	8082                	ret

0000000080003620 <ilock>:
{
    80003620:	1101                	addi	sp,sp,-32
    80003622:	ec06                	sd	ra,24(sp)
    80003624:	e822                	sd	s0,16(sp)
    80003626:	e426                	sd	s1,8(sp)
    80003628:	e04a                	sd	s2,0(sp)
    8000362a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000362c:	c115                	beqz	a0,80003650 <ilock+0x30>
    8000362e:	84aa                	mv	s1,a0
    80003630:	451c                	lw	a5,8(a0)
    80003632:	00f05f63          	blez	a5,80003650 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003636:	0541                	addi	a0,a0,16
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	c7e080e7          	jalr	-898(ra) # 800042b6 <acquiresleep>
  if(ip->valid == 0){
    80003640:	40bc                	lw	a5,64(s1)
    80003642:	cf99                	beqz	a5,80003660 <ilock+0x40>
}
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6902                	ld	s2,0(sp)
    8000364c:	6105                	addi	sp,sp,32
    8000364e:	8082                	ret
    panic("ilock");
    80003650:	00005517          	auipc	a0,0x5
    80003654:	fa850513          	addi	a0,a0,-88 # 800085f8 <syscalls+0x188>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	ee4080e7          	jalr	-284(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003660:	40dc                	lw	a5,4(s1)
    80003662:	0047d79b          	srliw	a5,a5,0x4
    80003666:	0001c597          	auipc	a1,0x1c
    8000366a:	a1a5a583          	lw	a1,-1510(a1) # 8001f080 <sb+0x18>
    8000366e:	9dbd                	addw	a1,a1,a5
    80003670:	4088                	lw	a0,0(s1)
    80003672:	fffff097          	auipc	ra,0xfffff
    80003676:	79e080e7          	jalr	1950(ra) # 80002e10 <bread>
    8000367a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000367c:	05850593          	addi	a1,a0,88
    80003680:	40dc                	lw	a5,4(s1)
    80003682:	8bbd                	andi	a5,a5,15
    80003684:	079a                	slli	a5,a5,0x6
    80003686:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003688:	00059783          	lh	a5,0(a1)
    8000368c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003690:	00259783          	lh	a5,2(a1)
    80003694:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003698:	00459783          	lh	a5,4(a1)
    8000369c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036a0:	00659783          	lh	a5,6(a1)
    800036a4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036a8:	459c                	lw	a5,8(a1)
    800036aa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036ac:	03400613          	li	a2,52
    800036b0:	05b1                	addi	a1,a1,12
    800036b2:	05048513          	addi	a0,s1,80
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	674080e7          	jalr	1652(ra) # 80000d2a <memmove>
    brelse(bp);
    800036be:	854a                	mv	a0,s2
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	880080e7          	jalr	-1920(ra) # 80002f40 <brelse>
    ip->valid = 1;
    800036c8:	4785                	li	a5,1
    800036ca:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036cc:	04449783          	lh	a5,68(s1)
    800036d0:	fbb5                	bnez	a5,80003644 <ilock+0x24>
      panic("ilock: no type");
    800036d2:	00005517          	auipc	a0,0x5
    800036d6:	f2e50513          	addi	a0,a0,-210 # 80008600 <syscalls+0x190>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	e62080e7          	jalr	-414(ra) # 8000053c <panic>

00000000800036e2 <iunlock>:
{
    800036e2:	1101                	addi	sp,sp,-32
    800036e4:	ec06                	sd	ra,24(sp)
    800036e6:	e822                	sd	s0,16(sp)
    800036e8:	e426                	sd	s1,8(sp)
    800036ea:	e04a                	sd	s2,0(sp)
    800036ec:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036ee:	c905                	beqz	a0,8000371e <iunlock+0x3c>
    800036f0:	84aa                	mv	s1,a0
    800036f2:	01050913          	addi	s2,a0,16
    800036f6:	854a                	mv	a0,s2
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	c58080e7          	jalr	-936(ra) # 80004350 <holdingsleep>
    80003700:	cd19                	beqz	a0,8000371e <iunlock+0x3c>
    80003702:	449c                	lw	a5,8(s1)
    80003704:	00f05d63          	blez	a5,8000371e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	c02080e7          	jalr	-1022(ra) # 8000430c <releasesleep>
}
    80003712:	60e2                	ld	ra,24(sp)
    80003714:	6442                	ld	s0,16(sp)
    80003716:	64a2                	ld	s1,8(sp)
    80003718:	6902                	ld	s2,0(sp)
    8000371a:	6105                	addi	sp,sp,32
    8000371c:	8082                	ret
    panic("iunlock");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	ef250513          	addi	a0,a0,-270 # 80008610 <syscalls+0x1a0>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e16080e7          	jalr	-490(ra) # 8000053c <panic>

000000008000372e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000372e:	7179                	addi	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	e052                	sd	s4,0(sp)
    8000373c:	1800                	addi	s0,sp,48
    8000373e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003740:	05050493          	addi	s1,a0,80
    80003744:	08050913          	addi	s2,a0,128
    80003748:	a021                	j	80003750 <itrunc+0x22>
    8000374a:	0491                	addi	s1,s1,4
    8000374c:	01248d63          	beq	s1,s2,80003766 <itrunc+0x38>
    if(ip->addrs[i]){
    80003750:	408c                	lw	a1,0(s1)
    80003752:	dde5                	beqz	a1,8000374a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003754:	0009a503          	lw	a0,0(s3)
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	8fc080e7          	jalr	-1796(ra) # 80003054 <bfree>
      ip->addrs[i] = 0;
    80003760:	0004a023          	sw	zero,0(s1)
    80003764:	b7dd                	j	8000374a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003766:	0809a583          	lw	a1,128(s3)
    8000376a:	e185                	bnez	a1,8000378a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000376c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003770:	854e                	mv	a0,s3
    80003772:	00000097          	auipc	ra,0x0
    80003776:	de2080e7          	jalr	-542(ra) # 80003554 <iupdate>
}
    8000377a:	70a2                	ld	ra,40(sp)
    8000377c:	7402                	ld	s0,32(sp)
    8000377e:	64e2                	ld	s1,24(sp)
    80003780:	6942                	ld	s2,16(sp)
    80003782:	69a2                	ld	s3,8(sp)
    80003784:	6a02                	ld	s4,0(sp)
    80003786:	6145                	addi	sp,sp,48
    80003788:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000378a:	0009a503          	lw	a0,0(s3)
    8000378e:	fffff097          	auipc	ra,0xfffff
    80003792:	682080e7          	jalr	1666(ra) # 80002e10 <bread>
    80003796:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003798:	05850493          	addi	s1,a0,88
    8000379c:	45850913          	addi	s2,a0,1112
    800037a0:	a021                	j	800037a8 <itrunc+0x7a>
    800037a2:	0491                	addi	s1,s1,4
    800037a4:	01248b63          	beq	s1,s2,800037ba <itrunc+0x8c>
      if(a[j])
    800037a8:	408c                	lw	a1,0(s1)
    800037aa:	dde5                	beqz	a1,800037a2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037ac:	0009a503          	lw	a0,0(s3)
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	8a4080e7          	jalr	-1884(ra) # 80003054 <bfree>
    800037b8:	b7ed                	j	800037a2 <itrunc+0x74>
    brelse(bp);
    800037ba:	8552                	mv	a0,s4
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	784080e7          	jalr	1924(ra) # 80002f40 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037c4:	0809a583          	lw	a1,128(s3)
    800037c8:	0009a503          	lw	a0,0(s3)
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	888080e7          	jalr	-1912(ra) # 80003054 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037d4:	0809a023          	sw	zero,128(s3)
    800037d8:	bf51                	j	8000376c <itrunc+0x3e>

00000000800037da <iput>:
{
    800037da:	1101                	addi	sp,sp,-32
    800037dc:	ec06                	sd	ra,24(sp)
    800037de:	e822                	sd	s0,16(sp)
    800037e0:	e426                	sd	s1,8(sp)
    800037e2:	e04a                	sd	s2,0(sp)
    800037e4:	1000                	addi	s0,sp,32
    800037e6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037e8:	0001c517          	auipc	a0,0x1c
    800037ec:	8a050513          	addi	a0,a0,-1888 # 8001f088 <itable>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	3e2080e7          	jalr	994(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037f8:	4498                	lw	a4,8(s1)
    800037fa:	4785                	li	a5,1
    800037fc:	02f70363          	beq	a4,a5,80003822 <iput+0x48>
  ip->ref--;
    80003800:	449c                	lw	a5,8(s1)
    80003802:	37fd                	addiw	a5,a5,-1
    80003804:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003806:	0001c517          	auipc	a0,0x1c
    8000380a:	88250513          	addi	a0,a0,-1918 # 8001f088 <itable>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	478080e7          	jalr	1144(ra) # 80000c86 <release>
}
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	64a2                	ld	s1,8(sp)
    8000381c:	6902                	ld	s2,0(sp)
    8000381e:	6105                	addi	sp,sp,32
    80003820:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003822:	40bc                	lw	a5,64(s1)
    80003824:	dff1                	beqz	a5,80003800 <iput+0x26>
    80003826:	04a49783          	lh	a5,74(s1)
    8000382a:	fbf9                	bnez	a5,80003800 <iput+0x26>
    acquiresleep(&ip->lock);
    8000382c:	01048913          	addi	s2,s1,16
    80003830:	854a                	mv	a0,s2
    80003832:	00001097          	auipc	ra,0x1
    80003836:	a84080e7          	jalr	-1404(ra) # 800042b6 <acquiresleep>
    release(&itable.lock);
    8000383a:	0001c517          	auipc	a0,0x1c
    8000383e:	84e50513          	addi	a0,a0,-1970 # 8001f088 <itable>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	444080e7          	jalr	1092(ra) # 80000c86 <release>
    itrunc(ip);
    8000384a:	8526                	mv	a0,s1
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	ee2080e7          	jalr	-286(ra) # 8000372e <itrunc>
    ip->type = 0;
    80003854:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003858:	8526                	mv	a0,s1
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	cfa080e7          	jalr	-774(ra) # 80003554 <iupdate>
    ip->valid = 0;
    80003862:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003866:	854a                	mv	a0,s2
    80003868:	00001097          	auipc	ra,0x1
    8000386c:	aa4080e7          	jalr	-1372(ra) # 8000430c <releasesleep>
    acquire(&itable.lock);
    80003870:	0001c517          	auipc	a0,0x1c
    80003874:	81850513          	addi	a0,a0,-2024 # 8001f088 <itable>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	35a080e7          	jalr	858(ra) # 80000bd2 <acquire>
    80003880:	b741                	j	80003800 <iput+0x26>

0000000080003882 <iunlockput>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	1000                	addi	s0,sp,32
    8000388c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	e54080e7          	jalr	-428(ra) # 800036e2 <iunlock>
  iput(ip);
    80003896:	8526                	mv	a0,s1
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	f42080e7          	jalr	-190(ra) # 800037da <iput>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6105                	addi	sp,sp,32
    800038a8:	8082                	ret

00000000800038aa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038aa:	1141                	addi	sp,sp,-16
    800038ac:	e422                	sd	s0,8(sp)
    800038ae:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038b0:	411c                	lw	a5,0(a0)
    800038b2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038b4:	415c                	lw	a5,4(a0)
    800038b6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038b8:	04451783          	lh	a5,68(a0)
    800038bc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038c0:	04a51783          	lh	a5,74(a0)
    800038c4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038c8:	04c56783          	lwu	a5,76(a0)
    800038cc:	e99c                	sd	a5,16(a1)
}
    800038ce:	6422                	ld	s0,8(sp)
    800038d0:	0141                	addi	sp,sp,16
    800038d2:	8082                	ret

00000000800038d4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038d4:	457c                	lw	a5,76(a0)
    800038d6:	0ed7e963          	bltu	a5,a3,800039c8 <readi+0xf4>
{
    800038da:	7159                	addi	sp,sp,-112
    800038dc:	f486                	sd	ra,104(sp)
    800038de:	f0a2                	sd	s0,96(sp)
    800038e0:	eca6                	sd	s1,88(sp)
    800038e2:	e8ca                	sd	s2,80(sp)
    800038e4:	e4ce                	sd	s3,72(sp)
    800038e6:	e0d2                	sd	s4,64(sp)
    800038e8:	fc56                	sd	s5,56(sp)
    800038ea:	f85a                	sd	s6,48(sp)
    800038ec:	f45e                	sd	s7,40(sp)
    800038ee:	f062                	sd	s8,32(sp)
    800038f0:	ec66                	sd	s9,24(sp)
    800038f2:	e86a                	sd	s10,16(sp)
    800038f4:	e46e                	sd	s11,8(sp)
    800038f6:	1880                	addi	s0,sp,112
    800038f8:	8b2a                	mv	s6,a0
    800038fa:	8bae                	mv	s7,a1
    800038fc:	8a32                	mv	s4,a2
    800038fe:	84b6                	mv	s1,a3
    80003900:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003902:	9f35                	addw	a4,a4,a3
    return 0;
    80003904:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003906:	0ad76063          	bltu	a4,a3,800039a6 <readi+0xd2>
  if(off + n > ip->size)
    8000390a:	00e7f463          	bgeu	a5,a4,80003912 <readi+0x3e>
    n = ip->size - off;
    8000390e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003912:	0a0a8963          	beqz	s5,800039c4 <readi+0xf0>
    80003916:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003918:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000391c:	5c7d                	li	s8,-1
    8000391e:	a82d                	j	80003958 <readi+0x84>
    80003920:	020d1d93          	slli	s11,s10,0x20
    80003924:	020ddd93          	srli	s11,s11,0x20
    80003928:	05890613          	addi	a2,s2,88
    8000392c:	86ee                	mv	a3,s11
    8000392e:	963a                	add	a2,a2,a4
    80003930:	85d2                	mv	a1,s4
    80003932:	855e                	mv	a0,s7
    80003934:	fffff097          	auipc	ra,0xfffff
    80003938:	b12080e7          	jalr	-1262(ra) # 80002446 <either_copyout>
    8000393c:	05850d63          	beq	a0,s8,80003996 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003940:	854a                	mv	a0,s2
    80003942:	fffff097          	auipc	ra,0xfffff
    80003946:	5fe080e7          	jalr	1534(ra) # 80002f40 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000394a:	013d09bb          	addw	s3,s10,s3
    8000394e:	009d04bb          	addw	s1,s10,s1
    80003952:	9a6e                	add	s4,s4,s11
    80003954:	0559f763          	bgeu	s3,s5,800039a2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003958:	00a4d59b          	srliw	a1,s1,0xa
    8000395c:	855a                	mv	a0,s6
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	8a4080e7          	jalr	-1884(ra) # 80003202 <bmap>
    80003966:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000396a:	cd85                	beqz	a1,800039a2 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000396c:	000b2503          	lw	a0,0(s6)
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	4a0080e7          	jalr	1184(ra) # 80002e10 <bread>
    80003978:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000397a:	3ff4f713          	andi	a4,s1,1023
    8000397e:	40ec87bb          	subw	a5,s9,a4
    80003982:	413a86bb          	subw	a3,s5,s3
    80003986:	8d3e                	mv	s10,a5
    80003988:	2781                	sext.w	a5,a5
    8000398a:	0006861b          	sext.w	a2,a3
    8000398e:	f8f679e3          	bgeu	a2,a5,80003920 <readi+0x4c>
    80003992:	8d36                	mv	s10,a3
    80003994:	b771                	j	80003920 <readi+0x4c>
      brelse(bp);
    80003996:	854a                	mv	a0,s2
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	5a8080e7          	jalr	1448(ra) # 80002f40 <brelse>
      tot = -1;
    800039a0:	59fd                	li	s3,-1
  }
  return tot;
    800039a2:	0009851b          	sext.w	a0,s3
}
    800039a6:	70a6                	ld	ra,104(sp)
    800039a8:	7406                	ld	s0,96(sp)
    800039aa:	64e6                	ld	s1,88(sp)
    800039ac:	6946                	ld	s2,80(sp)
    800039ae:	69a6                	ld	s3,72(sp)
    800039b0:	6a06                	ld	s4,64(sp)
    800039b2:	7ae2                	ld	s5,56(sp)
    800039b4:	7b42                	ld	s6,48(sp)
    800039b6:	7ba2                	ld	s7,40(sp)
    800039b8:	7c02                	ld	s8,32(sp)
    800039ba:	6ce2                	ld	s9,24(sp)
    800039bc:	6d42                	ld	s10,16(sp)
    800039be:	6da2                	ld	s11,8(sp)
    800039c0:	6165                	addi	sp,sp,112
    800039c2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039c4:	89d6                	mv	s3,s5
    800039c6:	bff1                	j	800039a2 <readi+0xce>
    return 0;
    800039c8:	4501                	li	a0,0
}
    800039ca:	8082                	ret

00000000800039cc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039cc:	457c                	lw	a5,76(a0)
    800039ce:	10d7e863          	bltu	a5,a3,80003ade <writei+0x112>
{
    800039d2:	7159                	addi	sp,sp,-112
    800039d4:	f486                	sd	ra,104(sp)
    800039d6:	f0a2                	sd	s0,96(sp)
    800039d8:	eca6                	sd	s1,88(sp)
    800039da:	e8ca                	sd	s2,80(sp)
    800039dc:	e4ce                	sd	s3,72(sp)
    800039de:	e0d2                	sd	s4,64(sp)
    800039e0:	fc56                	sd	s5,56(sp)
    800039e2:	f85a                	sd	s6,48(sp)
    800039e4:	f45e                	sd	s7,40(sp)
    800039e6:	f062                	sd	s8,32(sp)
    800039e8:	ec66                	sd	s9,24(sp)
    800039ea:	e86a                	sd	s10,16(sp)
    800039ec:	e46e                	sd	s11,8(sp)
    800039ee:	1880                	addi	s0,sp,112
    800039f0:	8aaa                	mv	s5,a0
    800039f2:	8bae                	mv	s7,a1
    800039f4:	8a32                	mv	s4,a2
    800039f6:	8936                	mv	s2,a3
    800039f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039fa:	00e687bb          	addw	a5,a3,a4
    800039fe:	0ed7e263          	bltu	a5,a3,80003ae2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a02:	00043737          	lui	a4,0x43
    80003a06:	0ef76063          	bltu	a4,a5,80003ae6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a0a:	0c0b0863          	beqz	s6,80003ada <writei+0x10e>
    80003a0e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a10:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a14:	5c7d                	li	s8,-1
    80003a16:	a091                	j	80003a5a <writei+0x8e>
    80003a18:	020d1d93          	slli	s11,s10,0x20
    80003a1c:	020ddd93          	srli	s11,s11,0x20
    80003a20:	05848513          	addi	a0,s1,88
    80003a24:	86ee                	mv	a3,s11
    80003a26:	8652                	mv	a2,s4
    80003a28:	85de                	mv	a1,s7
    80003a2a:	953a                	add	a0,a0,a4
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	a70080e7          	jalr	-1424(ra) # 8000249c <either_copyin>
    80003a34:	07850263          	beq	a0,s8,80003a98 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a38:	8526                	mv	a0,s1
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	75e080e7          	jalr	1886(ra) # 80004198 <log_write>
    brelse(bp);
    80003a42:	8526                	mv	a0,s1
    80003a44:	fffff097          	auipc	ra,0xfffff
    80003a48:	4fc080e7          	jalr	1276(ra) # 80002f40 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a4c:	013d09bb          	addw	s3,s10,s3
    80003a50:	012d093b          	addw	s2,s10,s2
    80003a54:	9a6e                	add	s4,s4,s11
    80003a56:	0569f663          	bgeu	s3,s6,80003aa2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003a5a:	00a9559b          	srliw	a1,s2,0xa
    80003a5e:	8556                	mv	a0,s5
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	7a2080e7          	jalr	1954(ra) # 80003202 <bmap>
    80003a68:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a6c:	c99d                	beqz	a1,80003aa2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a6e:	000aa503          	lw	a0,0(s5)
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	39e080e7          	jalr	926(ra) # 80002e10 <bread>
    80003a7a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7c:	3ff97713          	andi	a4,s2,1023
    80003a80:	40ec87bb          	subw	a5,s9,a4
    80003a84:	413b06bb          	subw	a3,s6,s3
    80003a88:	8d3e                	mv	s10,a5
    80003a8a:	2781                	sext.w	a5,a5
    80003a8c:	0006861b          	sext.w	a2,a3
    80003a90:	f8f674e3          	bgeu	a2,a5,80003a18 <writei+0x4c>
    80003a94:	8d36                	mv	s10,a3
    80003a96:	b749                	j	80003a18 <writei+0x4c>
      brelse(bp);
    80003a98:	8526                	mv	a0,s1
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	4a6080e7          	jalr	1190(ra) # 80002f40 <brelse>
  }

  if(off > ip->size)
    80003aa2:	04caa783          	lw	a5,76(s5)
    80003aa6:	0127f463          	bgeu	a5,s2,80003aae <writei+0xe2>
    ip->size = off;
    80003aaa:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003aae:	8556                	mv	a0,s5
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	aa4080e7          	jalr	-1372(ra) # 80003554 <iupdate>

  return tot;
    80003ab8:	0009851b          	sext.w	a0,s3
}
    80003abc:	70a6                	ld	ra,104(sp)
    80003abe:	7406                	ld	s0,96(sp)
    80003ac0:	64e6                	ld	s1,88(sp)
    80003ac2:	6946                	ld	s2,80(sp)
    80003ac4:	69a6                	ld	s3,72(sp)
    80003ac6:	6a06                	ld	s4,64(sp)
    80003ac8:	7ae2                	ld	s5,56(sp)
    80003aca:	7b42                	ld	s6,48(sp)
    80003acc:	7ba2                	ld	s7,40(sp)
    80003ace:	7c02                	ld	s8,32(sp)
    80003ad0:	6ce2                	ld	s9,24(sp)
    80003ad2:	6d42                	ld	s10,16(sp)
    80003ad4:	6da2                	ld	s11,8(sp)
    80003ad6:	6165                	addi	sp,sp,112
    80003ad8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ada:	89da                	mv	s3,s6
    80003adc:	bfc9                	j	80003aae <writei+0xe2>
    return -1;
    80003ade:	557d                	li	a0,-1
}
    80003ae0:	8082                	ret
    return -1;
    80003ae2:	557d                	li	a0,-1
    80003ae4:	bfe1                	j	80003abc <writei+0xf0>
    return -1;
    80003ae6:	557d                	li	a0,-1
    80003ae8:	bfd1                	j	80003abc <writei+0xf0>

0000000080003aea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003aea:	1141                	addi	sp,sp,-16
    80003aec:	e406                	sd	ra,8(sp)
    80003aee:	e022                	sd	s0,0(sp)
    80003af0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003af2:	4639                	li	a2,14
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	2aa080e7          	jalr	682(ra) # 80000d9e <strncmp>
}
    80003afc:	60a2                	ld	ra,8(sp)
    80003afe:	6402                	ld	s0,0(sp)
    80003b00:	0141                	addi	sp,sp,16
    80003b02:	8082                	ret

0000000080003b04 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b04:	7139                	addi	sp,sp,-64
    80003b06:	fc06                	sd	ra,56(sp)
    80003b08:	f822                	sd	s0,48(sp)
    80003b0a:	f426                	sd	s1,40(sp)
    80003b0c:	f04a                	sd	s2,32(sp)
    80003b0e:	ec4e                	sd	s3,24(sp)
    80003b10:	e852                	sd	s4,16(sp)
    80003b12:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b14:	04451703          	lh	a4,68(a0)
    80003b18:	4785                	li	a5,1
    80003b1a:	00f71a63          	bne	a4,a5,80003b2e <dirlookup+0x2a>
    80003b1e:	892a                	mv	s2,a0
    80003b20:	89ae                	mv	s3,a1
    80003b22:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b24:	457c                	lw	a5,76(a0)
    80003b26:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b28:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b2a:	e79d                	bnez	a5,80003b58 <dirlookup+0x54>
    80003b2c:	a8a5                	j	80003ba4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b2e:	00005517          	auipc	a0,0x5
    80003b32:	aea50513          	addi	a0,a0,-1302 # 80008618 <syscalls+0x1a8>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	a06080e7          	jalr	-1530(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003b3e:	00005517          	auipc	a0,0x5
    80003b42:	af250513          	addi	a0,a0,-1294 # 80008630 <syscalls+0x1c0>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	9f6080e7          	jalr	-1546(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b4e:	24c1                	addiw	s1,s1,16
    80003b50:	04c92783          	lw	a5,76(s2)
    80003b54:	04f4f763          	bgeu	s1,a5,80003ba2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b58:	4741                	li	a4,16
    80003b5a:	86a6                	mv	a3,s1
    80003b5c:	fc040613          	addi	a2,s0,-64
    80003b60:	4581                	li	a1,0
    80003b62:	854a                	mv	a0,s2
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	d70080e7          	jalr	-656(ra) # 800038d4 <readi>
    80003b6c:	47c1                	li	a5,16
    80003b6e:	fcf518e3          	bne	a0,a5,80003b3e <dirlookup+0x3a>
    if(de.inum == 0)
    80003b72:	fc045783          	lhu	a5,-64(s0)
    80003b76:	dfe1                	beqz	a5,80003b4e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b78:	fc240593          	addi	a1,s0,-62
    80003b7c:	854e                	mv	a0,s3
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	f6c080e7          	jalr	-148(ra) # 80003aea <namecmp>
    80003b86:	f561                	bnez	a0,80003b4e <dirlookup+0x4a>
      if(poff)
    80003b88:	000a0463          	beqz	s4,80003b90 <dirlookup+0x8c>
        *poff = off;
    80003b8c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b90:	fc045583          	lhu	a1,-64(s0)
    80003b94:	00092503          	lw	a0,0(s2)
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	754080e7          	jalr	1876(ra) # 800032ec <iget>
    80003ba0:	a011                	j	80003ba4 <dirlookup+0xa0>
  return 0;
    80003ba2:	4501                	li	a0,0
}
    80003ba4:	70e2                	ld	ra,56(sp)
    80003ba6:	7442                	ld	s0,48(sp)
    80003ba8:	74a2                	ld	s1,40(sp)
    80003baa:	7902                	ld	s2,32(sp)
    80003bac:	69e2                	ld	s3,24(sp)
    80003bae:	6a42                	ld	s4,16(sp)
    80003bb0:	6121                	addi	sp,sp,64
    80003bb2:	8082                	ret

0000000080003bb4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bb4:	711d                	addi	sp,sp,-96
    80003bb6:	ec86                	sd	ra,88(sp)
    80003bb8:	e8a2                	sd	s0,80(sp)
    80003bba:	e4a6                	sd	s1,72(sp)
    80003bbc:	e0ca                	sd	s2,64(sp)
    80003bbe:	fc4e                	sd	s3,56(sp)
    80003bc0:	f852                	sd	s4,48(sp)
    80003bc2:	f456                	sd	s5,40(sp)
    80003bc4:	f05a                	sd	s6,32(sp)
    80003bc6:	ec5e                	sd	s7,24(sp)
    80003bc8:	e862                	sd	s8,16(sp)
    80003bca:	e466                	sd	s9,8(sp)
    80003bcc:	1080                	addi	s0,sp,96
    80003bce:	84aa                	mv	s1,a0
    80003bd0:	8b2e                	mv	s6,a1
    80003bd2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bd4:	00054703          	lbu	a4,0(a0)
    80003bd8:	02f00793          	li	a5,47
    80003bdc:	02f70263          	beq	a4,a5,80003c00 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003be0:	ffffe097          	auipc	ra,0xffffe
    80003be4:	db6080e7          	jalr	-586(ra) # 80001996 <myproc>
    80003be8:	15053503          	ld	a0,336(a0)
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	9f6080e7          	jalr	-1546(ra) # 800035e2 <idup>
    80003bf4:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003bf6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003bfa:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bfc:	4b85                	li	s7,1
    80003bfe:	a875                	j	80003cba <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003c00:	4585                	li	a1,1
    80003c02:	4505                	li	a0,1
    80003c04:	fffff097          	auipc	ra,0xfffff
    80003c08:	6e8080e7          	jalr	1768(ra) # 800032ec <iget>
    80003c0c:	8a2a                	mv	s4,a0
    80003c0e:	b7e5                	j	80003bf6 <namex+0x42>
      iunlockput(ip);
    80003c10:	8552                	mv	a0,s4
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	c70080e7          	jalr	-912(ra) # 80003882 <iunlockput>
      return 0;
    80003c1a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c1c:	8552                	mv	a0,s4
    80003c1e:	60e6                	ld	ra,88(sp)
    80003c20:	6446                	ld	s0,80(sp)
    80003c22:	64a6                	ld	s1,72(sp)
    80003c24:	6906                	ld	s2,64(sp)
    80003c26:	79e2                	ld	s3,56(sp)
    80003c28:	7a42                	ld	s4,48(sp)
    80003c2a:	7aa2                	ld	s5,40(sp)
    80003c2c:	7b02                	ld	s6,32(sp)
    80003c2e:	6be2                	ld	s7,24(sp)
    80003c30:	6c42                	ld	s8,16(sp)
    80003c32:	6ca2                	ld	s9,8(sp)
    80003c34:	6125                	addi	sp,sp,96
    80003c36:	8082                	ret
      iunlock(ip);
    80003c38:	8552                	mv	a0,s4
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	aa8080e7          	jalr	-1368(ra) # 800036e2 <iunlock>
      return ip;
    80003c42:	bfe9                	j	80003c1c <namex+0x68>
      iunlockput(ip);
    80003c44:	8552                	mv	a0,s4
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	c3c080e7          	jalr	-964(ra) # 80003882 <iunlockput>
      return 0;
    80003c4e:	8a4e                	mv	s4,s3
    80003c50:	b7f1                	j	80003c1c <namex+0x68>
  len = path - s;
    80003c52:	40998633          	sub	a2,s3,s1
    80003c56:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c5a:	099c5863          	bge	s8,s9,80003cea <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003c5e:	4639                	li	a2,14
    80003c60:	85a6                	mv	a1,s1
    80003c62:	8556                	mv	a0,s5
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	0c6080e7          	jalr	198(ra) # 80000d2a <memmove>
    80003c6c:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c6e:	0004c783          	lbu	a5,0(s1)
    80003c72:	01279763          	bne	a5,s2,80003c80 <namex+0xcc>
    path++;
    80003c76:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c78:	0004c783          	lbu	a5,0(s1)
    80003c7c:	ff278de3          	beq	a5,s2,80003c76 <namex+0xc2>
    ilock(ip);
    80003c80:	8552                	mv	a0,s4
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	99e080e7          	jalr	-1634(ra) # 80003620 <ilock>
    if(ip->type != T_DIR){
    80003c8a:	044a1783          	lh	a5,68(s4)
    80003c8e:	f97791e3          	bne	a5,s7,80003c10 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003c92:	000b0563          	beqz	s6,80003c9c <namex+0xe8>
    80003c96:	0004c783          	lbu	a5,0(s1)
    80003c9a:	dfd9                	beqz	a5,80003c38 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c9c:	4601                	li	a2,0
    80003c9e:	85d6                	mv	a1,s5
    80003ca0:	8552                	mv	a0,s4
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	e62080e7          	jalr	-414(ra) # 80003b04 <dirlookup>
    80003caa:	89aa                	mv	s3,a0
    80003cac:	dd41                	beqz	a0,80003c44 <namex+0x90>
    iunlockput(ip);
    80003cae:	8552                	mv	a0,s4
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	bd2080e7          	jalr	-1070(ra) # 80003882 <iunlockput>
    ip = next;
    80003cb8:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cba:	0004c783          	lbu	a5,0(s1)
    80003cbe:	01279763          	bne	a5,s2,80003ccc <namex+0x118>
    path++;
    80003cc2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cc4:	0004c783          	lbu	a5,0(s1)
    80003cc8:	ff278de3          	beq	a5,s2,80003cc2 <namex+0x10e>
  if(*path == 0)
    80003ccc:	cb9d                	beqz	a5,80003d02 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003cce:	0004c783          	lbu	a5,0(s1)
    80003cd2:	89a6                	mv	s3,s1
  len = path - s;
    80003cd4:	4c81                	li	s9,0
    80003cd6:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003cd8:	01278963          	beq	a5,s2,80003cea <namex+0x136>
    80003cdc:	dbbd                	beqz	a5,80003c52 <namex+0x9e>
    path++;
    80003cde:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ce0:	0009c783          	lbu	a5,0(s3)
    80003ce4:	ff279ce3          	bne	a5,s2,80003cdc <namex+0x128>
    80003ce8:	b7ad                	j	80003c52 <namex+0x9e>
    memmove(name, s, len);
    80003cea:	2601                	sext.w	a2,a2
    80003cec:	85a6                	mv	a1,s1
    80003cee:	8556                	mv	a0,s5
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	03a080e7          	jalr	58(ra) # 80000d2a <memmove>
    name[len] = 0;
    80003cf8:	9cd6                	add	s9,s9,s5
    80003cfa:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cfe:	84ce                	mv	s1,s3
    80003d00:	b7bd                	j	80003c6e <namex+0xba>
  if(nameiparent){
    80003d02:	f00b0de3          	beqz	s6,80003c1c <namex+0x68>
    iput(ip);
    80003d06:	8552                	mv	a0,s4
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	ad2080e7          	jalr	-1326(ra) # 800037da <iput>
    return 0;
    80003d10:	4a01                	li	s4,0
    80003d12:	b729                	j	80003c1c <namex+0x68>

0000000080003d14 <dirlink>:
{
    80003d14:	7139                	addi	sp,sp,-64
    80003d16:	fc06                	sd	ra,56(sp)
    80003d18:	f822                	sd	s0,48(sp)
    80003d1a:	f426                	sd	s1,40(sp)
    80003d1c:	f04a                	sd	s2,32(sp)
    80003d1e:	ec4e                	sd	s3,24(sp)
    80003d20:	e852                	sd	s4,16(sp)
    80003d22:	0080                	addi	s0,sp,64
    80003d24:	892a                	mv	s2,a0
    80003d26:	8a2e                	mv	s4,a1
    80003d28:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d2a:	4601                	li	a2,0
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	dd8080e7          	jalr	-552(ra) # 80003b04 <dirlookup>
    80003d34:	e93d                	bnez	a0,80003daa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d36:	04c92483          	lw	s1,76(s2)
    80003d3a:	c49d                	beqz	s1,80003d68 <dirlink+0x54>
    80003d3c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d3e:	4741                	li	a4,16
    80003d40:	86a6                	mv	a3,s1
    80003d42:	fc040613          	addi	a2,s0,-64
    80003d46:	4581                	li	a1,0
    80003d48:	854a                	mv	a0,s2
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	b8a080e7          	jalr	-1142(ra) # 800038d4 <readi>
    80003d52:	47c1                	li	a5,16
    80003d54:	06f51163          	bne	a0,a5,80003db6 <dirlink+0xa2>
    if(de.inum == 0)
    80003d58:	fc045783          	lhu	a5,-64(s0)
    80003d5c:	c791                	beqz	a5,80003d68 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	24c1                	addiw	s1,s1,16
    80003d60:	04c92783          	lw	a5,76(s2)
    80003d64:	fcf4ede3          	bltu	s1,a5,80003d3e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d68:	4639                	li	a2,14
    80003d6a:	85d2                	mv	a1,s4
    80003d6c:	fc240513          	addi	a0,s0,-62
    80003d70:	ffffd097          	auipc	ra,0xffffd
    80003d74:	06a080e7          	jalr	106(ra) # 80000dda <strncpy>
  de.inum = inum;
    80003d78:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d7c:	4741                	li	a4,16
    80003d7e:	86a6                	mv	a3,s1
    80003d80:	fc040613          	addi	a2,s0,-64
    80003d84:	4581                	li	a1,0
    80003d86:	854a                	mv	a0,s2
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	c44080e7          	jalr	-956(ra) # 800039cc <writei>
    80003d90:	1541                	addi	a0,a0,-16
    80003d92:	00a03533          	snez	a0,a0
    80003d96:	40a00533          	neg	a0,a0
}
    80003d9a:	70e2                	ld	ra,56(sp)
    80003d9c:	7442                	ld	s0,48(sp)
    80003d9e:	74a2                	ld	s1,40(sp)
    80003da0:	7902                	ld	s2,32(sp)
    80003da2:	69e2                	ld	s3,24(sp)
    80003da4:	6a42                	ld	s4,16(sp)
    80003da6:	6121                	addi	sp,sp,64
    80003da8:	8082                	ret
    iput(ip);
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	a30080e7          	jalr	-1488(ra) # 800037da <iput>
    return -1;
    80003db2:	557d                	li	a0,-1
    80003db4:	b7dd                	j	80003d9a <dirlink+0x86>
      panic("dirlink read");
    80003db6:	00005517          	auipc	a0,0x5
    80003dba:	88a50513          	addi	a0,a0,-1910 # 80008640 <syscalls+0x1d0>
    80003dbe:	ffffc097          	auipc	ra,0xffffc
    80003dc2:	77e080e7          	jalr	1918(ra) # 8000053c <panic>

0000000080003dc6 <namei>:

struct inode*
namei(char *path)
{
    80003dc6:	1101                	addi	sp,sp,-32
    80003dc8:	ec06                	sd	ra,24(sp)
    80003dca:	e822                	sd	s0,16(sp)
    80003dcc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dce:	fe040613          	addi	a2,s0,-32
    80003dd2:	4581                	li	a1,0
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	de0080e7          	jalr	-544(ra) # 80003bb4 <namex>
}
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	6105                	addi	sp,sp,32
    80003de2:	8082                	ret

0000000080003de4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003de4:	1141                	addi	sp,sp,-16
    80003de6:	e406                	sd	ra,8(sp)
    80003de8:	e022                	sd	s0,0(sp)
    80003dea:	0800                	addi	s0,sp,16
    80003dec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dee:	4585                	li	a1,1
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	dc4080e7          	jalr	-572(ra) # 80003bb4 <namex>
}
    80003df8:	60a2                	ld	ra,8(sp)
    80003dfa:	6402                	ld	s0,0(sp)
    80003dfc:	0141                	addi	sp,sp,16
    80003dfe:	8082                	ret

0000000080003e00 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e00:	1101                	addi	sp,sp,-32
    80003e02:	ec06                	sd	ra,24(sp)
    80003e04:	e822                	sd	s0,16(sp)
    80003e06:	e426                	sd	s1,8(sp)
    80003e08:	e04a                	sd	s2,0(sp)
    80003e0a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e0c:	0001d917          	auipc	s2,0x1d
    80003e10:	d2490913          	addi	s2,s2,-732 # 80020b30 <log>
    80003e14:	01892583          	lw	a1,24(s2)
    80003e18:	02892503          	lw	a0,40(s2)
    80003e1c:	fffff097          	auipc	ra,0xfffff
    80003e20:	ff4080e7          	jalr	-12(ra) # 80002e10 <bread>
    80003e24:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e26:	02c92603          	lw	a2,44(s2)
    80003e2a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e2c:	00c05f63          	blez	a2,80003e4a <write_head+0x4a>
    80003e30:	0001d717          	auipc	a4,0x1d
    80003e34:	d3070713          	addi	a4,a4,-720 # 80020b60 <log+0x30>
    80003e38:	87aa                	mv	a5,a0
    80003e3a:	060a                	slli	a2,a2,0x2
    80003e3c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003e3e:	4314                	lw	a3,0(a4)
    80003e40:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003e42:	0711                	addi	a4,a4,4
    80003e44:	0791                	addi	a5,a5,4
    80003e46:	fec79ce3          	bne	a5,a2,80003e3e <write_head+0x3e>
  }
  bwrite(buf);
    80003e4a:	8526                	mv	a0,s1
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	0b6080e7          	jalr	182(ra) # 80002f02 <bwrite>
  brelse(buf);
    80003e54:	8526                	mv	a0,s1
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	0ea080e7          	jalr	234(ra) # 80002f40 <brelse>
}
    80003e5e:	60e2                	ld	ra,24(sp)
    80003e60:	6442                	ld	s0,16(sp)
    80003e62:	64a2                	ld	s1,8(sp)
    80003e64:	6902                	ld	s2,0(sp)
    80003e66:	6105                	addi	sp,sp,32
    80003e68:	8082                	ret

0000000080003e6a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e6a:	0001d797          	auipc	a5,0x1d
    80003e6e:	cf27a783          	lw	a5,-782(a5) # 80020b5c <log+0x2c>
    80003e72:	0af05d63          	blez	a5,80003f2c <install_trans+0xc2>
{
    80003e76:	7139                	addi	sp,sp,-64
    80003e78:	fc06                	sd	ra,56(sp)
    80003e7a:	f822                	sd	s0,48(sp)
    80003e7c:	f426                	sd	s1,40(sp)
    80003e7e:	f04a                	sd	s2,32(sp)
    80003e80:	ec4e                	sd	s3,24(sp)
    80003e82:	e852                	sd	s4,16(sp)
    80003e84:	e456                	sd	s5,8(sp)
    80003e86:	e05a                	sd	s6,0(sp)
    80003e88:	0080                	addi	s0,sp,64
    80003e8a:	8b2a                	mv	s6,a0
    80003e8c:	0001da97          	auipc	s5,0x1d
    80003e90:	cd4a8a93          	addi	s5,s5,-812 # 80020b60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e94:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e96:	0001d997          	auipc	s3,0x1d
    80003e9a:	c9a98993          	addi	s3,s3,-870 # 80020b30 <log>
    80003e9e:	a00d                	j	80003ec0 <install_trans+0x56>
    brelse(lbuf);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	09e080e7          	jalr	158(ra) # 80002f40 <brelse>
    brelse(dbuf);
    80003eaa:	8526                	mv	a0,s1
    80003eac:	fffff097          	auipc	ra,0xfffff
    80003eb0:	094080e7          	jalr	148(ra) # 80002f40 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb4:	2a05                	addiw	s4,s4,1
    80003eb6:	0a91                	addi	s5,s5,4
    80003eb8:	02c9a783          	lw	a5,44(s3)
    80003ebc:	04fa5e63          	bge	s4,a5,80003f18 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ec0:	0189a583          	lw	a1,24(s3)
    80003ec4:	014585bb          	addw	a1,a1,s4
    80003ec8:	2585                	addiw	a1,a1,1
    80003eca:	0289a503          	lw	a0,40(s3)
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	f42080e7          	jalr	-190(ra) # 80002e10 <bread>
    80003ed6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ed8:	000aa583          	lw	a1,0(s5)
    80003edc:	0289a503          	lw	a0,40(s3)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	f30080e7          	jalr	-208(ra) # 80002e10 <bread>
    80003ee8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003eea:	40000613          	li	a2,1024
    80003eee:	05890593          	addi	a1,s2,88
    80003ef2:	05850513          	addi	a0,a0,88
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	e34080e7          	jalr	-460(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80003efe:	8526                	mv	a0,s1
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	002080e7          	jalr	2(ra) # 80002f02 <bwrite>
    if(recovering == 0)
    80003f08:	f80b1ce3          	bnez	s6,80003ea0 <install_trans+0x36>
      bunpin(dbuf);
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	10a080e7          	jalr	266(ra) # 80003018 <bunpin>
    80003f16:	b769                	j	80003ea0 <install_trans+0x36>
}
    80003f18:	70e2                	ld	ra,56(sp)
    80003f1a:	7442                	ld	s0,48(sp)
    80003f1c:	74a2                	ld	s1,40(sp)
    80003f1e:	7902                	ld	s2,32(sp)
    80003f20:	69e2                	ld	s3,24(sp)
    80003f22:	6a42                	ld	s4,16(sp)
    80003f24:	6aa2                	ld	s5,8(sp)
    80003f26:	6b02                	ld	s6,0(sp)
    80003f28:	6121                	addi	sp,sp,64
    80003f2a:	8082                	ret
    80003f2c:	8082                	ret

0000000080003f2e <initlog>:
{
    80003f2e:	7179                	addi	sp,sp,-48
    80003f30:	f406                	sd	ra,40(sp)
    80003f32:	f022                	sd	s0,32(sp)
    80003f34:	ec26                	sd	s1,24(sp)
    80003f36:	e84a                	sd	s2,16(sp)
    80003f38:	e44e                	sd	s3,8(sp)
    80003f3a:	1800                	addi	s0,sp,48
    80003f3c:	892a                	mv	s2,a0
    80003f3e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f40:	0001d497          	auipc	s1,0x1d
    80003f44:	bf048493          	addi	s1,s1,-1040 # 80020b30 <log>
    80003f48:	00004597          	auipc	a1,0x4
    80003f4c:	70858593          	addi	a1,a1,1800 # 80008650 <syscalls+0x1e0>
    80003f50:	8526                	mv	a0,s1
    80003f52:	ffffd097          	auipc	ra,0xffffd
    80003f56:	bf0080e7          	jalr	-1040(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80003f5a:	0149a583          	lw	a1,20(s3)
    80003f5e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f60:	0109a783          	lw	a5,16(s3)
    80003f64:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f66:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	ea4080e7          	jalr	-348(ra) # 80002e10 <bread>
  log.lh.n = lh->n;
    80003f74:	4d30                	lw	a2,88(a0)
    80003f76:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f78:	00c05f63          	blez	a2,80003f96 <initlog+0x68>
    80003f7c:	87aa                	mv	a5,a0
    80003f7e:	0001d717          	auipc	a4,0x1d
    80003f82:	be270713          	addi	a4,a4,-1054 # 80020b60 <log+0x30>
    80003f86:	060a                	slli	a2,a2,0x2
    80003f88:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003f8a:	4ff4                	lw	a3,92(a5)
    80003f8c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	0791                	addi	a5,a5,4
    80003f90:	0711                	addi	a4,a4,4
    80003f92:	fec79ce3          	bne	a5,a2,80003f8a <initlog+0x5c>
  brelse(buf);
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	faa080e7          	jalr	-86(ra) # 80002f40 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f9e:	4505                	li	a0,1
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	eca080e7          	jalr	-310(ra) # 80003e6a <install_trans>
  log.lh.n = 0;
    80003fa8:	0001d797          	auipc	a5,0x1d
    80003fac:	ba07aa23          	sw	zero,-1100(a5) # 80020b5c <log+0x2c>
  write_head(); // clear the log
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	e50080e7          	jalr	-432(ra) # 80003e00 <write_head>
}
    80003fb8:	70a2                	ld	ra,40(sp)
    80003fba:	7402                	ld	s0,32(sp)
    80003fbc:	64e2                	ld	s1,24(sp)
    80003fbe:	6942                	ld	s2,16(sp)
    80003fc0:	69a2                	ld	s3,8(sp)
    80003fc2:	6145                	addi	sp,sp,48
    80003fc4:	8082                	ret

0000000080003fc6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fc6:	1101                	addi	sp,sp,-32
    80003fc8:	ec06                	sd	ra,24(sp)
    80003fca:	e822                	sd	s0,16(sp)
    80003fcc:	e426                	sd	s1,8(sp)
    80003fce:	e04a                	sd	s2,0(sp)
    80003fd0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fd2:	0001d517          	auipc	a0,0x1d
    80003fd6:	b5e50513          	addi	a0,a0,-1186 # 80020b30 <log>
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	bf8080e7          	jalr	-1032(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80003fe2:	0001d497          	auipc	s1,0x1d
    80003fe6:	b4e48493          	addi	s1,s1,-1202 # 80020b30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fea:	4979                	li	s2,30
    80003fec:	a039                	j	80003ffa <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fee:	85a6                	mv	a1,s1
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	ffffe097          	auipc	ra,0xffffe
    80003ff6:	04c080e7          	jalr	76(ra) # 8000203e <sleep>
    if(log.committing){
    80003ffa:	50dc                	lw	a5,36(s1)
    80003ffc:	fbed                	bnez	a5,80003fee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ffe:	5098                	lw	a4,32(s1)
    80004000:	2705                	addiw	a4,a4,1
    80004002:	0027179b          	slliw	a5,a4,0x2
    80004006:	9fb9                	addw	a5,a5,a4
    80004008:	0017979b          	slliw	a5,a5,0x1
    8000400c:	54d4                	lw	a3,44(s1)
    8000400e:	9fb5                	addw	a5,a5,a3
    80004010:	00f95963          	bge	s2,a5,80004022 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004014:	85a6                	mv	a1,s1
    80004016:	8526                	mv	a0,s1
    80004018:	ffffe097          	auipc	ra,0xffffe
    8000401c:	026080e7          	jalr	38(ra) # 8000203e <sleep>
    80004020:	bfe9                	j	80003ffa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004022:	0001d517          	auipc	a0,0x1d
    80004026:	b0e50513          	addi	a0,a0,-1266 # 80020b30 <log>
    8000402a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	c5a080e7          	jalr	-934(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004034:	60e2                	ld	ra,24(sp)
    80004036:	6442                	ld	s0,16(sp)
    80004038:	64a2                	ld	s1,8(sp)
    8000403a:	6902                	ld	s2,0(sp)
    8000403c:	6105                	addi	sp,sp,32
    8000403e:	8082                	ret

0000000080004040 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004040:	7139                	addi	sp,sp,-64
    80004042:	fc06                	sd	ra,56(sp)
    80004044:	f822                	sd	s0,48(sp)
    80004046:	f426                	sd	s1,40(sp)
    80004048:	f04a                	sd	s2,32(sp)
    8000404a:	ec4e                	sd	s3,24(sp)
    8000404c:	e852                	sd	s4,16(sp)
    8000404e:	e456                	sd	s5,8(sp)
    80004050:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004052:	0001d497          	auipc	s1,0x1d
    80004056:	ade48493          	addi	s1,s1,-1314 # 80020b30 <log>
    8000405a:	8526                	mv	a0,s1
    8000405c:	ffffd097          	auipc	ra,0xffffd
    80004060:	b76080e7          	jalr	-1162(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004064:	509c                	lw	a5,32(s1)
    80004066:	37fd                	addiw	a5,a5,-1
    80004068:	0007891b          	sext.w	s2,a5
    8000406c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000406e:	50dc                	lw	a5,36(s1)
    80004070:	e7b9                	bnez	a5,800040be <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004072:	04091e63          	bnez	s2,800040ce <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004076:	0001d497          	auipc	s1,0x1d
    8000407a:	aba48493          	addi	s1,s1,-1350 # 80020b30 <log>
    8000407e:	4785                	li	a5,1
    80004080:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004082:	8526                	mv	a0,s1
    80004084:	ffffd097          	auipc	ra,0xffffd
    80004088:	c02080e7          	jalr	-1022(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000408c:	54dc                	lw	a5,44(s1)
    8000408e:	06f04763          	bgtz	a5,800040fc <end_op+0xbc>
    acquire(&log.lock);
    80004092:	0001d497          	auipc	s1,0x1d
    80004096:	a9e48493          	addi	s1,s1,-1378 # 80020b30 <log>
    8000409a:	8526                	mv	a0,s1
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	b36080e7          	jalr	-1226(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800040a4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040a8:	8526                	mv	a0,s1
    800040aa:	ffffe097          	auipc	ra,0xffffe
    800040ae:	ff8080e7          	jalr	-8(ra) # 800020a2 <wakeup>
    release(&log.lock);
    800040b2:	8526                	mv	a0,s1
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	bd2080e7          	jalr	-1070(ra) # 80000c86 <release>
}
    800040bc:	a03d                	j	800040ea <end_op+0xaa>
    panic("log.committing");
    800040be:	00004517          	auipc	a0,0x4
    800040c2:	59a50513          	addi	a0,a0,1434 # 80008658 <syscalls+0x1e8>
    800040c6:	ffffc097          	auipc	ra,0xffffc
    800040ca:	476080e7          	jalr	1142(ra) # 8000053c <panic>
    wakeup(&log);
    800040ce:	0001d497          	auipc	s1,0x1d
    800040d2:	a6248493          	addi	s1,s1,-1438 # 80020b30 <log>
    800040d6:	8526                	mv	a0,s1
    800040d8:	ffffe097          	auipc	ra,0xffffe
    800040dc:	fca080e7          	jalr	-54(ra) # 800020a2 <wakeup>
  release(&log.lock);
    800040e0:	8526                	mv	a0,s1
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	ba4080e7          	jalr	-1116(ra) # 80000c86 <release>
}
    800040ea:	70e2                	ld	ra,56(sp)
    800040ec:	7442                	ld	s0,48(sp)
    800040ee:	74a2                	ld	s1,40(sp)
    800040f0:	7902                	ld	s2,32(sp)
    800040f2:	69e2                	ld	s3,24(sp)
    800040f4:	6a42                	ld	s4,16(sp)
    800040f6:	6aa2                	ld	s5,8(sp)
    800040f8:	6121                	addi	sp,sp,64
    800040fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fc:	0001da97          	auipc	s5,0x1d
    80004100:	a64a8a93          	addi	s5,s5,-1436 # 80020b60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004104:	0001da17          	auipc	s4,0x1d
    80004108:	a2ca0a13          	addi	s4,s4,-1492 # 80020b30 <log>
    8000410c:	018a2583          	lw	a1,24(s4)
    80004110:	012585bb          	addw	a1,a1,s2
    80004114:	2585                	addiw	a1,a1,1
    80004116:	028a2503          	lw	a0,40(s4)
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	cf6080e7          	jalr	-778(ra) # 80002e10 <bread>
    80004122:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004124:	000aa583          	lw	a1,0(s5)
    80004128:	028a2503          	lw	a0,40(s4)
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	ce4080e7          	jalr	-796(ra) # 80002e10 <bread>
    80004134:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004136:	40000613          	li	a2,1024
    8000413a:	05850593          	addi	a1,a0,88
    8000413e:	05848513          	addi	a0,s1,88
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	be8080e7          	jalr	-1048(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	db6080e7          	jalr	-586(ra) # 80002f02 <bwrite>
    brelse(from);
    80004154:	854e                	mv	a0,s3
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	dea080e7          	jalr	-534(ra) # 80002f40 <brelse>
    brelse(to);
    8000415e:	8526                	mv	a0,s1
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	de0080e7          	jalr	-544(ra) # 80002f40 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004168:	2905                	addiw	s2,s2,1
    8000416a:	0a91                	addi	s5,s5,4
    8000416c:	02ca2783          	lw	a5,44(s4)
    80004170:	f8f94ee3          	blt	s2,a5,8000410c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004174:	00000097          	auipc	ra,0x0
    80004178:	c8c080e7          	jalr	-884(ra) # 80003e00 <write_head>
    install_trans(0); // Now install writes to home locations
    8000417c:	4501                	li	a0,0
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	cec080e7          	jalr	-788(ra) # 80003e6a <install_trans>
    log.lh.n = 0;
    80004186:	0001d797          	auipc	a5,0x1d
    8000418a:	9c07ab23          	sw	zero,-1578(a5) # 80020b5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	c72080e7          	jalr	-910(ra) # 80003e00 <write_head>
    80004196:	bdf5                	j	80004092 <end_op+0x52>

0000000080004198 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004198:	1101                	addi	sp,sp,-32
    8000419a:	ec06                	sd	ra,24(sp)
    8000419c:	e822                	sd	s0,16(sp)
    8000419e:	e426                	sd	s1,8(sp)
    800041a0:	e04a                	sd	s2,0(sp)
    800041a2:	1000                	addi	s0,sp,32
    800041a4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041a6:	0001d917          	auipc	s2,0x1d
    800041aa:	98a90913          	addi	s2,s2,-1654 # 80020b30 <log>
    800041ae:	854a                	mv	a0,s2
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	a22080e7          	jalr	-1502(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041b8:	02c92603          	lw	a2,44(s2)
    800041bc:	47f5                	li	a5,29
    800041be:	06c7c563          	blt	a5,a2,80004228 <log_write+0x90>
    800041c2:	0001d797          	auipc	a5,0x1d
    800041c6:	98a7a783          	lw	a5,-1654(a5) # 80020b4c <log+0x1c>
    800041ca:	37fd                	addiw	a5,a5,-1
    800041cc:	04f65e63          	bge	a2,a5,80004228 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041d0:	0001d797          	auipc	a5,0x1d
    800041d4:	9807a783          	lw	a5,-1664(a5) # 80020b50 <log+0x20>
    800041d8:	06f05063          	blez	a5,80004238 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041dc:	4781                	li	a5,0
    800041de:	06c05563          	blez	a2,80004248 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041e2:	44cc                	lw	a1,12(s1)
    800041e4:	0001d717          	auipc	a4,0x1d
    800041e8:	97c70713          	addi	a4,a4,-1668 # 80020b60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041ee:	4314                	lw	a3,0(a4)
    800041f0:	04b68c63          	beq	a3,a1,80004248 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041f4:	2785                	addiw	a5,a5,1
    800041f6:	0711                	addi	a4,a4,4
    800041f8:	fef61be3          	bne	a2,a5,800041ee <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041fc:	0621                	addi	a2,a2,8
    800041fe:	060a                	slli	a2,a2,0x2
    80004200:	0001d797          	auipc	a5,0x1d
    80004204:	93078793          	addi	a5,a5,-1744 # 80020b30 <log>
    80004208:	97b2                	add	a5,a5,a2
    8000420a:	44d8                	lw	a4,12(s1)
    8000420c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	dcc080e7          	jalr	-564(ra) # 80002fdc <bpin>
    log.lh.n++;
    80004218:	0001d717          	auipc	a4,0x1d
    8000421c:	91870713          	addi	a4,a4,-1768 # 80020b30 <log>
    80004220:	575c                	lw	a5,44(a4)
    80004222:	2785                	addiw	a5,a5,1
    80004224:	d75c                	sw	a5,44(a4)
    80004226:	a82d                	j	80004260 <log_write+0xc8>
    panic("too big a transaction");
    80004228:	00004517          	auipc	a0,0x4
    8000422c:	44050513          	addi	a0,a0,1088 # 80008668 <syscalls+0x1f8>
    80004230:	ffffc097          	auipc	ra,0xffffc
    80004234:	30c080e7          	jalr	780(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004238:	00004517          	auipc	a0,0x4
    8000423c:	44850513          	addi	a0,a0,1096 # 80008680 <syscalls+0x210>
    80004240:	ffffc097          	auipc	ra,0xffffc
    80004244:	2fc080e7          	jalr	764(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004248:	00878693          	addi	a3,a5,8
    8000424c:	068a                	slli	a3,a3,0x2
    8000424e:	0001d717          	auipc	a4,0x1d
    80004252:	8e270713          	addi	a4,a4,-1822 # 80020b30 <log>
    80004256:	9736                	add	a4,a4,a3
    80004258:	44d4                	lw	a3,12(s1)
    8000425a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000425c:	faf609e3          	beq	a2,a5,8000420e <log_write+0x76>
  }
  release(&log.lock);
    80004260:	0001d517          	auipc	a0,0x1d
    80004264:	8d050513          	addi	a0,a0,-1840 # 80020b30 <log>
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	a1e080e7          	jalr	-1506(ra) # 80000c86 <release>
}
    80004270:	60e2                	ld	ra,24(sp)
    80004272:	6442                	ld	s0,16(sp)
    80004274:	64a2                	ld	s1,8(sp)
    80004276:	6902                	ld	s2,0(sp)
    80004278:	6105                	addi	sp,sp,32
    8000427a:	8082                	ret

000000008000427c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000427c:	1101                	addi	sp,sp,-32
    8000427e:	ec06                	sd	ra,24(sp)
    80004280:	e822                	sd	s0,16(sp)
    80004282:	e426                	sd	s1,8(sp)
    80004284:	e04a                	sd	s2,0(sp)
    80004286:	1000                	addi	s0,sp,32
    80004288:	84aa                	mv	s1,a0
    8000428a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000428c:	00004597          	auipc	a1,0x4
    80004290:	41458593          	addi	a1,a1,1044 # 800086a0 <syscalls+0x230>
    80004294:	0521                	addi	a0,a0,8
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	8ac080e7          	jalr	-1876(ra) # 80000b42 <initlock>
  lk->name = name;
    8000429e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042a6:	0204a423          	sw	zero,40(s1)
}
    800042aa:	60e2                	ld	ra,24(sp)
    800042ac:	6442                	ld	s0,16(sp)
    800042ae:	64a2                	ld	s1,8(sp)
    800042b0:	6902                	ld	s2,0(sp)
    800042b2:	6105                	addi	sp,sp,32
    800042b4:	8082                	ret

00000000800042b6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042b6:	1101                	addi	sp,sp,-32
    800042b8:	ec06                	sd	ra,24(sp)
    800042ba:	e822                	sd	s0,16(sp)
    800042bc:	e426                	sd	s1,8(sp)
    800042be:	e04a                	sd	s2,0(sp)
    800042c0:	1000                	addi	s0,sp,32
    800042c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042c4:	00850913          	addi	s2,a0,8
    800042c8:	854a                	mv	a0,s2
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	908080e7          	jalr	-1784(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800042d2:	409c                	lw	a5,0(s1)
    800042d4:	cb89                	beqz	a5,800042e6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042d6:	85ca                	mv	a1,s2
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffe097          	auipc	ra,0xffffe
    800042de:	d64080e7          	jalr	-668(ra) # 8000203e <sleep>
  while (lk->locked) {
    800042e2:	409c                	lw	a5,0(s1)
    800042e4:	fbed                	bnez	a5,800042d6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042e6:	4785                	li	a5,1
    800042e8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	6ac080e7          	jalr	1708(ra) # 80001996 <myproc>
    800042f2:	591c                	lw	a5,48(a0)
    800042f4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042f6:	854a                	mv	a0,s2
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	98e080e7          	jalr	-1650(ra) # 80000c86 <release>
}
    80004300:	60e2                	ld	ra,24(sp)
    80004302:	6442                	ld	s0,16(sp)
    80004304:	64a2                	ld	s1,8(sp)
    80004306:	6902                	ld	s2,0(sp)
    80004308:	6105                	addi	sp,sp,32
    8000430a:	8082                	ret

000000008000430c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	addi	s0,sp,32
    80004318:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431a:	00850913          	addi	s2,a0,8
    8000431e:	854a                	mv	a0,s2
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	8b2080e7          	jalr	-1870(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004328:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000432c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004330:	8526                	mv	a0,s1
    80004332:	ffffe097          	auipc	ra,0xffffe
    80004336:	d70080e7          	jalr	-656(ra) # 800020a2 <wakeup>
  release(&lk->lk);
    8000433a:	854a                	mv	a0,s2
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	94a080e7          	jalr	-1718(ra) # 80000c86 <release>
}
    80004344:	60e2                	ld	ra,24(sp)
    80004346:	6442                	ld	s0,16(sp)
    80004348:	64a2                	ld	s1,8(sp)
    8000434a:	6902                	ld	s2,0(sp)
    8000434c:	6105                	addi	sp,sp,32
    8000434e:	8082                	ret

0000000080004350 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004350:	7179                	addi	sp,sp,-48
    80004352:	f406                	sd	ra,40(sp)
    80004354:	f022                	sd	s0,32(sp)
    80004356:	ec26                	sd	s1,24(sp)
    80004358:	e84a                	sd	s2,16(sp)
    8000435a:	e44e                	sd	s3,8(sp)
    8000435c:	1800                	addi	s0,sp,48
    8000435e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004360:	00850913          	addi	s2,a0,8
    80004364:	854a                	mv	a0,s2
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	86c080e7          	jalr	-1940(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000436e:	409c                	lw	a5,0(s1)
    80004370:	ef99                	bnez	a5,8000438e <holdingsleep+0x3e>
    80004372:	4481                	li	s1,0
  release(&lk->lk);
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	910080e7          	jalr	-1776(ra) # 80000c86 <release>
  return r;
}
    8000437e:	8526                	mv	a0,s1
    80004380:	70a2                	ld	ra,40(sp)
    80004382:	7402                	ld	s0,32(sp)
    80004384:	64e2                	ld	s1,24(sp)
    80004386:	6942                	ld	s2,16(sp)
    80004388:	69a2                	ld	s3,8(sp)
    8000438a:	6145                	addi	sp,sp,48
    8000438c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000438e:	0284a983          	lw	s3,40(s1)
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	604080e7          	jalr	1540(ra) # 80001996 <myproc>
    8000439a:	5904                	lw	s1,48(a0)
    8000439c:	413484b3          	sub	s1,s1,s3
    800043a0:	0014b493          	seqz	s1,s1
    800043a4:	bfc1                	j	80004374 <holdingsleep+0x24>

00000000800043a6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043a6:	1141                	addi	sp,sp,-16
    800043a8:	e406                	sd	ra,8(sp)
    800043aa:	e022                	sd	s0,0(sp)
    800043ac:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043ae:	00004597          	auipc	a1,0x4
    800043b2:	30258593          	addi	a1,a1,770 # 800086b0 <syscalls+0x240>
    800043b6:	0001d517          	auipc	a0,0x1d
    800043ba:	8c250513          	addi	a0,a0,-1854 # 80020c78 <ftable>
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	784080e7          	jalr	1924(ra) # 80000b42 <initlock>
}
    800043c6:	60a2                	ld	ra,8(sp)
    800043c8:	6402                	ld	s0,0(sp)
    800043ca:	0141                	addi	sp,sp,16
    800043cc:	8082                	ret

00000000800043ce <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043ce:	1101                	addi	sp,sp,-32
    800043d0:	ec06                	sd	ra,24(sp)
    800043d2:	e822                	sd	s0,16(sp)
    800043d4:	e426                	sd	s1,8(sp)
    800043d6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043d8:	0001d517          	auipc	a0,0x1d
    800043dc:	8a050513          	addi	a0,a0,-1888 # 80020c78 <ftable>
    800043e0:	ffffc097          	auipc	ra,0xffffc
    800043e4:	7f2080e7          	jalr	2034(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043e8:	0001d497          	auipc	s1,0x1d
    800043ec:	8a848493          	addi	s1,s1,-1880 # 80020c90 <ftable+0x18>
    800043f0:	0001e717          	auipc	a4,0x1e
    800043f4:	84070713          	addi	a4,a4,-1984 # 80021c30 <disk>
    if(f->ref == 0){
    800043f8:	40dc                	lw	a5,4(s1)
    800043fa:	cf99                	beqz	a5,80004418 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043fc:	02848493          	addi	s1,s1,40
    80004400:	fee49ce3          	bne	s1,a4,800043f8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004404:	0001d517          	auipc	a0,0x1d
    80004408:	87450513          	addi	a0,a0,-1932 # 80020c78 <ftable>
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	87a080e7          	jalr	-1926(ra) # 80000c86 <release>
  return 0;
    80004414:	4481                	li	s1,0
    80004416:	a819                	j	8000442c <filealloc+0x5e>
      f->ref = 1;
    80004418:	4785                	li	a5,1
    8000441a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000441c:	0001d517          	auipc	a0,0x1d
    80004420:	85c50513          	addi	a0,a0,-1956 # 80020c78 <ftable>
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	862080e7          	jalr	-1950(ra) # 80000c86 <release>
}
    8000442c:	8526                	mv	a0,s1
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	1000                	addi	s0,sp,32
    80004442:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004444:	0001d517          	auipc	a0,0x1d
    80004448:	83450513          	addi	a0,a0,-1996 # 80020c78 <ftable>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	786080e7          	jalr	1926(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004454:	40dc                	lw	a5,4(s1)
    80004456:	02f05263          	blez	a5,8000447a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000445a:	2785                	addiw	a5,a5,1
    8000445c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000445e:	0001d517          	auipc	a0,0x1d
    80004462:	81a50513          	addi	a0,a0,-2022 # 80020c78 <ftable>
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	820080e7          	jalr	-2016(ra) # 80000c86 <release>
  return f;
}
    8000446e:	8526                	mv	a0,s1
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6105                	addi	sp,sp,32
    80004478:	8082                	ret
    panic("filedup");
    8000447a:	00004517          	auipc	a0,0x4
    8000447e:	23e50513          	addi	a0,a0,574 # 800086b8 <syscalls+0x248>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	0ba080e7          	jalr	186(ra) # 8000053c <panic>

000000008000448a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000448a:	7139                	addi	sp,sp,-64
    8000448c:	fc06                	sd	ra,56(sp)
    8000448e:	f822                	sd	s0,48(sp)
    80004490:	f426                	sd	s1,40(sp)
    80004492:	f04a                	sd	s2,32(sp)
    80004494:	ec4e                	sd	s3,24(sp)
    80004496:	e852                	sd	s4,16(sp)
    80004498:	e456                	sd	s5,8(sp)
    8000449a:	0080                	addi	s0,sp,64
    8000449c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000449e:	0001c517          	auipc	a0,0x1c
    800044a2:	7da50513          	addi	a0,a0,2010 # 80020c78 <ftable>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	72c080e7          	jalr	1836(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800044ae:	40dc                	lw	a5,4(s1)
    800044b0:	06f05163          	blez	a5,80004512 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044b4:	37fd                	addiw	a5,a5,-1
    800044b6:	0007871b          	sext.w	a4,a5
    800044ba:	c0dc                	sw	a5,4(s1)
    800044bc:	06e04363          	bgtz	a4,80004522 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044c0:	0004a903          	lw	s2,0(s1)
    800044c4:	0094ca83          	lbu	s5,9(s1)
    800044c8:	0104ba03          	ld	s4,16(s1)
    800044cc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044d0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044d4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044d8:	0001c517          	auipc	a0,0x1c
    800044dc:	7a050513          	addi	a0,a0,1952 # 80020c78 <ftable>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	7a6080e7          	jalr	1958(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    800044e8:	4785                	li	a5,1
    800044ea:	04f90d63          	beq	s2,a5,80004544 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044ee:	3979                	addiw	s2,s2,-2
    800044f0:	4785                	li	a5,1
    800044f2:	0527e063          	bltu	a5,s2,80004532 <fileclose+0xa8>
    begin_op();
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	ad0080e7          	jalr	-1328(ra) # 80003fc6 <begin_op>
    iput(ff.ip);
    800044fe:	854e                	mv	a0,s3
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	2da080e7          	jalr	730(ra) # 800037da <iput>
    end_op();
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	b38080e7          	jalr	-1224(ra) # 80004040 <end_op>
    80004510:	a00d                	j	80004532 <fileclose+0xa8>
    panic("fileclose");
    80004512:	00004517          	auipc	a0,0x4
    80004516:	1ae50513          	addi	a0,a0,430 # 800086c0 <syscalls+0x250>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	022080e7          	jalr	34(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004522:	0001c517          	auipc	a0,0x1c
    80004526:	75650513          	addi	a0,a0,1878 # 80020c78 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	75c080e7          	jalr	1884(ra) # 80000c86 <release>
  }
}
    80004532:	70e2                	ld	ra,56(sp)
    80004534:	7442                	ld	s0,48(sp)
    80004536:	74a2                	ld	s1,40(sp)
    80004538:	7902                	ld	s2,32(sp)
    8000453a:	69e2                	ld	s3,24(sp)
    8000453c:	6a42                	ld	s4,16(sp)
    8000453e:	6aa2                	ld	s5,8(sp)
    80004540:	6121                	addi	sp,sp,64
    80004542:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004544:	85d6                	mv	a1,s5
    80004546:	8552                	mv	a0,s4
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	348080e7          	jalr	840(ra) # 80004890 <pipeclose>
    80004550:	b7cd                	j	80004532 <fileclose+0xa8>

0000000080004552 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004552:	715d                	addi	sp,sp,-80
    80004554:	e486                	sd	ra,72(sp)
    80004556:	e0a2                	sd	s0,64(sp)
    80004558:	fc26                	sd	s1,56(sp)
    8000455a:	f84a                	sd	s2,48(sp)
    8000455c:	f44e                	sd	s3,40(sp)
    8000455e:	0880                	addi	s0,sp,80
    80004560:	84aa                	mv	s1,a0
    80004562:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004564:	ffffd097          	auipc	ra,0xffffd
    80004568:	432080e7          	jalr	1074(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	37f9                	addiw	a5,a5,-2
    80004570:	4705                	li	a4,1
    80004572:	04f76763          	bltu	a4,a5,800045c0 <filestat+0x6e>
    80004576:	892a                	mv	s2,a0
    ilock(f->ip);
    80004578:	6c88                	ld	a0,24(s1)
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	0a6080e7          	jalr	166(ra) # 80003620 <ilock>
    stati(f->ip, &st);
    80004582:	fb840593          	addi	a1,s0,-72
    80004586:	6c88                	ld	a0,24(s1)
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	322080e7          	jalr	802(ra) # 800038aa <stati>
    iunlock(f->ip);
    80004590:	6c88                	ld	a0,24(s1)
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	150080e7          	jalr	336(ra) # 800036e2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000459a:	46e1                	li	a3,24
    8000459c:	fb840613          	addi	a2,s0,-72
    800045a0:	85ce                	mv	a1,s3
    800045a2:	05093503          	ld	a0,80(s2)
    800045a6:	ffffd097          	auipc	ra,0xffffd
    800045aa:	0b0080e7          	jalr	176(ra) # 80001656 <copyout>
    800045ae:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045b2:	60a6                	ld	ra,72(sp)
    800045b4:	6406                	ld	s0,64(sp)
    800045b6:	74e2                	ld	s1,56(sp)
    800045b8:	7942                	ld	s2,48(sp)
    800045ba:	79a2                	ld	s3,40(sp)
    800045bc:	6161                	addi	sp,sp,80
    800045be:	8082                	ret
  return -1;
    800045c0:	557d                	li	a0,-1
    800045c2:	bfc5                	j	800045b2 <filestat+0x60>

00000000800045c4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045c4:	7179                	addi	sp,sp,-48
    800045c6:	f406                	sd	ra,40(sp)
    800045c8:	f022                	sd	s0,32(sp)
    800045ca:	ec26                	sd	s1,24(sp)
    800045cc:	e84a                	sd	s2,16(sp)
    800045ce:	e44e                	sd	s3,8(sp)
    800045d0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045d2:	00854783          	lbu	a5,8(a0)
    800045d6:	c3d5                	beqz	a5,8000467a <fileread+0xb6>
    800045d8:	84aa                	mv	s1,a0
    800045da:	89ae                	mv	s3,a1
    800045dc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045de:	411c                	lw	a5,0(a0)
    800045e0:	4705                	li	a4,1
    800045e2:	04e78963          	beq	a5,a4,80004634 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045e6:	470d                	li	a4,3
    800045e8:	04e78d63          	beq	a5,a4,80004642 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045ec:	4709                	li	a4,2
    800045ee:	06e79e63          	bne	a5,a4,8000466a <fileread+0xa6>
    ilock(f->ip);
    800045f2:	6d08                	ld	a0,24(a0)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	02c080e7          	jalr	44(ra) # 80003620 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045fc:	874a                	mv	a4,s2
    800045fe:	5094                	lw	a3,32(s1)
    80004600:	864e                	mv	a2,s3
    80004602:	4585                	li	a1,1
    80004604:	6c88                	ld	a0,24(s1)
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	2ce080e7          	jalr	718(ra) # 800038d4 <readi>
    8000460e:	892a                	mv	s2,a0
    80004610:	00a05563          	blez	a0,8000461a <fileread+0x56>
      f->off += r;
    80004614:	509c                	lw	a5,32(s1)
    80004616:	9fa9                	addw	a5,a5,a0
    80004618:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000461a:	6c88                	ld	a0,24(s1)
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	0c6080e7          	jalr	198(ra) # 800036e2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004624:	854a                	mv	a0,s2
    80004626:	70a2                	ld	ra,40(sp)
    80004628:	7402                	ld	s0,32(sp)
    8000462a:	64e2                	ld	s1,24(sp)
    8000462c:	6942                	ld	s2,16(sp)
    8000462e:	69a2                	ld	s3,8(sp)
    80004630:	6145                	addi	sp,sp,48
    80004632:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004634:	6908                	ld	a0,16(a0)
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	3c2080e7          	jalr	962(ra) # 800049f8 <piperead>
    8000463e:	892a                	mv	s2,a0
    80004640:	b7d5                	j	80004624 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004642:	02451783          	lh	a5,36(a0)
    80004646:	03079693          	slli	a3,a5,0x30
    8000464a:	92c1                	srli	a3,a3,0x30
    8000464c:	4725                	li	a4,9
    8000464e:	02d76863          	bltu	a4,a3,8000467e <fileread+0xba>
    80004652:	0792                	slli	a5,a5,0x4
    80004654:	0001c717          	auipc	a4,0x1c
    80004658:	58470713          	addi	a4,a4,1412 # 80020bd8 <devsw>
    8000465c:	97ba                	add	a5,a5,a4
    8000465e:	639c                	ld	a5,0(a5)
    80004660:	c38d                	beqz	a5,80004682 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004662:	4505                	li	a0,1
    80004664:	9782                	jalr	a5
    80004666:	892a                	mv	s2,a0
    80004668:	bf75                	j	80004624 <fileread+0x60>
    panic("fileread");
    8000466a:	00004517          	auipc	a0,0x4
    8000466e:	06650513          	addi	a0,a0,102 # 800086d0 <syscalls+0x260>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	eca080e7          	jalr	-310(ra) # 8000053c <panic>
    return -1;
    8000467a:	597d                	li	s2,-1
    8000467c:	b765                	j	80004624 <fileread+0x60>
      return -1;
    8000467e:	597d                	li	s2,-1
    80004680:	b755                	j	80004624 <fileread+0x60>
    80004682:	597d                	li	s2,-1
    80004684:	b745                	j	80004624 <fileread+0x60>

0000000080004686 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004686:	00954783          	lbu	a5,9(a0)
    8000468a:	10078e63          	beqz	a5,800047a6 <filewrite+0x120>
{
    8000468e:	715d                	addi	sp,sp,-80
    80004690:	e486                	sd	ra,72(sp)
    80004692:	e0a2                	sd	s0,64(sp)
    80004694:	fc26                	sd	s1,56(sp)
    80004696:	f84a                	sd	s2,48(sp)
    80004698:	f44e                	sd	s3,40(sp)
    8000469a:	f052                	sd	s4,32(sp)
    8000469c:	ec56                	sd	s5,24(sp)
    8000469e:	e85a                	sd	s6,16(sp)
    800046a0:	e45e                	sd	s7,8(sp)
    800046a2:	e062                	sd	s8,0(sp)
    800046a4:	0880                	addi	s0,sp,80
    800046a6:	892a                	mv	s2,a0
    800046a8:	8b2e                	mv	s6,a1
    800046aa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ac:	411c                	lw	a5,0(a0)
    800046ae:	4705                	li	a4,1
    800046b0:	02e78263          	beq	a5,a4,800046d4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b4:	470d                	li	a4,3
    800046b6:	02e78563          	beq	a5,a4,800046e0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046ba:	4709                	li	a4,2
    800046bc:	0ce79d63          	bne	a5,a4,80004796 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046c0:	0ac05b63          	blez	a2,80004776 <filewrite+0xf0>
    int i = 0;
    800046c4:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800046c6:	6b85                	lui	s7,0x1
    800046c8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800046cc:	6c05                	lui	s8,0x1
    800046ce:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800046d2:	a851                	j	80004766 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800046d4:	6908                	ld	a0,16(a0)
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	22a080e7          	jalr	554(ra) # 80004900 <pipewrite>
    800046de:	a045                	j	8000477e <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046e0:	02451783          	lh	a5,36(a0)
    800046e4:	03079693          	slli	a3,a5,0x30
    800046e8:	92c1                	srli	a3,a3,0x30
    800046ea:	4725                	li	a4,9
    800046ec:	0ad76f63          	bltu	a4,a3,800047aa <filewrite+0x124>
    800046f0:	0792                	slli	a5,a5,0x4
    800046f2:	0001c717          	auipc	a4,0x1c
    800046f6:	4e670713          	addi	a4,a4,1254 # 80020bd8 <devsw>
    800046fa:	97ba                	add	a5,a5,a4
    800046fc:	679c                	ld	a5,8(a5)
    800046fe:	cbc5                	beqz	a5,800047ae <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004700:	4505                	li	a0,1
    80004702:	9782                	jalr	a5
    80004704:	a8ad                	j	8000477e <filewrite+0xf8>
      if(n1 > max)
    80004706:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	8bc080e7          	jalr	-1860(ra) # 80003fc6 <begin_op>
      ilock(f->ip);
    80004712:	01893503          	ld	a0,24(s2)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	f0a080e7          	jalr	-246(ra) # 80003620 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000471e:	8756                	mv	a4,s5
    80004720:	02092683          	lw	a3,32(s2)
    80004724:	01698633          	add	a2,s3,s6
    80004728:	4585                	li	a1,1
    8000472a:	01893503          	ld	a0,24(s2)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	29e080e7          	jalr	670(ra) # 800039cc <writei>
    80004736:	84aa                	mv	s1,a0
    80004738:	00a05763          	blez	a0,80004746 <filewrite+0xc0>
        f->off += r;
    8000473c:	02092783          	lw	a5,32(s2)
    80004740:	9fa9                	addw	a5,a5,a0
    80004742:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004746:	01893503          	ld	a0,24(s2)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	f98080e7          	jalr	-104(ra) # 800036e2 <iunlock>
      end_op();
    80004752:	00000097          	auipc	ra,0x0
    80004756:	8ee080e7          	jalr	-1810(ra) # 80004040 <end_op>

      if(r != n1){
    8000475a:	009a9f63          	bne	s5,s1,80004778 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    8000475e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004762:	0149db63          	bge	s3,s4,80004778 <filewrite+0xf2>
      int n1 = n - i;
    80004766:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000476a:	0004879b          	sext.w	a5,s1
    8000476e:	f8fbdce3          	bge	s7,a5,80004706 <filewrite+0x80>
    80004772:	84e2                	mv	s1,s8
    80004774:	bf49                	j	80004706 <filewrite+0x80>
    int i = 0;
    80004776:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004778:	033a1d63          	bne	s4,s3,800047b2 <filewrite+0x12c>
    8000477c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000477e:	60a6                	ld	ra,72(sp)
    80004780:	6406                	ld	s0,64(sp)
    80004782:	74e2                	ld	s1,56(sp)
    80004784:	7942                	ld	s2,48(sp)
    80004786:	79a2                	ld	s3,40(sp)
    80004788:	7a02                	ld	s4,32(sp)
    8000478a:	6ae2                	ld	s5,24(sp)
    8000478c:	6b42                	ld	s6,16(sp)
    8000478e:	6ba2                	ld	s7,8(sp)
    80004790:	6c02                	ld	s8,0(sp)
    80004792:	6161                	addi	sp,sp,80
    80004794:	8082                	ret
    panic("filewrite");
    80004796:	00004517          	auipc	a0,0x4
    8000479a:	f4a50513          	addi	a0,a0,-182 # 800086e0 <syscalls+0x270>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	d9e080e7          	jalr	-610(ra) # 8000053c <panic>
    return -1;
    800047a6:	557d                	li	a0,-1
}
    800047a8:	8082                	ret
      return -1;
    800047aa:	557d                	li	a0,-1
    800047ac:	bfc9                	j	8000477e <filewrite+0xf8>
    800047ae:	557d                	li	a0,-1
    800047b0:	b7f9                	j	8000477e <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800047b2:	557d                	li	a0,-1
    800047b4:	b7e9                	j	8000477e <filewrite+0xf8>

00000000800047b6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047b6:	7179                	addi	sp,sp,-48
    800047b8:	f406                	sd	ra,40(sp)
    800047ba:	f022                	sd	s0,32(sp)
    800047bc:	ec26                	sd	s1,24(sp)
    800047be:	e84a                	sd	s2,16(sp)
    800047c0:	e44e                	sd	s3,8(sp)
    800047c2:	e052                	sd	s4,0(sp)
    800047c4:	1800                	addi	s0,sp,48
    800047c6:	84aa                	mv	s1,a0
    800047c8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047ca:	0005b023          	sd	zero,0(a1)
    800047ce:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047d2:	00000097          	auipc	ra,0x0
    800047d6:	bfc080e7          	jalr	-1028(ra) # 800043ce <filealloc>
    800047da:	e088                	sd	a0,0(s1)
    800047dc:	c551                	beqz	a0,80004868 <pipealloc+0xb2>
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	bf0080e7          	jalr	-1040(ra) # 800043ce <filealloc>
    800047e6:	00aa3023          	sd	a0,0(s4)
    800047ea:	c92d                	beqz	a0,8000485c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	2f6080e7          	jalr	758(ra) # 80000ae2 <kalloc>
    800047f4:	892a                	mv	s2,a0
    800047f6:	c125                	beqz	a0,80004856 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047f8:	4985                	li	s3,1
    800047fa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047fe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004802:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004806:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000480a:	00004597          	auipc	a1,0x4
    8000480e:	ee658593          	addi	a1,a1,-282 # 800086f0 <syscalls+0x280>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	330080e7          	jalr	816(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    8000481a:	609c                	ld	a5,0(s1)
    8000481c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004820:	609c                	ld	a5,0(s1)
    80004822:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004826:	609c                	ld	a5,0(s1)
    80004828:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000482c:	609c                	ld	a5,0(s1)
    8000482e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004832:	000a3783          	ld	a5,0(s4)
    80004836:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000483a:	000a3783          	ld	a5,0(s4)
    8000483e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004842:	000a3783          	ld	a5,0(s4)
    80004846:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000484a:	000a3783          	ld	a5,0(s4)
    8000484e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004852:	4501                	li	a0,0
    80004854:	a025                	j	8000487c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004856:	6088                	ld	a0,0(s1)
    80004858:	e501                	bnez	a0,80004860 <pipealloc+0xaa>
    8000485a:	a039                	j	80004868 <pipealloc+0xb2>
    8000485c:	6088                	ld	a0,0(s1)
    8000485e:	c51d                	beqz	a0,8000488c <pipealloc+0xd6>
    fileclose(*f0);
    80004860:	00000097          	auipc	ra,0x0
    80004864:	c2a080e7          	jalr	-982(ra) # 8000448a <fileclose>
  if(*f1)
    80004868:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000486c:	557d                	li	a0,-1
  if(*f1)
    8000486e:	c799                	beqz	a5,8000487c <pipealloc+0xc6>
    fileclose(*f1);
    80004870:	853e                	mv	a0,a5
    80004872:	00000097          	auipc	ra,0x0
    80004876:	c18080e7          	jalr	-1000(ra) # 8000448a <fileclose>
  return -1;
    8000487a:	557d                	li	a0,-1
}
    8000487c:	70a2                	ld	ra,40(sp)
    8000487e:	7402                	ld	s0,32(sp)
    80004880:	64e2                	ld	s1,24(sp)
    80004882:	6942                	ld	s2,16(sp)
    80004884:	69a2                	ld	s3,8(sp)
    80004886:	6a02                	ld	s4,0(sp)
    80004888:	6145                	addi	sp,sp,48
    8000488a:	8082                	ret
  return -1;
    8000488c:	557d                	li	a0,-1
    8000488e:	b7fd                	j	8000487c <pipealloc+0xc6>

0000000080004890 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004890:	1101                	addi	sp,sp,-32
    80004892:	ec06                	sd	ra,24(sp)
    80004894:	e822                	sd	s0,16(sp)
    80004896:	e426                	sd	s1,8(sp)
    80004898:	e04a                	sd	s2,0(sp)
    8000489a:	1000                	addi	s0,sp,32
    8000489c:	84aa                	mv	s1,a0
    8000489e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	332080e7          	jalr	818(ra) # 80000bd2 <acquire>
  if(writable){
    800048a8:	02090d63          	beqz	s2,800048e2 <pipeclose+0x52>
    pi->writeopen = 0;
    800048ac:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048b0:	21848513          	addi	a0,s1,536
    800048b4:	ffffd097          	auipc	ra,0xffffd
    800048b8:	7ee080e7          	jalr	2030(ra) # 800020a2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048bc:	2204b783          	ld	a5,544(s1)
    800048c0:	eb95                	bnez	a5,800048f4 <pipeclose+0x64>
    release(&pi->lock);
    800048c2:	8526                	mv	a0,s1
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	3c2080e7          	jalr	962(ra) # 80000c86 <release>
    kfree((char*)pi);
    800048cc:	8526                	mv	a0,s1
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	116080e7          	jalr	278(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    800048d6:	60e2                	ld	ra,24(sp)
    800048d8:	6442                	ld	s0,16(sp)
    800048da:	64a2                	ld	s1,8(sp)
    800048dc:	6902                	ld	s2,0(sp)
    800048de:	6105                	addi	sp,sp,32
    800048e0:	8082                	ret
    pi->readopen = 0;
    800048e2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048e6:	21c48513          	addi	a0,s1,540
    800048ea:	ffffd097          	auipc	ra,0xffffd
    800048ee:	7b8080e7          	jalr	1976(ra) # 800020a2 <wakeup>
    800048f2:	b7e9                	j	800048bc <pipeclose+0x2c>
    release(&pi->lock);
    800048f4:	8526                	mv	a0,s1
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	390080e7          	jalr	912(ra) # 80000c86 <release>
}
    800048fe:	bfe1                	j	800048d6 <pipeclose+0x46>

0000000080004900 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004900:	711d                	addi	sp,sp,-96
    80004902:	ec86                	sd	ra,88(sp)
    80004904:	e8a2                	sd	s0,80(sp)
    80004906:	e4a6                	sd	s1,72(sp)
    80004908:	e0ca                	sd	s2,64(sp)
    8000490a:	fc4e                	sd	s3,56(sp)
    8000490c:	f852                	sd	s4,48(sp)
    8000490e:	f456                	sd	s5,40(sp)
    80004910:	f05a                	sd	s6,32(sp)
    80004912:	ec5e                	sd	s7,24(sp)
    80004914:	e862                	sd	s8,16(sp)
    80004916:	1080                	addi	s0,sp,96
    80004918:	84aa                	mv	s1,a0
    8000491a:	8aae                	mv	s5,a1
    8000491c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000491e:	ffffd097          	auipc	ra,0xffffd
    80004922:	078080e7          	jalr	120(ra) # 80001996 <myproc>
    80004926:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004928:	8526                	mv	a0,s1
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	2a8080e7          	jalr	680(ra) # 80000bd2 <acquire>
  while(i < n){
    80004932:	0b405663          	blez	s4,800049de <pipewrite+0xde>
  int i = 0;
    80004936:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004938:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000493a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000493e:	21c48b93          	addi	s7,s1,540
    80004942:	a089                	j	80004984 <pipewrite+0x84>
      release(&pi->lock);
    80004944:	8526                	mv	a0,s1
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	340080e7          	jalr	832(ra) # 80000c86 <release>
      return -1;
    8000494e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004950:	854a                	mv	a0,s2
    80004952:	60e6                	ld	ra,88(sp)
    80004954:	6446                	ld	s0,80(sp)
    80004956:	64a6                	ld	s1,72(sp)
    80004958:	6906                	ld	s2,64(sp)
    8000495a:	79e2                	ld	s3,56(sp)
    8000495c:	7a42                	ld	s4,48(sp)
    8000495e:	7aa2                	ld	s5,40(sp)
    80004960:	7b02                	ld	s6,32(sp)
    80004962:	6be2                	ld	s7,24(sp)
    80004964:	6c42                	ld	s8,16(sp)
    80004966:	6125                	addi	sp,sp,96
    80004968:	8082                	ret
      wakeup(&pi->nread);
    8000496a:	8562                	mv	a0,s8
    8000496c:	ffffd097          	auipc	ra,0xffffd
    80004970:	736080e7          	jalr	1846(ra) # 800020a2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004974:	85a6                	mv	a1,s1
    80004976:	855e                	mv	a0,s7
    80004978:	ffffd097          	auipc	ra,0xffffd
    8000497c:	6c6080e7          	jalr	1734(ra) # 8000203e <sleep>
  while(i < n){
    80004980:	07495063          	bge	s2,s4,800049e0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004984:	2204a783          	lw	a5,544(s1)
    80004988:	dfd5                	beqz	a5,80004944 <pipewrite+0x44>
    8000498a:	854e                	mv	a0,s3
    8000498c:	ffffe097          	auipc	ra,0xffffe
    80004990:	95a080e7          	jalr	-1702(ra) # 800022e6 <killed>
    80004994:	f945                	bnez	a0,80004944 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004996:	2184a783          	lw	a5,536(s1)
    8000499a:	21c4a703          	lw	a4,540(s1)
    8000499e:	2007879b          	addiw	a5,a5,512
    800049a2:	fcf704e3          	beq	a4,a5,8000496a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049a6:	4685                	li	a3,1
    800049a8:	01590633          	add	a2,s2,s5
    800049ac:	faf40593          	addi	a1,s0,-81
    800049b0:	0509b503          	ld	a0,80(s3)
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	d2e080e7          	jalr	-722(ra) # 800016e2 <copyin>
    800049bc:	03650263          	beq	a0,s6,800049e0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049c0:	21c4a783          	lw	a5,540(s1)
    800049c4:	0017871b          	addiw	a4,a5,1
    800049c8:	20e4ae23          	sw	a4,540(s1)
    800049cc:	1ff7f793          	andi	a5,a5,511
    800049d0:	97a6                	add	a5,a5,s1
    800049d2:	faf44703          	lbu	a4,-81(s0)
    800049d6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049da:	2905                	addiw	s2,s2,1
    800049dc:	b755                	j	80004980 <pipewrite+0x80>
  int i = 0;
    800049de:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049e0:	21848513          	addi	a0,s1,536
    800049e4:	ffffd097          	auipc	ra,0xffffd
    800049e8:	6be080e7          	jalr	1726(ra) # 800020a2 <wakeup>
  release(&pi->lock);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	298080e7          	jalr	664(ra) # 80000c86 <release>
  return i;
    800049f6:	bfa9                	j	80004950 <pipewrite+0x50>

00000000800049f8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049f8:	715d                	addi	sp,sp,-80
    800049fa:	e486                	sd	ra,72(sp)
    800049fc:	e0a2                	sd	s0,64(sp)
    800049fe:	fc26                	sd	s1,56(sp)
    80004a00:	f84a                	sd	s2,48(sp)
    80004a02:	f44e                	sd	s3,40(sp)
    80004a04:	f052                	sd	s4,32(sp)
    80004a06:	ec56                	sd	s5,24(sp)
    80004a08:	e85a                	sd	s6,16(sp)
    80004a0a:	0880                	addi	s0,sp,80
    80004a0c:	84aa                	mv	s1,a0
    80004a0e:	892e                	mv	s2,a1
    80004a10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a12:	ffffd097          	auipc	ra,0xffffd
    80004a16:	f84080e7          	jalr	-124(ra) # 80001996 <myproc>
    80004a1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1b4080e7          	jalr	436(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a26:	2184a703          	lw	a4,536(s1)
    80004a2a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a2e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a32:	02f71763          	bne	a4,a5,80004a60 <piperead+0x68>
    80004a36:	2244a783          	lw	a5,548(s1)
    80004a3a:	c39d                	beqz	a5,80004a60 <piperead+0x68>
    if(killed(pr)){
    80004a3c:	8552                	mv	a0,s4
    80004a3e:	ffffe097          	auipc	ra,0xffffe
    80004a42:	8a8080e7          	jalr	-1880(ra) # 800022e6 <killed>
    80004a46:	e949                	bnez	a0,80004ad8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a48:	85a6                	mv	a1,s1
    80004a4a:	854e                	mv	a0,s3
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	5f2080e7          	jalr	1522(ra) # 8000203e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a54:	2184a703          	lw	a4,536(s1)
    80004a58:	21c4a783          	lw	a5,540(s1)
    80004a5c:	fcf70de3          	beq	a4,a5,80004a36 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a60:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a62:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a64:	05505463          	blez	s5,80004aac <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004a68:	2184a783          	lw	a5,536(s1)
    80004a6c:	21c4a703          	lw	a4,540(s1)
    80004a70:	02f70e63          	beq	a4,a5,80004aac <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a74:	0017871b          	addiw	a4,a5,1
    80004a78:	20e4ac23          	sw	a4,536(s1)
    80004a7c:	1ff7f793          	andi	a5,a5,511
    80004a80:	97a6                	add	a5,a5,s1
    80004a82:	0187c783          	lbu	a5,24(a5)
    80004a86:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a8a:	4685                	li	a3,1
    80004a8c:	fbf40613          	addi	a2,s0,-65
    80004a90:	85ca                	mv	a1,s2
    80004a92:	050a3503          	ld	a0,80(s4)
    80004a96:	ffffd097          	auipc	ra,0xffffd
    80004a9a:	bc0080e7          	jalr	-1088(ra) # 80001656 <copyout>
    80004a9e:	01650763          	beq	a0,s6,80004aac <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aa2:	2985                	addiw	s3,s3,1
    80004aa4:	0905                	addi	s2,s2,1
    80004aa6:	fd3a91e3          	bne	s5,s3,80004a68 <piperead+0x70>
    80004aaa:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004aac:	21c48513          	addi	a0,s1,540
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	5f2080e7          	jalr	1522(ra) # 800020a2 <wakeup>
  release(&pi->lock);
    80004ab8:	8526                	mv	a0,s1
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1cc080e7          	jalr	460(ra) # 80000c86 <release>
  return i;
}
    80004ac2:	854e                	mv	a0,s3
    80004ac4:	60a6                	ld	ra,72(sp)
    80004ac6:	6406                	ld	s0,64(sp)
    80004ac8:	74e2                	ld	s1,56(sp)
    80004aca:	7942                	ld	s2,48(sp)
    80004acc:	79a2                	ld	s3,40(sp)
    80004ace:	7a02                	ld	s4,32(sp)
    80004ad0:	6ae2                	ld	s5,24(sp)
    80004ad2:	6b42                	ld	s6,16(sp)
    80004ad4:	6161                	addi	sp,sp,80
    80004ad6:	8082                	ret
      release(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1ac080e7          	jalr	428(ra) # 80000c86 <release>
      return -1;
    80004ae2:	59fd                	li	s3,-1
    80004ae4:	bff9                	j	80004ac2 <piperead+0xca>

0000000080004ae6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ae6:	1141                	addi	sp,sp,-16
    80004ae8:	e422                	sd	s0,8(sp)
    80004aea:	0800                	addi	s0,sp,16
    80004aec:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004aee:	8905                	andi	a0,a0,1
    80004af0:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004af2:	8b89                	andi	a5,a5,2
    80004af4:	c399                	beqz	a5,80004afa <flags2perm+0x14>
      perm |= PTE_W;
    80004af6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004afa:	6422                	ld	s0,8(sp)
    80004afc:	0141                	addi	sp,sp,16
    80004afe:	8082                	ret

0000000080004b00 <exec>:

int
exec(char *path, char **argv)
{
    80004b00:	df010113          	addi	sp,sp,-528
    80004b04:	20113423          	sd	ra,520(sp)
    80004b08:	20813023          	sd	s0,512(sp)
    80004b0c:	ffa6                	sd	s1,504(sp)
    80004b0e:	fbca                	sd	s2,496(sp)
    80004b10:	f7ce                	sd	s3,488(sp)
    80004b12:	f3d2                	sd	s4,480(sp)
    80004b14:	efd6                	sd	s5,472(sp)
    80004b16:	ebda                	sd	s6,464(sp)
    80004b18:	e7de                	sd	s7,456(sp)
    80004b1a:	e3e2                	sd	s8,448(sp)
    80004b1c:	ff66                	sd	s9,440(sp)
    80004b1e:	fb6a                	sd	s10,432(sp)
    80004b20:	f76e                	sd	s11,424(sp)
    80004b22:	0c00                	addi	s0,sp,528
    80004b24:	892a                	mv	s2,a0
    80004b26:	dea43c23          	sd	a0,-520(s0)
    80004b2a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	e68080e7          	jalr	-408(ra) # 80001996 <myproc>
    80004b36:	84aa                	mv	s1,a0

  begin_op();
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	48e080e7          	jalr	1166(ra) # 80003fc6 <begin_op>

  if((ip = namei(path)) == 0){
    80004b40:	854a                	mv	a0,s2
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	284080e7          	jalr	644(ra) # 80003dc6 <namei>
    80004b4a:	c92d                	beqz	a0,80004bbc <exec+0xbc>
    80004b4c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	ad2080e7          	jalr	-1326(ra) # 80003620 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b56:	04000713          	li	a4,64
    80004b5a:	4681                	li	a3,0
    80004b5c:	e5040613          	addi	a2,s0,-432
    80004b60:	4581                	li	a1,0
    80004b62:	8552                	mv	a0,s4
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	d70080e7          	jalr	-656(ra) # 800038d4 <readi>
    80004b6c:	04000793          	li	a5,64
    80004b70:	00f51a63          	bne	a0,a5,80004b84 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004b74:	e5042703          	lw	a4,-432(s0)
    80004b78:	464c47b7          	lui	a5,0x464c4
    80004b7c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b80:	04f70463          	beq	a4,a5,80004bc8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b84:	8552                	mv	a0,s4
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	cfc080e7          	jalr	-772(ra) # 80003882 <iunlockput>
    end_op();
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	4b2080e7          	jalr	1202(ra) # 80004040 <end_op>
  }
  return -1;
    80004b96:	557d                	li	a0,-1
}
    80004b98:	20813083          	ld	ra,520(sp)
    80004b9c:	20013403          	ld	s0,512(sp)
    80004ba0:	74fe                	ld	s1,504(sp)
    80004ba2:	795e                	ld	s2,496(sp)
    80004ba4:	79be                	ld	s3,488(sp)
    80004ba6:	7a1e                	ld	s4,480(sp)
    80004ba8:	6afe                	ld	s5,472(sp)
    80004baa:	6b5e                	ld	s6,464(sp)
    80004bac:	6bbe                	ld	s7,456(sp)
    80004bae:	6c1e                	ld	s8,448(sp)
    80004bb0:	7cfa                	ld	s9,440(sp)
    80004bb2:	7d5a                	ld	s10,432(sp)
    80004bb4:	7dba                	ld	s11,424(sp)
    80004bb6:	21010113          	addi	sp,sp,528
    80004bba:	8082                	ret
    end_op();
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	484080e7          	jalr	1156(ra) # 80004040 <end_op>
    return -1;
    80004bc4:	557d                	li	a0,-1
    80004bc6:	bfc9                	j	80004b98 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	e90080e7          	jalr	-368(ra) # 80001a5a <proc_pagetable>
    80004bd2:	8b2a                	mv	s6,a0
    80004bd4:	d945                	beqz	a0,80004b84 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd6:	e7042d03          	lw	s10,-400(s0)
    80004bda:	e8845783          	lhu	a5,-376(s0)
    80004bde:	10078463          	beqz	a5,80004ce6 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004be2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004be4:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004be6:	6c85                	lui	s9,0x1
    80004be8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004bec:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004bf0:	6a85                	lui	s5,0x1
    80004bf2:	a0b5                	j	80004c5e <exec+0x15e>
      panic("loadseg: address should exist");
    80004bf4:	00004517          	auipc	a0,0x4
    80004bf8:	b0450513          	addi	a0,a0,-1276 # 800086f8 <syscalls+0x288>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	940080e7          	jalr	-1728(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004c04:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c06:	8726                	mv	a4,s1
    80004c08:	012c06bb          	addw	a3,s8,s2
    80004c0c:	4581                	li	a1,0
    80004c0e:	8552                	mv	a0,s4
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	cc4080e7          	jalr	-828(ra) # 800038d4 <readi>
    80004c18:	2501                	sext.w	a0,a0
    80004c1a:	24a49863          	bne	s1,a0,80004e6a <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004c1e:	012a893b          	addw	s2,s5,s2
    80004c22:	03397563          	bgeu	s2,s3,80004c4c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004c26:	02091593          	slli	a1,s2,0x20
    80004c2a:	9181                	srli	a1,a1,0x20
    80004c2c:	95de                	add	a1,a1,s7
    80004c2e:	855a                	mv	a0,s6
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	416080e7          	jalr	1046(ra) # 80001046 <walkaddr>
    80004c38:	862a                	mv	a2,a0
    if(pa == 0)
    80004c3a:	dd4d                	beqz	a0,80004bf4 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004c3c:	412984bb          	subw	s1,s3,s2
    80004c40:	0004879b          	sext.w	a5,s1
    80004c44:	fcfcf0e3          	bgeu	s9,a5,80004c04 <exec+0x104>
    80004c48:	84d6                	mv	s1,s5
    80004c4a:	bf6d                	j	80004c04 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004c4c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c50:	2d85                	addiw	s11,s11,1
    80004c52:	038d0d1b          	addiw	s10,s10,56
    80004c56:	e8845783          	lhu	a5,-376(s0)
    80004c5a:	08fdd763          	bge	s11,a5,80004ce8 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004c5e:	2d01                	sext.w	s10,s10
    80004c60:	03800713          	li	a4,56
    80004c64:	86ea                	mv	a3,s10
    80004c66:	e1840613          	addi	a2,s0,-488
    80004c6a:	4581                	li	a1,0
    80004c6c:	8552                	mv	a0,s4
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	c66080e7          	jalr	-922(ra) # 800038d4 <readi>
    80004c76:	03800793          	li	a5,56
    80004c7a:	1ef51663          	bne	a0,a5,80004e66 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004c7e:	e1842783          	lw	a5,-488(s0)
    80004c82:	4705                	li	a4,1
    80004c84:	fce796e3          	bne	a5,a4,80004c50 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004c88:	e4043483          	ld	s1,-448(s0)
    80004c8c:	e3843783          	ld	a5,-456(s0)
    80004c90:	1ef4e863          	bltu	s1,a5,80004e80 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004c94:	e2843783          	ld	a5,-472(s0)
    80004c98:	94be                	add	s1,s1,a5
    80004c9a:	1ef4e663          	bltu	s1,a5,80004e86 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004c9e:	df043703          	ld	a4,-528(s0)
    80004ca2:	8ff9                	and	a5,a5,a4
    80004ca4:	1e079463          	bnez	a5,80004e8c <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ca8:	e1c42503          	lw	a0,-484(s0)
    80004cac:	00000097          	auipc	ra,0x0
    80004cb0:	e3a080e7          	jalr	-454(ra) # 80004ae6 <flags2perm>
    80004cb4:	86aa                	mv	a3,a0
    80004cb6:	8626                	mv	a2,s1
    80004cb8:	85ca                	mv	a1,s2
    80004cba:	855a                	mv	a0,s6
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	73e080e7          	jalr	1854(ra) # 800013fa <uvmalloc>
    80004cc4:	e0a43423          	sd	a0,-504(s0)
    80004cc8:	1c050563          	beqz	a0,80004e92 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ccc:	e2843b83          	ld	s7,-472(s0)
    80004cd0:	e2042c03          	lw	s8,-480(s0)
    80004cd4:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004cd8:	00098463          	beqz	s3,80004ce0 <exec+0x1e0>
    80004cdc:	4901                	li	s2,0
    80004cde:	b7a1                	j	80004c26 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ce0:	e0843903          	ld	s2,-504(s0)
    80004ce4:	b7b5                	j	80004c50 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ce6:	4901                	li	s2,0
  iunlockput(ip);
    80004ce8:	8552                	mv	a0,s4
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	b98080e7          	jalr	-1128(ra) # 80003882 <iunlockput>
  end_op();
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	34e080e7          	jalr	846(ra) # 80004040 <end_op>
  p = myproc();
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	c9c080e7          	jalr	-868(ra) # 80001996 <myproc>
    80004d02:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d04:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004d08:	6985                	lui	s3,0x1
    80004d0a:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004d0c:	99ca                	add	s3,s3,s2
    80004d0e:	77fd                	lui	a5,0xfffff
    80004d10:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d14:	4691                	li	a3,4
    80004d16:	6609                	lui	a2,0x2
    80004d18:	964e                	add	a2,a2,s3
    80004d1a:	85ce                	mv	a1,s3
    80004d1c:	855a                	mv	a0,s6
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	6dc080e7          	jalr	1756(ra) # 800013fa <uvmalloc>
    80004d26:	892a                	mv	s2,a0
    80004d28:	e0a43423          	sd	a0,-504(s0)
    80004d2c:	e509                	bnez	a0,80004d36 <exec+0x236>
  if(pagetable)
    80004d2e:	e1343423          	sd	s3,-504(s0)
    80004d32:	4a01                	li	s4,0
    80004d34:	aa1d                	j	80004e6a <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d36:	75f9                	lui	a1,0xffffe
    80004d38:	95aa                	add	a1,a1,a0
    80004d3a:	855a                	mv	a0,s6
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	8e8080e7          	jalr	-1816(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d44:	7bfd                	lui	s7,0xfffff
    80004d46:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004d48:	e0043783          	ld	a5,-512(s0)
    80004d4c:	6388                	ld	a0,0(a5)
    80004d4e:	c52d                	beqz	a0,80004db8 <exec+0x2b8>
    80004d50:	e9040993          	addi	s3,s0,-368
    80004d54:	f9040c13          	addi	s8,s0,-112
    80004d58:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	0ee080e7          	jalr	238(ra) # 80000e48 <strlen>
    80004d62:	0015079b          	addiw	a5,a0,1
    80004d66:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d6a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d6e:	13796563          	bltu	s2,s7,80004e98 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d72:	e0043d03          	ld	s10,-512(s0)
    80004d76:	000d3a03          	ld	s4,0(s10)
    80004d7a:	8552                	mv	a0,s4
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	0cc080e7          	jalr	204(ra) # 80000e48 <strlen>
    80004d84:	0015069b          	addiw	a3,a0,1
    80004d88:	8652                	mv	a2,s4
    80004d8a:	85ca                	mv	a1,s2
    80004d8c:	855a                	mv	a0,s6
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	8c8080e7          	jalr	-1848(ra) # 80001656 <copyout>
    80004d96:	10054363          	bltz	a0,80004e9c <exec+0x39c>
    ustack[argc] = sp;
    80004d9a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d9e:	0485                	addi	s1,s1,1
    80004da0:	008d0793          	addi	a5,s10,8
    80004da4:	e0f43023          	sd	a5,-512(s0)
    80004da8:	008d3503          	ld	a0,8(s10)
    80004dac:	c909                	beqz	a0,80004dbe <exec+0x2be>
    if(argc >= MAXARG)
    80004dae:	09a1                	addi	s3,s3,8
    80004db0:	fb8995e3          	bne	s3,s8,80004d5a <exec+0x25a>
  ip = 0;
    80004db4:	4a01                	li	s4,0
    80004db6:	a855                	j	80004e6a <exec+0x36a>
  sp = sz;
    80004db8:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004dbc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dbe:	00349793          	slli	a5,s1,0x3
    80004dc2:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd220>
    80004dc6:	97a2                	add	a5,a5,s0
    80004dc8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dcc:	00148693          	addi	a3,s1,1
    80004dd0:	068e                	slli	a3,a3,0x3
    80004dd2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dd6:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004dda:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004dde:	f57968e3          	bltu	s2,s7,80004d2e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004de2:	e9040613          	addi	a2,s0,-368
    80004de6:	85ca                	mv	a1,s2
    80004de8:	855a                	mv	a0,s6
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	86c080e7          	jalr	-1940(ra) # 80001656 <copyout>
    80004df2:	0a054763          	bltz	a0,80004ea0 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004df6:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004dfa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dfe:	df843783          	ld	a5,-520(s0)
    80004e02:	0007c703          	lbu	a4,0(a5)
    80004e06:	cf11                	beqz	a4,80004e22 <exec+0x322>
    80004e08:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e0a:	02f00693          	li	a3,47
    80004e0e:	a039                	j	80004e1c <exec+0x31c>
      last = s+1;
    80004e10:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e14:	0785                	addi	a5,a5,1
    80004e16:	fff7c703          	lbu	a4,-1(a5)
    80004e1a:	c701                	beqz	a4,80004e22 <exec+0x322>
    if(*s == '/')
    80004e1c:	fed71ce3          	bne	a4,a3,80004e14 <exec+0x314>
    80004e20:	bfc5                	j	80004e10 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e22:	4641                	li	a2,16
    80004e24:	df843583          	ld	a1,-520(s0)
    80004e28:	158a8513          	addi	a0,s5,344
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	fea080e7          	jalr	-22(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e34:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e38:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004e3c:	e0843783          	ld	a5,-504(s0)
    80004e40:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e44:	058ab783          	ld	a5,88(s5)
    80004e48:	e6843703          	ld	a4,-408(s0)
    80004e4c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e4e:	058ab783          	ld	a5,88(s5)
    80004e52:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e56:	85e6                	mv	a1,s9
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	c9e080e7          	jalr	-866(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e60:	0004851b          	sext.w	a0,s1
    80004e64:	bb15                	j	80004b98 <exec+0x98>
    80004e66:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e6a:	e0843583          	ld	a1,-504(s0)
    80004e6e:	855a                	mv	a0,s6
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	c86080e7          	jalr	-890(ra) # 80001af6 <proc_freepagetable>
  return -1;
    80004e78:	557d                	li	a0,-1
  if(ip){
    80004e7a:	d00a0fe3          	beqz	s4,80004b98 <exec+0x98>
    80004e7e:	b319                	j	80004b84 <exec+0x84>
    80004e80:	e1243423          	sd	s2,-504(s0)
    80004e84:	b7dd                	j	80004e6a <exec+0x36a>
    80004e86:	e1243423          	sd	s2,-504(s0)
    80004e8a:	b7c5                	j	80004e6a <exec+0x36a>
    80004e8c:	e1243423          	sd	s2,-504(s0)
    80004e90:	bfe9                	j	80004e6a <exec+0x36a>
    80004e92:	e1243423          	sd	s2,-504(s0)
    80004e96:	bfd1                	j	80004e6a <exec+0x36a>
  ip = 0;
    80004e98:	4a01                	li	s4,0
    80004e9a:	bfc1                	j	80004e6a <exec+0x36a>
    80004e9c:	4a01                	li	s4,0
  if(pagetable)
    80004e9e:	b7f1                	j	80004e6a <exec+0x36a>
  sz = sz1;
    80004ea0:	e0843983          	ld	s3,-504(s0)
    80004ea4:	b569                	j	80004d2e <exec+0x22e>

0000000080004ea6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ea6:	7179                	addi	sp,sp,-48
    80004ea8:	f406                	sd	ra,40(sp)
    80004eaa:	f022                	sd	s0,32(sp)
    80004eac:	ec26                	sd	s1,24(sp)
    80004eae:	e84a                	sd	s2,16(sp)
    80004eb0:	1800                	addi	s0,sp,48
    80004eb2:	892e                	mv	s2,a1
    80004eb4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004eb6:	fdc40593          	addi	a1,s0,-36
    80004eba:	ffffe097          	auipc	ra,0xffffe
    80004ebe:	bf6080e7          	jalr	-1034(ra) # 80002ab0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ec2:	fdc42703          	lw	a4,-36(s0)
    80004ec6:	47bd                	li	a5,15
    80004ec8:	02e7eb63          	bltu	a5,a4,80004efe <argfd+0x58>
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	aca080e7          	jalr	-1334(ra) # 80001996 <myproc>
    80004ed4:	fdc42703          	lw	a4,-36(s0)
    80004ed8:	01a70793          	addi	a5,a4,26
    80004edc:	078e                	slli	a5,a5,0x3
    80004ede:	953e                	add	a0,a0,a5
    80004ee0:	611c                	ld	a5,0(a0)
    80004ee2:	c385                	beqz	a5,80004f02 <argfd+0x5c>
    return -1;
  if(pfd)
    80004ee4:	00090463          	beqz	s2,80004eec <argfd+0x46>
    *pfd = fd;
    80004ee8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004eec:	4501                	li	a0,0
  if(pf)
    80004eee:	c091                	beqz	s1,80004ef2 <argfd+0x4c>
    *pf = f;
    80004ef0:	e09c                	sd	a5,0(s1)
}
    80004ef2:	70a2                	ld	ra,40(sp)
    80004ef4:	7402                	ld	s0,32(sp)
    80004ef6:	64e2                	ld	s1,24(sp)
    80004ef8:	6942                	ld	s2,16(sp)
    80004efa:	6145                	addi	sp,sp,48
    80004efc:	8082                	ret
    return -1;
    80004efe:	557d                	li	a0,-1
    80004f00:	bfcd                	j	80004ef2 <argfd+0x4c>
    80004f02:	557d                	li	a0,-1
    80004f04:	b7fd                	j	80004ef2 <argfd+0x4c>

0000000080004f06 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f06:	1101                	addi	sp,sp,-32
    80004f08:	ec06                	sd	ra,24(sp)
    80004f0a:	e822                	sd	s0,16(sp)
    80004f0c:	e426                	sd	s1,8(sp)
    80004f0e:	1000                	addi	s0,sp,32
    80004f10:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	a84080e7          	jalr	-1404(ra) # 80001996 <myproc>
    80004f1a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f1c:	0d050793          	addi	a5,a0,208
    80004f20:	4501                	li	a0,0
    80004f22:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f24:	6398                	ld	a4,0(a5)
    80004f26:	cb19                	beqz	a4,80004f3c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f28:	2505                	addiw	a0,a0,1
    80004f2a:	07a1                	addi	a5,a5,8
    80004f2c:	fed51ce3          	bne	a0,a3,80004f24 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f30:	557d                	li	a0,-1
}
    80004f32:	60e2                	ld	ra,24(sp)
    80004f34:	6442                	ld	s0,16(sp)
    80004f36:	64a2                	ld	s1,8(sp)
    80004f38:	6105                	addi	sp,sp,32
    80004f3a:	8082                	ret
      p->ofile[fd] = f;
    80004f3c:	01a50793          	addi	a5,a0,26
    80004f40:	078e                	slli	a5,a5,0x3
    80004f42:	963e                	add	a2,a2,a5
    80004f44:	e204                	sd	s1,0(a2)
      return fd;
    80004f46:	b7f5                	j	80004f32 <fdalloc+0x2c>

0000000080004f48 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f48:	715d                	addi	sp,sp,-80
    80004f4a:	e486                	sd	ra,72(sp)
    80004f4c:	e0a2                	sd	s0,64(sp)
    80004f4e:	fc26                	sd	s1,56(sp)
    80004f50:	f84a                	sd	s2,48(sp)
    80004f52:	f44e                	sd	s3,40(sp)
    80004f54:	f052                	sd	s4,32(sp)
    80004f56:	ec56                	sd	s5,24(sp)
    80004f58:	e85a                	sd	s6,16(sp)
    80004f5a:	0880                	addi	s0,sp,80
    80004f5c:	8b2e                	mv	s6,a1
    80004f5e:	89b2                	mv	s3,a2
    80004f60:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f62:	fb040593          	addi	a1,s0,-80
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	e7e080e7          	jalr	-386(ra) # 80003de4 <nameiparent>
    80004f6e:	84aa                	mv	s1,a0
    80004f70:	14050b63          	beqz	a0,800050c6 <create+0x17e>
    return 0;

  ilock(dp);
    80004f74:	ffffe097          	auipc	ra,0xffffe
    80004f78:	6ac080e7          	jalr	1708(ra) # 80003620 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f7c:	4601                	li	a2,0
    80004f7e:	fb040593          	addi	a1,s0,-80
    80004f82:	8526                	mv	a0,s1
    80004f84:	fffff097          	auipc	ra,0xfffff
    80004f88:	b80080e7          	jalr	-1152(ra) # 80003b04 <dirlookup>
    80004f8c:	8aaa                	mv	s5,a0
    80004f8e:	c921                	beqz	a0,80004fde <create+0x96>
    iunlockput(dp);
    80004f90:	8526                	mv	a0,s1
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	8f0080e7          	jalr	-1808(ra) # 80003882 <iunlockput>
    ilock(ip);
    80004f9a:	8556                	mv	a0,s5
    80004f9c:	ffffe097          	auipc	ra,0xffffe
    80004fa0:	684080e7          	jalr	1668(ra) # 80003620 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fa4:	4789                	li	a5,2
    80004fa6:	02fb1563          	bne	s6,a5,80004fd0 <create+0x88>
    80004faa:	044ad783          	lhu	a5,68(s5)
    80004fae:	37f9                	addiw	a5,a5,-2
    80004fb0:	17c2                	slli	a5,a5,0x30
    80004fb2:	93c1                	srli	a5,a5,0x30
    80004fb4:	4705                	li	a4,1
    80004fb6:	00f76d63          	bltu	a4,a5,80004fd0 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004fba:	8556                	mv	a0,s5
    80004fbc:	60a6                	ld	ra,72(sp)
    80004fbe:	6406                	ld	s0,64(sp)
    80004fc0:	74e2                	ld	s1,56(sp)
    80004fc2:	7942                	ld	s2,48(sp)
    80004fc4:	79a2                	ld	s3,40(sp)
    80004fc6:	7a02                	ld	s4,32(sp)
    80004fc8:	6ae2                	ld	s5,24(sp)
    80004fca:	6b42                	ld	s6,16(sp)
    80004fcc:	6161                	addi	sp,sp,80
    80004fce:	8082                	ret
    iunlockput(ip);
    80004fd0:	8556                	mv	a0,s5
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	8b0080e7          	jalr	-1872(ra) # 80003882 <iunlockput>
    return 0;
    80004fda:	4a81                	li	s5,0
    80004fdc:	bff9                	j	80004fba <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80004fde:	85da                	mv	a1,s6
    80004fe0:	4088                	lw	a0,0(s1)
    80004fe2:	ffffe097          	auipc	ra,0xffffe
    80004fe6:	4a6080e7          	jalr	1190(ra) # 80003488 <ialloc>
    80004fea:	8a2a                	mv	s4,a0
    80004fec:	c529                	beqz	a0,80005036 <create+0xee>
  ilock(ip);
    80004fee:	ffffe097          	auipc	ra,0xffffe
    80004ff2:	632080e7          	jalr	1586(ra) # 80003620 <ilock>
  ip->major = major;
    80004ff6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004ffa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004ffe:	4905                	li	s2,1
    80005000:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005004:	8552                	mv	a0,s4
    80005006:	ffffe097          	auipc	ra,0xffffe
    8000500a:	54e080e7          	jalr	1358(ra) # 80003554 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000500e:	032b0b63          	beq	s6,s2,80005044 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005012:	004a2603          	lw	a2,4(s4)
    80005016:	fb040593          	addi	a1,s0,-80
    8000501a:	8526                	mv	a0,s1
    8000501c:	fffff097          	auipc	ra,0xfffff
    80005020:	cf8080e7          	jalr	-776(ra) # 80003d14 <dirlink>
    80005024:	06054f63          	bltz	a0,800050a2 <create+0x15a>
  iunlockput(dp);
    80005028:	8526                	mv	a0,s1
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	858080e7          	jalr	-1960(ra) # 80003882 <iunlockput>
  return ip;
    80005032:	8ad2                	mv	s5,s4
    80005034:	b759                	j	80004fba <create+0x72>
    iunlockput(dp);
    80005036:	8526                	mv	a0,s1
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	84a080e7          	jalr	-1974(ra) # 80003882 <iunlockput>
    return 0;
    80005040:	8ad2                	mv	s5,s4
    80005042:	bfa5                	j	80004fba <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005044:	004a2603          	lw	a2,4(s4)
    80005048:	00003597          	auipc	a1,0x3
    8000504c:	6d058593          	addi	a1,a1,1744 # 80008718 <syscalls+0x2a8>
    80005050:	8552                	mv	a0,s4
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	cc2080e7          	jalr	-830(ra) # 80003d14 <dirlink>
    8000505a:	04054463          	bltz	a0,800050a2 <create+0x15a>
    8000505e:	40d0                	lw	a2,4(s1)
    80005060:	00003597          	auipc	a1,0x3
    80005064:	6c058593          	addi	a1,a1,1728 # 80008720 <syscalls+0x2b0>
    80005068:	8552                	mv	a0,s4
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	caa080e7          	jalr	-854(ra) # 80003d14 <dirlink>
    80005072:	02054863          	bltz	a0,800050a2 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005076:	004a2603          	lw	a2,4(s4)
    8000507a:	fb040593          	addi	a1,s0,-80
    8000507e:	8526                	mv	a0,s1
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	c94080e7          	jalr	-876(ra) # 80003d14 <dirlink>
    80005088:	00054d63          	bltz	a0,800050a2 <create+0x15a>
    dp->nlink++;  // for ".."
    8000508c:	04a4d783          	lhu	a5,74(s1)
    80005090:	2785                	addiw	a5,a5,1
    80005092:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	4bc080e7          	jalr	1212(ra) # 80003554 <iupdate>
    800050a0:	b761                	j	80005028 <create+0xe0>
  ip->nlink = 0;
    800050a2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800050a6:	8552                	mv	a0,s4
    800050a8:	ffffe097          	auipc	ra,0xffffe
    800050ac:	4ac080e7          	jalr	1196(ra) # 80003554 <iupdate>
  iunlockput(ip);
    800050b0:	8552                	mv	a0,s4
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	7d0080e7          	jalr	2000(ra) # 80003882 <iunlockput>
  iunlockput(dp);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffe097          	auipc	ra,0xffffe
    800050c0:	7c6080e7          	jalr	1990(ra) # 80003882 <iunlockput>
  return 0;
    800050c4:	bddd                	j	80004fba <create+0x72>
    return 0;
    800050c6:	8aaa                	mv	s5,a0
    800050c8:	bdcd                	j	80004fba <create+0x72>

00000000800050ca <sys_dup>:
{
    800050ca:	7179                	addi	sp,sp,-48
    800050cc:	f406                	sd	ra,40(sp)
    800050ce:	f022                	sd	s0,32(sp)
    800050d0:	ec26                	sd	s1,24(sp)
    800050d2:	e84a                	sd	s2,16(sp)
    800050d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050d6:	fd840613          	addi	a2,s0,-40
    800050da:	4581                	li	a1,0
    800050dc:	4501                	li	a0,0
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	dc8080e7          	jalr	-568(ra) # 80004ea6 <argfd>
    return -1;
    800050e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050e8:	02054363          	bltz	a0,8000510e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800050ec:	fd843903          	ld	s2,-40(s0)
    800050f0:	854a                	mv	a0,s2
    800050f2:	00000097          	auipc	ra,0x0
    800050f6:	e14080e7          	jalr	-492(ra) # 80004f06 <fdalloc>
    800050fa:	84aa                	mv	s1,a0
    return -1;
    800050fc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050fe:	00054863          	bltz	a0,8000510e <sys_dup+0x44>
  filedup(f);
    80005102:	854a                	mv	a0,s2
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	334080e7          	jalr	820(ra) # 80004438 <filedup>
  return fd;
    8000510c:	87a6                	mv	a5,s1
}
    8000510e:	853e                	mv	a0,a5
    80005110:	70a2                	ld	ra,40(sp)
    80005112:	7402                	ld	s0,32(sp)
    80005114:	64e2                	ld	s1,24(sp)
    80005116:	6942                	ld	s2,16(sp)
    80005118:	6145                	addi	sp,sp,48
    8000511a:	8082                	ret

000000008000511c <sys_read>:
{
    8000511c:	7179                	addi	sp,sp,-48
    8000511e:	f406                	sd	ra,40(sp)
    80005120:	f022                	sd	s0,32(sp)
    80005122:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005124:	fd840593          	addi	a1,s0,-40
    80005128:	4505                	li	a0,1
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	9a6080e7          	jalr	-1626(ra) # 80002ad0 <argaddr>
  argint(2, &n);
    80005132:	fe440593          	addi	a1,s0,-28
    80005136:	4509                	li	a0,2
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	978080e7          	jalr	-1672(ra) # 80002ab0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005140:	fe840613          	addi	a2,s0,-24
    80005144:	4581                	li	a1,0
    80005146:	4501                	li	a0,0
    80005148:	00000097          	auipc	ra,0x0
    8000514c:	d5e080e7          	jalr	-674(ra) # 80004ea6 <argfd>
    80005150:	87aa                	mv	a5,a0
    return -1;
    80005152:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005154:	0007cc63          	bltz	a5,8000516c <sys_read+0x50>
  return fileread(f, p, n);
    80005158:	fe442603          	lw	a2,-28(s0)
    8000515c:	fd843583          	ld	a1,-40(s0)
    80005160:	fe843503          	ld	a0,-24(s0)
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	460080e7          	jalr	1120(ra) # 800045c4 <fileread>
}
    8000516c:	70a2                	ld	ra,40(sp)
    8000516e:	7402                	ld	s0,32(sp)
    80005170:	6145                	addi	sp,sp,48
    80005172:	8082                	ret

0000000080005174 <sys_write>:
{
    80005174:	7179                	addi	sp,sp,-48
    80005176:	f406                	sd	ra,40(sp)
    80005178:	f022                	sd	s0,32(sp)
    8000517a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000517c:	fd840593          	addi	a1,s0,-40
    80005180:	4505                	li	a0,1
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	94e080e7          	jalr	-1714(ra) # 80002ad0 <argaddr>
  argint(2, &n);
    8000518a:	fe440593          	addi	a1,s0,-28
    8000518e:	4509                	li	a0,2
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	920080e7          	jalr	-1760(ra) # 80002ab0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005198:	fe840613          	addi	a2,s0,-24
    8000519c:	4581                	li	a1,0
    8000519e:	4501                	li	a0,0
    800051a0:	00000097          	auipc	ra,0x0
    800051a4:	d06080e7          	jalr	-762(ra) # 80004ea6 <argfd>
    800051a8:	87aa                	mv	a5,a0
    return -1;
    800051aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800051ac:	0007cc63          	bltz	a5,800051c4 <sys_write+0x50>
  return filewrite(f, p, n);
    800051b0:	fe442603          	lw	a2,-28(s0)
    800051b4:	fd843583          	ld	a1,-40(s0)
    800051b8:	fe843503          	ld	a0,-24(s0)
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	4ca080e7          	jalr	1226(ra) # 80004686 <filewrite>
}
    800051c4:	70a2                	ld	ra,40(sp)
    800051c6:	7402                	ld	s0,32(sp)
    800051c8:	6145                	addi	sp,sp,48
    800051ca:	8082                	ret

00000000800051cc <sys_close>:
{
    800051cc:	1101                	addi	sp,sp,-32
    800051ce:	ec06                	sd	ra,24(sp)
    800051d0:	e822                	sd	s0,16(sp)
    800051d2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051d4:	fe040613          	addi	a2,s0,-32
    800051d8:	fec40593          	addi	a1,s0,-20
    800051dc:	4501                	li	a0,0
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	cc8080e7          	jalr	-824(ra) # 80004ea6 <argfd>
    return -1;
    800051e6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051e8:	02054463          	bltz	a0,80005210 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	7aa080e7          	jalr	1962(ra) # 80001996 <myproc>
    800051f4:	fec42783          	lw	a5,-20(s0)
    800051f8:	07e9                	addi	a5,a5,26
    800051fa:	078e                	slli	a5,a5,0x3
    800051fc:	953e                	add	a0,a0,a5
    800051fe:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005202:	fe043503          	ld	a0,-32(s0)
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	284080e7          	jalr	644(ra) # 8000448a <fileclose>
  return 0;
    8000520e:	4781                	li	a5,0
}
    80005210:	853e                	mv	a0,a5
    80005212:	60e2                	ld	ra,24(sp)
    80005214:	6442                	ld	s0,16(sp)
    80005216:	6105                	addi	sp,sp,32
    80005218:	8082                	ret

000000008000521a <sys_fstat>:
{
    8000521a:	1101                	addi	sp,sp,-32
    8000521c:	ec06                	sd	ra,24(sp)
    8000521e:	e822                	sd	s0,16(sp)
    80005220:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005222:	fe040593          	addi	a1,s0,-32
    80005226:	4505                	li	a0,1
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	8a8080e7          	jalr	-1880(ra) # 80002ad0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005230:	fe840613          	addi	a2,s0,-24
    80005234:	4581                	li	a1,0
    80005236:	4501                	li	a0,0
    80005238:	00000097          	auipc	ra,0x0
    8000523c:	c6e080e7          	jalr	-914(ra) # 80004ea6 <argfd>
    80005240:	87aa                	mv	a5,a0
    return -1;
    80005242:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005244:	0007ca63          	bltz	a5,80005258 <sys_fstat+0x3e>
  return filestat(f, st);
    80005248:	fe043583          	ld	a1,-32(s0)
    8000524c:	fe843503          	ld	a0,-24(s0)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	302080e7          	jalr	770(ra) # 80004552 <filestat>
}
    80005258:	60e2                	ld	ra,24(sp)
    8000525a:	6442                	ld	s0,16(sp)
    8000525c:	6105                	addi	sp,sp,32
    8000525e:	8082                	ret

0000000080005260 <sys_link>:
{
    80005260:	7169                	addi	sp,sp,-304
    80005262:	f606                	sd	ra,296(sp)
    80005264:	f222                	sd	s0,288(sp)
    80005266:	ee26                	sd	s1,280(sp)
    80005268:	ea4a                	sd	s2,272(sp)
    8000526a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000526c:	08000613          	li	a2,128
    80005270:	ed040593          	addi	a1,s0,-304
    80005274:	4501                	li	a0,0
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	87a080e7          	jalr	-1926(ra) # 80002af0 <argstr>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005280:	10054e63          	bltz	a0,8000539c <sys_link+0x13c>
    80005284:	08000613          	li	a2,128
    80005288:	f5040593          	addi	a1,s0,-176
    8000528c:	4505                	li	a0,1
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	862080e7          	jalr	-1950(ra) # 80002af0 <argstr>
    return -1;
    80005296:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005298:	10054263          	bltz	a0,8000539c <sys_link+0x13c>
  begin_op();
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	d2a080e7          	jalr	-726(ra) # 80003fc6 <begin_op>
  if((ip = namei(old)) == 0){
    800052a4:	ed040513          	addi	a0,s0,-304
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	b1e080e7          	jalr	-1250(ra) # 80003dc6 <namei>
    800052b0:	84aa                	mv	s1,a0
    800052b2:	c551                	beqz	a0,8000533e <sys_link+0xde>
  ilock(ip);
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	36c080e7          	jalr	876(ra) # 80003620 <ilock>
  if(ip->type == T_DIR){
    800052bc:	04449703          	lh	a4,68(s1)
    800052c0:	4785                	li	a5,1
    800052c2:	08f70463          	beq	a4,a5,8000534a <sys_link+0xea>
  ip->nlink++;
    800052c6:	04a4d783          	lhu	a5,74(s1)
    800052ca:	2785                	addiw	a5,a5,1
    800052cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	282080e7          	jalr	642(ra) # 80003554 <iupdate>
  iunlock(ip);
    800052da:	8526                	mv	a0,s1
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	406080e7          	jalr	1030(ra) # 800036e2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052e4:	fd040593          	addi	a1,s0,-48
    800052e8:	f5040513          	addi	a0,s0,-176
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	af8080e7          	jalr	-1288(ra) # 80003de4 <nameiparent>
    800052f4:	892a                	mv	s2,a0
    800052f6:	c935                	beqz	a0,8000536a <sys_link+0x10a>
  ilock(dp);
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	328080e7          	jalr	808(ra) # 80003620 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005300:	00092703          	lw	a4,0(s2)
    80005304:	409c                	lw	a5,0(s1)
    80005306:	04f71d63          	bne	a4,a5,80005360 <sys_link+0x100>
    8000530a:	40d0                	lw	a2,4(s1)
    8000530c:	fd040593          	addi	a1,s0,-48
    80005310:	854a                	mv	a0,s2
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	a02080e7          	jalr	-1534(ra) # 80003d14 <dirlink>
    8000531a:	04054363          	bltz	a0,80005360 <sys_link+0x100>
  iunlockput(dp);
    8000531e:	854a                	mv	a0,s2
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	562080e7          	jalr	1378(ra) # 80003882 <iunlockput>
  iput(ip);
    80005328:	8526                	mv	a0,s1
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	4b0080e7          	jalr	1200(ra) # 800037da <iput>
  end_op();
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	d0e080e7          	jalr	-754(ra) # 80004040 <end_op>
  return 0;
    8000533a:	4781                	li	a5,0
    8000533c:	a085                	j	8000539c <sys_link+0x13c>
    end_op();
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	d02080e7          	jalr	-766(ra) # 80004040 <end_op>
    return -1;
    80005346:	57fd                	li	a5,-1
    80005348:	a891                	j	8000539c <sys_link+0x13c>
    iunlockput(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	536080e7          	jalr	1334(ra) # 80003882 <iunlockput>
    end_op();
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	cec080e7          	jalr	-788(ra) # 80004040 <end_op>
    return -1;
    8000535c:	57fd                	li	a5,-1
    8000535e:	a83d                	j	8000539c <sys_link+0x13c>
    iunlockput(dp);
    80005360:	854a                	mv	a0,s2
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	520080e7          	jalr	1312(ra) # 80003882 <iunlockput>
  ilock(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	2b4080e7          	jalr	692(ra) # 80003620 <ilock>
  ip->nlink--;
    80005374:	04a4d783          	lhu	a5,74(s1)
    80005378:	37fd                	addiw	a5,a5,-1
    8000537a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537e:	8526                	mv	a0,s1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	1d4080e7          	jalr	468(ra) # 80003554 <iupdate>
  iunlockput(ip);
    80005388:	8526                	mv	a0,s1
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	4f8080e7          	jalr	1272(ra) # 80003882 <iunlockput>
  end_op();
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	cae080e7          	jalr	-850(ra) # 80004040 <end_op>
  return -1;
    8000539a:	57fd                	li	a5,-1
}
    8000539c:	853e                	mv	a0,a5
    8000539e:	70b2                	ld	ra,296(sp)
    800053a0:	7412                	ld	s0,288(sp)
    800053a2:	64f2                	ld	s1,280(sp)
    800053a4:	6952                	ld	s2,272(sp)
    800053a6:	6155                	addi	sp,sp,304
    800053a8:	8082                	ret

00000000800053aa <sys_unlink>:
{
    800053aa:	7151                	addi	sp,sp,-240
    800053ac:	f586                	sd	ra,232(sp)
    800053ae:	f1a2                	sd	s0,224(sp)
    800053b0:	eda6                	sd	s1,216(sp)
    800053b2:	e9ca                	sd	s2,208(sp)
    800053b4:	e5ce                	sd	s3,200(sp)
    800053b6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053b8:	08000613          	li	a2,128
    800053bc:	f3040593          	addi	a1,s0,-208
    800053c0:	4501                	li	a0,0
    800053c2:	ffffd097          	auipc	ra,0xffffd
    800053c6:	72e080e7          	jalr	1838(ra) # 80002af0 <argstr>
    800053ca:	18054163          	bltz	a0,8000554c <sys_unlink+0x1a2>
  begin_op();
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	bf8080e7          	jalr	-1032(ra) # 80003fc6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053d6:	fb040593          	addi	a1,s0,-80
    800053da:	f3040513          	addi	a0,s0,-208
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	a06080e7          	jalr	-1530(ra) # 80003de4 <nameiparent>
    800053e6:	84aa                	mv	s1,a0
    800053e8:	c979                	beqz	a0,800054be <sys_unlink+0x114>
  ilock(dp);
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	236080e7          	jalr	566(ra) # 80003620 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053f2:	00003597          	auipc	a1,0x3
    800053f6:	32658593          	addi	a1,a1,806 # 80008718 <syscalls+0x2a8>
    800053fa:	fb040513          	addi	a0,s0,-80
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	6ec080e7          	jalr	1772(ra) # 80003aea <namecmp>
    80005406:	14050a63          	beqz	a0,8000555a <sys_unlink+0x1b0>
    8000540a:	00003597          	auipc	a1,0x3
    8000540e:	31658593          	addi	a1,a1,790 # 80008720 <syscalls+0x2b0>
    80005412:	fb040513          	addi	a0,s0,-80
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	6d4080e7          	jalr	1748(ra) # 80003aea <namecmp>
    8000541e:	12050e63          	beqz	a0,8000555a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005422:	f2c40613          	addi	a2,s0,-212
    80005426:	fb040593          	addi	a1,s0,-80
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	6d8080e7          	jalr	1752(ra) # 80003b04 <dirlookup>
    80005434:	892a                	mv	s2,a0
    80005436:	12050263          	beqz	a0,8000555a <sys_unlink+0x1b0>
  ilock(ip);
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	1e6080e7          	jalr	486(ra) # 80003620 <ilock>
  if(ip->nlink < 1)
    80005442:	04a91783          	lh	a5,74(s2)
    80005446:	08f05263          	blez	a5,800054ca <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000544a:	04491703          	lh	a4,68(s2)
    8000544e:	4785                	li	a5,1
    80005450:	08f70563          	beq	a4,a5,800054da <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005454:	4641                	li	a2,16
    80005456:	4581                	li	a1,0
    80005458:	fc040513          	addi	a0,s0,-64
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	872080e7          	jalr	-1934(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005464:	4741                	li	a4,16
    80005466:	f2c42683          	lw	a3,-212(s0)
    8000546a:	fc040613          	addi	a2,s0,-64
    8000546e:	4581                	li	a1,0
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	55a080e7          	jalr	1370(ra) # 800039cc <writei>
    8000547a:	47c1                	li	a5,16
    8000547c:	0af51563          	bne	a0,a5,80005526 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005480:	04491703          	lh	a4,68(s2)
    80005484:	4785                	li	a5,1
    80005486:	0af70863          	beq	a4,a5,80005536 <sys_unlink+0x18c>
  iunlockput(dp);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	3f6080e7          	jalr	1014(ra) # 80003882 <iunlockput>
  ip->nlink--;
    80005494:	04a95783          	lhu	a5,74(s2)
    80005498:	37fd                	addiw	a5,a5,-1
    8000549a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000549e:	854a                	mv	a0,s2
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	0b4080e7          	jalr	180(ra) # 80003554 <iupdate>
  iunlockput(ip);
    800054a8:	854a                	mv	a0,s2
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	3d8080e7          	jalr	984(ra) # 80003882 <iunlockput>
  end_op();
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	b8e080e7          	jalr	-1138(ra) # 80004040 <end_op>
  return 0;
    800054ba:	4501                	li	a0,0
    800054bc:	a84d                	j	8000556e <sys_unlink+0x1c4>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	b82080e7          	jalr	-1150(ra) # 80004040 <end_op>
    return -1;
    800054c6:	557d                	li	a0,-1
    800054c8:	a05d                	j	8000556e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054ca:	00003517          	auipc	a0,0x3
    800054ce:	25e50513          	addi	a0,a0,606 # 80008728 <syscalls+0x2b8>
    800054d2:	ffffb097          	auipc	ra,0xffffb
    800054d6:	06a080e7          	jalr	106(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054da:	04c92703          	lw	a4,76(s2)
    800054de:	02000793          	li	a5,32
    800054e2:	f6e7f9e3          	bgeu	a5,a4,80005454 <sys_unlink+0xaa>
    800054e6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ea:	4741                	li	a4,16
    800054ec:	86ce                	mv	a3,s3
    800054ee:	f1840613          	addi	a2,s0,-232
    800054f2:	4581                	li	a1,0
    800054f4:	854a                	mv	a0,s2
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	3de080e7          	jalr	990(ra) # 800038d4 <readi>
    800054fe:	47c1                	li	a5,16
    80005500:	00f51b63          	bne	a0,a5,80005516 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005504:	f1845783          	lhu	a5,-232(s0)
    80005508:	e7a1                	bnez	a5,80005550 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000550a:	29c1                	addiw	s3,s3,16
    8000550c:	04c92783          	lw	a5,76(s2)
    80005510:	fcf9ede3          	bltu	s3,a5,800054ea <sys_unlink+0x140>
    80005514:	b781                	j	80005454 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005516:	00003517          	auipc	a0,0x3
    8000551a:	22a50513          	addi	a0,a0,554 # 80008740 <syscalls+0x2d0>
    8000551e:	ffffb097          	auipc	ra,0xffffb
    80005522:	01e080e7          	jalr	30(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005526:	00003517          	auipc	a0,0x3
    8000552a:	23250513          	addi	a0,a0,562 # 80008758 <syscalls+0x2e8>
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	00e080e7          	jalr	14(ra) # 8000053c <panic>
    dp->nlink--;
    80005536:	04a4d783          	lhu	a5,74(s1)
    8000553a:	37fd                	addiw	a5,a5,-1
    8000553c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	012080e7          	jalr	18(ra) # 80003554 <iupdate>
    8000554a:	b781                	j	8000548a <sys_unlink+0xe0>
    return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	a005                	j	8000556e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005550:	854a                	mv	a0,s2
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	330080e7          	jalr	816(ra) # 80003882 <iunlockput>
  iunlockput(dp);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	326080e7          	jalr	806(ra) # 80003882 <iunlockput>
  end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	adc080e7          	jalr	-1316(ra) # 80004040 <end_op>
  return -1;
    8000556c:	557d                	li	a0,-1
}
    8000556e:	70ae                	ld	ra,232(sp)
    80005570:	740e                	ld	s0,224(sp)
    80005572:	64ee                	ld	s1,216(sp)
    80005574:	694e                	ld	s2,208(sp)
    80005576:	69ae                	ld	s3,200(sp)
    80005578:	616d                	addi	sp,sp,240
    8000557a:	8082                	ret

000000008000557c <sys_open>:

uint64
sys_open(void)
{
    8000557c:	7131                	addi	sp,sp,-192
    8000557e:	fd06                	sd	ra,184(sp)
    80005580:	f922                	sd	s0,176(sp)
    80005582:	f526                	sd	s1,168(sp)
    80005584:	f14a                	sd	s2,160(sp)
    80005586:	ed4e                	sd	s3,152(sp)
    80005588:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000558a:	f4c40593          	addi	a1,s0,-180
    8000558e:	4505                	li	a0,1
    80005590:	ffffd097          	auipc	ra,0xffffd
    80005594:	520080e7          	jalr	1312(ra) # 80002ab0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005598:	08000613          	li	a2,128
    8000559c:	f5040593          	addi	a1,s0,-176
    800055a0:	4501                	li	a0,0
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	54e080e7          	jalr	1358(ra) # 80002af0 <argstr>
    800055aa:	87aa                	mv	a5,a0
    return -1;
    800055ac:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800055ae:	0a07c863          	bltz	a5,8000565e <sys_open+0xe2>

  begin_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	a14080e7          	jalr	-1516(ra) # 80003fc6 <begin_op>

  if(omode & O_CREATE){
    800055ba:	f4c42783          	lw	a5,-180(s0)
    800055be:	2007f793          	andi	a5,a5,512
    800055c2:	cbdd                	beqz	a5,80005678 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800055c4:	4681                	li	a3,0
    800055c6:	4601                	li	a2,0
    800055c8:	4589                	li	a1,2
    800055ca:	f5040513          	addi	a0,s0,-176
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	97a080e7          	jalr	-1670(ra) # 80004f48 <create>
    800055d6:	84aa                	mv	s1,a0
    if(ip == 0){
    800055d8:	c951                	beqz	a0,8000566c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055da:	04449703          	lh	a4,68(s1)
    800055de:	478d                	li	a5,3
    800055e0:	00f71763          	bne	a4,a5,800055ee <sys_open+0x72>
    800055e4:	0464d703          	lhu	a4,70(s1)
    800055e8:	47a5                	li	a5,9
    800055ea:	0ce7ec63          	bltu	a5,a4,800056c2 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	de0080e7          	jalr	-544(ra) # 800043ce <filealloc>
    800055f6:	892a                	mv	s2,a0
    800055f8:	c56d                	beqz	a0,800056e2 <sys_open+0x166>
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	90c080e7          	jalr	-1780(ra) # 80004f06 <fdalloc>
    80005602:	89aa                	mv	s3,a0
    80005604:	0c054a63          	bltz	a0,800056d8 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005608:	04449703          	lh	a4,68(s1)
    8000560c:	478d                	li	a5,3
    8000560e:	0ef70563          	beq	a4,a5,800056f8 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005612:	4789                	li	a5,2
    80005614:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005618:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000561c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005620:	f4c42783          	lw	a5,-180(s0)
    80005624:	0017c713          	xori	a4,a5,1
    80005628:	8b05                	andi	a4,a4,1
    8000562a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000562e:	0037f713          	andi	a4,a5,3
    80005632:	00e03733          	snez	a4,a4
    80005636:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000563a:	4007f793          	andi	a5,a5,1024
    8000563e:	c791                	beqz	a5,8000564a <sys_open+0xce>
    80005640:	04449703          	lh	a4,68(s1)
    80005644:	4789                	li	a5,2
    80005646:	0cf70063          	beq	a4,a5,80005706 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	096080e7          	jalr	150(ra) # 800036e2 <iunlock>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	9ec080e7          	jalr	-1556(ra) # 80004040 <end_op>

  return fd;
    8000565c:	854e                	mv	a0,s3
}
    8000565e:	70ea                	ld	ra,184(sp)
    80005660:	744a                	ld	s0,176(sp)
    80005662:	74aa                	ld	s1,168(sp)
    80005664:	790a                	ld	s2,160(sp)
    80005666:	69ea                	ld	s3,152(sp)
    80005668:	6129                	addi	sp,sp,192
    8000566a:	8082                	ret
      end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	9d4080e7          	jalr	-1580(ra) # 80004040 <end_op>
      return -1;
    80005674:	557d                	li	a0,-1
    80005676:	b7e5                	j	8000565e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005678:	f5040513          	addi	a0,s0,-176
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	74a080e7          	jalr	1866(ra) # 80003dc6 <namei>
    80005684:	84aa                	mv	s1,a0
    80005686:	c905                	beqz	a0,800056b6 <sys_open+0x13a>
    ilock(ip);
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	f98080e7          	jalr	-104(ra) # 80003620 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005690:	04449703          	lh	a4,68(s1)
    80005694:	4785                	li	a5,1
    80005696:	f4f712e3          	bne	a4,a5,800055da <sys_open+0x5e>
    8000569a:	f4c42783          	lw	a5,-180(s0)
    8000569e:	dba1                	beqz	a5,800055ee <sys_open+0x72>
      iunlockput(ip);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	1e0080e7          	jalr	480(ra) # 80003882 <iunlockput>
      end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	996080e7          	jalr	-1642(ra) # 80004040 <end_op>
      return -1;
    800056b2:	557d                	li	a0,-1
    800056b4:	b76d                	j	8000565e <sys_open+0xe2>
      end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	98a080e7          	jalr	-1654(ra) # 80004040 <end_op>
      return -1;
    800056be:	557d                	li	a0,-1
    800056c0:	bf79                	j	8000565e <sys_open+0xe2>
    iunlockput(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	1be080e7          	jalr	446(ra) # 80003882 <iunlockput>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	974080e7          	jalr	-1676(ra) # 80004040 <end_op>
    return -1;
    800056d4:	557d                	li	a0,-1
    800056d6:	b761                	j	8000565e <sys_open+0xe2>
      fileclose(f);
    800056d8:	854a                	mv	a0,s2
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	db0080e7          	jalr	-592(ra) # 8000448a <fileclose>
    iunlockput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	19e080e7          	jalr	414(ra) # 80003882 <iunlockput>
    end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	954080e7          	jalr	-1708(ra) # 80004040 <end_op>
    return -1;
    800056f4:	557d                	li	a0,-1
    800056f6:	b7a5                	j	8000565e <sys_open+0xe2>
    f->type = FD_DEVICE;
    800056f8:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800056fc:	04649783          	lh	a5,70(s1)
    80005700:	02f91223          	sh	a5,36(s2)
    80005704:	bf21                	j	8000561c <sys_open+0xa0>
    itrunc(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	026080e7          	jalr	38(ra) # 8000372e <itrunc>
    80005710:	bf2d                	j	8000564a <sys_open+0xce>

0000000080005712 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005712:	7175                	addi	sp,sp,-144
    80005714:	e506                	sd	ra,136(sp)
    80005716:	e122                	sd	s0,128(sp)
    80005718:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	8ac080e7          	jalr	-1876(ra) # 80003fc6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005722:	08000613          	li	a2,128
    80005726:	f7040593          	addi	a1,s0,-144
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	3c4080e7          	jalr	964(ra) # 80002af0 <argstr>
    80005734:	02054963          	bltz	a0,80005766 <sys_mkdir+0x54>
    80005738:	4681                	li	a3,0
    8000573a:	4601                	li	a2,0
    8000573c:	4585                	li	a1,1
    8000573e:	f7040513          	addi	a0,s0,-144
    80005742:	00000097          	auipc	ra,0x0
    80005746:	806080e7          	jalr	-2042(ra) # 80004f48 <create>
    8000574a:	cd11                	beqz	a0,80005766 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	136080e7          	jalr	310(ra) # 80003882 <iunlockput>
  end_op();
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	8ec080e7          	jalr	-1812(ra) # 80004040 <end_op>
  return 0;
    8000575c:	4501                	li	a0,0
}
    8000575e:	60aa                	ld	ra,136(sp)
    80005760:	640a                	ld	s0,128(sp)
    80005762:	6149                	addi	sp,sp,144
    80005764:	8082                	ret
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	8da080e7          	jalr	-1830(ra) # 80004040 <end_op>
    return -1;
    8000576e:	557d                	li	a0,-1
    80005770:	b7fd                	j	8000575e <sys_mkdir+0x4c>

0000000080005772 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005772:	7135                	addi	sp,sp,-160
    80005774:	ed06                	sd	ra,152(sp)
    80005776:	e922                	sd	s0,144(sp)
    80005778:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	84c080e7          	jalr	-1972(ra) # 80003fc6 <begin_op>
  argint(1, &major);
    80005782:	f6c40593          	addi	a1,s0,-148
    80005786:	4505                	li	a0,1
    80005788:	ffffd097          	auipc	ra,0xffffd
    8000578c:	328080e7          	jalr	808(ra) # 80002ab0 <argint>
  argint(2, &minor);
    80005790:	f6840593          	addi	a1,s0,-152
    80005794:	4509                	li	a0,2
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	31a080e7          	jalr	794(ra) # 80002ab0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000579e:	08000613          	li	a2,128
    800057a2:	f7040593          	addi	a1,s0,-144
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	348080e7          	jalr	840(ra) # 80002af0 <argstr>
    800057b0:	02054b63          	bltz	a0,800057e6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057b4:	f6841683          	lh	a3,-152(s0)
    800057b8:	f6c41603          	lh	a2,-148(s0)
    800057bc:	458d                	li	a1,3
    800057be:	f7040513          	addi	a0,s0,-144
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	786080e7          	jalr	1926(ra) # 80004f48 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057ca:	cd11                	beqz	a0,800057e6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	0b6080e7          	jalr	182(ra) # 80003882 <iunlockput>
  end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	86c080e7          	jalr	-1940(ra) # 80004040 <end_op>
  return 0;
    800057dc:	4501                	li	a0,0
}
    800057de:	60ea                	ld	ra,152(sp)
    800057e0:	644a                	ld	s0,144(sp)
    800057e2:	610d                	addi	sp,sp,160
    800057e4:	8082                	ret
    end_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	85a080e7          	jalr	-1958(ra) # 80004040 <end_op>
    return -1;
    800057ee:	557d                	li	a0,-1
    800057f0:	b7fd                	j	800057de <sys_mknod+0x6c>

00000000800057f2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057f2:	7135                	addi	sp,sp,-160
    800057f4:	ed06                	sd	ra,152(sp)
    800057f6:	e922                	sd	s0,144(sp)
    800057f8:	e526                	sd	s1,136(sp)
    800057fa:	e14a                	sd	s2,128(sp)
    800057fc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057fe:	ffffc097          	auipc	ra,0xffffc
    80005802:	198080e7          	jalr	408(ra) # 80001996 <myproc>
    80005806:	892a                	mv	s2,a0
  
  begin_op();
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	7be080e7          	jalr	1982(ra) # 80003fc6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005810:	08000613          	li	a2,128
    80005814:	f6040593          	addi	a1,s0,-160
    80005818:	4501                	li	a0,0
    8000581a:	ffffd097          	auipc	ra,0xffffd
    8000581e:	2d6080e7          	jalr	726(ra) # 80002af0 <argstr>
    80005822:	04054b63          	bltz	a0,80005878 <sys_chdir+0x86>
    80005826:	f6040513          	addi	a0,s0,-160
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	59c080e7          	jalr	1436(ra) # 80003dc6 <namei>
    80005832:	84aa                	mv	s1,a0
    80005834:	c131                	beqz	a0,80005878 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	dea080e7          	jalr	-534(ra) # 80003620 <ilock>
  if(ip->type != T_DIR){
    8000583e:	04449703          	lh	a4,68(s1)
    80005842:	4785                	li	a5,1
    80005844:	04f71063          	bne	a4,a5,80005884 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	e98080e7          	jalr	-360(ra) # 800036e2 <iunlock>
  iput(p->cwd);
    80005852:	15093503          	ld	a0,336(s2)
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	f84080e7          	jalr	-124(ra) # 800037da <iput>
  end_op();
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	7e2080e7          	jalr	2018(ra) # 80004040 <end_op>
  p->cwd = ip;
    80005866:	14993823          	sd	s1,336(s2)
  return 0;
    8000586a:	4501                	li	a0,0
}
    8000586c:	60ea                	ld	ra,152(sp)
    8000586e:	644a                	ld	s0,144(sp)
    80005870:	64aa                	ld	s1,136(sp)
    80005872:	690a                	ld	s2,128(sp)
    80005874:	610d                	addi	sp,sp,160
    80005876:	8082                	ret
    end_op();
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	7c8080e7          	jalr	1992(ra) # 80004040 <end_op>
    return -1;
    80005880:	557d                	li	a0,-1
    80005882:	b7ed                	j	8000586c <sys_chdir+0x7a>
    iunlockput(ip);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	ffc080e7          	jalr	-4(ra) # 80003882 <iunlockput>
    end_op();
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	7b2080e7          	jalr	1970(ra) # 80004040 <end_op>
    return -1;
    80005896:	557d                	li	a0,-1
    80005898:	bfd1                	j	8000586c <sys_chdir+0x7a>

000000008000589a <sys_exec>:

uint64
sys_exec(void)
{
    8000589a:	7121                	addi	sp,sp,-448
    8000589c:	ff06                	sd	ra,440(sp)
    8000589e:	fb22                	sd	s0,432(sp)
    800058a0:	f726                	sd	s1,424(sp)
    800058a2:	f34a                	sd	s2,416(sp)
    800058a4:	ef4e                	sd	s3,408(sp)
    800058a6:	eb52                	sd	s4,400(sp)
    800058a8:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800058aa:	e4840593          	addi	a1,s0,-440
    800058ae:	4505                	li	a0,1
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	220080e7          	jalr	544(ra) # 80002ad0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800058b8:	08000613          	li	a2,128
    800058bc:	f5040593          	addi	a1,s0,-176
    800058c0:	4501                	li	a0,0
    800058c2:	ffffd097          	auipc	ra,0xffffd
    800058c6:	22e080e7          	jalr	558(ra) # 80002af0 <argstr>
    800058ca:	87aa                	mv	a5,a0
    return -1;
    800058cc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800058ce:	0c07c263          	bltz	a5,80005992 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    800058d2:	10000613          	li	a2,256
    800058d6:	4581                	li	a1,0
    800058d8:	e5040513          	addi	a0,s0,-432
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	3f2080e7          	jalr	1010(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058e4:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800058e8:	89a6                	mv	s3,s1
    800058ea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058ec:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058f0:	00391513          	slli	a0,s2,0x3
    800058f4:	e4040593          	addi	a1,s0,-448
    800058f8:	e4843783          	ld	a5,-440(s0)
    800058fc:	953e                	add	a0,a0,a5
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	114080e7          	jalr	276(ra) # 80002a12 <fetchaddr>
    80005906:	02054a63          	bltz	a0,8000593a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    8000590a:	e4043783          	ld	a5,-448(s0)
    8000590e:	c3b9                	beqz	a5,80005954 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005910:	ffffb097          	auipc	ra,0xffffb
    80005914:	1d2080e7          	jalr	466(ra) # 80000ae2 <kalloc>
    80005918:	85aa                	mv	a1,a0
    8000591a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000591e:	cd11                	beqz	a0,8000593a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005920:	6605                	lui	a2,0x1
    80005922:	e4043503          	ld	a0,-448(s0)
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	13e080e7          	jalr	318(ra) # 80002a64 <fetchstr>
    8000592e:	00054663          	bltz	a0,8000593a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005932:	0905                	addi	s2,s2,1
    80005934:	09a1                	addi	s3,s3,8
    80005936:	fb491de3          	bne	s2,s4,800058f0 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593a:	f5040913          	addi	s2,s0,-176
    8000593e:	6088                	ld	a0,0(s1)
    80005940:	c921                	beqz	a0,80005990 <sys_exec+0xf6>
    kfree(argv[i]);
    80005942:	ffffb097          	auipc	ra,0xffffb
    80005946:	0a2080e7          	jalr	162(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000594a:	04a1                	addi	s1,s1,8
    8000594c:	ff2499e3          	bne	s1,s2,8000593e <sys_exec+0xa4>
  return -1;
    80005950:	557d                	li	a0,-1
    80005952:	a081                	j	80005992 <sys_exec+0xf8>
      argv[i] = 0;
    80005954:	0009079b          	sext.w	a5,s2
    80005958:	078e                	slli	a5,a5,0x3
    8000595a:	fd078793          	addi	a5,a5,-48
    8000595e:	97a2                	add	a5,a5,s0
    80005960:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005964:	e5040593          	addi	a1,s0,-432
    80005968:	f5040513          	addi	a0,s0,-176
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	194080e7          	jalr	404(ra) # 80004b00 <exec>
    80005974:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005976:	f5040993          	addi	s3,s0,-176
    8000597a:	6088                	ld	a0,0(s1)
    8000597c:	c901                	beqz	a0,8000598c <sys_exec+0xf2>
    kfree(argv[i]);
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	066080e7          	jalr	102(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005986:	04a1                	addi	s1,s1,8
    80005988:	ff3499e3          	bne	s1,s3,8000597a <sys_exec+0xe0>
  return ret;
    8000598c:	854a                	mv	a0,s2
    8000598e:	a011                	j	80005992 <sys_exec+0xf8>
  return -1;
    80005990:	557d                	li	a0,-1
}
    80005992:	70fa                	ld	ra,440(sp)
    80005994:	745a                	ld	s0,432(sp)
    80005996:	74ba                	ld	s1,424(sp)
    80005998:	791a                	ld	s2,416(sp)
    8000599a:	69fa                	ld	s3,408(sp)
    8000599c:	6a5a                	ld	s4,400(sp)
    8000599e:	6139                	addi	sp,sp,448
    800059a0:	8082                	ret

00000000800059a2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059a2:	7139                	addi	sp,sp,-64
    800059a4:	fc06                	sd	ra,56(sp)
    800059a6:	f822                	sd	s0,48(sp)
    800059a8:	f426                	sd	s1,40(sp)
    800059aa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059ac:	ffffc097          	auipc	ra,0xffffc
    800059b0:	fea080e7          	jalr	-22(ra) # 80001996 <myproc>
    800059b4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800059b6:	fd840593          	addi	a1,s0,-40
    800059ba:	4501                	li	a0,0
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	114080e7          	jalr	276(ra) # 80002ad0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800059c4:	fc840593          	addi	a1,s0,-56
    800059c8:	fd040513          	addi	a0,s0,-48
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	dea080e7          	jalr	-534(ra) # 800047b6 <pipealloc>
    return -1;
    800059d4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059d6:	0c054463          	bltz	a0,80005a9e <sys_pipe+0xfc>
  fd0 = -1;
    800059da:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059de:	fd043503          	ld	a0,-48(s0)
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	524080e7          	jalr	1316(ra) # 80004f06 <fdalloc>
    800059ea:	fca42223          	sw	a0,-60(s0)
    800059ee:	08054b63          	bltz	a0,80005a84 <sys_pipe+0xe2>
    800059f2:	fc843503          	ld	a0,-56(s0)
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	510080e7          	jalr	1296(ra) # 80004f06 <fdalloc>
    800059fe:	fca42023          	sw	a0,-64(s0)
    80005a02:	06054863          	bltz	a0,80005a72 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a06:	4691                	li	a3,4
    80005a08:	fc440613          	addi	a2,s0,-60
    80005a0c:	fd843583          	ld	a1,-40(s0)
    80005a10:	68a8                	ld	a0,80(s1)
    80005a12:	ffffc097          	auipc	ra,0xffffc
    80005a16:	c44080e7          	jalr	-956(ra) # 80001656 <copyout>
    80005a1a:	02054063          	bltz	a0,80005a3a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a1e:	4691                	li	a3,4
    80005a20:	fc040613          	addi	a2,s0,-64
    80005a24:	fd843583          	ld	a1,-40(s0)
    80005a28:	0591                	addi	a1,a1,4
    80005a2a:	68a8                	ld	a0,80(s1)
    80005a2c:	ffffc097          	auipc	ra,0xffffc
    80005a30:	c2a080e7          	jalr	-982(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a34:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a36:	06055463          	bgez	a0,80005a9e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005a3a:	fc442783          	lw	a5,-60(s0)
    80005a3e:	07e9                	addi	a5,a5,26
    80005a40:	078e                	slli	a5,a5,0x3
    80005a42:	97a6                	add	a5,a5,s1
    80005a44:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a48:	fc042783          	lw	a5,-64(s0)
    80005a4c:	07e9                	addi	a5,a5,26
    80005a4e:	078e                	slli	a5,a5,0x3
    80005a50:	94be                	add	s1,s1,a5
    80005a52:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005a56:	fd043503          	ld	a0,-48(s0)
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	a30080e7          	jalr	-1488(ra) # 8000448a <fileclose>
    fileclose(wf);
    80005a62:	fc843503          	ld	a0,-56(s0)
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	a24080e7          	jalr	-1500(ra) # 8000448a <fileclose>
    return -1;
    80005a6e:	57fd                	li	a5,-1
    80005a70:	a03d                	j	80005a9e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005a72:	fc442783          	lw	a5,-60(s0)
    80005a76:	0007c763          	bltz	a5,80005a84 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005a7a:	07e9                	addi	a5,a5,26
    80005a7c:	078e                	slli	a5,a5,0x3
    80005a7e:	97a6                	add	a5,a5,s1
    80005a80:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005a84:	fd043503          	ld	a0,-48(s0)
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	a02080e7          	jalr	-1534(ra) # 8000448a <fileclose>
    fileclose(wf);
    80005a90:	fc843503          	ld	a0,-56(s0)
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	9f6080e7          	jalr	-1546(ra) # 8000448a <fileclose>
    return -1;
    80005a9c:	57fd                	li	a5,-1
}
    80005a9e:	853e                	mv	a0,a5
    80005aa0:	70e2                	ld	ra,56(sp)
    80005aa2:	7442                	ld	s0,48(sp)
    80005aa4:	74a2                	ld	s1,40(sp)
    80005aa6:	6121                	addi	sp,sp,64
    80005aa8:	8082                	ret
    80005aaa:	0000                	unimp
    80005aac:	0000                	unimp
	...

0000000080005ab0 <kernelvec>:
    80005ab0:	7111                	addi	sp,sp,-256
    80005ab2:	e006                	sd	ra,0(sp)
    80005ab4:	e40a                	sd	sp,8(sp)
    80005ab6:	e80e                	sd	gp,16(sp)
    80005ab8:	ec12                	sd	tp,24(sp)
    80005aba:	f016                	sd	t0,32(sp)
    80005abc:	f41a                	sd	t1,40(sp)
    80005abe:	f81e                	sd	t2,48(sp)
    80005ac0:	fc22                	sd	s0,56(sp)
    80005ac2:	e0a6                	sd	s1,64(sp)
    80005ac4:	e4aa                	sd	a0,72(sp)
    80005ac6:	e8ae                	sd	a1,80(sp)
    80005ac8:	ecb2                	sd	a2,88(sp)
    80005aca:	f0b6                	sd	a3,96(sp)
    80005acc:	f4ba                	sd	a4,104(sp)
    80005ace:	f8be                	sd	a5,112(sp)
    80005ad0:	fcc2                	sd	a6,120(sp)
    80005ad2:	e146                	sd	a7,128(sp)
    80005ad4:	e54a                	sd	s2,136(sp)
    80005ad6:	e94e                	sd	s3,144(sp)
    80005ad8:	ed52                	sd	s4,152(sp)
    80005ada:	f156                	sd	s5,160(sp)
    80005adc:	f55a                	sd	s6,168(sp)
    80005ade:	f95e                	sd	s7,176(sp)
    80005ae0:	fd62                	sd	s8,184(sp)
    80005ae2:	e1e6                	sd	s9,192(sp)
    80005ae4:	e5ea                	sd	s10,200(sp)
    80005ae6:	e9ee                	sd	s11,208(sp)
    80005ae8:	edf2                	sd	t3,216(sp)
    80005aea:	f1f6                	sd	t4,224(sp)
    80005aec:	f5fa                	sd	t5,232(sp)
    80005aee:	f9fe                	sd	t6,240(sp)
    80005af0:	deffc0ef          	jal	ra,800028de <kerneltrap>
    80005af4:	6082                	ld	ra,0(sp)
    80005af6:	6122                	ld	sp,8(sp)
    80005af8:	61c2                	ld	gp,16(sp)
    80005afa:	7282                	ld	t0,32(sp)
    80005afc:	7322                	ld	t1,40(sp)
    80005afe:	73c2                	ld	t2,48(sp)
    80005b00:	7462                	ld	s0,56(sp)
    80005b02:	6486                	ld	s1,64(sp)
    80005b04:	6526                	ld	a0,72(sp)
    80005b06:	65c6                	ld	a1,80(sp)
    80005b08:	6666                	ld	a2,88(sp)
    80005b0a:	7686                	ld	a3,96(sp)
    80005b0c:	7726                	ld	a4,104(sp)
    80005b0e:	77c6                	ld	a5,112(sp)
    80005b10:	7866                	ld	a6,120(sp)
    80005b12:	688a                	ld	a7,128(sp)
    80005b14:	692a                	ld	s2,136(sp)
    80005b16:	69ca                	ld	s3,144(sp)
    80005b18:	6a6a                	ld	s4,152(sp)
    80005b1a:	7a8a                	ld	s5,160(sp)
    80005b1c:	7b2a                	ld	s6,168(sp)
    80005b1e:	7bca                	ld	s7,176(sp)
    80005b20:	7c6a                	ld	s8,184(sp)
    80005b22:	6c8e                	ld	s9,192(sp)
    80005b24:	6d2e                	ld	s10,200(sp)
    80005b26:	6dce                	ld	s11,208(sp)
    80005b28:	6e6e                	ld	t3,216(sp)
    80005b2a:	7e8e                	ld	t4,224(sp)
    80005b2c:	7f2e                	ld	t5,232(sp)
    80005b2e:	7fce                	ld	t6,240(sp)
    80005b30:	6111                	addi	sp,sp,256
    80005b32:	10200073          	sret
    80005b36:	00000013          	nop
    80005b3a:	00000013          	nop
    80005b3e:	0001                	nop

0000000080005b40 <timervec>:
    80005b40:	34051573          	csrrw	a0,mscratch,a0
    80005b44:	e10c                	sd	a1,0(a0)
    80005b46:	e510                	sd	a2,8(a0)
    80005b48:	e914                	sd	a3,16(a0)
    80005b4a:	6d0c                	ld	a1,24(a0)
    80005b4c:	7110                	ld	a2,32(a0)
    80005b4e:	6194                	ld	a3,0(a1)
    80005b50:	96b2                	add	a3,a3,a2
    80005b52:	e194                	sd	a3,0(a1)
    80005b54:	4589                	li	a1,2
    80005b56:	14459073          	csrw	sip,a1
    80005b5a:	6914                	ld	a3,16(a0)
    80005b5c:	6510                	ld	a2,8(a0)
    80005b5e:	610c                	ld	a1,0(a0)
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	30200073          	mret
	...

0000000080005b6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b6a:	1141                	addi	sp,sp,-16
    80005b6c:	e422                	sd	s0,8(sp)
    80005b6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b70:	0c0007b7          	lui	a5,0xc000
    80005b74:	4705                	li	a4,1
    80005b76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b78:	c3d8                	sw	a4,4(a5)
}
    80005b7a:	6422                	ld	s0,8(sp)
    80005b7c:	0141                	addi	sp,sp,16
    80005b7e:	8082                	ret

0000000080005b80 <plicinithart>:

void
plicinithart(void)
{
    80005b80:	1141                	addi	sp,sp,-16
    80005b82:	e406                	sd	ra,8(sp)
    80005b84:	e022                	sd	s0,0(sp)
    80005b86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	de2080e7          	jalr	-542(ra) # 8000196a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b90:	0085171b          	slliw	a4,a0,0x8
    80005b94:	0c0027b7          	lui	a5,0xc002
    80005b98:	97ba                	add	a5,a5,a4
    80005b9a:	40200713          	li	a4,1026
    80005b9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ba2:	00d5151b          	slliw	a0,a0,0xd
    80005ba6:	0c2017b7          	lui	a5,0xc201
    80005baa:	97aa                	add	a5,a5,a0
    80005bac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005bb0:	60a2                	ld	ra,8(sp)
    80005bb2:	6402                	ld	s0,0(sp)
    80005bb4:	0141                	addi	sp,sp,16
    80005bb6:	8082                	ret

0000000080005bb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bb8:	1141                	addi	sp,sp,-16
    80005bba:	e406                	sd	ra,8(sp)
    80005bbc:	e022                	sd	s0,0(sp)
    80005bbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	daa080e7          	jalr	-598(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bc8:	00d5151b          	slliw	a0,a0,0xd
    80005bcc:	0c2017b7          	lui	a5,0xc201
    80005bd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005bd2:	43c8                	lw	a0,4(a5)
    80005bd4:	60a2                	ld	ra,8(sp)
    80005bd6:	6402                	ld	s0,0(sp)
    80005bd8:	0141                	addi	sp,sp,16
    80005bda:	8082                	ret

0000000080005bdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bdc:	1101                	addi	sp,sp,-32
    80005bde:	ec06                	sd	ra,24(sp)
    80005be0:	e822                	sd	s0,16(sp)
    80005be2:	e426                	sd	s1,8(sp)
    80005be4:	1000                	addi	s0,sp,32
    80005be6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	d82080e7          	jalr	-638(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005bf0:	00d5151b          	slliw	a0,a0,0xd
    80005bf4:	0c2017b7          	lui	a5,0xc201
    80005bf8:	97aa                	add	a5,a5,a0
    80005bfa:	c3c4                	sw	s1,4(a5)
}
    80005bfc:	60e2                	ld	ra,24(sp)
    80005bfe:	6442                	ld	s0,16(sp)
    80005c00:	64a2                	ld	s1,8(sp)
    80005c02:	6105                	addi	sp,sp,32
    80005c04:	8082                	ret

0000000080005c06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c06:	1141                	addi	sp,sp,-16
    80005c08:	e406                	sd	ra,8(sp)
    80005c0a:	e022                	sd	s0,0(sp)
    80005c0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c0e:	479d                	li	a5,7
    80005c10:	04a7cc63          	blt	a5,a0,80005c68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005c14:	0001c797          	auipc	a5,0x1c
    80005c18:	01c78793          	addi	a5,a5,28 # 80021c30 <disk>
    80005c1c:	97aa                	add	a5,a5,a0
    80005c1e:	0187c783          	lbu	a5,24(a5)
    80005c22:	ebb9                	bnez	a5,80005c78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c24:	00451693          	slli	a3,a0,0x4
    80005c28:	0001c797          	auipc	a5,0x1c
    80005c2c:	00878793          	addi	a5,a5,8 # 80021c30 <disk>
    80005c30:	6398                	ld	a4,0(a5)
    80005c32:	9736                	add	a4,a4,a3
    80005c34:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005c38:	6398                	ld	a4,0(a5)
    80005c3a:	9736                	add	a4,a4,a3
    80005c3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005c40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005c44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005c48:	97aa                	add	a5,a5,a0
    80005c4a:	4705                	li	a4,1
    80005c4c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005c50:	0001c517          	auipc	a0,0x1c
    80005c54:	ff850513          	addi	a0,a0,-8 # 80021c48 <disk+0x18>
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	44a080e7          	jalr	1098(ra) # 800020a2 <wakeup>
}
    80005c60:	60a2                	ld	ra,8(sp)
    80005c62:	6402                	ld	s0,0(sp)
    80005c64:	0141                	addi	sp,sp,16
    80005c66:	8082                	ret
    panic("free_desc 1");
    80005c68:	00003517          	auipc	a0,0x3
    80005c6c:	b0050513          	addi	a0,a0,-1280 # 80008768 <syscalls+0x2f8>
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	8cc080e7          	jalr	-1844(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005c78:	00003517          	auipc	a0,0x3
    80005c7c:	b0050513          	addi	a0,a0,-1280 # 80008778 <syscalls+0x308>
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	8bc080e7          	jalr	-1860(ra) # 8000053c <panic>

0000000080005c88 <virtio_disk_init>:
{
    80005c88:	1101                	addi	sp,sp,-32
    80005c8a:	ec06                	sd	ra,24(sp)
    80005c8c:	e822                	sd	s0,16(sp)
    80005c8e:	e426                	sd	s1,8(sp)
    80005c90:	e04a                	sd	s2,0(sp)
    80005c92:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005c94:	00003597          	auipc	a1,0x3
    80005c98:	af458593          	addi	a1,a1,-1292 # 80008788 <syscalls+0x318>
    80005c9c:	0001c517          	auipc	a0,0x1c
    80005ca0:	0bc50513          	addi	a0,a0,188 # 80021d58 <disk+0x128>
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	e9e080e7          	jalr	-354(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cac:	100017b7          	lui	a5,0x10001
    80005cb0:	4398                	lw	a4,0(a5)
    80005cb2:	2701                	sext.w	a4,a4
    80005cb4:	747277b7          	lui	a5,0x74727
    80005cb8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cbc:	14f71b63          	bne	a4,a5,80005e12 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005cc0:	100017b7          	lui	a5,0x10001
    80005cc4:	43dc                	lw	a5,4(a5)
    80005cc6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cc8:	4709                	li	a4,2
    80005cca:	14e79463          	bne	a5,a4,80005e12 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cce:	100017b7          	lui	a5,0x10001
    80005cd2:	479c                	lw	a5,8(a5)
    80005cd4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005cd6:	12e79e63          	bne	a5,a4,80005e12 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cda:	100017b7          	lui	a5,0x10001
    80005cde:	47d8                	lw	a4,12(a5)
    80005ce0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ce2:	554d47b7          	lui	a5,0x554d4
    80005ce6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cea:	12f71463          	bne	a4,a5,80005e12 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cee:	100017b7          	lui	a5,0x10001
    80005cf2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cf6:	4705                	li	a4,1
    80005cf8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cfa:	470d                	li	a4,3
    80005cfc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005cfe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d00:	c7ffe6b7          	lui	a3,0xc7ffe
    80005d04:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9ef>
    80005d08:	8f75                	and	a4,a4,a3
    80005d0a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d0c:	472d                	li	a4,11
    80005d0e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005d10:	5bbc                	lw	a5,112(a5)
    80005d12:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005d16:	8ba1                	andi	a5,a5,8
    80005d18:	10078563          	beqz	a5,80005e22 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d1c:	100017b7          	lui	a5,0x10001
    80005d20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005d24:	43fc                	lw	a5,68(a5)
    80005d26:	2781                	sext.w	a5,a5
    80005d28:	10079563          	bnez	a5,80005e32 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d2c:	100017b7          	lui	a5,0x10001
    80005d30:	5bdc                	lw	a5,52(a5)
    80005d32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d34:	10078763          	beqz	a5,80005e42 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005d38:	471d                	li	a4,7
    80005d3a:	10f77c63          	bgeu	a4,a5,80005e52 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005d3e:	ffffb097          	auipc	ra,0xffffb
    80005d42:	da4080e7          	jalr	-604(ra) # 80000ae2 <kalloc>
    80005d46:	0001c497          	auipc	s1,0x1c
    80005d4a:	eea48493          	addi	s1,s1,-278 # 80021c30 <disk>
    80005d4e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005d50:	ffffb097          	auipc	ra,0xffffb
    80005d54:	d92080e7          	jalr	-622(ra) # 80000ae2 <kalloc>
    80005d58:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005d5a:	ffffb097          	auipc	ra,0xffffb
    80005d5e:	d88080e7          	jalr	-632(ra) # 80000ae2 <kalloc>
    80005d62:	87aa                	mv	a5,a0
    80005d64:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005d66:	6088                	ld	a0,0(s1)
    80005d68:	cd6d                	beqz	a0,80005e62 <virtio_disk_init+0x1da>
    80005d6a:	0001c717          	auipc	a4,0x1c
    80005d6e:	ece73703          	ld	a4,-306(a4) # 80021c38 <disk+0x8>
    80005d72:	cb65                	beqz	a4,80005e62 <virtio_disk_init+0x1da>
    80005d74:	c7fd                	beqz	a5,80005e62 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005d76:	6605                	lui	a2,0x1
    80005d78:	4581                	li	a1,0
    80005d7a:	ffffb097          	auipc	ra,0xffffb
    80005d7e:	f54080e7          	jalr	-172(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80005d82:	0001c497          	auipc	s1,0x1c
    80005d86:	eae48493          	addi	s1,s1,-338 # 80021c30 <disk>
    80005d8a:	6605                	lui	a2,0x1
    80005d8c:	4581                	li	a1,0
    80005d8e:	6488                	ld	a0,8(s1)
    80005d90:	ffffb097          	auipc	ra,0xffffb
    80005d94:	f3e080e7          	jalr	-194(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80005d98:	6605                	lui	a2,0x1
    80005d9a:	4581                	li	a1,0
    80005d9c:	6888                	ld	a0,16(s1)
    80005d9e:	ffffb097          	auipc	ra,0xffffb
    80005da2:	f30080e7          	jalr	-208(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005da6:	100017b7          	lui	a5,0x10001
    80005daa:	4721                	li	a4,8
    80005dac:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005dae:	4098                	lw	a4,0(s1)
    80005db0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005db4:	40d8                	lw	a4,4(s1)
    80005db6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005dba:	6498                	ld	a4,8(s1)
    80005dbc:	0007069b          	sext.w	a3,a4
    80005dc0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005dc4:	9701                	srai	a4,a4,0x20
    80005dc6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005dca:	6898                	ld	a4,16(s1)
    80005dcc:	0007069b          	sext.w	a3,a4
    80005dd0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005dd4:	9701                	srai	a4,a4,0x20
    80005dd6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005dda:	4705                	li	a4,1
    80005ddc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005dde:	00e48c23          	sb	a4,24(s1)
    80005de2:	00e48ca3          	sb	a4,25(s1)
    80005de6:	00e48d23          	sb	a4,26(s1)
    80005dea:	00e48da3          	sb	a4,27(s1)
    80005dee:	00e48e23          	sb	a4,28(s1)
    80005df2:	00e48ea3          	sb	a4,29(s1)
    80005df6:	00e48f23          	sb	a4,30(s1)
    80005dfa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005dfe:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e02:	0727a823          	sw	s2,112(a5)
}
    80005e06:	60e2                	ld	ra,24(sp)
    80005e08:	6442                	ld	s0,16(sp)
    80005e0a:	64a2                	ld	s1,8(sp)
    80005e0c:	6902                	ld	s2,0(sp)
    80005e0e:	6105                	addi	sp,sp,32
    80005e10:	8082                	ret
    panic("could not find virtio disk");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	98650513          	addi	a0,a0,-1658 # 80008798 <syscalls+0x328>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	722080e7          	jalr	1826(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	99650513          	addi	a0,a0,-1642 # 800087b8 <syscalls+0x348>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	712080e7          	jalr	1810(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	9a650513          	addi	a0,a0,-1626 # 800087d8 <syscalls+0x368>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	702080e7          	jalr	1794(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	9b650513          	addi	a0,a0,-1610 # 800087f8 <syscalls+0x388>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f2080e7          	jalr	1778(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	9c650513          	addi	a0,a0,-1594 # 80008818 <syscalls+0x3a8>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e2080e7          	jalr	1762(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80005e62:	00003517          	auipc	a0,0x3
    80005e66:	9d650513          	addi	a0,a0,-1578 # 80008838 <syscalls+0x3c8>
    80005e6a:	ffffa097          	auipc	ra,0xffffa
    80005e6e:	6d2080e7          	jalr	1746(ra) # 8000053c <panic>

0000000080005e72 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e72:	7159                	addi	sp,sp,-112
    80005e74:	f486                	sd	ra,104(sp)
    80005e76:	f0a2                	sd	s0,96(sp)
    80005e78:	eca6                	sd	s1,88(sp)
    80005e7a:	e8ca                	sd	s2,80(sp)
    80005e7c:	e4ce                	sd	s3,72(sp)
    80005e7e:	e0d2                	sd	s4,64(sp)
    80005e80:	fc56                	sd	s5,56(sp)
    80005e82:	f85a                	sd	s6,48(sp)
    80005e84:	f45e                	sd	s7,40(sp)
    80005e86:	f062                	sd	s8,32(sp)
    80005e88:	ec66                	sd	s9,24(sp)
    80005e8a:	e86a                	sd	s10,16(sp)
    80005e8c:	1880                	addi	s0,sp,112
    80005e8e:	8a2a                	mv	s4,a0
    80005e90:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e92:	00c52c83          	lw	s9,12(a0)
    80005e96:	001c9c9b          	slliw	s9,s9,0x1
    80005e9a:	1c82                	slli	s9,s9,0x20
    80005e9c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ea0:	0001c517          	auipc	a0,0x1c
    80005ea4:	eb850513          	addi	a0,a0,-328 # 80021d58 <disk+0x128>
    80005ea8:	ffffb097          	auipc	ra,0xffffb
    80005eac:	d2a080e7          	jalr	-726(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80005eb0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80005eb2:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005eb4:	0001cb17          	auipc	s6,0x1c
    80005eb8:	d7cb0b13          	addi	s6,s6,-644 # 80021c30 <disk>
  for(int i = 0; i < 3; i++){
    80005ebc:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ebe:	0001cc17          	auipc	s8,0x1c
    80005ec2:	e9ac0c13          	addi	s8,s8,-358 # 80021d58 <disk+0x128>
    80005ec6:	a095                	j	80005f2a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005ec8:	00fb0733          	add	a4,s6,a5
    80005ecc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ed0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80005ed2:	0207c563          	bltz	a5,80005efc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80005ed6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80005ed8:	0591                	addi	a1,a1,4
    80005eda:	05560d63          	beq	a2,s5,80005f34 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005ede:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80005ee0:	0001c717          	auipc	a4,0x1c
    80005ee4:	d5070713          	addi	a4,a4,-688 # 80021c30 <disk>
    80005ee8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80005eea:	01874683          	lbu	a3,24(a4)
    80005eee:	fee9                	bnez	a3,80005ec8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80005ef0:	2785                	addiw	a5,a5,1
    80005ef2:	0705                	addi	a4,a4,1
    80005ef4:	fe979be3          	bne	a5,s1,80005eea <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80005ef8:	57fd                	li	a5,-1
    80005efa:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80005efc:	00c05e63          	blez	a2,80005f18 <virtio_disk_rw+0xa6>
    80005f00:	060a                	slli	a2,a2,0x2
    80005f02:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80005f06:	0009a503          	lw	a0,0(s3)
    80005f0a:	00000097          	auipc	ra,0x0
    80005f0e:	cfc080e7          	jalr	-772(ra) # 80005c06 <free_desc>
      for(int j = 0; j < i; j++)
    80005f12:	0991                	addi	s3,s3,4
    80005f14:	ffa999e3          	bne	s3,s10,80005f06 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f18:	85e2                	mv	a1,s8
    80005f1a:	0001c517          	auipc	a0,0x1c
    80005f1e:	d2e50513          	addi	a0,a0,-722 # 80021c48 <disk+0x18>
    80005f22:	ffffc097          	auipc	ra,0xffffc
    80005f26:	11c080e7          	jalr	284(ra) # 8000203e <sleep>
  for(int i = 0; i < 3; i++){
    80005f2a:	f9040993          	addi	s3,s0,-112
{
    80005f2e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80005f30:	864a                	mv	a2,s2
    80005f32:	b775                	j	80005ede <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f34:	f9042503          	lw	a0,-112(s0)
    80005f38:	00a50713          	addi	a4,a0,10
    80005f3c:	0712                	slli	a4,a4,0x4

  if(write)
    80005f3e:	0001c797          	auipc	a5,0x1c
    80005f42:	cf278793          	addi	a5,a5,-782 # 80021c30 <disk>
    80005f46:	00e786b3          	add	a3,a5,a4
    80005f4a:	01703633          	snez	a2,s7
    80005f4e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f50:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80005f54:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f58:	f6070613          	addi	a2,a4,-160
    80005f5c:	6394                	ld	a3,0(a5)
    80005f5e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f60:	00870593          	addi	a1,a4,8
    80005f64:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f66:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f68:	0007b803          	ld	a6,0(a5)
    80005f6c:	9642                	add	a2,a2,a6
    80005f6e:	46c1                	li	a3,16
    80005f70:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f72:	4585                	li	a1,1
    80005f74:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80005f78:	f9442683          	lw	a3,-108(s0)
    80005f7c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f80:	0692                	slli	a3,a3,0x4
    80005f82:	9836                	add	a6,a6,a3
    80005f84:	058a0613          	addi	a2,s4,88
    80005f88:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80005f8c:	0007b803          	ld	a6,0(a5)
    80005f90:	96c2                	add	a3,a3,a6
    80005f92:	40000613          	li	a2,1024
    80005f96:	c690                	sw	a2,8(a3)
  if(write)
    80005f98:	001bb613          	seqz	a2,s7
    80005f9c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fa0:	00166613          	ori	a2,a2,1
    80005fa4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fa8:	f9842603          	lw	a2,-104(s0)
    80005fac:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fb0:	00250693          	addi	a3,a0,2
    80005fb4:	0692                	slli	a3,a3,0x4
    80005fb6:	96be                	add	a3,a3,a5
    80005fb8:	58fd                	li	a7,-1
    80005fba:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fbe:	0612                	slli	a2,a2,0x4
    80005fc0:	9832                	add	a6,a6,a2
    80005fc2:	f9070713          	addi	a4,a4,-112
    80005fc6:	973e                	add	a4,a4,a5
    80005fc8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80005fcc:	6398                	ld	a4,0(a5)
    80005fce:	9732                	add	a4,a4,a2
    80005fd0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fd2:	4609                	li	a2,2
    80005fd4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80005fd8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fdc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80005fe0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fe4:	6794                	ld	a3,8(a5)
    80005fe6:	0026d703          	lhu	a4,2(a3)
    80005fea:	8b1d                	andi	a4,a4,7
    80005fec:	0706                	slli	a4,a4,0x1
    80005fee:	96ba                	add	a3,a3,a4
    80005ff0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005ff4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005ff8:	6798                	ld	a4,8(a5)
    80005ffa:	00275783          	lhu	a5,2(a4)
    80005ffe:	2785                	addiw	a5,a5,1
    80006000:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006004:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006008:	100017b7          	lui	a5,0x10001
    8000600c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006010:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006014:	0001c917          	auipc	s2,0x1c
    80006018:	d4490913          	addi	s2,s2,-700 # 80021d58 <disk+0x128>
  while(b->disk == 1) {
    8000601c:	4485                	li	s1,1
    8000601e:	00b79c63          	bne	a5,a1,80006036 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006022:	85ca                	mv	a1,s2
    80006024:	8552                	mv	a0,s4
    80006026:	ffffc097          	auipc	ra,0xffffc
    8000602a:	018080e7          	jalr	24(ra) # 8000203e <sleep>
  while(b->disk == 1) {
    8000602e:	004a2783          	lw	a5,4(s4)
    80006032:	fe9788e3          	beq	a5,s1,80006022 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006036:	f9042903          	lw	s2,-112(s0)
    8000603a:	00290713          	addi	a4,s2,2
    8000603e:	0712                	slli	a4,a4,0x4
    80006040:	0001c797          	auipc	a5,0x1c
    80006044:	bf078793          	addi	a5,a5,-1040 # 80021c30 <disk>
    80006048:	97ba                	add	a5,a5,a4
    8000604a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000604e:	0001c997          	auipc	s3,0x1c
    80006052:	be298993          	addi	s3,s3,-1054 # 80021c30 <disk>
    80006056:	00491713          	slli	a4,s2,0x4
    8000605a:	0009b783          	ld	a5,0(s3)
    8000605e:	97ba                	add	a5,a5,a4
    80006060:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006064:	854a                	mv	a0,s2
    80006066:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000606a:	00000097          	auipc	ra,0x0
    8000606e:	b9c080e7          	jalr	-1124(ra) # 80005c06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006072:	8885                	andi	s1,s1,1
    80006074:	f0ed                	bnez	s1,80006056 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006076:	0001c517          	auipc	a0,0x1c
    8000607a:	ce250513          	addi	a0,a0,-798 # 80021d58 <disk+0x128>
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	c08080e7          	jalr	-1016(ra) # 80000c86 <release>
}
    80006086:	70a6                	ld	ra,104(sp)
    80006088:	7406                	ld	s0,96(sp)
    8000608a:	64e6                	ld	s1,88(sp)
    8000608c:	6946                	ld	s2,80(sp)
    8000608e:	69a6                	ld	s3,72(sp)
    80006090:	6a06                	ld	s4,64(sp)
    80006092:	7ae2                	ld	s5,56(sp)
    80006094:	7b42                	ld	s6,48(sp)
    80006096:	7ba2                	ld	s7,40(sp)
    80006098:	7c02                	ld	s8,32(sp)
    8000609a:	6ce2                	ld	s9,24(sp)
    8000609c:	6d42                	ld	s10,16(sp)
    8000609e:	6165                	addi	sp,sp,112
    800060a0:	8082                	ret

00000000800060a2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060a2:	1101                	addi	sp,sp,-32
    800060a4:	ec06                	sd	ra,24(sp)
    800060a6:	e822                	sd	s0,16(sp)
    800060a8:	e426                	sd	s1,8(sp)
    800060aa:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060ac:	0001c497          	auipc	s1,0x1c
    800060b0:	b8448493          	addi	s1,s1,-1148 # 80021c30 <disk>
    800060b4:	0001c517          	auipc	a0,0x1c
    800060b8:	ca450513          	addi	a0,a0,-860 # 80021d58 <disk+0x128>
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	b16080e7          	jalr	-1258(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060c4:	10001737          	lui	a4,0x10001
    800060c8:	533c                	lw	a5,96(a4)
    800060ca:	8b8d                	andi	a5,a5,3
    800060cc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060ce:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060d2:	689c                	ld	a5,16(s1)
    800060d4:	0204d703          	lhu	a4,32(s1)
    800060d8:	0027d783          	lhu	a5,2(a5)
    800060dc:	04f70863          	beq	a4,a5,8000612c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800060e0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060e4:	6898                	ld	a4,16(s1)
    800060e6:	0204d783          	lhu	a5,32(s1)
    800060ea:	8b9d                	andi	a5,a5,7
    800060ec:	078e                	slli	a5,a5,0x3
    800060ee:	97ba                	add	a5,a5,a4
    800060f0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060f2:	00278713          	addi	a4,a5,2
    800060f6:	0712                	slli	a4,a4,0x4
    800060f8:	9726                	add	a4,a4,s1
    800060fa:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800060fe:	e721                	bnez	a4,80006146 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006100:	0789                	addi	a5,a5,2
    80006102:	0792                	slli	a5,a5,0x4
    80006104:	97a6                	add	a5,a5,s1
    80006106:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006108:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000610c:	ffffc097          	auipc	ra,0xffffc
    80006110:	f96080e7          	jalr	-106(ra) # 800020a2 <wakeup>

    disk.used_idx += 1;
    80006114:	0204d783          	lhu	a5,32(s1)
    80006118:	2785                	addiw	a5,a5,1
    8000611a:	17c2                	slli	a5,a5,0x30
    8000611c:	93c1                	srli	a5,a5,0x30
    8000611e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006122:	6898                	ld	a4,16(s1)
    80006124:	00275703          	lhu	a4,2(a4)
    80006128:	faf71ce3          	bne	a4,a5,800060e0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000612c:	0001c517          	auipc	a0,0x1c
    80006130:	c2c50513          	addi	a0,a0,-980 # 80021d58 <disk+0x128>
    80006134:	ffffb097          	auipc	ra,0xffffb
    80006138:	b52080e7          	jalr	-1198(ra) # 80000c86 <release>
}
    8000613c:	60e2                	ld	ra,24(sp)
    8000613e:	6442                	ld	s0,16(sp)
    80006140:	64a2                	ld	s1,8(sp)
    80006142:	6105                	addi	sp,sp,32
    80006144:	8082                	ret
      panic("virtio_disk_intr status");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	70a50513          	addi	a0,a0,1802 # 80008850 <syscalls+0x3e0>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3ee080e7          	jalr	1006(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
