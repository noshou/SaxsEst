!> Fortran-OCaml bridge for exporting intensity estimates to CSV
module CsvInterface
    use, intrinsic :: iso_c_binding; use Est
    implicit none; private; public :: estWrap
    
    !> OCaml runtime initialization flag
    logical, save :: isInit = .false.
    
    interface 
        !> C bridge function to export data to OCaml CSV writer
        !! @param est Intensity estimate structure
        !! @param pth C pointer to null-terminated output path
        subroutine fortran2ocaml(est, pth) bind(C, name="fortran2ocaml")
            import :: estimate, c_ptr
            type(estimate), intent(in) :: est
            type(c_ptr), value :: pth 
        end subroutine fortran2ocaml
        
        !> @brief Initialize OCaml runtime (call once)
        subroutine initOCaml() bind(C, name="initOCaml")
        end subroutine 
    end interface    
    
contains

    !> Export intensity estimate to CSV file via OCaml
    !! @param est Intensity estimate to export
    !! @param pth Output path
    !! @return path of output
    subroutine estWrap(est, pth)
        
        type(estimate), intent(in) :: est
        character(len=*), intent(in) :: pth
        character(len=:, kind=c_char), allocatable, target :: csvPath
        character(len=256), allocatable :: pathBuild
        ! Initialize OCaml runtime on first call
        if (.not. isInit) then
            call initOCaml()
            isInit = .true.
        end if
        
        ! Build null-terminated file path
        csvPath = pth // c_null_char
        
        ! Export to CSV
        call fortran2ocaml(est, c_loc(csvPath))

    end subroutine estWrap
    
end module CsvInterface