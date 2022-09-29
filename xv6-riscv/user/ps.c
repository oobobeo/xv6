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

int isdigit(char a) {
  return (a >= '0') && (a <= '9');
}

int isalnum(char a) {
//  printf("isalnum func: \n");
//  printf("char: %c\n", a);
//  printf("char to hex: %x\n", a);
//  printf("%d, %d, %d\n", isdigit(a), ((a >= 'a') && (a <= 'z')), ((a >= 'A') && (a <= 'Z')));
//  printf("return %d\n", isdigit(a) || ((a >= 'a') && (a <= 'z')) || ((a >= 'A') && (a <= 'Z')));
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


  for (int i=0; i<argc; i++) {
//    printf("---------\n");
//    printf("%s\n", argv[i]);
//    printf("---------\n");
  }



  // Call the ps() syscall.

  // assert stuff
  // convert to int and assign to "args"
  for (int i=1; i<argc; i++) {

    int digit_check = 1;
    for (int j=0;;j++){

//      printf("!isalnum(argv[i][j]): %d\n", !isalnum(argv[i][j]));
//      printf("(argv[i][j] == '\\0'): %d\n", (argv[i][j] == '\0'));
      if (!(isalnum(argv[i][j]) || (argv[i][j] == '\0'))) {
        print_help(argc, argv);
//        printf("$$$$\n");
//        printf("%c\n",argv[i][j]);
//        printf("111111\n");
        exit(1);
      }
      digit_check = digit_check && (isdigit(argv[i][j]) || (argv[i][j] == '\0'));

      // if current char is NULL
      if (argv[i][j] == '\0') {
        if (j <= 1) {
          // integer or null
          if (digit_check) {
//            printf("THIS IS DIGIT\n");
            args[i] = atoi(&argv[i][0]);
          }
          // alphabet
          else {
            switch (argv[i][0]) {
              case 'X':
                args[i] = -1;
                break;
              case 'S':
                args[i] = -2;
                break;
              case 'R':
                args[i] = -3;
                break;
              case 'Z':
                args[i] = -4;
                break;
              case '\0':
                args[i] = 0;
                break;
              default:

                print_help(argc, argv);
//                printf("222222\n");
//                printf("argv[i][0]: %x\n", argv[i][0]);
//                printf("argv[i][0]: %c\n", argv[i][0]);
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
//          printf("333333\n");
          exit(1);
        }
      }
    }
  }

  // call sys_ps
//  printf("args[0]: %d\n", args[0]);
//  printf("args[1]: %d\n", args[1]);
//  printf("args[2]: %d\n", args[2]);
//  printf("args[3]: %d\n", args[3]);
//  printf("args[4]: %d\n", args[4]);
//  printf("args[5]: %d\n", args[5]);
//  printf("--------------------\n");
  int ret = ps(args[0], args[1], args[2], args[3], args[4], args[5]);
  if(ret) { fprintf(2, "ps failed\n"); exit(1); }

  exit(0);
}
