.libPaths(c("HUNT_ROOT/lib", .libPaths()))
suppressMessages(library(zuid))
p <- function(e) { cat(">", deparse(substitute(e))[1], "\n"); r <- tryCatch(e, error=function(c) paste("ERROR:", class(c)[1], conditionMessage(c))); print(r) }
