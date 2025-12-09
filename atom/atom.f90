!! Atom module: provides operations on atomic coordinate data
module atom_mod
	use iso_fortran_env, only: real64
	use xyz_data_mod, only: n_atoms, elements, x_coords, y_coords, z_coords
	implicit none

	private

	! Public types
	public :: coord, atom
	
	! Public interface
	public :: n_atoms  ! Re-export from xyz_data_mod
	public :: create_atom, load_atom
	public :: get_xyz, get_name, get_element
	public :: get_form_factor
	public :: atom_to_string
	public :: cmp_by_axis, cmp_by_coords
	public :: calc_distance
	public :: get_all_atoms

	! Type definitions
	
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
		procedure :: to_string => atom_to_string_method
		procedure :: distance_to => calc_distance_method
		procedure :: get_form_factor_method
	end type atom

contains

	! Constructors

	!! Creates an atom from position and element name
	function create_atom(position, element_name) result(new_atom)
		type(coord), intent(in) :: position
		character(len=*), intent(in) :: element_name
		type(atom) :: new_atom

		new_atom%xyz = position
		new_atom%element = trim(element_name)
	end function create_atom

	!! Loads an atom from the xyz_data_mod by index
	function load_atom(idx) result(a)
		integer, intent(in) :: idx
		type(atom) :: a
		type(coord) :: position

		! Validate index
		if (idx < 1 .or. idx > n_atoms) then
			write(*, '(A, I0, A, I0)') 'ERROR in load_atom: Index ', &
				idx, ' out of bounds. Valid range: 1 to ', n_atoms
			error stop
		end if

		! Create atom from data arrays
		position%x = x_coords(idx)
		position%y = y_coords(idx)
		position%z = z_coords(idx)
		
		a = create_atom(position, elements(idx))
	end function load_atom

	!! Loads all atoms from xyz_data_mod into an array
	function get_all_atoms() result(atoms)
		type(atom) :: atoms(n_atoms)
		integer :: i

		do i = 1, n_atoms
			atoms(i) = load_atom(i)
		end do
	end function get_all_atoms

	! Accessors

	!! Returns the xyz coordinates of an atom
	function get_xyz(a) result(position)
		type(atom), intent(in) :: a
		type(coord) :: position

		position = a%xyz
	end function get_xyz

	!! Returns the element name of an atom
	function get_name(a) result(element_name)
		type(atom), intent(in) :: a
		character(len=10) :: element_name

		element_name = trim(a%element)
	end function get_name

	!! Returns the element symbol (alias for get_name)
	function get_element(a) result(element)
		type(atom), intent(in) :: a
		character(len=10) :: element

		element = trim(a%element)
	end function get_element

	!! Returns the form factor for an atom at a given Q value
	function get_form_factor(a, q) result(f0_val)
		use f0_mod, only: get_f0
		type(atom), intent(in) :: a
		real(real64), intent(in) :: q
		real(real64) :: f0_val

		f0_val = get_f0(q, a%element)
	end function get_form_factor

	!! Type-bound method for getting form factor
	function get_form_factor_method(this, q) result(f0_val)
		class(atom), intent(in) :: this
		real(real64), intent(in) :: q
		real(real64) :: f0_val

		f0_val = get_form_factor(this, q)
	end function get_form_factor_method

	! String conversion

	!! Converts an atom to a string representation
	function atom_to_string(a, q) result(str)
		type(atom), intent(in) :: a
		real(real64), intent(in), optional :: q
		character(len=512) :: str
		real(real64) :: q_val, f0_val
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
			'  xyz: {x=', a%xyz%x, '; y=', a%xyz%y, '; z=', a%xyz%z, '};'
		str = trim(str) // new_line('A') // trim(temp)
		
		write(temp, '(A, A, A)') '  element: ', trim(a%element), ';'
		str = trim(str) // new_line('A') // trim(temp)

		! Add form factor if Q is provided and non-zero
		if (abs(q_val) > 1.0e-10_real64) then
			f0_val = get_form_factor(a, q_val)
			write(temp, '(A, F12.6, A, F12.6, A)') &
				'  form_fact (Q=', q_val, '): ', f0_val, ''
			str = trim(str) // new_line('A') // trim(temp)
		end if

		str = trim(str) // new_line('A') // '}'
	end function atom_to_string

	!! Type-bound method for to_string
	function atom_to_string_method(this, q) result(str)
		class(atom), intent(in) :: this
		real(real64), intent(in), optional :: q
		character(len=512) :: str

		str = atom_to_string(this, q)
	end function atom_to_string_method

	! Comparison functions

	!! Compares two atoms by a specific axis ('x', 'y', or 'z')
	!! Returns: -1 if ref < cmp, 0 if equal, +1 if ref > cmp
	function cmp_by_axis(ref, cmp, axis) result(comparison)
		type(atom), intent(in) :: ref, cmp
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
				ref_val = ref%xyz%x
				cmp_val = cmp%xyz%x
			case ('y')
				ref_val = ref%xyz%y
				cmp_val = cmp%xyz%y
			case ('z')
				ref_val = ref%xyz%z
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
	end function cmp_by_axis

	!! Checks if two atoms have the same coordinates
	function cmp_by_coords(ref, cmp) result(same)
		type(atom), intent(in) :: ref, cmp
		logical :: same
		logical :: same_x, same_y, same_z
		real(real64), parameter :: tolerance = 1.0e-10_real64

		same_x = abs(ref%xyz%x - cmp%xyz%x) < tolerance
		same_y = abs(ref%xyz%y - cmp%xyz%y) < tolerance
		same_z = abs(ref%xyz%z - cmp%xyz%z) < tolerance

		same = same_x .and. same_y .and. same_z
	end function cmp_by_coords

	! Distance calculations

	!! Calculates the Euclidean distance between two coordinates
	function calc_distance(a_start, a_end) result(distance)
		type(coord), intent(in) :: a_start, a_end
		real(real64) :: distance

		distance = sqrt((a_end%x - a_start%x)**2 + &
                    (a_end%y - a_start%y)**2 + &
                    (a_end%z - a_start%z)**2)
	end function calc_distance

	!! Type-bound method: calculates distance from this atom to another
	function calc_distance_method(this, other) result(distance)
		class(atom), intent(in) :: this
		type(atom), intent(in) :: other
		real(real64) :: distance

		distance = calc_distance(this%xyz, other%xyz)
	end function calc_distance_method

	!! Converts a single character to lowercase
	subroutine to_lower_char(c)
		character(len=1), intent(inout) :: c
		integer :: ic

		ic = iachar(c)
		if (ic >= iachar('A') .and. ic <= iachar('Z')) then
			c = achar(ic + 32)
		end if
	end subroutine to_lower_char

end module atom_mod