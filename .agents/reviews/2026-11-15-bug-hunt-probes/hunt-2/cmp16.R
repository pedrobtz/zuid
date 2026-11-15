source("pre.R")
d <- read.delim("cases16.tsv", header=FALSE, col.names=c("form","text","ref"), colClasses="character", na.strings=character(), quote="")
for (f in unique(d$form)) { s <- d[d$form==f,]; got <- vapply(id_decode(s$text, f), function(b) if (is.null(b)) "NA" else paste(sprintf("%02x", as.integer(b)), collapse=""), ""); cat(f, nrow(s), "cases; mismatches:", sum(got != s$ref), "\n")
  unp <- !grepl("=", s$text); bytes <- lapply(s$ref[unp], function(h) if (nzchar(h)) as.raw(strtoi(substring(h, seq(1,nchar(h),2), seq(2,nchar(h),2)), 16L)) else raw(0)); cat("   encode mismatches:", sum(id_encode(bytes, f) != s$text[unp]), "\n") }
