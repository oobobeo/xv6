#!/bin/bash
#########################################################
# EEE3535 Operating Systems                             #
# Written by William J. Song                            #
# School of Electrical Engineering, Yonsei University   #
#########################################################

patch_tar="process.tar"
patch_path="https://icsl.yonsei.ac.kr/wp-content/uploads"

if [[ `basename $PWD` == "xv6-riscv" && -d user ]]; then
    if [[ ! -f user/ps.c ]]; then
        make clean
        mv user/sid.h ./
        rm -f Makefile user kernel install.sh tar.sh
        wget $patch_path/$patch_tar
        tar xf $patch_tar
        rm -f $patch_tar
        mv sid.h user/
    else
        echo "xv6-riscv is already up to date for Assignment 1"
    fi
    if [[ `grep sname user/sid.h` =~ Unknown ]]; then
        read -p "Enter your 10-digit student ID: " sid
        read -p "Enter your name in English: " sname
        echo ""
        echo "#define sid $sid" > user/sid.h;
        echo "#define sname \"$sname\"" >> user/sid.h;
    fi
else
    echo "Error: $0 must run in the xv6-riscv/ directory"
fi

