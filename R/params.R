# Format parameters (layout, alphabet, min_length, blocklist): what a vector
# needs beyond its format to be read again. They travel as attributes and
# are compared by value when vectors combine. Only parameters that differ
# from the format's defaults are stored.

param_names <- c("layout", "alphabet", "min_length", "blocklist")

zuid_params <- function(x) {
  out <- lapply(param_names, function(p) attr(x, p, exact = TRUE))
  names(out) <- param_names
  if (is.null(out$min_length)) {
    out$min_length <- 0
  }
  out
}

# The parameters a format takes, checked, with the defaults dropped.
check_params <- function(params, format, call = sys.call(-1L)) {
  check_layout(params$layout, format, call = call)
  alphabet <- params$alphabet
  if (!is.null(alphabet)) {
    if (!format %in% c("nanoid", "sqids")) {
      zuid_abort(
        "type",
        sprintf("`%s` takes no `alphabet`.", format),
        call = call
      )
    }
    check_text_alphabet(alphabet, format, call = call)
    if (identical(alphabet, default_alphabet(format))) {
      alphabet <- NULL
    }
  }
  min_length <- params$min_length
  if (is.null(min_length)) {
    min_length <- 0
  }
  if (!is_whole(min_length) || min_length < 0 || min_length > 255) {
    zuid_abort(
      "type",
      "`min_length` must be a whole number from 0 to 255.",
      call = call
    )
  }
  if (min_length != 0 && format != "sqids") {
    zuid_abort(
      "type",
      sprintf("`%s` takes no `min_length`.", format),
      call = call
    )
  }
  list(
    layout = params$layout,
    alphabet = alphabet,
    min_length = if (min_length == 0) NULL else as.integer(min_length),
    blocklist = params$blocklist
  )
}

text_formats <- c("nanoid", "cuid2", "sqids", "cid")

# NanoID 6's url alphabet, in its order, and Sqids' default.
nanoid_alphabet <- "57X6y3wQZNzYjJB2L_10pxbackgroundhimselfUTF-8DEMOGRAPHICSVqvt4KW9"
sqids_alphabet <- "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

default_alphabet <- function(format) {
  switch(format, nanoid = nanoid_alphabet, sqids = sqids_alphabet, NULL)
}

check_text_alphabet <- function(alphabet, format, call = sys.call(-1L)) {
  check_string(alphabet, "alphabet", call = call)
  symbols <- strsplit(alphabet, "", fixed = TRUE)[[1L]]
  lo <- if (format == "sqids") 3L else 1L
  hi <- if (format == "sqids") 255L else 256L
  ok <- length(symbols) >= lo &&
    length(symbols) <= hi &&
    !anyDuplicated(symbols) &&
    all(grepl("^[ -~]$", symbols, useBytes = TRUE))
  if (!ok) {
    zuid_abort(
      "type",
      sprintf(
        "A %s `alphabet` is %d or more distinct printable ASCII characters.",
        format,
        lo
      ),
      call = call
    )
  }
}

parse_text_format <- function(x, format, params) {
  alphabet <- if (is.null(params$alphabet)) {
    default_alphabet(format)
  } else {
    params$alphabet
  }
  level <- switch(
    format,
    nanoid = .Call(zuid_c_charset, x, alphabet),
    cuid2 = .Call(zuid_c_cuid2, x),
    sqids = .Call(
      zuid_c_sqids_parse,
      x,
      alphabet,
      if (is.null(params$min_length)) 0L else params$min_length,
      params$blocklist
    )[[1L]],
    cid = .Call(zuid_c_cid_parse, x)$level
  )
  # Sqids strict is its structure; a CID has no time to be strict about.
  if (format %in% c("sqids", "cid")) {
    level[!is.na(level) & level == 2L] <- 3L
  }
  text <- x
  text[is.na(level) | level < 1L] <- NA_character_
  list(text = text, level = level)
}

# The fields of the variable-width formats, as zuid_c_fields() returns them.
text_format_fields <- function(x, format, params) {
  n <- length(x)
  cols <- list(
    time_s = rep(NA_real_, n),
    time_ns = rep(NA_real_, n),
    time_unit = rep(NA_character_, n),
    version = rep(NA_integer_, n),
    variant = rep(NA_character_, n),
    node = rep(NA_character_, n),
    sequence = rep(NA_integer_, n),
    random = rep(NA_character_, n),
    prefix = rep(NA_character_, n),
    process = rep(NA_integer_, n),
    codec = rep(NA_character_, n),
    hash = rep(NA_character_, n),
    digest = rep(NA_character_, n),
    numbers = vector("list", n)
  )
  if (format == "cid") {
    cid <- .Call(zuid_c_cid_parse, as.character(x))
    cols[c("version", "codec", "hash", "digest")] <-
      cid[c("version", "codec", "hash", "digest")]
  } else if (format == "sqids") {
    alphabet <- if (is.null(params$alphabet)) {
      sqids_alphabet
    } else {
      params$alphabet
    }
    min_length <- if (is.null(params$min_length)) 0L else params$min_length
    cols$numbers <- .Call(
      zuid_c_sqids_parse,
      as.character(x),
      alphabet,
      min_length,
      params$blocklist
    )[[2L]]
  }
  cols
}
