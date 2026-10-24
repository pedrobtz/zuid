#' Generate NanoIDs and Sqids
#'
#' `id_nanoid()` generates NanoIDs: `size` symbols drawn uniformly from
#' `alphabet`, by NanoID 6's `customRandom()`. Random bytes come in batches,
#' each read from its last byte, and a byte at or above the largest multiple
#' of the alphabet's size below 256 is rejected, so every symbol is equally
#' likely. When rejection uses up a batch, another is drawn.
#'
#' `id_sqids()` encodes non-negative whole numbers as Sqids, by the
#' specification's algorithm: the default alphabet and blocklist unless
#' given, and padded to `min_length`. A numeric vector gives one Sqid per
#' number; a list gives one per element, encoding all its numbers. An ID
#' that contains a blocklisted word is re-encoded with the next offset; when
#' every offset is blocked, the result is a `zuid_encode_error`.
#'
#' @param n The number of NanoIDs.
#' @param size Symbols per NanoID, 21 by default.
#' @param alphabet The symbols, or `NULL` for the format's default:
#'   `A-Za-z0-9_-` for NanoID and `a-zA-Z0-9` for Sqids. 1 to 256 printable
#'   ASCII characters for NanoID, 3 to 255 for Sqids, all distinct.
#' @param random For `id_nanoid()`, `NULL` to draw from the operating system,
#'   or a raw vector read batch by batch, for reproducible values; running
#'   out is a `zuid_type_error`.
#' @param numbers A numeric vector, or a list of numeric vectors, of whole
#'   numbers from 0 to 2^53 - 1. `NA` or `NULL` gives `NA`.
#' @param min_length The shortest Sqid, 0 to 255.
#' @param blocklist `NULL` for the default blocklist, or a character vector
#'   of words to avoid (`character()` for none).
#' @return A zuid vector.
#' @examples
#' id_nanoid(2)
#' id_nanoid(2, size = 10, alphabet = "0123456789abcdef")
#' id_sqids(c(1, 2, 3))
#' id_sqids(list(c(1, 2, 3)), min_length = 10)
#' @export
id_nanoid <- function(n = 1, size = 21, alphabet = NULL, random = NULL) {
  n <- check_count(n)
  if (!is_whole(size) || size < 0 || size > 65536) {
    zuid_abort("type", "`size` must be a whole number from 0 to 65536.")
  }
  if (is.null(alphabet)) {
    alphabet <- nanoid_alphabet
  }
  check_text_alphabet(alphabet, "nanoid")
  if (!is.null(random) && !is.raw(random)) {
    zuid_abort("type", "`random` must be `NULL` or a raw vector.")
  }
  out <- .Call(zuid_c_nanoid, n, as.numeric(size), alphabet, random)
  if (is.integer(out)) {
    zuid_abort(
      "type",
      sprintf("`random` ran out of bytes at value %d.", out)
    )
  }
  if (is.null(out)) {
    zuid_abort("entropy", "The operating system's entropy source failed.")
  }
  new_zuid(
    out,
    "nanoid",
    params = check_params(list(alphabet = alphabet), "nanoid")
  )
}

#' @rdname id_nanoid
#' @export
id_sqids <- function(
  numbers,
  alphabet = NULL,
  min_length = 0,
  blocklist = NULL
) {
  if (is.list(numbers)) {
    elements <- lapply(numbers, check_sqids_numbers)
  } else if (is.numeric(numbers) || all(is.na(numbers))) {
    # One Sqid per number: checked as one vector, then split.
    v <- as.numeric(numbers)
    check_sqids_numbers(v[!is.na(v)])
    elements <- as.list(v)
    elements[is.na(v)] <- list(NULL)
  } else {
    zuid_abort(
      "type",
      "`numbers` must be numeric or a list of numeric vectors."
    )
  }
  if (is.null(alphabet)) {
    alphabet <- sqids_alphabet
  }
  check_text_alphabet(alphabet, "sqids")
  if (!is.null(blocklist)) {
    check_character(blocklist, "blocklist")
    # The reference lowercases its words, and the C side expects it.
    blocklist <- tolower(blocklist[!is.na(blocklist)])
  }
  params <- check_params(
    list(alphabet = alphabet, min_length = min_length, blocklist = blocklist),
    "sqids"
  )
  out <- .Call(
    zuid_c_sqids_encode,
    unname(elements),
    alphabet,
    as.integer(min_length),
    blocklist
  )
  if (is.integer(out)) {
    zuid_abort(
      "encode",
      sprintf(
        "Element %d has no encoding the blocklist allows in this alphabet.",
        out
      )
    )
  }
  names(out) <- names(numbers)
  new_zuid(out, "sqids", params = params)
}

check_sqids_numbers <- function(v, call = sys.call(-1L)) {
  if (is.null(v) || anyNA(v)) {
    return(NULL)
  }
  if (!is.numeric(v) || any(v < 0) || any(v != trunc(v))) {
    zuid_abort("type", "Sqids encode non-negative whole numbers.", call = call)
  }
  if (any(v > 2^53 - 1)) {
    zuid_abort(
      "encode",
      "Sqids numbers above 2^53 - 1 need 64-bit integers, which zuid does not use yet.",
      call = call
    )
  }
  as.numeric(v)
}
