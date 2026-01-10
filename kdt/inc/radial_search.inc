!> Performs search to find all atoms within a given radius of a
!!
!! Algorithm:
!! 1. Pop current node from stack
!!    - if null, skip to step 4
!!    - if ||atom - curr|| <= r, add node to found list
!! 2. Determine which child is "near" and which is "far"
!!    - If atom.axis < curr.axis, then left child is "near", right child is "far"
!!    - If atom.axis >= curr.axis, then right child is "near", left child is "far"
!! 3. Check if axis hyperplane intersects search region (sphere of radius r)
!!    - If |atom.axis - curr.axis| <= r: plane intersects sphere; push near and far
!!    - If |atom.axis - curr.axis| > r: plane does not intersect sphere; push near
!! 4. If stack is empty, return found list; otherwise goto step 1
!!
!! @param this The K-D tree to search
!! @param a The query atom (center of search sphere)
!! @param r The search radius
!!
!! @return Array of atoms within radius of a
function radial_search_method(this, a, r) result(res)
    
    ! input variables
    class(kdt), intent(in), target :: this
    type(atom), intent(in) :: a
    real(c_double), intent(in) :: r

    ! Wrapper type for pointer array (since pointers cannot be in array)
    type :: kdt_ptr; type(kdt), pointer :: p => null(); end type

    ! allocatable targets
    type(atom), allocatable :: f(:), res(:)
    type(kdt_ptr), allocatable :: s(:)
    class(hype), allocatable :: curr_hype

    ! pointers (not copies w/ allocatable; too mem intensive and corrupt prone)
    type(kdt), pointer :: curr_kdt, near_kdt, far_kdt
    
    ! local loop variables
    integer :: n_f, n_s
    type(atom) :: curr_atom
    real(c_double) :: plane_dist

    ! check if tree is allocated; if not, return empty list
    if (this%empty()) then
        allocate(res(0))
        return 
    end if

    ! Initialize
    allocate(f(this%subtree_size)) ! list of atoms found within radius
    allocate(s(this%subtree_size)) ! stack of atoms to search
    n_f = 0                        ! number of atoms found
    n_s = 1                        ! size of stack
    s(1)%p => this                 ! first element of stack should point to root

    ! Main loop - process stack until empty
    do while (n_s > 0)

        ! pop first node
        curr_kdt => s(n_s)%p
        n_s = n_s - 1
        allocate(curr_hype, source=curr_kdt%root%axs) ! allocate hyperplane axis
        curr_atom = curr_kdt%root%atm

        ! if ||a - curr|| <= r, add to found
        if (a%dist_cart(curr_atom) <= r) then
            n_f = n_f + 1
            f(n_f) = curr_atom
        end if

        ! ensure near_kdt/far_kdt are uninitialized
        nullify(near_kdt, far_kdt)

        ! if a.axis < curr.axis, left child is near, right is far
        ! else, left child is far, right child is near
        if (a%cmp_axis(curr_atom, curr_hype%str()) < 0) then
            if (allocated(curr_kdt%root%lch)) near_kdt => curr_kdt%root%lch
            if (allocated(curr_kdt%root%rch)) far_kdt  => curr_kdt%root%rch
        else
            if (allocated(curr_kdt%root%rch)) near_kdt => curr_kdt%root%rch
            if (allocated(curr_kdt%root%lch)) far_kdt  => curr_kdt%root%lch
        end if

        ! given a hyperplane (x,y, or z) we have to check
        ! if it intersects the search radius. if it does,
        ! we push near and far to the stack, and if it
        ! does not we just push near to the stack
        !
        ! we use a switch case since axs is polymorphic
        ! then we check |atom.axis - curr.axis| <= r
        select type (curr_hype)
            type is (X); plane_dist = abs(curr_atom%xyz%x - a%xyz%x)
            type is (Y); plane_dist = abs(curr_atom%xyz%y - a%xyz%y)
            type is (Z); plane_dist = abs(curr_atom%xyz%z - a%xyz%z)
        end select

        if (plane_dist <= r) then

            ! Push near child
            if (associated(near_kdt)) then
                if(.not. is_empty(near_kdt)) then
                    n_s = n_s + 1
                    s(n_s)%p => near_kdt
                end if
            end if

            ! Push far child
            if (associated(far_kdt)) then
                if (.not. is_empty(far_kdt)) then
                    n_s = n_s + 1
                    s(n_s)%p => far_kdt 
                end if
            end if
        else

            ! Only push near child
            if (associated(near_kdt)) then
                if (.not. is_empty(near_kdt)) then
                    n_s = n_s + 1
                    s(n_s)%p => near_kdt
                end if
            end if
        end if

        ! clean up allocated memory
        deallocate(curr_hype)
        
    end do

    ! base case; no more atoms to find
    if (n_f > 0) then
        allocate(res(n_f)) ! don't need whole of found array (contains unallocated garbage);
        res = f(1:n_f)     ! so we only return needed slice
    else
        allocate(res(0))   ! we found nothing; return empty list
    end if
    deallocate(f); deallocate(s)
end function radial_search_method
