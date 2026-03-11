module Main
    use, intrinsic :: iso_c_binding
    use AtomXYZ; use Est; use FormFact; use CsvInterface; use Freq

    ! generated atom modules
    include "mod_uses.inc"
    
    implicit none; private; public :: cli, runSingle

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
            character(len=*), intent(in)  ::    xyzModListPath
            character(len=*), intent(in)  ::    outDir
            character(len=:), allocatable ::    fp1,fp2,fp3,fp4,fp5,fp6,fp7,fp8,fp9, &
                                                fp10,fp11,fp12,fp13,fp14,fp15,fp16,fp17
            character(len=512)            ::    exePath
            character(len=2048)           ::    subprocCmd

            ! input data
            type(frequencies)             ::    freq
            type(atom), allocatable       ::    atoms(:)
            real(c_double), allocatable   ::    qVals(:)
            character(len=256)            ::    name

            ! variables for file I/O    
            integer                       ::    xyzUnit, iostatVal, startPos, endPos, m, atms
            integer                       ::    exitStatus
            character(len=256)            ::    buff
            character(len=*), parameter   ::    xyzStartMatch = "xyz_"
            character(len=*), parameter   ::    xyzEndMatch = "_mod.mod"

            ! open xyz modules for analysis
            xyzUnit = 10
            open(unit=xyzUnit, file=xyzModListPath, status="old", iostat=iostatVal)
            if (iostatVal .ne. 0) then
                print*, "Error opening xyz_modules.txt! Exiting..."
                stop
            end if

            ! get path to this executable for self-invocation
            call get_command_argument(0, exePath)

            ! get q values
            qVals = getQValues()
            do 
                read(xyzUnit, "(A)", iostat=iostatVal) buff
                if (iostatVal .ne. 0) exit

                ! match name of molecule from module filename
                startPos = len(xyzStartMatch)
                endPos = len(xyzEndMatch)
                m = len(trim(buff)) - startPos - endPos
                name = trim(buff(startPos+1:len_trim(buff) - endPos))

                ! load atoms from appropriate generated module
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
                fp1  = trim(outDir)//"/"//"debye_"//trim(name)//".csv"
                fp2  = trim(outDir)//"/"//"strat{s=0.50}_"//trim(name)//".csv"
                fp3  = trim(outDir)//"/"//"strat{s=0.45}_"//trim(name)//".csv"
                fp4  = trim(outDir)//"/"//"strat{s=0.40}_"//trim(name)//".csv"
                fp5  = trim(outDir)//"/"//"strat{s=0.35}_"//trim(name)//".csv"
                fp6  = trim(outDir)//"/"//"strat{s=0.30}_"//trim(name)//".csv"
                fp7  = trim(outDir)//"/"//"strat{s=0.25}_"//trim(name)//".csv"
                fp8  = trim(outDir)//"/"//"strat{s=0.20}_"//trim(name)//".csv"
                fp9  = trim(outDir)//"/"//"strat{s=0.15}_"//trim(name)//".csv"
                fp10 = trim(outDir)//"/"//"propo{e=0.450}_"//trim(name)//".csv"
                fp11 = trim(outDir)//"/"//"propo{e=0.440}_"//trim(name)//".csv"
                fp12 = trim(outDir)//"/"//"propo{e=0.430}_"//trim(name)//".csv"
                fp13 = trim(outDir)//"/"//"propo{e=0.420}_"//trim(name)//".csv"
                fp14 = trim(outDir)//"/"//"propo{e=0.410}_"//trim(name)//".csv"
                fp15 = trim(outDir)//"/"//"propo{e=0.400}_"//trim(name)//".csv"
                fp16 = trim(outDir)//"/"//"propo{e=0.390}_"//trim(name)//".csv"
                fp17 = trim(outDir)//"/"//"propo{e=0.380}_"//trim(name)//".csv"
                
                ! build subprocess command (values hardcoded in runSingle)
                subprocCmd =    trim(exePath)//" --run-single "// &
                                trim(name)//" "//trim(outDir)

                call execute_command_line(trim(subprocCmd), wait=.true., exitstat=exitStatus)

                ! handle subprocess failure: cleanup partial outputs and continue
                if (exitStatus /= 0) then
                    print*, ""
                    print*, "**************************************"
                    print*, "ABORTING ", trim(name), "; CONTINUING ANALYSIS..."
                    print*, "**************************************"

                    call deleteFileIfExists(fp1)
                    call deleteFileIfExists(fp2)
                    call deleteFileIfExists(fp3)
                    call deleteFileIfExists(fp4)
                    call deleteFileIfExists(fp5)
                    call deleteFileIfExists(fp6)
                    call deleteFileIfExists(fp7)
                    call deleteFileIfExists(fp8)
                    call deleteFileIfExists(fp9)
                    call deleteFileIfExists(fp10)
                    call deleteFileIfExists(fp11)
                    call deleteFileIfExists(fp12)
                    call deleteFileIfExists(fp13)
                    call deleteFileIfExists(fp14)
                    call deleteFileIfExists(fp15)
                    call deleteFileIfExists(fp16)
                    call deleteFileIfExists(fp17)

                    print*, "===================="
                    cycle
                end if

                print*, "===================="
            end do

            ! generate combined plots from analysis CSVs
            call execute_command_line("Rscript SaxsEst/Plot.R "//trim(outDir))

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
    !! Entry point for subprocess mode (--run-single).
    !! Runs analysis for a single molecule. Any ERROR STOP will terminate
    !! only this subprocess, not the parent process.
    !!
    !! @param[in] name   Molecule name (used to load atoms and name output files)
    !! @param[in] outDir Output directory for CSV results
        subroutine runSingle(name, outDir)
            character(len=*), intent(in) :: name
            character(len=*), intent(in) :: outDir

            ! locals
            type(frequencies) :: freq
            type(atom), dimension(:), allocatable :: atoms
            real(c_double), allocatable :: qVals(:)
            character(len=:), allocatable :: pathDebye, pathEst, cmd
            type(estimate) :: debye, strat, prop

            ! parameter arrays
            real(c_double) :: eVals(8), sVals(8)
            integer :: i
            character(len=32) :: paramStr

            eVals = [0.450_c_double, 0.440_c_double, 0.430_c_double, 0.420_c_double,  &
                    0.410_c_double, 0.400_c_double, 0.390_c_double, 0.380_c_double]
            sVals = [0.50_c_double, 0.45_c_double, 0.40_c_double, 0.35_c_double, &
                    0.30_c_double, 0.25_c_double, 0.20_c_double, 0.15_c_double]

            ! load atoms for this molecule
            include "mod_switches.inc"

            ! build frequency table
            freq = initFreqs(atoms)

            ! get q values
            qVals = getQValues()

            ! ── Debye (exact, run once) ──────────────────────────────
            pathDebye = trim(outDir)//"/"//"debye_"//trim(name)//".csv"

            print*, ""
            print*, "Running debyeEst..."
            debye = debyeEst(atoms, qVals)
            call estWrap(debye, pathDebye)
            print*, "timing: ", debye%timing, "s"

            ! ── Stratified (one run per s value) ─────────────────────
            do i = 1, size(sVals)
                write(paramStr, '(F4.2)') sVals(i)
                pathEst = trim(outDir)//"/"//"strat{s="//trim(adjustl(paramStr))//"}_"//trim(name)//".csv"

                print*, ""
                print*, "Running stratEst  s=", trim(adjustl(paramStr)), "..."
                strat = stratEst(freq, qVals, sVals(i))
                call estWrap(strat, pathEst)
                print*, "timing: ", strat%timing, "s"
            end do

            ! ── Proportional (one run per e value) ───────────────────
            do i = 1, size(eVals)
                write(paramStr, '(F5.3)') eVals(i)
                pathEst = trim(outDir)//"/"//"propo{e="//trim(adjustl(paramStr))//"}_"//trim(name)//".csv"

                print*, ""
                print*, "Running propoEst  ε=", trim(adjustl(paramStr)), "; ñ=", size(atoms), "..."
                prop = propoEst(freq, atoms, qVals, real(size(atoms),kind=c_double), eVals(i))
                call estWrap(prop, pathEst)
                print*, "timing: ", prop%timing, "s"
            end do

            ! ── Combine via R ────────────────────────────────────────
            ! build command: CsvCombine.R <outDir> <name> <debye.csv> <est1.csv> <est2.csv> ...
            cmd =   "Rscript SaxsEst/CsvCombine.R "// &
                    trim(outDir)//" "//trim(name)//" "//trim(pathDebye)

            do i = 1, size(sVals)
                write(paramStr, '(F4.2)') sVals(i)
                cmd = cmd//" "//trim(outDir)//"/"//"strat{s="//trim(adjustl(paramStr))//"}_"//trim(name)//".csv"
            end do
            do i = 1, size(eVals)
                write(paramStr, '(F5.3)') eVals(i)
                cmd = cmd//" "//trim(outDir)//"/"//"propo{e="//trim(adjustl(paramStr))//"}_"//trim(name)//".csv"
            end do

            print*, ""
            call execute_command_line(trim(cmd))
            print*, "Finished analysis of ", trim(name)

        end subroutine runSingle

end module Main

program SaxsEst
    use, intrinsic :: iso_c_binding
    use Main
    use, intrinsic :: iso_fortran_env
    implicit none

    integer :: argNum
    character(len=256) :: arg1, xyzModListPath, outDir
    character(len=256) :: nameArg, outDirArg

    argNum = command_argument_count()

    ! check for help flag
    if (argNum == 1) then
        call get_command_argument(1, arg1)
        if (trim(arg1) == '-h' .or. trim(arg1) == '--help') then
            call printHelp()
            stop 0
        end if
    end if

    call random_seed()

    ! check for subprocess mode
    if (argNum >= 1) then
        call get_command_argument(1, arg1)
        if (trim(arg1) == '--run-single') then
            if (argNum /= 3) then
                write(error_unit, '(A)') "ERROR: --run-single requires 2 arguments"
                write(error_unit, '(A)') "Internal usage: SaxsEst --run-single <name> <outDir>"
                stop 1
            end if

            call get_command_argument(2, nameArg)
            call get_command_argument(3, outDirArg)

            call runSingle(trim(nameArg), trim(outDirArg))
            stop 0
        end if
    end if

    if (argNum /= 2) then
        write(error_unit, '(A)') "ERROR: Invalid number of arguments"
        write(error_unit, '(A)') ""
        call printUsage()
        stop 1
    end if

    call get_command_argument(1, xyzModListPath)
    call get_command_argument(2, outDir)
    call cli(trim(xyzModListPath), trim(outDir))

    contains

        subroutine printHelp()
            write(output_unit, '(A)') "SaxsEst - Small Angle X-ray Scattering Estimation"
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "DESCRIPTION:"
            write(output_unit, '(A)') "  Calculates SAXS intensity profiles for protein structures"
            write(output_unit, '(A)') "  using the Debye equation, stratified, and proportional methods."
            write(output_unit, '(A)') ""
            call printUsage()
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "ARGUMENTS:"
            write(output_unit, '(A)') "  xyz_module_list   Path to file containing list of XYZ modules"
            write(output_unit, '(A)') "  output_directory  Directory where CSV results will be written"
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "EXAMPLES:"
            write(output_unit, '(A)') "  SaxsEst _build/xyz_modules.txt ./results/"
            write(output_unit, '(A)') ""
            write(output_unit, '(A)') "OPTIONS:"
            write(output_unit, '(A)') "  -h, --help        Display this help message"
        end subroutine printHelp

        subroutine printUsage()
            write(error_unit, '(A)') "USAGE:"
            write(error_unit, '(A)') "  SaxsEst <xyz_module_list> <output_directory>"
            write(error_unit, '(A)') "  SaxsEst -h | --help"
        end subroutine printUsage

end program SaxsEst