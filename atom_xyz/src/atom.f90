!! Atom module: provides operations on atomic coordinate data
module atom_mod
    use iso_fortran_env, only: real64
    implicit none

    private
    
    ! Public types
    public :: coord, atom, create_atom
    
    !! Represents an <x,y,z> coordinate
    type :: coord
        real(real64) :: x
        real(real64) :: y
        real(real64) :: z
    end type coord

    !! Represents an atom at coordinate xyz
    type :: atom
        type(coord) :: xyz
        character(len=10) :: element
    contains
        procedure :: to_string   => atom_to_string_method
        procedure :: dist_cart   => calc_distance_method
        procedure :: form_factor => form_factor_method
        procedure :: cmp_axis    => cmp_by_axis_method
        procedure :: get_axis    => get_axis_method
    end type atom

contains

    !! Creates an atom from position and element name
    function create_atom(position, element_name) result(new_atom)
        type(coord), intent(in) :: position
        character(len=*), intent(in) :: element_name
        type(atom) :: new_atom

        new_atom%xyz = position
        new_atom%element = trim(element_name)
    end function create_atom
    
    !! Returns the form factor for an atom at a given Q value
    function form_factor_method(this, q) result(ff)
        use form_fact_mod
        class(atom), intent(in) :: this
        real(real64), intent(in) :: q
        complex(real64) :: ff
        integer :: status
        ff = form_fact(q, this%element, status)
    end function form_factor_method

    !! Converts an atom to a string representation
    function atom_to_string_method(this, q) result(str)
        class(atom), intent(in) :: this
        real(real64), intent(in), optional :: q
        character(len=512) :: str
        real(real64) :: q_val
        complex(real64) :: f0_val
        character(len=128) :: temp

        ! Use provided Q or default to 0.0
        if (present(q)) then
            q_val = q
        else
            q_val = 0.0_real64
        end if

        ! Build string representation
        write(str, '(A)') '{'
        write(temp, '(A, F12.6, A, F12.6, A, F12.6, A)') &
            '  xyz: {x=', this%xyz%x, '; y=', this%xyz%y, '; z=', this%xyz%z, '};'
        str = trim(str) // new_line('A') // trim(temp)
        
        write(temp, '(A, A, A)') '  element: ', trim(this%element), ';'
        str = trim(str) // new_line('A') // trim(temp)

        ! Add form factor if Q is provided and non-zero
        if (abs(q_val) > 1.0e-10_real64) then
            f0_val = this%form_factor(q_val)
            write(temp, '(A, F12.6, A, F12.6, A)') &
                '  form_fact (Q=', q_val, '): ', real(f0_val), ''
            str = trim(str) // new_line('A') // trim(temp)
        end if

        str = trim(str) // new_line('A') // '}'
    end function atom_to_string_method


    ! Comparison functions

    !! Compares by a specific axis ('x', 'y', or 'z')
    !! Returns: -1 if this < cmp, 0 if equal, +1 if this > cmp
    function cmp_by_axis_method(this, cmp, axis) result(comparison)
        class(atom), intent(in) :: this 
        type(atom), intent(in)  :: cmp
        character(len=*), intent(in) :: axis
        integer :: comparison
        character(len=1) :: axis_lower
        real(real64) :: ref_val, cmp_val
        real(real64), parameter :: tolerance = 1.0e-10_real64

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

    !! Calculates the Euclidean distance between two atoms
    function calc_distance_method(this, that) result(distance)
        class(atom), intent(in) :: this
        type(atom), intent(in)  :: that 
        real(real64) :: distance

        distance = sqrt((that%xyz%x - this%xyz%x)**2 + &
                        (that%xyz%y - this%xyz%y)**2 + &
                        (that%xyz%z - this%xyz%z)**2)
    end function calc_distance_method

    !! Converts a single character to lowercase
    subroutine to_lower_char(c)
        character(len=1), intent(inout) :: c
        integer :: ic
        
        ic = ichar(c)
        if (ic >= ichar('A') .and. ic <= ichar('Z')) then
            c = char(ic + ichar('a') - ichar('A'))
        end if
    end subroutine to_lower_char

end module atom_mod