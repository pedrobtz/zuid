/* Radix forms: base36, base58, base62 and the caller's alphabet (design.md
 * section 6.5). The bytes are one big-endian integer, written most
 * significant digit first.
 *
 * Fixed width: zero-padded with the first symbol to the digits that the
 * byte count needs, as Uuid25, KSUID and ShortUUID (Go and Python) do.
 * base58btc instead writes one '1' per leading zero byte and the rest of
 * the value without padding, as Bitcoin, Go's btcutil and mr-tron and
 * Python's base58 do. Either way every byte string has exactly one text.
 *
 * The integer is held as 32-bit limbs and divided by the largest power of
 * the base that fits in 32 bits, so a 2^16-byte input stays fast. */

#include "zuid_enc.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#define STACK_LIMBS 64

/* The largest k with base^k < 2^32, and base^k. */
static int chunk(int base, uint32_t *power)
{
    uint64_t p = 1;
    int k = 0;
    while (p * (uint64_t) base <= UINT32_MAX) {
        p *= (uint64_t) base;
        k++;
    }
    *power = (uint32_t) p;
    return k;
}

/* Divides the limbs from `first` on by `d` in place; returns the remainder. */
static inline uint64_t divide(uint32_t *l, size_t first, size_t nl, uint32_t d)
{
    uint64_t rem = 0;
    for (size_t i = first; i < nl; i++) {
        uint64_t cur = rem << 32 | l[i];
        l[i] = (uint32_t) (cur / d);
        rem = cur % d;
    }
    return rem;
}

/* Writes the `ndig` least significant digits of the integer in `in` into
 * `dig`, most significant first. */
static int to_digits(const uint8_t *in, size_t n, int base, uint8_t *dig,
                     size_t ndig)
{
    uint32_t stack[STACK_LIMBS];
    size_t nl = (n + 3) / 4;
    uint32_t *l = nl <= STACK_LIMBS ? stack : (uint32_t *) malloc(nl * 4);
    if (!l) return ZUID_ENC_NOMEM;
    size_t pad = nl * 4 - n;
    memset(l, 0, nl * 4);
    for (size_t i = 0; i < n; i++) {
        size_t j = i + pad;
        l[j / 4] |= (uint32_t) in[i] << (8 * (3 - j % 4));
    }

    uint32_t power;
    int k = chunk(base, &power);
    size_t first = 0, pos = ndig;
    while (first < nl && l[first] == 0) first++;
    while (pos > 0) {
        uint64_t rem;
        /* A literal divisor lets the compiler replace the division, which
         * dominates encoding, by a multiplication. */
        switch (base) {
        case 36: rem = divide(l, first, nl, UINT32_C(2176782336)); break;
        case 57: rem = divide(l, first, nl, UINT32_C(601692057)); break;
        case 58: rem = divide(l, first, nl, UINT32_C(656356768)); break;
        case 62: rem = divide(l, first, nl, UINT32_C(916132832)); break;
        default: rem = divide(l, first, nl, power); break;
        }
        while (first < nl && l[first] == 0) first++;
        for (int j = 0; j < k && pos > 0; j++) {
            dig[--pos] = (uint8_t) (rem % (uint64_t) base);
            rem /= (uint64_t) base;
        }
        if (first == nl) {
            memset(dig, 0, pos);
            pos = 0;
        }
    }
    if (l != stack) free(l);
    return 0;
}

/* Reads `nd` digits, most significant first, into `n` big-endian bytes.
 * Returns 0, or ZUID_ENC_INVALID when the value needs more bytes. */
static int from_digits(const uint8_t *dig, size_t nd, int base, uint8_t *out,
                       size_t n)
{
    uint32_t stack[STACK_LIMBS];
    size_t nl = (n + 3) / 4;
    uint32_t *l = nl <= STACK_LIMBS ? stack : (uint32_t *) malloc(nl * 4 + 4);
    if (!l) return ZUID_ENC_NOMEM;
    memset(l, 0, nl * 4);

    uint32_t power;
    int k = chunk(base, &power);
    size_t top = nl; /* limbs from `top` on may be nonzero */
    int status = 0;
    size_t i = 0, head = nd % (size_t) k;
    while (i < nd) {
        size_t take = head ? head : (size_t) k;
        head = 0;
        uint64_t mult = 1, add = 0;
        for (size_t j = 0; j < take; j++, i++) {
            mult *= (uint64_t) base;
            add = add * (uint64_t) base + dig[i];
        }
        /* value = value * base^take + add, over the limbs in use. */
        uint64_t carry = add;
        size_t limb = nl;
        while (limb > top) {
            limb--;
            uint64_t cur = (uint64_t) l[limb] * mult + carry;
            l[limb] = (uint32_t) cur;
            carry = cur >> 32;
        }
        while (carry) {
            if (limb == 0) {
                status = ZUID_ENC_INVALID;
                break;
            }
            l[--limb] = (uint32_t) carry;
            carry >>= 32;
        }
        if (status) break;
        top = limb;
    }
    if (status == 0) {
        size_t pad = nl * 4 - n;
        for (size_t b = 0; b < pad; b++) {
            if ((l[0] >> (8 * (3 - b))) & 0xff) status = ZUID_ENC_INVALID;
        }
        for (size_t b = 0; b < n && status == 0; b++) {
            size_t j = b + pad;
            out[b] = (uint8_t) (l[j / 4] >> (8 * (3 - j % 4)));
        }
    }
    if (l != stack) free(l);
    return status;
}

long zuid_enc_radix(const uint8_t *in, size_t n, const zuid_alphabet *a,
                    int btc, char *out)
{
    size_t zeros = 0;
    if (btc) {
        while (zeros < n && in[zeros] == 0) zeros++;
        in += zeros;
        n -= zeros;
    }
    size_t ndig = zuid_radix_width(n, a->base);
    /* The digits are written in place, then mapped to symbols. */
    uint8_t *dig = (uint8_t *) out + zeros;
    int r = to_digits(in, n, a->base, dig, ndig);
    if (r != 0) return r;
    size_t skip = 0;
    if (btc) {
        while (skip < ndig && dig[skip] == 0) skip++;
        memmove(dig, dig + skip, ndig - skip);
        memset(out, a->symbols[0], zeros);
    }
    for (size_t i = 0; i < ndig - skip; i++) {
        out[zeros + i] = a->symbols[dig[i]];
    }
    return (long) (zeros + ndig - skip);
}

long zuid_dec_radix(const char *s, size_t len, const zuid_alphabet *a,
                    int btc, long width, uint8_t *out)
{
    size_t zeros = 0;
    if (btc) {
        while (zeros < len && s[zeros] == a->symbols[0]) zeros++;
    }
    size_t nd = len - zeros, n;
    if (btc) {
        /* Enough bytes for any nd digits; the value's leading zero bytes
         * are dropped below. */
        n = (size_t) ceil((double) nd * log2((double) a->base) / 8) + 1;
    } else {
        n = (size_t) floor((double) len * log2((double) a->base) / 8);
        /* A length no byte count produces is not text of the form. */
        while (n > 0 && zuid_radix_width(n, a->base) > len) n--;
        if (zuid_radix_width(n, a->base) != len) return ZUID_ENC_INVALID;
        if (width >= 0 && (size_t) width != n) return ZUID_ENC_INVALID;
    }
    uint8_t *dig = (uint8_t *) malloc(nd ? nd : 1);
    if (!dig) return ZUID_ENC_NOMEM;
    for (size_t i = 0; i < nd; i++) {
        uint8_t v = a->index[(unsigned char) s[zeros + i]];
        if (v == 0xff || v >= a->base) {
            free(dig);
            return ZUID_ENC_INVALID;
        }
        dig[i] = v;
    }
    uint8_t stack[64];
    uint8_t *tmp = btc ? (n <= sizeof stack ? stack : (uint8_t *) malloc(n))
                       : out;
    if (!tmp) {
        free(dig);
        return ZUID_ENC_NOMEM;
    }
    int r = from_digits(dig, nd, a->base, tmp, n);
    free(dig);
    if (r != 0 || !btc) {
        return r != 0 ? r : (long) n;
    }
    size_t lead = 0;
    while (lead < n && tmp[lead] == 0) lead++;
    size_t total = zeros + n - lead;
    long res = (long) total;
    if (width >= 0 && (size_t) width != total) {
        res = ZUID_ENC_INVALID;
    } else {
        memset(out, 0, zeros);
        memcpy(out + zeros, tmp + lead, n - lead);
    }
    if (tmp != stack) free(tmp);
    return res;
}
