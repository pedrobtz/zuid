source("pre.R")
d <- read.delim("cases7.tsv", header=FALSE, col.names=c("hex","ref"), colClasses="character", na.strings=character(), quote="")
unhex <- function(h) vapply(h, function(z) { if (!nzchar(z)) return(""); r <- as.raw(strtoi(substring(z, seq(1,nchar(z),2), seq(2,nchar(z),2)), 16L)); x <- rawToChar(r); Encoding(x) <- "UTF-8"; x }, "", USE.NAMES=FALSE)
d$text <- unhex(d$hex)
for (lv in c("syntax","structure","strict")) { v <- id_valid(d$text, "cuid2", level=lv); cat(lv, ": disagreements with isCuid:", sum(v != (d$ref=="1")), "\n"); print(head(encodeString(d$text[v != (d$ref=="1")]), 8)) }
