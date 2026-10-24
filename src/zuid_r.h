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
                  SEXP tolerance_ms);
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

#endif
