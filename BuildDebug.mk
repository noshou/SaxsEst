# ============================================================================
# Debug build
# ============================================================================

MAKEFILE_NAME = BuildDebug.mk
BUILD_TYPE    = Debug
BLD_DIR       = _build/debug
CFLAGS        = -w -std=f2023 -g -fbacktrace -fcheck=all -O0 -march=native -mcmodel=large -fmax-array-constructor=500000
MAIN_EXE      = $(EXE_DIR)/saxs_est_DEBUG
PDB_TARGET    =

include BuildExe.mk