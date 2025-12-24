!> ! Given a list of complex weights and their frequencies, this function finds
!! a threshold value such that the cumulative probability of weights with
!! magnitude greater than or equal to the threshold is at most epsilon/3.
!!
!! @param[in] w Array of complex weights
!! @param[in] f Array of integer frequencies/counts for each weight
!! @param[in] e Epsilon threshold value (0 < e < 1)
!! @param[in] l Logical flag: .true. = find smallest valid threshold,
!!              .false. = find largest valid threshold
!! @param[in] n Total sample size (sum of all frequencies)
!! @param[out] err Optional error flag: 1 if threshold not found, 
!!                 0 if threshold found successfully
!!
!! @return bernoulli estimator:
!          thresh is Complex threshold value, or NaN+NaN*i if no valid threshold exists
function bern_est(w, f, e, l, n, err) result(bern)
    use, intrinsic :: ieee_arithmetic
    use, intrinsic :: iso_c_binding
    implicit none

    ! function arguments/parameters
    complex(c_double), dimension(:), intent(in) :: w    !< Array of complex weights
    integer, dimension(:), intent(in) :: f              !< Frequency array
    real(c_double), intent(in) :: e                     !< Epsilon threshold (0 < e < 1)
    logical, intent(in) :: l                            !< Search direction flag
    integer, intent(in) :: n                            !< Total sample size
    integer, intent(out), optional :: err               !< Error flag output

    ! result variable
    complex(c_double) :: thresh                         !< Threshold result

    ! local variables
    integer :: i, j                                     !< Loop indices
    real(c_double) :: p_curr                            !< Current cumulative probability
    real(c_double) :: mag                               !< Magnitude of current weight
    real(c_double) :: nan_val                           !< NaN value for initialization
    complex(c_double) :: t_curr                         !< Current threshold candidate
    logical :: found_                                   !< Flag indicating if valid threshold found

    ! initialize variables
    nan_val = ieee_value(nan_val, ieee_quiet_nan)
    thresh = cmplx(nan_val, nan_val, kind=c_double)
    found_ = .false.

    ! loop to find optimal threshold
    do i = 1, size(w)
        p_curr = 0.0_c_double
        t_curr = w(i)
        mag = abs(t_curr)

        ! calculate cumulative frequency distribution
        ! P(|w| >= mag) = sum of frequencies where |w_j| >= mag
        do j = 1, size(w)
        if (abs(w(j))>=mag) p_curr=p_curr+real(f(j),kind=c_double)/real(n,kind=c_double)
        end do 

        ! check if cumulative probability <= e/3
        if (p_curr <= e/3.0_c_double) then 
            if (.not. found_) then
                ! first valid threshold found
                thresh = t_curr
                found_ = .true. 
            else 
                if (l) then; if (mag < abs(thresh)) thresh = t_curr 
                else;        if (mag > abs(thresh)) thresh = t_curr
                end if 
            end if 
        end if 
    end do 

    ! set error flag
    if (.not. found_) then
        if (present(err)) err = 1
    else 
        if (present(err)) err = 0
    end if

    ! create new bernoulli estimator
    type(bernoulli) :: bern
    bern%thresh = thresh
    bern%probab = p_curr

end function bern_est