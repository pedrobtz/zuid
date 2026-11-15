source("pre.R")
u <- readRDS("dis3.rds")
a <- u[u$kind=="zuid-accepts",]
f <- id_fields(id_parse(a$text, "cid", level="syntax"))
print(cbind(substr(a$text,1,30), f[,c("version","codec","hash")], nchar(f$digest)/2, id_valid(a$text,"cid")))
r <- u[u$kind=="zuid-rejects" & substr(u$text,1,1) %in% strsplit("fFbBcCvVtTkKzmMuUQ","")[[1]],]
pre <- substr(r$text,1,1); body <- substring(r$text,2)
norm <- ifelse(pre %in% c("f","b","c","v","t","k"), tolower(body), ifelse(pre %in% c("F","B","C","V","T","K"), toupper(body), body))
norm2 <- sub("=+$", "", norm)
fixpad <- function(p, b) { blk <- if (p %in% c("c","C","t","T")) 8 else if (p %in% c("M","U")) 4 else 0; if (blk) paste0(b, strrep("=", (blk - nchar(b) %% blk) %% blk)) else b }
t2 <- paste0(pre, mapply(fixpad, pre, norm2))
x2 <- id_parse(t2, "cid", level="syntax"); b2 <- vapply(id_bytes(x2), function(v) if (is.null(v)) "NA" else paste(sprintf("%02x", as.integer(v)), collapse=""), "")
cat("rejects w/ supported prefix:", nrow(r), "; explained by case/padding leniency:", sum(b2==r$ref), "\n")
rest <- r[b2!=r$ref,]; for (i in seq_len(min(nrow(rest),40))) cat(encodeString(substr(rest$text[i],1,90)), " ref=", substr(rest$ref[i],1,30), "\n")
