# ============================================================================
# MASTER MAKEFILE - Builds form_fact and atom_xyz libraries
# ============================================================================

# ============================================================================
# COMPILER CONFIGURATION
# generated files can be extrremly large so compiler loves complaining: 
# -w suppresses them
# ============================================================================
FC          = gfortran
CFLAGS      = -w -std=f2023 -O3 -march=native -mcmodel=large -fmax-array-constructor=500000

# OCaml tools
OCAMLFIND    = ocamlfind
OC           = $(OCAMLFIND) ocamlopt
OPAM         = opam

# ============================================================================
# DIRECTORY STRUCTURE
# ============================================================================

# kdt directories

# ============================================================================
# FORM_FACT LIBRARY CONFIGURATION
# ============================================================================

# Directories
FF_DIR       = form_fact
FF_SRC_DIR   = $(FF_DIR)/src
FF_BLD_DIR   = $(FF_DIR)/_build
FF_MOD_DIR   = $(FF_BLD_DIR)/mod
FF_LIB_DIR   = $(FF_BLD_DIR)/lib
FF_DATA_DIR  = $(FF_DIR)/data
FF_PARSE_DIR = $(FF_DIR)/data_parsing

# Source files
FF_F0_SRC    = $(FF_SRC_DIR)/f0.f90
FF_F12_SRC   = $(FF_SRC_DIR)/f1_f2.f90
FF_FF_SRC    = $(FF_SRC_DIR)/form_fact.f90

# Object files
FF_F0_OBJ    = $(FF_BLD_DIR)/f0.o
FF_F12_OBJ   = $(FF_BLD_DIR)/f1_f2.o
FF_FF_OBJ    = $(FF_BLD_DIR)/form_fact.o

# Library
FF_LIB       = $(FF_LIB_DIR)/form_fact.a

# Data files
FF_F0_DATA   = $(FF_DATA_DIR)/f0_factors/f0.csv
FF_F12_DATA  = $(FF_DATA_DIR)/f1_f2_factors/(12412.8)eV_f1_f2.json

# ============================================================================
# ATOM_XYZ LIBRARY CONFIGURATION
# ============================================================================

# Directories
AXY_DIR      = atom_xyz
AXY_SRC_DIR  = $(AXY_DIR)/src
AXY_BLD_DIR  = $(AXY_DIR)/_build
AXY_MOD_DIR  = $(AXY_BLD_DIR)/mod
AXY_LIB_DIR  = $(AXY_BLD_DIR)/lib
AXY_DATA_DIR = $(AXY_DIR)/data
AXY_TMP_DIR  = $(AXY_SRC_DIR)/xyz_tmp
AXY_PARSE_DIR=$(AXY_DIR)/xyz_parse

# Source files
AXY_ATM_SRC  = $(AXY_SRC_DIR)/atom.f90

# Object files
AXY_ATM_OBJ  = $(AXY_BLD_DIR)/atom.o
AXY_XYZ_OBJ  = $(patsubst $(AXY_DATA_DIR)/%.xyz,$(AXY_BLD_DIR)/xyz_%.o,$(wildcard $(AXY_DATA_DIR)/*.xyz))

# Library
AXY_LIB      = $(AXY_LIB_DIR)/atom_xyz.a

# Available atom modules
AXY_LST 	 = $(AXY_BLD_DIR)/xyz_modules.txt

# ============================================================================
# KDT LIBRARY CONFIGURATION
# ============================================================================

# Directories
KDT_DIR 	 = kdt
KDT_SRC_DIR	 = $(KDT_DIR)/src
KDT_BLD_DIR  = $(KDT_DIR)/_build
KDT_MOD_DIR  = $(KDT_BLD_DIR)/mod
KDT_LIB_DIR  = $(KDT_BLD_DIR)/lib

# Files
KDT_SRC 	 = $(KDT_SRC_DIR)/kdt.f90
KDT_OBJ		 = $(KDT_BLD_DIR)/kdt.o
KDT_LIB		 = $(KDT_LIB_DIR)/kdt.a

# ============================================================================
# PDB_TO_XYZ LIBRARY CONFIGURATION
# ============================================================================

# Directories
PDB_DIR 	 = pdb_to_xyz
PDB_SRC_DIR  = $(PDB_DIR)/src
PDB_BLD_DIR  = $(PDB_DIR)/_build
PDB_EXE_DIR  = $(PDB_BLD_DIR)/exe

# Files
PDB_SRC 	 = $(PDB_SRC_DIR)/pdb_to_xyz.f90
PDB_OBJ		 = $(PDB_BLD_DIR)/pdb_to_xyz.o
PDB_EXE 	 = $(PDB_EXE_DIR)/pdb_to_xyz

# ============================================================================
# PHONY TARGETS
# ============================================================================
.PHONY: all form_fact atom_xyz clean clean-form_fact clean-atom_xyz \
        parse-f0 parse-f1_f2 parse-xyz check-ocaml check-deps-csv \
        check-deps-yojson check-deps-str help clean-formfacts \
		clean-objects build-dirs-atom_xyz parse-xyz tabulate-xyz \
		postamble kdt build-dirs-kdt clean-kdt compile-pdb-2-xyz clean-pdb-2-xyz \
		build-dirs-pdb-2-xyz

# ============================================================================
# MAIN TARGETS
# ============================================================================
all: form_fact atom_xyz kdt compile-pdb-2-xyz clean-objects postamble

help:
	@echo "Usage: make -f Compile.mk <target>"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Build all libraries (form_fact, atom_xyz, kdt, pdb_to_xyz)"
	@echo "  form_fact        - Build form_fact library only"
	@echo "  atom_xyz         - Build atom_xyz library only"
	@echo "  kdt              - Build kdt library only"
	@echo "  compile-pdb-2-xyz- Build pdb_to_xyz converter"
	@echo "  pdb-2-xyz        - Run pdb_to_xyz converter (prompts for filename)"
	@echo ""
	@echo "Parsing targets:"
	@echo "  parse-f0         - Parse f0 scattering factors from CSV"
	@echo "  parse-f1_f2      - Parse f1_f2 anomalous factors from JSON"
	@echo "  parse-xyz        - Parse XYZ coordinate files"
	@echo ""
	@echo "Clean targets:"
	@echo "  clean            - Clean all build artifacts"
	@echo "  clean-form_fact  - Clean form_fact build artifacts"
	@echo "  clean-atom_xyz   - Clean atom_xyz build artifacts"
	@echo "  clean-kdt        - Clean kdt build artifacts"
	@echo "  clean-pdb-2-xyz  - Clean pdb_to_xyz build artifacts"
	@echo "  clean-formfacts  - Remove generated f0 and f1_f2 modules (manual)"
	@echo "  clean-objects    - Remove all generated object files"
# ============================================================================
# PREAMBLE (shows AXY_LST) growing
# ============================================================================

# ============================================================================
# FORM_FACT LIBRARY BUILD
# ============================================================================
form_fact: $(FF_LIB)

# Parse f0 scattering factors
parse-f0: check-deps-csv
	@$(OC) -package csv -linkpkg $(FF_PARSE_DIR)/f0.ml -o f0_gen && \
		./f0_gen "$(FF_F0_DATA)" && \
		mv f0.f90 $(FF_SRC_DIR)/ && \
		rm -rf f0_gen $(FF_PARSE_DIR)/*.cmi $(FF_PARSE_DIR)/*.cmx $(FF_PARSE_DIR)/*.o

# Parse f1_f2 anomalous factors
parse-f1_f2: check-deps-yojson
	@$(OC) -package yojson,str -linkpkg $(FF_PARSE_DIR)/f1_f2.ml -o f1_f2_gen && \
		./f1_f2_gen "$(FF_F12_DATA)" && \
		mv f1_f2.f90 $(FF_SRC_DIR)/ && \
		rm -rf f1_f2_gen $(FF_PARSE_DIR)/*.cmi $(FF_PARSE_DIR)/*.cmx $(FF_PARSE_DIR)/*.o

$(FF_LIB): $(FF_F0_OBJ) $(FF_F12_OBJ) $(FF_FF_OBJ) | $(FF_LIB_DIR)
	@ar rcs $@ $^

# Build directories for form_fact
$(FF_BLD_DIR) $(FF_MOD_DIR) $(FF_LIB_DIR):
	@mkdir -p $@

# Compile f0 module
$(FF_F0_OBJ): $(FF_F0_SRC) | $(FF_BLD_DIR) $(FF_MOD_DIR)
	@$(FC) $(CFLAGS) -J$(FF_MOD_DIR) -c $< -o $@

# Compile f1_f2 module
$(FF_F12_OBJ): $(FF_F12_SRC) | $(FF_BLD_DIR) $(FF_MOD_DIR)
	@$(FC) $(CFLAGS) -J$(FF_MOD_DIR) -c $< -o $@

# Compile form_fact module (depends on f0 and f1_f2)
$(FF_FF_OBJ): $(FF_FF_SRC) $(FF_F0_OBJ) $(FF_F12_OBJ) | $(FF_BLD_DIR) $(FF_MOD_DIR)
	@$(FC) $(CFLAGS) -I$(FF_MOD_DIR) -J$(FF_MOD_DIR) -c $< -o $@

# Check and parse f0 if needed
$(FF_F0_SRC): | check-deps-csv
	@echo "f0.f90 not found, parsing from $(FF_F0_DATA)"
	@$(OC) -package csv -linkpkg $(FF_PARSE_DIR)/f0.ml -o f0_gen && \
		./f0_gen "$(FF_F0_DATA)" && \
		mv f0.f90 $(FF_SRC_DIR)/ && \
		rm -rf f0_gen $(FF_PARSE_DIR)/*.cmi $(FF_PARSE_DIR)/*.cmx $(FF_PARSE_DIR)/*.o

# Check and parse f1_f2 if needed
$(FF_F12_SRC): | check-deps-yojson
	@echo "f1_f2.f90 not found, parsing from $(FF_F12_DATA)"
	@$(OC) -package yojson,str -linkpkg $(FF_PARSE_DIR)/f1_f2.ml -o f1_f2_gen && \
		./f1_f2_gen "$(FF_F12_DATA)" && \
		mv f1_f2.f90 $(FF_SRC_DIR)/ && \
		rm -rf f1_f2_gen $(FF_PARSE_DIR)/*.cmi $(FF_PARSE_DIR)/*.cmx $(FF_PARSE_DIR)/*.o

# ============================================================================
# ATOM_XYZ LIBRARY BUILD
# Builds ALL xyz files in the data subdirectory into f90 modules
# The files that are produced are HUGE so use sparingly. 
# All files in the xyz folder are automatically deleted after compilation.
# ============================================================================
atom_xyz: clean-atom_xyz build-dirs-atom_xyz parse-xyz tabulate-xyz $(AXY_LIB)   

# make build dir
build-dirs-atom_xyz:
	@rm -rf $(AXY_BLD_DIR)
	@mkdir $(AXY_BLD_DIR)
	@mkdir $(AXY_MOD_DIR)
	@mkdir $(AXY_LIB_DIR)

# parses all xyz files into .f90 files
parse-xyz:
	@rm -rf $(AXY_TMP_DIR)
	@$(OC) -package str -linkpkg $(AXY_PARSE_DIR)/xyz_parser.ml -o xyz_parser
	@./xyz_parser $(AXY_DATA_DIR)/*.xyz
	@rm -rf xyz_parser $(AXY_PARSE_DIR)/*.cmi $(AXY_PARSE_DIR)/*.cmx $(AXY_PARSE_DIR)/*.o
	@mkdir -p $(AXY_TMP_DIR)
	@mv xyz_*.f90 $(AXY_TMP_DIR)

# tabulates xyz modules
tabulate-xyz:
	@for f in $(AXY_DATA_DIR)/*.xyz; do \
		echo "xyz_$$(basename "$$f" .xyz)_mod.mod"; \
	done > $(AXY_LST)

# compile files
$(AXY_ATM_OBJ): $(AXY_ATM_SRC) | $(AXY_BLD_DIR) $(AXY_MOD_DIR) $(FF_MOD_DIR)
	@$(FC) $(CFLAGS) -I$(FF_MOD_DIR) -J$(AXY_MOD_DIR) -c $< -o $@
$(AXY_BLD_DIR)/xyz_%.o: $(AXY_TMP_DIR)/xyz_%.f90 | $(AXY_BLD_DIR) $(AXY_MOD_DIR)
	@echo "compiling: $<"
	@$(FC) $(CFLAGS) -I$(AXY_MOD_DIR) -J$(AXY_MOD_DIR) -c $< -o $@

# create static library
$(AXY_LIB): $(AXY_ATM_OBJ) $(AXY_XYZ_OBJ) | $(AXY_LIB_DIR)
	@ar rcs $@ $^
	@rm -rf $(AXY_TMP_DIR)

# ============================================================================
# KDT LIBRARY BUILD
# ============================================================================
kdt: clean-kdt build-dirs-kdt $(KDT_LIB)
build-dirs-kdt:
	@rm -rf $(KDT_BLD_DIR)
	@mkdir $(KDT_BLD_DIR)
	@mkdir $(KDT_MOD_DIR)
	@mkdir $(KDT_LIB_DIR)

$(KDT_OBJ): $(KDT_SRC) | $(KDT_BLD_DIR) $(KDT_MOD_DIR) $(KDT_LIB_DIR)
	@$(FC) $(CFLAGS) -I$(FF_MOD_DIR) -I$(AXY_MOD_DIR) -J$(KDT_MOD_DIR) -c $< -o $@
$(KDT_LIB): $(KDT_OBJ)
	@ar rcs $@ $^

# ============================================================================
# OCAML DEPENDENCY CHECKING
# ============================================================================

# Check if ocamlfind is installed
check-ocaml:
	@which $(OCAMLFIND) > /dev/null 2>&1 || \
		(echo "ERROR: ocamlfind not found. Please install OCaml and opam first." && \
		echo "Visit: https://ocaml.org/docs/install.html" && \
		exit 1)

# Check and install csv package
check-deps-csv: check-ocaml
	@$(call check_and_install,csv)

# Check and install yojson and str packages
check-deps-yojson: check-ocaml
	@$(call check_and_install,yojson str)

# Check and install str package
check-deps-str: check-ocaml
	@$(call check_and_install,str)

# Function to check and install OCaml packages
define check_and_install
	@missing="" ; \
	for pkg in $(1); do \
		if ! $(OCAMLFIND) query $$pkg > /dev/null 2>&1; then \
			missing="$$missing $$pkg" ; \
		fi ; \
	done ; \
	if [ -n "$$missing" ]; then \
		echo "Missing OCaml packages:$$missing" ; \
		echo "" ; \
		echo "Would you like to install them now? [y/N]" ; \
		read -r response ; \
		if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
			echo "Installing OCaml packages:$$missing" ; \
			$(OPAM) install -y $$missing ; \
		else \
			echo "Please install manually with: opam install$$missing" ; \
			exit 1 ; \
		fi ; \
	fi
endef

# ============================================================================
# PDB TO XYZ FILE CONVERTER
# ============================================================================

build-dirs-pdb-2-xyz: 
	@rm -rf $(PDB_BLD_DIR)
	@mkdir $(PDB_BLD_DIR)
	@mkdir $(PDB_EXE_DIR)

compile-pdb-2-xyz: build-dirs-pdb-2-xyz $(PDB_EXE)
$(PDB_OBJ): $(PDB_SRC) | $(PDB_BLD_DIR)
	@$(FC) $(CFLAGS) -J$(PDB_BLD_DIR) -c $< -o $@
$(PDB_EXE): $(PDB_OBJ) | $(PDB_EXE_DIR)
	@$(FC) $(PDB_OBJ) -o $(PDB_EXE)

pdb-2-xyz:
	@read -p "Enter xyz filename: " file; \
	./$(PDB_EXE) $$file; \
	mv *.xyz $(AXY_DATA_DIR); \
	

# ============================================================================
# postamble
# ============================================================================

postamble:
	@echo "=================================="
	@echo "compilation complete"
	@echo "compiled xyz molecules: $(AXY_LST)"
	@echo "=================================="


# ============================================================================
# CLEAN TARGETS
# ============================================================================

clean: clean-form_fact clean-atom_xyz clean-objects clean-pdb-2-xyz
clean-form_fact:
	@rm -rf $(FF_BLD_DIR)
clean-atom_xyz:
	@rm -rf $(AXY_BLD_DIR)
	@rm -rf $(AXY_TMP_DIR)
	@rm -rf $(AXY_DIR)/*.o
clean-kdt:
	@rm -rf $(KDT_BLD_DIR)
clean-objects:
	@find . -type f -name '*.o' -delete
clean-formfacts: clean
	@rm -rf $(FF_F0_SRC) $(FF_F12_SRC)
clean-pdb-2-xyz:
	@rm -rf $(PDB_BLD_DIR)