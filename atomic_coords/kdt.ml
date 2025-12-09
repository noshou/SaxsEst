exception Invalid_kdt_state of string

(* defines the splitting axis of the kd tree (X -> Y -> Z -> X -> etc ...)*)
type hyperplane_axis = 
    | X
    | Y
    | Z 

(* recursively defined kd tree (either empty, or a node w/ subtree)*)
type kdt = 
    | Empty
    | Node of node

(** represents a kd node: 
    -> node.rch = right subtree;
    -> node.lch = left  subtree; 
    -> node.atm = atom stored at node;
    -> node.axs = hyperplane axis of node (X, Y, Z) *)
and node = {
    rch: kdt;
    lch: kdt; 
    atm: Atom.atom; 
    axs: hyperplane_axis 
}

(** returns true if t is empty, false otherwise *)
let is_empty (t : kdt) : bool = 
    match t with 
        | Empty  -> true 
        | Node _ -> false 

(** increments hyperplane axis: X -> Y -> Z -> X etc... *)
let incr_axis axis = 
    match axis with 
        | X -> Y 
        | Y -> Z 
        | Z -> X 

(* builds a static kdt from a list of atoms  *)
let rec kdt_creator atms ?(axis=X): kdt = 
	if List.is_empty atms then 
		Empty
	else 
		
    (* get pivot from median of medians algorithm *)
		let pivot = match Moms.moms atms axis with 
			| Some atom -> atom
			| None -> raise (Invalid_kdt_state "Cannot compute pivot!")
		in 
    
    (* divide into two groups: l.t. pivot, g.eq. pivot. Since we assume
    all atoms occupy a unique space, if two elements have save value along same axis, 
    distinguish if we are at pivot or if we are instead at a new point. 
    Imperative method used for efficiency (but could be wrong abt that) *)
		let left_tree  = ref [] in 
		let right_tree = ref [] in
		List.iter ( fun atom -> 
			let axs = match axis with 
				| X -> "x"
				| Y -> "y"
				| Z -> "z"
			in 
			
			if (Atom.cmp_by_axis atom pivot axs) < 0 then 
				left_tree := atom :: !left_tree 
			else if (Atom.cmp_by_axis atom pivot axs) > 0 then 
				right_tree := atom :: !right_tree
			else
				if not (Atom.cmp_by_coords atom pivot) then 
					right_tree := atom :: !right_tree
		) atms;

		(* construct tree *)
		Node {
			rch = kdt_creator !right_tree ~axis:(incr_axis axis);
			lch = kdt_creator !left_tree ~axis:(incr_axis axis);
			atm = pivot;
			axs = axis 
		}
(* 
(** returns the coordinate by the hyperplane axis *)
let ax_by_hype (n : node) h: float  = 
    let xyz = Atom.xyz n in 
    match h with 
        | X -> xyz.x
        | Y -> xyz.y
        | Z -> xyz.z
(* 
(** compares ref vs cmp by ref's hyperplane axis *)
let cmp_node (ref : node) (cmp : node) : int = 

    (* unpack reference hyperplane axis *)
    let axs = ref.axs in 
    
    (* unpack coordinate to compare *)
    let r_c = ax_by_hype ref axs in 
    let c_c = ax_by_hype cmp axs in 

    (* return -1, 0, 1 *)
    Float.compare r_c c_c *) *)
