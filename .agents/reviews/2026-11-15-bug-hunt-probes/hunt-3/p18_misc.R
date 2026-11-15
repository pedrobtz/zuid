source("hdr.R")
T0 <- 1.7e12
cat("uuid(1, 7, namespace='x', name='y'):", try_class(uuid(1, 7, namespace = "x", name = "y")), "(silently ignored)\n")
for (v in list(2, 3, 5, 0, 9, 7.5, NA, "7", c(4, 7))) cat("version", deparse(v), "->", sub("/.*", "", try_class(uuid(1, v))), "\n")
cat("v8 without random:", sub("/.*", "", try_class(uuid(1, 8))), " v4 node:", sub("/.*", "", try_class(uuid(1, 4, node = as.raw(1:6)))), " node 5 bytes:", sub("/.*", "", try_class(uuid(1, 1, node = as.raw(1:5)))), "\n")
x <- xid(2, machine = as.raw(c(9, 8, 7)), random = as.raw(1:6), time = T0); print(id_fields(x)[, c("node", "process", "sequence")])
x <- xid(1, machine = as.raw(c(9, 8, 7)), process = 2^31 + 5); print(id_fields(x)[, c("node", "process")])
for (p in list(-1, 1.5, NA, "a", 65536, 2^53)) cat("xid process", deparse(p), "->", sub("/.*", "", try_class(xid(1, process = p))), "\n")
# cross-call monotonicity, real clock, interleaved
reset(); v7 <- character(); v6 <- character(); v1t <- numeric(); ul <- character(); s128 <- character(); s64 <- character(); sn <- character(); tw <- id_layout("twitter")
for (i in 1:3000) { n <- sample(1:5, 1)
  v7 <- c(v7, as.character(uuid(n))); v6 <- c(v6, as.character(uuid(n, 6))); a <- uuid(n, 1); ul <- c(ul, as.character(ulid(n))); s128 <- c(s128, as.character(scru128(n)))
  s64 <- c(s64, as.character(scru64(n, 3, 8))); sn <- c(sn, as.character(snowflake(n, tw, list(datacenter = 1, worker = i %% 32))))
  v6 <- c(v6, as.character(id_convert(a, "uuid")))[seq_len(length(v6))]
  v1t <- c(v1t, as.character(a)) }
chk("v7 strictly increasing over 3000 interleaved calls", sorted_strict(v7)); chk("v6 strictly increasing", sorted_strict(v6)); chk("ulid strictly increasing", sorted_strict(ul))
chk("scru128 strictly increasing", sorted_strict(s128)); chk("scru64 strictly increasing", sorted_strict(s64)); chk("v1 unique", !anyDuplicated(v1t))
snn <- as.numeric(sn); chk("snowflake unique and increasing across workers (shared sequence)", !anyDuplicated(sn) && all(nchar(sn) == nchar(sn[1])) && sorted_strict(sn))
# v1 and v6 interleaved share the tick state: timestamps strictly increase across both
reset(); a <- uuid(3, 1); b <- uuid(3, 6); a2 <- uuid(3, 1)
tk <- function(x) { h <- gsub("-", "", as.character(x)); v <- substr(h, 13, 13); ifelse(v == "1", paste0(substr(h, 14, 16), substr(h, 9, 12), substr(h, 1, 8)), paste0(substr(h, 1, 12), substr(h, 14, 16))) }
chk("v1/v6 interleaved: ticks strictly increasing", sorted_strict(c(tk(a), tk(b), tk(a2))))
# 17 layouts, real clock, unit 's'
reset(); mk <- function(i) id_layout(time = list(bits = 41, unit = "s", epoch = i * 1000), fields = list(worker = 10), sequence = 12)
Ls <- lapply(0:16, mk); out <- character(); for (rep in 1:3) for (L in Ls) out <- c(out, paste(L$epoch, as.character(snowflake(1, L, 1))))
cat("real clock, 17 layouts (unit s) round-robin x3: duplicated ids:", sum(duplicated(out)), "of", length(out), "\n")
reset(); Ls <- lapply(0:15, mk); out <- character(); for (rep in 1:3) for (L in Ls) out <- c(out, paste(L$epoch, as.character(snowflake(1, L, 1))))
cat("real clock, 16 layouts (unit s) round-robin x3: duplicated ids:", sum(duplicated(out)), "\n")
# n = 0 calls and failed calls consume table slots
reset(); a <- scru64(1, 0, 8, time = T0); for (i in 1:16) invisible(scru64(0, i, 8)); b <- scru64(1, 0, 8, time = T0 - 60000, rollback = "error")
cat("16 calls of scru64(0, other node) then node 0 60 s back: no clock error, value went back:", as.character(b) < as.character(a), "\n")
# sonyflake real clock decode
sf <- id_layout("sonyflake", epoch = as.POSIXct("2014-09-01", tz = "UTC")); x <- snowflake(3, sf, 513); f <- id_fields(x); print(f[, c("time", "node", "sequence")]); cat("now:", format(Sys.time(), tz = "UTC"), "\n")
x <- snowflake(600, sf, 513); f <- id_fields(x); cat("sonyflake 600 in one call: ticks used:", length(unique(f$time)), " ahead of clock by (s):", round(as.numeric(max(f$time)) - as.numeric(Sys.time()), 2), "\n")
x <- snowflake(1e5, sf, 513); cat("sonyflake 1e5 in one call: last id time ahead of clock by (s):", round(as.numeric(max(id_time(x))) - as.numeric(Sys.time()), 2), "; next call:", sub("/.*", "", try_class(snowflake(1, sf, 513))), "\n")
x <- snowflake(5e5, tw, list(datacenter = 1, worker = 1)); cat("twitter 5e5 in one call: ahead (s):", round(as.numeric(max(id_time(x))) - as.numeric(Sys.time()), 3), "\n")
