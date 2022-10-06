#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// Print a help message.
//void print_help(int argc, char **argv) {
//  fprintf(2, "%s <options: pid or S/R/X/Z>%s\n",
//             argv[0], argc > 7 ? ": too many args" : "");
//}

int main(void) {
  // Print a help message.
//  if(argc > 7) { print_help(argc, argv); exit(1); }

  // Argument vector
//  int args[max_args];
//  memset(args, 0, max_args * sizeof(int));

  printf("ayy");

  // call sys_ps
  gettime();
//  if(ret) { fprintf(2, "ps failed\n"); exit(1); }

  exit(0);
}
