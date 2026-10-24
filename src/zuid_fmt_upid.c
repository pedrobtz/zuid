/* UPID (carderne/upid): 40 bits of time in 256 ms units, 64 random bits, a
 * 20-bit prefix and a 4-bit version, in that order in the bytes (design.md
 * section 6.1). The text puts the prefix first: four characters, '_', then
 * time (8 characters), random (13, the last carrying 4 bits) and version (1,
 * carrying 4 bits), in the reference's base32 alphabet. */

#include "zuid_formats.h"

#include <string.h>

static const char ALPHABET[] = "234567abcdefghijklmnopqrstuvwxyz";

/* The version nibble the reference writes, 'a'. */
#define UPID_VERSION 6

static int no_form(const char *form)
{
    (void) form;
    return -2;
}

static int digit(char c)
{
    if (c >= '2' && c <= '7') return c - '2';
    if (c >= 'a' && c <= 'z') return c - 'a' + 6;
    return -1;
}

/* Bits most significant first into or out of 16 bytes. */
typedef struct {
    uint8_t *b;
    int pos;
} bitcursor;

static void put(bitcursor *c, unsigned v, int nbits)
{
    for (int k = nbits - 1; k >= 0; k--, c->pos++) {
        if ((v >> k) & 1) c->b[c->pos / 8] |= (uint8_t) (0x80 >> (c->pos % 8));
    }
}

static unsigned get(const uint8_t *b, int pos, int nbits)
{
    unsigned v = 0;
    for (int k = 0; k < nbits; k++, pos++) {
        v = v << 1 | ((b[pos / 8] >> (7 - pos % 8)) & 1);
    }
    return v;
}

/* The text characters in order with the bits each carries, and where those
 * bits sit in the bytes. */
static const struct {
    int text, nbits, bit;
} layout[] = {
    /* prefix, text 0-3, bits 104-123 */
    {0, 5, 104}, {1, 5, 109}, {2, 5, 114}, {3, 5, 119},
    /* time, text 5-12, bits 0-39 */
    {5, 5, 0}, {6, 5, 5}, {7, 5, 10}, {8, 5, 15},
    {9, 5, 20}, {10, 5, 25}, {11, 5, 30}, {12, 5, 35},
    /* random, text 13-25, bits 40-103 */
    {13, 5, 40}, {14, 5, 45}, {15, 5, 50}, {16, 5, 55}, {17, 5, 60},
    {18, 5, 65}, {19, 5, 70}, {20, 5, 75}, {21, 5, 80}, {22, 5, 85},
    {23, 5, 90}, {24, 5, 95}, {25, 4, 100},
    /* version, text 26, bits 124-127 */
    {26, 4, 124},
};
#define N_CHARS ((int) (sizeof layout / sizeof layout[0]))
#define TEXT_LEN 27

static zuid_level upid_parse(const char *s, size_t len, int form, uint8_t *out,
                             zuid_prefix *pfx)
{
    (void) form;
    pfx->len = 0;
    if (len != TEXT_LEN || s[4] != '_') return ZUID_LEVEL_NONE;
    memset(out, 0, 16);
    bitcursor c = {out, 0};
    for (int i = 0; i < N_CHARS; i++) {
        int d = digit(s[layout[i].text]);
        /* A 4-bit character past 'j' would overflow 128 bits. */
        if (d < 0 || d >= (1 << layout[i].nbits)) return ZUID_LEVEL_NONE;
        c.pos = layout[i].bit;
        put(&c, (unsigned) d, layout[i].nbits);
    }
    return ZUID_LEVEL_STRUCTURE;
}

static double upid_ms(const uint8_t *b)
{
    uint64_t t = 0;
    for (int i = 0; i < 5; i++) t = t << 8 | b[i];
    return (double) (t << 8);
}

static int upid_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    return (b[15] & 0x0f) == UPID_VERSION &&
           upid_ms(b) <= now_ms + tolerance_ms;
}

static size_t upid_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                          char *out)
{
    (void) form;
    (void) pfx;
    out[4] = '_';
    for (int i = 0; i < N_CHARS; i++) {
        out[layout[i].text] = ALPHABET[get(b, layout[i].bit, layout[i].nbits)];
    }
    return TEXT_LEN;
}

static void upid_fields(const uint8_t *b, const zuid_prefix *pfx,
                        zuid_fields *f)
{
    (void) pfx;
    zuid_fields_clear(f);
    uint64_t ms = (uint64_t) upid_ms(b);
    f->has_time = 1;
    f->time_s = (int64_t) (ms / 1000);
    f->time_frac_ns = (int32_t) (ms % 1000) * 1000000;
    f->time_unit = "256ms";
    f->version = b[15] & 0x0f;
    zuid_bits_hex(b, 40, 64, f->random);
    f->has_prefix = 1;
    for (int i = 0; i < 4; i++) {
        f->prefix[i] = ALPHABET[get(b, 104 + 5 * i, 5)];
    }
    f->prefix[4] = '\0';
}

const zuid_format zuid_fmt_upid = {
    "upid",
    ZUID_CLASS_STRUCTURED,
    16,
    27, 27,
    "234567a-z",
    "lower",
    "256ms",
    "1970-01-01T00:00:00Z",
    "",
    no_form,
    upid_parse,
    upid_strict,
    upid_format,
    upid_fields,
};
