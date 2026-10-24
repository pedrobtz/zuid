test_that("ULID's specification vectors hold", {
  # ulid/spec README at the commit in tools/fixture-sources.yaml.
  expect_true(id_valid("01ARZ3NDEKTSV4RRFFQ69G5FAV", "ulid"))
  expect_identical(
    id_valid(
      c("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", "80000000000000000000000000"),
      "ulid"
    ),
    c(TRUE, FALSE)
  )
  expect_identical(
    id_time(id_parse("7ZZZZZZZZZZZZZZZZZZZZZZZZZ", "ulid"), "ms"),
    2^48 - 1
  )
})

test_that("ULID text is uppercase and either case parses", {
  x <- id_parse(
    c("01arz3ndektsv4rrffq69g5fav", "01ARZ3NDEKTSV4RRFFQ69G5FAV"),
    "ulid"
  )
  expect_identical(as.character(x), rep("01ARZ3NDEKTSV4RRFFQ69G5FAV", 2))
  expect_identical(
    id_valid(
      c(
        "01ARZ3NDEKTSV4RRFFQ69G5FA",
        "01ARZ3NDEKTSV4RRFFQ69G5FAI",
        "01ARZ3NDEKTSV4RRFFQ69G5FA-"
      ),
      "ulid"
    ),
    c(FALSE, FALSE, FALSE)
  )
})

test_that("ULID fields are the millisecond time and 80 random bits", {
  x <- id_parse("01ARZ3NDEKTSV4RRFFQ69G5FAV", "ulid")
  f <- id_fields(x)
  expect_identical(f$time_unit, "ms")
  expect_identical(id_time(x, "ms"), 1469922850259)
  expect_identical(f$random, "d6764c61efb99302bd5b")
  expect_true(is.na(f$version))
})

test_that("ULIDs increment within a millisecond, as the specification shows", {
  local_fresh_state()
  start <- id_parse("01BX5ZZKBKACTAV9WEVGEMMVRY", "ulid")
  time <- id_time(start, "ms")
  random <- c(id_bytes(start)[7:16], raw(30))
  x <- id_ulid(4, random = random, time = time)
  expect_identical(
    as.character(x),
    c(
      "01BX5ZZKBKACTAV9WEVGEMMVRY",
      "01BX5ZZKBKACTAV9WEVGEMMVRZ",
      "01BX5ZZKBKACTAV9WEVGEMMVS0",
      "01BX5ZZKBKACTAV9WEVGEMMVS1"
    )
  )
})

test_that("the random component overflowing is a zuid_overflow_error", {
  local_fresh_state()
  start <- id_parse("01BX5ZZKBKZZZZZZZZZZZZZZZX", "ulid")
  time <- id_time(start, "ms")
  random <- c(id_bytes(start)[7:16], raw(20))
  x <- id_ulid(3, random = random, time = time)
  expect_identical(as.character(x)[3], "01BX5ZZKBKZZZZZZZZZZZZZZZZ")
  expect_error(
    id_ulid(1, random = raw(10), time = time),
    class = "zuid_overflow_error"
  )
  # A later millisecond starts afresh.
  expect_no_error(id_ulid(1, random = raw(10), time = time + 1))
})

test_that("ULIDs strictly increase over a frozen clock and survive a rollback", {
  local_fresh_state()
  x <- id_ulid(1e4, time = 1.7e12)
  expect_true(strictly_increasing(x))
  later <- id_ulid(1, time = 1.7e12 - 5000)
  expect_gt(
    id_encode(id_bytes(later), "hex"),
    id_encode(id_bytes(x[1e4]), "hex")
  )
  withr::local_options(zuid.rollback_tolerance = 1)
  reset <- id_ulid(1, time = 1.7e12 - 5000)
  expect_identical(id_time(reset, "ms"), 1.7e12 - 5000)
})

test_that("generated ULIDs round-trip through text and bytes", {
  x <- id_ulid(1e4)
  expect_identical(id_parse(as.character(x), "ulid"), x)
  expect_identical(id_from_bytes(id_bytes(x), "ulid"), x)
  expect_true(all(id_valid(as.character(x), "ulid", level = "strict")))
})

test_that("set.seed() does not change ULIDs, and bad arguments are type errors", {
  withr::local_seed(1)
  a <- id_ulid(2)
  withr::local_seed(1)
  b <- id_ulid(2)
  expect_false(any(a == b))
  expect_error(id_ulid(1, random = raw(9)), class = "zuid_type_error")
  expect_error(id_ulid(-1), class = "zuid_type_error")
  expect_error(id_ulid(1, time = -1), class = "zuid_type_error")
  expect_error(id_parse("x", "ulid", form = "hex"), class = "zuid_type_error")
})
