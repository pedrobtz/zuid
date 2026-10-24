#include "zuid_r.h"
#include "zuid_tables.h"

#include <limits.h>
#include <string.h>

SEXP zuid_mkchar(const char *bytes, size_t len)
{
    if (len > INT_MAX) {
        Rf_error("zuid: string of %lu bytes is too long for R",
                 (unsigned long) len);
    }
    /* Identifiers and encodings are ASCII, so CE_UTF8 and CE_NATIVE agree;
     * UTF-8 is marked so the result never depends on the session locale. */
    return Rf_mkCharLenCE(bytes, (int) len, CE_UTF8);
}

static SEXP table_as_character(const char *const *table, R_xlen_t n)
{
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SET_STRING_ELT(out, i, zuid_mkchar(table[i], strlen(table[i])));
    }
    UNPROTECT(1);
    return out;
}

/* The compiled copy of a generated table, so tests can check it against
 * R/sysdata.rda. Internal; not part of the R API. */
SEXP zuid_c_table(SEXP name)
{
    if (!Rf_isString(name) || XLENGTH(name) != 1) {
        Rf_error("zuid: `name` must be a single string");
    }
    const char *what = CHAR(STRING_ELT(name, 0));
    if (strcmp(what, "niceware_words") == 0) {
        return table_as_character(zuid_niceware_words, ZUID_NICEWARE_N);
    }
    if (strcmp(what, "sqids_blocklist") == 0) {
        return table_as_character(zuid_sqids_blocklist, ZUID_SQIDS_BLOCKLIST_N);
    }
    Rf_error("zuid: unknown table '%s'", what);
    return R_NilValue; /* not reached */
}
