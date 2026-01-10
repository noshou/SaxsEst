!> K-D tree implementation
module kdt_mod

    use iso_c_binding, only: c_double
    use atom_mod
    implicit none
    private

    ! public API
    public :: kdt, kdt_creator

    !> Abstract base type representing a hyperplane axis in 3D space
    type, private, abstract :: hype
    contains; procedure :: str => str_method
    end type hype

    !> X-axis hyperplane
    type, private, extends(hype) :: X; end type X

    !> Y-axis hyperplane
    type, private, extends(hype) :: Y; end type Y

    !> Z-axis hyperplane
    type, private, extends(hype) :: Z; end type Z
    
    !> K-D tree node
    !!
    !! Each node contains a point and partitions space along one axis
    type :: node
        private
        type(kdt),   allocatable :: rch !< Right child subtree (points >= pivot on axis)
        type(kdt),   allocatable :: lch !< Left child subtree (points < pivot on axis)
        type(atom),  allocatable :: atm !< The point/atom stored at this node
        class(hype), allocatable :: axs !< The axis this node splits on
    end type node

    !> Frequency distribution of a weight (form factor)
    type :: frequency
        private
        character(len=4) :: name
        type(atom) :: atm
        integer :: freq
    end type frequency

    !> Container for frequency array
    type :: frequencies
        private
        type(frequency), allocatable  :: items(:)       !> list of weights
        integer                       :: n_items = 0    !> number of weights
    end type frequencies

    !> K-D tree data structure (3 dimensions; X, Y, Z)
    type :: kdt
        private
        type(node), allocatable :: root !< Root node of the tree (unallocated = empty tree)
        type(frequencies) :: freq_dist
        integer, allocatable :: subtree_size
        type(atom), allocatable :: atm(:)
        integer :: unique ! number of unique items
        contains
            procedure :: radial_search => radial_search_method
            procedure :: weights => get_weights
            procedure :: freqs => get_freqs
            procedure :: size  => get_size
            procedure :: atoms => get_atoms
            procedure :: empty => get_status
            procedure :: n_unique => get_number_unique
    end type kdt

    contains
        include "inc/kdt_methods.inc"
        include "inc/helpers.inc"
        include "inc/moms.inc"
        include "inc/creator.inc"
        include "inc/radial_search.inc"
end module kdt_mod