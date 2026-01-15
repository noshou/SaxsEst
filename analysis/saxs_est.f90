! cli module
module main_mod
    use, intrinsic :: iso_c_binding
    use kdt_mod; use atom_mod; use estimate_mod
    use form_fact_mod; use csv_interface_mod

    ! generated atom modules "use"
    include "mod_uses.inc"

    implicit none
    private

    public :: cli, run_single

contains

    !> Deletes a file if it exists.
    !> Used to clean up partial output files when analysis fails.
    !> @param filepath - path to file to delete
    subroutine delete_file_if_exists(filepath)
        character(len=*), intent(in) :: filepath
        integer :: del_unit, del_stat
        logical :: file_exists

        inquire(file=filepath, exist=file_exists)
        if (file_exists) then
            del_unit = 99
            open(unit=del_unit, file=filepath, status='old', iostat=del_stat)
            if (del_stat == 0) then
                close(del_unit, status='delete')
                print*, "  Deleted: ", trim(filepath)
            end if
        end if
    end subroutine delete_file_if_exists

    !! command line interface for running tests
    subroutine cli(xyz_module_list_path, out_dir)

        ! file paths
        character(len=*), intent(in) :: xyz_module_list_path
        character(len=*), intent(in) :: out_dir
        character(len=:), allocatable :: path, path1, path2, path3, path4, cmd, cmd2

        ! input data
        type(kdt) :: kdt_tree
        type(atom), dimension(:), allocatable :: atoms
        real(c_double), allocatable :: q_vals(:)
        character(len=256) :: name

        ! variables for file I/O
        integer :: xyz_unit, iostat_val, s, end_pos, m, atms
        character(len=256) :: buff, mode
        character(len=*), parameter :: xyz_start_match = "xyz_"
        character(len=*), parameter :: xyz_end_match = "_mod.mod"

        ! user cli inputs
        real :: a_, e_, r_
        real(c_double) :: a, e, r
        logical :: c

        ! analysis results
        type(estimate) :: deby_rad, deby_kdt, prop_rad, prop_kdt

        ! subprocess handling for error recovery
        integer :: exit_status
        character(len=32) :: a_str, e_str, r_str, c_str
        character(len=512) :: exe_path
        character(len=2048) :: subprocess_cmd

        ! open xyz modules for analysis
        xyz_unit = 10
        open(unit=xyz_unit, file=xyz_module_list_path, status="old", iostat=iostat_val)
        if (iostat_val .ne. 0) then
            print*, "Error opening xyz_modules.txt! Exiting..."
            stop
        end if

        ! get path to this executable for self-invocation
        call get_command_argument(0, exe_path)

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
            include "mod_switches.inc"
            atms = size(atoms)

            ! build KD-tree
            kdt_tree = kdt_creator(atoms)

            print*, ""
            print*, "===================="
            print*, "Analyzing:    ", trim(name)

            ! display number of atoms
            print*, "Number of atoms (n):", atms
            print*, ""
            ! prompt user for advice
            do while (.true.)
                print*, "Input advice parameter ñ (must be ≥ n): "
                read(*,*) a_
                if (a_ .ge. atms) then
                    a = real(a_, kind=c_double)
                    write(a_str, '(ES23.16)') a
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
                    write(e_str, '(ES23.16)') e
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
                    write(r_str, '(ES23.16)') r
                    exit
                else
                    print*, "r must be > 0"
                end if
            end do

            ! prompt user for rounding mode
            do while (.true.)
                print*, "Rounding mode:"
                print*, "  DOWN: round down"
                print*, "  UP:   round up"
                write(*, '(A)', advance='no') "Enter choice: "
                read(*,*) mode
                if (mode .eq. "DOWN" ) then
                    c = .false.
                    c_str = "0"
                    exit
                else if (mode .eq. "UP") then
                    c = .true.
                    c_str = "1"
                    exit
                else
                    print*, "Invalid input! Please enter DOWN or UP"
                end if
            end do

            ! Define output file paths for potential cleanup
            path1 = trim(out_dir)//"/"//"debye_radial_"//trim(name)//".csv"
            path2 = trim(out_dir)//"/"//"debye_kdt_"//trim(name)//".csv"
            path3 = trim(out_dir)//"/"//"prop_radial_"//trim(name)//".csv"
            path4 = trim(out_dir)//"/"//"prop_kdt_"//trim(name)//".csv"

            ! Self-invoke as subprocess with --run-single flag.
            ! This isolates ERROR STOP failures to the subprocess, allowing
            ! the parent to catch the non-zero exit status and continue.
            subprocess_cmd = trim(exe_path)//" --run-single "// &
                  trim(name)//" "// &
                  trim(out_dir)//" "// &
                  trim(adjustl(a_str))//" "// &
                  trim(adjustl(e_str))//" "// &
                  trim(adjustl(r_str))//" "// &
                  trim(adjustl(c_str))

            call execute_command_line(trim(subprocess_cmd), wait=.true., exitstat=exit_status)

            ! Handle subprocess failure: cleanup partial outputs and continue
            if (exit_status /= 0) then
                print*, ""
                print*, "**************************************"
                print*, "ABORTING ", trim(name), "; CONTINUING ANALYSIS..."
                print*, "**************************************"

                ! Delete any partial output files created before the error
                call delete_file_if_exists(path1)
                call delete_file_if_exists(path2)
                call delete_file_if_exists(path3)
                call delete_file_if_exists(path4)

                print*, "===================="
                cycle  ! Continue to next molecule
            end if

            print*, "===================="

        end do

        print*, ""
        print*, "All molecules processed."
        close(xyz_unit)
    end subroutine cli

    !> Entry point for subprocess mode (--run-single).
    !> Runs analysis for a single molecule; any ERROR STOP will terminate
    !> only this subprocess, not the parent process.
    !> @param name - molecule name
    !> @param out_dir - output directory
    !> @param a - advice parameter
    !> @param e - epsilon parameter
    !> @param r - search radius
    !> @param c_int - rounding mode (0 = DOWN, 1 = UP)
    subroutine run_single(name, out_dir, a, e, r, c_int)
        character(len=*), intent(in) :: name
        character(len=*), intent(in) :: out_dir
        real(c_double), intent(in) :: a, e, r
        integer, intent(in) :: c_int

        ! locals
        type(kdt) :: kdt_tree
        type(atom), dimension(:), allocatable :: atoms
        real(c_double), allocatable :: q_vals(:)
        logical :: c
        character(len=:), allocatable :: path, path1, path2, path3, path4, cmd
        type(estimate) :: deby_rad, deby_kdt, prop_rad, prop_kdt

        c = (c_int == 1)

        ! Load atoms for this molecule
        include "mod_switches.inc"

        ! Build KD-tree
        kdt_tree = kdt_creator(atoms)

        ! Get q values
        q_vals = get_q_values()

        ! Define output paths
        path1 = trim(out_dir)//"/"//"debye_radial_"//trim(name)//".csv"
        path2 = trim(out_dir)//"/"//"debye_kdt_"//trim(name)//".csv"
        path3 = trim(out_dir)//"/"//"prop_radial_"//trim(name)//".csv"
        path4 = trim(out_dir)//"/"//"prop_kdt_"//trim(name)//".csv"

        ! Run raw analysis
        ! Any ERROR STOP here will exit this subprocess with non-zero status,
        ! which the parent process will catch and handle gracefully.

        print*, "Running debyeEst_radial..."
        deby_rad = debyeEst_radial(atoms, q_vals)
        path    = path1
        call est_wrap(deby_rad, path)
        print*, "timing: ", deby_rad%timing, "s"
        print*, ""

        print*, "Running debyeEst_kdt..."
        deby_kdt = debyeEst_kdt(kdt_tree, r, q_vals)
        path    = path2
        call est_wrap(deby_kdt, path)
        print*, "timing: ", deby_kdt%timing, "s"
        print*, ""

        print*, "Running propEst_radial..."
        prop_rad = propEst_radial(kdt_tree, q_vals, a, e, c)
        path     = path3
        call est_wrap(prop_rad, path)
        print*, "timing: ", prop_rad%timing, "s"
        print*, ""

        print*, "Running propEst_kdt..."
        prop_kdt = propEst_kdt(kdt_tree, r, q_vals, a, e, c)
        path     = path4
        call est_wrap(prop_kdt, path)
        print*, "timing: ", prop_kdt%timing, "s"

        ! Run R analysis
        cmd = "Rscript analysis/standardize.R "//trim(out_dir)//" "// &
            trim(path1)//" "//trim(path2)//" "//trim(path3)//" "//trim(path4)
        print*, ""
        call execute_command_line(trim(cmd))

        print*, "Finished analysis of ", trim(name)

    end subroutine run_single

end module main_mod

program saxs_est

    use, intrinsic :: iso_c_binding
    use main_mod
    use, intrinsic :: iso_fortran_env
    implicit none

    ! local variables
    integer :: arg_num
    character(len=256) :: arg1, xyz_module_list_path, out_dir

    ! subprocess mode variables
    character(len=256) :: name_arg, out_dir_arg, a_arg, e_arg, r_arg, c_arg
    real(c_double) :: a_val, e_val, r_val
    integer :: c_val

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

    ! check for subprocess mode (--run-single)
    ! This mode is invoked internally by the main CLI to isolate ERROR STOP failures.
    ! When a molecule's analysis hits an ERROR STOP, only the subprocess terminates,
    ! allowing the parent process to catch the failure and continue with the next molecule.
    ! Usage: saxs_est --run-single <name> <out_dir> <a> <e> <r> <c>
    if (arg_num >= 1) then
        call get_command_argument(1, arg1)
        if (trim(arg1) == '--run-single') then
            if (arg_num /= 7) then
                write(error_unit, '(A)') "ERROR: --run-single requires 6 arguments"
                write(error_unit, '(A)') "Internal usage: saxs_est --run-single <name> <out_dir> <a> <e> <r> <c>"
                stop 1
            end if

            call get_command_argument(2, name_arg)
            call get_command_argument(3, out_dir_arg)
            call get_command_argument(4, a_arg)
            call get_command_argument(5, e_arg)
            call get_command_argument(6, r_arg)
            call get_command_argument(7, c_arg)

            read(a_arg, *) a_val
            read(e_arg, *) e_val
            read(r_arg, *) r_val
            read(c_arg, *) c_val

            call run_single(trim(name_arg), trim(out_dir_arg), a_val, e_val, r_val, c_val)
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
