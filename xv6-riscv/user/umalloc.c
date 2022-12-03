#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"

// Memory allocator by Kernighan and Ritchie,
// The C programming Language, 2nd ed.  Section 8.7.

typedef long Align;


/*
* union header { s, x }
* struct s = { *ptr(next), size }
* freeblock only
* circular linked list
*/
union header {
  struct {
    union header *ptr; // 8 Bytes
    uint size;         // 4 Bytes
  } s;
  Align x; // ignore
};

typedef union header Header;

static Header base;
static Header *freep;

void
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    bp->s.ptr = p->s.ptr->s.ptr;
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    p->s.ptr = bp->s.ptr;
  } else
    p->s.ptr = bp;
  freep = p;
}

static Header*
morecore(uint nu)
{
  char *p;
  Header *hp;

  if(nu < 4096)
    nu = 4096; // (= PGSIZE)
  // increased block size >= 4096*HEADER_SIZE
  // NOT page-aligned
  p = sbrk(nu * sizeof(Header)); // starting addr of new block = old value of myproc()->sz
  if(p == (char*)-1) // if (err)
    return 0;
  hp = (Header*)p;
  hp->s.size = nu;
  free((void*)(hp + 1));
  return freep; // start of linked list = new block header
}

void*
malloc(uint nbytes) // nbytes: num of Bytes
{
//  printf("<malloc> %d\n", nbytes);
  Header *p, *prevp;
  uint nunits;

  // covers nbytes + 1 Header
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;

  // if (first malloc) -> init base
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base; // ptr  = base
    base.s.size = 0;                    // size = 0
  }

  // prevp = freep
  // loop through [freep-> ]
  // find block with size bigger than nunits
  // if not -> morecore()
  // <NEXT FIT for circular queue>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){

    // found block with size bigger(or eq) than nunits
    if(p->s.size >= nunits){
      // if (block depleted) -> remove this block from list
      if(p->s.size == nunits)
        prevp->s.ptr = p->s.ptr;
      // if (block left) -> allocate tail end
      else {
        // just reduce s.size for the header in list
        p->s.size -= nunits;

        // malloc 에 return되는 block 세팅
        p += p->s.size;
        p->s.size = nunits; // 신비한 c의 세계: p는 그냥 pointer인데 [Header]로 걍 해석해서 s.size 에 해당하는 Byte에 nunits값 박음 (추정)
      }
      freep = prevp; // loop starts from freep->s.ptr
      return (void*)(p + 1); // addr after header
    }

    // if (no fitting block & all queue searched)
    // p->s.ptr = [new block | size >= nunits]
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0; // if morecore() fails
  }
}
