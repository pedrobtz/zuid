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

## zuid

Rows are added by the stages that build each operation (Stage 9 fills the
rest).
