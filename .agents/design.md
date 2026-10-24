# RFC 0043: `zuid`, UUIDs in full, their encodings and their kin

Adopted from [RFC 0043](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0043-zuid-identifiers-beyond-uuid.md)
on 2026-10-24. From here on this file is authoritative; the RFC is history.

- **Status:** Proposed. Merging this file adopts the design as the starting
  point for the package's own `.agents/design.md`; each decision in section
  13 stays the maintainer's until the package repository records it. The
  maintainer's two notes of 2026-10-24 set the direction: one inspection
  API across formats with explicit hints for ambiguous strings; Arrow and
  DuckDB interchange that keeps a ULID from being mistaken for a UUID; a
  complete UUID core with every version; the alternative text encodings of
  a UUID; the pronounceable and word encodings; and UPID, SCRU128, SCRU64
  and content identifiers. Password and passphrase generation was in the
  second note and the maintainer then set it aside for a later version
  (§14). Those decisions are marked **(M)**. Everything else is **(C)**,
  and D2 (text as the stored form), D5 (the OS entropy source) and D9
  (the `zuid.<format>` extension names) are the ones most worth a second
  look.
- **Date:** 2026-10-24.
- **Packages:** `zuid` (not yet created; `github.com/pedrobtz/zuid` and the
  CRAN mirror `github.com/cran/zuid` both returned 404 on 2026-10-24.
  crandb was unreachable from the session that wrote this, so §15 Q1 asks
  for the crandb check before the repository is created). No `Imports`.
  No `LinkingTo`. `Suggests: testthat, zuarrow, zuint, zucrypt, zutempo`.
  One shared object; vendors no code (D7); ships two generated tables,
  the Sqids blocklist and the Niceware word list (D8). MIT.
- **Source:** the maintainer's notes of 2026-10-24; RFC 9562 (UUIDs, May
  2024, which obsoletes RFC 4122 and defines versions 6, 7 and 8);
  `draft-davis-uuidrev-alt-uuid-encoding-methods-00` (April 2026), which
  lists the alternative UUID text encodings and the order-preserving
  Base62sort and Base64sort, and
  `draft-crockford-davis-base32-for-humans-01` (April 2026), the Crockford
  alphabet as a standards-track draft; both were read through search
  summaries only, so §15 Q2 pins them; the ULID specification
  (`ulid/spec`); the TypeID specification 0.3.0 (`jetify-com/typeid`,
  `spec/`, with its `valid.yml` and `invalid.yml` fixtures); UPID
  (`carderne/upid`, 40-bit 256 ms timestamp, 20-bit prefix, 64 random
  bits, 4 version bits, 26 lowercase base32 characters); SCRU128 and
  SCRU64 (`scru128/spec`, `scru64/spec`); Uuid25 (`uuid25/python`,
  Apache-2.0, 25 base36 characters); Segment's `ksuid` (`ksuid.go`, epoch
  `1400000000`, 20 bytes, 27 base62 characters); `rs/xid` (12 bytes,
  base32hex, 20 characters); the BSON specification's ObjectId; Twitter's
  Snowflake, Discord's and Instagram's layouts and Sony's Sonyflake
  (`sony/sonyflake`, 39 bits of 10 ms units, 8 bits of sequence, 16 bits
  of machine id; the library's default start time has changed between
  releases, which is why §6.8 makes the epoch explicit); `ai/nanoid`;
  `paralleldrive/cuid2`; `skorokithakis/shortuuid` (57-symbol alphabet,
  22 characters, most significant digit first since 1.0.0); the Sqids
  specification (`sqids/sqids-spec`) and blocklist
  (`sqids/sqids-blocklist`); Proquint (Daniel S. Wilkerson, arXiv
  0901.4016; `dsw/proquint`'s `proquint.c` for the tables
  `bdfghjklmnprstvz` and `aiou`); Niceware 4.0.0 (`diracdeltas/niceware`,
  MIT, a 2¹⁶-word list, two bytes per word); the CID specification
  (`multiformats/cid`); Arrow's canonical extension `arrow.uuid`
  (`FixedSizeBinary(16)`, big-endian, no metadata, no version
  guaranteed); the `duckdb-r` handbook's Arrow types page, which says a
  DuckDB `UUID` exports as a lowercase hyphenated string by default and as
  `arrow.uuid` under `arrow_lossless_conversion`; CRAN's `uuid` 1.2-2
  (Simon Urbanek, 2026-01-23), `ulid` 0.4.0 (Dirk Eddelbuettel,
  2024-06-04, Rcpp), `ids` 1.0.1 (Rich FitzJohn, 2017, with
  `ids::proquint()`) and `hashids`, read from the CRAN mirror on
  2026-10-24; this repository's RFC 0041 §6.6 and §6.10 (zuarrow's
  extension types and registry), RFC 0009 §4 (zuint's `uint128` and
  `int64`), RFC 0035 §4.1 (zutempo's instant), `zu-family-alignment.md`
  R1 to R10, and `archive/reviews/zu-family-review-2026-10-05.md` §8,
  which records that `zufast`'s design assigns UUID generation to
  `zurand`, which has no such function. Nothing has been built.

## 1. What zuid is

`zuid` is a complete UUID implementation for R with two rings around
it. The **core** is RFC 9562 in full: every version from 1 to 8, nil and
max, name-based generation, monotonic version 7, and every text form the
RFC names. The **first ring** is the alternative encodings of those same
128 bits: Crockford base32 (26 characters, the ULID alphabet), base36
(Uuid25, 25 characters), base58, base62 and base64url (22 characters),
the order-preserving Base62sort and Base64sort of the IETF draft, any
alphabet the caller supplies (ShortUUID), Proquint's pronounceable
quints, and Niceware's dictionary words. The **second ring** is the
identifier formats that grew up around UUIDs because they were too long,
too random or too anonymous: ULID, TypeID, UPID, SCRU128, SCRU64, KSUID,
Snowflake and Sonyflake, XID, MongoDB's ObjectId, NanoID, Cuid2, Sqids,
and content identifiers (CID). A third ring, passwords and passphrases
drawn from the same entropy and written in the same encodings, is
sketched in §14 and left for a later version.

For every format the same functions answer the same questions: is this
string one, which fields does it carry, when was it made, on which
machine, what are its bytes, and how does it look in another text form.
Where a format can be generated without a secret or a coordinator, it
generates it too.

The one-line statement that governs every decision below:

> **RFC 9562 in full; one vocabulary over every encoding and every kindred
> format; no dependency; and never a UUID by assumption.**

### 1.1 What zuid is not

- **Not a hashing package.** Name-based UUIDs (versions 3 and 5) and CID
  generation need MD5, SHA-1 and SHA-256, which `zucrypt` provides and
  `zuid` calls when it is installed (§6.6). Hashids needs the producer's
  salt and is a different kind of object (§2). HMAC-signed tokens, JWTs
  and session cookies are not identifiers in this sense.
- **Not a random number generator.** `zurand` is the family's engine for
  simulation. Identifiers need unpredictable bytes from outside the R
  session, not a reproducible stream (D5).
- **Not a password generator, yet.** A password or passphrase is fresh
  entropy, and re-encoding a public identifier does not make one; the
  functions that would draw fresh entropy for that purpose are a later
  version (§14), and `id_encode()` over bytes the caller drew is not
  offered as a substitute.
- **Not a database driver.** `zuid` converts identifier columns at the
  Arrow boundary (§6.9); moving tables is `zuarrow`'s and DuckDB's.
- **Not an opinion on which format to use.** The README has one paragraph
  on the trade-offs; the package treats every format as a first-class
  citizen.

### 1.2 Where it sits among existing packages

R has three identifier packages on CRAN and one encoding package:

| Package | Covers | Implementation |
| --- | --- | --- |
| `uuid` 1.2-2 | UUID generate, parse, validate; a class over raw | C, no deps |
| `ulid` 0.4.0 | ULID generate; `unmarshal()` to a timestamp | Rcpp |
| `ids` 1.0.1 | random hex, adjective-animal, `proquint()` | R, `openssl` |
| `hashids` | Hashids encode and decode | R |

`uuid` generates time-based, random and name-based UUIDs and can emit raw
bytes, but reads no fields back from a version 7 and has no text form
beyond hex. `ids::proquint()` is the one pronounceable encoding on CRAN
and converts to and from integers. No CRAN package re-encodes a UUID in
base32, base36, base62 or base64; a user who wants what Python's
`shortuuid` does writes a twenty-line encoder over `uuid`'s raw output.
None of the four reads the fields of a KSUID, an XID, an ObjectId or a
Snowflake; none knows TypeID, UPID, SCRU128, NanoID, Cuid2, Sqids or CID;
none detects a format; and each represents its one format its own way.
Outside R, every language has one library per format, and the libraries
disagree on small things (the digit order of ShortUUID before and after
1.0.0, the start time of Sonyflake) that an inspection tool must make
explicit rather than assume.

`zuid`'s claim: all of these in one package with no `Imports`, one
vectorised C loop per operation, one result shape for the fields of any
format, every encoding over the same bytes, and Arrow interchange that
round-trips every format exactly.

## 2. Scope

**In v0.1.0:**

- **The UUID core** (§6.1): versions 1 to 8, nil and max; parse and
  format in every RFC 9562 text form; fields and time per version;
  monotonic version 7; name-based versions through `zucrypt`.
- **Encodings** (§6.5): `id_encode()` and `id_decode()` over bytes of any
  even length, with UUID forms as the 16-byte case: hex forms, Crockford
  base32, RFC 4648 base32 and base32hex, base36, base58btc, base62,
  base64url, Base62sort and Base64sort, any alphabet, Proquint, Niceware
  words.
- **Fourteen kindred formats** (§6.1): ULID, TypeID, UPID, SCRU128,
  SCRU64, KSUID, Snowflake and Sonyflake under a layout, XID, ObjectId,
  NanoID, Cuid2, Sqids, CID.
- **Detection with hints** (§6.2): `id_detect()` and the `format`
  argument of `id_parse()`.
- **Parsing and validation at three levels** (§6.3): syntax, structure,
  strict.
- **Fields and time** (§6.4): `id_fields()`, `id_time()`, with each
  format's time resolution and epoch made explicit.
- **Generation** (§6.6) for every format that needs no secret or
  coordinator, and **monotonic generation** (§6.7) where defined.
- **Snowflake layouts** (§6.8): four built in, custom ones as data.
- **Arrow and DuckDB interchange** (§6.9) through `zuarrow`'s registry.
- A README and two articles, "Reading what an identifier knows" and
  "A UUID in every alphabet".

**Not in v0.1.0, and why:**

- **Hashids.** Decoding needs the producer's salt, so inspection yields
  nothing without it, and the same authors superseded it with Sqids. The
  CRAN `hashids` package covers the encoding. A later version may add it
  behind the Sqids interface (§14).
- **Cuid2 generation.** The reference needs SHA3-512 and a host
  fingerprint, and the family has no SHA-3 yet. Validation is in (§6.1);
  generation waits on a Keccak in `zucrypt` or here (§14).
- **Readable sentences.** The Go `readable` idea (a UUID as a grammatical
  sentence and back) needs part-of-speech word lists and a grammar; its
  short form keeps only 32 bits. Niceware's eight words cover the "say it
  aloud" need; sentences are §14.
- **Passwords and passphrases.** The maintainer set them aside for a
  later version so that v0.1.0 is identifiers only. The design they would
  follow is sketched in §14, so that the encodings of §6.5 are built with
  it in mind.
- **A C API.** `zucbor` (tag 37), `zumsgpack`, `qio` (Parquet's UUID
  logical type) and `zuarrow` would call `zid_parse()` from C. The
  header follows once the R surface has settled (§14).
- **Hashes without `zucrypt`.** MD5, SHA-1 and SHA-256 are not
  reimplemented here (D7).
- **Registration with the `arrow` and `nanoarrow` packages.** The family
  registry is `zuarrow`'s; the others are §14.
- **Base R RNG reproducibility.** There is no `set.seed()` path (D5); tests
  pass bytes in (§6.6).

## 3. Position in the `zu*` family

| | zuid |
| --- | --- |
| Role | R API; later a provider (§14) |
| R prefix | `id_` |
| Info function | `zuid_info()` |
| Root condition class | `zuid_error` |
| Internal C prefix | `zuid_` |
| Public C prefix | `zid_` (reserved; §14) |
| From C | no (§14) |
| Hides symbols | yes (R3) |
| Vendored code | none (D7); two generated tables (D8) |
| `Depends: R` | 4.1 (R2) |
| Language | en-GB (R2) |

**Relationships:**

- **`zuarrow`** (RFC 0041): `Suggests`. `zuid` registers its formats in
  `zuarrow`'s registry in `.onLoad()` when `zuarrow` is installed (§6.9),
  the pattern RFC 0041 §6.10 defines for `zuint`, `decimal` and
  `zutempo`.
- **`zuint`** (RFC 0009): `Suggests`. `id_integer()` returns a `uint128`
  for 128-bit formats and an `int64` for Snowflake and SCRU64, because
  both exceed 2⁵³ and must never become a double (§6.5). Without `zuint`
  the function errors; nothing else needs it.
- **`zucrypt`**: `Suggests`. MD5 and SHA-1 through `crypt_hash()` for
  UUID versions 3 and 5, SHA-256 for CID generation (§6.6).
- **`zutempo`** (RFC 0035): `Suggests`. `id_time(x, class = "zutempo")`
  returns an instant with exact nanoseconds, which matters for UUID
  versions 1 and 6 (100 ns ticks) and is the only exact form of those.
- **`zurand`**: not used. This RFC takes UUID generation, which `zufast`'s
  design had assigned to `zurand` (`zu-family-review-2026-10-05.md` §8).
  The one-line edit to `zufast`'s design that records the move is in
  §11 Stage 0.
- **`zucbor`, `zumsgpack`, `qio`, `zujson`**: consumers. CBOR tag 37 is a
  binary UUID; Parquet has a `UUID` logical type over 16 bytes; JSON
  carries identifiers as strings. Each parses or formats through `zuid`
  rather than by hand once §14's header exists; before that, through the
  R functions.
- **`mdbx`, `dastash`, `zudedup`, `openlineage`**: consumers. Sortable
  identifiers as keys (`mdbx`), artifact and content identifiers
  (`dastash`, `zudedup`), run identifiers that must be UUIDs
  (`openlineage`).

## 4. Architecture

Five layers:

1. **Format descriptors** (`src/zuid_formats.c`, `src/zuid_formats.h`).
   One static record per format: name, class (structured, encoding,
   syntactic; §6.2), byte width (or 0 for variable), text alphabet and
   length, case rule, canonicalisation, the field layout as a list of
   `{name, bit offset, bit width, kind}` entries where `kind` is one of
   time, node, process, sequence, random, version, variant, prefix,
   payload, codec, digest, and the time entry's unit and epoch. Snowflake
   layouts and SCRU64 node sizes are descriptors built at run time from
   `id_layout()` (§6.8), so built-in and custom cases share every code
   path. The descriptor table is also emitted as `R/sysdata.rda` so
   `id_formats()` and the descriptors never drift.
2. **Encodings** (`src/zuid_enc_*.c`). One codec per form of §6.5, each a
   pure function from bytes to text and back over a caller-supplied
   buffer: power-of-two alphabets by bit slicing; base36, base58 and
   base62 by limb division over 32-bit limbs; Proquint by 16-bit quints;
   Niceware by 16-bit indices into the word table; the Sqids algorithm;
   NanoID's mask-and-step uniform selection. The codecs compile as C11
   without R under `ZUID_STANDALONE`, which is how the fuzz target builds
   them.
3. **Formats** (`src/zuid_fmt_*.c`). Per-format parse, validate and
   field extraction over the descriptor, calling layer 2 for the text.
4. **Generators** (`src/zuid_gen.c`). One function per format taking
   `(count, time_ms, random bytes, node fields)` and writing bytes; the
   clock (`clock_gettime(CLOCK_REALTIME)`, or
   `GetSystemTimePreciseAsFileTime` on Windows) and the entropy source
   (`getrandom(2)`, `getentropy(3)`, `arc4random_buf`, or
   `BCryptGenRandom`) are supplied by the R entry point, never read inside
   a generator, so tests and the fuzz target pass fixed inputs (D5, D6).
   Per-session state for monotonic generation (last millisecond,
   counters, sequence; §6.7) lives in one static struct behind the R
   entry points, which R's single thread serialises.
5. **The R surface** (`R/`). Vectorisation happens in C: one loop per
   operation over a character or raw input, filling parallel output
   vectors that R assembles into a `zuid` vector or a data frame once.
   The only place a `CHARSXP` is made from bytes is one function in
   `src/zuid_r.c`.

## 5. Public R API (v0.1.0 shape)

```r
# detection and parsing
id_detect(x, hint = NULL, layout = NULL)
#   one format per element; NA when none or ambiguous
id_parse(x, format = NULL, form = NULL, layout = NULL,
         level = c("structure", "syntax", "strict"), strict = FALSE)
id_valid(x, format, form = NULL, layout = NULL, level = "structure")
#   logical; never errors
id_formats()
#   the descriptor table as a data frame

# fields and time
id_fields(x)
#   one row per element, the columns of section 6.4
id_time(x, class = c("POSIXct", "ms", "zutempo"))
id_version(x)
#   UUID version, through TypeID, UPID and the encodings too

# text and bytes
id_format(x, form = NULL)
#   canonical text, or an alternative form (section 6.5)
id_encode(bytes, form, alphabet = NULL, sep = "-")
id_decode(text, form, alphabet = NULL, width = NULL)
#   any bytes, any form; UUID forms are the 16-byte case
id_bytes(x)
#   raw matrix: width rows, one column per element
id_from_bytes(bytes, format, layout = NULL)
#   format is required
id_integer(x)
#   zuint uint128 or int64; needs zuint
id_convert(x, to, ...)
#   uuid <-> typeid <-> upid; xid <-> objectid; ulid <-> uuid

# generation
id_uuid(n = 1, version = 7, namespace = NULL, name = NULL,
        node = NULL, random = NULL, time = NULL)
id_ulid(n = 1, random = NULL, time = NULL)
id_typeid(n = 1, prefix, random = NULL, time = NULL)
id_upid(n = 1, prefix, random = NULL, time = NULL)
id_scru128(n = 1, random = NULL, time = NULL)
id_scru64(n = 1, node, node_bits, time = NULL)
id_ksuid(n = 1, random = NULL, time = NULL)
id_xid(n = 1, machine = NULL, process = NULL, time = NULL)
id_objectid(n = 1, process = NULL, time = NULL)
id_snowflake(n = 1, layout, worker, time = NULL)
id_nanoid(n = 1, size = 21, alphabet = NULL, random = NULL)
id_cid(x, codec = "raw", hash = "sha2-256", version = 1L)
#   content identifier of bytes or files; needs zucrypt
id_sqids(numbers, alphabet = NULL, min_length = 0, blocklist = NULL)
id_nil()
id_max()

# layouts
id_layout(name, epoch = NULL)
#   "twitter", "discord", "instagram", "sonyflake"
id_layout(time = list(bits, unit, epoch), fields = list(...),
          sequence, sign_bit = TRUE)

# the vector class: `[`, `[<-`, c(), rep(), unique(), ==, sort(),
# xtfrm(), format(), print(), as.character(), is.na(),
# as.data.frame(), and vctrs methods when vctrs is loaded
zuid_info()
```

### Results

`id_parse()` returns a `zuid` vector: a character vector of canonical text
(D2) with class `c("zuid_<format>", "zuid")` and attributes `format`
(one string) and, for Snowflake and SCRU64, `layout`. One vector holds
one format. `id_fields()` and `id_detect()` return plain vectors and data
frames. Parsing failures are `NA` elements, never errors, unless the
caller passes `strict = TRUE` to `id_parse()`; see §6.3.

## 6. Semantics

### 6.1 The formats

| Format | Width | Canonical text | Class (§6.2) |
| --- | --- | --- | --- |
| `uuid` | 128 bits | 36 hex with hyphens | structured |
| `ulid` | 128 bits | 26 Crockford base32 | structured |
| `typeid` | 128 bits + prefix | `prefix_` + 26 Crockford | structured |
| `upid` | 128 bits | 4 prefix + `_` + 22 base32 | structured |
| `scru128` | 128 bits | 25 base36 | structured |
| `scru64` | 64 bits | 12 base36 | structured |
| `ksuid` | 160 bits | 27 base62 | structured |
| `snowflake` | 64 bits | 1 to 20 decimal digits | structured |
| `xid` | 96 bits | 20 base32hex | structured |
| `objectid` | 96 bits | 24 hex | structured |
| `cid` | variable | multibase text | structured |
| `nanoid` | variable | 21 of `A-Za-z0-9_-` | syntactic |
| `cuid2` | variable | 2 to 32 base36, 24 by default | syntactic |
| `sqids` | variable | 1 to 255 of a 62-symbol alphabet | encoding |

What each carries, and what `id_fields()` can therefore read:

- **`uuid`.** Version and variant for every value. Versions 1 and 6: a
  60-bit time in 100 ns ticks from 1582-10-15, a 14-bit clock sequence
  and a 48-bit node. Version 7: 48 bits of milliseconds and 74 random
  bits, 12 of which may be a counter. Version 4: 122 random bits.
  Versions 3 and 5: hash bits. Version 8: 122 custom bits. Nil and max
  are recognised. Lowercase hyphenated is canonical; the RFC's other
  forms and every encoding of §6.5 are accepted with `form`.
- **`ulid`.** 48 bits of milliseconds and 80 random bits. Uppercase is
  canonical, input is case-insensitive, and the first character is `0`
  to `7` so the 26 characters fit 128 bits.
- **`typeid`.** A prefix matching `^([a-z]([a-z_]{0,61}[a-z])?)?$`, an
  underscore omitted when the prefix is empty, and 26 lowercase Crockford
  characters holding a UUID: version 7 when generated, any version
  accepted on input. 26 to 90 characters. Fields: the prefix, the UUID
  and the UUID's fields. The prefix lives outside the 128 bits.
- **`upid`.** 40 bits of time in 256 ms units, a 20-bit prefix of up to
  four base32 characters right-padded, 64 random bits and a 4-bit
  version, all inside the 128 bits, so the prefix survives in the binary
  form, which is what sets it apart from TypeID. Text is the prefix, an
  underscore and 22 lowercase base32 characters; case is significant.
  Fields: prefix, time at 256 ms, random, version.
- **`scru128`.** 48 bits of milliseconds, a 24-bit `counter_hi` renewed
  about once a second, a 24-bit `counter_lo` reset each millisecond, and
  32 bits of entropy. 25 base36 characters, lowercase on output,
  case-insensitive on input, maximum `f5lxx1zz5pnorynqglhzmsp33`.
  Timestamps 0 and 2⁴⁸ − 1 are reserved and fail `structure`.
- **`scru64`.** Time in 256 ms units in the upper bits and a 24-bit tail
  split into a node id of `node_bits` (1 to 23) and a counter. 12 base36
  characters, below 2⁶³ so it fits a signed 64-bit integer. The split is
  a layout (§6.8), given as `node_bits` or a hint.
- **`ksuid`.** 32 bits of seconds since `1400000000`
  (2014-05-13T16:53:20Z) and 128 random bits. Base62 over `0-9A-Za-z`
  preserves order; the maximum is `aWgEPTl1tmebfsQzFP4bxwgy80V`.
- **`snowflake`.** Time at the layout's unit and epoch, the layout's
  node fields (worker, datacenter, machine, shard) and a sequence. A
  layout is required (§6.8).
- **`xid`.** 32 bits of seconds since 1970, a 24-bit machine id, a 16-bit
  process id and a 24-bit counter, in lowercase base32hex (`0-9a-v`).
- **`objectid`.** 32 bits of seconds since 1970, a 40-bit per-process
  random value and a 24-bit counter, in lowercase hex. The current BSON
  specification makes the middle bytes random, not a machine id and a
  process id, so `id_fields()` names them `random`, never `node`. XID's
  bytes are laid out identically, and `id_convert(x, "objectid")`
  reinterprets an XID without touching them.
- **`cid`.** A content identifier: version 0 is a bare multihash
  (`0x12 0x20` and a 32-byte SHA-256 digest, 46 base58btc characters
  starting `Qm`); version 1 is a varint version, a multicodec varint for
  the content type, and a multihash (function code varint, digest length
  varint, digest), written with a multibase prefix character, lowercase
  base32 (`b…`) being the common form. Fields: version, codec, hash
  function, digest length, digest as hex, multibase. The same content
  under the same settings gives the same CID, so it is the one format
  here that identifies content rather than an event.
- **`nanoid`.** No fields. Any alphabet of 1 to 256 symbols and any size
  are accepted with a hint.
- **`cuid2`.** No fields. Time is hashed in and not recoverable. The first
  character is a letter.
- **`sqids`.** The non-negative integers encoded: doubles when all are
  below 2⁵³, `zuint` `uint64` otherwise. Alphabet and `min_length` are
  accepted with a hint; the blocklist is checked.

ShortUUID is not a format here but a `form` of a UUID (§6.5): the same
bits in another alphabet.

### 6.2 Detection and hints

Formats fall into three classes, and detection treats them differently:

- **Structured** formats carry fields with their own ranges and a fixed
  grammar: `uuid`, `ulid`, `typeid`, `upid`, `scru128`, `scru64`,
  `ksuid`, `xid`, `objectid`, `snowflake`, `cid`. A string that passes a
  structured format's structure check (§6.3) is evidence for that format.
- **Encodings** re-express a value another format or an integer already
  has: every `form` of §6.5, and `sqids`. Their alphabets are
  parameters, so any string over the alphabet decodes to something.
- **Syntactic** formats are an alphabet and a length: `nanoid`, `cuid2`.
  Any string over the alphabet matches.

`id_detect(x, hint = NULL, layout = NULL)` returns one format per
element, or `NA`, with the attribute `candidates`, a list of the formats
each element passes at the structure level, structured ones first. The
rules:

1. Only a structured format is ever chosen without a hint, because an
   encoding or a syntactic format matches any string over its alphabet
   and would claim everything. A UUID in Crockford base32 is textually a
   ULID, and a UUID in base36 is textually a SCRU128; the structured
   format wins, and `id_parse(x, "uuid", form = "base32")` is how a
   caller who knows better says so.
2. When exactly one structured format passes, it is the answer.
3. When several pass, the answer is `NA` and `candidates` lists them. The
   known collisions: a 26-character lowercase Crockford string is a ULID
   or a prefix-less TypeID (uppercase or mixed case resolves to ULID,
   since TypeID is lowercase only); a 20-character hex string is an XID
   whose characters happen to be hex, and also 20 digits of a Snowflake
   when the layout is given; a 27-character alphanumeric string is a
   KSUID or a NanoID of that length; a 12-character base36 string is a
   SCRU64 or a NanoID of that length, and SCRU64 is chosen only with a
   layout. A decimal string of 1 to 20 digits is a Snowflake only when
   `layout` is supplied, because every layout reads it differently and
   without one there is nothing to check. A CID is never ambiguous: its
   multibase prefix and varints either verify or do not.
4. `hint` restricts the candidates to the formats named, so
   `hint = "ulid"` resolves the first collision and `hint = "nanoid"`
   admits a syntactic format. With a hint of one format, `id_detect()` is
   `id_valid()` in another shape.

`id_parse(x, format = NULL)` calls `id_detect()` when `format` is `NULL`
and requires every non-missing element to resolve to the same format;
otherwise it raises `zuid_ambiguous_error` naming the candidates, or
`zuid_mixed_error` naming the formats found. A vector of one format is
what a column is, and mixed columns are a finding the caller should see,
not a vector `zuid` silently makes.

### 6.3 Validation levels

- **`syntax`**: alphabet, length, case rule, hyphen positions, TypeID and
  UPID prefix grammar, a CID's multibase prefix.
- **`structure`**: `syntax`, then: Crockford strings fit 128 bits (first
  character `0` to `7`); UUID variant bits are `10` for versions 1 to 8
  (nil and max exempt); a KSUID is at or below its maximum; a SCRU128 is
  at or below its maximum with a non-reserved timestamp; a Snowflake or
  SCRU64 fits the layout's bits with the sign bit clear; a Sqids string
  passes the blocklist and decodes to a canonical re-encoding; a CID's
  varints decode, its digest length matches its hash function, and a
  version 0 is exactly SHA-256 over dag-pb.
- **`strict`**: `structure`, then: a UUID's version is one RFC 9562
  defines (1 to 8, nil, max); a UPID's version nibble is the current one;
  a time field lies between the format's epoch and the current time plus
  a tolerance (one day by default, the option `zuid.time_tolerance`); a
  Cuid2 starts with a letter.

`id_parse()` runs `structure` by default (D4). `id_valid(x, format,
level)` is the vectorised predicate and never errors. The levels are
cumulative and named by the kind of evidence, as `zumime`'s confidence
levels are (RFC 0040 D3), so a caller can say what "valid" meant.

### 6.4 Fields and time

`id_fields(x)` returns a data frame with one row per element and these
columns, `NA` where the format has no such field:

| Column | Type | Meaning |
| --- | --- | --- |
| `format` | character | the vector's format |
| `time` | POSIXct | the time field at the format's unit and epoch |
| `time_unit` | character | `100ns`, `ms`, `10ms`, `256ms`, `s`, or `NA` |
| `version` | integer | UUID or UPID version, also through TypeID |
| `variant` | character | `rfc`, `ncs`, `microsoft`, `future`, or `NA` |
| `node` | character | hex of the node, machine or worker field |
| `process` | integer | XID's process id |
| `sequence` | integer | counter or sequence field |
| `random` | character | hex of the random bits |
| `prefix` | character | TypeID or UPID prefix |
| `codec` | character | CID content type, by multicodec name |
| `hash` | character | CID hash function, by multicodec name |
| `digest` | character | CID digest as hex |
| `numbers` | list | Sqids' integers |

For a Snowflake, `node` holds the layout's node fields joined as
`name=value` pairs, since a layout may have two. For a SCRU128,
`sequence` holds `counter_lo` and `node` holds `counter_hi`, each
documented as such; the two counters are not a node, but the column is
where a reader of the layout looks for the second field.

`id_time(x, class)` returns the `time` column alone: `POSIXct` by default,
exact for every format whose unit is a millisecond or coarser (the
largest millisecond count, 2⁴⁸ − 1, is below 2⁵³); `"ms"` for the
integral double of milliseconds since 1970 with the sub-millisecond part
dropped; `"zutempo"` for an instant with exact nanoseconds, which is the
only exact form for the 100 ns ticks of UUID versions 1 and 6, and
errors with `zuid_dependency_error` when `zutempo` is absent. A field a
format lacks is `NA`, never zero: NanoID, Cuid2 and CID have no time,
and the documentation says so where a user might hope otherwise.

### 6.5 Text, encodings and bytes

Every format has one **canonical text**, which is what a `zuid` vector
stores (D2) and what `format()`, `print()` and `as.character()` emit:
lowercase hyphenated UUID (RFC 9562 §4 says to emit lowercase and accept
either case); uppercase ULID; lowercase TypeID and UPID with their
prefixes; lowercase SCRU128 and SCRU64; lowercase XID and ObjectId;
KSUID, NanoID, Cuid2 and Sqids as given, since each is case-sensitive;
a CID in the multibase it arrived in; Snowflake as decimal without
padding.

**Forms.** `id_encode(bytes, form)` writes bytes of any even length in a
form, and `id_decode(text, form)` reads them back; `id_format(x, form)`
is `id_encode()` over `id_bytes(x)`, and `id_parse(x, format, form)` is
the reverse. The forms, with their output for 16 bytes:

| Form | Alphabet | 16 bytes | Order-preserving |
| --- | --- | --- | --- |
| `hex` | `0-9a-f`, hyphenated | 36 | yes |
| `compact` | `0-9a-f` | 32 | yes |
| `urn`, `braced`, `uppercase` | RFC 9562 variants | 45, 38, 36 | yes |
| `base32` | Crockford, `0-7` first | 26 | yes |
| `base32rfc`, `base32hex` | RFC 4648, no padding | 26 | hex only |
| `base36` | `0-9a-z`, Uuid25 | 25 | yes |
| `base58` | base58btc | 22 | no |
| `base62` | `0-9A-Za-z` | 22 | yes |
| `base64url` | RFC 4648 §5, no padding | 22 | no |
| `base62sort`, `base64sort` | the IETF draft's sorted alphabets | 22 | yes |
| `alphabet` | caller's; ShortUUID's 57 symbols by default | varies | yes |
| `proquint` | `bdfghjklmnprstvz`, `aiou` | 8 quints, 47 | yes |
| `words` | Niceware, 2¹⁶ words | 8 words | no |

Rules the table compresses:

- Power-of-two alphabets slice bits left to right, with zero bits
  prepended so the first character carries the remainder, which is why a
  Crockford or RFC 4648 base32 string of a 128-bit value starts `0` to
  `7` and the 130-bit TypeID and ULID rule falls out of the same code.
- Base36, base58 and base62 treat the bytes as one big-endian integer and
  write it most significant digit first, zero-padded to the fixed width
  for the byte count, so `base36` of 16 bytes is Uuid25 and `base62` is
  what `uuid-base62` and `uuid62` emit. `alphabet` is the same with the
  caller's symbols, most significant digit first; `legacy = TRUE`
  reverses the digits for strings made by Python `shortuuid` before
  1.0.0. A 26-letter alphabet gives 28 characters for 16 bytes, which is
  the maintainer's example.
- `base62sort` and `base64sort` are the IETF draft's order-preserving
  variants: fixed width, an alphabet in ASCII order, and the value padded
  with leading zero bits so that two encoded strings compare as their
  UUIDs do, which makes a version 7 UUID sort chronologically in any
  text column. The draft's exact post-processing is pinned in Stage 3
  (§15 Q2).
- `proquint` writes each 16-bit unit as consonant, vowel, consonant,
  vowel, consonant from the tables above (4, 2, 4, 2 and 4 bits, most
  significant first), quints joined by `sep`, `-` by default. Decoding
  ignores the separator and case.
- `words` writes each 16-bit unit as the Niceware word at that index,
  joined by `sep`; decoding looks words up case-insensitively and fails
  on a word not in the list. The list is MIT and ships as a generated
  table (D8); the reference warns it has not been checked for offensive
  words, and the documentation repeats the warning.
- Odd byte counts are `zuid_type_error` for `proquint` and `words`,
  whose unit is two bytes; the other forms take any length.

`id_bytes(x)` returns a raw matrix with the format's width in rows and
one column per element, big-endian in every field, `NA` elements as
columns of `00` with a `na` attribute naming them; for the
variable-width `cid` it returns a list of raw vectors. `id_from_bytes(
bytes, format, layout)` reverses it from a raw matrix, a list of raw
vectors or one raw vector of width × n bytes, and **`format` has no
default**: a 16-byte buffer is not a UUID until someone says so (D3,
**M**). For `"snowflake"` and `"scru64"` the layout is required too.

`id_integer(x)` returns the value as a `zuint` vector: `uint128` for the
128-bit formats, `int64` for Snowflake and SCRU64, a list of `uint64` for
Sqids; it errors without `zuint` rather than returning a double, because
a double would be wrong above 2⁵³ and silently so.

`id_convert(x, to)` moves between formats that carry the same value:
`uuid` to `typeid` (with `prefix`), `typeid` to `uuid` (dropping the
prefix), `upid` to `uuid` (the reference's own conversion, keeping the
bits), `xid` to and from `objectid` (same bytes). `ulid` to `uuid` and
back are bit reinterpretations and are allowed, with `id_fields()`
reporting whatever the bits say (`variant = "future"` for most ULIDs)
and the documentation stating that a ULID's time field will read a
UUID's first 48 bits as milliseconds, which is meaningful for version 7
and nonsense for the rest. Conversions that would need a value the
source lacks (`ksuid` to `uuid`, a Snowflake to anything, anything to
`cid`) are `zuid_convert_error`. Changing a UUID's text form is
`id_format()`, not a conversion.

Comparison and sorting are on bytes, in C, through `xtfrm()`, so
`sort()` on a `zuid_snowflake` vector is numeric and on a `zuid_ulid`
vector is chronological regardless of the canonical text's lexicographic
order.

### 6.6 Generation

Every generator is a pure function of its inputs: `n`, the time, the
random bytes, and the node fields (D6). The R entry point supplies the
clock and the entropy when `time` and `random` are `NULL`, which is the
normal call; a test, a fixture or a caller who has their own entropy
passes them in. `time` is a `POSIXct` or millisecond double recycled to
`n`; `random` is a raw vector of exactly the bytes the format needs for
`n` values, and the wrong length is `zuid_type_error`.

- **UUID.** `version = 7` by default (D11): 48 bits of milliseconds, a
  12-bit counter in `rand_a` (§6.7), 62 random bits in `rand_b`.
  `version = 4`: 122 random bits. `version = 1` and `6`: 60-bit time in
  100 ns ticks, a 14-bit clock sequence initialised randomly per
  session and incremented when the clock runs backwards, and a 48-bit
  node that is random with the multicast bit set unless `node` gives six
  bytes (RFC 9562 §6.10 recommends the random node). `version = 3` and
  `5`: `namespace` (a UUID or one of `"dns"`, `"url"`, `"oid"`,
  `"x500"`) and `name`, hashed through `zucrypt::crypt_hash()`, erroring
  with `zuid_dependency_error` when `zucrypt` is absent. `version = 8`:
  the caller's 122 bits through `random`, with version and variant bits
  set. `id_nil()` and `id_max()` are the two constants.
- **ULID.** 48 bits of milliseconds and 80 random bits, monotonic (§6.7).
- **TypeID.** A version 7 UUID under `prefix`, validated against the
  prefix grammar.
- **UPID.** `prefix` of one to four base32 characters, right-padded; 40
  bits of time in 256 ms units; 64 random bits; the current version
  nibble.
- **SCRU128.** The specification's generator: `counter_hi` random and
  renewed once the timestamp has advanced a second, `counter_lo` random
  at each new millisecond and incremented within it, 32 fresh entropy
  bits per value (§6.7).
- **SCRU64.** `node` and `node_bits` are required (D13 applies): a
  counter reset to a random value when the 256 ms tick advances.
- **KSUID.** Seconds since the KSUID epoch and 128 random bits; the
  specification defines no monotonic mode and none is added.
- **XID.** Seconds, a 3-byte machine id, a 2-byte process id and a
  3-byte counter started at a random value per session. The reference
  derives the machine id from the host name through MD5; `zuid` draws
  three random bytes per session instead and documents it (D12), with
  `machine` accepting three bytes for callers who need the reference's
  behaviour. `process` defaults to the real process id masked to 16
  bits.
- **ObjectId.** Seconds, a 5-byte per-process random value drawn once
  per session, and a 3-byte counter started at a random value.
- **Snowflake.** `layout` and `worker` are required (D13): the node field
  is the one thing the generator cannot invent safely, because duplicate
  node ids across machines are the failure Snowflake exists to prevent.
  `worker` is a named list when the layout has several node fields
  (`list(datacenter = 1L, worker = 7L)`). The sequence is per
  millisecond (§6.7).
- **NanoID.** `size` symbols from `alphabet` with the reference's
  mask-and-step rejection sampling, so a 57-symbol alphabet is as
  uniform as a 64-symbol one. The random bytes requested are the
  reference's estimate and the generator draws more if rejection eats
  them, which is the one place a generator asks for entropy twice.
- **CID.** `id_cid(x, codec, hash, version)` hashes raw vectors or files
  through `zucrypt` (SHA-256 by default; `zucrypt`'s other digests by
  multicodec name) and wraps the digest as a version 1 CID in lowercase
  base32, or a version 0 when `version = 0L`, `codec = "dag-pb"` and
  `hash = "sha2-256"`. It is the one generator that needs no clock and
  no entropy.
- **Sqids** is an encoding: `id_sqids(numbers)` takes integers, doubles
  below 2⁵³ or `zuint` `uint64`, applies the blocklist (D8), increments
  the offset and retries as the specification says, errors with
  `zuid_encode_error` when the alphabet is exhausted, and pads to
  `min_length` as the specification says.

### 6.7 Monotonicity

Within one call and across calls in one session, generation is monotonic
where the format defines what that means:

- **UUID version 7**: RFC 9562 §6.2 method 1. The 12 `rand_a` bits are a
  counter, re-seeded with a random value whose top bit is clear at each
  new millisecond, and incremented within a millisecond. When it would
  overflow, the millisecond is advanced by one and the counter
  re-seeded, which the RFC permits. `rand_b` stays random, so two
  sessions never collide on the counter alone.
- **ULID**: the specification's rule. Within a millisecond the 80-bit
  random component is incremented by one with carry; overflow is
  `zuid_overflow_error`.
- **SCRU128**: the specification's rules. `counter_lo` increments within
  a millisecond and carries into `counter_hi`; when both overflow the
  timestamp advances by one and the counters re-seed, so generation
  never blocks. A clock rollback of up to `zuid.rollback_tolerance`
  (10 s by default, the specification's "a few seconds") keeps the last
  timestamp; a larger one is `zuid_clock_error` unless
  `rollback = "reset"` asks for the specification's second option (D18).
- **SCRU64**: the counter increments within a 256 ms tick and starts from
  a random value below its maximum at each new tick, as the specification
  allows; overflow waits for the next tick.
- **XID and ObjectId**: the counter increments and wraps; the time field
  gives order at second resolution and the specifications promise no
  more.
- **Snowflake**: the sequence increments within a millisecond; when it
  overflows the generator waits for the next millisecond, as Twitter's
  does, checking for a user interrupt while it waits; a clock that runs
  backwards by more than `zuid.clock_tolerance` (10 ms by default) is
  `zuid_clock_error` rather than a silent duplicate.
- **UPID, KSUID, UUID version 4, NanoID, CID**: none, by their
  specifications or their nature.

The state is per session and is reset on load; `zuid_info()` reports the
last millisecond and counters so a test can see them.

### 6.8 Layouts

A layout is data: the number and unit of time bits, the epoch, the named
node fields with their widths in order, the sequence width, and whether
the top bit is reserved as a sign bit. `id_layout(name)` returns a
built-in:

| Name | Time | Node fields | Sequence |
| --- | --- | --- | --- |
| `twitter` | 41 bits, ms | `datacenter` 5, `worker` 5 | 12 bits |
| `discord` | 42 bits, ms | `worker` 5, `process` 5 | 12 bits |
| `instagram` | 41 bits, ms | `shard` 13 | 10 bits |
| `sonyflake` | 39 bits, 10 ms | `machine` 16 | 8 bits |
| `scru64` | 39 bits, 256 ms | `node` of `node_bits` | 24 − `node_bits` |

The epochs, in milliseconds since 1970:

- `twitter`: `1288834974657` (2010-11-04T01:42:54.657Z).
- `discord`: `1420070400000` (2015-01-01T00:00:00Z).
- `instagram`: `1314220021721` (2011-08-24T21:07:01.721Z).
- `sonyflake`: none. The reference library's default start time has
  changed between releases, so a caller supplies the one their producer
  used: `id_layout("sonyflake", epoch = ...)`. Sony's layout also puts
  the sequence before the machine field, and the built-in does the same.
- `scru64`: 1970, fixed by its specification; only `node_bits` varies,
  `id_layout("scru64", node_bits = 8)`.

`id_layout(time = list(bits = 41, unit = "ms", epoch = ...), fields =
list(worker = 10), sequence = 12, sign_bit = TRUE)` builds a custom one,
and the bits must sum to 64 (63 with the sign bit) or the call is
`zuid_layout_error`. A layout prints as its field diagram. Layouts are
compared by value and travel with the vector as an attribute and, at the
Arrow boundary, as extension metadata (§6.9).

The documentation states what the maintainer's note states: the fields of
a Snowflake or a SCRU64 are readable only when the layout is known, and
`zuid` cannot discover it from the number.

### 6.9 Arrow and DuckDB

The rule (**M**): **128 bits do not make a UUID.** A ULID, a SCRU128, a
UPID and a UUID all occupy 16 bytes, and interchange must carry which one
it was.

**Export** (`zuid` to Arrow, through `zuarrow`'s registry when `zuarrow`
is installed):

- `uuid`: `fixed_size_binary(16)` with the canonical extension name
  `arrow.uuid` and no metadata, as the canonical type requires.
- `ulid`, `scru128`: `fixed_size_binary(16)`, extensions `zuid.ulid` and
  `zuid.scru128`, no metadata.
- `typeid`: `fixed_size_binary(16)`, extension `zuid.typeid`, metadata
  `{"prefix":"user"}` when every element shares the prefix; otherwise
  `utf8` storage holding the full text, extension `zuid.typeid`, no
  metadata.
- `upid`: `fixed_size_binary(16)`, extension `zuid.upid`, no metadata,
  since the prefix is inside the bytes.
- `ksuid`: `fixed_size_binary(20)`, extension `zuid.ksuid`.
- `xid`, `objectid`: `fixed_size_binary(12)`, extensions `zuid.xid` and
  `zuid.objectid`.
- `snowflake`, `scru64`: `int64`, extensions `zuid.snowflake` and
  `zuid.scru64`, metadata holding the layout, for example
  `{"time":{"bits":41,"unit":"ms","epoch":1288834974657},`
  `"fields":{"datacenter":5,"worker":5},"sequence":12,"sign_bit":true}`.
- `cid`: `binary`, extension `zuid.cid`, metadata `{"multibase":"b"}`.
- `nanoid`, `cuid2`: `utf8`, extensions `zuid.nanoid` and `zuid.cuid2`;
  NanoID's metadata is `{"alphabet":"...","size":21}`.
- `sqids`: `utf8`, extension `zuid.sqids`, metadata
  `{"alphabet":"...","min_length":0}`; the blocklist is not carried.

`arrow.uuid` is used for UUIDs and for nothing else (D9). The other
names are namespaced `zuid.*`, which the Arrow specification allows for
non-canonical extensions, and the storage is what a consumer that does
not know the name would want: bytes for the binary formats, an `int64`
for Snowflake and SCRU64, text for the rest. RFC 0041 §6.6 says an
unregistered extension passes through `zuarrow` as its storage with the
name kept in an attribute, so a `zuid.ulid` column read without `zuid`
loaded is a list of 16-byte raws carrying the name, and loading `zuid`
and calling `id_from_bytes(x, "ulid")` recovers it. Nothing is lost on
either side.

**Import** (Arrow to `zuid`): `arrow.uuid` becomes a `zuid_uuid` vector,
whatever its version bits, at the `structure` level (variant bits are
not checked on import because the canonical type guarantees no version;
`id_valid()` tells). `zuid.<format>` becomes that format, with the
metadata restoring prefix, alphabet, multibase or layout. A
`fixed_size_binary(16)` column with no extension name is **not** an
identifier: `zuarrow` returns it as a list of raw vectors per its
built-in table, and `id_from_bytes(..., format)` is the explicit step. A
`utf8` column is never auto-detected at the boundary; `id_parse()` on
the character vector is the explicit step, with the hint rules of §6.2.

The metadata JSON is seven fixed keys written and read by hand in C; no
JSON package is involved, and unknown keys are ignored on read.

**DuckDB.** The `duckdb-r` handbook records that a DuckDB `UUID` column
exports as a lowercase hyphenated string by default and as `arrow.uuid`
when `arrow_lossless_conversion` is on. `zuid` handles both without a
flag: the string form through `id_parse(x, "uuid")`, the extension
through the registry. Going the other way, an `arrow.uuid` column
becomes a DuckDB `UUID`; a `zuid.ulid` column becomes a `BLOB`, because
DuckDB has no ULID type and drops extension names it does not know, so
the documentation says to send ULIDs, KSUIDs and the rest as text
(`as.character(x)`) when the type must survive inside DuckDB, and as
bytes when only the bytes must. A Snowflake or SCRU64 column becomes a
`BIGINT` either way, and the layout stays on the R side.

**Parquet.** `qio` is the consumer: Parquet's `UUID` logical type is a
`FIXED_LEN_BYTE_ARRAY(16)`, and only that type is a UUID; a bare
`FIXED_LEN_BYTE_ARRAY(16)` is bytes. The same rule, stated once in
`qio`'s design when it adopts `zuid`.

### 6.10 Determinism and limits

The same text gives the same bytes and fields on every platform and R
version (D6). Inputs are bytes or ASCII; a non-ASCII string fails
`syntax` and is `NA`. Vectors are limited by R's `R_xlen_t`. The Sqids
alphabet is 3 to 255 distinct single-byte characters; `min_length` is 0
to 255; a Sqids number is 0 to 2⁶⁴ − 1. A NanoID alphabet is 1 to 256
symbols. A TypeID prefix is 0 to 63 characters; a UPID prefix
is 1 to 4. `id_encode()` takes up to 2¹⁶ bytes per element. The strict
time tolerance is the option `zuid.time_tolerance`, one day by default.

## 7. The oracles

Each format and form has a reference that stands in for a conformance
suite, none a dependency:

1. **RFC 9562 Appendix A**: the worked examples for versions 1, 3, 4, 5,
   6, 7 and 8, parsed field for field and regenerated from the stated
   inputs.
2. **The IETF encoding draft's examples**, once read in full (§15 Q2),
   and until then Uuid25's, `uuid-base62`'s and `uuid62`'s published
   examples for base36 and base62, and the Crockford draft's for base32.
3. **TypeID's `spec/valid.yml` and `spec/invalid.yml`**: every valid
   fixture parses to the stated UUID and every invalid one is rejected,
   with the reason the fixture names.
4. **ULID's specification**: the maximum value, the overflow rejections,
   the monotonic sequence examples.
5. **UPID, SCRU128 and SCRU64**: the reference implementations' test
   vectors, including SCRU128's maximum and reserved timestamps and
   UPID's `user_2accvpp5guht4dts56je5a`.
6. **KSUID**: the README's worked example (`0ujsswThIGTUYm2K8FjOOfXtY1K`
   with its stated time and payload) and the Go test vectors for the
   minimum and maximum strings.
7. **XID**: the Go tests' vectors, and the byte-compatibility claim
   against ObjectIds from the BSON corpus.
8. **Snowflake**: Discord's documented example, `175928847299117063`,
   which decodes to 2016-04-30T11:18:25.796Z under the `discord` layout,
   and Twitter identifiers with published creation times.
9. **Sqids**: the specification repository's encoding, `min_length` and
   blocklist tests, run through the same inputs.
10. **Proquint**: the paper's examples (`127.0.0.1` is `lusab-babad`) and
    `proquint.c` run over random 16-byte inputs.
11. **Niceware**: the reference's test vectors for `bytesToPassphrase()`
    and `passphraseToBytes()`.
12. **CID**: the `go-cid` and `js-multiformats` fixtures for versions 0
    and 1 across multibases.
13. **NanoID**: the reference's uniformity test, a chi-squared check over
    10⁶ symbols for the default and a 26-symbol alphabet.

The fixtures are stored under `tests/testthat/fixtures/` at pinned
upstream commits recorded in `tools/fixture-sources.yaml`, as
`zumime`'s are (RFC 0040 §7).

## 8. Errors

Every condition inherits from `zuid_error`; tests assert on class.

| Class | Raised when |
| --- | --- |
| `zuid_type_error` | wrong type or length, including `random` |
| `zuid_ambiguous_error` | `id_parse()` without `format`, several candidates |
| `zuid_mixed_error` | `id_parse()` without `format`, several formats found |
| `zuid_parse_error` | `id_parse(..., strict = TRUE)` and an element fails |
| `zuid_layout_error` | bits do not sum to the width; `sonyflake` has no epoch |
| `zuid_convert_error` | `id_convert()` between formats sharing no value |
| `zuid_encode_error` | Sqids alphabet exhausted; number or word out of range |
| `zuid_overflow_error` | monotonic ULID overflow within a millisecond |
| `zuid_clock_error` | the clock ran backwards beyond the tolerance |
| `zuid_entropy_error` | the operating system's entropy source failed |
| `zuid_dependency_error` | a suggested package is asked for and absent |

`id_detect()`, `id_valid()`, `id_fields()`, `id_time()` and `id_parse()`
with the default `strict = FALSE` never raise on input.

## 9. Testing

`testthat` 3e. One file per format, one per form, and one per subsection
of §6 that crosses them. For each format: a round-trip property over 10⁴
generated values (text to bytes to text, text to fields to regenerated
text where the format allows regeneration from fields); the oracle of §7;
every form; the invalid inputs each level rejects, one per rule. For each
form: a round-trip property over random byte strings of every length the
form takes, and for the order-preserving forms a property that the sort
order of 10⁴ encoded strings equals the sort order of their bytes.
Detection has a table of strings against expected results and
candidates, including every collision §6.2 names. Monotonicity is tested
by generating 10⁵ values in a loop with the clock frozen through `time`
and checking strict increase, and by tests that advance `time` backwards
by less and by more than each tolerance and expect the documented
behaviour. Layouts round-trip through `id_layout()`, the attribute and
the Arrow metadata. The Arrow tests skip without `zuarrow` and otherwise
export every format and read it back with `arrow_equal()`, then read the
same stream with `zuid` unloaded and check the storage and the attribute.
The fuzz target under `ZUID_STANDALONE` runs random and mutated strings
through every codec and checks: no crash, no read past the buffer,
parse-then-format is idempotent, and a string accepted at `structure`
re-encodes to itself. From the family (R3): `test-abi.R`, that the shared
object exports `R_init_zuid` only.

## 10. Performance targets

Measured by `tools/run-benchmarks`, recorded in `.agents/benchmarks.md`,
with the baseline run in Stage 0 before any `zuid` code exists.

| Operation, 10⁶ elements | Target |
| --- | --- |
| `id_parse()` of UUID strings | under 150 ms; within 1.5× of `uuid` |
| `id_uuid(version = 7)` | under 100 ms; within 1.5× of `uuid` |
| `id_ulid()` | under 100 ms; faster than `ulid` |
| `id_format(form = "base62")` | under 300 ms |
| `id_format(form = "words")` | under 200 ms |
| `id_parse()` of KSUID strings | under 600 ms (base62 over 160 bits) |
| `id_detect()` of mixed strings | under 300 ms |
| `id_fields()` | under 400 ms |
| `id_sqids()` of single integers | under 500 ms including the blocklist |
| `id_bytes()`, `id_from_bytes()` | under 50 ms each |

The `uuid` rows compare against `uuid::UUIDparse()` and
`uuid::UUIDgenerate(n = )`; the `ulid` row against `ulid::ULIDgenerate()`.
The honest ceiling is `uuid`, which is a thin C layer over the same
operations; `zuid` should sit beside it on UUIDs and has no competitor
in R on the rest.

## 11. Roadmap

Stages run the quick CI profile unless marked `full`. Each is one pull
request, merged on green. Riskiest first: the vector class, the
descriptor table and the encoding layer before the long tail of formats,
because every later stage adds a row to the table and a caller of the
codecs, and neither may be reshaped.

| Stage | Delivers | Exit criterion |
| --- | --- | --- |
| 0 | repository, CI, generators for both tables, baseline | §10 bar |
| 1 | `zuid` class, descriptors, UUID parse, hex forms, fields, time | §7.1 |
| 2 (`full`) | UUID generation, counter, entropy and clock layer | §6.6, §6.7 |
| 3 | `id_encode()`, `id_decode()`, every form, `id_format()` | §7.2, §7.10 |
| 4 | ULID, TypeID, UPID, `id_convert()` | §7.3, §7.4, §7.5 |
| 5 | SCRU128, SCRU64, KSUID | §7.5, §7.6 |
| 6 | XID, ObjectId, Snowflake layouts, `id_integer()` | §7.7, §7.8 |
| 7 | NanoID, Cuid2 validation, Sqids, CID | §7.9, §7.12 |
| 8 | `id_detect()`, hints, collisions, `id_parse(format = NULL)` | §6.2 |
| 9 | Arrow registration, DuckDB round trip, fuzz, benchmarks | §6.9, §9 |
| 10 (`full`) | README, articles, release preparation | §12 |

Stage 0 writes `tools/fixture-sources.yaml`, generates `R/sysdata.rda`
from the descriptor table, the Sqids blocklist and the Niceware word
list, times `uuid::UUIDgenerate()`, `uuid::UUIDparse()` and
`ulid::ULIDgenerate()` so the bar is on record, and opens the one-line
pull request to `zufast`'s design that moves UUID generation from
`zurand` to `zuid`. Stage 1 covers §6.1 for UUID, §6.3, §6.4 and the
hex forms of §6.5. Stage 2 is `full` as the first stage that touches the
operating system. Stage 3 reads the IETF drafts in full and pins the
sorted forms (§15 Q2). Stage 10 writes `cran-comments.md`, adds the
Sqids blocklist's and Niceware's authors to `inst/COPYRIGHTS`, runs the
full profile and records the dates.

## 12. Acceptance criteria for v0.1.0

- Every behaviour in §6 and §8 has a passing test.
- The thirteen oracles of §7 pass.
- Every form round-trips over random bytes, and the order-preserving
  forms sort as their bytes do.
- The fuzz target runs one hour clean under `ZUID_STANDALONE` with
  sanitizers.
- Every format round-trips through `zuarrow` exactly, with `zuid` loaded
  and unloaded, and a `zuid_ulid` column never arrives as `arrow.uuid`.
- The same input gives byte-identical `zuid` vectors and `id_fields()`
  frames on the Linux, macOS and Windows CI legs.
- `R CMD check --as-cran` is clean on all r-actions legs; no `Imports`;
  `inst/COPYRIGHTS` states both tables' sources.
- `.agents/benchmarks.md` holds a number for every row of §10, met or
  not.
- Eleven stages. A stage that needs a second pull request moves scope to
  §14, not the release.

## 13. Decisions

- **D1 (M).** One package, one vocabulary, every format: the inspection
  API is the spine and generation hangs off it. The maintainer's first
  note set this, against a package that would wrap UUIDs alone.
- **D2 (C).** A `zuid` vector stores canonical text in a character
  vector with a class and a `format` attribute, not bytes and not a
  128-bit numeric payload. Text is what arrives from databases, JSON,
  CSV and logs and what goes back; it survives `unclass()`, `saveRDS()`
  and `write.csv()` readable; parsing 36 characters in C costs less than
  the allocation of a list of raws; and comparison on bytes is one
  `xtfrm()` method away. `uuid`'s raw-backed class and `zuint`'s
  payload-in-doubles are the alternatives, and both make a column that
  prints as noise when the class is lost.
- **D3 (M).** `id_from_bytes()` has no default format, and at the Arrow
  boundary a `fixed_size_binary(16)` without an extension name is bytes.
  The maintainer's rule that 128 bits do not make a UUID.
- **D4 (C).** `id_parse()` validates at `structure` by default: syntax
  alone admits a ULID that overflows 128 bits, and `strict` rejects
  legitimate identifiers from the future or with unusual version bits,
  which a parser should report, not refuse.
- **D5 (C).** Entropy comes from the operating system, never from R's
  RNG and not from `zurand`. An identifier must be
  unpredictable across sessions and must not change when a script calls
  `set.seed()`; reproducible tests pass `random` in. `zurand` is for
  simulation. This also settles the family-level assignment noted in the
  5 October review: UUID generation lives here.
- **D6 (C).** Generators are pure functions of `(n, time, random, node)`.
  The clock and entropy are read once in the R entry point and passed
  down, so the fuzz target and the tests reach every branch with fixed
  inputs and the same inputs give the same identifiers on every platform.
- **D7 (C).** No vendored code. Every codec is a few hundred lines
  against a specification with fixtures; MD5, SHA-1 and SHA-256 are not
  reimplemented and come from `zucrypt`.
- **D8 (C).** Two generated tables, the Sqids blocklist from
  `sqids/sqids-blocklist` and the Niceware word list from
  `diracdeltas/niceware`, go into `R/sysdata.rda` and a C header, with
  source, retrieval date and SHA-256 in `tools/fixture-sources.yaml`, as
  `zumime` does for its tables (RFC 0040 D8). The blocklist is on by
  default because the specification says so and off with
  `blocklist = NULL`. The word list is the reference's unchanged, so
  that passphrases decode in every Niceware implementation, and the
  reference's warning about unchecked offensive words is repeated.
- **D9 (C).** Arrow export uses `arrow.uuid` for UUIDs only and
  namespaced `zuid.<format>` names for everything else, over the storage
  a consumer without `zuid` would want. The alternative, `arrow.uuid` for
  every 128-bit format, is exactly the confusion D3 forbids.
- **D10 (M).** Detection never chooses an encoding or a syntactic format
  without a hint, and reports ambiguity among structured formats as
  `NA` with candidates rather than picking one. The maintainer's rule
  that a hint must be possible because some strings match several
  formats; the class split is how the RFC makes "some" precise.
- **D11 (C).** `id_uuid()` defaults to version 7, not 4, because a new
  identifier in 2026 should sort by time, RFC 9562 recommends it for new
  systems, and version 4 is one argument away.
- **D12 (C).** XID's machine id is three random bytes per session, not
  a hash of the host name, because the reference's derivation needs MD5
  and reads the host name, and random bytes give the same guarantee
  (distinct per host with overwhelming probability) without either. The
  `machine` argument restores the reference's behaviour for a caller
  who hashes the host name through `zucrypt`.
- **D13 (C).** `id_snowflake()` requires `layout` and `worker`, and
  `id_scru64()` requires `node` and `node_bits`. There is no safe default
  for any of them, and a default of zero would make two machines collide
  by construction.
- **D14 (C).** The R prefix is `id_`, the condition root `zuid_error`,
  the internal C prefix `zuid_`, and `zid_` is reserved for the header
  of §14. `id_` is short enough to read at a call site and no family
  package uses it.
- **D15 (C).** Performance targets (§10) are measured and recorded but do
  not gate v0.1.0; the API and the oracles do.
- **D16 (M).** The package is a complete UUID core with two rings in
  v0.1.0, encodings of the same bits and kindred formats, and a third,
  secrets, deferred to a later version. The maintainer's second note set
  the shape and a third set the deferral; the RFC orders the rings by
  how much they share with the core, which is also the roadmap's order.
- **D17 (C).** Encodings are one mechanism over bytes, `id_encode()` and
  `id_decode()`, and a UUID text form is the 16-byte case. One codec per
  alphabet then serves UUIDs, any raw vector a caller has and the later
  passphrases, and ShortUUID becomes a default alphabet rather than a format.
- **D18 (C).** SCRU128's clock rollback follows the specification's first
  option up to a tolerance and errors beyond it unless `rollback =
  "reset"`, because silently randomising the counters breaks the
  monotonicity a caller chose SCRU128 for, and the specification leaves
  the choice to the implementation.
- **D19 (C).** CID is a format here, not a separate package, because its
  parsing is varints and multibase over the same codec layer and
  `dastash` and `zudedup` are consumers now; its generation is one hash
  call away through `zucrypt`.
- **D20 (C).** Passwords, Readable sentences, Hashids and the EFF word
  lists are deferred (§2), each for the reason given there.

## 14. Later versions, in the order they are expected

- **A C API**: `inst/include/zuid.h` with `zid_parse()`, `zid_format()`,
  `zid_encode()` and the descriptor table, for `zucbor` tag 37,
  `zumsgpack`, `qio`'s `UUID` logical type and `zuarrow` to call without
  an R round trip, with a consumer fixture per R10.
- **Secrets**: `id_password(n, length = 28, alphabet = "letters")`,
  drawing symbols with the mask-and-step sampling of §6.6 from named
  alphabets (`letters`, `alnum`, `ascii`, `base32`, `digits`) or the
  caller's; `id_passphrase(n, bytes = 16, sep = "-")`, writing fresh
  bytes as Niceware words or, with `form = "proquint"`, as quints, so
  that 16 bytes is eight words and exactly 128 bits, with the argument in
  bytes as the reference's `generatePassphrase(16)` has it; and
  `id_entropy(x)`, the bits a secret carries (`length × log2(|alphabet|)`
  or `8 × bytes`) and, for an identifier, the random bits its format
  carries (122 for a version 4 UUID, 80 for a ULID, 0 for a Snowflake).
  Secrets would be plain character vectors with an `entropy_bits`
  attribute and no class, never `zuid` vectors, and the generators would
  refuse an identifier as input, because timestamps, counters, node ids
  and prefixes contribute nothing secret. Whether they live here or in
  `zucrypt`, the family's cryptography owner, is decided then; today
  `zucrypt` has no entropy function and this package has the entropy
  layer and the encodings.
- **Cuid2 generation**, once a Keccak exists in `zucrypt` or the
  maintainer accepts one here.
- **Hashids** behind the Sqids interface, with `salt`, if a consumer with
  legacy identifiers asks.
- **The EFF word lists** for passphrases that need no decoding, once
  secrets exist, and Readable-style sentences if a consumer wants
  identifiers read aloud in full.
- **Registration with `arrow` and `nanoarrow`**, so `arrow.uuid` and
  `zuid.*` columns convert in those packages too.
- **More layouts** as consumers bring them: Mastodon, Baidu's
  UidGenerator, Flickr's ticket servers, and whatever a user's producer
  used.
- **Hashes without `zucrypt`**, only if `zucrypt` is not released by the
  time a consumer needs them.
- **A `vctrs` record form** if the tidyverse integration wants one; the
  S3 methods in v0.1.0 cover `tibble` printing.

## 15. Open questions

- **Q1.** Is `zuid` free on crandb? The session that wrote this RFC could
  not reach crandb and checked the CRAN GitHub mirror instead, where
  `cran/zuid` is absent. Confirm with
  `curl -s https://crandb.r-pkg.org/zuid` before `gh repo create`;
  `zuuid` is the fallback, also absent from both on 2026-10-24.
- **Q2.** The IETF drafts `draft-davis-uuidrev-alt-uuid-encoding-methods`
  and `draft-crockford-davis-base32-for-humans` were read through search
  summaries only. Stage 3 reads them in full and pins the exact
  post-processing of Base62sort and Base64sort and the Crockford
  alphabet's decoding rules (the `I`, `L`, `O` and `U` substitutions),
  and records any difference from this RFC's §6.5 in the design log.
- **Q3.** Should `id_time()` default to `zutempo` instants once `zutempo`
  is on CRAN, so that UUID versions 1 and 6 are exact by default? D2's
  "readable when the class is lost" argues for `POSIXct`; exactness
  argues the other way.
- **Q4.** Should `id_parse()` accept a `zuid` vector of another format
  and reinterpret, or require `id_convert()`? The RFC requires
  `id_convert()`, so that a reinterpretation is always a visible call.
- **Q5.** Should the Snowflake `padded` text form be the canonical one,
  so that lexicographic order is numeric order in every tool? The RFC
  keeps the unpadded decimal because that is what every producer emits.
- **Q6.** Is v0.1.0 a CRAN submission or a GitHub release? The board's
  `CRAN intent` field records the answer; this RFC assumes `Planned`.

## 16. What this RFC does not decide

The printing format of a `zuid` vector and of a layout; whether
`id_formats()` includes custom layouts registered in the session; the
wording of condition messages beyond their classes; the exact set of
Snowflake-family layouts beyond the five named; which of `zucrypt`'s
digests `id_cid()` accepts beyond SHA-256; whether `id_nanoid()` exposes
the reference's `customRandom` hook as an R function; and the articles'
second examples.
