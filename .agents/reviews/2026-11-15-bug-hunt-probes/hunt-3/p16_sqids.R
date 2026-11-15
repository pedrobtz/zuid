source("hdr.R")
set.seed(3)
cases <- list()
add <- function(numbers, alphabet = NULL, min_length = 0, blocklist = NULL) {
  r <- tryCatch(as.character(sqids(list(numbers), alphabet, min_length, blocklist)), error = function(e) paste("ERR", class(e)[1]))
  cases[[length(cases) + 1]] <<- list(numbers = as.list(sprintf("%.0f", numbers)), alphabet = alphabet, min_length = min_length, blocklist = if (is.null(blocklist)) NULL else as.list(blocklist), id = r)
}
for (i in 0:30000) add(i)                       # default blocklist exercised on short ids
for (i in 1:3000) add(floor(runif(sample(1:6, 1)) * 10^sample(1:15, 1)))
for (v in list(2^53 - 1, c(2^53 - 1, 2^53 - 1), 0, c(0, 0, 0, 0), rep(1, 300), numeric(0))) add(v)
al <- c("abc", "abcd", "0123456789abcdef", rawToChar(as.raw(33:126)), "XYZxyz_-", "cab")
for (a in al) for (ml in c(0, 1, 5, 17, 255)) for (k in 1:25) add(floor(runif(sample(1:4, 1)) * 10^sample(0:9, 1)), a, ml)
for (ml in c(0, 3, 62, 63, 64, 100, 255)) for (k in 1:20) add(floor(runif(sample(1:3, 1)) * 1000), NULL, ml)
bl <- list(character(0), c("ab", "abc", "a1b2"), c("ABC", "x"), c("0", "1", "2"), c("86Rf07", "se8ojk", "ARsz1p"), c("a", "b", "c", "d", "e", "f", "g", "h"))
for (b in bl) for (k in 1:60) add(floor(runif(sample(1:3, 1)) * 10^sample(0:6, 1)), NULL, sample(c(0, 4, 10), 1), b)
for (k in 1:40) add(k, "abc", 0, c("a", "b"))   # everything blocked?
for (k in 1:40) add(k, "abcde", 0, c("ab", "ba", "cd", "dc", "ee"))
writeLines(jsonlite::toJSON(cases, auto_unbox = TRUE, null = "null"), "p16.json")
cat(length(cases), "cases\n")
x <- sqids(c(a = 1, b = NA, c = 3)); print(x); print(sqids(list(1:3, NULL, NA, integer(0))))
for (v in list(-1, 1.5, 2^53, Inf, "a", list("a"), list(c(1, NA)), TRUE)) cat("numbers", deparse(v), "->", sub("/.*", "", try_class(sqids(v))), "\n")
for (ml in list(-1, 256, 1.5, NA, "a", c(1, 2))) cat("min_length", deparse(ml), "->", sub("/.*", "", try_class(sqids(1, min_length = ml))), "\n")
