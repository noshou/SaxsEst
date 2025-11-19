exception Malformed_xyzEntry of string
exception Malformed_xyzFile of string

(** represents a 3-D coordinate *)
type coord = {x: float; y: float; z: float}

(** abstract type of an atom *)
type atom 


(** creates a new atom  *)
val create : coord -> string -> atom 

(** gets the coordinate of an atom *)
val xyz : atom -> coord

(** gets the name of an atom *)
val name : atom -> string

(** gets the form factor of an atom at a given q *)
val form_factor : atom -> float -> Complex.t

(** returns a string representation of the atom.
Optional q value (default set to 0)*)
val to_string : atom -> ?q:float -> unit -> string 

(** loads an xyz file (tsv or csv) from a file path.
Note: the list is returned backwards w.r.t how the file was read *)
val load_xyz : string -> atom list