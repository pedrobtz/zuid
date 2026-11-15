# Assurance

How this package meets the shared `assurance.md` rules. CI checks this
file (r-actions `assurance.yml`), so keep the headings and table
columns as they are.

- **Statuses:** a cell is a fact, `gap #<issue>` or `n/a: <reason>`.
- **Kinds:** delete the ones that do not apply.
- **Tables:** delete a table only when no kind requires it. Delete the
  example rows.

Written 2026-11-15 from the tests, not the design. `lifecycle` is not
declared: nothing R holds outlives the call. Every value is a classed
character vector. The generators' monotonic state is session-static in
`src/zuid_r_gen.c` and `src/zuid_r_layout.c`. It has no fork guard (#88),
and two of its tables drop slots (#89, #90). Those are bugs, filed as such.

## Kinds

`compiled` `untrusted-input` `spec` `emits`

## Required checks

`Where` names the workflow file under `.github/workflows/` that runs the
check. Add `(own)` when that workflow is the package's own rather than a
call to r-actions.

| Check         | Status   | Where                             |
| ------------- | -------- | --------------------------------- |
| sanitizers    | done     | native-checks.yaml                |
| valgrind      | done     | native-checks.yaml                |
| rchk          | done     | native-checks.yaml                |
| gctorture     | done     | native-checks.yaml                |
| analyzers     | done     | native-checks.yaml                |
| alloc-failure | gap #91  | n/a: no workflow yet              |
| mutation      | gap #92  | n/a: no workflow yet              |
| fuzz          | done     | fuzz.yaml                         |
| fuzz-reach    | gap #93  | fuzz.yaml, with `reach-floor` 0   |

The fuzz harness, `tools/fuzz/harness.c`, has an oracle on every branch:
text to bytes to text for every format, decode and encode for every
encoding, Sqids numbers, and CID text and bytes. Each one aborts on a
round trip that does not hold.

## Boundaries

One row per boundary the package crosses. An oracle knows the answer:

- a conformance suite or test vectors;
- a reference implementation;
- a round trip;
- equivalent inputs compared;
- the bytes the other side received.

"No crash" is not an oracle.

<!-- markdownlint-disable MD013 -->
| Boundary                                     | Oracle                                                                                                       | Carried by                                                    |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| UUID text, decode (every hex form)           | RFC 9562 Appendix A and B examples; every hex form compared with the canonical text                          | tests/testthat/test-uuid-parse.R                              |
| UUID text, encode (every hex form)           | RFC 9562 examples; round trip over 10^4 values; fuzz round trip                                              | tests/testthat/test-uuid-parse.R, tests/testthat/test-bytes.R |
| UUID fields and time                         | RFC 9562 A.1, A.5 and A.6 field values                                                                       | tests/testthat/test-uuid-fields.R                             |
| UUID generation, versions 1, 4, 6, 7, 8      | RFC 9562 A.1, A.3, A.5, A.6, B.1 and B.2 regenerated from their stated inputs                                | tests/testthat/test-uuid-generate.R                           |
| Encodings, decode (12 forms)                 | Go and Python references (`fixtures/encodings.csv`); Niceware, Proquint and IETF draft vectors               | tests/testthat/test-encode.R                                  |
| Encodings, encode (12 forms)                 | the same references, encode direction; round trip 0 to 64 bytes and at 65536; fuzz round trip                | tests/testthat/test-encode.R                                  |
| Caller's alphabet, both directions           | ShortUUID reference for the default; round trip for other alphabets                                          | tests/testthat/test-encode.R                                  |
| ULID, decode and fields                      | ulid/spec README vectors and overflow rejection; python-ulid via `encodings.csv`                             | tests/testthat/test-ulid.R                                    |
| ULID, monotonic generation                   | ulid/spec's monotonic sequences                                                                              | tests/testthat/test-ulid.R                                    |
| TypeID, decode                               | jetify-com/typeid `valid.yml` and `invalid.yml`                                                              | tests/testthat/test-typeid.R                                  |
| TypeID, encode                               | `valid.yml`, encode direction                                                                                | tests/testthat/test-typeid.R                                  |
| UPID, both directions                        | Python upid 0.3.1 (`fixtures/upid.csv`) and its README example                                               | tests/testthat/test-upid.R                                    |
| SCRU128, both directions                     | Python scru128 3.0.4 (`fixtures/scru128.csv`); scru128/spec vectors and rejections                           | tests/testthat/test-scru128.R                                 |
| SCRU128, generation                          | the specification's counter and overflow rules                                                               | tests/testthat/test-scru128.R                                 |
| SCRU64, both directions                      | Python scru64 1.0.2 (`fixtures/scru64.csv`) and its rejections                                               | tests/testthat/test-scru64.R                                  |
| SCRU64, generation                           | the reference generator's sequence                                                                           | tests/testthat/test-scru64.R                                  |
| KSUID, both directions                       | segmentio/ksuid README vectors, minimum and maximum, rejections                                              | tests/testthat/test-ksuid.R                                   |
| XID, both directions                         | rs/xid `id_test.go` vectors and rejection                                                                    | tests/testthat/test-xid.R                                     |
| ObjectId, both directions                    | mongodb/specifications BSON corpus `oid.json`                                                                | tests/testthat/test-objectid.R                                |
| Snowflake, Twitter and Discord decode        | Discord's documented ID and Twitter's published Tweet times                                                  | tests/testthat/test-snowflake.R                               |
| Snowflake, generation                        | a value worked out by hand; round trip under every built-in layout                                           | tests/testthat/test-snowflake.R                               |
| Sonyflake, decode and generate               | round trip only, which a misplaced field passes                                                              | gap #94                                                       |
| NanoID, generation                           | nanoid 6.0.2 `customRandom` vectors                                                                          | tests/testthat/test-nanoid.R                                  |
| Cuid2, validate                              | cases written by hand from the reference's rules                                                             | gap #95                                                       |
| Sqids, both directions                       | sqids-spec encoding, min_length, blocklist and alphabet tests; JavaScript sqids 0.3.0 (`fixtures/sqids.csv`) | tests/testthat/test-sqids.R                                   |
| CID, decode                                  | js-multiformats 13.3.1 in 17 multibases (`fixtures/cid.csv`); go-cid string vectors                          | tests/testthat/test-cid.R                                     |
| CID, encode                                  | `fixtures/cid.csv` bytes; round trip through bytes; fuzz round trip                                          | tests/testthat/test-cid.R                                     |
| Niceware and Sqids tables                    | SHA-256 and entry counts of the pinned upstream files                                                        | tests/testthat/test-info.R                                    |
| Detection                                    | design.md section 6.2, every collision it names                                                              | tests/testthat/test-detect.R                                  |
| Byte identity across platforms               | zuid's own output for fixed inputs (`fixtures/determinism.txt`), on every CI leg; not a correctness oracle   | tests/testthat/test-determinism.R                             |
<!-- markdownlint-enable MD013 -->

## Limits

One row per limit the package enforces. "Straddled by" is the test of
`limit - 1`, `limit` and `limit + 1` on every path that reaches it.

<!-- markdownlint-disable MD013 -->
| Limit                                         | Unit                       | Straddled by                                                                  |
| --------------------------------------------- | -------------------------- | ----------------------------------------------------------------------------- |
| `MAX_BYTES` 65536, encode input               | bytes                      | tests/testthat/test-encode.R (0 to 64 and 65536 round-trip, 65537 refused)    |
| `MAX_BYTES` 65536, decode output and `width`  | bytes                      | gap #97                                                                       |
| caller's alphabet, 2 to 94 symbols            | symbols                    | gap #96                                                                       |
| TypeID prefix, 63                             | characters                 | tests/testthat/test-typeid.R (63 accepted, 64 refused; `invalid.yml`)         |
| `nanoid(size)`, 1 to 65536                    | characters                 | gap #96                                                                       |
| Cuid2, 2 to 32                                | characters                 | gap #96                                                                       |
| `sqids(min_length)`, 0 to 255                 | characters                 | gap #96                                                                       |
| Sqids numbers, 2^53 - 1                       | value                      | tests/testthat/test-sqids.R (2^53 - 1 encodes, 2^53 refused)                  |
| SCRU64 `node_bits`, 1 to 23                   | bits                       | gap #96                                                                       |
| layout sequence, 31                           | bits                       | gap #96                                                                       |
| layout field width, 1 to 53; total 63 or 64   | bits                       | gap #96                                                                       |
| generator time range, per format              | ms, 256 ms, s, µs          | gap #98                                                                       |
| counter overflow (ULID, v7, SCRU128, SCRU64, Snowflake sequence) | values in one tick | tests/testthat/test-ulid.R, tests/testthat/test-uuid-generate.R, tests/testthat/test-scru128.R, tests/testthat/test-scru64.R, tests/testthat/test-snowflake.R |
| `zuid.time_tolerance`, strict validation      | seconds                    | tests/testthat/test-uuid-parse.R, tests/testthat/test-strict-time.R           |
| `zuid.clock_tolerance`, rollback              | ms                         | tests/testthat/test-uuid-generate.R, tests/testthat/test-snowflake.R, tests/testthat/test-scru64.R |
| `SNOWFLAKE_STATES` 16                         | layouts per session        | gap #89                                                                       |
| `SCRU64_STATES` 16                            | (node, node_bits) pairs    | gap #90                                                                       |
| stack-to-heap switches: hex 256, radix 64 limbs, Sqids blocklist 512 | characters, limbs | gap #99                                                    |
<!-- markdownlint-enable MD013 -->
