#!/bin/bash
# usage: nohup ./automate-run.sh

N_COUNT=(9981 135 772 3111 1243 22081 32872 3972 827 87055 6000 25055)
SEARCHR=25
ROUNDMD="DOWN"
EPSILON=0.1

R1="echo '=== System Info ===';" 
R2="lscpu | head -17; uname -a;" 
R3="echo '===================';" 
R4="echo '=== Parameters ===';" 
R5="echo \"ε = ${EPSILON}\";" 
R6="echo \"r = ${SEARCHR}Å\";"
R7="echo \"ROUNDING MODE: ${ROUNDMD}\";" 
R8="echo '==================='"
RINFO="$R1 $R2 $R3 $R4 $R5 $R6 $R7 $R8"

make clean

{
    for N in "${N_COUNT[@]}"; do
        echo "$N"
        echo "$EPSILON"
        echo "$SEARCHR"
        echo "$ROUNDMD"
    done
} | make release RUNINFO="$RINFO"