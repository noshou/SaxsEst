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
    complex(c_double) :: w_est                       !< Estimated weight
    
    ! Local variables
    complex(c_double), allocatable :: w(:)           !< Array of weights
    integer, allocatable :: f(:)                     !< Array of frequencies
    integer :: s                                     !< Sample size
    integer :: s_fact                                !< Factorial of s
    integer :: s_incr                                !< Incrementer for s factorial
    integer :: s_choose_2                            !< Binomial coefficient C(s,2)
    integer :: p_fact                                !< Factorial of (s-2)
    integer :: p_incr                                !< Incrementer for p factorial
    integer :: k_fact                                !< Factorial of (f(i)-2)
    integer :: k_incr                                !< Incrementer for k factorial
    integer :: i                                     !< Loop counter
    integer :: c_choose_2                            !< Binomial coefficient C(f(i),2)
    integer :: c_fact                                !< Factorial of f(i)
    integer :: c_incr                                !< Incrementer for c factorial
    complex(c_double) :: sum                         !< Accumulator for weighted sum
    
    ! Allocate space for list of weights and frequencies
    allocate(w, source=k%weights(q)); allocate(f, source=k%freqs())

    ! Calculate sample size based on rounding mode
    if (c) then
        ! Ceiling: s = ⌈√(24*a)/e⌉ + 1
        s = ceiling(sqrt(24*a)/e) + 1
    else
        ! Floor: s = ⌊√(24*a)/e⌋ + 1
        s = floor(sqrt(24*a)/e) + 1
    end if 
    
    ! Calculate factorial of s
    s_fact = 1
    s_incr = s
    do while (s_incr > 1)
        s_fact = s_fact * s_incr
        s_incr = s_incr - 1
    end do 
    
    ! Calculate factorial of (s-2)
    p_fact = 1
    p_incr = s - 2
    do while (p_incr > 1)
        p_fact = p_fact * p_incr
        p_incr = p_incr - 1
    end do
    
    ! Calculate binomial coefficient: C(s,2) = s! / (2! * (s-2)!)
    s_choose_2 = s_fact / (2 * p_fact)
    
    ! Accumulate sum of (C(f(i),2) / w(i)) for all weights
    sum = cmplx(0.0, 0.0, kind=c_double)
    do i = 1, k%n_unique()
        ! Calculate binomial coefficient C(f(i),2)
        if (f(i) == 1) then
            ! Edge case: frequency = 1, C(1,2) is undefined, use 0
            c_choose_2 = 0
        else 
            ! Calculate f(i)!
            c_fact = 1
            c_incr = f(i)
            do while(c_incr > 1)
                c_fact = c_fact * c_incr
                c_incr = c_incr - 1
            end do
            
            ! Calculate (f(i)-2)!
            k_fact = 1
            k_incr = f(i) - 2
            do while(k_incr > 1)
                k_fact = k_fact * k_incr
                k_incr = k_incr - 1
            end do 
            
            ! C(f(i),2) = f(i)! / (2! * (f(i)-2)!)
            c_choose_2 = c_fact / (2 * k_fact)
        end if 
        
        ! Accumulate: sum += C(f(i),2) / w(i)
        sum = sum + c_choose_2 / w(i)
    end do 
    
    ! Calculate estimated weight: w_est = C(s,2) / sum
    ! then get complex conjugate of w_est
    w_est = s_choose_2 / sum
    w_est = conjg(w_est)

end function propEst