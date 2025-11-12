(* represents an <x,y,z> coordinate *)
type point = {x: float; y: float; z: float}

(* wrapper for list *)
type points = 
    | Empty
    | Points of point list 

(* recursively defined kd tree (either empty, or a node w/ subtree) *)
type kdtree = 
    | Empty
    | Node of node

(* represents a kd node: 
    -> node.rc = right subtree;
    -> node.lc = left  subtree; 
    -> node.dt = data of node;
    -> node.dm = dimension of node *)
and node = {
    rc: kdtree;
    lc: kdtree; 
    dt: point;
    dm: int 
}

