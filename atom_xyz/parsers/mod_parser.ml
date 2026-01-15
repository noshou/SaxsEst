(* generates text files which are snippets of fortran code. Since
we dynamically generate the atom modules, they need to be known at compile time;
therefore we can use fortran's include directive which literally copies in 
the contents of files into whatever position the include directive is at. 
That way we can dynamically generate the needed snippets before compiling
our main module then "include" then later on :) *)

let lines xyz_mod_list = 
    In_channel.with_open_text xyz_mod_list In_channel.input_lines

(* Remove "xyz_" prefix and "_mod.mod" suffix *)
let extract_name line =
    let s = String.length "xyz_" in
    let e = String.length "_mod.mod" in
    let len = String.length line in
    String.sub line s (len - s - e)

(* prints: use <molecule_mod> *)
let atom_include xyz_mod_list = 
    let module_names = List.map extract_name (lines xyz_mod_list) in
    let use_statements = List.map (fun name -> "    use xyz_" ^ name ^ "_mod") module_names in
    String.concat "\n" use_statements

(* recursively builds case statements for atom mod *)
let rec print_cases case xyz_list = match xyz_list with
    | [] -> case
    | xyz :: rest -> 
        let new_case = 
            Printf.sprintf "\n        case(\"%s\")\n                atoms = get_atoms_xyz_%s()" xyz xyz
        in
        print_cases (case ^ new_case) rest

(* prints switch cases *)
let atom_cases xyz_mod_list =
    let module_names = List.map extract_name (lines xyz_mod_list) in
    let cases = print_cases "" module_names in
    let switch_cases = 
        "    select case(trim(name))" 
        ^ cases 
        ^ "\n        case default\n                print*,"
        ^ " \"Unknown module: \", trim(name)"
        ^ "\n    end select" 
    in
    switch_cases

(* outputs "use" to mod_uses.txt, must be included in main.f90 w/ other use statements *)
let mod_uses xyz_mod_list =
    let oc = open_out "mod_uses.inc" in
    Printf.fprintf oc "%s\n" (atom_include xyz_mod_list);
    close_out oc

(* outputs switch cases to mod_switches.inc, must be included in main.f90's main function *)
let mod_switches xyz_mod_list = 
    let oc = open_out "mod_switches.inc" in
    Printf.fprintf oc "%s\n" (atom_cases xyz_mod_list);
    close_out oc

(* Main entry point *)
let () = 
    if Array.length Sys.argv <> 2 then begin
        Printf.eprintf "Usage: %s <xyz_mod_list.txt>\n" Sys.argv.(0);
        exit 1
    end;
    mod_uses (Sys.argv.(1)); mod_switches(Sys.argv.(1))