# Generate ULIDs, TypeIDs and UPIDs

`ulid()` generates ULIDs: 48 bits of milliseconds and 80 random bits.
Values from one session strictly increase, by the specification's rule:
within a millisecond, the random component of the last value plus one.
That overflows only after 2^80 values in one millisecond, which is a
`zuid_overflow_error`.

## Usage

``` r
ulid(n = 1, random = NULL, time = NULL)

typeid(n = 1, prefix, random = NULL, time = NULL)

upid(n = 1, prefix, random = NULL, time = NULL)
```

## Arguments

- n:

  The number of UUIDs.

- random:

  `NULL` to draw from the operating system, or exactly the bytes needed:
  10 per value for ULIDs and TypeIDs, 8 for UPIDs.

- time:

  `NULL` for the current time, or a `POSIXct` (or a double of
  milliseconds since 1970) of length 1 or `n`.

- prefix:

  For `typeid()`, the type: up to 63 lowercase letters and underscores,
  starting and ending with a letter, or `""` for none. For `upid()`, one
  to four characters of `234567` and `a` to `z`, padded on the right
  with `z` as the reference pads it.

## Value

A zuid vector of `n` values.

## Details

`typeid()` generates TypeIDs: a version 7 UUID, as
[`uuid()`](https://pedrobtz.github.io/zuid/reference/uuid.md) makes it,
under `prefix`.

`upid()` generates UPIDs: 40 bits of time in 256 ms units, 64 random
bits, the prefix and the current version, as the reference does. UPIDs
are not monotonic within 256 ms.

Entropy comes from the operating system, never from R's random number
generator, and the clock rollback rule of
[`uuid()`](https://pedrobtz.github.io/zuid/reference/uuid.md) applies to
ULIDs. As there, a call given both `time` and `random` is a pure
function of its arguments.

## Examples

``` r
ulid(2)
#> <zuid_ulid[2]>
#> [1] 01M77J5TY9DA6BJHP1QHV2TXPC 01M77J5TY9DA6BJHP1QHV2TXPD
typeid(2, "user")
#> <zuid_typeid[2]>
#> [1] user_01m77j5tyaew49aejkevzrw5rd user_01m77j5tyaew4s26r7xyzswgzw
upid(2, "user")
#> <zuid_upid[2]>
#> [1] user_2akwycrfiyxjdaccqderfa user_2akwycrff6dmzd3xkomu4a
```
