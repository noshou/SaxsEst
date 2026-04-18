
!> Calculate form factor weights for each unique atom type
!> @param[in] this The frequencies instance
!> @param[in] q The scattering vector magnitude
!> 
!> @return Array of complex form factor weights
function getWeights(this, q) result(list)
    
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    ! local variables
    complex(c_double),  allocatable :: list(:)
    type(atom)                      :: atm
    integer                         :: i

    allocate(list(this%nUnique))
    do i = 1, this%nUnique
        atm = this%items(i)%atm
        list(i) = atm%formFactor(q)
    end do
end function getWeights

!> Get frequency counts for each unique atom type
!> @param[in] this The frequencies instance
!> 
!> @return Array of integer frequencies
function getFreqs(this) result(list)
    
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! local variables
    integer,            allocatable :: list(:)
    integer                         :: i

    allocate(list(this%nUnique))
    do i = 1, this%nUnique
        list(i) = this%items(i)%freq_
    end do
end function getFreqs

!> Returns the mean of the magnitudes of the weights for a given  
!> randomly selected weight is greater than a given weight's magnitude.
!> @param[in] this   The frequencies instance
!> @param[in] q      The q value
!> 
!> @return the mean
function getMean(this, q) result(mean)
    
    ! instance
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    
    ! local variables
    real(c_double)                  :: mean 
    integer                         :: i

    mean = 0.0_c_double
    do i = 1, this%nUnique
        mean = mean + real(this%items(i)%freq_,kind=c_double) * abs(this%items(i)%atm%formFactor(q))
    end do
    mean = mean / real(this%nItems, kind=c_double)
end function getMean

!> Computes the mean and standard deviation of the magnitudes of a cdf.
!! @param[inout] cdf_       CDF of complex form factor weights
!! @param[in]    cdfFreqs   Parallel list of frequencies
subroutine calcCdfMeanStDv(cdf_, cdfFreqs)
    type(cdf),      intent(inout) :: cdf_
    integer,        intent(in)    :: cdfFreqs(:)
    integer                       :: i
    real(c_double), parameter     :: tolerance = 1.0e-10_c_double

    ! calculate mean
    cdf_%mean = 0.0_c_double
    do i = 1, size(cdf_%weights)
        cdf_%mean = cdf_%mean + real(cdfFreqs(i), kind=c_double) * abs(cdf_%weights(i))
    end do
    cdf_%mean = cdf_%mean / real(sum(cdfFreqs), kind=c_double)

    ! calculate standard deviation
    cdf_%stdv = 0.0_c_double
    do i = 1, size(cdf_%weights)
        cdf_%stdv = cdf_%stdv + real(cdfFreqs(i), kind=c_double) * (abs(cdf_%weights(i)) - cdf_%mean) ** 2
    end do
    cdf_%stdv = sqrt(cdf_%stdv / real(cdf_%population - 1, kind=c_double))
    if (abs(cdf_%stdv) <= tolerance .or. ieee_is_nan(cdf_%stdv)) cdf_%stdv = 0.0_c_double
end subroutine calcCdfMeanStDv

!> Returns a CDF for atom types with form factor magnitude <= the mean.
!> Filters the frequency table into a "light" stratum containing atom
!> types whose form factor magnitude is at or below the mean. Used for
!>  stratified sampling where the light stratum is sampled less aggressively.
!> @param[in] this   The frequencies instance
!> @param[in] q      The q value
!> 
!> @return Allocated CDF for light stratum, with weights, cumulative probs, and coords
function getLight(this, q) result(cdf____)
    
    ! instance 
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    
    ! local variables
    type(cdf),          allocatable :: cdf____
    type(coordPtrList), allocatable :: coords_(:), cTmp(:)
    complex(c_double),  allocatable :: weights(:), wTmp(:)
    integer,            allocatable :: freqs__(:), fTmp(:)
    type(atom),         allocatable :: atoms__(:), aTmp(:)
    real(c_double)                  :: cmpThis, cmpThat
    integer                         :: i, j
    real(c_double),     parameter   :: tolerance = 1.0e-10_c_double

    cmpThis = this%mean(q)
    j = 0
    allocate(wTmp(this%nUnique))
    allocate(fTmp(this%nUnique))
    allocate(cTmp(this%nUnique))
    allocate(aTmp(this%nUnique))
    do i = 1, this%nUnique
        cmpThat = abs(this%items(i)%atm%formFactor(q))
        if (cmpThat - cmpThis <= tolerance) then
            j = j + 1
            wTmp(j) = this%items(i)%atm%formFactor(q)
            fTmp(j) = this%items(i)%freq_
            cTmp(j) = this%items(i)%coords
            aTmp(j) = this%items(i)%atm
        end if
    end do
    allocate(weights,    source = wTmp(1:j))
    allocate(freqs__,    source = fTmp(1:j))
    allocate(coords_,    source = cTmp(1:j))
    allocate(atoms__,    source = aTmp(1:j))
    allocate(cdf____,    source = buildCdf(weights, freqs__, coords_, atoms__))
end function getLight

!>  Returns a CDF for atom types with form factor magnitude > the mean.
!>  Filters the frequency table into a "heavy" stratum containing atom
!> types whose form factor magnitude exceeds the mean. For proteins,
!> this stratum is typically very small (e.g., metals, heavier atoms).
!> @param[in] this   The frequencies instance
!> @param[in] q      The q value
!>
!> Allocated CDF for heavy stratum if heavy atoms exist, unallocated otherwise
function getHeavy(this, q) result(cdf____)
    
    ! instance 
    class(frequencies), intent(in)  :: this
    
    ! input variable
    real(c_double),     intent(in)  :: q
    
    ! local variables
    type(cdf),          allocatable :: cdf____
    type(coordPtrList), allocatable :: coords_(:), cTmp(:)
    complex(c_double),  allocatable :: weights(:), wTmp(:)
    integer,            allocatable :: freqs__(:), fTmp(:)
    type(atom),         allocatable :: atoms__(:), aTmp(:)
    real(c_double)                  :: cmpThis, cmpThat
    integer                         :: i, j
    real(c_double),     parameter   :: tolerance = 1.0e-10_c_double

    cmpThis = this%mean(q)
    j = 0
    allocate(wTmp(this%nUnique))
    allocate(fTmp(this%nUnique))
    allocate(cTmp(this%nUnique))
    allocate(aTmp(this%nUnique))
    do i = 1, this%nUnique
        cmpThat = abs(this%items(i)%atm%formFactor(q))
        if (cmpThat - cmpThis > tolerance) then
            j = j + 1
            wTmp(j) = this%items(i)%atm%formFactor(q)
            fTmp(j) = this%items(i)%freq_
            cTmp(j) = this%items(i)%coords
            aTmp(j) = this%items(i)%atm
        end if
    end do
    if (j > 0) then
        allocate(weights,   source = wTmp(1:j))
        allocate(freqs__,   source = fTmp(1:j))
        allocate(coords_,   source = cTmp(1:j))
        allocate(atoms__,   source = aTmp(1:j))
        allocate(cdf____,   source = buildCdf(weights, freqs__, coords_, atoms__))
    end if
end function getHeavy

!> Constructs an ordered CDF from parallel arrays of weights, frequencies, and coordinates.
!> Computes discrete probabilities from frequency counts, sorts all parallel
!> arrays by ascending weight magnitude, then builds cumulative probabilities.
!> Uses a bubble sort since the number of unique atom types is typically very small.
!> @param[in] w Complex form factor weights per atom type
!> @param[in] f Integer frequency counts per atom type
!> @param[in] c Coordinate pointer lists per atom type
!> @param[in] a Array of input atoms  
!> 
!> @return CDF with weights, cumulative probabilities, coordinates, total population, mean, and std
function buildCdf(w, f, c, a) result(cdf_)
    
    ! input variables
    complex(c_double),  intent(in)  :: w(:) 
    integer,            intent(in)  :: f(:)
    type(coordPtrList), intent(in)  :: c(:) 
    type(atom),         intent(in)  :: a(:)

    ! local variables
    type(coordPtrList), allocatable :: coordsList(:)
    complex(c_double),  allocatable :: weights(:) 
    integer,            allocatable :: frequencies_(:)
    real(c_double),     allocatable :: probs(:), culmProbs(:)
    real(c_double),     parameter   :: tolerance = 1.0e-10_c_double
    type(cdf)                       :: cdf_
    complex(c_double)               :: wTmp
    real(c_double)                  :: pTmp, sizeReal, currPmf, mean
    type(coordPtrList)              :: cTmp
    integer                         :: i,j
    type(atom),         allocatable :: atoms(:)
    type(atom)                      :: aTmp


    ! calculate discrete probabilities
    allocate(coordsList,    source = c)
    allocate(weights,      source = w)
    allocate(frequencies_, source = f)
    allocate(probs(size(frequencies_)))
    allocate(culmProbs(size(frequencies_)))
    allocate(atoms, source = a)
    sizeReal = 0.0_c_double
    do i = 1, size(frequencies_)
        sizeReal = sizeReal + real(frequencies_(i), kind=c_double)
    end do
    do i = 1, size(frequencies_)
        probs(i) = real(frequencies_(i),kind=c_double) / sizeReal
    end do

    ! probabilities and weights are parallel but unordered
    ! cdf needs to be ordered from smallest -> largest magnitude
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
                aTmp = atoms(j)
                atoms(j) = atoms(j-1)
                atoms(j-1) = aTmp
            end if
        end do
    end do

    ! cdf is probability that a randomly selected value is leq
    ! than a given value. 
    culmProbs(1) = probs(1)
    do i = 2, size(weights)
        culmProbs(i) = culmProbs(i-1) + probs(i)
    end do 
    culmProbs(size(culmProbs)) = 1.0_c_double

    allocate(cdf_%weights,   source = weights)
    allocate(cdf_%atoms,     source = atoms)
    allocate(cdf_%culmProbs, source = culmProbs)
    allocate(cdf_%coords,    source = coordsList)
    cdf_%population = sum(frequencies_)
    call calcCdfMeanStDv(cdf_, frequencies_)
end function buildCdf