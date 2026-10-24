#ifndef ZUID_R_H
#define ZUID_R_H

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <stddef.h>

/* The only constructor of a CHARSXP from bytes (design.md section 4). Every
 * string zuid returns to R goes through it, so encoding and length rules live
 * in one place. */
SEXP zuid_mkchar(const char *bytes, size_t len);

SEXP zuid_c_table(SEXP name);
SEXP zuid_c_parse(SEXP x, SEXP format, SEXP form, SEXP now_ms,
                  SEXP tolerance_ms, SEXP want_text);
SEXP zuid_c_format(SEXP x, SEXP format, SEXP form);
SEXP zuid_c_bytes(SEXP x, SEXP format);
SEXP zuid_c_from_bytes(SEXP bytes, SEXP format, SEXP na);
SEXP zuid_c_fields(SEXP x, SEXP format);
SEXP zuid_c_formats(void);
SEXP zuid_c_key(SEXP x, SEXP format);
SEXP zuid_c_uuid(SEXP n, SEXP version, SEXP time_us, SEXP random, SEXP node,
                 SEXP tolerance_ms);
SEXP zuid_c_state(void);
SEXP zuid_c_reset_state(void);
SEXP zuid_c_ulid(SEXP n, SEXP time_us, SEXP random, SEXP tolerance_ms);
SEXP zuid_c_upid(SEXP n, SEXP time_us, SEXP random, SEXP tail);
SEXP zuid_c_scru128(SEXP n, SEXP time_us, SEXP random, SEXP tolerance_ms,
                    SEXP reset);
SEXP zuid_c_scru64(SEXP n, SEXP time_us, SEXP random, SEXP node,
                   SEXP node_bits, SEXP tolerance_ms, SEXP reset);
SEXP zuid_c_ksuid(SEXP n, SEXP time_us, SEXP random);
SEXP zuid_c_layout_unpack(SEXP bytes, SEXP widths, SEXP kinds);
SEXP zuid_c_snowflake(SEXP ticks, SEXP widths, SEXP kinds, SEXP node,
                      SEXP epoch_ms, SEXP unit_ms, SEXP tolerance_ticks,
                      SEXP reset);
SEXP zuid_c_xid(SEXP secs, SEXP machine, SEXP process, SEXP random);
SEXP zuid_c_objectid(SEXP secs, SEXP random);
void zuid_layout_reset_state(void);
SEXP zuid_c_charset(SEXP x, SEXP alphabet);
SEXP zuid_c_cuid2(SEXP x);
SEXP zuid_c_nanoid(SEXP n, SEXP size, SEXP alphabet, SEXP random);
SEXP zuid_c_sqids_encode(SEXP numbers, SEXP alphabet, SEXP min_length,
                         SEXP blocklist);
SEXP zuid_c_sqids_parse(SEXP x, SEXP alphabet, SEXP min_length,
                        SEXP blocklist);
SEXP zuid_c_cid_parse(SEXP x);
SEXP zuid_c_cid_text(SEXP bytes);
SEXP zuid_c_encode(SEXP bytes, SEXP form, SEXP alphabet, SEXP sep);
SEXP zuid_c_decode(SEXP text, SEXP form, SEXP alphabet, SEXP width);

#endif
