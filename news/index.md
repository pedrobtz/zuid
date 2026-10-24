# Changelog

## zuid 0.0.0.9000

- XID, ObjectId and Snowflake: parsing, fields and
  [`id_xid()`](https://pedrobtz.github.io/zuid/reference/id_xid.md),
  [`id_objectid()`](https://pedrobtz.github.io/zuid/reference/id_xid.md)
  and
  [`id_snowflake()`](https://pedrobtz.github.io/zuid/reference/id_xid.md).
  [`id_layout()`](https://pedrobtz.github.io/zuid/reference/id_layout.md)
  gives the Twitter, Discord, Instagram, Sonyflake and SCRU64 layouts
  and builds custom ones; a Snowflake is read and generated only under a
  layout, which travels with the vector.
  [`id_convert()`](https://pedrobtz.github.io/zuid/reference/id_convert.md)
  moves between `xid` and `objectid`.
- SCRU128, SCRU64 and KSUID parse, validate and read their fields, and
  [`id_scru128()`](https://pedrobtz.github.io/zuid/reference/id_scru128.md),
  [`id_scru64()`](https://pedrobtz.github.io/zuid/reference/id_scru128.md)
  and
  [`id_ksuid()`](https://pedrobtz.github.io/zuid/reference/id_scru128.md)
  generate them. The SCRU generators follow their references: monotonic,
  with counter overflow moving the timestamp forward, and a clock
  rollback beyond the tolerance a `zuid_clock_error` unless
  `rollback = "reset"`.
- ULID, TypeID and UPID:
  [`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md),
  [`id_valid()`](https://pedrobtz.github.io/zuid/reference/id_parse.md),
  [`id_fields()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
  and the rest read them, and
  [`id_ulid()`](https://pedrobtz.github.io/zuid/reference/id_ulid.md),
  [`id_typeid()`](https://pedrobtz.github.io/zuid/reference/id_ulid.md)
  and
  [`id_upid()`](https://pedrobtz.github.io/zuid/reference/id_ulid.md)
  generate them. ULIDs from one session strictly increase, by the
  specification’s rule, with `zuid_overflow_error` when the random
  component would overflow.
- [`id_convert()`](https://pedrobtz.github.io/zuid/reference/id_convert.md)
  moves values between `uuid`, `ulid`, `typeid` and `upid`, keeping the
  bytes; other pairs are a `zuid_convert_error`.
- [`id_encode()`](https://pedrobtz.github.io/zuid/reference/id_encode.md)
  and
  [`id_decode()`](https://pedrobtz.github.io/zuid/reference/id_encode.md)
  write and read bytes of any length in hex, Crockford base32, RFC 4648
  base32 and base32hex, base36, base58, base62, base64url, the sortable
  base62 and base64 of the IETF draft, a caller’s alphabet (ShortUUID’s
  by default), Proquint and Niceware words. Each form writes what the
  mainstream Go and Python libraries write. Every encoding is also a
  UUID form in
  [`id_format()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
  and
  [`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md).
- [`id_uuid()`](https://pedrobtz.github.io/zuid/reference/id_uuid.md)
  generates UUID versions 1, 4, 6, 7 (the default) and 8 from the
  operating system’s entropy source, never R’s random number generator.
  Version 7 values from one session strictly increase, and `random` and
  `time` give reproducible output.
  [`zuid_info()`](https://pedrobtz.github.io/zuid/reference/zuid_info.md)
  reports the entropy source and the generator state.
- [`id_parse()`](https://pedrobtz.github.io/zuid/reference/id_parse.md)
  and
  [`id_valid()`](https://pedrobtz.github.io/zuid/reference/id_parse.md)
  read UUIDs in every RFC 9562 text form (canonical, compact, URN,
  braced, uppercase) and validate them at three levels: syntax,
  structure and strict.
- [`id_fields()`](https://pedrobtz.github.io/zuid/reference/id_fields.md),
  [`id_time()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
  and
  [`id_version()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
  read the version, variant, time, clock sequence, node and random bits
  of every UUID version.
- [`id_format()`](https://pedrobtz.github.io/zuid/reference/id_format.md),
  [`id_bytes()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
  and
  [`id_from_bytes()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
  move between text forms and bytes;
  [`id_from_bytes()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
  has no default format.
- [`id_nil()`](https://pedrobtz.github.io/zuid/reference/id_nil.md),
  [`id_max()`](https://pedrobtz.github.io/zuid/reference/id_nil.md) and
  [`id_formats()`](https://pedrobtz.github.io/zuid/reference/id_formats.md).
- zuid vectors keep their class through subsetting, assignment,
  [`c()`](https://rdrr.io/r/base/c.html),
  [`rep()`](https://rdrr.io/r/base/rep.html),
  [`unique()`](https://rdrr.io/r/base/unique.html) and data frames,
  compare by value, sort by bytes, and combine with vctrs when it is
  loaded.
- [`zuid_info()`](https://pedrobtz.github.io/zuid/reference/zuid_info.md)
  reports the package version and the generated tables compiled into it,
  the Niceware word list and the Sqids blocklist, with their pinned
  upstream sources.
