/* CID parsing over the multibases of js-multiformats' basics, less base2,
 * base8, base10, base32z, base58flickr, base256emoji and identity. */

#include "zuid_cid.h"
#include "zuid_enc.h"

#include <string.h>

/* Unsigned LEB128, at most 9 bytes and minimally encoded, as the
 * multiformats unsigned-varint specification requires. Returns the bytes
 * read, or 0. */
static size_t varint(const uint8_t *b, size_t n, uint64_t *v)
{
    uint64_t x = 0;
    for (size_t i = 0; i < n && i < 9; i++) {
        x |= (uint64_t) (b[i] & 0x7f) << (7 * i);
        if (!(b[i] & 0x80)) {
            if (i > 0 && b[i] == 0) return 0; /* not minimal */
            *v = x;
            return i + 1;
        }
    }
    return 0;
}

static const struct {
    uint64_t code;
    const char *name;
    int digest_len; /* -1: any */
} codes[] = {
    {0x00, "identity", -1},
    {0x11, "sha1", 20},
    {0x12, "sha2-256", 32},
    {0x13, "sha2-512", 64},
    {0x14, "sha3-512", 64},
    {0x15, "sha3-384", 48},
    {0x16, "sha3-256", 32},
    {0x17, "sha3-224", 28},
    {0x1b, "keccak-256", 32},
    {0x1e, "blake3", -1},
    {0x20, "sha2-384", 48},
    {0x51, "cbor", -1},
    {0x55, "raw", -1},
    {0x70, "dag-pb", -1},
    {0x71, "dag-cbor", -1},
    {0x72, "libp2p-key", -1},
    {0x78, "git-raw", -1},
    {0x85, "dag-jose", -1},
    {0xd5, "md5", 16},
    {0x0129, "dag-json", -1},
    {0x0200, "json", -1},
    {0x0201, "messagepack", -1},
    {0x0202, "car", -1},
    {0x1012, "sha2-256-trunc254-padded", 32},
    {0xb220, "blake2b-256", 32},
    {0xb260, "blake2s-256", 32},
};
#define N_CODES (sizeof codes / sizeof codes[0])

const char *zuid_multicodec_name(uint64_t code)
{
    for (size_t i = 0; i < N_CODES; i++) {
        if (codes[i].code == code) return codes[i].name;
    }
    return NULL;
}

/* The digest length a hash function fixes, or -1. */
static int hash_length(uint64_t code)
{
    for (size_t i = 0; i < N_CODES; i++) {
        if (codes[i].code == code) return codes[i].digest_len;
    }
    return -1;
}

int zuid_cid_read(const uint8_t *b, size_t n, zuid_cid *out)
{
    memset(out, 0, sizeof *out);
    out->nbytes = n;
    /* Version 0: the bare 34-byte SHA-256 multihash. */
    if (n == 34 && b[0] == 0x12 && b[1] == 0x20) {
        out->version = 0;
        out->codec = 0x70;
        out->hash = 0x12;
        out->digest_len = 32;
        out->digest_at = 2;
        return 2;
    }
    uint64_t version, len;
    size_t pos = varint(b, n, &version), k;
    if (!pos || version != 1) return 0;
    if (!(k = varint(b + pos, n - pos, &out->codec))) return 0;
    pos += k;
    if (!(k = varint(b + pos, n - pos, &out->hash))) return 0;
    pos += k;
    if (!(k = varint(b + pos, n - pos, &len))) return 0;
    pos += k;
    if (len != n - pos) return 0;
    out->version = 1;
    out->digest_len = (size_t) len;
    out->digest_at = pos;
    int fixed = hash_length(out->hash);
    if (fixed >= 0 && (size_t) fixed != out->digest_len) return 1;
    if (out->hash == 0x1e && out->digest_len == 0) return 1;
    return 2;
}

/* Decodes text in a power-of-two alphabet, with exact RFC 4648 padding
 * when `padded`. */
static long bits(const char *s, size_t len, int nbits, const char *symbols,
                 int padded, uint8_t *out)
{
    zuid_alphabet a;
    zuid_alphabet_init(&a, symbols, strlen(symbols));
    size_t body = len;
    if (padded) {
        size_t block = nbits == 5 ? 8 : 4;
        while (body > 0 && s[body - 1] == '=') body--;
        if ((body + block - 1) / block * block != len) return ZUID_ENC_INVALID;
    }
    return zuid_dec_bits(s, body, nbits, 0, a.index, -1, out);
}

static long radix_btc(const char *s, size_t len, const char *symbols,
                      uint8_t *out)
{
    zuid_alphabet a;
    zuid_alphabet_init(&a, symbols, strlen(symbols));
    return zuid_dec_radix(s, len, &a, 1, -1, out);
}

static const char B16[] = "0123456789abcdef";
static const char B16U[] = "0123456789ABCDEF";
static const char B32[] = "abcdefghijklmnopqrstuvwxyz234567";
static const char B32U[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
static const char B32H[] = "0123456789abcdefghijklmnopqrstuv";
static const char B32HU[] = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
static const char B36[] = "0123456789abcdefghijklmnopqrstuvwxyz";
static const char B36U[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static const char B58[] =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
static const char B64[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char B64URL[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

int zuid_cid_parse(const char *s, size_t len, uint8_t *bytes, zuid_cid *out)
{
    if (len < 2) return 0;
    long n;
    if (len == 46 && s[0] == 'Q' && s[1] == 'm') {
        n = radix_btc(s, len, B58, bytes);
        if (n != 34) return 0;
        return zuid_cid_read(bytes, (size_t) n, out);
    }
    const char *body = s + 1;
    size_t blen = len - 1;
    switch (s[0]) {
    case 'f': n = bits(body, blen, 4, B16, 0, bytes); break;
    case 'F': n = bits(body, blen, 4, B16U, 0, bytes); break;
    case 'b': n = bits(body, blen, 5, B32, 0, bytes); break;
    case 'B': n = bits(body, blen, 5, B32U, 0, bytes); break;
    case 'c': n = bits(body, blen, 5, B32, 1, bytes); break;
    case 'C': n = bits(body, blen, 5, B32U, 1, bytes); break;
    case 'v': n = bits(body, blen, 5, B32H, 0, bytes); break;
    case 'V': n = bits(body, blen, 5, B32HU, 0, bytes); break;
    case 't': n = bits(body, blen, 5, B32H, 1, bytes); break;
    case 'T': n = bits(body, blen, 5, B32HU, 1, bytes); break;
    case 'k': n = radix_btc(body, blen, B36, bytes); break;
    case 'K': n = radix_btc(body, blen, B36U, bytes); break;
    case 'z': n = radix_btc(body, blen, B58, bytes); break;
    case 'm': n = bits(body, blen, 6, B64, 0, bytes); break;
    case 'M': n = bits(body, blen, 6, B64, 1, bytes); break;
    case 'u': n = bits(body, blen, 6, B64URL, 0, bytes); break;
    case 'U': n = bits(body, blen, 6, B64URL, 1, bytes); break;
    default: return 0;
    }
    if (n <= 0) return 0;
    zuid_cid tmp;
    int level = zuid_cid_read(bytes, (size_t) n, &tmp);
    /* A version 0 multihash is not a version 1 CID in a multibase. */
    if (level && tmp.version != 1) return 0;
    *out = tmp;
    return level;
}

long zuid_cid_text(const uint8_t *b, size_t n, char *out)
{
    zuid_cid c;
    if (!zuid_cid_read(b, n, &c)) return -1;
    if (c.version == 0) {
        zuid_alphabet a;
        zuid_alphabet_init(&a, B58, strlen(B58));
        return zuid_enc_radix(b, n, &a, 1, out);
    }
    out[0] = 'b';
    long m = zuid_enc_bits(b, n, 5, 0, B32, out + 1);
    return m < 0 ? -1 : m + 1;
}
