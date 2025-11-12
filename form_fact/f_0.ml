(* load hashtable *)
let df = Owl_dataframe.of_csv ~sep:',' "data/regular_scattering_factor/f0.csv"

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

    (* q = 0.02 * row# -> row# = floor (q/0.02) *)
    let row = int_of_float (floor (q /. 0.02)) in

    (* check if elm is in *)
    let col =
      match elm with
      | "h"  -> 1
      | "he" -> 2
      | "li" -> 3
      | "be" -> 4
      | "b"  -> 5
      | "c"  -> 6
      | "n"  -> 7
      | "o"  -> 8
      | "f"  -> 9
      | "ne" -> 10
      | "na" -> 11
      | "mg" -> 12
      | "al" -> 13
      | "si" -> 14
      | "p"  -> 15
      | "s"  -> 16
      | "cl" -> 17
      | "ar" -> 18
      | "k"  -> 19
      | "ca" -> 20
      | _ -> failwith ("Unknown element: " ^ elm)
    in 

    (* fetch value at df[row;col] *)
    Owl_dataframe.unpack_float (Owl_dataframe.get df row col)
