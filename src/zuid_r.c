#include "zuid_r.h"
#include "zuid_formats.h"
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

/* ---- Vectorised entry points over the format descriptors ---------------- */

static const zuid_format *arg_format(SEXP format)
{
    if (!Rf_isString(format) || XLENGTH(format) != 1 ||
        STRING_ELT(format, 0) == NA_STRING) {
        Rf_error("zuid: `format` must be a single string");
    }
    const zuid_format *fmt = zuid_format_find(CHAR(STRING_ELT(format, 0)));
    if (fmt == NULL) {
        Rf_error("zuid: unknown format '%s'", CHAR(STRING_ELT(format, 0)));
    }
    return fmt;
}

static int arg_form(const zuid_format *fmt, SEXP form)
{
    if (Rf_isNull(form)) {
        return -1;
    }
    if (!Rf_isString(form) || XLENGTH(form) != 1 ||
        STRING_ELT(form, 0) == NA_STRING) {
        Rf_error("zuid: `form` must be NULL or a single string");
    }
    int i = fmt->form_index(CHAR(STRING_ELT(form, 0)));
    if (i < -1) {
        Rf_error("zuid: format '%s' has no form '%s'", fmt->name,
                 CHAR(STRING_ELT(form, 0)));
    }
    return i;
}

static void arg_character(SEXP x)
{
    if (TYPEOF(x) != STRSXP) {
        Rf_error("zuid: `x` must be a character vector");
    }
}

static int is_ascii(const char *s, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        if ((unsigned char) s[i] > 127) return 0;
    }
    return 1;
}

/* Bytes of a canonical (or default-form) string already known to parse. */
static int canonical_bytes(const zuid_format *fmt, SEXP s, uint8_t *out,
                           zuid_prefix *pfx)
{
    const char *text = CHAR(s);
    size_t len = (size_t) LENGTH(s);
    return fmt->parse(text, len, -1, out, pfx) >= ZUID_LEVEL_SYNTAX;
}

SEXP zuid_c_parse(SEXP x, SEXP format, SEXP form, SEXP now_ms,
                  SEXP tolerance_ms)
{
    arg_character(x);
    const zuid_format *fmt = arg_format(format);
    int form_i = arg_form(fmt, form);
    double now = Rf_asReal(now_ms), tol = Rf_asReal(tolerance_ms);
    R_xlen_t n = XLENGTH(x);

    SEXP text = PROTECT(Rf_allocVector(STRSXP, n));
    SEXP level = PROTECT(Rf_allocVector(INTSXP, n));
    int *lv = INTEGER(level);
    uint8_t bytes[ZUID_MAX_WIDTH];
    zuid_prefix pfx;
    char buf[ZUID_TEXT_BUF];

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING) {
            SET_STRING_ELT(text, i, NA_STRING);
            lv[i] = NA_INTEGER;
            continue;
        }
        const char *chars = CHAR(s);
        size_t len = (size_t) LENGTH(s);
        zuid_level got = is_ascii(chars, len)
                             ? fmt->parse(chars, len, form_i, bytes, &pfx)
                             : ZUID_LEVEL_NONE;
        if (got == ZUID_LEVEL_STRUCTURE && fmt->strict(bytes, now, tol)) {
            got = ZUID_LEVEL_STRICT;
        }
        lv[i] = (int) got;
        if (got >= ZUID_LEVEL_SYNTAX) {
            size_t m = fmt->format(bytes, -1, &pfx, buf);
            SET_STRING_ELT(text, i, zuid_mkchar(buf, m));
        } else {
            SET_STRING_ELT(text, i, NA_STRING);
        }
    }

    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(out, 0, text);
    SET_VECTOR_ELT(out, 1, level);
    UNPROTECT(3);
    return out;
}

SEXP zuid_c_format(SEXP x, SEXP format, SEXP form)
{
    arg_character(x);
    const zuid_format *fmt = arg_format(format);
    int form_i = arg_form(fmt, form);
    R_xlen_t n = XLENGTH(x);
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    uint8_t bytes[ZUID_MAX_WIDTH];
    zuid_prefix pfx;
    char buf[ZUID_TEXT_BUF];

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING || !canonical_bytes(fmt, s, bytes, &pfx)) {
            SET_STRING_ELT(out, i, NA_STRING);
            continue;
        }
        size_t m = fmt->format(bytes, form_i, &pfx, buf);
        SET_STRING_ELT(out, i, zuid_mkchar(buf, m));
    }
    UNPROTECT(1);
    return out;
}

/* A raw matrix, width rows by one column per element; NA columns are zero. */
SEXP zuid_c_bytes(SEXP x, SEXP format)
{
    arg_character(x);
    const zuid_format *fmt = arg_format(format);
    R_xlen_t n = XLENGTH(x);
    int w = fmt->width;
    if (n > INT_MAX) {
        Rf_error("zuid: too many elements for a raw matrix");
    }
    SEXP out = PROTECT(Rf_allocMatrix(RAWSXP, w, (int) n));
    Rbyte *raw = RAW(out);
    memset(raw, 0, (size_t) w * (size_t) n);
    zuid_prefix pfx;

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s != NA_STRING) {
            canonical_bytes(fmt, s, raw + (size_t) i * (size_t) w, &pfx);
        }
    }
    UNPROTECT(1);
    return out;
}

/* Canonical text from width * n bytes; `na` marks elements to leave NA. */
SEXP zuid_c_from_bytes(SEXP bytes, SEXP format, SEXP na)
{
    const zuid_format *fmt = arg_format(format);
    if (TYPEOF(bytes) != RAWSXP || TYPEOF(na) != LGLSXP) {
        Rf_error("zuid: `bytes` must be raw and `na` logical");
    }
    int w = fmt->width;
    R_xlen_t n = XLENGTH(na);
    if (XLENGTH(bytes) != (R_xlen_t) w * n) {
        Rf_error("zuid: expected %d bytes per element", w);
    }
    const Rbyte *raw = RAW(bytes);
    const int *isna = LOGICAL(na);
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    char buf[ZUID_TEXT_BUF];

    for (R_xlen_t i = 0; i < n; i++) {
        if (isna[i] == TRUE) {
            SET_STRING_ELT(out, i, NA_STRING);
            continue;
        }
        size_t m = fmt->format(raw + (size_t) i * (size_t) w, -1, NULL, buf);
        SET_STRING_ELT(out, i, zuid_mkchar(buf, m));
    }
    UNPROTECT(1);
    return out;
}

static SEXP string_or_na(const char *s)
{
    return (s == NULL || s[0] == '\0') ? NA_STRING
                                       : zuid_mkchar(s, strlen(s));
}

SEXP zuid_c_fields(SEXP x, SEXP format)
{
    arg_character(x);
    const zuid_format *fmt = arg_format(format);
    R_xlen_t n = XLENGTH(x);
    const char *names[] = {"time_s",  "time_ns",  "time_unit",
                           "version", "variant",  "node",
                           "sequence", "random", "prefix", "process"};
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 10));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, 10));
    SEXPTYPE types[] = {REALSXP, REALSXP, STRSXP, INTSXP, STRSXP,
                        STRSXP,  INTSXP,  STRSXP, STRSXP, INTSXP};
    for (int j = 0; j < 10; j++) {
        SET_VECTOR_ELT(out, j, Rf_allocVector(types[j], n));
        SET_STRING_ELT(nms, j, Rf_mkChar(names[j]));
    }
    Rf_setAttrib(out, R_NamesSymbol, nms);
    double *ts = REAL(VECTOR_ELT(out, 0)), *tns = REAL(VECTOR_ELT(out, 1));
    int *ver = INTEGER(VECTOR_ELT(out, 3)), *seq = INTEGER(VECTOR_ELT(out, 6));
    uint8_t bytes[ZUID_MAX_WIDTH];
    zuid_prefix pfx;
    zuid_fields f;

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING || !canonical_bytes(fmt, s, bytes, &pfx)) {
            zuid_fields_clear(&f);
        } else {
            fmt->fields(bytes, &pfx, &f);
        }
        ts[i] = f.has_time ? (double) f.time_s : NA_REAL;
        tns[i] = f.has_time ? (double) f.time_frac_ns : NA_REAL;
        SET_STRING_ELT(VECTOR_ELT(out, 2), i, string_or_na(f.time_unit));
        ver[i] = f.version < 0 ? NA_INTEGER : f.version;
        SET_STRING_ELT(VECTOR_ELT(out, 4), i, string_or_na(f.variant));
        SET_STRING_ELT(VECTOR_ELT(out, 5), i, string_or_na(f.node));
        seq[i] = f.sequence < 0 ? NA_INTEGER : f.sequence;
        SET_STRING_ELT(VECTOR_ELT(out, 7), i, string_or_na(f.random));
        SET_STRING_ELT(VECTOR_ELT(out, 8), i,
                       f.has_prefix
                           ? zuid_mkchar(f.prefix, strlen(f.prefix))
                           : NA_STRING);
        INTEGER(VECTOR_ELT(out, 9))[i] = f.process < 0 ? NA_INTEGER : f.process;
    }
    UNPROTECT(2);
    return out;
}

/* The descriptor table as columns, for id_formats(). */
SEXP zuid_c_formats(void)
{
    static const char *const class_names[] = {"structured", "encoding",
                                              "syntactic"};
    const char *names[] = {"format", "class", "width", "text_min", "text_max",
                           "alphabet", "case", "time_unit", "epoch", "forms"};
    int n = zuid_n_formats, ncol = 10;
    SEXP out = PROTECT(Rf_allocVector(VECSXP, ncol));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, ncol));
    for (int j = 0; j < ncol; j++) {
        int is_int = j >= 2 && j <= 4;
        SET_VECTOR_ELT(out, j, Rf_allocVector(is_int ? INTSXP : STRSXP, n));
        SET_STRING_ELT(nms, j, Rf_mkChar(names[j]));
    }
    Rf_setAttrib(out, R_NamesSymbol, nms);
    for (int i = 0; i < n; i++) {
        const zuid_format *f = zuid_formats[i];
        SET_STRING_ELT(VECTOR_ELT(out, 0), i, string_or_na(f->name));
        SET_STRING_ELT(VECTOR_ELT(out, 1), i, string_or_na(class_names[f->cls]));
        INTEGER(VECTOR_ELT(out, 2))[i] = f->width * 8;
        INTEGER(VECTOR_ELT(out, 3))[i] = f->text_min;
        INTEGER(VECTOR_ELT(out, 4))[i] = f->text_max;
        SET_STRING_ELT(VECTOR_ELT(out, 5), i, string_or_na(f->alphabet));
        SET_STRING_ELT(VECTOR_ELT(out, 6), i, string_or_na(f->case_rule));
        SET_STRING_ELT(VECTOR_ELT(out, 7), i, string_or_na(f->time_unit));
        SET_STRING_ELT(VECTOR_ELT(out, 8), i, string_or_na(f->epoch));
        SET_STRING_ELT(VECTOR_ELT(out, 9), i, string_or_na(f->forms));
    }
    UNPROTECT(2);
    return out;
}

/* Hex of each element's bytes, after a TypeID's prefix and '_': the sort
 * and comparison key, since the canonical text of some formats does not
 * sort as their bytes do. */
SEXP zuid_c_key(SEXP x, SEXP format)
{
    static const char digits[] = "0123456789abcdef";
    arg_character(x);
    const zuid_format *fmt = arg_format(format);
    R_xlen_t n = XLENGTH(x);
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    uint8_t bytes[ZUID_MAX_WIDTH];
    zuid_prefix pfx;
    char buf[ZUID_PREFIX_MAX + 1 + 2 * ZUID_MAX_WIDTH];

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING || !canonical_bytes(fmt, s, bytes, &pfx)) {
            SET_STRING_ELT(out, i, NA_STRING);
            continue;
        }
        size_t m = 0;
        if (pfx.len > 0) {
            memcpy(buf, pfx.s, pfx.len);
            m = pfx.len;
            buf[m++] = '_';
        }
        for (int j = 0; j < fmt->width; j++) {
            buf[m++] = digits[bytes[j] >> 4];
            buf[m++] = digits[bytes[j] & 0x0f];
        }
        SET_STRING_ELT(out, i, zuid_mkchar(buf, m));
    }
    UNPROTECT(1);
    return out;
}
