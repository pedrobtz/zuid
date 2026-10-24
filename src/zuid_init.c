#include "zuid_r.h"

#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

static const R_CallMethodDef call_methods[] = {
    {"zuid_c_table", (DL_FUNC) &zuid_c_table, 1},
    {"zuid_c_parse", (DL_FUNC) &zuid_c_parse, 5},
    {"zuid_c_format", (DL_FUNC) &zuid_c_format, 3},
    {"zuid_c_bytes", (DL_FUNC) &zuid_c_bytes, 2},
    {"zuid_c_from_bytes", (DL_FUNC) &zuid_c_from_bytes, 3},
    {"zuid_c_fields", (DL_FUNC) &zuid_c_fields, 2},
    {"zuid_c_formats", (DL_FUNC) &zuid_c_formats, 0},
    {"zuid_c_key", (DL_FUNC) &zuid_c_key, 2},
    {"zuid_c_uuid", (DL_FUNC) &zuid_c_uuid, 6},
    {"zuid_c_state", (DL_FUNC) &zuid_c_state, 0},
    {"zuid_c_reset_state", (DL_FUNC) &zuid_c_reset_state, 0},
    {"zuid_c_encode", (DL_FUNC) &zuid_c_encode, 4},
    {"zuid_c_decode", (DL_FUNC) &zuid_c_decode, 4},
    {NULL, NULL, 0}
};

/* The one exported symbol. Everything else is hidden by $(C_VISIBILITY) in
 * src/Makevars and reached through this registration table only. */
void attribute_visible R_init_zuid(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
