(* f0.ml *)

exception Invalid_csv  of string

(* loads q, e, f into lists from csv file. *)
let load_data fp = 
	
	(* list of form factors representing rows *)
	let q = ref [] in 

	(* list of elements representing columns *)
	let e = ref [] in 

	(* 2x2 list where each element f[q][i] is a form factor *)
	let f = ref [] in 

	(Csv.load fp) 
	|> List.iteri (

        (* iterate through rows; first row is header, add to list of elements *)
        fun idx row ->

			(* skip first column, add element names to list *)
			if idx == 0 then  begin 
                let rec add_to (list : string list) (accum : string list ) = match list with 
                    | []            -> accum
                    | elm :: list  -> add_to list (elm :: accum) 
                in e := add_to (List.tl row) [];
			end 
			
			(* for n rows: first column goes to q, rest go to f *)
			else match row with 
				| q_val :: f_vals ->

					(* round to nearest 100th *)
					let q_rnd = (Float.round ((float_of_string q_val) *. 100.)) /. 100. in
					q := q_rnd :: !q;

                let rec add_to (list : string list) (accum : float list ) = match list with 
                    | []           -> accum
                    | elm :: list  -> add_to list ((float_of_string elm) :: accum) 
                in f := (add_to f_vals []) :: !f
				
              | [] -> ();
		);

	(* return lists *)
	(List.rev !q, !e, List.rev !f)


(* writes parsed data to Fortran *)
let f0_toFortran csv_fp = 

	(* fill q, e, f with data *)
	let q,e,f = load_data csv_fp in 

	(* write to Fortran at specified output *)
	let oc = open_out "f0.f90" in 
	
	(* Write module header with documentation *)
	Printf.fprintf oc "!===============================================================================\n";
	Printf.fprintf oc "! Module: f0_mod\n";
	Printf.fprintf oc "!\n";
	Printf.fprintf oc "! Description:\n";
	Printf.fprintf oc "!   Atomic form factors f0 for X-ray scattering calculations.\n";
	Printf.fprintf oc "!   f0(Q) represents the scattering amplitude of an atom as a function\n";
	Printf.fprintf oc "!   of the scattering vector Q = (sin θ)/λ.\n";
	Printf.fprintf oc "!\n";
	Printf.fprintf oc "! Data Source:\n";
	Printf.fprintf oc "!   International Tables for Crystallography Vol. C\n";
	Printf.fprintf oc "!   DOI: 10.1107/97809553602060000600\n";
	Printf.fprintf oc "!\n";
	Printf.fprintf oc "! Usage:\n";
	Printf.fprintf oc "!   use f0_mod, only: get_f0\n";
	Printf.fprintf oc "!   real(real64) :: f0_value\n";
	Printf.fprintf oc "!   f0_value = get_f0(q=0.25_real64, element='Fe')\n";
	Printf.fprintf oc "!\n";
	Printf.fprintf oc "! Note: Q values are rounded to nearest 0.01 Å⁻¹\n";
	Printf.fprintf oc "!===============================================================================\n";
	Printf.fprintf oc "module f0_mod\n";
	Printf.fprintf oc "\tuse iso_fortran_env, only: real64\n";
	Printf.fprintf oc "\timplicit none\n\n";
	Printf.fprintf oc "\tprivate\n\n";
	
	Printf.fprintf oc "\t! Public interface\n";
	Printf.fprintf oc "\tpublic :: n_elements, n_q_values\n";
	Printf.fprintf oc "\tpublic :: get_f0\n\n";
	
	Printf.fprintf oc "\t!---------------------------------------------------------------------------\n";
	Printf.fprintf oc "\t! Module Data\n";
	Printf.fprintf oc "\t!---------------------------------------------------------------------------\n\n";
	
	Printf.fprintf oc "\t! Number of elements and Q values in lookup table\n";
	Printf.fprintf oc "\tinteger, parameter :: n_elements = %d\n" (List.length e); 
	Printf.fprintf oc "\tinteger, parameter :: n_q_values = %d\n\n" (List.length q);
	
	(* write element names to array *)
	Printf.fprintf oc "\t! Element/ion symbols (lowercase)\n";
	Printf.fprintf oc "\tcharacter(len=4), parameter :: elements(%d) = [ &\n" (List.length e);
	List.iteri (
		fun idx element -> 
        if (idx == 0) then 
            Printf.fprintf oc "\t\t\t'%-4s'" element 
        else 
            Printf.fprintf oc ", &\n\t\t\t'%-4s'" element 
		) e;
    Printf.fprintf oc " ]\n\n";
    
	(* write q values to array *)
	Printf.fprintf oc "\t! Scattering vector magnitudes: Q = (sin θ)/λ in Å⁻¹\n";
	Printf.fprintf oc "\t! Range: 0 to ~2.0 Å⁻¹ in increments of 0.01 Å⁻¹\n";
	Printf.fprintf oc "\treal(real64), parameter :: q_values(%d) = [ &\n" (List.length q);
	List.iteri (
    fun idx q -> 
        if (idx == 0) then 
            Printf.fprintf oc "\t\t\t%f_real64" q 
        else
            Printf.fprintf oc ", &\n\t\t\t%f_real64" q
	) q;
	Printf.fprintf oc " ]\n\n";

	(* write f0_data*)
	Printf.fprintf oc "\t! Form factor data: f0(Q) for each element\n";
	Printf.fprintf oc "\t! Rows: Q values, Columns: Elements\n";
	Printf.fprintf oc "\t! f0 decreases with increasing Q due to destructive interference\n";
	Printf.fprintf oc "\treal(real64), parameter :: f0_data(%d,%d) = reshape([ &\n" (List.length q) (List.length e);
	List.iter (
    let idx = ref 0 in 
    fun row -> List.iter (
        fun col -> 
            if !idx == 0 then Printf.fprintf oc "\t\t\t%f_real64" col 
            else Printf.fprintf oc ", &\n\t\t\t%f_real64" col;
        idx := !idx + 1;
    ) row  
	) f;
	Printf.fprintf oc " &\n\t], shape=[%d,%d], order=[2,1])\n\n" (List.length q) (List.length e);
	
	(* methods *)
	Printf.fprintf oc "contains\n\n";

  Printf.fprintf oc "\t! Convert string to lowercase\n";
  Printf.fprintf oc "\tpure function to_lower(str) result(lower_str)\n";
  Printf.fprintf oc "\t\t\tcharacter(len=*), intent(in) :: str\n";
  Printf.fprintf oc "\t\t\tcharacter(len=len(str)) :: lower_str\n";
  Printf.fprintf oc "\t\t\tinteger :: i, ic\n";
  Printf.fprintf oc "\t\t\tlower_str = str\n";
  Printf.fprintf oc "\t\t\tdo i = 1, len(str)\n";
  Printf.fprintf oc "\t\t\t\t\tic = iachar(str(i:i))\n";
  Printf.fprintf oc "\t\t\t\t\tif (ic >= 65 .and. ic <= 90) lower_str(i:i) = achar(ic + 32)\n";
  Printf.fprintf oc "\t\t\tend do\n";
  Printf.fprintf oc "\tend function to_lower\n\n";


	(* initialize f0 data *)
	Printf.fprintf oc "\t!---------------------------------------------------------------------------\n";
	Printf.fprintf oc "\t! Function: get_f0\n";
	Printf.fprintf oc "\t!\n";
	Printf.fprintf oc "\t! Description:\n";
	Printf.fprintf oc "\t!   Returns the atomic form factor for a given element at a specific Q.\n";
	Printf.fprintf oc "\t!\n";
	Printf.fprintf oc "\t! Arguments:\n";
	Printf.fprintf oc "\t!   q       [in]  - Scattering vector magnitude (sin θ)/λ in Å⁻¹\n";
	Printf.fprintf oc "\t!   element [in]  - Element symbol (case-insensitive, e.g., 'Fe', 'cu')\n";
	Printf.fprintf oc "\t!\n";
	Printf.fprintf oc "\t! Returns:\n";
	Printf.fprintf oc "\t!   f0_val - Atomic form factor (electrons)\n";
	Printf.fprintf oc "\t!\n";
	Printf.fprintf oc "\t! Notes:\n";
	Printf.fprintf oc "\t!   - Q is rounded to nearest 0.01 Å⁻¹ for lookup\n";
	Printf.fprintf oc "\t!   - Program stops with error if element or Q not found\n";
	Printf.fprintf oc "\t!---------------------------------------------------------------------------\n";
	Printf.fprintf oc "\tfunction get_f0(q, element) result(f0_val)\n";
	Printf.fprintf oc "\t\t\treal(real64), intent(in) :: q\n";
	Printf.fprintf oc "\t\t\tcharacter(len=*), intent(in) :: element\n";
	Printf.fprintf oc "\t\t\treal(real64) :: f0_val\n";
	Printf.fprintf oc "\t\t\tinteger :: q_idx, elem_idx, i\n";
	Printf.fprintf oc "\t\t\treal(real64) :: q_round\n";
	Printf.fprintf oc "\t\t\tcharacter(len=10) :: element_lower\n\n";
	Printf.fprintf oc "\t\t\t! Convert element to lower case\n";
	Printf.fprintf oc "\t\t\telement_lower = to_lower(element)\n\n";
	Printf.fprintf oc "\t\t\t! Round q to nearest 0.01 Å⁻¹\n";
	Printf.fprintf oc "\t\t\tq_round = ceiling(q * 100_real64) / 100_real64\n\n";
	Printf.fprintf oc "\t\t\t! Find element index\n";
	Printf.fprintf oc "\t\t\telem_idx = -1\n";
	Printf.fprintf oc "\t\t\tdo i = 1, n_elements\n";
	Printf.fprintf oc "\t\t\t\t\tif (trim(elements(i)) == trim(element_lower)) then\n";
	Printf.fprintf oc "\t\t\t\t\t\t\telem_idx = i\n";
	Printf.fprintf oc "\t\t\t\t\t\t\tEXIT\n";
	Printf.fprintf oc "\t\t\t\t\tend if\n";
	Printf.fprintf oc "\t\t\tend do\n\n";
	Printf.fprintf oc "\t\t\tif (elem_idx == -1) then\n";
	Printf.fprintf oc "\t\t\t\t\twrite(*, '(A, A, A)') 'ERROR in get_f0: Element \"', &\n";
	Printf.fprintf oc "\t\t\t\t\t\t\ttrim(element), '\" not found'\n";
	Printf.fprintf oc "\t\t\t\t\terror stop\n";
	Printf.fprintf oc "\t\t\tend if\n\n";
	Printf.fprintf oc "\t\t\t! Find Q index\n";
	Printf.fprintf oc "\t\t\tq_idx = -1\n";
	Printf.fprintf oc "\t\t\tdo i = 1, n_q_values\n";
	Printf.fprintf oc "\t\t\t\t\tif (abs(q_values(i) - q_round) < 1.0e-6_real64) then\n";
	Printf.fprintf oc "\t\t\t\t\t\t\tq_idx = i\n";
	Printf.fprintf oc "\t\t\t\t\t\t\tEXIT\n";
	Printf.fprintf oc "\t\t\t\t\tend if\n";
	Printf.fprintf oc "\t\t\tend do\n\n";
	Printf.fprintf oc "\t\t\tif (q_idx == -1) then\n";
	Printf.fprintf oc "\t\t\t\t\twrite(*, '(A, F12.6, A)') 'ERROR in get_f0: Q value ', &\n";
	Printf.fprintf oc "\t\t\t\t\t\t\tq_round, ' not found in table'\n";
	Printf.fprintf oc "\t\t\t\t\terror stop\n";
	Printf.fprintf oc "\t\t\tend if\n\n";
	Printf.fprintf oc "\t\t\t! Access f0 value and return\n";
	Printf.fprintf oc "\t\t\tf0_val = f0_data(q_idx, elem_idx)\n\n";
	Printf.fprintf oc "\tend function get_f0\n\n";
	Printf.fprintf oc "end module f0_mod\n";
	
	close_out oc

(* Main entry point *)
let () =
  if Array.length Sys.argv != 2 then begin
    Printf.eprintf "Usage: %s <input.csv>\n" Sys.argv.(0);
    Printf.eprintf "  input.csv - CSV file with f0 form factor data\n";
    Printf.eprintf "  Outputs to: f0.f90\n";
    exit 1
  end;
  
  try
    f0_toFortran Sys.argv.(1)
  with 
  | Sys_error msg -> 
    Printf.eprintf "Error: %s\n" msg;
    exit 1
  | Csv.Failure (row, col, msg) ->
    Printf.eprintf "CSV Error at row %d, column %d: %s\n" row col msg;
    exit 1