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
        8.431760000000000e+01d0, &
        4.672180000000000e+01d0, &
        1.311410000000000e+01d0, &
        1.828370000000000e+01d0, &
        3.065930000000000e+01d0, &
        7.881290000000000e+01d0, &
        7.081600000000000e+01d0, &
        5.003760000000000e+00d0, &
        5.620110000000000e+01d0, &
        4.001450000000000e+00d0, &
        7.592240000000000e+01d0, &
        3.281160000000000e+01d0, &
        6.008060000000000e+00d0, &
        2.033720000000000e+01d0, &
        4.777210000000000e+01d0, &
        5.814390000000000e+01d0, &
        1.723850000000000e+01d0, &
        2.721730000000000e+01d0, &
        5.513910000000000e+01d0, &
        2.893330000000000e+01d0, &
        6.515400000000000e+01d0, &
        6.654450000000000e+01d0, &
        6.272370000000000e+01d0, &
        3.032830000000000e+01d0, &
        3.076420000000000e+01d0, &
        9.999770000000000e-01d0, &
        1.999980000000000e+00d0, &
        6.865340000000000e+01d0, &
        6.930629999999999e+01d0, &
        6.589830000000001e+01d0, &
        5.304810000000000e+01d0, &
        4.883450000000000e+01d0, &
        6.963290000000001e+01d0, &
        1.931540000000000e+01d0, &
        3.433870000000000e+01d0, &
        3.000300000000000e+00d0, &
        6.815570000000000e+01d0, &
        1.209290000000000e+01d0, &
        2.534890000000000e+01d0, &
        7.014230000000000e+00d0, &
        1.106870000000000e+01d0, &
        6.001850000000000e+01d0, &
        1.005110000000000e+01d0, &
        2.810240000000000e+01d0, &
        8.023880000000000e+00d0, &
        6.631130000000000e+01d0, &
        1.517630000000000e+01d0, &
        8.617290000000000e+01d0, &
        7.411850000000000e+01d0, &
        4.565770000000000e+01d0, &
        6.090310000000000e+01d0, &
        7.735160000000000e+01d0, &
        5.904390000000000e+01d0, &
        8.313830000000000e+01d0, &
        3.560820000000000e+01d0, &
        6.820980000000000e+01d0, &
        4.456040000000000e+01d0, &
        8.056900000000000e+01d0, &
        1.620460000000000e+01d0, &
        5.088860000000000e+01d0, &
        3.049020000000000e+01d0, &
        6.190490000000000e+01d0, &
        4.991820000000000e+01d0, &
        3.678900000000000e+01d0, &
        6.432590000000000e+01d0, &
        4.239430000000000e+01d0, &
        5.208260000000000e+01d0, &
        8.560850000000001e+01d0, &
        7.133550000000000e+01d0, &
        6.718729999999999e+01d0, &
        8.710760000000001e+01d0, &
        2.339490000000000e+01d0, &
        5.413150000000000e+01d0, &
        6.781950000000001e+01d0, &
        2.969520000000000e+01d0 ]

    ! f2 values (imaginary part of anomalous scattering factor)
    ! Also known as f'' or Δf''
    real(8), dimension(n_elements), parameter :: f2_values = [ &
        6.050520000000000e+00d0, &
        2.003310000000000e+00d0, &
        1.030450000000000e-01d0, &
        4.031690000000000e-01d0, &
        3.636710000000000e+00d0, &
        5.118070000000000e+00d0, &
        9.518390000000000e+00d0, &
        1.508600000000000e-03d0, &
        4.373640000000000e+00d0, &
        5.729940000000000e-04d0, &
        4.686970000000000e+00d0, &
        6.152840000000001e-01d0, &
        3.583820000000000e-03d0, &
        5.994100000000000e-01d0, &
        2.234660000000000e+00d0, &
        4.960450000000000e+00d0, &
        3.097950000000000e-01d0, &
        1.768910000000000e+00d0, &
        3.975820000000000e+00d0, &
        2.321750000000000e+00d0, &
        7.806950000000000e+00d0, &
        8.866890000000000e+00d0, &
        6.725550000000000e+00d0, &
        2.922440000000000e+00d0, &
        3.283220000000000e+00d0, &
        3.891760000000000e-07d0, &
        1.447250000000000e-05d0, &
        1.115540000000000e+01d0, &
        1.003670000000000e+01d0, &
        8.783030000000000e+00d0, &
        3.317140000000000e+00d0, &
        2.348890000000000e+00d0, &
        8.548660000000000e+00d0, &
        5.071960000000000e-01d0, &
        6.655940000000000e-01d0, &
        1.219160000000000e-04d0, &
        1.062960000000000e+01d0, &
        7.714050000000000e-02d0, &
        1.361780000000000e+00d0, &
        7.026850000000000e-03d0, &
        5.038550000000000e-02d0, &
        5.653840000000000e+00d0, &
        3.436720000000000e-02d0, &
        2.043030000000000e+00d0, &
        1.311470000000000e-02d0, &
        1.131520000000000e+01d0, &
        1.896810000000000e-01d0, &
        6.726320000000000e+00d0, &
        4.452090000000000e+00d0, &
        1.858080000000000e+00d0, &
        5.900530000000000e+00d0, &
        4.822580000000000e+00d0, &
        5.248970000000000e+00d0, &
        5.905940000000000e+00d0, &
        7.457530000000000e-01d0, &
        1.055560000000000e+01d0, &
        1.712600000000000e+00d0, &
        5.475750000000000e+00d0, &
        2.420860000000000e-01d0, &
        2.697350000000000e+00d0, &
        5.440730000000000e-01d0, &
        6.667650000000000e+00d0, &
        2.604910000000000e+00d0, &
        8.624360000000000e-01d0, &
        7.377100000000000e+00d0, &
        1.403240000000000e+00d0, &
        3.217270000000000e+00d0, &
        6.570290000000000e+00d0, &
        4.233770000000000e+00d0, &
        9.516970000000001e+00d0, &
        7.716520000000000e+00d0, &
        1.024630000000000e+00d0, &
        3.704390000000000e+00d0, &
        1.006800000000000e+01d0, &
        2.625520000000000e+00d0 ]

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
