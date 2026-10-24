# The nil and max UUIDs

The nil and max UUIDs

## Usage

``` r
id_nil()

id_max()
```

## Value

A zuid vector of one UUID: all bits zero (`id_nil()`) or all bits one
(`id_max()`).

## Examples

``` r
id_nil()
#> <zuid_uuid[1]>
#> [1] 00000000-0000-0000-0000-000000000000
id_max()
#> <zuid_uuid[1]>
#> [1] ffffffff-ffff-ffff-ffff-ffffffffffff
```
