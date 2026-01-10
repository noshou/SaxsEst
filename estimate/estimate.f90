module estimate_mod
    use, intrinsic :: iso_c_binding
    use kdt_mod
    use atom_mod
    
    implicit none 
    private 
    public :: estimate, debyeEst_radial, debyeEst_kdt, propEst_radial, propEst_kdt
    
    ! intensity estimate type
    type, bind(C) :: estimate
        type(c_ptr)             :: q_vals    
        type(c_ptr)             :: i_vals     
        real(c_int), public     :: timing
        integer(c_int), public  :: size  
    end type estimate

    contains 
        include "inc/new_intensity.inc"
        include "inc/propEst/propEst.inc"
        include "inc/sinc.inc"
        include "inc/debyeEst/debyeEst_radial.inc"
        include "inc/debyeEst/debyeEst_kdt.inc"
        include "inc/propEst/propEst_radial.inc"
        include "inc/propEst/propEst_kdt.inc"
        
end module estimate_mod