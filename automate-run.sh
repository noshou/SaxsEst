#!/bin/bash
N_COUNT=(9981 135 772 3111 1243 22081 32872 3972 827 87055 6000 25055)
SEARCHR=25
ROUNDMD="DOWN"
EPSILON=0.1

echo "=== System Info ==="
lscpu | head -18
uname -a
echo "==================="
echo "== Parameters ==="
echo "ε = ${EPSILON}"
echo "r = ${SEARCHR}Å"
echo "ROUNDING MODE: $ROUNDMD"
echo "==================="

make clean
{
    for N in "${N_COUNT[@]}"; do
        echo "$N"
        echo "$EPSILON"
        echo "$SEARCHR"
        echo "$ROUNDMD"
    done
} | make release
