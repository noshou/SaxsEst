!> Samples atom types and coordinates from a stratum via inverse CDF.
!!
!! Draws samples from the provided cumulative probability distribution,
!! assigns the corresponding atom, and randomly selects
!! a coordinate from that atom type's coordinate list. Designed to be
!! called twice per sampling (once for heavy, once for light strata)
!! with a shared counter j that tracks the write position.
!! @param[in]    tol        Tolerance for inverse CDF comparison
!! @param[in]    nSamples   Number of samples to draw from this stratum
!! @param[in]    atmInp     Atom types in this stratum
!! @param[inout] atmSmp     Output array of sampled atoms (shared across strata)
!! @param[in]    crdInp     Coordinate pointer lists per atom type in this stratum
!! @param[inout] crdSmp     Output array of sampled coordinate pointers (shared across strata)
!! @param[in]    probs      Cumulative probabilities for this stratum
!! @param[inout] j          Write position counter; caller must initialize to 0 before first stratum
!! @param[inout] atmPrb     Output array of the probability of selecting a specific atom (shared across strata)
subroutine sampleStratum(   &
        tol,                &
        nSamples,           &
        atmInp,             &
        atmSmp,             &
        crdInp,             & 
        crdSmp,             & 
        probs,              & 
        j,                  &
        atmProb             &
    )

    ! input variables
    real(c_double),     intent(in)    :: tol
    integer,            intent(in)    :: nSamples
    type(atom),         intent(in)    :: atmInp(:)
    real(c_double),     intent(in)    :: probs(:)
    type(coordPtrList), intent(in)    :: crdInp(:)

    ! input/output variables
    type(atom),         intent(inout) :: atmSmp(:)
    type(coordPtr),     intent(inout) :: crdSmp(:)
    real(c_double),     intent(inout) :: atmProb(:)

    ! shared counter
    integer,            intent(inout) :: j
    
    ! local variables
    real(c_double) :: u
    integer        :: i, m, idx

    do i = 1, nSamples
        call random_number(u)
        do m = 1, size(atmInp)

            ! inverse sample atom type
            if ((probs(m) - u) >= tol) then 
                
                ! increment to next position, sample atom
                j = j + 1
                atmSmp(j) = atmInp(m)
                
                ! calculate probability of selecting atom, store in parallel array
                if (m == 1) then
                    atmProb(j) = probs(1)
                else
                    atmProb(j) = probs(m) - probs(m-1)
                end if
                
                ! randomly select a coordinate
                call random_number(u)
                idx = floor(u * real(crdInp(m)%n)) + 1
                crdSmp(j) = crdInp(m)%ptrs(idx)
                exit
            end if 
        end do 
    end do 
end subroutine sampleStratum

!> Gives a stratified sample for a given q.
!! Splits the frequency distribution into heavy and light strata based on
!! mean form factor magnitude, then performs inverse CDF sampling biased
!! toward the heavy stratum. Returns a container with sampled atoms and
!! their corresponding coordinate pointers.
!! @param[in] k  Frequency distribution of atom types in the molecule
!! @param[in] a  Sampling proportion upper bound (scales with k%nItems)
!! @param[in] q  Single scattering vector magnitude (Å⁻¹) used for stratification
!!
!! @return   stratEstContainer with sampled atoms and coordinate pointers
function stratEstCalc(k, a, q) result(es)
    
    ! input variables
    type(frequencies), intent(in)  :: k
    real(c_double),    intent(in)  :: a, q
    
    ! local variables
    type(cdf),         allocatable :: heavyCdf, lightCdf
    complex(c_double), allocatable :: heavy(:), light(:)
    type(atom),        allocatable :: sampleAtoms(:)
    type(coordPtr),    allocatable :: sampleCoords(:) 
    real(c_double),    allocatable :: hansenHurwitz(:)
    type(stratEstContainer)        :: es
    integer                        :: j, lightSamples, heavySamples, totalSamples
    real(c_double)                 :: stratumStDev, strataBudget, sumStratMean
    real(c_double),    parameter   :: tolerance = 1.0e-10_c_double

    ! set upper/lower bounds and calculate advice
    totalSamples = ceiling(a*real(k%nItems,kind=c_double))
    
    ! sample total of a atoms
    heavyCdf = k%heavy(q)
    ! if (allocated(heavyCdf)) then
        allocate(heavy, source=heavyCdf%weights)
        
        ! light strata is <= mean
        lightCdf = k%light(q)
        allocate(light, source=lightCdf%weights)

        ! neyman allocation
        ! -> stratumStDev = heavyStDv * heavyPopulation + lightStDv * lightPopulation
        ! -> strataBudget = ⌈a * total population⌉
        ! -> minimum stratum size: 2
        ! -> maximum stratum size: strataBudget - 2
        ! -> heavySamples = min(max(ceilling(strataBudget * (heavyStDv * heavyPopulation)/(stratumStDev)), minimum stratum size), maximum stratum size)
        ! -> lightSamples = min(max(ceilling(strataBudget * (lightStDv * lightPopulation)/(stratumStDev)), minimum stratum size), maximum stratum size)
        ! -> totalSamples = heavySamples + lightSamples
        ! stratumStDev = heavyCdf%stdv * real(heavyCdf%population, kind=c_double) + lightCdf%stdv * real(lightCdf%population, kind=c_double)
        ! strataBudget = real(totalSamples, kind=c_double)
        ! if (abs(heavyCdf%stdv) <= tolerance) then 
        !     heavySamples = 2
        ! else
        !     heavySamples = ceiling(real(strataBudget,kind=c_double)*heavyCdf%stdv*real(heavyCdf%population,kind=c_double)/stratumStDev)
        !     if (heavySamples < 2) heavySamples = 2
        !     if (heavySamples >= (strataBudget - 2)) heavySamples = strataBudget - 2
        ! end if
        ! if (abs(lightCdf%stdv) <= tolerance) then 
        !     lightSamples = 2
        ! else
        !     lightSamples = ceiling(real(strataBudget,kind=c_double)*lightCdf%stdv*real(lightCdf%population,kind=c_double)/stratumStDev)
        !     if (lightSamples < 2) lightSamples = 2
        !     if (lightSamples >= (strataBudget - 2)) lightSamples = strataBudget - 2
        ! end if
        ! totalSamples = heavySamples + lightSamples
        ! print *, ""
        ! print *, "neyman allocation"
        ! print *, "  -> stratumStDev = heavyStDv * heavyPopulation + lightStDv * lightPopulation"
        ! print *, "  -> strataBudget = ⌈a * total population⌉"
        ! print *, "  -> minimum stratum size: 2"
        ! print *, "  -> maximum stratum size: strataBudget - 2"
        ! print *, "  -> heavySamples = min(max(ceilling(strataBudget * (heavyStDv * heavyPopulation)/(stratumStDev)), minimum stratum size), maximum stratum size)"
        ! print *, "  -> lightSamples = min(max(ceilling(strataBudget * (lightStDv * lightPopulation)/(stratumStDev)), minimum stratum size), maximum stratum size)"
        ! print *, "  -> totalSamples = heavySamples + lightSamples"

        ! proportional sampling
        ! -> heavySamples = ⌈heavyPopulation * a⌉
        ! -> lightSamples = ⌈lightPopulation * a⌉
        ! -> totalSamples = heavySamples + lightSamples
        ! heavySamples = ceiling(real(heavyCdf%population,kind=c_double) * a)
        ! lightSamples = ceiling(real(lightCdf%population,kind=c_double) * a)
        ! totalSamples = heavySamples + lightSamples
        ! print *, ""
        ! print *, "proportional sampling"
        ! print *, "  -> heavySamples = ⌈heavyPopulation * a⌉"
        ! print *, "  -> lightSamples = ⌈lightPopulation * a⌉"
        ! print *, "  -> totalSamples = heavySamples + lightSamples"

        ! heavy-rounded proportional sampling
        ! -> totalSamples = ⌈a * total population⌉
        ! -> heavySamples = ⌈a * heavyPopulation⌉
        ! -> lightSamples = totalSamples - heavySamples
        ! heavySamples = ceiling(a * real(heavyCdf%population,kind=c_double))
        ! lightSamples = totalSamples - heavySamples
        ! print *, ""
        ! print *, "heavy-rounded proportional sampling"
        ! print *, "  -> totalSamples = ⌈a * total population⌉"
        ! print *, "  -> heavySamples = ⌈a * heavyPopulation⌉"
        ! print *, "  -> lightSamples = totalSamples - heavySamples"

        ! light-rounded proportional sampling
        ! -> totalSamples = ⌈a * total population⌉
        ! -> lightSamples = ⌈a * lightPopulation⌉
        ! -> heavySamples = totalSamples - lightSamples
        ! lightSamples = ceiling(a * real(lightCdf%population,kind=c_double))
        ! heavySamples = totalSamples - lightSamples
        ! print *, ""
        ! print *, "light-rounded proportional sampling"
        ! print *, "  -> totalSamples = ⌈a * total population⌉"
        ! print *, "  -> lightSamples = ⌈a * lightPopulation⌉"
        ! print *, "  -> heavySamples = totalSamples - lightSamples"

        ! mean-weighted sampling
        ! -> strataBudget = ⌈a * total population⌉
        ! -> sumStratMean = meanLight + meanHeavy
        ! -> heavySamples = ⌈meanHeavy/(sumStratMean) * strataBudget⌉
        ! -> lightSamples = ⌈meanLight/(sumStratMean) * strataBudget⌉
        ! -> totalSamples = heavySamples + lightSamples
        ! strataBudget = real(totalSamples, kind=c_double)
        ! sumStratMean = heavyCdf%mean + lightCdf%mean
        ! heavySamples = ceiling(heavyCdf%mean/sumStratMean * strataBudget)
        ! lightSamples = ceiling(lightCdf%mean/sumStratMean * strataBudget)
        ! totalSamples = heavySamples + lightSamples
        ! print *, ""
        ! print *, "mean-weighted sampling"
        ! print *, "  -> strataBudget = ⌈a * total population⌉"
        ! print *, "  -> sumStratMean = meanLight + meanHeavy"
        ! print *, "  -> heavySamples = ⌈meanHeavy/(sumStratMean) * strataBudget"
        ! print *, "  -> lightSamples = ⌈meanLight/(sumStratMean) * strataBudget⌉"
        ! print *, "  -> totalSamples = heavySamples + lightSamples"

        ! heavy-rounded mean-weighted sampling
        ! -> totalSamples = ⌈a * total population⌉
        ! -> sumStratMean = meanLight + meanHeavy
        ! -> heavySamples = ⌈meanHeavy/(sumStratMean) * totalSamples⌉
        ! -> lightSamples = totalSamples - heavySamples
        strataBudget = real(totalSamples, kind=c_double)
        sumStratMean = heavyCdf%mean + lightCdf%mean
        heavySamples = ceiling(heavyCdf%mean/sumStratMean * strataBudget)
        lightSamples = totalSamples - heavySamples
        print *, ""
        print *, "heavy-rounded mean-weighted sampling"
        print *, "  -> totalSamples = ⌈a * total population⌉"
        print *, "  -> sumStratMean = meanLight + meanHeavy"
        print *, "  -> heavySamples = ⌈meanHeavy/(sumStratMean) * totalSamples⌉"
        print *, "  -> lightSamples = totalSamples - heavySamples"


        ! light-rounded mean-weighted sampling
        ! -> totalSamples = ⌈a * total population⌉
        ! -> sumStratMean = meanLight + meanHeavy
        ! -> lightSamples = ⌈meanLight/(sumStratMean) * totalSamples⌉
        ! -> heavySamples = totalSamples - lightSamples
        ! strataBudget = real(totalSamples, kind=c_double)
        ! sumStratMean = heavyCdf%mean + lightCdf%mean
        ! lightSamples = ceiling(lightCdf%mean/sumStratMean * strataBudget)
        ! heavySamples = totalSamples - lightSamples
        ! print *, ""
        ! print *, "light-rounded mean-weighted sampling"
        ! print *, "  -> totalSamples = ⌈a * total population⌉"
        ! print *, "  -> sumStratMean = meanLight + meanHeavy"
        ! print *, "  -> lightSamples = ⌈meanLight/(sumStratMean) * totalSamples⌉"
        ! print *, "  -> heavySamples = totalSamples - lightSamples"
        
        print *, ""
        print *, "q value:         ", q
        print *, "advice param:    ", a
        print *, ""
        print *, "heavy samples:   ", heavySamples
        print *, "light samples:   ", lightSamples
        print *, ""
        print *, "heavy cdf size: ", heavyCdf%population
        print *, "heavy cdf mean: ", heavyCdf%mean
        print *, "heavy cdf stdv: ", heavyCdf%stdv
        print *, ""
        print *, "light cdf size: ", lightCdf%population
        print *, "light cdf mean: ", lightCdf%mean
        print *, "light cdf stdv: ", lightCdf%stdv

        ! allocate arrays
        allocate(sampleAtoms(totalSamples))
        allocate(sampleCoords(totalSamples))
        allocate(hansenHurwitz(totalSamples))

        ! sample 
        j = 0
        call sampleStratum(           &
                tolerance,            &
                heavySamples,         & 
                heavyCdf%atoms,       &
                sampleAtoms,          & 
                heavyCdf%coords,      & 
                sampleCoords,         &
                heavyCdf%culmProbs,   & 
                j,                    &
                hansenHurwitz         &
            )
        call sampleStratum(           &
                tolerance,            &
                lightSamples,         &
                lightCdf%atoms,       &
                sampleAtoms,          &
                lightCdf%coords,      &
                sampleCoords,         &
                lightCdf%culmProbs,   &
                j,                    &
                hansenHurwitz         &
            )
    
    ! special case; molecule is monatomic => weights are uniform
    ! however we still have to sample our coordinates!
    ! NOTE: this does not work properly! needs to be reworked, was causing segfaults
    ! else 
    !     lightCdf = k%light(q)
    !     j = 0
    !     call sampleStratum(           &
    !             tolerance,            &
    !             totalSamples,         &
    !             lightCdf%atoms,       &
    !             sampleAtoms,          &
    !             lightCdf%coords,      &
    !             sampleCoords,         &
    !             lightCdf%culmProbs,   &
    !             j,                    &
    !             hansenHurwitz         &
    !         )
    ! end if 
    es = stratEstContainer(sampleCoords, sampleAtoms, hansenHurwitz)
end function stratEstCalc


!> Use for resampling at each q value Assumes 
!! total number of q values is negligible in comparison to total number of atoms. 
!! 
!! @param[in] k Frequency distribution of atom types in molecule
!! @param[in] a Stratum size upper bound
!! @param[in] q Array of scattering vector magnitudes (Å⁻¹)
!!
!! @return parallel list of samples per q value 
function resample(k, a, q) result(samples)
    type(frequencies), intent(in)           :: k
    real(c_double),    intent(in)           :: q(:)
    real(c_double),    intent(in)           :: a
    type(stratEstContainer), allocatable    :: samples(:)
    integer                                 :: i
    allocate(samples(size(q)))
    do i = 1, size(q)
        samples(i) = stratEstCalc(k, a, q(i))
    end do
end function resample


!> Estimates the full SAXS intensity profile I(Q) using stratified sampling.
!! 
!! @param k  Frequency distribution of atom types in the molecule
!! @param q  Array of scattering vector magnitudes (Å⁻¹)
!! @param a  Stratum size upper bound
!!
!! @return   estimate type containing I(Q) values and timing info
function stratEst(k, q, a) result(intensityEstimate)
    
    ! input variables
    type(frequencies),       intent(in)   :: k
    real(c_double),          intent(in)   :: q(:)
    real(c_double),          intent(in)   :: a

    ! local variables
    real(c_double),          allocatable  :: intensity(:)
    complex(c_double),       allocatable  :: ff(:)
    type(stratEstContainer), allocatable  :: samples(:)
    type(stratEstContainer)               :: es
    type(estimate)                        :: intensityEstimate
    integer                               :: i, j, qIJ, sampleSize
    real(kind=real64)                     :: start, finish
    real(c_double)                        :: dst, est, qVal, val
    type(coord)                           :: coordI, coordJ
    
    ! start timer
    call cpu_time(start)
    
    !> sample only on first q
    es = stratEstCalc(k, a, q(1)) !> sample only on first q
    sampleSize = size(es%sampledAtoms)
    print *, "sampling type:   sample only first q value"

    !> resample for each q
    ! allocate(samples, source=resample(k, a, q)) !> resample for each q
    ! print *, "sampling type:     resample for each q"

    ! calculate intensities for each q value
    allocate(intensity(size(q)))
    
    ! calculate stratified sample
    do qIJ = 1, size(q)

        qVal = q(qIJ)
        ! es = samples(qIJ)
        ! sampleSize = size(es%sampledAtoms)

        ! recompute form factors for this q
        allocate(ff(sampleSize))
        
        do i = 1, sampleSize
            ff(i) = es%sampledAtoms(i)%formFactor(qVal)
        end do

        est = 0.0_c_double
        do i = 1, sampleSize

            ! diagonal contribution
            val = real(ff(i) * conjg(ff(i)), kind=c_double)
            val = val / (es%hansenHurwitz(i) ** 2)
            est = est + val
            
            ! non-diagonal contributions            
            do j = i + 1, sampleSize
                coordI = es%sampledCoords(i)%coord_
                coordJ = es%sampledCoords(j)%coord_
                dst = coordI%distCart(coordJ)
                
                ! estimator (val) is biased, so need to apply Hansen-Hurwitz correction
                val = 2.0_c_double * real(ff(i) * conjg(ff(j)), kind=c_double) * sinc(qVal * dst)
                val = val / (es%hansenHurwitz(i) * es%hansenHurwitz(j))

                ! add estimate
                est = est + val
            end do 
        end do
        intensity(qIJ) = est / real(k%nItems ** 2, kind=c_double)
        deallocate(ff)
    end do 

    ! stop timer
    call cpu_time(finish)

    ! output estimate, cleanup
    intensityEstimate = newIntensity(start, finish, q, intensity)
end function stratEst
