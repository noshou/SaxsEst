! cli module
module Main
    use, intrinsic :: iso_c_binding
    use AtomXYZ; use Est
    use FormFact; use CsvInterface
    use Freq

    ! generated atom modules "use"
    include "mod_uses.inc"

    implicit none
    private

    public :: cli, runSingle

contains

    !> Deletes a file if it exists.
    !> Used to clean up partial output files when analysis fails.
    !> @param filepath - path to file to delete
    subroutine deleteFileIfExists(filepath)
        character(len=*), intent(in) :: filepath
        integer :: delUnit, delStat
        logical :: fileExists

        inquire(file=filepath, exist=fileExists)
        if (fileExists) then
            delUnit = 99
            open(unit=delUnit, file=filepath, status='old', iostat=delStat)
            if (delStat == 0) then
                close(delUnit, status='delete')
                print*, "  Deleted: ", trim(filepath)
            end if
        end if
    end subroutine deleteFileIfExists

    !! Command line interface for running SAXS analysis.
    !!
    !! Reads a list of XYZ module files, prompts the user for analysis parameters
    !! (advice parameter, epsilon, rounding mode), then spawns a subprocess for
    !! each molecule to isolate ERROR STOP failures. If a subprocess fails, partial
    !! output files are cleaned up and analysis continues with the next molecule.
    !!
    !! @param[in] xyzModListPath  Path to file listing XYZ modules to process
    !! @param[in] outDir              Output directory for CSV results
    subroutine cli(xyzModListPath, outDir)

        ! file paths
        character(len=*), intent(in) :: xyzModListPath
        character(len=*), intent(in) :: outDir
        character(len=:), allocatable :: path, path1, path3, cmd

        ! input data
        type(frequencies) :: freq
        type(atom), dimension(:), allocatable :: atoms
        real(c_double), allocatable :: qVals(:)
        character(len=256) :: name

        ! variables for file I/O
        integer :: xyzUnit, iostatVal, s, endPos, m, atms
        character(len=256) :: buff, mode
        character(len=*), parameter :: xyzStartMatch = "xyz_"
        character(len=*), parameter :: xyzEndMatch = "_mod.mod"

        ! user cli inputs
        real :: a_, e_
        real(c_double) :: a, e
        logical :: c

        ! analysis results
        type(estimate) :: debye, prop

        ! subprocess handling for error recovery
        integer :: exitStatus
        character(len=32) :: aStr, eStr, cStr
        character(len=512) :: exePath
        character(len=2048) :: subprocCmd

        ! open xyz modules for analysis
        xyzUnit = 10
        open(unit=xyzUnit, file=xyzModListPath, status="old", iostat=iostatVal)
        if (iostatVal .ne. 0) then
            print*, "Error opening xyz_modules.txt! Exiting..."
            stop
        end if

        ! get path to this executable for self-invocation
        call get_command_argument(0, exePath)

        ! run analysis
        qVals = getQValues()
        do
            read(xyzUnit, "(A)", iostat=iostatVal) buff
            if (iostatVal .ne. 0) exit  ! exit on EOF or error

            ! match name of molecule from module filename
            s = len(xyzStartMatch)
            endPos = len(xyzEndMatch)
            m = len(trim(buff)) - s - endPos
            name = trim(buff(s+1:len_trim(buff) - endPos))

            ! load atoms from the appropriate generated module
            include "mod_switches.inc"
            atms = size(atoms)

            ! build frequency table
            freq = initFreqs(atoms)

            print*, ""
            print*, "===================="
            print*, "Analyzing:    ", trim(name)
            print*, "Number of atoms (n):", atms
            print*, ""

            ! prompt user for advice parameter
            do while (.true.)
                print*, "Input advice parameter ñ (must be >= n): "
                read(*,*) a_
                if (a_ .ge. atms) then
                    a = real(a_, kind=c_double)
                    write(aStr, '(ES23.16)') a
                    exit
                else
                    print*, "ñ must be >= n, please retry"
                end if
            end do

            ! prompt user for epsilon value
            do while (.true.)
                print*, "Input epsilon parameter Ɛ (0 < Ɛ < 1): "
                read(*,*) e_
                if (e_ .gt. 0 .and. e_ .lt. 1) then
                    e = real(e_, kind=c_double)
                    write(eStr, '(ES23.16)') e
                    exit
                else
                    print*, "must be 0 < e < 1, please retry"
                end if
            end do

            ! prompt user for rounding mode
            do while (.true.)
                print*, "Rounding mode:"
                print*, "  DOWN: round down"
                print*, "  UP:   round up"
                write(*, '(A)', advance='no') " Enter choice: "
                read(*,*) mode
                if (mode .eq. "DOWN" ) then
                    c = .false.
                    cStr = "0"
                    exit
                else if (mode .eq. "UP") then
                    c = .true.
                    cStr = "1"
                    exit
                else
                    print*, "Invalid input! Please enter DOWN or UP"
                end if
            end do

            ! define output file paths for potential cleanup
            path1 = trim(outDir)//"/"//"debye_"//trim(name)//".csv"
            path3 = trim(outDir)//"/"//"prop_"//trim(name)//".csv"

            ! self-invoke as subprocess with --run-single flag.
            ! this isolates ERROR STOP failures to the subprocess, allowing
            ! the parent to catch the non-zero exit status and continue.
            subprocCmd = trim(exePath)//" --run-single "// &
                trim(name)//" "// &
                trim(outDir)//" "// &
                trim(adjustl(aStr))//" "// &
                trim(adjustl(eStr))//" "// &
                trim(adjustl(cStr))

            call execute_command_line(trim(subprocCmd), wait=.true., exitstat=exitStatus)

            ! handle subprocess failure: cleanup partial outputs and continue
            if (exitStatus /= 0) then
                print*, ""
                print*, "**************************************"
                print*, "ABORTING ", trim(name), "; CONTINUING ANALYSIS..."
                print*, "**************************************"

                ! delete any partial output files created before the error
                call deleteFileIfExists(path1)
                call deleteFileIfExists(path3)

                print*, "===================="
                cycle  ! continue to next molecule
            end if

            print*, "===================="
        end do

        print*, ""
        print*, "All molecules processed."
        close(xyzUnit)
    end subroutine cli

    !> Entry point for subprocess mode (--run-single).
    !! Runs analysis for a single molecule. Any ERROR STOP will terminate
    !! only this subprocess, not the parent process.
    !!
    !! Performs two analyses:
    !!   1. Debye radial estimation (exact pairwise computation)
    !!   2. Proportional estimation (approximate, using frequency-based weights)
    !!
    !! After both analyses complete, invokes an R script to combine into CSVs
    !!
    !! @param[in] name    Molecule name (used to load atoms and name output files)
    !! @param[in] outDir Output directory for CSV results
    !! @param[in] a       Advice parameter for weight estimation (must be >= nAtoms)
    !! @param[in] e       Epsilon accuracy parameter (must satisfy 0 < e < 1)
    !! @param[in] c_int   Rounding mode: 0 = floor, 1 = ceiling
    subroutine runSingle(name, outDir, a, e, c_int)
        character(len=*), intent(in) :: name
        character(len=*), intent(in) :: outDir
        real(c_double), intent(in) :: a, e
        integer, intent(in) :: c_int

        ! locals
        type(frequencies) :: freq
        type(atom), dimension(:), allocatable :: atoms
        real(c_double), allocatable :: qVals(:)
        logical :: c
        character(len=:), allocatable :: path, path1, path3, cmd
        type(estimate) :: debye, prop

        ! convert integer flag to logical
        c = (c_int == 1)

        ! load atoms for this molecule
        include "mod_switches.inc"

        ! build frequency table from atom list
        freq = initFreqs(atoms)

        ! get q values for intensity calculation
        qVals = getQValues()

        ! define output paths
        path1 = trim(outDir)//"/"//"debye_"//trim(name)//".csv"
        path3 = trim(outDir)//"/"//"prop_"//trim(name)//".csv"

        ! run Debye radial analysis (exact pairwise)
        ! any ERROR STOP here will exit this subprocess with non-zero status,
        ! which the parent process will catch and handle gracefully.
        print*, ""
        print*, "Running debyeEst..."
        debye = debyeEst(atoms, qVals)
        path = path1
        call estWrap(debye, path)
        print*, "timing: ", debye%timing, "s"
        print*, ""

        ! run propagator radial analysis (approximate, frequency-weighted)
        print*, "Running propEst..."
        prop = propEst(freq, atoms, qVals, a, e, c)
        path = path3
        call estWrap(prop, path)
        print*, "timing: ", prop%timing, "s"
        print*, ""

        ! run R script to combine to output CSVs
        cmd = "Rscript SaxsEst/CsvCombine.R "//trim(outDir)//" "// &
            trim(name)//" "//trim(path1)//" "//trim(path3)
        print*, ""
        call execute_command_line(trim(cmd))

        print*, "Finished analysis of ", trim(name)

    end subroutine runSingle

end module Main

program SaxsEst
    !! Main program for SAXS intensity estimation.
    !!
    !! Supports two modes:
    !!   1. Interactive CLI mode: reads a list of molecules and prompts for parameters
    !!      Usage: SaxsEst <xyz_module_list> <output_directory>
    !!
    !!   2. Subprocess mode: runs a single molecule analysis (invoked internally)
    !!      Usage: SaxsEst --run-single <name> <outDir> <a> <e> <c>

    use, intrinsic :: iso_c_binding
    use Main
    use, intrinsic :: iso_fortran_env
    implicit none

    ! local variables
    integer :: argNum
    character(len=256) :: arg1, xyzModListPath, outDir

    ! subprocess mode variables
    character(len=256) :: nameArg, outDirArg, aArg, eArg, cArg
    real(c_double) :: aVal, eVal
    integer :: cVal

    ! get number of arguments
    argNum = command_argument_count()

    ! check for help flag
    if (argNum == 1) then
        call get_command_argument(1, arg1)
        if (trim(arg1) == '-h' .or. trim(arg1) == '--help') then
            call printHelp()
            stop 0
        end if
    end if

    ! check for subprocess mode (--run-single)
    ! this mode is invoked internally by the main CLI to isolate ERROR STOP failures.
    ! when a molecule's analysis hits an ERROR STOP, only the subprocess terminates,
    ! allowing the parent process to catch the failure and continue with the next molecule.
    ! usage: SaxsEst --run-single <name> <outDir> <a> <e> <c>
    if (argNum >= 1) then
        call get_command_argument(1, arg1)
        if (trim(arg1) == '--run-single') then
            if (argNum /= 6) then
                write(error_unit, '(A)') "ERROR: --run-single requires 5 arguments"
                write(error_unit, '(A)') "Internal usage: SaxsEst --run-single <name> <outDir> <a> <e> <c>"
                stop 1
            end if

            ! parse subprocess arguments
            call get_command_argument(2, nameArg)
            call get_command_argument(3, outDirArg)
            call get_command_argument(4, aArg)
            call get_command_argument(5, eArg)
            call get_command_argument(6, cArg)

            read(aArg, *) aVal
            read(eArg, *) eVal
            read(cArg, *) cVal

            ! run single molecule analysis and exit
            call runSingle(trim(nameArg), trim(outDirArg), aVal, eVal, cVal)
            stop 0
        end if
    end if

    ! validate argument count for interactive mode
    if (argNum /= 2) then
        write(error_unit, '(A)') "ERROR: Invalid number of arguments"
        write(error_unit, '(A)') ""
        call printUsage()
        stop 1
    end if

    ! get arguments and launch interactive CLI
    call get_command_argument(1, xyzModListPath)
    call get_command_argument(2, outDir)
    call cli(trim(xyzModListPath), trim(outDir))

    contains

        !> Prints full help message including description, usage, arguments, and examples
        subroutine printHelp()
            write(output_unit, '(A)') "SaxsEst - Small Angle X-ray Scattering Estimation"
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "DESCRIPTION:"
            write(output_unit, '(A)') "  Calculates SAXS intensity profiles for protein structures"
            write(output_unit, '(A)') "  using the Debye equation and propagator methods."
            write(output_unit, '(A)') ""
            call printUsage()
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "ARGUMENTS:"
            write(output_unit, '(A)') "  xyz_module_list   Path to file containing list of XYZ modules to process"
            write(output_unit, '(A)') "  output_directory  Directory where CSV results will be written"
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "EXAMPLES:"
            write(output_unit, '(A)') "  SaxsEst _build/xyz_modules.txt ./results/"
            write(output_unit, '(A)') "  SaxsEst molecules.txt output/"
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "OPTIONS:"
            write(output_unit, '(A)') "  -h, --help        Display this help message"
        end subroutine printHelp

        !> Prints brief usage information to stderr
        subroutine printUsage()
            write(error_unit, '(A)') "USAGE:"
            write(error_unit, '(A)') "  SaxsEst <xyz_module_list> <output_directory>"
            write(error_unit, '(A)') "  SaxsEst -h | --help"
        end subroutine printUsage

end program SaxsEst