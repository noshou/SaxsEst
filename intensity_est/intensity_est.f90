module intensity_est_mod
    use atom_mod
    use iso_c_binding
    use kdt
    implicit none 
    private 

    contains 

        ! sinc function = sin(x)/x, 
        ! returns 1 if x is = 0
        pure function sinc(x) result(res)
            real(c_double), intent(in)  :: x
            real(c_double), :: res
            if (abs(x) <= 1e-9) then 
                res = real(1, kind=c_double)
            else 
                res = sin(x)/x
            end if 
        end function sinc 

        ! functions to include
        include "debeye_classic.f90"
        include "propest.f90"


end module intensity_est_mod