source("pre.R")
d <- read.delim("cases11.tsv", header=FALSE, col.names=c("fmt","text","kw"), colClasses="character", quote="")
get <- function(kw, key, num=FALSE) { m <- regmatches(kw, regexec(paste0('"', key, '": ("?)([^",}]*)'), kw)); v <- vapply(m, function(z) if (length(z)) z[3] else NA_character_, ""); v[!is.na(v) & v=="null"] <- NA; v }
cmp <- function(lbl, a, b) { bad <- which(!(is.na(a) & is.na(b)) & (is.na(a) != is.na(b) | a != b)); cat(sprintf("  %-10s mismatches: %d\n", lbl, length(bad))); if (length(bad)) print(head(data.frame(got=a[bad], ref=b[bad]), 5)); invisible(bad) }
for (f in unique(d$fmt)) {
  s <- d[d$fmt==f,]; cat("==", f, "\n")
  if (f == "xid_bytes") { hx <- s$text; m <- vapply(hx, function(h) as.raw(strtoi(substring(h, seq(1,23,2), seq(2,24,2)), 16L)), raw(12)); x <- id_from_bytes(m, "xid"); stopifnot(all(id_valid(as.character(x), "xid")))
    b2 <- id_bytes(id_parse(as.character(x), "xid")); stopifnot(identical(unname(b2), unname(m)))
  } else if (f == "uuid") x <- id_parse(s$text, "uuid", level="syntax") else x <- id_parse(s$text, f, level="syntax")
  cat("  NA:", sum(is.na(x)), "\n")
  fl <- id_fields(x); ms <- id_time(x, "ms")
  if (f == "uuid") {
    sp <- get(s$kw,"special")=="true"
    cmp("version", as.character(fl$version)[!sp], get(s$kw,"version")[!sp]); cmp("variant", fl$variant[!sp], get(s$kw,"variant")[!sp])
    tk <- get(s$kw,"ticks"); hasT <- !is.na(tk); # ticks -> ms floor
    exp_ms <- floor((as.numeric(tk) - 122192928000000000)/10000)
    cmp("v1/6 ms", sprintf("%.0f", ms[hasT]), sprintf("%.0f", exp_ms[hasT]))
    m7 <- get(s$kw,"ms"); cmp("v7 ms", sprintf("%.0f", ms[!is.na(m7)]), m7[!is.na(m7)])
    cmp("time NA", is.na(ms), !(hasT | !is.na(m7)))
    cmp("sequence", as.character(fl$sequence), get(s$kw,"sequence")); cmp("node", fl$node, get(s$kw,"node")); cmp("random", fl$random, get(s$kw,"random"))
  } else {
    cmp("ms", sprintf("%.0f", ms), get(s$kw,"ms"))
    if (f == "scru64") { nb <- as.integer(get(s$kw,"node_bits")); nd <- sq <- character(nrow(s)); for (k in unique(nb)) { i <- which(nb==k); y <- id_parse(s$text[i], "scru64", layout=id_layout("scru64", node_bits=k), level="syntax"); g <- id_fields(y); nd[i] <- g$node; sq[i] <- g$sequence; stopifnot(identical(id_time(y,"ms"), ms[i])) }
      cmp("node", nd, paste0("node=", get(s$kw,"node"))); cmp("sequence", sq, get(s$kw,"sequence")) }
    else { for (k in c("node","sequence","random","process","prefix")) { r <- get(s$kw,k); if (!all(is.na(r))) cmp(k, as.character(fl[[k]]), r) } }
    if (f == "upid") { hb <- get(s$kw,"hexb"); gb <- apply(id_bytes(x), 2, function(c) paste(sprintf("%02x", as.integer(c)), collapse="")); cmp("bytes", unname(gb), hb) }
  }
}
