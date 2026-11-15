source("pre.R")
d <- read.delim("cases1.tsv", header=FALSE, col.names=c("fmt","hex","ref"), stringsAsFactors=FALSE, colClasses="character", na.strings=character())
unhex <- function(h) vapply(h, function(z) { if (!nzchar(z)) return(""); r <- as.raw(strtoi(substring(z, seq(1,nchar(z),2), seq(2,nchar(z),2)), 16L)); x <- rawToChar(r); Encoding(x) <- "UTF-8"; x }, "", USE.NAMES=FALSE)
d$text <- unhex(d$hex)
for (f in unique(d$fmt)) {
  s <- d[d$fmt==f,]
  zf <- sub("_py","",f)
  x <- id_parse(s$text, zf, level="syntax")
  b <- id_bytes(x); got <- apply(b, 2, function(c) paste(sprintf("%02x", as.integer(c)), collapse="")); got[is.na(x)] <- "NA"
  dis <- which(got != s$ref)
  cat(sprintf("== %s: %d cases, %d ref-valid, %d zuid-valid, %d disagreements\n", f, nrow(s), sum(s$ref!="NA"), sum(got!="NA"), length(dis)))
  if (length(dis)) { u <- s[dis,]; u$got <- got[dis]; u$kind <- ifelse(u$ref=="NA","zuid-accepts", ifelse(u$got=="NA","zuid-rejects","differ")); print(table(u$kind)); for (k in unique(u$kind)) { cat("--",k,"\n"); print(head(encodeString(u$text[u$kind==k]), 12)) } }
}
