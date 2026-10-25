#include "zuid_r.h"

#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

static const R_CallMethodDef call_methods[] = {
    {"zuid_c_table", (DL_FUNC) &zuid_c_table, 1},
    {"zuid_c_parse", (DL_FUNC) &zuid_c_parse, 6},
    {"zuid_c_format", (DL_FUNC) &zuid_c_format, 3},
    {"zuid_c_bytes", (DL_FUNC) &zuid_c_bytes, 2},
    {"zuid_c_from_bytes", (DL_FUNC) &zuid_c_from_bytes, 3},
    {"zuid_c_fields", (DL_FUNC) &zuid_c_fields, 2},
    {"zuid_c_formats", (DL_FUNC) &zuid_c_formats, 0},
    {"zuid_c_key", (DL_FUNC) &zuid_c_key, 2},
    {"zuid_c_uuid", (DL_FUNC) &zuid_c_uuid, 6},
    {"zuid_c_state", (DL_FUNC) &zuid_c_state, 0},
    {"zuid_c_reset_state", (DL_FUNC) &zuid_c_reset_state, 0},
    {"zuid_c_entropy_fail", (DL_FUNC) &zuid_c_entropy_fail, 1},
    {"zuid_c_ulid", (DL_FUNC) &zuid_c_ulid, 4},
    {"zuid_c_upid", (DL_FUNC) &zuid_c_upid, 4},
    {"zuid_c_scru128", (DL_FUNC) &zuid_c_scru128, 5},
    {"zuid_c_scru64", (DL_FUNC) &zuid_c_scru64, 7},
    {"zuid_c_ksuid", (DL_FUNC) &zuid_c_ksuid, 3},
    {"zuid_c_layout_unpack", (DL_FUNC) &zuid_c_layout_unpack, 3},
    {"zuid_c_snowflake", (DL_FUNC) &zuid_c_snowflake, 8},
    {"zuid_c_xid", (DL_FUNC) &zuid_c_xid, 4},
    {"zuid_c_objectid", (DL_FUNC) &zuid_c_objectid, 2},
    {"zuid_c_charset", (DL_FUNC) &zuid_c_charset, 2},
    {"zuid_c_cuid2", (DL_FUNC) &zuid_c_cuid2, 1},
    {"zuid_c_nanoid", (DL_FUNC) &zuid_c_nanoid, 4},
    {"zuid_c_sqids_encode", (DL_FUNC) &zuid_c_sqids_encode, 4},
    {"zuid_c_sqids_parse", (DL_FUNC) &zuid_c_sqids_parse, 4},
    {"zuid_c_cid_parse", (DL_FUNC) &zuid_c_cid_parse, 1},
    {"zuid_c_cid_text", (DL_FUNC) &zuid_c_cid_text, 1},
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
