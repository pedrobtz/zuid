# Generate NanoIDs and Sqids

`id_nanoid()` generates NanoIDs: `size` symbols drawn uniformly from
`alphabet`, by NanoID 6's `customRandom()`. Random bytes come in
batches, each read from its last byte, and a byte at or above the
largest multiple of the alphabet's size below 256 is rejected, so every
symbol is equally likely. When rejection uses up a batch, another is
drawn.

## Usage

``` r
id_nanoid(n = 1, size = 21, alphabet = NULL, random = NULL)

id_sqids(numbers, alphabet = NULL, min_length = 0, blocklist = NULL)
```

## Arguments

- n:

  The number of NanoIDs.

- size:

  Symbols per NanoID, 21 by default.

- alphabet:

  The symbols, or `NULL` for the format's default: `A-Za-z0-9_-` for
  NanoID and `a-zA-Z0-9` for Sqids. 1 to 256 printable ASCII characters
  for NanoID, 3 to 255 for Sqids, all distinct.

- random:

  For `id_nanoid()`, `NULL` to draw from the operating system, or a raw
  vector read batch by batch, for reproducible values; running out is a
  `zuid_type_error`.

- numbers:

  A numeric vector, or a list of numeric vectors, of whole numbers from
  0 to 2^53 - 1. `NA` or `NULL` gives `NA`.

- min_length:

  The shortest Sqid, 0 to 255.

- blocklist:

  `NULL` for the default blocklist, or a character vector of words to
  avoid ([`character()`](https://rdrr.io/r/base/character.html) for
  none).

## Value

A zuid vector.

## Details

`id_sqids()` encodes non-negative whole numbers as Sqids, by the
specification's algorithm: the default alphabet and blocklist unless
given, and padded to `min_length`. A numeric vector gives one Sqid per
number; a list gives one per element, encoding all its numbers. An ID
that contains a blocklisted word is re-encoded with the next offset;
when every offset is blocked, the result is a `zuid_encode_error`.

## Examples

``` r
id_nanoid(2)
#> <zuid_nanoid[2]>
#> [1] 2w9GQMQgvvWl15gyw5c5e QscOFFH8zc2OeH0vCo9zT
id_nanoid(2, size = 10, alphabet = "0123456789abcdef")
#> <zuid_nanoid[2]>
#> [1] 7a828f1bae 40c16f055c
id_sqids(c(1, 2, 3))
#> <zuid_sqids[3]>
#> [1] Uk gb Ef
id_sqids(list(c(1, 2, 3)), min_length = 10)
#> <zuid_sqids[1]>
#> [1] 86Rf07xd4z
```
