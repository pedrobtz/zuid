# The zuid vector (design.md D2): canonical text in a character vector, with
# class c("zuid_<format>", "zuid") and a `format` attribute. One vector holds
# one format.

new_zuid <- function(text, format, layout = NULL) {
  if (!is.character(text)) {
    text <- as.character(text)
  }
  structure(
    text,
    format = format,
    layout = layout,
    class = c(paste0("zuid_", format), "zuid")
  )
}

zuid_format_of <- function(x) {
  attr(x, "format", exact = TRUE)
}

is_zuid <- function(x) {
  inherits(x, "zuid")
}

check_zuid <- function(x, arg = "x", call = sys.call(-1L)) {
  if (!is_zuid(x)) {
    zuid_abort(
      "type",
      sprintf(
        "`%s` must be a zuid vector from `id_parse()`, not %s.",
        arg,
        class(x)[[1L]]
      ),
      call = call
    )
  }
}

# Text in the format of `like`: a zuid vector of that format is taken as it
# is, a character vector is parsed and must parse completely.
as_zuid_like <- function(value, like, call = sys.call(-1L)) {
  format <- zuid_format_of(like)
  layout <- attr(like, "layout", exact = TRUE)
  if (is_zuid(value)) {
    if (!identical(attr(value, "layout", exact = TRUE), layout)) {
      zuid_abort(
        "layout",
        "Can't combine zuid vectors with different layouts.",
        call = call
      )
    }
    if (!identical(zuid_format_of(value), format)) {
      zuid_abort(
        "type",
        sprintf(
          "Can't combine a `%s` vector with a `%s` vector; use `id_convert()`.",
          format,
          zuid_format_of(value)
        ),
        call = call
      )
    }
    return(value)
  }
  if (is.null(value)) {
    return(new_zuid(character(), format, layout))
  }
  if (!is.character(value) && !all(is.na(value))) {
    zuid_abort(
      "type",
      sprintf(
        "Can't combine a `%s` vector with %s.",
        format,
        class(value)[[1L]]
      ),
      call = call
    )
  }
  id_parse(as.character(value), format = format, layout = layout, strict = TRUE)
}

#' @export
as.character.zuid <- function(x, ...) {
  as.vector(unclass(x), "character")
}

#' @export
format.zuid <- function(x, ...) {
  format(as.character(x), ...)
}

#' @export
print.zuid <- function(x, ...) {
  cat(sprintf("<%s[%d]>\n", class(x)[[1L]], length(x)))
  if (length(x) > 0L) {
    out <- as.character(x)
    names(out) <- names(x)
    print(out, quote = FALSE, ...)
  }
  invisible(x)
}

#' @export
`[.zuid` <- function(x, i, ...) {
  out <- NextMethod()
  new_zuid(out, zuid_format_of(x), attr(x, "layout", exact = TRUE))
}

#' @export
`[[.zuid` <- function(x, i, ...) {
  out <- NextMethod()
  new_zuid(out, zuid_format_of(x), attr(x, "layout", exact = TRUE))
}

#' @export
`[<-.zuid` <- function(x, i, value) {
  value <- as_zuid_like(value, x)
  out <- unclass(x)
  out[i] <- as.character(value)
  new_zuid(out, zuid_format_of(x), attr(x, "layout", exact = TRUE))
}

#' @export
`[[<-.zuid` <- function(x, i, value) {
  value <- as_zuid_like(value, x)
  out <- unclass(x)
  out[[i]] <- as.character(value)
  new_zuid(out, zuid_format_of(x), attr(x, "layout", exact = TRUE))
}

#' @export
c.zuid <- function(...) {
  args <- list(...)
  first <- args[[1L]]
  parts <- lapply(args, function(a) as.character(as_zuid_like(a, first)))
  new_zuid(
    unlist(parts, use.names = TRUE),
    zuid_format_of(first),
    attr(first, "layout", exact = TRUE)
  )
}

#' @export
rep.zuid <- function(x, ...) {
  new_zuid(NextMethod(), zuid_format_of(x), attr(x, "layout", exact = TRUE))
}

#' @export
unique.zuid <- function(x, incomparables = FALSE, ...) {
  out <- unique(as.character(x), incomparables = incomparables, ...)
  new_zuid(out, zuid_format_of(x), attr(x, "layout", exact = TRUE))
}

# Sorting is on bytes (design.md section 6.5), so a format whose canonical
# text does not sort as its value does still sorts correctly.
#' @export
xtfrm.zuid <- function(x) {
  key <- .Call(zuid_c_key, as.character(x), zuid_format_of(x))
  match(key, sort(unique(key[!is.na(key)]), method = "radix"))
}

#' @export
Ops.zuid <- function(e1, e2) {
  if (!.Generic %in% c("==", "!=")) {
    zuid_abort(
      "type",
      sprintf("`%s` is not defined for zuid vectors.", .Generic),
      call = sys.call(-1L)
    )
  }
  like <- if (is_zuid(e1)) e1 else e2
  canon <- function(v) {
    if (is_zuid(v)) {
      return(as.character(v))
    }
    if (!is.character(v)) {
      return(as.character(v))
    }
    # A string that does not parse cannot equal any identifier, so it is
    # kept as it is rather than turned into NA.
    parsed <- as.character(id_parse(
      v,
      format = zuid_format_of(like),
      layout = attr(like, "layout", exact = TRUE)
    ))
    ifelse(is.na(parsed), v, parsed)
  }
  if (
    is_zuid(e1) &&
      is_zuid(e2) &&
      !identical(zuid_format_of(e1), zuid_format_of(e2))
  ) {
    zuid_abort(
      "type",
      "Can't compare zuid vectors of different formats.",
      call = sys.call(-1L)
    )
  }
  get(.Generic)(canon(e1), canon(e2))
}

#' @export
as.data.frame.zuid <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  nm = deparse1(substitute(x))
) {
  as.data.frame.vector(
    x,
    row.names = row.names,
    optional = optional,
    ...,
    nm = nm
  )
}
