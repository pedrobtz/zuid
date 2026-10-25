test_that("RFC 9562 A.1 and A.5 regenerate from their stated inputs", {
  local_fresh_state()
  node <- hex_raw("9f6bdeced846")
  seq <- hex_raw("33c8")
  t <- rfc9562_instant()
  expect_identical(
    as.character(id_uuid(version = 1, time = t, node = node, random = seq)),
    "c232ab00-9414-11ec-b3c8-9f6bdeced846"
  )
  .Call(zuid:::zuid_c_reset_state)
  expect_identical(
    as.character(id_uuid(version = 6, time = t, node = node, random = seq)),
    "1ec9414c-232a-6b00-b3c8-9f6bdeced846"
  )
})

test_that("RFC 9562 A.3, B.1 and B.2 regenerate from their bits", {
  for (s in c(
    "919108f7-52d1-4320-9bac-f847db4148a8",
    "2489e9ad-2ee2-8e00-8ec9-32d5f69181c0",
    "5c146b14-3c52-8afd-938a-375d0df1fbf6"
  )) {
    version <- strtoi(substr(s, 15, 15), 16L)
    expect_identical(
      as.character(id_uuid(version = version, random = hex_raw(s))),
      s
    )
  }
})

test_that("RFC 9562 A.6 regenerates but for the counter's top bit", {
  # rand_a is a counter seeded with its top bit clear (design 6.7), so A.6's
  # 0xCC3 comes back as 0x4C3; the time and rand_b are A.6's.
  local_fresh_state()
  random <- c(hex_raw("0cc3"), hex_raw("98c4dc0c0c07398f"))
  expect_identical(
    as.character(id_uuid(
      version = 7,
      time = rfc9562_instant(),
      random = random
    )),
    "017f22e2-79b0-74c3-98c4-dc0c0c07398f"
  )
})

test_that("generated UUIDs parse at strict with their version", {
  for (v in c(1, 4, 6, 7)) {
    x <- id_uuid(5, version = v)
    expect_s3_class(x, "zuid_uuid")
    expect_true(all(id_valid(x, "uuid", level = "strict")), info = v)
    expect_identical(id_version(x), rep(as.integer(v), 5), info = v)
  }
  expect_identical(id_version(id_uuid()), 7L)
})

test_that("the current time is used when `time` is NULL", {
  before <- Sys.time()
  x <- id_uuid(version = 7)
  y <- id_uuid(version = 1)
  after <- Sys.time()
  expect_true(id_time(x) >= trunc(before) - 1 && id_time(x) <= after + 1)
  expect_true(id_time(y) >= trunc(before) - 1 && id_time(y) <= after + 1)
})

test_that("version 7 strictly increases over 10^5 values at a frozen clock", {
  local_fresh_state()
  t <- rfc9562_instant()
  x <- id_uuid(1e5, version = 7, time = t)
  expect_true(strictly_increasing(x))
  expect_false(anyDuplicated(x) > 0)
  ms <- id_time(x, "ms")
  expect_identical(ms[1], as.numeric(t) * 1000)
  # Counter overflow borrows the next millisecond, never more than needed.
  expect_true(all(diff(ms) %in% c(0, 1)))
  expect_true(strictly_increasing(c(x[1e5], id_uuid(version = 7, time = t))))
})

test_that("version 1 and 6 strictly increase at a frozen clock", {
  local_fresh_state()
  t <- rfc9562_instant()
  x1 <- id_uuid(1e4, version = 1, time = t)
  expect_false(anyDuplicated(x1) > 0)
  expect_true(all(diff(id_fields(x1)$time) >= 0))
  x6 <- id_uuid(1e4, version = 6, time = t)
  expect_true(strictly_increasing(x6))
})

test_that("a small clock rollback keeps version 7 increasing", {
  local_fresh_state()
  t <- rfc9562_instant()
  a <- id_uuid(version = 7, time = t)
  b <- id_uuid(version = 7, time = t - 5)
  expect_true(strictly_increasing(c(a, b)))
  expect_identical(id_time(b), id_time(a))
})

test_that("a large clock rollback restarts version 7 at the new time", {
  local_fresh_state()
  t <- rfc9562_instant()
  a <- id_uuid(version = 7, time = t)
  b <- id_uuid(version = 7, time = t - 60)
  expect_identical(id_time(b), t - 60)
  withr::local_options(zuid.rollback_tolerance = 3600)
  c <- id_uuid(version = 7, time = t - 120)
  expect_identical(id_time(c), t - 60)
})

test_that("a large rollback increments the version 1 clock sequence", {
  local_fresh_state()
  t <- rfc9562_instant()
  a <- id_uuid(version = 1, time = t)
  b <- id_uuid(version = 1, time = t - 5)
  expect_identical(id_fields(b)$sequence, id_fields(a)$sequence)
  # One tick past `a`: 100 ns, finer than a POSIXct resolves.
  expect_true(id_time(b) >= id_time(a))
  low <- function(u) as.numeric(paste0("0x", substr(as.character(u), 1, 8)))
  expect_identical(low(b), low(a) + 1)
  c <- id_uuid(version = 1, time = t - 60)
  expect_identical(
    id_fields(c)$sequence,
    (id_fields(a)$sequence + 1L) %% 16384L
  )
  expect_equal(id_time(c), t - 60, tolerance = 1e-6)
})

test_that("set.seed() does not change generated values", {
  a <- local({
    withr::local_seed(1)
    id_uuid(10, version = 4)
  })
  b <- local({
    withr::local_seed(1)
    id_uuid(10, version = 4)
  })
  expect_false(any(a == b))
})

test_that("fixed time and random give fixed bytes", {
  # The same strings are asserted on every CI leg, so a platform difference
  # in the generators fails here.
  random7 <- as.raw(0:29)
  random4 <- as.raw(seq(0, 255, length.out = 32))
  local_fresh_state()
  x <- id_uuid(3, version = 7, time = 1645557742000, random = random7)
  expect_identical(
    as.character(x),
    c(
      "017f22e2-79b0-7001-8203-040506070809",
      "017f22e2-79b0-7002-8c0d-0e0f10111213",
      "017f22e2-79b0-7003-9617-18191a1b1c1d"
    )
  )
  expect_identical(
    as.character(id_uuid(2, version = 4, random = random4)),
    c(
      "00081018-2029-4139-814a-525a626a737b",
      "838b949c-a4ac-44bd-85cd-d5dee6eef6ff"
    )
  )
})

test_that("zuid_info() reports the generation state", {
  local_fresh_state()
  info <- zuid_info()
  expect_true(
    info$entropy %in%
      c("getrandom", "getentropy", "BCryptGenRandom", "arc4random_buf")
  )
  expect_true(is.na(info$state$uuid7_last_ms))
  id_uuid(version = 7, time = 1645557742000)
  expect_identical(zuid_info()$state$uuid7_last_ms, 1645557742000)
  id_uuid(version = 1)
  expect_false(is.na(zuid_info()$state$uuid1_clock_seq))
})

test_that("arguments are checked with classed errors", {
  expect_error(id_uuid(-1), class = "zuid_type_error")
  expect_error(id_uuid(1.5), class = "zuid_type_error")
  expect_error(id_uuid(version = 2), class = "zuid_type_error")
  expect_error(id_uuid(version = 9), class = "zuid_type_error")
  expect_error(id_uuid(version = 3), class = "zuid_dependency_error")
  expect_error(id_uuid(version = 5), class = "zuid_dependency_error")
  expect_error(id_uuid(version = 8), class = "zuid_type_error")
  expect_error(
    id_uuid(version = 4, random = raw(15)),
    class = "zuid_type_error"
  )
  expect_error(
    id_uuid(2, version = 7, random = raw(10)),
    class = "zuid_type_error"
  )
  expect_error(id_uuid(version = 1, node = raw(5)), class = "zuid_type_error")
  expect_error(id_uuid(version = 4, node = raw(6)), class = "zuid_type_error")
  expect_error(id_uuid(time = "now"), class = "zuid_type_error")
  expect_error(id_uuid(3, time = Sys.time() + 1:2), class = "zuid_type_error")
  expect_error(id_uuid(time = -1), class = "zuid_type_error")
  expect_error(
    id_uuid(version = 7, time = 2^48 * 1000),
    class = "zuid_type_error"
  )
  withr::local_options(zuid.rollback_tolerance = "x")
  expect_error(id_uuid(), class = "zuid_type_error")
})

test_that("n = 0 gives an empty vector", {
  expect_length(id_uuid(0), 0L)
  expect_s3_class(id_uuid(0, version = 1), "zuid_uuid")
})

test_that("version 7 at the last millisecond overflows instead of wrapping", {
  local_fresh_state()
  expect_error(
    id_uuid(5000, version = 7, time = 2^48 - 1),
    class = "zuid_overflow_error"
  )
  # The values a smaller call makes there are valid and increasing.
  local_fresh_state()
  x <- id_uuid(100, version = 7, time = 2^48 - 1)
  expect_true(strictly_increasing(x))
  expect_true(all(id_time(x, "ms") == 2^48 - 1))
  expect_error(
    id_typeid(5000, "user", time = 2^48 - 1),
    class = "zuid_overflow_error"
  )
})

test_that("versions 1 and 6 hold the largest accepted time exactly", {
  local_fresh_state()
  top <- 103072857660684688 / 1000
  for (v in c(1, 6)) {
    x <- id_uuid(1, version = v, time = top)
    expect_true(id_valid(as.character(x), "uuid"))
    expect_gt(id_time(x, "ms"), 1e14)
    expect_error(
      id_uuid(1, version = v, time = top + 0.1),
      class = "zuid_type_error"
    )
  }
})

test_that("explicit time and random make generation a pure function", {
  local_fresh_state()
  t <- as.POSIXct("2024-01-01", tz = "UTC")
  expect_identical(
    id_uuid(3, random = as.raw(1:30), time = t),
    id_uuid(3, random = as.raw(1:30), time = t)
  )
  expect_identical(
    id_uuid(2, version = 1, random = as.raw(1:8), time = t),
    id_uuid(2, version = 1, random = as.raw(1:8), time = t)
  )
  expect_identical(
    id_ulid(2, random = as.raw(1:20), time = t),
    id_ulid(2, random = as.raw(1:20), time = t)
  )
  # A pure call leaves the session's state alone.
  expect_true(is.na(zuid_info()$state$uuid7_last_ms))
  expect_true(is.na(zuid_info()$state$ulid_last_ms))
})
