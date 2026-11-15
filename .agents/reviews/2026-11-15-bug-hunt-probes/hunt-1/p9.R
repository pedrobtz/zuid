source("pre.R")
cat("locale:", Sys.getlocale("LC_CTYPE"), "\n")
p("blocklist I", {x <- sqids(list(c(4,5,6))); y <- sqids(list(c(4,5,6)), blocklist="IIVTBT"); c(as.character(x), as.character(y), attr(y,"blocklist"))})
tw <- id_layout("twitter")
# zero-length & all-NA for each format
fmts <- c("uuid","ulid","typeid","upid","scru128","scru64","ksuid","xid","objectid","nanoid","cuid2","sqids","cid")
for (f in fmts) { z <- t(id_parse(character(), f)); if (inherits(z,"err")) next; r1 <- tryCatch(dim(id_fields(z)), error=function(e) conditionMessage(e)); r2 <- tryCatch(length(id_time(z)), error=function(e) conditionMessage(e));
  n <- id_parse(c(a=NA_character_), f); r3 <- tryCatch(dim(id_fields(n)), error=function(e) conditionMessage(e)); r4 <- tryCatch(deparse(id_time(n, "ms")), error=function(e) conditionMessage(e)); r5 <- tryCatch(deparse(id_format(n)), error=function(e) conditionMessage(e)); r6 <- tryCatch(paste(deparse(id_bytes(n)), collapse=""), error=function(e) conditionMessage(e))
  cat(f, "| fields0:", r1, "| time0:", r2, "| fieldsNA:", r3, "| timeNA:", r4, "| formatNA:", r5, "| sortNA:", tryCatch(deparse(order(n)), error=function(e) conditionMessage(e)), "\n   bytesNA:", substr(r6, 1, 150), "\n") }
s0 <- id_parse(character(), "snowflake", layout=tw); p("snow0 fields", dim(id_fields(s0))); p("snowNA fields", id_fields(id_parse(c(NA_character_, NA), "snowflake", layout=tw))[, c("time","node","sequence")]); p("snow0 bytes", dim(id_bytes(s0))); p("snow0 sort", sort(s0)); p("print0", s0)
p("id_fields non zuid", id_fields("x")); p("id_time class bad", id_time(uuid(1), "s")); p("id_time class vec", id_time(uuid(1), c("ms","POSIXct")))
p("id_time names", names(id_time(c(a=uuid(1))))); p("id_version names", id_version(c(a=uuid(1), b=uuid_nil(), c=uuid_max())));  p("fields rownames", rownames(id_fields(c(a=uuid(1), b=uuid(1)))))
p("id_time ms pre-1970 v1", {x <- id_parse("00000001-0000-1000-8000-000000000000","uuid"); c(id_time(x,"ms"), as.numeric(id_time(x))*1000)})
p("id_time ms neg frac v1", {x <- uuid(1, 1, time=-1.5); c(sprintf("%.4f", id_time(x,"ms")), sprintf("%.4f", as.numeric(id_time(x))*1000))})
p("id_time ms v1 .9996", {x <- uuid(1, 1, time=1709642096789.9996, random=raw(8)); c(sprintf("%.4f", id_time(x,"ms")), sprintf("%.6f", as.numeric(id_time(x))*1000))})
# CID
cid0 <- "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"; cid1 <- "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi"
c1 <- t(id_parse(c(a=cid0, b=cid1, c=NA), "cid")); p("cid fields", id_fields(c1)[,c("version","codec","hash","digest")]); p("cid bytes", lengths(id_bytes(c1))); p("cid roundtrip", identical(id_from_bytes(id_bytes(c1), "cid"), c1)); p("cid detect", id_detect(c(cid0,cid1))); p("cid sort", order(c1)); p("cid from raw", id_from_bytes(id_bytes(c1)[[1]], "cid")); p("cid from matrix", id_from_bytes(matrix(raw(4),2), "cid")); p("cid format", id_format(c1)); p("cid upper", id_valid(toupper(cid1), "cid")); p("cid time", id_time(c1))
p("cid == text", c1 == c(cid0, toupper(cid1), NA))
# encode / decode R layer
b <- as.raw(c(0,0,1,2,255))
forms <- c("hex","base32","base32rfc","base32hex","base36","base58","base62","base62sort","base64url","base64sort","alphabet","proquint","words")
set.seed(1); bad <- 0
for (f in forms) for (len in c(0:20, 32, 33, 64, 255, 256)) { if (f %in% c("proquint","words") && len %% 2) next
  for (k in 1:3) { v <- as.raw(sample(0:255, len, TRUE)); if (k == 2 && len > 2) v[1:2] <- as.raw(0); if (k==3 && len) v[] <- as.raw(255)
    e <- tryCatch(id_encode(v, f), error=function(e) NA); d <- tryCatch(id_decode(e, f)[[1]], error=function(e) NULL); d2 <- tryCatch(id_decode(e, f, width=len)[[1]], error=function(e) NULL)
    if (!identical(d2, v) || (!identical(d, v))) { bad <- bad + 1; if (bad < 15) cat("RT FAIL", f, len, k, e, "\n") } } }
cat("round-trip failures:", bad, "\n")
p("encode list names", id_encode(list(a=b, a=NULL, b), "hex")); p("encode matrix na", id_encode(id_bytes(id_parse(c(x="018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", y=NA), "uuid")), "base58"))
p("encode int", id_encode(1:3, "hex")); p("encode chr", id_encode("a", "hex")); p("encode list mixed", id_encode(list(b, 1L), "hex")); p("encode named raw", id_encode(c(a=b[1], b=b[2]), "hex")); p("encode empty list", id_encode(list(), "hex")); p("encode raw0", id_encode(raw(), "base58"))
p("form vec", id_encode(b, c("hex","base58"))); p("form NA", id_encode(b, NA)); p("form partial", id_encode(b, "base6"))
p("sep", list(t(id_encode(as.raw(1:4), "proquint", sep="")), t(id_encode(as.raw(1:4), "words", sep="")), t(id_encode(as.raw(1:4), "words", sep="a")), t(id_encode(as.raw(1:4), "words", sep="é")), id_encode(as.raw(1:4), "words", sep="\n"), id_encode(as.raw(1:4), "words", sep=" - "), t(id_encode(as.raw(1:4), "words", sep=NA)), t(id_encode(as.raw(1:4), "words", sep=c("-","_"))), id_encode(as.raw(1:4), "hex", sep="zz"[0]) ))
p("sep digits words", {e <- id_encode(as.raw(1:4), "words", sep="1"); c(e, identical(id_decode(e, "words")[[1]], as.raw(1:4)))})
p("sep ignored for hex?", id_encode(as.raw(1:4), "hex", sep=":"))
p("alphabet", list(id_encode(b, "alphabet", alphabet="01"), t(id_encode(b, "alphabet", alphabet="0")), t(id_encode(b, "alphabet", alphabet="0 1")), t(id_encode(b, "hex", alphabet="01")), t(id_encode(b, "alphabet", alphabet="001")), t(id_encode(b, "alphabet", alphabet=c("01","23")))))
p("decode alph rt", identical(id_decode(id_encode(b, "alphabet", alphabet="01"), "alphabet", alphabet="01")[[1]], b))
p("decode names/NA", id_decode(c(a="00", a=NA, "zz", ""), "hex")); p("decode factor", id_decode(factor("00"), "hex")); p("decode width", list(id_decode("0001", "hex", width=2), id_decode("0001", "hex", width=3), t(id_decode("00", "hex", width=-1)), t(id_decode("00", "hex", width=1.5)), t(id_decode("00","hex",width=NA)), t(id_decode("00","hex",width=c(1,2))), t(id_decode("00","hex",width="1")), id_decode("", "hex", width=0), t(id_decode("00","hex",width=65537))))
p("decode width base58", list(id_decode("11", "base58", width=2), id_decode("2", "base58", width=2), id_decode("2", "base62", width=2), id_decode("2", "base62"), id_decode("0002", "base62"), id_decode("0000002", "base62")))
p("decode ws", id_decode(c(" 00", "00 ", "00\n", "0x00"), "hex"))
p("encode > 65536", id_encode(raw(65537), "hex")); p("encode 65536 hex nchar", nchar(id_encode(raw(65536), "hex")))
p("uuid form width check", id_parse(c(id_encode(raw(15), "base58"), id_encode(raw(17), "base62"), id_encode(raw(16),"base58"), id_encode(raw(8),"hex")), "uuid", form="base58"))
p("uuid form alphabet no alphabet arg", {u <- id_parse("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3","uuid"); a <- id_format(u, "alphabet"); id_parse(a, "uuid", form="alphabet") == u})
