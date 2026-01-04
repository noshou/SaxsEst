function get_status(this) result(res)
    class(kdt), intent(in) :: this
    logical :: res
    res = .not. allocated(this%root)
end function get_status

function get_weights(this, q) result(list)
    class(kdt), intent(in) :: this
    integer :: i
    real(c_double), intent(in) :: q
    complex(c_double), allocatable :: list(:)
    type(atom) :: atm
    allocate(list(this%freq_dist%n_items))
    do i = 1, this%size()
        atm = this%freq_dist%items(i)%atm
        list(i) = atm%form_factor(q)
    end do 
end function get_weights

function get_freqs(this) result(list)
    class(kdt), intent(in) :: this
    type(frequencies) :: freqs
    integer :: i
    integer, allocatable :: list(:)
    freqs = this%freq_dist
    allocate(list(freqs%n_items))
    do i = 1, freqs%n_items
        list(i) = freqs%items(i)%freq
    end do
end function get_freqs

function get_size(this) result(n)
    class(kdt), intent(in) :: this
    integer :: n
    n = this%subtree_size
end function get_size

function get_number_unique(this) result(n)
    class(kdt), intent(in) :: this
    integer :: n
    n = this%freq_dist%n_items
end function get_number_unique

function get_atoms(this) result(atoms)
    class(kdt), intent(in) :: this
    type(atom), allocatable :: atoms(:)
    allocate(atoms(this%subtree_size))
    atoms = this%atm
end function get_atoms
