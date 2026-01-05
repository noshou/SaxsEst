! cli module
module main_mod
    use, intrinsic :: iso_c_binding
    use kdt_mod; use atom_mod; use estimate_mod
    use form_fact_mod; use csv_interface_mod
    
    ! generated atom modules "use"
    include "_build/inc/mod_uses.inc"

    implicit none
    private
    
    public :: cli

contains
    !! command line interface for running tests
    subroutine cli(xyz_module_list_path, out_dir)
        
        ! file paths
        character(len=*), intent(in) :: xyz_module_list_path  ! FIXED: Added
        character(len=*), intent(in) :: out_dir
        character(len=:), allocatable :: path
        
        ! input data
        type(kdt) :: kdt_tree
        type(atom), dimension(:), allocatable :: atoms  
        real(c_double), allocatable :: q_vals(:)
        character(len=256) :: name
        
        ! variables for file I/O
        integer :: xyz_unit, iostat_val, s, end_pos, m, atms  ! FIXED: Added atms
        character(len=256) :: buff, mode
        character(len=*), parameter :: xyz_start_match = "xyz_"
        character(len=*), parameter :: xyz_end_match = "_mod.mod"
        
        ! user cli inputs
        real :: a_, e_, r_
        real(c_double) :: a, e, r
        logical :: c
        
        ! analysis results
        type(estimate) :: deby_rad, deby_kdt, prop_rad, prop_kdt
                    
        ! open xyz modules for analysis
        xyz_unit = 10
        open(unit=xyz_unit, file=xyz_module_list_path, status="old", iostat=iostat_val)
        if (iostat_val .ne. 0) then 
            print*, "Error opening xyz_modules.txt! Exiting..."
            stop 
        end if
        
        ! run analysis
        q_vals = get_q_values()
        do 
            read(xyz_unit, "(A)", iostat=iostat_val) buff
            if (iostat_val .ne. 0) exit  ! Exit on EOF or error

            ! match name of molecule
            s = len(xyz_start_match)
            end_pos = len(xyz_end_match)
            m = len(trim(buff)) - s - end_pos
            name = trim(buff(s+1:len_trim(buff) - end_pos))
            
            ! add switch cases here - defines which atom module to use
            include "_build/inc/mod_switches.inc"
            atms = size(atoms)

            ! build KD-tree
            kdt_tree = kdt_creator(atoms)
            

            ! display number of atoms
            print*, "Number of atoms (n):", atms
            
            ! prompt user for advice
            do while (.true.)
                print*, "Input advice parameter a (must be ≥ ñ): "
                read(*,*) a_
                if (a_ .ge. atms) then
                    a = real(a_, kind=c_double)
                    exit
                else
                    print*, "ñ must be ≥ n, please retry"
                end if
            end do 
            
            ! prompt user for epsilon value
            do while (.true.)
                print*, "Input epsilon parameter ε (0 < ε < 1): "
                read(*,*) e_
                if (e_ .gt. 0 .and. e_ .lt. 1) then 
                    e = real(e_, kind=c_double)
                    exit
                else
                    print*, "must be 0 < ε < 1, please retry"
                end if
            end do
            
            ! prompt user for radius
            do while (.true.)
                print*, "Input search radius: "
                read(*,*) r_
                if (r_ > 0) then 
                    r = real(r_, kind=c_double)
                    exit
                else 
                    print*, "r must be > 0"
                end if
            end do

            ! prompt user for rounding mode
            do while (.true.)
                print*, "Rounding mode: \n\tDOWN:\tround down\n\tUP:\tround up: "
                read(*,*) mode
                if (mode .eq. "DOWN" ) then 
                    c = .false.
                    exit
                else if (mode .eq. "UP") then
                    c = .true.
                    exit
                else 
                    print*, "Invalid input!"
                end if
            end do
            
            print*, ""
            print*, "===================="
            print*, "Analyzing:\t", trim(name)
            
            
            print*, "Running debeyeEst_radial..."
            deby_rad = debeyeEst_radial(atoms, q_vals)  ! FIXED: atoms not kdt_tree
            path    = out_dir//"/"//"debeye_radial_"//name//".csv"
            call est_wrap(deby_rad, path)
            print*, "analysis saved at: ", path
            print*, ""

            print*, "Running debeyeEst_kdt..."
            deby_kdt = debeyeEst_kdt(kdt_tree, r, q_vals)
            path    = out_dir//"/"//"debeye_kdt_"//name//".csv"
            call est_wrap(deby_kdt, path)
            print*, "analysis saved at: ", path
            print*, ""

            print*, "Running propEst_radial..."
            prop_rad = propEst_radial(kdt_tree, q_vals, a, e, c)
            path     = out_dir//"/"//"prop_radial_"//name//".csv"
            call est_wrap(prop_rad, path)
            print*, "analysis saved at: ", path
            print*, ""

            print*, "Running propEst_kdt..."
            prop_kdt = propEst_kdt(kdt_tree, r, q_vals, a, e, c)
            path     = out_dir//"/"//"prop_kdt"//name//".csv"
            call est_wrap(prop_kdt, path)
            print*, "analysis saved at: ", path
            print*, ""
            
        end do 
        
        print*, ""
        print*, "===================="
        print*, ""
        print*, "Finished analysis!"
        print*, "===================="
        close(xyz_unit)
    end subroutine cli

end module main_mod

program saxs_est 
    
use, intrinsic :: iso_c_binding
use main_mod
use, intrinsic :: iso_fortran_env
implicit none

! local variables
integer :: arg_num
character(len=256) :: arg1, xyz_module_list_path, out_dir 

! get number of arguments
arg_num = command_argument_count()

! check for help flag or incorrect arguments
if (arg_num == 1) then
    call get_command_argument(1, arg1)
    if (trim(arg1) == '-h' .or. trim(arg1) == '--help') then
        call print_help()
        stop 0
    end if
end if

! validate argument count
if (arg_num /= 2) then 
    write(error_unit, '(A)') "ERROR: Invalid number of arguments"
    write(error_unit, '(A)') ""
    call print_usage()
    stop 1
end if

! get arguments and execute
call get_command_argument(1, xyz_module_list_path)
call get_command_argument(2, out_dir)
call cli(trim(xyz_module_list_path), trim(out_dir)) 

contains

    subroutine print_help()
        write(output_unit, '(A)') "saxs_est - Small Angle X-ray Scattering Estimation"
        write(output_unit, '(A)') ""
        write(output_unit, '(A)') "DESCRIPTION:"
        write(output_unit, '(A)') "  Calculates SAXS intensity profiles for protein structures"
        write(output_unit, '(A)') "  using the Debye equation and propagator methods."
        write(output_unit, '(A)') ""
        call print_usage()
        write(output_unit, '(A)') ""
        write(output_unit, '(A)') "ARGUMENTS:"
        write(output_unit, '(A)') "  xyz_module_list   Path to file containing list of XYZ modules to process"
        write(output_unit, '(A)') "  output_directory  Directory where CSV results will be written"
        write(output_unit, '(A)') ""
        write(output_unit, '(A)') "EXAMPLES:"
        write(output_unit, '(A)') "  saxs_est _build/xyz_modules.txt ./results/"
        write(output_unit, '(A)') "  saxs_est molecules.txt output/"
        write(output_unit, '(A)') ""
        write(output_unit, '(A)') "OPTIONS:"
        write(output_unit, '(A)') "  -h, --help        Display this help message"
    end subroutine print_help

    subroutine print_usage()
        write(error_unit, '(A)') "USAGE:"
        write(error_unit, '(A)') "  saxs_est <xyz_module_list> <output_directory>"
        write(error_unit, '(A)') "  saxs_est -h | --help"
    end subroutine print_usage

end program saxs_est