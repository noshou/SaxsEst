!===============================================================================
! Module: f1_f2_mod
!
! Description:
!   Provides anomalous scattering factors f1 and f2 for X-ray diffraction
!
! Background:
!   Anomalous scattering factors (f' and f'', or f1 and f2) account for
!   energy-dependent corrections to atomic scattering factors near
!   absorption edges. These values are critical for accurate structure
!   factor calculations in X-ray crystallography.
!
! Usage:
!   use f1_f2_mod, only: get_f1_f2
!   real(8) :: f1, f2
!   integer :: status
!   call get_f1_f2('Fe', f1, f2, status)
!   if (status == 0) then
!       ! Successfully retrieved f1 and f2 for iron
!   end if
!
! Public Interface:
!   get_f1_f2(elm, f1, f2, status) - Retrieve f1 and f2 for an element
!
!===============================================================================
module f1_f2_mod
    implicit none
    private

    ! Public interface
    public :: get_f1_f2

    !---------------------------------------------------------------------------
    ! Module Data
    !---------------------------------------------------------------------------

    ! Number of elements in lookup table
    integer, parameter :: n_elements = 75

    ! Element symbols (lowercase)
    character(len=2), dimension(n_elements), parameter :: elements = [ &
        'ac', &
        'ag', &
        'al', &
        'ar', &
        'as', &
        'at', &
        'au', &
        'b ', &
        'ba', &
        'be', &
        'bi', &
        'br', &
        'c ', &
        'ca', &
        'cd', &
        'ce', &
        'cl', &
        'co', &
        'cs', &
        'cu', &
        'dy', &
        'er', &
        'eu', &
        'ga', &
        'ge', &
        'h ', &
        'he', &
        'hf', &
        'hg', &
        'ho', &
        'i ', &
        'in', &
        'ir', &
        'k ', &
        'kr', &
        'li', &
        'lu', &
        'mg', &
        'mn', &
        'n ', &
        'na', &
        'nd', &
        'ne', &
        'ni', &
        'o ', &
        'os', &
        'p ', &
        'pa', &
        'pb', &
        'pd', &
        'pm', &
        'po', &
        'pr', &
        'ra', &
        'rb', &
        're', &
        'rh', &
        'rn', &
        's ', &
        'sb', &
        'se', &
        'sm', &
        'sn', &
        'sr', &
        'tb', &
        'tc', &
        'te', &
        'th', &
        'tl', &
        'tm', &
        'u ', &
        'v ', &
        'xe', &
        'yb', &
        'zn' ]

    ! f1 values (real part of anomalous scattering factor)
    ! Also known as f' or Δf'
    real(8), dimension(n_elements), parameter :: f1_values = [ &
        8.431760e+01, &
        4.672180e+01, &
        1.311410e+01, &
        1.828370e+01, &
        3.065930e+01, &
        7.881290e+01, &
        7.081600e+01, &
        5.003760e+00, &
        5.620110e+01, &
        4.001450e+00, &
        7.592240e+01, &
        3.281160e+01, &
        6.008060e+00, &
        2.033720e+01, &
        4.777210e+01, &
        5.814390e+01, &
        1.723850e+01, &
        2.721730e+01, &
        5.513910e+01, &
        2.893330e+01, &
        6.515400e+01, &
        6.654450e+01, &
        6.272370e+01, &
        3.032830e+01, &
        3.076420e+01, &
        9.999770e-01, &
        1.999980e+00, &
        6.865340e+01, &
        6.930630e+01, &
        6.589830e+01, &
        5.304810e+01, &
        4.883450e+01, &
        6.963290e+01, &
        1.931540e+01, &
        3.433870e+01, &
        3.000300e+00, &
        6.815570e+01, &
        1.209290e+01, &
        2.534890e+01, &
        7.014230e+00, &
        1.106870e+01, &
        6.001850e+01, &
        1.005110e+01, &
        2.810240e+01, &
        8.023880e+00, &
        6.631130e+01, &
        1.517630e+01, &
        8.617290e+01, &
        7.411850e+01, &
        4.565770e+01, &
        6.090310e+01, &
        7.735160e+01, &
        5.904390e+01, &
        8.313830e+01, &
        3.560820e+01, &
        6.820980e+01, &
        4.456040e+01, &
        8.056900e+01, &
        1.620460e+01, &
        5.088860e+01, &
        3.049020e+01, &
        6.190490e+01, &
        4.991820e+01, &
        3.678900e+01, &
        6.432590e+01, &
        4.239430e+01, &
        5.208260e+01, &
        8.560850e+01, &
        7.133550e+01, &
        6.718730e+01, &
        8.710760e+01, &
        2.339490e+01, &
        5.413150e+01, &
        6.781950e+01, &
        2.969520e+01 ]

    ! f2 values (imaginary part of anomalous scattering factor)
    ! Also known as f'' or Δf''
    real(8), dimension(n_elements), parameter :: f2_values = [ &
        6.050520e+00, &
        2.003310e+00, &
        1.030450e-01, &
        4.031690e-01, &
        3.636710e+00, &
        5.118070e+00, &
        9.518390e+00, &
        1.508600e-03, &
        4.373640e+00, &
        5.729940e-04, &
        4.686970e+00, &
        6.152840e-01, &
        3.583820e-03, &
        5.994100e-01, &
        2.234660e+00, &
        4.960450e+00, &
        3.097950e-01, &
        1.768910e+00, &
        3.975820e+00, &
        2.321750e+00, &
        7.806950e+00, &
        8.866890e+00, &
        6.725550e+00, &
        2.922440e+00, &
        3.283220e+00, &
        3.891760e-07, &
        1.447250e-05, &
        1.115540e+01, &
        1.003670e+01, &
        8.783030e+00, &
        3.317140e+00, &
        2.348890e+00, &
        8.548660e+00, &
        5.071960e-01, &
        6.655940e-01, &
        1.219160e-04, &
        1.062960e+01, &
        7.714050e-02, &
        1.361780e+00, &
        7.026850e-03, &
        5.038550e-02, &
        5.653840e+00, &
        3.436720e-02, &
        2.043030e+00, &
        1.311470e-02, &
        1.131520e+01, &
        1.896810e-01, &
        6.726320e+00, &
        4.452090e+00, &
        1.858080e+00, &
        5.900530e+00, &
        4.822580e+00, &
        5.248970e+00, &
        5.905940e+00, &
        7.457530e-01, &
        1.055560e+01, &
        1.712600e+00, &
        5.475750e+00, &
        2.420860e-01, &
        2.697350e+00, &
        5.440730e-01, &
        6.667650e+00, &
        2.604910e+00, &
        8.624360e-01, &
        7.377100e+00, &
        1.403240e+00, &
        3.217270e+00, &
        6.570290e+00, &
        4.233770e+00, &
        9.516970e+00, &
        7.716520e+00, &
        1.024630e+00, &
        3.704390e+00, &
        1.006800e+01, &
        2.625520e+00 ]

contains

    !---------------------------------------------------------------------------
    ! Subroutine: get_f1_f2
    !
    ! Description:
    !   Retrieves the anomalous scattering factors f1 and f2 for a given energy level
    !
    ! Parameters:
    !   elm    [in]  - Element symbol (e.g., 'Fe', 'Cu', 'Zn')
    !                  Case-insensitive, numeric suffixes ignored
    !   f1     [out] - Real part of anomalous scattering factor (f')
    !   f2     [out] - Imaginary part of anomalous scattering factor (f'')
    !   status [out] - Return status: 0 = success, -1 = element not found
    !
    ! Example:
    !   real(8) :: f1_fe, f2_fe
    !   integer :: stat
    !   call get_f1_f2('Fe', f1_fe, f2_fe, stat)
    !---------------------------------------------------------------------------
    subroutine get_f1_f2(elm, f1, f2, status)
        character(len=*), intent(in) :: elm
        real(8), intent(out) :: f1, f2
        integer, intent(out) :: status
        character(len=:), allocatable :: elm_clean
        integer :: i
        character :: c

        ! Extract alphabetic part only and convert to lowercase
        elm_clean = ''
        do i = 1, len_trim(elm)
            c = elm(i:i)
            if ((c >= 'A' .and. c <= 'Z')) then
                elm_clean = elm_clean // char(iachar(c) + 32)
            else if (c >= 'a' .and. c <= 'z') then
                elm_clean = elm_clean // c
            else
                exit  ! Stop at first non-alphabetic character
            end if
        end do

        ! Search for element in lookup table
        status = -1  ! Not found by default
        do i = 1, n_elements
            if (trim(elm_clean) == trim(elements(i))) then
                f1 = f1_values(i)
                f2 = f2_values(i)
                status = 0  ! Success
                return
            end if
        end do

        ! Element not found - f1 and f2 remain uninitialized

    end subroutine get_f1_f2

end module f1_f2_mod
