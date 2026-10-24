/* NanoID, Cuid2, Sqids and CID: variable-width formats (design.md 6.1).
 * They are in the descriptor table for id_formats(), with width 0; their
 * parsing takes parameters (alphabet, min_length, blocklist) and returns
 * more than bytes, so it goes through zuid_r_text.c, not these entries. */

#include "zuid_formats.h"

static int no_form(const char *form)
{
    (void) form;
    return -2;
}

static zuid_level no_parse(const char *s, size_t len, int form, uint8_t *out,
                           zuid_prefix *pfx)
{
    (void) s;
    (void) len;
    (void) form;
    (void) out;
    pfx->len = 0;
    return ZUID_LEVEL_NONE;
}

static int no_strict(const uint8_t *b, double now_ms, double tolerance_ms)
{
    (void) b;
    (void) now_ms;
    (void) tolerance_ms;
    return 0;
}

static size_t no_format(const uint8_t *b, int form, const zuid_prefix *pfx,
                        char *out)
{
    (void) b;
    (void) form;
    (void) pfx;
    (void) out;
    return 0;
}

static void no_fields(const uint8_t *b, const zuid_prefix *pfx, zuid_fields *f)
{
    (void) b;
    (void) pfx;
    zuid_fields_clear(f);
}

#define TEXT_FORMAT(id, name, cls, min, max, alphabet, case_rule)           \
    const zuid_format id = {name,      cls,       0,         min,           \
                            max,       alphabet,  case_rule, NULL,          \
                            NULL,      "",        no_form,   no_parse,      \
                            no_strict, no_format, no_fields}

TEXT_FORMAT(zuid_fmt_nanoid, "nanoid", ZUID_CLASS_SYNTACTIC, 1, 0,
            "A-Za-z0-9_- (or the caller's)", "case-sensitive");
TEXT_FORMAT(zuid_fmt_cuid2, "cuid2", ZUID_CLASS_SYNTACTIC, 2, 32, "0-9a-z",
            "lower");
TEXT_FORMAT(zuid_fmt_sqids, "sqids", ZUID_CLASS_ENCODING, 1, 0,
            "a-zA-Z0-9 (or the caller's)", "case-sensitive");
TEXT_FORMAT(zuid_fmt_cid, "cid", ZUID_CLASS_STRUCTURED, 2, 0,
            "a multibase", "the multibase's");
