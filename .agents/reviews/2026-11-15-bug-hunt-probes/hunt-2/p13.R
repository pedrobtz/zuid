source("pre.R")
set.seed(2)
fm <- id_formats(); 
for (f in c("uuid","ulid","typeid","upid","scru128","scru64","ksuid","xid","objectid","snowflake")) {
  w <- fm$width[fm$format==f] %/% 8L
  m <- matrix(as.raw(sample(0:255, w*500, TRUE)), nrow=w); m[,1] <- as.raw(0); m[,2] <- as.raw(255); m[1, 3:100] <- as.raw(0); m[1, 101:200] <- as.raw(255)
  L <- if (f=="snowflake") id_layout("discord")
  x <- tryCatch(id_from_bytes(m, f, layout=L), error=function(e) e)
  if (inherits(x, "error")) { cat(f, "ERROR", conditionMessage(x), "\n"); next }
  b <- id_bytes(x); rt <- colSums(b != m) == 0
  lv <- sapply(c("syntax","structure"), function(l) sum(id_valid(as.character(x), f, level=l, layout=L)))
  cat(sprintf("%-9s bytes round trip %d/500; text valid at syntax %d, structure %d; nchar %s\n", f, sum(rt), lv[1], lv[2], paste(range(nchar(as.character(x))), collapse="-")))
}
# from_bytes input shapes
u <- as.raw(1:16)
p(id_from_bytes(c(u,u), "uuid")); p(id_from_bytes(list(a=u, b=NULL), "uuid")); p(id_from_bytes(u[1:15], "uuid")); p(id_from_bytes(list(u[1:15]), "uuid"))
p(id_from_bytes(raw(0), "uuid")); p(id_from_bytes(list(), "uuid")); p(id_from_bytes(matrix(u, nrow=8), "uuid"))
bb <- id_bytes(id_parse(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", NA), "uuid")); p(attributes(bb)); p(id_from_bytes(bb, "uuid")); p(id_from_bytes(as.vector(bb), "uuid"))
p(id_from_bytes(as.raw(c(128, rep(0,7))), "snowflake", layout=id_layout("twitter")))
p(id_from_bytes(as.raw(c(128, rep(0,7))), "snowflake", layout=id_layout("discord")))
p(id_from_bytes(as.raw(c(128, rep(0,7))), "snowflake"))
p(id_from_bytes(as.raw(c(128, rep(0,7))), "scru64", layout=id_layout("scru64", node_bits=8)))
p(id_from_bytes(as.raw(rep(0,8)), "scru64", layout=id_layout("twitter")))
p(id_from_bytes(u, "nanoid")); p(id_from_bytes(u, "sqids"))
p(id_from_bytes(as.integer(1:16), "uuid")); p(id_from_bytes(u))
# reserved values and levels
lev <- function(x, f, ...) sapply(c("syntax","structure","strict"), function(l) id_valid(x, f, level=l, ...))
p(lev(c("00000000-0000-0000-0000-000000000000","ffffffff-ffff-ffff-ffff-ffffffffffff","00000000-0000-0000-8000-000000000000","00000000-0000-9000-8000-000000000000","ffffffff-ffff-ffff-bfff-ffffffffffff"), "uuid"))
p(lev(c("0000000000000000000000000","f5lxx1zz5pnorynqglhzmsp33","f5lxx1zz5pnorynqglhzmsp34","f5lxx1zxjkkcyhauwfqjaakqo", "0000000001000000000000000"), "scru128"))
p(lev(c("000000000000","zzzzzzzzzzzz","00000028n7ls","0000001lfls0", "zzzzzzq0em8e", "zzzzzzq0em8f"), "scru64"))
p(lev(c("user_2accvpp5guht4dts56je5a", "user_2accvpp5guht4dts56je5b", "user_2accvpp5guht4dts56je5k", "user_2accvpp5guht4dts56jk5a", "us1r_2accvpp5guht4dts56je5a", "User_2accvpp5guht4dts56je5a", "use_2accvpp5guht4dts56je5a", "zzzz_zzzzzzzzzzzzzzzzzzzzja"), "upid"))
p(lev(c("000000000000000000000000000","aWgEPTl1tmebfsQzFP4bxwgy80V","aWgEPTl1tmebfsQzFP4bxwgy80W"), "ksuid"))
p(id_time(id_parse(c("000000000000000000000000000","aWgEPTl1tmebfsQzFP4bxwgy80V"), "ksuid")))
# tolerance option
x7 <- as.character(uuid(1, version=7, time=Sys.time()+3600))
p(id_valid(x7, "uuid", level="strict"))
for (v in list(0, -1e9, Inf, NA, "a", NULL, c(1,2), 1e300)) { r <- tryCatch(withr::with_options(list(zuid.time_tolerance=v), id_valid(x7, "uuid", level="strict")), error=function(e) paste("ERR", class(e)[1])); cat("tolerance", deparse(v), "->", r, "\n") }
