!> Create a new  persistent storage for Q values, intensity values,
!! then creates a C-interoperable structure pointing to this data.
!! 
!! The returned structure contains pointers to SAVE variables that are
!! overwritten on the next call to this function. 
!!  
!! @param[in] s     Start  time of clock
!! @param[in] f     Finish time of clock
!! @param[in] r     Ticks/second of clock 
!! @param[in] q     Array of Q values
!! @param[in] i     Array of intensity estimates
!! @return e        C-interoperable intensity_est structure with pointers to allocated data
function newIntensity(s, f, r, q, i) result(e)
    
    ! input variables
    integer, intent(in) :: s, f
    real ,   intent(in) :: r
    real(c_double), dimension(:), intent(in) :: q, i

    ! execution time
    real(c_double) :: t

    ! targets for c arrays (need to be saved to persist!)
    real(c_double), dimension(:), allocatable, save, target :: qCpy, iCpy

    ! output variable
    type(estimate) :: e

    ! check if targets allocated - free if they are
    if (allocated(qCpy)) then; deallocate(qCpy); end if
    if (allocated(iCpy)) then; deallocate(iCpy); end if

    ! copy over data to c pointers
    allocate(qCpy(size(q)))
    allocate(iCpy(size(i)))
    qCpy = q  
    iCpy = i  
    
    ! calculate execution time
    t = real(f - s, kind=c_double) / real(r, kind=c_double)

    ! build output 
    e%qVals = c_loc(qCpy)
    e%iVals = c_loc(iCpy)
    e%timing = t
    e%size   = real(size(q), kind=c_double)

end function newIntensity

!> Cardinal sine function: sinc(x) = sin(x)/x
!! 
!! Returns 1 for x ≈ 0 to avoid division by zero
!!
!! @param[in] x  Input value
!!
!! @return sinc(x), with limit value 1 as x→0
pure function sinc(x) result(res)
    real(c_double), intent(in) :: x
    real(c_double) :: res   
    
    if (abs(x) <= 1e-9_c_double) then  
        res = 1.0_c_double
    else 
        res = sin(x) / x
    end if 
end function sinc