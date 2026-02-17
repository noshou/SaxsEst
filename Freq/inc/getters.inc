!> @brief Calculate form factor weights for each unique atom type
!> @param[in] this The frequency instance
!> @param[in] q The scattering vector magnitude
!> @return Array of complex form factor weights
function getWeights(this, q) result(list)
    class(frequencies), intent(in) :: this
    real(c_double), intent(in) :: q
    complex(c_double), allocatable :: list(:)
    type(atom) :: atm
    integer :: i

    allocate(list(this%nUnique))
    do i = 1, this%nUnique
        atm = this%items(i)%atm
        list(i) = atm%formFactor(q)
    end do
end function getWeights

!> @brief Get frequency counts for each unique atom type
!> @param[in] this The frequency instance
!> @return Array of integer frequencies
function getFreqs(this) result(list)
    class(frequencies), intent(in) :: this
    integer, allocatable :: list(:)
    integer :: i

    allocate(list(this%nUnique))
    do i = 1, this%nUnique
        list(i) = this%items(i)%freq_
    end do
end function getFreqs

!> @brief Returns the probability of the magnitude of a 
!> randomly selected weight is equal (within a tolerance) to a given weight's magnitude
!> @param[in] this   The frequency instance
!> @param[in] weight The atom name
!> @param[in] q      The q value
!> @return 0 <= probability <= 1 is the cmf of the atom
function getProbabilityMassFunction(this, weight, q) result(probability)
    class(frequencies), intent(in) :: this
    complex(c_double), intent(in)  :: weight
    real(c_double), intent(in) :: q
    real(c_double)     :: cmpThis
    real(c_double)     :: cmpThat
    integer            :: i
    real(c_double)     :: probability
    real(c_double), parameter :: tolerance = 1.0e-10_c_double
    probability = 0.0_c_double
    cmpThis = real(abs(weight), kind=c_double)
    do i = 1, this%nUnique
        cmpThat = real(abs(this%items(i)%atm%formFactor(q)), kind=c_double)
        if (abs(cmpThis - cmpThat) <= tolerance) then
            probability = real(this%items(i)%freq_,kind=c_double) / real(this%nItems,kind=c_double)
            exit
        end if 
    end do
end function getProbabilityMassFunction

!> @brief Returns the probability of the magnitude of a 
!> randomly selected weight is not equal to a given weight's magnitude
!> @param[in] this   The frequency instance
!> @param[in] weight The atom name
!> @param[in] q      The q value
!> @return 0 <= probability <= 1 is the pmf of the atom
function getProbabilityMassFunctionCompliment(this, weight, q) result(probability)
    class(frequencies), intent(in) :: this
    complex(c_double), intent(in)  :: weight
    real(c_double), intent(in) :: q
    real(c_double)     :: cmpThis
    real(c_double)     :: probability
    real(c_double), parameter :: tolerance = 1.0e-10_c_double
    cmpThis = real(abs(weight), kind=c_double)
    probability = 1.0_c_double - getProbabilityMassFunction(this, weight, q)
    if (abs(probability - 1.0_c_double) <= tolerance) then
        probability = 1.0_c_double
    else if (abs(probability - 0.0_c_double) <= tolerance) then 
        probability = 0.0_c_double
    end if 
end function getProbabilityMassFunctionCompliment

!> @brief Returns the probability that the magnitude of a 
!> randomly selected weight is lesser than or equal to a given weight's magnitude
!> @param[in] this   The frequency instance
!> @param[in] weight The atom name
!> @param[in] q      The q value
!> @return 0 <= probability <= 1 is the compliment of the pmf of the atom
function getContinuousMassFunction(this, weight, q) result(probability)
    class(frequencies), intent(in) :: this
    complex(c_double), intent(in)  :: weight
    real(c_double), intent(in) :: q
    real(c_double)     :: cmpThis
    real(c_double)     :: cmpThat
    integer            :: i
    real(c_double)     :: probCalc
    real(c_double)     :: probability
    real(c_double), parameter :: tolerance = 1.0e-10_c_double
    probability = 0.0_c_double
    cmpThis = real(abs(weight), kind=c_double)
    do i = 1, this%nUnique
        cmpThat = real(abs(this%items(i)%atm%formFactor(q)), kind=c_double)
        if (cmpThat < cmpThis .or. (abs(cmpThis - cmpThat) <= tolerance)) then
            probCalc = real(this%items(i)%freq_,kind=c_double) / real(this%nItems,kind=c_double)
            probability = probability + probCalc
        end if 
    end do
end function getContinuousMassFunction

!> @brief Returns the probability that the magnitude of a 
!> randomly selected weight is greater than a given weight's magnitude.
!> Note: this does NOT return the probability that the magnitude of a 
!> randomly selected weight is greater than or equal; to get that 
!> add the pmf PLUS getCmfCmp
!> @param[in] this   The frequency instance
!> @param[in] weight The atom name
!> @param[in] q      The q value
!> @return 0 <= probability <= 1 is the compliment of the cmf of the atom
function getSurvivalFunction(this, weight, q) result(probability)
    class(frequencies), intent(in) :: this
    complex(c_double), intent(in)  :: weight
    real(c_double), intent(in) :: q
    real(c_double)     :: cmpThis
    real(c_double)     :: probCalc
    real(c_double)     :: probability
    real(c_double), parameter :: tolerance = 1.0e-10_c_double
    cmpThis = real(abs(weight), kind=c_double)
    probability = 1.0_c_double - getContinuousMassFunction(this, weight, q)
        if (abs(probability - 1.0_c_double) <= tolerance) then
        probability = 1.0_c_double
    else if (abs(probability - 0.0_c_double) <= tolerance) then 
        probability = 0.0_c_double
    end if 
end function getSurvivalFunction
