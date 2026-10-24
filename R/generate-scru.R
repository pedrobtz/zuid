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
#' `rollback = "reset"` restarts the generator at the new time.
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
