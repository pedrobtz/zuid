/* R entry points for the variable-width formats: NanoID, Cuid2, Sqids and
 * CID (design.md 6.1, 6.6). The R side checks the parameters; these check
 * only what C relies on. */

#include "zuid_r.h"
#include "zuid_gen.h"
#include "zuid_sqids.h"
#include "zuid_cid.h"
#include "zuid_tables.h"

#include <stdio.h>
#include <string.h>

static void check_text(SEXP x)
{
    if (TYPEOF(x) != STRSXP) Rf_error("zuid: `x` must be character");
}

/* ---- NanoID and Cuid2 ---------------------------------------------------- */

/* Level 3 when every character is in `alphabet` (and there is one), else
 * 0; NA for NA. */
SEXP zuid_c_charset(SEXP x, SEXP alphabet)
{
    check_text(x);
    const char *a = CHAR(STRING_ELT(alphabet, 0));
    uint8_t in[256] = {0};
    for (const char *p = a; *p; p++) in[(unsigned char) *p] = 1;
    R_xlen_t n = XLENGTH(x);
    SEXP out = PROTECT(Rf_allocVector(INTSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING) {
            INTEGER(out)[i] = NA_INTEGER;
            continue;
        }
        const char *c = CHAR(s);
        int len = LENGTH(s), ok = len > 0;
        for (int k = 0; k < len && ok; k++) ok = in[(unsigned char) c[k]];
        INTEGER(out)[i] = ok ? 3 : 0;
    }
    UNPROTECT(1);
    return out;
}

/* Cuid2: 2 to 32 of 0-9a-z (structure, the reference's isCuid); strict
 * when it starts with a letter, as the generator writes it. */
SEXP zuid_c_cuid2(SEXP x)
{
    check_text(x);
    R_xlen_t n = XLENGTH(x);
    SEXP out = PROTECT(Rf_allocVector(INTSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING) {
            INTEGER(out)[i] = NA_INTEGER;
            continue;
        }
        const char *c = CHAR(s);
        int len = LENGTH(s), ok = len >= 2 && len <= 32;
        for (int k = 0; k < len && ok; k++) {
            ok = (c[k] >= '0' && c[k] <= '9') || (c[k] >= 'a' && c[k] <= 'z');
        }
        INTEGER(out)[i] = !ok ? 0 : (c[0] >= 'a' && c[0] <= 'z') ? 3 : 2;
    }
    UNPROTECT(1);
    return out;
}

/* `n` NanoIDs of `size` symbols by NanoID 6's customRandom(): bytes come
 * in batches (`size` for a power-of-two alphabet, else 1.6 * 256 * size /
 * cutoff) and are read from the last; a byte at or above the cutoff (256
 * minus 256 mod the alphabet's size) is rejected. `random` is NULL for the
 * entropy source, or a raw vector read in turn; when it runs out the
 * result is an integer, the value that needed more. NULL when the entropy
 * source failed. */
SEXP zuid_c_nanoid(SEXP n_, SEXP size_, SEXP alphabet, SEXP random)
{
    size_t n = (size_t) Rf_asReal(n_), size = (size_t) Rf_asReal(size_);
    SEXP a_ = STRING_ELT(alphabet, 0);
    const char *a = CHAR(a_);
    unsigned na = (unsigned) LENGTH(a_);
    if (na < 1 || na > 256) Rf_error("zuid: `alphabet` must be 1 to 256 symbols");
    unsigned cutoff = 256 - 256 % na;
    size_t step = size;
    if (cutoff != 256) {
        /* Math.ceil(1.6 * 256 * size / cutoff), as the reference has it. */
        double q = 1.6 * 256.0 * (double) size / (double) cutoff;
        step = (size_t) q;
        if ((double) step < q) step++;
    }
    const uint8_t *fixed = Rf_isNull(random) ? NULL : RAW(random);
    size_t fixed_n = fixed ? (size_t) XLENGTH(random) : 0, used = 0;

    SEXP out = PROTECT(Rf_allocVector(STRSXP, (R_xlen_t) n));
    char *id = R_alloc(size ? size : 1, 1);
    uint8_t *bytes = (uint8_t *) R_alloc(step ? step : 1, 1);
    for (size_t v = 0; v < n; v++) {
        size_t m = 0;
        while (m < size) {
            if (fixed) {
                if (fixed_n - used < step) {
                    UNPROTECT(1);
                    return Rf_ScalarInteger((int) v + 1);
                }
                memcpy(bytes, fixed + used, step);
                used += step;
            } else if (zuid_entropy(bytes, step) != 0) {
                UNPROTECT(1);
                return R_NilValue;
            }
            for (size_t i = step; i-- > 0 && m < size;) {
                if (bytes[i] < cutoff) id[m++] = a[bytes[i] % na];
            }
        }
        SET_STRING_ELT(out, (R_xlen_t) v, zuid_mkchar(id, size));
    }
    UNPROTECT(1);
    return out;
}

/* ---- Sqids --------------------------------------------------------------- */

typedef struct {
    zuid_sqids s;
    const char **block;
} sqids_arg;

/* `blocklist`: NULL for the default, else a character vector. */
static void arg_sqids(SEXP alphabet, SEXP min_length, SEXP blocklist,
                      sqids_arg *out)
{
    SEXP a = STRING_ELT(alphabet, 0);
    const char **words = NULL;
    size_t nwords = 0;
    if (!Rf_isNull(blocklist)) {
        nwords = (size_t) XLENGTH(blocklist);
        words = (const char **) R_alloc(nwords ? nwords : 1, sizeof(char *));
        for (size_t i = 0; i < nwords; i++) {
            words[i] = CHAR(STRING_ELT(blocklist, (R_xlen_t) i));
        }
    }
    size_t cap = words ? nwords : ZUID_SQIDS_BLOCKLIST_N;
    out->block = (const char **) R_alloc(cap ? cap : 1, sizeof(char *));
    if (zuid_sqids_init(&out->s, CHAR(a), (size_t) LENGTH(a),
                        Rf_asInteger(min_length), words, nwords,
                        out->block) != 0) {
        Rf_error("zuid: bad Sqids alphabet or `min_length`");
    }
}

/* `numbers`: a list of double vectors, NULL for a missing element. Returns
 * the text, or an integer: the value whose every encoding is blocked
 * (zuid_encode_error). */
SEXP zuid_c_sqids_encode(SEXP numbers, SEXP alphabet, SEXP min_length,
                         SEXP blocklist)
{
    sqids_arg arg;
    arg_sqids(alphabet, min_length, blocklist, &arg);
    R_xlen_t n = XLENGTH(numbers);
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP v = VECTOR_ELT(numbers, i);
        if (Rf_isNull(v)) {
            SET_STRING_ELT(out, i, NA_STRING);
            continue;
        }
        size_t count = (size_t) XLENGTH(v);
        const void *vmax = vmaxget();
        uint64_t *num = (uint64_t *) R_alloc(count ? count : 1, sizeof(uint64_t));
        for (size_t k = 0; k < count; k++) num[k] = (uint64_t) REAL(v)[k];
        char *buf = R_alloc(zuid_sqids_max_len(&arg.s, count), 1);
        long m = zuid_sqids_encode(&arg.s, num, count, buf);
        if (m < 0) {
            UNPROTECT(1);
            return Rf_ScalarInteger((int) i + 1);
        }
        SET_STRING_ELT(out, i, zuid_mkchar(buf, (size_t) m));
        vmaxset(vmax);
    }
    UNPROTECT(1);
    return out;
}

/* list(level, numbers): level 1 when every character is in the alphabet,
 * 3 when it also decodes and encodes back to itself (structure and strict
 * are the same for Sqids), 0 otherwise; numbers as doubles, NULL below
 * level 3. */
SEXP zuid_c_sqids_parse(SEXP x, SEXP alphabet, SEXP min_length,
                        SEXP blocklist)
{
    check_text(x);
    sqids_arg arg;
    arg_sqids(alphabet, min_length, blocklist, &arg);
    R_xlen_t n = XLENGTH(x);
    SEXP level = PROTECT(Rf_allocVector(INTSXP, n));
    SEXP nums = PROTECT(Rf_allocVector(VECSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        if (s == NA_STRING) {
            INTEGER(level)[i] = NA_INTEGER;
            continue;
        }
        const char *c = CHAR(s);
        size_t len = (size_t) LENGTH(s);
        int syntax = len > 0;
        for (size_t k = 0; k < len && syntax; k++) {
            unsigned char ch = (unsigned char) c[k];
            syntax = ch <= 127 && arg.s.present[ch];
        }
        INTEGER(level)[i] = syntax ? 1 : 0;
        if (!syntax) continue;
        const void *vmax = vmaxget();
        uint64_t *v = (uint64_t *) R_alloc(len, sizeof(uint64_t));
        long count = zuid_sqids_decode(&arg.s, c, len, v);
        if (count > 0) {
            char *buf = R_alloc(zuid_sqids_max_len(&arg.s, (size_t) count), 1);
            long m = zuid_sqids_encode(&arg.s, v, (size_t) count, buf);
            if (m == (long) len && memcmp(buf, c, len) == 0) {
                SEXP r = Rf_allocVector(REALSXP, count);
                for (long k = 0; k < count; k++) REAL(r)[k] = (double) v[k];
                SET_VECTOR_ELT(nums, i, r);
                INTEGER(level)[i] = 3;
            }
        }
        vmaxset(vmax);
    }
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(out, 0, level);
    SET_VECTOR_ELT(out, 1, nums);
    UNPROTECT(3);
    return out;
}

/* ---- CID ----------------------------------------------------------------- */

static SEXP hex_string(const uint8_t *b, size_t n)
{
    static const char digits[] = "0123456789abcdef";
    char *buf = R_alloc(2 * n + 1, 1);
    for (size_t i = 0; i < n; i++) {
        buf[2 * i] = digits[b[i] >> 4];
        buf[2 * i + 1] = digits[b[i] & 15];
    }
    return zuid_mkchar(buf, 2 * n);
}

static SEXP code_name(uint64_t code)
{
    const char *name = zuid_multicodec_name(code);
    if (name) return zuid_mkchar(name, strlen(name));
    char buf[24];
    int m = snprintf(buf, sizeof buf, "0x%llx", (unsigned long long) code);
    return zuid_mkchar(buf, (size_t) m);
}

/* list(level, version, codec, hash, digest, bytes), the fields NA and the
 * bytes NULL below level 1. */
SEXP zuid_c_cid_parse(SEXP x)
{
    check_text(x);
    R_xlen_t n = XLENGTH(x);
    const char *names[] = {"level", "version", "codec", "hash", "digest", "bytes"};
    SEXPTYPE types[] = {INTSXP, INTSXP, STRSXP, STRSXP, STRSXP, VECSXP};
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 6));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, 6));
    for (int j = 0; j < 6; j++) {
        SET_VECTOR_ELT(out, j, Rf_allocVector(types[j], n));
        SET_STRING_ELT(nms, j, Rf_mkChar(names[j]));
    }
    Rf_setAttrib(out, R_NamesSymbol, nms);
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP s = STRING_ELT(x, i);
        int level = NA_INTEGER;
        zuid_cid c;
        const void *vmax = vmaxget();
        uint8_t *b = NULL;
        if (s != NA_STRING) {
            size_t len = (size_t) LENGTH(s);
            b = (uint8_t *) R_alloc(len + 8, 1);
            level = zuid_cid_parse(CHAR(s), len, b, &c);
        }
        INTEGER(VECTOR_ELT(out, 0))[i] = level;
        if (level == NA_INTEGER || level < 1) {
            INTEGER(VECTOR_ELT(out, 1))[i] = NA_INTEGER;
            SET_STRING_ELT(VECTOR_ELT(out, 2), i, NA_STRING);
            SET_STRING_ELT(VECTOR_ELT(out, 3), i, NA_STRING);
            SET_STRING_ELT(VECTOR_ELT(out, 4), i, NA_STRING);
        } else {
            INTEGER(VECTOR_ELT(out, 1))[i] = c.version;
            SET_STRING_ELT(VECTOR_ELT(out, 2), i, code_name(c.codec));
            SET_STRING_ELT(VECTOR_ELT(out, 3), i, code_name(c.hash));
            SET_STRING_ELT(VECTOR_ELT(out, 4), i,
                           hex_string(b + c.digest_at, c.digest_len));
            SEXP raw = Rf_allocVector(RAWSXP, (R_xlen_t) c.nbytes);
            memcpy(RAW(raw), b, c.nbytes);
            SET_VECTOR_ELT(VECTOR_ELT(out, 5), i, raw);
        }
        vmaxset(vmax);
    }
    UNPROTECT(2);
    return out;
}

/* Text of binary CIDs (a list of raw vectors, NULL for missing); NA where
 * the bytes are not a CID. */
SEXP zuid_c_cid_text(SEXP bytes)
{
    R_xlen_t n = XLENGTH(bytes);
    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    for (R_xlen_t i = 0; i < n; i++) {
        SEXP b = VECTOR_ELT(bytes, i);
        if (TYPEOF(b) != RAWSXP) {
            SET_STRING_ELT(out, i, NA_STRING);
            continue;
        }
        size_t nb = (size_t) XLENGTH(b);
        const void *vmax = vmaxget();
        char *buf = R_alloc(2 * nb + 8, 1);
        long m = zuid_cid_text(RAW(b), nb, buf);
        SET_STRING_ELT(out, i, m < 0 ? NA_STRING : zuid_mkchar(buf, (size_t) m));
        vmaxset(vmax);
    }
    UNPROTECT(1);
    return out;
}
