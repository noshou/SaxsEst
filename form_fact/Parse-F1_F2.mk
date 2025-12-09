# Builds f1_f2.f90 module (tabulated anomalous scattering factors)
# NOTE: only need to run this script if data has been changed!

# Ocaml compiler / build tools
OCAMLFIND 	= ocamlfind
OC 			= $(OCAMLFIND) ocamlopt
OPAM 		= opam
REQUIRED 	= str yojson

# data files (CHANGE IF NEEDED)
F1_F2_DATA 	= "data/f1_f2_factors/(12412.8)eV_f1_f2.json"

# executables
F1_F2_GEN 	= "data_parsing/f1_f2.ml"

# compiled executables
F1_F2_EXE 	= f1_f2

# check ocaml dependencies - install if needed
.PHONY: all 

# first runs check-deps, then continues compilation
all: check-deps
	@$(OC) -package yojson,str -linkpkg $(F1_F2_GEN) -o $(F1_F2_EXE)
	@./$(F1_F2_EXE) $(F1_F2_DATA)
	@rm -rf $(F1_F2_EXE)
	@rm -rf data_parsing/*.cmi data_parsing/*.cmx data_parsing/*.o
	@mv f1_f2.f90 src/f1_f2.f90
	
## OCAML DEPENDENCY CHECKING ##

# check ocamlfind
check-ocaml:
	@which $(OCAMLFIND) > /dev/null 2>&1 || \
    (echo "ERROR: ocamlfind not found. Please install OCaml and opam first." && \
	echo "Visit: https://ocaml.org/docs/install.html" && \
	exit 1)

# Check if all required packages are installed
check-deps: check-ocaml
	@missing="" ; \
	for pkg in $(REQUIRED); do \
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
			$(MAKE) install-deps PACKAGES="$$missing" ; \
		else \
			echo "Please install manually with: opam install$$missing" ; \
			exit 1 ; \
		fi ; \
	fi

# Install missing packages via opam
install-deps:
	@if [ -z "$(PACKAGES)" ]; then \
		echo "No packages specified to install." ; \
	else \
		echo "Installing OCaml packages:$(PACKAGES)" ; \
		$(OPAM) install -y $(PACKAGES) ; \
	fi