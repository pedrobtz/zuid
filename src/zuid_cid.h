#ifndef ZUID_CID_H
#define ZUID_CID_H

/* Content identifiers (multiformats CID): version 0 is a base58btc
 * SHA-256 multihash; version 1 is a multibase prefix, then varints for the
 * version, the content codec and the hash function, the digest length and
 * the digest (design.md section 6.1). Plain C11, no R headers. */

#include <stddef.h>
#include <stdint.h>

typedef struct {
    int version;
    uint64_t codec, hash;
    size_t digest_len;
    size_t digest_at; /* offset of the digest in the bytes */
    size_t nbytes;    /* the binary CID: the multihash alone for version 0 */
} zuid_cid;

/* Decodes `len` characters into `bytes`, which holds len + 8. Returns the
 * level reached: 0 (not a CID), 1 (syntax: it decodes, but a known hash
 * function's digest length is wrong, or a version 0 is not SHA-256 over
 * dag-pb) or 2 (structure). */
int zuid_cid_parse(const char *s, size_t len, uint8_t *bytes, zuid_cid *out);

/* Reads a binary CID, as zuid_cid_parse() reads its text. */
int zuid_cid_read(const uint8_t *b, size_t n, zuid_cid *out);

/* Text of a binary CID: "Qm..." for a version 0 multihash, else lowercase
 * base32 with the "b" prefix. `out` holds 2 * n + 8. Returns the length, or
 * -1 when the bytes are not a CID. */
long zuid_cid_text(const uint8_t *b, size_t n, char *out);

/* The multicodec name of a code, or NULL when zuid does not know it. */
const char *zuid_multicodec_name(uint64_t code);

#endif
