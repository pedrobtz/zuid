test_that("version 1 and 6 fields match RFC 9562 A.1 and A.5", {
  x <- id_parse(
    c(
      "C232AB00-9414-11EC-B3C8-9F6BDECED846",
      "1EC9414C-232A-6B00-B3C8-9F6BDECED846"
    ),
    "uuid"
  )
  f <- id_fields(x)
  expect_identical(f$version, c(1L, 6L))
  expect_identical(f$variant, c("rfc", "rfc"))
  expect_identical(f$time_unit, c("100ns", "100ns"))
  expect_identical(f$sequence, c(0x33C8L, 0x33C8L))
  expect_identical(f$node, c("9f6bdeced846", "9f6bdeced846"))
  expect_equal(f$time, rep(rfc9562_instant(), 2), tolerance = 1e-6)
  expect_true(all(is.na(f$random)))
})

test_that("version 7 fields match RFC 9562 A.6", {
  x <- id_parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F", "uuid")
  f <- id_fields(x)
  expect_identical(f$version, 7L)
  expect_identical(f$time_unit, "ms")
  expect_identical(id_time(x, "ms"), 1645557742000)
  expect_identical(id_time(x), rfc9562_instant())
  expect_identical(f$random, "330d8c4dc0c0c07398f")
  expect_true(is.na(f$node))
  expect_true(is.na(f$sequence))
})

test_that("version 4 reports its 122 random bits", {
  f <- id_fields(id_parse("919108f7-52d1-4320-9bac-f847db4148a8", "uuid"))
  expect_identical(f$random, "2464423dd4b44c81bacf847db4148a8")
  expect_true(is.na(f$time))
})

test_that("versions 3, 5 and 8 report the version only", {
  x <- id_parse(
    c(
      "5df41881-3aed-3515-88a7-2f4a814cf09e",
      "2ed6657d-e927-568b-95e1-2665a8aea6a2",
      "5c146b14-3c52-8afd-938a-375d0df1fbf6"
    ),
    "uuid"
  )
  f <- id_fields(x)
  expect_identical(f$version, c(3L, 5L, 8L))
  expect_true(all(is.na(f$time)))
  expect_true(all(is.na(f$random)))
  expect_true(all(is.na(f$node)))
})

test_that("nil and max report versions 0 and 15 and no variant", {
  f <- id_fields(c(id_nil(), id_max()))
  expect_identical(f$version, c(0L, 15L))
  expect_true(all(is.na(f$variant)))
})

test_that("a non-RFC variant reports the variant and nothing else", {
  x <- id_parse(
    c(
      "017f22e2-79b0-7cc3-08c4-dc0c0c07398f",
      "017f22e2-79b0-7cc3-c8c4-dc0c0c07398f",
      "017f22e2-79b0-7cc3-e8c4-dc0c0c07398f"
    ),
    "uuid",
    level = "syntax"
  )
  f <- id_fields(x)
  expect_identical(f$variant, c("ncs", "microsoft", "future"))
  expect_true(all(is.na(f$version)))
  expect_true(all(is.na(f$time)))
})

test_that("times before 1970 floor correctly", {
  # Version 1 at tick 0, 1582-10-15T00:00:00Z.
  x <- id_parse("00000000-0000-1000-8000-000000000000", "uuid")
  expect_identical(id_time(x), as.POSIXct("1582-10-15", tz = "UTC"))
  expect_identical(id_time(x, "ms"), -12219292800000)
  # One tick later: 100 ns, which floors to the same millisecond.
  y <- id_parse("00000001-0000-1000-8000-000000000000", "uuid")
  expect_identical(id_time(y, "ms"), -12219292800000)
})

test_that("id_fields() has every column, NA for missing elements", {
  x <- id_parse(c("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", NA), "uuid")
  f <- id_fields(x)
  expect_named(
    f,
    c(
      "format",
      "time",
      "time_unit",
      "version",
      "variant",
      "node",
      "process",
      "sequence",
      "random",
      "prefix",
      "codec",
      "hash",
      "digest",
      "numbers"
    )
  )
  expect_identical(nrow(f), 2L)
  expect_identical(f$format, c("uuid", "uuid"))
  expect_true(all(is.na(f[2, c("time", "version", "variant", "random")])))
  expect_s3_class(f$time, "POSIXct")
  expect_identical(attr(f$time, "tzone"), "UTC")
})

test_that("inspection never raises on input but checks its argument", {
  x <- id_parse(c("nope", NA), "uuid")
  expect_no_error(id_fields(x))
  expect_no_error(id_time(x))
  expect_identical(id_version(x), c(NA_integer_, NA_integer_))
  expect_error(
    id_fields("017f22e2-79b0-7cc3-98c4-dc0c0c07398f"),
    class = "zuid_type_error"
  )
  expect_error(id_time(1), class = "zuid_type_error")
  expect_error(id_version(NULL), class = "zuid_type_error")
})
