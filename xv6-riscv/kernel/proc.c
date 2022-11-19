#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc* mlfq[LEVELS];
//struct proc* current_proc;
struct proc* first_proc; // proc that starts with the time slice
//int sched_reset = 0;
int first_proc_flag = 0;
int demote_flag = 0;
int next_boost = -1;

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid()
{
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // mlfq
  // put the new process at the END of the queue
  printf("\n<allocproc> %d\n", p->pid);
  struct proc* temp = mlfq[LEVELS-1];
  if (temp) { // if not empty
    // at the last of queue
    while (temp->next != 0) {
      temp = temp->next;
    } // pp: last in queue
    temp->next = p;
  }
  else {
    mlfq[LEVELS-1] = p;
  }
  p->next = 0;
  p->level = 3;
  p->allowance = 1;



  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

//  printf("mlfq[3]: ");
//  for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
//    printf("%d(%d)->", c->pid, c->state);
//  }
//  printf("\n");
//  printf("<allocproc> %d done\n", p->pid);
//  printf("\n");
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  printf("<freeproc> %d\n", p->pid);
  // dequeue from mlfq
  // search for current process in mlfq
  // update mlfq
//  struct proc* current;
//  struct proc* next;

  struct proc* pp = mlfq[p->level];
  if (pp == p) { // p was the first element
    mlfq[p->level] = p->next;
  }
  else { // p was NOT the fist element
    while (1) {
      if (pp->next == p) {
        pp->next = p->next;
        break;
      }
      pp = pp->next;
    }
  }
//
//  // reset p
  p->next = 0;
  p->level = -1;
  p->allowance = -1;

//  printf("mlfq[3]: ");
//  for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("mlfq[2]: ");
//  for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("mlfq[1]: ");
//  for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("mlfq[0]: ");
//  for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("\n");







  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(pp = proc; pp < &proc[NPROC]; pp++){
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
          // Found one.
          pid = pp->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                  sizeof(pp->xstate)) < 0) {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || killed(p)){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    // mlfq strategy
    // search mlfq from Q3->Q2->Q1->Q0
    // finds 1 process to run
    // after finding one, break
    // so that the searching can start from the top again

    // SELECT p in whole MLFQ
SEARCH:
    intr_on();

    // init has to stay at top at all times


//    printf("\n<SEARCH>\n");
    int proc_found_flag = 0;
    for(int i=LEVELS-1; i>=0; i--) {
//      printf("%d\n",i);

      p = mlfq[i];
      while (p) { // search this level for RUNNABLE proc
        if (p->state == RUNNABLE) {
//            printf("runnable: %d\n", p->pid);
          proc_found_flag = 1;
          if (first_proc_flag == 0) { // if first_proc is not recorded, this must be the first_proc
            first_proc_flag = 1;
            first_proc = p;
          }
          break;
        }
        else {
          p = p->next;
        }
      }

      if (!p && i==0) goto SEARCH; // no RUNNABLE proc in whole mlfq. ex) file io
      if (proc_found_flag) {
        break;
      }

    }



    printf("<RUN>: %d\n", p->pid);
    // RUN p
    // print every state
    if (p->pid != 1 && p->pid != 2) printf("BEFORE RUN %d(%d): \n", p->pid, p->state);
    if (p->pid != 1 && p->pid != 2) {
      printf("mlfq[3]: ");
      for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[2]: ");
      for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[1]: ");
      for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[0]: ");
      for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
    }

    acquire(&p->lock);
    if(p->state == RUNNABLE) {
      // Switch to chosen process.  It is the process's job
      // to release its lock and then reacquire it
      // before jumping back to us.
      p->state = RUNNING;
      c->proc = p;
      swtch(&c->context, &p->context);
      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
    }
    release(&p->lock);





    if (p->pid != 1 && p->pid != 2) printf("AFTER  RUN %d(%d)\n", p->pid, p->state);
//
//    // print every state
    if (p->pid != 1 && p->pid != 2) {
      printf("mlfq[3]: ");
      for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[2]: ");
      for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[1]: ");
      for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[0]: ");
      for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
    }
    if (p->pid != 1 && p->pid != 2) printf("---------\n");



    // MOVE p to BACK of QUEUE
    // if (demoted in yield()) -> back of demoted level queue
    // [scheduler() -> swtch() -> (running in cpu) -> yield() -> HERE]
    // p has to be RUNNABLE (not freeproc()'ed)
//    printf("\n%d | %d\n",p->pid,p->state);

//
    if (p->state != UNUSED) {
      printf("<MOVE> %d: \n", p->pid);
      if (demote_flag) { // mlfq handled at yield
        printf("was demoted in yield() %d\n", p->pid);
        printf("mlfq[3]: ");
        for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
          printf("%d(%d)->", c->pid, c->state);
        }
        printf("\n");
        printf("mlfq[2]: ");
        for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
          printf("%d(%d)->", c->pid, c->state);
        }
        printf("\n");
        printf("mlfq[1]: ");
        for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
          printf("%d(%d)->", c->pid, c->state);
        }
        printf("\n");
        printf("mlfq[0]: ");
        for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
          printf("%d(%d)->", c->pid, c->state);
        }
        printf("\n");


        demote_flag = 0;
        goto SEARCH;
      }
      else {
        if (p->next == 0) { // p is the last element
          printf("last element\n");
          goto SEARCH;
        }
        else { // p is NOT the last element
          printf("NOT last element\n");
          struct proc* temp = mlfq[p->level];
          if (temp == p) { // p is the first element
            printf("first element\n");
            mlfq[p->level] = p->next;
          }
          else { // p is NOT the first element
            printf("NOT first element\n");
            // (p's preceeding node) -> (p->next)
            temp = mlfq[p->level];
            while (1) {
              if (temp->next == p) {
                temp->next = p->next;
                break;
              }
              temp = temp->next;
            }
          }

          temp=p->next;
          while (1) {
            if (temp->next == 0) {
              temp->next = p;
              break;
            }
            temp = temp->next;
          }

          p->next = 0;
        }

      }
      printf("after <MOVE> %d: \n", p->pid);
      printf("mlfq[3]: ");
      for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[2]: ");
      for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[1]: ");
      for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");
      printf("mlfq[0]: ");
      for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
        printf("%d(%d)->", c->pid, c->state);
      }
      printf("\n");






    }


  } // for (;;)

}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void) // called every timer interrupt (per tick)
{
  struct proc *p = myproc();
//  printf("\n");
  printf("<yield> (pid) %d | (ticks) %d\n", p->pid, ticks);
////  printf("first_proc: %d | p: %d\n", first_proc->pid, p->pid);
////  printf("mlfq[3]: ");
////  for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
////    printf("%d->", c->pid);
////  }
////  printf("\n");
////  printf("mlfq[2]: ");
////  for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
////    printf("%d->", c->pid);
////  }
////  printf("\n");
////  printf("mlfq[1]: ");
////  for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
////    printf("%d->", c->pid);
////  }
////  printf("\n");
////  printf("mlfq[0]: ");
////  for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
////    printf("%d->", c->pid);
////  }
////  printf("\n");
//
//  //mlfq
//  // used up whole time slice
  // init(1) has to stay on top at all times
  if (p == first_proc && p->pid != 1) {
    p->allowance -= 1;
//    printf("> whole time slice used | allowance: %d\n", p->allowance);
    // used up whole allowance
    if (p->allowance == 0 && p->level != 0) {
//      printf("demote\n");
      demote_flag = 1; // handled at scheduler
      p->level -= 1;
      if (p->level == 2) p->allowance = 10;
      else if (p->level == 1) p->allowance = 30;
      else if (p->level == 0) p->allowance = 10000; // is never used up


      // move queue level
      // lower level: (last proc)->next = p
      struct proc* pp = mlfq[p->level];
      if (!pp) mlfq[p->level] = p; // the lower level is empty
      else {
        while (1) {
          if (pp->next == 0) {
            pp->next = p;
            break;
          }
          pp = pp->next;
        }
      }
//      printf("2\n");


      // upper level: pop p
      if (mlfq[p->level + 1] == p) mlfq[p->level + 1] = p->next; // p was the 1st element
      else { // p was not the 1st element, there was some other nodes in front
        pp = mlfq[p->level + 1];
        while (1) {
          if (pp->next == p) {
            pp->next = p->next;
            break;
          }
          pp = pp->next;
        }
      }
      p->next = 0;
    }
  }
//  sched_reset = 1;
//  printf("first_proc_flag = 0\n");
  first_proc_flag = 0;
  first_proc = 0;

//  printf("mlfq[3]: ");
//  for (struct proc* c=mlfq[3]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("mlfq[2]: ");
//  for (struct proc* c=mlfq[2]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("mlfq[1]: ");
//  for (struct proc* c=mlfq[1]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("mlfq[0]: ");
//  for (struct proc* c=mlfq[0]; c!=0; c=c->next) {
//    printf("%d->", c->pid);
//  }
//  printf("\n");
//  printf("\n");



  // BOOSTING
  if (next_boost == -1) { // first yield() called
    next_boost = ticks + 100;
  }
  if (ticks >= next_boost) { // BOOST
    printf("<BOOST>\n");
    struct proc* pb = mlfq[3]; // last proc in mlfq[3]. could be NULL
    for (int i=2; i>=0; i--) { // for 2,1,0 level only
      while (pb) {
        if (pb->next == 0) {
          break;
        }
        pb = pb->next;
      }
      if (mlfq[i]) { // proc present at this level
        if (pb) { // proc present at TOP queue
          pb->next = mlfq[i];
        }
        else { // proc NOT present at TOP queue
          mlfq[3] = pb;
        }
      }
    }
    mlfq[2] = 0;
    mlfq[1] = 0;
    mlfq[0] = 0;

    // update mlfq data for boosted procs
    for (pb=mlfq[3]; pb!=0; pb=pb->next) {
      pb->level = 3;
      pb->allowance = 1;
    }

    next_boost = ticks + 100;
  }


  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void
setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int
killed(struct proc *p)
{
  int k;
  
  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [USED]      "used",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}
