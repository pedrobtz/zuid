/* The power-of-two forms: hex, Crockford base32, RFC 4648 base32 and
 * base32hex, base64url and base64sort (design.md section 6.5).
 *
 * Bits are sliced most significant first. `lead` puts the spare bits in
 * front, as zero bits, which is what ULID, TypeID and every Go and Python
 * Crockford library do, so a 16-byte value starts with 0 to 7. Without it
 * the spare bits go at the end, as RFC 4648 says, and Go's and Python's
 * base32 and base64 do. */

#include "zuid_enc.h"

/* Symbols for `n` bytes, and the byte count a length holds, or -1. */
static size_t enc_len(size_t n, int bits)
{
    return (8 * n + (size_t) bits - 1) / (size_t) bits;
}

static long dec_count(size_t len, int bits)
{
    size_t n = len * (size_t) bits / 8;
    return enc_len(n, bits) == len ? (long) n : -1;
}

long zuid_enc_bits(const uint8_t *in, size_t n, int bits, int lead,
                   const char *symbols, char *out)
{
    size_t len = enc_len(n, bits);
    unsigned mask = (1u << bits) - 1;
    /* Bits pending in `acc`, at most bits - 1 + 8 of them. */
    uint32_t acc = 0;
    int pending = lead ? (int) (len * (size_t) bits - 8 * n) : 0;
    size_t m = 0;
    for (size_t i = 0; i < n; i++) {
        acc = acc << 8 | in[i];
        pending += 8;
        while (pending >= bits) {
            pending -= bits;
            out[m++] = symbols[(acc >> pending) & mask];
        }
        acc &= (1u << pending) - 1;
    }
    if (pending > 0) out[m++] = symbols[(acc << (bits - pending)) & mask];
    return (long) m;
}

long zuid_dec_bits(const char *s, size_t len, int bits, int lead,
                   const uint8_t *index, long width, uint8_t *out)
{
    long n = dec_count(len, bits);
    if (n < 0 || (width >= 0 && n != width)) return ZUID_ENC_INVALID;
    int spare = (int) (len * (size_t) bits - 8 * (size_t) n);
    /* With `lead` the spare bits are the first ones read; else the last. */
    int skip = lead ? spare : 0;
    uint32_t acc = 0;
    int pending = 0;
    size_t m = 0;
    for (size_t i = 0; i < len; i++) {
        uint8_t v = index[(unsigned char) s[i]];
        if (v == 0xff) return ZUID_ENC_INVALID;
        acc = acc << bits | v;
        pending += bits;
        if (skip) {
            /* A value too large for the byte count: Crockford's first
             * symbol above 7 for 16 bytes. */
            if (acc >> (pending - skip)) return ZUID_ENC_INVALID;
            pending -= skip;
            skip = 0;
        }
        if (pending >= 8) {
            pending -= 8;
            out[m++] = (uint8_t) (acc >> pending);
        }
        acc &= (1u << pending) - 1;
    }
    /* Trailing spare bits must be zero, so that each byte string has one
     * text, as Go's strict decoders require. */
    if (pending > 0 && acc != 0) return ZUID_ENC_INVALID;
    return (long) m;
}
