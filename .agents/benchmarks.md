# zuid benchmarks

Measured by `tools/run-benchmarks` against the targets of
[design.md](design.md) §10. The targets are a record, not a gate (D15).

## Baseline, Stage 0 (2026-10-24)

Before any zuid code exists. macOS Sequoia 15.7.9 (Apple silicon), R 4.5.2,
`uuid` 1.2-2, `ulid` 0.4.0; median of 5 iterations over 10⁶ elements.

| Operation, 10⁶ elements | Median |
| --- | --- |
| `uuid::UUIDgenerate(use.time = FALSE, n = )` (version 4) | 21019 ms |
| `uuid::UUIDgenerate(use.time = TRUE, n = )` (version 1) | 311 ms |
| `uuid::UUIDparse()` | 402 ms |
| `ulid::ULIDgenerate()` | 1471 ms |

`uuid` 1.2-2 has no version 7 generator, so the §10 row for
`id_uuid(version = 7)` compares against its version 4 and version 1 paths.
Its version 4 path is two orders of magnitude slower than its version 1 path
on this machine, so "within 1.5× of `uuid`" is met trivially there; the
absolute target, under 100 ms, is the one that binds.

## zuid, Stage 9 (2026-10-24)

The same machine; `tools/run-benchmarks`, zuid installed with R's usual
optimisation, median of 5 iterations over 10⁶ elements. The baselines on
this run were `uuid::UUIDparse()` 402 ms, `uuid::UUIDgenerate()` 330 ms
(version 1) and 21085 ms (version 4), and `ulid::ULIDgenerate()` 1902 ms.

| Operation, 10⁶ elements | Target (§10) | Median | Met |
| --- | --- | --- | --- |
| `id_parse()` of UUID strings | 150 ms; 1.5× `uuid` (603 ms) | 701 ms | no |
| `id_uuid(version = 7)` | 100 ms; 1.5× `uuid` | 1147 ms | no; beats `uuid`'s version 4 18× |
| `id_uuid(version = 4)` | (no row) | 942 ms | — |
| `id_ulid()` | 100 ms; faster than `ulid` | 359 ms | faster than `ulid` (5.3×) only |
| `id_format(form = "base62")` | 300 ms | 1123 ms | no |
| `id_format(form = "words")` | 200 ms | 934 ms | no |
| `id_parse()` of KSUID strings | 600 ms | 1504 ms | no |
| `id_detect()` of mixed strings | 300 ms | 2915 ms | no |
| `id_fields()` | 400 ms | 2056 ms | no |
| `id_sqids()` of single integers | 500 ms | 2786 ms | no |
| `id_bytes()` | 50 ms | 325 ms | no |
| `id_from_bytes()` | 50 ms | 282 ms | no |

What the numbers say, measured rather than guessed:

- **Making R strings is the floor.** `sprintf("%032x", seq_len(1e6))` takes
  680 ms on this machine, so every row that returns 10⁶ new strings
  (parsing, generating, `id_format()`, `id_from_bytes()`) costs most of
  that before zuid does any work. The §10 targets of 100 to 300 ms for those
  rows are below what R allows here; `uuid::UUIDparse()` is fast because it
  returns no strings. `id_fields()` makes three string columns.
- **Entropy is not the cost.** `getentropy()` fills 16 MB in 76 ms on macOS.
- **`id_bytes()` and `id_from_bytes()`** parse or write text for every
  element; 50 ms is the cost of copying the bytes alone.
- **Stage 9 fixed two hot spots** the first run showed: `id_detect()` made
  canonical text it threw away and built its result per element in R
  (8884 ms before), and `id_sqids()` compared blocklist words a character
  at a time and checked numbers per element in R (12249 ms before).
- The targets stay a record, not a gate (D15). `Full CI` and the
  readiness review can decide whether any is worth a design change, such as
  returning bytes rather than text from some calls.

