
(* f_0.ml *)

(* loads q, e, f into lists from csv file. 
Example output: 
	!elements = ["He"; "C"; "O"]
  !q_values = ["0."; "0.02"]
  !f_data = [["2.0"; "6.0"; "8.0"; "26.0"];["2.1"; "6.1"; "8.1"; "26.1"]]*)
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


(** gets f0 given a Q value, where:
Source: 10.1107/97809553602060000600. For the sake of simplifying stuff, 
we will only go from 0 -> .50 Å⁻¹ in increments of 0.02. The wizards at the source provided
have already gracefully done all calculations for f0!
*)

(* writes parsed data to Fortran *)
let f0_toFortran csv_fp out_fp = 

	(* fill q, e, f with data *)
	let q,e,f = load_data csv_fp in 

	(* write to Fortran at specified output *)
	let oc = open_out out_fp in 
	
	(* set up module *)
  Printf.fprintf oc "!! Organizes";
	Printf.fprintf oc "module f0_mod\n";
  Printf.fprintf oc "\n\t\t! F_0 values are organized into an mxn matrix,";
  Printf.fprintf oc "\n\t\t! Where m = # of Q values, n = # of elements/ions.";
  Printf.fprintf oc "\n\t\t! Element names represent columns, Q values represent rows,";
	Printf.fprintf oc "\n\t\tuse iso_fortran_env, only: real64";
  Printf.fprintf oc "\n\t\tuse stdlib_strings, only: to_lower\n";
	Printf.fprintf oc "\t\timplicit none\n\n";
  Printf.fprintf oc "\t\tprivate\n";
  Printf.fprintf oc "\n\t\t! Public interface\n";
  Printf.fprintf oc "\t\tpublic :: n_elements, n_q_values\n";
  Printf.fprintf oc "\t\tpublic :: get_f0\n\n";
  Printf.fprintf oc "\t\t ! Module Data\n";
	Printf.fprintf oc "\t\tinteger, parameter :: n_elements = %d\n"   (List.length e); 
	Printf.fprintf oc "\t\tinteger, parameter :: n_q_values = %d\n" (List.length q);
	
  (* write element names to array *)
  Printf.fprintf oc "\t\t! Element names";
	Printf.fprintf oc "\t\tcharacter(len=10), parameter :: elements(%d) = [ &" (List.length e);
	List.iteri (
		fun idx element -> 
        if (idx == 0) then 
            Printf.fprintf oc ("\n\t\t\t\t%s") element 
        else 
            Printf.fprintf oc (", &\n\t\t\t\t%s") element 
		) e;
    Printf.fprintf oc " ]\n";
    
	(* write q values to array *)
  Printf.fprintf oc "\t\t! Scattering angles: 0< Q = (sinθ)/λ<2.0 Å⁻¹ ";
  Printf.fprintf oc "\t\treal(real64), parameter :: q_values(%d) = [ &" (List.length q);
  List.iteri (
    fun idx q -> 
        if (idx == 0) then 
            Printf.fprintf oc ("\n\t\t\t\t%f_real64") q 
        else
            Printf.fprintf oc (", &\n\t\t\t\t%f_real64") q
  ) q;
  Printf.fprintf oc " ]\n";

  (* write f0_data*)
  Printf.fprintf oc "\n\t\t! f_0(Q) = ∑a_i*e^(-b_i * (Q)^2) + c,"; 
  Printf.fprintf oc "\n\t\t!where a_i/b_i are elements,  0<(sinθ)/λ<2.0 Å⁻¹.";
  Printf.fprintf oc "\t\treal(real64), parameter :: f0_data(%d,%d)  = reshape([ &" (List.length q) (List.length e);
  List.iter (
    let idx = ref 0 in 
    fun row -> List.iter (
        fun col -> 
            if !idx == 0 then Printf.fprintf oc ("\n\t\t\t\t%f_real64") col 
            else Printf.fprintf oc (", &\n\t\t\t\t%f_real64") col;
        idx := !idx + 1;
    ) row  
  ) f;
  Printf.fprintf oc "&\n\t\t], shape=[%d,%d], order=[2,1])" (List.length q) (List.length e);
  
  (* methods *)
  Printf.fprintf oc "\n\n\t\t contains\n";

  (* initialize f0 data *)
  Printf.fprintf oc "\n\t\t\t\t! Returns the f0 value for a given element or ion";
  Printf.fprintf oc "\n\t\t\t\tfunction get_f0(q, element) result(f0_val)";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\treal(real64), intent(in) :: q";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tcharacter(len=8), intent(in) :: element";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tinteger :: q_idx, elem_idx";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\treal(real64) :: q_round";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tcharacter(len=8) :: element_lower";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tcharacter(len=8) :: i, j";
  Printf.fprintf oc "\n\n\t\t\t\t\t\t\t\t! Convert element to lower case";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\telement_lower = to_lower(element)";
  Printf.fprintf oc "\n\n\t\t\t\t\t\t\t\t! Round q to nearest 100th";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tq_round = ceiling(q*100_real64) / 100_real64 ";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t! Find q_idx, elem_idx from lookups";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tdo i = 1, n_elements+1";
(* should check: if i ==  n_elements+1 then we throw an exeception (not found)*)
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t\tif (elements(i) .EQ. telement_lower)";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\\t\t\telem_idx = i";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t\t\tEXIT";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t\t\tend if";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tend do";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tdo i = 1, n_q_values+1";
  (* should check: if i ==  n_q_values+1 then we throw an exeception (not found)*)
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t\tif (q_values(j) .EQ. q_round)";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\\t\t\q_idx = j";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t\t\tEXIT";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\t\t\tend if";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tend do";
  Printf.fprintf oc "\n\n\t\t\t\t\t\t\t\t! Access f0 value and return";
  Printf.fprintf oc "\n\t\t\t\t\t\t\t\tf0_val = f0_data(q_idx, elem_idx)";
  Printf.fprintf oc "\n\t\t\t\tend function get_f0";
