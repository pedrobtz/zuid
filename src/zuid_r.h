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

#endif
