!> Builds a balanced K-D tree from a list of atoms
!! Uses median-of-medians for O(n log n) construction time.
!! Tree alternates splitting axes at each level (X -> Y -> Z -> X...).
!!
!! @param atoms Array of atoms to build tree from
!!
!! @return Constructed K-D tree
function kdt_creator(atoms) result(t)
    type(atom), dimension(:), intent(in) :: atoms
    class(hype), allocatable :: axs; allocate(X :: axs)           
    integer :: bin_size; bin_size = 5
    type(atom), allocatable :: atms(:)
    type(kdt) :: t

    ! call kdt_creator_method
    t = kdt_creator_method(atoms, axs, bin_size, .true.)

    ! add atoms to kdt
    allocate(atms, source=atoms)
    t%atm = atms
end function kdt_creator

!> "real" private function
!! 
!! Function caches frequency so it needs to be reset 
!! across new function calls. Public API does not need it!
recursive function kdt_creator_method(atoms, axs, bin_size, reset) result(t)

    ! input variables
    type(atom), dimension(:), intent(in) :: atoms
    class(hype), intent(in) :: axs
    logical, intent(in) :: reset            
    integer, intent(in) :: bin_size

    ! logic for refreshing/updating frequency
    type(frequencies), save :: freq
    if (reset) then
        if (allocated(freq%items)) deallocate(freq%items)
        if (allocated(freq%names)) deallocate(freq%names)
        if (allocated(freq%probs)) deallocate(freq%probs)
        freq%n_items = 0
    end if

    ! local variables
    type(kdt) :: t
    type(atom) :: pivot
    type(atom), allocatable :: left_tree(:)
    type(atom), allocatable :: right_tree(:)
    integer :: i, j, n, left_incr, right_incr

    ! allocate arrays for right and left subtree;
    ! to be safe we just made it the size of atoms,
    ! so when left_tree/right_tree are actually used,
    ! we must ensure only slice in range 1:incr is used
    ! (since rest is uninitialized)
    allocate(left_tree(size(atoms)))
    allocate(right_tree(size(atoms)))
    n = size(atoms)
    left_incr = 0
    right_incr = 0

    ! get pivot, sort into left sub tree (< root)
    ! and right subtree (>= root)
    ! note: since we have already pre-allocated for right/left sub trees,
    ! if either of the tree incrementors are 0 we deallocate the arrays :)
    !! if one axis is >= pivot; if other axis
    !! are equivalent, discard; else add to right sub_tree
    pivot = median(bin_size, atoms, axs)
    do i = 1, size(atoms)
        if (atoms(i)%cmp_axis(pivot, axs%str()) == 0) then
            if (.not. atoms(i)%cmp_axis(pivot, incr_axs(axs)%str()) == 0) then
                if (.not. atoms(i)%cmp_axis(pivot, incr_axs(incr_axs(axs))%str()) == 0) then
                    right_incr = right_incr + 1
                    right_tree(right_incr) = atoms(i)
                end if
            end if
        else if (atoms(i)%cmp_axis(pivot, axs%str()) > 0) then
            right_incr = right_incr + 1
            right_tree(right_incr) = atoms(i)
        else
            left_incr = left_incr + 1
            left_tree(left_incr) = atoms(i)
        end if
    end do

    ! build current node
    allocate(t%root); allocate(t%subtree_size)
    allocate(t%root%atm, source=pivot); allocate(t%root%axs, source=axs)
    t%subtree_size = size(atoms)

    ! update frequency
    call add_freq(freq, pivot%form_factor, trim(pivot%element))

    ! build left subtree
    if (left_incr > 0) then
        allocate(t%root%lch)
        t%root%lch = kdt_creator_method(left_tree(1:left_incr), incr_axs(axs), bin_size, .false.)
    end if

    ! build right subtree
    if (right_incr > 0) then
        allocate(t%root%rch)
        t%root%rch = kdt_creator_method(right_tree(1:right_incr), incr_axs(axs), bin_size, .false.)
    end if

    ! clean subtree arrays
    deallocate(left_tree)
    deallocate(right_tree)

    ! add probabilities
    allocate(freq%probs(size(freq%items)))
    do j = 1, size(freq%items) 
        freq%probs(j) = real(freq%items(j)%freq, kind=c_double) / real(freq%n_items, kind=c_double)
    end do 

    ! if root node, add frequency
    if (reset) then; t%freq_dist = freq; end if

end function kdt_creator_method
