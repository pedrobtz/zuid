// Write tests/testthat/fixtures/sqids.csv and cid.csv from the JavaScript
// references (design.md section 7, oracles 9 and 12), with the versions
// pinned in tools/fixture-sources.yaml:
//
//   (cd /tmp/zuid-js && npm install --ignore-scripts sqids@0.3.0 \
//     multiformats@13.3.1)
//   ZUID_NODE_MODULES=/tmp/zuid-js/node_modules node tools/gen-js-fixtures.mjs
//

import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

// The packages export ES modules only, so they are imported by file.
const from = (path) =>
  import(pathToFileURL(join(process.env.ZUID_NODE_MODULES, path)).href);
const Sqids = (await from("sqids/esm/sqids.js")).default;
const { CID } = await from("multiformats/dist/src/cid.js");
const { bases } = await from("multiformats/dist/src/basics.js");
const Digest = await from("multiformats/dist/src/hashes/digest.js");

// A seeded generator, so the fixtures are the same on every run.
let seed = 20261024n;
const next = () => {
  seed = (seed * 6364136223846793005n + 1442695040888963407n) & ((1n << 64n) - 1n);
  return Number(seed >> 33n);
};
const randInt = (n) => next() % n;
const randBytes = (n) => Uint8Array.from({ length: n }, () => next() & 0xff);
const hex = (b) => Buffer.from(b).toString("hex");
const csv = (rows) => rows.map((r) => r.join(",")).join("\n") + "\n";

// ---- Sqids ------------------------------------------------------------------

const MAX = Number.MAX_SAFE_INTEGER;
const magnitudes = [10, 100, 1e4, 1e6, 1e9, 1e12, 2 ** 40, MAX];
const number = () => {
  const m = magnitudes[randInt(magnitudes.length)];
  const f = next() / 2 ** 31 + next() / 2 ** 62;
  return Math.min(MAX, Math.floor(f * m));
};
const alphabets = [
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
  "0123456789abcdef",
  "abc",
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:'/?.><`~",
];
const sqidsRows = [["alphabet", "min_length", "numbers", "id"]];
for (const alphabet of alphabets) {
  for (const minLength of [0, 1, 5, 12, 30, 80]) {
    const s = new Sqids({ alphabet, minLength });
    for (let k = 0; k < 12; k++) {
      const count = 1 + randInt(5);
      const numbers = Array.from({ length: count }, number);
      if (k === 0) numbers[0] = 0;
      if (k === 1) numbers[0] = MAX;
      // An exhausted alphabet is a case too: zuid raises zuid_encode_error.
      let id;
      try {
        id = s.encode(numbers);
      } catch {
        id = null;
      }
      // No alphabet holds a comma or a double quote, so quoting is enough.
      sqidsRows.push([
        JSON.stringify(alphabet),
        minLength,
        numbers.join(" "),
        id === null ? "NA" : JSON.stringify(id),
      ]);
    }
  }
}
writeFileSync("tests/testthat/fixtures/sqids.csv", csv(sqidsRows));

// ---- CID --------------------------------------------------------------------

const codecs = { raw: 0x55, "dag-pb": 0x70, "dag-cbor": 0x71, "dag-json": 0x0129, json: 0x0200 };
const hashes = { "sha2-256": [0x12, 32], "sha2-512": [0x13, 64], blake3: [0x1e, 32], identity: [0x00, -1] };
const baseNames = [
  "base16", "base16upper", "base32", "base32upper", "base32pad", "base32padupper",
  "base32hex", "base32hexupper", "base32hexpad", "base32hexpadupper", "base36",
  "base36upper", "base58btc", "base64", "base64pad", "base64url", "base64urlpad",
];
const cidRows = [["text", "version", "codec", "hash", "digest", "bytes"]];
for (let k = 0; k < 40; k++) {
  const codec = Object.keys(codecs)[k % 5];
  const hash = Object.keys(hashes)[randInt(4)];
  const [code, len] = hashes[hash];
  const digest = randBytes(len < 0 ? randInt(40) : len);
  const cid = CID.createV1(codecs[codec], Digest.create(code, digest));
  for (const b of baseNames) {
    cidRows.push([cid.toString(bases[b]), 1, codec, hash, hex(digest), hex(cid.bytes)]);
  }
  if (codec === "dag-pb" && hash === "sha2-256") {
    const v0 = CID.createV0(Digest.create(code, digest));
    cidRows.push([v0.toString(), 0, codec, hash, hex(digest), hex(v0.bytes)]);
  }
}
for (let k = 0; k < 10; k++) {
  const digest = randBytes(32);
  const v0 = CID.createV0(Digest.create(0x12, digest));
  cidRows.push([v0.toString(), 0, "dag-pb", "sha2-256", hex(digest), hex(v0.bytes)]);
}
writeFileSync("tests/testthat/fixtures/cid.csv", csv(cidRows));
console.error("wrote sqids.csv and cid.csv");
