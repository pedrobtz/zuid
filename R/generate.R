#' Generate UUIDs
#'
#' Generates `n` UUIDs of a version, version 7 by default, from the
#' operating system's entropy source and clock. R's random number generator
#' is never used, so `set.seed()` does not change the result.
#'
#' * **Version 7** (the default): 48 bits of milliseconds, a 12-bit counter
#'   and 62 random bits. Values from one session strictly increase (RFC 9562
#'   section 6.2, method 1): within a millisecond the counter increments, and
#'   when it would overflow the millisecond advances by one.
#' * **Version 4**: 122 random bits.
#' * **Versions 1 and 6**: the time in 100 ns ticks, a 14-bit clock sequence
#'   and a 48-bit node. The clock sequence and node are random, drawn once
#'   per session, and the node has its multicast bit set so it is never
#'   mistaken for a hardware address (RFC 9562 section 6.10). Values from one
#'   session strictly increase in time.
#' * **Version 8**: the caller's 122 bits, through `random`.
#'
#' A clock that runs back by up to the option `zuid.rollback_tolerance`
#' (seconds, 10 by default) keeps generation increasing from the last value.
#' Further back, version 7 restarts at the new time and versions 1 and 6
#' increment the clock sequence.
#'
#' Versions 3 and 5 hash a name and are not generated yet; parsing them
#' works. Version 2 is not generated: RFC 9562 leaves it to DCE Security.
#'
#' @param n The number of UUIDs.
#' @param version 1, 4, 6, 7 or 8.
#' @param namespace,name Reserved for the name-based versions 3 and 5.
#' @param node For versions 1 and 6, six raw bytes to use as the node instead
#'   of the session's random one.
#' @param random `NULL` to draw from the operating system, or exactly the
#'   bytes the version needs, for tests and reproducible fixtures: 16 per
#'   value for versions 4 and 8; 10 per value for version 7 (2 seed the
#'   counter at a new millisecond, 8 fill the 62 random bits); for versions
#'   1 and 6, 2 bytes of clock sequence and, without `node`, 6 bytes of node.
#' @param time `NULL` for the current time, or a `POSIXct` (or a double of
#'   milliseconds since 1970) of length 1 or `n`.
#' @return A zuid vector of `n` UUIDs.
#' @examples
#' id_uuid(3)
#' id_uuid(2, version = 4)
#' id_uuid(version = 7, time = as.POSIXct("2022-02-22 19:22:22", tz = "UTC"))
#' @export
id_uuid <- function(
  n = 1,
  version = 7,
  namespace = NULL,
  name = NULL,
  node = NULL,
  random = NULL,
  time = NULL
) {
  n <- check_count(n)
  version <- check_uuid_version(version)
  if (version %in% c(3L, 5L)) {
    zuid_abort(
      "dependency",
      sprintf(
        "Version %d UUIDs hash a name with zucrypt, which zuid does not use yet.",
        version
      )
    )
  }
  if (version == 8L && is.null(random)) {
    zuid_abort("type", "Version 8 needs its 122 custom bits in `random`.")
  }
  if (!is.null(node)) {
    if (!version %in% c(1L, 6L)) {
      zuid_abort("type", "`node` is only used by versions 1 and 6.")
    }
    if (!is.raw(node) || length(node) != 6L) {
      zuid_abort("type", "`node` must be 6 raw bytes.")
    }
  }
  if (!is.null(random)) {
    need <- switch(
      as.character(version),
      "4" = ,
      "8" = 16 * n,
      "7" = 10 * n,
      "1" = ,
      "6" = if (is.null(node)) 8 else 2
    )
    if (!is.raw(random) || length(random) != need) {
      zuid_abort(
        "type",
        sprintf(
          "`random` must be %s raw bytes for version %d.",
          format(need),
          version
        )
      )
    }
  }
  time_us <- generation_time(time, n, version)

  out <- .Call(
    zuid_c_uuid,
    n,
    version,
    time_us,
    random,
    node,
    rollback_tolerance() * 1000
  )
  if (is.null(out)) {
    zuid_abort("entropy", "The operating system's entropy source failed.")
  }
  new_zuid(out, "uuid")
}

check_count <- function(n, call = sys.call(-1L)) {
  if (
    !is.numeric(n) ||
      length(n) != 1L ||
      is.na(n) ||
      n < 0 ||
      n != trunc(n) ||
      n > .Machine$integer.max
  ) {
    zuid_abort(
      "type",
      "`n` must be a single non-negative whole number.",
      call = call
    )
  }
  as.numeric(n)
}

check_uuid_version <- function(version, call = sys.call(-1L)) {
  ok <- is.numeric(version) &&
    length(version) == 1L &&
    !is.na(version) &&
    version %in% c(1, 3, 4, 5, 6, 7, 8)
  if (!ok) {
    zuid_abort(
      "type",
      "`version` must be one of 1, 3, 4, 5, 6, 7 or 8.",
      call = call
    )
  }
  as.integer(version)
}

# Microseconds since 1970 per value, as whole doubles, or NULL for the clock.
generation_time <- function(time, n, version, call = sys.call(-1L)) {
  if (is.null(time)) {
    return(NULL)
  }
  if (inherits(time, "POSIXct")) {
    us <- round(as.numeric(time) * 1e6)
  } else if (is.numeric(time) && !is.object(time)) {
    us <- round(as.numeric(time) * 1e3)
  } else {
    zuid_abort(
      "type",
      "`time` must be a POSIXct or a number of milliseconds since 1970.",
      call = call
    )
  }
  if (!length(us) %in% c(1L, n) || anyNA(us)) {
    zuid_abort(
      "type",
      "`time` must have length 1 or `n`, with no missing values.",
      call = call
    )
  }
  # The range each version's time field can hold.
  range_us <- if (version == 7L) {
    c(0, (2^48 - 1) * 1e3)
  } else {
    c(-12219292800 * 1e6, (2^60 - 1) / 10 - 12219292800 * 1e6)
  }
  if (any(us < range_us[1] | us > range_us[2])) {
    zuid_abort(
      "type",
      sprintf("`time` is outside what a version %d UUID can hold.", version),
      call = call
    )
  }
  rep_len(us, n)
}

# Seconds. The option may be a number of seconds or a difftime.
rollback_tolerance <- function() {
  tol <- getOption("zuid.rollback_tolerance", 10)
  if (inherits(tol, "difftime")) {
    tol <- as.numeric(tol, units = "secs")
  }
  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol < 0) {
    zuid_abort(
      "type",
      "The option `zuid.rollback_tolerance` must be a non-negative number of seconds."
    )
  }
  tol
}

#' Generate ULIDs, TypeIDs and UPIDs
#'
#' `id_ulid()` generates ULIDs: 48 bits of milliseconds and 80 random bits.
#' Values from one session strictly increase, by the specification's rule:
#' within a millisecond, the random component of the last value plus one.
#' That overflows only after 2^80 values in one millisecond, which is a
#' `zuid_overflow_error`.
#'
#' `id_typeid()` generates TypeIDs: a version 7 UUID, as [id_uuid()] makes
#' it, under `prefix`.
#'
#' `id_upid()` generates UPIDs: 40 bits of time in 256 ms units, 64 random
#' bits, the prefix and the current version, as the reference does. UPIDs
#' are not monotonic within 256 ms.
#'
#' Entropy comes from the operating system, never from R's random number
#' generator, and the clock rollback rule of [id_uuid()] applies to ULIDs.
#'
#' @inheritParams id_uuid
#' @param prefix For `id_typeid()`, the type: up to 63 lowercase letters and
#'   underscores, starting and ending with a letter, or `""` for none. For
#'   `id_upid()`, one to four characters of `234567` and `a` to `z`, padded
#'   on the right with `z` as the reference pads it.
#' @param random `NULL` to draw from the operating system, or exactly the
#'   bytes needed: 10 per value for ULIDs and TypeIDs, 8 for UPIDs.
#' @return A zuid vector of `n` values.
#' @examples
#' id_ulid(2)
#' id_typeid(2, "user")
#' id_upid(2, "user")
#' @export
id_ulid <- function(n = 1, random = NULL, time = NULL) {
  n <- check_count(n)
  check_random(random, 10 * n)
  time_us <- generation_time(time, n, 7L)
  out <- .Call(zuid_c_ulid, n, time_us, random, rollback_tolerance() * 1000)
  if (is.null(out)) {
    zuid_abort("entropy", "The operating system's entropy source failed.")
  }
  if (is.integer(out)) {
    zuid_abort(
      "overflow",
      sprintf(
        "Value %d overflows the 80-bit random component within its millisecond.",
        out
      )
    )
  }
  new_zuid(out, "ulid")
}

#' @rdname id_ulid
#' @export
id_typeid <- function(n = 1, prefix, random = NULL, time = NULL) {
  if (missing(prefix)) {
    zuid_abort("type", "`prefix` is required; use `\"\"` for none.")
  }
  check_typeid_prefix(prefix)
  n <- check_count(n)
  check_random(random, 10 * n)
  id_convert(id_uuid(n, 7, random = random, time = time), "typeid", prefix)
}

#' @rdname id_ulid
#' @export
id_upid <- function(n = 1, prefix, random = NULL, time = NULL) {
  if (missing(prefix)) {
    zuid_abort("type", "`prefix` is required.")
  }
  check_string(prefix, "prefix")
  if (!grepl("^[2-7a-z]{1,4}$", prefix)) {
    zuid_abort(
      "type",
      "`prefix` must be 1 to 4 characters of `234567` and `a` to `z`."
    )
  }
  n <- check_count(n)
  check_random(random, 8 * n)
  time_us <- generation_time(time, n, 7L)
  out <- .Call(zuid_c_upid, n, time_us, random, upid_tail(prefix))
  if (is.null(out)) {
    zuid_abort("entropy", "The operating system's entropy source failed.")
  }
  new_zuid(out, "upid")
}

check_random <- function(random, need, call = sys.call(-1L)) {
  if (!is.null(random) && (!is.raw(random) || length(random) != need)) {
    zuid_abort(
      "type",
      sprintf("`random` must be %s raw bytes.", format(need)),
      call = call
    )
  }
}

check_typeid_prefix <- function(prefix, call = sys.call(-1L)) {
  check_string(prefix, "prefix", call = call)
  if (!grepl("^([a-z]([a-z_]{0,61}[a-z])?)?$", prefix)) {
    zuid_abort(
      "type",
      paste(
        "`prefix` must be up to 63 lowercase letters and underscores,",
        "starting and ending with a letter."
      ),
      call = call
    )
  }
}

# The last three bytes of a UPID: the prefix, padded to four characters
# with "z", in 20 bits, then the version nibble, 6 ("a").
upid_tail <- function(prefix) {
  symbols <- strsplit("234567abcdefghijklmnopqrstuvwxyz", "")[[1L]]
  chars <- strsplit(substr(paste0(prefix, "zzzz"), 1L, 4L), "")[[1L]]
  v <- sum((match(chars, symbols) - 1) * 32^(3:0)) * 16 + 6
  as.raw(c(v %/% 65536, (v %/% 256) %% 256, v %% 256))
}
