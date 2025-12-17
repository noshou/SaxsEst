Library generates f90 modules from XYZ coordinate files in the data directory. 
Generated files can be extremely large, so they are deleted after compilation. 
A list of available xyz module names is printed as an output (_build/xyz_modules.txt).

API FOR XYZ FILES

public methods:
	n_atoms: 	# atoms in the molecule
	get_atoms() returns an array of atom objects  
