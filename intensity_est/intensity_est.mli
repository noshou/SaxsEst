(** Calculates the scattering intensity [I(Q)] using the Debye scattering approximation
over [[0.0, 0.5]] :
{[I(Q) = ∑ᵢ∑ⱼ fᵢ fⱼ* sinc(Q ·||rᵢ - rⱼ||)]}

Where:
		- [fᵢ] — form factor of atom [i]  
		- [fⱼ*] — complex conjugate of the form factor of atom [j]  
		- [rᵢ], [rⱼ] — positions of atoms [i] and [j], respectively  
		- [Q] — scattering vector (in Å⁻¹)
		- {[
				sinc(x) =
					if x == 0 then
						1
					if x != 0 then
						(sin x) / x 
			]}

The time complexity of the algorithm is [O(m·n²)] where [m] is 
the number of [Q] values iterated over, and [n] is the number of atoms 
in the xyz file.

@param xyz_file  Path to the input XYZ file containing atomic coordinates.  
@param tol optional precision; default is [1e-10]
@param run optional stem of csv file; default is ["classic"] (WILL OVERWRITE EXISTING FILES!)
@param clk optional output of timing as [<run>_timing.txt]; default is [false] (WILL OVERWRITE EXISTING FILES!)
@return the time it took to run (nanoseconds)*)
val classic : string -> ?tol:float -> ?run:string -> ?clk:bool -> unit -> Int64.t