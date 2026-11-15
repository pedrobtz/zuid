source("pre.R")
d <- read.delim("cases2.tsv", header=FALSE, col.names=c("fmt","hex","ref"), stringsAsFactors=FALSE, colClasses="character", na.strings=character(), quote="")
unhex <- function(h) vapply(h, function(z) { if (!nzchar(z)) return(""); r <- as.raw(strtoi(substring(z, seq(1,nchar(z),2), seq(2,nchar(z),2)), 16L)); rawToChar(r) }, "", USE.NAMES=FALSE)
d$text <- unhex(d$hex); d$form <- unhex(d$fmt)
tohex <- function(l) vapply(l, function(b) if (is.null(b)) "NA" else paste0("E", paste(sprintf("%02x", as.integer(b)), collapse="")), "")
for (f in unique(d$form)) {
  s <- d[d$form==f,]
  al <- NULL; form <- f
  if (startsWith(f, "alphabet:")) { al <- sub("^alphabet:", "", f); form <- "alphabet" }
  got <- tohex(id_decode(s$text, form, alphabet=al))
  # elementwise path must agree
  dis <- which(got != s$ref)
  cat(sprintf("== %s: %d cases, %d ref-valid, %d zuid-valid, %d disagreements\n", substr(f,1,30), nrow(s), sum(s$ref!="NA"), sum(got!="NA"), length(dis)))
  if (length(dis)) { u <- s[dis,]; u$got <- got[dis]; u$kind <- ifelse(u$ref=="NA","zuid-accepts", ifelse(u$got=="NA","zuid-rejects","differ")); print(table(u$kind)); for (k in unique(u$kind)) { cat("--",k,"\n"); print(head(substr(encodeString(u$text[u$kind==k]),1,80), 8)) } }
  # round trip of accepted
  ok <- got != "NA"
  dec <- id_decode(s$text[ok], form, alphabet=al)
  re <- id_encode(dec, form, alphabet=al)
  re2 <- tohex(id_decode(re, form, alphabet=al))
  if (any(re2 != got[ok])) cat("   ROUNDTRIP MISMATCH", sum(re2 != got[ok]), "\n")
  # width path: decode with width = actual must equal; width = actual+1 must be NULL
  w <- lengths(dec)
  for (ww in unique(w)) { i <- which(w==ww); a <- tohex(id_decode(s$text[ok][i], form, alphabet=al, width=ww)); if (any(a != got[ok][i])) cat("   WIDTH mismatch at", ww, "\n"); if (ww < 65536) { a2 <- id_decode(s$text[ok][i], form, alphabet=al, width=ww+1); if (!all(vapply(a2, is.null, NA))) cat("   WIDTH+1 accepted at", ww, "\n") } }
}
