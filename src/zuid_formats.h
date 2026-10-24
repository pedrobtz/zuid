#ifndef ZUID_FORMATS_H
#define ZUID_FORMATS_H

/* Format descriptors (design.md section 4, layer 1). One static record per
 * format; the R surface reaches every format through this table, so a new
 * format is a new row and a new zuid_fmt_*.c, never a new entry point. */

#include <stddef.h>
#include <stdint.h>

#define ZUID_MAX_WIDTH 32  /* bytes; the widest fixed-width format is 20 */
#define ZUID_TEXT_BUF 256  /* bytes; longer than any form of any format */
#define ZUID_PREFIX_MAX 63 /* a TypeID prefix, the longest text outside the bytes */

/* Text a format carries outside its bytes: the TypeID prefix. Empty for
 * every other format. */
typedef struct {
    char s[ZUID_PREFIX_MAX + 1];
    size_t len;
} zuid_prefix;

typedef enum {
    ZUID_CLASS_STRUCTURED,
    ZUID_CLASS_ENCODING,
    ZUID_CLASS_SYNTACTIC
} zuid_class;

/* Validation levels (design.md section 6.3), cumulative. */
typedef enum {
    ZUID_LEVEL_NONE = 0,
    ZUID_LEVEL_SYNTAX = 1,
    ZUID_LEVEL_STRUCTURE = 2,
    ZUID_LEVEL_STRICT = 3
} zuid_level;

/* What id_fields() reads from one value (design.md section 6.4). Columns a
 * format lacks keep the "absent" values zuid_fields_clear() sets. */
typedef struct {
    int has_time;
    int64_t time_s;       /* whole seconds since 1970, floored */
    int32_t time_frac_ns; /* 0 to 999999999, added to time_s */
    const char *time_unit;
    int version;          /* -1 when absent */
    const char *variant;  /* NULL when absent */
    char node[41];        /* hex; "" when absent */
    int sequence;         /* -1 when absent */
    char random[41];      /* hex; "" when absent */
    int has_prefix;
    char prefix[ZUID_PREFIX_MAX + 1];
} zuid_fields;

void zuid_fields_clear(zuid_fields *f);

/* Hex of `nbits` bits of `bytes` starting at bit `offset` (big-endian, bit 0
 * the most significant of byte 0), left-padded with zero bits to a multiple
 * of four. Writes a terminated string to `out`, which must hold
 * (nbits + 3) / 4 + 1 characters. */
void zuid_bits_hex(const uint8_t *bytes, int offset, int nbits, char *out);
/* Append the bits like zuid_bits_hex() but into an accumulator, so
 * discontiguous random fields can be reported as one value. */
typedef struct {
    uint8_t bits[ZUID_MAX_WIDTH * 8];
    int n;
} zuid_bitbuf;
void zuid_bitbuf_add(zuid_bitbuf *b, const uint8_t *bytes, int offset,
                     int nbits);
void zuid_bitbuf_hex(const zuid_bitbuf *b, char *out);

typedef struct zuid_format {
    const char *name;
    zuid_class cls;
    int width;             /* bytes */
    int text_min, text_max; /* canonical text length */
    const char *alphabet;
    const char *case_rule;
    const char *time_unit; /* NULL when the format has no time */
    const char *epoch;     /* ISO 8601, NULL when no time */
    const char *forms;     /* comma-separated text forms id_format() takes */

    /* Text forms: index into `forms`, or -1 for the format's default, which
     * on input accepts whatever the canonical text's case rule allows. */
    int (*form_index)(const char *form);
    /* Parse `len` bytes of text in `form`. Returns the level reached, at
     * most ZUID_LEVEL_STRUCTURE, and fills `out` (width bytes) and `pfx`
     * when at least ZUID_LEVEL_SYNTAX. */
    zuid_level (*parse)(const char *text, size_t len, int form, uint8_t *out,
                        zuid_prefix *pfx);
    /* Whether a value that passed structure passes strict, given the current
     * time and tolerance in milliseconds since 1970. */
    int (*strict)(const uint8_t *bytes, double now_ms, double tolerance_ms);
    /* Write the text of `bytes` (and `pfx`, NULL for none) in `form` (-1:
     * canonical) into `out`, which holds ZUID_TEXT_BUF bytes. Returns the
     * length, without a terminator. */
    size_t (*format)(const uint8_t *bytes, int form, const zuid_prefix *pfx,
                     char *out);
    void (*fields)(const uint8_t *bytes, const zuid_prefix *pfx,
                   zuid_fields *out);
} zuid_format;

/* The format named `name`, or NULL. */
const zuid_format *zuid_format_find(const char *name);
/* The table, for id_formats(). */
extern const zuid_format *const zuid_formats[];
extern const int zuid_n_formats;

/* Formats, one per zuid_fmt_*.c. */
extern const zuid_format zuid_fmt_uuid;
extern const zuid_format zuid_fmt_ulid;
extern const zuid_format zuid_fmt_typeid;
extern const zuid_format zuid_fmt_upid;

#endif
