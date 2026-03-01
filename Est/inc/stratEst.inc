!> @brief Samples atom types and coordinates from a stratum via inverse CDF.
!> @details Draws samples from the provided cumulative probability distribution,
!>          assigns the corresponding atom, and randomly selects
!>          a coordinate from that atom type's coordinate list. Designed to be
!>          called twice per sampling (once for heavy, once for light strata)
!>          with a shared counter j that tracks the write position.
!> @param[in]    tol        Tolerance for inverse CDF comparison
!> @param[in]    nSamples   Number of samples to draw from this stratum
!> @param[in]    atmInp     Atom types in this stratum
!> @param[inout] atmSmp     Output array of sampled atoms (shared across strata)
!> @param[in]    crdInp     Coordinate pointer lists per atom type in this stratum
!> @param[inout] crdSmp     Output array of sampled coordinate pointers (shared across strata)
!> @param[in]    probs      Cumulative probabilities for this stratum
!> @param[inout] j          Write position counter; caller must initialize to 0 before first stratum
subroutine sampleStratum(   &
        tol,                &
        nSamples,           &
        atmInp,             &
        atmSmp,             &
        crdInp,             & 
        crdSmp,             & 
        probs,              & 
        j                   &
    )

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variables
    real(c_double),     intent(in)    :: tol
    integer,            intent(in)    :: nSamples
    type(atom),         intent(in)    :: atmInp(:)
    real(c_double),     intent(in)    :: probs(:)
    type(coordPtrList), intent(in)    :: crdInp(:)

    ! output variables
    type(atom),         intent(inout) :: atmSmp(:)
    type(coordPtr),     intent(inout) :: crdSmp(:)

    ! shared counter
    integer,            intent(inout) :: j

    ! local variables
    real(c_double) :: u
    integer        :: i, m, idx
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    do i = 1, nSamples
        call random_number(u)
        do m = 1, size(atmInp)
            ! inverse sample atom type
            if ((probs(m) - u) >= tol) then 
                j = j + 1
                atmSmp(j) = atmInp(m)
                ! randomly select a coordinate
                call random_number(u)
                idx = floor(u * real(crdInp(m)%n)) + 1
                crdSmp(j) = crdInp(m)%ptrs(idx)
                exit
            end if 
        end do 
    end do 
end subroutine sampleStratum

!> @brief Computes the mean magnitude of a complex-valued form factor array.
!> @param[in] stratumArray  Array of complex form factor weights
!> @return Mean of the absolute values
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

! container for stratified sample
! type :: stratEstContainer
!     type(coordPtr),    allocatable :: sampledCoords(:)
!     type(atom),        allocatable :: sampledAtoms(:)
! end type stratEstContainer

!> @brief Gives a stratified sample for a given q.
!> @details Splits the frequency distribution into heavy and light strata based on
!>          mean form factor magnitude, then performs inverse CDF sampling biased
!>          toward the heavy stratum. Returns a container with sampled atoms and
!>          their corresponding coordinate pointers.
!> @param k  Frequency distribution of atom types in the molecule
!> @param e  Epsilon; sampling precision parameter, must be 0 < e < 1
!> @param c  Ceiling flag; if .true. use ceiling for sample sizes, else floor
!> @param a  Sampling proportion factor (scales with k%nItems)
!> @param q  Single scattering vector magnitude (Å⁻¹) used for stratification
!> @return   stratEstContainer with sampled atoms and coordinate pointers
function stratEstCalc(k, e, c, a, q) result(es)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variables
    type(frequencies), intent(in)  :: k
    real(c_double),    intent(in)  :: e, a, q
    logical,           intent(in)  :: c
    
    ! local variables
    type(cmf),         allocatable :: heavyCmf, lightCmf
    complex(c_double), allocatable :: heavy(:), light(:)
    type(atom),        allocatable :: sampleAtoms(:)
    type(coordPtr),    allocatable :: sampleCoords(:) 
    real(c_double),    parameter   :: tolerance = 1.0e-10_c_double
    type(stratEstContainer)        :: es
    integer                        :: j, lightSamples, heavySamples, totalSamples
    real(c_double)                 :: meanHeavy, meanLight, ratio
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! allocate space for sampled size
    if (c) then 
        totalSamples = ceiling(a * k%nItems)
    else 
        totalSamples = floor(a * k%nItems)
    end if
    allocate(sampleAtoms(totalSamples))
    allocate(sampleCoords(totalSamples))

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
        ratio =  (meanHeavy) / (meanHeavy + meanLight)
!                 * (e * real(lightCmf%population))      &
!                 / (e * real(lightCmf%population + heavyCmf%population))
        
        ! get number of light and heavy samples
        if (c) then 
            heavySamples = ceiling(ratio * totalSamples)
        else 
            heavySamples = floor(ratio * a)
        end if
        lightSamples = totalSamples - heavySamples

        ! sample 
        j = 0
        call sampleStratum(           &
                tolerance,            &
                heavySamples,         & 
                heavyCmf%atoms,       &
                sampleAtoms,          & 
                heavyCmf%coords,      & 
                sampleCoords,         &
                heavyCmf%culmProbs,   & 
                j                     &
            )
        call sampleStratum(           &
                tolerance,            &
                lightSamples,         &
                lightCmf%atoms,       &
                sampleAtoms,          &
                lightCmf%coords,      &
                sampleCoords,         &
                lightCmf%culmProbs,   &
                j                     &
            )

    ! special case; molecule is monatomic => weights are uniform
    ! however we still have to sample our coordinates!
    else 
        lightCmf = k%light(q)
        j = 0
        call sampleStratum(           &
                tolerance,            &
                totalSamples,         &
                lightCmf%atoms,       &
                sampleAtoms,          &
                lightCmf%coords,      &
                sampleCoords,         &
                lightCmf%culmProbs,   &
                j                     &
            )
    end if 
    es = stratEstContainer(sampleCoords, sampleAtoms)
end function stratEstCalc

!> @brief Estimates the full SAXS intensity profile I(Q) using stratified sampling.
!> @details Samples atoms once via stratEstCalc using q(1) for stratification,
!>          then recomputes form factors per q value while reusing the same
!>          sampled coordinates. For each q, computes pairwise sinc(q*d_ij)
!>          contributions weighted by form factor products f_i * conj(f_j).
!>          Normalizes by N² where N is the total atom count in the molecule.
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
    complex(c_double), allocatable  :: ff(:)
    type(stratEstContainer)         :: es
    type(coordPtr),    allocatable  :: sampledCoords(:)
    type(atom),        allocatable  :: sampledAtoms(:)
    type(estimate)                  :: intensityEstimate
    integer                         :: i, j, qIJ, start, finish, sampleSize
    real                            :: rate
    real(c_double)                  :: dst, est, qVal
    type(coord)                     :: coordI, coordJ
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    ! start timer
    call system_clock(start, rate)
    
    ! sample once using q(1) for stratification
    es = stratEstCalc(k, e, c, a, q(1))
    allocate(sampledCoords, source=es%sampledCoords)
    allocate(sampledAtoms,  source=es%sampledAtoms)
    sampleSize = size(sampledAtoms)
    allocate(ff(sampleSize))

    ! calculate intensities for each q value
    allocate(intensity(size(q)))
    do qIJ = 1, size(q)
        qVal = q(qIJ)

        ! recompute form factors for this q
        do i = 1, sampleSize
            ff(i) = sampledAtoms(i)%formFactor(qVal)
        end do

        ! pairwise contributions
        est = 0.0_c_double
        do i = 1, sampleSize
            do j = 1, sampleSize
                if (i /= j) then 
                    coordI = sampledCoords(i)%coord_
                    coordJ = sampledCoords(j)%coord_
                    dst = coordI%distCart(coordJ)
                    est = est + real(ff(i) * conjg(ff(j)), kind=c_double) * sinc(qVal * dst)
                else 
                    est = est + real(ff(i) * conjg(ff(i)), kind=c_double)
                end if 
            end do 
        end do
        intensity(qIJ) = est / (sampleSize ** 2)
    end do 

    ! stop timer
    call system_clock(finish)

    ! output estimate, cleanup
    intensityEstimate = newIntensity(start, finish, rate, q, intensity)
    deallocate(intensity)
    deallocate(ff)

end function stratEst
