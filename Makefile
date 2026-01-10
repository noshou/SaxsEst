# main entry point to build project
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
.PHONY: build_release build_debug release debug clean clean-all help

# ============================================================================
# VARIABLES
# ============================================================================
OUT_ROOT ?= out
TODAY := $(shell date +%F)

# ============================================================================
# BUILD TARGETS
# ============================================================================
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
		$(MAKE) --no-print-directory -f BuildRelease.mk all && \
		./_build/release/exe/saxs_est ./_build/release/xyz_modules.txt $$dir \
	) 2>&1 | tee "$$dir/$$(basename $$dir).log"

debug:
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
		$(MAKE) --no-print-directory -f BuildDebug.mk all && \
		./_build/debug/exe/saxs_est_DEBUG ./_build/debug/xyz_modules.txt ./_build/release/exe/saxs_est ./_build/release/xyz_modules.txt $$dir\
	) 2>&1 | tee "$$dir/$$(basename $$dir).log"

clean:
	@$(MAKE) --no-print-directory -f BuildClean.mk clean

clean-all:
	@$(MAKE) --no-print-directory -f BuildClean.mk clean-all

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "  release   - Build optimized release"
	@echo "  debug     - Build with debug symbols"
	@echo "  clean     - Remove build artifacts"
	@echo "  clean-all - Remove everything including generated sources"