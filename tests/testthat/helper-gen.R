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

# Over the bytes, so it holds for any format.
strictly_increasing <- function(x) {
  key <- id_encode(id_bytes(x), "hex")
  all(key[-1L] > key[-length(key)])
}

# Makes the entropy source fail until the calling test ends.
local_entropy_failure <- function(env = parent.frame()) {
  .Call(zuid:::zuid_c_entropy_fail, TRUE)
  withr::defer(.Call(zuid:::zuid_c_entropy_fail, FALSE), envir = env)
}
