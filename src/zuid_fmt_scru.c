/* SCRU128 (scru128/spec v2.1.1), SCRU64 (scru64/spec v1.0.0) and KSUID
 * (segmentio/ksuid): integers written in base36 or base62 at a fixed width
 * (design.md sections 6.1 and 6.3). */

#include "zuid_formats.h"
#include "zuid_enc.h"

#include <string.h>

static int no_form(const char *form)
{
    (void) form;
    return -2;
}

static uint64_t load_be(const uint8_t *b, int n)
{
    uint64_t v = 0;
    for (int i = 0; i < n; i++) v = v << 8 | b[i];
    return v;
}

static void set_time_ms(zuid_fields *f, uint64_t ms, const char *unit)
{
    f->has_time = 1;
    f->time_s = (int64_t) (ms / 1000);
    f->time_frac_ns = (int32_t) (ms % 1000) * 1000000;
    f->time_unit = unit;
}

static size_t encoded_text(int enc, const uint8_t *b, size_t n, char *out)
{
    long m = zuid_encode(enc, b, n, NULL, "", 0, out);
    return m > 0 ? (size_t) m : 0;
}

/* ---- SCRU128 ------------------------------------------------------------- */

#define SCRU128_MAX_TS ((UINT64_C(1) << 48) - 1)

/* 25 base36 digits, either case, at most 2^128 - 1. Timestamps 0 and
 * 2^48 - 1 are reserved, so they pass syntax only. */
static zuid_level scru128_parse(const char *s, size_t len, int form,
                                uint8_t *out, zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    if (len != 25 || zuid_decode(ZUID_ENC_BASE36, s, len, NULL, 16, out) != 16) {
        return ZUID_LEVEL_NONE;
    }
    uint64_t ts = load_be(out, 6);
    return ts == 0 || ts == SCRU128_MAX_TS ? ZUID_LEVEL_SYNTAX
                                           : ZUID_LEVEL_STRUCTURE;
}

static int scru128_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return (double) load_be(b, 6) <= now_ms + tolerance_ms;
}

static size_t scru128_format(const uint8_t *b, int form,
                             const zuid_prefix *pfx, char *out)
{
    (void) form;
    (void) pfx;
    return encoded_text(ZUID_ENC_BASE36, b, 16, out);
}

/* `node` holds counter_hi and `sequence` counter_lo (design.md 6.4). */
static void scru128_fields(const uint8_t *b, const zuid_prefix *pfx,
                           zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    set_time_ms(f, load_be(b, 6), "ms");
    zuid_bits_hex(b, 48, 24, f->node);
    f->sequence = (int) load_be(b + 9, 3);
    zuid_bits_hex(b, 96, 32, f->random);
}

const zuid_format zuid_fmt_scru128 = {
    "scru128",
    ZUID_CLASS_STRUCTURED,
    16,
    25, 25,
    "0-9a-z",
    "lower; either case on input",
    "ms",
    "1970-01-01T00:00:00Z",
    "",
    no_form,
    scru128_parse,
    scru128_strict,
    scru128_format,
    scru128_fields,
};

/* ---- SCRU64 -------------------------------------------------------------- */

/* 36^12 - 1, the largest 12-digit base36 value, and its timestamp, which
 * is reserved along with 0. 36^12 is 2^24 * 3^24, so the division is exact. */
#define SCRU64_MAX UINT64_C(4738381338321616895)
#define SCRU64_MAX_TS (SCRU64_MAX >> 24)

static int base36_digit(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'z') return c - 'a' + 10;
    if (c >= 'A' && c <= 'Z') return c - 'A' + 10;
    return -1;
}

static zuid_level scru64_parse(const char *s, size_t len, int form,
                               uint8_t *out, zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    if (len != 12) return ZUID_LEVEL_NONE;
    uint64_t v = 0;
    for (size_t i = 0; i < 12; i++) {
        int d = base36_digit(s[i]);
        if (d < 0) return ZUID_LEVEL_NONE;
        v = v * 36 + (uint64_t) d; /* 36^12 - 1 < 2^63: no overflow */
    }
    for (int i = 0; i < 8; i++) out[i] = (uint8_t) (v >> (56 - 8 * i));
    uint64_t ts = v >> 24;
    return ts == 0 || ts == SCRU64_MAX_TS ? ZUID_LEVEL_SYNTAX
                                          : ZUID_LEVEL_STRUCTURE;
}

static int scru64_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return (double) ((load_be(b, 8) >> 24) << 8) <= now_ms + tolerance_ms;
}

static size_t scru64_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                            char *out)
{
    (void) form;
    (void) pfx;
    static const char digits[] = "0123456789abcdefghijklmnopqrstuvwxyz";
    uint64_t v = load_be(b, 8);
    for (int i = 11; i >= 0; i--) {
        out[i] = digits[v % 36];
        v /= 36;
    }
    return 12;
}

/* The node and counter split needs a layout (node_bits), so only the time
 * is read here. */
static void scru64_fields(const uint8_t *b, const zuid_prefix *pfx,
                          zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    set_time_ms(f, (load_be(b, 8) >> 24) << 8, "256ms");
}

const zuid_format zuid_fmt_scru64 = {
    "scru64",
    ZUID_CLASS_STRUCTURED,
    8,
    12, 12,
    "0-9a-z",
    "lower; either case on input",
    "256ms",
    "1970-01-01T00:00:00Z",
    "",
    no_form,
    scru64_parse,
    scru64_strict,
    scru64_format,
    scru64_fields,
};

/* ---- KSUID --------------------------------------------------------------- */

#define KSUID_EPOCH INT64_C(1400000000)

/* 27 base62 digits, case-sensitive, at most aWgEPTl1tmebfsQzFP4bxwgy80V. */
static zuid_level ksuid_parse(const char *s, size_t len, int form, uint8_t *out,
                              zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    return len == 27 &&
                   zuid_decode(ZUID_ENC_BASE62, s, len, NULL, 20, out) == 20
               ? ZUID_LEVEL_STRUCTURE
               : ZUID_LEVEL_NONE;
}

static double ksuid_ms(const uint8_t *b)
{
    return ((double) load_be(b, 4) + (double) KSUID_EPOCH) * 1000.0;
}

static int ksuid_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return ksuid_ms(b) <= now_ms + tolerance_ms;
}

static size_t ksuid_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                           char *out)
{
    (void) form;
    (void) pfx;
    return encoded_text(ZUID_ENC_BASE62, b, 20, out);
}

static void ksuid_fields(const uint8_t *b, const zuid_prefix *pfx,
                         zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    f->has_time = 1;
    f->time_s = (int64_t) load_be(b, 4) + KSUID_EPOCH;
    f->time_frac_ns = 0;
    f->time_unit = "s";
    zuid_bits_hex(b, 32, 128, f->random);
}

const zuid_format zuid_fmt_ksuid = {
    "ksuid",
    ZUID_CLASS_STRUCTURED,
    20,
    27, 27,
    "0-9A-Za-z",
    "case-sensitive",
    "s",
    "2014-05-13T16:53:20Z",
    "",
    no_form,
    ksuid_parse,
    ksuid_strict,
    ksuid_format,
    ksuid_fields,
};
