# Describe this build of zuid

Reports the installed version and the generated tables compiled into it,
with the upstream source each was taken from.

## Usage

``` r
zuid_info()
```

## Value

A list with elements:

- `version`:

  the package version, as a `package_version`.

- `tables`:

  a data frame with one row per generated table: its name, the upstream
  `repo`, `commit` and `path`, the file's `sha256`, and the number of
  `entries`.

## Examples

``` r
zuid_info()
#> $version
#> [1] ‘0.0.0.9000’
#> 
#> $tables
#>             table                  repo
#> 1 sqids_blocklist sqids/sqids-blocklist
#> 2  niceware_words  diracdeltas/niceware
#>                                     commit                  path
#> 1 084d15864ce0d102fd1aa0e752edb2d78e073e9f output/blocklist.json
#> 2 0d48914236f1d026affc33efb6caa81cdf1bf715       lib/wordlist.js
#>                                                             sha256 entries
#> 1 757018526eaa1af57b9ccc9439fe672345b3ae85cf8162b74af45c0d6f5a9b1a     560
#> 2 8d874a859a6795f164eff11951724012cb9332965df3488a490126522c29da34   65536
#> 
```
