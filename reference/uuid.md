# Generate UUIDs

Generates `n` UUIDs of a version, version 7 by default, from the
operating system's entropy source and clock. R's random number generator
is never used, so [`set.seed()`](https://rdrr.io/r/base/Random.html)
does not change the result.

## Usage

``` r
uuid(
  n = 1,
  version = 7,
  namespace = NULL,
  name = NULL,
  node = NULL,
  random = NULL,
  time = NULL
)
```

## Arguments

- n:

  The number of UUIDs.

- version:

  1, 4, 6, 7 or 8.

- namespace, name:

  Reserved for the name-based versions 3 and 5.

- node:

  For versions 1 and 6, six raw bytes to use as the node instead of the
  session's random one.

- random:

  `NULL` to draw from the operating system, or exactly the bytes the
  version needs, for tests and reproducible fixtures (with `time`): 16
  per value for versions 4 and 8; 10 per value for version 7 (2 seed the
  counter at a new millisecond, 8 fill the 62 random bits); for versions
  1 and 6, 2 bytes of clock sequence and, without `node`, 6 bytes of
  node.

- time:

  `NULL` for the current time, or a `POSIXct` (or a double of
  milliseconds since 1970) of length 1 or `n`.

## Value

A zuid vector of `n` UUIDs.

## Details

- **Version 7** (the default): 48 bits of milliseconds, a 12-bit counter
  and 62 random bits. Values from one session strictly increase (RFC
  9562 section 6.2, method 1): within a millisecond the counter
  increments, and when it would overflow the millisecond advances by
  one.

- **Version 4**: 122 random bits.

- **Versions 1 and 6**: the time in 100 ns ticks, a 14-bit clock
  sequence and a 48-bit node. The clock sequence and node are random,
  drawn once per session, and the node has its multicast bit set so it
  is never mistaken for a hardware address (RFC 9562 section 6.10).
  Values from one session strictly increase in time.

- **Version 8**: the caller's 122 bits, through `random`.

A clock that runs back by up to the option `zuid.rollback_tolerance`
(seconds, 10 by default) keeps generation increasing from the last
value. A `time` that runs back is treated as the clock is, so within the
tolerance a version 7 value keeps the latest time so far. Further back,
version 7 restarts at the new time and versions 1 and 6 increment the
clock sequence. Values that would pass the last instant the time field
holds are a `zuid_overflow_error`.

With both `time` and `random` given, a call is a pure function of its
arguments: the same arguments give the same UUIDs, and the session's
monotonic state is neither used nor changed. Values within the call
still increase.

Versions 3 and 5 hash a name and are not generated yet; parsing them
works. Version 2 is not generated: RFC 9562 leaves it to DCE Security.

## Examples

``` r
uuid(3)
#> <zuid_uuid[3]>
#> [1] 01a1cf22-ec5d-72bb-9395-cefb5a3ee60a 01a1cf22-ec5d-72bc-bdd7-376be26a7367
#> [3] 01a1cf22-ec5d-72bd-b264-b9fc04101861
uuid(2, version = 4)
#> <zuid_uuid[2]>
#> [1] 6d3d2183-2e47-4b06-bfad-01c45c984e6d e3244f7c-2f08-43a3-add8-fec6284e55a4
uuid(version = 7, time = as.POSIXct("2022-02-22 19:22:22", tz = "UTC"))
#> <zuid_uuid[1]>
#> [1] 017f22e2-79b0-712b-a4bf-8d18983e64c1
```
