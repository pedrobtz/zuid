# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Shared conventions

The portfolio’s shared rules are synced into `.claude/shared/` from
`pedrobtz/packages:claude/shared/`. Never edit them here. Where this
file and a shared file disagree, this file wins for this package.

@.claude/shared/workflow.md @.claude/shared/r-package.md
@.claude/shared/ci.md @.claude/shared/correctness.md
@.claude/shared/assurance.md

## What this is

`zuid` is a complete UUID implementation for R with two rings around it.
The core is RFC 9562 in full: versions 1 to 8, nil and max, name-based
and monotonic generation, every RFC text form. The first ring re-encodes
the same bytes (Crockford base32, base36, base58, base62, base64url,
Base62sort and Base64sort, any alphabet, Proquint, Niceware words). The
second ring is the kindred formats: ULID, TypeID, UPID, SCRU128, SCRU64,
KSUID, Snowflake and Sonyflake, XID, ObjectId, NanoID, Cuid2, Sqids and
CID. Generators are named after their format
([`uuid()`](https://pedrobtz.github.io/zuid/reference/uuid.md),
[`ulid()`](https://pedrobtz.github.io/zuid/reference/ulid.md)), and one
`id_` vocabulary detects, parses, validates, reads fields and time, and
converts across all of them.

No `Imports` and no vendored code. v0.1.0 has no interface with other
`zu*` packages: Arrow interchange (`zuarrow`), integers (`zuint`),
name-based UUIDs and CID generation (`zucrypt`) and exact instants
(`zutempo`) come after it, as `Suggests`. It is not a hashing package,
not a random number generator, not a database driver, and in v0.1.0 not
a password generator.

The specification is
[`.agents/design.md`](https://pedrobtz.github.io/zuid/.agents/design.md),
adopted from [RFC
0043](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0043-zuid-identifiers-beyond-uuid.md).
It outranks this file: `CLAUDE.md` orients, the design doc decides. The
roadmap is
[`.agents/roadmap.md`](https://pedrobtz.github.io/zuid/.agents/roadmap.md);
its “After 0.1.0” section lists what was deferred, and why.

## Current state

Verified 2026-11-11. All twelve roadmap stages (0 to 11) are merged, and
v0.1.0 was submitted to CRAN on 2026-11-06 (`CRAN-SUBMISSION`); it is in
the incoming queue. Every format above parses, validates and reads its
fields. Not in v0.1.0, by the maintainer’s 2026-10-24 scope cut:
name-based UUID versions 3 and 5, `cid()` generation, Cuid2 generation,
`id_integer()`, `id_time(class = "zutempo")`, Sqids numbers of 2⁵³ or
more, and Arrow and DuckDB interchange.

The design’s speed targets (§10) are a record, not a gate (D15).
`.agents/benchmarks.md` holds the measurements; most targets are not
met, and creating 10⁶ R strings alone takes about 680 ms on the
benchmark machine.

## Versions and dependents

The current version’s parent issue is
[\#2](https://github.com/pedrobtz/zuid/issues/2) for `v0.1.0`; the
CRAN-submission issue is
[\#15](https://github.com/pedrobtz/zuid/issues/15). Sibling packages
that depend on this one before CRAN does: none. The design names
consumers that will call the R functions (`zucbor`, `zumsgpack`, `qio`,
`zujson`, `mdbx`, `dastash`, `zudedup`, `openlineage`). A C API for
them, `inst/include/zuid.h`, is a later version, not v0.1.0.

## Commands

Maintainer tooling under `tools/`, run from the package root. None of
what these need is a package dependency.

``` sh
tools/gen-tables            # regenerate the Niceware and Sqids tables
tools/gen-tables --check    # verify only; exit 1 if a written file differs
tools/gen-fixtures          # encodings, UPID, SCRU128, SCRU64 oracles (Python)
node tools/gen-js-fixtures.mjs   # Sqids and CID oracles (JavaScript)
tools/gen-determinism       # rewrite tests/testthat/fixtures/determinism.txt
tools/run-benchmarks        # design §10 timings, as rows for benchmarks.md
tools/run-benchmarks baseline    # the uuid and ulid baselines only
```

- `tools/gen-tables` needs R 4.5 or later
  ([`tools::sha256sum`](https://rdrr.io/r/tools/sha256sum.html)) and
  `yaml`. It writes `R/sysdata.rda`, `src/zuid_tables.h` and
  `src/zuid_tables.c`.
- `tools/gen-fixtures` runs in a virtual environment holding exactly the
  Python versions pinned in `tools/fixture-sources.yaml`; its docstring
  has the `pip install` line. `tools/gen-js-fixtures.mjs` reads
  `ZUID_NODE_MODULES`; its header has the `npm install` line.
- `tools/gen-determinism` regenerates zuid’s own output. Run it only for
  a change that is meant to alter generated values, and review the diff
  line by line.
- `tools/run-benchmarks` needs `bench`, `uuid` and `ulid`.

## Architecture

Five layers (design §4):

1.  **Format descriptors**, `src/zuid_formats.c` and
    `src/zuid_formats.h`. One static record per format. The R surface
    reaches every format through this table, so a new format is a new
    row and a new `zuid_fmt_*.c`, never a new entry point. Snowflake
    layouts and SCRU64 node sizes are descriptors built at run time from
    [`id_layout()`](https://pedrobtz.github.io/zuid/reference/id_layout.md).
2.  **Encodings**, `src/zuid_enc*.c`. Codecs over bytes of any length. A
    UUID text form other than the hex ones is the 16-byte case of one of
    these.
3.  **Formats**, `src/zuid_fmt_*.c`, plus `src/zuid_sqids.c` and
    `src/zuid_cid.c`. Parse, validate and fields over the descriptor.
4.  **Generators**, `src/zuid_gen.c`. Pure functions of
    `(n, time, random bytes, node)` plus the monotonic state they are
    handed. `src/zuid_entropy.c` reads the clock and the operating
    system’s entropy source, for the R entry points only. Per-session
    monotonic state is one static struct, reset by `zuid_c_reset_state`.
5.  **The R surface**, `R/` and the R-facing C files `src/zuid_r*.c`.
    Vectorisation happens in C: one loop per operation, filling parallel
    output vectors that R assembles once.

Everything except `src/zuid_r*.c` and `src/zuid_init.c` is plain C11
with no R headers. That split is what lets the fuzz workflow build the
codecs without R (`tools/fuzz/harness.c`, `-DZUID_STANDALONE`).

`src/zuid_tables.c` (about 66,000 lines) and `src/zuid_tables.h` are
generated by `tools/gen-tables`. Never edit them by hand.

The `vctrs` methods in `R/zzz.R` are registered only when `vctrs` is
loaded, so zuid vectors combine in tibbles without `vctrs` being a
dependency. `vctrs` double-dispatches on the first class, so each format
registers its own pair.

## Invariants that are easy to break

- **No `Imports`.** After 0.1.0 other `zu*` packages become `Suggests`,
  checked with
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html); a missing
  one raises `zuid_dependency_error`. In v0.1.0 no `zu*` package is
  referenced at all.
- **Entropy comes from the operating system, never R’s RNG** (D5). An
  identifier must not change when a script calls
  [`set.seed()`](https://rdrr.io/r/base/Random.html). Tests that need
  fixed output pass `random` in.
- **Generators are pure functions of `(n, time, random, node)`** (D6).
  The clock and entropy are read once in the R entry point. Reading them
  inside a generator makes the fuzz target and the cross-platform
  byte-identity tests impossible. A call given both `time` and `random`
  leaves the session’s monotonic state alone.
- **128 bits do not make a UUID** (D3, D9).
  [`id_from_bytes()`](https://pedrobtz.github.io/zuid/reference/id_format.md)
  has no default format, and only `uuid` exports to Arrow as
  `arrow.uuid`; every other format uses `zuid.<format>`. A ULID arriving
  as `arrow.uuid` is the bug this prevents.
- **Detection never guesses** (D10). An encoding or syntactic format
  needs a hint; ambiguity among structured formats is `NA` with
  candidates.
- **Inspection never raises on input.**
  [`id_detect()`](https://pedrobtz.github.io/zuid/reference/id_detect.md),
  [`id_valid()`](https://pedrobtz.github.io/zuid/reference/id_parse.md),
  [`id_fields()`](https://pedrobtz.github.io/zuid/reference/id_fields.md),
  [`id_time()`](https://pedrobtz.github.io/zuid/reference/id_fields.md)
  and `id_parse(strict = FALSE)` return `NA`.
- **The only place a `CHARSXP` is made from bytes is one function** in
  `src/zuid_r.c`, so encoding and length rules live in one place.
- **The shared object exports `R_init_zuid` only.** `src/Makevars`
  passes `$(C_VISIBILITY)` to hide every `zuid_*` symbol, and
  `test-abi.R` checks the installed object. Internal native symbols use
  the `zuid_` prefix, and `.Call` entry points `zuid_c_`.
- **The codec files include no R headers.** Adding one breaks the fuzz
  build, which compiles every `src/*.c` except the R-facing files.
- **No vendored code** (D7). The Sqids blocklist and the Niceware word
  list are generated tables with source, date and SHA-256 in
  `tools/fixture-sources.yaml`, and their authors are listed as `cph` in
  `DESCRIPTION` and in `inst/COPYRIGHTS`.
- **TypeID’s fixtures stay out of the tarball.** They are Apache-2.0, so
  `.Rbuildignore` excludes `tests/testthat/fixtures/typeid`, and the
  tests that read them skip on CRAN and when the files are absent.

## Testing

The oracles are the thirteen of `.agents/design.md` §7: RFC 9562
Appendices A and B, TypeID’s `valid.yml` and `invalid.yml`, and the
ULID, UPID, SCRU, KSUID, XID, Sqids, Proquint, Niceware and CID
reference vectors, among others. They are stored under
`tests/testthat/fixtures/` at the commits and versions pinned in
`tools/fixture-sources.yaml`, and written by the `tools/gen-*` scripts
above.

`fixtures/determinism.txt` is zuid’s own output, not an oracle. It
guards that every platform produces the same bytes; the oracle tests
check that the bytes are right.

Helpers in `tests/testthat/helper-*.R`:

- `helper-abi.R`: the symbol audit, after zucrypt’s. It is a helper so
  that testthat’s parallel workers see it too.
- `helper-class.R`: three parsed UUIDs, the last missing.
- `helper-detect.R`: every collision design §6.2 names, as a table of
  string, hint, layout, expected format and candidates.
- `helper-determinism.R`: every generator and encoding on fixed inputs,
  as the lines of `determinism.txt`.
- `helper-enc.R`: the Go and Python encoding oracle.
- `helper-formats.R`: a small reader for TypeID’s YAML fixtures, since
  zuid has no YAML dependency.
- `helper-gen.R`: `local_fresh_state()`, which resets the per-session
  generation state for a test and again after it, and `hex_raw()`.
- `helper-uuid.R`: the RFC 9562 test vectors.

## Continuous integration

The package calls r-actions’ `r-cmd-check.yml`, `coverage.yml` and
`cran-release.yml`, `fuzz.yml` from `fuzz.yaml`, and from
`native-checks.yaml` the sanitizers, valgrind, LTO, gctorture, rchk,
analyzers and cran-special workflows. The pkgdown site is built by a
local `pkgdown.yaml`.

Deliberate deviations from `.claude/shared/ci.md`:

- **A push to `main` runs the full profile.** The callers pass `quick`
  only for a pull request without `full-ci`, not `profile: auto`. Don’t
  wait on the full run a merge starts; a failure only it shows goes on
  an issue with the run link.
- **`R-CMD-check.yaml` adds Windows R-devel**, CRAN’s
  r-devel-windows-x86_64 flavour, and the NOSUGGESTS and NOLD flavours,
  in the full profile only.
- **Fuzzing runs on every pull request**: two minutes, and an hour
  nightly and under `full-ci`. The seed corpus is `tools/fuzz/corpus`,
  drawn from the oracle fixtures, and the dictionary is
  `tools/fuzz/zuid.dict`. Every broken round trip aborts, which
  libFuzzer reports as a crash.
