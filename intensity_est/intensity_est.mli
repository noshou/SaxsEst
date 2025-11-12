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
val classic : string -> Owl_dataframe.t * float