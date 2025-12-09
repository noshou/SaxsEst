(* module parses an xyz file and returns appropriate fortran module *)

exception Malformed_xyzEntry of string
exception Malformed_xyzFile of string

(* Simple record type for parsed atom data *)
type atom_data = {
  element: string;
  x: float;
  y: float;
  z: float;
}

(* matches tab/space-delimited files (TSV) *)
let re_tsv = Str.regexp (
  "^\\([A-Za-z]+\\)[ \t]+" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]+" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]+" ^
  "\\(-?[0-9]+\\.[0-9]+\\)$"
)

(* matches comma-delimited files (CSV) *)
let re_csv = Str.regexp(
  "^\\([A-Za-z]+\\)[ \t]*,[ \t]*" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]*,[ \t]*" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]*,[ \t]*" ^
  "\\(-?[0-9]+\\.[0-9]+\\)$"
)

(** loads an xyz file (tsv or csv) from a file path.
    Returns a list of atom_data records *)
let load_xyz fp =
  (* initialize mutable empty list of atoms *)
  let atoms = ref [] in 
  (* read first line (#atoms) and skip second line of xyz file*)
  let f = open_in fp in 
  
  (* parse file; any errors cause immediate abort; end of file handled in special case *)
  try 
    let size = int_of_string (String.trim(input_line f)) in 
    let _ = input_line f in 
    
    (* first data row parsing *)
    let row = String.trim(input_line f) in 
    
    (* detect delim type *)
    let _delimType =
      if Str.string_match re_tsv row 0 then
        re_tsv
      else if Str.string_match re_csv row 0 then
        re_csv
      else
        raise (Malformed_xyzFile "xyz file must be csv or tsv!")
    in 
    
    (* error message *)
    let errmsg m =
      if _delimType == re_tsv then
        "Expected tsv; got: " ^ m
      else if _delimType == re_csv then
        "Expected csv; got: " ^ m
      else
        "Unknown delimiter; got: " ^ m
    in
    if (Str.string_match _delimType row 0) then 
      begin
        
        (* parse data from first row *)     
        let element = Str.matched_group 1 row in 
        let x = float_of_string (Str.matched_group 2 row) in
        let y = float_of_string (Str.matched_group 3 row) in
        let z = float_of_string (Str.matched_group 4 row) in
        atoms := {element; x; y; z} :: !atoms;
      end 
    else 
      raise (Malformed_xyzEntry (errmsg row))
    ;
    
    (* parse rest of file *)
    let itr = ref 1 in (* have already seen first item *)
    while !itr < size do 
      let row = String.trim (input_line f) in 
      if (Str.string_match _delimType row 0) then 
        begin
          let element = Str.matched_group 1 row in 
          let x = float_of_string (Str.matched_group 2 row) in
          let y = float_of_string (Str.matched_group 3 row) in
          let z = float_of_string (Str.matched_group 4 row) in
          atoms := {element; x; y; z} :: !atoms;
        end 
      else 
        raise (Malformed_xyzEntry (errmsg row))
      ;
      itr := !itr + 1
    done;
    close_in f;
    !atoms  
  with 
  | End_of_file -> close_in f; !atoms 
  | e -> close_in_noerr f; raise e


(** writes atomic coordinate data to a Fortran module *)
let xyz_toFortran xyz_fp out_fp = 
  
  (* load atoms from xyz file *)
  let atoms = load_xyz xyz_fp in
  
  (* extract data into separate lists *)
  let elements = List.map (fun atom -> atom.element) atoms in
  let x_coords = List.map (fun atom -> atom.x) atoms in
  let y_coords = List.map (fun atom -> atom.y) atoms in
  let z_coords = List.map (fun atom -> atom.z) atoms in
  
  (* open output file *)
  let oc = open_out out_fp in
  
  (* write module header *)
  Printf.fprintf oc "!! Atomic coordinate data from XYZ file\n";
  Printf.fprintf oc "!! This module provides raw coordinate data for use with atom_mod\n";
  Printf.fprintf oc "module load_xyz_mod\n";
  Printf.fprintf oc "\tuse iso_fortran_env, only: real64\n";
  Printf.fprintf oc "\timplicit none\n\n";
  Printf.fprintf oc "\tprivate\n\n";
  
  (* public interface *)
  Printf.fprintf oc "\t! Public interface\n";
  Printf.fprintf oc "\tpublic :: n_atoms\n";
  Printf.fprintf oc "\tpublic :: elements, x_coords, y_coords, z_coords\n";
  Printf.fprintf oc "\tpublic :: get_atom_data\n";
  Printf.fprintf oc "\tpublic :: get_all_atoms\n\n";
  
  (* module data *)
  Printf.fprintf oc "\t! Module data\n";
  Printf.fprintf oc "\tinteger, parameter :: n_atoms = %d\n\n" (List.length atoms);
  
  (* write element names *)
  Printf.fprintf oc "\t! Element symbols\n";
  Printf.fprintf oc "\tcharacter(len=10), parameter :: elements(%d) = [ &\n" (List.length elements);
  List.iteri (fun idx elem ->
    if idx == 0 then
      Printf.fprintf oc "\t\t\t'%s'" elem
    else
      Printf.fprintf oc ", &\n\t\t\t'%s'" elem
  ) elements;
  Printf.fprintf oc " ]\n\n";
  
  (* write x coordinates *)
  Printf.fprintf oc "\t! X coordinates (Angstroms)\n";
  Printf.fprintf oc "\treal(real64), parameter :: x_coords(%d) = [ &\n" (List.length x_coords);
  List.iteri (fun idx x ->
    if idx == 0 then
      Printf.fprintf oc "\t\t\t%f_real64" x
    else
      Printf.fprintf oc ", &\n\t\t\t%f_real64" x
  ) x_coords;
  Printf.fprintf oc " ]\n\n";
  
  (* write y coordinates *)
  Printf.fprintf oc "\t! Y coordinates (Angstroms)\n";
  Printf.fprintf oc "\treal(real64), parameter :: y_coords(%d) = [ &\n" (List.length y_coords);
  List.iteri (fun idx y ->
    if idx == 0 then
      Printf.fprintf oc "\t\t\t%f_real64" y
    else
      Printf.fprintf oc ", &\n\t\t\t%f_real64" y
  ) y_coords;
  Printf.fprintf oc " ]\n\n";
  
  (* write z coordinates *)
  Printf.fprintf oc "\t! Z coordinates (Angstroms)\n";
  Printf.fprintf oc "\treal(real64), parameter :: z_coords(%d) = [ &\n" (List.length z_coords);
  List.iteri (fun idx z ->
    if idx == 0 then
      Printf.fprintf oc "\t\t\t%f_real64" z
    else
      Printf.fprintf oc ", &\n\t\t\t%f_real64" z
  ) z_coords;
  Printf.fprintf oc " ]\n\n";
  
  (* write methods *)
  Printf.fprintf oc "contains\n\n";
  
  (* get_atom_data subroutine - returns raw data for one atom *)
  Printf.fprintf oc "\t! Returns element and coordinates for a given atom index\n";
  Printf.fprintf oc "\tsubroutine get_atom_data(idx, element, x, y, z)\n";
  Printf.fprintf oc "\t\t\tinteger, intent(in) :: idx\n";
  Printf.fprintf oc "\t\t\tcharacter(len=10), intent(out) :: element\n";
  Printf.fprintf oc "\t\t\treal(real64), intent(out) :: x, y, z\n\n";
  Printf.fprintf oc "\t\t\tif (idx < 1 .or. idx > n_atoms) then\n";
  Printf.fprintf oc "\t\t\t\t\twrite(*, '(A, I0, A, I0)') 'ERROR in get_atom_data: Index ', &\n";
  Printf.fprintf oc "\t\t\t\t\t\t\tidx, ' out of bounds. Valid range: 1 to ', n_atoms\n";
  Printf.fprintf oc "\t\t\t\t\terror stop\n";
  Printf.fprintf oc "\t\t\t end if\n\n";
  Printf.fprintf oc "\t\t\telement = elements(idx)\n";
  Printf.fprintf oc "\t\t\tx = x_coords(idx)\n";
  Printf.fprintf oc "\t\t\ty = y_coords(idx)\n";
  Printf.fprintf oc "\t\t\tz = z_coords(idx)\n";
  Printf.fprintf oc "\tend subroutine get_atom_data\n\n";
  
  (* get_all_atoms function - returns array of atom objects *)
  Printf.fprintf oc "\t! Returns all atoms as an array of atom objects\n";
  Printf.fprintf oc "\t! Requires: use atom_mod, only: atom, coord, create_atom\n";
  Printf.fprintf oc "\tfunction get_all_atoms() result(atoms)\n";
  Printf.fprintf oc "\t\t\tuse atom_mod, only: atom, coord, create_atom\n";
  Printf.fprintf oc "\t\t\ttype(atom) :: atoms(n_atoms)\n";
  Printf.fprintf oc "\t\t\ttype(coord) :: position\n";
  Printf.fprintf oc "\t\t\tinteger :: i\n\n";
  Printf.fprintf oc "\t\t\tdo i = 1, n_atoms\n";
  Printf.fprintf oc "\t\t\t\t\tposition%%x = x_coords(i)\n";
  Printf.fprintf oc "\t\t\t\t\tposition%%y = y_coords(i)\n";
  Printf.fprintf oc "\t\t\t\t\tposition%%z = z_coords(i)\n";
  Printf.fprintf oc "\t\t\t\t\tatoms(i) = create_atom(position, elements(i))\n";
  Printf.fprintf oc "\t\t\tend do\n";
  Printf.fprintf oc "\tend function get_all_atoms\n\n";
  
  (* close module *)
  Printf.fprintf oc "end module load_xyz_mod\n";
  close_out oc;
  
  print_endline ("Generated " ^ out_fp)

(* Main entry point *)
let () =
  if Array.length Sys.argv != 3 then begin
    Printf.eprintf "Usage: %s <input.xyz> <output.f90>\n" Sys.argv.(0);
    exit 1
  end;
  
  let xyz_file = Sys.argv.(1) in
  let out_file = Sys.argv.(2) in
  
  xyz_toFortran xyz_file out_file