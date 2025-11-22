open Coordinates_data_struct

(** assimilates atomic coordinates as a list *)
module ListAssimilator : CoordinatesDataStruct = 
    type cds = Atom.atom list 
    
    let initial = []

    (** prepends on atom to a list. We do not 
    append since the former is O(n) but the 
    later is worst case O(n^2)*)
    let assimilate (atom : Atom.atom) (atoms : Atom.atom list) = atom :: atoms

    (** reverses a list of atoms   *)
    let unwind (atoms : Atom.atom) = List.rev atoms
end

(** assimilates atomic coordinates as a k-d tree *)
module KDTreeAssimilator : CoordinatesDataStruct = 
    type cds = Atom.atom KdTree.kdtree 
    let initial = Kdtree.empty 

    (** adds an atom to the kd tree *)
    let assimilate (atom : Atom.atom) (atoms: Atom.atom Kdtree.kdtree) = Kdtree.add atoms atom 
end