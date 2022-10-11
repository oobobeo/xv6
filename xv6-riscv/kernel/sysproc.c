#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_gettime(void)
{
  struct proc *p = myproc();

  // ms
  int r = p->real_time;
  int u = p->user_time;
  int s = p->sys_time;

  // 0m0.00s
  int r_s2 = (r%100); // 10ms = 0.01s (1)
  int r_s1 = (r/100) % 60;
  int r_m = r/6000;

  int u_s2 = (u%100);
  int u_s1 = (u/100) % 60;
  int u_m = u/6000;

  int s_s2 = (s%100);
  int s_s1 = (s/100) % 60;
  int s_m = s/6000;

  char r_s2_c[] = "00";
  char u_s2_c[] = "00";
  char s_s2_c[] = "00";

  if (r_s2 <= 9) {
    r_s2_c[0] = '0';
    r_s2_c[1] = '0' + r_s2;
  }
  else {
    r_s2_c[0] = '0' + (r_s2 / 10);
    r_s2_c[1] = '0' + (r_s2 % 10);
  }

  if (u_s2 <= 9) {
    u_s2_c[0] = '0';
    u_s2_c[1] = '0' + u_s2;
  }
  else {
    u_s2_c[0] = '0' + (u_s2 / 10);
    u_s2_c[1] = '0' + (u_s2 % 10);
  }

  if (s_s2 <= 9) {
    s_s2_c[0] = '0';
    s_s2_c[1] = '0' + s_s2;
  }
  else {
    s_s2_c[0] = '0' + (s_s2 / 10);
    s_s2_c[1] = '0' + (s_s2 % 10);
  }

//  printf("%d %d %d\n",r,u,s);
  printf("real: %dm%d.%ss\n", r_m, r_s1, r_s2_c);
  printf("user: %dm%d.%ss\n", u_m, u_s1, u_s2_c);
  printf("sys:  %dm%d.%ss\n", s_m, s_s1, s_s2_c);

  return 0;
}
