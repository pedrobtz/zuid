source("hdr.R")
library(parallel)
kids <- function(f, k = 4) mclapply(seq_len(k), function(i) as.character(f(i)), mc.cores = k)
cross_dups <- function(res) { all <- unlist(res); sum(duplicated(all)) }
reset()
d <- 0; for (t in 1:30) { invisible(ulid(1)); r <- kids(function(i) ulid(1), 2); d <- d + cross_dups(r) }
cat("ulid fork right after parent value, 30 trials, dups:", d, "\n")
d <- 0; for (t in 1:30) { invisible(scru128(1)); r <- kids(function(i) scru128(1), 2); d <- d + cross_dups(r) }
cat("scru128 same, dups:", d, "\n")
# v7 state ahead of clock after a burst: uuid(2e6) pushes last_ms ~650 ms ahead
reset(); invisible(uuid(2e6)); r <- kids(function(i) uuid(50000)); cat("v7 after burst cross-child dups:", cross_dups(r), "\n")
# v1: how small a per-child n collides
reset(); invisible(uuid(1, 1))
for (n in c(1, 10, 100, 1000, 10000, 50000)) { d <- 0; for (t in 1:10) d <- d + cross_dups(kids(function(i) uuid(n, 1), 4)); cat("v1 n =", n, "per child, 10 trials, dups:", d, "\n") }
# snowflake same worker (expected by design), different workers
L <- id_layout("twitter")
r <- kids(function(i) snowflake(5000, L, list(datacenter = 1, worker = i))); cat("snowflake distinct workers dups:", cross_dups(r), "\n")
# scru64 distinct nodes
r <- kids(function(i) scru64(5000, i, 8)); cat("scru64 distinct nodes dups:", cross_dups(r), "\n")
# mcparallel variant for objectid
invisible(objectid(1)); j <- list(mcparallel(as.character(objectid(3))), mcparallel(as.character(objectid(3)))); print(mccollect(j))
print(id_fields(objectid(2)))
