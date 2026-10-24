# Generation state is per session; tests that depend on it start clean.
local_fresh_state <- function(env = parent.frame()) {
  .Call(zuid:::zuid_c_reset_state)
  withr::defer(.Call(zuid:::zuid_c_reset_state), envir = env)
}

hex_raw <- function(hex) {
  hex <- gsub("-", "", hex)
  as.raw(strtoi(
    substring(hex, seq(1, nchar(hex), 2), seq(2, nchar(hex), 2)),
    16L
  ))
}

strictly_increasing <- function(x) {
  key <- id_format(x, "compact")
  all(key[-1L] > key[-length(key)])
}
