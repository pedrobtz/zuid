source("hdr.R")
# P1: v7 counter-overflow borrow vs tolerance
for (tol in c(0, 0.001, 0.002, 10)) {
  options(zuid.rollback_tolerance = tol); reset()
  x <- as.character(uuid(20000))
  chk(sprintf("uuid(20000) v7 strictly increasing, tol=%g", tol), sorted_strict(x) && !anyDuplicated(x))
  reset()
  x <- as.character(uuid(20000, time = 1.7e12, random = as.raw(rep(0xff, 200000))))
  chk(sprintf("uuid v7 pure (time+random) increasing, tol=%g", tol), sorted_strict(x))
}
# v1 with tolerance 0 / Inf
for (tol in c(0, 1e-7, 10, 1e12, Inf)) {
  for (v in c(1, 6)) {
  options(zuid.rollback_tolerance = tol); reset()
  x <- as.character(uuid(40000, v))
  f <- id_fields(uuid(40000, v))
  chk(sprintf("uuid(40000, %d) unique, tol=%g  (dups=%d)", v, tol, sum(duplicated(x))), !anyDuplicated(x))
  }
}
for (tol in c(0, 10, 1e12, Inf)) {
  options(zuid.rollback_tolerance = tol); reset()
  x <- as.character(uuid(40000, 6))
  chk(sprintf("uuid(40000, 6) strictly increasing, tol=%g", tol), sorted_strict(x))
  reset(); x <- as.character(ulid(40000)); chk(sprintf("ulid(40000) increasing tol=%g", tol), sorted_strict(x))
  reset(); x <- try_class(y <- as.character(scru128(40000))); chk(sprintf("scru128(40000) increasing tol=%g [%s]", tol, x), x == "ok" && sorted_strict(y))
  reset(); x <- try_class(y <- as.character(scru64(40000, 1, 8))); chk(sprintf("scru64(40000,1,8) increasing tol=%g [%s]", tol, x), x == "ok" && sorted_strict(y))
}
options(zuid.rollback_tolerance = 10)
# scru64 small counter
for (nb in c(23, 22, 20, 16)) { reset()
  r <- try_class(y <- scru64(3000, 1, nb))
  chk(sprintf("scru64(3000, node_bits=%d) no spurious clock error [%s]", nb, r), r == "ok")
}
reset()
r <- try_class(y <- scru64(3000, 1, 23, rollback = "reset"))
y <- as.character(y)
chk(sprintf("scru64(3000, node_bits=23, reset) unique+increasing [%s] dups=%d", r, sum(duplicated(y))), r == "ok" && sorted_strict(y))
