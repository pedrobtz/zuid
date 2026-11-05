# Extracted from test-encode.R:241

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "zuid", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
b <- hex_bytes("f81d4fae7dec11d0a76500a0c91e6bf6")
x <- id_parse(c(a = "f81d4fae-7dec-11d0-a765-00a0c91e6bf6", b = NA), "uuid")
expect_identical(id_encode(b, "base58"), "Xe22UfxT3rxcKJEAfL5373")
expect_identical(
    id_encode(list(p = b, q = NULL), "base58"),
    c(p = "Xe22UfxT3rxcKJEAfL5373", q = NA)
  )
expect_identical(
    id_encode(id_bytes(x), "base58"),
    c("Xe22UfxT3rxcKJEAfL5373", NA)
  )
