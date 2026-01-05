(* writes data to csv file *)
let oc_out csv_lst path = Csv.save path csv_lst

(* called from bridge.c *)
let () = Callback.register "oc_out" oc_out