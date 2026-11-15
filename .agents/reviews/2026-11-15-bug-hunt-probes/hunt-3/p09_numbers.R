source("hdr.R")
tw <- id_layout("twitter"); W <- list(datacenter = 1, worker = 1)
gens <- list(
  uuid7 = function(n, ...) uuid(n, 7, ...), uuid4 = function(n, ...) uuid(n, 4), uuid1 = function(n, ...) uuid(n, 1, ...), uuid6 = function(n, ...) uuid(n, 6, ...),
  ulid = ulid, typeid = function(n, ...) typeid(n, "a", ...), upid = function(n, ...) upid(n, "a", ...), scru128 = scru128,
  scru64 = function(n, ...) scru64(n, 1, 8, ...), ksuid = ksuid, xid = function(n, ...) xid(n, ...), objectid = objectid,
  snowflake = function(n, ...) snowflake(n, tw, W, ...), nanoid = function(n, ...) nanoid(n))
badn <- list(NA, NA_integer_, NA_real_, -1, 0.5, 1.5, .Machine$integer.max + 1, Inf, -Inf, NaN, 2^53, "1", TRUE, c(1, 2), numeric(0), NULL, 1e10)
for (g in names(gens)) { reset()
  res <- vapply(badn, function(n) try_class(gens[[g]](n)), "")
  ok <- all(grepl("zuid_type_error", res) | (res == "ok" & vapply(badn, function(n) isTRUE(n), NA)))
  chk(sprintf("%s: bad n all zuid_type_error", g), ok); if (!ok) print(setNames(res, vapply(badn, function(n) paste(deparse(n), collapse=""), "")))
  z <- gens[[g]](0); chk(sprintf("%s: n=0 gives length-0 %s", g, class(z)[1]), length(z) == 0 && inherits(z, "zuid"))
  l <- gens[[g]](1L); chk(sprintf("%s: integer n", g), length(l) == 1)
}
badt <- list(NA, NA_real_, Inf, -Inf, NaN, -1, 2^53, 2^63, "2020-01-01", as.Date("2020-01-01"), c(1, 2), numeric(0), as.POSIXct(NA), TRUE, 1L, as.difftime(1, units = "secs"), as.POSIXlt("2020-01-01", tz = "UTC"), factor("a"), 1e300)
for (g in setdiff(names(gens), c("uuid4", "nanoid"))) { reset()
  res <- vapply(badt, function(t) tryCatch({ v <- gens[[g]](1, time = t); paste("ok", format(id_time(v), "%Y-%m-%d %H:%M:%OS3", tz = "UTC")) }, error = function(e) class(e)[1]), "")
  names(res) <- vapply(badt, function(t) paste(deparse(t), collapse = "")[1], "")
  cat("----", g, "\n"); print(res[res != "zuid_type_error"])
}
