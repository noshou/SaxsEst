!! Returns the form factor for a given element
module form_fact_mod
    use iso_fortran_env, only: real64
    use f0_mod, only: get_f0
    use anomalous_scattering, only: get_f1_f2
    implicit none
    
    private
    public :: form_fact
    
contains

    ! Computes form_fact(q, elm) = f0(q, elm) + f1(elm) + i*f2(elm)
    function form_fact(q, elm, status) result(ff)
        real(real64), intent(in) :: q
        character(len=*), intent(in) :: elm
        integer, intent(out) :: status
        complex(real64) :: ff
        
        real(real64) :: f0_val, f1, f2
        
        ! Get anomalous scattering factors f1 and f2
        call get_f1_f2(elm, f1, f2, status)
        
        if (status /= 0) then
            ! Element not found, return zero and error status
            ff = cmplx(0.0_real64, 0.0_real64, kind=real64)
            return
        end if
        
        ! Get atomic form factor f0
        f0_val = get_f0(q, elm)
        
        ! Construct complex result: real = f1 + f0, imaginary = f2
        ff = cmplx(f1 + f0_val, f2, kind=real64)
        
    end function form_fact

end module form_fact_mod