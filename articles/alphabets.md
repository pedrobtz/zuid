# A UUID in every alphabet

``` r

library(zuid)
```

A UUID is 16 bytes. The hyphenated hex text is one way to write them,
and not the shortest. Others are shorter, sort as the bytes do, or can
be read aloud. This article shows the forms zuid writes, how to read
them back, and how bytes move between formats.

## The forms

[`id_format()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
writes a UUID in any of its forms:

``` r

u <- id_parse("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "uuid")
forms <- c(
  "hex", "compact", "urn", "braced", "uppercase",
  "base32", "base32rfc", "base32hex", "base36", "base58",
  "base62", "base64url", "base64sort", "alphabet", "proquint", "words"
)
text <- vapply(forms, id_format, "", x = u)
writeLines(sprintf("%-10s %s", forms, text))
#> hex        018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
#> compact    018f6b1c2d3e7a4b8c5d6e7f8091a2b3
#> urn        urn:uuid:018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
#> braced     {018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3}
#> uppercase  018F6B1C-2D3E-7A4B-8C5D-6E7F8091A2B3
#> base32     01HXNHRB9YF95RRQBEFY0938NK
#> base32rfc  AGHWWHBNHZ5EXDC5NZ7YBENCWM
#> base32hex  067MM71D7PT4N32TDPVO14D2MC
#> base36     03bpkx6u2msu6ciqi7535yf8z
#> base58     CB7z5qdx3BKrzyaKnqWbU
#> base62     02wX9SMOWJoiiOS5z0PjLH
#> base64url  AY9rHC0-ekuMXW5_gJGisw
#> base64sort -Nxf61oyTZiBMLtzV85Xgk
#> alphabet   2Hpv8uCyvCfeTVNwAzDWuU
#> proquint   bakaz-kosis-fuhuv-lonar-mudit-kunuz-mafid-papug
#> words      advertised-impunity-counterrevolutionary-lecher-munition-injecting-maladroit-pitch
```

Each form writes what the mainstream Go and Python libraries write, so
text made elsewhere reads here:

- `base32` is Crockford’s alphabet, as ULID uses. A UUID in this form is
  textually a ULID.
- `base32rfc` and `base32hex` are RFC 4648’s, without padding.
- `base36` is Uuid25’s 25 characters.
- `base58` is Bitcoin’s alphabet. Its length varies: each leading zero
  byte is one `1`.
- `base62` is `0-9A-Za-z`, fixed width.
- `base64url` is RFC 4648’s URL-safe alphabet, and `base64sort` the same
  bits in an alphabet in ASCII order.
- `alphabet` defaults to ShortUUID’s 57 symbols.
- `proquint` writes each 16 bits as five pronounceable letters, and
  `words` each 16 bits as a Niceware word. The Niceware list was not
  checked for offensive words, so some text in this form may offend.

## Reading them back

[`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md)
reads any of the forms with `form`:

``` r

id_parse("CB7z5qdx3BKrzyaKnqWbU", "uuid", form = "base58")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
id_parse("bakaz-kosis-fuhuv-lonar-mudit-kunuz-mafid-papug", "uuid", form = "proquint")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
```

The word forms ignore case and the separator, so text that someone read
aloud and typed back still decodes:

``` r

spoken <- "Advertised Impunity Counterrevolutionary Lecher Munition Injecting Maladroit Pitch"
id_parse(spoken, "uuid", form = "words")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
```

## Bytes of any length

[`id_encode()`](https://pedrobtz.github.io/zuid/reference/id_encode.md)
and
[`id_decode()`](https://pedrobtz.github.io/zuid/reference/id_encode.md)
are the forms over bytes of any length, not only 16. Proquint’s own
example is an IPv4 address:

``` r

localhost <- as.raw(c(127, 0, 0, 1))
id_encode(localhost, "proquint")
#> [1] "lusab-babad"
id_decode("lusab-babad", "proquint")
#> [[1]]
#> [1] 7f 00 00 01
```

A list of raw vectors encodes element by element, and `NULL` is a
missing value:

``` r

id_encode(list(localhost, as.raw(1:6), NULL), "base58")
#> [1] "4FHRnp"  "W7LcTy7" NA
```

`alphabet` takes any symbols, in digit order:

``` r

id_encode(localhost, "alphabet", alphabet = "01")
#> [1] "01111111000000000000000000000001"
```

## Order

The fixed-width forms `base32`, `base36`, `base62`, `base64sort` and
`alphabet` (with its symbols in ASCII order) sort as their bytes do.
Here are five byte strings, out of order, and their hex:

``` r

hex <- c(
  "f0000000000000000000000000000000",
  "3c000000000000000000000000000000",
  "00000000000000000000000000000001",
  "a5000000000000000000000000000000",
  "7f000000000000000000000000000000"
)
bytes <- id_decode(hex, "hex")
order(hex)
#> [1] 3 2 5 4 1
```

In `base62` and `base64sort` the text sorts the same way, and in
`base64url` it does not, since its alphabet puts `A-Z` before `0-9`:

``` r

order(id_encode(bytes, "base62"), method = "radix")
#> [1] 3 2 5 4 1
order(id_encode(bytes, "base64sort"), method = "radix")
#> [1] 3 2 5 4 1
order(id_encode(bytes, "base64url"), method = "radix")
#> [1] 1 3 2 5 4
```

A version 7 UUID begins with its time, so in a sorting form its text
sorts by time too.

## Between formats

Bytes do not carry their format. Sixteen bytes could be a UUID, a ULID
or a SCRU128, so
[`id_from_bytes()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
asks which:

``` r

b <- id_bytes(u)
id_from_bytes(b, "ulid")
#> <zuid_ulid[1]>
#> [1] 01HXNHRB9YF95RRQBEFY0938NK
err <- tryCatch(id_from_bytes(b), error = identity)
class(err)
#> [1] "zuid_type_error" "zuid_error"      "error"           "condition"
```

[`id_convert()`](https://pedrobtz.github.io/zuid/reference/id_convert.md)
moves an identifier to a format with the same bytes and the same
meaning. A ULID, a TypeID and a UPID hold a UUID’s 128 bits, and XID and
ObjectId share their 12-byte layout:

``` r

id_convert(u, "ulid")
#> <zuid_ulid[1]>
#> [1] 01HXNHRB9YF95RRQBEFY0938NK
id_convert(u, "typeid", prefix = "user")
#> <zuid_typeid[1]>
#> [1] user_01hxnhrb9yf95rrqbefy0938nk
id_convert(id_parse("9m4e2mr0ui3e8a215n4g", "xid"), "objectid")
#> <zuid_objectid[1]>
#> [1] 4d88e15b60f486e428412dc9
```

A conversion that would change the meaning of the bits is an error, not
a reinterpretation:

``` r

err <- tryCatch(id_convert(u, "ksuid"), error = identity)
class(err)
#> [1] "zuid_convert_error" "zuid_error"         "error"             
#> [4] "condition"
```
