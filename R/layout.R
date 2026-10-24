#' Snowflake and SCRU64 layouts
#'
#' A layout says how a 64-bit identifier splits into a time, node fields and
#' a sequence. It is data: the time field's bits, unit and epoch, the node
#' fields with their widths in order, the sequence width, and whether the top
#' bit is a sign bit. zuid cannot discover a Snowflake's layout from the
#' number, so its fields are readable only when the layout is given.
#'
#' The built-in layouts:
#'
#' | Name | Time | Node fields | Sequence |
#' | --- | --- | --- | --- |
#' | `twitter` | 41 bits, ms, from 2010-11-04T01:42:54.657Z | `datacenter` 5, `worker` 5 | 12 |
#' | `discord` | 42 bits, ms, from 2015-01-01 | `worker` 5, `process` 5 | 12 |
#' | `instagram` | 41 bits, ms, from 2011-08-24T21:07:01.721Z | `shard` 13 | 10 |
#' | `sonyflake` | 39 bits, 10 ms, from `epoch` | `machine` 16, after the sequence | 8 |
#' | `scru64` | 39 bits, 256 ms, from 1970 | `node` of `node_bits` | 24 − `node_bits` |
#'
#' Twitter, Sonyflake and SCRU64 keep the top bit as a sign bit; Discord and
#' Instagram use all 64 bits. Sonyflake's reference has changed its default
#' start time between releases, so `epoch` is required for it.
#'
#' A custom layout gives `time`, `fields`, `sequence` and `sign_bit`. The
#' bits must add up to 64, or 63 with the sign bit, and each part must have
#' fewer than 54 bits, so that it reads exactly as a double.
#'
#' @param name A built-in layout, or `NULL` for a custom one.
#' @param epoch For `"sonyflake"` (required) or a custom layout, the time
#'   the time field counts from: a `POSIXct` or milliseconds since 1970.
#' @param node_bits For `"scru64"`, the node id's bits, 1 to 23.
#' @param time For a custom layout, `list(bits =, unit =, epoch =)`, `unit`
#'   one of `"ms"`, `"10ms"`, `"256ms"` and `"s"`.
#' @param fields For a custom layout, the node fields as a named list or
#'   vector of widths, most significant first.
#' @param sequence For a custom layout, the sequence's bits.
#' @param sign_bit For a custom layout, whether the top bit is reserved.
#' @param x A layout.
#' @param ... Unused.
#' @return A `zuid_layout`.
#' @examples
#' id_layout("twitter")
#' id_layout("scru64", node_bits = 8)
#' id_layout(
#'   time = list(bits = 41, unit = "ms", epoch = 0),
#'   fields = list(worker = 10),
#'   sequence = 12
#' )
#' @export
id_layout <- function(
  name = NULL,
  epoch = NULL,
  node_bits = NULL,
  time = NULL,
  fields = NULL,
  sequence = NULL,
  sign_bit = TRUE
) {
  if (!is.null(name)) {
    check_string(name, "name")
    if (!is.null(time) || !is.null(fields) || !is.null(sequence)) {
      zuid_abort(
        "layout",
        "A built-in layout takes `epoch` or `node_bits`, not parts."
      )
    }
    return(builtin_layout(name, epoch, node_bits))
  }
  if (!is.list(time) || is.null(time$bits) || is.null(time$unit)) {
    zuid_abort(
      "layout",
      "A custom layout needs `time = list(bits =, unit =, epoch =)`."
    )
  }
  new_layout(
    "custom",
    time_bits = time$bits,
    unit = time$unit,
    epoch = if (is.null(time$epoch)) epoch else time$epoch,
    fields = fields,
    sequence = sequence,
    sign_bit = sign_bit
  )
}

builtin_layout <- function(name, epoch, node_bits, call = sys.call(-1L)) {
  if (name != "sonyflake" && !is.null(epoch)) {
    zuid_abort("layout", sprintf("The `%s` layout has its own epoch.", name))
  }
  if (name != "scru64" && !is.null(node_bits)) {
    zuid_abort("layout", "Only the `scru64` layout takes `node_bits`.")
  }
  switch(
    name,
    twitter = new_layout(
      name,
      41,
      "ms",
      1288834974657,
      list(datacenter = 5, worker = 5),
      12,
      TRUE
    ),
    discord = new_layout(
      name,
      42,
      "ms",
      1420070400000,
      list(worker = 5, process = 5),
      12,
      FALSE
    ),
    instagram = new_layout(
      name,
      41,
      "ms",
      1314220021721,
      list(shard = 13),
      10,
      FALSE
    ),
    sonyflake = {
      if (is.null(epoch)) {
        zuid_abort(
          "layout",
          paste(
            "The `sonyflake` layout needs `epoch`: the reference's default",
            "start time has changed between releases."
          )
        )
      }
      new_layout(
        name,
        39,
        "10ms",
        epoch,
        list(machine = 16),
        8,
        TRUE,
        order = c("time", "sequence", "machine")
      )
    },
    scru64 = {
      if (!is_whole(node_bits) || node_bits < 1 || node_bits > 23) {
        zuid_abort(
          "layout",
          "The `scru64` layout needs `node_bits`, a whole number from 1 to 23."
        )
      }
      new_layout(
        name,
        39,
        "256ms",
        0,
        list(node = node_bits),
        24 - node_bits,
        TRUE
      )
    },
    zuid_abort(
      "layout",
      sprintf(
        "`name` must be one of %s, not \"%s\".",
        "\"twitter\", \"discord\", \"instagram\", \"sonyflake\", \"scru64\"",
        name
      )
    )
  )
}

layout_units <- c(ms = 1, "10ms" = 10, "256ms" = 256, s = 1000)

new_layout <- function(
  name,
  time_bits,
  unit,
  epoch,
  fields,
  sequence,
  sign_bit,
  order = NULL,
  call = sys.call(-1L)
) {
  bad <- function(message) zuid_abort("layout", message, call = call)
  if (!is_whole(time_bits) || time_bits < 1 || time_bits > 53) {
    bad("The time field must have 1 to 53 bits.")
  }
  if (
    !is.character(unit) || length(unit) != 1L || !unit %in% names(layout_units)
  ) {
    bad("The time unit must be one of \"ms\", \"10ms\", \"256ms\" and \"s\".")
  }
  epoch <- epoch_ms(epoch, call)
  fields <- unlist(fields)
  if (
    !is.numeric(fields) ||
      !length(fields) ||
      is.null(names(fields)) ||
      any(!nzchar(names(fields))) ||
      anyDuplicated(names(fields)) ||
      any(names(fields) %in% c("time", "sequence"))
  ) {
    bad(
      "`fields` must be named widths, with names other than time and sequence."
    )
  }
  widths <- c(time = time_bits, fields, sequence = sequence)
  if (
    !is.numeric(sequence) ||
      length(sequence) != 1L ||
      any(is.na(widths)) ||
      any(widths != trunc(widths)) ||
      any(widths < 1) ||
      any(widths > 53)
  ) {
    bad("Every field must have a whole number of bits from 1 to 53.")
  }
  if (!isTRUE(sign_bit) && !isFALSE(sign_bit)) {
    bad("`sign_bit` must be `TRUE` or `FALSE`.")
  }
  total <- sum(widths)
  if (total != if (sign_bit) 63 else 64) {
    bad(
      sprintf(
        "The fields add up to %d bits; a layout needs %d.",
        total,
        if (sign_bit) 63L else 64L
      )
    )
  }
  if (is.null(order)) {
    order <- c("time", names(fields), "sequence")
  }
  if (length(widths) > 8L) {
    bad("A layout has at most six node fields.")
  }
  structure(
    list(
      name = name,
      time_bits = as.integer(time_bits),
      unit = unit,
      epoch = epoch,
      fields = stats::setNames(as.integer(fields), names(fields)),
      sequence = as.integer(sequence),
      sign_bit = sign_bit,
      order = order
    ),
    class = "zuid_layout"
  )
}

epoch_ms <- function(epoch, call) {
  if (inherits(epoch, "POSIXct")) {
    epoch <- as.numeric(epoch) * 1000
  }
  if (!is.numeric(epoch) || length(epoch) != 1L || !is.finite(epoch)) {
    zuid_abort(
      "layout",
      "`epoch` must be a POSIXct or a number of milliseconds since 1970.",
      call = call
    )
  }
  as.numeric(epoch)
}

is_layout <- function(x) inherits(x, "zuid_layout")

# The parts most significant first, as the C side takes them.
layout_parts <- function(layout) {
  widths <- c(
    time = layout$time_bits,
    layout$fields,
    sequence = layout$sequence
  )[layout$order]
  kinds <- ifelse(
    layout$order == "time",
    0L,
    ifelse(layout$order == "sequence", 2L, 1L)
  )
  list(
    widths = stats::setNames(as.integer(widths), layout$order),
    kinds = as.integer(kinds)
  )
}

check_layout <- function(layout, format, call = sys.call(-1L)) {
  needs <- format %in% c("snowflake", "scru64")
  if (is.null(layout)) {
    if (format == "snowflake") {
      zuid_abort(
        "layout",
        "A Snowflake needs a `layout`; see `id_layout()`.",
        call = call
      )
    }
    return(invisible())
  }
  if (!needs) {
    zuid_abort(
      "type",
      sprintf("`%s` takes no `layout`.", format),
      call = call
    )
  }
  if (!is_layout(layout)) {
    zuid_abort("layout", "`layout` must come from `id_layout()`.", call = call)
  }
  if (format == "scru64" && layout$name != "scru64") {
    zuid_abort(
      "layout",
      "A SCRU64 layout is `id_layout(\"scru64\", node_bits = )`.",
      call = call
    )
  }
}

#' @rdname id_layout
#' @export
print.zuid_layout <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

#' @rdname id_layout
#' @export
format.zuid_layout <- function(x, ...) {
  epoch <- format(
    .POSIXct(x$epoch / 1000, tz = "UTC"),
    "%Y-%m-%dT%H:%M:%OS3Z"
  )
  parts <- layout_parts(x)$widths
  cells <- paste0(names(parts), " ", parts)
  if (x$sign_bit) {
    cells <- c("sign 1", cells)
  }
  c(
    sprintf("<zuid_layout %s>", x$name),
    paste0("| ", paste(cells, collapse = " | "), " |"),
    sprintf("time: %s units from %s", x$unit, epoch)
  )
}

# Each part of 8-byte values, as doubles, named by the layout's order.
layout_unpack <- function(bytes, layout) {
  p <- layout_parts(layout)
  out <- .Call(zuid_c_layout_unpack, bytes, unname(p$widths), p$kinds)
  names(out) <- layout$order
  out
}

layout_time_ms <- function(bytes, layout) {
  layout$epoch + layout_unpack(bytes, layout)$time * layout_units[[layout$unit]]
}
