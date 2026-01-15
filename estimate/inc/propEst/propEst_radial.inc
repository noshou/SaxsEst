!! Computes scattering intensity I(Q) for a given set of Q values using a radial
!! contribution method with proportional weight estimation. The intensity is calculated
!! using atomic form factors and pairwise distance contributions via the sinc function.
!!
!! The algorithm performs the following steps for each Q value:
!! 1. Estimates proportional weights using the propEst function
!! 2. Computes pairwise contributions: f_i * w_est * sinc(Q * r_ij) for all atom pairs
!! 3. Adds self-contribution: f_i * conj(f_i) for each atom
!! 4. Normalizes the total intensity by N^2 where N is the number of atoms
!!
!! The intensity calculation follows the form:
!! \f$ I(Q) = \frac{1}{N^2} \sum_{i=1}^{N} \sum_{j=1}^{N} f_i(Q) w_{est}(Q) \frac{\sin(Q r_{ij})}{Q r_{ij}} \f$
!!
!! @param[in] k         K-d tree structure containing atomic positions and data
!! @param[in] q_vals    Array of Q values at which to calculate intensity
!! @param[in] a         Advice parameter for weight estimation (should be >= number of nodes)
!! @param[in] e         Epsilon parameter for accuracy control (must satisfy 0 < e < 1)
!! @param[in] c         Rounding mode flag: .true. for ceiling, .false. for floor
!!
!! @return              intensity_estimate type containing:
!!                      - Execution time in nanoseconds
!!                      - Q values array
!!                      - Calculated intensity values I(Q)
function propEst_radial(k, q_vals, a, e, c) result(intensity_estimate)
    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: a  !< Advice parameter (>= # nodes)
    real(c_double), intent(in) :: e  !< Epsilon (0 < e < 1)
    logical, intent(in) :: c         !< Ceiling flag
    
    ! Local variables
    type(atom), dimension(:), allocatable :: atoms
    integer :: n_atoms, n_q
    real(c_double), dimension(:), intent(in) :: q_vals
    real(c_double), dimension(:), allocatable :: intensity
    integer :: i, j, q_ij
    real(c_double) :: q_val 
    
    ! timing variables
    integer :: start, finish
    real    :: rate
    
    ! output data
    type(estimate) :: intensity_estimate
    
    ! variables for loop
    type(atom) :: atom_i
    complex(c_double) :: atom_i_ff
    complex(c_double) :: w_est       ! proportional estimate of atomic form factors
    real(c_double) :: radial_contrib ! sinc(|Q-dst|)/(|Q-dst)
    real(c_double) :: atomic_contrib ! ff_i * w_est
    real(c_double) :: dst
    real(c_double) :: est            ! estimate of intensity at I(Q) 
    
    ! start timer, initialize
    call system_clock(start, rate)
    
    ! initialize variables
    n_q = size(q_vals)
    n_atoms = k%size()
    allocate(atoms(n_atoms))
    allocate(intensity(n_q))
    atoms = k%atoms()

    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        
        ! get estimate of weight
        w_est = propEst(k, q_val, a, e, c)
        est = 0
        
        do i = 1, n_atoms
            atom_i = atoms(i)
            atom_i_ff = atom_i%form_factor(q_val)
            atomic_contrib = real(atom_i_ff * w_est, kind=c_double)
            
            do j = 1, n_atoms
                if (j /= i) then 
                    dst = q_val * abs(atom_i%dist_cart(atoms(j)))
                    radial_contrib = sinc(dst)
                    est = est + atomic_contrib * radial_contrib
                else
                    ! since self is not picked up in radial search, 
                    ! we add the case of atom_i_ff * conj(atom_i_ff)
                    est = est + real(atom_i_ff * conjg(atom_i_ff), kind=c_double)  ! ✅ ADDED real()
                end if
            end do 
        end do 
        
        intensity(q_ij) = est
    end do
    
    ! stop timer
    call system_clock(finish)
    
    ! output estimate
    intensity_estimate = new_intensity(start, finish, rate, q_vals, intensity)
    
    ! cleanup
    deallocate(atoms, intensity)
    
end function propEst_radial
