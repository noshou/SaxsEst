!! @param[in] a      Advice parameter, should be >= number of nodes 
!! @param[in] e      Epsilon parameter, must satisfy 0 < epsilon < 1 
!! @param[in] c      Rounding flag: .true. for ceiling, .false. for floor (logical)
function prop_kdt(k, r, w, f, a, e, c) result(intensity_estimate)
    
    type(kdt), intent(in) :: k
    real(c_double), intent(in) :: r
    character(len=*), intent(in) :: name
    real(c_double), dimension(n_q) :: intensity
    integer :: i, j, q_ij
    real(c_double) :: q_val 
    logical, intent(in) :: c

    ! timing variables
    integer(0_c_int) :: timing
    integer :: start, finish, rate

    ! output data
    type(estimate) :: intensity_estimate

    ! variables for weight estimate
    complex(c_double) :: w_est
    complex(c_double), dimension(:) :: w
    integer, dimension(:) :: f
    real(c_double), intent(in) :: a
    real(c_double), intent(in) :: e
    

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
    
    ! get arrays for weights
    f = k%freqs
    w = k%weights


    ! calculate proportional weight estimate
    w_est = call prop_est(w,f,a,e,c)

    ! calculate scattering estimate
    do q_ij = 1, n_q 
        q_val = q_vals(q_ij)
        est = 0
        do i = 1, n_atoms
            atom_i = atoms(i)
            atom_i_ff = atom_i%get_form_factor(q_val)

            ! do search and get list of atoms
            atoms_found = k%radial_search(atom_i, r)
            

end function prop_kdt