test_that("SCRU128 text and fields match the reference", {
  f <- scru128_fixture()
  x <- id_from_bytes(lapply(f$hex, hex_bytes), "scru128")
  expect_identical(as.character(x), f$text)
  y <- id_parse(toupper(f$text), "scru128", level = "syntax")
  expect_identical(id_encode(id_bytes(y), "hex"), f$hex)
  fields <- id_fields(y)
  expect_identical(id_time(y, "ms"), f$timestamp)
  expect_identical(strtoi(fields$node, 16L), as.integer(f$counter_hi))
  expect_identical(fields$sequence, as.integer(f$counter_lo))
  expect_identical(as.numeric(paste0("0x", fields$random)), f$entropy)
})

test_that("the specification's vectors and rejections hold", {
  # scru128/spec base36_128.c and scru128/python tests/test_identifier.py.
  x <- id_parse(
    c("0372hg16csmsm50l8dikcvukc", "0372ijojuxuhjsfkeryi2mrtm"),
    "scru128"
  )
  expect_identical(
    id_encode(id_bytes(x), "hex"),
    c("017fee7fef417e2b3432ac2ec553687c", "017fef39c2641ba56a9483188841e05a")
  )
  bad <- c(
    "",
    " 036z8puq4tsxsigk6o19y164q",
    "036z8puq54qny1vq3hcbrkweb ",
    "+036z8puq54qny1vq3hfcv3ss0",
    "-036z8puq54qny1vq3hhy8u1ch",
    "036z8puq5a7j0t_08p2cdz28v",
    "036z8pu-5a7j0ti08p3ol8ool",
    "036z8puq5a7j0ti08p4j 6cya",
    "f5lxx1zz5pnorynqglhzmsp34",
    "zzzzzzzzzzzzzzzzzzzzzzzzz",
    "039o\tvvklfmqlqe7fzllz7c7t",
    "039onvvklfmqlq漢字fgvd1"
  )
  expect_identical(
    id_valid(bad, "scru128", level = "syntax"),
    rep(FALSE, length(bad))
  )
})

test_that("the reserved timestamps pass syntax only", {
  reserved <- c(
    "0000000000000000000000000",
    "f5lxx1zz5k6tp71geeh2db7k0",
    "f5lxx1zz5pnorynqglhzmsp33"
  )
  expect_identical(
    id_valid(reserved, "scru128", level = "syntax"),
    rep(TRUE, 3)
  )
  expect_identical(id_valid(reserved, "scru128"), rep(FALSE, 3))
  expect_true(id_valid(
    "0000000000000000000000001",
    "scru128",
    level = "syntax"
  ))
})

test_that("generation follows the specification's counters", {
  local_fresh_state()
  r <- function(entropy, lo, hi) as.raw(c(entropy, lo, hi))
  random <- c(
    r(c(1, 2, 3, 4), c(0, 0, 9), c(0, 0, 7)),
    r(c(5, 6, 7, 8), c(9, 9, 9), c(9, 9, 9)),
    r(c(0, 0, 0, 0), c(0, 0, 1), c(0, 0, 2))
  )
  x <- id_scru128(3, random = random, time = c(1e12, 1e12, 1e12 + 1))
  f <- id_fields(x)
  expect_identical(id_time(x, "ms"), c(1e12, 1e12, 1e12 + 1))
  # counter_lo seeded, then incremented within the millisecond, then renewed.
  expect_identical(f$sequence, c(9L, 10L, 1L))
  # counter_hi is renewed only once the timestamp has moved a second.
  expect_identical(f$node, rep("000007", 3))
  expect_identical(f$random, c("01020304", "05060708", "00000000"))
  y <- id_scru128(
    1,
    random = r(c(0, 0, 0, 0), c(0, 0, 0), c(0, 0, 5)),
    time = 1e12 + 1000
  )
  expect_identical(id_fields(y)$node, "000005")
})

test_that("a counter overflow moves the timestamp forward", {
  local_fresh_state()
  max24 <- as.raw(c(0xff, 0xff, 0xff))
  random <- c(
    as.raw(1:4),
    max24,
    max24,
    as.raw(1:4),
    as.raw(c(0, 0, 3)),
    as.raw(c(0, 0, 4))
  )
  x <- id_scru128(2, random = random, time = 1e12)
  expect_identical(id_time(x, "ms"), c(1e12, 1e12 + 1))
  expect_identical(id_fields(x)$node, c("ffffff", "000000"))
  expect_identical(id_fields(x)$sequence, c(16777215L, 3L))
})

test_that("a clock rollback is kept, raised or reset (D18)", {
  local_fresh_state()
  a <- id_scru128(1, time = 1.7e12)
  b <- id_scru128(1, time = 1.7e12 - 5000)
  expect_true(strictly_increasing(c(a, b)))
  expect_identical(id_time(b, "ms"), 1.7e12)
  expect_error(id_scru128(1, time = 1.7e12 - 60000), class = "zuid_clock_error")
  c <- id_scru128(1, time = 1.7e12 - 60000, rollback = "reset")
  expect_identical(id_time(c, "ms"), 1.7e12 - 60000)
})

test_that("generated SCRU128 IDs strictly increase and round-trip", {
  local_fresh_state()
  x <- id_scru128(1e4, time = 1.7e12)
  expect_true(strictly_increasing(x))
  expect_identical(id_parse(as.character(x), "scru128"), x)
  expect_identical(id_from_bytes(id_bytes(x), "scru128"), x)
  expect_true(all(id_valid(
    as.character(id_scru128(3)),
    "scru128",
    level = "strict"
  )))
  expect_error(id_scru128(1, time = 0), class = "zuid_type_error")
  expect_error(id_scru128(1, random = raw(9)), class = "zuid_type_error")
})
