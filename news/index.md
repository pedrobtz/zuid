# Changelog

## zuid 0.0.0.9000

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
