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
!! @param n_atoms   Number of atoms
!! @param norm      Normalization constant (I_real = I_calc/norm)
!! @param q_vals    Q values to calculate I(Q); NOTE: assumed to be in valid range!
!! @param n_q       Number of q values
!! @param name      Name of dataset
!!
!! @return          The time it took to run (nanoseconds) and
!!                  array of q vs I_real (intensity_estimate type)
function debeye_radial(atoms, n_atoms, norm, q_vals, n_q, name) result(intensity_estimate)

    ! set arrays
    character(len=*), intent(in) :: name
    type(atom), dimension(:), intent(in) :: atoms
    integer, intent(in) :: n_atoms
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
    type(atom) :: atom_i
    type(atom) :: atom_j
    complex(c_double) :: atom_i_ff
    complex(c_double) :: atom_j_ff
    real(c_double) :: radial_contrib ! sinc(|Q-dst|)/(|Q-dst)
    real(c_double) :: atomic_contrib ! ff_i * conj(ff_j)
    real(c_double) :: dst
    real(c_double) :: est            ! estimate of intensity at I(Q) 

    ! start timer, do pairwise calculations
    call system_clock(start, rate)
        
    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        est = 0
        do i = 1, n_atoms
            atom_i = atoms(i)
            atom_i_ff = atom_i%get_form_factor(q_val)
            
            do j = 1, n_atoms    
                
                ! edge case: sin(x)/x is assumed to = 1,
                ! therefore, when i == j (ie: we are at the same atom)
                ! we add atom_i_ff * conjg(atom_i_ff)
                if (i == j) then 
                    est = est + atom_i_ff * conjg(atom_i_ff)
                else 
                    atom_j = atoms(j)
                    atom_j_ff = atom_j%get_form_factor(q_val)
                    dst = q_val * abs(atom_i%dist_cart(atom_j))

                    ! turns out because of weird symmetry we can 
                    ! ignore the complex part (since the summation over
                    ! all pairs is symmetric and therefore real)
                    atomic_contrib = real(atom_i_ff * conjg(atom_j_ff), kind=c_double)
                    radial_contrib = sinc(dst) / dst

                    est = est + atomic_contrib * radial_contrib
                end if 
            end do
        end do
        intensity(q_ij) = est / norm
    end do 
    
    ! stop timer
    call system_clock(finish)
    timing = (finish - start) / rate
    
    ! output results
    intensity_estimate = new_intensity(timing, q_vals, intensity, name)

end function debeye_radial
