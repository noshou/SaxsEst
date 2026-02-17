!! @param[in] k      Frequencies of atoms
!! @param[in] q      Q value for form factor calculation
!! @param[in] e      Epsilon, accuracy parameter (must satisfy 0 < e < 1)
!! @param[in] c      Ceiling flag: if .true. use ceiling, if .false. use floor
!! @param[in] a      Upper bound of W/n
!! @param[in] b      P_unif(k(q)>=phi) is sufficiently large and a/b is not too big     
!! @return wEst     Complex conjugate of the estimated propagator weight
function harmEst(k, q, e, c, a, b) result(wEst)
    
    ! Input parameters
    type(frequencies), intent(in) :: k
    real(c_double), intent(in) :: q, e, a, b
    real(c_double), intent(in) :: e !< Epsilon (0 < e < 1)
    logical, intent(in) :: c        !< Ceiling flag
    
    ! Return value
    complex(c_double) :: wEst

    ! number of samples