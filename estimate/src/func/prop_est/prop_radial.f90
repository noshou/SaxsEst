!!
!! @param k         kdt tree
!! @param q_vals    Q values to calculate I(Q); NOTE: assumed to be in valid range!
!! @param n_q       Number of q values
!! @param[in] a      Advice parameter, should be >= number of nodes 
!! @param[in] e      Epsilon parameter, must satisfy 0 < epsilon < 1 
!! @param[in] c      Rounding flag: .true. for ceiling, .false. for floor (logical)
!! @param name      Name of dataset
!! @return          The time it took to run (nanoseconds) and
!!                  array of q vs I_real (intensity_estimate type)
function prop_radial(k, q_vals, n_q, a, e, c, name) result(intensity_estimate)
    type(kdt), intent(in) :: k
    character(len=*), intent(in) :: name
    integer, intent(in) :: n_q 
    real(c_double), intent(in) :: a  !< Advice parameter (>= # nodes)
    real(c_double), intent(in) :: e  !< Epsilon (0 < e < 1)
    logical, intent(in) :: c         !< Ceiling flag
    
    ! Local variables
    type(atom), dimension(:), allocatable :: atoms
    integer :: n_atoms
    real(c_double), dimension(:), intent(in) :: q_vals
    real(c_double), dimension(:), allocatable :: intensity
    real(c_double) :: norm
    integer :: i, j, q_ij
    real(c_double) :: q_val 
    
    ! timing variables
    integer(c_int) :: timing
    integer :: start, finish, rate
    
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
    
    n_atoms = k%size()
    allocate(atoms(n_atoms))
    allocate(intensity(n_q))
    atoms = k%atoms()
    norm = real(n_atoms ** 2, kind=c_double)
    
    do q_ij = 1, n_q
        q_val = q_vals(q_ij)
        
        ! get estimate of weight
        w_est = prop_est(k, q_val, a, e, c)
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
        
        intensity(q_ij) = est / norm
    end do
    
    ! stop timer
    call system_clock(finish)
    timing = int((finish - start) / rate, kind=c_int)
    
    ! output estimate
    intensity_estimate = new_intensity(timing, q_vals, intensity, name)
    
    ! cleanup
    deallocate(atoms, intensity)
    
end function prop_radial
