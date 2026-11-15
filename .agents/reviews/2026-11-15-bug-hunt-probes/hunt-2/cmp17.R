source("pre.R")
d <- read.delim("cases17.tsv", header=FALSE, col.names=c("form","text","ref"), colClasses="character", quote="")
for (f in unique(d$form)) { s <- d[d$form==f,]; x <- id_parse(s$text, "uuid", form=f, level="syntax"); cat(f, nrow(s), "parse mismatches:", sum(is.na(x) | as.character(x) != s$ref), " format mismatches:", sum(id_format(id_parse(s$ref, "uuid", level="syntax"), f) != s$text), "\n") }
