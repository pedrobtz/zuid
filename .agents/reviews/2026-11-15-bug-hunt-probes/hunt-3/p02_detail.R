source("hdr.R")
options(zuid.rollback_tolerance = 0); reset()
x <- as.character(uuid(20000, time = 1.7e12, random = as.raw(rep(0xff, 200000))))
i <- which(x[-1] <= x[-length(x)])[1]
print(x[(i-1):(i+2)]); cat("first drop at", i+1, " dups:", sum(duplicated(x)), "\n")
f <- id_fields(uuid(20000, time = 1.7e12, random = as.raw(rep(0xff, 200000))))
print(table(f$time_s*1000 + f$time_ns/1e6 - 1.7e12))
options(zuid.rollback_tolerance = 10); reset()
# scru64 minimal n per node_bits at default tolerance
for (nb in 23:14) {
  lo <- 1; hi <- 200000
  ok <- function(n) { reset(); try_class(scru64(n, 1, nb)) == "ok" }
  if (ok(hi)) { cat("node_bits", nb, "ok up to", hi, "\n"); next }
  while (hi - lo > 1) { mid <- (lo + hi) %/% 2; if (ok(mid)) lo <- mid else hi <- mid }
  cat("node_bits", nb, ": largest n that works in one call =", lo, "\n")
}
reset(); print(tryCatch(scru64(200, 1, 23), error = function(e) conditionMessage(e)))
# across calls, not one call:
reset(); r <- try_class(for (i in 1:200) scru64(1, 1, 23)); cat("200 calls of scru64(1,1,23):", r, "\n")
reset(); y <- as.character(scru64(200, 1, 23, rollback = "reset")); cat("reset: n=200 unique:", length(unique(y)), "\n"); print(head(y, 3)); print(y[81:86])
