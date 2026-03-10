!> @brief CLI and subprocess entry points for SAXS intensity estimation.
!> @details Provides two execution modes:
!>   1. Interactive CLI: iterates over a list of molecules, prompts for parameters,
!>      and spawns subprocesses to isolate failures.
!>   2. Subprocess (--run-single): runs Debye, stratified, and proportional
!>      estimations for a single molecule, then combines results via R script.
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

    !> @brief CLI for batch SAXS analysis.
    !>
    !> Each molecule is analyzed in a subprocess via --run-single to isolate
    !> ERROR STOP failures. If a subprocess fails, partial output files are
    !> cleaned up and analysis continues with the next molecule.
    !>
    !> @param[in] xyzModListPath  Path to file listing XYZ modules to process
    !> @param[in] outDir          Output directory for CSV results
    !!
    !! Reads a list of XYZ module files,  then spawns a subprocess for
    !! each molecule to isolate ERROR STOP failures. If a subprocess fails, partial
    !! output files are cleaned up and analysis continues with the next molecule.
    !!
    !! @param[in] xyzModListPath  Path to file listing XYZ modules to process
    !! @param[in] outDir              Output directory for CSV results
    subroutine cli(xyzModListPath, outDir)

        ! file paths
        character(len=*), intent(in) :: xyzModListPath
        character(len=*), intent(in) :: outDir
        character(len=:), allocatable :: path, path1, path2, path3, cmd

        ! input data
        type(frequencies) :: freq
        type(atom), dimension(:), allocatable :: atoms
        real(c_double), allocatable :: qVals(:)
        character(len=256) :: name

        ! variables for file I/O
        integer :: xyzUnit, iostatVal, startPos, endPos, m, atms
        character(len=256) :: buff
        character(len=*), parameter :: xyzStartMatch = "xyz_"
        character(len=*), parameter :: xyzEndMatch = "_mod.mod"

        ! user cli inputs
        real :: a1_, a2_, e_
        real(c_double) :: a1, a2, e
        logical :: isDigitChar, isPercentChar, isValid
        integer :: i

        ! analysis results
        type(estimate) :: debye, prop

        ! subprocess handling for error recovery
        integer :: exitStatus
        character(len=32) :: a1Str, a2Str, eStr
        character(len=32) :: a2RawStr  ! raw "50%" style string for R script
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
            startPos = len(xyzStartMatch)
            endPos = len(xyzEndMatch)
            m = len(trim(buff)) - startPos - endPos
            name = trim(buff(startPos+1:len_trim(buff) - endPos))

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

            ! define output file paths for potential cleanup
            path1  = trim(outDir)//"/"//"debye_"//trim(name)//".csv"
            path2  = trim(outDir)//"/"//"strat50p_"//trim(name)//".csv"
            path3  = trim(outDir)//"/"//"strat45p_"//trim(name)//".csv"
            path4  = trim(outDir)//"/"//"strat40p_"//trim(name)//".csv"
            path5  = trim(outDir)//"/"//"strat35p_"//trim(name)//".csv"
            path6  = trim(outDir)//"/"//"strat30p_"//trim(name)//".csv"
            path7  = trim(outDir)//"/"//"strat25p_"//trim(name)//".csv"
            path8  = trim(outDir)//"/"//"strat20p_"//trim(name)//".csv"
            path9  = trim(outDir)//"/"//"strat15p_"//trim(name)//".csv"
            path10 = trim(outDir)//"/"//"strat10p_"//trim(name)//".csv"
            path11 = trim(outDir)//"/"//"strat5p_"//trim(name)//".csv"
            path12 = trim(outDir)//"/"//"propo0.42_"//trim(name)//".csv"
            path14 = trim(outDir)//"/"//"propo0.4105_"//trim(name)//".csv"
            path15 = trim(outDir)//"/"//"propo0.41_"//trim(name)//".csv"


            call execute_command_line(trim(subprocCmd), wait=.true., exitstat=exitStatus)

            ! handle subprocess failure: cleanup partial outputs and continue
            if (exitStatus /= 0) then
                print*, ""
                print*, "**************************************"
                print*, "ABORTING ", trim(name), "; CONTINUING ANALYSIS..."
                print*, "**************************************"

                ! delete any partial output files created before the error
                call deleteFileIfExists(path1)
                call deleteFileIfExists(path2)
                call deleteFileIfExists(path3)

                print*, "===================="
                cycle  ! continue to next molecule
            end if

            print*, "===================="
        end do

        ! generate combined plots from analysis CSVs
        cmd = "Rscript SaxsEst/Plot.R "//   &
                trim(outDir)//" "//         &
                trim(adjustl(eStr))//" "//  &
                trim(adjustl(a2RawStr))
        call execute_command_line(trim(cmd))

        print*, ""
        print*, "All molecules processed."
        close(xyzUnit)
    end subroutine cli

    !> @brief Subprocess entry point for single-molecule SAXS analysis.
    !> @details Runs three estimations and combines results:
    !>   1. Debye radial (exact pairwise, O(mn²)) → debye_<name>.csv
    !>   2. Stratified (importance-sampled, uses a2 as sample fraction) → strat_<name>.csv
    !>   3. Proportional (frequency-weighted, uses a1 as advice param) → propo_<name>.csv
    !>
    !> Any ERROR STOP terminates only this subprocess; the parent catches
    !> the non-zero exit status and continues with the next molecule.
    !>
    !> @param[in] name   Molecule name (used to load atoms and name output files)
    !> @param[in] outDir Output directory for CSV results
    !> @param[in] a1     Advice parameter for proportional weight estimation (must be >= nAtoms)
    !> @param[in] a2     Sample size as percentage of total atoms for stratified estimator
    !> @param[in] e      Epsilon accuracy parameter (must satisfy 0 < e < 1)
    !! Entry point for subprocess mode (--run-single).
    !! Runs analysis for a single molecule. Any ERROR STOP will terminate
    !! only this subprocess, not the parent process.
    !!
    !! Performs two analyses:
    !!   1. Debye radial estimation (exact pairwise computation)
    !!   2. Proportional estimation (approximate, using frequency-based weights)
    !!
    !! After both analyses complete, invokes an R script to combine into CSVs
    !!
    !! @param[in] name   Molecule name (used to load atoms and name output files)
    !! @param[in] outDir Output directory for CSV results
    !! @param[in] a1     Advice parameter for weight estimation (must be >= nAtoms)
    !! @param[in] a2     Advice parameter for percent of atom count to sample (>= 0)
    !! @param[in] e      Epsilon accuracy parameter (must satisfy 0 < e < 1)
    subroutine runSingle(name, outDir, a1, a2, e)
        character(len=*), intent(in) :: name
        character(len=*), intent(in) :: outDir
        real(c_double), intent(in) :: a1, a2, e
        integer, intent(in) :: c_int

        ! locals
        type(frequencies) :: freq
        type(atom), dimension(:), allocatable :: atoms
        real(c_double), allocatable :: qVals(:)
        character(len=:), allocatable :: path, path1, path2, path3, cmd
        type(estimate) :: debye, prop, strat

        ! load atoms for this molecule
        include "mod_switches.inc"

        ! build frequency table from atom list
        freq = initFreqs(atoms)

        ! get q values for intensity calculation
        qVals = getQValues()

        ! define output paths
        path1 = trim(outDir)//"/"//"debye_"//trim(name)//".csv"
        path2 = trim(outDir)//"/"//"strat_"//trim(name)//".csv"
        path3 = trim(outDir)//"/"//"propo_"//trim(name)//".csv"

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

        ! run stratified estimate radial analysis
        ! run stratified estimate radial analysis
        print*, "Running stratEst..."
        strat = stratEst(freq, qVals, e, a2)
        path = path2
        call estWrap(strat, path)
        print*, "timing: ", strat%timing, "s"
        print*, ""

        ! run proportional radial analysis (approximate, frequency-weighted)
        print*, "Running propoEst..."
        prop = propoEst(freq, atoms, qVals, a1, e)
        path = path3
        call estWrap(prop, path)
        print*, "timing: ", prop%timing, "s"
        print*, ""

        ! run R script to combine to output CSVs
        cmd =   "Rscript SaxsEst/CsvCombine.R "//   &    
                trim(outDir)//" "//                 &
                trim(name)//" "//                   &
                trim(path1)//" "//                  &
                trim(path2)//" "//                  &                
                trim(path3)                         
        print*, ""
        call execute_command_line(trim(cmd))

        print*, "Finished analysis of ", trim(name)

    end subroutine runSingle

end module Main


!> @brief Main program for SAXS intensity estimation.
!> @details Parses command-line arguments and dispatches to one of two modes:
!>   1. Interactive CLI (2 args): prompts user for parameters per molecule
!>      Usage: SaxsEst <xyz_module_list> <output_directory>
!>   2. Subprocess (7 args): runs single-molecule analysis
!>      Usage: SaxsEst --run-single <name> <outDir> <a1> <a2> <e>
program SaxsEst
    use, intrinsic :: iso_c_binding
    use Main
    use, intrinsic :: iso_fortran_env
    implicit none

    ! local variables
    integer :: argNum
    character(len=256) :: arg1, xyzModListPath, outDir

    ! subprocess mode variables
    character(len=256) :: nameArg, outDirArg, a1Arg, a2Arg, eArg
    real(c_double) :: a1Val, a2Val, eVal
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

    ! initialize random number generator
    call random_seed()

    ! check for subprocess mode (--run-single)
    ! this mode is invoked internally by the main CLI to isolate ERROR STOP failures.
    ! when a molecule's analysis hits an ERROR STOP, only the subprocess terminates,
    ! allowing the parent process to catch the failure and continue with the next molecule.
    ! usage: SaxsEst --run-single <name> <outDir> <a> <e>
    if (argNum >= 1) then
        call get_command_argument(1, arg1)
        if (trim(arg1) == '--run-single') then
            if (argNum /= 7) then
                write(error_unit, '(A)') "ERROR: --run-single requires 6 arguments"
                write(error_unit, '(A)') "Internal usage: SaxsEst --run-single <name> <outDir> <a1> <a2> <e>"
                stop 1
            end if

            ! parse subprocess arguments
            call get_command_argument(2, nameArg)
            call get_command_argument(3, outDirArg)
            call get_command_argument(4, a1Arg)
            call get_command_argument(5, a2Arg)
            call get_command_argument(6, eArg)

            read(a1Arg, *) a1Val
            read(a2Arg, *) a2Val
            read(eArg, *)  eVal

            ! run single molecule analysis and exit
            call runSingle(trim(nameArg), trim(outDirArg), a1Val, a2Val, eVal)
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
            write(output_unit, '(A)') "  using the Debye equation and proportional methods."
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