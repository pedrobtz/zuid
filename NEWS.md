# zuid 0.1.0

* Initial CRAN submission.
* A README and two articles, "Reading what an identifier knows" and "A UUID
  in every alphabet".
* `id_detect()` names each element's format, or `NA` with its candidates
  when the evidence does not settle it; only structured formats are tried
  without a `hint`. `id_parse(format = NULL)` detects one format for the
  whole vector, or raises `zuid_ambiguous_error` or `zuid_mixed_error`.
* NanoID, Cuid2, Sqids and CID parse and validate, and `id_nanoid()` and
  `id_sqids()` generate. `id_parse()` and `id_valid()` take `alphabet` and
  `min_length` for NanoID and Sqids, and the parameters travel with the
  vector. `id_fields()` reads a Sqid's numbers and a CID's version, codec,
  hash function and digest, and `id_bytes()` gives a CID's binary form.
* XID, ObjectId and Snowflake: parsing, fields and `id_xid()`,
  `id_objectid()` and `id_snowflake()`. `id_layout()` gives the Twitter,
  Discord, Instagram, Sonyflake and SCRU64 layouts and builds custom ones; a
  Snowflake is read and generated only under a layout, which travels with
  the vector. `id_convert()` moves between `xid` and `objectid`.
* SCRU128, SCRU64 and KSUID parse, validate and read their fields, and
  `id_scru128()`, `id_scru64()` and `id_ksuid()` generate them. The SCRU
  generators follow their references: monotonic, with counter overflow
  moving the timestamp forward, and a clock rollback beyond the tolerance a
  `zuid_clock_error` unless `rollback = "reset"`.
* ULID, TypeID and UPID: `id_parse()`, `id_valid()`, `id_fields()` and the
  rest read them, and `id_ulid()`, `id_typeid()` and `id_upid()` generate
  them. ULIDs from one session strictly increase, by the specification's
  rule, with `zuid_overflow_error` when the random component would overflow.
* `id_convert()` moves values between `uuid`, `ulid`, `typeid` and `upid`,
  keeping the bytes; other pairs are a `zuid_convert_error`.
* `id_encode()` and `id_decode()` write and read bytes of any length in
  hex, Crockford base32, RFC 4648 base32 and base32hex, base36, base58,
  base62, base64url, the sortable base62 and base64 of the IETF draft, a
  caller's alphabet (ShortUUID's by default), Proquint and Niceware words.
  Each form writes what the mainstream Go and Python libraries write. Every
  encoding is also a UUID form in `id_format()` and `id_parse()`.
* `id_uuid()` generates UUID versions 1, 4, 6, 7 (the default) and 8 from
  the operating system's entropy source, never R's random number generator.
  Version 7 values from one session strictly increase, and `random` and
  `time` give reproducible output. `zuid_info()` reports the entropy source
  and the generator state.
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
