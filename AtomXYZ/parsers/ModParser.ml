(* gen_includes.ml — Generates Fortran include files for dynamic atom module loading.
 *
 * Problem: Atom modules (xyz_<name>_mod) are generated at build time, but Fortran
 * requires them to be known at compile time, since fortran does not have dynamic module loading.
 *
 * Solution: This script reads a list of compiled .mod filenames (e.g. xyz_water_mod.mod)
 * and emits two Fortran include files:
 *   - mod_uses.inc      : `use xyz_<name>_mod` for each module
 *   - mod_switches.inc  : `select case` dispatch calling get_atoms_xyz_<name>()
 *
 * Both are pulled into SaxsEst.f90 via Fortran's `include` directive, which performs
 * textual substitution at the point of inclusion.
 *
 * Usage: gen_includes <xyzModList.txt>
 *   where xyzModList.txt contains one .mod filename per line.
 *)

(** Read all lines from the file at [path]. *)
let lines path =
  In_channel.with_open_text path In_channel.input_lines

(** Extract the molecule name from a .mod filename.
    e.g. "xyz_water_mod.mod" -> "water" *)
let extractName line =
  let s = String.length "xyz_" in
  let e = String.length "_mod.mod" in
  let len = String.length line in
  String.sub line s (len - s - e)

(** Generate `use xyz_<name>_mod` statements, one per module. *)
let atomInclude xyzModList =
  let moduleNames = List.map extractName (lines xyzModList) in
  let useStatements = List.map (fun name -> "    use xyz_" ^ name ^ "_mod") moduleNames in
  String.concat "\n" useStatements

(** Recursively build case branches for the select-case dispatch.
    Each branch maps a name string to its get_atoms_xyz_<name>() call. *)
let rec printCases case xyzList = match xyzList with
  | [] -> case
  | xyz :: rest ->
    let newCase =
      Printf.sprintf "\n        case(\"%s\")\n                atoms = get_atoms_xyz_%s()" xyz xyz
    in
    printCases (case ^ newCase) rest

(** Generate a complete `select case(trim(name))` block with a default error branch. *)
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

(** Write mod_uses.inc — include among `use` statements in SaxsEst.f90. *)
let mod_uses xyzModList =
  let oc = open_out "mod_uses.inc" in
  Printf.fprintf oc "%s\n" (atomInclude xyzModList);
  close_out oc

(** Write mod_switches.inc — include inside the main subroutine body in SaxsEst.f90. *)
let mod_switches xyzModList =
  let oc = open_out "mod_switches.inc" in
  Printf.fprintf oc "%s\n" (atom_cases xyzModList);
  close_out oc

(** Entry point. Expects a single argument: path to the module list file. *)
let () =
  if Array.length Sys.argv <> 2 then begin
    Printf.eprintf "Usage: %s <xyzModList.txt>\n" Sys.argv.(0);
    exit 1
  end;
  mod_uses Sys.argv.(1);
  mod_switches Sys.argv.(1)