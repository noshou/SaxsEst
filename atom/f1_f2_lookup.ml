open Yojson.Basic
exception Invalid_element of string 

(* loads a hashtable of f1/f2 factors  *)
let lookup = from_file "data/anomolous_scattering_factors/124128eV_f1_f2.json"

(* f1 and f2 values at 12.4128 keV *)
let get_f1_f2 (elm : string) : float * float = 
    
    (* search for value; raise error if not found *)
    let elm_lower = String.lowercase_ascii elm in 
    try
        (* Yojson returns a Basic.List [Basic.List[<data>]] so we must unwrap it :/ *)
        let lst = 
            Util.to_list (List.nth (Util.to_list (lookup |> Util.member elm_lower)) 0) 
        in
        (Util.to_float (List.nth lst 0), Util.to_float (List.nth lst 1))
    with _ ->
        raise (Invalid_element elm)
