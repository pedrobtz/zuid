source("hdr.R")
con <- file("p07.tsv", "w")
emit <- function(kind, x, ...) writeLines(paste(kind, as.character(x), ..., sep = "\t"), con)
set <- c(0, 1, 999.4, 1e12, 1.7e12 + 0.5, 1700000000123, 2^48 - 1, 2^47, 255, 256, 257, 1e12 + 255.999)
hex <- function(r) paste(as.character(r), collapse = "")
for (t in set) { tv1 <- min(t, 1e14 + 0.3)
  r10 <- as.raw(sample(0:255, 10, TRUE)); r16 <- as.raw(sample(0:255, 16, TRUE)); r8 <- as.raw(sample(0:255, 8, TRUE))
  emit("uuid7", uuid(1, 7, time = t, random = r10), sprintf("%.3f", t), hex(r10))
  emit("ulid", ulid(1, time = t, random = r10), sprintf("%.3f", t), hex(r10))
  emit("typeid", typeid(1, "user_x", time = t, random = r10), sprintf("%.3f", t), hex(r10))
  emit("upid", upid(1, "ab", time = t, random = r8), sprintf("%.3f", t), hex(r8))
  if (t >= 1 && t <= 2^48 - 2) emit("scru128", scru128(1, time = t, random = r10), sprintf("%.3f", t), hex(r10))
  if (t >= 256) for (nb in c(1, 8, 20, 23)) { r3 <- as.raw(sample(0:255, 3, TRUE)); if (t < 282429536480 * 256) emit("scru64", scru64(1, 2^nb - 1, nb, time = t, random = r3), sprintf("%.3f", t), hex(r3), nb) }
  nd <- as.raw(sample(0:255, 6, TRUE)); r2 <- as.raw(sample(0:255, 2, TRUE))
  emit("uuid1", uuid(1, 1, node = nd, time = tv1, random = r2), sprintf("%.3f", tv1), hex(r2), hex(nd))
  emit("uuid6", uuid(1, 6, node = nd, time = tv1, random = r2), sprintf("%.3f", tv1), hex(r2), hex(nd))
  emit("uuid4", uuid(1, 4, random = r16), "0", hex(r16)); emit("uuid8", uuid(1, 8, random = r16), "0", hex(r16))
}
for (t in c(1400000000000, 1400000000999, 1.7e12 + 999.9, (1400000000 + 2^32 - 1) * 1000 + 999)) {
  r16 <- as.raw(sample(0:255, 16, TRUE)); emit("ksuid", ksuid(1, time = t, random = r16), sprintf("%.3f", t), hex(r16)) }
for (t in c(0, 999, 1.7e12 + 999.9, (2^32 - 1) * 1000 + 999)) {
  r8 <- as.raw(sample(0:255, 8, TRUE)); r6 <- as.raw(sample(0:255, 6, TRUE))
  emit("objectid", objectid(1, time = t, random = r8), sprintf("%.3f", t), hex(r8))
  emit("xid", xid(1, process = 70000, time = t, random = r6), sprintf("%.3f", t), hex(r6)) }
# POSIXct route with microseconds
p <- as.POSIXct(1700000000.123456, origin = "1970-01-01", tz = "UTC")
emit("uuid7", uuid(1, 7, time = p, random = as.raw(1:10)), "1700000000123.456", hex(as.raw(1:10)))
emit("uuid1", uuid(1, 1, node = as.raw(1:6), time = p, random = as.raw(1:2)), "1700000000123.456", hex(as.raw(1:2)), hex(as.raw(1:6)))
emit("uuid6", uuid(1, 6, node = as.raw(1:6), time = -12219292800000, random = as.raw(1:2)), "-12219292800000.000", hex(as.raw(1:2)), hex(as.raw(1:6)))
emit("uuid1", uuid(1, 1, node = as.raw(1:6), time = -1.5, random = as.raw(1:2)), "-1.500", hex(as.raw(1:2)), hex(as.raw(1:6)))
emit("uuid1", uuid(1, 1, node = as.raw(1:6), time = 103072857660684.688, random = as.raw(1:2)), "103072857660684.688", hex(as.raw(1:2)), hex(as.raw(1:6)))
# live values
emit("live_uuid1", uuid(3, 1), sprintf("%.3f", as.numeric(Sys.time()) * 1000)); emit("live_uuid6", uuid(3, 6), sprintf("%.3f", as.numeric(Sys.time()) * 1000))
emit("live_uuid7", uuid(3, 7), sprintf("%.3f", as.numeric(Sys.time()) * 1000)); emit("live_ulid", ulid(3), sprintf("%.3f", as.numeric(Sys.time()) * 1000))
emit("live_scru128", scru128(3), sprintf("%.3f", as.numeric(Sys.time()) * 1000)); emit("live_ksuid", ksuid(3), sprintf("%.3f", as.numeric(Sys.time()) * 1000))
emit("live_objectid", objectid(3), sprintf("%.3f", as.numeric(Sys.time()) * 1000)); emit("live_upid", upid(3, "user"), sprintf("%.3f", as.numeric(Sys.time()) * 1000))
emit("live_scru64", scru64(3, 5, 8), sprintf("%.3f", as.numeric(Sys.time()) * 1000)); emit("live_xid", xid(3), sprintf("%.3f", as.numeric(Sys.time()) * 1000), Sys.getpid())
close(con)
