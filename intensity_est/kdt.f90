!> K-D tree implementation
module kdt
	
    use iso_fortran_env, only: real64
    use atoms_mod
    implicit none
    private

    ! public API 
    public :: kdt, hype, kdt_creator
    
    !> Abstract base type representing a hyperplane axis in 3D space
    type, abstract :: hype
    contains; procedure :: str => str_method 
    end type hype
    
    !> X-axis hyperplane
    type, extends(hype) :: X
    end type X
    
    !> Y-axis hyperplane
    type, extends(hype) :: Y
    end type Y
    
    !> Z-axis hyperplane
    type, extends(hype) :: Z
    end type Z

    !> K-D tree data structure (3 dimensions; X, Y, Z)
    type :: kdt  
        integer,    allocatable :: subtree_size
        type(node), allocatable :: root !< Root node of the tree (unallocated = empty tree)
        contains;   procedure   :: radial_search => radial_search_method
    end type kdt 

    !> K-D tree node
    !!
    !! Each node contains a point and partitions space along one axis
    type :: node 
        type(kdt),   allocatable :: rch !< Right child subtree (points >= pivot on axis)
        type(kdt),   allocatable :: lch !< Left child subtree (points < pivot on axis)
        type(atom),  allocatable :: atm !< The point/atom stored at this node
        class(hype), allocatable :: axs !< The axis this node splits on
    end type node
    
    contains

        !> Returns the hyperplane axis as a string
        !!
        !! @param this The hyperplane object
        !!
        !! @return Single character string: "x", "y", or "z"
        function str_method(this) result(plane)
            class(hype) :: this
            character(len=1) :: plane
            select type (this)
                type is (X); plane = "x"
                type is (Y); plane = "y"
                type is (Z); plane = "z"
            end select 
        end function str_method
        
        !> Sorts a bin of atoms using insertion sort
        !! Efficient for small arrays (< 20 elements)
        !!
        !! @param bin Array of atoms to sort (modified in place)
        !! @param axs Axis to sort along
        subroutine sort_bin(bin, axs)
            type(atom), intent(inout) :: bin(:)
            class(hype), intent(in) :: axs
            integer :: i, j
            type(atom) :: atom_i
            do i = 2, size(bin)
                atom_i = bin(i)
                j = i - 1
                do while (j >= 1 .and. bin(j)%cmp_axis(atom_i, axs%str()) > 0)
                    bin(j+1) = bin(j)
                    j = j - 1
                end do
                bin(j+1) = atom_i
            end do
        end subroutine sort_bin

        !> Takes the first n elements from an array
        !!
        !! @param n Number of elements to take
        !! @param atoms Source array
        !!
        !! @return New array containing first n elements
        function take(n, atoms) result(res)
            integer, intent(in) :: n
            type(atom), intent(in) :: atoms(:)
            type(atom) :: res(n)
            res = atoms(:n)
        end function take

        !> Drops the first n elements from an array
        !!
        !! @param n Number of elements to drop
        !! @param atoms Source array
        !!
        !! @return New array containing elements after the first n
        function drop(n, atoms) result(res)
            integer, intent(in) :: n
            type(atom), dimension(:), intent(in) :: atoms
            type(atom), dimension(size(atoms)-n) :: res
            res = atoms(n+1:)
        end function drop

        !> Finds the median of an array using median-of-medians algorithm
        !! Groups array into bins of size n, finds median of each bin,
        !! then recursively finds median of those medians.
        !!
        !! @param n Bin size (defaults to 5; don't change unless sure!)
        !! @param atoms Array of atoms to find median of
        !! @param axs Axis to compute median along
        !!
        !! @return The median atom
        recursive function median(n, atoms, axs) result(med)
            integer, intent(in) :: n
            type(atom), intent(in) :: atoms(:)
            class(hype), intent(in) :: axs
            type(atom) :: med
            type(atom), allocatable :: bin(:), medians(:), rest(:)
            integer :: idx, num_bins, i, bin_size
            
            if (size(atoms) <= n) then
                bin = atoms
                call sort_bin(bin, axs)
                med = bin((size(bin)+1)/2)
                return
            end if
            
            num_bins = (size(atoms) + n - 1) / n
            allocate(medians(num_bins))
            allocate(rest(size(atoms)))
            rest = atoms
            
            do i = 1, num_bins
                bin_size = min(n, size(rest))
                bin = take(bin_size, rest)
                call sort_bin(bin, axs)
                medians(i) = bin((size(bin)+1)/2)
                if (size(rest) > n) rest = drop(n, rest)
            end do
            
            med = median(n, medians, axs)
        end function median

        !> Checks if a K-D tree is empty
        !!
        !! @param t The K-D tree to check
        !!
        !! @return True if tree is empty, false otherwise
        function is_empty(t) result(res)
            type(kdt), intent(in) :: t
            logical :: res
            res = .not. allocated(t%root)
        end function is_empty

        !> Increments to the next axis in cycle
        !! Cycles through axes in order: X -> Y -> Z -> X -> ...
        !!
        !! @param cur_axs Current axis
        !!
        !! @return Next axis in the cycle
        function incr_axs(cur_axs) result(new_axs)
            class(hype), intent(in) :: cur_axs
            class(hype), allocatable :: new_axs
            select type (cur_axs)
                type is (X); allocate(Y :: new_axs)
                type is (Y); allocate(Z :: new_axs)
                type is (Z); allocate(X :: new_axs)
            end select 
        end function incr_axs

        !> Builds a balanced K-D tree from a list of atoms
        !! Uses median-of-medians for O(n log n) construction time.
        !! Tree alternates splitting axes at each level (X -> Y -> Z -> X...).
        !!
        !! @param atoms Array of atoms to build tree from
        !! @param axs Initial splitting axis (typically X)
        !! @param bin_size_opt Optional bin size for median algorithm (default: 5)
        !!
        !! @return Constructed K-D tree
        recursive function kdt_creator(atoms, axs, bin_size_opt) result(t)
            
            ! input variables
            type(atom), dimension(:), intent(in) :: atoms
            class(hype), intent(in) :: axs

            ! optional bin size of splitting (defaults to 5)
            integer, intent(in), optional :: bin_size_opt
            integer :: bin_size
            if (present(bin_size_opt)) then
                bin_size = bin_size_opt
            else 
                bin_size = 5
            end if 
            
            ! local variables
            type(kdt) :: t
            type(atom) :: pivot
            type(atom), allocatable :: left_tree(:)
            type(atom), allocatable :: right_tree(:)
            integer :: i, n, left_incr, right_incr
            
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
            
            ! build left subtree
            if (left_incr > 0) then 
                allocate(t%root%lch)
                t%root%lch = kdt_creator(left_tree(1:left_incr), incr_axs(axs))
            end if 
            
            ! build right subtree
            if (right_incr > 0) then 
                allocate(t%root%rch)
                t%root%rch = kdt_creator(right_tree(1:right_incr), incr_axs(axs))
            end if 
        end function kdt_creator
        
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
            real(real64), intent(in) :: r
            type(atom), allocatable :: res(:)
            type(atom), allocatable :: f(:)
            type(kdt), allocatable :: s(:)
            integer :: n_f, n_s
            type(node) :: curr_node
            class(hype), allocatable :: curr_hype
            type(atom) :: curr_atom
            type(kdt) :: near_kdt, far_kdt
            real(real64) :: plane_dist
            
            ! Initialize using tree size
            allocate(f(this%subtree_size))  
            allocate(s(this%subtree_size))  
            n_f = 0
            n_s = 0
            
            ! Push root to stack
            if (.not. is_empty(this)) then
                n_s = 1
                s(1) = this
            end if
            
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
end module kdt