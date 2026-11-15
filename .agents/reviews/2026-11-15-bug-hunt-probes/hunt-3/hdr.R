.libPaths(c("HUNT_ROOT/lib", .libPaths()))
suppressMessages(library(zuid))
reset <- function() invisible(.Call(zuid:::zuid_c_reset_state))
chk <- function(label, ok) cat(sprintf("%-70s %s\n", label, if (isTRUE(ok)) "HELD" else "**FAIL**"))
try_class <- function(expr) tryCatch({force(expr); "ok"}, error = function(e) paste(class(e), collapse="/"))
sorted_strict <- function(x) { x <- as.character(x); all(x[-1] > x[-length(x)]) }
