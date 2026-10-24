#include "zuid_r.h"

#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

static const R_CallMethodDef call_methods[] = {
    {"zuid_c_table", (DL_FUNC) &zuid_c_table, 1},
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
