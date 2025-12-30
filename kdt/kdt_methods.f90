pure function get_status(this) result(res)
    class(kdt), intent(in) :: this
    logical :: res
    res = .not. allocated(this%root)
end function get_status

pure function get_weights(this) result(list)
    class(kdt), intent(in) :: this
    integer :: i
    complex(c_double), allocatable :: list
    allocate(list(this%n_items))
    do i = 1, this%freq_dist%n_items
        list(i) = this%freq_dist%items(i)%weight
    end do 
end function get_weights

pure function get_freqs(this) result(list)
    class(kdt), intent(in) :: this
    type(frequencies) :: freqs
    integer :: i
    integer, allocatable :: list
    freqs = this%freq_dist
    allocate(list(freqs%n_items))
    do i = 1, freqs%n_items
        list(i) = freqs%items(i)%freq
    end do
end function get_freqs

pure function get_size(this) result(n)
    class(kdt), intent(in) :: this
    integer :: n
    n = this%subtree_size
end function get_size

pure function get_atoms(this) result(atoms)
    class(kdt), intent(in) :: this
    type(atom), allocatable :: atoms
    allocate(atoms(this%subtree_size))
    atoms = this%atm
end function get_atoms
