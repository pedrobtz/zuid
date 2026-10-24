/* ULID (ulid/spec) and TypeID (jetify-com/typeid, spec 0.3.0): 128 bits in
 * 26 Crockford base32 characters (design.md sections 6.1 and 6.3). */

#include "zuid_formats.h"
#include "zuid_enc.h"

#include <string.h>

#define CROCKFORD_LEN 26

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

/* 26 Crockford characters for 16 bytes. A first character above 7 does not
 * fit 128 bits and is not text of the format, since it has no bytes. */
static int crockford_bytes(const char *s, size_t len, uint8_t *out)
{
    return len == CROCKFORD_LEN &&
           zuid_decode(ZUID_ENC_BASE32, s, len, NULL, 16, out) == 16;
}

static size_t crockford_text(const uint8_t *b, int lower, char *out)
{
    long m = zuid_encode(ZUID_ENC_BASE32, b, 16, NULL, "", 0, out);
    if (lower) {
        for (long i = 0; i < m; i++) {
            if (out[i] >= 'A' && out[i] <= 'Z') out[i] = (char) (out[i] + 32);
        }
    }
    return (size_t) m;
}

/* ---- ULID ---------------------------------------------------------------- */

static zuid_level ulid_parse(const char *s, size_t len, int form, uint8_t *out,
                             zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    return crockford_bytes(s, len, out) ? ZUID_LEVEL_STRUCTURE
                                        : ZUID_LEVEL_NONE;
}

static int ulid_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return (double) load_be(b, 6) <= now_ms + tolerance_ms;
}

static size_t ulid_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                          char *out)
{
    (void) form;
    (void) pfx;
    return crockford_text(b, 0, out);
}

static void ulid_fields(const uint8_t *b, const zuid_prefix *pfx,
                        zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    uint64_t ms = load_be(b, 6);
    f->has_time = 1;
    f->time_s = (int64_t) (ms / 1000);
    f->time_frac_ns = (int32_t) (ms % 1000) * 1000000;
    f->time_unit = "ms";
    zuid_bits_hex(b, 48, 80, f->random);
}

const zuid_format zuid_fmt_ulid = {
    "ulid",
    ZUID_CLASS_STRUCTURED,
    16,
    26, 26,
    "0-9A-HJKMNP-TV-Z (Crockford)",
    "upper; either case on input",
    "ms",
    "1970-01-01T00:00:00Z",
    "",
    no_form,
    ulid_parse,
    ulid_strict,
    ulid_format,
    ulid_fields,
};

/* ---- TypeID -------------------------------------------------------------- */

/* ^([a-z]([a-z_]{0,61}[a-z])?)?$, the spec's prefix grammar. */
static int typeid_prefix_ok(const char *p, size_t n)
{
    if (n > ZUID_PREFIX_MAX) return 0;
    for (size_t i = 0; i < n; i++) {
        char c = p[i];
        int letter = c >= 'a' && c <= 'z';
        int edge = i == 0 || i == n - 1;
        if (!letter && (edge || c != '_')) return 0;
    }
    return 1;
}

static zuid_level typeid_parse(const char *s, size_t len, int form,
                               uint8_t *out, zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    const char *sep = NULL;
    for (size_t i = len; i > 0; i--) {
        if (s[i - 1] == '_') {
            sep = s + i - 1;
            break;
        }
    }
    size_t plen = sep ? (size_t) (sep - s) : 0;
    const char *suffix = sep ? sep + 1 : s;
    size_t slen = len - (size_t) (suffix - s);
    /* An empty prefix has no separator. */
    if (sep && plen == 0) return ZUID_LEVEL_NONE;
    if (!typeid_prefix_ok(s, plen)) return ZUID_LEVEL_NONE;
    /* The suffix is lowercase. */
    for (size_t i = 0; i < slen; i++) {
        if (suffix[i] >= 'A' && suffix[i] <= 'Z') return ZUID_LEVEL_NONE;
    }
    if (!crockford_bytes(suffix, slen, out)) return ZUID_LEVEL_NONE;
    memcpy(pfx->s, s, plen);
    pfx->s[plen] = '\0';
    pfx->len = plen;
    return ZUID_LEVEL_STRUCTURE;
}

/* Strict is the UUID's: a version RFC 9562 defines and no future time. */
static int typeid_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return zuid_fmt_uuid.strict(b, now_ms, tolerance_ms);
}

static size_t typeid_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                            char *out)
{
    (void) form;
    size_t m = 0;
    if (pfx && pfx->len > 0) {
        memcpy(out, pfx->s, pfx->len);
        m = pfx->len;
        out[m++] = '_';
    }
    return m + crockford_text(b, 1, out + m);
}

static void typeid_fields(const uint8_t *b, const zuid_prefix *pfx,
                          zuid_fields *f)
{
    zuid_fmt_uuid.fields(b, NULL, f);
    f->has_prefix = 1;
    size_t n = pfx ? pfx->len : 0;
    if (n) memcpy(f->prefix, pfx->s, n);
    f->prefix[n] = '\0';
}

const zuid_format zuid_fmt_typeid = {
    "typeid",
    ZUID_CLASS_STRUCTURED,
    16,
    26, 90,
    "prefix a-z_, suffix 0-9a-hjkmnp-tv-z (Crockford)",
    "lower",
    "as the UUID",
    "as the UUID",
    "",
    no_form,
    typeid_parse,
    typeid_strict,
    typeid_format,
    typeid_fields,
};
