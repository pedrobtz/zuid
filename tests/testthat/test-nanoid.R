test_that("NanoID 6's customRandom vectors hold", {
  # ai/nanoid test/index.test.js at 6.0.2.
  seq10 <- as.raw(c(2, 255, 3, 7, 7, 7, 7, 7, 0, 1))
  expect_identical(
    as.character(id_nanoid(1, 4, "abcde", random = seq10[1:7])),
    "cccc"
  )
  expect_identical(
    as.character(id_nanoid(1, 18, "abcde", random = rep_len(seq10, 29))),
    "acccccdcbacccccdcb"
  )
  expect_identical(
    as.character(id_nanoid(1, 4, "abcd", random = seq10[1:4])),
    "dddc"
  )
  expect_identical(as.character(id_nanoid(1, 0, "abc")), "")
  expect_identical(
    as.character(id_nanoid(1, 8, "abc", random = as.raw(rep(1, 16)))),
    "bbbbbbbb"
  )
})

test_that("symbols are uniform, for the default and a 26-symbol alphabet", {
  # design.md oracle 13: a chi-squared test over 10^6 symbols. With a
  # threshold of 1e-6, a correct generator fails it once in a million runs.
  for (alphabet in list(NULL, paste(letters, collapse = ""))) {
    x <- id_nanoid(1e4, size = 100, alphabet = alphabet)
    counts <- table(strsplit(paste(as.character(x), collapse = ""), "")[[1]])
    k <- if (is.null(alphabet)) 64L else 26L
    expect_length(counts, k)
    p <- stats::chisq.test(as.vector(counts))$p.value
    expect_gt(p, 1e-6)
  }
})

test_that("NanoIDs parse over their alphabet, any size", {
  x <- id_nanoid(1e4)
  expect_identical(id_parse(as.character(x), "nanoid"), x)
  expect_identical(unique(nchar(as.character(x))), 21L)
  expect_identical(
    id_valid(c("V1StGXR8_Z5jdHi6B-myT", "abc", "has space", "", "é"), "nanoid"),
    c(TRUE, TRUE, FALSE, FALSE, FALSE)
  )
  hex <- id_nanoid(3, size = 10, alphabet = "0123456789abcdef")
  expect_identical(attr(hex, "alphabet"), "0123456789abcdef")
  expect_true(all(grepl("^[0-9a-f]{10}$", as.character(hex))))
  expect_false(id_valid("xyz", "nanoid", alphabet = "0123456789abcdef"))
  expect_identical(id_parse(hex), hex)
  expect_true(all(is.na(id_fields(x[1:2])$time)))
})

test_that("set.seed() does not change NanoIDs, and bad arguments are type errors", {
  withr::local_seed(1)
  a <- id_nanoid(2)
  withr::local_seed(1)
  expect_false(any(a == id_nanoid(2)))
  expect_error(id_nanoid(1, random = raw(3)), class = "zuid_type_error")
  expect_error(id_nanoid(1, size = -1), class = "zuid_type_error")
  expect_error(id_nanoid(1, alphabet = "aa"), class = "zuid_type_error")
  expect_error(id_nanoid(1, alphabet = ""), class = "zuid_type_error")
  expect_error(id_nanoid(1, random = 1:3), class = "zuid_type_error")
})
