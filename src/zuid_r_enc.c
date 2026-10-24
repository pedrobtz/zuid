/* R entry points for id_encode() and id_decode() (design.md section 6.5).
 * The R side checks the arguments; these check only what C relies on. */

#include "zuid_r.h"
#include "zuid_enc.h"

#include <string.h>

#define MAX_BYTES 65536 /* per element, section 6.10 */

static int arg_enc_form(SEXP form)
{
    if (!Rf_isString(form) || XLENGTH(form) != 1 ||
        STRING_ELT(form, 0) == NA_STRING) {
        Rf_error("zuid: `form` must be a single string");
    }
    int f = zuid_enc_find(CHAR(STRING_ELT(form, 0)));
    if (f < 0) Rf_error("zuid: unknown form '%s'", CHAR(STRING_ELT(form, 0)));
    return f;
}

/* NULL for the form's default alphabet. */
static const zuid_alphabet *arg_alphabet(SEXP alphabet, zuid_alphabet *a)
{
    if (Rf_isNull(alphabet)) return NULL;
    if (!Rf_isString(alphabet) || XLENGTH(alphabet) != 1 ||
        STRING_ELT(alphabet, 0) == NA_STRING) {
        Rf_error("zuid: `alphabet` must be NULL or a single string");
    }
    SEXP s = STRING_ELT(alphabet, 0);
    if (zuid_alphabet_init(a, CHAR(s), (size_t) LENGTH(s)) != 0) {
        Rf_error("zuid: `alphabet` must be 2 to 94 distinct printable ASCII "
                 "characters");
    }
    return a;
}

static void check_status(long r)
{
    if (r == ZUID_ENC_NOMEM) Rf_error("zuid: out of memory");
}

/* `bytes`: a list of raw vectors, NULL for a missing element. */
SEXP zuid_c_encode(SEXP bytes, SEXP form_, SEXP alphabet, SEXP sep_)
{
    int form = arg_enc_form(form_);
    zuid_alphabet custom;
    const zuid_alphabet *a = arg_alphabet(alphabet, &custom);
    if (TYPEOF(bytes) != VECSXP) Rf_error("zuid: `bytes` must be a list");
    if (!Rf_isString(sep_) || XLENGTH(sep_) != 1 ||
        STRING_ELT(sep_, 0) == NA_STRING) {
        Rf_error("zuid: `sep` must be a single string");
    }
    const char *sep = CHAR(STRING_ELT(sep_, 0));
    size_t sep_len = (size_t) LENGTH(STRING_ELT(sep_, 0));

    R_xlen_t n = XLENGTH(bytes);
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP b = VECTOR_ELT(bytes, i);
        if (Rf_isNull(b)) {
            SET_STRING_ELT(out, i, NA_STRING);
            continue;
        }
        if (TYPEOF(b) != RAWSXP || XLENGTH(b) > MAX_BYTES) {
            Rf_error("zuid: each element of `bytes` must be raw, at most %d "
                     "bytes",
                     MAX_BYTES);
        }
        size_t nb = (size_t) XLENGTH(b);
        const void *vmax = vmaxget();
        char *buf = R_alloc(zuid_enc_max_len(form, nb, a, sep_len) + 1, 1);
        long m = zuid_encode(form, RAW(b), nb, a, sep, sep_len, buf);
        check_status(m);
        if (m < 0) {
            Rf_error("zuid: form '%s' needs an even number of bytes",
                     zuid_enc_name(form));
        }
        SET_STRING_ELT(out, i, zuid_mkchar(buf, (size_t) m));
        vmaxset(vmax);
    }
    UNPROTECT(1);
    return out;
}

/* A list of raw vectors, NULL where `text` is NA or not text of the form. */
SEXP zuid_c_decode(SEXP text, SEXP form_, SEXP alphabet, SEXP width_)
{
    int form = arg_enc_form(form_);
    zuid_alphabet custom;
    const zuid_alphabet *a = arg_alphabet(alphabet, &custom);
    if (TYPEOF(text) != STRSXP) Rf_error("zuid: `text` must be character");
    long width = Rf_isNull(width_) ? -1 : (long) Rf_asInteger(width_);

    R_xlen_t n = XLENGTH(text);
    SEXP out = PROTECT(Rf_allocVector(VECSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(text, i);
        if (s == NA_STRING) continue;
        size_t len = (size_t) LENGTH(s);
        const void *vmax = vmaxget();
        uint8_t *buf = (uint8_t *) R_alloc(zuid_dec_max_len(len), 1);
        long m = zuid_decode(form, CHAR(s), len, a, width, buf);
        check_status(m);
        if (m >= 0) {
            SEXP r = Rf_allocVector(RAWSXP, m);
            if (m > 0) memcpy(RAW(r), buf, (size_t) m);
            SET_VECTOR_ELT(out, i, r);
        }
        vmaxset(vmax);
    }
    UNPROTECT(1);
    return out;
}
