#!/bin/bash
# usage: ./saxsEst.sh [--debug] [--help]

print_help () {
    echo "Usage: ./saxsEst.sh [OPTIONS]"
    echo ""
    echo "Runs SAXS estimation suite with stepped upper bound sample sizes and epsilon values."
    echo ""
    echo "Options:"
    echo "  --debug    Build and run with debug target (default: release)"
    echo "  --help     Display this help message"
    echo ""
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

    R1="echo '=== System Info ===';"
    R2="lscpu | head -17; uname -a;"
    R3="echo '==================='"
    RINFO="$R1 $R2 $R3"

    if $DEBUG; then
        TARGET="debug"
    else
        TARGET="release"
    fi

    make clean
    make "$TARGET" RUNINFO="$RINFO"
}
main "$@"
