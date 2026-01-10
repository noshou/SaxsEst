# ============================================================================
# Release build
# ============================================================================

MAKEFILE_NAME = BuildRelease.mk
BUILD_TYPE    = Release
BLD_DIR       = _build/release
CFLAGS        = -w -std=f2023 -O3 -march=native -mcmodel=large -fmax-array-constructor=500000 
MAIN_EXE      = $(EXE_DIR)/saxs_est
PDB_TARGET    = compile-pdb-2-xyz

include BuildExe.mk