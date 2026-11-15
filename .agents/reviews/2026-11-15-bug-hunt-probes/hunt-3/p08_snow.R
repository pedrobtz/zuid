source("hdr.R")
con <- file("p08.tsv", "w")
emit <- function(...) writeLines(paste(..., sep = "\t"), con)
run <- function(tag, L, worker, times, order_desc, n = 3) {
  for (t in times) { reset()
    r <- tryCatch(as.character(snowflake(n, L, worker, time = t)), error = function(e) paste("ERR", class(e)[1]))
    emit(tag, order_desc, sprintf("%.0f", L$epoch), layout_units_ms[[L$unit]], sprintf("%.6f", t), paste(sprintf("%.0f", unlist(worker)), collapse = ","), paste(r, collapse = ","))
  }
}
layout_units_ms <- c(ms = 1, "10ms" = 10, "256ms" = 256, s = 1000)
tw <- id_layout("twitter"); e <- tw$epoch
run("twitter", tw, list(datacenter = 31, worker = 0), c(e, e + 0.999, e + 1, 1.7e12, e + 2^41 - 1, e + 2^41 - 0.5), "time:41,datacenter:5,worker:5,sequence:12")
run("twitter_rev", tw, list(worker = 30, datacenter = 1), c(1.7e12), "time:41,datacenter:5,worker:5,sequence:12")
dc <- id_layout("discord"); e <- dc$epoch
run("discord", dc, list(worker = 31, process = 17), c(e, 1.7e12, e + 2^41, e + 2^42 - 1), "time:42,worker:5,process:5,sequence:12")
ig <- id_layout("instagram"); e <- ig$epoch
run("instagram", ig, 8191, c(e, 1.7e12, e + 2^41 - 1), "time:41,shard:13,sequence:10")
sf <- id_layout("sonyflake", epoch = 1409529600000); e <- sf$epoch
run("sonyflake", sf, 65535, c(e, e + 9.999, e + 10, 1.7e12 + 5, e + 10 * (2^39 - 1) + 9), "time:39,sequence:8,machine:16")
sfp <- id_layout("sonyflake", epoch = as.POSIXct("2014-09-01", tz = "UTC"))
run("sonyflake_posix", sfp, 1, c(1.7e12 + 5), "time:39,sequence:8,machine:16")
s64 <- id_layout("scru64", node_bits = 8)
run("scru64layout", s64, 255, c(256, 1.7e12, 256 * 2^39 - 1), "time:39,node:8,sequence:16")
# custom: wide node (40 bits), 1-bit sequence, s unit, negative epoch
c1 <- id_layout(time = list(bits = 22, unit = "s", epoch = -1e12), fields = list(big = 40), sequence = 1)
run("wide_node", c1, 2^40 - 1, c(-1e12, -1e12 + 999.9, 0, -1e12 + 1000 * (2^22 - 1)), "time:22,big:40,sequence:1", n = 5)
c2 <- id_layout(time = list(bits = 10, unit = "256ms", epoch = 1.7e12), fields = list(a = 53), sequence = 1, sign_bit = FALSE)
run("node53", c2, 2^53 - 1, c(1.7e12, 1.7e12 + 255, 1.7e12 + 256 * 1023), "time:10,a:53,sequence:1")
run("node53b", c2, 2^52 + 1, c(1.7e12), "time:10,a:53,sequence:1")
c3 <- id_layout(time = list(bits = 53, unit = "ms", epoch = 0), fields = list(a = 1, b = 1, c = 1, d = 1, e = 1, f = 1), sequence = 4)
run("six_fields", c3, list(a = 1, b = 0, c = 1, d = 0, e = 1, f = 1), c(0, 1.7e12, 2^53 - 1), "time:53,a:1,b:1,c:1,d:1,e:1,f:1,sequence:4", n = 20)
c4 <- id_layout(time = list(bits = 1, unit = "s", epoch = 1.7e12), fields = list(a = 32), sequence = 31, sign_bit = FALSE)
run("time1bit", c4, 2^32 - 1, c(1.7e12, 1.7e12 + 1999), "time:1,a:32,sequence:31")
close(con)
