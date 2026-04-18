#!/bin/bash

# calculates total run time in seconds from a log file;
# adds it to the bottom of the log file

# argument: .log file
# example line:
#  timing:    12550.960527999996      s
totalExeTime() {
	echo "TOTAL EXECUTION TIME: $(awk '/timing:/ {sum+=$2} END {print sum}' "$1") s" >> "$1"
} 
totalExeTime "$@"
