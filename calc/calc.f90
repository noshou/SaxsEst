module calc_mod
    use, intrinsic :: ieee_arithmetic
    use, intrinsic :: iso_c_binding
    use kdt_mod
    use atom_mod
    
    implicit none 
    private 
    public :: estimate, debeye_radial, debeye_kdt, prop_radial, prop_kdt
    
    ! intensity estimate type
    type, bind(C) :: estimate
        type(c_ptr)     :: q_vals    
        type(c_ptr)     :: i_vals     
        integer(c_int)  :: timing
        integer(c_int)  :: size  
        type(c_ptr)     :: name       
    end type estimate

    ! ! bernoulli estimator type
    ! type :: bernoulli
    !     complex(c_double) :: thresh
    !     real(c_double)    :: probab
    ! end type bernoulli

    contains 

        ! helper functions
        include "new_intensity.f90"
        include "prop_est.f90"
        include "sinc.f90"
        include "debeye_radial.f90"
        include "debeye_kdt.f90"
        include "prop_radial.f90"
        include "prop_kdt.f90"
end module calc_mod