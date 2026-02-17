(* writes data to csv file *)
let ocamlOut csv_lst path = Csv.save path csv_lst

(* called from bridge.c *)
let () = Callback.register "ocamlOut" ocamlOut