source("pre.R")
d <- read.delim("cases5.tsv", header=FALSE, col.names=c("text","ref"), stringsAsFactors=FALSE, colClasses="character", na.strings=character(), quote="")
x <- id_parse(d$text, "sqids"); nums <- id_fields(x)$numbers
got <- vapply(seq_along(x), function(i) if (is.na(x[i])) "NA" else paste0("[", paste(sprintf("%.0f", nums[[i]]), collapse=", "), "]"), "")
cat(nrow(d), "cases", sum(d$ref!="NA"), "ref-valid", sum(got != d$ref), "disagreements\n")
# re-encode
ok <- which(d$ref != "NA"); re <- as.character(sqids(nums[ok])); cat("re-encode mismatches:", sum(re != d$text[ok]), "\n")
