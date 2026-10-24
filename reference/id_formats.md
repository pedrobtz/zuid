# The identifier formats zuid knows

The identifier formats zuid knows

## Usage

``` r
id_formats()
```

## Value

A data frame with one row per format: its name; its `class`
(`structured`, `encoding` or `syntactic`); its `width` in bits; the
length of its canonical text; its alphabet and case rule; the unit and
epoch of its time field; and the text `forms`
[`id_format()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
accepts.

## Examples

``` r
id_formats()
#>   format      class width text_min text_max
#> 1   uuid structured   128       36       36
#> 2   ulid structured   128       26       26
#> 3 typeid structured   128       26       90
#> 4   upid structured   128       27       27
#>                                           alphabet                        case
#> 1                                           0-9a-f lower; either case on input
#> 2                     0-9A-HJKMNP-TV-Z (Crockford) upper; either case on input
#> 3 prefix a-z_, suffix 0-9a-hjkmnp-tv-z (Crockford)                       lower
#> 4                                        234567a-z                       lower
#>                               time_unit
#> 1 100ns (versions 1, 6), ms (version 7)
#> 2                                    ms
#> 3                           as the UUID
#> 4                                 256ms
#>                                                                    epoch
#> 1 1582-10-15T00:00:00Z (versions 1, 6), 1970-01-01T00:00:00Z (version 7)
#> 2                                                   1970-01-01T00:00:00Z
#> 3                                                            as the UUID
#> 4                                                   1970-01-01T00:00:00Z
#>                                                                                                                                                      forms
#> 1 hex, compact, urn, braced, uppercase, base32, base32rfc, base32hex, base36, base58, base62, base62sort, base64url, base64sort, alphabet, proquint, words
#> 2                                                                                                                                                         
#> 3                                                                                                                                                         
#> 4                                                                                                                                                         
```
