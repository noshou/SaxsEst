# ============================================================================
# BuildClean.mk - Unified clean targets
# ============================================================================

BLD_DIR      ?= _build
OBJ_DIR      ?= $(BLD_DIR)/obj
FF_SRC_DIR   ?= form_fact
FF_F0_SRC    ?= $(FF_SRC_DIR)/f0.f90
FF_F12_SRC   ?= $(FF_SRC_DIR)/f1_f2.f90

.PHONY: clean clean-objects clean-build clean-formfacts clean-all

clean: clean-objects clean-build

clean-objects:
	@rm -rf $(OBJ_DIR)
	@find . -type f -name '*.o' -delete
	@find . -type f -name '*.cmx' -delete
	@find . -type f -name '*.cmi' -delete

clean-build:
	@rm -rf $(BLD_DIR)

clean-formfacts:
	@rm -rf $(FF_F0_SRC) $(FF_F12_SRC)

clean-all: clean clean-formfacts