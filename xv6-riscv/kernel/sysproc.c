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
sys_ps(void)
{
  // EEE3535-01 Operating Systems
  // Assignment 1: Process and System Call

  int args[6];
  for (int i=0; i<6; i++) {
    argint(i, &args[i]);
  }

  printf("PID\tState\tRuntime\tName\n");

  //  proc proc[NPROC]; <- cycle through
  // X(RUNNING):-4 | S(SLEEPING):-2 | R(RUNNABLE):-3 | Z(ZOMBIE):-5
  // proc.state: 4 -> X | 3 -> R | 2 -> S | 5 -> Z


  for (int i=0; i<NPROC; i++) {

    char state[] = "0";
    switch (proc->state) {
      case 2:
        state[0] = 'S';
        break;
      case 3:
        state[0] = 'R';
        break;
      case 4:
        state[0] = 'X';
        break;
      case 5:
        state[0] = 'Z';
        break;
      default:
        state[0] = '0';
        break;
    }
    // filter process
    int match = 0;
    int pid = proc[i].pid;
    for (int i=0; i<6; i++) {
      // if no input args -> print all
      if ((args[0] == 0) && (pid != 0)) {
        match = 1;
      }
      if ((pid == args[i]) && (pid != 0)) {
        match = 1;
        break;
      }
      if ((proc->state == (-1*args[i])) && (pid != 0)) {
        match = 1;
        break;
      }
    }

    // print out process info
    if (!match) continue;
    int runtime = ticks - proc[i].starttime;
    int sec = (runtime / 10) % 60;
    int sec_d = runtime % 10;
    int min = runtime / 600;
    printf("%d\t%s\t%d:%d.%d\t%s\n", pid, state, min, sec, sec_d, proc[i].name);
  }

  //error -> return non-zero
  return 0;
}
