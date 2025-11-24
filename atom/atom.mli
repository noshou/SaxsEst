(** represents a 3-D coordinate *)
type coord = {x: float; y: float; z: float}

(** abstract type of an atom *)
type atom 


(** creates a new atom  *)
val create : coord -> string -> atom 

(** gets the coordinate of an atom *)
val xyz : atom -> coord

(** gets the name of an atom *)
val name : atom -> string

(** The atomic form factor describes how an atom scatters X-rays or neutrons
    as a function of the scattering angle. 

    @param atom The atom for which to calculate the form factor.
    @param q The magnitude of the scattering vector in range [0,0.5] Å⁻¹
    @return The complex atomic form factor f(Q). For most elements in the*)
val form_factor : atom -> float -> Complex.t

(** returns a human-readable string of the atom.
    @param atom The atom to represent as a string.
    @param q Optional scattering vector magnitude in range [0,0.5] Å⁻¹ (default: [0.0] Å⁻¹).
    @return A formatted string containing the atom's element, coordinates, and its form factor.*)
val to_string : atom -> ?q:float -> unit -> string 

(** compares the positions of two atoms ([ref] and [cmp]) along 
    a single spatial axis (x, y, or z). 
    
    @param ref atom to compare against.
    @param cmp atom being compared 
    @param axs The axis along which to compare: ["x"], ["y"], or ["z"] (case-insensitive).
    
    @return An integer indicating the comparison result:
            - Negative if [cmp]'s coordinate < [ref]'s coordinate 
            - Zero if [cmp]'s coordinate = [ref]'s coordinate  
            - Positive if [cmp]'s coordinate > [ref]'s coordinate 
    
    @raise Invalid_argument if [axs] is not ["x"], ["y"], or ["z"] (case-insensitive)*)
val cmp_by_axis : atom -> atom -> string -> int

(** compares two coordinates; if they are the same, returns true *)
val cmp_by_coords : atom -> atom -> bool

(** calculates the distance between two atoms *)
val calc_distance : atom -> atom -> float