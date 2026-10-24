test_that("KSUID's reference vectors hold", {
  # segmentio/ksuid README.md and ksuid_test.go.
  x <- id_parse(
    c("0ujtsYcgvSTl8PAuAdqWYSMnLOv", "0ujzPyRiIAffKhBux4PvQdDqMHY"),
    "ksuid"
  )
  expect_identical(
    toupper(id_encode(id_bytes(x), "hex")),
    c(
      "0669F7EFB5A1CD34B5F99D1154FB6853345C9735",
      "066A029C73FC1AA3B2446246D6E89FCD909E8FE8"
    )
  )
  expect_identical(
    id_time(x, "ms"),
    (1400000000 + c(107608047, 107610780)) * 1000
  )
  expect_identical(
    toupper(id_fields(x)$random[1]),
    "B5A1CD34B5F99D1154FB6853345C9735"
  )
  expect_identical(id_fields(x)$time_unit, c("s", "s"))
  ends <- id_from_bytes(list(raw(20), as.raw(rep(0xff, 20))), "ksuid")
  expect_identical(
    as.character(ends),
    c(strrep("0", 27), "aWgEPTl1tmebfsQzFP4bxwgy80V")
  )
  expect_true(id_valid("0pN1Own7255s7jwpwy495bAZeEa", "ksuid"))
  expect_identical(
    id_valid(
      c(
        "123",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaa",
        "aWgEPTl1tmebfsQzFP4bxwgy80!",
        "aWgEPTl1tmebfsQzFP4bxwgy80W"
      ),
      "ksuid",
      level = "syntax"
    ),
    rep(FALSE, 4)
  )
})

test_that("KSUIDs sort by time and are case-sensitive", {
  x <- id_parse(
    c("0ujzPyRiIAffKhBux4PvQdDqMHY", "0ujtsYcgvSTl8PAuAdqWYSMnLOv"),
    "ksuid"
  )
  expect_identical(as.character(sort(x)), rev(as.character(x)))
  # Another case is another value.
  y <- id_parse(
    c("0ujtsYcgvSTl8PAuAdqWYSMnLOv", "0UJTSYCGVSTL8PAUADQWYSMNLOV"),
    "ksuid"
  )
  expect_false(identical(id_bytes(y)[, 1], id_bytes(y)[, 2]))
})

test_that("generated KSUIDs round-trip and use the given bytes", {
  x <- id_ksuid(1e4)
  expect_identical(id_parse(as.character(x), "ksuid"), x)
  expect_identical(id_from_bytes(id_bytes(x), "ksuid"), x)
  expect_true(all(id_valid(as.character(x), "ksuid", level = "strict")))
  y <- id_ksuid(
    1,
    random = as.raw(1:16),
    time = (1400000000 + 107608047) * 1000 + 999
  )
  expect_identical(
    id_encode(id_bytes(y), "hex"),
    "0669f7ef0102030405060708090a0b0c0d0e0f10"
  )
  expect_error(id_ksuid(1, time = 0), class = "zuid_type_error")
  expect_error(id_ksuid(1, random = raw(15)), class = "zuid_type_error")
})
