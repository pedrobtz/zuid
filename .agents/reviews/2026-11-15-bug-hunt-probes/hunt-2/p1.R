source("pre.R")
# A typeid strict w/ non-RFC variant
u <- "ffffffff-ffff-7fff-0fff-ffffffffffff"
p(id_valid(u, "uuid", level="strict")); p(id_valid(u, "uuid", level="structure"))
x <- id_parse(u, "uuid", level="syntax")
t <- id_convert(x, "typeid", prefix="a")
p(as.character(t))
p(id_valid(as.character(t), "typeid", level="strict"))
p(id_fields(t)[, c("time","version","variant")])
# future v7 typeid w/ rfc variant
u2 <- "ffffffff-ffff-7fff-8fff-ffffffffffff"
t2 <- id_convert(id_parse(u2,"uuid"), "typeid", prefix="a")
p(id_valid(as.character(t2), "typeid", level="strict"))
# B scru64 from bytes
p(id_from_bytes(as.raw(rep(0xff,8)), "scru64"))
z <- id_from_bytes(as.raw(rep(0xff,8)), "scru64")
p(id_bytes(z))
p(id_from_bytes(as.raw(c(0x41,0xc2,0x1c,0xb8,0xe1,0,0,0)), "scru64"))
p(id_from_bytes(as.raw(c(0x41,0xc2,0x1c,0xb8,0xe0,0xff,0xff,0xff)), "scru64"))
p(id_from_bytes(as.raw(rep(0,16)), "scru128")); 
p(id_valid(as.character(id_from_bytes(as.raw(rep(0,16)), "scru128")), "scru128"))
# D decode no cap
s <- strrep("ab", 70000)
p(length(id_decode(s, "hex")[[1]]))
p(tryCatch(nchar(id_encode(id_decode(s, "hex")[[1]], "hex")), error=function(e) class(e)))
p(id_decode(s, "hex", width=65536)); 
p(id_decode("--", "hex")); p(id_decode("", "hex")); p(id_decode("a-b", "hex"))
p(id_decode(c("", NA, "0"), "base58"))
p(id_decode("", "words")); p(id_decode("...", "proquint")); p(id_decode(" ", "base32"))
