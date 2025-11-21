(** Intensity Estimator - Process XYZ molecular structure files
    Usage: dune exec ./main.exe -- [OPTIONS] <file>.xyz
    NOTE: Files are expected to be in the root of data/xyz/ .
    Options:
        dune exec ./main.exe -- test.xyz (default: no clock logging)
        dune exec ./main.exe -- --clk molecule.xyz (enable clock logging to <run>_timing.txt)
        dune exec ./main.exe -- --tol 1e-12 --run my_run --clk test.xyz *)
let  () = 
  let fp = ref "" in
  let tol = ref 1e-10 in
  let run = ref "classic" in
  let clk = ref false in
  let usage_msg = "Usage: dune exec /main.exe -- [options] <file>.xyz" in
  let speclist = [
    ("--tol", Arg.Set_float tol, "Set precision tolerance (default: 1e-10)");
    ("--run", Arg.Set_string run, "Set CSV file stem (default: classic)");
    ("--clk", Arg.Set clk, "Enable timing output to <run>_timing.txt");
  ] in
  Arg.parse speclist (fun s -> fp := s) usage_msg;
  if !fp = "" then begin
    Arg.usage speclist usage_msg;
    exit 1
  end;
  let _ =
    Intensity_est.classic ("data/xyz" ^ !fp) ~tol:!tol ~run:!run ~clk:!clk ()
  in 
  ()
