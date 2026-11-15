source("hdr.R")
all95 <- rawToChar(as.raw(32:126))
alphas <- c("a", "ab", "abc", "0123456789abcdef", "0123456789abcdefg", zuid:::nanoid_alphabet, all95, substr(all95, 1, 94), substr(all95, 2, 34), "~ ")
set.seed(42); out <- list()
for (a in alphas) for (size in c(1, 2, 21, 100, 257)) for (n in c(1, 3)) {
  rb <- as.raw(sample(0:255, 20000, TRUE))
  r <- tryCatch(as.character(nanoid(n, size, a, random = rb)), error = function(e) paste("ERR", class(e)[1]))
  out[[length(out) + 1]] <- list(alphabet = a, size = size, n = n, random = paste(as.character(rb), collapse = ""), ids = as.list(r))
}
# a random stream that is all rejects then runs out
out[[length(out) + 1]] <- list(alphabet = "abc", size = 5, n = 1, random = paste(rep("ff", 50), collapse = ""), ids = as.list(tryCatch(as.character(nanoid(1, 5, "abc", random = as.raw(rep(255, 50)))), error = function(e) paste("ERR", class(e)[1]))))
writeLines(jsonlite::toJSON(out, auto_unbox = TRUE), "p15.json")
x <- nanoid(1000); f <- table(strsplit(paste(as.character(x), collapse = ""), "")[[1]]); cat("default nanoid: 21 chars all:", all(nchar(as.character(x)) == 21), " symbols seen:", length(f), " min/max count:", range(f), "\n")
x <- nanoid(2000, 30, "abc"); f <- table(strsplit(paste(as.character(x), collapse = ""), "")[[1]]); print(f)
for (s in list(0, 65536, 65537, 1.5, NA, -1, "a", c(1, 2), Inf)) cat("size", deparse(s), "->", sub("/.*", "", try_class(v <- nanoid(1, s))), "\n")
cat("nchar at 65536:", nchar(as.character(nanoid(2, 65536))), "\n")
for (a in list("", "aa", "aé", NA_character_, c("ab", "cd"), 1, "a\tb", paste0(all95, "a"))) cat("alphabet", deparse(a), "->", sub("/.*", "", try_class(nanoid(1, 5, a))), "\n")
