#' Parse and validate identifiers
#'
#' `id_parse()` turns text into a zuid vector of one format, holding each
#' element's canonical text. `id_valid()` is the vectorised predicate.
#'
#' Validation is cumulative over three levels:
#'
#' * `"syntax"`: the alphabet, length, case rule and separators of the form.
#' * `"structure"`: syntax, and the value's own rules. For a UUID, the variant
#'   bits are the RFC's (`10`), except for the nil and max UUIDs.
#' * `"strict"`: structure, and the value is one its specification defines.
#'   For a UUID, the version is 1 to 8 (or nil or max), and a time field is
#'   no later than now plus the option `zuid.time_tolerance` (seconds, one
#'   day by default).
#'
#' A UUID's canonical text is lowercase and hyphenated. On input, either
#' case is accepted, and `form` selects another of the RFC 9562 text forms:
#' `"compact"` (32 hex digits), `"urn"` (`urn:uuid:` prefix), `"braced"` or
#' `"uppercase"`, or one of the encodings of [id_encode()] over the 16 bytes,
#' such as `"base32"`, `"base58"` or `"words"`.
#'
#' A ULID is 26 Crockford base32 characters, uppercase, either case on
#' input, starting `0` to `7`. A TypeID is a lowercase prefix, `_` and 26
#' lowercase Crockford characters, or the 26 alone; strict asks what it asks
#' of the UUID. A UPID is four prefix characters, `_` and 22 lowercase
#' characters, as the reference writes them; strict asks for the current
#' version. SCRU128 is 25 base36 characters and SCRU64 12, lowercase,
#' either case on input; their reserved timestamps (the first and the last)
#' pass `"syntax"` only. A KSUID is 27 base62 characters, case-sensitive,
#' at most `aWgEPTl1tmebfsQzFP4bxwgy80V`. Strict also asks that a time is no
#' later than now plus the tolerance. An XID is 20 lowercase base32hex
#' characters, an ObjectId 24 hex digits (either case on input) and a
#' Snowflake 1 to 20 decimal digits without leading zeros. A NanoID is one or
#' more symbols of its alphabet; a Cuid2 is 2 to 32 of `0-9a-z`, and strict
#' asks that it starts with a letter, as generated ones do. A Sqid is valid
#' when it decodes and its numbers encode back to it under the alphabet,
#' `min_length` and blocklist. A CID is version 0 (`Qm` and 44 base58btc
#' characters) or version 1 in one of 17 multibases; structure checks its
#' varints, and the digest length of a hash function zuid knows. These
#' formats have one text form each.
#'
#' @param x A character vector.
#' @param format The format, such as `"uuid"`. See [id_formats()]. `NULL`
#'   detects it with [id_detect()]: every element that is not missing must
#'   resolve to the same format, or the call is a `zuid_ambiguous_error`
#'   naming the candidates or a `zuid_mixed_error` naming the formats found.
#'   Elements that fit no format are `NA`, or an error with `strict = TRUE`.
#'   When no element fits, or none is present (`x` is empty or all `NA`),
#'   there is no format to detect, and the call is a `zuid_parse_error`:
#'   give `format`.
#' @param form A text form of `format`, or `NULL` for its canonical text.
#' @param layout For `"snowflake"`, required, and for `"scru64"`, optional:
#'   an [id_layout()]. It travels with the vector and says how to read its
#'   fields. A Snowflake whose layout has a sign bit must have it clear.
#' @param level The validation level elements must reach.
#' @param strict If `TRUE`, an element that fails `level` is an error of
#'   class `zuid_parse_error`. If `FALSE`, it becomes `NA`.
#' @param alphabet For `"nanoid"` and `"sqids"`, the alphabet the values
#'   were made with, or `NULL` for the format's default. It travels with the
#'   vector.
#' @param min_length For `"sqids"`, the `min_length` the values were made
#'   with. A Sqids string is valid only when its numbers encode back to it,
#'   which depends on the alphabet, `min_length` and the blocklist.
#' @return `id_parse()`: a zuid vector, the same length as `x`, with `NA`
#'   where an element is missing or fails `level`. `id_valid()`: a logical
#'   vector, `NA` where `x` is.
#' @examples
#' x <- id_parse("018F6B1C-2D3E-7A4B-8C5D-6E7F8091A2B3", "uuid")
#' x
#' id_valid(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "nope"), "uuid")
#' id_parse("{018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3}", "uuid", form = "braced")
#' @export
id_parse <- function(
  x,
  format = NULL,
  form = NULL,
  layout = NULL,
  level = c("structure", "syntax", "strict"),
  strict = FALSE,
  alphabet = NULL,
  min_length = 0
) {
  level <- match.arg(level)
  params <- list(layout = layout, alphabet = alphabet, min_length = min_length)
  if (is_zuid(x)) {
    if (!is.null(format) && !identical(format, zuid_format_of(x))) {
      zuid_abort(
        "type",
        sprintf(
          "`x` is already a `%s` vector; use `id_convert()` to reinterpret it.",
          zuid_format_of(x)
        )
      )
    }
    format <- zuid_format_of(x)
    params <- with_own_params(params, x, missing(min_length))
    x <- as.character(x)
  }
  check_character(x)
  if (is.null(format)) {
    format <- detect_one_format(x, layout)
  }
  check_format(format)
  if (!isTRUE(strict) && !isFALSE(strict)) {
    zuid_abort("type", "`strict` must be `TRUE` or `FALSE`.")
  }
  parse_zuid(x, format, form, check_params(params, format), level, strict)
}

# A zuid vector's own parameters stand unless the call gives others.
with_own_params <- function(params, x, default_min_length) {
  own <- zuid_params(x)
  if (is.null(params$layout)) {
    params$layout <- own$layout
  }
  if (is.null(params$alphabet)) {
    params$alphabet <- own$alphabet
  }
  if (default_min_length) {
    params$min_length <- own$min_length
  }
  params$blocklist <- own$blocklist
  params
}

# id_parse() once the arguments are checked; `params` from check_params().
parse_zuid <- function(
  x,
  format,
  form,
  params,
  level,
  strict,
  call = sys.call(-1L)
) {
  check_form(form, format, call = call)
  parsed <- parse_text(x, format, form, params)
  ok <- !is.na(parsed$level) & parsed$level >= level_number(level)
  if (strict && any(!ok & !is.na(x))) {
    bad <- which(!ok & !is.na(x))
    zuid_abort(
      "parse",
      sprintf(
        "%d element%s of `x` %s not a valid `%s` at level \"%s\": %s.",
        length(bad),
        if (length(bad) == 1L) "" else "s",
        if (length(bad) == 1L) "is" else "are",
        format,
        level,
        paste(head_positions(bad), collapse = ", ")
      ),
      positions = bad,
      call = call
    )
  }
  text <- parsed$text
  text[!ok] <- NA_character_
  names(text) <- names(x)
  new_zuid(text, format, params = params)
}

#' @rdname id_parse
#' @export
id_valid <- function(
  x,
  format,
  form = NULL,
  layout = NULL,
  level = c("structure", "syntax", "strict"),
  alphabet = NULL,
  min_length = 0
) {
  level <- match.arg(level)
  params <- list(layout = layout, alphabet = alphabet, min_length = min_length)
  check_format(format)
  if (is_zuid(x)) {
    # A vector of this format is checked under its own parameters; one of
    # another format is only text here.
    if (identical(format, zuid_format_of(x))) {
      params <- with_own_params(params, x, missing(min_length))
    }
    x <- as.character(x)
  }
  check_character(x)
  check_form(form, format)
  params <- check_params(params, format)
  parsed <- parse_text(x, format, form, params, text = FALSE)
  out <- !is.na(parsed$level) & parsed$level >= level_number(level)
  out[is.na(x)] <- NA
  names(out) <- names(x)
  out
}

#' The identifier formats zuid knows
#'
#' @return A data frame with one row per format: its name; its `class`
#'   (`structured`, `encoding` or `syntactic`); its `width` in bits; the
#'   length of its canonical text; its alphabet and case rule; the unit and
#'   epoch of its time field; and the text `forms` [id_format()] accepts.
#' @examples
#' id_formats()
#' @export
id_formats <- function() {
  cols <- .Call(zuid_c_formats)
  out <- as.data.frame(cols, stringsAsFactors = FALSE)
  out$forms <- format_forms(out$forms)
  out
}

# The comma-separated forms column as a list; NA for a format with none.
format_forms <- function(forms) {
  lapply(forms, function(f) {
    if (is.na(f)) character() else strsplit(f, ",", fixed = TRUE)[[1L]]
  })
}

# list(text, level); `text = FALSE` returns the levels with NULL text.
parse_text <- function(x, format, form, params = list(), text = TRUE) {
  if (format %in% text_formats) {
    return(parse_text_format(x, format, params))
  }
  now <- as.numeric(Sys.time()) * 1000
  out <- .Call(
    zuid_c_parse,
    x,
    format,
    form,
    now,
    time_tolerance() * 1000,
    text
  )
  names(out) <- c("text", "level")
  if (format == "snowflake") {
    out$level <- layout_levels(x, out$level, params$layout, now)
  }
  out
}

# A Snowflake's structure and strict levels are its layout's: the sign bit
# clear when the layout has one, and the time no later than now plus the
# tolerance.
layout_levels <- function(x, level, layout, now) {
  ok <- which(!is.na(level) & level >= 2L)
  if (!length(ok)) {
    return(level)
  }
  bytes <- .Call(zuid_c_bytes, x[ok], "snowflake")
  if (layout$sign_bit) {
    signed <- as.integer(bytes[1L, ]) >= 128L
    level[ok[signed]] <- 1L
    ok <- ok[!signed]
    bytes <- bytes[, !signed, drop = FALSE]
  }
  if (length(ok)) {
    ms <- layout_time_ms(as.vector(bytes), layout)
    level[ok] <- ifelse(ms <= now + time_tolerance() * 1000, 3L, 2L)
  }
  level
}

level_number <- function(level) {
  match(level, c("syntax", "structure", "strict"))
}

# Seconds. The option may be a number of seconds or a difftime.
time_tolerance <- function() {
  tol <- getOption("zuid.time_tolerance", 86400)
  if (inherits(tol, "difftime")) {
    tol <- as.numeric(tol, units = "secs")
  }
  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol < 0) {
    zuid_abort(
      "type",
      "The option `zuid.time_tolerance` must be a non-negative number of seconds."
    )
  }
  tol
}

known_formats <- function() {
  .Call(zuid_c_formats)$format
}

check_format <- function(format, call = sys.call(-1L)) {
  check_string(format, "format", call = call)
  if (!format %in% known_formats()) {
    zuid_abort(
      "type",
      sprintf(
        "`format` must be one of %s, not \"%s\".",
        paste0("\"", known_formats(), "\"", collapse = ", "),
        format
      ),
      call = call
    )
  }
}

check_form <- function(form, format, call = sys.call(-1L)) {
  if (is.null(form)) {
    return(invisible())
  }
  check_string(form, "form", call = call)
  formats <- .Call(zuid_c_formats)
  forms <- format_forms(formats$forms[formats$format == format])[[1L]]
  if (!form %in% forms) {
    if (!length(forms)) {
      zuid_abort(
        "type",
        sprintf("`%s` has one text form; `form` must be `NULL`.", format),
        call = call
      )
    }
    zuid_abort(
      "type",
      sprintf(
        "`form` for `%s` must be one of %s, not \"%s\".",
        format,
        paste0("\"", forms, "\"", collapse = ", "),
        form
      ),
      call = call
    )
  }
}

head_positions <- function(x, n = 5L) {
  if (length(x) > n) c(x[seq_len(n)], "...") else x
}
