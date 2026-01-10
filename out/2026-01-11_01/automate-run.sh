#!/bin/bash
# automate run bc I wanna go to sleep
N_COUNT=(9981 135 772 3111 1243 22081 32872 3972 827 87055 6000 25055)
SEARCHR=50
ROUNDMD="DOWN"
EPSILON=0.01
make clean
{
    for N in "${N_COUNT[@]}"; do
        echo "$N"
        echo "$EPSILON"
        echo "$SEARCHR"
        echo "$ROUNDMD"
    done
} | make release