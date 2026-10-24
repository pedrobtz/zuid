#' Encode and decode bytes
#'
#' `id_encode()` writes bytes of any length as text in a form, and
#' `id_decode()` reads them back. A UUID's text forms are the 16-byte case:
#' `id_format(x, form)` is `id_encode(id_bytes(x), form)`.
#'
#' Each form writes what the mainstream Go and Python libraries write, so
#' text made elsewhere decodes here and the other way round:
#'
#' * `"hex"`: lowercase hexadecimal. Decoding takes either case and ignores
#'   hyphens.
#' * `"base32"`: Crockford's alphabet, with the spare bits in front as zero
#'   bits, as ULID and TypeID do. Sixteen bytes give 26 characters starting
#'   `0` to `7`, so a UUID in this form is textually a ULID. Uppercase, and
#'   either case on input; the letters `I`, `L`, `O` and `U` are rejected.
#' * `"base32rfc"`, `"base32hex"`: RFC 4648 sections 6 and 7, with the spare
#'   bits at the end and no padding. Decoding also takes `=` padding.
#' * `"base36"`: `0-9a-z`, fixed width; 16 bytes are Uuid25's 25 characters.
#' * `"base58"`: base58btc. Each leading zero byte is one `1`, so the length
#'   varies, as in Bitcoin and Go's and Python's base58.
#' * `"base62"`, `"base62sort"`: `0-9A-Za-z`, fixed width, padded with `0`;
#'   sorts as the bytes do. The two names are one form.
#' * `"base64url"`: RFC 4648 section 5, no padding. Decoding also takes `=`
#'   padding.
#' * `"base64sort"`: base64url's bits in the IETF draft's alphabet, in ASCII
#'   order, so it sorts as the bytes do.
#' * `"alphabet"`: the caller's symbols, most significant digit first, fixed
#'   width, padded with the first symbol. The default is ShortUUID's 57
#'   symbols, as ShortUUID 1.0 and later write them.
#' * `"proquint"`: each 16 bits as five pronounceable letters.
#' * `"words"`: each 16 bits as a Niceware word. The Niceware list was not
#'   checked for offensive words, and some text in this form may offend.
#'
#' The fixed-width forms (`"base32"`, `"base36"`, `"base62"`, `"alphabet"`)
#' write the digits the byte count needs, so the length gives the byte count
#' back. `"proquint"` and `"words"` take an even number of bytes, and their
#' decoding ignores case and any non-letter between units.
#'
#' @param bytes A raw vector (one element), a list of raw vectors (`NULL` for
#'   a missing element), or a raw matrix with one element per column. At most
#'   65536 bytes per element.
#' @param text A character vector.
#' @param form The form.
#' @param alphabet For `form = "alphabet"`, its symbols in digit order: 2 to
#'   94 distinct printable ASCII characters other than space. `NULL` for
#'   ShortUUID's.
#' @param sep The separator between units for `"proquint"` and `"words"`.
#'   It must not contain letters.
#' @param width `NULL`, or the number of bytes each element must decode to.
#' @return `id_encode()`: a character vector, `NA` where `bytes` is `NULL`.
#'   `id_decode()`: a list of raw vectors, with `NULL` where `text` is `NA`
#'   or not text of the form.
#' @examples
#' b <- as.raw(c(0xf8, 0x1d, 0x4f, 0xae))
#' id_encode(b, "base58")
#' id_decode("7R3N7TW", "base32")
#' x <- id_parse("f81d4fae-7dec-11d0-a765-00a0c91e6bf6", "uuid")
#' id_encode(id_bytes(x), "base62")
#' id_format(x, "proquint")
#' id_encode(id_bytes(x), "alphabet", alphabet = "0123456789")
#' @export
id_encode <- function(bytes, form, alphabet = NULL, sep = "-") {
  check_encoding_form(form)
  check_alphabet(alphabet, form)
  check_string(sep, "sep")
  if (grepl("[A-Za-z]", sep) || (form == "words" && !nzchar(sep))) {
    zuid_abort(
      "type",
      "`sep` must not contain letters, and `\"words\"` needs one."
    )
  }
  bytes <- bytes_list(bytes)
  if (form %in% c("proquint", "words")) {
    odd <- lengths(bytes) %% 2L == 1L
    if (any(odd)) {
      zuid_abort(
        "type",
        sprintf("Form `\"%s\"` needs an even number of bytes.", form)
      )
    }
  }
  if (any(lengths(bytes) > 65536L)) {
    zuid_abort("type", "Each element of `bytes` must be at most 65536 bytes.")
  }
  out <- .Call(zuid_c_encode, unname(bytes), form, alphabet, sep)
  names(out) <- names(bytes)
  out
}

#' @rdname id_encode
#' @export
id_decode <- function(text, form, alphabet = NULL, width = NULL) {
  check_character(text, "text")
  check_encoding_form(form)
  check_alphabet(alphabet, form)
  if (!is.null(width)) {
    if (
      !is.numeric(width) ||
        length(width) != 1L ||
        is.na(width) ||
        width < 0 ||
        width > 65536 ||
        width != trunc(width)
    ) {
      zuid_abort(
        "type",
        "`width` must be `NULL` or a whole number of bytes from 0 to 65536."
      )
    }
    width <- as.integer(width)
  }
  out <- .Call(zuid_c_decode, unname(text), form, alphabet, width)
  names(out) <- names(text)
  out
}

encoding_forms <- function() {
  c(
    "hex",
    "base32",
    "base32rfc",
    "base32hex",
    "base36",
    "base58",
    "base62",
    "base62sort",
    "base64url",
    "base64sort",
    "alphabet",
    "proquint",
    "words"
  )
}

check_encoding_form <- function(form, call = sys.call(-1L)) {
  check_string(form, "form", call = call)
  if (!form %in% encoding_forms()) {
    zuid_abort(
      "type",
      sprintf(
        "`form` must be one of %s, not \"%s\".",
        paste0("\"", encoding_forms(), "\"", collapse = ", "),
        form
      ),
      call = call
    )
  }
}

check_alphabet <- function(alphabet, form, call = sys.call(-1L)) {
  if (is.null(alphabet)) {
    return(invisible())
  }
  if (form != "alphabet") {
    zuid_abort(
      "type",
      "`alphabet` is only used by `form = \"alphabet\"`.",
      call = call
    )
  }
  check_string(alphabet, "alphabet", call = call)
  symbols <- strsplit(alphabet, "", fixed = TRUE)[[1L]]
  ok <- length(symbols) >= 2L &&
    length(symbols) <= 94L &&
    !anyDuplicated(symbols) &&
    all(grepl("^[!-~]$", symbols, useBytes = TRUE))
  if (!ok) {
    zuid_abort(
      "type",
      "`alphabet` must be 2 to 94 distinct printable ASCII characters, no space.",
      call = call
    )
  }
}

bytes_list <- function(bytes, call = sys.call(-1L)) {
  if (is.raw(bytes) && is.matrix(bytes)) {
    out <- lapply(seq_len(ncol(bytes)), function(j) bytes[, j])
    names(out) <- colnames(bytes)
    out[attr(bytes, "na", exact = TRUE)] <- list(NULL)
    return(out)
  }
  if (is.raw(bytes)) {
    return(list(as.vector(bytes)))
  }
  if (is.list(bytes)) {
    ok <- vapply(bytes, function(b) is.null(b) || is.raw(b), logical(1))
    if (all(ok)) {
      return(lapply(bytes, function(b) if (is.null(b)) b else as.vector(b)))
    }
  }
  zuid_abort(
    "type",
    "`bytes` must be a raw vector, a raw matrix or a list of raw vectors.",
    call = call
  )
}
