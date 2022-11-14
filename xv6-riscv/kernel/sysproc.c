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

// MLFQ stats
uint64
sys_mlfq(void)
{
  /* Assignment 4: Scheduling
     Print MLFQ scheduling stats if the input argument is 0.
     Reset MLFQ counter values to zeros if the input argument is 1. */
//  int arg0, arg1;
//  argint(0, &arg0);
//  argint(1, &arg1);
//  if (arg1 == 0) {
//    struct proc* p;
//    printf("(Q3): ");
//    p = mlfq[3];
//    while (1) {
//      if(!p) break;
//      printf("%s ", p->name);
//    }
//    printf("\n");
//    printf("(Q2)");
//    p = mlfq[2];
//    while (1) {
//      if(!p) break;
//      printf("%s ", p->name);
//    }
//    printf("\n");
//    printf("(Q1)");
//    p = mlfq[1];
//    while (1) {
//      if(!p) break;
//      printf("%s ", p->name);
//    }
//    printf("\n");
//    printf("(Q0)");
//    p = mlfq[0];
//    while (1) {
//      if(!p) break;
//      printf("%s ", p->name);
//    }
//    printf("\n");
//
//
//  }






  return 0;
}
