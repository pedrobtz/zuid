#include "zuid_formats.h"

#include <string.h>

const zuid_format *const zuid_formats[] = {
    &zuid_fmt_uuid,
    &zuid_fmt_ulid,
    &zuid_fmt_typeid,
    &zuid_fmt_upid,
    &zuid_fmt_scru128,
    &zuid_fmt_scru64,
    &zuid_fmt_ksuid,
};
const int zuid_n_formats = (int) (sizeof zuid_formats / sizeof zuid_formats[0]);

const zuid_format *zuid_format_find(const char *name)
{
    for (int i = 0; i < zuid_n_formats; i++) {
        if (strcmp(zuid_formats[i]->name, name) == 0) {
            return zuid_formats[i];
        }
    }
    return NULL;
}

void zuid_fields_clear(zuid_fields *f)
{
    f->has_time = 0;
    f->time_s = 0;
    f->time_frac_ns = 0;
    f->time_unit = NULL;
    f->version = -1;
    f->variant = NULL;
    f->node[0] = '\0';
    f->sequence = -1;
    f->random[0] = '\0';
    f->has_prefix = 0;
    f->prefix[0] = '\0';
}

static int bit_at(const uint8_t *bytes, int i)
{
    return (bytes[i / 8] >> (7 - i % 8)) & 1;
}

void zuid_bitbuf_add(zuid_bitbuf *b, const uint8_t *bytes, int offset,
                     int nbits)
{
    for (int i = 0; i < nbits; i++) {
        b->bits[b->n++] = (uint8_t) bit_at(bytes, offset + i);
    }
}

void zuid_bitbuf_hex(const zuid_bitbuf *b, char *out)
{
    static const char digits[] = "0123456789abcdef";
    int pad = (4 - b->n % 4) % 4;
    int ndigits = (b->n + pad) / 4;
    for (int d = 0; d < ndigits; d++) {
        int v = 0;
        for (int k = 0; k < 4; k++) {
            int i = d * 4 + k - pad; /* index into bits; negative is padding */
            v = (v << 1) | (i >= 0 ? b->bits[i] : 0);
        }
        out[d] = digits[v];
    }
    out[ndigits] = '\0';
}

void zuid_bits_hex(const uint8_t *bytes, int offset, int nbits, char *out)
{
    zuid_bitbuf b;
    b.n = 0;
    zuid_bitbuf_add(&b, bytes, offset, nbits);
    zuid_bitbuf_hex(&b, out);
}
