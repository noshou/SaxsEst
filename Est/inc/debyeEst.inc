!> Calculates the scattering intensity I(Q) using the Debye scattering
!! Docstring needs updating (add normalization constant)
!! approximation
!!
!!     I(Q) = ∑ᵢ∑ⱼ fᵢ fⱼ* sinc(Q · ||rᵢ - rⱼ||)
!!
!! Where:
!!   - fᵢ     — form factor of atom i
!!   - fⱼ*    — complex conjugate of the form factor of atom j
!!   - rᵢ, rⱼ — positions of atoms i and j, respectively
!!   - Q      — scattering vector (in Å⁻¹)
!!   - sinc(x) = { 1           if x == 0
!!               { sin(x) / x  if x != 0
!!
!! The time complexity of the algorithm is O(m·n²) where m is
!! the number of Q values iterated over, and n is the number of atoms
!! in the xyz file.
!!
!! @param atoms     List of atom objects in molecule
!! @param qVals    Q values to calculate I(Q); NOTE: assumed to be in valid range!
!!
!! @return          The time it took to run (nanoseconds) and
!!                  array of q vs I_real (intensityEstimate type)
function debyeEst(atoms, qVals) result(intensityEstimate)
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! input parameters
    type(atom), intent(in)      :: atoms(:)
    real(c_double), intent(in)  :: qVals(:)
    
    ! local variables
    real(c_double), allocatable :: intensity(:)
    integer                     :: i, j, qIJ, nAtoms, nQVals
    real(c_double)              :: qVal
    
    ! timing variables
    integer                     :: start, finish
    real                        :: rate
    
    ! output data
    type(estimate)              :: intensityEstimate
    
    ! variables for loop
    type(atom)                  :: atomI
    type(atom)                  :: atomJ
    complex(c_double)           :: atomIFormFact
    complex(c_double)           :: atomJFormFact
    real(c_double)              :: radialContrib  ! sinc(|Q-dst|)/(|Q-dst)
    real(c_double)              :: atomicContrib  ! ff_i * conj(ff_j)
    real(c_double)              :: dst
    real(c_double)              :: est            ! estimate of intensity at I(Q)
    real(c_double)              :: norm
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    ! initialize variables
    nQVals = size(qVals)
    nAtoms = size(atoms)
    norm = nAtoms * nAtoms

    ! allocate intensity array
    allocate(intensity(nQVals))
    
    ! start timer, do pairwise calculations
    call system_clock(start, rate)
    do qIJ = 1, nQVals
        qVal = qVals(qIJ)
        est = 0.0_c_double
        
        do i = 1, nAtoms
            atomI = atoms(i)
            atomIFormFact = atomI%formFactor(qVal)
            
            do j = 1, nAtoms
                ! edge case: sin(x)/x is assumed to = 1,
                ! therefore, when i == j (ie: we are at the same atom)
                ! we add atomIFormFact * conjg(atomIFormFact)
                if (i == j) then
                    est = est + real(atomIFormFact * conjg(atomIFormFact), kind=c_double)
                else
                    atomJ = atoms(j)
                    atomJFormFact = atomJ%formFactor(qVal)
                    dst = qVal * abs(atomI%distCart(atomJ))
                    ! turns out because of weird symmetry we can
                    ! ignore the complex part (since the summation over
                    ! all pairs is symmetric and therefore real)
                    atomicContrib = real(atomIFormFact * conjg(atomJFormFact), kind=c_double)
                    radialContrib = sinc(dst)
                    est = est + atomicContrib * radialContrib
                end if
            end do
        end do
        
        intensity(qIJ) = est / norm
    end do
    ! stop timer
    call system_clock(finish)
    
    ! output results
    intensityEstimate = newIntensity(start, finish, rate, qVals, intensity)
    
    ! clean up
    deallocate(intensity)
end function debyeEst