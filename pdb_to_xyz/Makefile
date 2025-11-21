# FORTRAN compiler
FC = gfortran

# compiler flags
CFLAGS = -Wall -pedantic -g

# linker flags
LDFLAGS = # empty; just here for boilerplate purposes :)

all: pdb_to_xyz

# compile .f90 module into object file
pdb_to_xyz.o: pdb_to_xyz.f90
	@$(FC) $(CFLAGS) -c pdb_to_xyz.f90 -o pdb_to_xyz.o

# link .o file -> executable
pdb_to_xyz: pdb_to_xyz.o
	@$(FC) $(LDFLAGS) pdb_to_xyz.o -o pdb_to_xyz

clean:
	@rm -f pdb_to_xyz pdb_to_xyz.o
