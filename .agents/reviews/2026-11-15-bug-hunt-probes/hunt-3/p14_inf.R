source("hdr.R")
T0 <- 1.7e12; ms <- function(x) round(as.numeric(id_time(x)) * 1000)
tw <- id_layout("twitter"); W <- list(datacenter = 1, worker = 1)
for (tol in list(Inf, 1e300, 1e16, 9.3e15, 9.2e15, 1e12, 9.3e11, 9.2e11, 1e9)) {
  options(zuid.rollback_tolerance = tol, zuid.clock_tolerance = tol)
  cat(sprintf("---- tolerance = %g s\n", tol))
  reset(); a <- uuid(1, time = T0); b <- uuid(1, time = T0 - 60000); chk("  v7: back 60 s keeps last ms", ms(b) == T0 && as.character(b) > as.character(a))
  reset(); a <- ulid(1, time = T0); b <- ulid(1, time = T0 - 60000); chk("  ulid: back 60 s keeps last ms", ms(b) == T0 && as.character(b) > as.character(a))
  reset(); a <- uuid(1, 6, time = T0); b <- uuid(1, 6, time = T0 - 60000); chk("  v6: back 60 s keeps increasing, same clock_seq", as.character(b) > as.character(a) && id_fields(a)$sequence == id_fields(b)$sequence)
  reset(); x <- as.character(uuid(20000, 1)); chk(sprintf("  v1: uuid(20000, 1) unique (dups %d)", sum(duplicated(x))), !anyDuplicated(x))
  reset(); a <- scru128(1, time = T0); r <- try_class(b <- scru128(1, time = T0 - 60000)); chk(sprintf("  scru128: back 60 s keeps last ts [%s]", sub("/.*", "", r)), r == "ok" && ms(b) == T0)
  reset(); a <- scru64(1, 1, 8, time = T0); r <- try_class(b <- scru64(1, 1, 8, time = T0 - 60000)); chk(sprintf("  scru64: back 60 s keeps last ts [%s]", sub("/.*", "", r)), r == "ok" && as.character(b) > as.character(a))
  reset(); r <- try_class(a <- snowflake(1, tw, W, time = T0)); r2 <- try_class(b <- snowflake(1, tw, W, time = T0 - 60000)); chk(sprintf("  snowflake: first call [%s], back 60 s [%s]", sub("/.*", "", r), sub("/.*", "", r2)), r == "ok" && r2 == "ok")
}
