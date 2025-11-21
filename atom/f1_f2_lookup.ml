open Yojson.Basic
exception Invalid_element of string 

(* loads a hashtable of f1/f2 factors  *)
let lookup = from_file "data/anomolous_scattering_factors/(12412.8)eV_f1_f2.json"


(* since f1/f2 only contain ground state, if it has <elm>x+/-, 
we must remove it and pass only <elm> *)
let re_elm = Str.regexp "\\([A-Za-z]+\\)\\([0-9]*\\)\\([0-9]*[+-]\\)?"

(* f1 and f2 values at 12.4128 keV *)
let get_f1_f2 (elm : string) : float * float = 
    
    (* search for value; raise error if not found *)
    let elm_lower = 
        if (Str.string_match re_elm elm 0) then
            Str.matched_group 1 elm
        else
            raise (Invalid_element elm)
    in 
    try
        (* Yojson returns a Basic.List [Basic.List[<data>]] so we must unwrap it :/ *)
        let lst = 
            Util.to_list (List.nth (Util.to_list (lookup |> Util.member elm_lower)) 0) 
        in
        (Util.to_float (List.nth lst 0), Util.to_float (List.nth lst 1))
    with _ ->
        raise (Invalid_element elm) 
