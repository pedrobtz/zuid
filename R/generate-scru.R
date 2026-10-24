#' Generate SCRU128, SCRU64 and KSUID values
#'
#' `id_scru128()` generates SCRU128 IDs by the specification's generator:
#' 48 bits of milliseconds, a 24-bit `counter_hi` renewed once a second, a
#' 24-bit `counter_lo` renewed each millisecond and incremented within it,
#' and 32 random bits. Values from one session strictly increase; a counter
#' overflow moves the timestamp forward instead of waiting.
#'
#' `id_scru64()` generates SCRU64 IDs for one node, as the reference
#' generator does: 256 ms ticks, then `node` in `node_bits` bits, then a
#' counter renewed at each tick and incremented within it. `node` and
#' `node_bits` are required, since only the caller can know that no other
#' generator uses the same node.
#'
#' `id_ksuid()` generates KSUIDs: seconds since 2014-05-13T16:53:20Z and
#' 128 random bits. KSUIDs are not monotonic within a second.
#'
#' A clock that runs back by up to the option `zuid.rollback_tolerance`
#' (seconds, 10 by default) keeps the last timestamp, as both SCRU
#' specifications recommend. Further back, `rollback = "error"` raises
#' `zuid_clock_error`, so that monotonicity is never silently lost, and
#' `rollback = "reset"` restarts the generator at the new time. A counter
#' overflow that would reach the reserved last timestamp is a
#' `zuid_overflow_error`.
#'
#' SCRU64 keeps one state per `node` and `node_bits`, so values for each
#' node increase however the calls for different nodes interleave. As in
#' [id_uuid()], a call given both `time` and `random` is a pure function of
#' its arguments.
#'
#' @inheritParams id_uuid
#' @param random `NULL` to draw from the operating system, or exactly the
#'   bytes needed: 10 per value for SCRU128 (4 of entropy, then the seeds of
#'   `counter_lo` and `counter_hi`), 3 per value for SCRU64 (the counter's
#'   seed) and 16 per value for KSUID.
#' @param node,node_bits The SCRU64 node id and its size in bits, 1 to 23;
#'   the counter gets the other `24 - node_bits` bits.
#' @param rollback What to do when the clock runs back further than the
#'   tolerance: `"error"` or `"reset"`.
#' @return A zuid vector of `n` values.
#' @examples
#' id_scru128(2)
#' id_scru64(2, node = 42, node_bits = 8)
#' id_ksuid(2)
#' @export
id_scru128 <- function(
  n = 1,
  random = NULL,
  time = NULL,
  rollback = c("error", "reset")
) {
  rollback <- match.arg(rollback)
  n <- check_count(n)
  check_random(random, 10 * n)
  # Timestamps 0 and 2^48 - 1 are reserved.
  time_us <- generation_time(time, n, c(1, 2^48 - 2) * 1e3, "SCRU128")
  out <- .Call(
    zuid_c_scru128,
    n,
    time_us,
    random,
    rollback_tolerance() * 1000,
    rollback == "reset"
  )
  generated(out, "scru128")
}

#' @rdname id_scru128
#' @export
id_scru64 <- function(
  n = 1,
  node,
  node_bits,
  random = NULL,
  time = NULL,
  rollback = c("error", "reset")
) {
  rollback <- match.arg(rollback)
  if (missing(node) || missing(node_bits)) {
    zuid_abort("type", "`node` and `node_bits` are required.")
  }
  if (!is_whole(node_bits) || node_bits < 1 || node_bits > 23) {
    zuid_abort("type", "`node_bits` must be a whole number from 1 to 23.")
  }
  if (!is_whole(node) || node < 0 || node >= 2^node_bits) {
    zuid_abort(
      "type",
      sprintf("`node` must be a whole number from 0 to %d.", 2^node_bits - 1)
    )
  }
  n <- check_count(n)
  check_random(random, 3 * n)
  # Ticks 0 and 282429536480 are reserved; ticks are milliseconds >> 8.
  range <- c(256, 282429536480 * 256 - 1) * 1e3
  time_us <- generation_time(time, n, range, "SCRU64")
  out <- .Call(
    zuid_c_scru64,
    n,
    time_us,
    random,
    as.numeric(node),
    as.integer(node_bits),
    rollback_tolerance() * 1000,
    rollback == "reset"
  )
  generated(out, "scru64")
}

#' @rdname id_scru128
#' @export
id_ksuid <- function(n = 1, random = NULL, time = NULL) {
  n <- check_count(n)
  check_random(random, 16 * n)
  range <- (1400000000 + c(0, 2^32 - 1)) * 1e6 + c(0, 999999)
  time_us <- generation_time(time, n, range, "KSUID")
  out <- .Call(zuid_c_ksuid, n, time_us, random)
  generated(out, "ksuid")
}

is_whole <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && x == trunc(x)
}

# The text a generator entry point returned, or the condition it signalled:
# NULL for an entropy failure, a positive integer for the position of a
# clock rollback, a negative one for a timestamp past the format's range.
generated <- function(out, format, call = sys.call(-1L)) {
  if (is.null(out)) {
    zuid_abort(
      "entropy",
      "The operating system's entropy source failed.",
      call = call
    )
  }
  if (is.integer(out) && out > 0L) {
    zuid_abort(
      "clock",
      sprintf(
        paste(
          "The clock ran back by more than `zuid.rollback_tolerance` at value",
          "%d; use `rollback = \"reset\"` to restart the generator."
        ),
        out
      ),
      call = call
    )
  }
  if (is.integer(out)) {
    zuid_abort(
      "overflow",
      sprintf("Value %d is past the largest %s timestamp.", -out, format),
      call = call
    )
  }
  new_zuid(out, format)
}

#' Generate XIDs, ObjectIds and Snowflakes
#'
#' `id_xid()` generates XIDs: seconds since 1970, a 3-byte machine id, a
#' 2-byte process id and a 3-byte counter. The reference derives the machine
#' id from the host name through MD5; zuid draws three random bytes once per
#' session instead, and `machine` takes the reference's bytes when they
#' matter. The process id is R's, masked to 16 bits. The counter starts at a
#' random value once per session and increments, wrapping at 2^24.
#'
#' `id_objectid()` generates BSON ObjectIds: seconds, a 5-byte random value
#' drawn once per session, and a 3-byte counter started at a random value.
#'
#' `id_snowflake()` generates Snowflakes under a layout. `worker` sets every
#' node field, since duplicate node ids across machines are what Snowflake
#' exists to prevent and only the caller can rule them out. The sequence
#' starts at zero each tick and increments within it; when it overflows,
#' generation moves to the next tick. One sequence serves every node value
#' of a layout, so values for different workers interleave without repeats.
#' A clock back by up to the option `zuid.clock_tolerance` (seconds, 0.01 by
#' default) keeps the last tick. Further back, `rollback = "error"` raises
#' `zuid_clock_error`, and `rollback = "reset"` restarts the layout's
#' generator at the new time, which may repeat values made before.
#'
#' @inheritParams id_uuid
#' @param machine For `id_xid()`, three raw bytes, or `NULL` for the
#'   session's random ones.
#' @param process For `id_xid()`, the process id, `Sys.getpid()` by default.
#' @param random `NULL`, or for reproducible values: 6 bytes for `id_xid()`
#'   (machine, then the counter's start) and 8 for `id_objectid()` (the
#'   random value, then the counter's start), used for this call only.
#' @param layout An [id_layout()].
#' @param worker The node fields' values: one number when the layout has one
#'   node field, else a named list, such as `list(datacenter = 1, worker = 7)`.
#' @param time `NULL` for the current time, or a `POSIXct` (or a double of
#'   milliseconds since 1970) of length 1 or `n`.
#' @param rollback For `id_snowflake()`, what to do when the clock (or
#'   `time`) runs back further than the tolerance: `"error"` or `"reset"`.
#' @return A zuid vector of `n` values.
#' @examples
#' id_xid(2)
#' id_objectid(2)
#' id_snowflake(2, id_layout("twitter"), list(datacenter = 1, worker = 7))
#' @export
id_xid <- function(
  n = 1,
  machine = NULL,
  process = Sys.getpid(),
  random = NULL,
  time = NULL
) {
  n <- check_count(n)
  if (!is.null(machine) && (!is.raw(machine) || length(machine) != 3L)) {
    zuid_abort("type", "`machine` must be 3 raw bytes.")
  }
  if (!is_whole(process) || process < 0) {
    zuid_abort("type", "`process` must be a non-negative whole number.")
  }
  check_random(random, 6)
  secs <- generation_seconds(time, n, "XID")
  out <- .Call(zuid_c_xid, secs, machine, as.integer(process %% 65536), random)
  generated(out, "xid")
}

#' @rdname id_xid
#' @export
id_objectid <- function(n = 1, random = NULL, time = NULL) {
  n <- check_count(n)
  check_random(random, 8)
  secs <- generation_seconds(time, n, "ObjectId")
  generated(.Call(zuid_c_objectid, secs, random), "objectid")
}

#' @rdname id_xid
#' @export
id_snowflake <- function(
  n = 1,
  layout,
  worker,
  time = NULL,
  rollback = c("error", "reset")
) {
  rollback <- match.arg(rollback)
  if (missing(layout) || missing(worker)) {
    zuid_abort("type", "`layout` and `worker` are required.")
  }
  if (!is_layout(layout)) {
    zuid_abort("layout", "`layout` must come from `id_layout()`.")
  }
  n <- check_count(n)
  nodes <- names(layout$fields)
  if (!is.list(worker)) {
    if (length(nodes) != 1L) {
      zuid_abort(
        "type",
        sprintf(
          "This layout has %d node fields; give `worker` as a named list of %s.",
          length(nodes),
          paste(nodes, collapse = ", ")
        )
      )
    }
    worker <- stats::setNames(list(worker), nodes)
  }
  if (!setequal(names(worker), nodes) || anyDuplicated(names(worker))) {
    zuid_abort(
      "type",
      sprintf(
        "`worker` must name each node field: %s.",
        paste(nodes, collapse = ", ")
      )
    )
  }
  for (f in nodes) {
    v <- worker[[f]]
    if (!is_whole(v) || v < 0 || v >= 2^layout$fields[[f]]) {
      zuid_abort(
        "type",
        sprintf(
          "`%s` must be a whole number from 0 to %.0f.",
          f,
          2^layout$fields[[f]] - 1
        )
      )
    }
  }
  unit <- layout_units[[layout$unit]]
  ms <- if (is.null(time)) {
    rep(as.numeric(Sys.time()) * 1000, n)
  } else {
    generation_time(time, n, c(-Inf, Inf), "Snowflake") / 1000
  }
  ticks <- floor((ms - layout$epoch) / unit)
  if (any(ticks < 0) || any(ticks >= 2^layout$time_bits)) {
    zuid_abort("type", "`time` is outside what this layout can hold.")
  }
  p <- layout_parts(layout)
  node <- vapply(
    layout$order,
    function(part) if (part %in% nodes) as.numeric(worker[[part]]) else 0,
    numeric(1)
  )
  tolerance <- clock_tolerance() * 1000 / unit
  out <- .Call(
    zuid_c_snowflake,
    ticks,
    unname(p$widths),
    p$kinds,
    unname(node),
    layout$epoch,
    unit,
    tolerance,
    rollback == "reset"
  )
  if (is.integer(out) && out > 0L) {
    zuid_abort(
      "clock",
      sprintf(
        paste(
          "The clock ran back by more than `zuid.clock_tolerance` at value",
          "%d; use `rollback = \"reset\"` to restart the generator."
        ),
        out
      )
    )
  }
  if (is.integer(out)) {
    zuid_abort(
      "overflow",
      sprintf("Value %d is past the layout's time range.", -out)
    )
  }
  new_zuid(out, "snowflake", layout)
}

# Whole seconds since 1970 per value, for the 32-bit second formats.
generation_seconds <- function(time, n, what, call = sys.call(-1L)) {
  us <- generation_time(time, n, c(0, (2^32 - 1) * 1e6 + 999999), what, call)
  if (is.null(us)) {
    us <- rep(as.numeric(Sys.time()) * 1e6, n)
  }
  floor(us / 1e6)
}

# Seconds. The option may be a number of seconds or a difftime.
clock_tolerance <- function() {
  tol <- getOption("zuid.clock_tolerance", 0.01)
  if (inherits(tol, "difftime")) {
    tol <- as.numeric(tol, units = "secs")
  }
  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol < 0) {
    zuid_abort(
      "type",
      "The option `zuid.clock_tolerance` must be a non-negative number of seconds."
    )
  }
  tol
}
