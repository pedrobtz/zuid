test_that("subsetting keeps the class and format", {
  x <- uuids()
  expect_s3_class(x[1:2], "zuid_uuid")
  expect_identical(attr(x[2], "format"), "uuid")
  expect_named(x[2:1], c("b", "a"))
  expect_s3_class(x[[1]], "zuid_uuid")
  expect_identical(
    as.character(rep(x[1], 2)),
    rep("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", 2)
  )
  expect_s3_class(rep(x, 2), "zuid_uuid")
})

test_that("assignment parses character values and refuses invalid ones", {
  x <- uuids()
  x[3] <- "1EC9414C-232A-6B00-B3C8-9F6BDECED846"
  expect_identical(as.character(x[[3]]), "1ec9414c-232a-6b00-b3c8-9f6bdeced846")
  x[[1]] <- id_nil()
  expect_identical(x[1], id_nil()[1] |> stats::setNames("a"))
  x[2] <- NA
  expect_true(is.na(x[2]))
  expect_error(x[1] <- "nope", class = "zuid_parse_error")
  expect_error(x[1] <- 1, class = "zuid_type_error")
})

test_that("c() combines zuid vectors and parseable text of one format", {
  x <- c(id_nil(), "017F22E2-79B0-7CC3-98C4-DC0C0C07398F", NULL, id_max())
  expect_s3_class(x, "zuid_uuid")
  expect_identical(as.character(x)[2], "017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  expect_error(c(id_nil(), "nope"), class = "zuid_parse_error")
})

test_that("comparison is on values, sorting on bytes", {
  x <- uuids()
  expect_identical(
    unname(x == "017F22E2-79B0-7CC3-98C4-DC0C0C07398F"),
    c(TRUE, FALSE, NA)
  )
  expect_identical(unname(x != "nope"), c(TRUE, TRUE, NA))
  expect_true(id_nil() == id_nil())
  expect_identical(
    as.character(sort(c(id_max(), id_nil(), x[1]))),
    c(
      "00000000-0000-0000-0000-000000000000",
      "017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
      "ffffffff-ffff-ffff-ffff-ffffffffffff"
    )
  )
  expect_identical(xtfrm(x), c(1L, 2L, NA))
  expect_identical(order(x), c(1L, 2L, 3L))
  expect_error(x < x, class = "zuid_type_error")
})

test_that("unique(), is.na() and length() behave as for character", {
  x <- c(uuids(), uuids())
  expect_s3_class(unique(x), "zuid_uuid")
  expect_length(unique(x), 3L)
  expect_identical(unname(is.na(x)), rep(c(FALSE, FALSE, TRUE), 2))
})

test_that("printing and formatting show the canonical text", {
  x <- uuids()
  expect_identical(unname(format(x))[1], "017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  expect_output(print(x), "<zuid_uuid\\[3\\]>")
  expect_output(print(x[0]), "<zuid_uuid\\[0\\]>")
  expect_identical(as.character(x), unname(unclass(x)[1:3]) |> as.vector())
})

test_that("a zuid vector is a data frame column", {
  df <- data.frame(id = uuids())
  expect_s3_class(df$id, "zuid_uuid")
  expect_s3_class(df[2:1, "id"], "zuid_uuid")
})

test_that("vctrs combines zuid vectors of one format", {
  skip_if_not_installed("vctrs")
  x <- uuids()
  expect_s3_class(vctrs::vec_c(x[1], x[2]), "zuid_uuid")
  # With plain text the common type is character, as for factors.
  expect_identical(
    vctrs::vec_c(x[[1]], "c232ab00-9414-11ec-b3c8-9f6bdeced846"),
    c(
      "017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
      "c232ab00-9414-11ec-b3c8-9f6bdeced846"
    )
  )
  expect_type(vctrs::vec_cast(x, character()), "character")
  expect_s3_class(
    vctrs::vec_cast("c232ab00-9414-11ec-b3c8-9f6bdeced846", x),
    "zuid_uuid"
  )
  expect_identical(vctrs::vec_ptype_abbr(x), "uuid")
})

test_that("vectors of different formats do not combine or compare (D3)", {
  u <- id_parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", "uuid")
  l <- id_convert(u, "ulid")
  expect_error(c(u, l), class = "zuid_type_error")
  expect_error(u == l, class = "zuid_type_error")
  skip_if_not_installed("vctrs")
  expect_error(vctrs::vec_c(u, l), class = "zuid_type_error")
})

test_that("Snowflakes under different layouts do not combine", {
  skip_if_not_installed("vctrs")
  a <- id_parse(
    "175928847299117063",
    "snowflake",
    layout = id_layout("discord")
  )
  b <- id_parse(
    "175928847299117063",
    "snowflake",
    layout = id_layout("twitter")
  )
  expect_error(c(a, b), class = "zuid_layout_error")
  expect_error(vctrs::vec_c(a, b), class = "zuid_layout_error")
})
