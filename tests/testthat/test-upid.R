test_that("UPIDs read and write as the reference does", {
  f <- upid_fixture()
  x <- id_from_bytes(lapply(f$hex, hex_bytes), "upid")
  expect_identical(as.character(x), f$text)
  y <- id_parse(f$text, "upid", level = "syntax")
  expect_identical(id_encode(id_bytes(y), "hex"), f$hex)
  expect_identical(id_fields(y)$prefix, f$prefix)
  expect_identical(id_time(y, "ms"), f$milliseconds)
})

test_that("the reference's README example holds", {
  x <- id_parse("user_2accvpp5guht4dts56je5a", "upid")
  expect_identical(
    id_encode(id_bytes(x), "hex"),
    "01908dd6a3669b912738191ea3d61576"
  )
  expect_identical(
    as.character(id_convert(x, "uuid")),
    "01908dd6-a366-9b91-2738-191ea3d61576"
  )
  f <- id_fields(x)
  expect_identical(f$prefix, "user")
  expect_identical(f$version, 6L)
  expect_identical(f$time_unit, "256ms")
  expect_identical(f$random, "669b912738191ea3")
  expect_true(id_valid("user_2accvpp5guht4dts56je5a", "upid", level = "strict"))
})

test_that("UPID text is checked as the reference checks it", {
  expect_identical(
    id_valid(
      c(
        "zzzz_zzzzzzzzzzzzzzzzzzzzjj", # the largest value
        "zzzz_zzzzzzzzzzzzzzzzzzzzjk", # version character past j
        "zzzz_zzzzzzzzzzzzzzzzzzzzkj", # last random character past j
        "USER_2accvpp5guht4dts56je5a", # uppercase
        "user-2accvpp5guht4dts56je5a",
        "user_2accvpp5guht4dts56je5",
        "user_2accvpp5guht4dts56je51" # 1 is not in the alphabet
      ),
      "upid"
    ),
    c(TRUE, rep(FALSE, 6))
  )
  # Strict needs the current version nibble, "a".
  expect_identical(
    id_valid(
      c("user_2accvpp5guht4dts56je5a", "user_2accvpp5guht4dts56je5b"),
      "upid",
      level = "strict"
    ),
    c(TRUE, FALSE)
  )
})

test_that("id_upid() pads the prefix, keeps the time to 256 ms and round-trips", {
  x <- id_upid(1e4, "ab")
  expect_true(all(startsWith(as.character(x), "abzz_")))
  expect_identical(id_parse(as.character(x), "upid"), x)
  expect_identical(id_from_bytes(id_bytes(x), "upid"), x)
  expect_true(all(id_valid(as.character(x), "upid", level = "strict")))
  y <- id_upid(1, "user", random = as.raw(1:8), time = 1720366572288 + 255)
  expect_identical(id_time(y, "ms"), 1720366572288)
  expect_identical(
    id_encode(id_bytes(y), "hex"),
    "01908dd6a30102030405060708d61576"
  )
  expect_error(id_upid(1, "users"), class = "zuid_type_error")
  expect_error(id_upid(1, "us1"), class = "zuid_type_error")
  expect_error(id_upid(1, ""), class = "zuid_type_error")
  expect_error(id_upid(1, "user", random = raw(7)), class = "zuid_type_error")
})
