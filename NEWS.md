# zuid 0.0.0.9000

* `id_parse()` and `id_valid()` read UUIDs in every RFC 9562 text form
  (canonical, compact, URN, braced, uppercase) and validate them at three
  levels: syntax, structure and strict.
* `id_fields()`, `id_time()` and `id_version()` read the version, variant,
  time, clock sequence, node and random bits of every UUID version.
* `id_format()`, `id_bytes()` and `id_from_bytes()` move between text forms
  and bytes; `id_from_bytes()` has no default format.
* `id_nil()`, `id_max()` and `id_formats()`.
* zuid vectors keep their class through subsetting, assignment, `c()`,
  `rep()`, `unique()` and data frames, compare by value, sort by bytes, and
  combine with vctrs when it is loaded.
* `zuid_info()` reports the package version and the generated tables compiled
  into it, the Niceware word list and the Sqids blocklist, with their pinned
  upstream sources.
