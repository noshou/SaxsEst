exception Malformed_xyzEntry of string
exception Malformed_xyzFile of string


(** loads an xyz file (tsv or csv) from a file path.
Note: the list is returned backwards w.r.t how the file was read *)
val load_xyz : string -> atom list