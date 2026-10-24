test_that("the 128-bit formats convert keeping their bytes", {
  u <- id_parse(c(a = "01890a5d-ac96-774b-bcce-b302099a8057", b = NA), "uuid")
  t <- id_convert(u, "typeid", prefix = "prefix")
  expect_identical(as.character(t), c("prefix_01h455vb4pex5vsknk084sn02q", NA))
  expect_identical(names(t), c("a", "b"))
  for (to in c("ulid", "upid", "typeid")) {
    v <- id_convert(u, to)
    expect_s3_class(v, paste0("zuid_", to))
    expect_identical(id_bytes(v), id_bytes(u), label = to)
    expect_identical(id_convert(v, "uuid"), u, label = to)
  }
  expect_identical(
    as.character(id_convert(u, "typeid")),
    c("01h455vb4pex5vsknk084sn02q", NA)
  )
})

test_that("a TypeID keeps or changes its prefix", {
  t <- id_parse("prefix_01h455vb4pex5vsknk084sn02q", "typeid")
  expect_identical(id_convert(t, "typeid"), t)
  expect_identical(
    as.character(id_convert(t, "typeid", prefix = "other")),
    "other_01h455vb4pex5vsknk084sn02q"
  )
})

test_that("a ULID read as a UUID reports what its bits say", {
  x <- id_convert(id_parse("01ARZ3NDEKTSV4RRFFQ69G5FAV", "ulid"), "uuid")
  expect_identical(as.character(x), "01563e3a-b5d3-d676-4c61-efb99302bd5b")
  expect_identical(id_fields(x)$variant, "ncs")
})

test_that("conversions without a common value are convert errors", {
  u <- id_parse("01890a5d-ac96-774b-bcce-b302099a8057", "uuid")
  expect_error(id_convert(u, "nope"), class = "zuid_type_error")
  expect_error(id_convert("x", "uuid"), class = "zuid_type_error")
  expect_error(id_convert(u, "ulid", prefix = "a"), class = "zuid_type_error")
  expect_error(id_convert(u, "typeid", prefix = "A"), class = "zuid_type_error")
})
