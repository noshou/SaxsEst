!> Cardinal sine function: sinc(x) = sin(x)/x
!! 
!! Returns 1 for x ≈ 0 to avoid division by zero
!!
!! @param[in] x  Input value
!!
!! @return sinc(x), with limit value 1 as x→0
pure function sinc(x) result(res)
    real(c_double), intent(in) :: x
    real(c_double) :: res   
    
    if (abs(x) <= 1e-9_c_double) then  
        res = 1.0_c_double
    else 
        res = sin(x) / x
    end if 
end function sinc