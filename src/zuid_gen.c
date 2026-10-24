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

void zuid_gen_uuid7(size_t n, const int64_t *ms, const uint8_t *random,
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
            /* Overflow: borrow the next millisecond, as RFC 9562 allows. */
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
}

void zuid_gen_uuid_time(size_t n, int version, const int64_t *ticks,
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
}
