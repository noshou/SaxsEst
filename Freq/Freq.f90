module Freq 
    use iso_c_binding, only: c_double
    use AtomXYZ
    implicit none
    public
    
    !> Frequency distribution of a weight (form factor)
    type :: frequency
        private
        character(len=4) :: name
        type(atom) :: atm
        integer :: freq_
    end type frequency

    !> Container for frequency array
    type :: frequencies
        type(frequency), private, allocatable  :: items(:)       !> list of weights
        integer :: nUnique = 0 !> total number of unique weights
        integer :: nItems  = 0 !> total number of weights/atoms
        contains
            procedure :: weights  => getWeights
            procedure :: freqs    => getFreqs
            procedure :: pmf      => getProbabilityMassFunction
            procedure :: pmfCmp   => getProbabilityMassFunctionCompliment
            procedure :: cmf      => getContinuousMassFunction
            procedure :: survival => getSurvivalFunction
    end type frequencies
    
    contains
        include "inc/initFreqs.inc"        
        include "inc/getters.inc"
end module Freq
    
