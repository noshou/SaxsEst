#include <stdio.h>
#include <string.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/callback.h>

// maximum size of number (way more than needed, but just 2 b safe)
#define MAX_DOUBLE_STR 32

/** C-interoperable estimate type */
typedef struct {
    double *q_vals;    /**< Pointer to Q-values array */
    double *i_vals;    /**< Pointer to intensity array */
    int timing;        /**< Timing in milliseconds */
    int size;          /**< Number of data points */
} estimate;

/**
 * Convert Fortran intensity estimate to OCaml CSV structure and call oc_out.
 *
 * Creates: [["q_inverse_angstrom"; "intensity"]; ["q0"; "i0"]; ["q1"; "i1"]; ...]
 *
 * @param est    Pointer to estimate structure from Fortran
 * @param fp     Pointer to full file path
 * @pre init_ocaml() must be called first
 * @pre OCaml "oc_out" function registered via Callback.register
 * @pre est->q_vals and est->i_vals must have est->size elements each
 * @pre pth must be null-terminated
 * @pre No headers in arrays - function adds them
 */
void fortran_to_ocaml(estimate *est, char *pth) {
    CAMLparam0(); // expects no ocaml arguments
    
    // 5 ocaml variables:
    CAMLlocal5(
        ocm_lst,    //  - ocm_lst -> csv list of lists (Q vs Intensity)
        row_lst,    //  - row_lst -> single nested row (Q; Intensity)
        cns_opi,    //  - cns_opi -> cons: "elm"  :: [row]  (inner cons)
        cns_opo,    //  - cns_opo -> cons: [row1] :: [row2] (outer cons)
        ocm_nme     //  - ocm_nme -> file path
    );
    
    // initialize empty ocaml list
    ocm_lst = Val_emptylist;
    
    // Build data rows (backwards)
    for (int i = est->size - 1; i >= 0; i--) {
        char buffer[MAX_DOUBLE_STR];
        
        // initialize row list, add intensities then add Q value
        row_lst = Val_emptylist;
        
        // add intensity to row
        snprintf(buffer, MAX_DOUBLE_STR, "%f", est->i_vals[i]);
        cns_opi = caml_alloc(2, 0);
        Store_field(cns_opi, 0, caml_copy_string(buffer));
        Store_field(cns_opi, 1, row_lst);
        row_lst = cns_opi;
        
        // add q value to row
        snprintf(buffer, MAX_DOUBLE_STR, "%f", est->q_vals[i]);
        cns_opi = caml_alloc(2, 0);
        Store_field(cns_opi, 0, caml_copy_string(buffer));
        Store_field(cns_opi, 1, row_lst);
        row_lst = cns_opi;
        
        // add row to ocm_lst
        cns_opo = caml_alloc(2, 0);
        Store_field(cns_opo, 0, row_lst);
        Store_field(cns_opo, 1, ocm_lst);  // Fixed: was row_lst, should be ocm_lst
        ocm_lst = cns_opo;
    }
    
    // add headers
    row_lst = Val_emptylist;
    cns_opi = caml_alloc(2, 0);
    Store_field(cns_opi, 0, caml_copy_string("intensity"));
    Store_field(cns_opi, 1, row_lst);
    row_lst = cns_opi;
    
    cns_opi = caml_alloc(2, 0);
    Store_field(cns_opi, 0, caml_copy_string("q_inv_angstrom"));
    Store_field(cns_opi, 1, row_lst);
    row_lst = cns_opi;
    
    cns_opo = caml_alloc(2, 0);
    Store_field(cns_opo, 0, row_lst);
    Store_field(cns_opo, 1, ocm_lst);
    ocm_lst = cns_opo;
    
    // allocate file name (null-terminated, so use caml_copy_string)
    ocm_nme = caml_copy_string(pth);
    
    // Call OCaml function
    static const value *closure = NULL; 
    if (closure == NULL) {
        closure = caml_named_value("oc_out");
    }
    if (closure != NULL) {
        caml_callback2(*closure, ocm_lst, ocm_nme);
    }
    
    CAMLreturn0;
}

void init_ocaml() {
    char *argv[] = { "csv_out", NULL };
    caml_startup(argv);
}

/** writes a simple file of timings to stdout */