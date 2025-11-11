open Load_xyz
open Form_fact

(** Calculates the scattering intensity [I(Q)] using the Debye scattering formula
    sweep over [Q] values from [0.0] to [0.5] Å⁻¹:
    
    {[I(Q) = ∑ᵢ∑ⱼ fᵢ fⱼ* sin(Q |rᵢ - rⱼ|) / (Q |rᵢ - rⱼ|)]}
    - [fᵢ] — form factor of atom [i]  
    - [fⱼ*] — complex conjugate of the form factor of atom [j]  
    - [rᵢ], [rⱼ] — positions of atoms [i] and [j], respectively  
    - [Q] — scattering vector (in inverse ångströms)
    @param xyz_file  Path to the input XYZ file containing atomic coordinates.  
    @return A tuple consisting of:
        - an Owl data frame containing [Q] vs [I(Q)]
        - the elapsed execution (ns)*)
let classic (fp: string) : Owl_dataframe.t * Int64.t = 
    
    (* load xyz data *)
    let df_coords = load_xyz fp |> Owl_dataframe.to_rows in 
    
    (* create empty dataframe for I(Q) values *)
    let df_scatts = Owl_dataframe.make [|"Q"; "I_Q" |] in 
    
    (* Q (Å⁻¹) iterate from 0.02 -> 0.5 in increments of 0.02 *)
    let qa = ref 0.02 in 
    
    (* ref for total time spent on calculations *)
    let tt = ref (Int64.of_float 0.) in 

    while !qa <= 0.5 do 
        
        (* current I(Q) value *)
        let qi = ref 0. in 
        
        (* start timer *)
        let start_time = Mtime_clock.now () in 

        (* calculate pairwise summation *)
        Array.iter ( fun i -> 
            
            (* atom i *)
            let i_e = i.(0) |> Owl_dataframe.unpack_string |> String.lowercase_ascii in
            let i_x = i.(1) |> Owl_dataframe.unpack_float in
            let i_y = i.(2) |> Owl_dataframe.unpack_float in
            let i_z = i.(3) |> Owl_dataframe.unpack_float in
            let i_f = form_fact !qa i_e in 
            let i_r = [|i_x;i_y;i_z|] in 
            
            Array.iter( fun j -> 
            
                (* atom j *)
                let j_e = j.(0) |> Owl_dataframe.unpack_string |> String.lowercase_ascii in
                let j_x = j.(1) |> Owl_dataframe.unpack_float in
                let j_y = j.(2) |> Owl_dataframe.unpack_float in 
                let j_z = j.(3) |> Owl_dataframe.unpack_float in
                let j_f = Complex.conj (form_fact !qa j_e) in  
                let j_r = [|j_x;j_y;j_z|] in
                    
                (* calculate |rᵢ - rⱼ| *)
                let dist = sqrt (
                    (i_r.(0) -. j_r.(0))**2.
                    +. (i_r.(1)-.j_r.(1))**2. 
                    +. (i_r.(2)-.j_r.(2)) **2.)
                in 
                
                (* if |r_i - r_j| == 0, means we must skip current atom since
                since we only care about inter atomic scattering  *)
                let contribution = 
                    if dist == 0. then 
                        0. 
                    else 
                        (* calculate Q * |r_i - r_j| *)
                        let q_dist = !qa *. dist in 
                        
                        (* calculate sin(Q*|r_i-r_j|) / Q*|r_i-r_j*)
                        let sin_q_dist = (sin q_dist) /. q_dist in
                        
                        (* calculate i_f * (conjugate(j_f)) 
                        turns out because of weird symmetry we can 
                        ignore the complex part (since the summation over
                        all pairs is real) *)
                        let facts = (Complex.mul i_f (Complex.conj j_f)).re in 
                        
                        (* calculate contribution *)
                        facts *. sin_q_dist
                in 
            
                (* add to qi *)
                qi := !qi +. contribution;
            ) df_coords
        ) df_coords; 
        
        (* stop timer; calculate span and add to time spent *)
        let end_time = Mtime_clock.now () in 
        
        (* calculate duration, convert to Int64 *)
        let duration = Mtime.span start_time end_time in
        tt := Int64.add !tt (Mtime.Span.to_uint64_ns duration);

        (* create row, add to df_scatts *)
        let q = Owl_dataframe.pack_float !qa in
        let i = Owl_dataframe.pack_float !qi in 
        Owl_dataframe.append_row df_scatts [|q;i|];
        
        (* increment qa *)
        qa := !qa +. 0.02
    done;
    
    (df_scatts, !tt)