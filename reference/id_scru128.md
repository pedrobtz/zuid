# Generate SCRU128, SCRU64 and KSUID values

`id_scru128()` generates SCRU128 IDs by the specification's generator:
48 bits of milliseconds, a 24-bit `counter_hi` renewed once a second, a
24-bit `counter_lo` renewed each millisecond and incremented within it,
and 32 random bits. Values from one session strictly increase; a counter
overflow moves the timestamp forward instead of waiting.

## Usage

``` r
id_scru128(n = 1, random = NULL, time = NULL, rollback = c("error", "reset"))

id_scru64(
  n = 1,
  node,
  node_bits,
  random = NULL,
  time = NULL,
  rollback = c("error", "reset")
)

id_ksuid(n = 1, random = NULL, time = NULL)
```

## Arguments

- n:

  The number of UUIDs.

- random:

  `NULL` to draw from the operating system, or exactly the bytes needed:
  10 per value for SCRU128 (4 of entropy, then the seeds of `counter_lo`
  and `counter_hi`), 3 per value for SCRU64 (the counter's seed) and 16
  per value for KSUID.

- time:

  `NULL` for the current time, or a `POSIXct` (or a double of
  milliseconds since 1970) of length 1 or `n`.

- rollback:

  What to do when the clock runs back further than the tolerance:
  `"error"` or `"reset"`.

- node, node_bits:

  The SCRU64 node id and its size in bits, 1 to 23; the counter gets the
  other `24 - node_bits` bits.

## Value

A zuid vector of `n` values.

## Details

`id_scru64()` generates SCRU64 IDs for one node, as the reference
generator does: 256 ms ticks, then `node` in `node_bits` bits, then a
counter renewed at each tick and incremented within it. `node` and
`node_bits` are required, since only the caller can know that no other
generator uses the same node.

`id_ksuid()` generates KSUIDs: seconds since 2014-05-13T16:53:20Z and
128 random bits. KSUIDs are not monotonic within a second.

A clock that runs back by up to the option `zuid.rollback_tolerance`
(seconds, 10 by default) keeps the last timestamp, as both SCRU
specifications recommend. Further back, `rollback = "error"` raises
`zuid_clock_error`, so that monotonicity is never silently lost, and
`rollback = "reset"` restarts the generator at the new time.

## Examples

``` r
id_scru128(2)
#> <zuid_scru128[2]>
#> [1] 03h3weu92q0flewzqp3zlhbhc 03h3weu92q0flewzqp62mdxtk
id_scru64(2, node = 42, node_bits = 8)
#> <zuid_scru64[2]>
#> [1] 0w4wpkstbfg8 0w4wpkstbfg9
id_ksuid(2)
#> <zuid_ksuid[2]>
#> [1] 3L8f41ARRee5MLrMQdGoXofYyFD 3L8f44rOtHfSsnoHOIuGHnYqwGD
```
