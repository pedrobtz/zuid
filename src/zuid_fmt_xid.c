/* XID (rs/xid), ObjectId (the BSON ObjectId specification) and Snowflake
 * (design.md sections 6.1 and 6.8). XID and ObjectId share their 12-byte
 * layout: seconds, five middle bytes and a counter. A Snowflake is a 64-bit
 * integer in decimal; its fields need a layout, which the R side applies. */

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

static int seconds_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return (double) load_be(b, 4) * 1000.0 <= now_ms + tolerance_ms;
}

static void set_seconds(zuid_fields *f, const uint8_t *b)
{
    f->has_time = 1;
    f->time_s = (int64_t) load_be(b, 4);
    f->time_frac_ns = 0;
    f->time_unit = "s";
}

static int has_upper(const char *s, size_t len)
{
    for (size_t i = 0; i < len; i++) {
        if (s[i] >= 'A' && s[i] <= 'Z') return 1;
    }
    return 0;
}

static size_t lower_encoding(int enc, const uint8_t *b, size_t n, char *out)
{
    long m = zuid_encode(enc, b, n, NULL, "", 0, out);
    for (long i = 0; i < m; i++) {
        if (out[i] >= 'A' && out[i] <= 'Z') out[i] = (char) (out[i] + 32);
    }
    return m > 0 ? (size_t) m : 0;
}

/* ---- XID ----------------------------------------------------------------- */

/* 20 lowercase base32hex characters; the last one's 4 spare bits are zero,
 * as rs/xid checks. */
static zuid_level xid_parse(const char *s, size_t len, int form, uint8_t *out,
                            zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    return len == 20 && !has_upper(s, len) &&
                   zuid_decode(ZUID_ENC_BASE32HEX, s, len, NULL, 12, out) == 12
               ? ZUID_LEVEL_STRUCTURE
               : ZUID_LEVEL_NONE;
}

static size_t xid_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                         char *out)
{
    (void) form;
    (void) pfx;
    return lower_encoding(ZUID_ENC_BASE32HEX, b, 12, out);
}

static void xid_fields(const uint8_t *b, const zuid_prefix *pfx,
                       zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    set_seconds(f, b);
    zuid_bits_hex(b, 32, 24, f->node);
    f->process = (int) load_be(b + 7, 2);
    f->sequence = (int) load_be(b + 9, 3);
}

const zuid_format zuid_fmt_xid = {
    "xid",
    ZUID_CLASS_STRUCTURED,
    12,
    20, 20,
    "0-9a-v (base32hex)",
    "lower",
    "s",
    "1970-01-01T00:00:00Z",
    "",
    no_form,
    xid_parse,
    seconds_strict,
    xid_format,
    xid_fields,
};

/* ---- ObjectId ------------------------------------------------------------ */

static zuid_level objectid_parse(const char *s, size_t len, int form,
                                 uint8_t *out, zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    if (len != 24 || memchr(s, '-', len)) return ZUID_LEVEL_NONE;
    return zuid_decode(ZUID_ENC_HEX, s, len, NULL, 12, out) == 12
               ? ZUID_LEVEL_STRUCTURE
               : ZUID_LEVEL_NONE;
}

static size_t objectid_format(const uint8_t *b, int form,
                              const zuid_prefix *pfx, char *out)
{
    (void) form;
    (void) pfx;
    return lower_encoding(ZUID_ENC_HEX, b, 12, out);
}

/* The middle five bytes are random in the current specification, so they
 * are `random`, never `node` (design.md 6.1). */
static void objectid_fields(const uint8_t *b, const zuid_prefix *pfx,
                            zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    set_seconds(f, b);
    zuid_bits_hex(b, 32, 40, f->random);
    f->sequence = (int) load_be(b + 9, 3);
}

const zuid_format zuid_fmt_objectid = {
    "objectid",
    ZUID_CLASS_STRUCTURED,
    12,
    24, 24,
    "0-9a-f",
    "lower; either case on input",
    "s",
    "1970-01-01T00:00:00Z",
    "",
    no_form,
    objectid_parse,
    seconds_strict,
    objectid_format,
    objectid_fields,
};

/* ---- Snowflake ----------------------------------------------------------- */

/* 1 to 20 decimal digits without leading zeros, at most 2^64 - 1. Whether
 * the value fits the layout's sign bit is the layout's check (R side). */
static zuid_level snowflake_parse(const char *s, size_t len, int form,
                                  uint8_t *out, zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    if (len < 1 || len > 20 || (len > 1 && s[0] == '0')) {
        return ZUID_LEVEL_NONE;
    }
    uint64_t v = 0;
    for (size_t i = 0; i < len; i++) {
        if (s[i] < '0' || s[i] > '9') return ZUID_LEVEL_NONE;
        unsigned d = (unsigned) (s[i] - '0');
        if (v > (UINT64_MAX - d) / 10) return ZUID_LEVEL_NONE;
        v = v * 10 + d;
    }
    for (int i = 0; i < 8; i++) out[i] = (uint8_t) (v >> (56 - 8 * i));
    return ZUID_LEVEL_STRUCTURE;
}

static int snowflake_strict(const uint8_t *b, double now_ms,
                            double tolerance_ms)
{
    (void) b;
    (void) now_ms;
    (void) tolerance_ms;
    return 1;
}

static size_t snowflake_format(const uint8_t *b, int form,
                               const zuid_prefix *pfx, char *out)
{
    (void) form;
    (void) pfx;
    char digits[20];
    uint64_t v = load_be(b, 8);
    int n = 0;
    do {
        digits[n++] = (char) ('0' + v % 10);
        v /= 10;
    } while (v);
    for (int i = 0; i < n; i++) out[i] = digits[n - 1 - i];
    return (size_t) n;
}

static void snowflake_fields(const uint8_t *b, const zuid_prefix *pfx,
                             zuid_fields *f)
{
    (void) b;
    (void) pfx;
    zuid_fields_clear(f);
}

const zuid_format zuid_fmt_snowflake = {
    "snowflake",
    ZUID_CLASS_STRUCTURED,
    8,
    1, 20,
    "0-9",
    "decimal, no leading zeros",
    "the layout's",
    "the layout's",
    "",
    no_form,
    snowflake_parse,
    snowflake_strict,
    snowflake_format,
    snowflake_fields,
};
