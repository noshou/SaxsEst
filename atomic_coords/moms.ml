open Kdtree

(* takes the first n elements from a list and
returns it as a new list.
For example: 
take ~n:3 [10;20;30;40;50] () 
├─ 10 :: take ~n:2 [20;30;40;50]
│        ├─ 20 :: take ~n:1 [30;40;50]
│        │        ├─ 30 :: take ~n:0 [40;50]
│        │        │        │
│        │        │        └─ []
│        │        └─ 30 :: [] = [30]
│        └─ 20 :: [30] = [20; 30]
└─ 10 :: [20; 30] = [10; 20; 30] *)
let rec take ?(n=5) atms () : Atom.atom list = match (n, atms) with 
    | (0,_)  | (_, []) ->  [] 
    | (i, atm::atms)   ->  atm :: (take ~n:(n-1) atms ()) 

(* drops the first n elements from a list and returns 
the tail of the list.
For example: 
drop ~n:3 [10;20;30;40;50] () 
├─ _ :: drop ~n:2 [20;30;40;50]
│        ├─ _ :: drop ~n:1 [30;40;50]
│        │        ├─  _ :: drop ~n:0 [40;50]
│        │        │        │
│        │        │        └─ [40;50] *)
let rec drop ?(n=5) atms () : Atom.atom list = match (n, atms) with 
    | (0, _)        -> atms 
    | (_, [])       -> []
    | (n, _::atms)  -> drop ~n:(n-1) atms () 

(* groups list of atoms into list of lists of max size n *)
let rec group ?(n=5) atms () : Atom.atom list list =  match atms with 
    | []	-> []
    | _ 	->
        let grp = take ~n=n atms () in 
        let rem = drop ~n=n atms () in 
        grp :: (group ~n=n rem())

(** median of medians algorithm returns the 
approximate median from an unordered list *)		
let rec moms atms hype : Atom.atom option =

		(* edge case: atms is empty -> return None *)
		if List.is_empty atms then None
    else 
        (* length of list *)
        let n = List.length atms in 

        (* base case: sort list and return x *)
        if n <= 5 then 

            (* List.sort takes a function which maps two elements of the list and 
            to an int. Since Atom.cmp_by_axis takes an axis argument, we must map 
            the hyperplane axis to an anonymous function sorting by the correct option *)
            let sort_by = match hype with 
                | X -> (fun a1 a2 -> Atom.cmp_by_axis a1 a2 "x")   
                | Y -> (fun a1 a2 -> Atom.cmp_by_axis a1 a2 "y")
                | Z -> (fun a1 a2 -> Atom.cmp_by_axis a1 a2 "z")
            in 
            Some (List.nth (List.sort sort_by atms) (n / 2))

        (* recursive case: n > 5, must keep splitting and finding *)
        else 

            (* build nested list of groups of at most n *)
            let groups = group atms () in 

            (* get median of each group, return new list of said medians *)
            let medians = ref [] in 
            for i = 0 to (List.length groups) - 1 do  
                let median_i = moms (List.nth groups i) hype in 
                    match median_i with 
                        | None      -> () 
                        | Some m    -> medians := m :: !medians 
            done;
            moms !medians hype