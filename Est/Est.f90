module Est
    use, intrinsic :: iso_c_binding
    use Freq
    use AtomXYZ
    
    implicit none 
    private 
    public :: estimate, debyeEst, propoEst, stratEst
    
    ! intensity estimate type
    type, bind(C) :: estimate
        type(c_ptr)             :: qVals    
        type(c_ptr)             :: iVals     
        real(c_int), public     :: timing
        integer(c_int), public  :: size  
    end type estimate

    ! container for stratified sample
    type :: stratEstContainer
        complex(c_double), allocatable :: sampledWeights(:)
        type(coord),       allocatable :: sampledCoords(:)
        real(c_double)                 :: formFactorEstimate
    end type stratEstContainer

    contains 
        include "inc/utils.inc"
        include "inc/debyeEst.inc"
        include "inc/stratEst.inc"
        include "inc/propoEst.inc"
end module Est