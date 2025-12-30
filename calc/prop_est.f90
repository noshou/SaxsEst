!> The algorithm performs the following steps:
!! 1. Calculates sample size s based on formula:
!!    - If u=.true.:  s = ⌈√(24*a)/e⌉ + 1
!!    - If u=.false.: s = ⌊√(24*a)/e⌋ + 1
!! 2. Computes binomial coefficient s_choose_2 = s!/(2!(s-2)!)
!! 3. For each weight-frequency pair, computes c_choose_2 and accumulates sum
!! 4. Returns estimated weight as w_est = s_choose_2 / sum
!!
!! @param[in] w      Array of weights       (must be same size as f)
!! @param[in] f      Array of frequencies   (must be same size as w)
!! @param[in] a      Advice parameter, should be >= number of nodes 
!! @param[in] e      Epsilon parameter, must satisfy 0 < epsilon < 1 
!! @param[in] c      Rounding flag: .true. for ceiling, .false. for floor (logical)
!!
!! @return w_est     Estimated complex conjugate  form factor weight (W)
pure function prop_est(w, f, a, e, c) result(w_est)
    
    ! Input parameters
    complex(c_double), dimension(:), intent(in) :: w !< Array of weights
    integer, dimension(:), intent(in) :: f           !< Array of frequencies
    real(c_double), intent(in) :: a                  !< Advice parameter (>= # nodes)
    real(c_double), intent(in) :: e                  !< Epsilon (0 < e < 1)
    logical, intent(in) :: c                         !< Ceiling flag
    
    ! Return value
    complex(c_double) :: w_est                       !< Estimated weight
    
    ! Local variables
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
    sum = cmplx(0.0_c_double, 0.0_c_double, kind=c_double)
    do i = 1, size(w) 
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
    w_est = s_choose_2 / sum
    
    ! get complex conjugate of w_est
    w_est = conjg(w_est)

end function prop_est