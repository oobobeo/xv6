#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "user/user.h"

#define buf_size    128     // Max length of user input
#define max_args    16      // Max number of arguments

int runcmd(char *cmd);      // Run a command.

// Read a shell input.
// DO NOT MODIFY
char* readcmd(char *buf) {
    // Read an input from stdin.
    fprintf(1, "$ ");
    memset(buf, 0, buf_size);
    char *cmd = gets(buf, buf_size);
  
    // Chop off the trailing '\n'.
    if(cmd) { cmd[strlen(cmd)-1] = 0; }
  
    return cmd;
}

// DO NOT MODIFY
int main(int argc, char **argv) {
    int fd = 0;
    char *cmd = 0;
    char buf[buf_size];
  
    // Ensure three file descriptors are open.
    while((fd = open("console", O_RDWR)) >= 0) {
        if(fd >= 3) { close(fd); break; }
    }
  
    fprintf(1, "EEE3535 Operating Systems: starting ysh\n");
  
    // Read and run input commands.
    while((cmd = readcmd(buf)) && runcmd(cmd)) ;
  
    fprintf(1, "EEE3535 Operating Systems: closing ysh\n");
    exit(0);
}

// Run a command.
int runcmd(char *cmd) {
    char *cmd_ = (char*) malloc(sizeof(char) * 200);
    memset(cmd_, 0, sizeof(cmd_));
    strcpy(cmd_, cmd);
    if(!*cmd_) { return 1; }                     // Empty command

    // Skip leading white space(s).
    while(*cmd_ == ' ') { cmd_++; }
    // Remove trailing white space(s).
    for(char *c = cmd_+strlen(cmd_)-1; *c == ' '; c--) { *c = 0; }

    if(!strcmp(cmd_, "exit")) { return 0; }      // exit command
    else if(!strncmp(cmd_, "cd ", 3)) {          // cd command
        if(chdir(cmd_+3) < 0) { fprintf(2, "Cannot cd %s\n", cmd_+3); }
    }
    else {
        // EEE3535-01 Operating Systems
        // Assignment 3: Shell
//        int left = 0;
//        int right = 0;

        // CASE1: (&)
        if (cmd_[strlen(cmd_)-1] == '&') {
          cmd_[strlen(cmd_)-1] = 0;
          int rc1 = fork();
          if (rc1 == 0) { // child
            runcmd(cmd_);
//            exit(0);
          }
        }

        // CASE2: (;)
        else if (strchr(cmd_, ';')) {
//          printf("(;) START\n");
          char *s = strchr(cmd_, ';');
          *s = 0;
          int rc2 = fork();
//          printf("rc2: %d\n", rc2);
          if (rc2 > 0) { // parent
//            printf("(;) right: %s\n", s+1);
            wait(0);
            runcmd(s+1);
          }
          if (rc2 == 0) { //child
//            printf("(;) LEFT: %s\n", cmd_);
            runcmd(cmd_);
            exit(0);
          }
        }

        // CASE3: (|)
        else if (strchr(cmd_, '|')) {
//          printf("PIPE: %s\n", cmd_);

          char *p = strchr(cmd_, '|');
          *p = 0;

          int rc3 = fork();
          if (rc3 > 0) { // parent
            wait(0);
          }
          else if (rc3 == 0) { // child
            int mypipe[2];
            pipe(mypipe);
            int rc4 = fork();
            if (rc4 > 0) { // child
              close(0);
              dup(mypipe[0]);
              close(mypipe[0]);
              close(mypipe[1]);
//              printf("PIPE child: (%s)\n", p+1);
              runcmd(p+1);
              exit(0);
            }
            else if (rc4 == 0) { // grandchild
              close(1);
              dup(mypipe[1]);
              close(mypipe[0]);
              close(mypipe[1]);
//              printf("PIPE grandchild: (%s)\n", cmd_);
              runcmd(cmd_);
              exit(0);
            }
          }






        }

        // CASE4: (single command)
        else {
//          printf("SINGLE COMMAND\n");
          char *argv[10]; // MAXARGS = 10
          for (int k=0; k<10; k++) {
              argv[k] = 0;
          }
          int i = 0; // index of argv
          do {
            // current segment
            argv[i] = cmd_;
            // next segment
            char *b = strchr(cmd_, ' ');
            if (!b) break; // current segment was the last segment
            *b = 0; // NULL
            int l = strlen(cmd_);
            cmd_ = &cmd_[l+1];
            i++;
          } while (1); // ex) "ps -c -x" index=2,5 is blank

          // if empty command: exit
//          if (!argv[0]) {
//            exit(1);
//          }

//          for (int k=0; k<10; k++) {
//            if (argv[k]) {
//              printf("COMMAND(%d): %s\n",k, argv[k]);
//            }
//          }
//          printf("\n");
          int rc5 = fork();
          if (rc5 == 0) {
            exec(argv[0], argv);
          }
          else if (rc5 > 0) {
            wait(0);
          }
        }
    }
//    printf("return 1\n");
    return 1;
}
