#!/bin/bash
# usage: ./automate-run-debug.sh

# runs suite with n_tilde = n
# and epsilon = 0.9 -> 0.01

# analysis order:
# 1.  chignolin       -> 135
# 2.  csgc            -> 772
# 3.  gpx             -> 3111
# 4.  kdelr1          -> 1243
# 5.  phgdh           -> 3972
# 6.  plastocyanin    -> 827
# 7.  strip1-iso2     -> 6000

main () {
    N_COUNT=(135 772 3111 1243 3972 827 6000)
    ROUNDMD="DOWN"
    EPSILON=$1

    R1="echo '=== System Info ===';"
    R2="lscpu | head -17; uname -a;"
    R3="echo '===================';"
    R4="echo '=== Parameters ===';"
    R5="echo \"ε = ${EPSILON}\";"
    R7="echo \"ROUNDING MODE: ${ROUNDMD}\";"
    R8="echo '==================='"
    RINFO="$R1 $R2 $R3 $R4 $R5 $R7 $R8"

    make clean

    {
        for N in "${N_COUNT[@]}"; do
            echo "$N"
            echo "$EPSILON"
            echo "$ROUNDMD"

        done
    } | make debug RUNINFO="$RINFO"
}
main 0.46

# for i in $(seq 0.01 0.05 0.5); do
#     main $i
# done
