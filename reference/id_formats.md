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
#>       format      class width text_min text_max
#> 1       uuid structured   128       36       36
#> 2       ulid structured   128       26       26
#> 3     typeid structured   128       26       90
#> 4       upid structured   128       27       27
#> 5    scru128 structured   128       25       25
#> 6     scru64 structured    64       12       12
#> 7      ksuid structured   160       27       27
#> 8        xid structured    96       20       20
#> 9   objectid structured    96       24       24
#> 10 snowflake structured    64        1       20
#> 11    nanoid  syntactic    NA        1       NA
#> 12     cuid2  syntactic    NA        2       32
#> 13     sqids   encoding    NA        1       NA
#> 14       cid structured    NA        2       NA
#>                                            alphabet                        case
#> 1                                            0-9a-f lower; either case on input
#> 2                      0-9A-HJKMNP-TV-Z (Crockford) upper; either case on input
#> 3  prefix a-z_, suffix 0-9a-hjkmnp-tv-z (Crockford)                       lower
#> 4                                         234567a-z                       lower
#> 5                                            0-9a-z lower; either case on input
#> 6                                            0-9a-z lower; either case on input
#> 7                                         0-9A-Za-z              case-sensitive
#> 8                                0-9a-v (base32hex)                       lower
#> 9                                            0-9a-f lower; either case on input
#> 10                                              0-9   decimal, no leading zeros
#> 11                    A-Za-z0-9_- (or the caller's)              case-sensitive
#> 12                                           0-9a-z                       lower
#> 13                      a-zA-Z0-9 (or the caller's)              case-sensitive
#> 14                                      a multibase             the multibase's
#>                                time_unit
#> 1  100ns (versions 1, 6), ms (version 7)
#> 2                                     ms
#> 3                            as the UUID
#> 4                                  256ms
#> 5                                     ms
#> 6                                  256ms
#> 7                                      s
#> 8                                      s
#> 9                                      s
#> 10                          the layout's
#> 11                                  <NA>
#> 12                                  <NA>
#> 13                                  <NA>
#> 14                                  <NA>
#>                                                                     epoch
#> 1  1582-10-15T00:00:00Z (versions 1, 6), 1970-01-01T00:00:00Z (version 7)
#> 2                                                    1970-01-01T00:00:00Z
#> 3                                                             as the UUID
#> 4                                                    1970-01-01T00:00:00Z
#> 5                                                    1970-01-01T00:00:00Z
#> 6                                                    1970-01-01T00:00:00Z
#> 7                                                    2014-05-13T16:53:20Z
#> 8                                                    1970-01-01T00:00:00Z
#> 9                                                    1970-01-01T00:00:00Z
#> 10                                                           the layout's
#> 11                                                                   <NA>
#> 12                                                                   <NA>
#> 13                                                                   <NA>
#> 14                                                                   <NA>
#>                                                                                                                                                       forms
#> 1  hex, compact, urn, braced, uppercase, base32, base32rfc, base32hex, base36, base58, base62, base62sort, base64url, base64sort, alphabet, proquint, words
#> 2                                                                                                                                                          
#> 3                                                                                                                                                          
#> 4                                                                                                                                                          
#> 5                                                                                                                                                          
#> 6                                                                                                                                                          
#> 7                                                                                                                                                          
#> 8                                                                                                                                                          
#> 9                                                                                                                                                          
#> 10                                                                                                                                                         
#> 11                                                                                                                                                         
#> 12                                                                                                                                                         
#> 13                                                                                                                                                         
#> 14                                                                                                                                                         
```
