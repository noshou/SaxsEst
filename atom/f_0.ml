
(*csv file is a list of nested string lists such that.:
[[headers]; [row_1 values (string)];  ... [row_n values]]

We want to make a hash map such that:
Q value -> list of f0 values
f0[elm] -> element's specific f0 value *)
let tbl = Hashtbl.create 100
let () = 
    (Csv.load "data/regular_scattering_factor/f0.csv")
    |> List.iteri (

        (* iterate through rows; first row are headers so skip it*)
        fun idx row ->
            if idx <> 0 then begin 
                
            (*  first value is Q idx; however, due to fp stuff, 
            we first convert each Q value into a float then 
            re-convert to fp string. For example: "0.00" would be 
            stored as that directly, but when a function calls 
            "string_of_float(0.)" that results in a string "0." 
            which would fail to query in the hashtable! *)
            let q =  string_of_float (float_of_string (List.hd row)) in 

            (* values f[1:] are form factor values at Q values; *)
            let f = List.tl row  in 

            (* Add to hashtable *)
            Hashtbl.add tbl q f
        end 
    )

(* each element matches to unique key *)
let idx s = match (String.lowercase_ascii s) with
  | "h"  -> 0
  | "he" -> 1
  | "li" -> 2
  | "be" -> 3
  | "b"  -> 4
  | "c"  -> 5
  | "n"  -> 6
  | "o"  -> 7
  | "f"  -> 8
  | "ne" -> 9
  | "na" -> 10
  | "mg" -> 11
  | "al" -> 12
  | "si" -> 13
  | "p"  -> 14
  | "s"  -> 15
  | "cl" -> 16
  | "ar" -> 17
  | "k"  -> 18
  | "ca" -> 19
  | _ -> failwith ("Invalid element: " ^ s)

(** gets f0 given a Q value, where:
f_0(Q) = ∑a_i*e^(-b_i * (Q)^2) + c,
where i ∈ [1, 4]; 0<(sinθ)/λ<2.0 Å⁻¹.
Source: 10.1107/97809553602060000600. For the sake of simplifying stuff, 
we will only go from 0 -> .50 Å⁻¹ in increments of 0.02. The wizards at the source provided
have already gracefully done all calculations for f0!
*)
let get_f0 (q : float) (elm : string) : float = 

    (* round q to nearest hundredth *)
    let round2 = (Float.round (q *. 100.)) /. 100. in 

    (* q value must be between 0.02 -> 0.5 *)
    if round2 < 0. || round2 > 0.5 
        then raise (Invalid_argument "Q out of bounds!");
    
    (* q * 100 must be even *)
    if (int_of_float (Float.round (q *. 100.)) mod 2) <> 0 then 
        raise (Invalid_argument "Q must be in increments of 0.02!") ;


    (* load possible values of f0 for given q *)
    let f0_vals = Hashtbl.find tbl (string_of_float q) in

    (* find + return f0 value *)
    float_of_string (List.nth f0_vals (idx elm))

