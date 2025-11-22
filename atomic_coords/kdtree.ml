(* recursively defined kd tree (either empty, or a node w/ subtree)*)
type kdt = 
    | Empty
    | Node of node

(* represents a kd node: 
    -> node.rc = right subtree;
    -> node.lc = left  subtree; 
    -> node.dt = data of node;
    -> node.dm = dimension of node *)
and node = {
    rc: kdt;
    lc: kdt; 
    dt: Atom.atom;
    dm: int 
}

(** creates a new kdtree from a list of atoms *)
let rec kdt_creator (atoms : Atom.atom list) : kdt = 
    
    (* if list is empty, return empty tree *)
    if (List.is_empty atoms) then Empty;

    (* build root node *)
    let r = 