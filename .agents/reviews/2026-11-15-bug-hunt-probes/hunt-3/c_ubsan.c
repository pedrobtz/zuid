/* Core generators under ASan+UBSan: boundary states and tolerances. */
#include "zuid_gen.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
int main(void) {
    enum { N = 5000 };
    static int64_t ms[N]; static uint8_t rnd[N * 16]; static uint8_t out[N * 20];
    for (int i = 0; i < N * 16; i++) rnd[i] = (uint8_t) rand();
    int64_t times[] = {0, 1, 255, 256, 0xffffffffffffLL - 1, 0xffffffffffffLL};
    int64_t tols[] = {0, 1, 10000, INT64_MAX / 2, INT64_MAX};
    for (unsigned a = 0; a < 6; a++) for (unsigned b = 0; b < 5; b++) {
        for (int i = 0; i < N; i++) ms[i] = times[a] - (i % 3 == 2 ? (times[a] > 20000 ? 20000 : 0) : 0);
        zuid_uuid7_state s7 = {0}; zuid_gen_uuid7(N, ms, rnd, tols[b], &s7, out);
        zuid_ulid_state su = {0}; zuid_gen_ulid(N, ms, rnd, tols[b], &su, out);
        zuid_scru128_state s128 = {0}; if (times[a] > 0) zuid_gen_scru128(N, ms, rnd, tols[b], b & 1, &s128, out);
        for (int nb = 1; nb <= 23; nb += 11) { zuid_scru64_state s64 = {0}; if (times[a] >= 256) zuid_gen_scru64(N, ms, rnd, 1, nb, tols[b], b & 1, &s64, out); }
        zuid_uuid1_state s1 = {0}; int cs = 0x3fff; uint8_t node[6] = {1,2,3,4,5,6};
        zuid_gen_uuid_time(N, 1, ms, &cs, node, tols[b], &s1, out);
        zuid_gen_ksuid(N, ms, rnd, out); uint8_t tail[3] = {1, 2, 3}; zuid_gen_upid(N, ms, rnd, tail, out);
        zuid_layout_spec sp; memset(&sp, 0, sizeof sp); sp.nparts = 3; sp.width[0] = 53; sp.kind[0] = ZUID_PART_TIME; sp.width[1] = 10; sp.kind[1] = ZUID_PART_NODE; sp.width[2] = 1; sp.kind[2] = ZUID_PART_SEQUENCE;
        zuid_snowflake_state ss; memset(&ss, 0, sizeof ss); uint64_t nodes[8] = {0, 1023, 0};
        zuid_gen_snowflake(N, ms, &sp, nodes, tols[b], b & 1, &ss, out);
        zuid_counter_state c = {1, 0xfffffe}; zuid_gen_xid(N, ms, node, &c, out);
    }
    puts("done");
    return 0;
}
