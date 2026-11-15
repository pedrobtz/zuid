source("hdr.R")
T0 <- 1.7e12
tm <- function(x) { f <- id_fields(x); as.numeric(f$time) * 1000 }
ms <- function(x) round(as.numeric(id_time(x)) * 1000)
for (tol in c(10, 0.5, 0, 2.5)) { options(zuid.rollback_tolerance = tol); tolms <- tol * 1000
  for (d in c(tolms - 1, tolms, tolms + 1)) { if (d < 0) next
    reset(); a <- uuid(1, time = T0); b <- uuid(1, time = T0 - d)
    exp_keep <- d <= tolms
    chk(sprintf("v7 tol=%gs back %gms: %s", tol, d, if (exp_keep) "keeps last ms and increases" else "restarts at new time"),
        if (exp_keep) ms(b) == T0 && as.character(b) > as.character(a) else ms(b) == T0 - d)
    reset(); a <- ulid(1, time = T0); b <- ulid(1, time = T0 - d)
    chk(sprintf("ulid tol=%gs back %gms", tol, d), if (exp_keep) ms(b) == T0 && as.character(b) > as.character(a) else ms(b) == T0 - d)
    reset(); a <- uuid(1, 6, time = T0); b <- uuid(1, 6, time = T0 - d); fa <- id_fields(a); fb <- id_fields(b)
    chk(sprintf("v6 tol=%gs back %gms: %s", tol, d, if (exp_keep) "ticks +1, same clock_seq" else "clock_seq+1 at new time"),
        if (exp_keep) as.character(b) > as.character(a) && fa$sequence == fb$sequence else (fb$sequence - fa$sequence) %% 16384 == 1 && ms(b) == T0 - d)
    reset(); a <- scru128(1, time = T0); r <- try_class(b <- scru128(1, time = T0 - d))
    chk(sprintf("scru128 tol=%gs back %gms [%s]", tol, d, sub("/.*", "", r)), if (exp_keep) r == "ok" && as.character(b) > as.character(a) else grepl("zuid_clock_error", r))
  }
}
options(zuid.rollback_tolerance = 10)
# difftime option, bad options
options(zuid.rollback_tolerance = as.difftime(1, units = "mins")); reset(); a <- uuid(1, time = T0); b <- uuid(1, time = T0 - 59999); chk("difftime tolerance of 1 min honoured", ms(b) == T0)
for (o in list(-1, NA, "a", c(1, 2), NULL, NaN)) { options(zuid.rollback_tolerance = o); cat("option", deparse(o), "->", sub("/.*", "", try_class(uuid(1))), "\n") }
options(zuid.rollback_tolerance = NULL)
# snowflake clock tolerance straddle (default 0.01 s = 10 ticks for ms; 1 tick for 10ms)
tw <- id_layout("twitter"); W <- list(datacenter = 1, worker = 1)
for (d in c(9, 10, 11)) { reset(); a <- snowflake(1, tw, W, time = T0); r <- try_class(b <- snowflake(1, tw, W, time = T0 - d))
  chk(sprintf("snowflake twitter back %d ms [%s]", d, sub("/.*", "", r)), if (d <= 10) r == "ok" && ms(b) == T0 && id_fields(b)$sequence == 1 else grepl("zuid_clock_error", r)) }
sf <- id_layout("sonyflake", epoch = 1409529600000)
for (d in c(5, 10, 19, 20)) { reset(); a <- snowflake(1, sf, 1, time = T0); r <- try_class(b <- snowflake(1, sf, 1, time = T0 - d)); cat(sprintf("sonyflake back %d ms: %s\n", d, sub("/.*", "", r))) }
for (ct in c(0, 0.0005, 0.001, 1)) { options(zuid.clock_tolerance = ct); reset(); a <- snowflake(2, tw, W, time = T0); r <- try_class(b <- snowflake(2, tw, W, time = T0 - 1)); r0 <- try_class(b0 <- snowflake(5000, tw, W, time = T0))
  cat(sprintf("clock_tolerance=%g: back 1 ms -> %s; then 5000 at same tick -> %s unique=%s\n", ct, sub("/.*", "", r), sub("/.*", "", r0), if (r0 == "ok") !anyDuplicated(as.character(b0)) else NA)) }
options(zuid.clock_tolerance = NULL)
# snowflake: overflow moved tick ahead, then the real tick: no error, no repeat
reset(); a <- snowflake(4096 * 30, tw, W, time = T0); r <- try_class(b <- snowflake(3, tw, W, time = T0 + 1)); chk(sprintf("snowflake after overflow drift of 30 ticks, next call at T0+1 [%s]", sub("/.*", "", r)), r == "ok" && !any(as.character(b) %in% as.character(a)) && all(as.character(b) > max(as.character(a))))
# snowflake reset repeats (documented)
reset(); a <- snowflake(2, tw, W, time = T0); b <- snowflake(2, tw, W, time = T0 - 5000, rollback = "reset"); c2 <- snowflake(2, tw, W, time = T0)
cat("snowflake after reset then back to T0: repeats of earlier values:", sum(as.character(c2) %in% as.character(a)), "(documented: may repeat)\n")
# mid-vector clock error: state after
reset(); r <- try_class(snowflake(3, tw, W, time = c(T0, T0, T0 - 5000))); b <- snowflake(1, tw, W, time = T0); cat("mid-vector error:", sub("/.*", "", r), " next seq:", id_fields(b)$sequence, "(2 = the two values made before the error stay consumed)\n")
reset(); invisible(scru128(1, time = T0)); r <- try_class(scru128(3, time = c(T0 + 5, T0 + 6, T0 - 50000))); b <- scru128(1, time = T0 + 6); a2 <- scru128(1, time = T0 + 6); cat("scru128 mid-vector error:", sub("/.*", "", r), " state kept at T0+6:", ms(b) == T0 + 6, "\n")
# v1/v6 share state; v1 then v6 at same instant
reset(); a <- uuid(1, 1, time = T0); b <- uuid(1, 6, time = T0); fa <- id_fields(a); fb <- id_fields(b); print(rbind(fa, fb)[, c("time", "sequence", "node")])
# node arg with session clock_seq
reset(); a <- uuid(2, 1, node = as.raw(1:6)); b <- uuid(1, 1); print(id_fields(c(a, b))[, c("sequence", "node")])
# random given without time (not pure) for v1: clock seq from random but session tick state
reset(); a <- uuid(1, 1, random = as.raw(c(0, 5, 1:6))); b <- uuid(1, 1, random = as.raw(c(0, 5, 1:6))); chk("v1 random without time: two calls differ", as.character(a) != as.character(b))
# v1 with random + time: rollback increments clock seq within the call
x <- uuid(4, 1, random = as.raw(c(0xff, 0xff, 1:6)), time = c(T0, T0 - 20000, T0 - 40000, T0 - 60000)); print(id_fields(x)[, c("time", "sequence")])
x <- uuid(3, 1, random = as.raw(c(0xff, 0xff, 1:6)), time = c(T0, T0 - 20000, T0)); cat("v1 pure: T0, T0-20s, T0 -> unique:", !anyDuplicated(as.character(x)), "\n")
