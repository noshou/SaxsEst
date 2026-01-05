# ============================================================================
# Compile.mk builds needed libraries and compiles main into an executable
# ============================================================================

# ============================================================================
# COMPILER CONFIGURATION
# ============================================================================
CC           = gcc -w -g 
FC           = gfortran
CFLAGS       = -w -std=f2023 -O3 -march=native -mcmodel=large -fmax-array-constructor=500000

# OCaml tools
OCAMLFIND    = ocamlfind
OC           = $(OCAMLFIND) ocamlopt
OPAM         = opam

# ============================================================================
# BUILD DIRECTORY CONFIGURATION
# ============================================================================
BLD_DIR      = _build
OBJ_DIR      = $(BLD_DIR)/obj
LIB_DIR      = $(BLD_DIR)/lib
MOD_DIR      = $(BLD_DIR)/mod
INC_DIR      = $(BLD_DIR)/inc
EXE_DIR      = $(BLD_DIR)/exe

# ============================================================================
# FORM_FACT LIBRARY CONFIGURATION
# ============================================================================
FF_DIR       = form_fact
FF_SRC_DIR   = $(FF_DIR)
FF_DATA_DIR  = $(FF_DIR)/data
FF_PARSE_DIR = $(FF_DIR)/data_parsing

FF_F0_SRC    = $(FF_SRC_DIR)/f0.f90
FF_F12_SRC   = $(FF_SRC_DIR)/f1_f2.f90
FF_FF_SRC    = $(FF_SRC_DIR)/form_fact.f90

FF_F0_OBJ    = $(OBJ_DIR)/f0.o
FF_F12_OBJ   = $(OBJ_DIR)/f1_f2.o
FF_FF_OBJ    = $(OBJ_DIR)/form_fact.o

FF_LIB       = $(LIB_DIR)/form_fact.a

FF_F0_DATA   = $(FF_DATA_DIR)/f0_factors/f0.csv
FF_F12_DATA  = $(FF_DATA_DIR)/f1_f2_factors/(12412.8)eV_f1_f2.json

# ============================================================================
# ATOM_XYZ LIBRARY CONFIGURATION
# ============================================================================
AXY_DIR      = atom_xyz
AXY_SRC_DIR  = $(AXY_DIR)
AXY_DATA_DIR = $(AXY_DIR)/data
AXY_TMP_DIR  = $(AXY_SRC_DIR)/xyz_tmp
AXY_PARSE_DIR= $(AXY_DIR)/parsers

AXY_ATM_SRC  = $(AXY_SRC_DIR)/atom.f90
AXY_ATM_OBJ  = $(OBJ_DIR)/atom.o
AXY_XYZ_OBJ  = $(patsubst $(AXY_DATA_DIR)/%.xyz,$(OBJ_DIR)/xyz_%.o,$(wildcard $(AXY_DATA_DIR)/*.xyz))

AXY_LIB      = $(LIB_DIR)/atom_xyz.a
AXY_LST      = $(BLD_DIR)/xyz_modules.txt
AXY_USE      = $(INC_DIR)/mod_uses.inc
AXY_SWT      = $(INC_DIR)/mod_switches.inc

# ============================================================================
# KDT LIBRARY CONFIGURATION
# ============================================================================
KDT_DIR      = kdt
KDT_SRC_DIR  = $(KDT_DIR)

KDT_SRC      = $(KDT_SRC_DIR)/kdt.f90
KDT_OBJ      = $(OBJ_DIR)/kdt.o
KDT_LIB      = $(LIB_DIR)/kdt.a

# ============================================================================
# ESTIMATE LIBRARY CONFIGURATION
# ============================================================================
EST_DIR      = estimate
EST_SRC_DIR  = $(EST_DIR)

EST_SRC      = $(EST_SRC_DIR)/estimate.f90
EST_OBJ      = $(OBJ_DIR)/estimate.o
EST_LIB      = $(LIB_DIR)/estimate.a

# ============================================================================
# CSV_INTERFACE LIBRARY CONFIGURATION
# ============================================================================
CSV_DIR      = csv_interface
CSV_SRC_DIR  = $(CSV_DIR)

CSV_BRD_SRC  = $(CSV_SRC_DIR)/csv_bridge.c
CSV_BRD_OBJ  = $(OBJ_DIR)/csv_bridge.o
CSV_OUT_SRC  = $(CSV_SRC_DIR)/csv_out.ml
CSV_OUT_OBJ  = $(OBJ_DIR)/csv_out.o
CSV_API_SRC  = $(CSV_SRC_DIR)/csv_interface.f90
CSV_API_OBJ  = $(OBJ_DIR)/csv_interface.o
CSV_LIB      = $(LIB_DIR)/csv_interface.a

# ============================================================================
# PDB_TO_XYZ EXECUTABLE CONFIGURATION
# ============================================================================
PDB_DIR      = pdb_to_xyz
PDB_SRC_DIR  = $(PDB_DIR)

PDB_SRC      = $(PDB_SRC_DIR)/pdb_to_xyz.f90
PDB_OBJ      = $(OBJ_DIR)/pdb_to_xyz.o
PDB_EXE      = $(EXE_DIR)/pdb_to_xyz

# ============================================================================
# MAIN EXECUTABLE CONFIGURATION
# ============================================================================
MAIN_EXE	 = $(EXE_DIR)/saxs_est
MAIN_SRC	 = saxs_est.f90

# ============================================================================
# PHONY TARGETS
# ============================================================================
.PHONY: all form_fact atom_xyz clean clean-build \
        parse-f0 parse-f1_f2 parse-xyz check-ocaml check-deps-csv \
        check-deps-yojson check-deps-str help clean-formfacts \
        clean-objects parse-xyz tabulate-xyz estimate \
        postamble kdt compile-pdb-2-xyz \
        generate-xyz-includes csv-interface build-dirs

# ============================================================================
# ALL TARGET
# ============================================================================
all: build-dirs form_fact atom_xyz kdt estimate compile-pdb-2-xyz csv-interface main clean-objects postamble

help:
	@echo "Usage: make -f Compile.mk <target>"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Build all libraries and executables"
	@echo "  main             - Build main SAXS estimation executable"
	@echo "  form_fact        - Build form_fact library only"
	@echo "  atom_xyz         - Build atom_xyz library only"
	@echo "  kdt              - Build kdt library only"
	@echo "  estimate         - Build estimate library only"
	@echo "  csv-interface    - Build csv_interface library only"
	@echo "  compile-pdb-2-xyz- Build pdb_to_xyz converter"
	@echo "  pdb-2-xyz        - Run pdb_to_xyz converter (prompts for filename)"
	@echo ""
	@echo "Parsing targets:"
	@echo "  parse-f0         - Parse f0 scattering factors from CSV"
	@echo "  parse-f1_f2      - Parse f1_f2 anomalous factors from JSON"
	@echo "  parse-xyz        - Parse XYZ coordinate files"
	@echo ""
	@echo "Clean targets:"
	@echo "  clean            - Remove all build artifacts (note: clean-formfact not run!)"
	@echo "  clean-formfact   - Remove generated f0 and f1_f2 modules"
	@echo "	 clean-build	  - Remove build directory"
	@echo "  clean-objects    - Remove all generated object files"

# ============================================================================
# BUILD DIRECTORIES
# ============================================================================
build-dirs:
	@mkdir -p $(OBJ_DIR) $(LIB_DIR) $(MOD_DIR) $(INC_DIR) $(EXE_DIR)

# ============================================================================
# FORM_FACT LIBRARY BUILD
# ============================================================================
form_fact: build-dirs $(FF_LIB)

parse-f0: check-deps-csv
	@$(OC) -package csv -linkpkg $(FF_PARSE_DIR)/f0.ml -o f0_gen && \
		./f0_gen "$(FF_F0_DATA)" && \
		mv f0.f90 $(FF_SRC_DIR)/ && \
		rm -rf f0_gen 

parse-f1_f2: check-deps-yojson
	@$(OC) -package yojson,str -linkpkg $(FF_PARSE_DIR)/f1_f2.ml -o f1_f2_gen && \
		./f1_f2_gen "$(FF_F12_DATA)" && \
		mv f1_f2.f90 $(FF_SRC_DIR)/ && \
		rm -rf f1_f2_gen

$(FF_LIB): $(FF_F0_OBJ) $(FF_F12_OBJ) $(FF_FF_OBJ)
	@ar rcs $@ $^

$(FF_F0_OBJ): $(FF_F0_SRC)
	@$(FC) $(CFLAGS) -J$(MOD_DIR) -c $< -o $@

$(FF_F12_OBJ): $(FF_F12_SRC)
	@$(FC) $(CFLAGS) -J$(MOD_DIR) -c $< -o $@

$(FF_FF_OBJ): $(FF_FF_SRC) $(FF_F0_OBJ) $(FF_F12_OBJ)
	@$(FC) $(CFLAGS) -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

$(FF_F0_SRC): | check-deps-csv
	@echo "f0.f90 not found, parsing from $(FF_F0_DATA)"
	@$(OC) -package csv -linkpkg $(FF_PARSE_DIR)/f0.ml -o f0_gen && \
		./f0_gen "$(FF_F0_DATA)" && \
		mv f0.f90 $(FF_SRC_DIR)/ && \
		rm -rf f0_gen

$(FF_F12_SRC): | check-deps-yojson
	@echo "f1_f2.f90 not found, parsing from $(FF_F12_DATA)"
	@$(OC) -package yojson,str -linkpkg $(FF_PARSE_DIR)/f1_f2.ml -o f1_f2_gen && \
		./f1_f2_gen "$(FF_F12_DATA)" && \
		mv f1_f2.f90 $(FF_SRC_DIR)/ && \
		rm -rf f1_f2_gen 

# ============================================================================
# ATOM_XYZ LIBRARY BUILD
# ============================================================================
atom_xyz: build-dirs parse-xyz tabulate-xyz generate-xyz-includes $(AXY_LIB)

parse-xyz:
	@rm -rf $(AXY_TMP_DIR)
	@$(OC) -package str -linkpkg $(AXY_PARSE_DIR)/xyz_parser.ml -o xyz_parser
	@./xyz_parser $(AXY_DATA_DIR)/*.xyz
	@rm -rf xyz_parser
	@mkdir -p $(AXY_TMP_DIR)
	@mv xyz_*.f90 $(AXY_TMP_DIR)

tabulate-xyz:
	@for f in $(AXY_DATA_DIR)/*.xyz; do \
		echo "xyz_$$(basename "$$f" .xyz)_mod.mod"; \
	done > $(AXY_LST)

generate-xyz-includes:
	@$(OC) $(AXY_PARSE_DIR)/mod_parser.ml -o mod_parser
	@./mod_parser $(AXY_LST)
	@rm -rf mod_parser
	@mv mod_uses.inc $(AXY_USE)
	@mv mod_switches.inc $(AXY_SWT)

$(AXY_ATM_OBJ): $(AXY_ATM_SRC)
	@$(FC) $(CFLAGS) -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

$(OBJ_DIR)/xyz_%.o: $(AXY_TMP_DIR)/xyz_%.f90
	@echo "compiling: $<"
	@$(FC) $(CFLAGS) -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

$(AXY_LIB): $(AXY_ATM_OBJ) $(AXY_XYZ_OBJ)
	@ar rcs $@ $^
	@rm -rf $(AXY_TMP_DIR)

# ============================================================================
# KDT LIBRARY BUILD
# ============================================================================
kdt: build-dirs $(KDT_LIB)

$(KDT_OBJ): $(KDT_SRC)
	@$(FC) $(CFLAGS) -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

$(KDT_LIB): $(KDT_OBJ)
	@ar rcs $@ $^

# ============================================================================
# ESTIMATE LIBRARY BUILD
# ============================================================================
estimate: build-dirs $(EST_LIB)

$(EST_OBJ): $(EST_SRC)
	@$(FC) $(CFLAGS)  -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

$(EST_LIB): $(EST_OBJ)
	@ar rcs $@ $^

# ============================================================================
# CSV_INTERFACE LIBRARY BUILD
# ============================================================================
csv-interface: build-dirs check-deps-csv $(CSV_LIB)

$(CSV_BRD_OBJ): $(CSV_BRD_SRC)
	@$(CC) -I$(shell ocamlc -where) -DCAML_NAME_SPACE -fPIC -c -o $@ $<

$(CSV_OUT_OBJ): $(CSV_OUT_SRC)
	@$(OC) -output-obj -package csv -linkpkg -o $@ $<

$(CSV_API_OBJ): $(CSV_API_SRC)
	@$(FC) $(CFLAGS) -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

$(CSV_LIB): $(CSV_BRD_OBJ) $(CSV_OUT_OBJ) $(CSV_API_OBJ)
	@ar rcs $@ $^

# ============================================================================
# MAIN EXECUTABLE BUILD
# ============================================================================
main: $(MAIN_EXE)
$(MAIN_EXE): $(MAIN_SRC) $(wildcard $(LIB_DIR)/*.a)
	@$(FC) $(CFLAGS) -I$(MOD_DIR) $(MAIN_SRC) \
	$(FF_LIB) $(AXY_LIB) $(KDT_LIB) $(EST_LIB) \
	$(CSV_BRD_OBJ) $(CSV_OUT_OBJ) $(CSV_API_OBJ) \
	-L$(shell ocamlc -where) -lasmrun_pic -ldl -lm -lpthread \
	-o $(MAIN_EXE)
# ============================================================================
# OCAML DEPENDENCY CHECKING
# ============================================================================
check-ocaml:
	@which $(OCAMLFIND) > /dev/null 2>&1 || \
		(echo "ERROR: ocamlfind not found. Please install OCaml and opam first." && \
		echo "Visit: https://ocaml.org/docs/install.html" && \
		exit 1)

check-deps-csv: check-ocaml
	@$(call check_and_install,csv)

check-deps-yojson: check-ocaml
	@$(call check_and_install,yojson str)

check-deps-str: check-ocaml
	@$(call check_and_install,str)

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
compile-pdb-2-xyz: build-dirs $(PDB_EXE)

$(PDB_OBJ): $(PDB_SRC)
	@$(FC) $(CFLAGS) -J$(MOD_DIR) -c $< -o $@

$(PDB_EXE): $(PDB_OBJ)
	@$(FC) $(PDB_OBJ) -o $(PDB_EXE)

pdb-2-xyz:
	@read -p "Enter xyz filename: " file; \
	./$(PDB_EXE) $$file; \
	mv *.xyz $(AXY_DATA_DIR)

# ============================================================================
# POSTAMBLE
# ============================================================================
postamble:
	@echo "=================================="
	@echo "Compilation complete"
	@echo "Compiled xyz molecules: $(AXY_LST)"
	@echo "Executable: $(MAIN_EXE)"
	@echo "=================================="

# ============================================================================
# CLEAN TARGETS
# ============================================================================
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