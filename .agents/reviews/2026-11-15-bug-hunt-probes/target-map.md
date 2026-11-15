# zuid target map (commit df17861)

Boundaries (from .agents/assurance.md, PR #100): UUID hex forms (decode, encode, fields, generation v1/4/6/7/8);
12 encodings + caller alphabet (hex, base32 Crockford, base32rfc, base32hex, base36, base58, base62, base62sort,
base64url, base64sort, alphabet, proquint, words/Niceware); ULID; TypeID; UPID; SCRU128; SCRU64; KSUID; XID;
ObjectId; Snowflake (twitter, discord, sonyflake, custom layouts); NanoID; Cuid2 (validate only); Sqids; CID;
detection (design §6.2). Weak oracles: Sonyflake (round trip only), Cuid2 (hand-written), Snowflake generation.

Limits: MAX_BYTES 65536 (src/zuid_r_enc.c); ZUID_TEXT_BUF 256, ZUID_MAX_WIDTH 32, ZUID_PREFIX_MAX 63
(src/zuid_formats.h); STACK_LIMBS 64 (zuid_enc_radix.c); hex stack 256 (zuid_enc.c:190); Sqids blocklist stack 512
(zuid_sqids.c:113); ZUID_SQIDS_MAX_MIN_LENGTH 255; SNOWFLAKE_STATES 16; SCRU64_STATES 16; ZUID_LAYOUT_PARTS 8;
alphabet 2..94 symbols; nanoid size 1..65536; cuid2 2..32; node_bits 1..23; layout sequence <=31, widths 1..53,
total 63/64; Sqids numbers <= 2^53-1; generator time ranges per format; zuid.time_tolerance, zuid.clock_tolerance.

Long-lived objects: none returned (classed character vectors). Session-static monotonic state in
src/zuid_r_gen.c and src/zuid_r_layout.c.

Numbers into C: ~36 sites of as.integer()/Rf_asInteger()/INTEGER() in R/ and src/zuid_r*.c.

Platform branches: src/zuid_entropy.c (_WIN32, __linux__, __APPLE__). Built here: __APPLE__ only.

Weakest (assurance gaps): #91 alloc failure, #92 mutation, #93 fuzz reach, #94 Sonyflake, #95 Cuid2,
#96 argument bounds one-sided, #97 decode cap/width, #98 generator time ranges, #99 stack-to-heap switches.
