module calc_mod
    
    use atom_mod
    use iso_c_binding
    use kdt_mod
    
    implicit none 
    private 

    ! intensity estimate type
    type, bind(C) :: intensity
        type(c_ptr)     :: q_vals    
        type(c_ptr)     :: i_vals     
        integer(c_int)  :: timing
        integer(c_int)  :: size  
        type(c_ptr)     :: name       
    end type intensity

    contains 

        ! helper functions
        include "new_intensity.f90"
        include "sinc.f90"

        ! estimator algorithms
        include "prop_est.f90"
        include "harm_est.f90"
        include "hybr_est.f90"

        ! calculation algorithms
        include "debeye.f90"
        include "prop_radial.f90"
        include "prop_kdt.f90"
        include "harm_radial.f90" 
        include "harm_kdt.f90"
        include "hybr_radial.f90"
        include "hybr_kdt.f90"

end module calc_mod