open Atom

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
let classic fp ?(tol = 1e-10) ?(run = "classic") ?(clk = false) () : Int64.t = 
	
	(* returns sinc(x) = sin(x)/x, x!=0; 1 x == 0 *)
	let sinc x =
		if (Float.abs x) <= tol then 1.
		else sin(x) /. x
	in 
	
	(* load xyz file *)
	let atoms = load_xyz fp in 
    
	(* this is the normalization constant (will be used to divide I(Q) by) *)
	let normalize = float_of_int(List.length atoms) *. float_of_int(List.length atoms) in

	(* Q (Å⁻¹) iterate from 0.00 -> 0.5 in increments of 0.02 *)
	let qa = ref 0. in 

	(* containers for eventual writing to csv file;
	must be strings so we can use Csv module *)
	let csv_list  : string list list ref = ref [["q_inverse_angstrom"; "intensity"]] in

    
	(* NOTE: hard coded at 0.5 for now (25 steps) *)
	let steps = int_of_float (0.5 /. 0.02) in
	let itr = ref 0 in 
	let start_time = Mtime_clock.now () in 

	while !itr <= steps do 
		
		(* current I(Q) value *)
		let qi = ref 0. in 
        
		(* calculate pairwise summation *)
		List.iter (fun atom_i ->  
			List.iter (fun atom_j ->
				
				(* unpack atoms *)
				let i_ff = form_factor atom_i !qa in 
				let j_ff = form_factor atom_j !qa in 
				let i_pt = xyz atom_i in 
				let j_pt = xyz atom_j in 
				(* calculate distance *)
				let dist = sqrt (
					(i_pt.x -. j_pt.x) ** 2. 
					+. (i_pt.y -. j_pt.y) ** 2. 
					+. (i_pt.z -. j_pt.z) ** 2.)
				in 
				
				(* calculate radial contribution = sinc(Q * |r_i - r_j|) *)
				let radial = sinc (!qa *. dist) in 
				
				(* calculate i_f * (conjugate(j_f)) 
				turns out because of weird symmetry we can 
				ignore the complex part (since the summation over
				all pairs is real) *)
				let facts = (Complex.mul i_ff (Complex.conj j_ff)).re in 
				
				(* add to qi *)
				qi := !qi +. ((facts *. radial) /. normalize)
			) atoms 
		) atoms;
		
		(* create new row (I vs I(Q)) and preprend (not append due to time complexity) *)
		let row = [string_of_float !qa; string_of_float !qi] in 
		csv_list := row :: !csv_list;
		
		(* increment Q and iteration counter *)
		qa := !qa +. 0.02;
		itr := !itr + 1
	done;
	(* log time *)
	let end_time = Mtime_clock.now () in 
	let duration = (
		Mtime.Span.to_uint64_ns (
			Mtime.span start_time end_time
			)
		) 
	in 

	(* stdout *)
  Printf.printf   "\n";
	Printf.printf 	"RUN:           %s\n" run;
	Printf.printf   "ALGORITHM:     DEBEYE-CLASSIC\n";
	Printf.printf   "DURATION (ns): %f\n" (Int64.to_float(duration));
  Printf.printf   "\n";
	
	if clk then begin
		let line1 = Printf.sprintf "RUN:           %s\n" run in
		let line2 = Printf.sprintf "ALGORITHM:     DEBEYE-CLASSIC\n" in 
		let line3 = Printf.sprintf "DURATION (ns): %f\n" (Int64.to_float duration) in
		let lines = line1 ^ line2 ^ line3 in
		let f = run ^ "_timing.txt" in 
		let oc = Out_channel.open_text f in 
		Out_channel.output_string oc lines;
		Out_channel.close oc
    end;

	(* save to csv file (note: must reverse csv list!) *)
	Csv.save (run ^ ".csv") (List.rev !csv_list);

  (* return duration *)
  duration