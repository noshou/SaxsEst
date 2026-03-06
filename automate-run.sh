#!/bin/bash
# usage: ./automate-run.sh [--debug] [--help]

print_help () {
    echo "Usage: ./automate-run.sh [OPTIONS]"
    echo ""
    echo "Runs SAXS estimation suite with stepped sample sizes and epsilon values."
    echo ""
    echo "Options:"
    echo "  --debug    Build and run with debug target (default: release)"
    echo "  --help     Display this help message"
    echo ""
    echo "Analysis order:"
    echo "  1. chignolin       (n=135)"
    echo "  2. csgc            (n=772)"
    echo "  3. gpx             (n=3111)"
    echo "  4. kdelr1          (n=1243)"
    echo "  5. phgdh           (n=3972)"
    echo "  6. plastocyanin    (n=827)"
    echo "  7. strip1-iso2     (n=6000)"
    echo ""
    echo "Parameters:"
    echo "  epsilon:     0.39 -> 0.45 (stepped)"
    echo "  sample size: 50% -> 5% (stepped)"
    echo "  rounding:    UP"
}

main () {
    DEBUG=false
    for arg in "$@"; do
        case "$arg" in
            --help)
                print_help
                exit 0
                ;;
            --debug)
                DEBUG=true
                ;;
            *)
                echo "Unknown option: $arg"
                print_help
                exit 1
                ;;
        esac
    done

    N_COUNT=(135 772 3111 1243 3972 827 6000)
    EPSILON=(0.39 0.395 0.4 0.405 0.41 0.4105)
    SMPSIZE=("50%" "45%" "40%" "35%" "30%" "25%" "20%" "15%" "10%" "5%")
    ROUNDMD="UP"
    R1="echo '=== System Info ===';"
    R2="lscpu | head -17; uname -a;"
    R3="echo '===================';"
    R4="echo '=== Parameters ===';"
    R5="echo \"#atoms      = ${N_COUNT[*]}\";"
    R6="echo \"sample size = ${SMPSIZE[*]}\";"
    R7="echo \"ε           = ${EPSILON[*]}\";"
    R8="echo \"ROUNDING MODE: ${ROUNDMD}\";"
    R9="echo '==================='"
    
    
    RINFO="$R1 $R2 $R3 $R4 $R5 $R6 $R7 $R8 $R9"

    if $DEBUG; then
        TARGET="debug"
    else
        TARGET="release"
    fi

    make clean
        for e in "${EPSILON[@]}"; do
            for s in "${SMPSIZE[@]}"; do 
                {
                    for n in "${N_COUNT[@]}"; do
                        echo "$n"
                        echo "$e"
                        echo "$ROUNDMD"
                        echo "$s"
                    done 
            } | make "$TARGET" RUNINFO="$RINFO"
        done 
    done    
}
main "$@"
