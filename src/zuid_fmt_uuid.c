/* UUIDs, RFC 9562 (design.md sections 6.1, 6.3 to 6.5). */

#include "zuid_formats.h"
#include "zuid_enc.h"

#include <string.h>

enum { FORM_HEX, FORM_COMPACT, FORM_URN, FORM_BRACED, FORM_UPPERCASE,
       FORM_ENC_FIRST };

/* The encodings of section 6.5 are forms too: form FORM_ENC_FIRST + i is
 * uuid_encodings[i] over the 16 bytes. Proquint and words use '-'. */
static const int uuid_encodings[] = {
    ZUID_ENC_BASE32,     ZUID_ENC_BASE32RFC, ZUID_ENC_BASE32HEX,
    ZUID_ENC_BASE36,     ZUID_ENC_BASE58,    ZUID_ENC_BASE62,
    ZUID_ENC_BASE62SORT, ZUID_ENC_BASE64URL, ZUID_ENC_BASE64SORT,
    ZUID_ENC_ALPHABET,   ZUID_ENC_PROQUINT,  ZUID_ENC_WORDS};
#define N_ENCODINGS ((int) (sizeof uuid_encodings / sizeof uuid_encodings[0]))

/* 100 ns ticks between the Gregorian epoch, 1582-10-15, and 1970-01-01. */
#define GREGORIAN_OFFSET INT64_C(0x01B21DD213814000)

static int uuid_form_index(const char *form)
{
    static const char *const names[] = {"hex", "compact", "urn", "braced",
                                        "uppercase"};
    for (int i = 0; i < 5; i++) {
        if (strcmp(form, names[i]) == 0) {
            return i;
        }
    }
    for (int i = 0; i < N_ENCODINGS; i++) {
        if (strcmp(form, zuid_enc_name(uuid_encodings[i])) == 0) {
            return FORM_ENC_FIRST + i;
        }
    }
    return -2; /* unknown */
}

static int hex_value(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* 32 hex digits, with hyphens at 8, 13, 18 and 23 when `hyphens`. */
static int parse_digits(const char *s, int hyphens, uint8_t *out)
{
    int pos = 0;
    for (int i = 0; i < 16; i++) {
        if (hyphens && (i == 4 || i == 6 || i == 8 || i == 10)) {
            if (s[pos++] != '-') return 0;
        }
        int hi = hex_value(s[pos++]);
        int lo = hex_value(s[pos++]);
        if (hi < 0 || lo < 0) return 0;
        out[i] = (uint8_t) (hi << 4 | lo);
    }
    return 1;
}

static int is_all(const uint8_t *b, uint8_t v)
{
    for (int i = 0; i < 16; i++) {
        if (b[i] != v) return 0;
    }
    return 1;
}

static int is_special(const uint8_t *b)
{
    return is_all(b, 0x00) || is_all(b, 0xff);
}

static int has_rfc_variant(const uint8_t *b)
{
    return (b[8] & 0xc0) == 0x80;
}

static int ascii_ieq(const char *s, const char *lower, size_t n)
{
    for (size_t i = 0; i < n; i++) {
        char c = s[i];
        if (c >= 'A' && c <= 'Z') c = (char) (c - 'A' + 'a');
        if (c != lower[i]) return 0;
    }
    return 1;
}

static zuid_level uuid_parse(const char *s, size_t len, int form, uint8_t *out,
                             zuid_prefix *pfx)
{
    pfx->len = 0;
    int ok;
    uint8_t buf[ZUID_TEXT_BUF + 8];
    switch (form) {
    case -1:
    case FORM_HEX:
    case FORM_UPPERCASE: /* RFC 9562 accepts either case */
        ok = len == 36 && parse_digits(s, 1, out);
        break;
    case FORM_COMPACT:
        ok = len == 32 && parse_digits(s, 0, out);
        break;
    case FORM_URN:
        ok = len == 45 && ascii_ieq(s, "urn:uuid:", 9) &&
             parse_digits(s + 9, 1, out);
        break;
    case FORM_BRACED:
        ok = len == 38 && s[0] == '{' && s[37] == '}' &&
             parse_digits(s + 1, 1, out);
        break;
    default: /* an encoding of the 16 bytes */
        ok = len <= ZUID_TEXT_BUF &&
             zuid_decode(uuid_encodings[form - FORM_ENC_FIRST], s, len, NULL,
                         16, buf) == 16;
        if (ok) memcpy(out, buf, 16);
        break;
    }
    if (!ok) return ZUID_LEVEL_NONE;
    if (!is_special(out) && !has_rfc_variant(out)) return ZUID_LEVEL_SYNTAX;
    return ZUID_LEVEL_STRUCTURE;
}

static uint64_t load_be(const uint8_t *b, int n)
{
    uint64_t v = 0;
    for (int i = 0; i < n; i++) v = v << 8 | b[i];
    return v;
}

static int uuid_version(const uint8_t *b)
{
    return b[6] >> 4;
}

/* The 60-bit timestamp of a version 1 or 6, in 100 ns ticks since 1582. */
static uint64_t gregorian_ticks(const uint8_t *b)
{
    uint64_t hi12 = load_be(b + 6, 2) & 0x0fff;
    if (uuid_version(b) == 1) {
        uint64_t low = load_be(b, 4), mid = load_be(b + 4, 2);
        return hi12 << 48 | mid << 32 | low;
    }
    uint64_t high = load_be(b, 4), mid = load_be(b + 4, 2);
    return high << 28 | mid << 12 | hi12;
}

static int64_t floor_div(int64_t a, int64_t b)
{
    int64_t q = a / b;
    return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q;
}

static void set_time_ticks(zuid_fields *f, uint64_t ticks)
{
    int64_t d = (int64_t) ticks - GREGORIAN_OFFSET;
    f->has_time = 1;
    f->time_s = floor_div(d, 10000000);
    f->time_frac_ns = (int32_t) ((d - f->time_s * 10000000) * 100);
    f->time_unit = "100ns";
}

static void set_time_ms(zuid_fields *f, uint64_t ms)
{
    f->has_time = 1;
    f->time_s = (int64_t) (ms / 1000);
    f->time_frac_ns = (int32_t) (ms % 1000) * 1000000;
    f->time_unit = "ms";
}

static void uuid_fields(const uint8_t *b, const zuid_prefix *pfx,
                        zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    if (is_all(b, 0x00) || is_all(b, 0xff)) {
        f->version = b[0] == 0 ? 0 : 15;
        return;
    }
    switch (b[8] >> 5) {
    case 0: case 1: case 2: case 3: f->variant = "ncs"; break;
    case 4: case 5: f->variant = "rfc"; break;
    case 6: f->variant = "microsoft"; break;
    default: f->variant = "future"; break;
    }
    if (!has_rfc_variant(b)) return; /* the version field is the RFC's */

    zuid_bitbuf random;
    random.n = 0;
    f->version = uuid_version(b);
    switch (f->version) {
    case 1:
    case 6:
        set_time_ticks(f, gregorian_ticks(b));
        f->sequence = (int) (load_be(b + 8, 2) & 0x3fff);
        zuid_bits_hex(b, 80, 48, f->node);
        break;
    case 4:
        zuid_bitbuf_add(&random, b, 0, 48);
        zuid_bitbuf_add(&random, b, 52, 12);
        zuid_bitbuf_add(&random, b, 66, 62);
        zuid_bitbuf_hex(&random, f->random);
        break;
    case 7:
        set_time_ms(f, load_be(b, 6));
        zuid_bitbuf_add(&random, b, 52, 12);
        zuid_bitbuf_add(&random, b, 66, 62);
        zuid_bitbuf_hex(&random, f->random);
        break;
    default: /* 2, 3, 5, 8 and unassigned: no fields beyond the version */
        break;
    }
}

static int uuid_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    if (is_special(b)) return 1;
    int v = uuid_version(b);
    if (v < 1 || v > 8) return 0;
    if (v == 1 || v == 6 || v == 7) {
        zuid_fields f;
        uuid_fields(b, NULL, &f);
        double ms = (double) f.time_s * 1000.0 + f.time_frac_ns / 1e6;
        if (ms > now_ms + tolerance_ms) return 0;
    }
    return 1;
}

static size_t write_digits(const uint8_t *b, int hyphens, int upper, char *out)
{
    const char *digits = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    size_t pos = 0;
    for (int i = 0; i < 16; i++) {
        if (hyphens && (i == 4 || i == 6 || i == 8 || i == 10)) {
            out[pos++] = '-';
        }
        out[pos++] = digits[b[i] >> 4];
        out[pos++] = digits[b[i] & 0x0f];
    }
    return pos;
}

static size_t uuid_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                          char *out)
{
    (void) pfx;
    if (form >= FORM_ENC_FIRST) {
        long m = zuid_encode(uuid_encodings[form - FORM_ENC_FIRST], b, 16, NULL,
                             "-", 1, out);
        return m > 0 ? (size_t) m : 0;
    }
    switch (form) {
    case FORM_COMPACT:
        return write_digits(b, 0, 0, out);
    case FORM_URN:
        memcpy(out, "urn:uuid:", 9);
        return 9 + write_digits(b, 1, 0, out + 9);
    case FORM_BRACED:
        out[0] = '{';
        write_digits(b, 1, 0, out + 1);
        out[37] = '}';
        return 38;
    case FORM_UPPERCASE:
        return write_digits(b, 1, 1, out);
    default:
        return write_digits(b, 1, 0, out);
    }
}

const zuid_format zuid_fmt_uuid = {
    "uuid",
    ZUID_CLASS_STRUCTURED,
    16,
    36, 36,
    "0-9a-f",
    "lower; either case on input",
    "100ns (versions 1, 6), ms (version 7)",
    "1582-10-15T00:00:00Z (versions 1, 6), 1970-01-01T00:00:00Z (version 7)",
    "hex,compact,urn,braced,uppercase,base32,base32rfc,base32hex,base36,"
    "base58,base62,base62sort,base64url,base64sort,alphabet,proquint,words",
    uuid_form_index,
    uuid_parse,
    uuid_strict,
    uuid_format,
    uuid_fields,
};
