!> Calculates the scattering intensity I(Q) using the Debye scattering 
!! approximation where atoms j are within radius r of atom i.
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
!! The time complexity of the algorithm is O(m·k·n·log(n)) 
!! with worst case O(m·n²). M m is the number of Q values
!! iterated over, k is the average number of atoms queried in the radius,f
!! n is the number of atoms in the dataset,
!! and log(n) is the time it takes to query the kdt tree.
!! in the xyz file, 
!!
!! @param k         kdt tree
!! @param r         radius to search within
!! @param q_vals    Q values to calculate I(Q); NOTE: assumed to be in valid range!
!! @param n_q       Number of q values
!! @param name      Name of dataset
!!
!! @return          The time it took to run (nanoseconds) and
!!                  array of q vs I_real (intensity_estimate type)
function debeye_kdt(k, r, q_vals, n_q, name) result(intensity_estimate)

    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: r
    character(len=*), intent(in) :: name
    type(atom), dimension(:) :: atoms
    integer:: n_atoms
    real(c_double), dimension(n_q), intent(in) :: q_vals
    real(c_double), dimension(n_q) :: intensity
    integer :: i, j, q_ij
    real(c_double) :: q_val 

    ! timing variables
    integer(0_c_int) :: timing
    integer :: start, finish, rate

    ! output data
    type(estimate) :: intensity_estimate

    ! variables for loop
    type(atom), dimension(:) :: atoms_found ! atoms within search radius
    type(atom) :: atom_i
    type(atom) :: atom_j
    complex(c_double) :: atom_i_ff
    complex(c_double) :: atom_j_ff
    real(c_double) :: radial_contrib ! sinc(|Q-dst|)/(|Q-dst)
    real(c_double) :: atomic_contrib ! ff_i * conj(ff_j)
    real(c_double) :: dst
    real(c_double) :: est            ! estimate of intensity at I(Q) 

    ! start timer
    call system_clock(start, rate)
    n_atoms = k%size
    atoms = k%atoms
    norm = n_atoms ** 2

    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        est = 0
        do i = 1, n_atoms
            
            atom_i = atoms(i)
            atom_i_ff = atom_i%get_form_factor(q_val)
            
            ! do search, get list of atoms
            atoms_found = k%radial_search(atom_i, r)
            do j = 1, size(atoms_found)
                atom_j = atoms_found(j)
                atom_j_ff = atom_j%get_form_factor(q_val)
                dst = q_val * abs(atom_i%dist_cart(atom_j))
                atomic_contrib = real(atom_i_ff * conjg(atom_j_ff), kind=c_double)
                radial_contrib = sinc(dst)
                est = est + atomic_contrib * radial_contrib
            end do 

            ! since self is not picked up in radial search, 
            ! we add the case of atom_i_ff * conj(atom_i_ff)
            est = est + atom_i_ff * conjg(atom_i_ff)
        end do 
        intensity(q_ij) = est / norm
    end do

    ! stop timer
    call system_clock(finish)
    timing = (finish - start) / rate

    ! output estimate
    intensity_estimate = new_intensity(timing, q_vals, intensity, name)
end function debeye_kdt