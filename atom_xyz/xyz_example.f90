! this is an example output of a generated xyz module (would be named xyz_chignolin.f90)

    !! Atomic coordinate data from XYZ file
!! This module provides raw coordinate data for use with atom_mod
module xyz_chignolin_mod
    use iso_c_binding, only: c_double
    implicit none

    private

    ! Public interface
    ! Public interface
    public  :: n_atoms
    private :: elements, x_coords, y_coords, z_coords
    public  :: get_atoms_chignolin

    ! Module data
    integer, parameter :: n_atoms = 135

    ! Element symbols
    character(len=4), parameter :: elements(135) = [ &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'O   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'O   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'C   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ', &
            'H   ', &
            'H   ', &
            'H   ', &
            'O   ', &
            'N   ', &
            'C   ', &
            'C   ' ]

    ! X coordinates (Angstroms)
    real(c_double), parameter :: x_coords(135) = [ &
            -1.387000_c_double, &
            -0.169000_c_double, &
            -2.159000_c_double, &
            -1.289000_c_double, &
            -1.844000_c_double, &
            -1.229000_c_double, &
            -1.877000_c_double, &
            -6.827000_c_double, &
            -7.093000_c_double, &
            -5.228000_c_double, &
            -5.766000_c_double, &
            -3.364000_c_double, &
            -2.478000_c_double, &
            -4.575000_c_double, &
            -3.295000_c_double, &
            -3.075000_c_double, &
            -1.532000_c_double, &
            -3.664000_c_double, &
            -6.248000_c_double, &
            -6.398000_c_double, &
            -5.349000_c_double, &
            -5.648000_c_double, &
            -4.608000_c_double, &
            -4.743000_c_double, &
            -3.216000_c_double, &
            -3.848000_c_double, &
            -3.640000_c_double, &
            -1.576000_c_double, &
            -1.545000_c_double, &
            -2.598000_c_double, &
            -1.960000_c_double, &
            1.885000_c_double, &
            2.533000_c_double, &
            0.813000_c_double, &
            3.275000_c_double, &
            1.018000_c_double, &
            -0.073000_c_double, &
            1.108000_c_double, &
            2.633000_c_double, &
            1.682000_c_double, &
            1.418000_c_double, &
            -0.633000_c_double, &
            1.127000_c_double, &
            0.411000_c_double, &
            -0.641000_c_double, &
            3.323000_c_double, &
            1.808000_c_double, &
            2.450000_c_double, &
            1.815000_c_double, &
            3.014000_c_double, &
            2.498000_c_double, &
            1.780000_c_double, &
            3.625000_c_double, &
            4.906000_c_double, &
            5.309000_c_double, &
            3.211000_c_double, &
            5.248000_c_double, &
            5.729000_c_double, &
            2.944000_c_double, &
            3.204000_c_double, &
            4.589000_c_double, &
            4.486000_c_double, &
            4.941000_c_double, &
            3.881000_c_double, &
            4.684000_c_double, &
            4.218000_c_double, &
            4.318000_c_double, &
            5.147000_c_double, &
            3.457000_c_double, &
            2.537000_c_double, &
            3.944000_c_double, &
            1.397000_c_double, &
            6.341000_c_double, &
            5.649000_c_double, &
            5.629000_c_double, &
            4.652000_c_double, &
            3.450000_c_double, &
            5.577000_c_double, &
            2.168000_c_double, &
            3.531000_c_double, &
            4.420000_c_double, &
            -2.232000_c_double, &
            -0.977000_c_double, &
            -1.792000_c_double, &
            -0.308000_c_double, &
            -0.670000_c_double, &
            0.750000_c_double, &
            0.567000_c_double, &
            -1.199000_c_double, &
            -0.876000_c_double, &
            -0.033000_c_double, &
            2.943000_c_double, &
            -0.311000_c_double, &
            0.579000_c_double, &
            2.002000_c_double, &
            0.055000_c_double, &
            -1.224000_c_double, &
            -1.795000_c_double, &
            -2.259000_c_double, &
            1.609000_c_double, &
            -0.069000_c_double, &
            0.418000_c_double, &
            -0.523000_c_double, &
            0.433000_c_double, &
            -2.287000_c_double, &
            -1.287000_c_double, &
            -0.301000_c_double, &
            0.765000_c_double, &
            -0.722000_c_double, &
            -1.265000_c_double, &
            -2.811000_c_double, &
            -3.352000_c_double, &
            -4.918000_c_double, &
            -5.189000_c_double, &
            -3.763000_c_double, &
            -6.203000_c_double, &
            0.304000_c_double, &
            -0.858000_c_double, &
            -1.295000_c_double, &
            -1.601000_c_double, &
            -2.474000_c_double, &
            -2.780000_c_double, &
            -3.216000_c_double, &
            -4.490000_c_double, &
            -3.252000_c_double, &
            -5.452000_c_double, &
            -4.189000_c_double, &
            -3.197000_c_double, &
            -7.085000_c_double, &
            -7.677000_c_double, &
            -7.273000_c_double, &
            -4.640000_c_double, &
            -6.778000_c_double, &
            -6.878000_c_double, &
            -5.557000_c_double ]

    ! Y coordinates (Angstroms)
    real(c_double), parameter :: y_coords(135) = [ &
            -2.946000_c_double, &
            -3.939000_c_double, &
            -2.553000_c_double, &
            -6.092000_c_double, &
            -3.461000_c_double, &
            -3.774000_c_double, &
            -5.031000_c_double, &
            -2.451000_c_double, &
            -1.796000_c_double, &
            -4.248000_c_double, &
            -2.927000_c_double, &
            -6.042000_c_double, &
            -6.628000_c_double, &
            -4.843000_c_double, &
            -6.041000_c_double, &
            -3.047000_c_double, &
            -4.627000_c_double, &
            -5.596000_c_double, &
            -2.947000_c_double, &
            -2.577000_c_double, &
            -3.958000_c_double, &
            -3.218000_c_double, &
            -4.591000_c_double, &
            -4.236000_c_double, &
            -5.882000_c_double, &
            -5.068000_c_double, &
            -5.067000_c_double, &
            -5.528000_c_double, &
            -3.955000_c_double, &
            -4.011000_c_double, &
            -4.395000_c_double, &
            -4.210000_c_double, &
            -5.563000_c_double, &
            -5.501000_c_double, &
            -4.296000_c_double, &
            -4.825000_c_double, &
            -3.195000_c_double, &
            -1.125000_c_double, &
            -3.587000_c_double, &
            -4.912000_c_double, &
            -4.147000_c_double, &
            -2.164000_c_double, &
            -1.719000_c_double, &
            -3.025000_c_double, &
            -3.013000_c_double, &
            -0.049000_c_double, &
            0.760000_c_double, &
            0.749000_c_double, &
            -2.091000_c_double, &
            0.272000_c_double, &
            -0.018000_c_double, &
            -1.368000_c_double, &
            -0.188000_c_double, &
            -1.371000_c_double, &
            0.265000_c_double, &
            -2.440000_c_double, &
            -1.709000_c_double, &
            0.510000_c_double, &
            1.248000_c_double, &
            -1.540000_c_double, &
            -0.535000_c_double, &
            -0.974000_c_double, &
            -0.687000_c_double, &
            1.383000_c_double, &
            0.239000_c_double, &
            -0.101000_c_double, &
            4.985000_c_double, &
            4.918000_c_double, &
            2.580000_c_double, &
            4.084000_c_double, &
            4.648000_c_double, &
            3.406000_c_double, &
            3.640000_c_double, &
            2.193000_c_double, &
            3.303000_c_double, &
            4.334000_c_double, &
            3.614000_c_double, &
            2.766000_c_double, &
            3.542000_c_double, &
            3.694000_c_double, &
            2.567000_c_double, &
            3.677000_c_double, &
            4.125000_c_double, &
            5.679000_c_double, &
            5.921000_c_double, &
            4.630000_c_double, &
            5.467000_c_double, &
            2.732000_c_double, &
            3.960000_c_double, &
            5.221000_c_double, &
            4.752000_c_double, &
            3.738000_c_double, &
            2.922000_c_double, &
            3.407000_c_double, &
            3.580000_c_double, &
            -0.151000_c_double, &
            0.346000_c_double, &
            2.207000_c_double, &
            -0.588000_c_double, &
            1.463000_c_double, &
            2.762000_c_double, &
            1.724000_c_double, &
            0.687000_c_double, &
            0.826000_c_double, &
            0.349000_c_double, &
            1.320000_c_double, &
            1.677000_c_double, &
            0.437000_c_double, &
            1.818000_c_double, &
            -2.429000_c_double, &
            1.973000_c_double, &
            -2.273000_c_double, &
            0.937000_c_double, &
            -0.788000_c_double, &
            -1.288000_c_double, &
            0.317000_c_double, &
            -0.402000_c_double, &
            -0.315000_c_double, &
            0.927000_c_double, &
            -1.470000_c_double, &
            1.015000_c_double, &
            -1.383000_c_double, &
            -0.141000_c_double, &
            -0.048000_c_double, &
            1.898000_c_double, &
            -0.212000_c_double, &
            -0.302000_c_double, &
            0.744000_c_double, &
            0.336000_c_double, &
            -1.140000_c_double, &
            -0.879000_c_double, &
            -1.504000_c_double, &
            -1.424000_c_double, &
            -0.708000_c_double, &
            -0.840000_c_double ]

    ! Z coordinates (Angstroms)
    real(c_double), parameter :: z_coords(135) = [ &
            5.106000_c_double, &
            4.305000_c_double, &
            2.918000_c_double, &
            4.882000_c_double, &
            3.109000_c_double, &
            4.431000_c_double, &
            5.014000_c_double, &
            -4.564000_c_double, &
            -2.187000_c_double, &
            -5.180000_c_double, &
            -0.422000_c_double, &
            -3.968000_c_double, &
            -1.618000_c_double, &
            0.980000_c_double, &
            0.800000_c_double, &
            0.957000_c_double, &
            -0.892000_c_double, &
            -3.150000_c_double, &
            -3.799000_c_double, &
            -2.455000_c_double, &
            -4.146000_c_double, &
            -1.454000_c_double, &
            -3.148000_c_double, &
            -1.786000_c_double, &
            -1.873000_c_double, &
            -0.996000_c_double, &
            0.487000_c_double, &
            2.417000_c_double, &
            -0.184000_c_double, &
            0.868000_c_double, &
            2.205000_c_double, &
            -3.104000_c_double, &
            -2.176000_c_double, &
            -2.562000_c_double, &
            -0.450000_c_double, &
            -0.273000_c_double, &
            -2.224000_c_double, &
            -0.531000_c_double, &
            -0.532000_c_double, &
            -2.308000_c_double, &
            -1.011000_c_double, &
            0.707000_c_double, &
            -1.310000_c_double, &
            -1.274000_c_double, &
            -0.162000_c_double, &
            -3.071000_c_double, &
            -2.670000_c_double, &
            -0.363000_c_double, &
            -3.362000_c_double, &
            -1.008000_c_double, &
            -2.375000_c_double, &
            -2.385000_c_double, &
            3.464000_c_double, &
            3.728000_c_double, &
            3.208000_c_double, &
            1.757000_c_double, &
            1.456000_c_double, &
            0.729000_c_double, &
            1.514000_c_double, &
            1.423000_c_double, &
            3.123000_c_double, &
            1.661000_c_double, &
            -1.449000_c_double, &
            1.261000_c_double, &
            0.748000_c_double, &
            -0.669000_c_double, &
            4.823000_c_double, &
            3.267000_c_double, &
            3.727000_c_double, &
            3.756000_c_double, &
            1.600000_c_double, &
            1.904000_c_double, &
            5.529000_c_double, &
            4.090000_c_double, &
            4.597000_c_double, &
            4.030000_c_double, &
            3.418000_c_double, &
            1.055000_c_double, &
            1.315000_c_double, &
            1.893000_c_double, &
            1.368000_c_double, &
            0.991000_c_double, &
            2.167000_c_double, &
            -0.042000_c_double, &
            0.895000_c_double, &
            -1.773000_c_double, &
            -1.123000_c_double, &
            -1.353000_c_double, &
            1.121000_c_double, &
            0.298000_c_double, &
            -0.911000_c_double, &
            -0.731000_c_double, &
            0.557000_c_double, &
            -0.513000_c_double, &
            0.021000_c_double, &
            2.889000_c_double, &
            3.997000_c_double, &
            2.427000_c_double, &
            1.846000_c_double, &
            3.911000_c_double, &
            4.283000_c_double, &
            3.866000_c_double, &
            3.249000_c_double, &
            0.502000_c_double, &
            1.560000_c_double, &
            2.084000_c_double, &
            0.964000_c_double, &
            -4.234000_c_double, &
            -3.303000_c_double, &
            -3.660000_c_double, &
            -1.975000_c_double, &
            -2.332000_c_double, &
            -1.380000_c_double, &
            -1.616000_c_double, &
            0.328000_c_double, &
            0.660000_c_double, &
            -4.307000_c_double, &
            -3.568000_c_double, &
            -3.091000_c_double, &
            -3.293000_c_double, &
            -2.342000_c_double, &
            -2.544000_c_double, &
            -2.068000_c_double, &
            -1.264000_c_double, &
            0.342000_c_double, &
            0.999000_c_double, &
            0.213000_c_double, &
            0.717000_c_double, &
            3.073000_c_double, &
            2.309000_c_double, &
            4.933000_c_double, &
            2.579000_c_double, &
            4.200000_c_double, &
            2.896000_c_double, &
            2.138000_c_double ]

contains

    ! Returns all atoms as an array of atom objects
    ! Requires: use atom_mod, only: atom, coord, create_atom
    function get_atoms_xyz_chignolin() result(atoms)
            use atom_mod, only: atom, coord, create_atom
            type(atom) :: atoms(n_atoms)
            type(coord) :: position
            integer :: i

            do i = 1, n_atoms
                    position%x = x_coords(i)
                    position%y = y_coords(i)
                    position%z = z_coords(i)
                    atoms(i) = create_atom(position, elements(i))
            end do
    end function get_atoms_xyz_chignolin

end module xyz_chignolin_mod
