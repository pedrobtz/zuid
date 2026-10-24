# Every condition inherits from `zuid_error` (design.md section 8). Tests
# assert on the class, never the message.
zuid_abort <- function(class, message, ..., call = sys.call(-1L)) {
  cnd <- structure(
    class = c(
      paste0("zuid_", class, "_error"),
      "zuid_error",
      "error",
      "condition"
    ),
    list(message = message, call = call, ...)
  )
  stop(cnd)
}

check_character <- function(x, arg = "x", call = sys.call(-1L)) {
  if (!is.character(x)) {
    zuid_abort(
      "type",
      sprintf("`%s` must be a character vector, not %s.", arg, class(x)[[1L]]),
      call = call
    )
  }
}

check_string <- function(x, arg, call = sys.call(-1L)) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    zuid_abort(
      "type",
      sprintf("`%s` must be a single string.", arg),
      call = call
    )
  }
}
