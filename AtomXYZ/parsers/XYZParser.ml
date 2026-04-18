(* xyz_to_fortran.ml — Parses .xyz molecular coordinate files and emits Fortran modules.
 *
 * Each input .xyz file (CSV or TSV) is converted to a standalone Fortran module
 * (xyz_<name>_mod.f90) containing:
 *   - Element symbols and x/y/z coordinate arrays as compile-time parameters
 *   - A get_atoms_xyz_<name>() function that returns an array of atom objects
 *
 * Usage: xyz_to_fortran <input.xyz> [<input2.xyz> ...]
 *)

exception Malformed_xyzEntry of string
exception Malformed_xyzFile of string

(** Parsed atom: element symbol and Cartesian coordinates in Angstroms. *)
type atom_data = {
  element: string;
  x: float;
  y: float;
  z: float;
}

(** Matches tab/space-delimited rows: Element  x  y  z *)
let reTSV = Str.regexp (
  "^\\([A-Za-z][A-Za-z0-9]*[+-]?\\)[ \t]+" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]+" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]+" ^
  "\\(-?[0-9]+\\.[0-9]+\\)$"
)

(** Matches comma-delimited rows: Element, x, y, z *)
let reCSV = Str.regexp(
  "^\\([A-Za-z]+\\)[ \t]*,[ \t]*" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]*,[ \t]*" ^
  "\\(-?[0-9]+\\.[0-9]+\\)[ \t]*,[ \t]*" ^
  "\\(-?[0-9]+\\.[0-9]+\\)$"
)

(** Load atoms from an .xyz file at [fp].

    Expects standard XYZ format:
      - Line 1: atom count (digits extracted, tolerates trailing whitespace/BOM)
      - Line 2: comment (skipped)
      - Lines 3+: element x y z (CSV or TSV, auto-detected from first data row)

    @raise Malformed_xyzFile if the header is invalid or delimiter is unrecognized.
    @raise Malformed_xyzEntry if a data row doesn't match the detected format. *)
let loadXYZ fp =

  let atoms = ref [] in
  let f = open_in fp in

  try

    (* Extract atom count from first line, filtering to digits only
       to tolerate BOM or trailing whitespace *)
    let firstLine = input_line f in
    let size =
      let digits_only =
        String.to_seq firstLine
        |> Seq.filter (fun c -> c >= '0' && c <= '9')
        |> String.of_seq
      in
      if String.length digits_only = 0 then
        raise (Malformed_xyzFile ("First line must contain atom count"))
      else
        int_of_string digits_only
    in

    (* Skip comment line *)
    let _ = input_line f in

    (* Auto-detect delimiter from first data row *)
    let row = String.trim(input_line f) in

    let _delimType =
      if Str.string_match reTSV row 0 then
        reTSV
      else if Str.string_match reCSV row 0 then
        reCSV
      else
        raise (Malformed_xyzFile "xyz file must be csv or tsv!")
    in

    let errmsg m =
      if _delimType == reTSV then
        "Expected tsv; got: " ^ m
      else if _delimType == reCSV then
        "Expected csv; got: " ^ m
      else
        "Unknown delimiter; got: " ^ m
    in

    (* Parse a single row into an atom_data and prepend to atoms *)
    let parse_row row =
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
    in

    (* First data row was already read for delimiter detection *)
    parse_row row;

    (* Parse remaining rows *)
    let itr = ref 1 in
    while !itr < size do
      let row = String.trim (input_line f) in
      parse_row row;
      itr := !itr + 1
    done;
    close_in f;
    List.rev !atoms
  with
  | End_of_file -> close_in f; List.rev !atoms
  | e -> close_in_noerr f; raise e


(** Emit a Fortran module file (xyz_<name>_mod.f90) from an .xyz file.

    The generated module contains element symbols and coordinates as parameter
    arrays, plus a get_atoms_xyz_<name>() function that constructs atom objects
    via the AtomXYZ interface. *)
let xyz_toFortran xyz_fp =

  let base_name = "xyz_" ^ (Filename.chop_extension (Filename.basename xyz_fp)) in
  let atoms = loadXYZ xyz_fp in

  let elements = List.map (fun atom -> atom.element) atoms in
  let x_coords = List.map (fun atom -> atom.x) atoms in
  let y_coords = List.map (fun atom -> atom.y) atoms in
  let z_coords = List.map (fun atom -> atom.z) atoms in

  let oc = open_out (base_name ^ ".f90") in

  (* --- Module header --- *)
  Printf.fprintf oc "!! Atomic coordinate data from XYZ file\n";
  Printf.fprintf oc "!! This module provides raw coordinate data for use with AtomXYZ\n";
  Printf.fprintf oc "module %s_mod\n" base_name;
  Printf.fprintf oc "    use iso_c_binding, only: c_double\n";
  Printf.fprintf oc "    implicit none\n\n";
  Printf.fprintf oc "    private\n\n";

  (* --- Visibility declarations --- *)
  Printf.fprintf oc "    ! Public interface\n";
  Printf.fprintf oc "    public  :: nAtoms\n";
  Printf.fprintf oc "    private :: elements, x_coords, y_coords, z_coords\n";
  Printf.fprintf oc "    public  :: get_atoms_%s" base_name;

  (* --- Parameter data (element symbols + coordinates) --- *)
  Printf.fprintf oc "    ! Module data\n";
  Printf.fprintf oc "    integer, parameter :: nAtoms = %d\n\n" (List.length atoms);

  (* Helper: write a Fortran parameter array with a formatting function per element *)
  let write_array label type_str len fmt_elem lst =
    Printf.fprintf oc "    ! %s\n" label;
    Printf.fprintf oc "    %s, parameter :: %s(%d) = [ &\n" type_str label len;
    List.iteri (fun idx v ->
      if idx == 0 then
        Printf.fprintf oc "            %s" (fmt_elem v)
      else
        Printf.fprintf oc ", &\n            %s" (fmt_elem v)
    ) lst;
    Printf.fprintf oc " ]\n\n"
  in

  write_array "elements" "character(len=4)" (List.length elements)
    (Printf.sprintf "'%-4s'") elements;
  write_array "x_coords" "real(c_double)" (List.length x_coords)
    (Printf.sprintf "%f_c_double") x_coords;
  write_array "y_coords" "real(c_double)" (List.length y_coords)
    (Printf.sprintf "%f_c_double") y_coords;
  write_array "z_coords" "real(c_double)" (List.length z_coords)
    (Printf.sprintf "%f_c_double") z_coords;

  (* --- get_atoms function --- *)
  Printf.fprintf oc "contains\n\n";
  Printf.fprintf oc "    ! Returns all atoms as an array of atom objects\n";
  Printf.fprintf oc "    ! Requires: use AtomXYZ, only: atom, coord, createAtom\n";
  Printf.fprintf oc "    function get_atoms_%s() result(atoms)\n" base_name;
  Printf.fprintf oc "        use AtomXYZ, only: atom, coord, createAtom\n";
  Printf.fprintf oc "        type(atom) :: atoms(nAtoms)\n";
  Printf.fprintf oc "        type(coord) :: position\n";
  Printf.fprintf oc "        integer :: i\n\n";
  Printf.fprintf oc "        do i = 1, nAtoms\n";
  Printf.fprintf oc "            position%%x = x_coords(i)\n";
  Printf.fprintf oc "            position%%y = y_coords(i)\n";
  Printf.fprintf oc "            position%%z = z_coords(i)\n";
  Printf.fprintf oc "            atoms(i) = createAtom(position, elements(i))\n";
  Printf.fprintf oc "        end do\n";
  Printf.fprintf oc "    end function get_atoms_%s\n\n" base_name;

  Printf.fprintf oc "end module %s_mod\n" base_name;
  close_out oc

(** Entry point. Processes each .xyz argument into a Fortran module. *)
let () =
  if Array.length Sys.argv < 2 then begin
    Printf.eprintf "Usage: %s <input.xyz> [<input2.xyz> ...]\n" Sys.argv.(0);
    exit 1
  end;

  let arg_count = Array.length Sys.argv in
  let i = ref 1 in
  while !i <> arg_count do
    xyz_toFortran Sys.argv.(!i);
    i := !i + 1
  done