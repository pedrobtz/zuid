test_that("zuid_info() reports the version and both tables", {
  info <- zuid_info()
  expect_s3_class(info$version, "package_version")
  expect_identical(info$version, packageVersion("zuid"))
  expect_setequal(info$tables$table, c("niceware_words", "sqids_blocklist"))
  expect_true(all(grepl("^[0-9a-f]{40}$", info$tables$commit)))
  expect_true(all(grepl("^[0-9a-f]{64}$", info$tables$sha256)))
})

test_that("the Niceware word list is the reference's, in both copies", {
  words <- zuid:::niceware_words
  expect_length(words, 65536L)
  expect_identical(words[c(1L, 2L, 65536L)], c("a", "aah", "zyzzyva"))
  expect_false(is.unsorted(words, strictly = TRUE))
  expect_identical(.Call(zuid:::zuid_c_table, "niceware_words"), words)
})

test_that("the Sqids blocklist is upstream's, in both copies", {
  blocklist <- zuid:::sqids_blocklist
  expect_length(blocklist, 560L)
  expect_true(all(grepl("^[a-z0-9]+$", blocklist)))
  expect_identical(.Call(zuid:::zuid_c_table, "sqids_blocklist"), blocklist)
})

test_that("table entry counts match the recorded sources", {
  tables <- zuid_info()$tables
  expect_identical(
    tables$entries[match(c("niceware_words", "sqids_blocklist"), tables$table)],
    c(length(zuid:::niceware_words), length(zuid:::sqids_blocklist))
  )
})
