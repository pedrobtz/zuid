# Read the fields of identifiers

`id_fields()` reports what each identifier carries, one row per element.
`id_time()` returns its time field alone, and `id_version()` its
version.

## Usage

``` r
id_fields(x)

id_time(x, class = c("POSIXct", "ms"))

id_version(x)
```

## Arguments

- x:

  A zuid vector from
  [`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md).

- class:

  For `id_time()`, `"POSIXct"` (the default), or `"ms"` for the whole
  number of milliseconds since 1970 as a double, the sub-millisecond
  part dropped. `POSIXct` is exact to the microsecond; the 100 ns ticks
  of UUID versions 1 and 6 are exact in neither.

## Value

`id_fields()`: a data frame with columns `format`, `time`, `time_unit`,
`version`, `variant`, `node`, `process`, `sequence`, `random`, `prefix`,
`codec`, `hash`, `digest` and `numbers`, `NA` where the format or the
element has no such field. `id_time()`: a `POSIXct` in UTC or a double.
`id_version()`: an integer vector.

## Details

For a UUID, the fields depend on the version and are read only when the
variant is RFC 9562's:

- versions 1 and 6: the time in 100 ns ticks from 1582-10-15, the 14-bit
  clock sequence (`sequence`) and the 48-bit `node`;

- version 4: the 122 `random` bits;

- version 7: the millisecond time and the 74 `random` bits;

- versions 2, 3, 5 and 8: the version only.

A ULID has its millisecond time and 80 `random` bits. A TypeID has its
UUID's fields and its `prefix`, `""` when it has none. A UPID has its
time in 256 ms units, 64 `random` bits, its `prefix` and its version
nibble (6, the reference's `"a"`, is the current one).

A SCRU128 has its millisecond time, `counter_hi` in `node` (as hex),
`counter_lo` in `sequence` and its 32 entropy bits in `random`. A SCRU64
has its time at 256 ms, and its `node` and counter in `sequence` when it
was parsed with `id_layout("scru64", node_bits = )`. A KSUID has its
time in seconds and its 128-bit payload in `random`. An XID has its time
in seconds, its machine id in `node`, its `process` and its counter in
`sequence`; an ObjectId the same, but its middle five bytes are
`random`, as the current BSON specification makes them. A Snowflake has
what its layout says: the time at the layout's unit and epoch, the node
fields in `node` as `name=value` pairs, and the `sequence`.

The nil and max UUIDs report versions 0 and 15 and no variant. `random`
is the random bits joined in order, as hex, left-padded with zero bits
to a whole number of hex digits.

## Examples

``` r
x <- id_parse(c(
  "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3",
  "c232ab00-9414-11ec-b3c8-9f6bdeced846"
), "uuid")
id_fields(x)
#>   format                time time_unit version variant         node process
#> 1   uuid 2024-05-12 04:42:39        ms       7     rfc         <NA>      NA
#> 2   uuid 2022-02-22 19:22:22     100ns       1     rfc 9f6bdeced846      NA
#>   sequence              random prefix codec hash digest numbers
#> 1       NA 292cc5d6e7f8091a2b3   <NA>  <NA> <NA>   <NA>        
#> 2    13256                <NA>   <NA>  <NA> <NA>   <NA>        
id_time(x)
#> [1] "2024-05-12 04:42:39 UTC" "2022-02-22 19:22:22 UTC"
id_version(x)
#> [1] 7 1
```
