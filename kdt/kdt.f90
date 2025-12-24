!> K-D tree implementation
module kdt_mod

    use iso_c_binding, only: c_double
    use atoms_mod
    implicit none
    private

    ! public API
    public :: kdt, hype, kdt_creator, frequency, frequency_list

    !> Abstract base type representing a hyperplane axis in 3D space
    type, abstract :: hype
    contains; procedure :: str => str_method
    end type hype

    !> X-axis hyperplane
    type, extends(hype) :: X; end type X

    !> Y-axis hyperplane
    type, extends(hype) :: Y; end type Y

    !> Z-axis hyperplane
    type, extends(hype) :: Z; end type Z

    !> K-D tree data structure (3 dimensions; X, Y, Z)
    type :: kdt
        integer,    allocatable :: subtree_size
        type(node), allocatable :: root !< Root node of the tree (unallocated = empty tree)
        type(frequency_list)    :: freq_dist
        contains
            procedure   :: radial_search => radial_search_method
    end type kdt

    !> K-D tree node
    !!
    !! Each node contains a point and partitions space along one axis
    type :: node
        type(kdt),   allocatable :: rch !< Right child subtree (points >= pivot on axis)
        type(kdt),   allocatable :: lch !< Left child subtree (points < pivot on axis)
        type(atom),  allocatable :: atm !< The point/atom stored at this node
        class(hype), allocatable :: axs !< The axis this node splits on
    end type node

    !> Frequency distribution of a weight (form factor)
    type :: frequency
        complex(c_double) :: weight
        integer :: freq
    end type frequency

    !> Container for frequency array
    type :: frequency_list
        character(len=4), allocatable :: names(:)       !> name of weights
        type(frequency), allocatable  :: items(:)       !> list of weights
        integer                       :: n_items = 0    !> number of weights
        real(c_double), allocatable   :: probs(:)       !> probability of each weight
    end type frequency_list

    contains
        include "helpers.f90"
        include "moms.f90"
        include "creator.f90"
        include "radial_search.f90"
end module kdt_mod