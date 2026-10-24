test_that("detection follows section 6.2 for every collision it names", {
  for (case in detect_cases()) {
    d <- id_detect(case[[1]], hint = case[[2]], layout = case[[3]])
    label <- paste(case[[1]], paste(case[[2]], collapse = "+"), case[[3]]$name)
    expect_identical(unname(d[[1]]), as.character(case[[4]]), label = label)
    expect_identical(attr(d, "candidates")[[1]], case[[5]], label = label)
  }
})

test_that("no encoding or syntactic format is chosen without a hint (D10)", {
  withr::local_seed(1)
  x <- c(
    as.character(id_nanoid(50)),
    as.character(id_nanoid(
      50,
      size = 12,
      alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    )),
    as.character(id_sqids(1:50)),
    "tz4a98xxat96iws9zmbrgj3a"
  )
  d <- id_detect(x)
  chosen <- unique(d[!is.na(d)])
  expect_true(all(
    chosen %in%
      c(
        "uuid",
        "ulid",
        "typeid",
        "upid",
        "scru128",
        "ksuid",
        "xid",
        "objectid",
        "cid"
      )
  ))
  expect_false(any(
    c("nanoid", "cuid2", "sqids") %in% unlist(attr(d, "candidates"))
  ))
})

test_that("detection keeps names and missing values, and checks its arguments", {
  d <- id_detect(c(a = "01ARZ3NDEKTSV4RRFFQ69G5FAV", b = NA))
  expect_identical(names(d), c("a", "b"))
  expect_identical(as.vector(d), c("ulid", NA))
  expect_identical(attr(id_detect(character()), "candidates"), list())
  expect_identical(
    as.vector(id_detect(id_parse("01ARZ3NDEKTSV4RRFFQ69G5FAV", "ulid"))),
    "ulid"
  )
  expect_error(id_detect(1), class = "zuid_type_error")
  expect_error(id_detect("x", hint = "nope"), class = "zuid_type_error")
  expect_error(id_detect("x", layout = list()), class = "zuid_layout_error")
})

test_that("id_parse(format = NULL) detects one format or says why not", {
  x <- id_parse(c(
    "01ARZ3NDEKTSV4RRFFQ69G5FAV",
    NA,
    "01BX5ZZKBKACTAV9WEVGEMMVRY"
  ))
  expect_s3_class(x, "zuid_ulid")
  expect_identical(as.character(x)[2], NA_character_)
  y <- id_parse(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "nope"))
  expect_s3_class(y, "zuid_uuid")
  expect_true(is.na(y[2]))
  expect_error(
    id_parse(c("018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3", "nope"), strict = TRUE),
    class = "zuid_parse_error"
  )
  err <- tryCatch(id_parse("01arz3ndektsv4rrffq69g5fav"), error = identity)
  expect_s3_class(err, "zuid_ambiguous_error")
  expect_identical(err$candidates, list(c("ulid", "typeid")))
  err <- tryCatch(
    id_parse(c(
      "01ARZ3NDEKTSV4RRFFQ69G5FAV",
      "018f6b1c-2d3e-7a4b-8c5d-6e7f8091a2b3"
    )),
    error = identity
  )
  expect_s3_class(err, "zuid_mixed_error")
  expect_identical(err$formats, c("ulid", "uuid"))
  expect_error(id_parse(c("nope", NA)), class = "zuid_parse_error")
  s <- id_parse("175928847299117063", layout = id_layout("discord"))
  expect_s3_class(s, "zuid_snowflake")
  expect_identical(attr(s, "layout"), id_layout("discord"))
})
