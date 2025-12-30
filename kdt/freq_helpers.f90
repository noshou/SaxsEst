pure function weights(this) result(list)
    class(frequencies), intent(in) :: this
    integer :: i
    complex(c_double), allocatable :: list
    allocate(list(this%n_items))
    do i = 1, this%n_items
        list(i) = this%items(i)%weight
    end do 
end function weights

pure function as_list(this) result(list)
    class(frequencies), intent(in) :: this
    integer :: i
    integer, allocatable :: list
    allocate(list(this%n_items))
    do i = 1, this%n_items
        list(i) = this%items(i)%freq
    end do
end function as_list