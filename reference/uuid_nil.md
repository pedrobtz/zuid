# The nil and max UUIDs

The nil and max UUIDs

## Usage

``` r
uuid_nil()

uuid_max()
```

## Value

A zuid vector of one UUID: all bits zero (`uuid_nil()`) or all bits one
(`uuid_max()`).

## Examples

``` r
uuid_nil()
#> <zuid_uuid[1]>
#> [1] 00000000-0000-0000-0000-000000000000
uuid_max()
#> <zuid_uuid[1]>
#> [1] ffffffff-ffff-ffff-ffff-ffffffffffff
```
