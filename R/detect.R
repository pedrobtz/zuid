#' Detect the format of identifiers
#'
#' `id_detect()` names the format of each element, or gives `NA` when the
#' evidence does not settle it. Detection never guesses:
#'
#' * Without a `hint`, only structured formats are tried, since an encoding
#'   or a syntactic format (NanoID, Cuid2, Sqids) matches any string over its
#'   alphabet. A UUID written in Crockford base32 is textually a ULID, and
#'   the ULID is what is detected; `id_parse(x, "uuid", form = "base32")` is
#'   how to say otherwise.
#' * When exactly one format passes at the `"structure"` level, it is the
#'   answer. When several pass, the answer is `NA`, and the `candidates`
#'   attribute lists them. A 26-character lowercase Crockford string, for
#'   one, is a ULID or a TypeID without a prefix.
#' * A Snowflake is considered only under a Snowflake `layout`, since every
#'   layout reads the digits differently. A SCRU64 is listed among the
#'   candidates, but chosen only under `id_layout("scru64", node_bits = )`.
#' * `hint` restricts the formats tried to those named, and is how a
#'   syntactic format or an encoding can be detected at all.
#'
#' Formats are recognised in their canonical text, with their default
#' alphabets.
#'
#' @param x A character vector.
#' @param hint `NULL`, or the formats to try.
#' @param layout An [id_layout()] for Snowflake or SCRU64.
#' @return A character vector of formats, `NA` where none or several fit,
#'   with the attribute `candidates`: a list of the formats each element
#'   passes, structured formats first.
#' @examples
#' id_detect(c(
#'   "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3",
#'   "01ARZ3NDEKTSV4RRFFQ69G5FAV",
#'   "01arz3ndektsv4rrffq69g5fav",
#'   "not an id"
#' ))
#' id_detect("01arz3ndektsv4rrffq69g5fav", hint = "typeid")
#' id_detect("175928847299117063", layout = id_layout("discord"))
#' @export
id_detect <- function(x, hint = NULL, layout = NULL) {
  if (is_zuid(x)) {
    x <- as.character(x)
  }
  check_character(x)
  pool <- detection_pool(hint, layout)
  if (!length(x)) {
    return(structure(character(), candidates = list()))
  }
  passes <- vapply(
    pool,
    function(f) {
      lay <- if (
        f %in%
          c("snowflake", "scru64") &&
          !is.null(layout) &&
          (f == "scru64") == (layout$name == "scru64")
      ) {
        layout
      } else {
        NULL
      }
      ok <- id_valid(x, f, layout = lay)
      ok & !is.na(ok)
    },
    logical(length(x))
  )
  if (!is.matrix(passes)) {
    passes <- matrix(passes, nrow = length(x), dimnames = list(NULL, pool))
  }
  # SCRU64 is chosen only under a SCRU64 layout.
  choosable <- pool != "scru64" | (!is.null(layout) && layout$name == "scru64")
  # Over the pass matrix at once: the candidates in pool order, and the
  # answer where exactly one choosable format passes.
  hit <- which(passes, arr.ind = TRUE)
  hit <- hit[order(hit[, "row"], hit[, "col"]), , drop = FALSE]
  candidates <- unname(split(
    pool[hit[, "col"]],
    factor(hit[, "row"], levels = seq_along(x))
  ))
  single <- rowSums(passes) == 1L
  first <- max.col(passes, ties.method = "first")
  out <- ifelse(single & choosable[first], pool[first], NA_character_)
  names(out) <- names(x)
  attr(out, "candidates") <- candidates
  out
}

# The formats to try, structured first in the order of section 6.1.
detection_pool <- function(hint, layout, call = sys.call(-1L)) {
  structured <- c(
    "uuid",
    "ulid",
    "typeid",
    "upid",
    "scru128",
    "scru64",
    "ksuid",
    "xid",
    "objectid",
    "snowflake",
    "cid"
  )
  if (!is.null(layout) && !is_layout(layout)) {
    zuid_abort("layout", "`layout` must come from `id_layout()`.", call = call)
  }
  if (is.null(hint)) {
    pool <- structured
  } else {
    if (!is.character(hint) || !length(hint) || anyNA(hint)) {
      zuid_abort(
        "type",
        "`hint` must be `NULL` or a character vector of formats.",
        call = call
      )
    }
    for (f in hint) {
      check_format(f, call = call)
    }
    pool <- c(intersect(structured, hint), setdiff(unique(hint), structured))
  }
  snowflake_layout <- !is.null(layout) && layout$name != "scru64"
  if (!snowflake_layout) {
    pool <- setdiff(pool, "snowflake")
  }
  pool
}

# The one format every element of `x` resolves to, for id_parse().
detect_one_format <- function(x, layout, call = sys.call(-1L)) {
  found <- id_detect(x, layout = layout)
  candidates <- attr(found, "candidates")
  ambiguous <- which(is.na(found) & lengths(candidates) > 0L)
  if (length(ambiguous)) {
    i <- ambiguous[[1L]]
    zuid_abort(
      "ambiguous",
      sprintf(
        "Element %d of `x` could be %s; give `format`.",
        i,
        paste0("`", candidates[[i]], "`", collapse = " or ")
      ),
      positions = ambiguous,
      candidates = candidates[ambiguous],
      call = call
    )
  }
  formats <- unique(found[!is.na(found)])
  if (length(formats) > 1L) {
    zuid_abort(
      "mixed",
      sprintf(
        "`x` holds more than one format: %s.",
        paste0("`", formats, "`", collapse = ", ")
      ),
      formats = formats,
      call = call
    )
  }
  if (!length(formats)) {
    zuid_abort(
      "parse",
      "No element of `x` is an identifier zuid can detect; give `format`.",
      positions = which(!is.na(x)),
      call = call
    )
  }
  formats
}
