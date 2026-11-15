source("hdr.R")
# minimal JSON in/out without packages
txt <- paste(readLines("p12_cases.json", warn = FALSE), collapse = "")
cases <- if (requireNamespace("jsonlite", quietly = TRUE)) jsonlite::fromJSON(txt, simplifyVector = FALSE) else stop("need jsonlite")
out <- lapply(cases, function(c) {
  ts <- as.numeric(unlist(c$ts)); rb <- as.raw(unlist(c$rb)); rbk <- if (isTRUE(c$reset)) "reset" else "error"
  tryCatch({
    v <- if (c$kind == "scru128") scru128(length(ts), random = rb, time = ts, rollback = rbk) else scru64(length(ts), c$node, c$nb, random = rb, time = ts, rollback = rbk)
    as.list(as.character(v))
  }, zuid_clock_error = function(e) sprintf("clock@%s", sub(".*at value ([0-9]+);.*", "\\1", conditionMessage(e))),
     zuid_overflow_error = function(e) sprintf("overflow@%s", sub("^Value ([0-9]+) .*", "\\1", conditionMessage(e))))
})
writeLines(jsonlite::toJSON(out, auto_unbox = TRUE), "p12_out.json")
