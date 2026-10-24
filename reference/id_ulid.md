# Generate ULIDs, TypeIDs and UPIDs

`id_ulid()` generates ULIDs: 48 bits of milliseconds and 80 random bits.
Values from one session strictly increase, by the specification's rule:
within a millisecond, the random component of the last value plus one.
That overflows only after 2^80 values in one millisecond, which is a
`zuid_overflow_error`.

## Usage

``` r
id_ulid(n = 1, random = NULL, time = NULL)

id_typeid(n = 1, prefix, random = NULL, time = NULL)

id_upid(n = 1, prefix, random = NULL, time = NULL)
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

  For `id_typeid()`, the type: up to 63 lowercase letters and
  underscores, starting and ending with a letter, or `""` for none. For
  `id_upid()`, one to four characters of `234567` and `a` to `z`, padded
  on the right with `z` as the reference pads it.

## Value

A zuid vector of `n` values.

## Details

`id_typeid()` generates TypeIDs: a version 7 UUID, as
[`id_uuid()`](https://pedrobtz.github.io/zuid/reference/id_uuid.md)
makes it, under `prefix`.

`id_upid()` generates UPIDs: 40 bits of time in 256 ms units, 64 random
bits, the prefix and the current version, as the reference does. UPIDs
are not monotonic within 256 ms.

Entropy comes from the operating system, never from R's random number
generator, and the clock rollback rule of
[`id_uuid()`](https://pedrobtz.github.io/zuid/reference/id_uuid.md)
applies to ULIDs.

## Examples

``` r
id_ulid(2)
#> <zuid_ulid[2]>
#> [1] 01M5PTVWGPNP5PZQ68TV968B7J 01M5PTVWGPNP5PZQ68TV968B7K
id_typeid(2, "user")
#> <zuid_typeid[2]>
#> [1] user_01m5ptvwgqek7v64ksq0hs6hg8 user_01m5ptvwgqek89bp7n9c8nmfm2
id_upid(2, "user")
#> <zuid_upid[2]>
#> [1] user_2akqvfjms5iuyazcgzrk6a user_2akqvfjmi6lonjplph3uha
```
