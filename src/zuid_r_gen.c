/* R entry points for generation. They read the clock and the entropy source
 * once per call and hand both to the pure generators of zuid_gen.c (design.md
 * D5, D6). The monotonic state lives here, serialised by R's single thread. */

#include "zuid_r.h"
#include "zuid_formats.h"
#include "zuid_gen.h"

#include <stdlib.h>
#include <string.h>

/* 100 ns ticks between 1582-10-15 and 1970-01-01. */
#define GREGORIAN_OFFSET INT64_C(0x01B21DD213814000)

static zuid_uuid7_state uuid7_state;
static zuid_uuid1_state uuid1_state;
static zuid_ulid_state ulid_state;
static zuid_scru128_state scru128_state;
/* SCRU64 keeps one state per (node, node_bits), so that values for one
 * node stay monotonic whichever other nodes the session generates for. A
 * full table reuses its oldest slot. */
#define SCRU64_STATES 16
static zuid_scru64_state scru64_states[SCRU64_STATES];
static int scru64_next;

static zuid_scru64_state *scru64_state_for(uint32_t node, int node_bits)
{
    for (int k = 0; k < SCRU64_STATES; k++) {
        zuid_scru64_state *s = &scru64_states[k];
        if (s->has && s->node == node && s->node_bits == node_bits) return s;
    }
    zuid_scru64_state *s = &scru64_states[scru64_next];
    scru64_next = (scru64_next + 1) % SCRU64_STATES;
    memset(s, 0, sizeof *s);
    return s;
}
static int session_clock_seq = -1; /* -1 until first drawn */
static uint8_t session_node[6];

SEXP zuid_c_reset_state(void)
{
    memset(&uuid7_state, 0, sizeof uuid7_state);
    memset(&uuid1_state, 0, sizeof uuid1_state);
    memset(&ulid_state, 0, sizeof ulid_state);
    memset(&scru128_state, 0, sizeof scru128_state);
    memset(scru64_states, 0, sizeof scru64_states);
    scru64_next = 0;
    zuid_layout_reset_state();
    session_clock_seq = -1;
    memset(session_node, 0, sizeof session_node);
    return R_NilValue;
}

/* Test-only: make the entropy source fail (TRUE) or work again (FALSE). */
SEXP zuid_c_entropy_fail(SEXP fail)
{
    zuid_entropy_set_failure(Rf_asLogical(fail) == TRUE);
    return R_NilValue;
}

SEXP zuid_c_state(void)
{
    const char *names[] = {"entropy",          "uuid7_last_ms",
                           "uuid7_counter",    "uuid1_last_ticks",
                           "uuid1_clock_seq",  "ulid_last_ms"};
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 6));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, 6));
    for (int i = 0; i < 6; i++) SET_STRING_ELT(nms, i, Rf_mkChar(names[i]));
    Rf_setAttrib(out, R_NamesSymbol, nms);
    const char *src = zuid_entropy_source();
    SET_VECTOR_ELT(out, 0, Rf_ScalarString(zuid_mkchar(src, strlen(src))));
    SET_VECTOR_ELT(out, 1, Rf_ScalarReal(uuid7_state.has
                                             ? (double) uuid7_state.last_ms
                                             : NA_REAL));
    SET_VECTOR_ELT(out, 2, Rf_ScalarInteger(uuid7_state.has
                                                ? uuid7_state.counter
                                                : NA_INTEGER));
    SET_VECTOR_ELT(out, 3, Rf_ScalarReal(uuid1_state.has
                                             ? (double) uuid1_state.last_ticks
                                             : NA_REAL));
    SET_VECTOR_ELT(out, 4, Rf_ScalarInteger(session_clock_seq < 0
                                                ? NA_INTEGER
                                                : session_clock_seq));
    SET_VECTOR_ELT(out, 5, Rf_ScalarReal(ulid_state.has
                                             ? (double) ulid_state.last_ms
                                             : NA_REAL));
    UNPROTECT(2);
    return out;
}

/* Fills `buf` from `random` when given, else from the entropy source.
 * Returns 0 on success, -1 when the entropy source failed. */
static int take_random(SEXP random, size_t need, uint8_t *buf)
{
    if (!Rf_isNull(random)) {
        if (TYPEOF(random) != RAWSXP || (size_t) XLENGTH(random) != need) {
            Rf_error("zuid: `random` must be %lu raw bytes",
                     (unsigned long) need);
        }
        memcpy(buf, RAW(random), need);
        return 0;
    }
    return zuid_entropy(buf, need);
}

/* With both `time` and `random` given, a call is a pure function of its
 * inputs (D6): it uses a fresh state of its own and leaves the session's
 * alone. */
static int is_pure(SEXP time_us, SEXP random)
{
    return !Rf_isNull(time_us) && !Rf_isNull(random);
}

/* `time_us`: NULL to read the clock, or microseconds since 1970 per value.
 * Returns the canonical text, NULL when the entropy source failed (the R
 * caller raises zuid_entropy_error), or a negative integer, -(1 + the
 * index) of a value past the time field (zuid_overflow_error). */
SEXP zuid_c_uuid(SEXP n_, SEXP version_, SEXP time_us, SEXP random,
                 SEXP node, SEXP tolerance_ms)
{
    R_xlen_t n = (R_xlen_t) Rf_asReal(n_);
    int version = Rf_asInteger(version_);
    int64_t tol_ms = (int64_t) Rf_asReal(tolerance_ms);
    if (n < 0) Rf_error("zuid: `n` must be non-negative");
    if (!Rf_isNull(time_us) &&
        (TYPEOF(time_us) != REALSXP || XLENGTH(time_us) != n)) {
        Rf_error("zuid: `time` must be one value per element");
    }

    size_t un = (size_t) n;
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 16);
    int64_t *t100 = (int64_t *) R_alloc(un ? un : 1, sizeof(int64_t));
    if (Rf_isNull(time_us)) {
        int64_t now = zuid_clock_now_100ns();
        for (size_t i = 0; i < un; i++) t100[i] = now;
    } else {
        const double *us = REAL(time_us);
        for (size_t i = 0; i < un; i++) t100[i] = (int64_t) us[i] * 10;
    }

    if (version == 4 || version == 8) {
        uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, 16);
        if (take_random(random, 16 * un, r) != 0) return R_NilValue;
        zuid_gen_uuid_random(un, version, r, bytes);
    } else if (version == 7) {
        uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, ZUID_UUID7_RANDOM);
        if (take_random(random, ZUID_UUID7_RANDOM * un, r) != 0) {
            return R_NilValue;
        }
        int64_t *ms = (int64_t *) R_alloc(un ? un : 1, sizeof(int64_t));
        for (size_t i = 0; i < un; i++) {
            int64_t q = t100[i] / 10000;
            ms[i] = (t100[i] % 10000 < 0) ? q - 1 : q;
        }
        zuid_uuid7_state local = {0};
        size_t bad = zuid_gen_uuid7(un, ms, r, tol_ms,
                                    is_pure(time_us, random) ? &local
                                                             : &uuid7_state,
                                    bytes);
        if (bad) return Rf_ScalarInteger(-(int) bad);
    } else if (version == 1 || version == 6) {
        /* Clock sequence (2 bytes) and, without `node`, the node (6 bytes):
         * from `random` for this call, else drawn once per session. */
        int have_node = !Rf_isNull(node);
        if (have_node && (TYPEOF(node) != RAWSXP || XLENGTH(node) != 6)) {
            Rf_error("zuid: `node` must be 6 raw bytes");
        }
        uint8_t r[8];
        int clock_seq;
        uint8_t node_bytes[6];
        if (!Rf_isNull(random)) {
            take_random(random, have_node ? 2 : 8, r);
            clock_seq = ((r[0] << 8) | r[1]) & 0x3fff;
            memcpy(node_bytes, r + 2, 6);
            node_bytes[0] |= 0x01; /* multicast: not a hardware address */
        } else {
            if (session_clock_seq < 0) {
                if (zuid_entropy(r, 8) != 0) return R_NilValue;
                session_clock_seq = ((r[0] << 8) | r[1]) & 0x3fff;
                memcpy(session_node, r + 2, 6);
                session_node[0] |= 0x01;
            }
            clock_seq = session_clock_seq;
            memcpy(node_bytes, session_node, 6);
        }
        if (have_node) memcpy(node_bytes, RAW(node), 6);
        for (size_t i = 0; i < un; i++) t100[i] += GREGORIAN_OFFSET;
        zuid_uuid1_state local = {0};
        size_t bad = zuid_gen_uuid_time(un, version, t100, &clock_seq,
                                        node_bytes, tol_ms * 10000,
                                        is_pure(time_us, random)
                                            ? &local
                                            : &uuid1_state,
                                        bytes);
        if (bad) return Rf_ScalarInteger(-(int) bad);
        if (Rf_isNull(random)) session_clock_seq = clock_seq;
    } else {
        Rf_error("zuid: version %d is not generated", version);
    }

    SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
    char buf[ZUID_TEXT_BUF];
    for (size_t i = 0; i < un; i++) {
        size_t m = zuid_fmt_uuid.format(bytes + 16 * i, -1, NULL, buf);
        SET_STRING_ELT(out, (R_xlen_t) i, zuid_mkchar(buf, m));
    }
    UNPROTECT(1);
    return out;
}

/* Milliseconds since 1970 per value: from `time_us` (microseconds, floored)
 * or the clock. */
static int64_t *value_ms(SEXP time_us, size_t un)
{
    int64_t *ms = (int64_t *) R_alloc(un ? un : 1, sizeof(int64_t));
    if (Rf_isNull(time_us)) {
        int64_t now = zuid_clock_now_100ns() / 10000;
        for (size_t i = 0; i < un; i++) ms[i] = now;
    } else {
        if (TYPEOF(time_us) != REALSXP || (size_t) XLENGTH(time_us) != un) {
            Rf_error("zuid: `time` must be one value per element");
        }
        const double *us = REAL(time_us);
        for (size_t i = 0; i < un; i++) {
            int64_t v = (int64_t) us[i];
            ms[i] = v / 1000 - (v % 1000 < 0);
        }
    }
    return ms;
}

static SEXP canonical_strings(const zuid_format *fmt, const uint8_t *bytes,
                              size_t un)
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

/* NULL when the entropy source failed; an integer, the position of the
 * value that overflowed, on monotonic overflow (zuid_overflow_error). */
SEXP zuid_c_ulid(SEXP n_, SEXP time_us, SEXP random, SEXP tolerance_ms)
{
    double dn = Rf_asReal(n_);
    if (!(dn >= 0)) Rf_error("zuid: `n` must be non-negative");
    size_t un = (size_t) dn;
    int64_t tol_ms = (int64_t) Rf_asReal(tolerance_ms);
    int64_t *ms = value_ms(time_us, un);
    uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, ZUID_ULID_RANDOM);
    if (take_random(random, ZUID_ULID_RANDOM * un, r) != 0) return R_NilValue;
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 16);
    zuid_ulid_state local = {0};
    size_t bad = zuid_gen_ulid(un, ms, r, tol_ms,
                               is_pure(time_us, random) ? &local : &ulid_state,
                               bytes);
    if (bad) return Rf_ScalarInteger((int) bad);
    return canonical_strings(&zuid_fmt_ulid, bytes, un);
}

/* `tail`: three raw bytes, the prefix and version. NULL when the entropy
 * source failed. */
SEXP zuid_c_upid(SEXP n_, SEXP time_us, SEXP random, SEXP tail)
{
    double dn = Rf_asReal(n_);
    if (!(dn >= 0)) Rf_error("zuid: `n` must be non-negative");
    if (TYPEOF(tail) != RAWSXP || XLENGTH(tail) != 3) {
        Rf_error("zuid: `tail` must be 3 raw bytes");
    }
    size_t un = (size_t) dn;
    int64_t *ms = value_ms(time_us, un);
    uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, ZUID_UPID_RANDOM);
    if (take_random(random, ZUID_UPID_RANDOM * un, r) != 0) return R_NilValue;
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 16);
    zuid_gen_upid(un, ms, r, RAW(tail), bytes);
    return canonical_strings(&zuid_fmt_upid, bytes, un);
}

static size_t arg_count(SEXP n_)
{
    double dn = Rf_asReal(n_);
    if (!(dn >= 0)) Rf_error("zuid: `n` must be non-negative");
    return (size_t) dn;
}

/* NULL when the entropy source failed; an integer, the position of the
 * value, on a rollback beyond the tolerance (zuid_clock_error), negated
 * for an overflow into the reserved timestamp (zuid_overflow_error). */
SEXP zuid_c_scru128(SEXP n_, SEXP time_us, SEXP random, SEXP tolerance_ms,
                    SEXP reset)
{
    size_t un = arg_count(n_);
    int64_t *ms = value_ms(time_us, un);
    uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, ZUID_SCRU128_RANDOM);
    if (take_random(random, ZUID_SCRU128_RANDOM * un, r) != 0) {
        return R_NilValue;
    }
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 16);
    zuid_scru128_state local = {0};
    long bad = zuid_gen_scru128(un, ms, r, (int64_t) Rf_asReal(tolerance_ms),
                                Rf_asLogical(reset) == TRUE,
                                is_pure(time_us, random) ? &local
                                                         : &scru128_state,
                                bytes);
    if (bad) return Rf_ScalarInteger((int) bad);
    return canonical_strings(&zuid_fmt_scru128, bytes, un);
}

/* As zuid_c_scru128(); a negative integer is a timestamp past the largest
 * SCRU64 can hold (zuid_overflow_error). */
SEXP zuid_c_scru64(SEXP n_, SEXP time_us, SEXP random, SEXP node,
                   SEXP node_bits, SEXP tolerance_ms, SEXP reset)
{
    size_t un = arg_count(n_);
    int bits = Rf_asInteger(node_bits);
    double nd = Rf_asReal(node);
    if (bits < 1 || bits > 23 || !(nd >= 0) || nd >= (double) (1 << bits)) {
        Rf_error("zuid: `node` must fit `node_bits`, 1 to 23");
    }
    int64_t *ms = value_ms(time_us, un);
    uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, ZUID_SCRU64_RANDOM);
    if (take_random(random, ZUID_SCRU64_RANDOM * un, r) != 0) {
        return R_NilValue;
    }
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 8);
    zuid_scru64_state local = {0};
    zuid_scru64_state *state = is_pure(time_us, random)
                                   ? &local
                                   : scru64_state_for((uint32_t) nd, bits);
    long bad = zuid_gen_scru64(un, ms, r, (uint32_t) nd, bits,
                               (int64_t) Rf_asReal(tolerance_ms),
                               Rf_asLogical(reset) == TRUE, state, bytes);
    if (bad) return Rf_ScalarInteger((int) bad);
    return canonical_strings(&zuid_fmt_scru64, bytes, un);
}

SEXP zuid_c_ksuid(SEXP n_, SEXP time_us, SEXP random)
{
    size_t un = arg_count(n_);
    int64_t *ms = value_ms(time_us, un);
    uint8_t *r = (uint8_t *) R_alloc(un ? un : 1, ZUID_KSUID_RANDOM);
    if (take_random(random, ZUID_KSUID_RANDOM * un, r) != 0) return R_NilValue;
    uint8_t *bytes = (uint8_t *) R_alloc(un ? un : 1, 20);
    zuid_gen_ksuid(un, ms, r, bytes);
    return canonical_strings(&zuid_fmt_ksuid, bytes, un);
}
