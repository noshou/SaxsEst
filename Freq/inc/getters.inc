! getters.inc
!> @brief Calculate form factor weights for each unique atom type
!> @param[in] this The frequencies instance
!> @param[in] q The scattering vector magnitude
!> @return Array of complex form factor weights
function getWeights(this, q) result(list)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    ! local variables
    complex(c_double),  allocatable :: list(:)
    type(atom)                      :: atm
    integer                         :: i
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    allocate(list(this%nUnique))
    do i = 1, this%nUnique
        atm = this%items(i)%atm
        list(i) = atm%formFactor(q)
    end do
end function getWeights

!> @brief Get frequency counts for each unique atom type
!> @param[in] this The frequencies instance
!> @return Array of integer frequencies
function getFreqs(this) result(list)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! local variables
    integer,            allocatable :: list(:)
    integer                         :: i
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    allocate(list(this%nUnique))
    do i = 1, this%nUnique
        list(i) = this%items(i)%freq_
    end do
end function getFreqs

!> @brief Returns the mean of the magnitudes of the weights for a given  
!> randomly selected weight is greater than a given weight's magnitude.
!> @param[in] this   The frequencies instance
!> @param[in] q      The q value
!> @return the mean
function getMean(this, q) result(mean)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    
    ! local variables
    real(c_double)                  :: mean 
    integer                         :: i
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    mean = 0.0_c_double
    do i = 1, this%nUnique
        mean = mean + real(this%items(i)%freq_,kind=c_double) * abs(this%items(i)%atm%formFactor(q))
    end do
    mean = mean / real(this%nItems, kind=c_double)
end function getMean

!> @brief Returns a CMF for atom types with form factor magnitude <= the mean.
!> @details Filters the frequency table into a "light" stratum containing atom
!>          types whose form factor magnitude is at or below the mean. Used for
!>          stratified sampling where the light stratum is sampled less aggressively.
!> @param[in] this   The frequencies instance
!> @param[in] q      The q value
!> @return Allocated CMF for light stratum, with weights, cumulative probs, and coords
function getLight(this, q) result(cmf_)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    
    ! local variables
    type(cmf),          allocatable :: cmf_
    type(coordPtrList), allocatable :: cTmp(:), coordsList(:)
    complex(c_double),  allocatable :: weights(:), wTmp(:)
    integer,            allocatable :: freqs__(:), fTmp(:)
    real(c_double)                  :: cmpThis, cmpThat
    integer                         :: i, j
    real(c_double),     parameter   :: tolerance = 1.0e-10_c_double
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    cmpThis = this%mean(q)
    j = 0
    allocate(wTmp(this%nUnique))
    allocate(fTmp(this%nUnique))
    allocate(cTmp(this%nUnique))
    do i = 1, this%nUnique
        cmpThat = abs(this%items(i)%atm%formFactor(q))
        if (cmpThat - cmpThis <= tolerance) then
            j = j + 1
            wTmp(j) = this%items(i)%atm%formFactor(q)
            fTmp(j) = this%items(i)%freq_
            cTmp(j) = this%items(i)%coords
        end if
    end do
    allocate(weights,    source = wTmp(1:j))
    allocate(freqs__,    source = fTmp(1:j))
    allocate(coordsList, source = cTmp(1:j))
    allocate(cmf_,       source = buildCmf(weights, freqs__, coordsList))
end function getLight

!> @brief Returns a CMF for atom types with form factor magnitude > the mean.
!> @details Filters the frequency table into a "heavy" stratum containing atom
!>          types whose form factor magnitude exceeds the mean. For proteins,
!>          this stratum is typically very small (e.g., metals, heavier atoms).
!>          Returns unallocated if no atom types exceed the mean.
!> @param[in] this   The frequencies instance
!> @param[in] q      The q value
!> @return Allocated CMF for heavy stratum if heavy atoms exist, unallocated otherwise
function getHeavy(this, q) result(cmf_)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! instance 
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    
    ! local variables
    type(cmf),          allocatable :: cmf_
    type(coordPtrList), allocatable :: cTmp(:), coordsList(:)
    complex(c_double),  allocatable :: weights(:), wTmp(:)
    integer,            allocatable :: freqs__(:), fTmp(:)
    real(c_double)                  :: cmpThis, cmpThat
    integer                         :: i, j
    real(c_double), parameter       :: tolerance = 1.0e-10_c_double
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    cmpThis = this%mean(q)
    j = 0
    allocate(wTmp(this%nUnique))
    allocate(fTmp(this%nUnique))
    allocate(cTmp(this%nUnique))
    do i = 1, this%nUnique
        cmpThat = abs(this%items(i)%atm%formFactor(q))
        if (cmpThat - cmpThis > tolerance) then
            j = j + 1
            wTmp(j) = this%items(i)%atm%formFactor(q)
            fTmp(j) = this%items(i)%freq_
            cTmp(j) = this%items(i)%coords
        end if
    end do
    if (j > 0) then
        allocate(weights,    source = wTmp(1:j))
        allocate(freqs__,    source = fTmp(1:j))
        allocate(coordsList, source = cTmp(1:j))
        allocate(cmf_,       source = buildCmf(weights, freqs__, coordsList))
    end if
end function getHeavy

!> @brief Constructs an ordered CMF from parallel arrays of weights, frequencies, and coordinates.
!> @details Computes discrete probabilities from frequency counts, sorts all parallel
!>          arrays by ascending weight magnitude, then builds cumulative probabilities.
!>          Uses a bubble sort since the number of unique atom types is typically very small.
!> @param[in] w  Complex form factor weights per atom type
!> @param[in] f  Integer frequency counts per atom type
!> @param[in] c  Coordinate pointer lists per atom type
!> @return CMF with sorted weights, cumulative probabilities, coordinates, and total population
function buildCmf(w, f, c) result(cmf_)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input variables
    complex(c_double),  intent(in)    :: w(:) 
    integer,            intent(in)    :: f(:)
    type(coordPtrList), intent(in)    :: c(:) 

    ! local variables
    type(coordPtrList), allocatable :: coordsList(:)
    complex(c_double),  allocatable :: weights(:) 
    integer,            allocatable :: frequencies_(:)
    real(c_double),     allocatable :: probs(:), culmProbs(:)
    real(c_double),     parameter   :: tolerance = 1.0e-10_c_double
    type(cmf)                       :: cmf_
    complex(c_double)               :: wTmp
    real(c_double)                  :: pTmp, sizeReal, currPmf
    type(coordPtrList)              :: cTmp
    integer                         :: i,j
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    ! calculate discrete probabilities
    allocate(coordsList,    source = c)
    allocate(weights,      source = w)
    allocate(frequencies_, source = f)
    allocate(probs(size(frequencies_)))
    allocate(culmProbs(size(frequencies_)))
    sizeReal = 0.0_c_double
    do i = 1, size(frequencies_)
        sizeReal = sizeReal + real(frequencies_(i), kind=c_double)
    end do
    do i = 1, size(frequencies_)
        probs(i) = real(frequencies_(i),kind=c_double) / sizeReal
    end do

    ! probabilities and weights are parallel but unordered
    ! cmf needs to be ordered from smallest -> largest magnitude
    do i = 1, size(weights)
        do j = 2, size(weights)
            if (abs(weights(j-1)) - abs(weights(j)) > tolerance) then 
                wTmp = weights(j)
                weights(j) = weights(j-1)
                weights(j-1) = wTmp
                pTmp = probs(j)
                probs(j) = probs(j-1)
                probs(j-1) = pTmp
                cTmp = coordsList(j)
                coordsList(j) = coordsList(j-1)
                coordsList(j-1) = cTmp
            end if
        end do
    end do

    ! cmf is probability that a randomly selected value is leq
    ! than a given value. pmf gives us the probability that it is 
    ! equal to a given value
    culmProbs(1) = probs(1)
    do i = 2, size(weights)
        culmProbs(i) = culmProbs(i-1) + probs(i)
    end do 
    culmProbs(size(culmProbs)) = 1.0_c_double

    allocate(cmf_%weights,   source = weights)
    allocate(cmf_%culmProbs, source = culmProbs)
    allocate(cmf_%coords,    source = coordsList)
    cmf_%population = sum(frequencies_)
    
end function buildCmf