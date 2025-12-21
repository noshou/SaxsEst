module intensity_est_mod
    use atom_mod
    use iso_c_binding
    implicit none 
    private 

    contains 

        ! sinc function = sin(x)/x
        pure function sinc(x) result(res)
            real(c_double), intent(in)  :: x
            real(c_double), :: res
            res = sin(x)/x
        end function sinc 

        include "functions/debeye_classic.f90"
        
end module intensity_est_mod