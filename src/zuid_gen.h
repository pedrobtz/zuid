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

#endif
