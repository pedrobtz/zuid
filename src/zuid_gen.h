#ifndef ZUID_GEN_H
#define ZUID_GEN_H

/* Generators (design.md section 4, layer 4). Each is a pure function of
 * (n, time, random bytes, node) plus the explicit monotonic state it is
 * handed; none reads the clock or the entropy source (D6). */

#include <stddef.h>
#include <stdint.h>

/* Entropy and clock, read by the R entry points only (zuid_entropy.c). */
int zuid_entropy(uint8_t *buf, size_t n); /* 0 on success */
const char *zuid_entropy_source(void);
int64_t zuid_clock_now_100ns(void);       /* since 1970 */

/* Per-session state for monotonic generation (design.md section 6.7). */
typedef struct {
    int has;          /* whether a value has been generated */
    int64_t last_ms;
    int counter;      /* the 12-bit rand_a counter */
} zuid_uuid7_state;

typedef struct {
    int has;
    int64_t last_ticks; /* 100 ns since 1582-10-15 */
} zuid_uuid1_state;

typedef struct {
    int has;
    int64_t last_ms;
    uint8_t random[10]; /* the last 80-bit random component */
} zuid_ulid_state;

#define ZUID_UUID7_RANDOM 10 /* bytes per value: 2 counter seed, 8 rand_b */

/* Versions 4 and 8: 16 bytes of `random` per value, version and variant set. */
void zuid_gen_uuid_random(size_t n, int version, const uint8_t *random,
                          uint8_t *out);

/* Version 7 at `ms[i]` (milliseconds since 1970), RFC 9562 section 6.2
 * method 1. A clock that runs back by up to `tolerance_ms` keeps the last
 * millisecond; further back, generation restarts at the new time. */
void zuid_gen_uuid7(size_t n, const int64_t *ms, const uint8_t *random,
                    int64_t tolerance_ms, zuid_uuid7_state *state,
                    uint8_t *out);

/* Versions 1 and 6 at `ticks[i]` (100 ns since 1582-10-15). A tick at or
 * before the last one is moved past it, unless the clock ran back by more
 * than `tolerance_ticks`, which increments the clock sequence instead
 * (RFC 9562 section 5.1). */
void zuid_gen_uuid_time(size_t n, int version, const int64_t *ticks,
                        int *clock_seq, const uint8_t node[6],
                        int64_t tolerance_ticks, zuid_uuid1_state *state,
                        uint8_t *out);

typedef struct {
    int has;
    uint64_t timestamp;     /* ms */
    uint32_t counter_hi, counter_lo;
    uint64_t ts_counter_hi; /* when counter_hi was last renewed */
} zuid_scru128_state;

typedef struct {
    int has;
    int node_bits;
    uint32_t node;
    uint64_t timestamp;  /* 256 ms ticks */
    uint32_t node_ctr;   /* node << counter bits | counter */
} zuid_scru64_state;

#define ZUID_SCRU128_RANDOM 10 /* 4 entropy, 3 counter_lo, 3 counter_hi */
#define ZUID_SCRU64_RANDOM 3
#define ZUID_KSUID_RANDOM 16
#define ZUID_ULID_RANDOM 10
#define ZUID_UPID_RANDOM 8

/* ULID at `ms[i]`, monotonic by the specification: at or before the last
 * millisecond (back by up to `tolerance_ms`), the last random component
 * plus one. Returns 0, or 1 + the index of the value whose increment
 * overflowed 80 bits; values before it are written. */
size_t zuid_gen_ulid(size_t n, const int64_t *ms, const uint8_t *random,
                     int64_t tolerance_ms, zuid_ulid_state *state,
                     uint8_t *out);

/* UPID at `ms[i]`: the time in 256 ms units, 8 random bytes per value, then
 * `tail`, the 20-bit prefix and 4-bit version. Not monotonic, as in the
 * reference. */
void zuid_gen_upid(size_t n, const int64_t *ms, const uint8_t *random,
                   const uint8_t tail[3], uint8_t *out);

/* SCRU128 at `ms[i]`, by the specification's generator: counter_lo is
 * renewed when the millisecond advances and incremented within it,
 * counter_hi renewed once the timestamp has moved a second past its last
 * renewal, and a counter overflow advances the timestamp. A clock back by
 * more than `tolerance_ms` returns 1 + its index unless `reset`, which
 * restarts the generator there (D18). */
size_t zuid_gen_scru128(size_t n, const int64_t *ms, const uint8_t *random,
                        int64_t tolerance_ms, int reset,
                        zuid_scru128_state *state, uint8_t *out);

/* SCRU64 at `ms[i]` for `node` of `node_bits` bits, by the reference
 * generator: the counter is renewed at each new 256 ms tick and incremented
 * within it, and an overflow advances the tick. Returns 0, 1 + the index of
 * a rollback beyond `tolerance_ms` (unless `reset`), or, negated, 1 + the
 * index of a tick past the largest timestamp. */
long zuid_gen_scru64(size_t n, const int64_t *ms, const uint8_t *random,
                     uint32_t node, int node_bits, int64_t tolerance_ms,
                     int reset, zuid_scru64_state *state, uint8_t *out);

/* KSUID at `ms[i]`: seconds since 1400000000 and 16 random bytes. */
void zuid_gen_ksuid(size_t n, const int64_t *ms, const uint8_t *random,
                    uint8_t *out);

#endif
