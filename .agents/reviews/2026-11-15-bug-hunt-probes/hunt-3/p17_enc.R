source("hdr.R")
set.seed(9); out <- list()
lens <- c(0:20, 31:34, 63:66, 127:130, 255:258, 1000)
forms <- c("hex", "base32", "base32rfc", "base32hex", "base36", "base58", "base62", "base62sort", "base64url", "base64sort", "alphabet", "proquint")
for (L in lens) for (k in 1:6) {
  b <- as.raw(sample(0:255, L, TRUE)); if (k == 1) b <- as.raw(rep(0, L)); if (k == 2) b <- as.raw(rep(255, L)); if (k == 3 && L > 2) b[1:2] <- as.raw(0)
  enc <- lapply(forms, function(f) tryCatch(id_encode(b, f), error = function(e) paste("ERR", class(e)[1])))
  names(enc) <- forms
  enc$alpha10 <- tryCatch(id_encode(b, "alphabet", alphabet = "0123456789"), error = function(e) "ERR")
  out[[length(out) + 1]] <- c(list(hexin = paste(as.character(b), collapse = "")), enc)
}
writeLines(jsonlite::toJSON(out, auto_unbox = TRUE), "p17.json")
# id_format on generated values equals id_encode(id_bytes())
x <- uuid(50); ok <- TRUE
for (f in setdiff(forms, "base62sort")) ok <- ok && identical(unname(id_format(x, f)), unname(id_encode(id_bytes(x), f)))
chk("id_format(x, form) == id_encode(id_bytes(x), form) for uuid", ok)
print(id_formats()[1:3, ])
x <- uuid(3, time = 1.7e12, random = as.raw(1:30)); for (f in c("urn", "compact", "braced", "upper")) cat(f, ":", tryCatch(id_format(x[1], f), error = function(e) "ERR"), "\n")
