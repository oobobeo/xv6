
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <print_help>:

// A xv6-riscv syscall can take up to six arguments.
#define max_args 6

// Print a help message.
void print_help(int argc, char **argv) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  fprintf(2, "%s <options: pid or S/R/X/Z>%s\n",
   8:	6190                	ld	a2,0(a1)
   a:	479d                	li	a5,7
   c:	00001697          	auipc	a3,0x1
  10:	85468693          	addi	a3,a3,-1964 # 860 <malloc+0x100>
  14:	00a7d663          	bge	a5,a0,20 <print_help+0x20>
  18:	00001697          	auipc	a3,0x1
  1c:	83868693          	addi	a3,a3,-1992 # 850 <malloc+0xf0>
  20:	00001597          	auipc	a1,0x1
  24:	84858593          	addi	a1,a1,-1976 # 868 <malloc+0x108>
  28:	4509                	li	a0,2
  2a:	00000097          	auipc	ra,0x0
  2e:	650080e7          	jalr	1616(ra) # 67a <fprintf>
             argv[0], argc > 7 ? ": too many args" : "");
}
  32:	60a2                	ld	ra,8(sp)
  34:	6402                	ld	s0,0(sp)
  36:	0141                	addi	sp,sp,16
  38:	8082                	ret

000000000000003a <main>:

int main(int argc, char **argv) {
  3a:	7179                	addi	sp,sp,-48
  3c:	f406                	sd	ra,40(sp)
  3e:	f022                	sd	s0,32(sp)
  40:	1800                	addi	s0,sp,48
  // Print a help message.
  if(argc > 7) { print_help(argc, argv); exit(1); }
  42:	479d                	li	a5,7
  44:	00a7db63          	bge	a5,a0,5a <main+0x20>
  48:	00000097          	auipc	ra,0x0
  4c:	fb8080e7          	jalr	-72(ra) # 0 <print_help>
  50:	4505                	li	a0,1
  52:	00000097          	auipc	ra,0x0
  56:	2e6080e7          	jalr	742(ra) # 338 <exit>

  // Argument vector
  int args[max_args];
  memset(args, 0, max_args * sizeof(int));
  5a:	4661                	li	a2,24
  5c:	4581                	li	a1,0
  5e:	fd840513          	addi	a0,s0,-40
  62:	00000097          	auipc	ra,0x0
  66:	0dc080e7          	jalr	220(ra) # 13e <memset>
     Convert char inputs of argv[] into appropriate integers in args[].
     In this skeleton code, args[] is initialized to zeros,
     so technically no arguments are passed to the ps() syscall. */

  // Call the ps() syscall.
  int ret = ps(args[0], args[1], args[2], args[3], args[4], args[5]);
  6a:	fec42783          	lw	a5,-20(s0)
  6e:	fe842703          	lw	a4,-24(s0)
  72:	fe442683          	lw	a3,-28(s0)
  76:	fe042603          	lw	a2,-32(s0)
  7a:	fdc42583          	lw	a1,-36(s0)
  7e:	fd842503          	lw	a0,-40(s0)
  82:	00000097          	auipc	ra,0x0
  86:	356080e7          	jalr	854(ra) # 3d8 <ps>
  if(ret) { fprintf(2, "ps failed\n"); exit(1); }
  8a:	cd19                	beqz	a0,a8 <main+0x6e>
  8c:	00000597          	auipc	a1,0x0
  90:	7fc58593          	addi	a1,a1,2044 # 888 <malloc+0x128>
  94:	4509                	li	a0,2
  96:	00000097          	auipc	ra,0x0
  9a:	5e4080e7          	jalr	1508(ra) # 67a <fprintf>
  9e:	4505                	li	a0,1
  a0:	00000097          	auipc	ra,0x0
  a4:	298080e7          	jalr	664(ra) # 338 <exit>

  exit(0);
  a8:	4501                	li	a0,0
  aa:	00000097          	auipc	ra,0x0
  ae:	28e080e7          	jalr	654(ra) # 338 <exit>

00000000000000b2 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  b2:	1141                	addi	sp,sp,-16
  b4:	e406                	sd	ra,8(sp)
  b6:	e022                	sd	s0,0(sp)
  b8:	0800                	addi	s0,sp,16
  extern int main();
  main();
  ba:	00000097          	auipc	ra,0x0
  be:	f80080e7          	jalr	-128(ra) # 3a <main>
  exit(0);
  c2:	4501                	li	a0,0
  c4:	00000097          	auipc	ra,0x0
  c8:	274080e7          	jalr	628(ra) # 338 <exit>

00000000000000cc <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e422                	sd	s0,8(sp)
  d0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  d2:	87aa                	mv	a5,a0
  d4:	0585                	addi	a1,a1,1
  d6:	0785                	addi	a5,a5,1
  d8:	fff5c703          	lbu	a4,-1(a1)
  dc:	fee78fa3          	sb	a4,-1(a5)
  e0:	fb75                	bnez	a4,d4 <strcpy+0x8>
    ;
  return os;
}
  e2:	6422                	ld	s0,8(sp)
  e4:	0141                	addi	sp,sp,16
  e6:	8082                	ret

00000000000000e8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  e8:	1141                	addi	sp,sp,-16
  ea:	e422                	sd	s0,8(sp)
  ec:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  ee:	00054783          	lbu	a5,0(a0)
  f2:	cb91                	beqz	a5,106 <strcmp+0x1e>
  f4:	0005c703          	lbu	a4,0(a1)
  f8:	00f71763          	bne	a4,a5,106 <strcmp+0x1e>
    p++, q++;
  fc:	0505                	addi	a0,a0,1
  fe:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 100:	00054783          	lbu	a5,0(a0)
 104:	fbe5                	bnez	a5,f4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 106:	0005c503          	lbu	a0,0(a1)
}
 10a:	40a7853b          	subw	a0,a5,a0
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret

0000000000000114 <strlen>:

uint
strlen(const char *s)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cf91                	beqz	a5,13a <strlen+0x26>
 120:	0505                	addi	a0,a0,1
 122:	87aa                	mv	a5,a0
 124:	86be                	mv	a3,a5
 126:	0785                	addi	a5,a5,1
 128:	fff7c703          	lbu	a4,-1(a5)
 12c:	ff65                	bnez	a4,124 <strlen+0x10>
 12e:	40a6853b          	subw	a0,a3,a0
 132:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 134:	6422                	ld	s0,8(sp)
 136:	0141                	addi	sp,sp,16
 138:	8082                	ret
  for(n = 0; s[n]; n++)
 13a:	4501                	li	a0,0
 13c:	bfe5                	j	134 <strlen+0x20>

000000000000013e <memset>:

void*
memset(void *dst, int c, uint n)
{
 13e:	1141                	addi	sp,sp,-16
 140:	e422                	sd	s0,8(sp)
 142:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 144:	ca19                	beqz	a2,15a <memset+0x1c>
 146:	87aa                	mv	a5,a0
 148:	1602                	slli	a2,a2,0x20
 14a:	9201                	srli	a2,a2,0x20
 14c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 150:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 154:	0785                	addi	a5,a5,1
 156:	fee79de3          	bne	a5,a4,150 <memset+0x12>
  }
  return dst;
}
 15a:	6422                	ld	s0,8(sp)
 15c:	0141                	addi	sp,sp,16
 15e:	8082                	ret

0000000000000160 <strchr>:

char*
strchr(const char *s, char c)
{
 160:	1141                	addi	sp,sp,-16
 162:	e422                	sd	s0,8(sp)
 164:	0800                	addi	s0,sp,16
  for(; *s; s++)
 166:	00054783          	lbu	a5,0(a0)
 16a:	cb99                	beqz	a5,180 <strchr+0x20>
    if(*s == c)
 16c:	00f58763          	beq	a1,a5,17a <strchr+0x1a>
  for(; *s; s++)
 170:	0505                	addi	a0,a0,1
 172:	00054783          	lbu	a5,0(a0)
 176:	fbfd                	bnez	a5,16c <strchr+0xc>
      return (char*)s;
  return 0;
 178:	4501                	li	a0,0
}
 17a:	6422                	ld	s0,8(sp)
 17c:	0141                	addi	sp,sp,16
 17e:	8082                	ret
  return 0;
 180:	4501                	li	a0,0
 182:	bfe5                	j	17a <strchr+0x1a>

0000000000000184 <gets>:

char*
gets(char *buf, int max)
{
 184:	711d                	addi	sp,sp,-96
 186:	ec86                	sd	ra,88(sp)
 188:	e8a2                	sd	s0,80(sp)
 18a:	e4a6                	sd	s1,72(sp)
 18c:	e0ca                	sd	s2,64(sp)
 18e:	fc4e                	sd	s3,56(sp)
 190:	f852                	sd	s4,48(sp)
 192:	f456                	sd	s5,40(sp)
 194:	f05a                	sd	s6,32(sp)
 196:	ec5e                	sd	s7,24(sp)
 198:	1080                	addi	s0,sp,96
 19a:	8baa                	mv	s7,a0
 19c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 19e:	892a                	mv	s2,a0
 1a0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1a2:	4aa9                	li	s5,10
 1a4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1a6:	89a6                	mv	s3,s1
 1a8:	2485                	addiw	s1,s1,1
 1aa:	0344d863          	bge	s1,s4,1da <gets+0x56>
    cc = read(0, &c, 1);
 1ae:	4605                	li	a2,1
 1b0:	faf40593          	addi	a1,s0,-81
 1b4:	4501                	li	a0,0
 1b6:	00000097          	auipc	ra,0x0
 1ba:	19a080e7          	jalr	410(ra) # 350 <read>
    if(cc < 1)
 1be:	00a05e63          	blez	a0,1da <gets+0x56>
    buf[i++] = c;
 1c2:	faf44783          	lbu	a5,-81(s0)
 1c6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ca:	01578763          	beq	a5,s5,1d8 <gets+0x54>
 1ce:	0905                	addi	s2,s2,1
 1d0:	fd679be3          	bne	a5,s6,1a6 <gets+0x22>
  for(i=0; i+1 < max; ){
 1d4:	89a6                	mv	s3,s1
 1d6:	a011                	j	1da <gets+0x56>
 1d8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1da:	99de                	add	s3,s3,s7
 1dc:	00098023          	sb	zero,0(s3)
  return buf;
}
 1e0:	855e                	mv	a0,s7
 1e2:	60e6                	ld	ra,88(sp)
 1e4:	6446                	ld	s0,80(sp)
 1e6:	64a6                	ld	s1,72(sp)
 1e8:	6906                	ld	s2,64(sp)
 1ea:	79e2                	ld	s3,56(sp)
 1ec:	7a42                	ld	s4,48(sp)
 1ee:	7aa2                	ld	s5,40(sp)
 1f0:	7b02                	ld	s6,32(sp)
 1f2:	6be2                	ld	s7,24(sp)
 1f4:	6125                	addi	sp,sp,96
 1f6:	8082                	ret

00000000000001f8 <stat>:

int
stat(const char *n, struct stat *st)
{
 1f8:	1101                	addi	sp,sp,-32
 1fa:	ec06                	sd	ra,24(sp)
 1fc:	e822                	sd	s0,16(sp)
 1fe:	e426                	sd	s1,8(sp)
 200:	e04a                	sd	s2,0(sp)
 202:	1000                	addi	s0,sp,32
 204:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 206:	4581                	li	a1,0
 208:	00000097          	auipc	ra,0x0
 20c:	170080e7          	jalr	368(ra) # 378 <open>
  if(fd < 0)
 210:	02054563          	bltz	a0,23a <stat+0x42>
 214:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 216:	85ca                	mv	a1,s2
 218:	00000097          	auipc	ra,0x0
 21c:	178080e7          	jalr	376(ra) # 390 <fstat>
 220:	892a                	mv	s2,a0
  close(fd);
 222:	8526                	mv	a0,s1
 224:	00000097          	auipc	ra,0x0
 228:	13c080e7          	jalr	316(ra) # 360 <close>
  return r;
}
 22c:	854a                	mv	a0,s2
 22e:	60e2                	ld	ra,24(sp)
 230:	6442                	ld	s0,16(sp)
 232:	64a2                	ld	s1,8(sp)
 234:	6902                	ld	s2,0(sp)
 236:	6105                	addi	sp,sp,32
 238:	8082                	ret
    return -1;
 23a:	597d                	li	s2,-1
 23c:	bfc5                	j	22c <stat+0x34>

000000000000023e <atoi>:

int
atoi(const char *s)
{
 23e:	1141                	addi	sp,sp,-16
 240:	e422                	sd	s0,8(sp)
 242:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 244:	00054683          	lbu	a3,0(a0)
 248:	fd06879b          	addiw	a5,a3,-48
 24c:	0ff7f793          	zext.b	a5,a5
 250:	4625                	li	a2,9
 252:	02f66863          	bltu	a2,a5,282 <atoi+0x44>
 256:	872a                	mv	a4,a0
  n = 0;
 258:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 25a:	0705                	addi	a4,a4,1
 25c:	0025179b          	slliw	a5,a0,0x2
 260:	9fa9                	addw	a5,a5,a0
 262:	0017979b          	slliw	a5,a5,0x1
 266:	9fb5                	addw	a5,a5,a3
 268:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 26c:	00074683          	lbu	a3,0(a4)
 270:	fd06879b          	addiw	a5,a3,-48
 274:	0ff7f793          	zext.b	a5,a5
 278:	fef671e3          	bgeu	a2,a5,25a <atoi+0x1c>
  return n;
}
 27c:	6422                	ld	s0,8(sp)
 27e:	0141                	addi	sp,sp,16
 280:	8082                	ret
  n = 0;
 282:	4501                	li	a0,0
 284:	bfe5                	j	27c <atoi+0x3e>

0000000000000286 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 286:	1141                	addi	sp,sp,-16
 288:	e422                	sd	s0,8(sp)
 28a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 28c:	02b57463          	bgeu	a0,a1,2b4 <memmove+0x2e>
    while(n-- > 0)
 290:	00c05f63          	blez	a2,2ae <memmove+0x28>
 294:	1602                	slli	a2,a2,0x20
 296:	9201                	srli	a2,a2,0x20
 298:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 29c:	872a                	mv	a4,a0
      *dst++ = *src++;
 29e:	0585                	addi	a1,a1,1
 2a0:	0705                	addi	a4,a4,1
 2a2:	fff5c683          	lbu	a3,-1(a1)
 2a6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2aa:	fee79ae3          	bne	a5,a4,29e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret
    dst += n;
 2b4:	00c50733          	add	a4,a0,a2
    src += n;
 2b8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ba:	fec05ae3          	blez	a2,2ae <memmove+0x28>
 2be:	fff6079b          	addiw	a5,a2,-1
 2c2:	1782                	slli	a5,a5,0x20
 2c4:	9381                	srli	a5,a5,0x20
 2c6:	fff7c793          	not	a5,a5
 2ca:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2cc:	15fd                	addi	a1,a1,-1
 2ce:	177d                	addi	a4,a4,-1
 2d0:	0005c683          	lbu	a3,0(a1)
 2d4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2d8:	fee79ae3          	bne	a5,a4,2cc <memmove+0x46>
 2dc:	bfc9                	j	2ae <memmove+0x28>

00000000000002de <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2de:	1141                	addi	sp,sp,-16
 2e0:	e422                	sd	s0,8(sp)
 2e2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2e4:	ca05                	beqz	a2,314 <memcmp+0x36>
 2e6:	fff6069b          	addiw	a3,a2,-1
 2ea:	1682                	slli	a3,a3,0x20
 2ec:	9281                	srli	a3,a3,0x20
 2ee:	0685                	addi	a3,a3,1
 2f0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2f2:	00054783          	lbu	a5,0(a0)
 2f6:	0005c703          	lbu	a4,0(a1)
 2fa:	00e79863          	bne	a5,a4,30a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2fe:	0505                	addi	a0,a0,1
    p2++;
 300:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 302:	fed518e3          	bne	a0,a3,2f2 <memcmp+0x14>
  }
  return 0;
 306:	4501                	li	a0,0
 308:	a019                	j	30e <memcmp+0x30>
      return *p1 - *p2;
 30a:	40e7853b          	subw	a0,a5,a4
}
 30e:	6422                	ld	s0,8(sp)
 310:	0141                	addi	sp,sp,16
 312:	8082                	ret
  return 0;
 314:	4501                	li	a0,0
 316:	bfe5                	j	30e <memcmp+0x30>

0000000000000318 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 318:	1141                	addi	sp,sp,-16
 31a:	e406                	sd	ra,8(sp)
 31c:	e022                	sd	s0,0(sp)
 31e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 320:	00000097          	auipc	ra,0x0
 324:	f66080e7          	jalr	-154(ra) # 286 <memmove>
}
 328:	60a2                	ld	ra,8(sp)
 32a:	6402                	ld	s0,0(sp)
 32c:	0141                	addi	sp,sp,16
 32e:	8082                	ret

0000000000000330 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 330:	4885                	li	a7,1
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <exit>:
.global exit
exit:
 li a7, SYS_exit
 338:	4889                	li	a7,2
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <wait>:
.global wait
wait:
 li a7, SYS_wait
 340:	488d                	li	a7,3
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 348:	4891                	li	a7,4
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <read>:
.global read
read:
 li a7, SYS_read
 350:	4895                	li	a7,5
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <write>:
.global write
write:
 li a7, SYS_write
 358:	48c1                	li	a7,16
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <close>:
.global close
close:
 li a7, SYS_close
 360:	48d5                	li	a7,21
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <kill>:
.global kill
kill:
 li a7, SYS_kill
 368:	4899                	li	a7,6
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <exec>:
.global exec
exec:
 li a7, SYS_exec
 370:	489d                	li	a7,7
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <open>:
.global open
open:
 li a7, SYS_open
 378:	48bd                	li	a7,15
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 380:	48c5                	li	a7,17
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 388:	48c9                	li	a7,18
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 390:	48a1                	li	a7,8
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <link>:
.global link
link:
 li a7, SYS_link
 398:	48cd                	li	a7,19
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3a0:	48d1                	li	a7,20
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3a8:	48a5                	li	a7,9
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3b0:	48a9                	li	a7,10
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3b8:	48ad                	li	a7,11
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3c0:	48b1                	li	a7,12
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3c8:	48b5                	li	a7,13
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3d0:	48b9                	li	a7,14
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <ps>:
.global ps
ps:
 li a7, SYS_ps
 3d8:	48d9                	li	a7,22
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3e0:	1101                	addi	sp,sp,-32
 3e2:	ec06                	sd	ra,24(sp)
 3e4:	e822                	sd	s0,16(sp)
 3e6:	1000                	addi	s0,sp,32
 3e8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3ec:	4605                	li	a2,1
 3ee:	fef40593          	addi	a1,s0,-17
 3f2:	00000097          	auipc	ra,0x0
 3f6:	f66080e7          	jalr	-154(ra) # 358 <write>
}
 3fa:	60e2                	ld	ra,24(sp)
 3fc:	6442                	ld	s0,16(sp)
 3fe:	6105                	addi	sp,sp,32
 400:	8082                	ret

0000000000000402 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 402:	7139                	addi	sp,sp,-64
 404:	fc06                	sd	ra,56(sp)
 406:	f822                	sd	s0,48(sp)
 408:	f426                	sd	s1,40(sp)
 40a:	f04a                	sd	s2,32(sp)
 40c:	ec4e                	sd	s3,24(sp)
 40e:	0080                	addi	s0,sp,64
 410:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 412:	c299                	beqz	a3,418 <printint+0x16>
 414:	0805c963          	bltz	a1,4a6 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 418:	2581                	sext.w	a1,a1
  neg = 0;
 41a:	4881                	li	a7,0
 41c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 420:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 422:	2601                	sext.w	a2,a2
 424:	00000517          	auipc	a0,0x0
 428:	4d450513          	addi	a0,a0,1236 # 8f8 <digits>
 42c:	883a                	mv	a6,a4
 42e:	2705                	addiw	a4,a4,1
 430:	02c5f7bb          	remuw	a5,a1,a2
 434:	1782                	slli	a5,a5,0x20
 436:	9381                	srli	a5,a5,0x20
 438:	97aa                	add	a5,a5,a0
 43a:	0007c783          	lbu	a5,0(a5)
 43e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 442:	0005879b          	sext.w	a5,a1
 446:	02c5d5bb          	divuw	a1,a1,a2
 44a:	0685                	addi	a3,a3,1
 44c:	fec7f0e3          	bgeu	a5,a2,42c <printint+0x2a>
  if(neg)
 450:	00088c63          	beqz	a7,468 <printint+0x66>
    buf[i++] = '-';
 454:	fd070793          	addi	a5,a4,-48
 458:	00878733          	add	a4,a5,s0
 45c:	02d00793          	li	a5,45
 460:	fef70823          	sb	a5,-16(a4)
 464:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 468:	02e05863          	blez	a4,498 <printint+0x96>
 46c:	fc040793          	addi	a5,s0,-64
 470:	00e78933          	add	s2,a5,a4
 474:	fff78993          	addi	s3,a5,-1
 478:	99ba                	add	s3,s3,a4
 47a:	377d                	addiw	a4,a4,-1
 47c:	1702                	slli	a4,a4,0x20
 47e:	9301                	srli	a4,a4,0x20
 480:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 484:	fff94583          	lbu	a1,-1(s2)
 488:	8526                	mv	a0,s1
 48a:	00000097          	auipc	ra,0x0
 48e:	f56080e7          	jalr	-170(ra) # 3e0 <putc>
  while(--i >= 0)
 492:	197d                	addi	s2,s2,-1
 494:	ff3918e3          	bne	s2,s3,484 <printint+0x82>
}
 498:	70e2                	ld	ra,56(sp)
 49a:	7442                	ld	s0,48(sp)
 49c:	74a2                	ld	s1,40(sp)
 49e:	7902                	ld	s2,32(sp)
 4a0:	69e2                	ld	s3,24(sp)
 4a2:	6121                	addi	sp,sp,64
 4a4:	8082                	ret
    x = -xx;
 4a6:	40b005bb          	negw	a1,a1
    neg = 1;
 4aa:	4885                	li	a7,1
    x = -xx;
 4ac:	bf85                	j	41c <printint+0x1a>

00000000000004ae <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ae:	715d                	addi	sp,sp,-80
 4b0:	e486                	sd	ra,72(sp)
 4b2:	e0a2                	sd	s0,64(sp)
 4b4:	fc26                	sd	s1,56(sp)
 4b6:	f84a                	sd	s2,48(sp)
 4b8:	f44e                	sd	s3,40(sp)
 4ba:	f052                	sd	s4,32(sp)
 4bc:	ec56                	sd	s5,24(sp)
 4be:	e85a                	sd	s6,16(sp)
 4c0:	e45e                	sd	s7,8(sp)
 4c2:	e062                	sd	s8,0(sp)
 4c4:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4c6:	0005c903          	lbu	s2,0(a1)
 4ca:	18090c63          	beqz	s2,662 <vprintf+0x1b4>
 4ce:	8aaa                	mv	s5,a0
 4d0:	8bb2                	mv	s7,a2
 4d2:	00158493          	addi	s1,a1,1
  state = 0;
 4d6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d8:	02500a13          	li	s4,37
 4dc:	4b55                	li	s6,21
 4de:	a839                	j	4fc <vprintf+0x4e>
        putc(fd, c);
 4e0:	85ca                	mv	a1,s2
 4e2:	8556                	mv	a0,s5
 4e4:	00000097          	auipc	ra,0x0
 4e8:	efc080e7          	jalr	-260(ra) # 3e0 <putc>
 4ec:	a019                	j	4f2 <vprintf+0x44>
    } else if(state == '%'){
 4ee:	01498d63          	beq	s3,s4,508 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 4f2:	0485                	addi	s1,s1,1
 4f4:	fff4c903          	lbu	s2,-1(s1)
 4f8:	16090563          	beqz	s2,662 <vprintf+0x1b4>
    if(state == 0){
 4fc:	fe0999e3          	bnez	s3,4ee <vprintf+0x40>
      if(c == '%'){
 500:	ff4910e3          	bne	s2,s4,4e0 <vprintf+0x32>
        state = '%';
 504:	89d2                	mv	s3,s4
 506:	b7f5                	j	4f2 <vprintf+0x44>
      if(c == 'd'){
 508:	13490263          	beq	s2,s4,62c <vprintf+0x17e>
 50c:	f9d9079b          	addiw	a5,s2,-99
 510:	0ff7f793          	zext.b	a5,a5
 514:	12fb6563          	bltu	s6,a5,63e <vprintf+0x190>
 518:	f9d9079b          	addiw	a5,s2,-99
 51c:	0ff7f713          	zext.b	a4,a5
 520:	10eb6f63          	bltu	s6,a4,63e <vprintf+0x190>
 524:	00271793          	slli	a5,a4,0x2
 528:	00000717          	auipc	a4,0x0
 52c:	37870713          	addi	a4,a4,888 # 8a0 <malloc+0x140>
 530:	97ba                	add	a5,a5,a4
 532:	439c                	lw	a5,0(a5)
 534:	97ba                	add	a5,a5,a4
 536:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 538:	008b8913          	addi	s2,s7,8
 53c:	4685                	li	a3,1
 53e:	4629                	li	a2,10
 540:	000ba583          	lw	a1,0(s7)
 544:	8556                	mv	a0,s5
 546:	00000097          	auipc	ra,0x0
 54a:	ebc080e7          	jalr	-324(ra) # 402 <printint>
 54e:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 550:	4981                	li	s3,0
 552:	b745                	j	4f2 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 554:	008b8913          	addi	s2,s7,8
 558:	4681                	li	a3,0
 55a:	4629                	li	a2,10
 55c:	000ba583          	lw	a1,0(s7)
 560:	8556                	mv	a0,s5
 562:	00000097          	auipc	ra,0x0
 566:	ea0080e7          	jalr	-352(ra) # 402 <printint>
 56a:	8bca                	mv	s7,s2
      state = 0;
 56c:	4981                	li	s3,0
 56e:	b751                	j	4f2 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 570:	008b8913          	addi	s2,s7,8
 574:	4681                	li	a3,0
 576:	4641                	li	a2,16
 578:	000ba583          	lw	a1,0(s7)
 57c:	8556                	mv	a0,s5
 57e:	00000097          	auipc	ra,0x0
 582:	e84080e7          	jalr	-380(ra) # 402 <printint>
 586:	8bca                	mv	s7,s2
      state = 0;
 588:	4981                	li	s3,0
 58a:	b7a5                	j	4f2 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 58c:	008b8c13          	addi	s8,s7,8
 590:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 594:	03000593          	li	a1,48
 598:	8556                	mv	a0,s5
 59a:	00000097          	auipc	ra,0x0
 59e:	e46080e7          	jalr	-442(ra) # 3e0 <putc>
  putc(fd, 'x');
 5a2:	07800593          	li	a1,120
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	e38080e7          	jalr	-456(ra) # 3e0 <putc>
 5b0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5b2:	00000b97          	auipc	s7,0x0
 5b6:	346b8b93          	addi	s7,s7,838 # 8f8 <digits>
 5ba:	03c9d793          	srli	a5,s3,0x3c
 5be:	97de                	add	a5,a5,s7
 5c0:	0007c583          	lbu	a1,0(a5)
 5c4:	8556                	mv	a0,s5
 5c6:	00000097          	auipc	ra,0x0
 5ca:	e1a080e7          	jalr	-486(ra) # 3e0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5ce:	0992                	slli	s3,s3,0x4
 5d0:	397d                	addiw	s2,s2,-1
 5d2:	fe0914e3          	bnez	s2,5ba <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5d6:	8be2                	mv	s7,s8
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	bf21                	j	4f2 <vprintf+0x44>
        s = va_arg(ap, char*);
 5dc:	008b8993          	addi	s3,s7,8
 5e0:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5e4:	02090163          	beqz	s2,606 <vprintf+0x158>
        while(*s != 0){
 5e8:	00094583          	lbu	a1,0(s2)
 5ec:	c9a5                	beqz	a1,65c <vprintf+0x1ae>
          putc(fd, *s);
 5ee:	8556                	mv	a0,s5
 5f0:	00000097          	auipc	ra,0x0
 5f4:	df0080e7          	jalr	-528(ra) # 3e0 <putc>
          s++;
 5f8:	0905                	addi	s2,s2,1
        while(*s != 0){
 5fa:	00094583          	lbu	a1,0(s2)
 5fe:	f9e5                	bnez	a1,5ee <vprintf+0x140>
        s = va_arg(ap, char*);
 600:	8bce                	mv	s7,s3
      state = 0;
 602:	4981                	li	s3,0
 604:	b5fd                	j	4f2 <vprintf+0x44>
          s = "(null)";
 606:	00000917          	auipc	s2,0x0
 60a:	29290913          	addi	s2,s2,658 # 898 <malloc+0x138>
        while(*s != 0){
 60e:	02800593          	li	a1,40
 612:	bff1                	j	5ee <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 614:	008b8913          	addi	s2,s7,8
 618:	000bc583          	lbu	a1,0(s7)
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	dc2080e7          	jalr	-574(ra) # 3e0 <putc>
 626:	8bca                	mv	s7,s2
      state = 0;
 628:	4981                	li	s3,0
 62a:	b5e1                	j	4f2 <vprintf+0x44>
        putc(fd, c);
 62c:	02500593          	li	a1,37
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	dae080e7          	jalr	-594(ra) # 3e0 <putc>
      state = 0;
 63a:	4981                	li	s3,0
 63c:	bd5d                	j	4f2 <vprintf+0x44>
        putc(fd, '%');
 63e:	02500593          	li	a1,37
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	d9c080e7          	jalr	-612(ra) # 3e0 <putc>
        putc(fd, c);
 64c:	85ca                	mv	a1,s2
 64e:	8556                	mv	a0,s5
 650:	00000097          	auipc	ra,0x0
 654:	d90080e7          	jalr	-624(ra) # 3e0 <putc>
      state = 0;
 658:	4981                	li	s3,0
 65a:	bd61                	j	4f2 <vprintf+0x44>
        s = va_arg(ap, char*);
 65c:	8bce                	mv	s7,s3
      state = 0;
 65e:	4981                	li	s3,0
 660:	bd49                	j	4f2 <vprintf+0x44>
    }
  }
}
 662:	60a6                	ld	ra,72(sp)
 664:	6406                	ld	s0,64(sp)
 666:	74e2                	ld	s1,56(sp)
 668:	7942                	ld	s2,48(sp)
 66a:	79a2                	ld	s3,40(sp)
 66c:	7a02                	ld	s4,32(sp)
 66e:	6ae2                	ld	s5,24(sp)
 670:	6b42                	ld	s6,16(sp)
 672:	6ba2                	ld	s7,8(sp)
 674:	6c02                	ld	s8,0(sp)
 676:	6161                	addi	sp,sp,80
 678:	8082                	ret

000000000000067a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 67a:	715d                	addi	sp,sp,-80
 67c:	ec06                	sd	ra,24(sp)
 67e:	e822                	sd	s0,16(sp)
 680:	1000                	addi	s0,sp,32
 682:	e010                	sd	a2,0(s0)
 684:	e414                	sd	a3,8(s0)
 686:	e818                	sd	a4,16(s0)
 688:	ec1c                	sd	a5,24(s0)
 68a:	03043023          	sd	a6,32(s0)
 68e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 692:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 696:	8622                	mv	a2,s0
 698:	00000097          	auipc	ra,0x0
 69c:	e16080e7          	jalr	-490(ra) # 4ae <vprintf>
}
 6a0:	60e2                	ld	ra,24(sp)
 6a2:	6442                	ld	s0,16(sp)
 6a4:	6161                	addi	sp,sp,80
 6a6:	8082                	ret

00000000000006a8 <printf>:

void
printf(const char *fmt, ...)
{
 6a8:	711d                	addi	sp,sp,-96
 6aa:	ec06                	sd	ra,24(sp)
 6ac:	e822                	sd	s0,16(sp)
 6ae:	1000                	addi	s0,sp,32
 6b0:	e40c                	sd	a1,8(s0)
 6b2:	e810                	sd	a2,16(s0)
 6b4:	ec14                	sd	a3,24(s0)
 6b6:	f018                	sd	a4,32(s0)
 6b8:	f41c                	sd	a5,40(s0)
 6ba:	03043823          	sd	a6,48(s0)
 6be:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6c2:	00840613          	addi	a2,s0,8
 6c6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ca:	85aa                	mv	a1,a0
 6cc:	4505                	li	a0,1
 6ce:	00000097          	auipc	ra,0x0
 6d2:	de0080e7          	jalr	-544(ra) # 4ae <vprintf>
}
 6d6:	60e2                	ld	ra,24(sp)
 6d8:	6442                	ld	s0,16(sp)
 6da:	6125                	addi	sp,sp,96
 6dc:	8082                	ret

00000000000006de <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6de:	1141                	addi	sp,sp,-16
 6e0:	e422                	sd	s0,8(sp)
 6e2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6e4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e8:	00001797          	auipc	a5,0x1
 6ec:	9187b783          	ld	a5,-1768(a5) # 1000 <freep>
 6f0:	a02d                	j	71a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6f2:	4618                	lw	a4,8(a2)
 6f4:	9f2d                	addw	a4,a4,a1
 6f6:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6fa:	6398                	ld	a4,0(a5)
 6fc:	6310                	ld	a2,0(a4)
 6fe:	a83d                	j	73c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 700:	ff852703          	lw	a4,-8(a0)
 704:	9f31                	addw	a4,a4,a2
 706:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 708:	ff053683          	ld	a3,-16(a0)
 70c:	a091                	j	750 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 70e:	6398                	ld	a4,0(a5)
 710:	00e7e463          	bltu	a5,a4,718 <free+0x3a>
 714:	00e6ea63          	bltu	a3,a4,728 <free+0x4a>
{
 718:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 71a:	fed7fae3          	bgeu	a5,a3,70e <free+0x30>
 71e:	6398                	ld	a4,0(a5)
 720:	00e6e463          	bltu	a3,a4,728 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 724:	fee7eae3          	bltu	a5,a4,718 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 728:	ff852583          	lw	a1,-8(a0)
 72c:	6390                	ld	a2,0(a5)
 72e:	02059813          	slli	a6,a1,0x20
 732:	01c85713          	srli	a4,a6,0x1c
 736:	9736                	add	a4,a4,a3
 738:	fae60de3          	beq	a2,a4,6f2 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 73c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 740:	4790                	lw	a2,8(a5)
 742:	02061593          	slli	a1,a2,0x20
 746:	01c5d713          	srli	a4,a1,0x1c
 74a:	973e                	add	a4,a4,a5
 74c:	fae68ae3          	beq	a3,a4,700 <free+0x22>
    p->s.ptr = bp->s.ptr;
 750:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 752:	00001717          	auipc	a4,0x1
 756:	8af73723          	sd	a5,-1874(a4) # 1000 <freep>
}
 75a:	6422                	ld	s0,8(sp)
 75c:	0141                	addi	sp,sp,16
 75e:	8082                	ret

0000000000000760 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 760:	7139                	addi	sp,sp,-64
 762:	fc06                	sd	ra,56(sp)
 764:	f822                	sd	s0,48(sp)
 766:	f426                	sd	s1,40(sp)
 768:	f04a                	sd	s2,32(sp)
 76a:	ec4e                	sd	s3,24(sp)
 76c:	e852                	sd	s4,16(sp)
 76e:	e456                	sd	s5,8(sp)
 770:	e05a                	sd	s6,0(sp)
 772:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 774:	02051493          	slli	s1,a0,0x20
 778:	9081                	srli	s1,s1,0x20
 77a:	04bd                	addi	s1,s1,15
 77c:	8091                	srli	s1,s1,0x4
 77e:	0014899b          	addiw	s3,s1,1
 782:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 784:	00001517          	auipc	a0,0x1
 788:	87c53503          	ld	a0,-1924(a0) # 1000 <freep>
 78c:	c515                	beqz	a0,7b8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 78e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 790:	4798                	lw	a4,8(a5)
 792:	02977f63          	bgeu	a4,s1,7d0 <malloc+0x70>
  if(nu < 4096)
 796:	8a4e                	mv	s4,s3
 798:	0009871b          	sext.w	a4,s3
 79c:	6685                	lui	a3,0x1
 79e:	00d77363          	bgeu	a4,a3,7a4 <malloc+0x44>
 7a2:	6a05                	lui	s4,0x1
 7a4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7a8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7ac:	00001917          	auipc	s2,0x1
 7b0:	85490913          	addi	s2,s2,-1964 # 1000 <freep>
  if(p == (char*)-1)
 7b4:	5afd                	li	s5,-1
 7b6:	a895                	j	82a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7b8:	00001797          	auipc	a5,0x1
 7bc:	85878793          	addi	a5,a5,-1960 # 1010 <base>
 7c0:	00001717          	auipc	a4,0x1
 7c4:	84f73023          	sd	a5,-1984(a4) # 1000 <freep>
 7c8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ca:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7ce:	b7e1                	j	796 <malloc+0x36>
      if(p->s.size == nunits)
 7d0:	02e48c63          	beq	s1,a4,808 <malloc+0xa8>
        p->s.size -= nunits;
 7d4:	4137073b          	subw	a4,a4,s3
 7d8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7da:	02071693          	slli	a3,a4,0x20
 7de:	01c6d713          	srli	a4,a3,0x1c
 7e2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7e4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7e8:	00001717          	auipc	a4,0x1
 7ec:	80a73c23          	sd	a0,-2024(a4) # 1000 <freep>
      return (void*)(p + 1);
 7f0:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7f4:	70e2                	ld	ra,56(sp)
 7f6:	7442                	ld	s0,48(sp)
 7f8:	74a2                	ld	s1,40(sp)
 7fa:	7902                	ld	s2,32(sp)
 7fc:	69e2                	ld	s3,24(sp)
 7fe:	6a42                	ld	s4,16(sp)
 800:	6aa2                	ld	s5,8(sp)
 802:	6b02                	ld	s6,0(sp)
 804:	6121                	addi	sp,sp,64
 806:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 808:	6398                	ld	a4,0(a5)
 80a:	e118                	sd	a4,0(a0)
 80c:	bff1                	j	7e8 <malloc+0x88>
  hp->s.size = nu;
 80e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 812:	0541                	addi	a0,a0,16
 814:	00000097          	auipc	ra,0x0
 818:	eca080e7          	jalr	-310(ra) # 6de <free>
  return freep;
 81c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 820:	d971                	beqz	a0,7f4 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 822:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 824:	4798                	lw	a4,8(a5)
 826:	fa9775e3          	bgeu	a4,s1,7d0 <malloc+0x70>
    if(p == freep)
 82a:	00093703          	ld	a4,0(s2)
 82e:	853e                	mv	a0,a5
 830:	fef719e3          	bne	a4,a5,822 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 834:	8552                	mv	a0,s4
 836:	00000097          	auipc	ra,0x0
 83a:	b8a080e7          	jalr	-1142(ra) # 3c0 <sbrk>
  if(p == (char*)-1)
 83e:	fd5518e3          	bne	a0,s5,80e <malloc+0xae>
        return 0;
 842:	4501                	li	a0,0
 844:	bf45                	j	7f4 <malloc+0x94>
