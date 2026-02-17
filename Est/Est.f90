module Est
    use, intrinsic :: iso_c_binding
    use Freq
    use AtomXYZ
    
    implicit none 
    private 
    public :: estimate, debyeEst, propEst
    
    ! intensity estimate type
    type, bind(C) :: estimate
        type(c_ptr)             :: qVals    
        type(c_ptr)             :: iVals     
        real(c_int), public     :: timing
        integer(c_int), public  :: size  
        type(c_ptr)             :: wVals 
    end type estimate

    contains 
        include "inc/utils.inc"
        include "inc/propEst.inc"
        include "inc/debyeEst.inc"
end module Est