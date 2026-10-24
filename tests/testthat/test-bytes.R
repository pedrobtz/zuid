test_that("id_bytes() is big-endian, one column per element", {
  x <- id_parse(c("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", NA), "uuid")
  b <- id_bytes(x)
  expect_identical(dim(b), c(16L, 2L))
  expect_identical(b[1:4, 1], as.raw(c(0x01, 0x7f, 0x22, 0xe2)))
  expect_identical(b[, 2], raw(16))
  expect_identical(attr(b, "na"), 2L)
})

test_that("id_from_bytes() takes a matrix, a list or a flat vector", {
  x <- id_parse(c("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", NA), "uuid")
  b <- id_bytes(x)
  expect_identical(id_from_bytes(b, "uuid"), unname(x))
  expect_identical(id_from_bytes(list(b[, 1], NULL), "uuid"), unname(x))
  expect_identical(
    as.character(id_from_bytes(as.vector(b), "uuid")),
    c(
      "017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
      "00000000-0000-0000-0000-000000000000"
    )
  )
  expect_length(id_from_bytes(raw(), "uuid"), 0L)
  expect_length(id_from_bytes(list(), "uuid"), 0L)
})

test_that("id_from_bytes() requires a format and the right width", {
  expect_error(id_from_bytes(raw(16)), class = "zuid_type_error")
  expect_error(id_from_bytes(raw(15), "uuid"), class = "zuid_type_error")
  expect_error(
    id_from_bytes(matrix(raw(32), 8), "uuid"),
    class = "zuid_type_error"
  )
  expect_error(id_from_bytes(list(raw(3)), "uuid"), class = "zuid_type_error")
  expect_error(id_from_bytes("00", "uuid"), class = "zuid_type_error")
})

test_that("id_format() writes every hex form", {
  x <- id_parse(c("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", NA), "uuid")
  expect_identical(id_format(x), c("017f22e2-79b0-7cc3-98c4-dc0c0c07398f", NA))
  expect_identical(
    id_format(x, "hex")[1],
    "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
  )
  expect_identical(
    id_format(x, "compact")[1],
    "017f22e279b07cc398c4dc0c0c07398f"
  )
  expect_identical(
    id_format(x, "urn")[1],
    "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
  )
  expect_identical(
    id_format(x, "braced")[1],
    "{017f22e2-79b0-7cc3-98c4-dc0c0c07398f}"
  )
  expect_identical(
    id_format(x, "uppercase")[1],
    "017F22E2-79B0-7CC3-98C4-DC0C0C07398F"
  )
  expect_error(id_format(x, "base99"), class = "zuid_type_error")
  expect_error(id_format("x"), class = "zuid_type_error")
})

test_that("nil and max are the all-zero and all-one UUIDs", {
  expect_identical(id_bytes(id_nil())[, 1], raw(16))
  expect_identical(id_bytes(id_max())[, 1], as.raw(rep(0xff, 16)))
  expect_s3_class(id_nil(), "zuid_uuid")
})
