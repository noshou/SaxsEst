(* module interface for atomic coordinate data structures *)
module type CoordinatesDataStruct = sig 

    (** atomic cooridnate data structure (defines a type) *)
    type cds

    (** an empty cds*)
    val initial : cds

    (** takes an atom and a cds, and returns a new 
    cds of same type with that new entry added *)
    val assimilate Atom.atom -> cds -> cds
end