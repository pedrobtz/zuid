/* Default tolerance (10 s): one frozen instant, chunked so memory stays small. */
#include "zuid_gen.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(void) {
    enum { CH = 1 << 16 };
    static int64_t ms[CH]; static uint8_t rnd[CH * 10]; static uint8_t out[CH * 16];
    for (int i = 0; i < CH; i++) ms[i] = 1700000000000LL;
    srand(1); for (int i = 0; i < CH * 10; i++) rnd[i] = (uint8_t) rand();
    zuid_uuid7_state st = {0}; uint8_t prev[16] = {0}; size_t total = 0; int found = 0;
    for (int c = 0; c < 1000 && !found; c++) {
        size_t bad = zuid_gen_uuid7(CH, ms, rnd, 10000, &st, out);
        if (bad) { printf("v7 overflow?\n"); return 1; }
        for (int i = 0; i < CH; i++) {
            if (memcmp(out + 16 * i, prev, 16) <= 0) { printf("v7: value %zu is not above its predecessor (tolerance 10000 ms, one instant)\n", total + i + 1); found = 1; break; }
            memcpy(prev, out + 16 * i, 16);
        }
        total += CH;
    }
    if (!found) printf("v7 held for %zu values\n", total);
    /* v1: same instant, count until a (tick, clock_seq) pair repeats */
    static int64_t tk[CH]; for (int i = 0; i < CH; i++) tk[i] = 0x01B21DD213814000LL + 17000000000000000LL;
    zuid_uuid1_state s1 = {0}; int cs = 5, cs0 = 5; uint8_t node[6] = {1,2,3,4,5,6};
    uint8_t first_back[16]; int have_back = 0; total = 0; found = 0; memset(prev, 0, 16);
    size_t first_drop = 0;
    for (int c = 0; c < 3000 && !found; c++) {
        size_t bad = zuid_gen_uuid_time(CH, 6, tk, &cs, node, 10000LL * 10000, &s1, out);
        if (bad) { printf("v6 err\n"); return 1; }
        for (int i = 0; i < CH; i++) {
            const uint8_t *b = out + 16 * i;
            if (!first_drop && memcmp(b, prev, 8) <= 0) { first_drop = total + i + 1; printf("v6: value %zu has a timestamp not above its predecessor; clock_seq now %d (was %d)\n", first_drop, cs, cs0); }
            memcpy(prev, b, 16);
            if (first_drop && ((cs - cs0) & 0x3fff) == 0 && s1.last_ticks == tk[0]) { printf("v6: value %zu repeats clock_seq %d at the starting tick: a duplicate of value 1\n", total + i + 1, cs); found = 1; break; }
        }
        total += CH;
    }
    return 0;
}
