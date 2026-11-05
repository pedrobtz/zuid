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

abort_entropy <- function(call = sys.call(-1L)) {
  zuid_abort(
    "entropy",
    "The operating system's entropy source failed.",
    call = call
  )
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

# A tolerance option, in seconds. It may be a number of seconds or a difftime.
option_seconds <- function(name, default) {
  tol <- getOption(name, default)
  if (inherits(tol, "difftime")) {
    tol <- as.numeric(tol, units = "secs")
  }
  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol < 0) {
    zuid_abort(
      "type",
      sprintf("The option `%s` must be a non-negative number of seconds.", name)
    )
  }
  tol
}

time_tolerance <- function() option_seconds("zuid.time_tolerance", 86400)
rollback_tolerance <- function() option_seconds("zuid.rollback_tolerance", 10)
clock_tolerance <- function() option_seconds("zuid.clock_tolerance", 0.01)
