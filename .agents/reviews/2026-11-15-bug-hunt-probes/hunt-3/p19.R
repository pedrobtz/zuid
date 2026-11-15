source("hdr.R")
x <- uuid(5)
forms <- c("hex", "base32", "base32rfc", "base32hex", "base36", "base58", "base62", "base62sort", "base64url", "base64sort", "alphabet", "proquint", "words")
for (f in forms) { a <- tryCatch(id_format(x, f), error = function(e) paste("ERR", conditionMessage(e))); b <- tryCatch(id_encode(id_bytes(x), f), error = function(e) paste("ERR", conditionMessage(e)))
  if (!identical(unname(a), unname(b))) { cat("DIFF", f, "\n"); print(a[1]); print(b[1]) } }
str(id_bytes(x)[, 1])
reset(); tw <- id_layout("twitter"); sn <- character()
for (i in 1:3000) sn <- c(sn, as.character(snowflake(sample(1:5, 1), tw, list(datacenter = 1, worker = i %% 32))))
chk("snowflake unique across workers, 3000 calls", !anyDuplicated(sn))
