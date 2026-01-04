module estimate_mod
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

    ! bernoulli estimator type
    ! type :: bernoulli
    !     complex(c_double) :: thresh
    !     real(c_double)    :: probab
    ! end type bernoulli

    contains 
        include "func/new_intensity.f90"
        include "func/prop_est/prop_est.f90"
        include "func/sinc.f90"
        include "func/debeye/debeye_radial.f90"
        include "func/debeye/debeye_kdt.f90"
        include "func/prop_est/prop_radial.f90"
        include "func/prop_est/prop_kdt.f90"
end module estimate_mod