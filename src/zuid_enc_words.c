/* Proquint and Niceware words: one unit per 16 bits, joined by a separator
 * (design.md section 6.5). Decoding ignores the separator and case. */

#include "zuid_enc.h"
#include "zuid_tables.h"

#include <string.h>

static const char CONSONANTS[] = "bdfghjklmnprstvz";
static const char VOWELS[] = "aiou";

static int lower(int c)
{
    return c >= 'A' && c <= 'Z' ? c - 'A' + 'a' : c;
}

static int is_letter(int c)
{
    c = lower(c);
    return c >= 'a' && c <= 'z';
}

long zuid_enc_proquint(const uint8_t *in, size_t n, const char *sep,
                       size_t sep_len, char *out)
{
    if (n % 2) return ZUID_ENC_INVALID;
    size_t m = 0;
    for (size_t i = 0; i < n; i += 2) {
        unsigned v = (unsigned) in[i] << 8 | in[i + 1];
        if (i > 0) {
            memcpy(out + m, sep, sep_len);
            m += sep_len;
        }
        out[m++] = CONSONANTS[(v >> 12) & 15];
        out[m++] = VOWELS[(v >> 10) & 3];
        out[m++] = CONSONANTS[(v >> 6) & 15];
        out[m++] = VOWELS[(v >> 4) & 3];
        out[m++] = CONSONANTS[v & 15];
    }
    return (long) m;
}

static int position(const char *set, int c)
{
    const char *p = c ? strchr(set, c) : NULL;
    return p ? (int) (p - set) : -1;
}

long zuid_dec_proquint(const char *s, size_t len, uint8_t *out)
{
    /* Letters in fives; anything that is not a letter separates. */
    static const int is_consonant[5] = {1, 0, 1, 0, 1};
    static const int shift[5] = {12, 10, 6, 4, 0};
    unsigned v = 0;
    int k = 0;
    size_t m = 0;
    for (size_t i = 0; i < len; i++) {
        int c = (unsigned char) s[i];
        if (!is_letter(c)) {
            if (k != 0) return ZUID_ENC_INVALID;
            continue;
        }
        int d = position(is_consonant[k] ? CONSONANTS : VOWELS, lower(c));
        if (d < 0) return ZUID_ENC_INVALID;
        v |= (unsigned) d << shift[k];
        if (++k == 5) {
            out[m++] = (uint8_t) (v >> 8);
            out[m++] = (uint8_t) v;
            v = 0;
            k = 0;
        }
    }
    return k == 0 ? (long) m : ZUID_ENC_INVALID;
}

long zuid_enc_words(const uint8_t *in, size_t n, const char *sep,
                    size_t sep_len, char *out)
{
    if (n % 2) return ZUID_ENC_INVALID;
    size_t m = 0;
    for (size_t i = 0; i < n; i += 2) {
        const char *w = zuid_niceware_words[(unsigned) in[i] << 8 | in[i + 1]];
        size_t wl = strlen(w);
        if (i > 0) {
            memcpy(out + m, sep, sep_len);
            m += sep_len;
        }
        memcpy(out + m, w, wl);
        m += wl;
    }
    return (long) m;
}

/* The index of a lowercase word in the sorted list, or -1. */
static long word_index(const char *w)
{
    long lo = 0, hi = ZUID_NICEWARE_N - 1;
    while (lo <= hi) {
        long mid = lo + (hi - lo) / 2;
        int c = strcmp(zuid_niceware_words[mid], w);
        if (c == 0) return mid;
        if (c < 0) {
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return -1;
}

long zuid_dec_words(const char *s, size_t len, uint8_t *out)
{
    char word[32];
    size_t wl = 0, m = 0;
    for (size_t i = 0; i <= len; i++) {
        int c = i < len ? (unsigned char) s[i] : 0;
        if (i < len && is_letter(c)) {
            if (wl + 1 >= sizeof word) return ZUID_ENC_INVALID;
            word[wl++] = (char) lower(c);
            continue;
        }
        if (wl == 0) continue;
        word[wl] = '\0';
        long v = word_index(word);
        if (v < 0) return ZUID_ENC_INVALID;
        out[m++] = (uint8_t) (v >> 8);
        out[m++] = (uint8_t) v;
        wl = 0;
    }
    return (long) m;
}
