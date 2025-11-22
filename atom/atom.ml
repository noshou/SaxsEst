(* re-export for public API *)
exception Malformed_xyzEntry of string
exception Malformed_xyzFile of string
type coord = Atom_.coord = { x : float; y : float; z : float }
type atom = Atom_.atom
let create = Atom_.create_atom  
let xyz = Atom_.xyz 
let name = Atom_.name
let form_factor = Atom_.form_fact 
let to_string = Atom_.to_string
let load_xyz = Load_xyz.load_xyz