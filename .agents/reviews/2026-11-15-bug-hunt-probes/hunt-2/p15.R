source("pre.R")
set.seed(3)
for (n in c(65535L, 65536L)) { b <- as.raw(sample(0:255, n, TRUE)); b0 <- b; b0[1:5] <- as.raw(0)
  for (f in c("hex","base32","base32rfc","base32hex","base36","base58","base62","base64url","base64sort","alphabet","proquint","words")) {
    for (bb in list(b, b0, as.raw(rep(255L, n)), raw(n))) {
      if (f %in% c("proquint","words") && n %% 2) next
      t <- id_encode(bb, f); d <- id_decode(t, f)[[1]]; dw <- id_decode(t, f, width=n)[[1]]; dn <- id_decode(t, f, width=n-1L)[[1]]
      if (!identical(d, bb) || !identical(dw, bb) || !is.null(dn)) cat("MISMATCH", f, n, "\n")
    }
  }
}
cat("cap straddle ok\n")
p(tryCatch(id_encode(raw(65537), "hex"), error=function(e) class(e)[1]))
p(length(id_decode(strrep("00", 65537), "hex")[[1]]))
p(tryCatch(id_decode("00", "hex", width=65537), error=function(e) class(e)[1]))
p(id_decode(c("", "00"), "hex", width=0)); p(id_decode("00", "hex", width=1.0)); p(tryCatch(id_decode("00", "hex", width=1.5), error=function(e) class(e)[1]))
p(tryCatch(id_decode("00", "hex", width=NA), error=function(e) class(e)[1])); p(tryCatch(id_decode("00", "hex", width=c(1,1)), error=function(e) class(e)[1])); p(tryCatch(id_decode("00", "hex", width=-1), error=function(e) class(e)[1])); p(tryCatch(id_decode("00", "hex", width="1"), error=function(e) class(e)[1])); p(id_decode("00", "hex", width=TRUE))
for (n in c(50000, 200000, 400000)) { s <- strrep("z", n); cat(n, "chars base58 decode seconds:", system.time(r <- id_decode(s, "base58"))[["elapsed"]], " bytes:", length(r[[1]]), "\n") }
for (n in c(200000)) { s <- paste0("0", strrep("z", n-1)); cat(n, "chars base62 decode seconds:", system.time(r <- id_decode(s, "base62"))[["elapsed"]], " bytes:", length(r[[1]]), "\n") }
s <- paste0("z", strrep("1", 400000)); cat("cid base58 400k chars seconds:", system.time(r <- id_valid(s, "cid"))[["elapsed"]], r, "\n")
