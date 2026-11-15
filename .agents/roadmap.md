# zuid: roadmap

Status: draft 2026-10-24; re-planned 2026-11-15 for v0.1.1. Implements
[design.md](design.md).
Target: v0.1.0, the first CRAN release (Stages 0 to 11, done), then
v0.1.1, which fixes what the 2026-11-15 assurance pass and bug hunt found
(Stages 12 to 18).
Tracking: [v0.1.0 (#2)](https://github.com/pedrobtz/zuid/issues/2), with one
sub-issue per stage;
[CRAN-submission (#15)](https://github.com/pedrobtz/zuid/issues/15).
v0.1.1: [v0.1.1 (#118)](https://github.com/pedrobtz/zuid/issues/118), with one
sub-issue per stage from Stage 12;
[CRAN-submission 0.1.1 (#126)](https://github.com/pedrobtz/zuid/issues/126).

The v0.1.1 re-plan (2026-11-15) comes from
[`.agents/assurance.md`](assurance.md) and
[`reviews/2026-11-15-bug-hunt.md`](reviews/2026-11-15-bug-hunt.md). Work
starts at `0.1.0.9000` once CRAN accepts 0.1.0. If CRAN sends 0.1.0 back
first, Stage 12 goes into the resubmission instead (see Stage 12). The
design changes are D26 to D32.

Follows design §11, with two portfolio changes. Design Stage 10 is split into
`Full CI` and `v0.1.0 readiness`, so there are twelve stages, not the eleven
§12 names. Stage 1 is `full` as well as Stage 2, because it is the first
compiled code and the parser every later stage builds on.

Scope narrowed 2026-10-24 by the maintainer: v0.1.0 has no interface with
other `zu*` packages. `zuarrow`, `zuint`, `zucrypt` and `zutempo` are not in
`Suggests`, and everything that needs them moves to After 0.1.0: Arrow and
DuckDB interchange (§6.9), `id_integer()`, `id_time(class = "zutempo")`,
name-based UUID versions 3 and 5, `cid()` generation, and Sqids numbers
of 2⁵³ or more. Parsing, fields and validation of every format are
unaffected. Design §12's Arrow criterion does not apply to v0.1.0.

## Stages

| Stage | Title | CI | Issue | Pull request | Done |
| --- | --- | --- | --- | --- | --- |
| 0 | [Package identity](#stage-0--package-identity) | quick | [#3](https://github.com/pedrobtz/zuid/issues/3) | [#17](https://github.com/pedrobtz/zuid/pull/17) | 2026-10-24 |
| 1 | [Vector class, descriptors and UUID parsing](#stage-1--vector-class-descriptors-and-uuid-parsing) | full | [#4](https://github.com/pedrobtz/zuid/issues/4) | [#18](https://github.com/pedrobtz/zuid/pull/18) | 2026-10-24 |
| 2 | [UUID generation](#stage-2--uuid-generation) | full | [#5](https://github.com/pedrobtz/zuid/issues/5) | [#19](https://github.com/pedrobtz/zuid/pull/19) | 2026-10-24 |
| 3 | [Encodings](#stage-3--encodings) | quick | [#6](https://github.com/pedrobtz/zuid/issues/6) | [#20](https://github.com/pedrobtz/zuid/pull/20) | 2026-10-24 |
| 4 | [ULID, TypeID and UPID](#stage-4--ulid-typeid-and-upid) | quick | [#7](https://github.com/pedrobtz/zuid/issues/7) | [#21](https://github.com/pedrobtz/zuid/pull/21) | 2026-10-24 |
| 5 | [SCRU128, SCRU64 and KSUID](#stage-5--scru128-scru64-and-ksuid) | quick | [#8](https://github.com/pedrobtz/zuid/issues/8) | [#22](https://github.com/pedrobtz/zuid/pull/22) | 2026-10-24 |
| 6 | [XID, ObjectId and Snowflake layouts](#stage-6--xid-objectid-and-snowflake-layouts) | quick | [#9](https://github.com/pedrobtz/zuid/issues/9) | [#23](https://github.com/pedrobtz/zuid/pull/23) | 2026-10-24 |
| 7 | [NanoID, Cuid2, Sqids and CID](#stage-7--nanoid-cuid2-sqids-and-cid) | quick | [#10](https://github.com/pedrobtz/zuid/issues/10) | [#24](https://github.com/pedrobtz/zuid/pull/24) | 2026-10-24 |
| 8 | [Detection](#stage-8--detection) | quick | [#11](https://github.com/pedrobtz/zuid/issues/11) | [#25](https://github.com/pedrobtz/zuid/pull/25) | 2026-10-24 |
| 9 | [Fuzzing and benchmarks](#stage-9--fuzzing-and-benchmarks) | quick | [#12](https://github.com/pedrobtz/zuid/issues/12) | [#26](https://github.com/pedrobtz/zuid/pull/26) | 2026-10-24 |
| 10 | [Full CI](#stage-10--full-ci) | full | [#13](https://github.com/pedrobtz/zuid/issues/13) | [#27](https://github.com/pedrobtz/zuid/pull/27) | 2026-10-24 |
| 11 | [v0.1.0 readiness](#stage-11--v010-readiness) | full | [#14](https://github.com/pedrobtz/zuid/issues/14) | [#72](https://github.com/pedrobtz/zuid/pull/72) | 2026-10-25 |
| 12 | [Generator state](#stage-12--generator-state) | full | [#119](https://github.com/pedrobtz/zuid/issues/119) | | |
| 13 | [One check on every route](#stage-13--one-check-on-every-route) | full | [#120](https://github.com/pedrobtz/zuid/issues/120) | | |
| 14 | [The vector class](#stage-14--the-vector-class) | quick | [#121](https://github.com/pedrobtz/zuid/issues/121) | | |
| 15 | [Assurance](#stage-15--assurance) | quick | [#122](https://github.com/pedrobtz/zuid/issues/122) | | |
| 16 | [Full CI](#stage-16--full-ci) | full | [#123](https://github.com/pedrobtz/zuid/issues/123) | | |
| 17 | [v0.1.1 readiness](#stage-17--v011-readiness) | full | [#124](https://github.com/pedrobtz/zuid/issues/124) | | |
| 18 | [Review](#stage-18--review) | full | [#125](https://github.com/pedrobtz/zuid/issues/125) | | |

## Stage 0 — Package identity

**Issue.** [#3](https://github.com/pedrobtz/zuid/issues/3), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** The package has its real identity, the CI the roadmap relies on,
the two generated tables, and the benchmark baseline on record.

**Work.**

- `DESCRIPTION`: real Title and Description, `Authors@R` with `cre`, `aut`,
  `cph`, `Depends: R (>= 4.1)`, `Language: en-GB`. `Suggests` holds test
  tooling only; no `zu*` package.
- `R-CMD-check.yaml`: add the `{"os": "windows-latest", "r": "devel"}`
  runner row. Add `native-checks.yml` from r-actions' examples. Pin
  `coverage.yml` to a commit, with the tag in a comment.
- Hidden symbols and registration so the shared object exports
  `R_init_zuid` only; `tests/testthat/test-abi.R` checks it (design R3).
- `zuid_info()`.
- `tools/fixture-sources.yaml`, and generators that write the Sqids
  blocklist and the Niceware word list into `R/sysdata.rda` and a C header,
  with source, retrieval date and SHA-256 recorded (D8).
- `tools/run-benchmarks` and `.agents/benchmarks.md` with the baseline:
  `uuid::UUIDgenerate()`, `uuid::UUIDparse()`, `ulid::ULIDgenerate()`.
- The one-line pull request to `zufast`'s design moving UUID generation from
  `zurand` to `zuid` (design §3).
- Replace the placeholder test.

**Exit criteria.**

- `R CMD check` passes on the quick r-actions profile, and every quick check
  finishes in under five minutes; any tuning is recorded here.
- `DESCRIPTION` has no scaffold text.
- `test-abi.R` passes.
- `R/sysdata.rda` holds both tables, and `tools/fixture-sources.yaml` records
  their sources and checksums.
- `.agents/benchmarks.md` has the three baseline numbers.
- The `zufast` pull request is open, and linked from this stage's pull
  request.

**Deviation (2026-10-24).** `inst/COPYRIGHTS` and the `Copyright` field
land here rather than in Stage 11, because the two MIT-licensed tables ship
from this stage on and their notices must ship with them.

**Design.** §3, §10, §11 Stage 0, D8.

## Stage 1 — Vector class, descriptors and UUID parsing

**Issue.** [#4](https://github.com/pedrobtz/zuid/issues/4), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `full — first compiled code: a parser of untrusted input and the one
CHARSXP constructor every later format builds on.`

**Goal.** UUIDs parse, validate, format in the hex forms and report their
fields and time, through the descriptor table every later format extends.

**Work.**

- `src/zuid_formats.{c,h}`: the descriptor record and the `uuid` row;
  `R/sysdata.rda` regenerated from it; `id_formats()`.
- `src/zuid_r.c`: the single `CHARSXP` constructor and the vectorised entry
  points.
- The `zuid` vector class with the methods of design §5.
- `id_parse()`, `id_valid()` at the three levels (§6.3), for `uuid`.
- The hex forms of §6.5 in `id_format()`; `id_bytes()`, `id_from_bytes()`.
- `id_fields()`, `id_time()` (`POSIXct` and `ms`), `id_version()` for every
  UUID version;
  `uuid_nil()`, `uuid_max()`.
- The condition classes of §8 that these raise.

**Exit criteria.**

- Oracle §7.1: every RFC 9562 Appendix A example parses field for field.
- A text to bytes to text round trip over 10⁴ values passes.
- Every rule each level rejects has a test.
- `id_parse(strict = FALSE)`, `id_valid()`, `id_fields()` and `id_time()`
  never raise on input.
- A full-profile run is green on the pull request.

**Deviations (2026-10-24).**

- `id_formats()` reads the compiled descriptor table directly rather than a
  copy in `R/sysdata.rda`. There is one copy, so the two cannot drift.
- `id_parse(format = NULL)` raises `zuid_type_error` until Stage 8 builds
  detection.
- `id_parse()` on a zuid vector of another format raises `zuid_type_error`
  and points at `id_convert()`, as the design proposes for §15 Q4.
- `vctrs` and `withr` join `Suggests` for the tests.

**Design.** §4 layers 1, 3 and 5; §5; §6.1 (UUID); §6.3; §6.4; §6.5 (hex
forms); §8.

## Stage 2 — UUID generation

**Issue.** [#5](https://github.com/pedrobtz/zuid/issues/5), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `full — first operating-system code: entropy and clock sources with
Windows-only paths (BCryptGenRandom, GetSystemTimePreciseAsFileTime).`

**Goal.** `uuid()` generates every version except the name-based 3 and 5,
with monotonic version 7, from operating-system entropy.

**Work.**

- The entropy layer (`getrandom`, `getentropy`, `arc4random_buf`,
  `BCryptGenRandom`) and the clock, read once in the R entry point (D5, D6).
- `src/zuid_gen.c`: pure generators for versions 1, 4, 6, 7 and 8.
- The monotonic version 7 counter and its per-session state (§6.7).
- `uuid(version = 3)` and `version = 5` raise a classed error saying
  name-based generation comes after 0.1.0. Parsing them is Stage 1's.
- `zuid_entropy_error`, `zuid_clock_error`.

**Exit criteria.**

- Oracle §7.1: the Appendix A examples other than versions 3 and 5
  regenerate from their stated inputs.
- 10⁵ version 7 values with a frozen clock strictly increase; the clock
  moving back by less and by more than the tolerance behaves as §6.7 says.
- `set.seed()` does not change generated values.
- Generation with fixed `random` and `time` gives the same bytes on Linux,
  macOS and Windows.
- A full-profile run is green on the pull request.

**Deviations (2026-10-24).**

- Version 2 is not generated. RFC 9562 leaves it to DCE Security, and the
  Work list named it by mistake. It raises `zuid_type_error`.
- Appendix A.6 regenerates except one bit: zuid seeds the version 7 counter
  with its top bit clear (§6.7), so its `rand_a` is `0x4C3`, not `0xCC3`.
- `zuid_clock_error` is not raised here. §6.7 gives UUID version 7 no error:
  a rollback beyond `zuid.rollback_tolerance` restarts at the new time, and
  versions 1 and 6 increment the clock sequence, as RFC 9562 §6.1 says. The
  error arrives with SCRU128 and Snowflake (Stages 5 and 6).
- Versions 3 and 5 raise `zuid_dependency_error`, since they need `zucrypt`.

**Design.** §4 layer 4; §6.6; §6.7; D5, D6, D11.

## Stage 3 — Encodings

**Issue.** [#6](https://github.com/pedrobtz/zuid/issues/6), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** Any bytes encode and decode in every form, and UUIDs format in
each of them.

**Work.**

- Read the two IETF drafts in full and pin Base62sort, Base64sort and the
  Crockford decoding rules; record differences in `design.md` (§15 Q2).
- `src/zuid_enc_*.c`: one codec per form of §6.5, compiling as C11 without R
  under `ZUID_STANDALONE`.
- `id_encode()`, `id_decode()`; every UUID `form` in `id_format()` and
  `id_parse()`; ShortUUID as a default alphabet (D17).

**Exit criteria.**

- Oracles §7.2 and §7.10 pass, and the Niceware vectors of §7.11.
- Every form round-trips over random byte strings of every length it takes.
- The order-preserving forms sort 10⁴ encoded strings as their bytes sort.
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- The oracle is the output of the mainstream Go and Python libraries, by the
  maintainer's decision (design.md D21), and the IETF draft's vectors only
  where they agree. The Crockford draft's left-aligned vectors are not
  followed; ULID's, TypeID's and every library's are.
- `base58` is base58btc, one `1` per leading zero byte, so 16 bytes take up
  to 22 characters rather than exactly 22.
- The RFC 4648 forms put the spare bits at the end, as RFC 4648 says, not at
  the front as §6.5 first had it.
- The Niceware oracle is the JavaScript reference 4.0.0, whose word list zuid
  ships; Python's `niceware` 0.2.1 has an older list.
- `legacy = TRUE` for ShortUUID before 1.0.0 is deferred: no pinned
  reference was found for those strings.
- The 10⁴-string sort criterion covers 16-byte values, the case §6.5 calls
  order-preserving.

**Design.** §4 layer 2; §6.5; D17; D21; §15 Q2.

## Stage 4 — ULID, TypeID and UPID

**Issue.** [#7](https://github.com/pedrobtz/zuid/issues/7), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** The three 128-bit sortable formats parse, read fields, generate
and convert to and from UUIDs.

**Work.**

- Descriptors and format code for `ulid`, `typeid`, `upid`.
- `ulid()` with monotonic overflow (`zuid_overflow_error`), `typeid()`,
  `upid()`.
- `id_convert()` for `uuid`, `typeid`, `upid` and `ulid`;
  `zuid_convert_error`.

**Exit criteria.**

- Oracles §7.3, §7.4 and §7.5 (UPID) pass.
- Each format round-trips over 10⁴ generated values.
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- A ULID, TypeID or UPID string too large for 128 bits fails `syntax`, not
  only `structure`: it has no bytes, so it has no canonical text either.
- `id_from_bytes(bytes, "typeid")` makes TypeIDs without a prefix; a prefix
  comes through `id_convert(x, "typeid", prefix = )`.
- `id_convert(x, to, prefix = NULL)` names its one extra argument instead of
  taking `...`.
- `upid()` rejects a prefix outside the UPID alphabet with
  `zuid_type_error`, where the reference silently turns it into `zzzz`.
- UPID has no published test vectors. The oracle is the Python reference,
  `upid` 0.3.1, over random bytes, plus the README's example.
- The TypeID fixtures ship with upstream's Apache-2.0 licence beside them,
  and `inst/COPYRIGHTS` records them.

**Design.** §6.1, §6.4, §6.6, §6.7 for these formats; §5 `id_convert()`.

## Stage 5 — SCRU128, SCRU64 and KSUID

**Issue.** [#8](https://github.com/pedrobtz/zuid/issues/8), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** The three counter- and base36/base62-based formats parse, read
fields and generate.

**Work.**

- Descriptors and format code for `scru128`, `scru64`, `ksuid`.
- `scru128()` with the rollback rule of D18, `scru64()` requiring
  `node` and `node_bits` (D13), `ksuid()`.

**Exit criteria.**

- Oracles §7.5 (SCRU) and §7.6 pass, including SCRU128's reserved
  timestamps.
- Each format round-trips over 10⁴ generated values.
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- SCRU64's node and counter fields need `node_bits`, which is a layout
  (§6.8, Stage 6). Until then `id_fields()` reads its time only, and
  `id_parse()` and `id_from_bytes()` take a SCRU64 without a layout.
- `scru64()` takes `random` (3 bytes per value, the counter's seed), as
  D6 needs and the API sketch omits.
- A SCRU64 counter overflow advances the tick, as the specification and its
  reference recommend, rather than waiting for it (§6.7): waiting would read
  the clock inside the generator (D6).
- `scru128()` and `scru64()` both take `rollback = c("error",
  "reset")`, D18's rule for SCRU128 applied to SCRU64 as well, whose
  reference has the same two modes.
- A KSUID above its maximum fails `syntax`, not only `structure`, as ULID's
  does: it has no bytes.
- The SCRU oracles are the Python references' output (`tools/gen-fixtures`)
  plus the vectors and rejections of their tests.

**Design.** §6.1, §6.4, §6.6, §6.7 for these formats; D13, D18.

## Stage 6 — XID, ObjectId and Snowflake layouts

**Issue.** [#9](https://github.com/pedrobtz/zuid/issues/9), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** The 96-bit formats and Snowflake under explicit layouts parse,
read fields and generate.

**Work.**

- Descriptors and format code for `xid`, `objectid`, `snowflake`.
- `id_layout()` with the built-in layouts and custom ones as data;
  `zuid_layout_error`.
- `xid()` (D12), `objectid()`, `snowflake()` requiring `layout` and
  `worker` (D13); `id_convert()` between `xid` and `objectid`.

**Exit criteria.**

- Oracles §7.7 and §7.8 pass.
- Layouts round-trip through `id_layout()` and the `layout` attribute.
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- A Snowflake sequence overflow moves to the next tick instead of waiting
  for it (§6.7), as SCRU64's does (Stage 5): waiting would read the clock
  inside the generator (D6). Ticks moved ahead this way are not counted as
  a clock rollback; only the clock's own readings are.
- `zuid.clock_tolerance` is in seconds, 0.01 by default, like the other
  tolerance options, rather than in milliseconds.
- `snowflake()` has no `random`: the sequence starts at zero each tick,
  as Twitter's does. `xid()` and `objectid()` take `random` (D6).
- A layout's parts are at most 53 bits each, so that every field reads
  exactly as a double, and a layout has one to six node fields.
- The SCRU64 layout is optional, so a SCRU64 still parses without one;
  with `id_layout("scru64", node_bits = )` its node and counter are read,
  which finishes what Stage 5 deferred.
- An XID in uppercase is rejected, as `rs/xid` rejects it; a Snowflake with
  leading zeros is rejected, so each value has one text.

**Design.** §6.1, §6.4, §6.6, §6.8; D12, D13.

## Stage 7 — NanoID, Cuid2, Sqids and CID

**Issue.** [#10](https://github.com/pedrobtz/zuid/issues/10), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** The syntactic formats, Sqids and content identifiers parse and
validate; NanoID and Sqids generate.

**Work.**

- `nanoid`, `cuid2` (validation only), `sqids`, `cid` (parsing and fields
  only) descriptors and code.
- `nanoid()` with mask-and-step sampling; `sqids()` with the blocklist
  on by default (D8), for numbers below 2⁵³; `zuid_encode_error`.

**Exit criteria.**

- Oracles §7.9 and §7.13 pass, and §7.12's CID fixtures parse to their
  stated fields.
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- `id_parse()` and `id_valid()` gain `alphabet` and `min_length`, after
  `strict`, which the maintainer chose over a parameters object; with a
  `blocklist` from `sqids()` they travel as vector attributes, as
  `layout` does.
- `nanoid()` follows NanoID 6.0.2's `customRandom()`, a cutoff-and-modulo
  sampler, not mask-and-step: the reference changed in 6.0.0, and D21
  follows the reference. Its default alphabet is in 6.x's order.
- NanoID, Cuid2 and Sqids have no bytes, so `id_bytes()` and
  `id_from_bytes()` are `zuid_type_error` for them; a CID's bytes are a
  list. `id_from_bytes(, "cid")` writes base32 for version 1 and `Qm` for
  version 0.
- CID text is read in 17 multibases, those of js-multiformats' basics less
  base2, base8, base10, base32z, base58flickr, base256emoji and identity.
- `sqids()` takes a numeric vector (one Sqid per number) or a list (one
  per element). Numbers above 2^53 - 1 are `zuid_encode_error` until zuint.
- NanoID's oracle 13 is a chi-squared test over 10^6 symbols with a 1e-6
  threshold, plus the reference's `customRandom` vectors.

**Design.** §6.1, §6.6 for these formats; D8, D19.

## Stage 8 — Detection

**Issue.** [#11](https://github.com/pedrobtz/zuid/issues/11), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** `id_detect()` and `id_parse(format = NULL)` pick a format only
when the evidence allows, and report ambiguity otherwise.

**Work.**

- `id_detect()` with `hint`, `layout` and the `candidates` attribute.
- `id_parse(format = NULL)`; `zuid_ambiguous_error`, `zuid_mixed_error`.

**Exit criteria.**

- A table of strings against expected results and candidates passes,
  covering every collision §6.2 names.
- No encoding or syntactic format is chosen without a hint (D10).
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- A SCRU64 is listed among the candidates without a layout but chosen only
  under `id_layout("scru64", node_bits = )`, which is how this stage reads
  "SCRU64 is chosen only with a layout". A Snowflake is not tried at all
  without a Snowflake layout.
- Detection reads each format's canonical text with its default alphabet;
  the other text forms of a UUID and custom alphabets need `format`.
- `id_parse(format = NULL)` on a vector where no element fits any format is
  a `zuid_parse_error`; elements that fit none among ones that do are `NA`,
  as with a given format.
- The conditions carry `positions`, `candidates` (ambiguous) and `formats`
  (mixed) for a caller to inspect.

**Design.** §6.2; D10.

## Stage 9 — Fuzzing and benchmarks

**Issue.** [#12](https://github.com/pedrobtz/zuid/issues/12), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `quick`.

**Goal.** The codecs are fuzzed, and every benchmark row has a number.

**Work.**

- The `ZUID_STANDALONE` fuzz harness and `fuzz.yml` from r-actions.
- Every row of §10 measured into `.agents/benchmarks.md`.

**Exit criteria.**

- The fuzz workflow runs green.
- `.agents/benchmarks.md` has a number for every row of §10 (D15: not a
  gate).
- `R CMD check` passes on the quick r-actions profile.

**Deviations (2026-10-24).**

- Most §10 targets are missed, recorded with their causes in
  `benchmarks.md`: creating 10⁶ R strings alone takes about 680 ms on the
  benchmark machine. Two hot spots the first run showed were fixed in this
  stage (`id_detect()` 8884 → 2915 ms, `sqids()` 12249 → 2786 ms),
  including `id_valid()` no longer building text it discards.
- The harness needs no `ZUID_STANDALONE` code: the codec files include no R
  headers, so the fuzz build excludes the R-facing files instead
  (`zuid_r*.c`, `zuid_init.c`) and defines the macro only for the record.
- The fuzz workflow runs 120 s on pull requests and 30 minutes nightly, as
  r-actions' example does, from a 209-file seed corpus drawn from the oracle
  fixtures.

**Design.** §9; §10; D15.

## Stage 10 — Full CI

**Issue.** [#13](https://github.com/pedrobtz/zuid/issues/13), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `full`.

**Goal.** The full r-actions profile is green on the default branch's code.

**Work.**

- No new features. Run the full profile (`full-ci` label) and fix what it
  finds: gctorture at the sensitive step, valgrind, ASan, every platform
  leg, `nosuggests`, `nold`, cran-special.
- Fix every failure recorded on this issue by earlier merges.
- Run the fuzz target for one hour under sanitizers (§12).

**Exit criteria.**

- A full-profile run is green on the pull request and on its merge commit.
- The same input gives byte-identical `zuid` vectors and `id_fields()`
  frames on the Linux, macOS and Windows legs.
- The fuzz target has run one hour clean with sanitizers.

**Deviations (2026-10-24).**

- The full run on Stage 9's merge commit (3cc1b20) was green and this issue
  had no comments, so the stage fixes nothing; it adds the two checks the
  exit criteria name.
- The hour of fuzzing runs in CI: the fuzz workflow fuzzes 3600 s nightly
  and on a pull request labelled `full-ci`, with a 75-minute job timeout.
- Byte identity across platforms is a golden file,
  `tests/testthat/fixtures/determinism.txt`: every generator run on fixed
  time and random input, the text, time and `id_fields()` of each, and the
  encodings of one byte string in every form. Each R CMD check leg compares
  against it.
- The `nosuggests` and `nold` jobs are opt-in in r-actions and were off, so
  the first full run on this pull request skipped them. The R-CMD-check
  caller now turns both on. `nosuggests` then failed on `library(testthat)`
  in `tests/testthat.R`, which now runs the tests only when testthat is
  installed.

**Design.** §9; §12.

## Stage 11 — v0.1.0 readiness

**Issue.** [#14](https://github.com/pedrobtz/zuid/issues/14), sub-issue of [v0.1.0](https://github.com/pedrobtz/zuid/issues/2).

**CI.** `full`.

**Goal.** Only the submission itself is left.

**Work.**

- README and the two articles, "Reading what an identifier knows" and
  "A UUID in every alphabet".
- `inst/COPYRIGHTS` naming the Sqids blocklist's and Niceware's authors.
- `Version: 0.1.0` and the matching `NEWS.md` heading.
- `cran-comments.md` listing the r-actions CI legs as test environments.
- Run `pkg-critical-review` and fix its blocking and required findings,
  then `pkg-cran-review` and resolve every finding.

**Exit criteria.**

- Every acceptance criterion of design §12 holds, except the `zuarrow`
  round trip, which is After 0.1.0.
- `urlchecker::url_check()` and `spelling::spell_check_package()` are clean.
- `R CMD check --as-cran` has 0 errors, 0 warnings and only the
  "New submission" note.
- A full-profile r-actions run is green on the release commit.

**Deviations (2026-10-25).**

- The articles are pkgdown articles under `vignettes/articles/`, not
  vignettes: `vignettes/` is in `.Rbuildignore`, so they add no build
  dependency and no check time.
- `pkg-critical-review` filed #28 to #71 at 07e9b10. This stage fixes the
  five Blocking and eleven Required findings (#28 to #43) and three cheap
  suggestions (#50, #51, #59). The remaining suggestions, questions and
  notes stay open for after 0.1.0. Three fixes needed decisions, which the
  maintainer took and the design records as D22 (pure calls with `time`
  and `random`), D23 (`snowflake(rollback =)`, per-layout and per-node
  state) and D24 (`id_parse()` without a format needs an element).
- Three C guards are not reached by tests, with the reason in
  `tests/testthat/test-c-guards.R`: a string longer than R allows, a raw
  matrix past `R_XLEN_T_MAX`, and the encoders' out-of-memory branches.
- `pkg-cran-review` found the bundled data's copyright holders missing
  from `Authors@R`; they are listed now, with the Description's acronyms
  expanded and a method references section in `cran-comments.md`.
- The two article links in the README return 404 until this merge
  deploys the site; `urlchecker::url_check()` is otherwise clean.

**Design.** §2 (README and articles); §12; D8.

## Stage 12 — Generator state

**Issue.** [#119](https://github.com/pedrobtz/zuid/issues/119), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118).

**CI.** `full — changes the C state every generator shares, and the fork
path exists on Unix only, so the platform legs and sanitizers must see it`.

**Goal.** No generator repeats a value or goes backwards because of
process, table or counter state. Fixes #88, #109, #101, #89, #90, #102 and
#116. These are the two high-severity findings and the four medium ones
behind them. If CRAN returns 0.1.0, this stage is the resubmission's
content.

**Work.**
- D26: a process-id check on every static in `src/zuid_r_gen.c` and
  `src/zuid_r_layout.c`, resetting all state on a change.
- D27: last clock reading and last emitted time kept apart in the v7,
  v1/v6 and SCRU64 generators of `src/zuid_gen.c`; tolerance options
  clamped in R before the C conversion.
- D28: growable SCRU64 and Snowflake state tables; layout comparison
  field by field.
- Documentation of §6.7's per-process rule under the generators.

**Tests.**
- Fork: a warm parent, then two `parallel::mclapply()` children at a frozen
  `time`, for every generator. No value is repeated across the children.
  Skipped on Windows. In `tests/testthat/test-fork.R`.
- Overflow is not a rollback: one call of 4× the per-tick counter capacity
  at a frozen `time`, at tolerance 0 and at the default, for v7, v1, v6,
  ULID, SCRU128 and SCRU64 (`node_bits` 23 and 8). Values strictly
  increase and no `zuid_clock_error` is raised. For SCRU64 the values are
  compared with the Python `scru64` 1.0.2 generator fed the same inputs (a
  new `tools/gen-fixtures` table). In `tests/testthat/test-monotonic.R`.
- Tables: 15, 16, 17 and 40 other layouts and nodes between two calls at a
  frozen `time`; the second value is greater. In `test-snowflake.R` and
  `test-scru64.R`.
- Tolerances: each option at `Inf`, `.Machine$double.xmax` and 2⁴⁰ ms
  behaves as unlimited, and 2⁴⁰ − 1 ms still bounds. In
  `test-uuid-generate.R` and `test-snowflake.R`.
- Layout identity: two equal layouts built by different routes share one
  sequence. In `test-layout.R`.

**Exit criteria.**
- Every `**Tests.**` line exists and was seen to fail on `df17861`. Each
  hunt trigger in `reviews/2026-11-15-bug-hunt-probes/` (`h3.R`, and
  `h1.R`'s fork case) now passes.
- A full-profile run green on the pull request, including the ASan and
  valgrind legs.
- `.agents/assurance.md` rows for the two state tables and the generator
  time state name their tests.

**Design.** D26, D27 and D28 in [§13](design.md#13-decisions);
[§6.7](design.md#67-monotonicity).

## Stage 13 — One check on every route

**Issue.** [#120](https://github.com/pedrobtz/zuid/issues/120), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118).

**CI.** `full — changes the C validation of untrusted input in the decoders,
so ASan, valgrind and the fuzz harness must run on it`.

**Goal.** Every route that makes a zuid value, or decodes bytes, checks what
`id_parse()` checks. Fixes #103, #104, #110, #97 and #113, and closes the
gap #95.

**Work.**
- D29: structure checks in `zuid_c_from_bytes`; the 2¹⁶-byte cap and the
  ASCII rule in `zuid_c_decode`; one separator rule for words and Proquint
  on both paths.
- #104: `uuid_strict()` checks the variant itself.
- D31: Cuid2 structure takes `isCuid()`'s leading letter.
- The fuzz harness gains the new checks as oracles: `id_from_bytes` of
  bytes then `id_parse` of the text must agree.

**Tests.**
- `id_from_bytes()`: for every fixed-width format, all-zero, all-one,
  maximum, maximum + 1 and reserved bytes. Either bytes in equal bytes
  out, or `NA` where `id_parse()` of the text is `NA`. SCRU64's maximum
  is checked against the Python `scru64` range error. In
  `tests/testthat/test-bytes.R`.
- TypeID strict: for every version nibble and variant, `id_valid(typeid,
  "strict")` equals `id_valid(its UUID, "strict")`. In `test-typeid.R`.
- `id_decode()` cap: decoded sizes of 65535, 65536 and 65537 bytes, in
  hex, base64url and base58, and `width` at the same values. In
  `test-encode.R`.
- Words and Proquint: decode and `id_parse(form =)` agree on accept and
  reject over non-ASCII, digits, en dashes and long separators. In
  `test-encode.R`.
- Cuid2: `isCuid()` from `@paralleldrive/cuid2` 3.3.0 over generated ids
  and boundary strings (lengths 1, 2, 32, 33; case; a leading digit). Made
  by `tools/gen-js-fixtures.mjs` and pinned in `tools/fixture-sources.yaml`.
  In `test-cuid2.R`.

**Exit criteria.**
- Every `**Tests.**` line exists, compares against its oracle, and was
  seen to fail on `df17861`.
- A full-profile run and an hour of fuzzing (`full-ci`) green on the
  pull request.
- Assurance rows "Cuid2, validate" and the decode limit name their tests;
  #95 and #97 are closed.

**Design.** D29 and D31 in [§13](design.md#13-decisions);
[§6.3](design.md#63-validation-levels), [§6.5](design.md#65-text-encodings-and-bytes),
[§6.10](design.md#610-determinism-and-limits).

## Stage 14 — The vector class

**Issue.** [#121](https://github.com/pedrobtz/zuid/issues/121), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118).

**CI.** `quick`. Plain R in `R/`.

**Goal.** A zuid vector behaves the same through base R, vctrs and dplyr,
and every argument is checked with a classed error. Fixes #105, #106, #107,
#108, #111, #112, #114 and #115.

**Work.**
- D30: `vec_proxy_order` and `vec_proxy_compare` per format; `Ops.zuid`
  refuses numbers, factors and mismatched parameters; `mtfrm.zuid`, so
  `match()` and `%in%` use the canonical form.
- D32: `blocklist` in `id_parse()` and `id_valid()`.
- `c()` keeps names; `typeid(0, prefix)` and `id_convert()` of a
  zero-length vector give length 0.
- `is_whole()` rejects non-finite values; `NULL` and an out-of-range `na`
  attribute are `zuid_type_error`.
- `id_layout()` field names and widths are validated.
- #114: the layout epoch printed from integer milliseconds; the `"hex"`
  form documentation corrected; error text independent of `OutDec` and
  `scipen`; the `nanoid()` and `uuid(7)` argument documentation.

**Tests.**
- Ordering: `vctrs::vec_order(x)` equals `order(x)` for every format, on
  values whose text and byte orders differ (Snowflake, mixed case,
  TypeID). In `test-class.R`, under `skip_if_not_installed("vctrs")`.
- Comparison: `==`, `match()` and `%in%` agree with each other on
  uppercase, compact and urn text, and are `zuid_type_error` for numbers,
  factors and other layouts. The results are identical under
  `options(scipen = -5, OutDec = ",")`. In `test-class.R`.
- Names: through `c()`, compared with the same operation on a character
  vector. In `test-class.R`.
- `n = 0` through every generator and every `id_convert()` target: length
  0 and the right class. In `test-convert.R`.
- Sqids: for each of `alphabet`, `min_length` and `blocklist`, `sqids(...)`
  written to text and parsed back gives the same vector. In
  `test-sqids.R`.
- Numeric arguments: a table over every numeric argument at `NA`, `NULL`,
  `Inf`, `-Inf`, `NaN` and length 0, expecting `zuid_type_error`. In
  `test-c-guards.R`.
- Layout display: `format()` of a layout whose epoch ends in each digit 0
  to 9 ms shows that digit. In `test-layout.R`.

**Exit criteria.**
- Every `**Tests.**` line exists and was seen to fail on `df17861`.
- `R CMD check` green on the quick profile; `NEWS.md` names the `==`
  change, which is user-visible.

**Design.** D30 and D32 in [§13](design.md#13-decisions);
[§5](design.md#5-public-r-api-v010-shape).

## Stage 15 — Assurance

**Issue.** [#122](https://github.com/pedrobtz/zuid/issues/122), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118).

**CI.** `quick`. It adds scheduled workflows and tests, and no package
code.

**Goal.** No `gap #` left in `.agents/assurance.md`. Closes #91, #92, #93,
#94, #96, #98 and #99.

**Work.**
- `alloc-failure.yml` on the schedule (#91), and the decision on Sqids'
  out-of-memory result, which should raise.
- `mutation.yml` over the standalone codec build, with `encodings.csv`
  rows as the vectors (#92). The survivors are read and filed.
- A `reach-floor` in `fuzz.yaml`, a few points under the current reach
  (#93).
- Tests for the remaining straddles: argument bounds (#96), every
  generator's time range (#98), the stack-to-heap switches (#99).
- A Sonyflake fixture from `sonyflake-py` (#94).

**Tests.**
- Sonyflake: `(id, time, sequence, machine)` rows from `sonyflake-py`'s
  `decompose`, compared in both directions. In `test-snowflake.R`.
- Bounds: each limit of #96 at `limit − 1`, `limit` and `limit + 1`,
  through R and C. In `test-c-guards.R`.
- Time ranges: every generator at its minimum and maximum, one unit
  inside each and one unit outside each. In `test-strict-time.R`.
- Buffer switches: hex at 255, 256 and 257 characters; base58 and base62
  at 255, 256 and 257 bytes; a Sqid of 511, 512 and 513 characters with
  a blocked word at the end. In `test-encode.R` and `test-sqids.R`.

**Exit criteria.**
- `assurance.yml` green with no `gap #` rows.
- Mutation survivors and the reach gap list read, with each missing
  oracle filed.
- Each new test seen to fail once on a deliberately broken build.

**Design.** [§7](design.md#7-the-oracles), [§9](design.md#9-testing).

## Stage 16 — Full CI

**Issue.** [#123](https://github.com/pedrobtz/zuid/issues/123), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118).

**CI.** `full`.

**Goal.** The full r-actions profile and step-20 gctorture are green on the
v0.1.1 code. #84 (the r-universe WebAssembly build) is fixed or recorded
as a known limit.

**Exit criteria.** A full-profile run green on the pull request. A
dispatched one green on the merge commit. A dispatched step-20 gctorture
run green on the pull request's last commit.

## Stage 17 — v0.1.1 readiness

**Issue.** [#124](https://github.com/pedrobtz/zuid/issues/124), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118).

**CI.** `full`.

**Work.** `Version: 0.1.1`, with a `NEWS.md` section listing every fix by
issue. `cran-comments.md` for an update, with the r-actions legs as test
environments. `urlchecker::url_check()` and
`spelling::spell_check_package()` clean.

**Exit criteria.** A full-profile run green on the merge commit.

## Stage 18 — Review

**Issue.** [#125](https://github.com/pedrobtz/zuid/issues/125), sub-issue of [v0.1.1](https://github.com/pedrobtz/zuid/issues/118). No pull request closes it.

**CI.** `full`.

**Work.**
1. `pkg-critical-review`, with its blocking and required findings as
   sub-issues of this issue, fixed in one pull request.
2. A second bug hunt (`pkg-bug-hunt`) on the release candidate, sliced
   the same way, so the result can be compared with 2026-11-15.
3. `pkg-cran-review` on the code to be submitted.

**Exit criteria.** Every blocking and required review issue closed. The
`pkg-cran-review` table clean. A full-profile run green on the default
branch, whose head becomes the release commit.

## After 0.1.0

First, the interfaces with other `zu*` packages, deferred by the
maintainer on 2026-10-24 so v0.1.0 stands alone:

- Arrow and DuckDB interchange through `zuarrow`'s registry (§6.9, D9),
  with its §12 round-trip criterion.
- `id_integer()` through `zuint`, and Sqids numbers of 2⁵³ or more as
  `uint64`.
- `id_time(class = "zutempo")`, and design §15 Q3 with it.
- Name-based UUID versions 3 and 5, and `cid()` generation, through
  `zucrypt`.

Then design §14, in the order expected:

- A C API, `inst/include/zuid.h`, once the R surface has settled.
- Passwords and passphrases (`id_password()`, `id_passphrase()`,
  `id_entropy()`), set aside so v0.1.0 is identifiers only.
- Cuid2 generation, once a Keccak exists.
- Hashids behind the Sqids interface, if a consumer asks.
- The EFF word lists and Readable-style sentences.
- Registration with `arrow` and `nanoarrow`.
- More Snowflake layouts as consumers bring them.
- Hashes without `zucrypt`, only if a consumer needs them first.
- A `vctrs` record form, if the tidyverse integration wants one.

## Open questions

- **Q4** is settled in Stage 1: `id_parse()` refuses a zuid vector of
  another format and points at `id_convert()`, as the design proposed.
- **Q5: Snowflake `padded` canonical text (Stage 6).**
- **Q6: CRAN or GitHub release (Stage 11).** The board's `CRAN intent`
  field records it; assumed `Planned`.
- Design §15 Q1 (is the name free) is answered: crandb returned
  `not_found` for `zuid` on 2026-10-24. Q2 is Stage 3's work.
