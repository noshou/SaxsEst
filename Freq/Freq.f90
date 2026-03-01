!> @brief Frequency distribution module for SAXS intensity estimation.
!> @details Provides types and procedures for building frequency tables of
!>          unique atom types, constructing cumulative mass functions (CMFs),
!>          and stratifying atoms into heavy/light strata for sampling.
module Freq 
    use iso_c_binding, only: c_double
    use AtomXYZ
    implicit none
    public
    
    ! coord type from AtomXYZ for reference
    ! type :: coord
    !     real(c_double) :: x  !< X-coordinate
    !     real(c_double) :: y  !< Y-coordinate
    !     real(c_double) :: z  !< Z-coordinate
    ! end type coord

    !> @brief Pointer to a single coordinate
    type :: coordPtr
        type(coord), pointer :: coord_ => null()
    end type coordPtr
    
    !> @brief Growable list of coordinate pointers for a single atom type
    type :: coordPtrList
        type(coordPtr), allocatable :: ptrs(:)
        integer :: n = 0
    end type coordPtrList

    !> Frequency distribution of a weight (form factor)
    type :: frequency
        private
        character(len=4) :: name
        type(atom)       :: atm
        integer          :: freq_
        type(coordPtrList), allocatable :: coords
    end type frequency

    !> Collection of unique atom types with their frequency counts.
    !> Provides methods for computing form factor weights, stratifying
    !> into heavy/light strata, and constructing CMFs for sampling.
    type :: frequencies
        type(frequency), private, allocatable  :: items(:) !> list of weights
        integer       :: nUnique = 0                       !> total number of unique weights
        integer       :: nItems  = 0                       !> total number of weights/atoms
        contains
            procedure :: weights  => getWeights
            procedure :: freqs    => getFreqs
            procedure :: heavy    => getHeavy
            procedure :: light    => getLight
            procedure :: mean     => getMean
    end type frequencies
    
    !> Cumulative mass function with parallel coordinate storage.
    !> Each index maps a form factor weight to its cumulative probability
    !> and the coordinates of all atoms of that type.
    type :: cmf 
        complex(c_double),  allocatable :: weights(:)
        real(c_double),     allocatable :: culmProbs(:)
        type(coordPtrList), allocatable :: coords(:)
        integer                         :: population
    end type cmf
    
    contains
        include "inc/initFreqs.inc"        
        include "inc/getters.inc"
end module Freq
    
