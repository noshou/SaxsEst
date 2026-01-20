
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
!! @param[in] w     Array of weights
!! @return e        C-interoperable intensity_est structure with pointers to allocated data
function new_intensity(s, f, r, q, i, w) result(e)
    
    ! input variables
    integer, intent(in) :: s, f
    real ,   intent(in) :: r
    real(c_double), dimension(:), intent(in) :: q, i
    complex(c_double), dimension(:), intent(in), optional :: w

    ! execution time
    real(c_double) :: t

    ! targets for c arrays (need to be saved to persist!)
    real(c_double), dimension(:), allocatable, save, target :: q_cpy, i_cpy
    complex(c_double), dimension(:), allocatable, save, target :: w_cpy

    ! output variable
    type(estimate) :: e

    ! check if targets allocated - free if they are
    if (allocated(q_cpy)) then; deallocate(q_cpy); end if
    if (allocated(i_cpy)) then; deallocate(i_cpy); end if
    if (allocated(w_cpy)) then; deallocate(w_cpy); end if

    ! copy over data to c pointers
    allocate(q_cpy(size(q)))
    allocate(i_cpy(size(i)))
    allocate(w_cpy(size(w)))
    q_cpy = q  
    i_cpy = i  
    w_cpy = w
    
    ! calculate execution time
    t = real(f - s, kind=c_double) / real(r, kind=c_double)

    ! build output 
    e%q_vals = c_loc(q_cpy)
    e%i_vals = c_loc(i_cpy)
    e%timing = t
    e%size   = real(size(q), kind=c_double)
    e%w_vals = c_loc(w_cpy)

end function new_intensity
