/* libFuzzer target for zuid's codecs, built without R by the r-actions
 * fuzz workflow (.github/workflows/fuzz.yml). design.md section 9.
 *
 * The first byte picks what the rest of the input is fed to:
 *
 *   0..ZUID_N  a fixed-width format's parser (zuid_formats[]), then its
 *              formatter, fields and strict check; the canonical text must
 *              parse back to the same bytes and prefix
 *   0x40+f     zuid_decode() in encoding form f, then zuid_encode(); the
 *              text must decode back to the same bytes
 *   0x60+f     zuid_encode() of the input as bytes, then zuid_decode()
 *   0x80       Sqids: the next byte picks the alphabet and min_length; a
 *              decoded string re-encodes and decodes to the same numbers
 *   0x81       CID text; a parsed CID's bytes write text that parses back
 *   0x82       CID bytes; a written text parses back to them
 *
 * Any broken round trip aborts, which libFuzzer reports as a crash. */

#include "zuid_formats.h"
#include "zuid_enc.h"
#include "zuid_sqids.h"
#include "zuid_cid.h"
#include "zuid_tables.h"

#include <stdlib.h>
#include <string.h>

#define CHECK(cond) do { if (!(cond)) abort(); } while (0)

static void fuzz_format(const zuid_format *fmt, const char *s, size_t len)
{
    uint8_t bytes[ZUID_MAX_WIDTH], again[ZUID_MAX_WIDTH];
    zuid_prefix pfx, pfx2;
    char text[ZUID_TEXT_BUF];
    if (fmt->width == 0) return;
    zuid_level lv = fmt->parse(s, len, -1, bytes, &pfx);
    if (lv < ZUID_LEVEL_SYNTAX) return;
    size_t m = fmt->format(bytes, -1, &pfx, text);
    CHECK(m > 0 && m < ZUID_TEXT_BUF);
    CHECK(fmt->parse(text, m, -1, again, &pfx2) == lv);
    CHECK(memcmp(bytes, again, (size_t) fmt->width) == 0);
    CHECK(pfx.len == pfx2.len && memcmp(pfx.s, pfx2.s, pfx.len) == 0);
    zuid_fields f;
    fmt->fields(bytes, &pfx, &f);
    (void) fmt->strict(bytes, 1.7e12, 8.64e7);
}

static void fuzz_decode(int form, const char *s, size_t len)
{
    uint8_t *out = malloc(zuid_dec_max_len(len));
    long n = zuid_decode(form, s, len, NULL, -1, out);
    if (n >= 0) {
        char *text = malloc(zuid_enc_max_len(form, (size_t) n, NULL, 1) + 1);
        long m = zuid_encode(form, out, (size_t) n, NULL, "-", 1, text);
        if (m >= 0) {
            uint8_t *back = malloc(zuid_dec_max_len((size_t) m));
            CHECK(zuid_decode(form, text, (size_t) m, NULL, -1, back) == n);
            CHECK(memcmp(back, out, (size_t) n) == 0);
            free(back);
        }
        free(text);
    }
    free(out);
}

static void fuzz_encode(int form, const uint8_t *b, size_t n)
{
    if (n > 4096) n = 4096;
    char *text = malloc(zuid_enc_max_len(form, n, NULL, 1) + 1);
    long m = zuid_encode(form, b, n, NULL, "-", 1, text);
    if (m >= 0) {
        uint8_t *back = malloc(zuid_dec_max_len((size_t) m));
        CHECK(zuid_decode(form, text, (size_t) m, NULL, -1, back) == (long) n);
        CHECK(memcmp(back, b, n) == 0);
        free(back);
    } else {
        CHECK(form == ZUID_ENC_PROQUINT || form == ZUID_ENC_WORDS);
    }
    free(text);
}

static void fuzz_sqids(const uint8_t *d, size_t size)
{
    static const char *alphabets[] = {
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
        "abc", "0123456789abcdef", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"};
    if (size < 1) return;
    const char *a = alphabets[d[0] % 4];
    zuid_sqids s;
    const char *block[ZUID_SQIDS_BLOCKLIST_N];
    CHECK(zuid_sqids_init(&s, a, strlen(a), d[0] >> 2, NULL, 0, block) == 0);
    const char *id = (const char *) d + 1;
    size_t len = size - 1;
    uint64_t *nums = malloc((len ? len : 1) * sizeof(uint64_t));
    long count = zuid_sqids_decode(&s, id, len, nums);
    if (count > 0) {
        char *text = malloc(zuid_sqids_max_len(&s, (size_t) count));
        long m = zuid_sqids_encode(&s, nums, (size_t) count, text);
        if (m > 0) {
            uint64_t *back = malloc((size_t) m * sizeof(uint64_t));
            CHECK(zuid_sqids_decode(&s, text, (size_t) m, back) == count);
            CHECK(memcmp(back, nums, (size_t) count * sizeof(uint64_t)) == 0);
            free(back);
        }
        free(text);
    }
    free(nums);
}

static void fuzz_cid_text(const char *s, size_t len)
{
    uint8_t *b = malloc(len + 8);
    zuid_cid c;
    if (zuid_cid_parse(s, len, b, &c) >= 1) {
        char *text = malloc(2 * c.nbytes + 8);
        long m = zuid_cid_text(b, c.nbytes, text);
        CHECK(m > 0);
        uint8_t *back = malloc((size_t) m + 8);
        zuid_cid c2;
        CHECK(zuid_cid_parse(text, (size_t) m, back, &c2) >= 1);
        CHECK(c2.nbytes == c.nbytes && memcmp(back, b, c.nbytes) == 0);
        free(back);
        free(text);
    }
    free(b);
}

static void fuzz_cid_bytes(const uint8_t *b, size_t n)
{
    char *text = malloc(2 * n + 8);
    long m = zuid_cid_text(b, n, text);
    if (m > 0) {
        uint8_t *back = malloc((size_t) m + 8);
        zuid_cid c;
        CHECK(zuid_cid_parse(text, (size_t) m, back, &c) >= 1);
        CHECK(c.nbytes == n && memcmp(back, b, n) == 0);
        free(back);
    }
    free(text);
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 1) return 0;
    unsigned sel = data[0];
    const uint8_t *rest = data + 1;
    size_t n = size - 1;
    const char *s = (const char *) rest;
    if (sel < (unsigned) zuid_n_formats) {
        fuzz_format(zuid_formats[sel], s, n);
    } else if (sel >= 0x40 && sel < 0x40 + ZUID_ENC_N) {
        fuzz_decode((int) (sel - 0x40), s, n);
    } else if (sel >= 0x60 && sel < 0x60 + ZUID_ENC_N) {
        fuzz_encode((int) (sel - 0x60), rest, n);
    } else if (sel == 0x80) {
        fuzz_sqids(rest, n);
    } else if (sel == 0x81) {
        fuzz_cid_text(s, n);
    } else if (sel == 0x82) {
        fuzz_cid_bytes(rest, n);
    }
    return 0;
}

#ifdef ZUID_FUZZ_REPLAY
/* Without libFuzzer: replay the files named on the command line. */
#include <stdio.h>
int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        FILE *f = fopen(argv[i], "rb");
        if (!f) continue;
        uint8_t buf[1 << 16];
        size_t n = fread(buf, 1, sizeof buf, f);
        fclose(f);
        LLVMFuzzerTestOneInput(buf, n);
    }
    return 0;
}
#endif
