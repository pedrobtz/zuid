test_that("fixed inputs give the same text and fields on every platform", {
  expect_identical(
    determinism_lines(),
    readLines(test_path("fixtures", "determinism.txt"), encoding = "UTF-8")
  )
})
