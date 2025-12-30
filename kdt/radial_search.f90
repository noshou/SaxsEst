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
    class(kdt), intent(in) :: this
    type(atom), intent(in) :: a
    real(c_double), intent(in) :: r
    type(atom), allocatable :: res(:)
    type(atom), allocatable :: f(:)
    type(kdt), allocatable :: s(:)
    integer :: n_f, n_s
    type(node) :: curr_node
    class(hype), allocatable :: curr_hype
    type(atom) :: curr_atom
    type(kdt) :: near_kdt, far_kdt
    real(c_double) :: plane_dist

    ! check if tree is allocated; if not, return empty list
    if (this%empty()) then
        allocate(res(0))
        return 
    end if

    ! Initialize using tree size
    allocate(f(this%subtree_size))
    allocate(s(this%subtree_size))
    n_f = 0
    n_s = 1
    s(1) = this

    ! Main loop - process stack until empty
    do while (n_s > 0)

        ! pop first node
        curr_node = s(n_s)%root
        n_s = n_s - 1
        allocate(curr_hype, source=curr_node%axs)
        curr_atom = curr_node%atm

        ! if ||a - curr|| <= r, add to found
        if (a%dist_cart(curr_atom) <= r) then
            n_f = n_f + 1
            f(n_f) = curr_atom
        end if

        ! if a.axis < curr.axis, left child is near, right is far
        ! else, left child is far, right child is near
        if (a%cmp_axis(curr_atom, curr_hype%str()) < 0) then
            near_kdt = curr_node%lch
            far_kdt = curr_node%rch
        else
            near_kdt = curr_node%rch
            far_kdt = curr_node%lch
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
            if (.not. is_empty(near_kdt)) then
                n_s = n_s + 1
                s(n_s) = near_kdt
            end if

            ! Push far child
            if (.not. is_empty(far_kdt)) then
                n_s = n_s + 1
                s(n_s) = far_kdt
            end if
        else

            ! Only push near child
            if (.not. is_empty(near_kdt)) then
                n_s = n_s + 1
                s(n_s) = near_kdt
            end if
        end if

        deallocate(curr_hype)
    end do

    ! base case; no more atoms to find
    if (n_f > 0) then
        allocate(res(n_f))
        res = f(1:n_f)
    else
        allocate(res(0))
    end if
    deallocate(f); deallocate(s)
end function radial_search_method
