(* module for internal use only; re-exported in atom.ml *)

(* represents an <x,y,z> coordinate *)
type coord = {x: float; y: float; z: float}

(* represents an atom at coordinate xyz; internal to atom module *)
type atom = {xyz: coord; name: string;}

(* public constructor for atom *)
let create_atom p n =
    {   xyz = p; name = n}

(* public facing accessors *)
let xyz a = a.xyz
let name a = a.name
let form_fact a q = Form_fact.form_fact q a.name
let to_string a ?(q = 0.) () : string =
    let complex : Complex.t = form_fact a q in 
    let re = complex.re in 
    let im = complex.im in 
    Printf.sprintf "{\n\txyz: {x=%f; y=%f; z=%f};" a.xyz.x a.xyz.y a.xyz.z ^
    Printf.sprintf "\n\tname: %s;" a.name 
    ^
    Printf.sprintf "\n\tform_fact (Q=%f): {im=%f; re=%f}\n}" q im re
