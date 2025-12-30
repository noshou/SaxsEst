!! @param[in] a      Advice parameter, should be >= number of nodes 
!! @param[in] e      Epsilon parameter, must satisfy 0 < epsilon < 1 
!! @param[in] c      Rounding flag: .true. for ceiling, .false. for floor (logical)
function prop_kdt(k, r, atoms, n_atoms, norm, q_vals, n_q, name, a, e, c) result(intensity_estimate)
    
    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: r
    character(len=*), intent(in) :: name
    type(atom), dimension(:), intent(in) :: atoms
    integer, intent(in) :: n_atoms
    real(c_double), dimension(n_q), intent(in) :: q_vals
    real(c_double), dimension(n_q) :: intensity
    integer :: i, j, q_ij
    real(c_double) :: q_val 
    logical, intent(in) :: c

    ! timing variables
    integer(0_c_int) :: timing
    integer :: start, finish, rate

    ! output data
    type(estimate) :: intensity_estimate

    ! variables for weight estimate
    complex(c_double) :: w_est
    complex(c_double), dimension(:) :: w
    integer, dimension(:) :: f
    real(c_double), intent(in) :: a
    real(c_double), intent(in) :: e
    f = 

end function prop_kdt