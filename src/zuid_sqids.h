#ifndef ZUID_SQIDS_H
#define ZUID_SQIDS_H

/* Sqids (sqids/sqids-spec): integers to short strings over a shuffled
 * alphabet, with a blocklist (design.md sections 6.1 and 6.6, D8). Plain
 * C11, no R headers. Numbers are 0 to 2^53 - 1, the reference's range; the
 * 64-bit range waits for zuint (roadmap, After 0.1.0). */

#include <stddef.h>
#include <stdint.h>

#define ZUID_SQIDS_MAX UINT64_C(9007199254740991) /* 2^53 - 1 */
#define ZUID_SQIDS_MAX_MIN_LENGTH 255

typedef struct {
    char alphabet[256]; /* shuffled */
    int n;
    int8_t present[256];
    int min_length;
    const char **block; /* lowercase words that fit the alphabet */
    size_t nblock;
} zuid_sqids;

/* `words` (NULL: the default blocklist), which must be lowercase, are
 * filtered as the reference
 * filters them into `block`, which holds room for `nwords` pointers and
 * points into `words` or the compiled table. Returns 0, or -1 unless the
 * alphabet is 3 or more distinct ASCII characters and `min_length` is 0 to
 * 255. Word pointers must outlive the struct. */
int zuid_sqids_init(zuid_sqids *s, const char *alphabet, size_t len,
                    int min_length, const char *const *words, size_t nwords,
                    const char **block);

/* Characters zuid_sqids_encode() may write for `count` numbers. */
size_t zuid_sqids_max_len(const zuid_sqids *s, size_t count);

/* Returns the length written to `out`, or -1 when every offset is blocked
 * (zuid_encode_error), or -2 for a number above ZUID_SQIDS_MAX. */
long zuid_sqids_encode(const zuid_sqids *s, const uint64_t *numbers,
                       size_t count, char *out);

/* Returns the count of numbers written to `out` (room for `len`), 0 for an
 * empty string or one with a character outside the alphabet (as the
 * reference returns []), or -2 for a number above ZUID_SQIDS_MAX. */
long zuid_sqids_decode(const zuid_sqids *s, const char *id, size_t len,
                       uint64_t *out);

#endif
