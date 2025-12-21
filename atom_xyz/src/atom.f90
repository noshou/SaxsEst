!> @brief Atomic coordinate and property operations
!>
!! Provides data types and operations for atomic coordinate data including:
!!   - Coordinate representation (x, y, z)
!!   - Atom type with position, element, and form factor calculations
!!   - Distance calculations and axis-based comparisons
!!   - String representation for output
module atom_mod
    use iso_c_binding, only: c_double
    implicit none

    private
    
    ! Public types
    public :: coord, atom, create_atom
    
    !> @brief Three-dimensional Cartesian coordinate
    !!
    !! Represents a point in 3D space with x, y, z components
    type :: coord
        real(c_double) :: x  !< X-coordinate
        real(c_double) :: y  !< Y-coordinate
        real(c_double) :: z  !< Z-coordinate
    end type coord

    !> @brief Atomic structure with position and element information
    !!
    !! Represents an atom with its 3D position and element type.
    !! Provides methods for:
    !!   - String representation
    !!   - Distance calculations
    !!   - Form factor computation
    !!   - Axis-based comparisons
    type :: atom
        type(coord) :: xyz               !< Atomic position in Cartesian coordinates
        character(len=10) :: element     !< Element symbol (e.g., 'Fe', 'Cu')
    contains
        procedure :: to_string   => atom_to_string_method    !< Convert atom to string
        procedure :: dist_cart   => calc_distance_method     !< Calculate distance to another atom
        procedure :: form_factor => form_factor_method       !< Get form factor at Q
        procedure :: cmp_axis    => cmp_by_axis_method       !< Compare by axis
    end type atom

contains

    !> @brief Create an atom from position and element name
    !!
    !! @param[in] position Cartesian coordinates
    !! @param[in] element_name Element symbol (e.g., 'Fe', 'Cu', 'Zn')
    !!
    !! @return new_atom Initialized atom structure
    function create_atom(position, element_name) result(new_atom)
        type(coord), intent(in) :: position
        character(len=*), intent(in) :: element_name
        type(atom) :: new_atom

        new_atom%xyz = position
        new_atom%element = trim(element_name)
    end function create_atom
    
    !> @brief Calculate atomic form factor at specified Q value
    !! Computes the complex atomic form factor including anomalous corrections:
    !! ff = f0(Q) + f1 + i*f2
    !!
    !! @param[in] this The atom object
    !! @param[in] q Scattering vector magnitude (sin θ)/λ in Å⁻¹
    !!
    !! @return ff Complex form factor
    function form_factor_method(this, q) result(ff)
        use form_fact_mod
        class(atom), intent(in) :: this
        real(c_double), intent(in) :: q
        complex(c_double) :: ff
        integer :: status
        ff = form_fact(q, this%element, status)
    end function form_factor_method

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
    function atom_to_string_method(this, q) result(str)
        class(atom), intent(in) :: this
        real(c_double), intent(in), optional :: q
        character(len=512) :: str
        real(c_double) :: q_val
        complex(c_double) :: f0_val
        character(len=128) :: temp

        ! Use provided Q or default to 0.0
        if (present(q)) then
            q_val = q
        else
            q_val = 0.0_c_double
        end if

        ! Build string representation
        write(str, '(A)') '{'
        write(temp, '(A, F12.6, A, F12.6, A, F12.6, A)') &
            '  xyz: {x=', this%xyz%x, '; y=', this%xyz%y, '; z=', this%xyz%z, '};'
        str = trim(str) // new_line('A') // trim(temp)
        
        write(temp, '(A, A, A)') '  element: ', trim(this%element), ';'
        str = trim(str) // new_line('A') // trim(temp)

        ! Add form factor if Q is provided and non-zero
        if (abs(q_val) > 1.0e-10_c_double) then
            f0_val = this%form_factor(q_val)
            write(temp, '(A, F12.6, A, F12.6, A)') &
                '  form_fact (Q=', q_val, '): ', real(f0_val), ''
            str = trim(str) // new_line('A') // trim(temp)
        end if

        str = trim(str) // new_line('A') // '}'
    end function atom_to_string_method


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
    function cmp_by_axis_method(this, cmp, axis) result(comparison)
        class(atom), intent(in) :: this 
        type(atom), intent(in)  :: cmp
        character(len=*), intent(in) :: axis
        integer :: comparison
        character(len=1) :: axis_lower
        real(c_double) :: ref_val, cmp_val
        real(c_double), parameter :: tolerance = 1.0e-10_c_double

        ! Convert axis to lowercase
        axis_lower = axis(1:1)
        call to_lower_char(axis_lower)

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
    end function cmp_by_axis_method

    ! Distance calculations

    !> @brief Calculate Euclidean distance between two atoms
    !!
    !! @details
    !! Computes the Cartesian distance between two atoms:
    !! distance = sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)
    !!
    !! @param[in] this First atom
    !! @param[in] that Second atom
    !!
    !! @return distance Euclidean distance in Å
    function calc_distance_method(this, that) result(distance)
        class(atom), intent(in) :: this
        type(atom), intent(in)  :: that 
        real(c_double) :: distance

        distance = sqrt((that%xyz%x - this%xyz%x)**2 + &
                        (that%xyz%y - this%xyz%y)**2 + &
                        (that%xyz%z - this%xyz%z)**2)
    end function calc_distance_method

    !> @brief Convert a single character to lowercase
    !!
    !! @param[inout] c Character to convert
    subroutine to_lower_char(c)
        character(len=1), intent(inout) :: c
        integer :: ic
        
        ic = ichar(c)
        if (ic >= ichar('A') .and. ic <= ichar('Z')) then
            c = char(ic + ichar('a') - ichar('A'))
        end if
    end subroutine to_lower_char

end module atom_mod