# Encode and decode bytes

`id_encode()` writes bytes of any length as text in a form, and
`id_decode()` reads them back. A UUID's text forms are the 16-byte case:
`id_format(x, form)` is `id_encode(id_bytes(x), form)`.

## Usage

``` r
id_encode(bytes, form, alphabet = NULL, sep = "-")

id_decode(text, form, alphabet = NULL, width = NULL)
```

## Arguments

- bytes:

  A raw vector (one element), a list of raw vectors (`NULL` for a
  missing element), or a raw matrix with one element per column. At most
  65536 bytes per element.

- form:

  The form.

- alphabet:

  For `form = "alphabet"`, its symbols in digit order: 2 to 94 distinct
  printable ASCII characters other than space. `NULL` for ShortUUID's.

- sep:

  The separator between units for `"proquint"` and `"words"`. It must
  not contain letters.

- text:

  A character vector.

- width:

  `NULL`, or the number of bytes each element must decode to.

## Value

`id_encode()`: a character vector, `NA` where `bytes` is `NULL`.
`id_decode()`: a list of raw vectors, with `NULL` where `text` is `NA`
or not text of the form.

## Details

Each form writes what the mainstream Go and Python libraries write, so
text made elsewhere decodes here and the other way round:

- `"hex"`: lowercase hexadecimal. Decoding takes either case and ignores
  hyphens.

- `"base32"`: Crockford's alphabet, with the spare bits in front as zero
  bits, as ULID and TypeID do. Sixteen bytes give 26 characters starting
  `0` to `7`, so a UUID in this form is textually a ULID. Uppercase, and
  either case on input; the letters `I`, `L`, `O` and `U` are rejected.

- `"base32rfc"`, `"base32hex"`: RFC 4648 sections 6 and 7, with the
  spare bits at the end and no padding. Decoding also takes `=` padding.

- `"base36"`: `0-9a-z`, fixed width; 16 bytes are Uuid25's 25
  characters.

- `"base58"`: base58btc. Each leading zero byte is one `1`, so the
  length varies, as in Bitcoin and Go's and Python's base58.

- `"base62"`, `"base62sort"`: `0-9A-Za-z`, fixed width, padded with `0`;
  sorts as the bytes do. The two names are one form.

- `"base64url"`: RFC 4648 section 5, no padding. Decoding also takes `=`
  padding.

- `"base64sort"`: base64url's bits in the IETF draft's alphabet, in
  ASCII order, so it sorts as the bytes do.

- `"alphabet"`: the caller's symbols, most significant digit first,
  fixed width, padded with the first symbol. The default is ShortUUID's
  57 symbols, as ShortUUID 1.0 and later write them.

- `"proquint"`: each 16 bits as five pronounceable letters.

- `"words"`: each 16 bits as a Niceware word. The Niceware list was not
  checked for offensive words, and some text in this form may offend.

The fixed-width forms (`"base32"`, `"base36"`, `"base62"`, `"alphabet"`)
write the digits the byte count needs, so the length gives the byte
count back. `"proquint"` and `"words"` take an even number of bytes, and
their decoding ignores case and any non-letter between units.

## Examples

``` r
b <- as.raw(c(0xf8, 0x1d, 0x4f, 0xae))
id_encode(b, "base58")
#> [1] "7LqmvD"
id_decode("7R3N7TW", "base32")
#> [[1]]
#> NULL
#> 
x <- id_parse("f81d4fae-7dec-11d0-a765-00a0c91e6bf6", "uuid")
id_encode(id_bytes(x), "base62")
#> [1] "7YBUWgZR1mKSqGyj9tVViw"
id_format(x, "proquint")
#> [1] "zobit-huvov-lulos-dalib-pitoj-bafob-sohiv-kozuk"
id_encode(id_bytes(x), "alphabet", alphabet = "0123456789")
#> [1] "329800735698586629295641978511506172918"
```
