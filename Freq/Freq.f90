!> Frequency distribution module for SAXS intensity estimation.
!> Provides types and procedures for building frequency tables of
!> unique atom types, constructing cumulative distribution functions (CDFs),
!> and stratifying atoms into heavy/light strata for sampling.
module Freq 
    use iso_c_binding, only: c_double
    use AtomXYZ
    use, intrinsic  :: ieee_arithmetic

    implicit none
    public

    !> Pointer to a single coordinate
    type :: coordPtr
        type(coord), pointer :: coord_ => null() !> pointer to a cooridnate
    end type coordPtr
    
    !> Growable list of coordinate pointers for a single atom type
    type :: coordPtrList
        type(coordPtr), allocatable :: ptrs(:) !> pointer to coordinates
        integer :: n = 0 !> number of coordinates in this list
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
    !> into heavy/light strata, and constructing CDFs for sampling.
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
    
    !> Cumulative distribution function with parallel coordinate storage.
    !> Each index maps a form factor weight to its cumulative probability
    !> and the coordinates of all atoms of that type.
    !> Note that atoms contain "dummy atoms" and should NOT be used
    !> for sampling; only for form factor calculation.
    type :: cdf 
        complex(c_double),  allocatable :: weights(:)   !> parallel list of weights
        real(c_double),     allocatable :: culmProbs(:) !> parallel list of cumulative probabilities
        type(coordPtrList), allocatable :: coords(:)    !> parallel list-of-list of valid coordinates
        type(atom),         allocatable :: atoms(:)     !> parallel list of dummy atoms)
        integer                         :: population   !> total number of atoms contained in cdf
        real(c_double)                  :: mean         !> mean magnitude of cdf
        real(c_double)                  :: stdv         !> standard deviation of cdf
    end type cdf
    
    contains
        include "inc/initFreqs.inc"        
        include "inc/getters.inc"
end module Freq
    
