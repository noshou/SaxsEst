!! Calculates an estimated weight for the propagator based on a k-d tree structure
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
!! @param[in] k      Frequencies of atoms
!! @param[in] q      Q value for form factor calculation
!! @param[in] a      Advice for scaling factor for sample size calculation
!! @param[in] e      Epsilon, accuracy parameter (must satisfy 0 < e < 1)
!! @param[in] c      Ceiling flag: if .true. use ceiling, if .false. use floor
!!
!! @return wEst    Complex conjugate of the estimated propagator weight
function propEstCalc(k, q, a, e, c) result(wEst)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    type(frequencies),  intent(in) :: k
    real(c_double),     intent(in) :: a, q,  e  
    logical, intent(in)            :: c        
    complex(c_double)              :: wEst, tot    
    complex(c_double), allocatable :: w(:)
    integer, allocatable           :: f(:)
    integer                        :: s, sChoose2, cChoose2, i 
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    ! Allocate space for list of weights and frequencies
    allocate(w, source=k%weights(q)); allocate(f, source=k%freqs())

    ! Calculate sample size based on rounding mode
    if (c) then
        s = ceiling(sqrt(24.0_c_double*a)/e) + 1
    else
        s = floor(sqrt(24.0_c_double*a)/e) + 1
    end if 
    
    ! Calculate binomial coefficient: C(s,2) = s * (s-1) / 2
    sChoose2 = s * (s - 1) / 2
    
    ! Accumulate tot of (C(f(i),2) / w(i)) for all weights
    tot = cmplx(0.0, 0.0, kind=c_double)
    do i = 1, k%nUnique
        ! Calculate binomial coefficient C(f(i),2)
        if (f(i) <= 1) then
            cChoose2 = 0
        else 
            cChoose2 = f(i) * (f(i) - 1) / 2
        end if 
        
        ! Accumulate: tot += C(f(i),2) / w(i)
        tot = tot + cChoose2 / w(i)
    end do 
    
    ! Calculate estimated weight: wEst = conjg(C(s,2) / tot)
    wEst = conjg(sChoose2 / tot)

end function propEstCalc

!! Docstring needs updating (add normalization constant)
!! Computes scattering intensity I(Q) for a given set of Q values using a radial
!! contribution method with proportional weight estimation. The intensity is calculated
!! using atomic form factors and pairwise distance contributions via the sinc function.
!!
!! The algorithm performs the following steps for each Q value:
!! 1. Estimates proportional weights using the propoEst function
!! 2. Computes pairwise contributions: f_i * wEst * sinc(Q * r_ij) for all atom pairs
!! 3. Adds self-contribution: f_i * conj(f_i) for each atom
!!
!! The intensity calculation follows the form:
!! \f$ I(Q) = \sum_{i=1}^{N} \sum_{j=1}^{N} f_i(Q) w_{est}(Q) \frac{\sin(Q r_{ij})}{Q r_{ij}} \f$
!!
!! @param[in] k         List of frequencies
!! @param[in] atoms     List of atoms
!! @param[in] qVals    Array of Q values at which to calculate intensity
!! @param[in] a         Advice parameter for weight estimation (should be >= number of nodes)
!! @param[in] e         Epsilon parameter for accuracy control (must satisfy 0 < e < 1)
!! @param[in] c         Rounding mode flag: .true. for ceiling, .false. for floor
!!
!! @return              intensityEstimate type containing:
!!                      - Execution time in nanoseconds
!!                      - Q values array
!!                      - Calculated intensity values I(Q)
function propoEst(k, atoms, qVals, a, e, c) result(intensityEstimate)
    
    ! input variables
    type(frequencies),  intent(in)  :: k
    real(c_double),     intent(in)  :: a 
    real(c_double),     intent(in)  :: e  
    logical,            intent(in)  :: c         
    type(atom),         intent(in)  :: atoms(:)
    real(c_double),     intent(in)  :: qVals(:)

    ! local variables
    real(c_double), allocatable     :: intensity(:)
    integer                         :: nAtoms, nQVals, i, j, qIJ, start, finish
    real                            :: rate
    type(estimate)                  :: intensityEstimate
    type(atom)                      :: atomI
    complex(c_double)               :: wEst, atomIFormFact
    real(c_double)                  :: qVal, radialContrib, atomicContrib, dst, est, norm

    ! start timer
    call system_clock(start, rate)

    ! initialize variables
    nAtoms = size(atoms)
    nQVals = size(qVals)
    allocate(intensity(nQVals))
    
    do qIJ = 1, nQVals
        qVal = qVals(qIJ)
        
        ! get estimate of weight
        wEst = propEstCalc(k, qVal, a, e, c)
        est = 0.0_c_double
        if (c) then
            norm = nAtoms * (ceiling(sqrt(24.0_c_double*a)/e) + 1)
        else
            norm = nAtoms * (floor(sqrt(24.0_c_double*a)/e) + 1)
        end if 

        do i = 1, nAtoms
            atomI = atoms(i)
            atomIFormFact = atomI%formFactor(qVal)
            atomicContrib = real(atomIFormFact * wEst, kind=c_double)
            
            do j = 1, nAtoms
                if (j /= i) then 
                    dst = qVal * abs(atomI%distCart(atoms(j)))
                    radialContrib = sinc(dst)
                    est = est + atomicContrib * radialContrib
                else
                    ! since self is not picked up in radial search, 
                    ! we add the case of atomIFormFact * conj(atomIFormFact)
                    est = est + real(atomIFormFact * conjg(atomIFormFact), kind=c_double)  
                end if
            end do 
        end do 
        
        intensity(qIJ) = est / norm
    end do
    
    ! stop timer
    call system_clock(finish)
    
    ! output estimate
    intensityEstimate = newIntensity(start, finish, rate, qVals, intensity)
    
    ! cleanup
    deallocate(intensity)
    
end function propoEst
