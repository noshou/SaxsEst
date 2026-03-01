!> @brief Create an atom from position and element name
!!
!! @param[in] position Cartesian coordinates
!! @param[in] element_name Element symbol (e.g., 'Fe', 'Cu', 'Zn')
!!
!! @return new_atom Initialized atom structure
function createAtom(position, element_name) result(new_atom)
    type(coord), intent(in) :: position
    character(len=*), intent(in) :: element_name
    type(atom) :: new_atom

    new_atom%xyz = position
    new_atom%element = trim(element_name)
end function createAtom

!> @brief Calculate atomic form factor at specified Q value
!! Computes the complex atomic form factor including anomalous corrections:
!! ff = f0(Q) + f1 + i*f2
!!
!! @param[in] this The atom object
!! @param[in] q Scattering vector magnitude (sin θ)/λ in Å⁻¹
!!
!! @return ff Complex form factor
function formFactorMethod(this, q) result(ff)
    use FormFact
    class(atom), intent(in) :: this
    real(c_double), intent(in) :: q
    complex(c_double) :: ff
    integer :: status
    ff = getFormFact(q, this%element, status)
end function formFactorMethod

!> @brief Convert atom to string representation
!! Creates a formatted string containing:
!!   - Cartesian coordinates (x, y, z)
!!   - Element symbol
!!   - Form factor (if Q is provided and non-zero)
!!
!! @param[in] this The atom object
!! @param[in] q Optional scattering vector magnitude for form factor
!! 
!! @return str Formatted string representation
function atom2String(this, q) result(str)
    class(atom), intent(in) :: this
    real(c_double), intent(in), optional :: q
    character(len=512) :: str
    real(c_double) :: qVal
    complex(c_double) :: f0Val
    character(len=128) :: temp

    ! Use provided Q or default to 0.0
    if (present(q)) then
        qVal = q
    else
        qVal = 0.0_c_double
    end if

    ! Build string representation
    write(str, '(A)') '{'
    write(temp, '(A, F12.6, A, F12.6, A, F12.6, A)') &
        '  xyz: {x=', this%xyz%x, '; y=', this%xyz%y, '; z=', this%xyz%z, '};'
    str = trim(str) // new_line('A') // trim(temp)
    
    write(temp, '(A, A, A)') '  element: ', trim(this%element), ';'
    str = trim(str) // new_line('A') // trim(temp)

    ! Add form factor if Q is provided and non-zero
    if (abs(qVal) > 1.0e-10_c_double) then
        f0Val = this%formFactor(qVal)
        write(temp, '(A, F12.6, A, F12.6, A)') &
            '  getFormFact (Q=', qVal, '): ', real(f0Val), ''
        str = trim(str) // new_line('A') // trim(temp)
    end if

    str = trim(str) // new_line('A') // '}'
end function atom2String


! Comparison functions

!> @brief Compare atoms by a specific coordinate axis
!! Compares two atoms based on their position along a specified axis.
!! Comparison uses a tolerance of 1.0e-10 for floating-point equality.
!!
!! @param[in] this The reference atom
!! @param[in] cmp The atom to compare against
!! @param[in] axis Axis to compare ('x', 'y', or 'z'), case-insensitive
!! 
!! @return -1 if this < cmp, 0 if equal, +1 if this > cmp
function cmpByAxis(this, cmp, axis) result(comparison)
    class(atom), intent(in) :: this 
    type(atom), intent(in)  :: cmp
    character(len=*), intent(in) :: axis
    integer :: comparison
    character(len=1) :: axis_lower
    real(c_double) :: ref_val, cmp_val
    real(c_double), parameter :: tolerance = 1.0e-10_c_double

    ! Convert axis to lowercase
    axis_lower = axis(1:1)
    call toLowerChar(axis_lower)

    ! Select the appropriate coordinate
    select case (axis_lower)
        case ('x')
            ref_val = this%xyz%x
            cmp_val = cmp%xyz%x
        case ('y')
            ref_val = this%xyz%y
            cmp_val = cmp%xyz%y
        case ('z')
            ref_val = this%xyz%z
            cmp_val = cmp%xyz%z
        case default
            write(*, '(A, A, A)') "ERROR in cmp_by_axis: Expected 'x', 'y', or 'z' but got: '", &
                trim(axis), "'"
            error stop
    end select

    ! Compare with tolerance
    if (abs(ref_val - cmp_val) < tolerance) then
        comparison = 0
    else if (ref_val < cmp_val) then
        comparison = -1
    else
        comparison = 1
    end if
end function cmpByAxis

! Distance calculations

!> @brief Calculate cartesian distance between two coordinates
!! @param[in] this First coordinate
!! @param[in] that Second coordinate
!! @return distance in Å
pure function calcDistanceCoord(this, that) result(res)
    class(coord)   :: this
    type(coord)    :: that
    real(c_double) :: res
    res = sqrt((this%x - that%x)**2 + (this%y - that%y)**2 + (this%z - that%z)**2)
end function calcDistanceCoord

!> @brief Calculate cartesian distance between two atoms
!! @param[in] this First atom
!! @param[in] that Second atom 
!! @return distance in Å
pure function calcDistanceAtom(this, that) result(distance)
    class(atom), intent(in) :: this
    type(atom), intent(in)  :: that 
    real(c_double)          :: res
    res = this%xyz%distCart(that%xyz)
end function calcDistanceAtom

!> @brief Convert a single character to lowercase
!!
!! @param[inout] c Character to convert
subroutine toLowerChar(c)
    character(len=1), intent(inout) :: c
    integer :: ic
    
    ic = ichar(c)
    if (ic >= ichar('A') .and. ic <= ichar('Z')) then
        c = char(ic + ichar('a') - ichar('A'))
    end if
end subroutine toLowerChar

