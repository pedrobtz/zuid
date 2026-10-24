test_that("Cuid2 is validated as the reference's isCuid() validates it", {
  # paralleldrive/cuid2: 2 to 32 of 0-9a-z; generated ones start with a
  # letter, which is the strict level.
  x <- c(
    "tz4a98xxat96iws9zmbrgj3a",
    "pfh0haxfpzowht3oi213cqos",
    "1abc",
    "a",
    strrep("a", 33),
    "Tz4a",
    "ab-c",
    NA
  )
  expect_identical(
    id_valid(x, "cuid2"),
    c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, NA)
  )
  expect_identical(
    id_valid(x, "cuid2", level = "strict"),
    c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, NA)
  )
  y <- id_parse(x[1:2], "cuid2")
  expect_identical(as.character(sort(y)), sort(x[1:2]))
  expect_true(all(is.na(id_fields(y)$time)))
  expect_error(id_bytes(y), class = "zuid_type_error")
})
