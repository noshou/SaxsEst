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

let cmp_by_axis ref cmp axs =
    match (String.lowercase_ascii axs) with 
        | "x" -> Float.compare cmp.xyz.x ref.xyz.x
        | "y" -> Float.compare cmp.xyz.y ref.xyz.y
        | "z" -> Float.compare cmp.xyz.z ref.xyz.z
        | _   -> raise(Invalid_argument(("expected 'x', 'y', or 'z' but got: ")^axs))

let cmp_by_coords ref cmp = 
    let same_x = Float.compare ref.xyz.x cmp.xyz.x == 0 in 
    let same_y = Float.compare ref.xyz.y cmp.xyz.y == 0 in
    let same_z = Float.compare ref.xyz.z cmp.xyz.z == 0 in
    same_x && same_y && same_z

let calc_distance a_start a_end = 
    sqrt((a_end.x -. a_start.x)**2. +. (a_end.y -. a_start.y)**2. +. (a_end.z -. a_start.z)**2.)