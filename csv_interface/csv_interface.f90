!> Fortran-OCaml bridge for exporting intensity estimates to CSV
module csv_interface_mod
    use, intrinsic :: iso_c_binding; use estimate_mod
    implicit none; private; public :: est_wrap
    
    !> OCaml runtime initialization flag
    logical, save :: is_init = .false.
    
    interface 
        !> C bridge function to export data to OCaml CSV writer
        !! @param est Intensity estimate structure
        !! @param pth C pointer to null-terminated output path
        subroutine fortran_to_ocaml(est, pth) bind(C, name="fortran_to_ocaml")
            import :: estimate, c_ptr
            type(estimate), intent(in) :: est
            type(c_ptr), value :: pth 
        end subroutine fortran_to_ocaml
        
        !> @brief Initialize OCaml runtime (call once)
        subroutine init_ocaml() bind(C, name="init_ocaml")
        end subroutine 
    end interface    
    
contains

    !> Export intensity estimate to CSV file via OCaml
    !! @param est Intensity estimate to export
    !! @param pth Output path
    !! @return path of output
    subroutine est_wrap(est, pth)
        
        type(estimate), intent(in) :: est
        character(len=*), intent(in) :: pth
        character(len=:, kind=c_char), allocatable, target :: csv_path
        character(len=256), allocatable :: path_build
        ! Initialize OCaml runtime on first call
        if (.not. is_init) then
            call init_ocaml()
            is_init = .true.
        end if
        
        ! Build null-terminated file path
        csv_path = pth // c_null_char
        
        ! Export to CSV
        call fortran_to_ocaml(est, c_loc(csv_path))

    end subroutine est_wrap
    
end module csv_interface_mod