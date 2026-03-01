! type :: stratEstContainer
!     type(atom), allocatable :: sampledAtoms(:)
!     real(c_double)          :: formFactorEstimate
! end type stratEstContainer

function calcStratumMean(stratumArray) result(mean)

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variable
    complex(c_double), intent(in) :: stratumArray(:)
    ! local variables
    real(c_double) :: mean
    integer        :: i 
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    mean = 0.0_c_double
    do i = 1, size(stratumArray)
        mean = mean + abs(stratumArray(i))
    end do
    mean = mean / real(size(stratumArray), kind=c_double)

end function calcStratumMean

!> @brief Samples atom types and coordinates from a stratum via inverse CDF.
!> @details Draws samples from the provided cumulative probability distribution,
!>          assigns the corresponding form factor weight, and randomly selects
!>          a coordinate from that atom type's coordinate list. Designed to be
!>          called twice per q value (once for heavy, once for light strata)
!>          with a shared counter j that tracks the write position into the
!>          output arrays.
!> @param[in]    tol     Tolerance for inverse CDF comparison
!> @param[in]    nSamples Number of samples to draw from this stratum
!> @param[in]    wtsInp  Form factor weights per atom type in this stratum
!> @param[inout] wtsSmp  Output array of sampled weights (shared across strata)
!> @param[in]    crdInp  Coordinate pointer lists per atom type in this stratum
!> @param[inout] crdSmp  Output array of sampled coordinate pointers (shared across strata)
!> @param[in]    probs   Cumulative probabilities for this stratum
!> @param[inout] j       Write position counter; caller must initialize to 0 before first stratum
subroutine sampleStratum(tol, nSamples, wtsInp, wtsSmp, crdInp, crdSmp, probs, j)

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variables
    real(c_double),     intent(in)    :: tol
    complex(c_double),  intent(in)    :: wtsInp(:)
    real(c_double),     intent(in)    :: probs(:)
    type(coordPtrList), intent(in)    :: crdInp(:)
    integer,            intent(in)    :: nSamples

    ! output variables
    complex(c_double),  intent(inout) :: wtsSmp(:)
    type(coordPtr),     intent(inout) :: crdSmp(:)

    ! shared counter
    integer,            intent(inout) :: j

    ! local variables
    real(c_double) :: u
    integer        :: i, m, idx
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    do i = 1, nSamples
        call random_number(u)
        do m = 1, size(wtsInp)
            ! inverse sample atom type
            if ((probs(m) - u) >= tol) then 
                j = j + 1
                wtsSmp(j) = wtsInp(m)
                ! randomly sample a coordinate from this atom type
                call random_number(u)
                idx = floor(u * real(crdInp(m)%n)) + 1
                crdSmp(j) = crdInp(m)%ptrs(idx)
                exit
            end if 
        end do
    end do 
end subroutine sampleStratum

!> @brief Calculates a single stratified estimate for a given q value.
!>
!> Splits the frequency distribution into heavy and light strata based on
!> mean form factor weight, then performs inverse CDF sampling biased toward
!> the heavy stratum. Returns a container with the sampled atoms and the
!> estimated form factor product.
!>
!> @param k  Frequency distribution of atom types in the molecule
!> @param e  Epsilon; sampling precision parameter, must be 0 < e < 1
!> @param c  Ceiling flag; if .true. use ceiling for sample sizes, else floor
!> @param a  Sampling proportion factor (scales with k%nItems)
!> @param q  Single scattering vector magnitude (Å⁻¹)
!> @return   stratEstContainer with sampled atoms and form factor estimate
function stratEstCalc(k, e, c, a, q) result(es)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variables
    type(frequencies), intent(in)  :: k
    real(c_double),    intent(in)  :: e, a, q
    logical,           intent(in)  :: c
    
    ! local variables
    type(cmf),         allocatable :: heavyCmf, lightCmf
    complex(c_double), allocatable :: heavy(:), light(:), samplesWeights(:)
    type(coordPtr),    allocatable :: sampleCoords(:) 
    real(c_double),    allocatable :: lightCulmProbs(:), heavyCulmProbs(:)
    real(c_double),    parameter   :: tolerance = 1.0e-10_c_double
    type(stratEstContainer)        :: es
    integer                        :: i, j, m, lightSamples, heavySamples
    complex(c_double)              :: wI, wJ
    real(c_double)                 :: w, u, meanHeavy, meanLight, ratio
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! allocate space for sampled size
    if (c) then 
        allocate(samplesWeights(ceiling(a*k%nItems)))
        allocate(sampleCoords(ceiling(a*k%nItems)))
    else 
        allocate(samplesWeights(floor(a*k%nItems)))
        allocate(sampleCoords(floor(a*k%nItems)))
    end if

    ! sample total of a atoms
    heavyCmf = k%heavy(q)
    if (allocated(heavyCmf)) then
        allocate(heavy, source=heavyCmf%weights)
        meanHeavy = calcStratumMean(heavy)

        ! light strata is <= mean
        lightCmf = k%light(q)
        allocate(light, source=lightCmf%weights)
        meanLight = calcStratumMean(light) 

        ! calculate ratio of heavy vs light mean (biased towards heavy)
        ratio = (meanHeavy)/(meanHeavy + meanLight) &
                * (e * real(lightCmf%population)) &
                / (real(lightCmf%population + heavyCmf%population)) 
        
        ! get number of light and heavy samplesWeights
        if (c) then 
            heavySamples = ceiling(ratio*size(samplesWeights))
        else 
            heavySamples = floor(ratio*a)
        end if
        lightSamples = size(samplesWeights) - heavySamples

        ! sample 
        j = 0
        call sampleStratum(
            tolerance,            & 
            heavySamples,         &
            heavy,                &
            samplesWeights,       & 
            heavyCmf%coords,      & 
            sampleCoords,         &
            heavyCmf%culmProbs,   & 
            j)
        call sampleStratum(
            tolerance,            &
            lightSamples,         &
            light,                &
            samplesWeights,       &
            lightCmf%coords,      &
            sampleCoords,         &
            lightCmf%culmProbs,   &
            j)

    ! special case; molecule is monatomic => weights are uniform
    ! however we still have to sample our coordinates!
    else 
        lightCmf = k%light(q)
        allocate(light, source=lightCmf%weights)
        j = 0
        call sampleStratum(
            tolerance,            &
            size(samplesWeights), &
            light,                &
            samplesWeights,       &
            lightCmf%coords,      &
            sampleCoords,         &
            lightCmf%culmProbs,   &
            j)
    end if 

    ! calculate the estimated weight
    w = real(0.0_c_double, kind=c_double)
    do i = 1, size(samplesWeights)
        wI = samplesWeights(i)
        do j = 1, size(samplesWeights)
            wJ = samplesWeights(j)
            w = w + real(wI * conjg(wJ), kind=c_double)
        end do
    end do 
    es = stratEstContainer(
        sampledWeights     = samplesWeights, & 
        sampledCoords      = samplesCoords,   & 
        formFactorEstimate = w)
end function stratEstCalc

!> @brief Estimates the full SAXS intensity profile I(Q) using stratified sampling.
!>
!> For each q value, draws a stratified sample via stratEstCalc, then computes
!> pairwise distance contributions using sinc(q*d_ij) weighted by the estimated
!> form factor product. Normalizes by the squared sample size.
!>
!> @param k  Frequency distribution of atom types in the molecule
!> @param q  Array of scattering vector magnitudes (Å⁻¹)
!> @param e  Epsilon; sampling precision parameter, must be 0 < e < 1
!> @param c  Ceiling flag; if .true. use ceiling for sample sizes, else floor
!> @param a  Sampling proportion factor
!> @return   estimate type containing I(Q) values and timing info
function stratEst(k, q, e, c, a) result(intensityEstimate)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variables
    type(frequencies), intent(in)   :: k
    real(c_double),    intent(in)   :: q(:)
    real(c_double),    intent(in)   :: e 
    logical,           intent(in)   :: c
    real(c_double),    intent(in)   :: a

    ! local variables
    real(c_double),    allocatable  :: intensity(:)
    type(stratEstContainer)         :: es
    type(estimate)                  :: intensityEstimate
    integer                         :: i, j, qIJ, start, finish, sampleSize
    real                            :: rate
    real(c_double)                  :: w, dst, est, radialContrib, qVal
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! start timer
    call system_clock(start, rate)
    
    ! calculate intensities for each q value
    allocate(intensity(size(q)))
    do qIJ = 1, size(q)
        qVal = q(qIJ)
        es = stratEstCalc(k, e, c, a, qVal)
        sampleSize = size(es%sampledWeights)
        est = 0.0_c_double
        do i = 1, sampleSize
            do j = 1, sampleSize
                if (i /= j) then
                    dst = es%sampledCoords(i)%coord_%distCart(es%sampledCoords(j)%coord_)
                    radialContrib = sinc(qVal * dst)
                    est = est + es%formFactorEstimate * radialContrib
                else 
                    est = est + es%formFactorEstimate
                end if
            end do 
        end do
        intensity(qIJ) = est/(sampleSize ** 2)
    end do 

    ! stop timer
    call system_clock(finish)

    ! output estimate, cleanup
    intensityEstimate = newIntensity(start, finish, rate, q, intensity)
    deallocate(intensity)

end function stratEst