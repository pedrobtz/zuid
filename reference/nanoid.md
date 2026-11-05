# Generate NanoIDs and Sqids

`nanoid()` generates NanoIDs: `size` symbols drawn uniformly from
`alphabet`, by NanoID 6's `customRandom()`. Random bytes come in
batches, each read from its last byte, and a byte at or above the
largest multiple of the alphabet's size below 256 is rejected, so every
symbol is equally likely. When rejection uses up a batch, another is
drawn.

## Usage

``` r
nanoid(n = 1, size = 21, alphabet = NULL, random = NULL)

sqids(numbers, alphabet = NULL, min_length = 0, blocklist = NULL)
```

## Arguments

- n:

  The number of NanoIDs.

- size:

  Symbols per NanoID, 1 to 65536, 21 by default.

- alphabet:

  The symbols, or `NULL` for the format's default: `A-Za-z0-9_-` for
  NanoID and `a-zA-Z0-9` for Sqids. 1 to 256 printable ASCII characters
  for NanoID, 3 to 255 for Sqids, all distinct.

- random:

  For `nanoid()`, `NULL` to draw from the operating system, or a raw
  vector read batch by batch, for reproducible values; running out is a
  `zuid_type_error`.

- numbers:

  A numeric vector, or a list of numeric vectors, of whole numbers from
  0 to 2^53 - 1. An element that is `NULL` or a single `NA` gives `NA`;
  an element with `NA` among other numbers is an error.

- min_length:

  The shortest Sqid, 0 to 255.

- blocklist:

  `NULL` for the default blocklist, or a character vector of words to
  avoid ([`character()`](https://rdrr.io/r/base/character.html) for
  none).

## Value

A zuid vector.

## Details

`sqids()` encodes non-negative whole numbers as Sqids, by the
specification's algorithm: the default alphabet and blocklist unless
given, and padded to `min_length`. A numeric vector gives one Sqid per
number; a list gives one per element, encoding all its numbers. An ID
that contains a blocklisted word is re-encoded with the next offset;
when every offset is blocked, the result is a `zuid_encode_error`. An
element with no numbers encodes as `""`, as the specification says, and
`""` parses back to no numbers.

## Examples

``` r
nanoid(2)
#> <zuid_nanoid[2]>
#> [1] gU355NQMtvEWukkcNkxjb 7FDS0w58WSeHUM9CBu_wI
nanoid(2, size = 10, alphabet = "0123456789abcdef")
#> <zuid_nanoid[2]>
#> [1] a58760fb71 a3ac36c994
sqids(c(1, 2, 3))
#> <zuid_sqids[3]>
#> [1] Uk gb Ef
sqids(list(c(1, 2, 3)), min_length = 10)
#> <zuid_sqids[1]>
#> [1] 86Rf07xd4z
```
