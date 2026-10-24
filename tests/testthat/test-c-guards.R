# The .Call entry points check their arguments again, so that a bug in the
# R wrappers cannot read past a buffer. The wrappers never send these
# values, so the tests call the entry points directly. Two guards are not
# reached: a string longer than R allows (src/zuid_r.c, zuid_mkchar) and a
# raw matrix past R_XLEN_T_MAX (zuid_c_bytes), since neither input can be
# built in a test's memory. Nor are the out-of-memory branches of the
# encoders (ZUID_ENC_NOMEM), which need malloc() to fail.

c_call <- function(name, ...) {
  .Call(getNativeSymbolInfo(name, "zuid"), ...)
}

test_that("the table and format arguments are checked in C", {
  expect_error(c_call("zuid_c_table", 1), class = "error")
  expect_error(c_call("zuid_c_table", "nope"), class = "error")
  expect_error(c_call("zuid_c_bytes", "x", 1), class = "error")
  expect_error(c_call("zuid_c_bytes", "x", "nope"), class = "error")
  expect_error(c_call("zuid_c_bytes", "x", "nanoid"), class = "error")
  expect_error(c_call("zuid_c_format", "x", "uuid", 1), class = "error")
  expect_error(c_call("zuid_c_format", "x", "uuid", "nope"), class = "error")
  expect_error(c_call("zuid_c_bytes", 1, "uuid"), class = "error")
})

test_that("bytes are checked in C", {
  expect_error(c_call("zuid_c_from_bytes", "x", "uuid", FALSE), class = "error")
  expect_error(
    c_call("zuid_c_from_bytes", raw(15), "uuid", FALSE),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_layout_unpack", raw(7), 1:2, 0:1),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_layout_unpack", raw(8), c(32L, 31L), c(0L, 9L)),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_layout_unpack", raw(8), c(32L, 30L), c(0L, 2L)),
    class = "error"
  )
  expect_error(c_call("zuid_c_layout_unpack", raw(8), 1, 0), class = "error")
  expect_error(c_call("zuid_c_cid_text", list(1)), class = "error")
})

test_that("encoding arguments are checked in C", {
  b <- list(as.raw(1:4))
  expect_error(c_call("zuid_c_encode", b, 1, NULL, "-"), class = "error")
  expect_error(c_call("zuid_c_encode", b, "nope", NULL, "-"), class = "error")
  expect_error(c_call("zuid_c_encode", b, "alphabet", 1, "-"), class = "error")
  expect_error(
    c_call("zuid_c_encode", b, "alphabet", "aa", "-"),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_encode", as.raw(1), "hex", NULL, "-"),
    class = "error"
  )
  expect_error(c_call("zuid_c_encode", b, "proquint", NULL, 1), class = "error")
  expect_error(
    c_call("zuid_c_encode", list(1), "hex", NULL, "-"),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_encode", list(as.raw(1:3)), "proquint", NULL, "-"),
    class = "error"
  )
  expect_error(c_call("zuid_c_decode", 1, "hex", NULL, NULL), class = "error")
})

test_that("generator arguments are checked in C", {
  expect_error(
    c_call("zuid_c_uuid", -1, 7L, NULL, NULL, NULL, 0),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_uuid", 2, 7L, 1, NULL, NULL, 0),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_uuid", 1, 4L, NULL, raw(3), NULL, 0),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_uuid", 1, 1L, NULL, NULL, raw(5), 0),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_uuid", 1, 2L, NULL, NULL, NULL, 0),
    class = "error"
  )
  expect_error(c_call("zuid_c_ulid", -1, NULL, NULL, 0), class = "error")
  expect_error(c_call("zuid_c_ulid", 2, 1, NULL, 0), class = "error")
  expect_error(c_call("zuid_c_upid", -1, NULL, NULL, raw(3)), class = "error")
  expect_error(c_call("zuid_c_upid", 1, NULL, NULL, raw(2)), class = "error")
  expect_error(
    c_call("zuid_c_scru128", -1, NULL, NULL, 0, FALSE),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_scru64", 1, NULL, NULL, 1, 24L, 0, FALSE),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_scru64", 1, NULL, NULL, 256, 8L, 0, FALSE),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_snowflake", 1, c(41L, 22L), c(0L, 2L), 0, 0, 1, 0, FALSE),
    class = "error"
  )
  expect_error(
    c_call(
      "zuid_c_snowflake",
      1L,
      c(42L, 22L),
      c(0L, 2L),
      c(0, 0),
      0,
      1,
      0,
      FALSE
    ),
    class = "error"
  )
  expect_error(c_call("zuid_c_xid", 1, raw(2), 1L, NULL), class = "error")
  expect_error(c_call("zuid_c_xid", 1, NULL, 1L, raw(5)), class = "error")
  expect_error(c_call("zuid_c_objectid", 1, raw(7)), class = "error")
  expect_error(
    c_call("zuid_c_nanoid", 1, 21, strrep("a", 257), NULL),
    class = "error"
  )
})

test_that("text format arguments are checked in C", {
  expect_error(c_call("zuid_c_charset", 1, "abc"), class = "error")
  expect_error(c_call("zuid_c_cuid2", 1), class = "error")
  expect_error(c_call("zuid_c_cid_parse", 1), class = "error")
  expect_error(
    c_call("zuid_c_sqids_encode", list(1), "ab", 0, NULL),
    class = "error"
  )
  expect_error(
    c_call("zuid_c_sqids_parse", "x", "abc", 300, NULL),
    class = "error"
  )
})
