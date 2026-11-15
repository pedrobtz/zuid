source("pre.R")
b <- "bafkreigh2akiscaildcqabsyg3dfr6chu3fgpregiymsck7e7aqa4s52zy"
x <- id_parse(b, "cid"); raw <- id_bytes(x)[[1]]
hex <- paste0("f", paste(sprintf("%02x", as.integer(raw)), collapse=""))
HEX <- paste0("F", toupper(substring(hex,2)))
p(id_parse(c(b, hex, HEX), "cid"))
y <- id_parse(c(b, hex, HEX), "cid")
p(y[1] == y[2]); p(length(unique(y))); p(y == b); p(hex == y)
p(identical(id_bytes(y)[[1]], id_bytes(y)[[2]]))
p(as.character(id_from_bytes(id_bytes(y), "cid")))
p(id_detect(c(b, hex, HEX)))
p(grep("canonical", readLines("../src/man/id_parse.Rd"), value=TRUE))
# typeid / others canonicalization
p(as.character(id_parse("01ARZ3NDEKTSV4RRFFQ69G5FAV", "typeid")))
p(as.character(id_parse("01arz3ndektsv4rrffq69g5fav", "ulid")))
# id_parse(x) of zuid w/ levels
# CID v0 forms
v0 <- "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG"
p(id_valid(c(v0, paste0("z", v0), paste0(v0, " "), substr(v0,1,45)), "cid"))
p(id_fields(id_parse(v0,"cid"))[,c("version","codec","hash")])
r0 <- id_bytes(id_parse(v0,"cid"))[[1]]
v1 <- id_from_bytes(c(as.raw(c(1,0x70)), r0), "cid"); p(v1)
p(id_from_bytes(r0, "cid"))
p(id_from_bytes(list(r0, NULL, as.raw(1:3)), "cid"))
p(id_from_bytes(matrix(r0, ncol=1), "cid"))
# varint edge: codec 9-byte varint
mk <- function(...) id_from_bytes(as.raw(c(...)), "cid")
p(mk(1, 0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x01, 0x00, 0x00))   # codec 2^56
p(id_fields(mk(1, 0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x7f, 0x00, 0x00))[,c("codec","hash","digest")])   # 2^63-1
p(mk(1, 0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x01, 0x00, 0x00)) # 10 bytes
p(mk(1, 0x55, 0x00, 0x80, 0x00))  # non-minimal len
p(mk(1, 0x55, 0x00, 0x00))
p(id_fields(mk(1, 0x55, 0x00, 0x00))[,c("codec","hash","digest")])
p(mk(1, 0x55, 0x12, 0x20, rep(7,32)))
p(id_valid(as.character(mk(1, 0x55, 0x12, 0x1f, rep(7,31))), "cid", level="syntax"))
p(id_valid(as.character(mk(1, 0x55, 0x12, 0x1f, rep(7,31))), "cid", level="structure"))
p(id_parse(as.character(mk(1, 0x55, 0x12, 0x1f, rep(7,31))), "cid"))
p(mk(0x12, 0x20, rep(7,32))); p(mk(0x12, 0x20, rep(7,31)))
# empty multibase bodies
p(id_valid(c("b","f","z","Qm","", "bb", "f01", "k", "z1"), "cid", level="syntax"))
