(* generates text files which are snippets of fortran code. Atom modules are dynamically
generated yet they need to be known at compile time. So we can "fake" dynamic loading
by building static file outputs (switch cases for each type of atom, and a file which
is a list of "use <atom mod>"), then use fortran's include directive which literally copies
in the contents of files intowhatever position the include directive is at. Overcomplicated?
Yes, totally. But itis very modular! Anyways, OCaml is used here because it's great at this
kinda parsing.*)

let lines xyzModList = 
    In_channel.with_open_text xyzModList In_channel.input_lines

(* Remove "xyz_" prefix and "_mod.mod" suffix *)
let extractName line =
    let s = String.length "xyz_" in
    let e = String.length "_mod.mod" in
    let len = String.length line in
    String.sub line s (len - s - e)

(* prints: use <molecule_mod> *)
let atomInclude xyzModList = 
    let moduleNames = List.map extractName (lines xyzModList) in
    let useStatements = List.map (fun name -> "    use xyz_" ^ name ^ "_mod") moduleNames in
    String.concat "\n" useStatements

(* recursively builds case statements for atom mod *)
let rec printCases case xyzList = match xyzList with
    | [] -> case
    | xyz :: rest -> 
        let newCase = 
            Printf.sprintf "\n        case(\"%s\")\n                atoms = get_atoms_xyz_%s()" xyz xyz
        in
        printCases (case ^ newCase) rest

(* prints switch cases *)
let atom_cases xyzModList =
    let moduleNames = List.map extractName (lines xyzModList) in
    let cases = printCases "" moduleNames in
    let switch_cases = 
        "    select case(trim(name))" 
        ^ cases 
        ^ "\n        case default\n                print*,"
        ^ " \"Unknown module: \", trim(name)"
        ^ "\n    end select" 
    in
    switch_cases

(* outputs "use" to mod_uses.inc, must be included in SaxsEst.f90 w/ other use statements *)
let mod_uses xyzModList =
    let oc = open_out "mod_uses.inc" in
    Printf.fprintf oc "%s\n" (atomInclude xyzModList);
    close_out oc

(* outputs switch cases to mod_switches.inc, must be included in SaxsEst.f90's main function *)
let mod_switches xyzModList = 
    let oc = open_out "mod_switches.inc" in
    Printf.fprintf oc "%s\n" (atom_cases xyzModList);
    close_out oc

(* Main entry point *)
let () = 
    if Array.length Sys.argv <> 2 then begin
        Printf.eprintf "Usage: %s <xyzModList.txt>\n" Sys.argv.(0);
        exit 1
    end;
    mod_uses (Sys.argv.(1)); mod_switches(Sys.argv.(1))
