module Est
    
    use, intrinsic :: iso_c_binding
    use Freq
    use AtomXYZ
    use iso_fortran_env, only: real64
    
    implicit none 
    private 
    public :: estimate, debyeEst, propoEst, stratEst
    
    !> intensity estimate type
    type, bind(C) :: estimate
        type(c_ptr)             :: qVals    !> list of q values 
        type(c_ptr)             :: iVals    !> list of intensities
        real(c_double), public  :: timing   !> total CPU exec time
        integer(c_int), public  :: size     !> total number of datapoints
    end type estimate

    !> container for stratified sample containing 
    !! sampled coordinates, sampled atoms, and selection probabilities
    type :: stratEstContainer
        type(coordPtr),    allocatable :: sampledCoords(:)  !> parallel list of sampled coordinates
        type(atom),        allocatable :: sampledAtoms(:)   !> parallel list of sampled atoms
        real(c_double),    allocatable :: hansenHurwitz(:)  !> parallel list of selection probability
    end type stratEstContainer

    contains 
        include "inc/utils.inc"
        include "inc/debyeEst.inc"
        include "inc/stratEst.inc"
        include "inc/propoEst.inc"
end module Est
