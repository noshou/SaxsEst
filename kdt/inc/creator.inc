!> "real" private function
!! 
!! Function caches frequency so it needs to be reset 
!! across new function calls.
recursive function kdt_creator_method(atoms, axs, bin_size, reset) result(t)

    ! input variables
    type(atom), dimension(:), intent(in) :: atoms
    class(hype), intent(in) :: axs
    logical, intent(in) :: reset            
    integer, intent(in) :: bin_size

    ! local variables
    type(kdt) :: t
    type(atom) :: pivot
    type(atom), allocatable :: left_tree(:)
    type(atom), allocatable :: right_tree(:)
    integer :: i, j, n, left_incr, right_incr
    class(hype), allocatable :: next_axs, next_next_axs

    ! logic for refreshing/updating frequency
    type(frequencies), save :: freq
    if (reset) then
        if (allocated(freq%items)) deallocate(freq%items)
        freq%n_items = 0
    end if

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

    ! set next axis in cycle
    if (allocated(next_axs)) deallocate(next_axs)
    allocate(next_axs, source=incr_axs(axs))

    ! get pivot, sort into left sub tree (< root)
    ! and right subtree (>= root)
    ! note: since we have already pre-allocated for right/left sub trees,
    ! if either of the tree incrementors are 0 we deallocate the arrays :)
    pivot = median(bin_size, atoms, axs)
    do i = 1, size(atoms)

        ! since all atoms are unique 3D coords, if we encounter one with the exact
        ! same three coordinates we know it is the pivot so we skip it 
        if (atoms(i)%cmp_axis(pivot, axs%str()) == 0) then
            allocate(next_next_axs, source=incr_axs(next_axs))
            if (atoms(i)%cmp_axis(pivot, next_axs%str()) /= 0) then
                right_incr = right_incr + 1
                right_tree(right_incr) = atoms(i)
            else if (atoms(i)%cmp_axis(pivot, next_next_axs%str()) /= 0) then
                right_incr = right_incr + 1
                right_tree(right_incr) = atoms(i)
            end if  
            deallocate(next_next_axs)      
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
    call add_freq(freq, pivot%element)

    ! build left subtree
    if (left_incr > 0) then
        allocate(t%root%lch)
        t%root%lch = kdt_creator_method(left_tree(1:left_incr), next_axs, bin_size, .false.)
    end if

    ! build right subtree
    if (right_incr > 0) then
        allocate(t%root%rch)
        t%root%rch = kdt_creator_method(right_tree(1:right_incr), next_axs, bin_size, .false.)
    end if

    ! clean subtree arrays and next axis
    deallocate(left_tree)
    deallocate(right_tree)
    deallocate(next_axs)

    ! if root node, add frequency
    if (reset) then; t%freq_dist = freq; end if

end function kdt_creator_method

!> Builds a balanced K-D tree from a list of atoms
!! Uses median-of-medians for O(n log n) construction time.
!! Tree alternates splitting axes at each level (X -> Y -> Z -> X...).
!!
!! @param atoms Array of atoms to build tree from
!!
!! @return Constructed K-D tree
function kdt_creator(atoms) result(tree)
    type(atom), dimension(:), intent(in) :: atoms
    integer :: bin_size 
    type(atom), allocatable :: atms(:)
    type(kdt) :: tree
    class(hype), allocatable :: axs
    allocate(X :: axs)           
    bin_size = 5
    ! call kdt_creator_method
    tree = kdt_creator_method(atoms, axs, bin_size, .true.)

    ! add atoms to kdt
    allocate(atms, source=atoms)
    tree%atm = atms

end function kdt_creator