# The Go/Python oracle (tools/gen-encoding-fixtures): form, hex, text.
encoding_fixtures <- function() {
  utils::read.csv(
    test_path("fixtures", "encodings.csv"),
    colClasses = "character",
    na.strings = character()
  )
}

hex_bytes <- function(hex) {
  if (!nzchar(hex)) {
    return(raw())
  }
  as.raw(strtoi(
    substring(hex, seq(1, nchar(hex), 2), seq(2, nchar(hex), 2)),
    16L
  ))
}
