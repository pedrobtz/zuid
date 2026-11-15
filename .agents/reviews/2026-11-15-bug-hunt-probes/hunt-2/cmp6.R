source("pre.R")
d <- read.delim("cases6.tsv", header=FALSE, col.names=c("id","msb","time","seq","mach"), colClasses="character")
L <- id_layout("sonyflake", epoch = 1409529600000)   # 2014-09-01 UTC
print(L)
x <- id_parse(d$id, "snowflake", layout=L)
f <- id_fields(x)
ms <- id_time(x, "ms")
big <- as.numeric(d$id) >= 2^63
cat("ids >= 2^63 parsed as non-NA:", sum(!is.na(x) & big), " of ", sum(big), "; <2^63 NA:", sum(is.na(x) & !big), "\n")
ok <- !is.na(x)
exp_ms <- 1409529600000 + as.numeric(d$time[ok]) * 10
cat("time mismatches:", sum(ms[ok] != exp_ms), " seq mismatches:", sum(f$sequence[ok] != as.integer(d$seq[ok])), " machine mismatches:", sum(f$node[ok] != paste0("machine=", d$mach[ok])), "\n")
cat("time_unit:", unique(f$time_unit[ok]), "\n")
# round trip text
cat("text mismatches:", sum(as.character(x)[ok] != d$id[ok]), "\n")
b <- id_bytes(x); y <- id_from_bytes(b[, ok, drop=FALSE], "snowflake", layout=L); cat("bytes rt mismatches:", sum(as.character(y) != d$id[ok]), "\n")
# posixct exact?
pt <- id_time(x); cat("POSIXct vs ms max abs diff (s):", max(abs(as.numeric(pt[ok]) - exp_ms/1000)), "\n")
# levels
print(table(syntax=id_valid(d$id, "snowflake", layout=L, level="syntax"), structure=id_valid(d$id, "snowflake", layout=L, level="structure"), big, useNA="ifany"))
print(table(strict=id_valid(d$id, "snowflake", layout=L, level="strict"), future=as.numeric(ifelse(ok, ms, NA)) > as.numeric(Sys.time())*1000 + 86400000, useNA="ifany"))
# other layouts: twitter/discord/instagram vs manual
chk <- function(L, tb, fb, sb, epoch, mult=1, sign=TRUE) {
  ids <- d$id[as.numeric(d$id) < if (sign) 2^63 else 2^64]
  x <- id_parse(ids, "snowflake", layout=L); stopifnot(!anyNA(x))
  bits <- vapply(ids, function(s) { # decimal -> 64 bit string via repeated division
    dg <- as.integer(strsplit(s,"")[[1]]); o <- integer(64); for (k in 64:1) { r <- 0L; for (j in seq_along(dg)) { cur <- r*10L + dg[j]; dg[j] <- cur %/% 2L; r <- cur %% 2L }; o[k] <- r }; paste(o, collapse="") }, "")
  tonum <- function(b) sum(as.integer(strsplit(b,"")[[1]]) * 2^((nchar(b)-1):0))
  off <- if (sign) 1 else 0
  t <- vapply(substr(bits, off+1, off+tb), tonum, 0); 
  ms <- id_time(x, "ms"); cat(L$name, "time mismatches:", sum(ms != epoch + t*mult))
  f <- id_fields(x)
  s <- vapply(substr(bits, 64-sb+1, 64), tonum, 0); cat(" seq mismatches:", sum(f$sequence != s))
  pos <- off+tb; nodes <- character(length(ids)); first <- TRUE
  for (nm in names(fb)) { v <- vapply(substr(bits, pos+1, pos+fb[[nm]]), tonum, 0); nodes <- paste0(nodes, if (first) "" else ",", nm, "=", sprintf("%.0f", v)); pos <- pos+fb[[nm]]; first <- FALSE }
  cat(" node mismatches:", sum(f$node != nodes), "\n")
}
chk(id_layout("twitter"), 41, list(datacenter=5, worker=5), 12, 1288834974657)
chk(id_layout("discord"), 42, list(worker=5, process=5), 12, 1420070400000, sign=FALSE)
chk(id_layout("instagram"), 41, list(shard=13), 10, 1314220021721, sign=FALSE)
chk(id_layout(time=list(bits=1, unit="s", epoch=0), fields=list(a=53, b=1, c=1, d=1, e=1, g=5), sequence=1, sign_bit=FALSE), 1, list(a=53,b=1,c=1,d=1,e=1,g=5), 1, 0, 1000, sign=FALSE)
chk(id_layout(time=list(bits=53, unit="256ms", epoch=-5), fields=list(a=9), sequence=1), 53, list(a=9), 1, -5, 256)
chk(id_layout(time=list(bits=22, unit="10ms", epoch=7), fields=list(a=11), sequence=31, sign_bit=FALSE), 22, list(a=11), 31, 7, 10, sign=FALSE)
