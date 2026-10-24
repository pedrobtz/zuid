# Detect the format of identifiers

`id_detect()` names the format of each element, or gives `NA` when the
evidence does not settle it. Detection never guesses:

## Usage

``` r
id_detect(x, hint = NULL, layout = NULL)
```

## Arguments

- x:

  A character vector.

- hint:

  `NULL`, or the formats to try.

- layout:

  An
  [`id_layout()`](https://pedrobtz.github.io/zuid/reference/id_layout.md)
  for Snowflake or SCRU64.

## Value

A character vector of formats, `NA` where none or several fit, with the
attribute `candidates`: a list of the formats each element passes,
structured formats first.

## Details

- Without a `hint`, only structured formats are tried, since an encoding
  or a syntactic format (NanoID, Cuid2, Sqids) matches any string over
  its alphabet. A UUID written in Crockford base32 is textually a ULID,
  and the ULID is what is detected;
  `id_parse(x, "uuid", form = "base32")` is how to say otherwise.

- When exactly one format passes at the `"structure"` level, it is the
  answer. When several pass, the answer is `NA`, and the `candidates`
  attribute lists them. A 26-character lowercase Crockford string, for
  one, is a ULID or a TypeID without a prefix.

- A Snowflake is considered only under a Snowflake `layout`, since every
  layout reads the digits differently. A SCRU64 is listed among the
  candidates, but chosen only under `id_layout("scru64", node_bits = )`.

- `hint` restricts the formats tried to those named, and is how a
  syntactic format or an encoding can be detected at all.

Formats are recognised in their canonical text, with their default
alphabets.

## Examples

``` r
id_detect(c(
  "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3",
  "01ARZ3NDEKTSV4RRFFQ69G5FAV",
  "01arz3ndektsv4rrffq69g5fav",
  "not an id"
))
#> [1] "uuid" "ulid" NA     NA    
#> attr(,"candidates")
#> attr(,"candidates")[[1]]
#> [1] "uuid"
#> 
#> attr(,"candidates")[[2]]
#> [1] "ulid"
#> 
#> attr(,"candidates")[[3]]
#> [1] "ulid"   "typeid"
#> 
#> attr(,"candidates")[[4]]
#> character(0)
#> 
id_detect("01arz3ndektsv4rrffq69g5fav", hint = "typeid")
#> [1] "typeid"
#> attr(,"candidates")
#> attr(,"candidates")[[1]]
#> [1] "typeid"
#> 
id_detect("175928847299117063", layout = id_layout("discord"))
#> [1] "snowflake"
#> attr(,"candidates")
#> attr(,"candidates")[[1]]
#> [1] "snowflake"
#> 
```
