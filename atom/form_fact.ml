open F_0 
open F1_f2_lookup
exception Invalid_element of string

(** form_fact(q, elm) = f0(q, elm) + f1(elm) + i*f2(elm) *)
let form_fact (q : float) (elm : string) : Complex.t = 
    let (f1, f2) = get_f1_f2 elm in
    {re = f1 +. (get_f0 q elm); im = f2}
