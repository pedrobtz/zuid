# Snowflake and SCRU64 layouts

A layout says how a 64-bit identifier splits into a time, node fields
and a sequence. It is data: the time field's bits, unit and epoch, the
node fields with their widths in order, the sequence width, and whether
the top bit is a sign bit. zuid cannot discover a Snowflake's layout
from the number, so its fields are readable only when the layout is
given.

## Usage

``` r
id_layout(
  name = NULL,
  epoch = NULL,
  node_bits = NULL,
  time = NULL,
  fields = NULL,
  sequence = NULL,
  sign_bit = TRUE
)

# S3 method for class 'zuid_layout'
print(x, ...)

# S3 method for class 'zuid_layout'
format(x, ...)
```

## Arguments

- name:

  A built-in layout, or `NULL` for a custom one.

- epoch:

  For `"sonyflake"` (required) or a custom layout, the time the time
  field counts from: a `POSIXct` or milliseconds since 1970.

- node_bits:

  For `"scru64"`, the node id's bits, 1 to 23.

- time:

  For a custom layout, `list(bits =, unit =, epoch =)`, `unit` one of
  `"ms"`, `"10ms"`, `"256ms"` and `"s"`.

- fields:

  For a custom layout, the node fields as a named list or vector of
  widths, most significant first.

- sequence:

  For a custom layout, the sequence's bits.

- sign_bit:

  For a custom layout, whether the top bit is reserved.

- x:

  A layout.

- ...:

  Unused.

## Value

A `zuid_layout`.

## Details

The built-in layouts:

|  |  |  |  |
|----|----|----|----|
| Name | Time | Node fields | Sequence |
| `twitter` | 41 bits, ms, from 2010-11-04T01:42:54.657Z | `datacenter` 5, `worker` 5 | 12 |
| `discord` | 42 bits, ms, from 2015-01-01 | `worker` 5, `process` 5 | 12 |
| `instagram` | 41 bits, ms, from 2011-08-24T21:07:01.721Z | `shard` 13 | 10 |
| `sonyflake` | 39 bits, 10 ms, from `epoch` | `machine` 16, after the sequence | 8 |
| `scru64` | 39 bits, 256 ms, from 1970 | `node` of `node_bits` | 24 − `node_bits` |

Twitter, Sonyflake and SCRU64 keep the top bit as a sign bit; Discord
and Instagram use all 64 bits. Sonyflake's reference has changed its
default start time between releases, so `epoch` is required for it.

A custom layout gives `time`, `fields`, `sequence` and `sign_bit`. The
bits must add up to 64, or 63 with the sign bit, and each part must have
fewer than 54 bits, so that it reads exactly as a double.

## Examples

``` r
id_layout("twitter")
#> <zuid_layout twitter>
#> | sign 1 | time 41 | datacenter 5 | worker 5 | sequence 12 |
#> time: ms units from 2010-11-04T01:42:54.657Z
id_layout("scru64", node_bits = 8)
#> <zuid_layout scru64>
#> | sign 1 | time 39 | node 8 | sequence 16 |
#> time: 256ms units from 1970-01-01T00:00:00.000Z
id_layout(
  time = list(bits = 41, unit = "ms", epoch = 0),
  fields = list(worker = 10),
  sequence = 12
)
#> <zuid_layout custom>
#> | sign 1 | time 41 | worker 10 | sequence 12 |
#> time: ms units from 1970-01-01T00:00:00.000Z
```
