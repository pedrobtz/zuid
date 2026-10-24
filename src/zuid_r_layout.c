/* R entry points for layouts, Snowflake, XID and ObjectId (design.md 6.6,
 * 6.8). The R side builds and checks the layout; here it is a list of part
 * widths and kinds. */

#include "zuid_r.h"
#include "zuid_formats.h"
#include "zuid_gen.h"

#include <string.h>

static zuid_snowflake_state snowflake_state;
static zuid_counter_state xid_counter, objectid_counter;
static int xid_machine_drawn, objectid_random_drawn;
static uint8_t xid_machine[3], objectid_random[5];

void zuid_layout_reset_state(void)
{
    memset(&snowflake_state, 0, sizeof snowflake_state);
    memset(&xid_counter, 0, sizeof xid_counter);
    memset(&objectid_counter, 0, sizeof objectid_counter);
    xid_machine_drawn = objectid_random_drawn = 0;
}

static zuid_layout_spec arg_spec(SEXP widths, SEXP kinds)
{
    zuid_layout_spec spec;
    memset(&spec, 0, sizeof spec);
    R_xlen_t n = XLENGTH(widths);
    if (TYPEOF(widths) != INTSXP || TYPEOF(kinds) != INTSXP ||
        XLENGTH(kinds) != n || n < 1 || n > ZUID_LAYOUT_PARTS) {
        Rf_error("zuid: a layout is 1 to %d parts", ZUID_LAYOUT_PARTS);
    }
    int total = 0;
    for (R_xlen_t k = 0; k < n; k++) {
        int w = INTEGER(widths)[k], kind = INTEGER(kinds)[k];
        if (w < 1 || w > 63 || kind < ZUID_PART_TIME ||
            kind > ZUID_PART_SEQUENCE) {
            Rf_error("zuid: bad layout part");
        }
        spec.width[k] = w;
        spec.kind[k] = kind;
        total += w;
    }
    if (total != 63 && total != 64) Rf_error("zuid: a layout is 63 or 64 bits");
    spec.nparts = (int) n;
    return spec;
}

/* One double column per part. The R side keeps every part below 2^53. */
SEXP zuid_c_layout_unpack(SEXP bytes, SEXP widths, SEXP kinds)
{
    zuid_layout_spec spec = arg_spec(widths, kinds);
    if (TYPEOF(bytes) != RAWSXP || XLENGTH(bytes) % 8 != 0) {
        Rf_error("zuid: `bytes` must be raw, 8 per value");
    }
    R_xlen_t n = XLENGTH(bytes) / 8;
    SEXP out = PROTECT(Rf_allocVector(VECSXP, spec.nparts));
    for (int k = 0; k < spec.nparts; k++) {
        SET_VECTOR_ELT(out, k, Rf_allocVector(REALSXP, n));
    }
    uint64_t parts[ZUID_LAYOUT_PARTS];
    for (R_xlen_t i = 0; i < n; i++) {
        zuid_layout_unpack(RAW(bytes) + 8 * i, &spec, parts);
        for (int k = 0; k < spec.nparts; k++) {
            REAL(VECTOR_ELT(out, k))[i] = (double) parts[k];
        }
    }
    UNPROTECT(1);
    return out;
}

static SEXP texts(const zuid_format *fmt, const uint8_t *bytes, size_t un)
{
    SEXP out = PROTECT(Rf_allocVector(STRSXP, (R_xlen_t) un));
    char buf[ZUID_TEXT_BUF];
    size_t w = (size_t) fmt->width;
    for (size_t i = 0; i < un; i++) {
        size_t m = fmt->format(bytes + w * i, -1, NULL, buf);
        SET_STRING_ELT(out, (R_xlen_t) i, zuid_mkchar(buf, m));
    }
    UNPROTECT(1);
    return out;
}

static int64_t *whole_values(SEXP x, size_t un)
{
    if (TYPEOF(x) != REALSXP || (size_t) XLENGTH(x) != un) {
        Rf_error("zuid: expected one time value per element");
    }
    int64_t *v = (int64_t *) R_alloc(un ? un : 1, sizeof(int64_t));
    for (size_t i = 0; i < un; i++) v[i] = (int64_t) REAL(x)[i];
    return v;
}

/* `node`: one value per part, ignored for non-node parts. Returns the text,
 * or an integer as zuid_gen_snowflake() describes. */
SEXP zuid_c_snowflake(SEXP ticks, SEXP widths, SEXP kinds, SEXP node,
                      SEXP tolerance_ticks)
{
    zuid_layout_spec spec = arg_spec(widths, kinds);
    if (TYPEOF(node) != REALSXP || XLENGTH(node) != spec.nparts) {
        Rf_error("zuid: `node` must have one value per part");
    }
    uint64_t nodes[ZUID_LAYOUT_PARTS] = {0};
    for (int k = 0; k < spec.nparts; k++) {
        double v = REAL(node)[k];
        nodes[k] = spec.kind[k] == ZUID_PART_NODE && v >= 0 ? (uint64_t) v : 0;
    }
    size_t un = (size_t) XLENGTH(ticks);
    int64_t *t = whole_values(ticks, un);
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 8);
    long bad = zuid_gen_snowflake(un, t, &spec, nodes,
                                  (int64_t) Rf_asReal(tolerance_ticks),
                                  &snowflake_state, bytes);
    if (bad) return Rf_ScalarInteger((int) bad);
    return texts(&zuid_fmt_snowflake, bytes, un);
}

/* Fills `buf` from `fixed` when given, else from the entropy source. */
static int bytes_or_entropy(SEXP fixed, size_t need, uint8_t *buf)
{
    if (!Rf_isNull(fixed)) {
        if (TYPEOF(fixed) != RAWSXP || (size_t) XLENGTH(fixed) != need) {
            Rf_error("zuid: expected %lu raw bytes", (unsigned long) need);
        }
        memcpy(buf, RAW(fixed), need);
        return 0;
    }
    return zuid_entropy(buf, need);
}

static uint32_t load24(const uint8_t *r)
{
    return (uint32_t) r[0] << 16 | (uint32_t) r[1] << 8 | r[2];
}

/* XID: `machine` (3 bytes) or NULL for the session's; `process` the 16-bit
 * process id; `random` (6 bytes: machine, counter seed) or NULL. With
 * `random` the call uses its own counter and leaves the session's alone.
 * NULL when the entropy source failed. */
SEXP zuid_c_xid(SEXP secs, SEXP machine, SEXP process, SEXP random)
{
    size_t un = (size_t) XLENGTH(secs);
    int64_t *s = whole_values(secs, un);
    uint8_t middle[5];
    zuid_counter_state local, *counter = &xid_counter;
    if (!Rf_isNull(random)) {
        uint8_t r[6];
        bytes_or_entropy(random, 6, r);
        memcpy(middle, r, 3);
        local.has = 1;
        local.counter = load24(r + 3);
        counter = &local;
    } else {
        if (!xid_machine_drawn) {
            if (zuid_entropy(xid_machine, 3) != 0) return R_NilValue;
            xid_machine_drawn = 1;
        }
        if (!xid_counter.has) {
            uint8_t r[3];
            if (zuid_entropy(r, 3) != 0) return R_NilValue;
            xid_counter.counter = load24(r);
            xid_counter.has = 1;
        }
        memcpy(middle, xid_machine, 3);
    }
    if (!Rf_isNull(machine)) bytes_or_entropy(machine, 3, middle);
    int pid = Rf_asInteger(process) & 0xffff;
    middle[3] = (uint8_t) (pid >> 8);
    middle[4] = (uint8_t) pid;
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 12);
    zuid_gen_xid(un, s, middle, counter, bytes);
    return texts(&zuid_fmt_xid, bytes, un);
}

/* ObjectId: `random` (8 bytes: the 5-byte process value, counter seed) or
 * NULL for the session's. */
SEXP zuid_c_objectid(SEXP secs, SEXP random)
{
    size_t un = (size_t) XLENGTH(secs);
    int64_t *s = whole_values(secs, un);
    uint8_t middle[5];
    zuid_counter_state local, *counter = &objectid_counter;
    if (!Rf_isNull(random)) {
        uint8_t r[8];
        bytes_or_entropy(random, 8, r);
        memcpy(middle, r, 5);
        local.has = 1;
        local.counter = load24(r + 5);
        counter = &local;
    } else {
        if (!objectid_random_drawn) {
            if (zuid_entropy(objectid_random, 5) != 0) return R_NilValue;
            objectid_random_drawn = 1;
        }
        if (!objectid_counter.has) {
            uint8_t r[3];
            if (zuid_entropy(r, 3) != 0) return R_NilValue;
            objectid_counter.counter = load24(r);
            objectid_counter.has = 1;
        }
        memcpy(middle, objectid_random, 5);
    }
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 12);
    zuid_gen_xid(un, s, middle, counter, bytes);
    return texts(&zuid_fmt_objectid, bytes, un);
}
