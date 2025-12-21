(* writes data to csv file *)
let oc_out csv_lst file_name = Csv.save file_name csv_lst

(* called from bridge.c *)
let () = Callback.register "oc_out" oc_out