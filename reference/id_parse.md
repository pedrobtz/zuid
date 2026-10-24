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
  strict = FALSE
)

id_valid(
  x,
  format,
  form = NULL,
  layout = NULL,
  level = c("structure", "syntax", "strict")
)
```

## Arguments

- x:

  A character vector.

- format:

  The format, such as `"uuid"`. See
  [`id_formats()`](https://pedrobtz.github.io/zuid/reference/id_formats.md).
  Required for now; detecting it from `x` is not available yet.

- form:

  A text form of `format`, or `NULL` for its canonical text.

- layout:

  Reserved for formats that need a layout.

- level:

  The validation level elements must reach.

- strict:

  If `TRUE`, an element that fails `level` is an error of class
  `zuid_parse_error`. If `FALSE`, it becomes `NA`.

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
version. Strict also asks that a time is no later than now plus the
tolerance. These formats have one text form each.

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
