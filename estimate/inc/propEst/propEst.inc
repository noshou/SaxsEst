!! Computes an estimated weight for the propagator based on a k-d tree structure
!! containing weights and their frequencies. The estimation uses a sample size
!! determined by the accuracy parameter epsilon and scaling factor a.
!!
!! The sample size is calculated as:
!! - If ceiling mode: s = ⌈√(24*a)/e⌉ + 1
!! - If floor mode:   s = ⌊√(24*a)/e⌋ + 1
!!
!! The weight estimate is computed using the formula:
!! \f$ \hat{w} = \overline{\frac{C(s,2)}{\sum_{i=1}^{n} \frac{C(f_i,2)}{w_i}}} \f$
!!
!! where:
!! - C(n,k) is the binomial coefficient "n choose k"
!! - f_i is the frequency of the i-th unique weight
!! - w_i is the i-th unique weight
!! - The overline denotes complex conjugate
!!
!! @param[in] k      K-d tree structure containing weights and frequencies
!! @param[in] q      Query parameter for weight extraction
!! @param[in] a      Scaling factor for sample size calculation
!! @param[in] e      Epsilon, accuracy parameter (must satisfy 0 < e < 1)
!! @param[in] c      Ceiling flag: if .true. use ceiling, if .false. use floor
!!
!! @return w_est    Complex conjugate of the estimated propagator weight
function propEst(k, q, a, e, c) result(w_est)
    
    ! Input parameters
    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: q
    real(c_double), intent(in) :: a
    real(c_double), intent(in) :: e !< Epsilon (0 < e < 1)
    logical, intent(in) :: c        !< Ceiling flag
    
    ! Return value
    complex(c_double) :: w_est
    
    ! Local variables
    complex(c_double), allocatable :: w(:)
    integer, allocatable :: f(:)
    integer :: s, s_choose_2, c_choose_2, i
    complex(c_double) :: sum
    
    ! Allocate space for list of weights and frequencies
    allocate(w, source=k%weights(q)); allocate(f, source=k%freqs())

    ! Calculate sample size based on rounding mode
    if (c) then
        s = ceiling(sqrt(24*a)/e) + 1
    else
        s = floor(sqrt(24*a)/e) + 1
    end if 
    
    ! Calculate binomial coefficient: C(s,2) = s * (s-1) / 2
    s_choose_2 = s * (s - 1) / 2
    
    ! Accumulate sum of (C(f(i),2) / w(i)) for all weights
    sum = cmplx(0.0, 0.0, kind=c_double)
    do i = 1, k%n_unique()
        ! if (abs(w(i)) < 1.0e-15_c_double) cycle
        
        ! Calculate binomial coefficient C(f(i),2)
        if (f(i) <= 1) then
            c_choose_2 = 0
        else 
            c_choose_2 = f(i) * (f(i) - 1) / 2
        end if 
        
        ! Accumulate: sum += C(f(i),2) / w(i)
        sum = sum + c_choose_2 / w(i)
    end do 
    
    ! Calculate estimated weight: w_est = conjg(C(s,2) / sum)
    w_est = conjg(s_choose_2 / sum)

end function propEst