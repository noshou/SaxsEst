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
        - the elapsed execution (ns) *)
let classic (fp: string) : Owl_dataframe.t * float = 
    
    (* load xyz data *)
    let df_coords = load_xyz fp |> Owl_dataframe.to_rows in 
	
	  (* this is the normalization constant; makes I(Q) be in range [0,1] *)
	  let normalize = (float_of_int (Array.length df_coords) *. float_of_int (Array.length df_coords)) in 

    (* create empty dataframe for I(Q) values *)
    let df_scatts = Owl_dataframe.make [|"Q"; "I_Q"|] in 

    (* Q (Å⁻¹) iterate from 0.02 -> 0.5 in increments of 0.02 *)
    let qa = ref 0.02 in 
    
    (* ref for total time spent on calculations *)
    let tt = ref (Int64.of_float 0.) in 

    (* increment for number of steps (25) *)
    let ii = ref 0 in 
    
	while !ii < 25 do 
        
        (* current I(Q) value *)
        let qi = ref 0. in 

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
                let j_f = form_fact !qa j_e in  
                let j_r = [|j_x;j_y;j_z|] in
                
                (* start timer *)
                let start_time_1 = Mtime_clock.now () in 
                
                (* calculate |rᵢ - rⱼ| *)
                let dist = sqrt (
                    (i_r.(0) -. j_r.(0))**2.
                    +. (i_r.(1)-.j_r.(1))**2. 
                    +. (i_r.(2)-.j_r.(2)) **2.)
                in 
                
                (* stop timer; calculate span and add to time spent *)
                let end_time_1 = Mtime_clock.now () in 
                let span1 = Mtime.span start_time_1 end_time_1 in

                (* if |r_i - r_j| == 0, limit(x->0) of sin(x)/x = 1. Since we cannot divide by zero,
				        we set sin(x)/x = 1 and our term becomes f_i * conjugate(f_i) *)
                let contribution = 
                    if Float.abs dist < 1e-12 then
                        let start_time_2 = Mtime_clock.now () in
                        let intensity = (Complex.mul i_f (Complex.conj i_f)).re in 
                        let end_time_2 = Mtime_clock.now () in
                        (intensity, Mtime.span start_time_2 end_time_2)
                    else 
                        let start_time_2 = Mtime_clock.now () in

                        (* calculate Q * |r_i - r_j| *)
                        let q_dist = !qa *. dist in 
                        
                        (* calculate  Q*|r_i-r_j*)
                        let sin_q_dist = (sin q_dist) /. q_dist in

                        (* calculate i_f * (conjugate(j_f)) 
                        turns out because of weird symmetry we can 
                        ignore the complex part (since the summation over
                        all pairs is real) *)
                        let facts = (Complex.mul i_f (Complex.conj j_f)).re in 

                        (* calculate contribution *)
                        let intensity = facts *. sin_q_dist in
                        let end_time_2 = Mtime_clock.now() in 
                        (intensity, Mtime.span start_time_2 end_time_2)
                in 
                
                (* unpack tuple *)
                let (intensity, span2) = contribution in 

                (* add to qi *)
                let start_time_3 = Mtime_clock.now () in 				
                qi := !qi +. intensity;
                let end_time_3 = Mtime_clock.now () in 
                let span3 = Mtime.span start_time_3 end_time_3 in 

                (* sum spans, add to tracker of total time spent *)
                let duration = Mtime.Span.add (Mtime.Span.add span1 span2) span3 in
                tt := Int64.add !tt (Mtime.Span.to_uint64_ns duration);
            
            ) df_coords
        ) df_coords; 
		
		(*We have to pack qa and qi into an Owl_dataframe.elts array 
		which can then be passed a row to the dataframe. Before we do this we must 
		normalize the intensity*)		
		let q = Owl_dataframe.pack_float !qa in
		let i = !qi /. normalize |> Owl_dataframe.pack_float  in 
        Owl_dataframe.append_row df_scatts [|q;i|];
                
        (* Print progress *)
        Printf.printf "Q = %f, I(Q) = %f\n%!" !qa !qi; 
        
        (* increment qa *)
        qa := !qa +. 0.02;
		ii := !ii + 1
    done;
    
    (df_scatts, Int64.to_float !tt)