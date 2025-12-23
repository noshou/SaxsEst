#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/callback.h>

// maximum size of number (way more than needed, but just 2 b safe)
#define MAX_DOUBLE_STR 32

/**
 * Convert parallel Fortran double arrays to OCaml CSV structure and call data_out.
 *
 * Creates: [["q_inverse_angstrom"; "intensity"]; ["q0"; "i0"]; ["q1"; "i1"]; ...]
 *
 * @param q_arr      Q-values array (double*, length *size, read-only)
 * @param i_arr      Intensity array (double*, length *size, read-only)  
 * @param size       Number of data points (int*, must match array lengths)
 * @param name       File path (char*, length *name_size, not null-terminated)
 * @param name_size  Filename length (int*)
 *
 * @pre init_ocaml() must be called first
 * @pre OCaml "data_out" function registered via Callback.register
 * @pre Arrays must have equal length (*size elements each)
 * @pre No headers in arrays - function adds them
 */
void fortran_to_ocaml(
	double *q_arr, 
	double *i_arr,
	int *size, 
	char *name, 
	int *name_size
) {
	CAMLparam0(); // expects no ocaml arguments

	// 5 ocaml variables:
	//	- ocm_lst  -> csv list of lists (Q vs Intensity)
	//  - row_lst -> single nested row (Q; Intensity)
	// 	- cns_opi -> cons: "elm"  :: [row]  (inner cons)
	//	- cns_opo -> cons: [row1] :: [row2] (outer cons)
	//  - ocm_nme -> name of run/file
	CAMLlocal5(ocm_lst, row_lst, cns_opi, cns_opo, ocm_nme);

	// initialize empty ocaml list
	ocm_lst = Val_emptylist;

	// Build data rows (backwards)
	for (int i = *size - 1; i >= 0; i--) {
		
		char buffer[MAX_DOUBLE_STR];
		
		// initialize row list, add intensities then add Q value
		row_lst = Val_emptylist;
		
		// add intensity to row
		snprintf(buffer, MAX_DOUBLE_STR, "%f", i_arr[i]);
		cns_opi = caml_alloc(2, 0);
		Store_field(cns_opi, 0, caml_copy_string(buffer));
		Store_field(cns_opi, 1, row_lst);
		row_lst = cns_opi;

		// add q value to row
		snprintf(buffer, MAX_DOUBLE_STR, "%f", q_arr[i]);
		cns_opi = caml_alloc(2, 0);
		Store_field(cns_opi, 0, caml_copy_string(buffer));
		Store_field(cns_opi, 1, row_lst);
		row_lst = cns_opi;

		// add row to oc_lst
		cns_opo = caml_alloc(2, 0);
		Store_field(cns_opo, 0, row_lst);
		Store_field(cns_opo, 1, row_lst);
		ocm_lst = cns_opo;
	}

	// add headers
	row_lst = Val_emptylist;
	cns_opi = caml_alloc(2, 0);
	Store_field(cns_opi, 0, caml_copy_string("intensity"));
	Store_field(cns_opi, 1, row_lst);
	cns_opi = caml_alloc(2, 0);
	Store_field(cns_opi, 0, caml_copy_string("q_inv_angstrom"));
	Store_field(cns_opi, 1, row_lst);
	row_lst = cns_opi;
	cns_opo = caml_alloc(2, 0);
	Store_field(cns_opo, 0, row_lst);
	Store_field(cns_opo, 1, ocm_lst);
	ocm_lst = cns_opo;

	// allocate file name
	ocm_nme = caml_alloc_string(*name_size);
	for (int i = 0; i < *name_size; i++) {
		Byte(ocm_nme, i) = name[i];
	}

		// Call OCaml function
	static const value *closure = NULL; 
	if (closure == NULL) {
		closure = caml_named_value("data_out");
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
