#ifndef ZUID_ENC_H
#define ZUID_ENC_H

/* Encodings over bytes of any length (design.md section 4, layer 2; section
 * 6.5; D17). Plain C11 with no R headers, so the codecs compile on their
 * own under ZUID_STANDALONE for the fuzz harness. A UUID text form other
 * than the hex ones is the 16-byte case of one of these. */

#include <stddef.h>
#include <stdint.h>

typedef enum {
    ZUID_ENC_HEX,
    ZUID_ENC_BASE32,     /* Crockford, zero bits prepended: ULID, TypeID */
    ZUID_ENC_BASE32RFC,  /* RFC 4648 section 6, left-aligned */
    ZUID_ENC_BASE32HEX,  /* RFC 4648 section 7, left-aligned */
    ZUID_ENC_BASE36,     /* big-endian integer, fixed width: Uuid25 */
    ZUID_ENC_BASE58,     /* base58btc: one '1' per leading zero byte */
    ZUID_ENC_BASE62,     /* big-endian integer, fixed width */
    ZUID_ENC_BASE62SORT, /* the IETF draft's name for the same */
    ZUID_ENC_BASE64URL,  /* RFC 4648 section 5, left-aligned */
    ZUID_ENC_BASE64SORT, /* base64url's grouping, alphabet in ASCII order */
    ZUID_ENC_ALPHABET,   /* the caller's symbols; ShortUUID's by default */
    ZUID_ENC_PROQUINT,
    ZUID_ENC_WORDS,      /* Niceware */
    ZUID_ENC_N
} zuid_enc_form;

/* Error returns of zuid_encode() and zuid_decode(). */
#define ZUID_ENC_INVALID (-1) /* not text of the form, or odd byte count */
#define ZUID_ENC_NOMEM (-2)

/* An alphabet: the symbols in digit order and a reverse index. */
typedef struct {
    char symbols[256];
    int base;
    uint8_t index[256]; /* digit of each byte, 0xff when not a symbol */
} zuid_alphabet;

/* The ShortUUID alphabet, the default of ZUID_ENC_ALPHABET. */
extern const char zuid_shortuuid_alphabet[];

/* Fills `a` from `n` symbols. Returns 0, or -1 unless the symbols are 2 to
 * 94 distinct printable ASCII characters other than space. */
int zuid_alphabet_init(zuid_alphabet *a, const char *symbols, size_t n);

/* The form called `name`, or -1. */
int zuid_enc_find(const char *name);
const char *zuid_enc_name(int form);

/* Characters zuid_encode() may write for `n` bytes, and bytes
 * zuid_decode() may write for `len` characters. */
size_t zuid_enc_max_len(int form, size_t n, const zuid_alphabet *a,
                        size_t sep_len);
size_t zuid_dec_max_len(size_t len);

/* Writes the text of `n` bytes into `out`, which holds zuid_enc_max_len()
 * characters, without a terminator. `a` is used by ZUID_ENC_ALPHABET only
 * (NULL: ShortUUID's) and `sep` by proquint and words. Returns the length,
 * or ZUID_ENC_INVALID (odd `n` for proquint or words) or ZUID_ENC_NOMEM. */
long zuid_encode(int form, const uint8_t *in, size_t n, const zuid_alphabet *a,
                 const char *sep, size_t sep_len, char *out);

/* Reads `len` characters into `out`, which holds zuid_dec_max_len(len)
 * bytes. `width` is the byte count the text must hold, or -1 to infer it
 * from the length. Returns the byte count, ZUID_ENC_INVALID or
 * ZUID_ENC_NOMEM. */
long zuid_decode(int form, const char *s, size_t len, const zuid_alphabet *a,
                 long width, uint8_t *out);

/* Shared between the codec files. */
long zuid_enc_bits(const uint8_t *in, size_t n, int bits, int lead,
                   const char *symbols, char *out);
long zuid_dec_bits(const char *s, size_t len, int bits, int lead,
                   const uint8_t *index, long width, uint8_t *out);
size_t zuid_radix_width(size_t n, int base);
long zuid_enc_radix(const uint8_t *in, size_t n, const zuid_alphabet *a,
                    int btc, char *out);
long zuid_dec_radix(const char *s, size_t len, const zuid_alphabet *a,
                    int btc, long width, uint8_t *out);
long zuid_enc_proquint(const uint8_t *in, size_t n, const char *sep,
                       size_t sep_len, char *out);
long zuid_dec_proquint(const char *s, size_t len, uint8_t *out);
long zuid_enc_words(const uint8_t *in, size_t n, const char *sep,
                    size_t sep_len, char *out);
long zuid_dec_words(const char *s, size_t len, uint8_t *out);

#endif
