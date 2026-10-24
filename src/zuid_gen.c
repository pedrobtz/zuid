#include "zuid_gen.h"

#include <string.h>

static void set_version_variant(uint8_t *b, int version)
{
    b[6] = (uint8_t) ((b[6] & 0x0f) | (version << 4));
    b[8] = (uint8_t) ((b[8] & 0x3f) | 0x80);
}

void zuid_gen_uuid_random(size_t n, int version, const uint8_t *random,
                          uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        uint8_t *b = out + 16 * i;
        memcpy(b, random + 16 * i, 16);
        set_version_variant(b, version);
    }
}

/* A fresh counter: 12 bits with the top bit clear, so it can count at least
 * 2048 values before it overflows (RFC 9562 section 6.2). */
static int counter_seed(const uint8_t *r)
{
    return ((r[0] << 8) | r[1]) & 0x07ff;
}

#define MAX48 INT64_C(0xffffffffffff)

size_t zuid_gen_uuid7(size_t n, const int64_t *ms, const uint8_t *random,
                      int64_t tolerance_ms, zuid_uuid7_state *state,
                      uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        const uint8_t *r = random + ZUID_UUID7_RANDOM * i;
        int64_t t = ms[i];
        if (!state->has || t > state->last_ms ||
            t < state->last_ms - tolerance_ms) {
            state->last_ms = t;
            state->counter = counter_seed(r);
            state->has = 1;
        } else if (++state->counter > 0x0fff) {
            /* Overflow: borrow the next millisecond, as RFC 9562 allows,
             * unless this is the last one the field holds. The state stays
             * at the maximum so the next call fails too. */
            if (state->last_ms >= MAX48) {
                state->counter = 0x0fff;
                return i + 1;
            }
            state->last_ms++;
            state->counter = counter_seed(r);
        }
        uint64_t m = (uint64_t) state->last_ms;
        uint8_t *b = out + 16 * i;
        for (int k = 0; k < 6; k++) {
            b[k] = (uint8_t) (m >> (40 - 8 * k));
        }
        b[6] = (uint8_t) (state->counter >> 8);
        b[7] = (uint8_t) (state->counter & 0xff);
        memcpy(b + 8, r + 2, 8);
        set_version_variant(b, 7);
    }
    return 0;
}

#define MAX60 INT64_C(0x0fffffffffffffff)

size_t zuid_gen_uuid_time(size_t n, int version, const int64_t *ticks,
                          int *clock_seq, const uint8_t node[6],
                          int64_t tolerance_ticks, zuid_uuid1_state *state,
                          uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        int64_t t = ticks[i];
        if (state->has && t <= state->last_ticks) {
            if (state->last_ticks - t > tolerance_ticks) {
                *clock_seq = (*clock_seq + 1) & 0x3fff;
            } else {
                t = state->last_ticks + 1;
            }
        }
        if (t < 0 || t > MAX60) return i + 1;
        state->last_ticks = t;
        state->has = 1;

        uint64_t u = (uint64_t) t;
        uint8_t *b = out + 16 * i;
        if (version == 1) {
            uint32_t low = (uint32_t) (u & 0xffffffffu);
            uint16_t mid = (uint16_t) ((u >> 32) & 0xffff);
            uint16_t hi = (uint16_t) ((u >> 48) & 0x0fff);
            b[0] = (uint8_t) (low >> 24);
            b[1] = (uint8_t) (low >> 16);
            b[2] = (uint8_t) (low >> 8);
            b[3] = (uint8_t) low;
            b[4] = (uint8_t) (mid >> 8);
            b[5] = (uint8_t) mid;
            b[6] = (uint8_t) (hi >> 8);
            b[7] = (uint8_t) hi;
        } else {
            uint32_t high = (uint32_t) (u >> 28);
            uint16_t mid = (uint16_t) ((u >> 12) & 0xffff);
            uint16_t low = (uint16_t) (u & 0x0fff);
            b[0] = (uint8_t) (high >> 24);
            b[1] = (uint8_t) (high >> 16);
            b[2] = (uint8_t) (high >> 8);
            b[3] = (uint8_t) high;
            b[4] = (uint8_t) (mid >> 8);
            b[5] = (uint8_t) mid;
            b[6] = (uint8_t) (low >> 8);
            b[7] = (uint8_t) low;
        }
        b[8] = (uint8_t) (*clock_seq >> 8);
        b[9] = (uint8_t) (*clock_seq & 0xff);
        memcpy(b + 10, node, 6);
        set_version_variant(b, version);
    }
    return 0;
}

size_t zuid_gen_ulid(size_t n, const int64_t *ms, const uint8_t *random,
                     int64_t tolerance_ms, zuid_ulid_state *state,
                     uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        int64_t t = ms[i];
        if (!state->has || t > state->last_ms ||
            t < state->last_ms - tolerance_ms) {
            state->last_ms = t;
            memcpy(state->random, random + ZUID_ULID_RANDOM * i, 10);
            state->has = 1;
        } else {
            int k = 9;
            while (k >= 0 && ++state->random[k] == 0) k--;
            if (k < 0) {
                /* All ones plus one: the specification's overflow. Leave the
                 * component at its maximum so the next call fails too. */
                memset(state->random, 0xff, 10);
                return i + 1;
            }
        }
        uint64_t m = (uint64_t) state->last_ms;
        uint8_t *b = out + 16 * i;
        for (int k = 0; k < 6; k++) b[k] = (uint8_t) (m >> (40 - 8 * k));
        memcpy(b + 6, state->random, 10);
    }
    return 0;
}

void zuid_gen_upid(size_t n, const int64_t *ms, const uint8_t *random,
                   const uint8_t tail[3], uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        uint64_t t = (uint64_t) ms[i] >> 8;
        uint8_t *b = out + 16 * i;
        for (int k = 0; k < 5; k++) b[k] = (uint8_t) (t >> (32 - 8 * k));
        memcpy(b + 5, random + ZUID_UPID_RANDOM * i, 8);
        memcpy(b + 13, tail, 3);
    }
}

static uint32_t load24(const uint8_t *r)
{
    return (uint32_t) r[0] << 16 | (uint32_t) r[1] << 8 | r[2];
}

static void store_be(uint8_t *b, uint64_t v, int n)
{
    for (int k = 0; k < n; k++) b[k] = (uint8_t) (v >> (8 * (n - 1 - k)));
}

#define MAX24 UINT32_C(0xffffff)

long zuid_gen_scru128(size_t n, const int64_t *ms, const uint8_t *random,
                      int64_t tolerance_ms, int reset,
                      zuid_scru128_state *state, uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        const uint8_t *r = random + ZUID_SCRU128_RANDOM * i;
        uint64_t t = (uint64_t) ms[i];
        if (!state->has) {
            memset(state, 0, sizeof *state);
            state->has = 1;
        }
        if (t > state->timestamp) {
            state->timestamp = t;
            state->counter_lo = load24(r + 4);
        } else if (t + (uint64_t) tolerance_ms >= state->timestamp) {
            /* A small rollback keeps the last timestamp. */
            if (++state->counter_lo > MAX24) {
                state->counter_lo = 0;
                if (++state->counter_hi > MAX24) {
                    state->counter_hi = 0;
                    state->timestamp++;
                    state->counter_lo = load24(r + 4);
                }
            }
        } else if (reset) {
            memset(state, 0, sizeof *state);
            state->has = 1;
            state->timestamp = t;
            state->counter_lo = load24(r + 4);
        } else {
            return (long) i + 1;
        }
        /* 2^48 - 1 is reserved, so an overflow cannot move there. */
        if (state->timestamp >= (uint64_t) MAX48) return -((long) i + 1);
        if (state->timestamp - state->ts_counter_hi >= 1000 ||
            state->ts_counter_hi < 1) {
            state->ts_counter_hi = state->timestamp;
            state->counter_hi = load24(r + 7);
        }
        uint8_t *b = out + 16 * i;
        store_be(b, state->timestamp, 6);
        store_be(b + 6, state->counter_hi, 3);
        store_be(b + 9, state->counter_lo, 3);
        memcpy(b + 12, r, 4);
    }
    return 0;
}

#define SCRU64_MAX_TS UINT64_C(282429536480)

long zuid_gen_scru64(size_t n, const int64_t *ms, const uint8_t *random,
                     uint32_t node, int node_bits, int64_t tolerance_ms,
                     int reset, zuid_scru64_state *state, uint8_t *out)
{
    int counter_bits = 24 - node_bits;
    uint32_t mask = (UINT32_C(1) << counter_bits) - 1;
    /* The reference keeps one bit back as an overflow guard when the
     * counter has four bits or fewer. */
    int guard = counter_bits <= 4 ? 1 : 0;
    uint64_t allowance = (uint64_t) tolerance_ms >> 8;
    /* The caller keeps one state per (node, node_bits); a fresh one starts
     * here. */
    if (!state->has) {
        state->has = 1;
        state->node = node;
        state->node_bits = node_bits;
        state->timestamp = 0;
        state->node_ctr = node << counter_bits;
    }
    for (size_t i = 0; i < n; i++) {
        uint32_t renew = load24(random + ZUID_SCRU64_RANDOM * i) &
                         (mask >> guard);
        uint64_t t = (uint64_t) ms[i] >> 8;
        if (t > state->timestamp) {
            state->timestamp = t;
            state->node_ctr = node << counter_bits | renew;
        } else if (t + allowance >= state->timestamp) {
            if ((state->node_ctr & mask) < mask) {
                state->node_ctr++;
            } else {
                state->timestamp++;
                state->node_ctr = node << counter_bits | renew;
            }
        } else if (reset) {
            state->timestamp = t;
            state->node_ctr = node << counter_bits | renew;
        } else {
            return (long) i + 1;
        }
        if (state->timestamp >= SCRU64_MAX_TS) return -((long) i + 1);
        store_be(out + 8 * i, state->timestamp << 24 | state->node_ctr, 8);
    }
    return 0;
}

#define KSUID_EPOCH INT64_C(1400000000)

void zuid_gen_ksuid(size_t n, const int64_t *ms, const uint8_t *random,
                    uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        int64_t s = ms[i] / 1000 - (ms[i] % 1000 < 0);
        uint8_t *b = out + 20 * i;
        store_be(b, (uint64_t) (s - KSUID_EPOCH), 4);
        memcpy(b + 4, random + ZUID_KSUID_RANDOM * i, 16);
    }
}

static uint64_t mask_bits(int w)
{
    return w >= 64 ? UINT64_MAX : (UINT64_C(1) << w) - 1;
}

long zuid_gen_snowflake(size_t n, const int64_t *ticks,
                        const zuid_layout_spec *spec, const uint64_t *node,
                        int64_t tolerance_ticks, int reset,
                        zuid_snowflake_state *state, uint8_t *out)
{
    int time_w = 0, seq_w = 0;
    for (int k = 0; k < spec->nparts; k++) {
        if (spec->kind[k] == ZUID_PART_TIME) time_w = spec->width[k];
        if (spec->kind[k] == ZUID_PART_SEQUENCE) seq_w = spec->width[k];
    }
    /* One state per layout, shared by every node value: a sequence number
     * is never reused within a tick, whichever node asks. */
    if (!state->has || memcmp(&state->spec, spec, sizeof *spec) != 0) {
        memset(state, 0, sizeof *state);
        state->spec = *spec;
        state->last_tick = -1;
        state->last_clock = -1;
        state->has = 1;
    }
    for (size_t i = 0; i < n; i++) {
        int64_t t = ticks[i];
        if (t < state->last_clock - tolerance_ticks) {
            if (!reset) return (long) i + 1;
            state->last_clock = t;
            state->last_tick = t - 1;
        }
        if (t > state->last_clock) state->last_clock = t;
        if (t > state->last_tick) {
            state->last_tick = t;
            state->sequence = 0;
        } else if (++state->sequence > mask_bits(seq_w)) {
            state->last_tick++;
            state->sequence = 0;
        }
        if ((uint64_t) state->last_tick > mask_bits(time_w)) {
            return -((long) i + 1);
        }
        uint64_t v = 0;
        for (int k = 0; k < spec->nparts; k++) {
            uint64_t part = spec->kind[k] == ZUID_PART_TIME
                                ? (uint64_t) state->last_tick
                            : spec->kind[k] == ZUID_PART_SEQUENCE
                                ? state->sequence
                                : node[k];
            v = (spec->width[k] >= 64 ? 0 : v << spec->width[k]) |
                (part & mask_bits(spec->width[k]));
        }
        store_be(out + 8 * i, v, 8);
    }
    return 0;
}

void zuid_layout_unpack(const uint8_t *bytes, const zuid_layout_spec *spec,
                        uint64_t *parts)
{
    uint64_t v = 0;
    for (int i = 0; i < 8; i++) v = v << 8 | bytes[i];
    for (int k = spec->nparts - 1; k >= 0; k--) {
        int w = spec->width[k];
        parts[k] = v & mask_bits(w);
        v = w >= 64 ? 0 : v >> w;
    }
}

void zuid_gen_xid(size_t n, const int64_t *secs, const uint8_t middle[5],
                  zuid_counter_state *counter, uint8_t *out)
{
    for (size_t i = 0; i < n; i++) {
        uint8_t *b = out + 12 * i;
        store_be(b, (uint64_t) secs[i], 4);
        memcpy(b + 4, middle, 5);
        store_be(b + 9, counter->counter, 3);
        counter->counter = (counter->counter + 1) & MAX24;
    }
}
