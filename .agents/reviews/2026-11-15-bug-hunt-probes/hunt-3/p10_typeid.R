source("hdr.R")
z <- tryCatch(typeid(0, "user"), error = function(e) e); print(z); str(unclass(z))
print(tryCatch(typeid(0, ""), error = function(e) e))
r <- as.raw(1:20)
a <- typeid(2, "user", random = r, time = 1.7e12); b <- id_convert(uuid(2, 7, random = r, time = 1.7e12), "typeid", "user")
chk("typeid() == id_convert(uuid(7)) with same inputs", identical(a, b)); print(a)
p63 <- strrep("a", 63); print(try_class(typeid(1, p63))); print(try_class(typeid(1, strrep("a", 64)))); print(try_class(typeid(1, "a_"))); print(try_class(typeid(1, "_a"))); print(try_class(typeid(1, NA_character_))); print(try_class(typeid(1, c("a","b"))))
x <- typeid(3, "ab_c"); print(x); chk("typeid sorted", sorted_strict(x)); print(id_fields(x)[, c("format","time","version","prefix")])
# one call of n vs n calls of 1, pure
t <- 1.7e12
for (g in list(function(n, r, tt) uuid(n, 7, random = r, time = tt), function(n, r, tt) ulid(n, random = r, time = tt), function(n, r, tt) scru128(n, random = r, time = tt))) {
  r <- as.raw(sample(0:255, 30, TRUE))
  one <- as.character(g(3, r, t)); sep <- c(as.character(g(1, r[1:10], t)), as.character(g(1, r[11:20], t)), as.character(g(1, r[21:30], t)))
  cat("n=3 :", one, "\nn=1x3:", sep, "\n")
}
# POSIXct vs double ms equivalence
p <- as.POSIXct(1700000000.123, origin = "1970-01-01", tz = "UTC")
chk("uuid7 POSIXct == ms", identical(uuid(1, 7, random = as.raw(1:10), time = p), uuid(1, 7, random = as.raw(1:10), time = 1700000000123)))
chk("ulid POSIXct == ms", identical(ulid(1, random = as.raw(1:10), time = p), ulid(1, random = as.raw(1:10), time = 1700000000123)))
chk("ksuid POSIXct == ms", identical(ksuid(1, random = as.raw(1:16), time = p), ksuid(1, random = as.raw(1:16), time = 1700000000123)))
chk("snowflake POSIXct == ms", {reset(); a <- snowflake(1, id_layout("twitter"), list(datacenter=1, worker=1), time = p); reset(); b <- snowflake(1, id_layout("twitter"), list(datacenter=1, worker=1), time = 1700000000123); identical(a, b)})
# time length 1 or n
print(try_class(uuid(3, time = c(1, 2)))); print(try_class(ulid(3, time = c(1, 2, 3)))); 
# pure calls leave state alone
reset(); s0 <- zuid_info()$state; invisible(uuid(5, 7, random = as.raw(1:50), time = 5)); invisible(uuid(1, 1, random = as.raw(1:8), time = 5)); invisible(ulid(1, random = as.raw(1:10), time = 5))
chk("pure calls leave zuid_info()$state untouched", identical(s0, zuid_info()$state)); 
invisible(uuid(1)); invisible(uuid(1, 1)); invisible(ulid(1)); str(zuid_info()$state)
s1 <- zuid_info()$state; s2 <- zuid_info()$state; chk("zuid_info() is read-only", identical(s1, s2))
# set.seed independence
set.seed(1); a <- c(uuid(1, 4), nanoid(1)); set.seed(1); b <- c(uuid(1, 4), nanoid(1)); chk("set.seed does not repeat ids", !any(as.character(a) == as.character(b)))
set.seed(1); x <- runif(1); invisible(uuid(10)); invisible(nanoid(10)); y <- runif(1); set.seed(1); invisible(runif(1)); chk("generators do not consume R RNG", y == runif(1))
