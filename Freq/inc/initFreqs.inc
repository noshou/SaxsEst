!> @brief Doubles the capacity of a coordPtrList, preserving existing pointer associations.
!> @param[inout] cl  The coordPtrList to grow
subroutine growPtrList(cl)
    type(coordPtrList), intent(inout) :: cl
    type(coordPtr), allocatable :: tmp(:)
    integer :: oldSize
    oldSize = size(cl%ptrs)
    allocate(tmp(oldSize * 2))
    tmp(1:oldSize) = cl%ptrs
    call move_alloc(tmp, cl%ptrs)
end subroutine growPtrList

!> @brief Creates a frequency table of unique atom types from an atom array.
!> @details Uses a perfect hash map with O(n) construction. Builds parallel
!>          arrays for counts, representative atoms, and coordinate pointer lists,
!>          then compacts into a frequencies object with no empty slots.
!> @param[in] atoms  Array of atoms to tabulate
!> @return Allocated frequencies object with unique atom types, counts, and coordinates
!! Creates a frequency table of unique atom types from an array of atoms in O(n) time.
!!
!! Algorithm:
!!   Uses a perfect hash map to count occurrences of each unique atom/ion type.
!!   Atom names can take the forms: a, aa, a#+, aa#+, a#-, aa#- (where a is a 
!!   lowercase letter and # is a digit 1-9).
!!
!! Hash function:
!!   - Single letter (e.g. "c"):       hash = ichar(c1)
!!   - Two letters (e.g. "fe"):        hash = ichar(c1) + ichar(c2) * 97
!!   - With charge (e.g. "fe2+"):      hash = ichar(c1) + ichar(c2) * 97  + sum(ichar(charge_chars)) * 122
!!   - Single + charge (e.g. "s2+"):   hash = ichar(c1) + sum(ichar(charge_chars)) * 122
!!
!!   Multiplying the second character by ichar('a')=97 separates the two-letter
!!   namespace from the single-letter one. Multiplying the charge sum by 
!!   ichar('z')=122 separates charged elements from uncharged ones.
!!
!! Complexity: O(n) where n = size(atoms). The hash table scan is O(nSlots) 
!!             which is a fixed constant (~17k), so total is O(n + C) = O(n).
!!
!! Returns: an allocated frequencies object containing the list of unique 
!!          atom types with their counts.
function initFreqs(atoms) result(freqs)

    !! hash function takes a maximum of 2 letter input (ie: aa) and a digit and a charge. 
    !! to avoid collisions, if the second letter exists we multiply the ascii value of the second letter 
    !! by the ascii value of a (97). Next, we sum up the ascii values of the number + charge, then multiply
    !! by the ascii value of z to ensure no collisions between non-charged and charged elements. 
    !! the total number of slots is therefore: ichar('z') + ichar('z')*ichar('a') + (ichar('9') + ichar('-')*ichar('z'))
    integer, parameter :: nSlots = ichar('z') + ichar('z') * ichar('a') + (ichar('9') + ichar('-')) * ichar('z')
    integer, parameter :: aAscii = ichar('a')
    integer, parameter :: zAscii = ichar('z') 
    type(atom), dimension(:), intent(in) :: atoms
    integer, allocatable :: counts(:)
    integer :: hashIdx, firstNumIdx, i, j, k, numUnique, chargeVal, numTotal
    character(len=4) :: atomName
    type(frequency), allocatable :: freqList(:)
    type(atom), allocatable :: atomList(:)
    type(frequencies), allocatable :: freqs
    type(coordPtrList) :: coords(nSlots)
    
    ! allocate counts with initial values of 0
    allocate(counts(nSlots), source=0)
    allocate(atomList(nSlots))
    
    ! fill indices with correct values
    do i = 1, size(atoms)
        atomName = atoms(i)%element
        
        ! hash atom name
        select case (len_trim(atomName))
            case(1)
                hashIdx = ichar(atomName(1:1))
            case(2)
                hashIdx = ichar(atomName(1:1)) + ichar(atomName(2:2)) * aAscii
            case default
                firstNumIdx = 0                        
                do j = 1, len_trim(atomName)
                    if (atomName(j:j) >= '0' .and. atomName(j:j) <= '9') then
                        firstNumIdx = j
                        exit
                    end if
                end do
                if (firstNumIdx == 0) then
                    print *, "Error: unexpected atom name format: ", atomName
                    stop 1
                else if (firstNumIdx == 1) then
                    hashIdx = ichar(atomName(1:1))
                    chargeVal = 0
                    do k = 2, len_trim(atomName)
                        chargeVal = chargeVal + ichar(atomName(k:k))
                    end do
                    hashIdx = hashIdx + chargeVal * zAscii
                else
                    hashIdx = ichar(atomName(1:1)) + ichar(atomName(2:2)) * aAscii
                    chargeVal = 0
                    do k = 3, len_trim(atomName)
                        chargeVal = chargeVal + ichar(atomName(k:k)) 
                    end do
                    hashIdx = hashIdx + chargeVal * zAscii
                end if
        end select

        ! increment frequency count and insert atom name
        counts(hashIdx) = counts(hashIdx) + 1
        atomList(hashIdx) = atoms(i)

        ! append list of coordinates
        if (.not. allocated(coords(hashIdx)%ptrs)) then
            allocate(coords(hashIdx)%ptrs(20))
        else if (coords(hashIdx)%n == size(coords(hashIdx)%ptrs)) then
            call growPtrList(coords(hashIdx))
        end if
        coords(hashIdx)%n = coords(hashIdx)%n + 1
        coords(hashIdx)%ptrs(coords(hashIdx)%n)%coord_ => atoms(i)%coords

    end do

    ! find actual number of frequencies and allocate list of frequencies
    numUnique = 0
    numTotal  = 0
    do i = 1, nSlots 
        if (counts(i) .ne. 0) then 
            numUnique = numUnique + 1
            numTotal  = numTotal  + counts(i)
        end if 
    end do 
    allocate(freqList(numUnique))

    ! build freqList and coordsList
    j = 0
    do i = 1, nSlots
        if (counts(i) .ne. 0) then 
            j = j + 1
            freqList(j)%name  = atomList(i)%element
            freqList(j)%atm   = atomList(i)
            freqList(j)%freq_ = counts(i)
            allocate(freqList(j)%coords, source=coords(i))
        end if 
    end do

    ! allocate frequencies
    allocate(freqs)
    allocate(freqs%items, source=freqList)
    freqs%nUnique = numUnique
    freqs%nItems  = numTotal
end function initFreqs