source("hdr.R")
library(parallel)
kids <- function(f, k = 4) mclapply(seq_len(k), function(i) as.character(f(i)), mc.cores = k)
cross_dups <- function(res) { all <- unlist(res); sum(duplicated(all)) }
# warm state in parent, then fork
invisible(list(uuid(1), uuid(1, 1), uuid(1, 6), ulid(1), scru128(1), objectid(1), xid(1), ksuid(1), nanoid(1)))
r <- kids(function(i) objectid(1000));           cat("objectid cross-child dups:", cross_dups(r), "of", 4000, "\n")
r <- kids(function(i) xid(1000));                cat("xid cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) xid(1000, process = 7));   cat("xid(process fixed) cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) uuid(200000, 1));          cat("uuid v1 cross-child dups:", cross_dups(r), "of", 800000, "\n")
r <- kids(function(i) uuid(200000, 6));          cat("uuid v6 cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) uuid(1000, 1));            cat("uuid v1 n=1000 cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) uuid(100000, 7));          cat("uuid v7 cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) uuid(100000, 4));          cat("uuid v4 cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) ulid(100000));             cat("ulid cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) scru128(100000));          cat("scru128 cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) ksuid(10000));             cat("ksuid cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) nanoid(10000));            cat("nanoid cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) upid(10000, "a"));         cat("upid cross-child dups:", cross_dups(r), "\n")
# ULID: state ahead of the clock (a time= slightly in the future, within tolerance), then fork
reset(); invisible(ulid(1, time = as.numeric(Sys.time()) * 1000 + 5000))
r <- kids(function(i) ulid(5));                  cat("ulid after future time (5 s ahead) cross-child dups:", cross_dups(r), "of 20\n"); print(r[1:2])
# ULID fork immediately after a parent value; many trials
d <- 0; for (t in 1:20) { invisible(ulid(1)); r <- kids(function(i) ulid(1), 2); d <- d + cross_dups(r) }
cat("ulid fork right after parent value, 20 trials, dups:", d, "\n")
# first use only in children (state cold in parent)
reset()
r <- kids(function(i) objectid(1000));           cat("objectid cold-state cross-child dups:", cross_dups(r), "\n")
r <- kids(function(i) uuid(200000, 1));          cat("uuid v1 cold-state cross-child dups:", cross_dups(r), "\n")
