source("pre.R")
ids <- list(uuid=as.character(uuid(50)), ulid=as.character(ulid(50)), typeid=as.character(typeid(50, prefix="user")), typeid0=as.character(typeid(50, prefix="")),
  upid=as.character(upid(50, prefix="user")), scru128=as.character(scru128(50)), ksuid=as.character(ksuid(50)), xid=as.character(xid(50)), objectid=as.character(objectid(50)))
for (n in names(ids)) { d <- id_detect(ids[[n]]); cat(n, ":", paste(names(table(d, useNA="ifany")), table(d, useNA="ifany")), "| candidates:", paste(unique(vapply(attr(d,"candidates"), paste, "", collapse="+")), collapse=" ; "), "\n")
  e <- vapply(ids[[n]], function(s) id_detect(s), "", USE.NAMES=FALSE); stopifnot(identical(e, as.vector(d))) }
digs <- vapply(c(1,11,12,13,19,20,21,24,25,26,27,32,36), function(n) paste0("1", strrep("0", n-1)), "")
d <- id_detect(digs); print(data.frame(n=nchar(digs), det=as.vector(d), cand=vapply(attr(d,"candidates"), paste, "", collapse="+")))
for (L in list(id_layout("discord"), id_layout("twitter"), id_layout("scru64", node_bits=8))) { d <- id_detect(digs, layout=L); print(data.frame(n=nchar(digs), det=as.vector(d), cand=vapply(attr(d,"candidates"), paste, "", collapse="+"))) }
p(id_detect("0v1e6nq5q3g0", layout=id_layout("scru64", node_bits=8)))
p(id_detect(c(a="x", b=NA, c="018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3")))
p(id_detect("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", hint=c("uuid","uuid")))
p(id_detect("abc", hint=c("nanoid","cuid2","sqids")))
p(id_detect("V1StGXR8_Z5jdHi6B-myT", hint="nanoid"))
p(id_detect(character()))
p(id_detect(NA_character_))
p(id_detect("urn:uuid:018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3")); p(id_detect("018F6B1C-2D3E-7A4B-8C5D-6E7F8091A2B3")); p(id_detect("{018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3}"))
p(id_detect("018f6b1c2d3e7a4b8c5d6e7f8091a2b3"))
# parse w/ detection
p(id_parse(c(NA, "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "junk")))
p(id_parse(c(NA, "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "junk"), strict=TRUE))
p(id_parse(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "01ARZ3NDEKTSV4RRFFQ69G5FAV")))
p(id_parse(c("01arz3ndektsv4rrffq69g5fav")))
p(id_parse("175928847299117063", layout=id_layout("discord")))
p(id_parse("0v1e6nq5q3g0", layout=id_layout("scru64", node_bits=8)))
p(id_parse("0v1e6nq5q3g0"))
# uuid non-rfc variant: detection (structure) vs parse
p(id_detect("018f6b1c-2d3e-7a4b-0c5d-6e7f8091a2b3")); p(id_parse("018f6b1c-2d3e-7a4b-0c5d-6e7f8091a2b3"))
# strict error positions
r <- tryCatch(id_parse(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", NA, "bad", "018f6b1c-2d3e-7a4b-0c5d-6e7f8091a2b3", "x","y","z","w"), "uuid", strict=TRUE), error=function(e) e)
p(r$positions); p(conditionMessage(r))
r <- tryCatch(id_parse(c("1", "18446744073709551615", "9223372036854775808", "01"), "snowflake", layout=id_layout("twitter"), strict=TRUE), error=function(e) e); p(r$positions)
r <- tryCatch(id_parse(c("1", "99999999999999999999999"), "snowflake", layout=id_layout("discord"), strict=TRUE, level="strict"), error=function(e) e); p(r$positions)
# names
p(names(id_parse(c(a="018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", b=NA), "uuid")))
p(id_valid(c(a="018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", b=NA), "uuid"))
