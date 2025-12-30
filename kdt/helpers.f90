!> Adds and/or grows the frequency list
subroutine add_freq(flist, w, n)
    type(frequencies), intent(inout) :: flist
    real(c_double), intent(in) :: w
    character(len=4), intent(in) :: n
    integer :: i, found_idx
    logical :: found
    type(frequency), allocatable    :: temp(:)
    character(len=4), allocatable   :: temp_names(:)
    integer :: new_capacity
    found = .false.
    found_idx = -1

    ! Check if item is already in frequency list
    if (allocated(flist%items)) then
        do i = 1, flist%n_items
            if (n == flist%names(i)) then 
                found = .true.
                found_idx = i
                exit  ! Stop searching once found
            end if 
        end do 
    end if            ! check if item is already in frequency list
    
    if (found) then 
        flist%items(found_idx)%freq = flist%items(found_idx)%freq + 1 
    else 
        ! Item doesn't exist - need to add it
        if (.not. allocated(flist%items)) then
            ! First allocation
            allocate(flist%items(10))
            allocate(flist%names(10))
            flist%n_items = 0
        else if (flist%n_items >= size(flist%items)) then
            ! Need more space - double capacity
            new_capacity = size(flist%items) * 2

            ! Reallocate items array
            allocate(temp(flist%n_items))
            temp = flist%items(1:flist%n_items)
            deallocate(flist%items)
            allocate(flist%items(new_capacity))
            flist%items(1:flist%n_items) = temp
            deallocate(temp)

            ! Reallocate names array
            allocate(temp_names(flist%n_items))
            temp_names = flist%names(1:flist%n_items)
            deallocate(flist%names)
            allocate(flist%names(new_capacity))
            flist%names(1:flist%n_items) = temp_names
            deallocate(temp_names)
        end if
        
            ! Add new item
            flist%n_items = flist%n_items + 1
            flist%items(flist%n_items)%weight = w
            flist%items(flist%n_items)%freq = 1  ! New item starts with freq=1
            flist%names(flist%n_items) = n
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
pure function is_empty(t) result(res)
    type(kdt), intent(in) :: t
    logical :: res
    res = t%empty
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
