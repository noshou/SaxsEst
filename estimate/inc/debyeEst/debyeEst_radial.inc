!> Calculates the scattering intensity I(Q) using the Debye scattering
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
!! @param q_vals    Q values to calculate I(Q); NOTE: assumed to be in valid range!
!!
!! @return          The time it took to run (nanoseconds) and
!!                  array of q vs I_real (intensity_estimate type)
function debyeEst_radial(atoms, q_vals) result(intensity_estimate)
    ! input parameters
    type(atom), dimension(:), intent(in) :: atoms
    real(c_double), dimension(:), intent(in) :: q_vals

    ! local variables
    real(c_double), dimension(:), allocatable :: intensity
    integer :: i, j, q_ij, n_atoms, n_q
    real(c_double) :: q_val

    ! timing variables
    integer :: start, finish
    real    :: rate

    ! output data
    type(estimate) :: intensity_estimate

    ! variables for loop
    type(atom) :: atom_i
    type(atom) :: atom_j
    complex(c_double) :: atom_i_ff
    complex(c_double) :: atom_j_ff
    real(c_double) :: radial_contrib ! sinc(|Q-dst|)/(|Q-dst)
    real(c_double) :: atomic_contrib ! ff_i * conj(ff_j)
    real(c_double) :: dst
    real(c_double) :: est            ! estimate of intensity at I(Q)

    ! initialize variables
    n_q = size(q_vals)
    n_atoms = size(atoms)

    ! allocate intensity array
    allocate(intensity(n_q))

    ! start timer, do pairwise calculations
    call system_clock(start, rate)


    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        est = 0

        do i = 1, n_atoms
            atom_i = atoms(i)
            atom_i_ff = atom_i%form_factor(q_val)

            do j = 1, n_atoms
                ! edge case: sin(x)/x is assumed to = 1,
                ! therefore, when i == j (ie: we are at the same atom)
                ! we add atom_i_ff * conjg(atom_i_ff)
                if (i == j) then
                    est = est + real(atom_i_ff * conjg(atom_i_ff), kind=c_double)
                else
                    atom_j = atoms(j)
                    atom_j_ff = atom_j%form_factor(q_val)
                    dst = q_val * abs(atom_i%dist_cart(atom_j))
                    ! turns out because of weird symmetry we can
                    ! ignore the complex part (since the summation over
                    ! all pairs is symmetric and therefore real)
                    atomic_contrib = real(atom_i_ff * conjg(atom_j_ff), kind=c_double)
                    radial_contrib = sinc(dst)
                    est = est + atomic_contrib * radial_contrib
                end if
            end do
        end do

        intensity(q_ij) = est
    end do

    ! stop timer
    call system_clock(finish)

    ! output results
    intensity_estimate = new_intensity(start, finish, rate, q_vals, intensity)

    ! clean up
    deallocate(intensity)
end function debyeEst_radial
