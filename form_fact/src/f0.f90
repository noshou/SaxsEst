!===============================================================================
! Module: f0_mod
!
! Description:
!   Atomic form factors f0 for X-ray scattering calculations.
!   f0(Q) represents the scattering amplitude of an atom as a function
!   of the scattering vector Q = (sin θ)/λ.
!
! Data Source:
!   International Tables for Crystallography Vol. C
!   DOI: 10.1107/97809553602060000600
!
! Usage:
!   use f0_mod, only: get_f0
!   real(real64) :: f0_value
!   f0_value = get_f0(q=0.25_real64, element='Fe')
!
! Note: Q values are rounded to nearest 0.01 Å⁻¹
!===============================================================================
module f0_mod
    use iso_fortran_env, only: real64
    implicit none

    private

    ! Public interface
    public :: n_elements, n_q_values
    public :: get_f0

    !---------------------------------------------------------------------------
    ! Module Data
    !---------------------------------------------------------------------------

    ! Number of elements and Q values in lookup table
    integer, parameter :: n_elements = 23
    integer, parameter :: n_q_values = 26

    ! Element/ion symbols (lowercase)
    character(len=4), parameter :: elements(23) = [ &
            'se  ', &
            'cu2+', &
            'mn2+', &
            'ca  ', &
            'k   ', &
            'ar  ', &
            'cl  ', &
            's   ', &
            'p   ', &
            'si  ', &
            'al  ', &
            'mg  ', &
            'na  ', &
            'ne  ', &
            'f   ', &
            'o   ', &
            'n   ', &
            'c   ', &
            'b   ', &
            'be  ', &
            'li  ', &
            'he  ', &
            'h   ' ]

    ! Scattering vector magnitudes: Q = (sin θ)/λ in Å⁻¹
    ! Range: 0 to ~2.0 Å⁻¹ in increments of 0.01 Å⁻¹
    real(real64), parameter :: q_values(26) = [ &
            0.000000_real64, &
            0.020000_real64, &
            0.040000_real64, &
            0.060000_real64, &
            0.080000_real64, &
            0.100000_real64, &
            0.120000_real64, &
            0.140000_real64, &
            0.160000_real64, &
            0.180000_real64, &
            0.200000_real64, &
            0.220000_real64, &
            0.240000_real64, &
            0.260000_real64, &
            0.280000_real64, &
            0.300000_real64, &
            0.320000_real64, &
            0.340000_real64, &
            0.360000_real64, &
            0.380000_real64, &
            0.400000_real64, &
            0.420000_real64, &
            0.440000_real64, &
            0.460000_real64, &
            0.480000_real64, &
            0.500000_real64 ]

    ! Form factor data: f0(Q) for each element
    ! Rows: Q values, Columns: Elements
    ! f0 decreases with increasing Q due to destructive interference
    real(real64), parameter :: f0_data(26,23) = reshape([ &
            34.000000_real64, &
            27.000000_real64, &
            23.000000_real64, &
            20.000000_real64, &
            19.000000_real64, &
            18.000000_real64, &
            17.000000_real64, &
            16.000000_real64, &
            15.000000_real64, &
            14.000000_real64, &
            13.000000_real64, &
            12.000000_real64, &
            11.000000_real64, &
            10.000000_real64, &
            9.000000_real64, &
            8.000000_real64, &
            7.000000_real64, &
            6.000000_real64, &
            5.000000_real64, &
            4.000000_real64, &
            3.000000_real64, &
            2.000000_real64, &
            1.000000_real64, &
            33.881000_real64, &
            26.956000_real64, &
            22.953000_real64, &
            19.838000_real64, &
            18.854000_real64, &
            17.924000_real64, &
            16.919000_real64, &
            15.915000_real64, &
            14.914000_real64, &
            13.900000_real64, &
            12.903000_real64, &
            11.914000_real64, &
            10.922000_real64, &
            9.973000_real64, &
            8.970000_real64, &
            7.967000_real64, &
            6.963000_real64, &
            5.958000_real64, &
            4.954000_real64, &
            3.950000_real64, &
            2.947000_real64, &
            1.993000_real64, &
            0.991000_real64, &
            33.532000_real64, &
            26.824000_real64, &
            22.812000_real64, &
            19.392000_real64, &
            18.462000_real64, &
            17.700000_real64, &
            16.683000_real64, &
            15.665000_real64, &
            14.646000_real64, &
            13.628000_real64, &
            12.629000_real64, &
            11.674000_real64, &
            10.709000_real64, &
            9.891000_real64, &
            8.881000_real64, &
            7.869000_real64, &
            6.855000_real64, &
            5.837000_real64, &
            4.820000_real64, &
            3.807000_real64, &
            2.802000_real64, &
            1.972000_real64, &
            0.966000_real64, &
            32.982000_real64, &
            26.608000_real64, &
            22.581000_real64, &
            18.758000_real64, &
            17.924000_real64, &
            17.340000_real64, &
            16.306000_real64, &
            15.271000_real64, &
            14.237000_real64, &
            13.209000_real64, &
            12.222000_real64, &
            11.319000_real64, &
            10.412000_real64, &
            9.757000_real64, &
            8.736000_real64, &
            7.712000_real64, &
            6.682000_real64, &
            5.645000_real64, &
            4.613000_real64, &
            3.592000_real64, &
            2.606000_real64, &
            1.939000_real64, &
            0.925000_real64, &
            32.273000_real64, &
            26.311000_real64, &
            22.266000_real64, &
            18.045000_real64, &
            17.332000_real64, &
            16.865000_real64, &
            15.814000_real64, &
            14.764000_real64, &
            13.721000_real64, &
            12.695000_real64, &
            11.739000_real64, &
            10.903000_real64, &
            10.084000_real64, &
            9.576000_real64, &
            8.541000_real64, &
            7.501000_real64, &
            6.453000_real64, &
            5.396000_real64, &
            4.352000_real64, &
            3.336000_real64, &
            2.400000_real64, &
            1.893000_real64, &
            0.872000_real64, &
            31.449000_real64, &
            25.939000_real64, &
            21.875000_real64, &
            17.331000_real64, &
            16.733000_real64, &
            16.298000_real64, &
            15.234000_real64, &
            14.177000_real64, &
            13.138000_real64, &
            12.134000_real64, &
            11.230000_real64, &
            10.472000_real64, &
            9.760000_real64, &
            9.351000_real64, &
            8.302000_real64, &
            7.245000_real64, &
            6.180000_real64, &
            5.107000_real64, &
            4.060000_real64, &
            3.065000_real64, &
            2.215000_real64, &
            1.837000_real64, &
            0.811000_real64, &
            30.557000_real64, &
            25.500000_real64, &
            21.418000_real64, &
            16.655000_real64, &
            16.138000_real64, &
            15.665000_real64, &
            14.597000_real64, &
            13.546000_real64, &
            12.527000_real64, &
            11.567000_real64, &
            10.733000_real64, &
            10.059000_real64, &
            9.455000_real64, &
            9.090000_real64, &
            8.026000_real64, &
            6.954000_real64, &
            5.875000_real64, &
            4.794000_real64, &
            3.756000_real64, &
            2.804000_real64, &
            2.065000_real64, &
            1.774000_real64, &
            0.744000_real64, &
            29.637000_real64, &
            25.001000_real64, &
            20.904000_real64, &
            16.024000_real64, &
            15.543000_real64, &
            14.991000_real64, &
            13.932000_real64, &
            12.902000_real64, &
            11.922000_real64, &
            11.025000_real64, &
            10.273000_real64, &
            9.678000_real64, &
            9.166000_real64, &
            8.799000_real64, &
            7.721000_real64, &
            6.637000_real64, &
            5.551000_real64, &
            4.472000_real64, &
            3.459000_real64, &
            2.569000_real64, &
            1.950000_real64, &
            1.701000_real64, &
            0.676000_real64, &
            28.718000_real64, &
            24.451000_real64, &
            20.344000_real64, &
            15.430000_real64, &
            14.941000_real64, &
            14.301000_real64, &
            13.263000_real64, &
            12.270000_real64, &
            11.345000_real64, &
            10.525000_real64, &
            9.857000_real64, &
            9.334000_real64, &
            8.888000_real64, &
            8.483000_real64, &
            7.395000_real64, &
            6.304000_real64, &
            5.218000_real64, &
            4.153000_real64, &
            3.179000_real64, &
            2.365000_real64, &
            1.863000_real64, &
            1.624000_real64, &
            0.608000_real64, &
            27.822000_real64, &
            23.857000_real64, &
            19.748000_real64, &
            14.859000_real64, &
            14.334000_real64, &
            13.615000_real64, &
            12.611000_real64, &
            11.668000_real64, &
            10.811000_real64, &
            10.074000_real64, &
            9.487000_real64, &
            9.023000_real64, &
            8.613000_real64, &
            8.150000_real64, &
            7.055000_real64, &
            5.964000_real64, &
            4.886000_real64, &
            3.847000_real64, &
            2.924000_real64, &
            2.197000_real64, &
            1.796000_real64, &
            1.543000_real64, &
            0.542000_real64, &
            26.962000_real64, &
            23.229000_real64, &
            19.126000_real64, &
            14.304000_real64, &
            13.728000_real64, &
            12.949000_real64, &
            11.991000_real64, &
            11.109000_real64, &
            10.327000_real64, &
            9.673000_real64, &
            9.158000_real64, &
            8.735000_real64, &
            8.335000_real64, &
            7.805000_real64, &
            6.709000_real64, &
            5.623000_real64, &
            4.563000_real64, &
            3.560000_real64, &
            2.699000_real64, &
            2.060000_real64, &
            1.742000_real64, &
            1.460000_real64, &
            0.481000_real64, &
            26.145000_real64, &
            22.574000_real64, &
            18.488000_real64, &
            13.760000_real64, &
            13.130000_real64, &
            12.315000_real64, &
            11.413000_real64, &
            10.598000_real64, &
            9.894000_real64, &
            9.319000_real64, &
            8.862000_real64, &
            8.465000_real64, &
            8.052000_real64, &
            7.454000_real64, &
            6.362000_real64, &
            5.289000_real64, &
            4.254000_real64, &
            3.297000_real64, &
            2.503000_real64, &
            1.951000_real64, &
            1.693000_real64, &
            1.377000_real64, &
            0.424000_real64, &
            25.372000_real64, &
            21.900000_real64, &
            17.517000_real64, &
            13.225000_real64, &
            12.550000_real64, &
            11.721000_real64, &
            10.881000_real64, &
            10.138000_real64, &
            9.510000_real64, &
            9.004000_real64, &
            8.592000_real64, &
            8.205000_real64, &
            7.764000_real64, &
            7.102000_real64, &
            6.020000_real64, &
            4.965000_real64, &
            3.963000_real64, &
            3.058000_real64, &
            2.336000_real64, &
            1.864000_real64, &
            1.648000_real64, &
            1.295000_real64, &
            0.373000_real64, &
            24.641000_real64, &
            21.214000_real64, &
            17.193000_real64, &
            12.701000_real64, &
            11.994000_real64, &
            11.172000_real64, &
            10.398000_real64, &
            9.727000_real64, &
            9.170000_real64, &
            8.722000_real64, &
            8.341000_real64, &
            7.951000_real64, &
            7.471000_real64, &
            6.754000_real64, &
            5.685000_real64, &
            4.655000_real64, &
            3.693000_real64, &
            2.846000_real64, &
            2.195000_real64, &
            1.795000_real64, &
            1.604000_real64, &
            1.214000_real64, &
            0.328000_real64, &
            23.947000_real64, &
            20.523000_real64, &
            16.551000_real64, &
            12.194000_real64, &
            11.468000_real64, &
            10.671000_real64, &
            9.964000_real64, &
            9.363000_real64, &
            8.869000_real64, &
            8.467000_real64, &
            8.103000_real64, &
            7.698000_real64, &
            7.176000_real64, &
            6.412000_real64, &
            5.363000_real64, &
            4.363000_real64, &
            3.445000_real64, &
            2.658000_real64, &
            2.077000_real64, &
            1.739000_real64, &
            1.559000_real64, &
            1.136000_real64, &
            0.287000_real64, &
            23.288000_real64, &
            19.832000_real64, &
            15.920000_real64, &
            11.705000_real64, &
            10.977000_real64, &
            10.216000_real64, &
            9.576000_real64, &
            9.039000_real64, &
            8.600000_real64, &
            8.231000_real64, &
            7.873000_real64, &
            7.446000_real64, &
            6.881000_real64, &
            6.079000_real64, &
            5.054000_real64, &
            4.089000_real64, &
            3.219000_real64, &
            2.494000_real64, &
            1.979000_real64, &
            1.692000_real64, &
            1.513000_real64, &
            1.060000_real64, &
            0.251000_real64, &
            22.656000_real64, &
            19.146000_real64, &
            15.304000_real64, &
            11.240000_real64, &
            10.521000_real64, &
            9.807000_real64, &
            9.231000_real64, &
            8.752000_real64, &
            8.357000_real64, &
            8.011000_real64, &
            7.648000_real64, &
            7.194000_real64, &
            6.588000_real64, &
            5.758000_real64, &
            4.761000_real64, &
            3.834000_real64, &
            3.014000_real64, &
            2.351000_real64, &
            1.897000_real64, &
            1.652000_real64, &
            1.465000_real64, &
            0.988000_real64, &
            0.220000_real64, &
            22.048000_real64, &
            18.469000_real64, &
            14.707000_real64, &
            10.800000_real64, &
            10.103000_real64, &
            9.441000_real64, &
            8.923000_real64, &
            8.494000_real64, &
            8.134000_real64, &
            7.800000_real64, &
            7.426000_real64, &
            6.943000_real64, &
            6.298000_real64, &
            5.451000_real64, &
            4.484000_real64, &
            3.599000_real64, &
            2.831000_real64, &
            2.227000_real64, &
            1.829000_real64, &
            1.616000_real64, &
            1.417000_real64, &
            0.920000_real64, &
            0.193000_real64, &
            21.459000_real64, &
            17.805000_real64, &
            14.132000_real64, &
            10.388000_real64, &
            9.722000_real64, &
            9.113000_real64, &
            8.649000_real64, &
            8.262000_real64, &
            7.928000_real64, &
            7.597000_real64, &
            7.205000_real64, &
            6.691000_real64, &
            6.015000_real64, &
            5.158000_real64, &
            4.225000_real64, &
            3.383000_real64, &
            2.667000_real64, &
            2.120000_real64, &
            1.771000_real64, &
            1.583000_real64, &
            1.369000_real64, &
            0.856000_real64, &
            0.169000_real64, &
            20.887000_real64, &
            17.157000_real64, &
            13.581000_real64, &
            10.004000_real64, &
            9.375000_real64, &
            8.820000_real64, &
            8.403000_real64, &
            8.051000_real64, &
            7.733000_real64, &
            7.398000_real64, &
            6.985000_real64, &
            6.442000_real64, &
            5.739000_real64, &
            4.880000_real64, &
            3.983000_real64, &
            3.186000_real64, &
            2.522000_real64, &
            2.028000_real64, &
            1.723000_real64, &
            1.551000_real64, &
            1.320000_real64, &
            0.795000_real64, &
            0.148000_real64, &
            20.328000_real64, &
            16.528000_real64, &
            13.055000_real64, &
            9.650000_real64, &
            9.061000_real64, &
            8.558000_real64, &
            8.181000_real64, &
            7.856000_real64, &
            7.547000_real64, &
            7.202000_real64, &
            6.766000_real64, &
            6.194000_real64, &
            5.471000_real64, &
            4.617000_real64, &
            3.759000_real64, &
            3.006000_real64, &
            2.393000_real64, &
            1.948000_real64, &
            1.681000_real64, &
            1.520000_real64, &
            1.270000_real64, &
            0.738000_real64, &
            0.130000_real64, &
            19.780000_real64, &
            15.919000_real64, &
            12.556000_real64, &
            9.324000_real64, &
            8.778000_real64, &
            8.322000_real64, &
            7.979000_real64, &
            7.673000_real64, &
            7.367000_real64, &
            7.008000_real64, &
            6.548000_real64, &
            5.951000_real64, &
            5.214000_real64, &
            4.370000_real64, &
            3.551000_real64, &
            2.844000_real64, &
            2.278000_real64, &
            1.880000_real64, &
            1.644000_real64, &
            1.489000_real64, &
            1.221000_real64, &
            0.686000_real64, &
            0.115000_real64, &
            19.242000_real64, &
            15.332000_real64, &
            12.083000_real64, &
            9.025000_real64, &
            8.522000_real64, &
            8.110000_real64, &
            7.794000_real64, &
            7.501000_real64, &
            7.190000_real64, &
            6.815000_real64, &
            6.330000_real64, &
            5.712000_real64, &
            4.967000_real64, &
            4.139000_real64, &
            3.360000_real64, &
            2.697000_real64, &
            2.178000_real64, &
            1.821000_real64, &
            1.611000_real64, &
            1.458000_real64, &
            1.173000_real64, &
            0.636000_real64, &
            0.101000_real64, &
            18.713000_real64, &
            14.767000_real64, &
            11.638000_real64, &
            8.752000_real64, &
            8.290000_real64, &
            7.917000_real64, &
            7.621000_real64, &
            7.335000_real64, &
            7.017000_real64, &
            6.622000_real64, &
            6.115000_real64, &
            5.480000_real64, &
            4.731000_real64, &
            3.923000_real64, &
            3.183000_real64, &
            2.564000_real64, &
            2.089000_real64, &
            1.770000_real64, &
            1.581000_real64, &
            1.427000_real64, &
            1.125000_real64, &
            0.591000_real64, &
            0.090000_real64, &
            18.193000_real64, &
            14.227000_real64, &
            11.219000_real64, &
            8.502000_real64, &
            8.080000_real64, &
            7.739000_real64, &
            7.459000_real64, &
            7.174000_real64, &
            6.845000_real64, &
            6.431000_real64, &
            5.902000_real64, &
            5.253000_real64, &
            4.506000_real64, &
            3.722000_real64, &
            3.022000_real64, &
            2.445000_real64, &
            2.011000_real64, &
            1.725000_real64, &
            1.553000_real64, &
            1.395000_real64, &
            1.078000_real64, &
            0.548000_real64, &
            0.079000_real64, &
            17.682000_real64, &
            13.711000_real64, &
            10.827000_real64, &
            8.275000_real64, &
            7.889000_real64, &
            7.575000_real64, &
            7.305000_real64, &
            7.017000_real64, &
            6.674000_real64, &
            6.240000_real64, &
            5.692000_real64, &
            5.034000_real64, &
            4.293000_real64, &
            3.535000_real64, &
            2.874000_real64, &
            2.338000_real64, &
            1.942000_real64, &
            1.685000_real64, &
            1.526000_real64, &
            1.362000_real64, &
            1.033000_real64, &
            0.509000_real64, &
            0.071000_real64 &
    ], shape=[26,23], order=[2,1])

contains

    ! Convert string to lowercase
    pure function to_lower(str) result(lower_str)
            character(len=*), intent(in) :: str
            character(len=len(str)) :: lower_str
            integer :: i, ic
            lower_str = str
            do i = 1, len(str)
                    ic = iachar(str(i:i))
                    if (ic >= 65 .and. ic <= 90) lower_str(i:i) = achar(ic + 32)
            end do
    end function to_lower

    !---------------------------------------------------------------------------
    ! Function: get_f0
    !
    ! Description:
    !   Returns the atomic form factor for a given element at a specific Q.
    !
    ! Arguments:
    !   q       [in]  - Scattering vector magnitude (sin θ)/λ in Å⁻¹
    !   element [in]  - Element symbol (case-insensitive, e.g., 'Fe', 'cu')
    !
    ! Returns:
    !   f0_val - Atomic form factor (electrons)
    !
    ! Notes:
    !   - Q is rounded to nearest 0.01 Å⁻¹ for lookup
    !   - Program stops with error if element or Q not found
    !---------------------------------------------------------------------------
    function get_f0(q, element) result(f0_val)
            real(real64), intent(in) :: q
            character(len=*), intent(in) :: element
            real(real64) :: f0_val
            integer :: q_idx, elem_idx, i
            real(real64) :: q_round
            character(len=10) :: element_lower

            ! Convert element to lower case
            element_lower = to_lower(element)

            ! Round q to nearest 0.01 Å⁻¹
            q_round = ceiling(q * 100_real64) / 100_real64

            ! Find element index
            elem_idx = -1
            do i = 1, n_elements
                    if (trim(elements(i)) == trim(element_lower)) then
                            elem_idx = i
                            EXIT
                    end if
            end do

            if (elem_idx == -1) then
                    write(*, '(A, A, A)') 'ERROR in get_f0: Element "', &
                            trim(element), '" not found'
                    error stop
            end if

            ! Find Q index
            q_idx = -1
            do i = 1, n_q_values
                    if (abs(q_values(i) - q_round) < 1.0e-6_real64) then
                            q_idx = i
                            EXIT
                    end if
            end do

            if (q_idx == -1) then
                    write(*, '(A, F12.6, A)') 'ERROR in get_f0: Q value ', &
                            q_round, ' not found in table'
                    error stop
            end if

            ! Access f0 value and return
            f0_val = f0_data(q_idx, elem_idx)

    end function get_f0

end module f0_mod
