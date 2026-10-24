# Convert identifiers between formats

`id_convert()` moves values between formats that hold the same 128 bits:
`"uuid"`, `"ulid"`, `"typeid"` and `"upid"`. The bytes are kept and the
text is rewritten.

## Usage

``` r
id_convert(x, to, prefix = NULL)
```

## Arguments

- x:

  A zuid vector.

- to:

  The format to convert to.

- prefix:

  For `to = "typeid"`, the prefix of every value, `""` for none. `NULL`
  keeps the prefixes of a TypeID and means `""` otherwise.

## Value

A zuid vector of format `to`.

## Details

- A UUID becomes a TypeID under `prefix`, and a TypeID becomes a UUID by
  dropping it.

- A UPID becomes a UUID as the reference converts it, keeping the bits.

- A ULID and a UUID convert by reinterpreting the bits.
  [`id_fields()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
  then reports what the bits say: most ULIDs read as UUIDs of the
  `"future"` variant, and a UUID read as a ULID has its first 48 bits as
  a time, which is meaningful for version 7 only.

Any other pair is a `zuid_convert_error`: the target would need a value
the source does not have. To change a UUID's text form, use
[`id_format()`](https://pedrobtz.github.io/zuid/reference/id_format.md).

## Examples

``` r
x <- id_parse("01890a5d-ac96-774b-bcce-b302099a8057", "uuid")
t <- id_convert(x, "typeid", prefix = "user")
t
#> <zuid_typeid[1]>
#> [1] user_01h455vb4pex5vsknk084sn02q
id_convert(t, "uuid")
#> <zuid_uuid[1]>
#> [1] 01890a5d-ac96-774b-bcce-b302099a8057
id_convert(x, "ulid")
#> <zuid_ulid[1]>
#> [1] 01H455VB4PEX5VSKNK084SN02Q
```
