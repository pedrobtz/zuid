# Text forms and bytes

`id_format()` writes identifiers in their canonical text or another text
form. `id_bytes()` returns their bytes, and `id_from_bytes()` reads them
back.

## Usage

``` r
id_format(x, form = NULL)

id_bytes(x)

id_from_bytes(bytes, format, layout = NULL)
```

## Arguments

- x:

  A zuid vector from
  [`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md).

- form:

  A text form of the vector's format (see
  [`id_formats()`](https://pedrobtz.github.io/zuid/reference/id_formats.md)),
  or `NULL` for the canonical text.

- bytes:

  A raw matrix with one column per element, a list of raw vectors
  (`NULL` for a missing element), or one raw vector holding the elements
  back to back.

- format:

  The format the bytes are in. Required.

- layout:

  Reserved for formats that need a layout.

## Value

`id_format()`: a character vector. `id_bytes()`: a raw matrix with the
format's width in rows and one column per element, big-endian, with
missing elements as columns of zeros listed in the attribute `na`.
`id_from_bytes()`: a zuid vector.

## Details

Every encoding of
[`id_encode()`](https://pedrobtz.github.io/zuid/reference/id_encode.md)
is a form of a UUID too: `id_format(x, "base62")` is
`id_encode(id_bytes(x), "base62")`.

`id_from_bytes()` has no default `format`: sixteen bytes are not a UUID
until the caller says so.

## Examples

``` r
x <- id_parse("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "uuid")
id_format(x, "urn")
#> [1] "urn:uuid:018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3"
id_format(x, "compact")
#> [1] "018f6b1c2d3e7a4b8c5d6e7f8091a2b3"
id_format(x, "base32")
#> [1] "01HXNHRB9YF95RRQBEFY0938NK"
b <- id_bytes(x)
b[, 1]
#>  [1] 01 8f 6b 1c 2d 3e 7a 4b 8c 5d 6e 7f 80 91 a2 b3
id_from_bytes(b, "uuid")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
```
