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

// return 1 if input is numeric
int isdigit(char a) {
  return (a >= '0') && (a <= '9');
}

// return 1 if input is numeric or alphabetic
int isalnum(char a) {
  return isdigit(a) || ((a >= 'a') && (a <= 'z')) || ((a >= 'A') && (a <= 'Z'));
}

int main(int argc, char **argv) {
  // Print a help message.
  if(argc > 7) { print_help(argc, argv); exit(1); }

  // Argument vector
  int args[max_args];
  memset(args, 0, max_args * sizeof(int));

  /* Assignment 1: Process and System Call
     Convert char inputs of argv[] into appropriate integers in args[].
     In this skeleton code, args[] is initialized to zeros,
     so technically no arguments are passed to the ps() syscall. */


  // Call the ps() syscall.

  // assert stuff
  // convert to int and assign to "args"
  for (int i=1; i<argc; i++) {

    // convert to 0 if any of the character is not numeric, except null
    int digit_check = 1;

    // loop through all character of each input
    for (int j=0;;j++){
      // character is neither alphanumeric or null
      if (!(isalnum(argv[i][j]) || (argv[i][j] == '\0'))) {
        print_help(argc, argv);
        exit(1);
      }
      digit_check = digit_check && (isdigit(argv[i][j]) || (argv[i][j] == '\0'));

      // if current char is NULL
      if (argv[i][j] == '\0') {
        if (j <= 1) {
          // integer or null
          if (digit_check) {
            args[i] = atoi(&argv[i][0]);
          }
          // alphabet
          else {
            switch (argv[i][0]) {
              case 'X':
                args[i] = -4;
                break;
              case 'S':
                args[i] = -2;
                break;
              case 'R':
                args[i] = -3;
                break;
              case 'Z':
                args[i] = -5;
                break;
              case '\0':
                args[i] = 0;
                break;
              default:
                print_help(argc, argv);
                exit(1);
                break;
            }
          }
          break;
        }
        else { // "\0 index >= 2"
          if (digit_check) {
            args[i] = atoi(argv[i]);
            break;
          }
          print_help(argc, argv);
          exit(1);
        }
      }
    }
  }

  // call sys_ps
  int ret = ps(args[0], args[1], args[2], args[3], args[4], args[5]);
  if(ret) { fprintf(2, "ps failed\n"); exit(1); }

  exit(0);
}
