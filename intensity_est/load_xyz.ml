exception Malformed_xyzEntry of string

(** loads an xyz file to an owl dataframe *)
let load_xyz (fp : string) : Owl_dataframe.t =
    
    (* each line in xyz file (ignoring 1st and 2nd lines)
    is tabulated as |element | x-coord | y-coord| z-coord| *)
    let line_regex =
        Str.regexp "^\\([A-Za-z]+\\)[ \t]+\\(-?[0-9]+\\.[0-9]+\\)[ \t]+\\(-?[0-9]+\\.[0-9]+\\)[ \t]+\\(-?[0-9]+\\.[0-9]+\\)$"
    in

    (* read file *)
    let f = open_in fp in 

    (* create empty dataframe with 4 columns*)
    let df = Owl_dataframe.make [|"element";"x";"y";"z"|] in 

    (* Skip first 2 lines of xyz file*)
    let _ = input_line f in 
    let _ = input_line f in 
    
    try 
        while true do 
            let row = input_line f in 
            if (Str.string_match line_regex row 0) then                 
                
                (* make into array of dataframe elements *)
                let atom_nm = Owl_dataframe.pack_string (Str.matched_group 1 row) in 
                let x_coord = Owl_dataframe.pack_float (float_of_string (Str.matched_group 2 row)) in
                let y_coord = Owl_dataframe.pack_float (float_of_string (Str.matched_group 3 row)) in
                let z_coord = Owl_dataframe.pack_float (float_of_string (Str.matched_group 4 row)) in
                let row = [|atom_nm;x_coord;y_coord;z_coord|] in

                (* append to df *)
                Owl_dataframe.append_row df row

            else
                raise (Malformed_xyzEntry row)
        done;
        df 
    with 
        | End_of_file -> close_in f; df 
        | e -> close_in_noerr f; raise e