# Parse and validate identifiers

`id_parse()` turns text into a zuid vector of one format, holding each
element's canonical text. `id_valid()` is the vectorised predicate.

## Usage

``` r
id_parse(
  x,
  format = NULL,
  form = NULL,
  layout = NULL,
  level = c("structure", "syntax", "strict"),
  strict = FALSE,
  alphabet = NULL,
  min_length = 0
)

id_valid(
  x,
  format,
  form = NULL,
  layout = NULL,
  level = c("structure", "syntax", "strict"),
  alphabet = NULL,
  min_length = 0
)
```

## Arguments

- x:

  A character vector.

- format:

  The format, such as `"uuid"`. See
  [`id_formats()`](https://pedrobtz.github.io/zuid/reference/id_formats.md).
  `NULL` detects it with
  [`id_detect()`](https://pedrobtz.github.io/zuid/reference/id_detect.md):
  every element that is not missing must resolve to the same format, or
  the call is a `zuid_ambiguous_error` naming the candidates or a
  `zuid_mixed_error` naming the formats found. Elements that fit no
  format are `NA`, or an error with `strict = TRUE`. When no element
  fits, or none is present (`x` is empty or all `NA`), there is no
  format to detect, and the call is a `zuid_parse_error`: give `format`.

- form:

  A text form of `format`, or `NULL` for its canonical text.

- layout:

  For `"snowflake"`, required, and for `"scru64"`, optional: an
  [`id_layout()`](https://pedrobtz.github.io/zuid/reference/id_layout.md).
  It travels with the vector and says how to read its fields. A
  Snowflake whose layout has a sign bit must have it clear.

- level:

  The validation level elements must reach.

- strict:

  If `TRUE`, an element that fails `level` is an error of class
  `zuid_parse_error`. If `FALSE`, it becomes `NA`.

- alphabet:

  For `"nanoid"` and `"sqids"`, the alphabet the values were made with,
  or `NULL` for the format's default. It travels with the vector.

- min_length:

  For `"sqids"`, the `min_length` the values were made with. A Sqids
  string is valid only when its numbers encode back to it, which depends
  on the alphabet, `min_length` and the blocklist.

## Value

`id_parse()`: a zuid vector, the same length as `x`, with `NA` where an
element is missing or fails `level`. `id_valid()`: a logical vector,
`NA` where `x` is.

## Details

Validation is cumulative over three levels:

- `"syntax"`: the alphabet, length, case rule and separators of the
  form.

- `"structure"`: syntax, and the value's own rules. For a UUID, the
  variant bits are the RFC's (`10`), except for the nil and max UUIDs.

- `"strict"`: structure, and the value is one its specification defines.
  For a UUID, the version is 1 to 8 (or nil or max), and a time field is
  no later than now plus the option `zuid.time_tolerance` (seconds, one
  day by default).

A UUID's canonical text is lowercase and hyphenated. On input, either
case is accepted, and `form` selects another of the RFC 9562 text forms:
`"compact"` (32 hex digits), `"urn"` (`urn:uuid:` prefix), `"braced"` or
`"uppercase"`, or one of the encodings of
[`id_encode()`](https://pedrobtz.github.io/zuid/reference/id_encode.md)
over the 16 bytes, such as `"base32"`, `"base58"` or `"words"`.

A ULID is 26 Crockford base32 characters, uppercase, either case on
input, starting `0` to `7`. A TypeID is a lowercase prefix, `_` and 26
lowercase Crockford characters, or the 26 alone; strict asks what it
asks of the UUID. A UPID is four prefix characters, `_` and 22 lowercase
characters, as the reference writes them; strict asks for the current
version. SCRU128 is 25 base36 characters and SCRU64 12, lowercase,
either case on input; their reserved timestamps (the first and the last)
pass `"syntax"` only. A KSUID is 27 base62 characters, case-sensitive,
at most `aWgEPTl1tmebfsQzFP4bxwgy80V`. Strict also asks that a time is
no later than now plus the tolerance. An XID is 20 lowercase base32hex
characters, an ObjectId 24 hex digits (either case on input) and a
Snowflake 1 to 20 decimal digits without leading zeros. A NanoID is one
or more symbols of its alphabet; a Cuid2 is 2 to 32 of `0-9a-z`, and
strict asks that it starts with a letter, as generated ones do. A Sqid
is valid when it decodes and its numbers encode back to it under the
alphabet, `min_length` and blocklist. A CID is version 0 (`Qm` and 44
base58btc characters) or version 1 in one of 17 multibases; structure
checks its varints, and the digest length of a hash function zuid knows.
These formats have one text form each.

## Examples

``` r
x <- id_parse("018F6B1C-2D3E-7A4B-8C5D-6E7F8091A2B3", "uuid")
x
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
id_valid(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "nope"), "uuid")
#> [1]  TRUE FALSE
id_parse("{018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3}", "uuid", form = "braced")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
```
