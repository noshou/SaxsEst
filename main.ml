let () = 
    let res = Intensity_est.classic "data/perlecan.xyz" in 
    let (df, tt) = res in 
    Owl_dataframe.to_csv ~sep:',' df "res.csv";
    let fname = "time-to-completion.txt" in 
    let content = Printf.sprintf "%f" tt ^ "\ntype: Classic Algo" in 
    let oc = open_out fname in 
    output_string oc content; 
    close_out oc