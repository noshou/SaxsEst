
!> Create a new  persistent storage for Q values, intensity values,
!! and dataset name, then creates a C-interoperable structure pointing to this data.
!! 
!! The returned structure contains pointers to SAVE variables that are
!! overwritten on the next call to this function. 
!!  
!! @param[in] t     Timing value in milliseconds
!! @param[in] q     Array of Q values
!! @param[in] i     Array of intensity estimates
!! @param[in] n     Dataset name 
!!
!! @return e        C-interoperable intensity_est structure with pointers to allocated data
function new_intensity(t, q, i, n) result(e)
    
    ! input variables
    integer(c_int), intent(in) :: t
    real(c_double), intent(in) :: q, i
    character(len=*), intent(in) :: n

    ! targets for c arrays (need to be saved to persist!)
    real(c_double), dimension(:), allocatable, save, target :: q_cpy, i_cpy
    character(len=:), allocatable, save, target :: n_cpy

    ! check if targets allocated - free if they are
    if (allocated(q_cpy)) then; deallocate(q_cpy); end if
    if (allocated(i_cpy)) then; deallocate(i_cpy); end if
    if (allocated(n_cpy)) then; deallocate(n_cpy); end if

    ! copy over data to c pointers
    allocate(q_cpy(size(q)))
    allocate(i_cpy(size(i)))
    q_cpy = q  
    i_cpy = i  
    n_cpy = trim(n) // c_null_char
    
    ! build output 
    type(intensity_est) :: e
    e%q_vals = c_loc(q_cpy)
    e%i_vals = c_loc(i_cpy)
    e%timing = t
    e%size   = integer(size(q), kind=c_int)
    e%name   = c_loc(n_cpy)

end function new_intensity
