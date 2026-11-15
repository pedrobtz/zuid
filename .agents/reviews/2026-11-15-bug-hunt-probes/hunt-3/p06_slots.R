source("hdr.R")
T0 <- 1.75e12
mk <- function(i) id_layout(time = list(bits = 41, unit = "ms", epoch = i), fields = list(worker = 10), sequence = 12)
for (others in c(14, 15, 16)) {
  reset()
  a <- snowflake(3, mk(0), 1, time = T0)
  for (i in seq_len(others)) invisible(snowflake(1, mk(i), 1, time = T0))
  b <- snowflake(3, mk(0), 1, time = T0)
  chk(sprintf("snowflake: %d other layouts in between, same layout+tick gives no repeat", others), !anyDuplicated(c(as.character(a), as.character(b))))
  if (others == 16) { print(a); print(b) }
}
for (others in c(14, 15, 16)) {
  reset()
  a <- scru64(3, 0, 8, time = T0)
  for (i in seq_len(others)) invisible(scru64(1, i, 8, time = T0))
  b <- scru64(3, 0, 8, time = T0)
  x <- c(as.character(a), as.character(b))
  chk(sprintf("scru64: %d other nodes in between, node 0 still strictly increasing", others), sorted_strict(x))
}
# probability over trials with 16 others
bad <- 0; dup <- 0
for (t in 1:200) { reset(); a <- as.character(scru64(1, 0, 8, time = T0)); for (i in 1:16) invisible(scru64(1, i, 8, time = T0)); b <- as.character(scru64(1, 0, 8, time = T0)); bad <- bad + (b <= a) }
cat("scru64 17 nodes, 200 trials: second value for node 0 not above first in", bad, "\n")
# real clock, no time=: 17 layouts round-robin
reset(); Ls <- lapply(0:16, mk); out <- character()
for (rep in 1:50) for (L in Ls) out <- c(out, paste(L$epoch, as.character(snowflake(1, L, 1))))
cat("snowflake real clock, 17 layouts round-robin x50: dups", sum(duplicated(out)), "of", length(out), "\n")
reset(); Ls <- lapply(0:15, mk); out <- character()
for (rep in 1:50) for (L in Ls) out <- c(out, paste(L$epoch, as.character(snowflake(1, L, 1))))
cat("snowflake real clock, 16 layouts round-robin x50: dups", sum(duplicated(out)), "of", length(out), "\n")
# real clock scru64, 17 nodes round robin: per-node monotonic?
reset(); res <- vector("list", 17)
for (rep in 1:200) for (nd in 0:16) res[[nd + 1]] <- c(res[[nd + 1]], as.character(scru64(1, nd, 8)))
cat("scru64 real clock 17 nodes: nodes whose values are not strictly increasing:", sum(!vapply(res, sorted_strict, NA)), " dups:", sum(vapply(res, function(v) sum(duplicated(v)), 1)), "\n")
reset(); res <- vector("list", 16)
for (rep in 1:200) for (nd in 0:15) res[[nd + 1]] <- c(res[[nd + 1]], as.character(scru64(1, nd, 8)))
cat("scru64 real clock 16 nodes: not increasing:", sum(!vapply(res, sorted_strict, NA)), "\n")
# same node different node_bits = two slots; equal layouts built two ways share state
reset(); a <- snowflake(1, id_layout("twitter"), list(datacenter=0, worker=1), time = T0)
L2 <- id_layout(time = list(bits = 41, unit = "ms", epoch = 1288834974657), fields = list(a = 5, b = 5), sequence = 12)
b <- snowflake(1, L2, list(a = 0, b = 1), time = T0)
chk("twitter built-in and equal custom layout share a sequence", as.character(a) != as.character(b))
# snowflake padding memcmp: consecutive calls continue the sequence
reset(); a <- id_fields(snowflake(1, id_layout("twitter"), list(datacenter=0, worker=1), time = T0)); b <- id_fields(snowflake(1, id_layout("twitter"), list(datacenter=0, worker=2), time = T0))
chk("snowflake sequence continues across calls and workers", a$sequence == 0 && b$sequence == 1)
