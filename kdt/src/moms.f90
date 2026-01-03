!! Functions for median-of-median algorithm

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
    integer :: num_bins, i, bin_size

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
