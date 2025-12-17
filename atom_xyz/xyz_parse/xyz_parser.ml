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
  "^\\([A-Za-z][A-Za-z0-9]*[+-]?\\)[ \t]+" ^  
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
  
  try 
    
    (* Read first line and extract ONLY digits *)
    let first_line = input_line f in
    let size = 
      let digits_only = 
        String.to_seq first_line
        |> Seq.filter (fun c -> c >= '0' && c <= '9')
        |> String.of_seq
      in
      if String.length digits_only = 0 then
        raise (Malformed_xyzFile ("First line must contain atom count"))
      else
        int_of_string digits_only
    in    
    
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
    List.rev !atoms  
  with 
  | End_of_file -> close_in f; List.rev !atoms 
  | e -> close_in_noerr f; raise e


(** writes atomic coordinate data to a Fortran module *)
let xyz_toFortran xyz_fp = 
  
  (* get basename *)
  let base_name = "xyz_" ^ (Filename.chop_extension (Filename.basename xyz_fp)) in
  
  (* load atoms from xyz file *)
  let atoms = load_xyz xyz_fp in
  
  (* extract data into separate lists *)
  let elements = List.map (fun atom -> atom.element) atoms in
  let x_coords = List.map (fun atom -> atom.x) atoms in
  let y_coords = List.map (fun atom -> atom.y) atoms in
  let z_coords = List.map (fun atom -> atom.z) atoms in
  
  (* open output file *)
  let oc = open_out (base_name ^ ".f90") in
  
  (* write module header *)
  Printf.fprintf oc "!! Atomic coordinate data from XYZ file\n";
  Printf.fprintf oc "!! This module provides raw coordinate data for use with atom_mod\n";
  Printf.fprintf oc "module %s_mod\n" base_name;
  Printf.fprintf oc "    use iso_fortran_env, only: real64\n";
  Printf.fprintf oc "    implicit none\n\n";
  Printf.fprintf oc "    private\n\n";
  
  (* public interface *)
  Printf.fprintf oc "    ! Public interface\n";
  Printf.fprintf oc "    public  :: n_atoms\n";
  Printf.fprintf oc "    private :: elements, x_coords, y_coords, z_coords\n";
  Printf.fprintf oc "    public  :: get_atoms\n\n";
  
  (* module data *)
  Printf.fprintf oc "    ! Module data\n";
  Printf.fprintf oc "    integer, parameter :: n_atoms = %d\n\n" (List.length atoms);
  
  (* write element names *)
  Printf.fprintf oc "    ! Element symbols\n";
  Printf.fprintf oc "    character(len=4), parameter :: elements(%d) = [ &\n" (List.length elements);
  List.iteri (fun idx elem ->
    if idx == 0 then
      Printf.fprintf oc "            '%-4s'" elem
    else
      Printf.fprintf oc ", &\n            '%-4s'" elem
  ) elements;
  Printf.fprintf oc " ]\n\n";
  
  (* write x coordinates *)
  Printf.fprintf oc "    ! X coordinates (Angstroms)\n";
  Printf.fprintf oc "    real(real64), parameter :: x_coords(%d) = [ &\n" (List.length x_coords);
  List.iteri (fun idx x ->
    if idx == 0 then
      Printf.fprintf oc "            %f_real64" x
    else
      Printf.fprintf oc ", &\n            %f_real64" x
  ) x_coords;
  Printf.fprintf oc " ]\n\n";
  
  (* write y coordinates *)
  Printf.fprintf oc "    ! Y coordinates (Angstroms)\n";
  Printf.fprintf oc "    real(real64), parameter :: y_coords(%d) = [ &\n" (List.length y_coords);
  List.iteri (fun idx y ->
    if idx == 0 then
      Printf.fprintf oc "            %f_real64" y
    else
      Printf.fprintf oc ", &\n            %f_real64" y
  ) y_coords;
  Printf.fprintf oc " ]\n\n";
  
  (* write z coordinates *)
  Printf.fprintf oc "    ! Z coordinates (Angstroms)\n";
  Printf.fprintf oc "    real(real64), parameter :: z_coords(%d) = [ &\n" (List.length z_coords);
  List.iteri (fun idx z ->
    if idx == 0 then
      Printf.fprintf oc "            %f_real64" z
    else
      Printf.fprintf oc ", &\n            %f_real64" z
  ) z_coords;
  Printf.fprintf oc " ]\n\n";
  
  (* write methods *)
  Printf.fprintf oc "contains\n\n";
  
  (* get_atoms function - returns array of atom objects *)
  Printf.fprintf oc "    ! Returns all atoms as an array of atom objects\n";
  Printf.fprintf oc "    ! Requires: use atom_mod, only: atom, coord, create_atom\n";
  Printf.fprintf oc "    function get_atoms() result(atoms)\n";
  Printf.fprintf oc "        use atom_mod, only: atom, coord, create_atom\n";
  Printf.fprintf oc "        type(atom) :: atoms(n_atoms)\n";
  Printf.fprintf oc "        type(coord) :: position\n";
  Printf.fprintf oc "        integer :: i\n\n";
  Printf.fprintf oc "        do i = 1, n_atoms\n";
  Printf.fprintf oc "            position%%x = x_coords(i)\n";
  Printf.fprintf oc "            position%%y = y_coords(i)\n";
  Printf.fprintf oc "            position%%z = z_coords(i)\n";
  Printf.fprintf oc "            atoms(i) = create_atom(position, elements(i))\n";
  Printf.fprintf oc "        end do\n";
  Printf.fprintf oc "    end function get_atoms\n\n";
  
  (* close module *)
  Printf.fprintf oc "end module %s_mod\n" base_name;
  close_out oc

(* Main entry point; allows multiple inputs to be sent and parsed at the same time *)
let () =
  if Array.length Sys.argv < 2 then begin
    Printf.eprintf "Usage: %s <input.xyz> [<input2.xyz> ...]\n" Sys.argv.(0);
    exit 1
  end;

  let arg_count = Array.length Sys.argv in
  let i = ref 1 in (* since Sys.argv(0) is name of file, we start at pos 1 *)

  while !i <> arg_count do
      xyz_toFortran Sys.argv.(!i);
      i := !i + 1 
  done