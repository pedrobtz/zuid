/* Encoding dispatch and the fixed alphabets (design.md section 6.5). Each
 * form follows what the mainstream Go and Python libraries emit (section
 * 15 Q2, settled 2026-10-24); tests/testthat/fixtures/encodings.csv holds
 * their output. */

#include "zuid_enc.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

static const char *const names[ZUID_ENC_N] = {
    "hex",       "base32",    "base32rfc",  "base32hex", "base36",
    "base58",    "base62",    "base62sort", "base64url", "base64sort",
    "alphabet",  "proquint",  "words"};

static const char HEX[] = "0123456789abcdef";
static const char CROCKFORD[] = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
static const char RFC32[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
static const char RFC32HEX[] = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
static const char B36[] = "0123456789abcdefghijklmnopqrstuvwxyz";
static const char B58[] =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
static const char B62[] =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
static const char B64URL[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
static const char B64SORT[] =
    "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
const char zuid_shortuuid_alphabet[] =
    "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

int zuid_enc_find(const char *name)
{
    for (int i = 0; i < ZUID_ENC_N; i++) {
        if (strcmp(name, names[i]) == 0) return i;
    }
    return -1;
}

const char *zuid_enc_name(int form)
{
    return form >= 0 && form < ZUID_ENC_N ? names[form] : NULL;
}

int zuid_alphabet_init(zuid_alphabet *a, const char *symbols, size_t n)
{
    if (n < 2 || n > 94) return -1;
    memset(a->index, 0xff, sizeof a->index);
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char) symbols[i];
        if (c <= 0x20 || c >= 0x7f || a->index[c] != 0xff) return -1;
        a->index[c] = (uint8_t) i;
        a->symbols[i] = (char) c;
    }
    a->symbols[n] = '\0';
    a->base = (int) n;
    return 0;
}

/* The alphabets of the fixed forms, built once. Folded forms also index the
 * other case of each letter, so input is case-insensitive. */
typedef struct {
    int ready;
    zuid_alphabet a[ZUID_ENC_N];
} fixed_alphabets;

static void fold(zuid_alphabet *a)
{
    for (int i = 0; i < a->base; i++) {
        unsigned char c = (unsigned char) a->symbols[i];
        if (c >= 'a' && c <= 'z') a->index[c - 'a' + 'A'] = (uint8_t) i;
        if (c >= 'A' && c <= 'Z') a->index[c - 'A' + 'a'] = (uint8_t) i;
    }
}

static const zuid_alphabet *fixed(int form)
{
    static fixed_alphabets t;
    if (!t.ready) {
        static const struct {
            int form;
            const char *symbols;
            int folded;
        } spec[] = {{ZUID_ENC_HEX, HEX, 1},
                    {ZUID_ENC_BASE32, CROCKFORD, 1},
                    {ZUID_ENC_BASE32RFC, RFC32, 1},
                    {ZUID_ENC_BASE32HEX, RFC32HEX, 1},
                    {ZUID_ENC_BASE36, B36, 1},
                    {ZUID_ENC_BASE58, B58, 0},
                    {ZUID_ENC_BASE62, B62, 0},
                    {ZUID_ENC_BASE62SORT, B62, 0},
                    {ZUID_ENC_BASE64URL, B64URL, 0},
                    {ZUID_ENC_BASE64SORT, B64SORT, 0},
                    {ZUID_ENC_ALPHABET, zuid_shortuuid_alphabet, 0}};
        for (size_t i = 0; i < sizeof spec / sizeof spec[0]; i++) {
            zuid_alphabet *a = &t.a[spec[i].form];
            zuid_alphabet_init(a, spec[i].symbols, strlen(spec[i].symbols));
            if (spec[i].folded) fold(a);
        }
        t.ready = 1;
    }
    return &t.a[form];
}

/* Bits per symbol of the power-of-two forms, 0 for the others. */
static int form_bits(int form)
{
    switch (form) {
    case ZUID_ENC_HEX: return 4;
    case ZUID_ENC_BASE32:
    case ZUID_ENC_BASE32RFC:
    case ZUID_ENC_BASE32HEX: return 5;
    case ZUID_ENC_BASE64URL:
    case ZUID_ENC_BASE64SORT: return 6;
    default: return 0;
    }
}

size_t zuid_enc_max_len(int form, size_t n, const zuid_alphabet *a,
                        size_t sep_len)
{
    int bits = form_bits(form);
    if (bits) return (8 * n + (size_t) bits - 1) / (size_t) bits;
    switch (form) {
    case ZUID_ENC_PROQUINT: return n / 2 * (5 + sep_len);
    case ZUID_ENC_WORDS: return n / 2 * (28 + sep_len);
    case ZUID_ENC_ALPHABET:
        return zuid_radix_width(n, a ? a->base : 57) + n + 2;
    default: return zuid_radix_width(n, fixed(form)->base) + n + 2;
    }
}

size_t zuid_dec_max_len(size_t len)
{
    return len + 8;
}

long zuid_encode(int form, const uint8_t *in, size_t n, const zuid_alphabet *a,
                 const char *sep, size_t sep_len, char *out)
{
    switch (form) {
    case ZUID_ENC_HEX:
    case ZUID_ENC_BASE32RFC:
    case ZUID_ENC_BASE32HEX:
    case ZUID_ENC_BASE64URL:
    case ZUID_ENC_BASE64SORT:
        return zuid_enc_bits(in, n, form_bits(form), 0, fixed(form)->symbols,
                             out);
    case ZUID_ENC_BASE32:
        return zuid_enc_bits(in, n, 5, 1, CROCKFORD, out);
    case ZUID_ENC_BASE58:
        return zuid_enc_radix(in, n, fixed(form), 1, out);
    case ZUID_ENC_BASE36:
    case ZUID_ENC_BASE62:
    case ZUID_ENC_BASE62SORT:
        return zuid_enc_radix(in, n, fixed(form), 0, out);
    case ZUID_ENC_ALPHABET:
        return zuid_enc_radix(in, n, a ? a : fixed(form), 0, out);
    case ZUID_ENC_PROQUINT:
        return zuid_enc_proquint(in, n, sep, sep_len, out);
    case ZUID_ENC_WORDS:
        return zuid_enc_words(in, n, sep, sep_len, out);
    default:
        return ZUID_ENC_INVALID;
    }
}

/* Strips the RFC 4648 padding of a form that allows it: '=' up to a whole
 * block, and only the count that block needs. Returns the length without
 * it, or -1 when the padding is wrong. */
static long strip_padding(const char *s, size_t len, int bits)
{
    size_t block = bits == 5 ? 8 : 4, pad = 0;
    while (pad < len && s[len - 1 - pad] == '=') pad++;
    if (pad == 0) return (long) len;
    size_t body = len - pad;
    if (len % block != 0 || pad >= block) return -1;
    /* The body must be the unpadded length of some byte count, which the
     * decoder checks, and the padding must complete exactly its block. */
    if ((body + block - 1) / block * block != len) return -1;
    return (long) body;
}

long zuid_decode(int form, const char *s, size_t len, const zuid_alphabet *a,
                 long width, uint8_t *out)
{
    switch (form) {
    case ZUID_ENC_HEX: {
        /* Hyphens anywhere are ignored, so a UUID's hex form decodes. */
        char stack[256];
        char *tmp = len <= sizeof stack ? stack : (char *) malloc(len);
        size_t m = 0;
        if (!tmp) return ZUID_ENC_NOMEM;
        for (size_t i = 0; i < len; i++) {
            if (s[i] != '-') tmp[m++] = s[i];
        }
        long r = zuid_dec_bits(tmp, m, 4, 0, fixed(form)->index, width, out);
        if (tmp != stack) free(tmp);
        return r;
    }
    case ZUID_ENC_BASE32RFC:
    case ZUID_ENC_BASE32HEX:
    case ZUID_ENC_BASE64URL: {
        long body = strip_padding(s, len, form_bits(form));
        if (body < 0) return ZUID_ENC_INVALID;
        return zuid_dec_bits(s, (size_t) body, form_bits(form), 0,
                             fixed(form)->index, width, out);
    }
    case ZUID_ENC_BASE64SORT:
        return zuid_dec_bits(s, len, 6, 0, fixed(form)->index, width, out);
    case ZUID_ENC_BASE32:
        return zuid_dec_bits(s, len, 5, 1, fixed(form)->index, width, out);
    case ZUID_ENC_BASE58:
        return zuid_dec_radix(s, len, fixed(form), 1, width, out);
    case ZUID_ENC_BASE36:
    case ZUID_ENC_BASE62:
    case ZUID_ENC_BASE62SORT:
        return zuid_dec_radix(s, len, fixed(form), 0, width, out);
    case ZUID_ENC_ALPHABET:
        return zuid_dec_radix(s, len, a ? a : fixed(form), 0, width, out);
    case ZUID_ENC_PROQUINT: {
        long r = zuid_dec_proquint(s, len, out);
        return r >= 0 && width >= 0 && r != width ? ZUID_ENC_INVALID : r;
    }
    case ZUID_ENC_WORDS: {
        long r = zuid_dec_words(s, len, out);
        return r >= 0 && width >= 0 && r != width ? ZUID_ENC_INVALID : r;
    }
    default:
        return ZUID_ENC_INVALID;
    }
}

size_t zuid_radix_width(size_t n, int base)
{
    if (n == 0) return 0;
    int bits = 0;
    while ((1 << bits) < base) bits++;
    if ((1 << bits) == base) return (8 * n + (size_t) bits - 1) / (size_t) bits;
    /* log2 of a base that is not a power of two is irrational, so the
     * quotient is never a whole number and ceil() is exact. */
    return (size_t) ceil((double) (8 * n) / log2((double) base));
}
