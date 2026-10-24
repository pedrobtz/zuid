test_that("the built-in layouts are what section 6.8 says", {
  tw <- id_layout("twitter")
  expect_s3_class(tw, "zuid_layout")
  expect_identical(tw$epoch, 1288834974657)
  expect_identical(tw$fields, c(datacenter = 5L, worker = 5L))
  expect_identical(tw$sequence, 12L)
  expect_true(tw$sign_bit)
  expect_false(id_layout("discord")$sign_bit)
  expect_identical(id_layout("instagram")$epoch, 1314220021721)
  sf <- id_layout("sonyflake", epoch = as.POSIXct("2014-09-01", tz = "UTC"))
  expect_identical(sf$order, c("time", "sequence", "machine"))
  expect_identical(sf$unit, "10ms")
  s6 <- id_layout("scru64", node_bits = 8)
  expect_identical(s6$fields, c(node = 8L))
  expect_identical(s6$sequence, 16L)
})

test_that("layouts compare by value and print as a field diagram", {
  expect_identical(id_layout("twitter"), id_layout("twitter"))
  expect_false(identical(
    id_layout("scru64", node_bits = 8),
    id_layout("scru64", node_bits = 9)
  ))
  expect_snapshot(print(id_layout("twitter")))
  expect_snapshot(print(id_layout("sonyflake", epoch = 0)))
})

test_that("a custom layout is data and must add up", {
  l <- id_layout(
    time = list(bits = 41, unit = "ms", epoch = 0),
    fields = list(worker = 10),
    sequence = 12
  )
  expect_identical(l$name, "custom")
  x <- id_snowflake(2, l, 5, time = 1000)
  expect_identical(id_fields(x)$node, rep("worker=5", 2))
  bad <- function(...) expect_error(id_layout(...), class = "zuid_layout_error")
  bad(
    time = list(bits = 41, unit = "ms", epoch = 0),
    fields = list(worker = 10),
    sequence = 11
  )
  bad(
    time = list(bits = 41, unit = "ms", epoch = 0),
    fields = list(worker = 10),
    sequence = 13,
    sign_bit = TRUE
  )
  bad(
    time = list(bits = 41, unit = "us", epoch = 0),
    fields = list(worker = 10),
    sequence = 12
  )
  bad(
    time = list(bits = 60, unit = "ms", epoch = 0),
    fields = list(w = 2),
    sequence = 1
  )
  bad(
    time = list(bits = 41, unit = "ms", epoch = 0),
    fields = list(10),
    sequence = 12
  )
  bad(
    time = list(bits = 41, unit = "ms"),
    fields = list(worker = 10),
    sequence = 12
  )
  bad(
    time = list(bits = 41, unit = "ms", epoch = 0),
    fields = list(sequence = 10),
    sequence = 12
  )
  expect_no_error(id_layout(
    time = list(bits = 42, unit = "ms", epoch = 0),
    fields = list(worker = 10),
    sequence = 12,
    sign_bit = FALSE
  ))
  bad("nope")
  bad("sonyflake")
  bad("twitter", epoch = 0)
  bad("scru64")
  bad("scru64", node_bits = 24)
  bad("twitter", node_bits = 8)
})

test_that("the layout travels with the vector", {
  tw <- id_layout("twitter")
  x <- id_parse(c("20", "100"), "snowflake", layout = tw)
  expect_identical(attr(x[2], "layout"), tw)
  expect_identical(attr(c(x, x), "layout"), tw)
  expect_identical(attr(rep(x, 2), "layout"), tw)
  expect_identical(attr(id_parse(x), "layout"), tw)
  x[1] <- "30"
  expect_identical(as.character(x), c("30", "100"))
  expect_true(x[2] == "100")
  y <- id_parse("20", "snowflake", layout = id_layout("discord"))
  expect_error(c(x, y), class = "zuid_layout_error")
})

test_that("a SCRU64 layout reads its node and counter", {
  f <- scru64_fixture()
  x <- id_parse(
    f$text[f$timestamp > 0 & f$timestamp < 282429536480],
    "scru64",
    layout = id_layout("scru64", node_bits = 8)
  )
  ctr <- f$node_ctr[f$timestamp > 0 & f$timestamp < 282429536480]
  fields <- id_fields(x)
  expect_identical(fields$node, paste0("node=", ctr %/% 2^16))
  expect_identical(fields$sequence, as.integer(ctr %% 2^16))
  expect_error(
    id_parse("0u2pf62ji4b9", "scru64", layout = id_layout("twitter")),
    class = "zuid_layout_error"
  )
})
