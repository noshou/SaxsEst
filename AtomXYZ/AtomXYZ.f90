!> @brief Atomic coordinate and property operations
!>
!! Provides data types and operations for atomic coordinate data including:
!!   - Coordinate representation (x, y, z)
!!   - Atom type with position, element, and form factor calculations
!!   - Distance calculations and axis-based comparisons
!!   - String representation for output
module AtomXYZ
    use iso_c_binding, only: c_double
    implicit none

    private
    
    ! Public types
    public :: coord, atom, createAtom
    
    include "inc/types.inc"
contains
    include "inc/methods.inc"
end module AtomXYZ