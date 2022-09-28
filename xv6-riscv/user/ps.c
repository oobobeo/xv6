#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// A xv6-riscv syscall can take up to six arguments.
#define max_args 6

// Print a help message.
void print_help(int argc, char **argv) {
  fprintf(2, "%s <options: pid or S/R/X/Z>%s\n",
             argv[0], argc > 7 ? ": too many args" : "");
}

int main(int argc, char **argv) {
  // Print a help message.
  if(argc > 7) { print_help(argc, argv); exit(1); }

  // Argument vector
  int args[max_args];
//  memset(args, 0, max_args * sizeof(int));

  /* Assignment 1: Process and System Call
     Convert char inputs of argv[] into appropriate integers in args[].
     In this skeleton code, args[] is initialized to zeros,
     so technically no arguments are passed to the ps() syscall. */

  // Call the ps() syscall.
  int ret = ps(args[0], args[1], args[2], args[3], args[4], args[5]);
  if(ret) { fprintf(2, "ps failed\n"); exit(1); }

  exit(0);
}
