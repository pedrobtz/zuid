source("pre.R")
d <- read.delim("cases4.tsv", header=FALSE, col.names=c("ci","hex","ref"), stringsAsFactors=FALSE, colClasses="character", na.strings=character(), quote="")
unhex <- function(h) vapply(h, function(z) { if (!nzchar(z)) return(""); r <- as.raw(strtoi(substring(z, seq(1,nchar(z),2), seq(2,nchar(z),2)), 16L)); rawToChar(r) }, "", USE.NAMES=FALSE)
d$text <- unhex(d$hex)
alph <- c(rep("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",3),"abc","abc","0123456789abcdef","0123456789abcdef","ABCDEFGHIJKLMNOPQRSTUVWXYZ", rawToChar(as.raw(33:126)), "fuckasdbith","fuckasdbith")
ml <- c(0,10,255,0,7,0,40,0,0,0,5)
for (ci in 0:10) {
  s <- d[d$ci==as.character(ci),]
  x <- id_parse(s$text, "sqids", alphabet=alph[ci+1], min_length=ml[ci+1])
  nums <- id_fields(x)$numbers
  got <- vapply(seq_along(x), function(i) if (is.na(x[i])) "NA" else paste0("[", paste(sprintf("%.0f", nums[[i]]), collapse=", "), "]"), "")
  v <- id_valid(s$text, "sqids", alphabet=alph[ci+1], min_length=ml[ci+1])
  stopifnot(identical(unname(v), !is.na(as.character(x))))
  dis <- which(got != s$ref)
  cat(sprintf("cfg %d: %d cases, %d ref-valid, %d zuid-valid, %d disagreements\n", ci, nrow(s), sum(s$ref!="NA"), sum(got!="NA"), length(dis)))
  if (length(dis)) { for (i in head(dis, 8)) cat("   ", encodeString(substr(s$text[i],1,60)), " ref=", substr(s$ref[i],1,60), " got=", substr(got[i],1,60), "\n") }
}
