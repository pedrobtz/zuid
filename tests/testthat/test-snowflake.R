test_that("Discord's documented example decodes", {
  # discord.com/developers/docs/reference#snowflakes
  x <- id_parse(
    "175928847299117063",
    "snowflake",
    layout = id_layout("discord")
  )
  expect_identical(
    format(id_time(x), "%Y-%m-%dT%H:%M:%OS3Z"),
    "2016-04-30T11:18:25.796Z"
  )
  f <- id_fields(x)
  expect_identical(f$node, "worker=1,process=0")
  expect_identical(f$sequence, 7L)
  expect_identical(f$time_unit, "ms")
})

test_that("Twitter identifiers decode to their published creation times", {
  # Tweet 1050118621198921728, created 2018-10-10T20:19:24Z (the Twitter
  # API's example Tweet object), and 20, the first of the Snowflake era.
  x <- id_parse(
    c("1050118621198921728", "20"),
    "snowflake",
    layout = id_layout("twitter")
  )
  expect_identical(
    format(id_time(x), "%Y-%m-%dT%H:%M:%S"),
    c("2018-10-10T20:19:24", "2010-11-04T01:42:54")
  )
  expect_identical(id_fields(x)$sequence, c(0L, 20L))
})

test_that("a Snowflake needs a layout and fits it", {
  expect_error(id_parse("20", "snowflake"), class = "zuid_layout_error")
  tw <- id_layout("twitter")
  big <- "18446744073709551615"
  expect_identical(
    id_valid(big, "snowflake", layout = tw, level = "syntax"),
    TRUE
  )
  expect_identical(id_valid(big, "snowflake", layout = tw), FALSE)
  expect_identical(
    id_valid(big, "snowflake", layout = id_layout("discord")),
    TRUE
  )
  expect_identical(
    id_valid(
      c("0", "01", "18446744073709551616", "-1", "1e5", ""),
      "snowflake",
      layout = tw,
      level = "syntax"
    ),
    c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
  )
  expect_error(
    id_from_bytes(as.raw(rep(0xff, 8)), "snowflake", layout = tw),
    class = "zuid_layout_error"
  )
  expect_error(id_from_bytes(raw(8), "snowflake"), class = "zuid_layout_error")
  expect_error(id_parse("20", "uuid", layout = tw), class = "zuid_type_error")
})

test_that("Snowflakes sort numerically, not as text", {
  x <- id_parse(c("100", "20", "3"), "snowflake", layout = id_layout("twitter"))
  expect_identical(as.character(sort(x)), c("3", "20", "100"))
})

test_that("id_snowflake() packs the layout and counts within a tick", {
  local_fresh_state()
  tw <- id_layout("twitter")
  t <- 1288834974657 + 41944705796
  x <- id_snowflake(3, tw, list(datacenter = 1, worker = 7), time = t)
  f <- id_fields(x)
  expect_identical(f$sequence, 0:2)
  expect_identical(f$node, rep("datacenter=1,worker=7", 3))
  expect_identical(id_time(x, "ms"), rep(t, 3))
  # (41944705796 << 22) | (1 << 17) | (7 << 12), worked out by hand.
  expect_identical(as.character(x[1]), "175928847299145728")
})

test_that("the sequence overflows into the next tick", {
  local_fresh_state()
  ig <- id_layout("instagram")
  x <- id_snowflake(1025, ig, 3, time = 1.6e12)
  f <- id_fields(x)
  expect_identical(f$sequence[1024:1025], c(1023L, 0L))
  expect_identical(diff(id_time(x, "ms"))[1024], 1)
  expect_true(strictly_increasing(x))
  # Ticks an overflow moved ahead to are not a clock rollback.
  expect_no_error(id_snowflake(5000, ig, 3, time = 1.6e12))
})

test_that("a clock rollback beyond zuid.clock_tolerance is a clock error", {
  local_fresh_state()
  tw <- id_layout("twitter")
  a <- id_snowflake(1, tw, list(datacenter = 0, worker = 0), time = 1.7e12)
  b <- id_snowflake(1, tw, list(datacenter = 0, worker = 0), time = 1.7e12 - 5)
  expect_true(strictly_increasing(c(a, b)))
  expect_error(
    id_snowflake(1, tw, list(datacenter = 0, worker = 0), time = 1.7e12 - 100),
    class = "zuid_clock_error"
  )
  withr::local_options(zuid.clock_tolerance = 1)
  expect_no_error(id_snowflake(
    1,
    tw,
    list(datacenter = 0, worker = 0),
    time = 1.7e12 - 100
  ))
})

test_that("generated Snowflakes round-trip under every built-in layout", {
  local_fresh_state()
  layouts <- list(
    twitter = list(id_layout("twitter"), list(datacenter = 31, worker = 31)),
    discord = list(id_layout("discord"), list(worker = 1, process = 2)),
    instagram = list(id_layout("instagram"), 8191),
    sonyflake = list(
      id_layout("sonyflake", epoch = as.POSIXct("2014-09-01", tz = "UTC")),
      65535
    )
  )
  for (nm in names(layouts)) {
    l <- layouts[[nm]][[1]]
    x <- id_snowflake(1e4, l, layouts[[nm]][[2]])
    expect_identical(
      id_parse(as.character(x), "snowflake", layout = l),
      x,
      label = nm
    )
    expect_identical(
      id_from_bytes(id_bytes(x), "snowflake", layout = l),
      x,
      label = nm
    )
    expect_true(strictly_increasing(x), label = nm)
    expect_true(
      all(id_valid(as.character(x), "snowflake", layout = l, level = "strict")),
      label = nm
    )
  }
})

test_that("worker is required and must fit the layout", {
  tw <- id_layout("twitter")
  expect_error(id_snowflake(1, tw), class = "zuid_type_error")
  expect_error(id_snowflake(1, worker = 1), class = "zuid_type_error")
  expect_error(id_snowflake(1, tw, 1), class = "zuid_type_error")
  expect_error(
    id_snowflake(1, tw, list(datacenter = 32, worker = 0)),
    class = "zuid_type_error"
  )
  expect_error(
    id_snowflake(1, tw, list(datacenter = 1)),
    class = "zuid_type_error"
  )
  expect_error(
    id_snowflake(1, tw, list(datacenter = 1, worker = 1), time = 0),
    class = "zuid_type_error"
  )
  expect_error(id_snowflake(1, list(), 1), class = "zuid_layout_error")
})
