#' Text forms and bytes
#'
#' `id_format()` writes identifiers in their canonical text or another text
#' form. `id_bytes()` returns their bytes, and `id_from_bytes()` reads them
#' back.
#'
#' Every encoding of [id_encode()] is a form of a UUID too: `id_format(x,
#' "base62")` is `id_encode(id_bytes(x), "base62")`.
#'
#' `id_from_bytes()` has no default `format`: sixteen bytes are not a UUID
#' until the caller says so.
#'
#' @param x A zuid vector from [id_parse()].
#' @param form A text form of the vector's format (see [id_formats()]), or
#'   `NULL` for the canonical text.
#' @param bytes A raw matrix with one column per element, a list of raw
#'   vectors (`NULL` for a missing element), or one raw vector holding the
#'   elements back to back.
#' @param format The format the bytes are in. Required.
#' @param layout For `"snowflake"` (required) and `"scru64"` (optional), an
#'   [id_layout()].
#' @return `id_format()`: a character vector. `id_bytes()`: a raw matrix
#'   with the format's width in rows and one column per element, big-endian,
#'   with missing elements as columns of zeros listed in the attribute `na`.
#'   `id_from_bytes()`: a zuid vector.
#' @examples
#' x <- id_parse("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "uuid")
#' id_format(x, "urn")
#' id_format(x, "compact")
#' id_format(x, "base32")
#' b <- id_bytes(x)
#' b[, 1]
#' id_from_bytes(b, "uuid")
#' @export
id_format <- function(x, form = NULL) {
  check_zuid(x)
  format <- zuid_format_of(x)
  check_form(form, format)
  if (format %in% text_formats) {
    out <- as.character(x)
    names(out) <- names(x)
    return(out)
  }
  out <- .Call(zuid_c_format, as.character(x), format, form)
  names(out) <- names(x)
  out
}

#' @rdname id_format
#' @export
id_bytes <- function(x) {
  check_zuid(x)
  if (zuid_format_of(x) == "cid") {
    out <- .Call(zuid_c_cid_parse, as.character(x))$bytes
    names(out) <- names(x)
    return(out)
  }
  if (zuid_format_of(x) %in% text_formats) {
    zuid_abort(
      "type",
      sprintf("A `%s` is text and has no bytes.", zuid_format_of(x))
    )
  }
  out <- .Call(zuid_c_bytes, as.character(x), zuid_format_of(x))
  missing <- which(is.na(x))
  if (length(missing)) {
    attr(out, "na") <- missing
  }
  out
}

#' @rdname id_format
#' @export
id_from_bytes <- function(bytes, format, layout = NULL) {
  if (missing(format)) {
    zuid_abort(
      "type",
      "`format` is required: bytes alone do not say which identifier they are."
    )
  }
  check_format(format)
  check_layout(layout, format)
  if (format == "cid") {
    return(cid_from_bytes(bytes))
  }
  if (format %in% text_formats) {
    zuid_abort("type", sprintf("A `%s` is text and has no bytes.", format))
  }
  width <- id_formats()$width[id_formats()$format == format] %/% 8L
  if (is.list(bytes)) {
    na <- vapply(bytes, is.null, logical(1))
    ok <- vapply(
      bytes,
      function(b) is.null(b) || (is.raw(b) && length(b) == width),
      logical(1)
    )
    if (!all(ok)) {
      zuid_abort(
        "type",
        sprintf("Each element of `bytes` must be NULL or %d raw bytes.", width)
      )
    }
    bytes[na] <- list(raw(width))
    flat <- unlist(bytes, use.names = FALSE)
    if (is.null(flat)) flat <- raw()
  } else if (is.raw(bytes)) {
    if (is.matrix(bytes) && nrow(bytes) != width) {
      zuid_abort(
        "type",
        sprintf("A `%s` matrix of bytes must have %d rows.", format, width)
      )
    }
    if (length(bytes) %% width != 0L) {
      zuid_abort(
        "type",
        sprintf("`bytes` must hold a multiple of %d bytes.", width)
      )
    }
    flat <- as.vector(bytes)
    na <- rep(FALSE, length(flat) %/% width)
    na[attr(bytes, "na", exact = TRUE)] <- TRUE
  } else {
    zuid_abort(
      "type",
      sprintf(
        "`bytes` must be raw or a list of raw vectors, not %s.",
        class(bytes)[[1L]]
      )
    )
  }
  text <- .Call(zuid_c_from_bytes, flat, format, na)
  if (format == "snowflake" && layout$sign_bit) {
    signed <- as.integer(flat[seq(1L, by = 8L, length.out = length(na))]) >=
      128L
    if (any(signed & !na)) {
      zuid_abort(
        "layout",
        "A Snowflake with a sign bit in its layout must have the top bit clear."
      )
    }
  }
  new_zuid(text, format, layout)
}

#' The nil and max UUIDs
#'
#' @return A zuid vector of one UUID: all bits zero (`id_nil()`) or all bits
#'   one (`id_max()`).
#' @examples
#' id_nil()
#' id_max()
#' @export
id_nil <- function() {
  new_zuid("00000000-0000-0000-0000-000000000000", "uuid")
}

#' @rdname id_nil
#' @export
id_max <- function() {
  new_zuid("ffffffff-ffff-ffff-ffff-ffffffffffff", "uuid")
}

cid_from_bytes <- function(bytes, call = sys.call(-1L)) {
  if (is.raw(bytes) && !is.matrix(bytes)) {
    bytes <- list(bytes)
  }
  ok <- is.list(bytes) &&
    all(vapply(bytes, function(b) is.null(b) || is.raw(b), logical(1)))
  if (!ok) {
    zuid_abort(
      "type",
      "CID bytes are a raw vector or a list of raw vectors.",
      call = call
    )
  }
  text <- .Call(zuid_c_cid_text, unname(bytes))
  bad <- is.na(text) & !vapply(bytes, is.null, logical(1))
  if (any(bad)) {
    zuid_abort(
      "parse",
      sprintf("Element %d of `bytes` is not a binary CID.", which(bad)[1L]),
      positions = which(bad),
      call = call
    )
  }
  names(text) <- names(bytes)
  new_zuid(text, "cid")
}
