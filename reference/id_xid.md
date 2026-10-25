# Generate XIDs, ObjectIds and Snowflakes

`id_xid()` generates XIDs: seconds since 1970, a 3-byte machine id, a
2-byte process id and a 3-byte counter. The reference derives the
machine id from the host name through MD5; zuid draws three random bytes
once per session instead, and `machine` takes the reference's bytes when
they matter. The process id is R's, masked to 16 bits. The counter
starts at a random value once per session and increments, wrapping at
2^24.

## Usage

``` r
id_xid(
  n = 1,
  machine = NULL,
  process = Sys.getpid(),
  random = NULL,
  time = NULL
)

id_objectid(n = 1, random = NULL, time = NULL)

id_snowflake(
  n = 1,
  layout,
  worker,
  time = NULL,
  rollback = c("error", "reset")
)
```

## Arguments

- n:

  The number of UUIDs.

- machine:

  For `id_xid()`, three raw bytes, or `NULL` for the session's random
  ones.

- process:

  For `id_xid()`, the process id,
  [`Sys.getpid()`](https://rdrr.io/r/base/Sys.getpid.html) by default.

- random:

  `NULL`, or for reproducible values: 6 bytes for `id_xid()` (machine,
  then the counter's start) and 8 for `id_objectid()` (the random value,
  then the counter's start), used for this call only.

- time:

  `NULL` for the current time, or a `POSIXct` (or a double of
  milliseconds since 1970) of length 1 or `n`.

- layout:

  An
  [`id_layout()`](https://pedrobtz.github.io/zuid/reference/id_layout.md).

- worker:

  The node fields' values: one number when the layout has one node
  field, else a named list, such as `list(datacenter = 1, worker = 7)`.

- rollback:

  For `id_snowflake()`, what to do when the clock (or `time`) runs back
  further than the tolerance: `"error"` or `"reset"`.

## Value

A zuid vector of `n` values.

## Details

`id_objectid()` generates BSON ObjectIds: seconds, a 5-byte random value
drawn once per session, and a 3-byte counter started at a random value.

`id_snowflake()` generates Snowflakes under a layout. `worker` sets
every node field, since duplicate node ids across machines are what
Snowflake exists to prevent and only the caller can rule them out. The
sequence starts at zero each tick and increments within it; when it
overflows, generation moves to the next tick. One sequence serves every
node value of a layout, so values for different workers interleave
without repeats. A clock back by up to the option `zuid.clock_tolerance`
(seconds, 0.01 by default) keeps the last tick. Further back,
`rollback = "error"` raises `zuid_clock_error`, and `rollback = "reset"`
restarts the layout's generator at the new time, which may repeat values
made before.

## Examples

``` r
id_xid(2)
#> <zuid_xid[2]>
#> [1] dbekhi9g2vs1lhaolri0 dbekhi9g2vs1lhaolrig
id_objectid(2)
#> <zuid_objectid[2]>
#> [1] 6add48c97cff36c876100fd8 6add48c97cff36c876100fd9
id_snowflake(2, id_layout("twitter"), list(datacenter = 1, worker = 7))
#> <zuid_snowflake[2]>
#> [1] 2114147364985008128 2114147364985008129
```
