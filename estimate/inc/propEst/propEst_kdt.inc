!! Performs radius-based searches in the k-d tree for each provided Q value
!! and computes intensity estimates. Returns both the computation time and
!! the resulting intensity data as a function of Q.
!!
!! @param[in] k         K-d tree structure containing the data
!! @param[in] r         Search radius for nearest neighbor queries
!! @param[in] q_vals    Array of Q values to calculate I(Q) at (must be in valid range)
!! @param[in] a         Advice parameter for estimation (should be >= number of nodes)
!! @param[in] e         Epsilon parameter for accuracy control (must satisfy 0 < e < 1)
!! @param[in] c         Rounding mode flag: .true. for ceiling, .false. for floor
!!
!! @return              Returns a tuple containing:
!!                      - Execution time in nanoseconds (integer)
!!                      - Array of intensity_estimate type with Q vs I_real values
function propEst_kdt(k, r, q_vals, a, e, c) result(intensity_estimate)
    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: r
    real(c_double), intent(in) :: a  !< Advice parameter (>= # nodes)
    real(c_double), intent(in) :: e  !< Epsilon (0 < e < 1)
    logical, intent(in) :: c         !< Ceiling flag
    
    ! Local variables
    type(atom), dimension(:), allocatable :: atoms             
    integer :: n_atoms
    real(c_double), dimension(:), intent(in) :: q_vals
    real(c_double), dimension(:), allocatable :: intensity
    integer :: i, j, q_ij, n_q
    real(c_double) :: q_val 
    
    ! timing variables
    integer :: start, finish
    real    :: rate
    
    ! output data
    type(estimate) :: intensity_estimate
    
    ! variables for loop
    type(atom), dimension(:), allocatable :: atoms_found        
    type(atom) :: atom_i
    complex(c_double) :: atom_i_ff
    complex(c_double) :: w_est       ! proportional estimate of atomic form factors
    real(c_double) :: radial_contrib ! sinc(|Q-dst|)/(|Q-dst)
    real(c_double) :: atomic_contrib ! ff_i * w_est
    real(c_double) :: dst
    real(c_double) :: est            ! estimate of intensity at I(Q) 
    
    ! start timer, initialize
    call system_clock(start, rate)
    
    ! initialize local variables
    n_q = size(q_vals)
    n_atoms = k%size()
    allocate(atoms(n_atoms))
    allocate(intensity(n_q))                                   
    atoms = k%atoms()
    
    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        w_est = propEst(k, q_val, a, e, c)
        est = 0
        
        do i = 1, n_atoms
            atom_i = atoms(i)
            atom_i_ff = atom_i%form_factor(q_val)
            atomic_contrib = real(atom_i_ff * w_est, kind=c_double)
            
            ! do search, get list of atoms
            atoms_found = k%radial_search(atom_i, r)
            
            do j = 1, size(atoms_found)
                dst = q_val * abs(atom_i%dist_cart(atoms_found(j)))
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
    
    ! cleanup
    deallocate(atoms)
    
end function propEst_kdt
