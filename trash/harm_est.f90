!! @param[in] a Advice for W/n
!! @param[in] w Array of complex weights
!! @param[in] f Array of integer frequencies/counts for each weight
!! @param[in] e Epsilon threshold value (0 < e < 1)
!! @param[in] c Logical flag: .true. = round up, .false. = round down
!! @param[in] l Logical flag: .true. = find smallest valid threshold,
!!              .false. = find largest valid threshold
!! @param[in] n Total sample size (sum of all frequencies)
!! @param[out] err Optional error flag: 1 if threshold not found, 
!!                 0 if threshold found successfully
!!
!! @return w_est     Estimated form factor weight (W/n)
function harm_est(a, w, f, e, c, l, n, err) result(w_est)
    
    complex(c_double), dimension(:), intent(in) :: w !< Array of weights
    integer, dimension(:), intent(in) :: f           !< Array of frequencies
    real(c_double), intent(in) :: e                  !< Epsilon (0 < e < 1)
    logical, intent(in) :: c, l                        
    type(bernoulli) :: bern
    integer :: k
    integer, optional, intent(in) :: err
    real(c_double), intent(in) :: a
    complex(c_double) :: w_est                       !< Estimated weight
    
    ! call bernoulli estimator, return nan if not found
    bern = call bern_est(w, f, e, l, n, err)
    if (err == 1) then 
        w_est = bern%thresh
    else 

        ! calculate k value
        if (c) then 
            k = ceiling(45.0_c_double*a/(bern%thresh*1-(e/3.0_c_double)*(e**2)*bern%probab))
        else 
            k = floor(45.0_c_double*a/(bern%thresh*1-(e/3.0_c_double)*(e**2)*bern%probab))
        end if 

        ! we now need to proportionally sample our weights to calculate 
        

    end if
end function harm_est