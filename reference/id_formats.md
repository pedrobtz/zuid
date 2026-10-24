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
#>   format      class width text_min text_max alphabet
#> 1   uuid structured   128       36       36   0-9a-f
#>                          case                             time_unit
#> 1 lower; either case on input 100ns (versions 1, 6), ms (version 7)
#>                                                                    epoch
#> 1 1582-10-15T00:00:00Z (versions 1, 6), 1970-01-01T00:00:00Z (version 7)
#>                                  forms
#> 1 hex, compact, urn, braced, uppercase
```
