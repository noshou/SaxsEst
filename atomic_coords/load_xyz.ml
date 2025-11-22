exception Malformed_xyzEntry of string
exception Malformed_xyzFile of string
(* matches tab/space-delimited files (TSV) *)
let re_tsv = Str.regexp (
	"^\\([A-Za-z]+\\)[ \t]+"		^
	"\\(-?[0-9]+\\.[0-9]+\\)[ \t]+"	^
	"\\(-?[0-9]+\\.[0-9]+\\)[ \t]+"	^
	"\\(-?[0-9]+\\.[0-9]+\\)$"
	)

(* matches comma-delimited files (CSV) *)
let re_csv = Str.regexp(
	"^\\([A-Za-z]+\\)[ \t]*,[ \t]*" 		^
	"\\(-?[0-9]+\\.[0-9]+\\)[ \t]*,[ \t]*" 	^
	"\\(-?[0-9]+\\.[0-9]+\\)[ \t]*,[ \t]*" 	^
	"\\(-?[0-9]+\\.[0-9]+\\)$"
)

(** loads an xyz file (tsv or csv) from a file path.
Note: the list is returned backwards w.r.t how the file was read *)
let load_xyz fp =

    (* initialize mutable empty list of atoms *)
    let atoms = ref [] in 
	(* read first line (#atoms) and skip second line of xyz file*)
	let f = open_in fp in 

	(* parse file; any errors cause immediate abort; end of file handled in special case :) *)
	try 

		let size = int_of_string (String.trim(input_line f)) in 
		let _ = input_line f in 

		(* first data row parsing *)
		let row = String.trim(input_line f) in 

		(* detect delim type *)
		let _delimType =
			if Str.string_match re_tsv row 0 then
				re_tsv
			else if Str.string_match re_csv row 0 then
				re_csv
			else
				raise (Malformed_xyzFile "xyz file must be csv or tsv!")
		in 
		
		
		(* error message *)
		let errmsg m =
			if _delimType == re_tsv then
				"Expected tsv; got: " ^ m
			else if _delimType == re_csv then
				"Expected csv; got: " ^ m
			else
				"Unknown delimiter; got: " ^ m
		in

		if (Str.string_match _delimType row 0) then 
			begin

			(* parse data from first row *)			
			let n = Str.matched_group 1 row in 
			
			let p : Atom_.coord = 
				{   x = float_of_string (Str.matched_group 2 row);
					y = float_of_string (Str.matched_group 3 row);
					z = float_of_string (Str.matched_group 4 row);
				}
			in 
			atoms := (Atom_.create_atom p n) :: !atoms;
			end 
		else 
			raise (Malformed_xyzEntry (errmsg row))
		;

	    (* parse rest of file *)
		let itr = ref 1 in (* have already seen last first item *)
    while !itr <= size do 
      print_endline (string_of_int !itr);
			(* raise end of line expection if size == line *)
			let row = String.trim (input_line f) in 

			if (Str.string_match _delimType row 0) then 
			begin
                let n = Str.matched_group 1 row in 
                let p : Atom_.coord = 
                    {   x = float_of_string (Str.matched_group 2 row);
                        y = float_of_string (Str.matched_group 3 row);
                        z = float_of_string (Str.matched_group 4 row)
                    }
                in 
                atoms := (Atom_.create_atom p n) :: !atoms;
			end 
            else 
                raise (Malformed_xyzEntry (errmsg row))
			;
			itr := !itr + 1
    done;
        close_in f; !atoms; 
    
	with 
        | End_of_file -> close_in f; !atoms 
        | e -> close_in_noerr f; raise e
