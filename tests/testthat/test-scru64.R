test_that("SCRU64 text and time match the reference", {
  f <- scru64_fixture()
  x <- id_from_bytes(lapply(f$hex, hex_bytes), "scru64")
  expect_identical(as.character(x), f$text)
  y <- id_parse(toupper(f$text), "scru64", level = "syntax")
  expect_identical(id_encode(id_bytes(y), "hex"), f$hex)
  ok <- f$timestamp > 0 & f$timestamp < 282429536480
  expect_identical(id_valid(f$text, "scru64"), ok)
  expect_identical(id_time(y, "ms"), f$timestamp * 256)
  expect_identical(id_fields(y)$time_unit, rep("256ms", nrow(f)))
})

test_that("the reference's rejections hold", {
  bad <- c(
    "",
    " 0u3wrp5g81jx",
    "0u3wrp5g81jy ",
    "+0u3wrp5g81k0",
    "-0u3wrp5g81k1",
    "+u3wrp5q7ta5",
    "0u3w_p5q7ta7",
    "0u3wrp5-7ta8",
    "0u3wrp5q7t 9",
    "0u3wrp5q7t"
  )
  expect_identical(
    id_valid(bad, "scru64", level = "syntax"),
    rep(FALSE, length(bad))
  )
  expect_true(id_valid("zzzzzzzzzzzz", "scru64", level = "syntax"))
  expect_false(id_valid("zzzzzzzzzzzz", "scru64"))
})

test_that("generation follows the reference generator", {
  local_fresh_state()
  t <- 1.7e12
  x <- id_scru64(
    3,
    node = 5,
    node_bits = 20,
    random = as.raw(c(0, 0, 0x0e, 0, 0, 0, 0, 0, 0)),
    time = c(t, t, t)
  )
  v <- as.numeric(paste0("0x", id_encode(id_bytes(x), "hex")))
  tick <- floor(t / 256)
  # 4 counter bits: one is kept back as the overflow guard, so 0x0e seeds 6.
  expect_identical(v, tick * 2^24 + 5 * 16 + c(6, 7, 8))
  # The counter overflows into the next tick.
  more <- id_scru64(8, node = 5, node_bits = 20, random = raw(24), time = t)
  w <- as.numeric(paste0("0x", id_encode(id_bytes(more), "hex")))
  expect_identical(w[8], (tick + 1) * 2^24 + 5 * 16)
  expect_true(strictly_increasing(c(x, more)))
})

test_that("generated SCRU64 IDs strictly increase and round-trip", {
  local_fresh_state()
  x <- id_scru64(1e4, node = 1, node_bits = 8, time = 1.7e12)
  expect_true(strictly_increasing(x))
  expect_identical(id_parse(as.character(x), "scru64"), x)
  expect_identical(id_from_bytes(id_bytes(x), "scru64"), x)
  expect_true(all(id_valid(as.character(x), "scru64", level = "strict")))
  expect_error(
    id_scru64(1, node = 1, node_bits = 8, time = 1.7e12 - 60000),
    class = "zuid_clock_error"
  )
  expect_no_error(id_scru64(
    1,
    node = 1,
    node_bits = 8,
    time = 1.7e12 - 60000,
    rollback = "reset"
  ))
})

test_that("node and node_bits are required and checked", {
  expect_error(id_scru64(1), class = "zuid_type_error")
  expect_error(id_scru64(1, node = 1), class = "zuid_type_error")
  expect_error(
    id_scru64(1, node = 256, node_bits = 8),
    class = "zuid_type_error"
  )
  expect_error(
    id_scru64(1, node = 1, node_bits = 24),
    class = "zuid_type_error"
  )
  expect_error(
    id_scru64(1, node = 1.5, node_bits = 8),
    class = "zuid_type_error"
  )
  expect_error(
    id_scru64(1, node = 1, node_bits = 8, random = raw(2)),
    class = "zuid_type_error"
  )
})
