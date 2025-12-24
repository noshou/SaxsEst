!! @param[in] w      Array of weights       (must be same size as f)
!! @param[in] f      Array of frequencies   (must be same size as w)
!! @param[in] a      Advice parameter, should be >= number of nodes 
!! @param[in] e      Epsilon parameter, must satisfy 0 < epsilon < 1 
!! @param[in] c      Rounding flag: .true. for ceiling, .false. for floor (logical)
!!
!! @return w_est     Estimated form factor weight (W/n)
pure function harm_est(w, f, a, e, c) result(w_est)
    
    ! Input parameters
    complex(c_double), dimension(:), intent(in) :: w !< Array of weights
    integer, dimension(:), intent(in) :: f           !< Array of frequencies
    real(c_double), intent(in) :: a                  !< Advice parameter (>= # nodes)
    real(c_double), intent(in) :: e                  !< Epsilon (0 < e < 1)
    logical, intent(in) :: c                         !< Ceiling flag
    
    ! Return value
    complex(c_double) :: w_est                       !< Estimated weight
    

end function harm_est