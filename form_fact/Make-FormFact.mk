# compiles form_fact library into a static library

# compiler  
# TODO: these should be arguments passed by a "master" makefile or bash script
FC          = gfortran
FFLAGS      = -g -O3 -march=native -pedantic -Wno-tabs

# build directory
BLD_DIR     = _build
MOD_DIR     = $(BLD_DIR)/mod
LIB_DIR     = $(BLD_DIR)/lib

# source files
F0_SRC      = src/f0.f90
F12_SRC     = src/f1_f2.f90
FF_SRC      = src/form_fact.f90

# object files
F0_OBJ      = $(BLD_DIR)/f0.o
F12_OBJ     = $(BLD_DIR)/f1_f2.o
FF_OBJ      = $(BLD_DIR)/form_fact.o

# library
LIB_NAME    = $(LIB_DIR)/form_fact.a

.PHONY: all check clean

all: check $(LIB_NAME) clean_up

# check if f0.f90 and f1_f2.f90 are present; if they are not, build them
check:
	@if [ ! -f "$(F0_SRC)" ]; then \
		$(MAKE) --no-print-directory -f Parse-F0.mk ; \
	fi
	@if [ ! -f "$(F12_SRC)" ]; then \
		$(MAKE) --no-print-directory -f Parse-F1_F2.mk ; \
	fi

# build directories
$(BLD_DIR) $(MOD_DIR) $(LIB_DIR):
	@mkdir -p $@

# compile f0 module (no dependencies)
$(F0_OBJ): $(F0_SRC) | $(BLD_DIR) $(MOD_DIR)
	@$(FC) $(FFLAGS) -J$(MOD_DIR) -c $< -o $@

# compile f1_f2 module (no dependencies)
$(F12_OBJ): $(F12_SRC) | $(BLD_DIR) $(MOD_DIR)
	@$(FC) $(FFLAGS) -J$(MOD_DIR) -c $< -o $@

# compile form_fact module (depends on f0 and f1_f2)
$(FF_OBJ): $(FF_SRC) $(F0_OBJ) $(F12_OBJ) | $(BLD_DIR) $(MOD_DIR)
	@$(FC) $(FFLAGS) -I$(MOD_DIR) -J$(MOD_DIR) -c $< -o $@

# create static library
$(LIB_NAME): $(F0_OBJ) $(F12_OBJ) $(FF_OBJ) | $(LIB_DIR)
	@ar rcs $@ $^

# remove stray obj files
clean_up:
	@rm -rf _build/*.o

# clean
clean:
	@rm -rf $(BLD_DIR)