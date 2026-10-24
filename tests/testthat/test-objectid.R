test_that("the BSON corpus ObjectIds hold", {
  # mongodb/specifications source/bson-corpus/tests/oid.json.
  hex <- c(
    "000000000000000000000000",
    "ffffffffffffffffffffffff",
    "56e1fc72e0c917e9c4714161"
  )
  x <- id_parse(hex, "objectid")
  expect_identical(as.character(x), hex)
  expect_identical(id_encode(id_bytes(x), "hex"), hex)
  expect_identical(as.character(id_parse(toupper(hex), "objectid")), hex)
  f <- id_fields(x)
  expect_identical(id_time(x, "ms")[3], 0x56e1fc72 * 1000)
  expect_identical(f$random[3], "e0c917e9c4")
  expect_identical(f$sequence[3], 0x714161L)
  expect_true(all(is.na(f$node)))
  expect_identical(
    id_valid(
      c(
        "56e1fc72e0c917e9c47141",
        "56e1fc72-e0c917e9c47141",
        "56e1fc72e0c917e9c471416g"
      ),
      "objectid"
    ),
    c(FALSE, FALSE, FALSE)
  )
})

test_that("an XID and an ObjectId convert keeping their bytes", {
  x <- id_parse("9m4e2mr0ui3e8a215n4g", "xid")
  o <- id_convert(x, "objectid")
  expect_identical(as.character(o), "4d88e15b60f486e428412dc9")
  expect_identical(id_convert(o, "xid"), x)
  expect_error(id_convert(o, "uuid"), class = "zuid_convert_error")
})

test_that("generated ObjectIds round-trip and count up", {
  local_fresh_state()
  x <- id_objectid(1e4)
  expect_identical(id_parse(as.character(x), "objectid"), x)
  expect_identical(id_from_bytes(id_bytes(x), "objectid"), x)
  f <- id_fields(x)
  expect_length(unique(f$random), 1L)
  expect_identical(diff(f$sequence) %% 2^24, rep(1, 1e4 - 1))
  expect_true(all(id_valid(as.character(x), "objectid", level = "strict")))
  y <- id_objectid(
    2,
    random = as.raw(c(0xe0, 0xc9, 0x17, 0xe9, 0xc4, 0x71, 0x41, 0x61)),
    time = 0x56e1fc72 * 1000
  )
  expect_identical(
    as.character(y),
    c("56e1fc72e0c917e9c4714161", "56e1fc72e0c917e9c4714162")
  )
})
