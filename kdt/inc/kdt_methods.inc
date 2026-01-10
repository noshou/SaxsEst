!> @brief Check if the tree is empty
!> @param[in] this The kdt instance
!> @return .true. if tree is empty, .false. otherwise
function get_status(this) result(res)
    class(kdt), intent(in) :: this
    logical :: res
    res = .not. allocated(this%root)
end function get_status

!> @brief Calculate form factor weights for each unique atom type
!> @param[in] this The kdt instance
!> @param[in] q The scattering vector magnitude
!> @return Array of complex form factor weights
function get_weights(this, q) result(list)
    class(kdt), intent(in) :: this
    real(c_double), intent(in) :: q
    complex(c_double), allocatable :: list(:)
    type(atom) :: atm
    integer :: i

    allocate(list(this%freq_dist%n_items))
    do i = 1, this%freq_dist%n_items
        atm = this%freq_dist%items(i)%atm
        list(i) = atm%form_factor(q)
    end do
end function get_weights

!> @brief Get frequency counts for each unique atom type
!> @param[in] this The kdt instance
!> @return Array of integer frequencies
function get_freqs(this) result(list)
    class(kdt), intent(in) :: this
    type(frequencies) :: freqs
    integer, allocatable :: list(:)
    integer :: i

    freqs = this%freq_dist
    allocate(list(freqs%n_items))
    do i = 1, freqs%n_items
        list(i) = freqs%items(i)%freq
    end do
end function get_freqs

!> @brief Get total number of atoms in the subtree
!> @param[in] this The kdt instance
!> @return Number of atoms
function get_size(this) result(n)
    class(kdt), intent(in) :: this
    integer :: n
    n = this%subtree_size
end function get_size

!> @brief Get number of unique atom types
!> @param[in] this The kdt instance
!> @return Number of unique atom types
function get_number_unique(this) result(n)
    class(kdt), intent(in) :: this
    integer :: n
    n = this%freq_dist%n_items
end function get_number_unique

!> @brief Get the atom stored at this node
!> @param[in] this The kdt instance
!> @return Array containing the node's atom
function get_atoms(this) result(atoms)
    class(kdt), intent(in) :: this
    type(atom), allocatable :: atoms(:)
    allocate(atoms(this%size()))
    atoms = this%atm
end function get_atoms