source("hdr.R")
z <- id_convert(uuid(0), "typeid", "user"); cat("id_convert(uuid(0),'typeid','user') length:", length(z), " value:", as.character(z), "\n")
cat("typeid(0,'user') length:", length(typeid(0, "user")), "\n")
set.seed(1); a <- as.character(uuid(1, 4)); a2 <- as.character(nanoid(1)); set.seed(1); b <- as.character(uuid(1, 4)); b2 <- as.character(nanoid(1)); chk("set.seed does not repeat ids", a != b && a2 != b2)
set.seed(1); x <- runif(1); invisible(uuid(10)); invisible(nanoid(10)); invisible(ulid(3)); invisible(xid(2)); y <- runif(1); set.seed(1); invisible(runif(1)); chk("generators do not consume R RNG", y == runif(1))
fail <- function(on) invisible(.Call(zuid:::zuid_c_entropy_fail, on))
tw <- id_layout("twitter"); W <- list(datacenter = 1, worker = 1)
gens <- list(uuid7 = function(n = 1) uuid(n), uuid4 = function(n = 1) uuid(n, 4), uuid1 = function(n = 1) uuid(n, 1), uuid6 = function(n = 1) uuid(n, 6), ulid = ulid,
  typeid = function(n = 1) typeid(n, "a"), upid = function(n = 1) upid(n, "a"), scru128 = scru128, scru64 = function(n = 1) scru64(n, 1, 8), ksuid = ksuid, xid = xid, objectid = objectid, nanoid = nanoid)
# cold state + entropy failure, then recovery
for (g in names(gens)) { reset(); fail(TRUE); r <- try_class(gens[[g]](2)); fail(FALSE)
  r2 <- try_class(v <- gens[[g]](3)); chk(sprintf("%s: entropy failure -> zuid_entropy_error [%s]; next call fine", g, sub("/.*", "", r)), grepl("zuid_entropy_error", r) && r2 == "ok" && length(v) == 3 && !anyDuplicated(as.character(v))) }
# warm state + entropy failure: state after
for (g in names(gens)) { reset(); a <- as.character(gens[[g]](2)); fail(TRUE); r <- try_class(gens[[g]](2)); fail(FALSE); b <- as.character(gens[[g]](2))
  mono <- if (g %in% c("uuid4", "upid", "ksuid", "nanoid")) !anyDuplicated(c(a, b)) else if (g %in% c("xid", "objectid", "uuid1")) !anyDuplicated(c(a, b)) else sorted_strict(c(a, b))
  chk(sprintf("%s: warm, entropy failure [%s], then still unique/increasing", g, sub("/.*", "", r)), mono) }
# xid/objectid counter continuity across failure and across calls
reset(); a <- id_fields(objectid(3))$sequence; b <- id_fields(objectid(2))$sequence; chk("objectid counter continues across calls", all(diff(c(a, b)) %% 2^24 == 1))
reset(); a <- id_fields(xid(3))$sequence; b <- id_fields(xid(2))$sequence; chk("xid counter continues across calls", all(diff(c(a, b)) %% 2^24 == 1))
# counter wrap at 2^24 with random seed ff ff fe
x <- id_fields(xid(4, random = as.raw(c(1, 2, 3, 0xff, 0xff, 0xfe)), time = 1.7e12)); print(x$sequence)
x <- objectid(4, random = as.raw(c(1, 2, 3, 4, 5, 0xff, 0xff, 0xfe)), time = 1.7e12); print(x); 
# xid(n > 2^24) in one second: duplicates? (2^24+1 values) -- via time fixed
# partial failure inside a vector call: ULID overflow
reset(); r <- try_class(ulid(3, time = 5, random = as.raw(rep(0xff, 30)))); cat("ulid pure overflow:", r, "\n")
reset(); invisible(ulid(1, time = 1.7e12)); 
# v7: pure overflow at last ms
r <- try_class(uuid(3000, 7, time = 2^48 - 1, random = as.raw(rep(0xff, 30000)))); cat("uuid7 last-ms overflow:", r, "\n")
reset(); r <- try_class(uuid(5000, 7, time = 2^48 - 1)); cat("uuid7 session last-ms overflow:", r, "\n"); r2 <- try_class(v <- uuid(1)); cat("  next uuid():", r2, format(id_time(v)), "\n"); str(zuid_info()$state[1:2])
# session poisoned by a far-future time?
for (g in c("uuid7", "ulid", "scru128", "scru64", "uuid1")) { reset()
  fut <- 4e12
  f <- switch(g, uuid7 = function(...) uuid(1, ...), ulid = function(...) ulid(1, ...), scru128 = function(...) scru128(1, ...), scru64 = function(...) scru64(1, 1, 8, ...), uuid1 = function(...) uuid(1, 1, ...))
  invisible(f(time = fut)); r <- try_class(v <- f()); cat(sprintf("%s: after a time= in 2096, a clock call: %s %s\n", g, sub("/.*", "", r), if (r == "ok") format(id_time(v)) else "")) }
reset(); invisible(snowflake(1, tw, W, time = 2e12)); r <- try_class(snowflake(1, tw, W)); cat("snowflake after future time:", sub("/.*", "", r), "\n"); r <- try_class(v <- snowflake(1, tw, W, rollback = "reset")); cat("  reset:", r, format(id_time(v)), "\n")
