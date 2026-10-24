test_that("rs/xid's vectors hold", {
  # rs/xid id_test.go at the commit in tools/fixture-sources.yaml.
  x <- id_parse("9m4e2mr0ui3e8a215n4g", "xid")
  expect_identical(id_encode(id_bytes(x), "hex"), "4d88e15b60f486e428412dc9")
  f <- id_fields(x)
  expect_identical(id_time(x, "ms"), 1300816219 * 1000)
  expect_identical(f$node, "60f486")
  expect_identical(f$process, 0xe428L)
  expect_identical(f$sequence, 4271561L)
  y <- id_from_bytes(
    list(raw(12), hex_bytes("00000000aabbccddee000001")),
    "xid"
  )
  expect_identical(id_fields(y)$node, c("000000", "aabbcc"))
  expect_identical(id_fields(y)$process, c(0L, 0xddeeL))
  expect_identical(id_fields(y)$sequence, c(0L, 1L))
  expect_identical(id_parse(as.character(y), "xid"), y)
})

test_that("XID text is checked as rs/xid checks it", {
  expect_identical(
    id_valid(
      c(
        "9m4e2mr0ui3e8a215n4g",
        "c6e52g2mrqcjl44hf179", # nonzero spare bits
        "invalid",
        "9M4E2MR0UI3E8A215N4G", # uppercase
        "9m4e2mr0ui3e8a215n4w" # w is not base32hex
      ),
      "xid"
    ),
    c(TRUE, FALSE, FALSE, FALSE, FALSE)
  )
  expect_true(id_valid("c6e52g2mrqcjl44hf170", "xid"))
})

test_that("id_xid() uses the machine, process and counter it is given", {
  x <- id_xid(
    3,
    process = 0x1e428,
    random = as.raw(c(0x60, 0xf4, 0x86, 0xff, 0xff, 0xfe)),
    time = 1300816219000
  )
  expect_identical(
    id_encode(id_bytes(x), "hex"),
    c(
      "4d88e15b60f486e428fffffe",
      "4d88e15b60f486e428ffffff",
      "4d88e15b60f486e428000000"
    )
  )
  y <- id_xid(1, machine = as.raw(1:3), random = raw(6), time = 0)
  expect_identical(id_fields(y)$node, "010203")
})

test_that("generated XIDs share the session's machine and count up", {
  local_fresh_state()
  x <- id_xid(1e4)
  expect_identical(id_parse(as.character(x), "xid"), x)
  expect_identical(id_from_bytes(id_bytes(x), "xid"), x)
  f <- id_fields(x)
  expect_length(unique(f$node), 1L)
  expect_identical(unique(f$process), as.integer(Sys.getpid() %% 65536))
  expect_identical(diff(f$sequence) %% 2^24, rep(1, 1e4 - 1))
  expect_identical(id_fields(id_xid(1))$node, f$node[1])
  expect_error(id_xid(1, machine = raw(2)), class = "zuid_type_error")
  expect_error(id_xid(1, random = raw(5)), class = "zuid_type_error")
  expect_error(id_xid(1, time = -1), class = "zuid_type_error")
})
