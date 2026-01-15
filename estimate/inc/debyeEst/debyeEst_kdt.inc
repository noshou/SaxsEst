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
!! iterated over, k is the average number of atoms queried in the radius,
!! n is the number of atoms in the dataset,
!! and log(n) is the time it takes to query the kdt tree.
!! in the xyz file, 
!!
!! @param k         kdt tree
!! @param r         radius to search within
!! @param q_vals    Q values to calculate I(Q); NOTE: assumed to be in valid range!
!!
!! @return          The time it took to run (nanoseconds) and
!!                  array of q vs I_real (intensity_estimate type)
function debyeEst_kdt(k, r, q_vals) result(intensity_estimate)
    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: r
    integer :: n_q                              
    real(c_double), dimension(:), intent(in) :: q_vals
    
    ! Local variables
    type(atom), dimension(:), allocatable :: atoms          
    integer :: n_atoms
    real(c_double), dimension(:), allocatable :: intensity  
    integer :: i, j, q_ij
    real(c_double) :: q_val 
    
    ! timing variables
    integer :: start, finish
    real    :: rate
    
    ! output data
    type(estimate) :: intensity_estimate
    
    ! variables for loop
    type(atom), dimension(:), allocatable :: atoms_found    
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
    
    ! initialize variables
    n_q = size(q_vals)
    n_atoms = k%size()
    allocate(atoms(n_atoms))                                
    allocate(intensity(n_q))                                
    atoms = k%atoms()
    
    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        est = 0
        
        do i = 1, n_atoms
            atom_i = atoms(i)
            atom_i_ff = atom_i%form_factor(q_val)
            
            ! do search, get list of atoms
            atoms_found = k%radial_search(atom_i, r)
            
            do j = 1, size(atoms_found)
                atom_j = atoms_found(j)
                atom_j_ff = atom_j%form_factor(q_val)
                dst = q_val * abs(atom_i%dist_cart(atom_j))
                atomic_contrib = real(atom_i_ff * conjg(atom_j_ff), kind=c_double)
                radial_contrib = sinc(dst)
                est = est + atomic_contrib * radial_contrib
            end do 
            
            ! since self is not picked up in radial search, 
            ! we add the case of atom_i_ff * conj(atom_i_ff)
            est = est + real(atom_i_ff * conjg(atom_i_ff), kind=c_double) 
        end do 
        
        intensity(q_ij) = est
    end do
    
    ! stop timer
    call system_clock(finish)
    
    ! output estimate
    intensity_estimate = new_intensity(start, finish, rate, q_vals, intensity)
    
    ! Clean up
    deallocate(atoms, intensity)                            
    
end function debyeEst_kdt
