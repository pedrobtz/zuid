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
#' version. Strict also asks that a time is no later than now plus the
#' tolerance. These formats have one text form each.
#'
#' @param x A character vector.
#' @param format The format, such as `"uuid"`. See [id_formats()]. Required
#'   for now; detecting it from `x` is not available yet.
#' @param form A text form of `format`, or `NULL` for its canonical text.
#' @param layout Reserved for formats that need a layout.
#' @param level The validation level elements must reach.
#' @param strict If `TRUE`, an element that fails `level` is an error of
#'   class `zuid_parse_error`. If `FALSE`, it becomes `NA`.
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
  strict = FALSE
) {
  level <- match.arg(level)
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
    x <- as.character(x)
  }
  check_character(x)
  if (is.null(format)) {
    zuid_abort(
      "type",
      "`format` is required: detecting it from `x` is not available yet."
    )
  }
  check_format(format)
  check_form(form, format)
  if (!isTRUE(strict) && !isFALSE(strict)) {
    zuid_abort("type", "`strict` must be `TRUE` or `FALSE`.")
  }

  parsed <- parse_text(x, format, form)
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
      positions = bad
    )
  }
  text <- parsed$text
  text[!ok] <- NA_character_
  names(text) <- names(x)
  new_zuid(text, format)
}

#' @rdname id_parse
#' @export
id_valid <- function(
  x,
  format,
  form = NULL,
  layout = NULL,
  level = c("structure", "syntax", "strict")
) {
  level <- match.arg(level)
  if (is_zuid(x)) {
    x <- as.character(x)
  }
  check_character(x)
  check_format(format)
  check_form(form, format)
  parsed <- parse_text(x, format, form)
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

parse_text <- function(x, format, form) {
  out <- .Call(
    zuid_c_parse,
    x,
    format,
    form,
    as.numeric(Sys.time()) * 1000,
    time_tolerance() * 1000
  )
  names(out) <- c("text", "level")
  out
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
