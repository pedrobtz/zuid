/* Sqids, following the specification's reference (src/index.ts) step by
 * step, so its tests hold byte for byte. */

#include "zuid_sqids.h"
#include "zuid_tables.h"

#include <stdlib.h>
#include <string.h>

static void shuffle(char *c, int n)
{
    for (int i = 0, j = n - 1; j > 0; i++, j--) {
        int r = (i * j + (unsigned char) c[i] + (unsigned char) c[j]) % n;
        char t = c[i];
        c[i] = c[r];
        c[r] = t;
    }
}

static int lower(int c)
{
    return c >= 'A' && c <= 'Z' ? c - 'A' + 'a' : c;
}

int zuid_sqids_init(zuid_sqids *s, const char *alphabet, size_t len,
                    int min_length, const char *const *words, size_t nwords,
                    const char **block)
{
    if (len < 3 || len > 255 || min_length < 0 ||
        min_length > ZUID_SQIDS_MAX_MIN_LENGTH) {
        return -1;
    }
    memset(s->present, 0, sizeof s->present);
    int8_t lowered[256] = {0};
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char) alphabet[i];
        if (c == 0 || c > 127 || s->present[c]) return -1;
        s->present[c] = 1;
        lowered[lower(c)] = 1;
        s->alphabet[i] = (char) c;
    }
    s->n = (int) len;
    s->min_length = min_length;
    if (!words) {
        words = zuid_sqids_blocklist;
        nwords = ZUID_SQIDS_BLOCKLIST_N;
    }
    /* Words of 3 or more characters, every one in the lowercased alphabet.
     * Words must be lowercase: the compiled table is, and the R side
     * lowercases a caller's. */
    s->block = block;
    s->nblock = 0;
    for (size_t w = 0; w < nwords; w++) {
        const char *word = words[w];
        size_t wl = strlen(word);
        if (wl < 3) continue;
        int fits = 1;
        for (size_t k = 0; k < wl && fits; k++) {
            int c = (unsigned char) word[k];
            fits = c <= 127 && lowered[lower(c)];
        }
        if (fits) block[s->nblock++] = word;
    }
    /* Shortest first, so that is_blocked() stops at the first word longer
     * than the id. An insertion sort: the list is filtered once per call. */
    for (size_t i = 1; i < s->nblock; i++) {
        const char *w = block[i];
        size_t wl = strlen(w), j = i;
        while (j > 0 && strlen(block[j - 1]) > wl) {
            block[j] = block[j - 1];
            j--;
        }
        block[j] = w;
    }
    shuffle(s->alphabet, s->n);
    return 0;
}

size_t zuid_sqids_max_len(const zuid_sqids *s, size_t count)
{
    /* Each number takes at most 53 digits in base 2, plus a separator. */
    size_t body = 1 + count * 55;
    return (body > (size_t) s->min_length ? body : (size_t) s->min_length) +
           (size_t) s->n;
}

/* In the alphabet `a` of `n` characters, the digits of `num`. */
static size_t to_id(uint64_t num, const char *a, int n, char *out)
{
    char tmp[64];
    size_t k = 0;
    do {
        tmp[k++] = a[num % (uint64_t) n];
        num /= (uint64_t) n;
    } while (num > 0);
    for (size_t i = 0; i < k; i++) out[i] = tmp[k - 1 - i];
    return k;
}

static int has_digit(const char *w)
{
    for (; *w; w++) {
        if (*w >= '0' && *w <= '9') return 1;
    }
    return 0;
}

/* The reference's isBlockedId(), on the id lowercased once; the words are
 * lowercase already (the compiled table is, and the R side lowercases a
 * caller's). */
static int is_blocked(const zuid_sqids *s, const char *id, size_t len)
{
    char stack[512];
    char *low = len < sizeof stack ? stack : (char *) malloc(len + 1);
    if (!low) return 0;
    for (size_t i = 0; i < len; i++) low[i] = (char) lower((unsigned char) id[i]);
    low[len] = '\0';
    int blocked = 0;
    for (size_t w = 0; w < s->nblock && !blocked; w++) {
        const char *word = s->block[w];
        size_t wl = strlen(word);
        if (wl > len) break; /* sorted by length */
        if (len <= 3 || wl <= 3) {
            blocked = wl == len && memcmp(low, word, len) == 0;
        } else if (has_digit(word)) {
            blocked = memcmp(low, word, wl) == 0 ||
                      memcmp(low + len - wl, word, wl) == 0;
        } else {
            blocked = strstr(low, word) != NULL;
        }
    }
    if (low != stack) free(low);
    return blocked;
}

static void reverse(char *c, int n)
{
    for (int i = 0, j = n - 1; i < j; i++, j--) {
        char t = c[i];
        c[i] = c[j];
        c[j] = t;
    }
}

long zuid_sqids_encode(const zuid_sqids *s, const uint64_t *numbers,
                       size_t count, char *out)
{
    if (count == 0) return 0;
    for (size_t i = 0; i < count; i++) {
        if (numbers[i] > ZUID_SQIDS_MAX) return -2;
    }
    int n = s->n;
    for (int increment = 0; increment <= n; increment++) {
        uint64_t sum = count;
        for (size_t i = 0; i < count; i++) {
            sum += (unsigned char) s->alphabet[numbers[i] % (uint64_t) n] + i;
        }
        int offset = (int) ((sum % (uint64_t) n + (uint64_t) increment) %
                            (uint64_t) n);
        char a[256];
        memcpy(a, s->alphabet + offset, (size_t) (n - offset));
        memcpy(a + (n - offset), s->alphabet, (size_t) offset);
        char prefix = a[0];
        reverse(a, n);

        size_t m = 0;
        out[m++] = prefix;
        for (size_t i = 0; i < count; i++) {
            m += to_id(numbers[i], a + 1, n - 1, out + m);
            if (i + 1 < count) {
                out[m++] = a[0];
                shuffle(a, n);
            }
        }
        if ((size_t) s->min_length > m) {
            out[m++] = a[0];
            while ((size_t) s->min_length > m) {
                shuffle(a, n);
                size_t take = (size_t) s->min_length - m;
                if (take > (size_t) n) take = (size_t) n;
                memcpy(out + m, a, take);
                m += take;
            }
        }
        if (!is_blocked(s, out, m)) return (long) m;
    }
    return -1;
}

long zuid_sqids_decode(const zuid_sqids *s, const char *id, size_t len,
                       uint64_t *out)
{
    if (len == 0) return 0;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char) id[i];
        if (c > 127 || !s->present[c]) return 0;
    }
    int n = s->n;
    const char *p = memchr(s->alphabet, id[0], (size_t) n);
    int offset = (int) (p - s->alphabet);
    char a[256];
    memcpy(a, s->alphabet + offset, (size_t) (n - offset));
    memcpy(a + (n - offset), s->alphabet, (size_t) offset);
    reverse(a, n);

    size_t pos = 1, count = 0;
    while (pos < len) {
        char sep = a[0];
        const char *end = memchr(id + pos, sep, len - pos);
        size_t chunk = end ? (size_t) (end - (id + pos)) : len - pos;
        if (chunk == 0) return (long) count;
        /* The chunk in the alphabet without the separator. */
        uint64_t v = 0;
        for (size_t k = 0; k < chunk; k++) {
            const char *d = memchr(a + 1, id[pos + k], (size_t) (n - 1));
            /* The separator cannot occur inside a chunk. */
            uint64_t digit = (uint64_t) (d - (a + 1));
            if (v > (ZUID_SQIDS_MAX - digit) / (uint64_t) (n - 1)) return -2;
            v = v * (uint64_t) (n - 1) + digit;
        }
        out[count++] = v;
        pos += chunk;
        if (end) {
            pos++; /* the separator */
            shuffle(a, n);
        }
    }
    return (long) count;
}
