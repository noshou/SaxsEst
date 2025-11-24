open Kdt

(** Finds all points within radius [r] of the query point [atm].
    
    @param r The search radius
    @param atm The query point (atom/point to search around)
    @param f Accumulator for found points (should be initialized to empty list)
    @param s Stack of nodes to visit (should be initialized to root node of tree)
    
    @return List of points within radius [r] of [atm]
    {[Algorithm:]}
    {ol
        {li Pop current node from stack
            {ul 
                {li if [== kdt.Empty], skip to step 4} 
                {li if [||p - curr|| <= r], add node to found list}
            } 
        }
        {li Determine which child is "near" and which is "far" 
            {ul
                {li If [p.axis < curr.axis], then left child is "near", right child is "far"}
                {li If [p.axis >= curr.axis], then right child is "near", left child is "far"}
            }
        }
        {li Check if axis hyperplane intersects search region (sphere of radius r)
            {ul
                {li If [|p.axis - curr.axis| <= r]: plane intersects sphere; push near and far }
                {li If [|p.axis - curr.axis| > r]:  plane does not intersect sphere; push near}
            }
        }
        {li If stack is empty, return found list; otherwise goto step 1}
    } *)
let rec kdt_radial_search r atm ?(f=[]) ?(s=[] ) () = match s with 
    | []    -> f 
    | a::_s -> match a with 
        | Empty -> kdt_radial_search r atm ~f:f ~s:_s ()  
        | Node n ->

            (* add to found if within radius *)
            let _found = 
                let distance = Atom.calc_distance atm n.atm in 
                if (Float.compare distance r) <= 0 then 
                    n.atm :: f
                else 
                    f
            in 

            (* get splitting plane *)
            let axis = 
                match n.axs with
                    | X -> "x"
                    | Y -> "y"
                    | Z -> "z"
            in 

            (* determine if left or right child is "near" *)
            let near_far = 
                if (Atom.cmp_by_axis n.atm atm axis) < 0 then 
                    (n.lch, n.rch)
                else
                    (n.rch, n.lch)
            in
            let (near, far) = near_far in

            (* determine if plane intersects *)
            let intersects = 
                let dist = match n.axs with 
                    | X -> Float.compare (abs_float((Atom.xyz atm).x -. (Atom.xyz n.atm).x)) r
                    | Y -> Float.compare (abs_float((Atom.xyz atm).y -. (Atom.xyz n.atm).y)) r 
                    | Z -> Float.compare (abs_float((Atom.xyz atm).z -. (Atom.xyz n.atm).z)) r 
                in 
                dist <= 0
            in 

            (* push to stack *)
            let _stack = 
                if intersects then near :: far :: _s 
                else near :: _s 
            in
            
            (* recurse :) *)
            kdt_radial_search r atm ~f:_found ~s:_stack ()
            