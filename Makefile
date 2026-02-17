# main entry point to build project
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
.PHONY: build_release build_debug release debug clean clean-all help

# ============================================================================
# VARIABLES
# ============================================================================
OUT_ROOT ?= Analysis
TODAY := $(shell date +%F)
RUNINFO ?= rinf

# check for valgrind at parse time (1 = found, 0 = not found)
HAS_VALGRIND := $(shell which valgrind >/dev/null && echo 1 || echo 0)
# ============================================================================
# BUILD TARGETS
# ============================================================================

# Build optimized release binary via BuildRelease.mk, then run it.
# Output goes to a timestamped directory under $(OUT_ROOT), with a
# numeric suffix appended when the date-based name already exists.
release:
	@mkdir -p $(OUT_ROOT); \
		base="$(TODAY)"; \
		dir="$(OUT_ROOT)/$$base"; \
		n=0; \
		while [ -d "$$dir" ]; do \
			n=$$((n+1)); \
			dir="$(OUT_ROOT)/$$base$$(printf '_%02d' $$n)"; \
		done; \
		mkdir "$$dir"; \
		( \
	$(RUNINFO); \
	$(MAKE) --no-print-directory -f BuildRelease.mk all && \
			./_build/release/exe/SaxsEst ./_build/release/xyz_modules.txt $$dir \
		) 2>&1 | tee "$$dir/$$(basename $$dir).log"

# Build debug binary via BuildDebug.mk, then run it.
# If valgrind is available, the binary is run under valgrind with full
# leak checking; the valgrind report is written to a separate log file.
# note: valgrind is NOT RUN if the user does not have it!
ifeq ($(HAS_VALGRIND),1)
debug:
	@mkdir -p $(OUT_ROOT); \
		base="$(TODAY)_DEBUG"; \
		dir="$(OUT_ROOT)/$$base"; \
		n=0; \
		while [ -d "$$dir" ]; do \
			n=$$((n+1)); \
			dir="$(OUT_ROOT)/$$base$$(printf '_%02d' $$n)"; \
		done; \
		mkdir "$$dir"; \
		( \
	$(RUNINFO); \
	$(MAKE) --no-print-directory -f BuildDebug.mk all && \
			valgrind --leak-check=full --track-origins=yes --log-file="$$dir/$$(basename $$dir)_valgrind.log" \
			./_build/debug/exe/SaxsEst_DEBUG ./_build/debug/xyz_modules.txt $$dir \
		) 2>&1 | tee "$$dir/$$(basename $$dir).log"
else
debug:
	@echo "Valgrind not found, running without memory analysis"; \
		mkdir -p $(OUT_ROOT); \
		base="$(TODAY)"; \
		dir="$(OUT_ROOT)/$$base"; \
		n=0; \
		while [ -d "$$dir" ]; do \
			n=$$((n+1)); \
			dir="$(OUT_ROOT)/$$base$$(printf '_%02d' $$n)"; \
		done; \
		mkdir "$$dir"; \
		( \
	$(RUNINFO); \
	$(MAKE) --no-print-directory -f BuildDebug.mk all && \
			./_build/debug/exe/SaxsEst_DEBUG ./_build/debug/xyz_modules.txt $$dir \
		) 2>&1 | tee "$$dir/$$(basename $$dir).log"
endif

clean:
	@$(MAKE) --no-print-directory -f BuildClean.mk clean
clean-all:
	@$(MAKE) --no-print-directory -f BuildClean.mk clean-all
help:
	@echo "Usage: make <target> [VARIABLE=value]"
	@echo ""
	@echo "Targets:"
	@echo "  release   - Build optimized release and run in timestamped output directory"
	@echo "  debug     - Build with debug symbols and run in timestamped output directory"
	@echo "  clean     - Remove build artifacts"
	@echo "  clean-all - Remove everything including generated sources"
	@echo ""
	@echo "Variables:"
	@echo "  OUT_ROOT  - Output directory root (default: out)"
	@echo "  RUNINFO   - Command to capture system info (default: rinf)"
	@echo ""
	@echo "Examples:"
	@echo "  make release"
	@echo "  make debug OUT_ROOT=results"
	@echo "  make release RUNINFO='uname -a'"