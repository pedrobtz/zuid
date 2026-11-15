source("pre.R")
set.seed(1)
m <- matrix(as.raw(sample(0:255, 16*300, TRUE)), nrow=16)
m[1:3, 1:40] <- as.raw(0); m[, 41] <- as.raw(0); m[, 42] <- as.raw(255); m[1:15, 43] <- as.raw(0); m[16,44] <- as.raw(0)
m[9, ] <- as.raw((as.integer(m[9, ]) %% 64L) + 128L); m[9,41] <- as.raw(0); m[9,42] <- as.raw(255)
u <- id_from_bytes(m, "uuid")
forms <- id_formats()$forms[[1]]
for (f in forms) {
  t <- id_format(u, f)
  back <- id_parse(t, "uuid", form=f)
  a <- identical(as.character(back), as.character(u))
  enc <- if (f %in% c("hex","compact","urn","braced","uppercase")) NA else { d <- id_decode(t, f, width=16); b <- !any(vapply(d, is.null, NA)) && identical(unname(do.call(cbind, d)), unname(m)); e <- identical(id_encode(m, f), unname(t)); b && e }
  # other-case input
  up <- id_parse(toupper(t), "uuid", form=f); lo <- id_parse(tolower(t), "uuid", form=f)
  cat(sprintf("%-11s parse-rt %s  decode/encode-path %s  upper-ok %d/300 lower-ok %d/300  nchar %s\n", f, a, enc, sum(!is.na(up) & as.character(up)==as.character(u)), sum(!is.na(lo) & as.character(lo)==as.character(u)), paste(range(nchar(t)), collapse="-")))
  # wrongly-equal: upper/lower parse to a DIFFERENT uuid?
  w <- sum(!is.na(up) & as.character(up)!=as.character(u)) + sum(!is.na(lo) & as.character(lo)!=as.character(u)); if (w) cat("    case-changed text parses to a different UUID:", w, "\n")
}
x <- "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3"
p(id_parse(c(x, toupper(x), paste0("URN:UUID:", x), paste0("urn:uuid:", toupper(x)), paste0("{", x, "}"), gsub("-","",x)), "uuid"))
p(id_parse(c(x, paste0("URN:UUID:", x), paste0("Urn:Uuid:", toupper(x)), paste0("urn:uuid:", gsub("-","",x))), "uuid", form="urn"))
p(id_parse(c(x, gsub("-","",x), toupper(gsub("-","",x)), paste0(gsub("-","",x)," ")), "uuid", form="compact"))
p(id_parse(c(x, gsub("-","",x), tolower(x)), "uuid", form="uppercase"))
p(id_parse(c(x, gsub("-","",x), sub("-","",x), paste0("-",x)), "uuid", form="hex"))
p(id_decode(c(x, gsub("-","",x), paste0("-",x,"-")), "hex", width=16))
# words w/ long separators beyond ZUID_TEXT_BUF
w <- id_format(id_parse(x,"uuid"), "words"); w2 <- gsub("-", strrep(" ", 30), w); p(nchar(w2))
p(id_parse(w2, "uuid", form="words")); p(length(id_decode(w2, "words", width=16)[[1]]))
pq <- gsub("-", strrep("-", 40), id_format(id_parse(x,"uuid"), "proquint")); p(nchar(pq)); p(id_parse(pq, "uuid", form="proquint")); p(length(id_decode(pq, "proquint")[[1]]))
# typeid prefix limits
suf <- "01h455vb4pex5vsknk084sn02q"
pre <- function(n) strrep("a", n)
p(id_valid(paste0(c(pre(1), pre(62), pre(63), pre(64), pre(200), "a_b", "a__b", "_a", "a_", "A", "a1", ""), "_", suf), "typeid"))
p(nchar(as.character(id_parse(paste0(pre(63), "_", suf), "typeid"))))
p(id_fields(id_parse(paste0(pre(63), "_", suf), "typeid"))$prefix == pre(63))
p(id_valid(c(suf, toupper(suf), paste0("a_", toupper(suf)), paste0("a_8", substring(suf,2)), paste0("a_", sub("h","i",suf)), paste0("a_", sub("h","l",suf)), paste0("a_", sub("h","o",suf)), paste0("a_", sub("h","u",suf))), "typeid"))
p(id_valid(c("01ARZ3NDEKTSV4RRFFQ69G5FAV","01ARZ3NDEKTSV4RRFFQ69G5FAI","01ARZ3NDEKTSV4RRFFQ69G5FAL","01ARZ3NDEKTSV4RRFFQ69G5FAO","01ARZ3NDEKTSV4RRFFQ69G5FAU","81ARZ3NDEKTSV4RRFFQ69G5FAV","7ZZZZZZZZZZZZZZZZZZZZZZZZZ"), "ulid", level="syntax"))
p(id_valid("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", "ulid", level="strict"))
p(id_time(id_parse("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", "ulid")))
p(id_time(id_parse("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", "ulid"), "ms") == 2^48-1)
# xid rs/xid rules
p(id_valid(c("9m4e2mr0ui3e8a215n4g", "9M4E2MR0UI3E8A215N4G", "9m4e2mr0ui3e8a215n4h", "9m4e2mr0ui3e8a215n4w", "vvvvvvvvvvvvvvvvvvvg", "vvvvvvvvvvvvvvvvvvvv", "00000000000000000000", "9m4e2mr0ui3e8a215n4g===="), "xid"))
p(id_fields(id_parse("9m4e2mr0ui3e8a215n4g", "xid"))[, c("time","node","process","sequence")])
# objectid
p(id_parse(c("507F1F77BCF86CD799439011", "507f1f77-bcf86cd799439011", "507f1f77bcf86cd79943901", "507f1f77bcf86cd7994390111"), "objectid"))
# non-ascii across formats
bad <- c("0é", "éé", "ａｂｃ")
for (f in c("nanoid","cuid2","sqids","cid","uuid","ulid","snowflake")) cat(f, id_valid(bad, f, layout = if (f=="snowflake") id_layout("discord"), level="syntax"), "\n")
p(id_valid(c("١٢٣", "１２３", "12 3", "+123", "-1", "1e3", "0x10", "0", "00", "18446744073709551615", "18446744073709551616", " 1", "1 "), "snowflake", layout=id_layout("discord")))
