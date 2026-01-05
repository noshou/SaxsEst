subroutine add_freq(flist, n)
    type(frequencies), intent(inout) :: flist
    character(len=4), intent(in)  :: n
    integer :: i, found_idx, new_capacity
    logical :: found
    type(frequency), allocatable :: temp(:)
    type(coord) :: coords

    found = .false.
    found_idx = -1

    ! if atom already in frequencies, increment freq
    if (allocated(flist%items)) then
        do i=1, flist%n_items
            if (n == flist%items(i)%name) then
                found = .true.
                found_idx = i
                exit
            end if 
        end do 
    end if

    ! atom found; increment frequency
    if (found) then
        flist%items(found_idx)%freq = flist%items(found_idx)%freq + 1
        
    ! atom not found
    else

        ! if flist is empty, allocate ten empty positions
        if (.not. allocated(flist%items)) then
            allocate(flist%items(10))
            flist%n_items = 0

        ! check if we need to increase size of array
        ! first we allocate space for a temp list 
        ! which holds current size + 10 uninitialized spots.
        ! second we copy over flist's items into this temp 
        ! then deallocate flist items
        ! third we allocate flist items to temp's size 
        ! and copy over the values from temp; we then
        ! deallocate tmp
        else if (flist%n_items >= size(flist%items)) then
            new_capacity = size(flist%items) + 10
            allocate(temp(flist%n_items))
            temp = flist%items(1:flist%n_items)
            deallocate(flist%items)
            allocate(flist%items(new_capacity))
            flist%items(1:flist%n_items) = temp
            deallocate(temp)
        end if

        ! allocate new atom w/ dummy coordinate (since they not needed)
        coords%x=real(0.0, kind=c_double) 
        coords%y=real(0.0, kind=c_double)
        coords%z=real(0.0, kind=c_double)
        flist%items(flist%n_items+1)%atm  = create_atom(coords, n)
        flist%items(flist%n_items+1)%name = n
        flist%items(flist%n_items+1)%freq = 1
        flist%n_items = flist%n_items + 1
    end if 
end subroutine add_freq

!> Returns the hyperplane axis as a string
!!
!! @param this The hyperplane object
!!
!! @return Single character string: "x", "y", or "z"
pure function str_method(this) result(plane)
    class(hype), intent(in) :: this
    character(len=1) :: plane
    select type (this)
        type is (X); plane = "x"
        type is (Y); plane = "y"
        type is (Z); plane = "z"
    end select
end function str_method


!> Checks if a K-D tree is empty
!!
!! @param t The K-D tree to check
!!
!! @return True if tree is empty, false otherwise
function is_empty(t) result(res)
    type(kdt), intent(in) :: t
    logical :: res
    res = t%empty()
end function is_empty

!> Increments to the next axis in cycle
!! Cycles through axes in order: X -> Y -> Z -> X -> ...
!!
!! @param cur_axs Current axis
!!
!! @return Next axis in the cycle
pure function incr_axs(cur_axs) result(new_axs)
    class(hype), intent(in) :: cur_axs
    class(hype), allocatable :: new_axs
    select type (cur_axs)
        type is (X); allocate(Y :: new_axs)
        type is (Y); allocate(Z :: new_axs)
        type is (Z); allocate(X :: new_axs)
    end select
end function incr_axs
