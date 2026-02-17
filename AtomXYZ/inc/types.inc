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
    type(coord), public :: xyz              !< Atomic position in Cartesian coordinates
    character(len=10), public :: element    !< Element symbol (e.g., 'Fe', 'Cu')
contains
    procedure :: toString   => atom2String      !< Convert atom to string
    procedure :: distCart   => calcDistance     !< Calculate distance to another atom
    procedure :: formFactor => formFactorMethod !< Get form factor at Q
    procedure :: cmpAxis    => cmpByAxis        !< Compare by axis
end type atom
