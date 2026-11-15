.libPaths(c("HUNT_ROOT/lib", .libPaths())); suppressMessages(library(zuid))
t <- function(e) { r <- tryCatch(withCallingHandlers(e, warning=function(w){cat("  [warning:", conditionMessage(w), "]\n"); invokeRestart("muffleWarning")}), error=function(e) structure(paste0("ERR<", paste(class(e)[1], collapse=","), ">: ", conditionMessage(e)), class="err")); if (inherits(r,"err")) cat(unclass(r), "\n") else print(r); invisible(r) }
p <- function(label, e) { cat("##", label, "\n"); t(e) }
