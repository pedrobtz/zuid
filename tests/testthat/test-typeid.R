test_that("every valid TypeID fixture decodes to its prefix and UUID", {
  v <- typeid_fixture("valid.yml")
  x <- id_parse(v$typeid, "typeid")
  expect_identical(as.character(x), v$typeid)
  expect_identical(id_fields(x)$prefix, v$prefix)
  expect_identical(as.character(id_convert(x, "uuid")), v$uuid)
})

test_that("every valid TypeID fixture encodes from its prefix and UUID", {
  v <- typeid_fixture("valid.yml")
  for (i in seq_len(nrow(v))) {
    # Some fixtures are not RFC 9562 variants, so parse at syntax.
    u <- id_parse(v$uuid[i], "uuid", level = "syntax")
    expect_identical(
      as.character(id_convert(u, "typeid", prefix = v$prefix[i])),
      v$typeid[i],
      label = v$name[i]
    )
  }
})

test_that("every invalid TypeID fixture is rejected", {
  i <- typeid_fixture("invalid.yml")
  expect_identical(id_valid(i$typeid, "typeid"), rep(FALSE, nrow(i)))
  expect_true(all(is.na(id_parse(i$typeid, "typeid"))))
})

test_that("TypeID fields are the UUID's, with the prefix", {
  x <- id_parse(
    c("prefix_01h455vb4pex5vsknk084sn02q", "01h455vb4pex5vsknk084sn02q"),
    "typeid"
  )
  f <- id_fields(x)
  expect_identical(f$prefix, c("prefix", ""))
  expect_identical(f$version, c(7L, 7L))
  expect_identical(f$variant, c("rfc", "rfc"))
  expect_identical(id_time(x, "ms"), rep(1688096058518, 2))
})

test_that("TypeIDs sort by prefix, then by the UUID's bytes", {
  x <- id_parse(
    c(
      "b_00000000000000000000000000",
      "a_00000000000000000000000001",
      "ab_00000000000000000000000000",
      "a_00000000000000000000000000"
    ),
    "typeid"
  )
  expect_identical(
    as.character(sort(x)),
    c(
      "a_00000000000000000000000000",
      "a_00000000000000000000000001",
      "ab_00000000000000000000000000",
      "b_00000000000000000000000000"
    )
  )
})

test_that("id_typeid() makes version 7 UUIDs under a prefix", {
  local_fresh_state()
  x <- id_typeid(1e4, "user")
  expect_true(all(startsWith(as.character(x), "user_")))
  expect_identical(unique(id_version(x)), 7L)
  expect_identical(id_parse(as.character(x), "typeid"), x)
  expect_true(strictly_increasing(x))
  local_fresh_state()
  t <- id_typeid(1, "", random = as.raw(1:10), time = 0)
  local_fresh_state()
  u <- id_uuid(1, random = as.raw(1:10), time = 0)
  expect_identical(as.character(t), tolower(id_format(u, "base32")))
  expect_true(all(id_valid(
    as.character(id_typeid(3, "")),
    "typeid",
    level = "strict"
  )))
})

test_that("bad TypeID prefixes are type errors", {
  expect_error(id_typeid(1, "User"), class = "zuid_type_error")
  expect_error(id_typeid(1, "_user"), class = "zuid_type_error")
  expect_error(id_typeid(1, strrep("a", 64)), class = "zuid_type_error")
  expect_error(id_typeid(1), class = "zuid_type_error")
  expect_no_error(id_typeid(1, strrep("a", 63)))
})
