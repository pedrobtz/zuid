#' Read the fields of identifiers
#'
#' `id_fields()` reports what each identifier carries, one row per element.
#' `id_time()` returns its time field alone, and `id_version()` its version.
#'
#' For a UUID, the fields depend on the version and are read only when the
#' variant is RFC 9562's:
#'
#' * versions 1 and 6: the time in 100 ns ticks from 1582-10-15, the 14-bit
#'   clock sequence (`sequence`) and the 48-bit `node`;
#' * version 4: the 122 `random` bits;
#' * version 7: the millisecond time and the 74 `random` bits;
#' * versions 2, 3, 5 and 8: the version only.
#'
#' A ULID has its millisecond time and 80 `random` bits. A TypeID has its
#' UUID's fields and its `prefix`, `""` when it has none. A UPID has its time
#' in 256 ms units, 64 `random` bits, its `prefix` and its version nibble
#' (6, the reference's `"a"`, is the current one).
#'
#' A SCRU128 has its millisecond time, `counter_hi` in `node` (as hex),
#' `counter_lo` in `sequence` and its 32 entropy bits in `random`. A SCRU64
#' has its time at 256 ms, and its `node` and counter in `sequence` when it
#' was parsed with `id_layout("scru64", node_bits = )`. A KSUID has its time
#' in seconds and its 128-bit payload in `random`. An XID has its time in
#' seconds, its machine id in `node`, its `process` and its counter in
#' `sequence`; an ObjectId the same, but its middle five bytes are `random`,
#' as the current BSON specification makes them. A Snowflake has what its
#' layout says: the time at the layout's unit and epoch, the node fields in
#' `node` as `name=value` pairs, and the `sequence`.
#'
#' The nil and max UUIDs report versions 0 and 15 and no variant. `random`
#' is the random bits joined in order, as hex, left-padded with zero bits to
#' a whole number of hex digits.
#'
#' @param x A zuid vector from [id_parse()].
#' @param class For `id_time()`, `"POSIXct"` (the default), or `"ms"` for
#'   the whole number of milliseconds since 1970 as a double, the
#'   sub-millisecond part dropped. `POSIXct` is exact to the microsecond;
#'   the 100 ns ticks of UUID versions 1 and 6 are exact in neither.
#' @return `id_fields()`: a data frame with columns `format`, `time`,
#'   `time_unit`, `version`, `variant`, `node`, `process`, `sequence`,
#'   `random`, `prefix`, `codec`, `hash`, `digest` and `numbers`, `NA` where
#'   the format or the element has no such field. `id_time()`: a `POSIXct`
#'   in UTC or a double. `id_version()`: an integer vector.
#' @examples
#' x <- id_parse(c(
#'   "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3",
#'   "c232ab00-9414-11ec-b3c8-9f6bdeced846"
#' ), "uuid")
#' id_fields(x)
#' id_time(x)
#' id_version(x)
#' @export
id_fields <- function(x) {
  check_zuid(x)
  format <- zuid_format_of(x)
  cols <- field_columns(x)
  n <- length(x)
  na_chr <- rep(NA_character_, n)
  data.frame(
    format = rep(format, n),
    time = as_posixct(cols$time_s, cols$time_ns),
    time_unit = cols$time_unit,
    version = cols$version,
    variant = cols$variant,
    node = cols$node,
    process = cols$process,
    sequence = cols$sequence,
    random = cols$random,
    prefix = cols$prefix,
    codec = na_chr,
    hash = na_chr,
    digest = na_chr,
    numbers = I(vector("list", n)),
    stringsAsFactors = FALSE
  )
}

#' @rdname id_fields
#' @export
id_time <- function(x, class = c("POSIXct", "ms")) {
  check_zuid(x)
  class <- match.arg(class)
  cols <- field_columns(x)
  out <- switch(
    class,
    POSIXct = as_posixct(cols$time_s, cols$time_ns),
    ms = cols$time_s * 1000 + floor(cols$time_ns / 1e6)
  )
  names(out) <- names(x)
  out
}

#' @rdname id_fields
#' @export
id_version <- function(x) {
  check_zuid(x)
  out <- .Call(zuid_c_fields, as.character(x), zuid_format_of(x))$version
  names(out) <- names(x)
  out
}

# The C fields, completed from the layout for Snowflake and SCRU64.
field_columns <- function(x) {
  cols <- .Call(zuid_c_fields, as.character(x), zuid_format_of(x))
  layout <- attr(x, "layout", exact = TRUE)
  if (is.null(layout)) {
    return(cols)
  }
  ok <- !is.na(x)
  bytes <- .Call(zuid_c_bytes, as.character(x)[ok], zuid_format_of(x))
  parts <- layout_unpack(as.vector(bytes), layout)
  ms <- layout$epoch + parts$time * layout_units[[layout$unit]]
  cols$time_s[ok] <- floor(ms / 1000)
  cols$time_ns[ok] <- (ms - floor(ms / 1000) * 1000) * 1e6
  cols$time_unit[ok] <- layout$unit
  nodes <- names(layout$fields)
  cols$node[ok] <- do.call(
    paste,
    c(
      lapply(nodes, function(f) {
        paste0(f, "=", format(parts[[f]], scientific = FALSE, trim = TRUE))
      }),
      sep = ","
    )
  )
  cols$sequence[ok] <- as.integer(parts$sequence)
  cols
}

as_posixct <- function(seconds, nanoseconds) {
  .POSIXct(seconds + nanoseconds / 1e9, tz = "UTC")
}
