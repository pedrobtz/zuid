#' Convert identifiers between formats
#'
#' `id_convert()` moves values between formats that hold the same bits:
#' `"uuid"`, `"ulid"`, `"typeid"` and `"upid"` (128 bits), and `"xid"` and
#' `"objectid"` (96 bits, laid out alike). The bytes are kept and the text is
#' rewritten.
#'
#' * A UUID becomes a TypeID under `prefix`, and a TypeID becomes a UUID by
#'   dropping it.
#' * A UPID becomes a UUID as the reference converts it, keeping the bits.
#' * A ULID and a UUID convert by reinterpreting the bits. [id_fields()] then
#'   reports what the bits say: most ULIDs read as UUIDs of the `"future"`
#'   variant, and a UUID read as a ULID has its first 48 bits as a time, which
#'   is meaningful for version 7 only.
#'
#' Any other pair is a `zuid_convert_error`: the target would need a value
#' the source does not have. To change a UUID's text form, use
#' [id_format()].
#'
#' @param x A zuid vector.
#' @param to The format to convert to.
#' @param prefix For `to = "typeid"`, the prefix of every value, `""` for
#'   none. `NULL` keeps the prefixes of a TypeID and means `""` otherwise.
#' @return A zuid vector of format `to`.
#' @examples
#' x <- id_parse("01890a5d-ac96-774b-bcce-b302099a8057", "uuid")
#' t <- id_convert(x, "typeid", prefix = "user")
#' t
#' id_convert(t, "uuid")
#' id_convert(x, "ulid")
#' @export
id_convert <- function(x, to, prefix = NULL) {
  check_zuid(x)
  check_format(to)
  from <- zuid_format_of(x)
  same_bits <- if (from %in% c("xid", "objectid")) {
    c("xid", "objectid")
  } else {
    c("uuid", "ulid", "typeid", "upid")
  }
  if (!from %in% same_bits || !to %in% same_bits) {
    zuid_abort(
      "convert",
      sprintf(
        "Can't convert `%s` to `%s`: they do not hold the same value.",
        from,
        to
      )
    )
  }
  if (!is.null(prefix)) {
    if (to != "typeid") {
      zuid_abort("type", "`prefix` is only used with `to = \"typeid\"`.")
    }
    check_typeid_prefix(prefix)
  }
  if (from == to && is.null(prefix)) {
    return(x)
  }
  bytes <- id_bytes(x)
  if (to == "typeid") {
    suffix <- tolower(id_encode(bytes, "base32"))
    prefix <- if (is.null(prefix)) "" else prefix
    text <- if (nzchar(prefix)) paste0(prefix, "_", suffix) else suffix
    text[is.na(suffix)] <- NA_character_
    out <- new_zuid(text, "typeid")
  } else {
    out <- id_from_bytes(bytes, to)
  }
  names(out) <- names(x)
  out
}
