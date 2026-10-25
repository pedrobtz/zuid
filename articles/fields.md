# Reading what an identifier knows

``` r

library(zuid)
```

An identifier is a value with a structure. A version 7 UUID begins with
a millisecond time, a KSUID with a second count from its own epoch, and
a Snowflake packs a time, a node and a sequence into one 64-bit integer.
This article shows how zuid finds out which format a string is, how
strictly it checks it, and what it reads from it.

## Which format is it?

[`id_detect()`](https://pedrobtz.github.io/zuid/reference/id_detect.md)
tries the structured formats, those whose text proves its own format:
UUID, ULID, TypeID, UPID, SCRU128, SCRU64, KSUID, XID, ObjectId and CID.
It returns one format per element, or `NA`:

``` r

ids <- c(
  "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3",
  "01ARZ3NDEKTSV4RRFFQ69G5FAV",
  "01arz3ndektsv4rrffq69g5fav",
  "9m4e2mr0ui3e8a215n4g",
  "not an identifier"
)
found <- id_detect(ids)
as.vector(found)
#> [1] "uuid" "ulid" NA     "xid"  NA
```

`NA` means two different things, and the `candidates` attribute tells
them apart. The last string fits no format. The third fits two: a ULID
in lowercase, or a TypeID without a prefix. zuid does not pick one.

``` r

attr(found, "candidates")[3:5]
#> [[1]]
#> [1] "ulid"   "typeid"
#> 
#> [[2]]
#> [1] "xid"
#> 
#> [[3]]
#> character(0)
```

A `hint` restricts the formats tried. It settles an ambiguity, and it is
the only way to detect a format whose text proves nothing, such as a
NanoID, which is any string over its alphabet:

``` r

as.vector(id_detect("01arz3ndektsv4rrffq69g5fav", hint = "typeid"))
#> [1] "typeid"
as.vector(id_detect("V1StGXR8_Z5jdHi6B-myT", hint = "nanoid"))
#> [1] "nanoid"
```

[`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md)
without a `format` detects one format for the whole vector. When the
vector is ambiguous, or holds more than one format, it raises an error
rather than guess. The error’s class says which:

``` r

err <- tryCatch(id_parse(ids[3]), error = identity)
class(err)
#> [1] "zuid_ambiguous_error" "zuid_error"           "error"               
#> [4] "condition"
err$candidates
#> [[1]]
#> [1] "ulid"   "typeid"
```

## How strict?

[`id_valid()`](https://pedrobtz.github.io/zuid/reference/id_parse.md)
and
[`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md)
check at one of three levels, each including the one before:

- `"syntax"`: the alphabet, the length, the case and the separators.
- `"structure"`, the default: the value’s own rules. For a UUID, the
  variant bits.
- `"strict"`: the value is one its specification defines. For a UUID, a
  version from 1 to 8, and a time no later than now plus a tolerance.

The second UUID below has the wrong variant bits. It is well-formed
text, but it is not an RFC 9562 UUID:

``` r

x <- c(
  "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3",
  "018f6b1c-2d3e-7a4b-cc5d-6e7f8091a2b3"
)
id_valid(x, "uuid", level = "syntax")
#> [1] TRUE TRUE
id_valid(x, "uuid")
#> [1]  TRUE FALSE
```

Inspection never raises on input. Text that fails the level is `NA` in a
parsed vector, unless `strict = TRUE` asks for an error:

``` r

id_parse(c(x, "nope"), "uuid")
#> <zuid_uuid[3]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3 <NA>                                
#> [3] <NA>
err <- tryCatch(id_parse("nope", "uuid", strict = TRUE), error = identity)
class(err)
#> [1] "zuid_parse_error" "zuid_error"       "error"            "condition"
```

A UUID can arrive in other text forms. `form` names the one to read:

``` r

id_parse("{018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3}", "uuid", form = "braced")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
id_parse("urn:uuid:018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "uuid", form = "urn")
#> <zuid_uuid[1]>
#> [1] 018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3
```

## Fields

[`id_fields()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
returns a data frame with one row per element and the same columns for
every format. A column a format does not have is `NA`:

``` r

v1 <- id_parse("c232ab00-9414-11ec-b3c8-9f6bdeced846", "uuid")
id_fields(v1)[c("version", "time", "time_unit", "node", "sequence")]
#>   version                time time_unit         node sequence
#> 1       1 2022-02-22 19:22:22     100ns 9f6bdeced846    13256
```

A version 1 UUID records its time in 100-nanosecond ticks since 1582, a
node and a clock sequence. A version 7 records milliseconds since 1970
and random bits:

``` r

v7 <- id_parse("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "uuid")
id_fields(v7)[c("version", "time", "time_unit", "random")]
#>   version                time time_unit              random
#> 1       7 2024-05-12 04:42:39        ms 292cc5d6e7f8091a2b3
```

Other formats fill the columns they have. An XID has a machine, a
process and a counter; a TypeID has a prefix; a CID has a codec, a hash
function and a digest:

``` r

xid <- id_parse("9m4e2mr0ui3e8a215n4g", "xid")
id_fields(xid)[c("time", "node", "process", "sequence")]
#>                  time   node process sequence
#> 1 2011-03-22 17:50:19 60f486   58408  4271561

tid <- id_parse("user_01h455vb4pex5vsknk084sn02q", "typeid")
id_fields(tid)[c("prefix", "time", "version")]
#>   prefix                time version
#> 1   user 2023-06-30 03:34:18       7

cid <- id_parse(
  "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
  "cid"
)
id_fields(cid)[c("version", "codec", "hash")]
#>   version  codec     hash
#> 1       1 dag-pb sha2-256
```

[`id_formats()`](https://pedrobtz.github.io/zuid/reference/id_formats.md)
lists each format’s width, alphabet, time unit and epoch.

## Time

[`id_time()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
reads the creation time as a `POSIXct`, or as milliseconds since 1970
with `class = "ms"`. Each format has its own resolution and epoch, and
zuid converts from them:

``` r

id_time(v1)
#> [1] "2022-02-22 19:22:22 UTC"
id_time(id_parse("0ujtsYcgvSTl8PAuAdqWYSMnLOv", "ksuid"))
#> [1] "2017-10-10 04:00:47 UTC"
ms <- id_time(id_parse("01ARZ3NDEKTSV4RRFFQ69G5FAV", "ulid"), class = "ms")
format(ms, scientific = FALSE)
#> [1] "1469922850259"
```

A format with no time, such as a version 4 UUID or a NanoID, gives `NA`.

## Snowflakes need a layout

A Snowflake is a decimal integer whose bits each platform divides in its
own way, from its own epoch. The digits alone say nothing about which
platform made them, so zuid reads a Snowflake only under a layout.
[`id_layout()`](https://pedrobtz.github.io/zuid/reference/id_layout.md)
has Twitter’s, Discord’s, Instagram’s and Sonyflake’s, and builds custom
ones:

``` r

discord <- id_layout("discord")
discord
#> <zuid_layout discord>
#> | time 42 | worker 5 | process 5 | sequence 12 |
#> time: ms units from 2015-01-01T00:00:00.000Z
s <- id_parse("175928847299117063", "snowflake", layout = discord)
id_fields(s)[c("time", "node", "sequence")]
#>                  time               node sequence
#> 1 2016-04-30 11:18:25 worker=1,process=0        7
```

The layout travels with the vector, so
[`id_time()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
and
[`id_fields()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
need it only once. Under another layout the same digits give another
time:

``` r

id_time(s)
#> [1] "2016-04-30 11:18:25 UTC"
id_time(id_parse("175928847299117063", "snowflake", layout = id_layout("twitter")))
#> [1] "2012-03-03 13:01:20 UTC"
```
