module calc_mod
    use, intrinsic :: ieee_arithmetic
    use, intrinsic :: iso_c_binding
    use kdt_mod
    use atom_mod
    
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

    ! bernoulli estimator type
    type :: bernoulli
        complex(c_double) :: thresh
        real(c_double)    :: probab
    end type bernoulli

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